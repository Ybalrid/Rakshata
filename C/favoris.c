/*********************************************************************************************
**	__________         __           .__            __                 ________   _______   	**
**	\______   \_____  |  | __  _____|  |__ _____ _/  |______   	___  _\_____  \  \   _  \  	**
**	 |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \  	\  \/ //  ____/  /  /_\  \ 	**
**	 |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \__ \   //       \  \  \_/   \	**
**	 |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /	  \_/ \_______ \ /\_____  /	**
**	        \/      \/     \/     \/     \/     \/          \/ 	              \/ \/     \/ 	**
**                                                                                          **
**    Licence propriétaire, code source confidentiel, distribution formellement interdite   **
**                                                                                          **
*********************************************************************************************/

#include "db.h"

bool checkIfFaved(MANGAS_DATA* mangaDB, char **favs)
{
    bool generateOwnCache = false;
    char *favsBak = NULL, *internalCache = NULL;
	char mangaLong[LONGUEUR_NOM_MANGA_MAX] = {0}, teamLong[LONGUEUR_NOM_MANGA_MAX] = {0};

    if(favs == NULL)
    {
        favs = &internalCache;
        generateOwnCache = true;
    }

    if(*favs == NULL)
    {
        *favs = loadLargePrefs(SETTINGS_FAVORITE_FLAG);
    }

    if(*favs == NULL || mangaDB == NULL)
        return 0;

    favsBak = *favs;
    while(favsBak != NULL && *favsBak && (strcmp(mangaDB->team->teamLong, teamLong) || strcmp(mangaDB->mangaName, mangaLong)))
    {
        favsBak += sscanfs(favsBak, "%s %s", teamLong, LONGUEUR_NOM_MANGA_MAX, mangaLong, LONGUEUR_NOM_MANGA_MAX);
        for(; favsBak != NULL && *favsBak && (*favsBak == '\n' || *favsBak == '\r'); favsBak++);
    }
    if(generateOwnCache)
        free(internalCache);

    if(!strcmp(mangaDB->team->teamLong, teamLong) && !strcmp(mangaDB->mangaName, mangaLong))
        return true;
    return false;
}

extern bool addRepoByFileInProgress;
void updateFavorites()
{
    char *favs = NULL;
    if(!checkFileExist(INSTALL_DATABASE) && (favs = loadLargePrefs(SETTINGS_FAVORITE_FLAG)) != NULL && !addRepoByFileInProgress)
        favorisToDL = 0;
    else
        return;

    if(favs != NULL)
        free(favs);

    updateDatabase(false);
    MANGAS_DATA *mangaDB = getCopyCache(RDB_LOADINSTALLED | SORT_TEAM | RDB_CTXFAVS, NULL);
    if(mangaDB == NULL)
        return;

    int i;
    for(i = 0; mangaDB[i].mangaName[0]; i++)
    {
        if(mangaDB[i].favoris)
        {
            char temp[2*LONGUEUR_NOM_MANGA_MAX+128];
            snprintf(temp, 2*LONGUEUR_NOM_MANGA_MAX+128, "manga/%s/%s/Chapitre_%d/%s", mangaDB[i].team->teamLong, mangaDB[i].mangaName, mangaDB[i].lastChapter, CONFIGFILE);
            if(!checkFileExist(temp))
            {
                do
                {
                    favorisToDL = 1;
                } while(!favorisToDL);
                break;
            }
        }
    }
    freeMangaData(mangaDB);
    if(!favorisToDL)
    {
        while(1)
        {
            favorisToDL = -1;
            if(favorisToDL == -1) //Un petit truc au cas où
                break;
        }
    }
}

#warning "To test"
void getNewFavs()
{
	uint maxValue;
    FILE* import = NULL;
    MANGAS_DATA *mangaDB = getCopyCache(RDB_LOADINSTALLED | SORT_TEAM | RDB_CTXFAVS, NULL);

    if(mangaDB == NULL)
        return;

    int i, j, WEGOTSOMETHING = 0;

    for(i = 0; mangaDB[i].team != NULL; i++)
    {
        if(mangaDB[i].favoris)
        {
            if(mangaDB[i].chapitres != NULL)
			{
				maxValue = mangaDB[i].nombreChapitre;
				for(j = 0; j < maxValue && mangaDB[i].chapitres[j] != VALEUR_FIN_STRUCTURE_CHAPITRE; j++)
				{
					if(!checkChapterReadable(mangaDB[i], mangaDB[i].chapitres[j]))
					{
						if(import == NULL)
							import = fopen(INSTALL_DATABASE, "a+");
						
						if(import != NULL)
						{
							WEGOTSOMETHING = 1;
							fprintf(import, "%s %s C %d\n", mangaDB[i].team->teamCourt, mangaDB[i].mangaNameShort, mangaDB[i].chapitres[j]);
						}
					}
				}
			}
			if(mangaDB[i].tomes != NULL)
			{
				maxValue = mangaDB[i].nombreTomes;
				for(j = 0; j < maxValue && mangaDB[i].tomes[j].ID != VALEUR_FIN_STRUCTURE_CHAPITRE; j++)
				{
					if(!checkTomeReadable(mangaDB[i], mangaDB[i].tomes[j].ID))
					{
						if(import == NULL)
							import = fopen(INSTALL_DATABASE, "a+");
						
						if(import != NULL)
						{
							WEGOTSOMETHING = 1;
							fprintf(import, "%s %s T %d\n", mangaDB[i].team->teamCourt, mangaDB[i].mangaNameShort, mangaDB[i].tomes[j].ID);
						}
					}
				}
			}
        }
    }
	
	fclose(import);
    freeMangaData(mangaDB);
    if(WEGOTSOMETHING && checkLancementUpdate())
        lancementModuleDL();
}
