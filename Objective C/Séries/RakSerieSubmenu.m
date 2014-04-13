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

@implementation RakSerieSubmenuItem

- (id) init : (void*) data : (BOOL) isRootItem
{
	self = [super init];
	
	if(self != nil)
	{
		_isRootItem = isRootItem;
		
		if(_isRootItem)
		{
			dataRoot = data;
			dataChild = NULL;
		}
		else
		{
			dataRoot = NULL;
			dataChild = data;
		}
	}
	
	return self;
}

- (BOOL) isRootItem
{
	return _isRootItem;
}

- (NSString*) getData
{
	if(_isRootItem && dataRoot != NULL)
		return dataRoot;
	else if(!_isRootItem && dataChild != NULL)
		return [NSString stringWithCString:dataChild->mangaName encoding:NSASCIIStringEncoding];
	else
		return @"Internal error :(";
}

@end

@implementation RakSerieSubmenu

- (id) init : (NSView *) superview : (BOOL) isRecentDownload
{
	self = [super init];
	
	if(self != nil)
	{
		_isRecentDownload = isRecentDownload;
		[self loadContent];
		
		if(_data != nil)
		{
			content = [[RakTreeView alloc] initWithFrame:[self getContentFrame:[superview bounds]]];
			NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:@"The Solar Empire shall fall!"];
			[column setWidth:content.frame.size.width];
			
			//Customisation
			[content setBackgroundColor:[NSColor clearColor]];
			[content setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
			[content setFocusRingType:NSFocusRingTypeNone];
			
			//End of setup
			[content setDelegate:self];
			[content setDataSource:self];
			[content addTableColumn:column];
			[content setOutlineTableColumn:column];
			[content expandItem:nil expandChildren:YES];
			[superview addSubview:content];
		}
		else
			[self release];
	}
	
	return self;
}

- (NSRect) getContentFrame : (NSRect) superviewFrame
{
	superviewFrame.origin.y = superviewFrame.size.height - 150 - 100;
	superviewFrame.size.height = 150;
	superviewFrame.size.width /= 2;
	superviewFrame.origin.x = superviewFrame.size.width / 2;
	
	return superviewFrame;
}

- (id) retain
{
	[content retain];
	return [super retain];
}

- (oneway void) release
{
	[content release];
	[super release];
}

- (void) dealloc
{
	freeMangaData(_cache);
	[_data release];
	[content removeFromSuperview];
	
	[super dealloc];
}

#pragma mark - Color

- (NSColor *) getFontColor
{
	return [Prefs getSystemColor:GET_COLOR_ACTIVE];
}

#pragma mark - Loading routines

- (void) loadContent
{
	_cache = getCopyCache(RDB_CTXSERIES | SORT_TEAM, &_sizeCache);
	
	if(_cache != NULL)
	{
		_data = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsOpaqueMemory];
		
		changeTo(_cache[_sizeCache - 1].mangaName, '_', ' ');
		[_data addPointer:&_cache[_sizeCache - 1]];
		
		changeTo(_cache[_sizeCache - 2].mangaName, '_', ' ');
		[_data addPointer:&_cache[_sizeCache - 2]];
		
		changeTo(_cache[_sizeCache - 3].mangaName, '_', ' ');
		[_data addPointer:&_cache[_sizeCache - 3]];
		
		_nbElemDisplayed = 3;
	}
}

#pragma mark - Data source to the view

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return (item == nil) ? 1 : ([item isRootItem] ? _nbElemDisplayed : 0);
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return item == nil ? YES : [item isRootItem];
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if(item == nil)
		return [[RakSerieSubmenuItem alloc] init : @"Header" : YES];
	else
		return [[RakSerieSubmenuItem alloc] init : [_data pointerAtIndex:index] : NO];
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if(item == NULL)
		return @"Invalid data :(";
	else
		return [item getData];
}

#pragma mark - Delegate to the view

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return item != nil && ![item isRootItem];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return item != nil && ![item isRootItem];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
	return [item isRootItem];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[cell setDrawsBackground:NO];
	
	if(item == nil)	//Header
	{
		
	}
	else			//Normal elements
	{
		
	}
}

@end

@implementation RakTreeView

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row{
    
	NSRect superFrame = [super frameOfCellAtColumn:column row:row];
	
	
    if (column == 0)
	{
        return NSMakeRect(0, superFrame.origin.y, [self bounds].size.width, superFrame.size.height);
    }
    return superFrame;
}

@end
