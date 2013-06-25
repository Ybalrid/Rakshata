/*********************************************************************************************
**  __________         __           .__            __                  ____     ________    **
**  \______   \_____  |  | __  _____|  |__ _____ _/  |______    ___  _/_   |    \_____  \   **
**   |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \   \  \/ /|   |     /  ____/   **
**   |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \_  \   / |   |    /       \   **
**   |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /   \_/  |___| /\ \_______ \  **
**          \/      \/     \/     \/     \/     \/          \/               \/         \/  **
**                                                                                          **
**    Licence propriétaire, code source confidentiel, distribution formellement interdite   **
**                                                                                          **
*********************************************************************************************/

#include "main.h"
#include "moduleDL.h"

int WINDOW_SIZE_H_DL = 0, WINDOW_SIZE_W_DL = 0, INSTANCE_RUNNING = 0;
volatile bool quit;
int pageCourante;
int nbElemTotal;
static int **status; //Le status des différents elements
int **statusCache;
#ifndef _WIN32
    MUTEX_VAR mutexDispIcons = PTHREAD_MUTEX_INITIALIZER;
#else
    MUTEX_VAR mutexDispIcons;
#endif

void mainMDL()
{
    bool jobUnfinished = false, error = false, printError = false;;
    int i = 0;
    int nombreElementDrawn;
    char trad[SIZE_TRAD_ID_22][TRAD_LENGTH];
    DATA_LOADED ***todoList = malloc(sizeof(DATA_LOADED ***));
    THREAD_TYPE threadData;
    MANGAS_DATA* mangaDB = miseEnCache(LOAD_DATABASE_ALL);
    SDL_Event event;

    /*Initialisation*/

#ifdef _WIN32
    mutexDispIcons = CreateSemaphore (NULL, 1, 1, NULL);
#endif // _WIN32

    loadTrad(trad, 22);
    quit = false;
    nbElemTotal = pageCourante = 0;
    *todoList = MDL_loadDataFromImport(mangaDB, &nbElemTotal);
    if(nbElemTotal == 0)
        return;

    status = calloc(nbElemTotal+1, sizeof(int*));
    statusCache = calloc(nbElemTotal+1, sizeof(int*));

    if(status == NULL || statusCache == NULL)
        return;

    for(i = 0; i < nbElemTotal; i++)
    {
        status[i] = malloc(sizeof(int));
        statusCache[i] = malloc(sizeof(int));
        *statusCache[i] = *status[i] = MDL_CODE_DEFAULT;
    }

    /*Checks réseau*/
    while(1)
    {
        if(!checkNetworkState(CONNEXION_TEST_IN_PROGRESS))
            break;
        SDL_PollEvent(&event);
        SDL_Delay(50);
    }

    if(checkNetworkState(CONNEXION_DOWN))
        return;

    MDLDispDownloadHeader(NULL);
    MDLDispInstallHeader(NULL);
    nombreElementDrawn = MDLDrawUI(*todoList, trad); //Initial draw
    MDLUpdateIcons(true);
    threadData = createNewThreadRetValue(mainDLProcessing, todoList);

    while(!quit) //Corps de la fonction
    {
        if(MDLEventsHandling(&(*todoList)[pageCourante*MDL_NOMBRE_ELEMENT_COLONNE], nombreElementDrawn))
        {
            nombreElementDrawn = MDLDrawUI(*todoList, trad); //Redraw if requested
            MDLUpdateIcons(true);
        }

        else if(checkFileExist(INSTALL_DATABASE) && INSTANCE_RUNNING == -1)
        {
            int newNbElemTotal = nbElemTotal;
            DATA_LOADED ** ptr = MDL_updateDownloadList(mangaDB, &newNbElemTotal, status, *todoList);
            if(ptr != NULL)
            {
                int ** ptr2 = realloc(status, newNbElemTotal*sizeof(int*));
                int ** ptr3 = realloc(statusCache, newNbElemTotal*sizeof(int*));
                if(ptr2 == NULL || ptr3 == NULL)
                {
                    for(i = newNbElemTotal-1; i > nbElemTotal; free((*todoList)[i--]));
                    free(*ptr);
                    free(ptr);
                    free(ptr2);
                    free(ptr3);
                }
                else
                {
                    for(nbElemTotal++; nbElemTotal < newNbElemTotal; nbElemTotal++)
                    {
                        ptr2[nbElemTotal] = malloc(sizeof(int*));
                        if(ptr2[nbElemTotal] != NULL)
                            *ptr2[nbElemTotal] = MDL_CODE_DEFAULT;

                        ptr3[nbElemTotal] = malloc(sizeof(int*));
                        if(ptr3[nbElemTotal] != NULL)
                            *ptr3[nbElemTotal] = MDL_CODE_DEFAULT;
                    }
                    status = ptr2;
                    statusCache = ptr3;
                    *todoList = ptr;
                    nombreElementDrawn = MDLDrawUI(*todoList, trad); //Redraw if requested
                    MDLUpdateIcons(true);
                }
            }
        }
        else if(!isThreadStillRunning(threadData))
        {
            printError = MDLDispError(trad);
        }
    }

    /*Attente de la fin du thread de traitement*/
    while(isThreadStillRunning(threadData))
    {
        if(SDL_PollEvent(&event))
            haveInputFocus(&event, windowDL); //Renvoyer l'evenement si nécessaire
        SDL_Delay(100);
    }

    for(i = 0; i < nbElemTotal; i++)
    {
        if (*status[i] == MDL_CODE_DEFAULT)
            jobUnfinished = true;
        else if(*status[i] < MDL_CODE_DEFAULT) //Error
            error = true;
    }

    /*Si interrompu, on enregistre ce qui reste à faire*/
    if(jobUnfinished)
    {
        printError = error;
        /*Checker si il y a eu des erreurs et proposer de réessayer/reporter/annuler*/
		MDLParseFile(*todoList, status, nbElemTotal, printError);
    }

    /*On libère la mémoire*/
    for(i = 0; i < nbElemTotal; free((*todoList)[i++]));
    freeMangaData(mangaDB, NOMBRE_MANGA_MAX);
    free(*todoList);
    free(todoList);
    MUTEX_DESTROY(mutexDispIcons);

#ifdef _WIN32
    CloseHandle (threadData);
#endif // _WIN32
}

