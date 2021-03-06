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
 ********************************************************************************************/

@implementation RakReaderBottomBar

#define RADIUS_BORDERS 13.0

- (instancetype) init: (BOOL) displayed : (Reader*) parent
{
	self = [super initWithFrame:[self createFrameWithSuperView:parent.frame]];
	
	if(self != nil)
	{
		isFaved = NO;
		
		[Prefs registerForChange:self forType:KVO_THEME];
		[self setAutoresizesSubviews:NO];
		
		_parent = parent;
		self.readerMode = parent.mainThread == TAB_READER;
		
		[self setWantsLayer:YES];
		[self.layer setCornerRadius:RADIUS_BORDERS];
		
		[self loadIcons : parent];
		
		if(!displayed)
			[self setHidden:![self isHidden]];
	}
	
	return self;
}

- (void) viewDidMoveToWindow
{
	[super viewDidMoveToWindow];
	[self updateTrackingAreaToBounds:self.bounds.size];
}

- (void) updateTrackingAreaToBounds : (NSSize) size
{
	trackingArea = [[NSTrackingArea alloc] initWithRect:(NSRect) {NSZeroPoint, size} options:NSTrackingActiveInActiveApp|NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
	[self addTrackingArea:trackingArea];
}

- (void) setupPath
{
	NSSize selfSize = self.frame.size;
	
	contextBorder = [[NSGraphicsContext currentContext] graphicsPort];
	
	CGContextBeginPath(contextBorder);
	CGContextAddArc(contextBorder, RADIUS_BORDERS, selfSize.height / 2, RADIUS_BORDERS, -5 * M_PI_2 / 3, M_PI_2, 1);
	CGContextAddLineToPoint(contextBorder, selfSize.width - RADIUS_BORDERS, selfSize.height);
	CGContextAddArc(contextBorder, selfSize.width - RADIUS_BORDERS, selfSize.height/2, RADIUS_BORDERS, M_PI_2, M_PI_2 / 3, 1);
}

- (void) releaseIcons
{
	RakButton* icons[] = {favorite, fullscreen, prevChapter, prevPage, nextPage, nextChapter, trash};
	
	for(int i = 0; i < 7; i++)
	{
		if(icons[i] != nil)
		{
			[icons[i] removeFromSuperview];
		}
	}
}

- (void) dealloc
{
	[Prefs deRegisterForChange:self forType:KVO_THEME];
	[self releaseIcons];
	
	if(pageCount != nil)
	{
		[pageCount removeFromSuperview];
	}
	
}

#pragma mark - Update page counter

- (void) updatePage : (uint) newCurrentPage : (uint) newPageMax
{
	if(pageCount == nil)
	{
		pageCount = [[RakPageCounter alloc] init: self : [self getPosXElement : 8 : self.frame.size.width] :newCurrentPage :newPageMax : (Reader*) self.superview];
		[self addSubview:pageCount];
	}
	else
	{
		[pageCount updatePage:newCurrentPage :newPageMax];
	}
}

- (void) triggerPageCounterPopover
{
	if(![pageCount openPopover])
		[pageCount closePopover];
}

#pragma mark - Buttons

- (short) numberIconsInBar
{
	return 7;
}

- (void) loadIcons : (Reader*) superview
{
	const CGFloat width = self.frame.size.width;
	
	favorite = [RakButton allocForReader:self :@"favs" :[self getPosXElement : 1 : width] :YES :self :@selector(switchFavs)];
	fullscreen = [RakButton allocForReader:self :@"fullscreen" :[self getPosXElement : 2 : width] :YES :superview :@selector(triggerFullscreen)];
	
	prevChapter = [RakButton allocForReader:self :@"prevChap" :[self getPosXElement : 3 : width] :NO :superview :@selector(prevChapter)];
	prevPage = [RakButton allocForReader:self :@"prev" :[self getPosXElement : 4 : width] :NO :superview :@selector(prevPage)];
	nextPage = [RakButton allocForReader:self :@"next" :[self getPosXElement : 5 : width] :YES :superview :@selector(nextPage)];
	nextChapter = [RakButton allocForReader:self :@"nextChap" :[self getPosXElement : 6 : width] :YES :superview :@selector(nextChapter)];
	
	trash = [RakReaderBBButton allocForReader:self :@"trash" :[self getPosXElement : 7 : width] :NO : self :@selector(reactToDelete)];
	
	if(favorite != nil && isFaved)	[self favsUpdated:isFaved];
	if(fullscreen != nil)		[fullscreen.cell setActiveAllowed:NO];
	if(prevChapter != nil)		[prevChapter.cell setActiveAllowed:NO];
	if(prevPage != nil)			[prevPage.cell setActiveAllowed:NO];
	if(nextPage != nil)			[nextPage.cell setActiveAllowed:NO];
	if(nextChapter != nil)		[nextChapter.cell setActiveAllowed:NO];
	if(trash != nil)			[trash.cell setActiveAllowed:NO];
}

- (void) favsUpdated : (BOOL) isNewStatedFaved
{
	isFaved = isNewStatedFaved;
	[favorite.cell setState: isNewStatedFaved ? RB_STATE_HIGHLIGHTED : RB_STATE_STANDARD];
}

- (void) switchFavs
{
	if(_parent.initWithNoContent)
		return;
	
	if(!isFaved)
		[[[RakFavsInfo alloc] autoInit] launchPopover : favorite];
	
	[_parent switchFavs];
}

- (void) reactToDelete
{
	if(!_parent.initWithNoContent && !trash.popoverOpened)
		trash.popoverOpened = [[[RakDeleteConfirm alloc] autoInit] launchPopover: trash : _parent];
}

- (CGFloat) getPosXElement : (uint) IDButton : (CGFloat) width
{
	CGFloat output = 0;
	
	switch (IDButton)
	{
		case 1:			//favorite
		{
			output = 20;
			break;
		}
		case 2:			//fullscreen
		{
			output = 60;
			break;
		}
			
		case 3:			//previous chapter
		{
			output = width / 2 - 40;
			
			if(prevChapter != nil)
				output -= prevChapter.frame.size.width;
			
			break;
		}
			
		case 4:			//previous page
		{
			output = width / 2 - 10;
			
			if(prevPage != nil)
				output -= prevPage.frame.size.width;
			
			break;
		}
			
		case 5:			//next page
		{
			output = width / 2 + 10;
			break;
		}
			
		case 6:			//next chapter
		{
			output = width / 2 + 40;
			break;
		}
			
		case 7:			//trash
		{
			output = width - 25;
			
			if(trash != nil)
				output -= trash.frame.size.width;
			
			break;
		}
			
		case 8:		//Page counter, we set the middle of the place we want to put it
		{
			//Centered between the next chapter and the trashcan
			//output = ((self.frame.size.width / 2 + 40 + 20) + (self.frame.size.width - 25)) / 2;
			output = width * 3 / 4 + 17.5f;		//Optimized version
			break;
		}
	}
	
	return output;
}

- (void) recalculateElementsPosition : (BOOL) isAnimated : (CGFloat) newWidth
{
	RakButton* icons[] = {favorite, fullscreen, prevChapter, prevPage, nextPage, nextChapter, trash};
	short nbElem = [self numberIconsInBar];
	CGFloat midleHeightBar = self.frame.size.height / 2, lastElemHeight = 0;
	NSPoint origin = NSZeroPoint;
	
	for(byte pos = 0; pos < nbElem; pos++)
	{
		if(icons[pos] == nil)
			continue;
		
		origin.x = [self getPosXElement : pos + 1 : newWidth];
		
		if(icons[pos].frame.size.height != lastElemHeight)
		{
			origin.y = midleHeightBar - icons[pos].frame.size.height / 2;
			lastElemHeight = icons[pos].frame.size.height;
		}
		
		if(isAnimated)
			[icons[pos] setFrameOriginAnimated:origin];
		else
			[icons[pos] setFrameOrigin:origin];
		
	}
	
	//Repositionate pageCounter
	[pageCount updateSize:self.frame.size.height : [self getPosXElement : 8 : newWidth]];
}

- (void) displaySuggestionsForProject : (PROJECT_DATA) project withOldDFState : (BOOL) oldDFState
{
	if(project.isInitialized && !_suggestionPopoverIsOpen)
	{
		RakReaderSuggestions * popover = [[RakReaderSuggestions alloc] autoInit];
		if(popover != nil)
		{
			//This is switched back by RakReaderSuggestions on close notification
			_suggestionPopoverIsOpen = YES;
			popover.openedLeavingDFMode = oldDFState;
			[popover launchPopover:nextChapter withProjectID:project.cacheDBID];
		}
	}
}

#pragma mark - Color stuffs

- (RakColor*) getMainColor
{
	return [Prefs getSystemColor:COLOR_READER_BAR];
}

- (RakColor*) getColorFront
{
	return [Prefs getSystemColor:COLOR_READER_BAR_FRONT];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[[self getMainColor] setFill];
	NSRectFill(dirtyRect);
	
	[self setupPath];
	[[self getColorFront] setStroke];
	CGContextStrokePath(contextBorder);
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([object class] != [Prefs class])
		return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	[self setNeedsDisplay:YES];
}

/*	Routines à overwrite	*/
#pragma mark - Routine to overwrite

- (void) resizeAnimation : (NSRect) frameRect
{
	if(self.readerMode)
		[self.animator setHidden:NO];
	
	[self setFrameInternal:frameRect :YES];
}

- (void) setFrame:(NSRect)frameRect
{
	[self setFrameInternal:frameRect :NO];
}

- (void) setFrameInternal : (NSRect) frameRect : (BOOL) isAnimated
{
	NSRect popoverFrame = [pageCount.window convertRectToScreen: (NSRect) {[pageCount convertPoint:NSMakePoint(pageCount.frame.size.width / 2, 0) toView:nil], NSZeroSize}];
	
	if(isAnimated)
		popoverFrame.origin.x += frameRect.origin.x - self.superview.frame.origin.x;
	
	if(!self.readerMode)
	{
		frameRect.size.height = [self getRequestedViewHeight:frameRect.size.height];
		
		if(frameRect.size.height == self.frame.size.height)
			return;
		
		frameRect.size.width = self.frame.size.width;
		frameRect.origin.x = self.frame.origin.x;
		frameRect.origin.y = self.frame.origin.y;
	}
	else
		frameRect = [self createFrameWithSuperView:frameRect];
	
	if(isAnimated)
	{
		popoverFrame.origin.x += frameRect.origin.x - self.frame.origin.x;
		[self setFrameAnimated:frameRect];
	}
	else
		[super setFrame:frameRect];
	
	if(self.readerMode)
	{
		if(isAnimated)
			popoverFrame.origin.x -= pageCount.frame.origin.x;
		
		[self recalculateElementsPosition : isAnimated : frameRect.size.width];
		[self updateTrackingAreaToBounds:frameRect.size];
		
		if(isAnimated)
			popoverFrame.origin.x += pageCount.frame.origin.x;
	}
	
	[pageCount updatePopoverFrame : popoverFrame : isAnimated];
}

- (void) setFrameOrigin:(NSPoint)newOrigin
{
	if(self.readerMode)
		[super setFrameOrigin:newOrigin];
}

- (void) mouseUp:(NSEvent *)theEvent
{
	//Prevent a clic on the bar to end up on the page
}

#pragma mark - Distraction free mode

- (void) mouseEntered:(NSEvent *)theEvent
{
	if(_parent.distractionFree && self.alphaValue != 1.0f)
	{
		[_parent abortFadeTimer];
		self.highjackedMouseEvents = YES;
		[_parent fadeBottomBar:1.0f];	//We recycle the call, otherwise, we'd have to rewrite the same animation block
	}
}

- (void) mouseExited:(NSEvent *)theEvent
{
	if(_parent.distractionFree)
	{
		[_parent fadeBottomBar:READER_BB_ALPHA_DF];	//We recycle the call, otherwise, we'd have to rewrite the same animation block

		self.highjackedMouseEvents = NO;
		[_parent startFadeTimer:[NSEvent mouseLocation]];
	}
}

/*Constraints routines*/
#pragma mark - Data about bar position

- (NSRect) createFrameWithSuperView : (NSRect) superviewRect
{
	NSSize size = superviewRect.size;
	return NSMakeRect([self getRequestedViewPosX : size.width], [self getRequestedViewPosY : size.height], [self getRequestedViewWidth:size.width], [self getRequestedViewHeight:size.height]);
}

- (CGFloat) getRequestedViewPosX : (CGFloat) widthWindow
{
	return widthWindow / 2 - [self getRequestedViewWidth : widthWindow] / 2;
}

- (CGFloat) getRequestedViewPosY:(CGFloat) heightWindow
{
	return heightWindow - RD_CONTROLBAR_POSY - RD_CONTROLBAR_HEIGHT;
}

- (CGFloat) getRequestedViewWidth:(CGFloat) widthWindow
{
	CGFloat output = widthWindow * RD_CONTROLBAR_WIDHT_PERC / 100;
	
	output = MIN(output, RD_CONTROLBAR_WIDHT_MAX);
	output = MAX(output, RD_CONTROLBAR_WIDHT_MIN);
	
	return output;
}

- (CGFloat) getRequestedViewHeight:(CGFloat) heightWindow
{
	return RD_CONTROLBAR_HEIGHT;
}

@end

@implementation RakReaderBBButton

- (instancetype) init
{
	self = [super init];
	
	if(self != nil)
		self.popoverOpened = NO;
	
	return self;
}

- (void) mouseDown:(NSEvent *)theEvent
{
	if(self.popoverOpened)
		[self.nextResponder mouseDown:theEvent];
	else
		[super mouseDown:theEvent];
}

- (void) removePopover
{
	self.popoverOpened = NO;
}

@end
