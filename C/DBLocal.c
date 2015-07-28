/*********************************************************************************************
 **	__________         __           .__            __                 ________   _______   	**
 **	\______   \_____  |  | __  _____|  |__ _____ _/  |______   	___  _\_____  \  \   _  \  	**
 **	 |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \  	\  \/ //  ____/  /  /_\  \ 	**
 **	 |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \__ \   //       \  \  \_/   \	**
 **	 |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /	  \_/ \_______ \ /\_____  /	**
 **	        \/      \/     \/     \/     \/     \/          \/ 	              \/ \/     \/ 	**
 **                                                                                         **
 **		Source code and assets are property of Taiki, distribution is stricly forbidden		**
 **                                                                                         **
 *********************************************************************************************/

#include "dbCache.h"

#pragma mark - Public API

//Prevent reusing ID
static uint baseID = 1;

uint getEmptyLocalSlot(PROJECT_DATA project)
{
	char requestString[300];

	//Either we want the main local repo, or the local entries of a standard repo
	snprintf(requestString, sizeof(requestString), "SELECT "DBNAMETOID(RDB_projectID)" FROM "MAIN_CACHE" WHERE "DBNAMETOID(RDB_repo)" = %llu %s ORDER BY "DBNAMETOID(RDB_projectID)" ASC", getRepoID(project.repo), isLocalProject(project) ? "AND "DBNAMETOID(RDB_isLocal)" = 1" : "");

	sqlite3_stmt * request = createRequest(cache, requestString);

	if(request == NULL)
		return INVALID_VALUE;

	while(sqlite3_step(request) == SQLITE_ROW)
	{
		uint data = (uint) sqlite3_column_int(request, 0);

		if(data == baseID)
			baseID++;
		else if(data > baseID)
			break;
	}

	destroyRequest(request);

	//We ensure the directory is clean
	project.projectID = baseID;
	char * path = getPathForProject(project);
	if(path != NULL)
	{
		char pathFinal[strlen(path) + 100];
		snprintf(pathFinal, sizeof(pathFinal), PROJECT_ROOT"%s/", path);
		free(path);

		removeFolder(pathFinal);
	}

	return baseID;
}

void registerImportEntry(PROJECT_DATA_PARSED project, bool isTome)
{
	if(ACCESS_DATA(isTome, (void *) project.chapitresLocal, (void *) project.tomeLocal) == NULL)
		return;

	//Okay, we have quite some work to do
	//First, we need to check if we need to register the project

	char requestString[400];
	uint64_t repoID = getRepoID(project.project.repo);

	//Does the oroject exist?
	snprintf(requestString, sizeof(requestString), "SELECT "DBNAMETOID(RDB_ID)" FROM "MAIN_CACHE" WHERE "DBNAMETOID(RDB_projectID)" = %d AND "DBNAMETOID(RDB_repo)" = %llu %s ORDER BY "DBNAMETOID(RDB_ID)" ASC", project.project.projectID, repoID, isLocalProject(project.project) ? "AND "DBNAMETOID(RDB_isLocal)" = 1" : "");

	sqlite3_stmt * request = createRequest(cache, requestString);

	PROJECT_DATA_PARSED cachedProject;
	switch(sqlite3_step(request))
	{
		//We found something, we need to insert our new data in the base
		//If we can't load the data, we just insert the new entry
		case SQLITE_ROW:
		{
			cachedProject = getParsedProjectByID((uint) sqlite3_column_int(request, 0));

			//Successfully loaded the data
			if(cachedProject.project.isInitialized)
				break;
		}

		//Insert into the base, and quit
		case SQLITE_OK:
		default:
		{
			destroyRequest(request);

			generateCTUsable(&project);

			project.project.cacheDBID = addToCache(NULL, project, repoID, true, true);
			if(project.project.cacheDBID != 0)
			{
				insertInSearch(NULL, INSERT_PROJECT, project.project);
				addRecentEntry(project.project, true);
			}
			return;
		}
	}

	//We insert the new item
	if(isTome)
	{
		META_TOME * newField = realloc(cachedProject.tomeLocal, (project.nombreTomeLocal + cachedProject.nombreTomeLocal) * sizeof(META_TOME));
		if(newField != NULL)
		{
			memcpy(&newField[cachedProject.nombreTomeLocal], project.tomeLocal, project.nombreTomeLocal * sizeof(META_TOME));
			cachedProject.nombreTomeLocal += project.nombreTomeLocal;
			cachedProject.tomeLocal = newField;

			qsort(cachedProject.tomeLocal, cachedProject.nombreTomeLocal, sizeof(META_TOME), sortTomes);
		}
	}
	else
	{
		int * newField = realloc(cachedProject.chapitresLocal, (project.nombreChapitreLocal + cachedProject.nombreChapitreLocal) * sizeof(int));
		if(newField != NULL)
		{
			memcpy(&newField[cachedProject.nombreChapitreLocal], project.chapitresLocal, project.nombreChapitreLocal * sizeof(int));
			cachedProject.nombreChapitreLocal += project.nombreChapitreLocal;
			cachedProject.chapitresLocal = newField;

			qsort(cachedProject.chapitresLocal, cachedProject.nombreChapitreLocal, sizeof(int), sortNumbers);
		}
	}

	consolidateCTLocale(&cachedProject, isTome);
	generateCTUsable(&cachedProject);

	updateCache(cachedProject, RDB_UPDATE_ID, 0);
	addRecentEntry(cachedProject.project, true);
	releaseParsedData(cachedProject);
}

