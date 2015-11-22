/*********************************************************************************************
 **	__________         __           .__            __                 ________   _______   	**
 **	\______   \_____  |  | __  _____|  |__ _____ _/  |______   	___  _\_____  \  \   _  \  	**
 **	 |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \  	\  \/ //  ____/  /  /_\  \ 	**
 **	 |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \__ \   //       \  \  \_/   \	**
 **	 |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /	  \_/ \_______ \ /\_____  /	**
 **	        \/      \/     \/     \/     \/     \/          \/ 	              \/ \/     \/ 	**
 **                                                                                         **
 **		Source code and assets are property of Taiki, distribution is stricly forbidden		**
 **                                                                                         **
 *********************************************************************************************/

@interface RakSRSearchTabGroup : NSView
{
	byte _ID;
	
	RakSRSearchList * list;
	RakSRSearchBar * searchBar;
	
	//Used by extra
	RakButton * close;
	RakSwitchButton * freeSwitch, * favsSwitch;
	RakText * freeText, * favsText;
	
	charType ** listData;
	uint nbDataList;
	uint64_t * indexesData;
}

- (instancetype) initWithFrame:(NSRect)frameRect : (byte) ID;
- (void) resizeAnimation:(NSRect)frameRect;

- (RakSRSearchBar *) searchBar;

@end
