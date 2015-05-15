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

enum
{
	BORDER_BOTTOM = 14,
	BORDER_BOTTOM_EXTENDED = 14 + 20,
	OFFSET_BUTTON = 28
};

@implementation MDL

- (instancetype) init : (NSView *) contentView : (NSString *) state
{
    self = [super init];
    if (self)
	{
		flag = TAB_MDL;
		_needUpdateMainViews = NO;
		self.forcedToShowUp = NO;
		_popover = nil;
		self = [self initView: contentView : state];
		canDeploy = false;
		
		self.layer.borderColor = [Prefs getSystemColor:GET_COLOR_BORDER_TABS:self].CGColor;
		self.layer.borderWidth = 2;
		
		if(![self initContent:state])
			self = nil;
	}
    return self;
}

- (BOOL) initContent : (NSString *) state
{
	controller = [[RakMDLController alloc] init: self : state];
	if(controller == nil)
		return NO;
	
	coreView = [[RakMDLView alloc] initContent:[self getCoreviewFrame : _bounds] : state : controller];
	if(coreView != nil)
		[self addSubview:coreView];
	
	footer = [[RakMDLFooter alloc] initWithFrame:[self getFooterFrame:_bounds]];
	if(footer != nil)
	{
		footer.controller = controller;
		footer.hidden = self.mainThread != TAB_SERIES;
		[self addSubview:footer];
	}
	
	return YES;
}

- (BOOL) available
{
	return coreView != nil && [controller getNbElem:YES] != 0;
}

- (void) wakeUp
{
	[coreView wakeUp];
	_needUpdateMainViews = YES;
	[self updateDependingViews : YES];
}

- (NSString *) byebye
{
	[controller needToQuit];
	
	NSString * output = [controller serializeData];
	return output != nil ? output : [super byebye];
}

- (void) dealloc
{
	[coreView removeFromSuperview];
}

- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent { return NO; }
- (BOOL) acceptsFirstResponder { return NO; }

#pragma mark - Proxy

- (void) proxyAddElement : (PROJECT_DATA) data  isTome : (bool) isTome element : (int) newElem  partOfBatch : (bool) partOfBatch
{
	if(controller != nil)
		[controller addElement:data :isTome :newElem :partOfBatch];
}

- (BOOL) proxyCheckForCollision : (PROJECT_DATA) data : (BOOL) isTome : (int) element
{
	if(controller != nil)
		return [controller checkForCollision:data :isTome :element];
	return NO;
}

#pragma mark - View sizing manipulation

- (CGFloat) getBottomBorder
{
	return self.mainThread == TAB_SERIES ? BORDER_BOTTOM_EXTENDED : BORDER_BOTTOM;
}

- (NSRect) getCoreviewFrame : (NSRect) frame
{
	NSRect output = frame;
	
	output.origin.x = frame.size.width / 20;
	output.size.width -= 2 * output.origin.x;
	output.origin.y = 0;

	output.size.height -= [self getBottomBorder];

	return output;
}

- (NSRect) getFooterFrame : (NSRect) frame
{
	NSRect output = frame;
	
	output.origin.y = output.size.height - BORDER_BOTTOM_EXTENDED;
	output.size.height = BORDER_BOTTOM_EXTENDED;
	
	return output;
}

- (NSRect) lastFrame
{
	if(_lastFrame.size.height + _lastFrame.origin.y <= 0 || _lastFrame.size.width + _lastFrame.origin.x <= 0)
		return NSZeroRect;
	
	return [super lastFrame];
}

- (void) resizeAnimation
{
	[super resizeAnimation];

	if (_popover != nil && ![self isDisplayed])
	{
		[_popover locationUpdated :[self createFrame] :YES];
	}
}

- (void) resize : (NSRect) frame : (BOOL) animated
{
	if(coreView != nil)
	{
		NSRect coreFrame = [self getCoreviewFrame : frame];
		
		if(animated)
			[coreView resizeAnimation:coreFrame];
		else
			[coreView setFrame:coreFrame];
	}
	
	if(footer != nil)
	{
		NSRect footerFrame = [self getFooterFrame:frame];
		
		if(animated)
			[footer resizeAnimation : footerFrame];
		else
			[footer setFrame:footerFrame];
	}
	
	if(_popover != nil)
		[_popover locationUpdated:frame:animated];
	
	if(_needUpdateMainViews)
		[self updateDependingViews : NO];
}

#pragma mark - Sizing

- (BOOL) isStillCollapsedReaderTab
{
	uint state;
	[Prefs getPref:PREFS_GET_READER_TABS_STATE :&state];
	return (state & STATE_READER_TAB_MDL_FOCUS) == 0;
}

- (NSRect) createFrameWithSuperView : (NSView*) superview
{
	NSRect maximumSize = [super createFrameWithSuperView:superview];
	
	//Our height is synced to the height of the coreview of the serie tab if focus is on series
	if(self.mainThread == TAB_SERIES)
		maximumSize.size.height = [[[NSApp delegate] serie] getHeightOfMainView];
	
	if(coreView != nil && !self.forcedToShowUp)
	{
		maximumSize.size.height = round(maximumSize.size.height);
		
		CGFloat contentHeight = [coreView getContentHeight] + [self getBottomBorder];
		
		if([controller getNbElem:YES] == 0)	//Let's get the fuck out of here, it's empty
		{
			//The animation is different depending of the focus
			//Series make us slide to the left, while the others to the bottom
			if(_lastFrame.size.width != - _lastFrame.origin.x && _lastFrame.size.height != - _lastFrame.origin.y)
				_needUpdateMainViews = YES;

			if(self.mainThread == TAB_SERIES)
			{
				maximumSize.origin.x = -maximumSize.size.width;
			}
			else
			{
				maximumSize.size.height = contentHeight;
				maximumSize.origin.y = -contentHeight;
			}
		}
		
		else if(maximumSize.size.height > contentHeight - 1)
		{
			if(self.mainThread != TAB_SERIES)
			{
				maximumSize.size.height = contentHeight;
				
				if(_lastFrame.size.height != contentHeight)
					_needUpdateMainViews = YES;
			}
			
			[coreView updateScroller:YES];
		}
		else
			[coreView updateScroller:NO];
	}

	[self setLastFrame:maximumSize];
	return maximumSize;
}

