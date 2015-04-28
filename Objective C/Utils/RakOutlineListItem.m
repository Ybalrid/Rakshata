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

@implementation RakOutlineListItem

- (id) init
{
	self = [super init];
	
	if(self != nil)
	{
		children = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (BOOL) isRootItem
{
	return _isRootItem;
}

- (uint) getNbChildren
{
	if([self isRootItem])
		return _nbChildren;
	return 0;
}

- (void) setChild : (id) child atIndex : (NSInteger) index
{
	if(children != nil)
	{
		[children insertObject:child atIndex:index];
	}
}

- (id) getChildAtIndex : (NSInteger) index
{
	if(children != nil && [children count] > index)
		return [children objectAtIndex:index];
	
	return nil;
}

- (id) getData
{
	return dataString;
}

@end