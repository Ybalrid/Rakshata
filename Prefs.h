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

#import <Foundation/Foundation.h>
#include "../../../Sources/graphics.h"

@interface Prefs : NSObject

+ (void) initCache;
+ (void) rebuildCache;
+ (void) clearCache;
+ (void *) getPref : (int) request;

@end

/*Codes servant à identifier les requêtes*/
#define PREFS_GET_TAB_SERIE_WIDTH 1

/*Divers constantes utilisées un peu partout mais renvoyés par Prefs*/
#define TAB_SERIE_INACTIVE_CT				200
#define TAB_SERIE_INACTIVE_LECTEUR			200
#define TAB_SERIE_INACTIVE_LECTEUR_REDUCED	50