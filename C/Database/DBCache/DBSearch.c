/*********************************************************************************************
 **	__________         __           .__            __                 ________   _______   	**
 **	\______   \_____  |  | __  _____|  |__ _____ _/  |______   	___  _\_____  \  \   _  \  	**
 **	 |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \  	\  \/ //  ____/  /  /_\  \ 	**
 **	 |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \_  \   //       \  \  \_/   \	**
 **	 |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /	  \_/ \_______ \ /\_____  /	**
 **	        \/      \/     \/     \/     \/     \/          \/ 	              \/ \/     \/ 	**
 **                                                                                         **
 **			This Source Code Form is subject to the terms of the Mozilla Public				**
 **			License, v. 2.0. If a copy of the MPL was not distributed with this				**
 **			file, You can obtain one at https://mozilla.org/MPL/2.0/.						**
 **                                                                                         **
 **                     			© Taiki 2011-2016                                       **
 **                                                                                         **
 *********************************************************************************************/

#include "dbCache.h"

static bool initialized = false;

static int64_t nbAuthor = 0, nbTag = 0, nbCat = 0;
static int64_t nbRestrictionAuthor = 0, nbRestrictionTag = 0, nbRestrictionCat = 0, nbRestrictionSource = 0;
static uint64_t sessionAuthor = 1, sessionTag = 1, sessionType = 1;

typedef struct randoName
{
	sqlite3_stmt * addAuthor;
	sqlite3_stmt * addTag;
	sqlite3_stmt * addType;
	sqlite3_stmt * getAuthorID;
	sqlite3_stmt * getTagID;
	sqlite3_stmt * getTypeID;
	sqlite3_stmt * addProject;
	sqlite3_stmt * updateProject;
	sqlite3_stmt * removeProject;
	sqlite3_stmt * flushCategories;
	sqlite3_stmt * readProject;
	sqlite3_stmt * addString;
	sqlite3_stmt * updateString;
	
} * SEARCH_JUMPTABLE;

#define TABLE_NAME_AUTHOR		"rakSearch1"
#define TABLE_NAME_TAG			"rakSearch2"
#define TABLE_NAME_CORRES		"rakSearch3"
#define TABLE_NAME_RESTRICTIONS	"rakSearch4"

bool manipulateProjectSearch(SEARCH_JUMPTABLE table, bool wantInsert, PROJECT_DATA project);
void updateElementCount(byte type, int change);
void updateRestrictionCount(byte type, int change);

void buildSearchTables(sqlite3 *_cache)
{
	if(_cache == NULL)
		return;
	
	sqlite3_stmt* request = NULL;
	
	if((request = createRequest(_cache, "CREATE TABLE "TABLE_NAME_AUTHOR" ("DBNAMETOID(RDB_authors)" TEXT UNIQUE ON CONFLICT FAIL, "DBNAMETOID(RDB_ID)" INTEGER PRIMARY KEY AUTOINCREMENT);")) == NULL || sqlite3_step(request) != SQLITE_DONE)
	{
		initialized = false;
		destroyRequest(request);
		return;
	}
	
	destroyRequest(request);
	
	if((request = createRequest(_cache, "CREATE TABLE "TABLE_NAME_TAG"("DBNAMETOID(RDB_ID)" INTEGER PRIMARY KEY AUTOINCREMENT, "DBNAMETOID(RDB_tagID)" INTEGER NOT NULL, "DBNAMETOID(RDBS_tagType)" INTEGER NOT NULL);")) == NULL || sqlite3_step(request) != SQLITE_DONE)
	{
		initialized = false;
		destroyRequest(request);
		return;
	}

	destroyRequest(request);
	
	if((request = createRequest(_cache, "CREATE TABLE "TABLE_NAME_CORRES" ("DBNAMETOID(RDB_ID)" INTEGER NOT NULL, "DBNAMETOID(RDBS_dataID)" INTEGER NOT NULL, "DBNAMETOID(RDBS_dataType)" INTEGER NOT NULL);")) == NULL || sqlite3_step(request) != SQLITE_DONE)
	{
		initialized = false;
		destroyRequest(request);
		return;
	}
	
	destroyRequest(request);
	
	if((request = createRequest(_cache, "CREATE TABLE "TABLE_NAME_RESTRICTIONS" ("DBNAMETOID(RDBS_dataType)" INTEGER NOT NULL, "DBNAMETOID(RDBS_dataID)" INTEGER NOT NULL);")) == NULL || sqlite3_step(request) != SQLITE_DONE)
	{
		initialized = false;
		destroyRequest(request);
		return;
	}
	
	//We need at least one (invalid) data :/
	if((request = createRequest(_cache, "INSERT INTO "TABLE_NAME_RESTRICTIONS" ("DBNAMETOID(RDBS_dataType)", "DBNAMETOID(RDBS_dataID)") values("STRINGIZE(RDBS_TYPE_UNUSED)", "STRINGIZE(RDBS_TYPE_UNUSED)");")) == NULL || sqlite3_step(request) != SQLITE_DONE)
	{
		initialized = false;
		destroyRequest(request);
		return;
	}
	
	if(!createCollate(_cache))
	{
		initialized = false;
		return;
	}
	
	initialized = true;
	destroyRequest(request);
}

