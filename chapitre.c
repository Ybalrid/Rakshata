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

#include "main.h"
#include "MDLCache.h"

void refreshChaptersList(MANGAS_DATA *mangaDB)
{
    if(mangaDB->chapitres != NULL)
        free(mangaDB->chapitres);

    /*On commence par énumérer les chapitres spéciaux*/
    int nbElem, i;
    char temp[TAILLE_BUFFER];
    snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/%s", mangaDB->team->teamLong, mangaDB->mangaName, CHAPITRE_INDEX);
    FILE* chapSpeciaux = fopenR(temp, "r");

    nbElem = mangaDB->nombreChapitreSpeciaux + mangaDB->lastChapter - mangaDB->firstChapter + 1;
    mangaDB->chapitres = calloc(nbElem+5, sizeof(int));
    for(i = 0; i < nbElem+5; mangaDB->chapitres[i++] = VALEUR_FIN_STRUCTURE_CHAPITRE);

    for(i = 0; i <= mangaDB->lastChapter-mangaDB->firstChapter && i < nbElem; i++)
        mangaDB->chapitres[i] = (mangaDB->firstChapter+i)*10;

    if(chapSpeciaux != NULL)
    {
        if(nbElem)
        {
            for(; i < nbElem && fgetc(chapSpeciaux) != EOF; i++)
            {
                fseek(chapSpeciaux, -1, SEEK_CUR);
                fscanfs(chapSpeciaux, "%d", &(mangaDB->chapitres[i]));
            }
        }
        fclose(chapSpeciaux);
    }
    qsort(mangaDB->chapitres, i, sizeof(int), sortNumbers);
    mangaDB->nombreChapitre = i;
}

void checkChapitreValable(MANGAS_DATA *mangaDB, int *dernierLu)
{
    int first = -1, end = -1, fBack, eBack, nbElem = 0;
    char temp[TAILLE_BUFFER*5];

    snprintf(temp, TAILLE_BUFFER*5, "manga/%s/%s/%s", mangaDB->team->teamLong, mangaDB->mangaName, CONFIGFILE);
    FILE* file = fopenR(temp, "r");
    if(file == NULL)
    {
        mangaDB->chapitres[0] = VALEUR_FIN_STRUCTURE_CHAPITRE;
        mangaDB->nombreChapitre = 0;
        return;
    }
    fscanfs(file, "%d %d", &fBack, &eBack);
    if(fgetc(file) != EOF)
    {
        fseek(file, -1, SEEK_CUR);
        fscanfs(file, "%d", dernierLu);
    }
    fclose(file);

    for(nbElem = 0; mangaDB->chapitres[nbElem] != VALEUR_FIN_STRUCTURE_CHAPITRE && nbElem < mangaDB->nombreChapitre; nbElem++)
    {
        if(!checkChapterReadable(*mangaDB, mangaDB->chapitres[nbElem]))
            mangaDB->chapitres[nbElem] = VALEUR_FIN_STRUCTURE_CHAPITRE;
    }

    qsort(mangaDB->chapitres, nbElem, sizeof(int), sortNumbers);
    for(; nbElem > 0 && mangaDB->chapitres[nbElem-1] == VALEUR_FIN_STRUCTURE_CHAPITRE; nbElem--);

    if(nbElem == 0)
    {
        snprintf(temp, TAILLE_BUFFER, "manga/%s/%s", mangaDB->team->teamLong, mangaDB->mangaName);
        removeFolder(temp);
        mangaDB->chapitres[0] = VALEUR_FIN_STRUCTURE_CHAPITRE;
        mangaDB->nombreChapitre = 0;
        return;
    }

    first = mangaDB->chapitres[0];
    end = mangaDB->chapitres[nbElem-1];

    if(first > *dernierLu && *dernierLu != VALEUR_FIN_STRUCTURE_CHAPITRE)
        *dernierLu = mangaDB->chapitres[0];

    else if(end < *dernierLu && *dernierLu != VALEUR_FIN_STRUCTURE_CHAPITRE)
        *dernierLu = mangaDB->chapitres[nbElem-1];

    if((first != fBack || end != eBack) && first <= end)
    {
        snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/%s", mangaDB->team->teamLong, mangaDB->mangaName, CONFIGFILE);
        file = fopenR(temp, "w+");
        if(temp != NULL)
        {
            fprintf(file, "%d %d", first, end);
            if(*dernierLu != VALEUR_FIN_STRUCTURE_CHAPITRE)
                fprintf(file, " %d", *dernierLu);
            fclose(file);
        }
    }
    else if(first > end)
    {
        snprintf(temp, TAILLE_BUFFER, "manga/%s/%s", mangaDB->team->teamLong, mangaDB->mangaName);
        removeFolder(temp);
        mangaDB->chapitres[0] = VALEUR_FIN_STRUCTURE_CHAPITRE;
        mangaDB->nombreChapitre = 0;
        return;
    }
    mangaDB->nombreChapitre = nbElem;
}

