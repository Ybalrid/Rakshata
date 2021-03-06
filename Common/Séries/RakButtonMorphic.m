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

@implementation RakButtonMorphic

+ (instancetype) allocImages : (NSArray*) imageNames : (id) target : (SEL) selector
{
	if(imageNames == nil || [imageNames count] == 0 || target == nil)
		return nil;
	
	RakButtonMorphic * output = [self allocImageWithBackground:imageNames[0] :target : selector];
	
	if(output != nil)
	{
		[output.cell setActiveAllowed:NO];
		output = [output initImages : imageNames];
	}
	
	return output;
}

- (instancetype) initImages : (NSArray*) imageNames
{
	[Prefs registerForChange:self forType:KVO_THEME];
	didRegister = YES;
	
	if(![self updateImages:imageNames])
		return nil;
	
	_activeCell = 0;
	_imageNames = [NSArray arrayWithArray:imageNames];
	
	return self;
}

- (void) dealloc
{
	if(didRegister)
		[Prefs deRegisterForChange:self forType:KVO_THEME];
}

#pragma mark - Context update

- (BOOL) updateImages : (NSArray *) imageNames
{
	NSMutableArray * images = [NSMutableArray array];
	
	RakImage * image;
	BOOL firstPass = YES;
	
	for(NSString * imageName in imageNames)
	{
		if(firstPass)
		{
			[images addObject : self.image];
			firstPass = !firstPass;
		}
		else
		{
			image = getResImageWithName(imageName);
			if(image != nil)
				[images addObject:image];
			else
				return NO;
		}
	}
	
	_images = [NSArray arrayWithArray:images];
	
	return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([object class] != [Prefs class])
		return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	RakImage * image = getResImageWithName(_imageNames[0]);
	
	if(image != nil)
	{
		self.image = image;
		[self updateImages:_imageNames];
	}
	
	[self setNeedsDisplay:YES];
}

#pragma mark - Active Cell property

- (uint) activeCell
{
	return _activeCell;
}

- (void) setActiveCell : (uint) activeCell
{
	if(activeCell <= [_images count])
	{
		self.image = _images[activeCell];
		_activeCell = activeCell;
	}
}

@end
