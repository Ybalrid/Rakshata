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

//Macro pour libérer plus facilement la mémoire
#define FREE_CONTEXT() cleanMemory(dataReader, chapitre, chapitre_texture, OChapitre, NChapitre, UI_PageAccesDirect, infoSurface, bandeauControle, police)
#define REFRESH_SCREEN() refreshScreen(chapitre_texture, positionSlide, positionPage, positionBandeauControle, bandeauControle, infoSurface, positionInfos, pageAccesDirect, UI_PageAccesDirect)

extern int unlocked;
extern int pageWaaaayyyyTooBig;

typedef struct data_lecture_tome
{
    int nombrePageTotale;
    int pageCourante;
    int *pageCouranteDuChapitre;

    int *pathNumber; //Correspondance entre nomPage et path
    char **nomPages;
    char **path;

    int IDDisplayed;
    int *chapitreTomeCPT; //Pour la crypto
} DATA_LECTURE;

typedef struct data_thread_check_new_CT
{
    MANGAS_DATA mangaDB;
    bool isTome;
    int CT;
    int * fullscreen;
} DATA_CK_LECTEUR;

/** lecteur_event.c **/

int clicOnButton(const int x, const int y, const int positionBandeauX);
void applyFullscreen(int *var_fullscreen, int *checkChange, int *changementEtat);

/** lecteur_check_newElems.c **/

void startCheckNewElementInRepo(MANGAS_DATA mangaDB, bool isTome, int CT, int * fullscreen);
void checkNewElementInRepo(DATA_CK_LECTEUR *input);
void addtoDownloadListFromReader(MANGAS_DATA mangaDB, int firstElem, bool isTome);

/** lecteur_loading.c **/

int configFileLoader(MANGAS_DATA *mangaDB, bool isTome, int chapitre_tome, DATA_LECTURE* dataReader);
char ** loadChapterConfigDat(char* input, int *nombrePage);
void slideOneStepDown(SDL_Surface *chapitre, SDL_Rect *positionSlide, SDL_Rect *positionPage, int ctrlPressed, int pageTropGrande, int move, int *noRefresh);
void slideOneStepUp(SDL_Surface *chapitre, SDL_Rect *positionSlide, SDL_Rect *positionPage, int ctrlPressed, int pageTropGrande, int move, int *noRefresh);
int changementDePage(MANGAS_DATA *mangaDB, DATA_LECTURE* dataReader, bool isTome, bool goToNextPage, int *changementPage, int *finDuChapitre, int *chapitreChoisis, int currentPosIntoStructure);
int changementDeChapitre(MANGAS_DATA* mangaDB, bool isTome, int posIntoStructToTest, int *chapitreChoisis);

/**	lecteur_ui.c	**/
SDL_Texture* loadControlBar(int favState);
void generateMessageInfoLecteur(MANGAS_DATA mangaDB, DATA_LECTURE dataReader, char localization[SIZE_TRAD_ID_21][TRAD_LENGTH], bool isTome, int fullscreen, int curPosIntoStruct, char* output, int sizeOut);
void cleanMemory(DATA_LECTURE dataReader, SDL_Surface *chapitre, SDL_Texture *chapitre_texture, SDL_Surface *OChapitre, SDL_Surface *NChapitre, SDL_Surface *UI_PageAccesDirect, SDL_Texture *infoSurface, SDL_Texture *bandeauControle, TTF_Font *police);
void freeCurrentPage(SDL_Texture *texture);
void refreshScreen(SDL_Texture *chapitre, SDL_Rect positionSlide, SDL_Rect positionPage, SDL_Rect positionBandeauControle, SDL_Texture *bandeauControle, SDL_Texture *infoSurface, SDL_Rect positionInfos, int pageAccesDirect, SDL_Surface *UI_pageAccesDirect);
void afficherMessageRestauration(char* title, char* content, char* noMoreDisplay, char* OK);


/*Mouvements*/
#define DEPLACEMENT 50
#define DEPLACEMENT_BIG positionSlide.h - BORDURE_CONTROLE_LECTEUR
#define DEPLACEMENT_SOURIS 7
#define DEPLACEMENT_LATERAL_PAGE 5
#define DEPLACEMENT_HORIZONTAL_PAGE 5
#define TOLERANCE_CLIC_PAGE 10

/*Limites buffers*/
#define LONGUEUR_NOM_PAGE LONGUEUR_NOM_MANGA_MAX*2+300

/*Tailles*/
#define BORDURE_LAT_LECTURE 20
#define BORDURE_HOR_LECTURE 40
#define BORDURE_INFERIEURE 25
#define BORDURE_BUTTON_H 5
#define BORDURE_BUTTON_W 10
#define BORDURE_CONTROLE_LECTEUR 100
#define LARGEUR_CONTROLE_LECTEUR 800
#define MINIICONE_H 42
#define MINIICONE_W 42
#define BIGICONE_H 90
#define BIGICONE_W 90

/*Positions*/
#define LARGE_BUTTONS_LECTEUR_PC 30
#define LARGE_BUTTONS_LECTEUR_PP 185
#define LARGE_BUTTONS_LECTEUR_NP 510
#define LARGE_BUTTONS_LECTEUR_NC 665

/*Return values*/
#define CLIC_SUR_BANDEAU_NONE 0
#define CLIC_SUR_BANDEAU_PREV_CHAPTER 1
#define CLIC_SUR_BANDEAU_PREV_PAGE 2
#define CLIC_SUR_BANDEAU_NEXT_PAGE 3
#define CLIC_SUR_BANDEAU_NEXT_CHAPTER 4
#define CLIC_SUR_BANDEAU_FAVORITE 5
#define CLIC_SUR_BANDEAU_FULLSCREEN 6
#define CLIC_SUR_BANDEAU_DELETE 7
#define CLIC_SUR_BANDEAU_MAINMENU 8

/*Calibration*/
#define LECTEUR_DISTANCE_OPTIMALE_INFOS_ET_PAGEACCESDIRE 100
#define LECTEUR_DISTANCE_MINIMALE_INFOS_ET_PAGEACCESDIRE 5
#define DELAY_KEY_PRESSED_TO_START_PAGE_SLIDE 350
