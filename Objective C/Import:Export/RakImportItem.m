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

@implementation RakImportItem

- (BOOL) isReadable
{
	if(!_isTome)
		return checkReadable(_projectData.data.project, false, _contentID);

	//The volume must be in the list
	META_TOME * tomeFull = _projectData.data.project.tomesFull;
	uint lengthTomeFull = _projectData.data.project.nombreTomes;

	_projectData.data.project.tomesFull = _projectData.data.tomeLocal;
	_projectData.data.project.nombreTomes = _projectData.data.nombreTomeLocal;

	bool output = checkReadable(_projectData.data.project, true, _contentID);

	_projectData.data.project.tomesFull = tomeFull;
	_projectData.data.project.nombreTomes = lengthTomeFull;

	return output;
}

- (BOOL) needMoreData
{
	if(_projectData.data.project.isInitialized)
		return false;

	PROJECT_DATA project = _projectData.data.project;

	if(project.projectName[0] == 0)
		return true;

	if(project.authorName[0] == 0)
		return true;

	return false;
}

- (BOOL) installWithUI : (RakImportStatusController *) UI
{
	char * projectPath = getPathForProject(_projectData.data.project);
	if(projectPath == NULL)
		return false;

	char basePath[sizeof(projectPath) + 256];
	int selection = _contentID;

	//Local project
	if(_isTome)
	{
		snprintf(basePath, sizeof(basePath), PROJECT_ROOT"%s/", projectPath);
	}
	else
	{
		if(selection % 10)
			snprintf(basePath, sizeof(basePath), PROJECT_ROOT"%s/"CHAPTER_PREFIX"%d.%d", projectPath, selection / 10, selection % 10);
		else
			snprintf(basePath, sizeof(basePath), PROJECT_ROOT"%s/"CHAPTER_PREFIX"%d", projectPath, selection / 10);
	}

	//Main decompression cycle
	if([_IOController respondsToSelector:@selector(willStartEvaluateFromScratch)])
		[_IOController willStartEvaluateFromScratch];

	__block BOOL foundOneThing = NO;
	NSString * basePathObj = [NSString stringWithUTF8String:basePath];

	[_IOController evaluateItemFromDir:_path withInitBlock:^(uint nbItems) {

		if(UI != nil)
			UI.nbElementInEntry = nbItems;

	} andWithBlock:^(id<RakImportIO> controller, NSString * filename, uint index, BOOL * stop)
	{
		if(UI == nil || ![UI haveCanceled])
		{
			if(UI != nil)
				UI.posInEntry = index;

			[controller copyItemOfName:filename toDir:basePathObj];
			foundOneThing = YES;
		}
		else
			*stop = YES;
	}];

	//Decompression is over, now, we need to ensure everything is fine
	if((UI != nil && [UI haveCanceled]) || !foundOneThing || ![self isReadable])
	{
		//Oh, the entry was not valid 😱
		if(UI != nil && ![UI haveCanceled])
			logR("Uh? Invalid import :|");

		if(_isTome)
			snprintf(basePath, sizeof(basePath), PROJECT_ROOT"%s/"VOLUME_PREFIX"%d", projectPath, _contentID);

		removeFolder(basePath);
		free(projectPath);
		return false;
	}

	free(projectPath);
	return true;
}

- (BOOL) overrideDuplicate
{
	if(_issue != IMPORT_PROBLEM_DUPLICATE)
		return NO;

	[self deleteData];
	if(![self installWithUI:nil])
	{
		_issue = IMPORT_PROBLEM_INSTALL_ERROR;
		return NO;
	}

	[self processThumbs];
	[self registerProject];
	_issue = IMPORT_PROBLEM_NONE;

	return YES;
}

- (BOOL) updateProject : (PROJECT_DATA) project
{
	_projectData.data.project = project;

	if([self needMoreData])
	{
		_issue = IMPORT_PROBLEM_METADATA;
		return NO;
	}

	//Okay, perform installation
	if([self isReadable])
		_issue = IMPORT_PROBLEM_DUPLICATE;

	if(![self installWithUI:nil])
	{
		_issue = IMPORT_PROBLEM_INSTALL_ERROR;
		return NO;
	}

	[self processThumbs];
	[self registerProject];
	_issue = IMPORT_PROBLEM_NONE;

	return YES;
}

