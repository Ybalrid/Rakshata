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

@implementation RakBackButton

- (id)initWithFrame:(NSRect)frame : (int) numberReturnChar
{
	frame.origin.x = frame.size.width / 8;
	frame.origin.y = frame.size.height - 35;
	frame.size.width *= 0.75;
	frame.size.height = 25;
	
    self = [super initWithFrame:frame];
    if (self)
	{
		[self setAutoresizingMask:NSViewWidthSizable];
		[self setWantsLayer:true];
		[self setBordered:NO];
		[self.layer setCornerRadius:4];
		cursorOnMe = false;

		//On initialise la cellule
		[self.cell switchToNewContext: @"arrowBack" : RB_STATE_STANDARD];
	
		//Set tracking area
		frame = [self frame];
		frame.origin.x = frame.origin.y = 0;
		[self addTrackingRect:frame owner:self userData:NULL assumeInside:NO];
	}
    return self;
}

- (void) setFrame:(NSRect)frameRect
{
	frameRect.size.height = self.frame.size.height;
	frameRect.size.width = self.superview.frame.size.width * 0.75;
	frameRect.origin.x = self.superview.frame.size.width / 8;
	frameRect.origin.y = self.superview.frame.size.height - self.frame.size.height - 10;
	
	[super setFrame:frameRect];
}

- (void) drawRect:(NSRect)dirtyRect
{
	[self.cell drawBezelWithFrame:dirtyRect inView:self];
	[self.cell drawImage:[self.cell image] withFrame:dirtyRect inView:self];
}

+ (Class) cellClass
{
	return [RakBackButtonCell class];
}

#pragma mark - Color

- (NSColor *) getColorBackground
{
	return [Prefs getSystemColor:GET_COLOR_BACKGROUD_BACK_BUTTONS];
}

- (NSColor *) getColorBackgroundSlider
{
	return [Prefs getSystemColor:GET_COLOR_BACKGROUD_BACK_BUTTONS_ANIMATING];
}

#pragma mark - Events

- (void) mouseEntered:(NSEvent *)theEvent
{
	cursorOnMe = true;
	[self startAnimation];
}

- (void) mouseExited:(NSEvent *)theEvent
{
	cursorOnMe = false;
	[self.cell setAnimationInProgress:false];
	[_animation stopAnimation];
}

//	Haaaaaccckkkyyyyyyyyy, in theory, nobody should call this function except before performing the click
- (SEL) action
{
	cursorOnMe = false;
	[self.cell setAnimationInProgress:false];
	return [super action];
}

#pragma mark - Animation

- (void) startAnimation
{
	_animation = [[NSAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationLinear];
	[_animation setFrameRate:20.0];
	[_animation setAnimationBlockingMode:NSAnimationNonblocking];
	[_animation setDelegate:self];
	
	for (NSAnimationProgress i = 0; i < 1; i+= 0.05)
	{
		[_animation addProgressMark:i];
	}
	
	[self.cell setAnimationInProgress:true];
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
	if(cursorOnMe && animation)
	{
		[self.cell setAnimationInProgress:false];
		[self performClick:self];
	}
}

@end

@implementation RakBackButtonCell

- (void) switchToNewContext : (NSString*) imageName : (short) state
{
	clicked		= [[RakResPath craftResNameFromContext:imageName : YES : YES : 1] retain];
	nonClicked	= [[RakResPath craftResNameFromContext:imageName : NO : YES : 1] retain];
	unAvailable = [[RakResPath craftResNameFromContext:imageName : NO : NO : 1] retain];
	
	notAvailable = false;
	
	if(state == RB_STATE_STANDARD && nonClicked != nil)
		[self setImage:nonClicked];
	else if(state == RB_STATE_HIGHLIGHTED && clicked != nil)
		[self setImage:clicked];
	else if(unAvailable != nil)
	{
		[self setImage:unAvailable];
		notAvailable = true;
	}
	else
	{
		NSLog(@"Failed at create button for icon: %@", imageName);
	}
}

- (void) setAnimationInProgress : (bool) start
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
		[[NSColor colorWithCalibratedWhite:0.0f alpha:0.35] setFill];
		NSRectFill(frame);
	}
	else if (animationInProgress)
	{
		NSRect drawingRect = frame;
		
		drawingRect.size.width *= animationStatus;
		if (animationStatus)
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
