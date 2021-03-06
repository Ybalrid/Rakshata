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

#define BUTTON_NAME @"clearTag"

@implementation RakSRTagItem

- (instancetype) initWithTag : (NSString *) tagName
{
	self = [self init];
	
	if(self != nil)
	{
		[Prefs registerForChange:self forType:KVO_THEME];
		
		if(![self updateIcon])
			return nil;
		
		label = [[RakText alloc] initWithText:NSMakeRect(0, 0, 25, TAG_BUTTON_HEIGHT) :tagName :[self getTextColor]];
		if(label != nil)
		{
			[label sizeToFit];
			[label setFrameOrigin:NSMakePoint(NSMaxX(close.frame) + TAG_BORDER_LEFT_LABEL, TAG_BUTTON_MIDDLE + 1 -label.bounds.size.height / 2)];
			[self addSubview:label];
		}
		else
			return nil;
		
		[self setFrameSize:NSMakeSize(NSMaxX(label.frame) + TAG_BORDER_RIGHT_LABEL, TAG_BUTTON_HEIGHT)];
	}
	
	return self;
}

- (void) dealloc
{
	[Prefs deRegisterForChange:self forType:KVO_THEME];
}

- (BOOL) updateIcon
{
	if(close != nil)
		[close removeFromSuperview];
	
	close = [RakButton allocImageWithoutBackground:BUTTON_NAME :self :@selector(close)];
	if(close != nil)
	{
		[close.cell setActiveAllowed:NO];
		[close setFrameOrigin:NSMakePoint(5, TAG_BUTTON_MIDDLE - close.bounds.size.height / 2)];
		[self addSubview:close];
		return YES;
	}
	
	return NO;
}

- (void) updateContent : (NSString *) newTagName
{
	label.stringValue = newTagName;
	[label sizeToFit];
	
	[self setFrameSize:NSMakeSize(NSMaxX(label.frame) + TAG_BORDER_RIGHT_LABEL, TAG_BUTTON_HEIGHT)];
}

- (RakColor *) getTextColor
{
	return [Prefs getSystemColor:COLOR_TAGITEM_FONT];
}

- (RakColor *) backgroundColor
{
	return [Prefs getSystemColor:COLOR_TAGITEM_BACKGROUND];
}

- (RakColor *) borderColor
{
	return [Prefs getSystemColor:COLOR_READER_BAR_FRONT];
}

#pragma mark - UI Drawing

- (void) mouseDown:(NSEvent *)theEvent
{
	
}

- (void) drawRect : (NSRect) dirtyRect
{
	NSSize size = self.bounds.size;
	
	CGContextRef contextBorder = [[NSGraphicsContext currentContext] graphicsPort];
	
	//Background
	CGContextBeginPath(contextBorder);
	CGContextMoveToPoint(contextBorder, 0, TAG_BUTTON_MIDDLE);
	CGContextAddLineToPoint(contextBorder, TAG_BUTTON_ARROW_DEPTH, size.height);
	CGContextAddLineToPoint(contextBorder, size.width, size.height);
	CGContextAddLineToPoint(contextBorder, size.width, 0);
	CGContextAddLineToPoint(contextBorder, TAG_BUTTON_ARROW_DEPTH, 0);
	CGContextAddLineToPoint(contextBorder, 0, TAG_BUTTON_MIDDLE);
	
	[[self backgroundColor] setFill];
	CGContextFillPath(contextBorder);
	
	//Front
	CGContextBeginPath(contextBorder);
	CGContextMoveToPoint(contextBorder, TAG_BUTTON_ARROW_DEPTH - 1, 1);
	CGContextAddLineToPoint(contextBorder, size.width, 1);
	CGContextAddLineToPoint(contextBorder, size.width, size.height);
	
	[[self borderColor] setStroke];
	CGContextSetLineWidth(contextBorder, 2);
	CGContextStrokePath(contextBorder);
}

- (void) close
{
	NSString * notification;
	
	if(__dataType == RDBS_TYPE_AUTHOR)
		notification = SR_NOTIFICATION_AUTHOR;
	
	else if(__dataType == RDBS_TYPE_SOURCE)
		notification = SR_NOTIFICATION_SOURCE;
	
	else if(__dataType == RDBS_TYPE_TAG)
		notification = SR_NOTIFICATION_TAG;
	
	else if(__dataType == RDBS_TYPE_CAT)
		notification = SR_NOTIFICATION_TYPE;
	else
		return;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:notification object:@(_index) userInfo:@{SR_NOTIF_CACHEID : @(__dataID), SR_NOTIF_OPTYPE : @(NO), SR_NOTIF_UNSELECT : @(YES)}];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([object class] != [Prefs class])
		return;
	
	[self updateIcon];
	[label setTextColor:[self getTextColor]];
	
	[self setNeedsDisplay:YES];
}

@end
