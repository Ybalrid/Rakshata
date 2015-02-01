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
		workingSize = _workingSize;
		
		[self initContent];
		[self setFrameSize: workingSize];
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
		uint random = getRandom() % 70;
		if(random < 10)			mainTag.stringValue = @"Shonen";
		else if(random < 20)	mainTag.stringValue = @"Shojo";
		else if(random < 30)	mainTag.stringValue = @"Seinen";
		else if(random < 40)	mainTag.stringValue = @"Comics";
		else if(random == 42)	mainTag.stringValue = @"Pony";
		else if(random < 50)	mainTag.stringValue = @"Manwa";
		else if(random < 60)	mainTag.stringValue = @"Webcomic";
		else if(random < 69)	mainTag.stringValue = @"Ecchi";
		else 					mainTag.stringValue = @"Hentai";
		
		mainTag.alignment = NSCenterTextAlignment;
		mainTag.font = [NSFont fontWithName:[Prefs getFontName:GET_FONT_TAGS] size:10];
		[mainTag sizeToFit];
		
		[self addSubview:mainTag];
	}
	
	_requestedHeight = MAX(RCVC_MINIMUM_HEIGHT, [self getMinimumHeight]);
	workingSize.height = _requestedHeight;
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

- (void) mouseDown:(NSEvent *)theEvent
{
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	//Three cases: click on tag, click on author, other
	//The first two trigger a tag, the last select
	
	if(NSPointInRect(point, mainTag.frame))
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:SR_NOTIFICATION_TAG object:nil userInfo:@{SR_NOTIF_CACHEID : @(_project.cacheDBID)}];
	}
	else if(NSPointInRect(point, author.frame))
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:SR_NOTIFICATION_AUTHOR object:nil userInfo:@{SR_NOTIF_CACHEID : @(_project.cacheDBID)}];
	}
	else if(point.y > mainTag.frame.origin.y)	//We exclude when we are below the main tag
	{
		NSRect mainFrame;	mainFrame.size = workingSize;
		mainFrame.origin = NSCenterSize(self.bounds.size, mainFrame.size);
		
		if(NSPointInRect(point, mainFrame))	//We check we are actually inside the valid area (excluding the padding
		{
			PROJECT_DATA dataToSend = getElementByID(_project.cacheDBID);

			if(dataToSend.isInitialized)
				[RakTabView broadcastUpdateContext: [[NSApp delegate] serie] : dataToSend : NO : VALEUR_FIN_STRUCT];

//			[[NSNotificationCenter defaultCenter] postNotificationName:SR_NOTIFICATION_PROJECT object:nil userInfo:@{SR_NOTIF_CACHEID : @(_project.cacheDBID)}];
		}
	}
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
	NSRect frameRect;
	//We update the frame
	frameRect.origin = NSCenterSize(newSize, workingSize);
	frameRect.size = workingSize;
	
	//We resize our content
	NSPoint previousOrigin;
	
	if(animated)
	{
		[thumbnails.animator setFrameOrigin:	(previousOrigin = [self originOfThumb : frameRect])];
		[name.animator setFrameOrigin: 			(previousOrigin = [self originOfName : frameRect : previousOrigin])];
		[author.animator setFrameOrigin:		(previousOrigin = [self originOfAuthor : frameRect : previousOrigin])];
		[mainTag.animator setFrameOrigin:		(previousOrigin = [self originOfTag : frameRect : previousOrigin])];
	}
	else
	{
		[thumbnails setFrameOrigin: (previousOrigin = [self originOfThumb : frameRect])];
		[name setFrameOrigin: 		(previousOrigin = [self originOfName : frameRect : previousOrigin])];
		[author setFrameOrigin:		(previousOrigin = [self originOfAuthor : frameRect : previousOrigin])];
		[mainTag setFrameOrigin:	(previousOrigin = [self originOfTag : frameRect : previousOrigin])];
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
	return BORDER_BOTTOM + mainTag.bounds.size.height + author.bounds.size.height + name.bounds.size.height + BORDER_THUMB;
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
		NSRect printArea = {NSCenterSize(dirtyRect.size, workingSize), workingSize};
		NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:printArea xRadius:3 yRadius:3];
		
		[[self backgroundColor] setFill];
		[path fill];
	}
}

@end