void * buildSearchJumpTable(sqlite3 * _cache)
{
	if(_cache == NULL)
		_cache = cache;
		
	if(!initialized || _cache == NULL)
		return NULL;
	
	byte stage = 0;
	SEARCH_JUMPTABLE output = malloc(sizeof(struct randoName));
	
	if(output == NULL)
		return NULL;
	
	if((output->addAuthor = createRequest(_cache, "INSERT INTO "TABLE_NAME_AUTHOR"("DBNAMETOID(RDB_authors)") values(?1);")) == NULL)
		goto fail;
	else
		stage++;
	
	if((output->addTag = createRequest(_cache, "INSERT INTO "TABLE_NAME_TAG"("DBNAMETOID(RDB_tagID)", "DBNAMETOID(RDBS_tagType)") values(?1, "STRINGIZE(RDBS_TYPE_TAG)");")) == NULL)
		goto fail;
	else
		stage++;
	
	if((output->addType = createRequest(_cache, "INSERT INTO "TABLE_NAME_TAG"("DBNAMETOID(RDB_tagID)", "DBNAMETOID(RDBS_tagType)") values(?1, "STRINGIZE(RDBS_TYPE_CAT)");")) == NULL)
		goto fail;
	else
		stage++;
	
	if((output->getAuthorID = createRequest(_cache, "SELECT "DBNAMETOID(RDB_ID)" FROM "TABLE_NAME_AUTHOR" WHERE "DBNAMETOID(RDB_authors)" = ?1;")) == NULL)
		goto fail;
	else
		stage++;
	
	if((output->getTagID = createRequest(_cache, "SELECT "DBNAMETOID(RDB_ID)" FROM "TABLE_NAME_TAG" WHERE "DBNAMETOID(RDBS_tagType)" = "STRINGIZE(RDBS_TYPE_TAG)" AND "DBNAMETOID(RDB_tagID)" = ?1;")) == NULL)
		goto fail;
	else
		stage++;
	
	if((output->getTypeID = createRequest(_cache, "SELECT "DBNAMETOID(RDB_ID)" FROM "TABLE_NAME_TAG" WHERE "DBNAMETOID(RDBS_tagType)" = "STRINGIZE(RDBS_TYPE_CAT)" AND "DBNAMETOID(RDB_tagID)" = ?1;")) == NULL)
		goto fail;
	else
		stage++;
	
	if((output->addProject = createRequest(_cache, "INSERT INTO "TABLE_NAME_CORRES" ("DBNAMETOID(RDB_ID)", "DBNAMETOID(RDBS_dataID)", "DBNAMETOID(RDBS_dataType)") values(?1, ?2, ?3);")) == NULL)
		goto fail;
	else
		stage++;

	if((output->updateProject = createRequest(_cache, "UPDATE "TABLE_NAME_CORRES" SET "DBNAMETOID(RDBS_dataID)" = ?2 WHERE "DBNAMETOID(RDB_ID)" = ?1 AND "DBNAMETOID(RDBS_dataType)" = ?3;")) == NULL)
		goto fail;
	else
		stage++;
	
	if((output->removeProject = createRequest(_cache, "DELETE FROM "TABLE_NAME_CORRES" WHERE "DBNAMETOID(RDB_ID)" = ?1; DELETE FROM "FTS_TABLE" WHERE "DBNAMETOID(RDB_FTS_CACHEID)" = ?1")) == NULL)
		goto fail;
	else
		stage++;
	
	if((output->flushCategories = createRequest(_cache, "DELETE FROM "TABLE_NAME_CORRES" WHERE "DBNAMETOID(RDB_ID)" = ?1 AND "DBNAMETOID(RDBS_dataType)" = "STRINGIZE(RDBS_TYPE_CAT)";")) == NULL)
		goto fail;
	else
		stage++;
	
	if((output->readProject = createRequest(_cache, "SELECT "DBNAMETOID(RDBS_dataID)", "DBNAMETOID(RDBS_dataType)" FROM "TABLE_NAME_CORRES" WHERE "DBNAMETOID(RDB_ID)" = ?1;")) == NULL)
		goto fail;
	else
		stage++;
	
	if((output->addString = createRequest(_cache, "INSERT INTO "FTS_TABLE" ("DBNAMETOID(RDB_FTS_CACHEID)", "DBNAMETOID(RDB_FTS_REAL_CODE)", "DBNAMETOID(RDB_FTS_STRING)") values (?1, "STRINGIZE(RDB_FTS_CODE_NAME)", ?2), (?1, "STRINGIZE(RDB_FTS_CODE_AUTHOR)", ?3), (?1, "STRINGIZE(RDB_FTS_CODE_DESCRIPTION)", ?4)")) == NULL)
		goto fail;
	else
		stage++;
	
	if((output->updateString = createRequest(_cache, "UPDATE "FTS_TABLE" SET "DBNAMETOID(RDB_FTS_STRING)" = ?2 WHERE "DBNAMETOID(RDB_FTS_CACHEID)" = ?1 AND "DBNAMETOID(RDB_FTS_REAL_CODE)" = "STRINGIZE(RDB_FTS_CODE_NAME)"; UPDATE "FTS_TABLE" SET "DBNAMETOID(RDB_FTS_STRING)" = ?3 WHERE "DBNAMETOID(RDB_FTS_CACHEID)" = ?1 AND "DBNAMETOID(RDB_FTS_REAL_CODE)" = "STRINGIZE(RDB_FTS_CODE_AUTHOR)"; UPDATE "FTS_TABLE" SET "DBNAMETOID(RDB_FTS_STRING)" = ?4 WHERE "DBNAMETOID(RDB_FTS_CACHEID)" = ?1 AND "DBNAMETOID(RDB_FTS_REAL_CODE)" = "STRINGIZE(RDB_FTS_CODE_DESCRIPTION)";")) == NULL)
		goto fail;
	else
		stage++;
	
	if(0)
	{
fail:
		if(stage > 0)	destroyRequest(output->addAuthor);
		if(stage > 1)	destroyRequest(output->addTag);
		if(stage > 2)	destroyRequest(output->addType);
		if(stage > 3)	destroyRequest(output->getAuthorID);
		if(stage > 4)	destroyRequest(output->getTagID);
		if(stage > 5)	destroyRequest(output->getTypeID);
		if(stage > 6)	destroyRequest(output->addProject);
		if(stage > 7)	destroyRequest(output->updateProject);
		if(stage > 8)	destroyRequest(output->removeProject);
		if(stage > 9)	destroyRequest(output->flushCategories);
		if(stage > 10)	destroyRequest(output->readProject);
		if(stage > 11)	destroyRequest(output->addString);
		
		free(output);
		output = NULL;
		
#ifdef EXTENSIVE_LOGGING
		logR("Failed while building the request table for searching: %s", sqlite3_errmsg(_cache));
#endif
	}
	
	return output;
}

void flushSearchJumpTable(void * _table)
{
	SEARCH_JUMPTABLE table = _table;
	
	if(table == NULL)
		return;
	
	destroyRequest(table->addAuthor);
	destroyRequest(table->addTag);
	destroyRequest(table->addType);
	destroyRequest(table->getAuthorID);
	destroyRequest(table->getTagID);
	destroyRequest(table->getTypeID);
	destroyRequest(table->addProject);
	destroyRequest(table->updateProject);
	destroyRequest(table->removeProject);
	destroyRequest(table->flushCategories);
	destroyRequest(table->readProject);
	destroyRequest(table->addString);
	destroyRequest(table->updateString);
	
	free(table);
}

#pragma mark - Manipulate the content

uint getFromSearch(void * _table, byte type, PROJECT_DATA project)
{
	return _getFromSearch(_table, type, type == PULL_SEARCH_AUTHORID ? (void*) &(project.authorName) : (type == PULL_SEARCH_TAGID ? &(project.mainTag) : &(project.category)));
}

uint getIDForTag(byte type, uint code)
{
	return _getFromSearch(NULL, type, &code);
}

