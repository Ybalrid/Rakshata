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
 ********************************************************************************************/

#include "db.h"

static NSSize _workingSize = {RCVC_MINIMUM_WIDTH, RCVC_MINIMUM_HEIGHT};

enum
{
	BORDER_THUMB			= 150,
	BORDER_BOTTOM			= 7
};

@implementation RakCollectionViewItem

- (instancetype) initWithProject : (PROJECT_DATA) project
{
	if(!project.isInitialized || project.repo == NULL)
		return nil;
	
	self = [self initWithFrame:NSMakeRect(0, 0, RCVC_MINIMUM_WIDTH, RCVC_MINIMUM_HEIGHT)];
	
	if(self != nil)
	{
		_selected = NO;
		
		//We really don't care about those data, so we don't want the burden of having to update them
		project.chapitresFull = project.chapitresInstalled = NULL;
		project.tomesFull = project.tomesInstalled = NULL;
		project.chapitresPrix = NULL;
		
		_project = project;
		_workingArea.size = _workingSize;
		
		[self initContent];
		[self setFrameSize: NSMakeSize(_workingArea.size.height + BORDER_BOTTOM, _workingArea.size.width)];
	}
	
	return self;
}

- (void) initContent
{
	NSImage * image = [self loadImage];
	if(image != nil)
	{
		thumbnails = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, BORDER_THUMB, BORDER_THUMB)];
		if(thumbnails != nil)
		{
			thumbnails.image = image;
			[self addSubview:thumbnails];
		}
	}
	
	name = [[RakText alloc] initWithText :getStringForWchar(_project.projectName) : [self getTextColor]];
	if(name != nil)
	{
		name.alignment = NSCenterTextAlignment;
		name.font = [NSFont fontWithName:[Prefs getFontName:GET_FONT_SR_TITLE] size:13];

		[name.cell setWraps : YES];
		name.fixedWidth = RCVC_MINIMUM_WIDTH * 0.8;
		
		[self addSubview:name];
	}
	
	author = [[RakText alloc] initWithText:getStringForWchar(_project.authorName) : [self getTextColor]];
	if(author != nil)
	{
		author.alignment = NSCenterTextAlignment;
		author.font = [NSFont fontWithName:[Prefs getFontName:GET_FONT_STANDARD] size:10];
		
		[author.cell setWraps : YES];
		author.fixedWidth = RCVC_MINIMUM_WIDTH * 0.8;
		
		[self addSubview:author];
	}
	

	mainTag = [[RakText alloc] initWithText: @"Placeholder" :[self getTagTextColor]];
	if(mainTag != nil)
	{
		mainTag.stringValue = getStringForWchar(getTagForCode(getRandom() % 70));
		mainTag.alignment = NSCenterTextAlignment;
		mainTag.font = [NSFont fontWithName:[Prefs getFontName:GET_FONT_TAGS] size:10];
		[mainTag sizeToFit];
		
		[self addSubview:mainTag];
	}
	
	_requestedHeight = MAX(RCVC_MINIMUM_HEIGHT, [self getMinimumHeight]);
	_workingArea.size.height = _requestedHeight;
	_workingArea.origin = NSCenterSize(_bounds.size, _workingArea.size);
}

- (NSImage *) loadImage
{
	char * teamPath = getPathForRepo(_project.repo);
	
	if(teamPath == NULL)
		return nil;
	
	NSImage * image = nil;
	
	NSBundle * bundle = [NSBundle bundleWithPath: [NSString stringWithFormat:@"imageCache/%s/", teamPath]];
	if(bundle != nil)
		image = [bundle imageForResource:[NSString stringWithFormat:@"%d_"PROJ_IMG_SUFFIX_SRGRID, _project.projectID]];
	
	if(image == nil)
		image = [NSImage imageNamed:@"defaultSRImage"];
	
	return image;
}

#ifdef TRACKING_AREA_WORK_PROPERLY

- (void) viewDidMoveToSuperview
{
	[self removeTracking];
	[self addTracking];
}

- (void) viewDidHide
{
	[self removeTracking];
}

- (void) viewDidUnhide
{
	[self addTracking];
}

- (void) addTracking
{
	if(!haveTrackRect)
	{
		trackingArea = [[NSTrackingArea alloc] initWithRect:_workingArea options:NSTrackingActiveInActiveApp|NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
		[self addTrackingArea:trackingArea];
		
		if (NSPointInRect([self convertPoint: [self.window mouseLocationOutsideOfEventStream] fromView: nil], _bounds))
			[self mouseEntered:nil];

		haveTrackRect = YES;
	}
}

- (void) updateTrackingAreass
{
	[self removeTracking];
	[self addTracking];
	[super updateTrackingAreass];
}

- (void) removeTracking
{
	if(haveTrackRect)
	{
		[self removeTrackingArea:trackingArea];
		trackingArea = nil;
		haveTrackRect = NO;
	}
}

#endif

#pragma mark - Mouse handling

- (void) mouseEntered:(NSEvent *)theEvent
{
	if(!_selected)
	{
		_selected = YES;
		[self acquireFocus];
		[self setNeedsDisplay:YES];
	}
}

- (void) mouseExited:(NSEvent *)theEvent
{
	if(_selected)
	{
		_selected = NO;
		[self acquireFocus];
		[self setNeedsDisplay:YES];
	}
}

- (void) mouseDown:(NSEvent *)theEvent
{
	RakCollectionView * view = (id) self.superview;
	
	if([view class] == [RakCollectionView class])
		view.clickedView = self;

	[view mouseDown:theEvent];
}

- (void) mouseUp:(NSEvent *)theEvent
{
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	//Three cases: click on tag, click on author, other
	//The first two trigger a tag, the last select
	
	if(NSPointInRect(point, mainTag.frame))
	{
		uint ID = _getFromSearch(NULL, PULL_SEARCH_TAGID, &(_project.tag));
		
		if(ID != UINT_MAX)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:SR_NOTIFICATION_TAG object:getStringForWchar(getTagForCode(_project.tag)) userInfo:@{SR_NOTIF_CACHEID : @(ID), SR_NOTIF_OPTYPE : @(YES)}];
		}
	}
	else if(NSPointInRect(point, author.frame))
	{
		uint ID = _getFromSearch(NULL, PULL_SEARCH_AUTHORID, &(_project.authorName));
		
		if(ID != UINT_MAX)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:SR_NOTIFICATION_AUTHOR object:getStringForWchar(_project.authorName) userInfo:@{SR_NOTIF_CACHEID : @(ID), SR_NOTIF_OPTYPE : @(YES)}];
		}
	}
	else if(point.y > mainTag.frame.origin.y)	//We exclude when we are below the main tag
	{
		if(NSPointInRect(point, _workingArea))	//We check we are actually inside the valid area (excluding the padding
		{
			PROJECT_DATA dataToSend = getElementByID(_project.cacheDBID);

			if(dataToSend.isInitialized)
				[RakTabView broadcastUpdateContext: [[NSApp delegate] serie] : dataToSend : NO : VALEUR_FIN_STRUCT];
		}
	}
}

