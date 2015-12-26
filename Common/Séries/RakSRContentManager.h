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
 ********************************************************************************************/

@interface RakSRStupidDataStructure : NSObject

@property uint index;

@end

@interface RakSRContentManager : NSObject
{
	BOOL _initialized, secondPass;
	
	NSString * commitedSearch;
	
	//Model
	BOOL installedOnly, freeOnly, favsOnly;
	PROJECT_DATA * project;
	uint nbElemFull, nbElemActivated;
	
	uint * cacheList;
	
	uint * orderedToSorted;
	uint * filteredToOrdered;
	
	//Views
	NSRect previousFrame;
	byte _activeView;

#if !TARGET_OS_IPHONE
	RakGridView * _grid;
#endif
}

@property (weak) RakView * controlView;
@property byte activeView;

@property NSMutableArray <RakSRStupidDataStructure *> * sharedReference;

#if !TARGET_OS_IPHONE
@property (readonly) RakView * getActiveView;

- (void) initViews;

- (void) setFrame : (NSRect) frame;
- (void) resizeAnimation : (NSRect) frame;
#endif

- (uint) nbElement;
- (uint) nbActivatedElement;

- (PROJECT_DATA *) getDirectDataAtIndex : (uint) index;
- (PROJECT_DATA *) getDataAtIndex : (uint) index;

@end