uint _getFromSearch(void * _table, byte type, void * data)
{
	SEARCH_JUMPTABLE table = _table;

	if(_table == NULL)
	{
		table = buildSearchJumpTable(cache);
		
		if(table == NULL)
			return UINT_MAX;
	}
	
	sqlite3_stmt * request = NULL;
	
	switch (type)
	{
		case PULL_SEARCH_AUTHORID:
		{
			request = table->getAuthorID;
			
			size_t length = wstrlen((charType *) data);
			char utf8[4 * length + 1];
			length = wchar_to_utf8((charType *) data, length, utf8, 4 * length + 1, 0);
			
			sqlite3_bind_text(request, 1, utf8, (int32_t) length, SQLITE_TRANSIENT);
			break;
		}
			
		case PULL_SEARCH_TAGID:
		{
			request = table->getTagID;
			sqlite3_bind_int64(request, 1, *(uint *) data);
			break;
		}
			
		case PULL_SEARCH_CATID:
		{
			request = table->getTypeID;
			sqlite3_bind_int64(request, 1, *(uint *) data);
			break;
		}
			
		default:
		{
			return UINT_MAX;
		}
	}
	
	uint output = UINT_MAX;
	
	if((output = (uint) sqlite3_step(request)) == SQLITE_ROW)
		output = (uint32_t) sqlite3_column_int(request, 0);
	else
		output = UINT_MAX;
	
	sqlite3_reset(request);
	
	if(_table == NULL)
		flushSearchJumpTable(table);
	
	return output;
}

bool _insertUpdateStringsInSearch(SEARCH_JUMPTABLE table, bool wantInsert, PROJECT_DATA project)
{
	bool output;
	sqlite3_stmt * request = wantInsert ? table->addString : table->updateString;
	
	size_t lengthProjectName = wstrlen(project.projectName), lengthAuthor = wstrlen(project.authorName), lengthDescription = wstrlen(project.description);
	char utf8ProjectName[4 * lengthProjectName + 1],  utf8Author[4 * lengthAuthor + 1],  utf8Description[4 * lengthDescription + 1];

	lengthProjectName = wchar_to_utf8(project.projectName, lengthProjectName, utf8ProjectName, 4 * lengthProjectName + 1, 0);
	lengthAuthor = wchar_to_utf8(project.authorName, lengthAuthor, utf8Author, 4 * lengthAuthor + 1, 0);
	lengthDescription = wchar_to_utf8(project.description, lengthDescription, utf8Description, 4 * lengthDescription + 1, 0);
	
	sqlite3_bind_int(request, 1, (int32_t) project.cacheDBID);
	sqlite3_bind_text(request, 2, utf8ProjectName, (int32_t) lengthProjectName, SQLITE_STATIC);
	sqlite3_bind_text(request, 3, utf8Author, (int32_t) lengthAuthor, SQLITE_STATIC);
	sqlite3_bind_text(request, 4, utf8Description, (int32_t) lengthDescription, SQLITE_STATIC);

	output = sqlite3_step(request) == SQLITE_DONE;
	
	sqlite3_reset(request);
	
	return output;
}

bool insertInSearch(void * _table, byte type, PROJECT_DATA project)
{
	SEARCH_JUMPTABLE table = _table;
	
	if(_table == NULL)
	{
		table = buildSearchJumpTable(cache);

		if(table == NULL)
			return false;
	}

	if(type == INSERT_PROJECT)
	{
		bool output = manipulateProjectSearch(table, true, project) && _insertUpdateStringsInSearch(table, true, project);
		
		if(_table == NULL)
			flushSearchJumpTable(table);
		
		return output;
	}
	
	sqlite3_stmt * request = NULL;
	byte requestType;
	
	switch (type)
	{
		case INSERT_AUTHOR:
		{
			requestType = RDBS_TYPE_AUTHOR;
			request = table->addAuthor;
			
			size_t length = wstrlen(project.authorName);
			char utf8[4 * length + 1];
			length = wchar_to_utf8(project.authorName, length, utf8, 4 * length + 1, 0);
			
			sqlite3_bind_text(request, 1, utf8, (int32_t) length, SQLITE_TRANSIENT);
			break;
		}
			
		case INSERT_TAG:
		{
			requestType = RDBS_TYPE_TAG;
			request = table->addTag;
			sqlite3_bind_int64(request, 1, project.mainTag);
			break;
		}
			
		case INSERT_CAT:
		{
			requestType = RDBS_TYPE_CAT;
			request = table->addType;
			sqlite3_bind_int64(request, 1, project.category);
			break;
		}
			
		default:
		{
			return false;
		}
	}
	
	bool output = sqlite3_step(request) == SQLITE_DONE;
	
	sqlite3_reset(request);
	
	if(_table == NULL)
		flushSearchJumpTable(table);
	
	if(output)
		updateElementCount(requestType, 1);

	return output;
}

bool removeFromSearch(void * _table, PROJECT_DATA project)
{
	SEARCH_JUMPTABLE table = _table;
	
	if(_table == NULL)
	{
		table = buildSearchJumpTable(cache);
		
		if(table == NULL)
			return false;
	}
	
	//We copy the various ID to check if we need to delete them afterward
	uint authorID = getFromSearch(table, PULL_SEARCH_AUTHORID, project);
	uint catID = getFromSearch(table, PULL_SEARCH_CATID, project);
	uint tagID = getFromSearch(table, PULL_SEARCH_TAGID, project);

	sqlite3_stmt * request = table->removeProject;
	sqlite3_bind_int(request, 1, (int32_t) project.cacheDBID);

	bool output = sqlite3_step(request) == SQLITE_DONE;
	
	sqlite3_reset(request);
	
	if(_table == NULL)
		flushSearchJumpTable(table);
	
	checkIfRemainingAndDelete(authorID, RDBS_TYPE_AUTHOR);
	checkIfRemainingAndDelete(catID, RDBS_TYPE_CAT);
	checkIfRemainingAndDelete(tagID, RDBS_TYPE_TAG);
	
	return output;
}

bool updateProjectSearch(void * _table, PROJECT_DATA project)
{
	SEARCH_JUMPTABLE table = _table;
	
	if(_table == NULL)
	{
		table = buildSearchJumpTable(cache);
		
		if(table == NULL)
			return false;
	}

	bool output = manipulateProjectSearch(table, false, project) & _insertUpdateStringsInSearch(table, false, project);
	
	if(_table == NULL)
		flushSearchJumpTable(table);

	return output;
}