- (void) acquireFocus
{
	if(!_project.isInitialized)
		return;
	
	__block uint initialFocus = ++currentRequestID;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RCVC_FOCUS_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		if(initialFocus == currentRequestID)
		{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
				[[NSNotificationCenter defaultCenter] postNotificationName:SR_NOTIFICATION_FOCUS object:@(_project.cacheDBID)];
			});
		}
	});
}

#pragma mark - Resizing code

//We hook animator in order to run our logic during animated resizing
- (id) animator
{
	_animationRequested = YES;
	return self;
}

- (void) setFrame:(NSRect)frameRect
{
	BOOL animated = _animationRequested;
	
	if(animated)
	{
		_animationRequested = NO;
		[[super animator] setFrame:frameRect];
	}
	else
		[super setFrame:frameRect];
	
	[self resizeContent:frameRect.size :animated];
}

- (void) setFrameSize:(NSSize)newSize
{
	BOOL animated = _animationRequested;
	
	if(animated)
	{
		_animationRequested = NO;
		[[super animator] setFrameSize:newSize];
	}
	else
		[super setFrameSize:newSize];
	
	[self resizeContent:newSize :animated];
}

- (void) resizeContent : (NSSize) newSize : (BOOL) animated
{
	_workingArea.origin = NSCenterSize(newSize, _workingArea.size);
	
	//We resize our content
	NSPoint previousOrigin;
	
	if(animated)
	{
		[thumbnails.animator setFrameOrigin:	(previousOrigin = [self originOfThumb : _workingArea])];
		[name.animator setFrameOrigin: 			(previousOrigin = [self originOfName : _workingArea : previousOrigin])];
		[author.animator setFrameOrigin:		(previousOrigin = [self originOfAuthor : _workingArea : previousOrigin])];
		[mainTag.animator setFrameOrigin:		(previousOrigin = [self originOfTag : _workingArea : previousOrigin])];
	}
	else
	{
		[thumbnails setFrameOrigin: (previousOrigin = [self originOfThumb : _workingArea])];
		[name setFrameOrigin: 		(previousOrigin = [self originOfName : _workingArea : previousOrigin])];
		[author setFrameOrigin:		(previousOrigin = [self originOfAuthor : _workingArea : previousOrigin])];
		[mainTag setFrameOrigin:	(previousOrigin = [self originOfTag : _workingArea : previousOrigin])];
	}
}

- (NSPoint) originOfThumb : (NSRect) frameRect
{
	NSPoint output;
	
	output.x = frameRect.origin.x + frameRect.size.width / 2 - BORDER_THUMB / 2;
	output.y = frameRect.origin.y + frameRect.size.height - BORDER_THUMB;
	
	return output;
}

- (NSPoint) originOfName : (NSRect) frameRect : (NSPoint) thumbOrigin
{
	NSPoint center = NSCenteredRect(frameRect, name.bounds);
	
	center.y = thumbOrigin.y - name.bounds.size.height;
	
	return center;
}

- (NSPoint) originOfAuthor : (NSRect) frameRect : (NSPoint) nameOrigin
{
	NSPoint center = NSCenteredRect(frameRect, author.bounds);
	
	center.y = nameOrigin.y - author.bounds.size.height;
	
	return center;
}

- (NSPoint) originOfTag : (NSRect) frameRect : (NSPoint) authorOrigin
{
	NSPoint center = NSCenteredRect(frameRect, mainTag.bounds);
	
	center.y = authorOrigin.y - mainTag.bounds.size.height;
	
	return center;
}

- (CGFloat) getMinimumHeight
{
	return mainTag.bounds.size.height + author.bounds.size.height + name.bounds.size.height + BORDER_THUMB;
}

#pragma mark - Color & Drawing

- (NSColor *) getTextColor
{
	return [Prefs getSystemColor:GET_COLOR_CLICKABLE_TEXT :nil];
}

- (NSColor *) getTagTextColor
{
	return [Prefs getSystemColor:GET_COLOR_TAGITEM_FONT :nil];
}

- (NSColor *) borderColor
{
	return [NSColor blackColor];
}

- (NSColor *) backgroundColor
{
	return [NSColor grayColor];
}

- (void) drawRect:(NSRect)dirtyRect
{
	if(_selected)
	{
		NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:_workingArea xRadius:3 yRadius:3];
		
		[[self backgroundColor] setFill];
		[path fill];
	}
}

@end
