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

@interface RakCTContentTabView : NSView
{
	PROJECT_DATA data;
	RakCTCoreViewButtons * _buttons;
	RakCTCoreContentView * _chapterView;
	RakCTCoreContentView * _volView;
	
	uint _currentContext;
}

@property uint currentContext;

@property BOOL dontNotify;
@property (readonly) PROJECT_DATA currentProject;


- (instancetype) initWithProject : (PROJECT_DATA) project : (BOOL) isTome : (NSRect) parentBounds : (CGFloat) headerHeight : (long [4]) context;

- (void) setFrame : (NSRect) parentFrame : (CGFloat) headerHeight;
- (void) resizeAnimation : (NSRect) parentFrame : (CGFloat) headerHeight;

- (NSString *) getContextToGTFO;

- (void) gotClickedTransmitData : (bool) isTome : (uint) index;

- (void) feedAnimationController : (RakCTAnimationController *) animationController;
- (void) switchIsTome : (RakCTCoreViewButtons*) sender;

- (void) refreshCTData : (BOOL) checkIfRequired : (uint) ID;
- (void) selectElem : (uint) projectID : (BOOL) isTome : (int) element;
- (BOOL) updateContext : (PROJECT_DATA) newData;

@end

