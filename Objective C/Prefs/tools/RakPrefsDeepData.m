/*********************************************************************************************
 **	__________         __           .__            __                 ________   _______   	**
 **	\______   \_____  |  | __  _____|  |__ _____ _/  |______   	___  _\_____  \  \   _  \  	**
 **	 |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \  	\  \/ //  ____/  /  /_\  \ 	**
 **	 |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \__ \   //       \  \  \_/   \	**
 **	 |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /	  \_/ \_______ \ /\_____  /	**
 **	        \/      \/     \/     \/     \/     \/          \/ 	              \/ \/     \/ 	**
 **                                                                                         **
 **    Licence propriétaire, code source confidentiel, distribution formellement interdite  **
 **                                                                                         **
 *********************************************************************************************/

CGFloat hex2intPrefs(char hex[4], int maximum);

@implementation RakPrefsDeepData

- (id) init : (Prefs*) creator : (char *) inputData
{
	self = [super init];
	if(self != nil)
	{
		[self setNumberElem];
		[self setExpectedBufferSize];
		
		CGFloat dataBuf;
		uint i;
		SEL jumpTable[numberElem];
		
		mammouth = creator;
		[self initJumpTable:jumpTable];
		
		for(i = 0; i < numberElem; i++)
		{
			dataBuf = hex2intPrefs(&inputData[4*i], 1000);
			if(dataBuf == -1)
				dataBuf = [self triggerJumpTable:jumpTable[i]];
			else
				dataBuf /= 10;
			[self setAtIndex:i :dataBuf];
		}
	}
	return self;
}

- (void) initJumpTable : (SEL *) jumpTable
{
	int i;
	for(i = 0; i < numberElem; jumpTable[i] = NULL);
}

- (void) setNumberElem
{
	numberElem = 1;
}

- (void) setExpectedBufferSize
{
	sizeInputBuffer = numberElem * 4;
}

- (uint8_t) getFlagFocus
{
	return STATE_READER_TAB_MASK;
}

- (CGFloat) triggerJumpTable : (SEL) selector
{
	CGFloat output = -1;
	
	if (selector != NULL && [self respondsToSelector:selector])
	{
		NSMethodSignature * signature = [[self class] instanceMethodSignatureForSelector:selector];
		NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
		
		[invocation setTarget:self];
		[invocation setSelector:selector];
		[invocation invoke];
		[invocation getReturnValue:&output];
	}
	
	return output;
}

//Getters

- (CGFloat) getAtIndex: (uint8_t) index
{
	return -1;
}

- (uint8_t) getIndexFromInput: (int) mainThread : (int) backgroundTabsWhenMDLActive : (int) stateTabsReader
{
	return 0xff;
}

- (void) setAtIndex: (uint8_t) index : (CGFloat) data
{

}

- (void) reinitAtIndex : (uint8_t) index
{
	if(index < numberElem)
	{
		SEL jumpTable[numberElem];
		[self initJumpTable:jumpTable];
		
		[self setAtIndex:index : [self triggerJumpTable: jumpTable[index]] ];
	}
#ifdef DEV_VERSION
	else
		NSLog(@"[%s] : Unknown index: %d", __PRETTY_FUNCTION__, index);
#endif
}

- (void) performSelfCheck
{

}

- (int) getNbElem
{
	return numberElem;
}

@end