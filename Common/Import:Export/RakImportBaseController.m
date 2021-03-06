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

@implementation RakImportBaseController

- (BOOL) noValidFileFoundForDir : (const char *) dirname butFoundInFiles : (BOOL) foundDirInFiles shouldRedirectTo : (NSString **) redirection
{
#ifdef EXTENSIVE_LOGGING
	NSLog(@"[WARNING]: was tasked with processing a CT but couldn't find a file starting with %s (could %sfind dirname)", dirname == NULL ? "(no name)" : dirname, foundDirInFiles ? "" : "not ");
#endif
	
	//If the directory existed in the dir, or we were already using a wildcard, no need to enlarge the search
	if(foundDirInFiles || dirname == NULL)
	{
		*redirection = nil;
		return NO;
	}
	
#ifdef EXTENSIVE_LOGGING
	NSLog(@"Removing the first dir in the dirname");
#endif
	
	//We remove the first path component of the archive
	
	NSString * newDirName;
	uint i = 0, lengthExpected = strlen(dirname);
	
	for(; i < lengthExpected && dirname[i] != 0 && dirname[i] != '/'; ++i);
	
	if(i == lengthExpected || dirname[i] == 0)
		newDirName = @"";
	else
	{
		for(; i < lengthExpected && dirname[i] == '/'; ++i);
		if(i == lengthExpected || dirname[i] == 0)
			newDirName = @"";
		else
			newDirName = [NSString stringWithUTF8String:&dirname[i]];
	}
	
	*redirection = newDirName;
	
	return YES;
}

- (BOOL) acceptPackageInPackage
{
	return NO;
}

- (BOOL) needCraftedPathForUnread
{
	return NO;
}



- (uint) prepareFilesToUnpack : (char **) fileList
		   totalNumberOfFiles : (const uint) nbFiles
					 fromPath : (const char *) startExpectedPath
			 writeToIndexList : (uint []) indexOfFiles
				couldFindADir : (bool *) couldFindDirInArray
{
	uint lengthExpected = startExpectedPath != NULL ? strlen(startExpectedPath) : 0, nbFileToEvaluate = 0;
	
	if(couldFindDirInArray != NULL)
		*couldFindDirInArray = false;
	
	for(uint pos = 0; pos < nbFiles; pos++)
	{
		if(!isStringLongerOrAsLongThan(fileList[pos], lengthExpected))
			continue;
		
		if(startExpectedPath == NULL || !strncmp(fileList[pos], startExpectedPath, lengthExpected))
		{
			if(fileList[pos][lengthExpected] != '\0')
				indexOfFiles[nbFileToEvaluate++] = pos;
			else if(couldFindDirInArray != NULL)
				*couldFindDirInArray = true;
		}
	}
	
	return nbFileToEvaluate;
}

@end
