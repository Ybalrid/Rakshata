/******************************************************************************************************
**  __________         __           .__            __                  ____     ____     ________    **
**  \______   \_____  |  | __  _____|  |__ _____ _/  |______    ___  _/_   |   /_   |    \_____  \   **
**   |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \   \  \/ /|   |    |   |     /  ____/   **
**   |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \_  \   / |   |    |   |    /       \   **
**   |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /   \_/  |___| /\ |___| /\ \_______ \  **
**          \/      \/     \/     \/     \/     \/          \/               \/       \/         \/  **
**                                                                                                   **
**         Licence propriétaire, code source confidentiel, distribution formellement interdite       **
**                                                                                                   **
******************************************************************************************************/
#include "main.h"

extern int INSTALL_DONE;
extern int CURRENT_TOKEN;

int WINDOW_SIZE_H_DL = 0;
int WINDOW_SIZE_W_DL = 0;
volatile int status;
static int error;
int INSTANCE_RUNNING = 0;

int telechargement()
{
    int i = 0, j = 0, k = 0, mangaActuel = 0, mangaTotal = 0, pourcentage = 0, glados = 0, posVariable = 0;
    char temp[200], mangaCourt[LONGUEUR_COURT], teamCourt[LONGUEUR_COURT], historiqueTeam[1000][LONGUEUR_COURT];
    char superTemp[400], trad[SIZE_TRAD_ID_22][100], MOT_DE_PASSE_COMPTE[100] = {0};
    FILE *fichier = NULL;
    DATA_LOADED **todoList = NULL, **todoListPtrBak = NULL;
    MANGAS_DATA* mangaDB = miseEnCache(LOAD_DATABASE_ALL);
    SDL_Texture *texte = NULL;
    TTF_Font *police_big = NULL;
    TTF_Font *police = NULL;
    SDL_Rect position;
	SDL_Color couleurTexte = {palette.police.r, palette.police.g, palette.police.b};
    SDL_Event event;
    OUT_DL* struc = NULL;

    error = 0;
    INSTALL_DONE = 0;
    CURRENT_TOKEN = 0;

#ifdef _WIN32
    HANDLE hSem = CreateSemaphore (NULL, 1, 1,"RakshataDL2");
    if (WaitForSingleObject (hSem, 0) == WAIT_TIMEOUT)
    {
        logR("Fail: instance already running\n");
        CloseHandle (hSem);
        return -1;
    }
#else
    FILE *fileBlocker = fopenR("data/download", "w+");
    fprintf(fileBlocker, "%d", getpid());
    fclose(fileBlocker);
#endif

    while(1)
    {
        if(!checkNetworkState(CONNEXION_TEST_IN_PROGRESS))
            break;
        SDL_PollEvent(&event);
        SDL_Delay(50);
    }


    if(checkNetworkState(CONNEXION_DOWN))
    {
        quit_thread(0);
    }

    police_big = TTF_OpenFont(FONTUSED, POLICE_GROS);
    police = TTF_OpenFont(FONTUSED, POLICE_MOYEN);

    fichier = fopenR(INSTALL_DATABASE, "r");
    if(fichier == NULL)
        return 0;

    /*On compte le nombre de mangas*/
    mangaTotal = 0;
    while((i = fgetc(fichier)) != EOF)
    {
        if(i == '\n')
            mangaTotal++;
    }
    if(!mangaTotal)
        mangaTotal = 1; //Si un seul manga sans retour à la ligne

    rewind(fichier);

    todoListPtrBak = todoList = calloc(mangaTotal+1, sizeof(DATA_LOADED*));
    for(i = 0; i < mangaTotal; todoList[i++] = (DATA_LOADED*) calloc(1, sizeof(DATA_LOADED)));

    if(todoList == NULL)
    {
        char temp[200];
        snprintf(temp, 200, "Failed at allocate: %d * %d bytes", mangaTotal, LONGUEUR_COURT*2 + 50);
        logR(temp);
        return -1;
    }

    for(j = k = 0; j < mangaTotal && (i = fgetc(fichier)) != EOF;)
    {
        fseek(fichier, -1, SEEK_CUR);
        fscanfs(fichier, "%s %s %d", teamCourt, LONGUEUR_COURT, mangaCourt, LONGUEUR_COURT, &k);
        if(posVariable < NOMBRE_MANGA_MAX && !strcmp(mangaDB[posVariable].mangaNameShort, mangaCourt) && !strcmp(mangaDB[posVariable].team->teamCourt, teamCourt)) //On vérifie si c'estpas le même manga, pour éviter de se retapper toute la liste
        {
            todoList[j]->chapitre = k;
            todoList[j++]->datas = &mangaDB[posVariable];
        }
        else
        {
            for(posVariable = 0; posVariable < NOMBRE_MANGA_MAX && (strcmp(mangaDB[posVariable].mangaNameShort, mangaCourt) || strcmp(mangaDB[posVariable].team->teamCourt, teamCourt)); posVariable++);
            if(posVariable < NOMBRE_MANGA_MAX && !strcmp(mangaDB[posVariable].mangaNameShort, mangaCourt) && !strcmp(mangaDB[posVariable].team->teamCourt, teamCourt)) //On vérifie si c'estpas le même manga, pour éviter de se retapper toute la liste
            {
                todoList[j]->chapitre = k;
                todoList[j++]->datas = &mangaDB[posVariable];
            }
        }
    }
    qsort(todoList, j, sizeof(DATA_LOADED*), sortMangasToDownload);
    fclose(fichier);
    removeR(INSTALL_DATABASE);
    mangaTotal--; //On décale d'un cran
    int nbrMaxElem = (mangaTotal+1>1000)?1000:(mangaTotal+1);

    for(i = 0; i < nbrMaxElem; historiqueTeam[i++][0] = 0);
    loadTrad(trad, 22);

    for(mangaActuel = 1; mangaTotal >= 0 && glados != CODE_RETOUR_DL_CLOSE; mangaActuel++) //On démarre à 1 car sinon, le premier pourcentage serait de 0
    {
        if(mangaTotal + (mangaActuel - 1) != 0)
            pourcentage = mangaActuel * 100 / (mangaTotal + mangaActuel);
        else
            pourcentage = 100;

        /*Extraction du chapitre*/
        do
        {
            if(todoList[0]->datas != NULL)
            {
                /*Ouverture du site de la team*/
                for(i = 0; i < nbrMaxElem && historiqueTeam[i][0] && strcmp(todoList[0]->datas->team->teamCourt, historiqueTeam[i]) != 0 && historiqueTeam[i][0] != 0; i++);
                if(i < nbrMaxElem && historiqueTeam[i][0] == 0) //Si pas déjà installé
                {
                    ustrcpy(historiqueTeam[i], todoList[0]->datas->team->teamCourt);
                    ouvrirSite(todoList[0]->datas->team);
                }

                /*Génération de l'URL*/
                if (!strcmp(todoList[0]->datas->team->type, TYPE_DEPOT_1))
                {
                    if(todoList[0]->chapitre%10)
                        snprintf(superTemp, 400, "https://dl.dropboxusercontent.com/u/%s/%s/%s_Chapitre_%d.%d.zip", todoList[0]->datas->team->URL_depot, todoList[0]->datas->mangaName, todoList[0]->datas->mangaNameShort, todoList[0]->chapitre/10, todoList[0]->chapitre%10);
                    else
                        snprintf(superTemp, 400, "https://dl.dropboxusercontent.com/u/%s/%s/%s_Chapitre_%d.zip", todoList[0]->datas->team->URL_depot, todoList[0]->datas->mangaName, todoList[0]->datas->mangaNameShort, todoList[0]->chapitre/10);
                }

                else if (!strcmp(todoList[0]->datas->team->type, TYPE_DEPOT_2))
                {
                    if(todoList[0]->chapitre%10)
                        snprintf(superTemp, 400, "http://%s/%s/%s_Chapitre_%d.%d.zip", todoList[0]->datas->team->URL_depot, todoList[0]->datas->mangaName, todoList[0]->datas->mangaNameShort, todoList[0]->chapitre/10, todoList[0]->chapitre%10);
                    else
                        snprintf(superTemp, 400, "http://%s/%s/%s_Chapitre_%d.zip", todoList[0]->datas->team->URL_depot, todoList[0]->datas->mangaName, todoList[0]->datas->mangaNameShort, todoList[0]->chapitre/10);
                }

                else if (!strcmp(todoList[0]->datas->team->type, TYPE_DEPOT_3)) //DL Payant
                {
                    if(MOT_DE_PASSE_COMPTE[0] == -1)
                        break;

                    else if((i = getPassword(MOT_DE_PASSE_COMPTE, 1, 1)) == 1)
                        snprintf(superTemp, 400, "https://rsp.%s/main_controler.php?ver=%d&target=%s&project=%s&chapter=%d&mail=%s&pass=%s", MAIN_SERVER_URL[0], CURRENTVERSION, todoList[0]->datas->team->URL_depot, todoList[0]->datas->mangaName, todoList[0]->chapitre, COMPTE_PRINCIPAL_MAIL, MOT_DE_PASSE_COMPTE);

                    else if(i == PALIER_QUIT)
                    {
                        glados = CODE_RETOUR_DL_CLOSE;
                        break;
                    }

                    else
                        MOT_DE_PASSE_COMPTE[0] = -1;

                    chargement(rendererDL, WINDOW_SIZE_H_DL, WINDOW_SIZE_W_DL);
                }

                else
                {
                    snprintf(superTemp, 400, "URL non gérée: %s\n", todoList[0]->datas->team->type);
                    logR(superTemp);
                    break;
                }

                /*Affichage du DL*/
                crashTemp(temp, 200);

                changeTo(todoList[0]->datas->mangaName, '_', ' ');
                if(todoList[0]->chapitre%10)
                    snprintf(temp, 200, "%s %s %s %d.%d %s %s (%d%% %s)", trad[0], todoList[0]->datas->mangaName, trad[1], todoList[0]->chapitre/10, todoList[0]->chapitre%10, trad[2], todoList[0]->datas->team->teamCourt, pourcentage, trad[3]);
                else
                    snprintf(temp, 200, "%s %s %s %d %s %s (%d%% %s)", trad[0], todoList[0]->datas->mangaName, trad[1], todoList[0]->chapitre/10, trad[2], todoList[0]->datas->team->teamCourt, pourcentage, trad[3]);
                changeTo(todoList[0]->datas->mangaName, ' ', '_');

                //On remplis la fenêtre
                SDL_RenderClear(rendererDL);
                texte = TTF_Write(rendererDL, police_big, trad[4], couleurTexte);
                position.x = WINDOW_SIZE_W_DL / 2 - texte->w / 2;
                position.y = HAUTEUR_MESSAGE_INITIALISATION;
                position.h = texte->h;
                position.w = texte->w;
                SDL_RenderCopy(rendererDL, texte, NULL, &position);
                SDL_DestroyTextureS(texte);

                texte = TTF_Write(rendererDL, police, temp, couleurTexte);
                position.x = WINDOW_SIZE_W_DL / 2 - texte->w / 2;
                position.y = HAUTEUR_TEXTE_TELECHARGEMENT;
                position.h = texte->h;
                position.w = texte->w;
                SDL_RenderCopy(rendererDL, texte, NULL, &position);
                SDL_DestroyTextureS(texte);

                SDL_RenderPresent(rendererDL);

                /**Téléchargement**/

                /*On teste si le chapitre est déjà installé*/
                crashTemp(temp, 200);
                if(todoList[0]->chapitre%10)
                    snprintf(temp, 200, "manga/%s/%s/Chapitre_%d.%d/%s", todoList[0]->datas->team->teamLong, todoList[0]->datas->mangaName, todoList[0]->chapitre/10, todoList[0]->chapitre%10, CONFIGFILE);
                else
                    snprintf(temp, 200, "manga/%s/%s/Chapitre_%d/%s", todoList[0]->datas->team->teamLong, todoList[0]->datas->mangaName, todoList[0]->chapitre/10, CONFIGFILE);
                if(!checkFileExist(temp))
                {
                    glados = CODE_RETOUR_OK;
                    struc = download_UI(superTemp);

                    if(struc <= (OUT_DL*) CODE_RETOUR_MAX)
                    {
                        glados = (int)struc;
                        if(glados == CODE_RETOUR_DL_CLOSE)
                            break;
                    }

                    else if(struc->buf == NULL || struc->length < 50 || struc->length > 400*1024*1024 || struc->buf[0] != 'P' || struc->buf[1] != 'K')
                    {
                        if(struc->buf == NULL)
                        {
                            snprintf(superTemp, 400, "Erreur dans le telechargement d'un chapitre: Team: %s\n", todoList[0]->datas->team->teamLong);
                            logR(superTemp);
                        }
                        else
                        {
                            if(!strcmp(todoList[0]->datas->team->type, TYPE_DEPOT_3) && struc->length < 50)
                                logR(struc->buf);
                            free(struc->buf);
                        }
                        free(struc);
                        glados = CODE_RETOUR_INTERNAL_FAIL;//On annule l'installation
                    }
                }

                if(glados == CODE_RETOUR_OK) // Archive pas corrompue
                {
                    status += 1; //On signale le lancement d'une installation
                    nameWindow(windowDL, status);

                    /**Installation**/
                    DATA_INSTALL* data_instal = malloc(sizeof(DATA_INSTALL));
                    data_instal->mangaDB = *todoList[0]->datas;
                    data_instal->chapitre = todoList[0]->chapitre;
                    data_instal->buf = struc;
                    createNewThread(installation, data_instal);
                }

                else if(glados == CODE_RETOUR_INTERNAL_FAIL)
                {
                    glados = CODE_RETOUR_OK;
                    snprintf(temp, 200, "Echec telechargement: %s - %d\n", todoList[0]->datas->mangaName, todoList[0]->chapitre);
                    logR(temp);
                    error++;
                }

                snprintf(temp, 200, "manga/%s/%s/infos.png", todoList[0]->datas->team->teamLong, todoList[0]->datas->mangaName);
                if(todoList[0]->datas->pageInfos && !checkFileExist(temp)) //k peut avoir a être > 1
                {
                    snprintf(temp, 200, "manga/%s/%s/%s", todoList[0]->datas->team->teamLong, todoList[0]->datas->mangaName, CONFIGFILE);
                    if(!checkFileExist(temp))
                    {
                        crashTemp(temp, TAILLE_BUFFER);
                        snprintf(temp, 200, "manga/%s", todoList[0]->datas->team->teamLong);
                        mkdirR(temp);
                        snprintf(temp, 200, "manga/%s/%s", todoList[0]->datas->team->teamLong, todoList[0]->datas->mangaName);
                        mkdirR(temp);
                    }

                    crashTemp(superTemp, 400);
                    /*Génération de l'URL*/
                    if(!strcmp(todoList[0]->datas->team->type, TYPE_DEPOT_1))
                    {
                        snprintf(superTemp, 400, "https://dl.dropboxusercontent.com/u/%s/%s/infos.png", todoList[0]->datas->team->URL_depot, todoList[0]->datas->mangaName);
                    }
                    else if (!strcmp(todoList[0]->datas->team->type, TYPE_DEPOT_2))
                    {
                        snprintf(superTemp, 400, "http://%s/%s/infos.png", todoList[0]->datas->team->URL_depot, todoList[0]->datas->mangaName);
                    }
                    else if(!strcmp(todoList[0]->datas->team->type, TYPE_DEPOT_3))
                    {
                        snprintf(superTemp, 400, "https://%s/getinfopng.php?owner=%s&manga=%s", MAIN_SERVER_URL[0], todoList[0]->datas->team->teamLong, todoList[0]->datas->mangaName);
                    }
                    else
                    {
                        snprintf(superTemp, 400, "URL non gérée: %s\n", todoList[0]->datas->team->type);
                        logR(superTemp);
                        continue;
                    }

                    crashTemp(temp, TAILLE_BUFFER);
                    snprintf(temp, 200, "manga/%s/%s/infos.png", todoList[0]->datas->team->teamLong, todoList[0]->datas->mangaName);
                    download_disk(superTemp, temp, strcmp(todoList[0]->datas->team->type, TYPE_DEPOT_2)?1:0);
                }

                else if(!todoList[0]->datas->pageInfos && checkFileExist(temp))//Si k = 0 et infos.png existe
                    removeR(temp);
            }
        } while(0); //Permet d'interrompre le code avec break;

        if(glados == CODE_RETOUR_OK)
        {
            DATA_LOADED **newBufferTodo = NULL;
            if(INSTANCE_RUNNING == -1 && checkFileExist(INSTALL_DATABASE))
            {
                int oldSize = mangaTotal;
                fichier = fopenR(INSTALL_DATABASE, "r");
                while((i = fgetc(fichier)) != EOF)
                {
                    if(i == '\n')
                        mangaTotal++;
                }
                rewind(fichier);
                if(mangaTotal)
                {
                    newBufferTodo = calloc(mangaTotal, sizeof(DATA_LOADED*));
                    for(i = 0; i < mangaTotal; i++)
                    {
                        newBufferTodo[i] = calloc(1, sizeof(DATA_LOADED));
                        if(i < oldSize) //Pas besoin de oldSize != 0 car i commence à 0 et (0 < 0) = 0
                        {
                            newBufferTodo[i]->chapitre = todoList[i+1]->chapitre;
                            newBufferTodo[i]->datas = todoList[i+1]->datas;
                            free(todoList[i+1]);
                        }
                    }
                    free(todoList[0]);
                    free(todoList);
                    todoListPtrBak = todoList = newBufferTodo;

                    for(j = oldSize; j < mangaTotal && (i = fgetc(fichier)) != EOF;)
                    {
                        fseek(fichier, -1, SEEK_CUR);
                        fscanfs(fichier, "%s %s %d", teamCourt, LONGUEUR_COURT, mangaCourt, LONGUEUR_COURT, &k);

                        if(posVariable < NOMBRE_MANGA_MAX && !strcmp(mangaDB[posVariable].mangaNameShort, mangaCourt) && !strcmp(mangaDB[posVariable].team->teamCourt, teamCourt)) //On vérifie si c'estpas le même manga, pour éviter de se retapper toute la liste
                        {
                            newBufferTodo[j]->chapitre = k;
                            newBufferTodo[j++]->datas = &mangaDB[posVariable];
                        }
                        else
                        {
                            for(posVariable = 0; posVariable < NOMBRE_MANGA_MAX && (strcmp(mangaDB[posVariable].mangaNameShort, mangaCourt) || strcmp(mangaDB[posVariable].team->teamCourt, teamCourt)); posVariable++);
                            if(posVariable < NOMBRE_MANGA_MAX && !strcmp(mangaDB[posVariable].mangaNameShort, mangaCourt) && !strcmp(mangaDB[posVariable].team->teamCourt, teamCourt)) //On vérifie si c'estpas le même manga, pour éviter de se retapper toute la liste
                            {
                                newBufferTodo[j]->chapitre = k;
                                newBufferTodo[j++]->datas = &mangaDB[posVariable];
                            }
                        }
                    }
                    qsort(newBufferTodo, j, sizeof(DATA_LOADED*), sortMangasToDownload);
                    fclose(fichier);
                    removeR(INSTALL_DATABASE);
                }
            }
            else
            {
                newBufferTodo = &todoList[1];
                free(todoList[0]);
                todoList = newBufferTodo;
            }
            mangaTotal--;
        }
    }
    if(glados != CODE_RETOUR_OK)
    {
        fichier = fopenR(INSTALL_DATABASE, "a+");
        if(fichier != NULL)
        {
            for(i = 0; i <= mangaTotal; i++)
            {
                fprintf(fichier, "%s %s %d\n", todoList[i]->datas->team->teamCourt, todoList[i]->datas->mangaNameShort, todoList[i]->chapitre);
                free(todoList[i]);
            }
            fclose(fichier);
        }
    }
    else
    {
        if(todoList != NULL)
            free(todoList[0]);
    }
    free(todoListPtrBak);

    SDL_RenderClear(rendererDL);
    texte = TTF_Write(rendererDL, police_big, trad[5], couleurTexte);
    position.x = WINDOW_SIZE_W_DL / 2 - texte->w / 2;
    position.y = WINDOW_SIZE_H_DL / 2 - texte->h / 2;
    position.h = texte->h;
    position.w = texte->w;
    SDL_RenderCopy(rendererDL, texte, NULL, &position);
    SDL_DestroyTextureS(texte);

    SDL_RenderPresent(rendererDL);
    TTF_CloseFont(police_big);
    TTF_CloseFont(police);

    while(status > 1)
    {
        SDL_Delay(250);
        event.type = 0;
        SDL_WaitEventTimeout(&event, 1000);
        SDL_RenderPresent(rendererDL);
        if(event.type != 0 && !haveInputFocus(&event, windowDL))
            SDL_PushEvent(&event);
    }

    chargement(rendererDL, WINDOW_SIZE_H_DL, WINDOW_SIZE_W_DL);
    freeMangaData(mangaDB, NOMBRE_MANGA_MAX);//On libère la mémoire utilisé seulement quand c'est vraiment fini.
    INSTANCE_RUNNING = 0;

#ifdef _WIN32
    ReleaseSemaphore (hSem, 1, NULL);
    CloseHandle (hSem);
#else
    removeR("data/download");
#endif
    if(glados == CODE_RETOUR_DL_CLOSE)
        return -1;
    return 0;
}

