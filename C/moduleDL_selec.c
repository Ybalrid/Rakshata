/*********************************************************************************************
**	__________         __           .__            __                 ________   _______   	**
**	\______   \_____  |  | __  _____|  |__ _____ _/  |______   	___  _\_____  \  \   _  \  	**
**	 |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \  	\  \/ //  ____/  /  /_\  \ 	**
**	 |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \__ \   //       \  \  \_/   \	**
**	 |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /	  \_/ \_______ \ /\_____  /	**
**	        \/      \/     \/     \/     \/     \/          \/ 	              \/ \/     \/ 	**
**                                                                                          **
**		Source code and assets are property of Taiki, distribution is stricly forbidden		**
**                                                                                          **
*********************************************************************************************/

#include "MDLCache.h"
#include "db.h"

#ifdef IDENTIFY_MISSING_UI
#warning "Need to get replaced"
#endif

/*extern int curPage; //Too lazy to use an argument
int mainChoixDL()
{
    bool autoSelect = false;
    int continuer = PALIER_DEFAULT, mangaChoisis = 0, chapitreChoisis = -1, nombreChapitre = 0, supprUsedInChapitre = 0, pageManga = 1;
    int pageChapitre = 1, previousMangaSelected = VALEUR_FIN_STRUCTURE_CHAPITRE;

    mkdirR("manga");

    MUTEX_LOCK(mutex);
    if(NETWORK_ACCESS != CONNEXION_DOWN)
    {
        MUTEX_UNLOCK(mutex);
        updateDatabase(false);
        MANGAS_DATA* mangaDB = getCopyCache(RDB_LOADALL | SORT_NAME | RDB_CTXSELMDL, NULL);
        MDL_SELEC_CACHE * cache = NULL;
        MDLSetCacheStruct(&cache);

		//C/C du choix de manga pour le lecteur.
        while((continuer > PALIER_MENU && continuer < 1) && (continuer != PALIER_CHAPTER || supprUsedInChapitre))
        {
            supprUsedInChapitre = 0;

			//Appel des selectionneurs
            curPage = pageManga;
            mangaChoisis = controleurManga(mangaDB, CONTEXTE_DL, nombreChapitre, &autoSelect);
            pageManga = curPage;

            if(mangaChoisis == ENGINE_RETVALUE_DL_START) //Télécharger
                continuer = PALIER_CHAPTER;
            else if(mangaChoisis == ENGINE_RETVALUE_DL_CANCEL) //Annuler
            {
                if(nombreChapitre > 0)
                {
                    continuer = -1;
                    nombreChapitre = 0;
                    remove(INSTALL_DATABASE);
                }
                else
                    continuer = PALIER_CHAPTER;
            }
            else if(mangaChoisis < PALIER_CHAPTER)
                continuer = mangaChoisis;
            else if(mangaChoisis == PALIER_CHAPTER)
                continuer = PALIER_MENU;
            else if(mangaChoisis > PALIER_DEFAULT)
            {
                bool isTome;
                chapitreChoisis = PALIER_DEFAULT;
                continuer = PALIER_DEFAULT;
                if(previousMangaSelected == VALEUR_FIN_STRUCTURE_CHAPITRE || mangaChoisis != previousMangaSelected)
                {
                    pageChapitre = 1;
                    previousMangaSelected = mangaChoisis;
                }

                while(chapitreChoisis > PALIER_CHAPTER && continuer == PALIER_DEFAULT)
                {
					updateIfRequired(&mangaDB[mangaChoisis], RDB_CTXSELMDL);
                    if(autoSelect)
                    {
                        chapitreChoisis = VALEUR_FIN_STRUCTURE_CHAPITRE;
                        autoSelect = isTome = false;
                        checkChapitreValable(&mangaDB[mangaChoisis], NULL);
                    }
                    else
                    {
                        curPage = pageChapitre;
                        chapitreChoisis = controleurChapTome(&mangaDB[mangaChoisis], &isTome, CONTEXTE_DL);
                        pageChapitre = curPage;
                    }

                    if (chapitreChoisis <= PALIER_CHAPTER)
                    {
                        continuer = chapitreChoisis;
                        if(chapitreChoisis == PALIER_CHAPTER)
                            supprUsedInChapitre = 1;
                    }

                    else
                    {
                        nombreChapitre = nombreChapitre + ecritureDansImport(&mangaDB[mangaChoisis], isTome, chapitreChoisis);
                        if(!checkIfNonCachedStuffs(getStructCacheManga(cache, &mangaDB[mangaChoisis]), isTome))
                            chapitreChoisis = PALIER_CHAPTER;
                    }
                }
            }
        }

        if(continuer == PALIER_CHAPTER && mangaChoisis == ENGINE_RETVALUE_DL_START && nombreChapitre)
        {
			//#warning "Need to get linked to launcher!
        }
        else
            remove(INSTALL_DATABASE);

        MDLFlushCachedCache();
        freeMDLSelecCache(cache);
        freeMangaData(mangaDB);
    }
    else
    {
        MUTEX_UNLOCK(mutex);
        continuer = erreurReseau();
    }
    return continuer;
}*/