void getUpdatedChapterList(MANGAS_DATA *mangaDB)
{
    int i = VALEUR_FIN_STRUCTURE_CHAPITRE;
    refreshChaptersList(mangaDB);
    checkChapitreValable(mangaDB, &i);
}

int askForChapter(MANGAS_DATA *mangaDB, int contexte)
{
    /*Initialisations*/
    int i = 0, chapitreChoisis = 0, dernierLu = VALEUR_FIN_STRUCTURE_CHAPITRE;
    char temp[TAILLE_BUFFER], texteTrad[SIZE_TRAD_ID_19][TRAD_LENGTH];
    loadTrad(texteTrad, 19);

    if((i = autoSelectionChapitreTome(mangaDB, 0, contexte)) != VALEUR_FIN_STRUCTURE_CHAPITRE)
        return i;

    snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/%s", mangaDB->team->teamLong, mangaDB->mangaName, CONFIGFILE);
    if(checkFileExist(temp) || contexte == CONTEXTE_DL)
    {
        /*Initialize internal chapter list*/
        refreshChaptersList(mangaDB);
        if(contexte == CONTEXTE_DL)
        {
            if(checkFileExist(temp))
                dernierLu = VALEUR_FIN_STRUCTURE_CHAPITRE; //Si un manga est déjà installé, on le met dans le sens décroissant
        }
        else
        {
            checkChapitreValable(mangaDB, &dernierLu);
            if(mangaDB->nombreChapitre == 0)
                return PALIER_MENU;
        }

        //Generate chapter list
		PREFS_ENGINE prefs;
        DATA_ENGINE *chapitreDB = generateChapterList(mangaDB, (dernierLu == VALEUR_FIN_STRUCTURE_CHAPITRE), contexte, texteTrad[14], texteTrad[0], &prefs);
        if(chapitreDB == NULL) //Erreur de mémoire ou liste vide
            return errorEmptyCTList(contexte, texteTrad);
        else
            prefs.IDDernierElemLu = dernierLu;

        displayTemplateChapitre(mangaDB, prefs, contexte, texteTrad);

        do
        {
            chapitreChoisis = engineCore(&prefs, CONTEXTE_CHAPITRE, chapitreDB, prefs.nombreElementTotal>ENGINE_ELEMENT_PAR_PAGE?BORDURE_SUP_SELEC_CHAPITRE_FULL:BORDURE_SUP_SELEC_CHAPITRE_PARTIAL, NULL);
            if(chapitreChoisis == ENGINE_RETVALUE_SWITCH)
                continue;
        } while(0);

        free(chapitreDB);
    }
    else
        chapitreChoisis = PALIER_CHAPTER;

    return chapitreChoisis;
}

void displayTemplateChapitre(MANGAS_DATA* mangaDB, PREFS_ENGINE data, int contexte, char texteTrad[SIZE_TRAD_ID_19][TRAD_LENGTH])
{
    displayTemplateChapitreTome(mangaDB, contexte, 0, data, texteTrad);
}