void MDLLauncher()
{
    /*On affiche la petite fenêtre, on peut pas utiliser un mutex à cause
    d'une réservation à deux endroits en parallèle, qui cause des crashs*/

    if(INSTANCE_RUNNING || !checkLancementUpdate())
    {
        INSTANCE_RUNNING = -1; //Signale qu'il faut charger le nouveau fichier
        quit_thread(0);
    }

    if(!loadEmailProfile())
        quit_thread(0);

    INSTANCE_RUNNING = 1;

#ifdef _WIN32
    HANDLE hSem = CreateSemaphore (NULL, 1, 1,"RakshataDL2");
    if (WaitForSingleObject (hSem, 0) == WAIT_TIMEOUT)
    {
        logR("Fail: instance already running\n");
        CloseHandle (hSem);
        return;
    }
#else
    FILE *fileBlocker = fopenR("data/download", "w+");
    fprintf(fileBlocker, "%d", getpid());
    fclose(fileBlocker);
#endif

    SDL_FlushEvent(SDL_WINDOWEVENT);
    windowDL = SDL_CreateWindow(PROJECT_NAME, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, LARGEUR, HAUTEUR_FENETRE_DL, SDL_WINDOW_OPENGL);
    SDL_FlushEvent(SDL_WINDOWEVENT);

    loadIcon(windowDL);
    nameWindow(windowDL, 1);

    SDL_FlushEvent(SDL_WINDOWEVENT);
    rendererDL = setupRendererSafe(windowDL);
    SDL_FlushEvent(SDL_WINDOWEVENT);

    WINDOW_SIZE_W_DL = LARGEUR;
    WINDOW_SIZE_H_DL = HAUTEUR_FENETRE_DL;

    chargement(rendererDL, WINDOW_SIZE_H_DL, WINDOW_SIZE_W_DL);
    mainMDL();

    INSTANCE_RUNNING = 0;

#ifdef _WIN32
    ReleaseSemaphore (hSem, 1, NULL);
    CloseHandle (hSem);
#else
    removeR("data/download");
#endif
    quit_thread(0);
}

/*Processing*/

