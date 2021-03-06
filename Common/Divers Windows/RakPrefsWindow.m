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

@implementation RakPrefsWindow

+ (NSSize) defaultWindowSize
{
	return NSMakeSize(PREF_WINDOW_WIDTH, PREF_WINDOW_HEIGHT);
}

- (NSRect) contentFrame : (RakView *) content
{
	NSRect frame = [super contentFrame:content];
	
	CGFloat offset = frame.origin.x;
	
	frame.origin.x -= offset - 2;
	frame.origin.y -= offset;
	frame.size.height += 2 * offset - 2;
	frame.size.width += 2 * offset - 4;
	
	return frame;
}

- (void) fillWindow
{
	[super fillWindow];
	
	activeView = PREFS_BUTTON_CODE_UNUSED;
	
	byte currentFocus = PREFS_BUTTON_CODE_DEFAULT;
	[Prefs getPref:PREFS_GET_ACTIVE_PREFS_PANEL :&currentFocus];
	
	header = [[RakPrefsButtons alloc] initWithFrame : NSMakeRect(0, 0, PREF_WINDOW_WIDTH, PREF_BUTTON_BAR_HEIGHT) :self];
	if(header != nil)
	{
		[header selectElem:currentFocus];
		[contentView addSubview:header];
	}
	else
		[self focusChanged:currentFocus];
}

- (Class) contentClass
{
	return [RakFlippedView class];
}

#pragma mark - Drawing

- (NSRect) mainFrame
{
	NSRect frame = contentView.bounds;
	
	frame.origin.y = PREF_BUTTON_BAR_HEIGHT;
	frame.size.height -= PREF_BUTTON_BAR_HEIGHT + 4;
	
	return frame;
}

- (RakColor *) textColor
{
	return [Prefs getSystemColor:COLOR_CLICKABLE_TEXT];
}

#pragma mark - Buttons responder

- (void) focusChanged : (byte) newTab
{
	RakView * old = [self viewForCode : activeView : NO], * new = [self viewForCode : newTab : YES];
	
	if(old == nil)
	{
		NSRect newWindowFrame = window.frame;
		NSSize oldSize = [self mainFrame].size;
		
		CGFloat diff = oldSize.height + 4 - new.bounds.size.height;
		newWindowFrame.size.height -= diff - TITLE_BAR_HEIGHT;
		newWindowFrame.origin.y = MAX(0, newWindowFrame.origin.y + diff / 2);
		
		diff = oldSize.width - new.bounds.size.width;
		newWindowFrame.size.width -= diff;
		newWindowFrame.origin.x = MAX(0, newWindowFrame.origin.x + diff / 2);
		
		[header setFrameSize:NSMakeSize(newWindowFrame.size.width - 4, PREF_BUTTON_BAR_HEIGHT)];
		[window setFrame:newWindowFrame display:YES animate:NO];
	}
	else if(old != new)
	{
		new.alphaValue = 0;
		new.hidden = NO;
		
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			
			context.duration = 0.1f;
			old. alphaAnimated = 0;
			
		} completionHandler:^{
			
			NSRect newWindowFrame = window.frame;
			
			CGFloat diff = old.bounds.size.height - new.bounds.size.height;
			
			newWindowFrame.size.height -= diff + 0.5;
			newWindowFrame.origin.y = MAX(0, newWindowFrame.origin.y + diff / 2);
			
			diff = old.bounds.size.width - new.bounds.size.width;
			newWindowFrame.size.width -= diff;
			newWindowFrame.origin.x = MAX(0, newWindowFrame.origin.x + diff / 2);
			
			if(diff < 0)	//We expand
				[header setFrameSize:NSMakeSize(newWindowFrame.size.width - 4, PREF_BUTTON_BAR_HEIGHT)];
			
			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				
				context.duration = 0.1f;
				[window.animator setFrame:newWindowFrame display:YES animate:YES];
				
			} completionHandler:^{
				
				if(diff > 0)	//We shrink
					[header setFrameSize:NSMakeSize(newWindowFrame.size.width - 4, PREF_BUTTON_BAR_HEIGHT)];
				
				[new setFrameOrigin:NSMakePoint(0, PREF_BUTTON_BAR_HEIGHT)];
				
				[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
					
					context.duration = 0.1f;
					new. alphaAnimated = 1;
					
				} completionHandler:^{
					old.hidden = YES;
				}];
			}];
		}];
	}
	
	activeView = newTab;
}

- (RakView *) viewForCode : (byte) code : (BOOL) createIfNeeded
{
	switch (code)
	{
		case PREFS_BUTTON_CODE_GENERAL:
		{
			if(generalView != nil)
				return generalView;
			
			else if(createIfNeeded)
			{
				generalView = [[RakPrefsGeneralView alloc] initWithFrame:[self mainFrame]];
				
				if(generalView != nil)
					[contentView addSubview:generalView];
				
				return generalView;
			}
			
			break;
		}
			
		case PREFS_BUTTON_CODE_REPO:
		{
			if(repoView != nil)
				return repoView;
			
			else if(createIfNeeded)
			{
				repoView = [[RakPrefsRepoView alloc] init];
				
				if(repoView != nil)
					[contentView addSubview:repoView];
				
				return repoView;
			}
			
			break;
		}
			
		case PREFS_BUTTON_CODE_FAV:
		{
			if(favoriteView != nil)
				return favoriteView;
			
			else if(createIfNeeded)
			{
				favoriteView = [[RakPrefsFavoriteView alloc] initWithFrame:[self mainFrame]];
				
				if(favoriteView != nil)
					[contentView addSubview:favoriteView];
				
				return favoriteView;
			}
			
			break;
		}
			
		case PREFS_BUTTON_CODE_CUSTOM:
		{
			if(customView != nil)
				return customView;
			
			else if(createIfNeeded)
			{
				customView = [[RakView alloc] initWithFrame:[self mainFrame]];
				
				if(customView != nil)
					[contentView addSubview:customView];
				
				return customView;
			}
			
			break;
		}
	}
	
	return nil;
}

@end