#ifdef _WIN32
DWORD WINAPI installation(LPVOID datas)
#else
void* installation(void* datas)
#endif
{
    int extremes[2], erreurs = 0, dernierLu = -1, chapitre = 0;
    char temp[TAILLE_BUFFER];
    size_t length;
    FILE* ressources = NULL;

    DATA_INSTALL *valeurs = (DATA_INSTALL*)datas;

    /*Récupération des valeurs envoyés*/
    MANGAS_DATA mangaDB = valeurs->mangaDB;
    chapitre = valeurs->chapitre;
    if(valeurs->buf == NULL) //return;
    {
        free(valeurs);
        status--; //On signale la fin de l'installation
        nameWindow(windowDL, status);
        quit_thread(0);
    }
    length = valeurs->buf->length;

    if(chapitre%10)
        snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d.%d/%s", mangaDB.team->teamLong, mangaDB.mangaName, chapitre/10, chapitre%10, CONFIGFILE);
    else
        snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d/%s", mangaDB.team->teamLong, mangaDB.mangaName, chapitre/10, CONFIGFILE);
    ressources = fopenR(temp, "r");
    if(ressources == NULL)
    {
        /*Si le manga existe déjà*/
        snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/%s", mangaDB.team->teamLong, mangaDB.mangaName, CONFIGFILE);
        ressources = fopenR(temp, "r");
        if(ressources == NULL)
        {
            /*Si le dossier du manga n'existe pas*/
            snprintf(temp, TAILLE_BUFFER, "manga/%s/%s", mangaDB.team->teamLong, mangaDB.mangaName);
            #ifdef _WIN32
                mkdir(temp);
            #else
                mkdir(temp, PERMISSIONS);
            #endif
        }
        else
            fclose(ressources);

        /**Décompression dans le repertoire de destination**/

        /*Création du répertoire de destination*/
        if(chapitre%10)
            snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d.%d", mangaDB.team->teamLong, mangaDB.mangaName, chapitre/10, chapitre%10);
        else
            snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d", mangaDB.team->teamLong, mangaDB.mangaName, chapitre/10);
        mkdirR(temp);

        //On crée un message pour ne pas lire un chapitre en cours d'installe
        char temp_path_install[TAILLE_BUFFER];
        if(chapitre%10)
            snprintf(temp_path_install, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d.%d/installing", mangaDB.team->teamLong, mangaDB.mangaName, chapitre/10, chapitre%10);
        else
            snprintf(temp_path_install, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d/installing", mangaDB.team->teamLong, mangaDB.mangaName, chapitre/10);
        ressources = fopenR(temp_path_install, "w+");
        if(ressources != NULL)
            fclose(ressources);

        erreurs = miniunzip (valeurs->buf->buf, temp, "", valeurs->buf->length, chapitre);

        removeR(temp_path_install);

        /*Si c'est pas un nouveau dossier, on modifie config.dat du manga*/
        if(!erreurs)
        {
            if(chapitre%10)
                snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d.%d/%s", mangaDB.team->teamLong, mangaDB.mangaName, chapitre/10, chapitre%10, CONFIGFILE);
            else
                snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d/%s", mangaDB.team->teamLong, mangaDB.mangaName, chapitre/10, CONFIGFILE);
            ressources = fopenR(temp, "r");
        }

        snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/%s", mangaDB.team->teamLong, mangaDB.mangaName, CONFIGFILE);
        if(erreurs != -1 && checkFileExist(temp) && ressources != NULL)
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

        else if(erreurs != -1 && !checkFileExist(temp) && ressources != NULL)
        {
            fclose(ressources);
            /*Création du config.dat du nouveau manga*/
            snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/%s", mangaDB.team->teamLong, mangaDB.mangaName, CONFIGFILE);
            ressources = fopenR(temp, "w+");
            fprintf(ressources, "%d %d", chapitre, chapitre);
            fclose(ressources);
        }

        else //Archive corrompue
        {
            if(ressources != NULL)
                fclose(ressources);
            snprintf(temp, TAILLE_BUFFER, "Archive Corrompue: %s - %d\n", mangaDB.mangaName, chapitre);
            logR(temp);
            if(chapitre%10)
                snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d.%d", mangaDB.team->teamLong, mangaDB.mangaName, chapitre/10, chapitre%10);
            else
                snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d", mangaDB.team->teamLong, mangaDB.mangaName, chapitre/10);
            removeFolder(temp);
            erreurs = 1;
        }
    }
    else
        fclose(ressources);

    if(erreurs)
        error++; //On note si le chapitre a posé un probléme

    if(length == valeurs->buf->length)
        free(valeurs->buf->buf);
    free(valeurs->buf);
    free(valeurs);

    int staBack = status;
    while(staBack == status)
        status--;

    nameWindow(windowDL, status);
    quit_thread(0);
}

int ecritureDansImport(MANGAS_DATA mangaDB, int chapitreChoisis)
{
    FILE* fichier = NULL;
    char temp[TAILLE_BUFFER];
    int i = 0, nombreChapitre = 0;

    /*On ouvre le fichier d'import*/
    fichier = fopenR(INSTALL_DATABASE, "a+");

    if(chapitreChoisis != VALEUR_FIN_STRUCTURE_CHAPITRE)
    {
		nombreChapitre = 1;
        /*On test l'existance du fichier (zipé ou dézipé)*/
        if(chapitreChoisis%10)
                snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d.%d/%s", mangaDB.team->teamLong, mangaDB.mangaName, chapitreChoisis/10, chapitreChoisis%10, CONFIGFILE);
            else
                snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d/%s", mangaDB.team->teamLong, mangaDB.mangaName, chapitreChoisis/10, CONFIGFILE);
        if(!checkFileExist(temp))
            fprintf(fichier, "%s %s %d\n", mangaDB.team->teamCourt, mangaDB.mangaNameShort, chapitreChoisis);
    }
    else
    {
        for(i = 0; mangaDB.chapitres[i] != VALEUR_FIN_STRUCTURE_CHAPITRE; i++)
        {
            if(mangaDB.chapitres[i]%10)
                snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d.%d/%s", mangaDB.team->teamLong, mangaDB.mangaName, mangaDB.chapitres[i]/10, mangaDB.chapitres[i]%10, CONFIGFILE);
            else
                snprintf(temp, TAILLE_BUFFER, "manga/%s/%s/Chapitre_%d/%s", mangaDB.team->teamLong, mangaDB.mangaName, mangaDB.chapitres[i]/10, CONFIGFILE);
            if(!checkFileExist(temp))
            {
                fprintf(fichier, "%s %s %d\n", mangaDB.team->teamCourt, mangaDB.mangaNameShort, mangaDB.chapitres[i]);
                nombreChapitre++;
            }
        }
    }
    fclose(fichier);
	return nombreChapitre;
}

void DLmanager()
{
    char temp[TAILLE_BUFFER], texteTrad[SIZE_TRAD_ID_16][LONGUEURTEXTE];
	SDL_Texture *texte = NULL;
    TTF_Font *police = NULL;
    SDL_Color couleurTexte = {palette.police.r, palette.police.g, palette.police.b};
	SDL_Rect position;

    /*On affiche la petite fenêtre, on peut pas utiliser un mutex à cause
    d'une réservation à deux endroits en parallèle, qui cause des crashs*/

    SDL_FlushEvent(SDL_WINDOWEVENT);
    windowDL = SDL_CreateWindow(PROJECT_NAME, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, LARGEUR, HAUTEUR_FENETRE_DL, SDL_WINDOW_OPENGL);
    SDL_FlushEvent(SDL_WINDOWEVENT);

    loadIcon(windowDL);
    status = 1;
    nameWindow(windowDL, status);

    SDL_FlushEvent(SDL_WINDOWEVENT);
    rendererDL = setupRendererSafe(windowDL);
    SDL_FlushEvent(SDL_WINDOWEVENT);

    WINDOW_SIZE_W_DL = LARGEUR;
    WINDOW_SIZE_H_DL = HAUTEUR_FENETRE_DL;

    chargement(rendererDL, WINDOW_SIZE_H_DL, WINDOW_SIZE_W_DL);

    int output = telechargement();

    SDL_Renderer *rendererDLCurrent = rendererDL;
    SDL_Window *windowDLCurrent = windowDL;

    rendererDL = NULL;
    windowDL = NULL;

    //Chargement de la traduction
    loadTrad(texteTrad, 16);
    police = TTF_OpenFont(FONTUSED, POLICE_MOYEN);
    SDL_RenderClear(rendererDLCurrent);
    if(!error && !output)
    {
        texte = TTF_Write(rendererDLCurrent, police, texteTrad[0], couleurTexte);
        position.x = WINDOW_SIZE_W_DL / 2 - texte->w / 2;
        position.y = WINDOW_SIZE_H_DL / 2 - texte->h / 2 * 3;
        position.h = texte->h;
        position.w = texte->w;
        SDL_RenderCopy(rendererDLCurrent, texte, NULL, &position);
        SDL_DestroyTextureS(texte);

        texte = TTF_Write(rendererDLCurrent, police, texteTrad[1], couleurTexte);
        position.x = WINDOW_SIZE_W_DL / 2 - texte->w / 2;
        position.y = WINDOW_SIZE_H_DL / 2 + texte->h / 2;
        position.h = texte->h;
        position.w = texte->w;
        SDL_RenderCopy(rendererDLCurrent, texte, NULL, &position);
        SDL_DestroyTextureS(texte);

        SDL_RenderPresent(rendererDLCurrent);
        waitEnter(rendererDLCurrent);
    }
    else if (error > 0 && output != -1)
    {
        snprintf(temp, TAILLE_BUFFER, "%s %d %s", texteTrad[2], error, texteTrad[3]);

        texte = TTF_Write(rendererDLCurrent, police, temp, couleurTexte);
        position.x = WINDOW_SIZE_W_DL / 2 - texte->w / 2;
        position.y = HAUTEUR_TEXTE_TELECHARGEMENT - texte->h - MINIINTERLIGNE;
        position.h = texte->h;
        position.w = texte->w;
        SDL_RenderCopy(rendererDLCurrent, texte, NULL, &position);
        SDL_DestroyTextureS(texte);

        texte = TTF_Write(rendererDLCurrent, police, texteTrad[4], couleurTexte);
        position.x = WINDOW_SIZE_W_DL / 2 - texte->w / 2;
        position.y = HAUTEUR_TEXTE_TELECHARGEMENT;
        position.h = texte->h;
        position.w = texte->w;
        SDL_RenderCopy(rendererDLCurrent, texte, NULL, &position);
        SDL_DestroyTextureS(texte);

        texte = TTF_Write(rendererDLCurrent, police, texteTrad[5], couleurTexte);
        position.x = WINDOW_SIZE_W / 2 - texte->w / 2;
        position.y = HAUTEUR_TEXTE_TELECHARGEMENT + texte->h + MINIINTERLIGNE;
        position.h = texte->h;
        position.w = texte->w;
        SDL_RenderCopy(rendererDLCurrent, texte, NULL, &position);
        SDL_DestroyTextureS(texte);

        SDL_RenderPresent(rendererDLCurrent);
        waitEnter(rendererDLCurrent);
    }
    TTF_CloseFont(police);
    SDL_DestroyRenderer(rendererDLCurrent);
    SDL_DestroyWindow(windowDLCurrent);
    return;
}

void lancementModuleDL()
{
    SDL_Event event;
    createNewThread(mainDL, NULL);
    while(1)
    {
        if(windowDL != NULL)
            break;
        SDL_PollEvent(&event);
        SDL_Delay(100);
    }
}

void updateWindowSizeDL(int w, int h)
{
    if(WINDOW_SIZE_H_DL != h || WINDOW_SIZE_W_DL != w)
    {
        WINDOW_SIZE_H_DL = h; //Pour repositionner chargement
        WINDOW_SIZE_W_DL = w;

        chargement(rendererDL, WINDOW_SIZE_H_DL, WINDOW_SIZE_W_DL);

        SDL_SetWindowSize(windowDL, w, h);

        if(WINDOW_SIZE_H_DL > h || WINDOW_SIZE_W_DL > w)
        {
            SDL_RenderClear(rendererDL);
            SDL_RenderPresent(rendererDL);
        }
        WINDOW_SIZE_H_DL = windowDL->h;
        WINDOW_SIZE_W_DL = windowDL->w;
    }
    else
    {
        SDL_RenderClear(rendererDL);
        SDL_RenderPresent(rendererDL);
    }
}