/*Permet d'envoyer la variable de cache au coeur du système sans ajouter trop d'arguments*/
bool isCacheStrucCached = false;
MDL_SELEC_CACHE ** activeCache;

bool MDLSetCacheStruct(MDL_SELEC_CACHE ** cache)
{
    if(!isCacheStrucCached)
    {
        activeCache = cache;
        isCacheStrucCached = true;
        return true;
    }
    return false;
}

MDL_SELEC_CACHE ** MDLGetCacheStruct()
{
    if(isCacheStrucCached)
        return activeCache;
    return NULL;
}

void MDLFlushCachedCache()
{
    activeCache = NULL;
    isCacheStrucCached = false;
}

/*Cache des éléments sélectionnés pour les afficher dans l'interface*/

/*Recoit les données et si pas déjà présente, les injecte dans le cache.
Il sera possible soit de découper cette fonction en un test et un ajout si nécessaire*/

void initCacheSelectionMDL(MDL_SELEC_CACHE ** cache, MANGAS_DATA * mangaToPutInCache, bool isTome, int idElem)
{
    bool newDataset = false;

    if(*cache == NULL)
    {
        *cache = calloc(1, sizeof(MDL_SELEC_CACHE));
        if(*cache == NULL)   return;

        newDataset = true;
    }

    MDL_SELEC_CACHE * internalCache = *cache;   //cache != NULL

    if(!newDataset) //Si il y a déjà des trucs dans le cache, on vérifie que la team n'est pas déjà présente
        for(; internalCache->team != mangaToPutInCache->team && internalCache->nextTeam != NULL; internalCache = internalCache->nextTeam);

    if(newDataset || internalCache->team != mangaToPutInCache->team)   //Team non existante dans le cache
    {
        if(!newDataset)
        {
            MDL_SELEC_CACHE * newTeam = calloc(1, sizeof(MDL_SELEC_CACHE));
            if(newTeam == NULL)     return;

            internalCache->nextTeam = newTeam;  //Set the new structure as next element
            internalCache = newTeam;            //Jump to that element, if newDataset, already the case
            newDataset = true;
        }

        internalCache->team = mangaToPutInCache->team;
    }

    //now, internalCache contain the current team structure, let's check manga

    //We initialize a new var because if we don't, casting will make the code ugly
    MDL_SELEC_CACHE_MANGA * internalCacheM = internalCache->data;    //Get into the content of team's cache to find the manga, if newDataset, internalCache->data == NULL

    if(!newDataset && internalCacheM != NULL)
        for(; internalCacheM->manga != mangaToPutInCache && internalCacheM->nextManga != NULL;  internalCacheM = internalCacheM->nextManga);

    if(newDataset || internalCacheM == NULL || internalCacheM->manga != mangaToPutInCache)   //Si ajout du manga dans le cache est requis
    {
        MDL_SELEC_CACHE_MANGA * newManga = calloc(1, sizeof(MDL_SELEC_CACHE_MANGA));
        if(newManga == NULL)    return;

        newManga->allTomeCached = (mangaToPutInCache->firstTome == VALEUR_FIN_STRUCTURE_CHAPITRE);          //Si rien de dispo dans les tomes
        newManga->allChapterCached = (mangaToPutInCache->firstChapter == VALEUR_FIN_STRUCTURE_CHAPITRE);

        if(newDataset || internalCacheM == NULL)
            internalCache->data = newManga;
        else
            internalCacheM->nextManga = newManga;

        internalCacheM = newManga;
        internalCacheM->manga = mangaToPutInCache;
        //newDataset = true;    //Could be usefull later but for now, it's not used after that point
    }

    if(idElem == VALEUR_FIN_STRUCTURE_CHAPITRE)
        return;

    int * input = isTome ? internalCacheM->tome : internalCacheM->chapitre;
    int size = input != NULL ? *input : 0;
    int * newCache = realloc(input, (size + 2) * sizeof(int));

    //On ne recherche pas les doublons pour des raisons de performance

    if(newCache == NULL)     return;

    if(isTome)  internalCacheM->tome = newCache;
    else        internalCacheM->chapitre = newCache;

    *newCache = size + 1;   //Set the new size
    newCache[*newCache] = idElem;               //Set the value in the last entry

    if(input != NULL)
        mergeSort(&newCache[1], *newCache);
}