void mainDLProcessing(DATA_LOADED *** todoList)
{
    int dataPos = 0;
    char **historiqueTeam = malloc(sizeof(char*));
    historiqueTeam[0] = NULL;

    if(dataPos < nbElemTotal)
    {
        MDLStartHandler(dataPos, *todoList, &historiqueTeam);
        MDLDispDownloadHeader((*todoList)[dataPos]);
    }

    while(1)
    {
        if(*status[dataPos] != MDL_CODE_DL)
        {
            if(quit)
                break;

            for(dataPos = 0; dataPos < nbElemTotal && *status[dataPos] != MDL_CODE_DEFAULT; dataPos++);
            if(dataPos < nbElemTotal)
            {
                MDLDispDownloadHeader((*todoList)[dataPos]);
                MDLStartHandler(dataPos, *todoList, &historiqueTeam);
            }
            else
            {
                MDLDispDownloadHeader(NULL);
                break;
            }
        }
    }
    for(dataPos = 0; historiqueTeam[dataPos] != NULL; free(historiqueTeam[dataPos++]));
    free(historiqueTeam);
    quit_thread(0);
}

void MDLStartHandler(int posElement, DATA_LOADED ** todoList, char ***historiqueTeam)
{
    MDL_HANDLER_ARG* argument = malloc(sizeof(MDL_HANDLER_ARG));
    if(argument == NULL)
    {
        memoryError(sizeof(MDL_HANDLER_ARG));
        return;
    }
    *status[posElement] = MDL_CODE_DL; //Permet à la boucle de mainDL de ce poursuivre tranquillement
    argument->todoList = todoList[posElement];
    argument->currentState = status[posElement];
    argument->isTomeAndLastElem = false;
    argument->historiqueTeam = historiqueTeam;
    if(todoList[posElement]->partOfTome != VALEUR_FIN_STRUCTURE_CHAPITRE)
    {
        if(posElement+1 >= nbElemTotal || todoList[posElement+1] == NULL || todoList[posElement+1]->datas != todoList[posElement]->datas || todoList[posElement+1]->partOfTome != todoList[posElement]->partOfTome)
            argument->isTomeAndLastElem = true; //Validation
    }
    createNewThread(MDLHandleProcess, argument);
}

void MDLHandleProcess(MDL_HANDLER_ARG* inputVolatile)
{
    int i = 0;
    MDL_HANDLER_ARG input;
    memcpy(&input, inputVolatile, sizeof(MDL_HANDLER_ARG));
    free(inputVolatile);

    if(input.todoList == NULL || input.todoList->datas == NULL)
    {
        *input.currentState = MDL_CODE_INTERNAL_ERROR;
        MDLUpdateIcons(false);
        quit_thread(0);
    }

    if(!checkChapterAlreadyInstalled(*input.todoList))
    {
        if(checkIfWebsiteAlreadyOpened(*input.todoList->datas->team, input.historiqueTeam))
        {
            ouvrirSiteTeam(input.todoList->datas->team); //Ouverture du site de la team
        }

        DATA_MOD_DL argument;
        argument.currentState = input.currentState;
        argument.todoList = input.todoList;
        MDLUpdateIcons(false);
        MDLTelechargement(&argument);

        if(*argument.currentState == MDL_CODE_DL_OVER) //On lance l'installation
        {
            for(; i < nbElemTotal && *status[i] != MDL_CODE_INSTALL; i++);
            if(i == nbElemTotal) //Aucune installation en cours
            {
                *input.currentState = MDL_CODE_INSTALL;
                MDLUpdateIcons(false);
            }
            else
            {
                while(*input.currentState != MDL_CODE_INSTALL)
                    SDL_Delay(250);
            }
            MDLDispInstallHeader(input.todoList);
            MDLInstallation(input, argument);
        }
    }
    else
    {
        *input.currentState = MDL_CODE_INSTALL_OVER;
    }

    for(i = 0; i < nbElemTotal && *status[i] != MDL_CODE_DL_OVER; i++);
    if(i != nbElemTotal) //une installation a été trouvée
        *status[i] = MDL_CODE_INSTALL;
    else
        MDLDispInstallHeader(NULL);
    MDLUpdateIcons(false);
    quit_thread(0);
}

