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

void init_zmemfile(zlib_filefunc_def *inst, char *bufZip, char* mask, size_t length);
void destroy_zmemfile(zlib_filefunc_def *inst);

//Utils
bool checkNameFileZip(char * fileToTest)
{
	if(!strncmp(fileToTest, "__MACOSX", 8) || !strncmp(fileToTest, ".DS_Store", 9))	//Dossier parasite de OSX
		return false;
	
	//strlen(fileToTest) - 1 est le dernier caractère, strlen(fileToTest) donnant la longueur de la chaine
	uint posLastChar = strlen(fileToTest) - 1;
	
	if(fileToTest[posLastChar] == '/' 		//Si c'est un dossier, le dernier caractère est /
	   || (fileToTest[posLastChar - 3] == '.' && fileToTest[posLastChar - 2] == 'e' && fileToTest[posLastChar - 1] == 'x' && fileToTest[posLastChar] == 'e'))	//.exe
		return false;
	
	return true;
}

void minimizeString(char* input)
{
	for(; *input; input++)
	{
		if(*input >= 'A' && *input <= 'Z')
			*input += 'a' - 'A';
	}
}

//Zip routines
bool decompressChapter(void *inputData, size_t sizeInput, char *outputPath, PROJECT_DATA project, int entryDetail)
{
	if(inputData == NULL || outputPath == NULL)
		return false;

	bool ret_value = true;

	uint lengthOutput = strlen(outputPath) + 1, nbFichiers = 0;
	char ** filename = NULL, *pathToConfigFile = malloc(lengthOutput + 50);

	//Init unzip file
	zlib_filefunc_def fileops;
	init_zmemfile(&fileops, ((DATA_DL_OBFS*)inputData)->data, ((DATA_DL_OBFS*)inputData)->mask, sizeInput);
	unzFile zipFile = unzOpen2(NULL, &fileops);

	if(pathToConfigFile == NULL || zipFile == NULL)
		goto quit;

	snprintf(pathToConfigFile, lengthOutput + 50, "%s/"CONFIGFILE, outputPath);

	//We create if required the path
	if(!checkDirExist(outputPath))
    {
        createPath(outputPath);
        if(!checkDirExist(outputPath))
        {
            logR("Error creating path %s", outputPath);
            goto quit;
        }
    }
	else if(checkFileExist(pathToConfigFile))		//Ensure the project is not already installed
        goto quit;

	//List files
    ret_value &= unzListArchiveContent(zipFile, &filename, &nbFichiers);
	if(ret_value)
	{
		uint nbFichierValide = 0;

		//Mot de pass des fichiers si la DRM est active
		unsigned char pass[nbFichiers][SHA256_DIGEST_LENGTH];
		crashTemp(pass, sizeof(pass));

		//Decompress files
		unzGoToFirstFile(zipFile);
		for(uint i = 0; i < nbFichiers && ret_value; i++)
		{
			//Name is valid
			if(checkNameFileZip(filename[i]))
			{
				ret_value &= unzExtractOnefile(zipFile, filename[i], outputPath, STRIP_PATH_ALL, project.haveDRM ? pass[i] : NULL);
				nbFichierValide++;
			}
			else
			{
				free(filename[i]);
				filename[i] = NULL;
			}

			//Go to next file if needed
			if(i + 1 < nbFichiers)
			{
				if(unzGoToNextFile(zipFile) != UNZ_OK)
					break;
			}
		}

		if(ret_value & project.haveDRM)
		{
			/*On va écrire les clées dans un config.enc
			 Pour ça, on va classer les clées en fonction des pages, retirer les éléments invalides, puis on chiffre tout ce beau monde*/

			uint nbFichierDansConfigFile = 0;
			char **pageNames = NULL;
			byte temp[256];

			//On vire les paths des noms de fichiers
			for(uint i = 0, j, k; i < nbFichiers; i++)
			{
				if(filename[i] == NULL)
					continue;

				j = strlen(filename[i]);
				for(; j > 0 && filename[i][j] != '/'; j--);
				if(j)
				{
					for(k = 0, j++; filename[i][j] != 0 && j < 256; filename[i][k++] = filename[i][j++]);
					filename[i][k] = 0;
				}
			}

			//We compact everything
			for(uint i = 0; i < nbFichiers; i++)
			{
				if(filename[i] == NULL || !strcmp(filename[i], CONFIGFILE)) //On vire la clé du config.dat
				{
					if(filename[i] != NULL)
					{
						nbFichierValide -= 1;
						free(filename[i]);
					}

					for(uint iter = i; iter < nbFichiers - 1; iter++)
					{
						filename[iter] = filename[iter + 1];
						memcpy(&(pass[iter]), &(pass[iter + 1]), sizeof(pass[0]));
					}
					
					nbFichiers -= 1;
				}
			}

			//On va classer les fichier et les clées en ce basant sur config.dat
			if((pageNames = loadChapterConfigDat(pathToConfigFile, &nbFichierDansConfigFile, NULL)) == NULL
			   || (nbFichierDansConfigFile != nbFichierValide && nbFichierDansConfigFile != nbFichierValide - 1))
			{
#ifdef EXTENSIVE_LOGGING
				logR("config.dat invalid: encryption aborted");
#endif

				removeFolder(outputPath);

				if(pageNames != NULL)
				{
					for(uint i = 0; nbFichierDansConfigFile; free(pageNames[i++]));
					free(pageNames);
				}
				ret_value = false;
				goto quit;
			}

			//Ensure the strings are minimized to properly compare them
			for(uint i = 0; i < nbFichiers; i++)
				minimizeString(filename[i]);
				
			for(uint i = 0; i < nbFichierDansConfigFile; i++)
				minimizeString(pageNames[i]);

			//Order the keys to match the order of the pages in config.dat
			for(uint filenamePos = 0, searchPos; filenamePos < nbFichierDansConfigFile; filenamePos++)
			{
				//Try finding the entry onward
				for(searchPos = filenamePos; searchPos < nbFichiers && strcmp(pageNames[filenamePos], filename[searchPos]); searchPos++);

				//Not working, trying backward
				if(searchPos == nbFichiers)
					for(searchPos = filenamePos; searchPos-- > 0 && strcmp(pageNames[filenamePos], filename[searchPos]););
				
				//Incorrect sorting
				if(searchPos != filenamePos && searchPos < nbFichiers)
				{
					void * entry = filename[filenamePos];
					filename[filenamePos] = filename[searchPos];
					filename[searchPos] = entry;

					char swapItem[SHA256_DIGEST_LENGTH];
					memcpy(swapItem, pass[filenamePos], SHA256_DIGEST_LENGTH); //On déplace les clées
					memcpy(pass[filenamePos], pass[searchPos], SHA256_DIGEST_LENGTH);
					memcpy(pass[searchPos], swapItem, SHA256_DIGEST_LENGTH);
					crashTemp(swapItem, SHA256_DIGEST_LENGTH);
				}
			}

			for(uint i = 0; i < nbFichierDansConfigFile; free(pageNames[i++]));
			free(pageNames);

			//Global encryption buffer
			byte * hugeBuffer = malloc(((SHA256_DIGEST_LENGTH + 1) * nbFichierValide + 15 + CRYPTO_BUFFER_SIZE) * sizeof(byte));
			if(hugeBuffer == NULL)
			{
#ifdef EXTENSIVE_LOGGING
				logR("Failed at allocate memory to buffer");
#endif
				memoryError((SHA256_DIGEST_LENGTH + 1) * nbFichierValide + 15 + CRYPTO_BUFFER_SIZE);
				removeFolder(outputPath);
				ret_value = false;
				goto quit;
			}

			//Add the number of entries at the begining of the said buffer
			int sizeWritten = sprintf((char *) hugeBuffer, "%d", nbFichierValide);
			uint posBlob = sizeWritten > 0 ? (uint) sizeWritten : 0;

			//Inject the keys in the buffer
			for(uint i = 0; i < nbFichiers; i++)
			{
				if(filename[i] != NULL)
				{
					hugeBuffer[posBlob++] = ' ';
					for(short keyPos = 0; keyPos < SHA256_DIGEST_LENGTH; hugeBuffer[posBlob++] = pass[i][keyPos++]);
				}
			}

			//We generate the masterkey
			if(getMasterKey(temp) == GMK_RETVAL_OK && COMPTE_PRINCIPAL_MAIL != NULL)
			{
				uint lengthEmail = strlen(COMPTE_PRINCIPAL_MAIL);
				if(lengthEmail != 0)
				{
					//We want to copy COMPTE_PRINCIPAL_MAIL ASAP in order to prevent TOCTOU
					char * encodedEmail[lengthEmail * 2 + 1];
					decToHex((void*) COMPTE_PRINCIPAL_MAIL, lengthEmail, (char*) encodedEmail);

					snprintf(pathToConfigFile, lengthOutput + 50, "%s/"DRM_FILE, outputPath);
					FILE * output = fopen(pathToConfigFile, "wb");
					if(output != NULL)
					{
						fputs((char*) encodedEmail, output);
						fputc('\n', output);

						uint8_t hash[SHA256_DIGEST_LENGTH], chapter[10];
						snprintf((char *)chapter, sizeof(chapter), "%d", entryDetail);

						internal_pbkdf2(SHA256_DIGEST_LENGTH, temp, SHA256_DIGEST_LENGTH, chapter, ustrlen(chapter), 512, PBKDF2_OUTPUT_LENGTH, hash);

						crashTemp(temp, sizeof(temp));

						_AES(hash, hugeBuffer, posBlob, hugeBuffer, EVERYTHING_IN_MEMORY, AES_ENCRYPT, AES_ECB);
						crashTemp(hash, SHA256_DIGEST_LENGTH);

						//We want to write the end of the block
						if(posBlob % CRYPTO_BUFFER_SIZE)
							posBlob += CRYPTO_BUFFER_SIZE - (posBlob % CRYPTO_BUFFER_SIZE);

						fwrite(hugeBuffer, posBlob, 1, output);
						fclose(output);
					}
					else //delete chapter
					{
						crashTemp(temp, sizeof(temp));
						removeFolder(outputPath);
					}
				}
				else //delete chapter
				{
					crashTemp(temp, sizeof(temp));
					removeFolder(outputPath);
				}
			}
			else //delete chapter
			{
				crashTemp(temp, sizeof(temp));
				removeFolder(outputPath);
			}

			free(hugeBuffer);
		}
	}

quit:

	if(filename != NULL)
	{
		for(uint i = 0; i < nbFichiers; free(filename[i++]));
		free(filename);
	}

    unzClose(zipFile);
	destroy_zmemfile(&fileops);
    free(pathToConfigFile);

	return ret_value;
}

void finishInstallationAtPath(const char * path)
{
	if (path == NULL)
		return;
	
	uint length = strlen(path) + 50;
	char finalPath[length];
	snprintf(finalPath, length, "%s/"CT_UNREAD_FLAG, path);
	
	FILE * file = fopen(finalPath, "w+");
	if(file != NULL)
		fclose(file);
}