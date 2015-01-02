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

#import "RakListScrollView.h"

#define RAKLIST_MAIN_COLUMN_ID @"For the New Lunar Republic!"

@interface RakTableView : NSTableView
{
	BOOL _lastSelectionWasClic;
	
	NSInteger _preCommitedLastClickedRow;
	
	NSInteger _lastClickedRow;
	NSInteger _lastClickedColumn;
}

@property NSInteger lastClickedRow;
@property NSInteger lastClickedColumn;
@property NSInteger preCommitedLastClickedColumn;

- (NSColor *) _dropHighlightColor;

//Need to be called when the clicked row/column are validated, and we want to exploit the data
- (void) commitClic;

@end

typedef struct smartReload_data
{
	uint data;
	BOOL installed;
	
} SR_DATA;

@interface RakList : RakDragResponder <NSTableViewDelegate, NSTableViewDataSource>
{
	void* _data;
	uint _nbData;
	RakListScrollView * scrollView;
	RakTableView * _tableView;
	
	NSInteger selectedRowIndex;
	NSInteger selectedColumnIndex;
	uint _nbElemPerCouple;
	uint _nbCoupleColumn;
	
	//Color cache
	NSColor * normal;
	NSColor * highlight;
	
	NSString * _identifier;
}

@property (getter=isHidden, setter=setHidden:)				BOOL hidden;
@property (getter=frame, setter=setFrame:)					NSRect frame;
@property (weak, getter=superview, setter=setSuperview:)	NSView * superview;

- (void) applyContext : (NSRect) frame : (int) activeRow : (long) scrollerPosition;
- (bool) didInitWentWell;
- (void) failure;

- (void) setFrameOrigin : (NSPoint) origin;
- (void) setAlphaValue : (CGFloat) alphaValue : (BOOL) animated;

- (NSScrollView*) getContent;
- (void) resizeAnimation : (NSRect) frameRect;
- (void) reloadSize;

- (void) updateMultiColumn : (NSSize) scrollviewSize;
//Overwrite only
- (void) additionalResizing : (NSSize) newSize;

- (NSRect) getFrameFromParent : (NSRect) superviewFrame;

- (void) enableDrop;

- (NSInteger) getSelectedElement;
- (NSInteger) getIndexOfElement : (NSInteger) element;
- (float) getSliderPos;
- (NSInteger) selectedRow;

- (NSColor *) getTextColor;
- (NSColor *) getTextColor : (uint) column : (uint) row;
- (NSColor *) getTextHighlightColor;
- (NSColor *) getTextHighlightColor : (uint) column : (uint) row;
- (NSColor *) getBackgroundHighlightColor;

- (void) postProcessingSelection : (uint) row;

- (void) selectRow : (int) row;
- (void) resetSelection : (NSTableView *) tableView;

- (void) smartReload : (SR_DATA*) oldData : (uint) nbElemOld : (SR_DATA*) newData : (uint) nbElemNew;
- (void) fullAnimatedReload : (uint) oldElem : (uint) newElem;

- (void) fillDragItemWithData : (RakDragItem*) data : (uint) row;
- (BOOL) acceptDrop : (id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation source:(uint) source;
- (void) cleanupDrag;
- (BOOL) receiveDrop : (PROJECT_DATA) project : (bool) isTome : (int) element : (uint) sender : (NSInteger)row : (NSTableViewDropOperation)operation;

+ (void) propagateDragAndDropChangeState : (BOOL) started : (BOOL) canDL;

@end