- (void) updateDependingViews : (BOOL) animated
{
	if(!_needUpdateMainViews)
		return;
	
	RakAppDelegate * delegate = (RakAppDelegate *) [NSApp delegate];
	
	if(animated)
	{
		[delegate CT].forceNextFrameUpdate = YES;
		[self refreshLevelViewsAnimation : self.superview];
	}
	else
	{
		for(RakTabView * view in @[[delegate serie], [delegate CT], [delegate reader]])
			[view refreshViewSize];
	}

	_needUpdateMainViews = NO;
}

- (void) fastAnimatedRefreshLevel : (NSView*) superview
{
	if(self.mainThread == TAB_SERIES)
		[[NSApp delegate] serie].forceNextFrameUpdate = YES;

	else if(self.mainThread == TAB_CT)
		[[NSApp delegate] CT].forceNextFrameUpdate = YES;
	
	[super fastAnimatedRefreshLevel:superview];
}

- (NSRect) generateNSTrackingAreaSize
{
	NSSize svSize = self.superview.frame.size;
	NSRect frame = [self lastFrame];
	
	frame.origin = NSZeroPoint;

	[Prefs getPref : PREFS_GET_TAB_READER_POSX : &(frame.size.width) : &svSize];
	
	return frame;
}

- (void) refreshViewSize
{
	[self setFrame: [self createFrame]];
	[self refreshDataAfterAnimation];
}

- (NSRect) getFrameOfNextTab
{
	NSSize sizeSuperview = self.superview.bounds.size;
	NSRect output;
	[Prefs getPref:PREFS_GET_TAB_READER_FRAME :&output : &sizeSuperview];
	
	return output;
}

- (uint) getFrameCode
{
	return PREFS_GET_MDL_FRAME;
}

- (void) mouseEntered:(NSEvent *)theEvent
{
	if(!self.forcedToShowUp)
		[super mouseEntered:theEvent];
}

#pragma mark - Animation

- (void) setUpViewForAnimation : (uint) mainThread
{
	BOOL inSeries = mainThread == TAB_SERIES;

	if(inSeries == footer.isHidden)
	{
		if(inSeries)
		{
			footer.alphaValue = 0;
			footer.hidden = NO;
		}

		footer.animator.alphaValue = inSeries;
	}
	
	[super setUpViewForAnimation:mainThread];
}

- (void) refreshDataAfterAnimation
{
	if([controller getNbElem:YES] != 0)
	{
		[super refreshDataAfterAnimation];
		[self updateDependingViews : NO];
	}
	
	if(footer.alphaValue == 0)
		footer.hidden = YES;
}

#pragma mark - Login request

- (NSString *) waitingLoginMessage
{
	if(controller != NULL && controller.requestCredentials)
	{
		return NSLocalizedString(@"MDL-LOGIN-TO-PAY", nil);
	}
	
	return NSLocalizedString(@"MDL-LOGIN-TO-AUTH", nil);
}

#pragma mark - Intertab communication

- (void) propagateContextUpdate : (PROJECT_DATA) data : (bool) isTome : (int) element
{
	[[(RakAppDelegate*) [NSApp delegate] CT]		updateContextNotification : data : isTome : VALEUR_FIN_STRUCT];
	[[(RakAppDelegate*) [NSApp delegate] reader]	updateContextNotification : data : isTome : element];
}

- (void) registerPopoverExistance : (RakReaderControllerUIQuery*) popover
{
	_popover = popover;
}

#pragma mark - Drag and drop UI effects

- (BOOL) isDisplayed
{
	return (self.forcedToShowUp || (_lastFrame.origin.y != -_lastFrame.size.height && _lastFrame.origin.x != -_lastFrame.size.width));
}

- (void) dragAndDropStarted : (BOOL)started : (BOOL) canDL
{
	if(!canDL)
		return;
	
	if(started)
	{
		if(self.forcedToShowUp)
			self.forcedToShowUp = NO;
		
		if([self isDisplayed] && !self.waitingLogin)
			return;
		
		self.forcedToShowUp = YES;
	}
	else if (self.forcedToShowUp)
		self.forcedToShowUp = NO;
	
	else
		return;
	
	[coreView hideList: self.forcedToShowUp];
	[coreView setFocusDrop : self.forcedToShowUp];
	
	_needUpdateMainViews = YES;
	[self updateDependingViews : YES];
}

#pragma mark - Drop support

- (NSDragOperation) dropOperationForSender : (uint) sender : (BOOL) canDL
{
	if(!canDL)
		return NSDragOperationNone;
	if (sender == TAB_SERIES || sender == TAB_CT)
		return NSDragOperationCopy;
	
	return [super dropOperationForSender:sender:canDL];
}

- (BOOL) receiveDrop : (PROJECT_DATA) data : (bool) isTome : (int) element : (uint) sender;
{
	return (coreView != nil && [coreView proxyReceiveDrop:data :isTome :element :sender]);
}

@end