void MDLTelechargement(DATA_MOD_DL* input)
{
    int ret_value = CODE_RETOUR_OK;

    /**Téléchargement**/
    TMP_DL dataDL;
    dataDL.URL = MDL_craftDownloadURL(*input->todoList);

    if(dataDL.URL == NULL)
    {
        logR("Memory error");
        ret_value = CODE_RETOUR_INTERNAL_FAIL;
    }
    else
    {
        do
        {
            dataDL.buf = NULL;
            ret_value = download_UI(&dataDL);
            free(dataDL.URL);

            if(dataDL.length < 50 && dataDL.buf != NULL && !strcmp(input->todoList->datas->team->type, TYPE_DEPOT_3))
            {
                /*Output du RSP, à gérer*/
                logR(dataDL.buf);
                if(dataDL.buf != NULL)
                    free(dataDL.buf);
                *input->currentState = MDL_CODE_ERROR_DL;
            }
            else if(ret_value != CODE_RETOUR_OK || dataDL.buf == NULL || dataDL.length < 50 || ((dataDL.buf[0] != 'P' || dataDL.buf[1] != 'K') && strncmp(dataDL.buf, "http://", 7) && strncmp(dataDL.buf, "https://", 8)))
            {
                if(dataDL.buf != NULL)
                    free(dataDL.buf);
                if(ret_value != CODE_RETOUR_DL_CLOSE)
                    *input->currentState = MDL_CODE_ERROR_DL;
                else //Quit
                {
                    *input->currentState = MDL_CODE_DEFAULT;
                    MDLDispDownloadHeader(NULL);
                }
            }
            else if(!strncmp(dataDL.buf, "http://", 7) || !strncmp(dataDL.buf, "https://", 8))
            {
                //Redirection
                dataDL.URL = dataDL.buf;
                continue;
            }
            else // Archive pas corrompue, installation
            {
                *input->currentState = MDL_CODE_DL_OVER;
                input->buf = dataDL.buf;
                input->length = dataDL.current_pos;
            }
        }while(0);
    }

    if(ret_value == CODE_RETOUR_INTERNAL_FAIL)
    {
        *input->currentState = MDL_CODE_ERROR_DL;
    }
    //On ne raffraichis pas l'écran car on va avoir à le faire un peu plus tard
    return;
}

