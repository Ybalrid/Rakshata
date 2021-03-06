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

@implementation RakContentViewBack

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if(self != nil)
		[self earlySetup];
	
	return self;
}

- (instancetype) initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self != nil)
		[self earlySetup];
	
	return self;
}

- (void) earlySetup
{
	[self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[self setAutoresizesSubviews:NO];
	[self setNeedsDisplay:YES];
	[self setWantsLayer:YES];
	
	titleView = [[RakText alloc] initWithText:@"" :[self textColor]];
	if(titleView != nil)
	{
		[titleView setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
		[self addSubview:titleView];
	}
}

- (void) setupBorders
{
	if(!didRegisterKVO)
	{
		[Prefs registerForChange:self forType:KVO_THEME];
		didRegisterKVO = YES;
	}

	self.backgroundColor = [self firstBorderColor];
	NSRect frame = [self internalFrame];
	
	frame.size.width -= 2 * WIDTH_BORDER_FAREST;
	frame.size.height -= 2 * WIDTH_BORDER_FAREST;
	frame.origin.x += WIDTH_BORDER_FAREST;
	frame.origin.y += WIDTH_BORDER_FAREST;

	internalRows1 = [[RakBorder alloc] initWithFrame:frame : WIDTH_BORDER_MIDDLE : 3.5 : [self middleBorderColor]];
	if(internalRows1 != nil)
		[self addSubview:internalRows1];
	
	frame.size.width -= 2 * WIDTH_BORDER_MIDDLE;
	frame.size.height -= 2 * WIDTH_BORDER_MIDDLE;
	frame.origin.x += WIDTH_BORDER_MIDDLE;
	frame.origin.y += WIDTH_BORDER_MIDDLE;
	
	if(self.window.isMainWindow)
	{
		internalRows2 = [[RakBorder alloc] initWithFrame:frame : WIDTH_BORDER_INTERNAL : 5.0 : [self lastBorderColor]];
		if(internalRows2 != nil)
			[self addSubview:internalRows2];
		
		if(firstResponder == nil)
			[self craftFirstResponder];
		else
		{
			[firstResponder removeFromSuperview];
			[self addSubview:firstResponder];
		}
		
		frame.size.width -= 2 * WIDTH_BORDER_INTERNAL;
		frame.size.height -= 2 * WIDTH_BORDER_INTERNAL;
		frame.origin.x += WIDTH_BORDER_INTERNAL;
		frame.origin.y += WIDTH_BORDER_INTERNAL;
		firstResponder.frame = frame;
	}
}

- (void) craftFirstResponder
{
	if(self.window.isMainWindow)
	{
		firstResponder = [[RakContentView alloc] initWithFrame:self.bounds];
		if(firstResponder != nil)
			[self addSubview:firstResponder];
	}
}

- (RakContentView *) getFirstResponder
{
	if(firstResponder == nil)
		[self craftFirstResponder];
	
	return firstResponder;
}

- (void) keyDown:(NSEvent *)theEvent
{
	[firstResponder keyDown:theEvent];
}

- (void) dealloc
{
	[internalRows1 removeFromSuperview];
	[internalRows2 removeFromSuperview];
	[firstResponder removeFromSuperview];
	
	if(didRegisterKVO)
	{
		[Prefs deRegisterForChange:self forType:KVO_THEME];
		didRegisterKVO = NO;
	}
}

#pragma mark - Positioning

- (void) setFrameSize:(NSSize)newSize
{
	if(_heightOffset + TITLE_BAR_HEIGHT)
	{
		NSSize windowSize = self.window.frame.size;
		
		if(windowSize.height > 0)
			newSize.height = MIN(newSize.height + _heightOffset + TITLE_BAR_HEIGHT, self.window.frame.size.height);
		else
			newSize.height += _heightOffset + TITLE_BAR_HEIGHT;
	}

	[super setFrameSize:newSize];
}

- (void) setFrame : (NSRect) frameRect
{
	[super setFrame:frameRect];
	
	if(![self.subviews count])
		return;
	
	[self centerTitle];
	
	frameRect = [self internalFrame];
	
	frameRect.size.width -= 2 * WIDTH_BORDER_FAREST;
	frameRect.size.height -= 2 * WIDTH_BORDER_FAREST;
	frameRect.origin.x += WIDTH_BORDER_FAREST;
	frameRect.origin.y += WIDTH_BORDER_FAREST;
	
	[internalRows1 setFrame:frameRect];
	
	frameRect.size.width -= 2 * WIDTH_BORDER_MIDDLE;
	frameRect.size.height -= 2 * WIDTH_BORDER_MIDDLE;
	frameRect.origin.x += WIDTH_BORDER_MIDDLE;
	frameRect.origin.y += WIDTH_BORDER_MIDDLE;

	[internalRows2 setFrame:frameRect];
	
	frameRect.size.width -= 2 * WIDTH_BORDER_INTERNAL;
	frameRect.size.height -= 2 * WIDTH_BORDER_INTERNAL;
	frameRect.origin.x += WIDTH_BORDER_INTERNAL;
	frameRect.origin.y += WIDTH_BORDER_INTERNAL;
	
	for(RakView * view in self.subviews)
	{
		if(view != titleView && [view class] != [RakBorder class])
			[view setFrame:frameRect];
	}
}

- (NSRect) internalFrame
{
	NSRect output = self.bounds;
	
	output.size.height -= _heightOffset + TITLE_BAR_HEIGHT;
	
	return output;
}

- (void) centerTitle
{
	NSRect bounds = titleView.bounds, internalFrame = [self internalFrame];
	
	[titleView setFrameOrigin:NSMakePoint(internalFrame.size.width / 2 - bounds.size.width / 2, internalFrame.size.height + TITLE_BAR_HEIGHT / 2 - bounds.size.height / 2)];
}

#pragma mark - Properties update

- (void) setHeightOffset:(CGFloat)heightOffset
{
	if(heightOffset == -TITLE_BAR_HEIGHT)
		titleView.hidden = YES;
	else
		titleView.hidden = NO;
	
	_heightOffset = heightOffset;
}

- (void) setTitle:(NSString *)title
{
	titleView.stringValue = _title = title;
	[titleView sizeToFit];
	[self centerTitle];
}

- (void) setIsMainWindow:(BOOL)isMainWindow
{
	isMainWindow &= self.window.isMainWindow;
	
	if(_isMainWindow != isMainWindow)
	{
		_isMainWindow = isMainWindow;
		titleView.textColor = [self textColor];

		[self setNeedsDisplay:YES];
	}
}

#pragma mark - Drawing

- (void) drawRect:(NSRect)dirtyRect
{
	NSRect internalFrame = [self internalFrame];
	dirtyRect = NSMakeRect(0, NSMaxY(internalFrame), internalFrame.size.width, TITLE_BAR_HEIGHT);
	
	if(_isMainWindow)
	{
		if((NSInteger)NSAppKitVersionNumber < NSAppKitVersionNumber10_10)
		{
			NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[[Prefs getSystemColor:COLOR_TITLEBAR_BACKGROUND_GRADIENT_START] colorWithAlphaComponent:0.7]
																 endingColor:[Prefs getSystemColor:COLOR_TITLEBAR_BACKGROUND_GRADIENT_END]];
			[gradient drawInRect:dirtyRect angle:90];
		}
		else
		{
			[[Prefs getSystemColor:COLOR_TITLEBAR_BACKGROUND_MAIN] setFill];
			NSRectFill(dirtyRect);
		}
	}
	else
	{
		[[Prefs getSystemColor:COLOR_TITLEBAR_BACKGROUND_STANDBY] setFill];
		NSRectFill(dirtyRect);
	}
}

#pragma mark - Color

- (RakColor *) textColor
{
	return _isMainWindow ? [Prefs getSystemColor:COLOR_SURVOL] : [Prefs getSystemColor:COLOR_HIGHLIGHT];
}

- (RakColor *) firstBorderColor
{
	return [Prefs getSystemColor:COLOR_EXTERNALBORDER_FAREST];
}

- (RakColor *) middleBorderColor
{
	if(self.window.isMainWindow)
		return [Prefs getSystemColor:COLOR_EXTERNALBORDER_MIDDLE];
	
	return [Prefs getSystemColor:COLOR_EXTERNALBORDER_MIDDLE_NON_MAIN];
}

- (RakColor *) lastBorderColor
{
	return [Prefs getSystemColor:COLOR_EXTERNALBORDER_CLOSEST];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([object class] != [Prefs class])
		return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	self.backgroundColor = [self firstBorderColor];
	[internalRows1 setColor: [self middleBorderColor]];
	
	if(self.window.isMainWindow)
		[internalRows2 setColor: [self lastBorderColor]];
	
	[titleView setTextColor:[self textColor]];
	
	[self setNeedsDisplay:YES];
}

@end

@implementation RakContentView

- (instancetype) initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self != nil)
	{
		[self setAutoresizesSubviews:NO];
#ifdef HIDE_EVERYTHING
		self.hidden = YES;
#endif
	}
	
	return self;
}

