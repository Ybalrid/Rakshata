/*********************************************************************************************
 **	__________         __           .__            __                 ________   _______   	**
 **	\______   \_____  |  | __  _____|  |__ _____ _/  |______   	___  _\_____  \  \   _  \  	**
 **	 |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \  	\  \/ //  ____/  /  /_\  \ 	**
 **	 |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \__ \   //       \  \  \_/   \	**
 **	 |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /	  \_/ \_______ \ /\_____  /	**
 **	        \/      \/     \/     \/     \/     \/          \/ 	              \/ \/     \/ 	**
 **                                                                                         **
 **    Licence propriétaire, code source confidentiel, distribution formellement interdite  **
 **                                                                                         **
 *********************************************************************************************/

@implementation Reader

- (id)init:(NSView*)contentView
{
    self = [super init];
    if (self)
	{
		flag = GUI_THREAD_READER;
		gonnaReduceTabs = 0;
		self = [self initView:contentView];
		[self initReaderMainView];
	}
    return self;
}

- (int) convertTypeToPrefArg : (bool) getX
{
	return PREFS_GET_TAB_READER_WIDTH + [super convertTypeToPrefArg:getX];
}

- (void) refreshViewSize
{
	if(gonnaReduceTabs)
	{
		int mainTab;
		bool isReaderMode;
		[Prefs getPref:PREFS_GET_IS_READER_MT :&isReaderMode];
		[Prefs getPref:PREFS_GET_READER_TABS_STATE :&mainTab];
		if(!isReaderMode || (mainTab & STATE_READER_TAB_DEFAULT) == 0)
			gonnaReduceTabs = 0;
	}
	
	[super refreshViewSize];
}

- (void) readerIsOpening
{
	uint copy;
	do
	{
		gonnaReduceTabs = copy = getRandom();
	}while (!copy);
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{	if(gonnaReduceTabs == copy){[self collapseAllTabs];}	});
}

- (void) initReaderMainView
{
	setupBDDCache();
	uint i;
	MANGAS_DATA *mangaData = getCopyCache(RDB_LOADALL | SORT_NAME, &i);
	i--;
	
	mainImage = [[RakPage alloc] init: self: mangaData[i] : 10: false];
	bottomBar = [[RakReaderBottomBar alloc] init: YES: self];
}

/**	Drawing	**/

- (NSColor*) getMainColor
{
	return [NSColor colorWithSRGBRed:42/255.0f green:42/255.0 blue:42/255.0 alpha:1.0];
}

/**	Events **/
- (void) keyDown:(NSEvent *)theEvent
{
	[mainImage keyDown:theEvent];
}

/**	NSTrackingArea	**/

- (BOOL) isStillCollapsedReaderTab
{
	int state;
	[Prefs getPref:PREFS_GET_READER_TABS_STATE :&state];
	return ((state == STATE_READER_TAB_ALL_COLLAPSED) || (state == STATE_READER_TAB_DISTRACTION_FREE)) == 0;
}

- (void) resizeReaderCatchArea
{
	if([self isStillCollapsedReaderTab])
		[super resizeReaderCatchArea];
}

- (void)mouseExited:(NSEvent *)theEvent
{
}

/**	Hide stuffs	**/

- (void) collapseAllTabs
{
	[Prefs setPref:PREFS_SET_READER_TABS_STATE: STATE_READER_TAB_ALL_COLLAPSED];
	[super refreshLevelViews:[self superview]];
}

- (void) hideBothTab
{
	NSArray *subView = [[self superview] subviews];
	NSView *subViewView;
	NSUInteger i, count = [subView count];
	
	for(i = 0; i < count; i++)
	{
		subViewView = [subView objectAtIndex:i];
		if(subViewView != self)
			[subViewView setHidden:YES];
	}
	[Prefs setPref:PREFS_SET_READER_TABS_STATE :STATE_READER_TAB_DISTRACTION_FREE];
	[self refreshLevelViews:[self superview]];
}

- (void) unhideBothTab
{
	NSArray *subView = [[self superview] subviews];
	NSView *subViewView;
	NSUInteger i, count = [subView count];
	
	for(i = 0; i < count; i++)
	{
		subViewView = [subView objectAtIndex:i];
		if([subViewView isHidden])
			[subViewView setHidden:NO];
	}
}

- (void) hideCursor
{
	[NSCursor setHiddenUntilMouseMoves:YES];
}

@end
