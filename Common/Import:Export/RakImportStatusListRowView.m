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

@implementation RakImportStatusListRowView

- (instancetype) initWithFrame : (NSRect) frame
{
	self = [super initWithFrame : frame];

	if(self != nil)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkRefreshStatus) name:NOTIFICATION_IMPORT_STATUS_UI object:nil];
		[Prefs registerForChange:self forType:KVO_THEME];
	}

	return self;
}

- (void) dealloc
{
	[Prefs deRegisterForChange:self forType:KVO_THEME];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) updateWithItem : (RakImportStatusListItem *) item
{
	listItem = item;
	_item = item.itemForChild;
	isRoot = item.isRootItem;
	
	[[[RakImportMenu alloc] initWithResponder:listItem] configureMenu:self];

	if(projectName == nil)
	{
		projectName = [[RakText alloc] initWithText:[self getLineName : item] :[Prefs getSystemColor:COLOR_CLICKABLE_TEXT]];
		if(projectName != nil)
			[self addSubview:projectName];
	}
	else
	{
		projectName.stringValue = [self getLineName : item];
		[projectName sizeToFit];
	}

	if(button == nil)
	{
		button = [[RakStatusButton alloc] initWithStatus:item.status];
		if(button != nil)
		{
			button.underlyingBackgroundColor = [Prefs getSystemColor:COLOR_IMPORT_LIST_BACKGROUND];
			button.target = self;
			button.action = @selector(getDetails);
			[self addSubview:button];
		}
	}
	else
		button.status = item.status;

	button.stringValue = [self determineMessageForStatus : button.status andItem:item];

	//Refresh everything's position
	if(!NSEqualSizes(self.bounds.size, NSZeroSize))
		[self setFrameSize:self.bounds.size];
}

- (byte) status
{
	return button.status;
}

- (void) setFrameSize:(NSSize)newSize
{
	[super setFrameSize:newSize];

	newSize = self.bounds.size;

	[projectName setFrameOrigin:NSMakePoint(20, newSize.height / 2 - projectName.bounds.size.height / 2)];

	NSSize itemSize = button.bounds.size;
	[button setFrameOrigin:NSMakePoint(newSize.width - itemSize.width - (isRoot ? 18 : 20), newSize.height / 2 - itemSize.height / 2)];
}

#pragma mark - Logic

- (NSString *) getLineName : (RakImportStatusListItem *) item
{
	if(isRoot)
		return getStringForWchar(item.projectData.projectName);

	if(_item.isTome)
	{
		META_TOME metadata = _item.projectData.data.tomeLocal[0];

		if(metadata.readingID != INVALID_SIGNED_VALUE || metadata.readingName[0])
			return getStringForVolumeFull(metadata);

		return _item.path;
	}

	uint content = _item.contentID;

	if(content == INVALID_VALUE)
		return _item.path;

	return getStringForChapter(content);
}

- (NSString *) determineMessageForStatus : (byte) status andItem : (RakImportStatusListItem *) item
{
	if(status == STATUS_BUTTON_OK)
		return NSLocalizedString(@"IMPORT-STATUS-OK", nil);

	if(item.isRootItem && item.metadataProblem)
		return NSLocalizedString(@"IMPORT-STATUS-ROOT-METADATA", nil);

	else if(item.isRootItem || status == STATUS_BUTTON_WARN)
		return NSLocalizedString(@"IMPORT-STATUS-ROOT-WARN", nil);

	//Ok, error
	else if(item.itemForChild.issue == IMPORT_PROBLEM_DUPLICATE)
		return NSLocalizedString(@"IMPORT-STATUS-DUPLICATE", nil);

	else if(item.itemForChild.issue == IMPORT_PROBLEM_INSTALL_ERROR)
		return [NSString localizedStringWithFormat:NSLocalizedString(@"IMPORT-STATUS-%@-CORRUPTED", nil), NSLocalizedString(_item.isTome ? @"VOLUME" : @"CHAPTER", nil)];
	
	else if(item.itemForChild.issue == IMPORT_PROBLEM_METADATA_DETAILS)
		return NSLocalizedString(@"IMPORT-STATUS-CHILD-METADATA", nil);

	return NSLocalizedString(@"IMPORT-STATUS-MISSING-DATA", nil);
}

- (void) checkRefreshStatus
{
	byte oldStatus = button.status;
	button.status = listItem.status;

	button.stringValue = [self determineMessageForStatus : button.status andItem:listItem];

	projectName.stringValue = [self getLineName : listItem];
	[projectName sizeToFit];

	if(oldStatus != button.status)
		[self setNeedsDisplay:YES];

	if(button.status != STATUS_BUTTON_ERROR && _list.query == alert)
		_list.query = alert = nil;
}

- (void) getDetails
{
	if(isRoot)
	{
		if(listItem.metadataProblem)
		{
			_list.query = alert = [[RakImportQuery alloc] autoInitWithMetadata:listItem.projectData];
			if(alert != nil)
			{
				if(isRoot)
				{
					RakImportStatusListItem * child = [listItem getChildAtIndex:0];
					if(child != nil)
						alert.itemOfQueryForMetadata = child.itemForChild;
				}
				else
					alert.itemOfQueryForMetadata = _item;
			}
		}
	}

	else if(_item.issue == IMPORT_PROBLEM_DUPLICATE)
		_list.query = alert = [[RakImportQuery alloc] autoInitWithDuplicate:_item];

	else	//_item.issue == IMPORT_PROBLEM_METADATA_DETAILS || listItem.metadataProblem
		_list.query = alert = [[RakImportQuery alloc] autoInitWithDetails:_item];
	
	[alert launchPopover:button :self];
}

#pragma mark - Theme

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([object class] != [Prefs class])
		return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	button.underlyingBackgroundColor = [Prefs getSystemColor:COLOR_IMPORT_LIST_BACKGROUND];
}

@end

