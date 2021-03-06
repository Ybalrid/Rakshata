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

enum
{
	BORDER = 5,
	WIDTH = 800,
	HEIGHT = 410,
	
	SWITCH_Y_OFFSET = 10,
	BORDER_X_LIST = 20
};

@interface RakPrefsFavoriteView()
{
	RakText * header, * autoDLMessage;
	RakSwitchButton * autoDLButton;
	
	RakPrefsFavoriteList * list;
}

@end

@implementation RakPrefsFavoriteView

- (instancetype) initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:NSMakeRect(frameRect.origin.x, frameRect.origin.y, WIDTH, HEIGHT)];
	
	if(self != nil)
	{
		header = [[RakText alloc] initWithText:NSLocalizedString(@"PREFS-FAVORITE-HEADER", nil) :[self textColor]];
		if(header != nil)
		{
			[header setFont:[RakMenuText getFont:16]];
			[header sizeToFit];
			
			[header setFrameOrigin: [self headerOrigin]];
			[self addSubview:header];
		}
		
		autoDLButton = [[RakSwitchButton alloc] init];
		if(autoDLButton != nil)
		{
			autoDLMessage = [[RakText alloc] initWithText:NSLocalizedString(@"PREFS-FAVORITE-AUTODL", nil) :[self textColor]];
			if(autoDLMessage != nil)
			{
				autoDLButton.state = shouldDownloadFavorite() ? NSOnState : NSOffState;
				autoDLButton.target = self;
				autoDLButton.action = @selector(autoDLToggled);
				
				[autoDLButton setFrameOrigin:[self switchButtonOrigin]];
				[self addSubview:autoDLButton];
				
				autoDLMessage.clicTarget = self;
				autoDLMessage.clicAction = @selector(textClicked);
				
				[autoDLMessage setFrameOrigin:[self switchMessageOrigin]];
				[self addSubview:autoDLMessage];
			}
			else
				autoDLButton = nil;
		}
		
		list = [[RakPrefsFavoriteList alloc] initWithFrame:[self listFrame]];
		if(list != nil)
		{
			[self addSubview:[list getContent]];
		}
		
		[Prefs registerForChange:self forType:KVO_THEME];
	}
	
	return self;
}

- (void) dealloc
{
	[Prefs deRegisterForChange:self forType:KVO_THEME];
}

#pragma mark - Sizing & color

- (NSPoint) headerOrigin
{
	NSSize base = self.bounds.size, head = header.bounds.size;
	
	return NSMakePoint(base.width / 2 - head.width / 2, base.height - head.height - BORDER);
}

- (NSRect) listFrame
{
	const NSSize base = self.bounds.size;
	const CGFloat heightBelow = NSMaxY(autoDLButton.frame) + BORDER;
	
	return NSMakeRect(BORDER_X_LIST, heightBelow, base.width - 2 * BORDER_X_LIST, header.frame.origin.y - BORDER - heightBelow);
}

- (NSPoint) switchButtonOrigin
{
	CGFloat fullWidth = autoDLButton.bounds.size.width + BORDER + autoDLMessage.bounds.size.width;
	return NSMakePoint(self.bounds.size.width / 2 - fullWidth / 2, SWITCH_Y_OFFSET);
}

- (NSPoint) switchMessageOrigin
{
	NSRect autoDLFrame = autoDLButton.frame;

	return NSMakePoint(NSMaxX(autoDLFrame) + BORDER, SWITCH_Y_OFFSET + (autoDLFrame.size.height / 2 - autoDLMessage.bounds.size.height / 2));
}

- (RakColor *) textColor
{
	return [Prefs getSystemColor:COLOR_INACTIVE];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([object class] != [Prefs class])
		return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	header.textColor = [self textColor];
	autoDLMessage.textColor = [self textColor];
}

#pragma mark - Logic

- (void) textClicked
{
	[autoDLButton performClick:self];
}

- (void) autoDLToggled
{
	[Prefs setPref:PREFS_SET_FAVORITE_AUTODL atValue:autoDLButton.state == NSOnState];
}

@end
