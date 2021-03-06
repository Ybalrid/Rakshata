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
	IMAGE_BORDER = 50,
	IMAGE_BORDER_ROOT = 10,
	BUTTON_BORDER = 60,
	BUTTON_SEPARATOR = 10,
	SYNOPSIS_HEIGHT = 80,
	SYNOPSIS_VERTICAL_BORDER = 5,
	CONTENT_BORDER = 10,
	LIST_HEIGHT = 130
};

@interface RakPrefsRepoDetails()
{
	RakImage * repoImage;
	RakClickableText * URL, * group, * nbElement;
	RakText * data;
	
	RakDeleteButton * flushButton, * deleteButton;
	
	RakSynopsis * description;
	RakPrefsRepoList * subrepoList;
	
	NSRect imageFrame;
	
	REPO_DATA * _repo;
	
	RakPrefsRepoView * __weak _responder;
}

@end

@implementation RakPrefsRepoDetails

- (instancetype) initWithRepo : (NSRect) frame : (BOOL) isRoot : (void *) repo : (RakPrefsRepoView *) responder
{
	self = [self initWithFrame:[self getFrame:frame]];
	
	if(self != nil)
	{
		_responder = responder;
		[self updateContent:isRoot :repo : NO];
		[Prefs registerForChange:self forType:KVO_THEME];
	}
	
	return self;
}

- (void) dealloc
{
	[Prefs deRegisterForChange:self forType:KVO_THEME];
}

- (NSRect) getFrame : (NSRect) parentFrame
{
	parentFrame.origin.x = PREFS_REPO_LIST_WIDTH + 10;
	parentFrame.origin.y = CONTENT_BORDER;
	
	parentFrame.size.width -= parentFrame.origin.x;
	parentFrame.size.height -= parentFrame.origin.y;
	
	return parentFrame;
}

- (NSRect) getSynopsisFrame : (NSRect) parentFrame
{
	parentFrame.origin.y = imageFrame.origin.y - SYNOPSIS_VERTICAL_BORDER - SYNOPSIS_HEIGHT;
	parentFrame.size.height = SYNOPSIS_HEIGHT;
	
	parentFrame.origin.x = CONTENT_BORDER;
	parentFrame.size.width -= 2 * CONTENT_BORDER;
	
	return parentFrame;
}

- (NSRect) listFrame : (NSRect) parentFrame
{
	parentFrame.origin.y = 0;
	parentFrame.size.height = LIST_HEIGHT;
	
	parentFrame.origin.x = CONTENT_BORDER;
	parentFrame.size.width -= 2 * CONTENT_BORDER;
	
	return parentFrame;
}

#pragma mark - Interface

- (void) updateContent : (BOOL) isRoot : (void *) repo : (BOOL) animated
{
	if(animated)
	{
		if(self.alphaValue)
		{
			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				
				context.duration = 0.2f;
				self. alphaAnimated = 0;
				
			} completionHandler:^{
				[self _updateContent:isRoot :repo];
				
				[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
					
					context.duration = 0.2f;
					self. alphaAnimated = 1;
					
				} completionHandler:^{}];
			}];
		}
		else
		{
			[self _updateContent:isRoot :repo];
			
			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				
				context.duration = 0.2f;
				self. alphaAnimated = 1;
				
			} completionHandler:^{}];
		}
	}
	else
	{
		[self _updateContent:isRoot :repo];
		if(self.alphaValue == 0)
			self.alphaValue = 1;
	}
}