void MDLInstallation(MDL_HANDLER_ARG input, DATA_MOD_DL data)
{
    bool subFolder, haveToPutTomeAsReadable;
    int extremes[2], erreurs = 0, dernierLu = -1, chapitre, tome;
    char temp[600], basePath[500];
    FILE* ressources = NULL;

    /*Récupération des valeurs envoyés*/
    MANGAS_DATA *mangaDB = input.todoList->datas;
    chapitre = input.todoList->chapitre;
    tome = input.todoList->partOfTome;
    subFolder = input.todoList->subFolder;
    haveToPutTomeAsReadable = input.isTomeAndLastElem;

    if(data.buf == NULL) //return;
    {
        return;
    }

    if(subFolder == true)
    {
        if(chapitre%10)
            snprintf(basePath, 500, "manga/%s/%s/Tome_%d/Chapitre_%d.%d", mangaDB->team->teamLong, mangaDB->mangaName, tome, chapitre/10, chapitre%10);
        else
            snprintf(basePath, 500, "manga/%s/%s/Tome_%d/Chapitre_%d", mangaDB->team->teamLong, mangaDB->mangaName, tome, chapitre/10);
    }
    else
    {
        if(chapitre%10)
            snprintf(basePath, 500, "manga/%s/%s/Chapitre_%d.%d", mangaDB->team->teamLong, mangaDB->mangaName, chapitre/10, chapitre%10);
        else
            snprintf(basePath, 500, "manga/%s/%s/Chapitre_%d", mangaDB->team->teamLong, mangaDB->mangaName, chapitre/10);
    }

    snprintf(temp, 600, "%s/%s", basePath, CONFIGFILE);
    ressources = fopenR(temp, "r");
    if(ressources == NULL)
    {
        /*Si le manga existe déjà*/
        snprintf(temp, 500, "manga/%s/%s/%s", mangaDB->team->teamLong, mangaDB->mangaName, CONFIGFILE);
        ressources = fopenR(temp, "r");
        if(ressources == NULL)
        {
            /*Si le dossier du manga n'existe pas*/
            snprintf(temp, 500, "manga/%s/%s", mangaDB->team->teamLong, mangaDB->mangaName);
            mkdirR(temp);
        }
        else
            fclose(ressources);

        /**Décompression dans le repertoire de destination**/

        //Création du répertoire de destination
        mkdirR(basePath);
        if(!checkDirExist(basePath))
            createPath(basePath);

        //On crée un message pour ne pas lire un chapitre en cours d'installe
        char temp_path_install[600];
        snprintf(temp_path_install, 600, "%s/installing", basePath);
        ressources = fopenR(temp_path_install, "w+");
        if(ressources != NULL)
            fclose(ressources);

        erreurs = miniunzip (data.buf, basePath, "", data.length, chapitre/10);
        removeR(temp_path_install);

        /*Si c'est pas un nouveau dossier, on modifie config.dat du manga*/
        if(!erreurs)
        {
            if(haveToPutTomeAsReadable)
            {
                char pathWithTemp[600], pathWithoutTemp[600];

                snprintf(pathWithTemp, 600, "manga/%s/%s/Tome_%d/%s.tmp", mangaDB->team->teamLong, mangaDB->mangaName, tome, CONFIGFILETOME);
                snprintf(pathWithoutTemp, 600, "manga/%s/%s/Tome_%d/%s", mangaDB->team->teamLong, mangaDB->mangaName, tome, CONFIGFILETOME);

                rename(pathWithTemp, pathWithoutTemp);
                if(!checkTomeReadable(*mangaDB, tome))
                    remove(pathWithoutTemp);
            }
            snprintf(temp, 600, "%s/%s", basePath, CONFIGFILE);
            ressources = fopenR(temp, "r");
        }
        snprintf(temp, 500, "manga/%s/%s/%s", mangaDB->team->teamLong, mangaDB->mangaName, CONFIGFILE);

        if(!subFolder && erreurs != -1 && ressources != NULL)
        {
            if(checkFileExist(temp))
            {
                fclose(ressources);
                ressources = fopenR(temp, "r+");
                fscanfs(ressources, "%d %d", &extremes[0], &extremes[1]);
                if(fgetc(ressources) != EOF)
                    fscanfs(ressources, "%d", &dernierLu);
                else
                    dernierLu = -1;
                fclose(ressources);
                ressources = fopenR(temp, "w+");
                if(extremes[0] > chapitre)
                    fprintf(ressources, "%d %d", chapitre, extremes[1]);

                else if(extremes[1] < chapitre)
                    fprintf(ressources, "%d %d", extremes[0], chapitre);

                else
                    fprintf(ressources, "%d %d", extremes[0], extremes[1]);
                if(dernierLu != -1)
                    fprintf(ressources, " %d", dernierLu);

                fclose(ressources);
            }
            else
            {
                fclose(ressources);
                /*Création du config.dat du nouveau manga*/
                snprintf(temp, 500, "manga/%s/%s/%s", mangaDB->team->teamLong, mangaDB->mangaName, CONFIGFILE);
                ressources = fopenR(temp, "w+");
                fprintf(ressources, "%d %d", chapitre, chapitre);
                fclose(ressources);
            }
        }

        else if(!subFolder)//Archive corrompue
        {
            if(ressources != NULL)
                fclose(ressources);
            snprintf(temp, 500, "Archive Corrompue: %s - %d\n", mangaDB->mangaName, chapitre);
            logR(temp);
            removeFolder(basePath);
            erreurs = 1;
        }
    }
    else
        fclose(ressources);

    if(erreurs)
        *data.currentState = MDL_CODE_ERROR_INSTALL;
    else
        *data.currentState = MDL_CODE_INSTALL_OVER;

    free(data.buf);
    return;
}

/*UI*/