- (void) deleteData
{
	if(!_isTome)
		return	internalDeleteCT(_projectData.data.project, false, _contentID);

	//The volume must be in the list
	META_TOME * tomeFull = _projectData.data.project.tomesFull;
	uint lengthTomeFull = _projectData.data.project.nombreTomes;

	_projectData.data.project.tomesInstalled = _projectData.data.project.tomesFull = _projectData.data.tomeLocal;
	_projectData.data.project.nombreTomesInstalled = _projectData.data.project.nombreTomes = _projectData.data.nombreTomeLocal;

	internalDeleteTome(_projectData.data.project, _contentID, true);

	_projectData.data.project.tomesFull = tomeFull;
	_projectData.data.project.nombreTomes = lengthTomeFull;
}

- (void) processThumbs
{
	for(byte pos = 0; pos < NB_IMAGES; pos++)
	{
		if(!_projectData.haveImages[pos])
			continue;

		ICON_PATH path = getPathToIconsOfProject(_projectData.data.project, pos);
		if(path.string[0] == 0)
			continue;

		if(checkFileExist(path.string))
			continue;

		[_IOController copyItemOfName:[NSString stringWithUTF8String:_projectData.URLImages[pos]] toPath:[NSString stringWithUTF8String:path.string]];
	}
}

- (NSData *) queryThumbInWithIndex : (uint) index
{
	if(index >= NB_IMAGES || !_projectData.haveImages[index])
		return nil;

	NSData * data = nil;

	if(![_IOController copyItemOfName:[NSString stringWithUTF8String:_projectData.URLImages[index]] toData:&data])
		return nil;

	return data;
}

- (void) registerProject
{
	_projectData.data.project.isInitialized = true;
	registerImportEntry(_projectData.data, _isTome);
}

#pragma mark - Metadata inference

