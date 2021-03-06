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

bool getRepoData(byte type, char * repoURL, char ** output, size_t * sizeOutput)
{
	if(type == 0 || type > MAX_TYPE_DEPOT || repoURL == NULL || output == NULL || sizeOutput == NULL)
		return false;

	if(type == TYPE_DEPOT_DB || type == TYPE_DEPOT_OTHER)
	{
		short versionRepo = VERSION_REPO;
		char fullURL[512];
		
		snprintf(fullURL, sizeof(fullURL), type == TYPE_DEPOT_DB ? "https://dl.dropboxusercontent.com/u/%s/rakshata-repo-%d" : "http://%s/rakshata-repo-%d", repoURL, versionRepo);
		download_mem(fullURL, NULL, output, sizeOutput, type == TYPE_DEPOT_PAID ? SSL_ON : SSL_OFF);
	}
	else
	{
		char fullURL[64];
		snprintf(fullURL, sizeof(fullURL), "http://goo.gl/%s", repoURL);
		download_mem(fullURL, NULL, output, sizeOutput, SSL_OFF);
	}
	
	return isDownloadValid(*output);
}

void * enforceRepoExtra(ROOT_REPO_DATA * root, bool getRidOfThemAfterward)
{
	if(!root->subRepoAreExtra)
		return NULL;
	
	ICONS_UPDATE * begin = NULL, * current, * new;
	REPO_DATA_EXTRA * data = (void *) root->subRepo;
	uint nbSubRepo = root->nbSubrepo;
	char rootPath[64], imagePath[256], crcHash[LENGTH_CRC];
	
	if(nbSubRepo == 0)
		return NULL;
	
	for(uint i = 0; i < nbSubRepo; i++)
	{
		//Check if there is any data
		if(!data[i].data->active || !data[i].URLImage[0])
			continue;
		
		//We create the file path
		char * encodedHash = getPathForRepo(data[i].data);
		if(encodedHash == NULL)
			continue;
		snprintf(rootPath, sizeof(rootPath), IMAGE_CACHE_DIR"/%s", encodedHash);
		createPath(rootPath);
		free(encodedHash);

		snprintf(imagePath, sizeof(imagePath), "%s/"REPO_IMG_NAME".png", rootPath);
		snprintf(crcHash, sizeof(crcHash), "%08x", crc32File(imagePath));
		
		if(!checkFileExist(imagePath) || strncmp(crcHash, data[i].hashImage, LENGTH_CRC))
		{
			new = calloc(1, sizeof(ICONS_UPDATE));
			if(new == NULL)
			{
				memoryError(sizeof(ICONS_UPDATE));
				continue;
			}
			
			//Copy the data
			new->URL = strdup(data[i].URLImage);
			new->filename = strdup(imagePath);
			
			if(new->URL == NULL || new->filename == NULL)
			{
				free(new->URL);
				free(new->filename);
				free(new);
				continue;
			}
		}
		else
			new = NULL;
		
		//We check for retina
		if(data[i].haveRetina)
		{
			//We check for update
			snprintf(imagePath, sizeof(imagePath), "%s/"REPO_IMG_NAME"@2x.png", rootPath);
			snprintf(crcHash, sizeof(crcHash), "%08x", crc32File(imagePath));
			
			if(!checkFileExist(imagePath) || strncmp(crcHash, data[i].hashImageRetina, LENGTH_CRC))
			{
				ICONS_UPDATE * retina = calloc(1, sizeof(ICONS_UPDATE));
				if(retina != NULL)
				{
					//Copy the data
					retina->URL = strdup(data[i].URLImageRetina);
					retina->filename = strdup(imagePath);
					
					if(retina->URL == NULL || retina->filename == NULL)
					{
						free(retina->URL);
						free(retina->filename);
						free(retina);
					}
					else if(new != NULL)
						new->next = retina;
					
					else
						new = retina;
				}
			}
		}
		
		if(new != NULL)
		{
			if(begin == NULL)
			{
				begin = new;
				if(new->next == NULL)
					current = new;
				else
					current = new->next;
			}
			else
			{
				current->next = new;
				if(new->next == NULL)
					current = new;
				else
					current = new->next;
			}
		}
	}
	
	if(getRidOfThemAfterward)
	{
		REPO_DATA * final = calloc(nbSubRepo, sizeof(REPO_DATA));
		
		for(uint i = 0; i < nbSubRepo; i++)
		{
			final[i] = *(((REPO_DATA_EXTRA *)root->subRepo)[i].data);
		}
		
		free(root->subRepo);
		root->subRepo = final;
		root->subRepoAreExtra = false;
	}
	
	return begin;
}

char * getPathForRepo(REPO_DATA * repo)
{
	char * output = calloc(20, sizeof(char));
	if(output != NULL)
	{
		if(isLocalRepo(repo))
			strncpy(output, LOCAL_PATH_NAME, 20);
		else
			snprintf(output, 20, "%x/%x", repo->parentRepoID, repo->repoID);
	}
	
	return output;
}

char * getPathForProject(PROJECT_DATA project)
{
	char * repoPath = getPathForRepo(project.repo);
	if(repoPath == NULL)
		return NULL;

	char rootPath[strlen(repoPath) + 20];

	//Craft the path with the project in it
	snprintf(rootPath, sizeof(rootPath), isLocalProject(project) ? "%s/"LOCAL_PATH_NAME"_%d" : "%s/%d", repoPath, project.projectID);
	free(repoPath);

	return strdup(rootPath);
}

char * getPathForRootRepo(ROOT_REPO_DATA * repo)
{
	if(repo == NULL)
		return NULL;
	
	char * output = calloc(10, sizeof(char));
	if(output != NULL)
	{
		snprintf(output, 10, "%x", repo->repoID);
	}
	
	return output;
}

byte defineTypeRepo(char *URL)
{
    int i = 0;
    if(strlen(URL) == 8) //SI DB, seulement 8 chiffres
    {
        while(i < 8 && isNbr(URL[i++]));
        if(i == 8) //Si que des chiffres
            return TYPE_DEPOT_DB;
    }
    else if(strlen(URL) == 5 || strlen(URL) == 6) //GOO.GL
        return TYPE_DEPOT_GOO;

	return TYPE_DEPOT_OTHER;
}