#define getData(run, newData, index)	ACCESS_DATA(run == 1, ((int*) newData)[index], ((META_TOME*) newData)[index].ID)

void migrateRemovedInstalledToLocal(PROJECT_DATA_PARSED oldProject, PROJECT_DATA_PARSED * newProject)
{
	uint nbOld, nbNew, lengthCollector;
	void * dataOld, *dataNew, * collector;
	uint16_t sizeOfType;
	bool shouldFreeCollector;

	//We have two passes, one for the chapters, one for the volume
	for(byte run = 0; run < 2; run++)
	{
		lengthCollector = 0;
		collector = NULL;
		shouldFreeCollector = false;

		if(run == 0)	//chapters
		{
			oldProject.project.nombreChapitre = nbOld = oldProject.nombreChapitreRemote;
			oldProject.project.chapitresFull = dataOld = oldProject.chapitresRemote;
			nbNew = newProject->nombreChapitreRemote;
			dataNew = newProject->chapitresRemote;

			sizeOfType = sizeof(int);
		}
		else
		{
			oldProject.project.nombreTomes = nbOld = oldProject.nombreTomeRemote;
			oldProject.project.tomesFull = dataOld = oldProject.tomeRemote;
			nbNew = newProject->nombreTomeRemote;
			dataNew = newProject->tomeRemote;

			sizeOfType = sizeof(META_TOME);
		}

		//Nothing that could even be installed, make things easier...
		if(nbOld == 0)
			continue;

		//Nothing remaining, so anything remaining is here to stay
		if(nbNew == 0)
		{
			if(run == 0)
				oldProject.project.chapitresInstalled = NULL;
			else
				oldProject.project.tomesInstalled = NULL;

			getCTInstalled(&oldProject.project, run != 0);

			uint length = ACCESS_DATA(run != 0, oldProject.project.nombreChapitreInstalled, oldProject.project.nombreTomesInstalled);

			if(length != 0)
			{
				collector = ACCESS_DATA(run != 0, (void*) oldProject.project.chapitresInstalled, (void*) oldProject.project.tomesInstalled);
				lengthCollector = length;
			}
		}
		else
		{
			//Okay, we have to perform a real diff
			collector = malloc(nbOld * sizeOfType);
			if(collector == NULL)
			{
				memoryError(nbOld * sizeOfType);
				continue;
			}

			shouldFreeCollector = true;

			//O(n^2) because meh
			for(uint posOld = 0, posNew; posOld < nbOld; ++posOld)
			{
				posNew = 0;
				int oldDataForIndex = getData(run, dataOld, posOld);

				for(; posNew < nbNew && getData(run, dataNew, posNew) != oldDataForIndex; ++posNew);

				//The entry still exist, awesome
				if (posNew != nbNew)
					continue;

				//Oh, is it still installed?
				if(checkReadable(oldProject.project, run != 0, oldDataForIndex))
				{
					//And shit... we need to copy it to the selector :X
					if(run == 0)
						((int *) collector)[lengthCollector++] = oldDataForIndex;
					else
						copyTomeList(&(((META_TOME *) dataOld)[posOld]), 1, &(((META_TOME *) collector)[lengthCollector++]));
				}
			}
		}

		//Copy the collected data to the local buffer
		if(lengthCollector != 0)
		{
			if(run == 0)
			{
				void * tmp = realloc(newProject->chapitresLocal, newProject->nombreChapitreLocal + lengthCollector);
				if(tmp != NULL)
				{
					newProject->chapitresLocal = tmp;
					memcpy(&(newProject->chapitresLocal[newProject->nombreChapitreLocal]), collector, lengthCollector * sizeOfType);
					newProject->nombreChapitreLocal += lengthCollector;
				}
			}
			else
			{
				void * tmp = realloc(newProject->tomeLocal, newProject->nombreTomeLocal + lengthCollector);
				if(tmp != NULL)
				{
					newProject->tomeLocal = tmp;
					memcpy(&(newProject->tomeLocal[newProject->nombreTomeLocal]), collector, lengthCollector * sizeOfType);
					newProject->nombreTomeLocal += lengthCollector;
				}
			}
		}

		if(shouldFreeCollector)
			free(collector);
	}
}