- (void) _updateContent:(BOOL)isRoot :(void *)repo
{
	if(repo == NULL)
		return;
	
	_repo = repo;
	
	CGFloat baseY = self.bounds.size.height;
	
	repoImage = loadImageForRepo(isRoot, repo);
	if(repoImage != nil)
	{
		imageFrame.size = repoImage.size;
		imageFrame.origin.x = self.bounds.size.width / 2 - imageFrame.size.width / 2;
		imageFrame.origin.y = (baseY -= (isRoot ? IMAGE_BORDER_ROOT : IMAGE_BORDER) + imageFrame.size.height);
		
		[self setNeedsDisplay:YES];
	}
	else
		imageFrame = NSZeroRect;
	
	if(!isRoot)
	{
		description.hidden = YES;
		subrepoList.hidden = YES;
		
		//URL field
		if(((REPO_DATA *) repo)->website[0])
		{
			if(URL == nil)
			{
				URL = [[RakClickableText alloc] initWithText:NSLocalizedString(@"WEBSITE", nil) :[self textColor] responder:self];
				if(URL != nil)
				{
					[URL sizeToFit];
					[self addSubview:URL];
				}
			}
			else
				URL.hidden = NO;
			
			[URL setFrameOrigin:NSMakePoint(self.bounds.size.width / 2 - URL.bounds.size.width / 2, (baseY -= URL.bounds.size.height))];
			URL.URL = [NSString stringWithUTF8String : ((REPO_DATA *) repo)->website];
		}
		else
		{
			URL.hidden = YES;
		}
		
		//Metadata on repo
		NSString * string = [NSString stringWithFormat:@"[%s]%s", ((REPO_DATA *) repo)->language, ((REPO_DATA *) repo)->isMature ? " [-18]" : ""];
		if(string != nil)
		{
			if(data == nil)
			{
				data = [[RakText alloc] initWithText:string :[self textColor]];
				[self addSubview:data];
			}
			else
			{
				data.hidden = NO;
				data.stringValue = string;
			}
		}
		else
			data.hidden = YES;
		
		uint nbProject = getNumberInstalledProjectForRepo(false, repo);
		if(nbProject == 0)
			string = NSLocalizedString(@"PREFS-REPO-NO-ACTIVE-PROJECT", nil);
		else if(nbProject == 1)
			string = NSLocalizedString(@"PREFS-REPO-ONE-ACTIVE-PROJECT", nil);
		else
			string = [NSString localizedStringWithFormat:NSLocalizedString(@"PREFS-REPO-%zu-ACTIVE-PROJECT", nil), nbProject];
		
		if(nbElement == nil)
		{
			nbElement = [[RakClickableText alloc] initWithText:string :[self textColor] responder:self];
			if(nbElement != nil)
			{
				nbElement.URL = @(42);
				[self addSubview:nbElement];
			}
		}
		else
		{
			nbElement.hidden = NO;
			nbElement.stringValue = string;
			[nbElement sizeToFit];
		}
		
		if(flushButton == nil)
		{
			flushButton = [RakDeleteButton allocWithText:NSLocalizedString(@"PREFS-DELETE-CONTENT", nil)];
			if(flushButton != nil)
			{
				[flushButton.cell setBorderWidth:2];
				[flushButton.cell setCustomBackgroundColor:[Prefs getSystemColor:COLOR_REPO_LIST_BACKGROUND]];
				[flushButton sizeToFit];
				
				flushButton.target = self;
				flushButton.action = @selector(nukeTheDB);
				
				[self addSubview:flushButton];
			}
		}
		else
			flushButton.hidden = NO;
		
		if(deleteButton == nil)
		{
			deleteButton = [RakDeleteButton allocWithText:NSLocalizedString(@"PREFS-DELETE-SOURCE", nil)];
			if(deleteButton != nil)
			{
				[deleteButton.cell setBorderWidth:2];
				[deleteButton.cell setCustomBackgroundColor:[Prefs getSystemColor:COLOR_REPO_LIST_BACKGROUND]];
				[deleteButton sizeToFit];
				
				deleteButton.target = self;
				deleteButton.action = @selector(nukeEverything);
				
				[self addSubview:deleteButton];
			}
		}
		else
			deleteButton.hidden = NO;
		
		//Resizing
		if(!data.isHidden)
			[data setFrameOrigin:NSMakePoint(self.bounds.size.width / 2 - data.bounds.size.width / 2, (baseY -= data.bounds.size.height))];
		
		if(!nbElement.isHidden)
			[nbElement setFrameOrigin:NSMakePoint(self.bounds.size.width / 2 - nbElement.bounds.size.width / 2, (baseY -= nbElement.bounds.size.height))];
		
		[flushButton setFrameOrigin:NSMakePoint(self.bounds.size.width / 2 - BUTTON_SEPARATOR - flushButton.bounds.size.width, BUTTON_BORDER)];
		[deleteButton setFrameOrigin:NSMakePoint(self.bounds.size.width / 2 + BUTTON_SEPARATOR, BUTTON_BORDER)];
	}
	else
	{
		URL.hidden = YES;
		data.hidden = YES;
		nbElement.hidden = YES;
		flushButton.hidden = YES;
		deleteButton.hidden = YES;
		
		if(description == nil)
		{
			description = [[RakSynopsis alloc] initWithSynopsis:[self selectDescription:repo] :[self getSynopsisFrame : self.bounds] : YES];
			if(description != NULL)
			{
				description.haveBackground = YES;
				[self addSubview:description];
			}
		}
		else
		{
			description.hidden = NO;
			[description setStringToSynopsis:getStringForWchar([self selectDescription:repo])];
		}
		
		if(subrepoList == nil)
		{
			subrepoList = [RakPrefsRepoList alloc];
			if(subrepoList != nil)
			{
				subrepoList.responder = self;
				subrepoList.detailMode = YES;
				
				subrepoList = [subrepoList initWithFrame:[self listFrame : self.bounds]];
				
				[self addSubview:[subrepoList getContent]];
			}
		}
		else
		{
			subrepoList.hidden = NO;
			[subrepoList reloadContent:NO];
		}
	}
}