bool manipulateProjectSearch(SEARCH_JUMPTABLE table, bool wantInsert, PROJECT_DATA project)
{
	uint catID = getFromSearch(table, PULL_SEARCH_CATID, project), tagID = getFromSearch(table, PULL_SEARCH_TAGID, project), authorID = getFromSearch(table, PULL_SEARCH_AUTHORID, project);
	uint oldCat, oldTag, oldAuthor;
	
	getProjectSearchData(table, project.cacheDBID, &oldAuthor, &oldTag, &oldCat);
	
	if(catID == UINT_MAX && insertInSearch(table, INSERT_CAT, project))
		catID = getFromSearch(table, PULL_SEARCH_CATID, project);
	
	if(tagID == UINT_MAX && insertInSearch(table, INSERT_TAG, project))
		tagID = getFromSearch(table, PULL_SEARCH_TAGID, project);
	
	if(authorID == UINT_MAX && insertInSearch(table, INSERT_AUTHOR, project))
		authorID = getFromSearch(table, PULL_SEARCH_AUTHORID, project);
	
	if(catID == UINT_MAX || tagID == UINT_MAX || authorID == UINT_MAX)
		return false;
	
	bool fail = false;
	sqlite3_stmt * request = wantInsert ? table->addProject : table->updateProject;

	if(authorID != oldAuthor)
	{
		sqlite3_bind_int(request, 1, (int32_t) project.cacheDBID);
		sqlite3_bind_int(request, 2, (int32_t) authorID);
		sqlite3_bind_int(request, 3, RDBS_TYPE_AUTHOR);
		
		fail = sqlite3_step(request) != SQLITE_DONE;
		sqlite3_reset(request);
		
		if(fail)
			return false;

		checkIfRemainingAndDelete(oldAuthor, RDBS_TYPE_AUTHOR);
	}

	if(catID != oldCat)
	{
		if(!wantInsert)
		{
			//We have to flush the previous category (as all parents are there)
			sqlite3_bind_int(table->flushCategories, 1, (int32_t) project.cacheDBID);
			sqlite3_step(table->flushCategories);
			sqlite3_reset(table->flushCategories);
		}
		
		//Insert the catID and its parents
		while (!fail && catID != CAT_NO_VALUE)
		{
			sqlite3_bind_int(request, 1, (int32_t) project.cacheDBID);
			sqlite3_bind_int(request, 2, (int32_t) catID);
			sqlite3_bind_int(request, 3, RDBS_TYPE_CAT);
			
			fail = sqlite3_step(request) != SQLITE_DONE;
			sqlite3_reset(request);
			
			if(!fail)
				catID = getRootCategoryIDForID(catID);
		}
		
		if(fail)
			return false;
		
		checkIfRemainingAndDelete(oldCat, RDBS_TYPE_CAT);
	}
	
	if(tagID != oldTag)
	{
		sqlite3_bind_int(request, 1, (int32_t) project.cacheDBID);
		sqlite3_bind_int(request, 2, (int32_t) tagID);
		sqlite3_bind_int(request, 3, RDBS_TYPE_TAG);
		
		fail = sqlite3_step(request) != SQLITE_DONE;
		sqlite3_reset(request);
		
		checkIfRemainingAndDelete(oldTag, RDBS_TYPE_TAG);
	}
	
	if(wantInsert && !fail)
	{
		sqlite3_bind_int(request, 1, (int32_t) project.cacheDBID);
		sqlite3_bind_int64(request, 2, (int64_t) getRepoID(project.repo));
		sqlite3_bind_int(request, 3, RDBS_TYPE_SOURCE);
		
		fail = sqlite3_step(request) != SQLITE_DONE;
		sqlite3_reset(request);
	}

	return !fail;
}

#pragma mark - Manipulate tags

bool insertRestriction(uint64_t code, byte type)
{
	if(cache == NULL || code == UINT_MAX || (type != RDBS_TYPE_AUTHOR && type != RDBS_TYPE_SOURCE && type != RDBS_TYPE_TAG && type != RDBS_TYPE_CAT) || haveRestriction(code, type))
		return false;
	
	sqlite3_stmt * request;
	
	if((request = createRequest(cache, "SELECT COUNT() FROM "TABLE_NAME_RESTRICTIONS" WHERE "DBNAMETOID(RDBS_dataType)" = ?1 AND "DBNAMETOID(RDBS_dataID)" = ?2 LIMIT 1")) == NULL)
		return false;
	
	sqlite3_bind_int(request, 1, type);
	sqlite3_bind_int64(request, 2, (int64_t) code);
	
	if(sqlite3_step(request) != SQLITE_ROW || sqlite3_column_int(request, 0) != 0)
	{
		destroyRequest(request);
		return false;
	}
	
	destroyRequest(request);

	if((request = createRequest(cache, "INSERT INTO "TABLE_NAME_RESTRICTIONS" ("DBNAMETOID(RDBS_dataType)", "DBNAMETOID(RDBS_dataID)") values(?1, ?2);")) == NULL)
		return false;
	
	sqlite3_bind_int(request, 1, type);
	sqlite3_bind_int64(request, 2, (int64_t) code);
	
	bool output = sqlite3_step(request) == SQLITE_DONE;
	
	destroyRequest(request);
	
	if(output)
		updateRestrictionCount(type, 1);
	
	notifyRestrictionChanged();
	
	return output;
}

bool haveRestriction(uint64_t code, byte type)
{
	if(cache == NULL || code == UINT_MAX || (type != RDBS_TYPE_AUTHOR && type != RDBS_TYPE_SOURCE && type != RDBS_TYPE_TAG && type != RDBS_TYPE_CAT))
		return false;
	
	sqlite3_stmt * request;
	
	if((request = createRequest(cache, "SELECT COUNT() FROM "TABLE_NAME_RESTRICTIONS" WHERE "DBNAMETOID(RDBS_dataType)" = ?1 AND "DBNAMETOID(RDBS_dataID)" = ?2;")) == NULL)
		return false;
	
	sqlite3_bind_int(request, 1, type);
	sqlite3_bind_int64(request, 2, (int64_t) code);
	
	bool output = sqlite3_step(request) == SQLITE_ROW && (uint32_t) sqlite3_column_int(request, 0) >= 1;
	
	destroyRequest(request);

	return output;
}

bool removeRestriction(uint64_t code, byte type)
{
	if(cache == NULL || code == UINT_MAX || (type != RDBS_TYPE_AUTHOR && type != RDBS_TYPE_SOURCE && type != RDBS_TYPE_TAG && type != RDBS_TYPE_CAT))
		return false;
	
	sqlite3_stmt * request;
	
	if((request = createRequest(cache, "DELETE FROM "TABLE_NAME_RESTRICTIONS" WHERE "DBNAMETOID(RDBS_dataType)" = ?1 AND "DBNAMETOID(RDBS_dataID)" = ?2;")) == NULL)
		return false;
	
	sqlite3_bind_int(request, 1, type);
	sqlite3_bind_int64(request, 2, (int64_t) code);
	
	bool output = sqlite3_step(request) == SQLITE_DONE;
	
	destroyRequest(request);
	
	if(output)
		updateRestrictionCount(type, -1);
	
	notifyRestrictionChanged();
	
	return output;
}

