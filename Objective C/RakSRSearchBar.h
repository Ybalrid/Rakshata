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

#define SEARCH_BAR_ID_NBCASES 2
enum
{
	SEARCH_BAR_ID_MAIN		= 0,
	SEARCH_BAR_ID_AUTHOR	= 1,
	SEARCH_BAR_ID_SOURCE	= 2,
	SEARCH_BAR_ID_TAG		= 3,
	SEARCH_BAR_ID_TYPE		= 4
};

enum
{
	SEARCH_BAR_ID_MAIN_TRIGGERED 	= 1,
	SEARCH_BAR_ID_MAIN_TYPED 		= 2,
	SEARCH_BAR_ID_AUTHOR_TRIGGERED	= 3,
	SEARCH_BAR_ID_AUTHOR_TYPED		= 4,
	SEARCH_BAR_ID_SOURCE_TRIGGERED	= 5,
	SEARCH_BAR_ID_SOURCE_TYPED		= 6,
	SEARCH_BAR_ID_TAG_TRIGGERED		= 7,
	SEARCH_BAR_ID_TAG_TYPED			= 8,
	SEARCH_BAR_ID_TYPE_TRIGGERED	= 9,
	SEARCH_BAR_ID_TYPE_TYPED		= 10
};

@interface RakSRSearchBar : NSSearchField
{
	BOOL _currentPlaceholderState;
	byte _ID;
	
	id _cancelTarget;
	SEL _cancelAction;
}

- (instancetype) initWithFrame : (NSRect) frameRect : (byte) ID;

+ (void) triggeringSearchBar : (BOOL) goingIn : (byte) ID;

- (void) resizeAnimation : (NSRect) frame;

- (void) updatePlaceholder : (BOOL) inactive;
- (void) willLooseFocus;

+ (NSColor *) getBackgroundColor;

@end

@interface RakSRSearchBarCell : NSSearchFieldCell

@end