- (charType *) selectDescription : (ROOT_REPO_DATA *) root
{
	const uint nbSubRepo = root->nbSubrepo;
	
	if(root == NULL || !nbSubRepo || root->descriptions == NULL || root->langueDescriptions == NULL)
		return NULL;
	
	if(nbSubRepo == 1)
		return root->descriptions[0];
	
	for(NSString * element in [NSLocale preferredLanguages])
	{
		for(uint i = 0; i < nbSubRepo; i++)
		{
			if(!strcmp([element UTF8String], root->langueDescriptions[i]))
				return root->descriptions[i];
		}
	}
	
	//If we couldn't find a perfect hit, we try to use english
	for(uint i = 0; i < nbSubRepo; i++)
	{
		if(root->langueDescriptions[i] != NULL && !strcmp(root->langueDescriptions[i], "en"))
			return root->descriptions[i];
	}
	
#ifdef EXTENSIVE_LOGGING
	NSLog(@"Couldn't find a proper language in %@", [NSLocale preferredLanguages]);
#endif
	
	return NULL;
}

- (void) statusTriggered : (id) responder : (REPO_DATA *) repoData
{
	if([responder getButtonState])
		activateRepo(*repoData);
	else
		[self nukeEverything:responder :repoData];
}

#pragma mark - List data interface

- (void *) dataForMode : (BOOL) rootMode index : (uint) index
{
	if(index >= ((ROOT_REPO_DATA *) _repo)->nbSubrepo)
		return NULL;
	
	return &(((ROOT_REPO_DATA *) _repo)->subRepo[index]);
}

- (uint) sizeForMode : (BOOL) rootMode
{
	return ((ROOT_REPO_DATA *) _repo)->nbSubrepo;
}

- (void) selectionUpdate : (BOOL) isRoot : (uint) index
{
	[_responder selectionUpdate:isRoot :index];
}

#pragma mark - Responder

- (void) respondTo : (RakClickableText *) sender
{
	if(sender == nbElement)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:SR_NOTIFICATION_SOURCE object:getStringForWchar(_repo->name) userInfo:@{SR_NOTIF_CACHEID : @(getRepoID(_repo)), SR_NOTIF_OPTYPE : @(YES)}];
	}
	else
	{
		NSString * string = sender.URL;
		
		if(string != nil)
			ouvrirSite([string UTF8String]);
	}
}

- (void) nukeTheDB
{
	NSAlert * alert = [[NSAlert alloc] init];
	
	if(alert != nil)
	{
		alert.alertStyle = NSCriticalAlertStyle;
		alert.messageText = NSLocalizedString(@"PREFS-DELETE-CONTENT-TITLE", nil);
		alert.informativeText = NSLocalizedString(@"PREFS-DELETE-CONTENT-MESSAGE", nil);
		[alert addButtonWithTitle:NSLocalizedString(@"CANCEL", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"PREFS-DELETE-GO-FOR-IT", nil)];
		
		[alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
			if(returnCode != -NSModalResponseStop)
				[self deleteContent : NO : _repo];
		}];
	}
}

- (void) nukeEverything
{
	[self nukeEverything:nil : _repo];
}