bool flushRestriction()
{
	if(cache == NULL)
		return false;
	
	sqlite3_stmt * request;
	
	if((request = createRequest(cache, "DELETE FROM "TABLE_NAME_RESTRICTIONS";")) == NULL)
		return false;
	
	bool output = sqlite3_step(request) == SQLITE_DONE;
	
	destroyRequest(request);
	
	notifyRestrictionChanged();
	
	return output;
}

#pragma mark - Maintenance API

uint64_t getSessionForType(byte type)
{
	switch (type)
	{
		case RDBS_TYPE_AUTHOR:
			return sessionAuthor;
			
		case RDBS_TYPE_TAG:
			return sessionTag;
			
		case RDBS_TYPE_CAT:
			return sessionType;
	}
	
	return INVALID_VALUE;
}

void updateElementCount(byte type, int change)
{
	switch (type)
	{
		case RDBS_TYPE_AUTHOR:
		{
			nbAuthor += change;
			++sessionAuthor;
			break;
		}
			
		case RDBS_TYPE_TAG:
		{
			nbTag += change;
			++sessionTag;
			break;
		}
			
		case RDBS_TYPE_CAT:
		{
			nbCat += change;
			++sessionType;
			break;
		}
	}
}

void updateRestrictionCount(byte type, int change)
{
	switch (type)
	{
		case RDBS_TYPE_AUTHOR:
		{
			nbRestrictionAuthor += change;
			break;
		}
			
		case RDBS_TYPE_TAG:
		{
			nbRestrictionTag += change;
			break;
		}
			
		case RDBS_TYPE_CAT:
		{
			nbRestrictionCat += change;
			break;
		}
			
		case RDBS_TYPE_SOURCE:
		{
			nbRestrictionSource += change;
			break;
		}
	}
}

void checkIfRemainingAndDelete(uint data, byte type)
{
	if(cache == NULL || data == UINT_MAX)
		return;
	
	sqlite3_stmt * request = createRequest(cache, "SELECT COUNT() FROM "TABLE_NAME_CORRES" WHERE "DBNAMETOID(RDBS_dataID)" = ?1 AND "DBNAMETOID(RDBS_dataType)" = ?2;");
	
	if(request == NULL)
		return;
	
	sqlite3_bind_int64(request, 1, data);
	sqlite3_bind_int(request, 2, type);
	
	int retValue = sqlite3_step(request);
	bool nothingRemaining = retValue == SQLITE_DONE || (retValue == SQLITE_ROW && sqlite3_column_int(request, 0) == 0);
	
	destroyRequest(request);
	
	//We have to delete the entry
	if(nothingRemaining)
	{
		if(type == RDBS_TYPE_AUTHOR && (request = createRequest(cache, "DELETE FROM "TABLE_NAME_AUTHOR" WHERE "DBNAMETOID(RDB_ID)" = ?1")) != NULL);

		else if(type == RDBS_TYPE_TAG && (request = createRequest(cache, "DELETE FROM "TABLE_NAME_TAG" WHERE "DBNAMETOID(RDB_ID)" = ?1 AND "DBNAMETOID(RDBS_tagType)" = "STRINGIZE(RDBS_TYPE_TAG)"")) != NULL);
		
		else if(type == RDBS_TYPE_CAT && (request = createRequest(cache, "DELETE FROM "TABLE_NAME_TAG" WHERE "DBNAMETOID(RDB_ID)" = ?1 AND "DBNAMETOID(RDBS_tagType)" = "STRINGIZE(RDBS_TYPE_CAT)"")) != NULL);
		
		else
			return;
		
		sqlite3_bind_int(request, 1, (int32_t) data);
		
		if(sqlite3_step(request) == SQLITE_DONE)
			updateElementCount(type, -1);
			
		destroyRequest(request);
	}
}

#pragma mark - Read and work on those data

bool getProjectSearchData(void * table, uint cacheID, uint * authorID, uint * tagID, uint * typeID)
{
	if(authorID == NULL || tagID == NULL || typeID == NULL)
		return false;
	else
		*authorID = *tagID = *typeID = UINT_MAX;
	
	sqlite3_stmt * request;
	
	if(table != NULL)
		request = ((SEARCH_JUMPTABLE) table)->readProject;
	else
	{
		if((request = createRequest(cache, "SELECT "DBNAMETOID(RDBS_dataID)", "DBNAMETOID(RDBS_dataType)" FROM "TABLE_NAME_CORRES" WHERE "DBNAMETOID(RDB_ID)" = ?1;")) == NULL)
			return false;
	}

	sqlite3_bind_int(request, 1, (int32_t) cacheID);

	while(sqlite3_step(request) == SQLITE_ROW)
	{
		uint type = (uint32_t) sqlite3_column_int(request, 1), data = (uint32_t) sqlite3_column_int(request, 0);
		
		if(type == RDBS_TYPE_AUTHOR)
			*authorID = data;

		else if(type == RDBS_TYPE_TAG)
			*tagID = data;
		
		else if(type == RDBS_TYPE_CAT)
			*typeID = data;
	}

	sqlite3_reset(request);
	
	if(table == NULL)
		destroyRequest(request);
	
	return true;
}

uint64_t * getSearchData(byte type, charType *** dataName, uint * dataLength)
{
	if(dataName == NULL || dataLength == NULL || cache == NULL)
		return NULL;
	
	sqlite3_stmt * request = NULL;

	if(type == RDBS_TYPE_AUTHOR)
	{
		*dataLength = nbAuthor;
		request = createRequest(cache, "SELECT * FROM "TABLE_NAME_AUTHOR" ORDER BY "DBNAMETOID(RDB_authors)" COLLATE "SORT_FUNC" ASC;");
	}
	else if(type == RDBS_TYPE_TAG)
	{
		*dataLength = nbTag;
		request = createRequest(cache, "SELECT "DBNAMETOID(RDB_tagID)", "DBNAMETOID(RDB_ID)" FROM "TABLE_NAME_TAG" WHERE "DBNAMETOID(RDBS_tagType)" = "STRINGIZE(RDBS_TYPE_TAG)";");
	}
	else if(type == RDBS_TYPE_CAT)
	{
		*dataLength = nbCat;
		request = createRequest(cache, "SELECT "DBNAMETOID(RDB_tagID)", "DBNAMETOID(RDB_ID)" FROM "TABLE_NAME_TAG" WHERE "DBNAMETOID(RDBS_tagType)" = "STRINGIZE(RDBS_TYPE_CAT)";");
	}
	
	if(request == NULL)
		return NULL;
	
	uint pos = 0, length = *dataLength;
	uint64_t * codes = malloc(length * sizeof(uint64_t));
	*dataName = malloc(length * sizeof(charType *));
	
	if(codes == NULL || *dataName == NULL)
	{
		free(codes);
		free(*dataName);	*dataName = NULL;
		
		destroyRequest(request);
		return NULL;
	}
	
	while(pos < length && sqlite3_step(request) == SQLITE_ROW)
	{
		if(type == RDBS_TYPE_AUTHOR)
			(*dataName)[pos] = getStringFromUTF8(sqlite3_column_text(request, 0));

		else if(type == RDBS_TYPE_CAT)
			(*dataName)[pos] = wstrdup(getCatNameForCode((uint32_t) sqlite3_column_int(request, 0)));

		else
			(*dataName)[pos] = wstrdup(getTagNameForCode((uint32_t) sqlite3_column_int(request, 0)));

		if((*dataName)[pos] != NULL)
			codes[pos++] = (uint64_t) sqlite3_column_int64(request, 1);
	}
	
	destroyRequest(request);

	if(*dataLength != pos)
		*dataLength = pos;
	
	return codes;
}