MDL_SELEC_CACHE_MANGA * getStructCacheManga(MDL_SELEC_CACHE * cache, MANGAS_DATA * mangaToGet)
{
    if(cache == NULL || mangaToGet == NULL)     return NULL;

    /*On assume que il y a du contenu dans le cache cf initCacheSelectionMDL*/

    for(; cache->team != mangaToGet->team && cache->nextTeam != NULL; cache = cache->nextTeam);

    if(cache->team != mangaToGet->team || cache->data == NULL)     return NULL;

    MDL_SELEC_CACHE_MANGA * internalCache = cache->data;    //Get into the content of team's cache to find the manga, if newDataset, internalCache->data == NULL

    for(; internalCache->manga != mangaToGet && internalCache->nextManga != NULL;  internalCache = internalCache->nextManga);

    if(internalCache->manga != mangaToGet)   return NULL;
    return internalCache;
}

bool checkIfNonCachedStuffs(MDL_SELEC_CACHE_MANGA * cacheManga, bool isTome)
{
    if(cacheManga == NULL)
        return true;

    if((isTome && cacheManga->allTomeCached) || (!isTome && cacheManga->allChapterCached))  //All read
        return false;

    int curPos, curElem, posCache = 0, length;
    MANGAS_DATA mangaDB = *cacheManga->manga;

    if(isTome)  //Si iSTome && !allTomeCached, il y a des tomes valides
    {
        if(cacheManga->tome == NULL)    //Si pas de cache, c'est réglé
            return true;

        length = cacheManga->tome[0];       //On stock la longueure pour évite de déréférencer le pointeur à chaque fois
        for(curPos = 0; curPos < mangaDB.nombreTomes; curPos++)
        {
            curElem = mangaDB.tomes[curPos].ID;

            for(; posCache < length && cacheManga->tome[posCache+1] < curElem; posCache++);
            if(posCache < length && cacheManga->tome[posCache+1] == curElem)  //Si dans le cache
                continue;
            else if(!checkTomeReadable(mangaDB, mangaDB.tomes[curPos].ID))
                break;
        }
        return (curPos == mangaDB.nombreTomes);
    }
    else
    {
        if(cacheManga->chapitre == NULL)    //Si pas de cache, c'est réglé
            return true;

        length = cacheManga->chapitre[0];       //On stock la longueure pour évite de déréférencer le pointeur à chaque fois
        for(curPos = 0; curPos < mangaDB.nombreChapitre; curPos++)
        {
            curElem = mangaDB.chapitres[curPos];

            for(; posCache < length && cacheManga->chapitre[posCache+1] < curElem; posCache++);
            if(posCache < length && cacheManga->chapitre[posCache+1] == curElem)  //Si dans le cache
                continue;
            else if(!checkChapterReadable(mangaDB, mangaDB.chapitres[curPos]))
                break;
        }
        return (curPos != mangaDB.nombreChapitre);
    }
    return true;
}

bool checkIfElemCached(MDL_SELEC_CACHE_MANGA * cacheManga, bool isTome, int element)
{
    if(cacheManga == NULL || (isTome && cacheManga->tome == NULL) || (!isTome && cacheManga->chapitre == NULL))
        return false;

    int * input = isTome ? cacheManga->tome : cacheManga->chapitre;
    int posCache, size = *input;

    for(posCache = 1; posCache <= size && input[posCache] != element; posCache++);
    return (posCache <= size);
}

void freeMDLSelecCache(MDL_SELEC_CACHE * cache)
{
    void * buffer;
    /*NULL pointers can be freely freed*/
    while(cache != NULL)
    {
        while(cache->data != NULL)
        {
            buffer = cache->data->nextManga;
            free(cache->data->tome);
            free(cache->data->chapitre);
            free(cache->data);
            cache->data = (MDL_SELEC_CACHE_MANGA *) buffer;
        }
        buffer = cache;
        cache = cache->nextTeam;
        free(buffer);
    }
}

