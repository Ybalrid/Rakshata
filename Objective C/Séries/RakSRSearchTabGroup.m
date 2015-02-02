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

#include "db.h"

@implementation RakSRSearchTabGroup

- (instancetype) initWithFrame:(NSRect)frameRect : (byte) ID
{
	self = [super initWithFrame:frameRect];
	
	if(self != nil)
	{
		_ID = ID;
		
		list = [[RakSRSearchList alloc] init:[self getTableFrame : _bounds] :[self getRDBSCodeForID]];
		if(list != nil)
			[self addSubview:[list getContent]];
		
		searchBar = [[RakSRSearchBar alloc] initWithFrame:[self getSearchFrame:_bounds] :SEARCH_BAR_ID_AUTHOR];
		if(searchBar != nil)
		{
			[self addSubview:searchBar];
		}
		
		self.wantsLayer = YES;
		self.layer.cornerRadius = 3;
		self.layer.borderWidth = 1;
		self.layer.borderColor = [Prefs getSystemColor:GET_COLOR_SEARCHBAR_BORDER :nil].CGColor;
	}
	
	return self;
}

- (byte) getRDBSCodeForID
{
	if(_ID == SEARCH_BAR_ID_AUTHOR)
		return RDBS_TYPE_AUTHOR;
	else if(_ID == SEARCH_BAR_ID_TAG)
		return RDBS_TYPE_TAG;
	else if(_ID == SEARCH_BAR_ID_TYPE)
		return RDBS_TYPE_TYPE;
	
	NSLog(@"Not supported yet");
	return 255;
}

- (void) setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	[list setFrame:[self getTableFrame:frameRect]];
	[searchBar setFrame:[self getSearchFrame:frameRect]];
}

- (void) resizeAnimation:(NSRect)frameRect
{
	[self.animator setFrame:frameRect];
	[list resizeAnimation:[self getTableFrame:frameRect]];
	[searchBar resizeAnimation:[self getSearchFrame:frameRect]];
}

#define BORDER_LIST 3
#define BORDERL_SEARCH_LIST 10

- (NSRect) getSearchFrame : (NSRect) frame
{
	frame.origin.y = frame.size.height - SR_SEARCH_FIELD_HEIGHT;
	frame.size.height = SR_SEARCH_FIELD_HEIGHT;
	
	frame.origin.x = 0;
	
	return frame;
}

- (NSRect) getTableFrame : (NSRect) frame
{
	frame.size.height -= SR_SEARCH_FIELD_HEIGHT + BORDERL_SEARCH_LIST;
	
	frame.size.width -= 2 * BORDER_LIST;
	
	frame.origin.x = BORDER_LIST;
	frame.origin.y = 0;
	
	return frame;
}


@end