#pragma mark - Most highlevel API

uint * _copyDataForRequest(sqlite3_stmt * request, uint * nbElemOutput)
{
	const uint maxLength = getDBCount();
	uint realLength = 0, data[maxLength];
	
	while (realLength < maxLength && sqlite3_step(request) == SQLITE_ROW)
	{
		data[realLength++] = (uint32_t) sqlite3_column_int(request, 0);
	}
	
	*nbElemOutput = 0;
	
	if(realLength == 0)
		return NULL;

	uint * output = malloc(realLength * sizeof(uint));
	if(output != NULL)
	{
		memcpy(output, data, realLength * sizeof(uint));
		*nbElemOutput = realLength;
	}
	
	return output;
}

uint * _getIDForRestriction(const char * categoryName, uint nbItemInCategory, bool wantAND, const char * additionnalRequest, const char * searchString, uint * nbElemOutput)
{
	if(additionnalRequest == NULL)
		additionnalRequest = "";
	
	if(nbElemOutput != NULL)
		*nbElemOutput = 0;
	
	char requestString[1024 + strlen(additionnalRequest)];
	
	if(categoryName != NULL)
	{
		if(wantAND)
		{
			snprintf(requestString, sizeof(requestString), "SELECT list."DBNAMETOID(RDB_ID)" FROM "TABLE_NAME_CORRES" AS list, "TABLE_NAME_RESTRICTIONS" AS rest, "MAIN_CACHE" AS cache, "FTS_TABLE" AS fts WHERE rest."DBNAMETOID(RDBS_dataType)" = %s AND list."DBNAMETOID(RDBS_dataType)" = %s AND list."DBNAMETOID(RDBS_dataID)" = rest."DBNAMETOID(RDBS_dataID)" %s GROUP BY list."DBNAMETOID(RDB_ID)" HAVING COUNT(list."DBNAMETOID(RDB_ID)") >= %d ORDER BY list."DBNAMETOID(RDB_ID)" ASC;", categoryName, categoryName, additionnalRequest, nbItemInCategory);
		}
		else
		{
			snprintf(requestString, sizeof(requestString), "SELECT DISTINCT list."DBNAMETOID(RDB_ID)" FROM "TABLE_NAME_CORRES" AS list, "TABLE_NAME_RESTRICTIONS" AS rest, "MAIN_CACHE" AS cache, "FTS_TABLE" AS fts WHERE rest."DBNAMETOID(RDBS_dataType)" = %s AND list."DBNAMETOID(RDBS_dataType)" = %s AND list."DBNAMETOID(RDBS_dataID)" = rest."DBNAMETOID(RDBS_dataID)" %s ORDER BY list."DBNAMETOID(RDB_ID)" ASC", categoryName, categoryName, additionnalRequest);
		}
	}
	else if(additionnalRequest[0] != 0)		//Not an empty request
	{
		while (*additionnalRequest == ' ')									additionnalRequest++;
		while (*additionnalRequest != ' ' && *additionnalRequest != 0)		additionnalRequest++;
		
		if(*additionnalRequest == 0)
			return NULL;
		
		snprintf(requestString, sizeof(requestString), "SELECT DISTINCT cache."DBNAMETOID(RDB_ID)" FROM "MAIN_CACHE" AS cache, "FTS_TABLE" AS fts WHERE %s ORDER BY cache."DBNAMETOID(RDB_ID)" ASC", additionnalRequest);
	}
	else
		snprintf(requestString, sizeof(requestString), "SELECT "DBNAMETOID(RDB_ID)" FROM "MAIN_CACHE" AS cache ORDER BY "DBNAMETOID(RDB_ID)" ASC");
	
	sqlite3_stmt * request = createRequest(cache, requestString);
	if(request == NULL)
		return NULL;
	
	if(searchString != NULL)
	{
		uint length = strlen(searchString);
		char copySearchString[length + 3];
		
		memcpy(&copySearchString[1], searchString, length * sizeof(char));
		copySearchString[0] = copySearchString[length + 1] = '*';
		copySearchString[length + 2] = 0;
		
		sqlite3_bind_text(request, 1, copySearchString, -1, SQLITE_TRANSIENT);
	}
	
	void * output = _copyDataForRequest(request, nbElemOutput);
	
	destroyRequest(request);

	return output;
}

