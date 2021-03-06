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
	LEVEL_SERIE,
	LEVEL_CT
};

@implementation RakBackButton

- (instancetype) initWithFrame : (NSRect) frame : (BOOL) isOneLevelBack
{
	self = [super initWithFrame : [self frameFromParent:frame]];
	if(self != nil)
	{
		[self setAutoresizesSubviews:NO];
		[self setWantsLayer:YES];
		[self setBordered:NO];
		[self.layer setCornerRadius:4];
		cursorOnMe = NO;
		
		[Prefs registerForChange:self forType:KVO_THEME];
		
		//On initialise la cellule
		[self.cell switchToNewContext: (isOneLevelBack ? @"back" : @"backback") : RB_STATE_STANDARD];
		ID = isOneLevelBack ? LEVEL_CT : LEVEL_SERIE;
		
		//Set tracking area
		tag = [self addTrackingRect:self.bounds owner:self userData:NULL assumeInside:NO];
	}
	return self;
}

- (NSRect) frameFromParent : (NSRect) frame
{
	frame.origin.y = RBB_TOP_BORDURE;
	frame.size.height = RBB_BUTTON_HEIGHT;
	frame.origin.x += frame.size.width * RBB_BUTTON_POSX / 100.0f;
	frame.size.width *= RBB_BUTTON_WIDTH / 100.0f;
	
	return frame;
}

- (void) setFrame:(NSRect)frameRect
{
	NSRect newFrame = [self frameFromParent:frameRect];
	[super setFrame: newFrame];
	
	newFrame.origin = NSZeroPoint;
	
	[self removeTrackingRect:tag];
	tag = [self addTrackingRect:newFrame owner:self userData:NULL assumeInside:NO];
}

- (void) resizeAnimation : (NSRect) frameRect
{
	NSRect newFrame = [self frameFromParent:frameRect];
	
	[self setFrameAnimated:newFrame];
	
	newFrame.origin = NSZeroPoint;
	
	[self removeTrackingRect:tag];
	tag = [self addTrackingRect:newFrame owner:self userData:NULL assumeInside:NO];
}

- (void) drawRect:(NSRect)dirtyRect
{
	[self.cell drawBezelWithFrame:dirtyRect inView:self];
	[self.cell drawImage:(RakImage *) [self.cell image] withFrame:dirtyRect inView:self];
}

+ (Class) cellClass
{
	return [RakBackButtonCell class];
}

- (void) dealloc
{
	[Prefs deRegisterForChange:self forType:KVO_THEME];
}

#pragma mark - Color

- (RakColor *) getColorBackground
{
	return [Prefs getSystemColor:COLOR_BACK_BUTTONS_BACKGROUND];
}

- (RakColor *) getColorBackgroundSlider
{
	return [Prefs getSystemColor:COLOR_BACK_BUTTONS_BACKGROUND_ANIMATING];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([object class] != [Prefs class])
		return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	[self setNeedsDisplay];
}

#pragma mark - Events

- (BOOL) confirmMouseOnMe
{
	//On vérifie que le tab est ouvert ET que la souris est bien sur nous
	RakTabView * group = ID == LEVEL_SERIE ? RakApp.serie : RakApp.CT;
	
	NSRect frame = self.frame;
	if(group.isFlipped)
		frame.origin.y = group.bounds.size.height - frame.size.height - frame.origin.y;
	
	return ![group isStillCollapsedReaderTab] && [group isCursorOnRect:frame];
}

- (void) mouseEntered:(NSEvent *)theEvent
{
	if([self confirmMouseOnMe])
	{
		cursorOnMe = YES;
		[self startAnimation];
	}
}

- (void) mouseDown:(NSEvent *)theEvent
{
	cursorOnMe = NO;
	[self.cell setAnimationInProgress:NO];
}

- (void) mouseUp:(NSEvent *)theEvent
{
	[self performClick:self];
}

- (void) mouseExited:(NSEvent *)theEvent
{
	cursorOnMe = NO;
	[self.cell setAnimationInProgress:NO];
	
	[_animation stopAnimation];
	_animation = nil;
	
	[self setNeedsDisplay:YES];
}

- (void) performClick : (id) sender
{
	if([self confirmMouseOnMe])
	{
		cursorOnMe = NO;
		[self.cell setAnimationInProgress:NO];
		[super performClick:sender];
	}
}

#pragma mark - Animation

- (void) startAnimation
{
	_animation = [[NSAnimation alloc] initWithDuration:1 animationCurve:NSAnimationLinear];
	[_animation setFrameRate:60.0];
	[_animation setAnimationBlockingMode:NSAnimationNonblocking];
	[_animation setDelegate:self];
	
	NSAnimationProgress progress = 0;
	for(uint i = 0; i < 60; i++)
	{
		[_animation addProgressMark:progress];
		progress += 1/60.0f;
	}
	
	[self.cell setAnimationInProgress:YES];
	[_animation startAnimation];
}

- (void) animation:(NSAnimation *)animation didReachProgressMark:(NSAnimationProgress)progress
{
	if(cursorOnMe)
	{
		[self.cell setAnimationStatus: progress];
		[self setNeedsDisplay:YES];
	}
}

- (void)animationDidEnd:(NSAnimation *)animation
{
	if(cursorOnMe)
	{
		[self.cell setAnimationInProgress:NO];
		[self performClick:self];
	}
	
	_animation = nil;
}

@end

@implementation RakBackButtonCell

- (void) switchToNewContext : (NSString*) imageName : (short) state
{
	RakImage * template = getResImageWithName(imageName);
	clicked		= [template copy];		[clicked tintWithColor:[Prefs getSystemColor:COLOR_ICON_ACTIVE]];
	nonClicked	= [template copy];		[nonClicked tintWithColor:[Prefs getSystemColor:COLOR_ICON_INACTIVE]];
	unAvailable	= template;				[unAvailable tintWithColor:[Prefs getSystemColor:COLOR_ICON_DISABLE]];
	
	notAvailable = NO;
	
	if(state == RB_STATE_STANDARD && nonClicked != nil)
		[self setImage:nonClicked];
	else if(state == RB_STATE_HIGHLIGHTED && clicked != nil)
		[self setImage:clicked];
	else if(unAvailable != nil)
	{
		[self setImage:unAvailable];
		notAvailable = YES;
	}
	else
		NSLog(@"Failed at create button for icon: %@", imageName);
}

- (void) setAnimationInProgress : (BOOL) start
{
	animationInProgress = start;
	animationStatus = 0;
}

- (void) setAnimationStatus:(CGFloat) status
{
	animationStatus = status;
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(RakBackButton *)controlView
{
	NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
	
	[ctx saveGraphicsState];
	
	if([self isHighlighted])
	{
		[[RakColor colorWithCalibratedWhite:0.0f alpha:0.35] setFill];
		NSRectFill(frame);
	}
	else if(animationInProgress)
	{
		NSRect drawingRect = frame;
		
		drawingRect.size.width *= animationStatus;
		if(animationStatus)
		{
			[[controlView getColorBackgroundSlider] setFill];
			NSRectFill(drawingRect);
		}
		
		if(animationStatus != 1)
		{
			drawingRect.origin.x = drawingRect.size.width;
			drawingRect.size.width = frame.size.width;
			[[controlView getColorBackground] setFill];
			NSRectFill(drawingRect);
		}
	}
	else
	{
		[[controlView getColorBackground] setFill];
		NSRectFill(frame);
	}
	[ctx restoreGraphicsState];
}

@end