int MDLDrawUI(DATA_LOADED** todoList, char trad[SIZE_TRAD_ID_22][TRAD_LENGTH])
{
    int curseurDebut = pageCourante * MDL_NOMBRE_ELEMENT_COLONNE, nbrElementDisp;
    char texte[200];
    SDL_Texture *texture = NULL;
    SDL_Rect position;
    SDL_Color couleurFont = {palette.police.r, palette.police.g, palette.police.b};
    TTF_Font *police = TTF_OpenFont(FONTUSED, MDL_SIZE_FONT_USED);

    MUTEX_LOCK(mutexDispIcons);
    applyBackground(rendererDL, 0, MDL_HAUTEUR_DEBUT_CATALOGUE, WINDOW_SIZE_W_DL, MDL_NOMBRE_ELEMENT_COLONNE*MDL_INTERLIGNE);

    if(police == NULL)
    {
        logR("Failed at initialize font");
        return -1;
    }

    for(nbrElementDisp = 0; nbrElementDisp < MDL_NOMBRE_ELEMENT_COLONNE * MDL_NOMBRE_COLONNE && curseurDebut+nbrElementDisp < nbElemTotal; nbrElementDisp++)
    {
        if(todoList[curseurDebut+nbrElementDisp] == NULL || todoList[curseurDebut+nbrElementDisp]->datas == NULL)
            continue;

        if(todoList[curseurDebut+nbrElementDisp]->partOfTome == VALEUR_FIN_STRUCTURE_CHAPITRE)
            snprintf(texte, 200, "%s %s %d", todoList[curseurDebut+nbrElementDisp]->datas->mangaName, trad[3], todoList[curseurDebut+nbrElementDisp]->chapitre / 10);
        else
            snprintf(texte, 200, "%s %s %d", todoList[curseurDebut+nbrElementDisp]->datas->mangaName, trad[4], todoList[curseurDebut+nbrElementDisp]->partOfTome);
        changeTo(texte, '_', ' ');

        texture = TTF_Write(rendererDL, police, texte, couleurFont);
        if(texture != NULL)
        {
            position.x = MDL_BORDURE_CATALOGUE + (nbrElementDisp / MDL_NOMBRE_ELEMENT_COLONNE) * MDL_ESPACE_INTERCOLONNE;
            position.y = MDL_HAUTEUR_DEBUT_CATALOGUE + (nbrElementDisp % MDL_NOMBRE_ELEMENT_COLONNE) * MDL_INTERLIGNE;
            position.w = texture->w;
            position.h = texture->h;
            SDL_RenderCopy(rendererDL, texture, NULL, &position);
            SDL_DestroyTexture(texture);
        }
    }
    //SDL_RenderPresent(rendererDL); //Erase icons, shouldn't print
    MUTEX_UNLOCK(mutexDispIcons);
    TTF_CloseFont(police);
    return nbrElementDisp;
}

void MDLUpdateIcons(bool ignoreCache)
{
    int posDansPage, posDebutPage = pageCourante * MDL_NOMBRE_ELEMENT_COLONNE;
    SDL_Texture *texture = NULL;
    SDL_Rect position;
    position.h = position.w = MDL_ICON_SIZE;

    MUTEX_LOCK(mutexDispIcons);

    for(posDansPage = 0; posDansPage < MDL_NOMBRE_COLONNE * MDL_NOMBRE_ELEMENT_COLONNE && posDebutPage + posDansPage < nbElemTotal; posDansPage++)
    {
        if(*status[posDebutPage + posDansPage] != *statusCache[posDebutPage + posDansPage] || ignoreCache)
        {
            position.x = MDL_ICON_POS + (posDansPage / MDL_NOMBRE_ELEMENT_COLONNE) * MDL_ESPACE_INTERCOLONNE;
            position.y = MDL_HAUTEUR_DEBUT_CATALOGUE + (posDansPage % MDL_NOMBRE_ELEMENT_COLONNE) * MDL_INTERLIGNE - (MDL_ICON_SIZE / 2 - MDL_LARGEUR_FONT / 2);
            SDL_RenderFillRect(rendererDL, &position);

            texture = getIconTexture(rendererDL, *status[posDebutPage + posDansPage]);
            if(texture != NULL)
            {
                SDL_RenderCopy(rendererDL, texture, NULL, &position);
                SDL_DestroyTexture(texture);
            }
            *statusCache[posDebutPage + posDansPage] = *status[posDebutPage + posDansPage];
        }
    }
    SDL_RenderPresent(rendererDL);
    MUTEX_UNLOCK(mutexDispIcons);
}