uint * getFilteredProject(uint * dataLength, const char * searchQuery, bool wantInstalledOnly, bool wantFreeOnly, bool wantFavsOnly)
{
	if(dataLength == NULL)
		return NULL;
	else
		*dataLength = UINT_MAX;
	
	const size_t maxLength = getDBCount();
	uint * output = malloc(maxLength * sizeof(uint));	//We allocate more space, but will reduce at the end
	
	if(output == NULL)
		return NULL;
	
	//Current recipe: AUTHOR(|) AND SOURCE(|) AND TYPE(|) AND TAG(&)
	
	uint searchLength = searchQuery == NULL ? 0 : strlen(searchQuery);
	bool haveAdditionnalRequest = false;
	char additionnalRequest[256];	additionnalRequest[0] = 0;

	//We craft the additional parts of the request
	if(searchLength || wantInstalledOnly || wantFreeOnly || wantFavsOnly)
	{
		if(searchLength)
		{
			if(nbRestrictionSource || nbRestrictionAuthor || nbRestrictionCat || nbRestrictionTag)
				snprintf(additionnalRequest, sizeof(additionnalRequest), " AND list."DBNAMETOID(RDB_ID)" = fts."DBNAMETOID(RDB_FTS_CACHEID)" AND fts."DBNAMETOID(RDB_FTS_STRING)" MATCH ?1");
			else
				snprintf(additionnalRequest, sizeof(additionnalRequest), " AND cache."DBNAMETOID(RDB_ID)" = fts."DBNAMETOID(RDB_FTS_CACHEID)" AND fts."DBNAMETOID(RDB_FTS_STRING)" MATCH ?1");
		}
		
		if(wantFavsOnly)
		{
			uint currentLength = strlen(additionnalRequest);
			snprintf(&(additionnalRequest[currentLength]), sizeof(additionnalRequest) - currentLength, " AND cache."DBNAMETOID(RDB_favoris)" = 1");
		}
		
		if(wantFreeOnly)
		{
			uint currentLength = strlen(additionnalRequest);
			snprintf(&(additionnalRequest[currentLength]), sizeof(additionnalRequest) - currentLength, " AND cache."DBNAMETOID(RDB_isPaid)" = 0");
		}
		
		if(wantInstalledOnly)
		{
			uint currentLength = strlen(additionnalRequest);
			snprintf(&(additionnalRequest[currentLength]), sizeof(additionnalRequest) - currentLength, " AND cache."DBNAMETOID(RDB_isInstalled)" = 1");
		}
		
		haveAdditionnalRequest = true;
	}
	
	uint * intermediaryData[4] = {NULL}, nbElemInData[4] = {0}, dataCount = 0;
	
	//We get the data for the various restrictions
	if(nbRestrictionAuthor)
	{
		intermediaryData[dataCount] = _getIDForRestriction(STRINGIZE(RDBS_TYPE_AUTHOR), nbRestrictionAuthor, false, haveAdditionnalRequest ? additionnalRequest : NULL, haveAdditionnalRequest ? searchQuery : NULL, &(nbElemInData[dataCount]));
		
		if(haveAdditionnalRequest)
			haveAdditionnalRequest = false;
		
		if(intermediaryData[dataCount] != NULL)
			dataCount++;
	}
	
	if(nbRestrictionSource)
	{
		intermediaryData[dataCount] = _getIDForRestriction(STRINGIZE(RDBS_TYPE_SOURCE), nbRestrictionSource, false, haveAdditionnalRequest ? additionnalRequest : NULL, haveAdditionnalRequest ? searchQuery : NULL, &(nbElemInData[dataCount]));
		
		if(haveAdditionnalRequest)
			haveAdditionnalRequest = false;
		
		if(intermediaryData[dataCount] != NULL)
			dataCount++;
	}
	
	if(nbRestrictionCat)
	{
		intermediaryData[dataCount] = _getIDForRestriction(STRINGIZE(RDBS_TYPE_CAT), nbRestrictionCat, false, haveAdditionnalRequest ? additionnalRequest : NULL, haveAdditionnalRequest ? searchQuery : NULL, &(nbElemInData[dataCount]));
		
		if(haveAdditionnalRequest)
			haveAdditionnalRequest = false;
		
		if(intermediaryData[dataCount] != NULL)
			dataCount++;
	}
	
	if(nbRestrictionTag)
	{
		intermediaryData[dataCount] = _getIDForRestriction(STRINGIZE(RDBS_TYPE_TAG), nbRestrictionTag, true, haveAdditionnalRequest ? additionnalRequest : NULL, haveAdditionnalRequest ? searchQuery : NULL, &(nbElemInData[dataCount]));
		
		if(haveAdditionnalRequest)
			haveAdditionnalRequest = false;
		
		if(intermediaryData[dataCount] != NULL)
			dataCount++;
	}
	
	//If there was no other restriction
	if(haveAdditionnalRequest || dataCount == 0)
	{
		intermediaryData[dataCount] = _getIDForRestriction(NULL, 0, false, additionnalRequest, searchQuery, &(nbElemInData[dataCount]));

		if(intermediaryData[dataCount] != NULL)
			dataCount++;
		else if(dataCount == 0)	//No data at all
		{
			*dataLength = 0;
			free(output);
			return NULL;
		}
	}
	
	//We find the largest array
	uint minCount = 0, indexSmallestArray = 0, indexInIntermediary[dataCount];
	for(uint i = 0; i < dataCount; ++i)
	{
		if(minCount > nbElemInData[i])
		{
			minCount = nbElemInData[i];
			indexSmallestArray = i;
		}
		
		indexInIntermediary[i] = 0;
	}
	
	//Array are all sorted, we want the ID appearing in all of them. We pick the smallest, then check that all its item appear in all the other items
	uint validateLength = 0;
	bool reachedEndOfAList = dataCount == 0, itemValidated;
	
	while(!reachedEndOfAList)
	{
		if(indexInIntermediary[indexSmallestArray] >= nbElemInData[indexSmallestArray])
			break;
		
		uint currentID = intermediaryData[indexSmallestArray][indexInIntermediary[indexSmallestArray]++];
		itemValidated = true;
		
		for(uint posInIntermediary = 0; posInIntermediary < dataCount; ++posInIntermediary)
		{
			//We don't have to compare with ourselves
			if(posInIntermediary == indexSmallestArray)
				continue;
			
			//We discard any data that is over the current item were evaluating
			while(indexInIntermediary[posInIntermediary] < nbElemInData[posInIntermediary] &&
				  currentID > intermediaryData[posInIntermediary][indexInIntermediary[posInIntermediary]])
				indexInIntermediary[posInIntermediary]++;
			
			//If a list is over, then none of the following data can be in all of them
			if(indexInIntermediary[posInIntermediary] >= nbElemInData[posInIntermediary])
			{
				reachedEndOfAList = true;
				break;
			}
			
			//If the item doesn't match, it's missing from this list
			if(currentID != intermediaryData[posInIntermediary][indexInIntermediary[posInIntermediary]])
			{
				itemValidated = false;
				break;
			}
		}
		
		//If the item is validated
		if(itemValidated)
		{
			output[validateLength++] = currentID;
		}
	}
	
	//Release the allocated data
	for(uint i = 0; i < dataCount; ++i)
		free(intermediaryData[i]);
	
	*dataLength = validateLength;

	if(validateLength < maxLength)
	{
		if(validateLength == 0)	//No data :/
		{
			free(output);
			return NULL;
		}
			
		void * tmp = realloc(output, validateLength * sizeof(uint));
		if(tmp != NULL)
			output = tmp;
	}
	
	return output;
}