- (void) setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	
	for(RakTabView * view in self.subviews)
	{
		if(![view isKindOfClass:[RakTabView class]])
			continue;
		
		BOOL isMDL = [view class] == [MDL class], oldVal;
		
		if(isMDL)
		{
			oldVal = ((MDL*) view).needUpdateMainViews;
			((MDL*) view).needUpdateMainViews = NO;
		}
		
		[view setFrame:[view createFrame]];
		
		if(isMDL)
			((MDL*) view).needUpdateMainViews = oldVal;
	}
}

- (void) setupCtx : (Series*) tabSerie : (CTSelec*) tabCT : (Reader*) tabReader : (MDL*) tabMDL
{
	_tabSerie = tabSerie;
	_tabCT = tabCT;
	_tabReader = tabReader;
	_tabMDL = tabMDL;
}

- (void) updateContext : (uint) mainThread : (uint) stateTabsReader
{
	_mainThread = mainThread;
	_stateTabsReader = stateTabsReader;
}

- (void) cleanCtx
{
	_tabSerie = nil;
	_tabCT = nil;
	_tabReader = nil;
	_tabMDL = nil;
}

- (void)keyDown:(NSEvent *)theEvent
{
	switch (_mainThread)
	{
		case TAB_SERIES:
		{
			[_tabSerie keyDown:theEvent];
			break;
		}
			
		case TAB_CT:
		{
			[_tabCT keyDown:theEvent];
			break;
		}
			
		case TAB_MDL:
		{
			[_tabMDL keyDown:theEvent];
			break;
		}
			
		case TAB_READER:
		{
			[_tabReader keyDown:theEvent];
			break;
		}
			
		default:
			break;
	}
}

@end
