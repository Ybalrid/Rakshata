/*********************************************************************************************
 **	__________         __           .__            __                 ________   _______   	**
 **	\______   \_____  |  | __  _____|  |__ _____ _/  |______   	___  _\_____  \  \   _  \  	**
 **	 |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \  	\  \/ //  ____/  /  /_\  \ 	**
 **	 |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \_  \   //       \  \  \_/   \	**
 **	 |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /	  \_/ \_______ \ /\_____  /	**
 **	        \/      \/     \/     \/     \/     \/          \/ 	              \/ \/     \/ 	**
 **                                                                                         **
 **			This Source Code Form is subject to the terms of the Mozilla Public				**
 **			License, v. 2.0. If a copy of the MPL was not distributed with this				**
 **			file, You can obtain one at https://mozilla.org/MPL/2.0/.						**
 **                                                                                         **
 **                     			© Taiki 2011-2016                                       **
 **                                                                                         **
 *********************************************************************************************/

@implementation RakSRHeaderText

- (NSRect) getMenuFrame : (NSRect) superviewSize
{
	superviewSize.size.height = MENU_TEXT_WIDTH;
	
	return superviewSize;
}

@end

@implementation RakTableRowView

- (instancetype) init
{
	self = [super init];

	if(self != nil)
	{
		self.drawBackground = NO;
	}

	return self;
}

- (void) drawBackgroundInRect:(NSRect)dirtyRect
{
	if(self.drawBackground)
	{
		if(self.selected)
		{
			[[Prefs getSystemColor:COLOR_ADD_REPO_BACKGROUND] setFill];
			NSRectFill(dirtyRect);
		}
	}
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	[self drawBackgroundInRect:dirtyRect];
}

- (void) setForcedWidth:(CGFloat)forcedWidth
{
	haveForcedWidth = YES;
	_forcedWidth = forcedWidth;
	
	NSSize size = self.frame.size;
	if(size.width != _forcedWidth)
	{
		[self setFrameSize:size];
	}
}

- (void) setFrameSize:(NSSize)newSize
{
	if(haveForcedWidth)
		newSize.width = _forcedWidth;
	
	[super setFrameSize:newSize];
}

@end

@implementation RakSRSubMenu

- (CGFloat) getFontSize
{
	return [NSFont systemFontSize];
}

- (CGFloat) getTextHeight
{
	return 21;
}

- (RakColor *) getBackgroundColor
{
	return nil;
}

@end