SEARCH_SUGGESTION * getProjectNameWith(const char * partial, uint * nbProject, bool projectNameOnly)
{
	char requestText[256];
	const uint maxLength = getDBCount(), length = strlen(partial);

	SEARCH_SUGGESTION * output = calloc(maxLength, sizeof(SEARCH_SUGGESTION));
	if(output == NULL)
		return NULL;
	
	
	if(projectNameOnly)
		snprintf(requestText, sizeof(requestText), "SELECT "DBNAMETOID(RDB_FTS_STRING)", "DBNAMETOID(RDB_FTS_REAL_CODE)", "DBNAMETOID(RDB_FTS_CACHEID)" FROM "FTS_TABLE" WHERE "DBNAMETOID(RDB_FTS_REAL_CODE)" = "STRINGIZE(RDB_FTS_CODE_NAME)" AND "DBNAMETOID(RDB_FTS_STRING)" MATCH ?1 ORDER BY "DBNAMETOID(RDB_FTS_STRING)" COLLATE "SORT_FUNC_SEARCH" DESC");
	else
		//Two part request. First, we get the project and try to give them a higher RDB_FTS_REAL_CODE if the search have multiple hits (name & author)
		//	description is ignored in the computation
		//The second part excludes specifically the project name and try to bring up direct hit of authors
		snprintf(requestText, sizeof(requestText), "SELECT "DBNAMETOID(RDB_FTS_STRING)", SUM("DBNAMETOID(RDB_FTS_REAL_CODE)") AS "DBNAMETOID(RDB_FTS_REAL_CODE)", "DBNAMETOID(RDB_FTS_CACHEID)" FROM "FTS_TABLE" WHERE "DBNAMETOID(RDB_FTS_REAL_CODE)" != "STRINGIZE(RDB_FTS_CODE_DESCRIPTION)" AND "DBNAMETOID(RDB_FTS_STRING)" MATCH ?1 GROUP BY "DBNAMETOID(RDB_FTS_CACHEID)" UNION ALL SELECT "DBNAMETOID(RDB_FTS_STRING)", "DBNAMETOID(RDB_FTS_REAL_CODE)", "DBNAMETOID(RDB_FTS_CACHEID)" FROM "FTS_TABLE" WHERE "DBNAMETOID(RDB_FTS_REAL_CODE)" != "STRINGIZE(RDB_FTS_CODE_NAME)" AND "DBNAMETOID(RDB_FTS_STRING)" MATCH ?1 GROUP BY "DBNAMETOID(RDB_FTS_STRING)", "DBNAMETOID(RDB_FTS_REAL_CODE)" ORDER BY "DBNAMETOID(RDB_FTS_REAL_CODE)" DESC, "DBNAMETOID(RDB_FTS_STRING)" COLLATE "SORT_FUNC_SEARCH" ASC");
	
	sqlite3_stmt * request;
	
	if((request = createRequest(cache, requestText)) == NULL)
	{
		free(output);
		return NULL;
	}
	
	char copyString[length + 2];
	memcpy(&copyString[1], partial, length * sizeof(char));
	copyString[0] = copyString[length + 1] = '*';
	sqlite3_bind_text(request, 1, copyString, sizeof(copyString), SQLITE_STATIC);
	
	searchStringForCollate = &partial;
	
	size_t realLength = 0, maxEntries = MIN(maxLength, 100);
	while (realLength < maxEntries && sqlite3_step(request) == SQLITE_ROW)
	{
		output[realLength].type = (byte) sqlite3_column_int(request, 1);
		output[realLength].cacheDBID = (uint) sqlite3_column_int(request, 2);
		
		//If a project, the author name may be produced by the database instead of the project name
		//In this case, we must recover it with the cacheDBID
		if(output[realLength].type != RDB_FTS_CODE_AUTHOR)
		{
			uint i = 0, currentCacheValue = output[realLength].cacheDBID;
		
			//We don't want a duplicate
			for(; i < realLength; i++)
			{
				if(output[i].cacheDBID == currentCacheValue && output[i].type != RDB_FTS_CODE_AUTHOR)
					break;
			}
			
			if(i == realLength)
				output[realLength].string = getProjectNameByID(output[realLength].cacheDBID);
		}
		
		//There may be repetitions in the dataset, we reject them if we run into them
		else if(realLength == 0 || output[realLength - 1].cacheDBID != output[realLength].cacheDBID)
			output[realLength].string = getAuthorNameByID(output[realLength].cacheDBID);
		
		if(output[realLength].string != NULL)
			realLength++;
	}
	
	searchStringForCollate = NULL;
	
	destroyRequest(request);
	
	if(nbProject != NULL)
		*nbProject = realLength;
	
	return output;
}

uint getNbSeriesForAuthorOfID(uint cacheDBID)
{
	sqlite3_stmt * request = createRequest(cache, "SELECT COUNT() FROM "FTS_TABLE" WHERE "DBNAMETOID(RDB_FTS_REAL_CODE)" = "STRINGIZE(RDB_FTS_CODE_AUTHOR)" AND "DBNAMETOID(RDB_FTS_STRING)" MATCH (SELECT "DBNAMETOID(RDB_FTS_STRING)" FROM "FTS_TABLE" WHERE "DBNAMETOID(RDB_FTS_REAL_CODE)" = "STRINGIZE(RDB_FTS_CODE_AUTHOR)" AND "DBNAMETOID(RDB_FTS_CACHEID)" = ?1);");
	
	if(request == NULL)
		return 1;
	
	sqlite3_bind_int(request, 1, (int) cacheDBID);
	
	uint output;
	
	if(sqlite3_step(request) == SQLITE_ROW)
	{
		output = (uint) sqlite3_column_int64(request, 0);
		
		if(output == 0)
		{
			logR("Uhm? Tried to count the number of series for author but results don't make sense");
		}
	}
	else
		output = 1;
	
	destroyRequest(request);
	
	return output;
}

bool haveOneOrLessMatchForNameWith(const char * partial)
{
	bool oneOrLess = false;
	char requestText[200];
	uint length = strlen(partial);
	snprintf(requestText, sizeof(requestText), "SELECT COUNT() FROM "FTS_TABLE" WHERE "DBNAMETOID(RDB_FTS_REAL_CODE)" = "STRINGIZE(RDB_FTS_CODE_NAME)" AND "DBNAMETOID(RDB_FTS_STRING)" MATCH ?1");
	
	sqlite3_stmt * request;
	if(length > INT_MAX || (request = createRequest(cache, requestText)) == NULL)
		return false;
	
	char copyString[length + 2];
	memcpy(&copyString[1], partial, length * sizeof(char));
	copyString[0] = copyString[length + 1] = '*';

	sqlite3_bind_text(request, 1, copyString, sizeof(copyString), NULL);
	oneOrLess = (sqlite3_step(request) == SQLITE_ROW && sqlite3_column_int(request, 0) <= 1);
	
	destroyRequest(request);

	return oneOrLess;
}