void MDLDispHeader(bool isInstall, DATA_LOADED *todoList)
{
    char texte[500], trad[SIZE_TRAD_ID_22][TRAD_LENGTH];
    SDL_Texture *texture = NULL;
    SDL_Rect position;
    SDL_Color couleurFont = {palette.police.r, palette.police.g, palette.police.b};
    TTF_Font *police = TTF_OpenFont(FONTUSED, MDL_SIZE_FONT_USED);
    loadTrad(trad, 22);

    MUTEX_LOCK(mutexDispIcons);
    if(isInstall)
        applyBackground(rendererDL, 0, HAUTEUR_TEXTE_INSTALLATION, WINDOW_SIZE_W_DL, MDL_HAUTEUR_DEBUT_CATALOGUE-HAUTEUR_TEXTE_INSTALLATION);
    else
        applyBackground(rendererDL, 0, HAUTEUR_TEXTE_TELECHARGEMENT, WINDOW_SIZE_W_DL, HAUTEUR_TEXTE_INSTALLATION-HAUTEUR_TEXTE_TELECHARGEMENT);

    if(police == NULL)
    {
        logR("Failed at initialize font");
        return;
    }

    if(todoList == NULL)
        usstrcpy(texte, TRAD_LENGTH, trad[5+isInstall]);
    else
    {
        snprintf(texte, 500, "%s %s %s %d %s %s", trad[isInstall], todoList->datas->mangaName, todoList->subFolder?trad[4]:trad[3], (todoList->subFolder?todoList->partOfTome:todoList->chapitre) / 10, trad[2], todoList->datas->team->teamLong);
        changeTo(texte, '_', ' ');
    }
    texture = TTF_Write(rendererDL, police, texte, couleurFont);
    if(texture != NULL)
    {
        position.x = WINDOW_SIZE_W_DL / 2 - texture->w / 2;
        if(isInstall)
            position.y = HAUTEUR_TEXTE_INSTALLATION;
        else
            position.y = HAUTEUR_TEXTE_TELECHARGEMENT;
        position.h = texture->h;
        position.w = texture->w;
        SDL_RenderCopy(rendererDL, texture, NULL, &position);
        SDL_DestroyTexture(texture);
        SDL_RenderPresent(rendererDL);
    }
    MUTEX_UNLOCK(mutexDispIcons);
}

bool MDLDispError(char trad[SIZE_TRAD_ID_22][TRAD_LENGTH])
{
    #warning "some todo there"
    return true;
}

/*Final processing*/
void MDLParseFile(DATA_LOADED **todoList, int **status, int nombreTotal, bool errorPrinted)
{
    int currentPosition;
    FILE *import = fopenR(INSTALL_DATABASE, "a+");
    if(import != NULL)
    {
        for(currentPosition = 0; currentPosition < nombreTotal; currentPosition++) //currentPosition a déjà été incrémenté par le for précédent
        {
            if(todoList[currentPosition] == NULL || *status[currentPosition] == MDL_CODE_INSTALL_OVER || (!errorPrinted && *status[currentPosition] <= MDL_CODE_ERROR_DL))
                continue;
            else if(todoList[currentPosition]->partOfTome != VALEUR_FIN_STRUCTURE_CHAPITRE)
            {
                if(todoList[currentPosition]->chapitre != VALEUR_FIN_STRUCTURE_CHAPITRE)
                {
                    int j;
                    fprintf(import, "%s %s T %d\n", todoList[currentPosition]->datas->team->teamCourt, todoList[currentPosition]->datas->mangaNameShort, todoList[currentPosition]->partOfTome);
                    for(j = currentPosition+1; j < nombreTotal; j++)
                    {
                        if(todoList[j] != NULL && todoList[j]->partOfTome == todoList[currentPosition]->partOfTome && todoList[j]->datas == todoList[currentPosition]->datas)
                        {
                            todoList[j]->chapitre = VALEUR_FIN_STRUCTURE_CHAPITRE;
                        }
                    }
                }
            }
            else if(todoList[currentPosition]->chapitre != VALEUR_FIN_STRUCTURE_CHAPITRE)
            {
                fprintf(import, "%s %s C %d\n", todoList[currentPosition]->datas->team->teamCourt, todoList[currentPosition]->datas->mangaNameShort, todoList[currentPosition]->chapitre);
            }
        }
        fclose(import);
    }
}