- (void) nukeEverything : (id) responder : (REPO_DATA *) repoData
{
	NSAlert * alert = [[NSAlert alloc] init];
	
	if(alert != nil)
	{
		alert.alertStyle = NSCriticalAlertStyle;
		alert.messageText = NSLocalizedString(@"PREFS-DELETE-SOURCE-TITLE", nil);
		alert.informativeText = NSLocalizedString(@"PREFS-DELETE-SOURCE-MESSAGE", nil);
		[alert addButtonWithTitle:NSLocalizedString(@"CANCEL", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"PREFS-DELETE-GO-FOR-IT", nil)];
		
		[alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
			if(returnCode != -NSModalResponseStop)
				[self deleteContent:YES : repoData];
			else
				[responder cancelSelection];
		}];
	}
}

- (void) deleteContent : (BOOL) nukeRepo : (REPO_DATA *) repoData
{
	NSString * windowTitle = self.window.title;
	CTSelec * CT = RakApp.CT;
	Reader * reader = RakApp.reader;
	
	PROJECT_DATA readerProject = [reader activeProject], CTProject = [CT activeProject];
	uint64_t ID = getRepoID(repoData);
	
	if((CTProject.isInitialized && getRepoID(CTProject.repo) == ID) || (readerProject.isInitialized && getRepoID(readerProject.repo) == ID))
	{
		self.window.title = NSLocalizedString(@"PREFS-DELETE-KILL-USE", nil);
		
		BOOL readerDeleted = !readerProject.isInitialized, CTDeleted = !CTProject.isInitialized;
		
		//We check which tab are using content we are about to delete
		if(readerProject.isInitialized && getRepoID(readerProject.repo) == ID)
		{
			[reader resetReader];
			readerDeleted = YES;
		}
		
		if(CTProject.isInitialized && getRepoID(CTProject.repo) == ID)
		{
			if(readerDeleted)
			{
				[CT resetTabContent];
				CTDeleted = YES;
			}
			else
				[CT updateProject:readerProject.cacheDBID :reader.isTome :reader.currentElem];
		}
		
		//Update focus if required
		if(CTDeleted)
		{
			[RakTabView broadcastUpdateFocus:TAB_SERIES];
		}
		else if(readerDeleted)
		{
			if(getMainThread() == TAB_READER)
				[RakTabView broadcastUpdateFocus:TAB_CT];
		}
	}
	
	if(nukeRepo)
	{
		self.window.title = NSLocalizedString(@"PREFS-DELETE-REMOVE", nil);
		removeRepoFromCache(*repoData);
		deleteSubRepo(ID);
	}
	
	self.window.title = NSLocalizedString(@"PREFS-DELETE-PURGE", nil);
	
	//Delete projects
	char path[256], *repoPath = getPathForRepo(repoData);
	snprintf(path, sizeof(path), PROJECT_ROOT"%s/", repoPath);
	removeFolder(path);
	free(repoPath);
	
	if(!nukeRepo)
		setUninstalled(false, ID);	//Update DB, and notify everything
	
	self.window.title = windowTitle;
}

#pragma mark - Drawing

- (RakColor *) textColor
{
	return [Prefs getSystemColor:COLOR_CLICKABLE_TEXT];
}

- (void) drawRect:(NSRect)dirtyRect
{
	[repoImage drawInRect:imageFrame
				 fromRect:NSZeroRect
				operation:NSCompositeSourceOver
				 fraction:1.0];
}

- (void) mouseUp:(NSEvent *)theEvent
{
	NSPoint cursor = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	//Check the X coordinate
	if(flushButton != nil && deleteButton != nil && cursor.x > flushButton.frame.origin.x && cursor.x < NSMaxX(deleteButton.frame))
	{
		//Okay, we are between the two buttons, let's check on the Y coordinate
		if(cursor.y > MIN(flushButton.frame.origin.y, deleteButton.frame.origin.y) && cursor.y < NSMaxY(imageFrame))
			return;
	}
	
	[super mouseUp:theEvent];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([object class] != [Prefs class])
		return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	[flushButton.cell setCustomBackgroundColor:[Prefs getSystemColor:COLOR_REPO_LIST_BACKGROUND]];
	[deleteButton.cell setCustomBackgroundColor:[Prefs getSystemColor:COLOR_REPO_LIST_BACKGROUND]];
}

@end