//If hinted, and we can't figure anything ourselves, we relax the search
- (NSString *) inferMetadataFromPathWithHint : (BOOL) haveHintedCT
{
	NSString * inferedName = nil;
	const char * forbiddenChars = "_ -~:;|", nbForbiddenChars = 7;
	NSMutableCharacterSet * charSet = [NSMutableCharacterSet new];
	[charSet addCharactersInString:[NSString stringWithUTF8String:forbiddenChars]];

	//We look for something la C* or [T-V]* followed then exclusively by numbers
	NSArray * tokens = [[_path lastPathComponent] componentsSeparatedByCharactersInSet:charSet];

	BOOL couldHaveSomething, inferingTome, firstPointCrossed, inferedSomethingSolid = NO, isTomeInfered;
	int elementID;
	uint discardedCloseCalls = 0;

	for(uint i = 0, length, posInChunk, baseDigits; i < [tokens count]; ++i)
	{
		NSData * data = [[tokens objectAtIndex:i] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		const char * simplifiedChunk = [data bytes];
		length = [data length];

		if(length == 0)
			continue;

		couldHaveSomething = NO;

		char sample = toupper(simplifiedChunk[0]);

		if(sample == 'C')	//Chapter?
		{
			couldHaveSomething = YES;
			inferingTome = NO;
		}
		else if(sample == 'V' || sample == 'T')	//Volume? (or Tome)
		{
			couldHaveSomething = YES;
			inferingTome = YES;
		}
		else
			continue;

		for(posInChunk = 1; posInChunk < length && !isdigit(simplifiedChunk[posInChunk]); ++posInChunk);

		//Couldn't find digits in the end of the chunk and the next chunk doesn't start with digits
		if(posInChunk == length && (i == [tokens count] || [[tokens objectAtIndex:i + 1] length] == 0 || !isdigit([[tokens objectAtIndex:i + 1] UTF8String][0])))
		{
			++discardedCloseCalls;
			continue;
		}

		//Digits analysis

		//If we separated the numbers from the base
		if(posInChunk == length)
		{
			data = [[tokens objectAtIndex:i + 1] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
			simplifiedChunk = [data bytes];
			length = [data length];
			posInChunk = 0;
		}

		//We only want digits at this point, any interruption will result in elimination
		firstPointCrossed = NO;
		for(baseDigits = posInChunk; posInChunk < length; ++posInChunk)
		{
			if(isdigit(simplifiedChunk[posInChunk]))
				continue;

			if(!firstPointCrossed && simplifiedChunk[posInChunk] == '.')
			{
				firstPointCrossed = YES;
				continue;
			}

			break;
		}

		//Close call, but nop, invalid
		if(posInChunk < length)
		{
#ifdef DEV_VERSION
			logR("Close call, this chunk almost got me!");
			NSLog(@"`%@` -> %s", tokens, simplifiedChunk);
#endif
			++discardedCloseCalls;
			continue;
		}

		//Well, we're good
		isTomeInfered = inferingTome;
		double inferedElementID = atof(&simplifiedChunk[baseDigits]);
		inferedElementID *= 10;

		if(inferedElementID >= INT_MIN && inferedElementID <= INT_MAX)
		{
			elementID = (int) inferedElementID;

			if(inferedSomethingSolid)
				++discardedCloseCalls;
			else
				inferedSomethingSolid = YES;
		}
		else
			++discardedCloseCalls;
	}

	if(inferedSomethingSolid)
	{
		_isTome = isTomeInfered;
		_contentID = isTomeInfered ? elementID / 10 : elementID;

		//We'll assume that most of what came before CT was the name
		char * fullName = strdup([[[_path lastPathComponent] stringByDeletingPathExtension] UTF8String]);
		uint fullNameLength = strlen(fullName), posFullName = 0;
		BOOL nextCharNeedChecking = YES;

		for(; posFullName < fullNameLength; ++posFullName)
		{
			char c = fullName[posFullName];
			if(nextCharNeedChecking)
			{
				c = toupper(c);
				if((c == 'C' || c == 'T' || c == 'V') && discardedCloseCalls-- == 0)
				{
					//If it starts with the C/T/V we used, we stop the prediction
					if(posFullName)
					{
						fullName[posFullName] = 0;
						inferedName = [NSString stringWithUTF8String:fullName];
					}
					break;
				}
				else
					nextCharNeedChecking = NO;
			}
			else
			{
				//We don't care about hot chars if they are not the begining of a chunk
				for(byte i = 0; i < nbForbiddenChars; ++i)
				{
					if(c == forbiddenChars[i])
					{
						nextCharNeedChecking = YES;
						break;
					}
				}
			}
		}

		free(fullName);
	}

	//Perform a simpler search
	else if(haveHintedCT)
	{
		charSet = [NSMutableCharacterSet new];
		[charSet addCharactersInString:@"0123456789."];
		NSCharacterSet * notOnlyDigits = [charSet invertedSet];

		for(NSString * chunk in tokens)
		{
			if([chunk length] == 0 || [chunk rangeOfCharacterFromSet:notOnlyDigits].location != NSNotFound)
				continue;

			double inferedElementID = atof([chunk UTF8String]);
			if(!_isTome)
				inferedElementID *= 10;

			if(inferedElementID >= INT_MIN && inferedElementID <= INT_MAX)
			{
				elementID = (int) inferedElementID;
				inferedSomethingSolid = YES;
			}
		}

		//We found something \o/
		if(inferedSomethingSolid)
			_contentID = elementID;
	}

	if(inferedName == nil || inferedName.length == 0)
		inferedName = [_path lastPathComponent];

	//We try to clean it up a bit
	return [self cleanupString : inferedName];
}

- (NSString *) cleanupString : (NSString *) inferedName
{
	if(inferedName == nil)
		return nil;

	//First, remove digits withing parenthesis
	inferedName = [inferedName stringByReplacingOccurrencesOfString:@"\\(\\d+?\\)"
														 withString:@""
															options:NSRegularExpressionSearch
															  range:NSMakeRange(0, inferedName.length)];

	//Then, anything between []
	inferedName = [inferedName stringByReplacingOccurrencesOfString:@"\\[.*\\]"
														 withString:@""
															options:NSRegularExpressionSearch
															  range:NSMakeRange(0, inferedName.length)];

	if(inferedName != nil && [inferedName length] > 0)
	{
		NSMutableCharacterSet * charSet = [NSMutableCharacterSet new];
		[charSet addCharactersInString:@"_ -~:;|"];

		//Good, now, let's replace _ with spaces, and remove noise from the end
		inferedName = [inferedName stringByReplacingOccurrencesOfString:@"_" withString:@" "];
		inferedName = [inferedName stringByTrimmingCharactersInSet:charSet];
	}

	//Okay, we're going too hard, we give up
	if([inferedName length] == 0)
		return nil;

	return inferedName;
}

@end