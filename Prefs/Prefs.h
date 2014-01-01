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

#define DEV_VERSION

@interface Prefs : NSObject

+ (void) initCache;
+ (void) rebuildCache;
+ (void) clearCache;
+ (void *) getPref : (int) request;

@end

/*Codes servant à identifier les requêtes*/
#define PREFS_GET_TAB_SERIE_WIDTH	1
#define PREFS_GET_TAB_CT_WIDTH		2
#define PREFS_GET_TAB_READER_WIDTH	3

/*Divers constantes utilisées un peu partout mais renvoyés par Prefs*/
#define TAB_SERIE_ACTIVE					78
#define TAB_SERIE_INACTIVE_CT				20
#define TAB_SERIE_INACTIVE_LECTEUR			15
#define TAB_SERIE_INACTIVE_LECTEUR_REDUCED	5

#define TAB_CT_INACTIVE_SERIE				20
#define TAB_CT_ACTIVE						60
#define TAB_CT_INACTIVE_LECTEUR				15
#define TAB_CT_INACTIVE_LECTEUR_REDUCED		7

#define TAB_READER_INACTIVE_SERIE			2
#define TAB_READER_INACTIVE_CT				20
#define TAB_READER_ACTIVE					70
#define TAB_READER_INACTIVE_LECTEUR_REDUCED	88

#if (TAB_SERIE_ACTIVE + TAB_CT_INACTIVE_SERIE + TAB_READER_INACTIVE_SERIE != 100)
	#warning "Inconsistencies in tab size in SERIE"
#endif

#if (TAB_SERIE_INACTIVE_CT + TAB_CT_ACTIVE + TAB_READER_INACTIVE_CT != 100)
	#warning "Inconsistencies in tab size in CT"
#endif

#if (TAB_SERIE_INACTIVE_LECTEUR + TAB_CT_INACTIVE_LECTEUR + TAB_READER_ACTIVE != 100) \
	|| (TAB_SERIE_INACTIVE_LECTEUR_REDUCED + TAB_CT_INACTIVE_LECTEUR_REDUCED + TAB_READER_INACTIVE_LECTEUR_REDUCED != 100)
	#warning "Inconsistencies in tab size in READER"
#endif