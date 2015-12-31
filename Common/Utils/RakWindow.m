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

@implementation RakWindow

- (void) configure
{
	((RakContentViewBack *) self.contentView).isMainWindow = YES;
	((RakContentViewBack *) self.contentView).title = [self getProjectName];

	[self.contentView setupBorders];

	self.movable = YES;
	self.movableByWindowBackground = YES;
	self.titlebarAppearsTransparent = YES;
	self.autorecalculatesKeyViewLoop = NO;
}

- (BOOL) canBecomeKeyWindow		{ return YES; }
- (BOOL) canBecomeMainWindow	{ return YES; }
- (BOOL) acceptsFirstResponder	{ return YES; }
- (BOOL) becomeFirstResponder	{ return YES; }
- (BOOL) resignFirstResponder	{ return YES; }

- (BOOL) isFullscreen
{
	return (self.styleMask & NSFullScreenWindowMask) == NSFullScreenWindowMask;
}

- (void) sendEvent:(NSEvent *)event
{
	//In some cases, the window would end up becoming the first responder, which is not an expected scenario
	if(self.firstResponder == self || [self.firstResponder class] == [RakContentView class])
	{
		uint thread = getMainThread();
		
		if(thread == TAB_SERIES)
			[self makeFirstResponder:RakApp.serie];
		else if(thread == TAB_CT)
			[self makeFirstResponder:RakApp.CT];
		else if(thread == TAB_READER)
			[self makeFirstResponder:RakApp.reader];
	}
	
	if(!self.fullscreen)
	{
		if([event type] == NSLeftMouseDown)
			[self mouseDown:event];
	}
	
	if([event type] == NSKeyDown)
	{
		if(self.shiftPressed && self.commandPressed)
		{
			NSString * character = [event charactersIgnoringModifiers];
			
			if(_isMainWindow)
			{
				if([character isEqualToString:@"f"])
					[self toggleFullScreen:self];
			}
		}
	}
	
	[super sendEvent:event];
}

- (void) flagsChanged:(NSEvent *)theEvent
{
	uint flags = [theEvent modifierFlags];
	
	self.shiftPressed		= (flags & NSShiftKeyMask) != 0;
	self.optionPressed		= (flags & NSAlternateKeyMask) != 0;
	self.controlPressed		= (flags & NSControlKeyMask) != 0;
	self.functionPressed	= (flags & NSFunctionKeyMask) != 0;
	self.commandPressed		= (flags & NSCommandKeyMask) != 0;
	
	[super flagsChanged:theEvent];
}

- (void) keyDown:(NSEvent *)theEvent
{
	[self.contentView keyDown:theEvent];
}

- (void) layoutIfNeeded
{
	
}

- (void) updateConstraintsIfNeeded
{
	
}

#pragma mark - Register D&D of file extension

- (void) registerForDrop
{
	[self registerForDraggedTypes:@[NSFilenamesPboardType]];
}

- (NSDragOperation) draggingEntered : (id <NSDraggingInfo>) sender
{
	NSArray *files = [[sender draggingPasteboard] propertyListForType: NSFilenamesPboardType];

	if(files != nil && [files count] != 0)
	{
		for(NSString * string in files)
		{
			NSString * extension = [string pathExtension];

			//If a directory
			if([extension isEqualToString:@""] && checkDirExist([string UTF8String]))
			{
				return NSDragOperationCopy;
			}

			if([extension caseInsensitiveCompare:SOURCE_FILE_EXT] == NSOrderedSame)
			{
				return NSDragOperationCopy;
			}

			for(NSString * sample in ARCHIVE_SUPPORT)
			{
				if([extension caseInsensitiveCompare:sample] == NSOrderedSame)
					return NSDragOperationCopy;
			}
		}
	}

	return NSDragOperationNone;
}

- (BOOL) prepareForDragOperation : (id <NSDraggingInfo>) sender
{
	NSArray *files = [[sender draggingPasteboard] propertyListForType: NSFilenamesPboardType];

	if(files == nil || [files count] == 0)
		return NO;

	[RakApp application:RakRealApp openFiles:files];

	return YES;
}

#pragma mark - Title management

- (NSString *) getProjectName
{
#ifdef EXTENSIVE_LOGGING
	return [NSString stringWithFormat:@"%s β", PROJECT_NAME];
#else
	return [NSString stringWithUTF8String:PROJECT_NAME];
#endif
}

- (void) resetTitle
{
	((RakContentViewBack *) self.contentView).title = [self getProjectName];
}

- (void) setProjectTitle : (PROJECT_DATA) project
{
	((RakContentViewBack *) self.contentView).title = [NSString stringWithFormat:@"%@ - %@", [self getProjectName], getStringForWchar(project.projectName)];
}

- (void) setCTTitle : (PROJECT_DATA) project : (NSString *) element
{
	((RakContentViewBack *) self.contentView).title = [NSString stringWithFormat:@"%@ - %@ - %@", [self getProjectName], getStringForWchar(project.projectName), element];
}

#pragma mark - Sheet management

//Because our title bar is a bit hacky, sheets stick at the top of our content view, and it seems it cause issues
//in its internal logic as it'll stick at the top of the window, instead of below the title bar. To fix this,
//we detect whenever the code managing the sheet will read our frame, and then tweak it to move the top of the window
//below the title bar. It seems it make the window a bit jumpy if you move the window before discarding but hey, good enough

- (void) beginCriticalSheet:(nonnull NSWindow *)sheetWindow completionHandler:(void (^ __nullable)(NSModalResponse))handler
{
	_sheetManipulation = YES;
	[super beginCriticalSheet:sheetWindow completionHandler:handler];
	_sheetManipulation = NO;
}

- (void)beginSheet:(NSWindow *)sheetWindow completionHandler:(void (^ __nullable)(NSModalResponse returnCode))handler
{
	_sheetManipulation = YES;
	[super beginSheet:sheetWindow completionHandler:handler];
	_sheetManipulation = NO;
}

- (void)endSheet:(NSWindow *)sheetWindow returnCode:(NSModalResponse)returnCode
{
	_sheetManipulation = YES;
	[super endSheet:sheetWindow returnCode:returnCode];
	_sheetManipulation = NO;
}

- (NSRect) frame
{
	NSRect frame = _frame;

	if(_sheetManipulation)
		frame.origin.y -= TITLE_BAR_HEIGHT + WIDTH_BORDER_ALL - 1;

	return frame;
}

#pragma mark - Delegate

- (BOOL) makeFirstResponder:(NSResponder *)aResponder
{
	id old = _imatureFirstResponder;
	
	_imatureFirstResponder = aResponder;
	BOOL retValue = [super makeFirstResponder:aResponder];
	_imatureFirstResponder = old;
	
	return retValue;
}

#pragma mark - Workaround

//This function initiate some dark magic with nextKeyView things to magically "update" everything
//Considering we manage all this manually, this is only getting in the way
//We only force it to respect the flag though
- (void) recalculateKeyViewLoop
{
	if(self.autorecalculatesKeyViewLoop)
		[super recalculateKeyViewLoop];
}

@end