DATA_ENGINE *generateChapterList(MANGAS_DATA *mangaDB, bool ordreCroissant, int contexte, char* stringAll, char* stringGeneric, PREFS_ENGINE * prefs)
{
    int i = 0;
    char temp[500], stringGenericUsable[TRAD_LENGTH];
    MDL_SELEC_CACHE_MANGA * cacheMDL;

    if(strlen(stringGeneric) >= TRAD_LENGTH)
        stringGeneric[TRAD_LENGTH-1] = 0;
    strcpy(stringGenericUsable, stringGeneric);
    if(stringGenericUsable[0] >= 'a' && stringGenericUsable[0] <= 'z')
        stringGenericUsable[0] += 'A'-'a';

    /*On prépare maintenant la structure*/
    int chapitreCourant = 0;
    DATA_ENGINE *chapitreDB = calloc(mangaDB->nombreChapitre+2, sizeof(DATA_ENGINE));
    prefs->chapitrePlusAncien = prefs->chapitrePlusRecent = VALEUR_FIN_STRUCTURE_CHAPITRE;

    if(contexte != CONTEXTE_LECTURE)
    {
        chapitreDB[chapitreCourant].ID = VALEUR_FIN_STRUCTURE_CHAPITRE;
        usstrcpy(chapitreDB[chapitreCourant].stringToDisplay, MAX_LENGTH_TO_DISPLAY, stringAll);
        chapitreCourant++;

        if(contexte == CONTEXTE_DL)
        {
            MDL_SELEC_CACHE ** cache = MDLGetCacheStruct();
            cacheMDL = getStructCacheManga((cache != NULL ? *cache : NULL), mangaDB);
        }
    }

    if(ordreCroissant)
        i = 0;
    else
        i = mangaDB->nombreChapitre-1;
    while((i < mangaDB->nombreChapitre && ordreCroissant) || (i >= 0 && !ordreCroissant))
    {
        if(mangaDB->chapitres[i] % 10)
            snprintf(temp, 500, "manga/%s/%s/Chapitre_%d.%d/%s", mangaDB->team->teamLong, mangaDB->mangaName, mangaDB->chapitres[i]/10, mangaDB->chapitres[i]%10, CONFIGFILE);
        else
            snprintf(temp, 500, "manga/%s/%s/Chapitre_%d/%s", mangaDB->team->teamLong, mangaDB->mangaName, mangaDB->chapitres[i]/10, CONFIGFILE);

        if((contexte != CONTEXTE_DL && checkFileExist(temp)) || (contexte == CONTEXTE_DL && !checkFileExist(temp)))
        {
            chapitreDB[chapitreCourant].ID = mangaDB->chapitres[i];
            if(mangaDB->chapitres[i]%10)
                snprintf(chapitreDB[chapitreCourant++].stringToDisplay, MAX_LENGTH_TO_DISPLAY, "%s %d.%d", stringGenericUsable, mangaDB->chapitres[i]/10, mangaDB->chapitres[i]%10);
            else
                snprintf(chapitreDB[chapitreCourant++].stringToDisplay, MAX_LENGTH_TO_DISPLAY, "%s %d", stringGenericUsable, mangaDB->chapitres[i]/10);

            if(ordreCroissant)
            {
                if(prefs->chapitrePlusAncien == VALEUR_FIN_STRUCTURE_CHAPITRE)
                    prefs->chapitrePlusAncien = mangaDB->chapitres[i];
                prefs->chapitrePlusRecent = mangaDB->chapitres[i];
            }
            else
            {
                if(prefs->chapitrePlusRecent == VALEUR_FIN_STRUCTURE_CHAPITRE)
                    prefs->chapitrePlusRecent = mangaDB->chapitres[i];
                prefs->chapitrePlusAncien = mangaDB->chapitres[i];
            }

            if(contexte == CONTEXTE_DL && checkIfElemCached(cacheMDL, false, chapitreDB[chapitreCourant-1].ID))
                chapitreDB[chapitreCourant-1].isFullySelected = true;
        }
        if(ordreCroissant)
            i++;
        else
            i--;
    }
    prefs->website = mangaDB->team->site; //On copie juste le pointeur pour économiser de la taille
    prefs->nombreElementTotal = chapitreCourant;

    if((chapitreCourant == 1 && contexte != CONTEXTE_LECTURE) || (chapitreCourant == 0 && contexte == CONTEXTE_LECTURE)) //Si il n'y a pas de chapitre
    {
        free(chapitreDB);
        chapitreDB = NULL;
    }
    return chapitreDB;
}

