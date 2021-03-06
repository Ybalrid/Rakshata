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

#include "JSONParser.h"

void * parseChapterStructure(NSArray * chapterBloc, uint * nbElem, BOOL isChapter, BOOL paidContent, uint ** chaptersPrice)
{
	if(nbElem != NULL)
		*nbElem = 0;
	
	if(chapterBloc == nil)
		return NULL;

	if(paidContent && chaptersPrice == NULL)
		return NULL;
	
	void * output = NULL;
	uint counterVar = 0, *counter, pos = 0, pricePos = 0;
	size_t nbSubBloc = [chapterBloc count];

	if(nbSubBloc != 0)
	{
		id entry1, entry2 = nil;
		int jump, first, last, sum;
		void* tmp;
		
		BOOL isPrivateIfVolume = NO;
		uint typeSize = isChapter ? sizeof(uint) : sizeof(CONTENT_TOME);
		
		if(nbElem != NULL)		counter = nbElem;
		else					counter = &counterVar;
		
		for(NSDictionary * dictionary in chapterBloc)
		{
			if(ARE_CLASSES_DIFFERENT(dictionary, [NSDictionary class]))	continue;
			
			entry1 = objectForKey(dictionary, JSON_PROJ_CHAP_DETAILS, @"details", [NSObject class]);
			if(isChapter && paidContent)
				entry2 = objectForKey(dictionary, JSON_PROJ_PRICE, @"price", [NSObject class]);
			else if(!isChapter)
				entry2 = objectForKey(dictionary, JSON_PROJ_VOL_ISRESERVEDTOVOL, @"privateTome", [NSObject class]);
				
			if(entry1 != nil && !ARE_CLASSES_DIFFERENT(entry1, [NSArray class]))	//This is a special chunck
			{
				*counter += [(NSArray*) entry1 count];
				
				if(!*counter)
					continue;
				
				else if((tmp = realloc(output, (*counter + 1) * typeSize)) != NULL)
				{
					output = tmp;
					
					if(isChapter)
					{
						if(entry2 != nil && (tmp = realloc(*chaptersPrice, *counter * sizeof(uint))) != NULL)
						{
							*chaptersPrice = tmp;
							
							if(entry2 == nil)
								memset(&((*chaptersPrice)[pricePos]), 0, (*counter - pricePos) * sizeof(uint));
							else
							{
								uint count = *counter;
								for(NSNumber * entry3 in entry2)
								{
									if(pricePos > count)
										break;
									
									if(ARE_CLASSES_DIFFERENT(entry3, [NSNumber class]))
										continue;
									
									(*chaptersPrice)[pricePos++] = [entry3 unsignedIntValue];
								}
							}
						}
					}
					else	//Volume detail option telling if private or not
					{
						if(entry2 != nil && !ARE_CLASSES_DIFFERENT(entry2, [NSNumber class]))
							isPrivateIfVolume = [entry2 boolValue];
						else
							isPrivateIfVolume = NO;
					}

					//Actual parsing of details
					for(NSNumber * entry3 in entry1)
					{
						if(ARE_CLASSES_DIFFERENT(entry3, [NSNumber class]))
							continue;
						
						uint value = [entry3 unsignedIntValue];
						
#ifdef DEV_VERSION
						if(value == 0xdeadbead)
						{
							//This value is used to signal a deallocated memory area, it'd crash if ran in debugger
							logR("Error: this value (-559038803) is forbiden, moved by one");
							value--;
						}
#endif
						if(isChapter)
							((uint *)output)[pos++] = value;
						else
						{
							((CONTENT_TOME *) output)[pos].ID = value;
							((CONTENT_TOME *) output)[pos++].isPrivate = isPrivateIfVolume;
						}
					}
				}
			}
			else
			{
				entry1 = objectForKey(dictionary, JSON_PROJ_CHAP_JUMP, @"jump", [NSNumber class]);
				if(entry1 != nil)	jump = [(NSNumber*) entry1 integerValue];	else	{	continue;	}
				
				entry1 = objectForKey(dictionary, JSON_PROJ_CHAP_FIRST, @"first", [NSNumber class]);
				if(entry1 != nil)	first = [(NSNumber*) entry1 integerValue];	else	{	continue;	}
				
				entry1 = objectForKey(dictionary, JSON_PROJ_CHAP_LAST, @"last", [NSNumber class]);
				if(entry1 != nil)	last = [(NSNumber*) entry1 integerValue];	else	{	continue;	}
				
				if(jump == 0 || (last < first && jump > 0) || (last > first && jump < 0))
					continue;
				
				sum = (last - first) / jump + 1;
				if(sum > 0)	*counter += (uint) sum;
				else		continue;
				
				if((tmp = realloc(output, (*counter + 1) * typeSize)) != NULL)
				{
					output = tmp;

					if(!isChapter)
					{
						//Check if native of not if volume
						if(entry2 != nil && !ARE_CLASSES_DIFFERENT(entry2, [NSNumber class]))
							isPrivateIfVolume = [entry2 boolValue];
						else
							isPrivateIfVolume = NO;

						//The first element have to be initialized early
						((CONTENT_TOME *) output)[pos].isPrivate = isPrivateIfVolume;
						for (((CONTENT_TOME *) output)[pos++].ID = (uint) first; pos < *counter; pos++)
						{
							((CONTENT_TOME *) output)[pos].ID = (uint) (((int) ((CONTENT_TOME *) output)[pos - 1].ID) + jump);
							((CONTENT_TOME *) output)[pos].isPrivate = isPrivateIfVolume;
						}
					}
					else
					{
						for(((int *)output)[pos++] = first; pos < *counter; pos++)
							((int *)output)[pos] = ((int *)output)[pos-1] + jump;
					}
				}
				
				if(isChapter && entry2 != nil && (tmp = realloc(*chaptersPrice, *counter * sizeof(uint))) != NULL)
				{
					*chaptersPrice = tmp;
					
					if(!ARE_CLASSES_DIFFERENT(entry2, [NSNumber class]))
					{
						*chaptersPrice = tmp;
						uint price = [entry2 unsignedIntValue];
						
						while(pricePos < *counter)
							(*chaptersPrice)[pricePos++] = price;
					}
					else
						memset(&((*chaptersPrice)[pricePos]), 0, (*counter - pricePos) * sizeof(uint));
				}
			}
		}
	}
	
	return output;
}

NSArray * recoverChapterStructure(void * structure, BOOL isChapter, uint * chapterPrices, uint length)
{
	if(structure == NULL || length == 0)		return nil;
	
	NSMutableArray * output = [NSMutableArray new], *currentDetail = nil, *currentBurst = nil, *pricesInBurst, *priceDetail = nil;
	BOOL currentNativeIfNotChap = NO;
	
	if(output == nil)		return nil;
	
	if(length < 6)	//No need for diffs
	{
		currentDetail = [NSMutableArray array];
		
		if(isChapter)
		{
			for(uint i = 0; i < length; [currentDetail addObject:@(((int *) structure)[i++])]);
			
			if(chapterPrices != NULL)
			{
				NSMutableArray * prices = [NSMutableArray array];
				
				for(uint i = 0; i < length; [prices addObject:@(chapterPrices[i++])]);
				
				[output addObject:[NSDictionary dictionaryWithObjects:@[currentDetail, prices] forKeys : @[JSON_PROJ_CHAP_DETAILS, JSON_PROJ_PRICE]]];
			}
			else
				[output addObject:[NSDictionary dictionaryWithObject:currentDetail forKey : JSON_PROJ_CHAP_DETAILS]];
		}
		else
		{
			currentNativeIfNotChap = ((CONTENT_TOME *) structure)[0].isPrivate;
			
			for(uint i = 0; i < length; [currentDetail addObject:@((int) ((CONTENT_TOME *) structure)[i++].ID)])
			{
				if(((CONTENT_TOME *) structure)[i].isPrivate != currentNativeIfNotChap)
				{
					[output addObject:[NSDictionary dictionaryWithObjects:@[currentDetail, @(currentNativeIfNotChap)] forKeys : @[JSON_PROJ_CHAP_DETAILS, JSON_PROJ_VOL_ISRESERVEDTOVOL]]];
					
					currentDetail = [NSMutableArray array];
					currentNativeIfNotChap = ((CONTENT_TOME *) structure)[i].isPrivate;
				}
			}
			
			[output addObject:[NSDictionary dictionaryWithObjects:@[currentDetail, @(currentNativeIfNotChap)] forKeys : @[JSON_PROJ_CHAP_DETAILS, JSON_PROJ_VOL_ISRESERVEDTOVOL]]];
		}
			
		currentDetail = nil;
	}
	else
	{
		//We create a diff table
		int diff[length - 1];
		
		if(isChapter)
		{
			for(uint i = 0; i < length-1; i++)
				diff[i] = ((int *) structure)[i+1] - ((int *) structure)[i];
		}
		else
		{
			for(uint i = 0; i < length-1; i++)
				diff[i] = (int) ((CONTENT_TOME *) structure)[i+1].ID - (int) ((CONTENT_TOME *) structure)[i].ID;

			currentNativeIfNotChap = ((CONTENT_TOME *) structure)[0].isPrivate;
		}
		
		//We look for burst
		int repeatingDiff = diff[0];
		currentBurst = [NSMutableArray array];
		
		bool pricesValid = isChapter && chapterPrices != NULL;
		
		if(pricesValid)
			pricesInBurst = [NSMutableArray array];
		
		for (uint pos = 0, counter = 0; pos < length; pos++)
		{
			if(pos == length - 1 || diff[pos] != repeatingDiff ||
			   (pricesValid && chapterPrices[pos] != chapterPrices[pos + 1]) ||
			   (!isChapter && ((CONTENT_TOME *) structure)[pos + 1].isPrivate != currentNativeIfNotChap))
			{
				if(counter > 5)
				{
					if(currentDetail != nil && [currentDetail count])
					{
						if(pricesValid)
							[output addObject:[NSDictionary dictionaryWithObjects:@[currentDetail, priceDetail] forKeys : @[JSON_PROJ_CHAP_DETAILS, JSON_PROJ_PRICE]]];
						else
							[output addObject:[NSDictionary dictionaryWithObject:currentDetail forKey : JSON_PROJ_CHAP_DETAILS]];

						currentDetail = nil;
					}
					
					//Because diff tell us how far is the next element, a != diff mean the next element break the chain, so the last one of the burst is the current one
					//However, it gets a bit tricky thanks to currentNativeState (!isChapter only, thankfully)
					if(!isChapter)
					{
						[output addObject:[NSDictionary dictionaryWithObjects:@[@((int) ((CONTENT_TOME *) structure)[pos - counter].ID), @((int) ((CONTENT_TOME *) structure)[pos].ID), @(repeatingDiff)] forKeys:@[JSON_PROJ_CHAP_FIRST, JSON_PROJ_CHAP_LAST, JSON_PROJ_CHAP_JUMP]]];
						if(pos != length - 1)
							currentNativeIfNotChap = ((CONTENT_TOME *) structure)[pos + 1].isPrivate;
					}
					else
					{
						if(pricesValid)
							[output addObject:[NSDictionary dictionaryWithObjects:@[@(((int *) structure)[pos - counter]), @(((int *) structure)[pos]), @(repeatingDiff), @(chapterPrices[pos])] forKeys:@[JSON_PROJ_CHAP_FIRST, JSON_PROJ_CHAP_LAST, JSON_PROJ_CHAP_JUMP, JSON_PROJ_PRICE]]];
						else
							[output addObject:[NSDictionary dictionaryWithObjects:@[@(((int *) structure)[pos - counter]), @(((int *) structure)[pos]), @(repeatingDiff)] forKeys:@[JSON_PROJ_CHAP_FIRST, JSON_PROJ_CHAP_LAST, JSON_PROJ_CHAP_JUMP]]];
					}
				}
				else
				{
					[currentBurst addObject:@(isChapter ? ((int *) structure)[pos] : (int) ((CONTENT_TOME *) structure)[pos].ID)];
					if(pricesValid)
						[pricesInBurst addObject:@(chapterPrices[pos])];

					if(!isChapter && pos != length - 1 && ((CONTENT_TOME *) structure)[pos + 1].isPrivate != currentNativeIfNotChap)
					{
						[output addObject:[NSDictionary dictionaryWithObjects:@[currentBurst, @(currentNativeIfNotChap)] forKeys : @[JSON_PROJ_CHAP_DETAILS, JSON_PROJ_VOL_ISRESERVEDTOVOL]]];
						
						currentBurst = nil;
						currentNativeIfNotChap = !currentNativeIfNotChap;
					}
					else
					{
						if(currentDetail == nil)
						{
							currentDetail = [NSMutableArray new];
							
							if(pricesValid)
								priceDetail = [NSMutableArray new];
						}
						
						[currentDetail addObjectsFromArray:currentBurst];
						
						if(pricesValid)
							[priceDetail addObjectsFromArray:pricesInBurst];
					}
				}
				
				currentBurst = [NSMutableArray new];
				if(pricesValid)
					pricesInBurst = [NSMutableArray new];

				repeatingDiff = diff[(pos != length - 1) ? pos : pos - 1];	counter = 0;
			}
			else
			{
				[currentBurst addObject:@(isChapter ? ((int *) structure)[pos] : (int) ((CONTENT_TOME *) structure)[pos].ID)];
				
				if(pricesValid)
					[pricesInBurst addObject:@(chapterPrices[pos])];
				
				counter++;
			}
		}
		
		if(currentDetail != nil && [currentDetail count])
		{
			if(pricesValid)
				[output addObject:[NSDictionary dictionaryWithObjects:@[currentDetail, pricesInBurst] forKeys : @[JSON_PROJ_CHAP_DETAILS, JSON_PROJ_PRICE]]];
			else if(isChapter)
				[output addObject:[NSDictionary dictionaryWithObject:currentDetail forKey : JSON_PROJ_CHAP_DETAILS]];
			else
				[output addObject:[NSDictionary dictionaryWithObjects:@[currentDetail, @(currentNativeIfNotChap)] forKeys : @[JSON_PROJ_CHAP_DETAILS, JSON_PROJ_VOL_ISRESERVEDTOVOL]]];
		}
	}
	
	return [NSArray arrayWithArray:output];
}

META_TOME * getVolumes(NSArray* volumeBloc, uint * nbElem, BOOL paidContent, BOOL remoteData)
{
	if(nbElem == NULL)
		return NULL;
	else
		*nbElem = 0;
	
	if(volumeBloc == nil || ARE_CLASSES_DIFFERENT(volumeBloc, [NSArray class]))
		return NULL;
	
	size_t nbElemMax = [volumeBloc count];
	
	if(nbElemMax == 0)
		return NULL;
	
	META_TOME * output = malloc(nbElemMax * sizeof(META_TOME));

	if(output != NULL)
	{
		uint cache = 0;
		NSArray * content;
		NSDictionary * dict;
		NSString *description, *readingName;
		NSNumber *readingID, *internalID, *priceObj;

		for(dict in volumeBloc)
		{
			if(ARE_CLASSES_DIFFERENT(dict, [NSDictionary class]))	continue;

			internalID = objectForKey(dict, JSON_PROJ_VOL_INTERNAL_ID, @"Internal ID", [NSNumber class]);
			if(internalID == nil)
				continue;
			
			//The internal ID submitted by a remote source have to be below 2^31, as number after this one are reserved for imported volumes
			if(remoteData && ([internalID intValue] < 0 || [internalID unsignedIntValue] > INT_MAX))
				continue;

			//The reading ID need some post-processing
			readingID = objectForKey(dict, JSON_PROJ_VOL_READING_ID, @"Reading ID", [NSNumber class]);
			if(readingID == nil)	continue;

			readingName = objectForKey(dict, JSON_PROJ_VOL_READING_NAME, @"Reading name", [NSString class]);
			if(readingName != nil && [readingName length] == 0)
				readingName = nil;

			description = objectForKey(dict, JSON_PROJ_DESCRIPTION, @"Description", [NSString class]);
			if(description != nil && [description length] == 0)
				description = nil;

			content = objectForKey(dict, JSON_PROJ_CHAPTERS, @"chapters", [NSArray class]);
			if(content == nil)			continue;
			
			if(paidContent)
				priceObj = objectForKey(dict, JSON_PROJ_PRICE, @"price", [NSNumber class]);
			
			output[cache].details = parseChapterStructure(content, &(output[cache].lengthDetails), NO, NO, NULL);
			
			if(output[cache].details == NULL)
				continue;
			
			output[cache].ID = [internalID unsignedIntValue];
			output[cache].readingID = [readingID intValue];
			
			if(readingName == nil)			output[cache].readingName[0] = 0;
			else							wcsncpy(output[cache].readingName, (charType*) [readingName cStringUsingEncoding:NSUTF32StringEncoding], MAX_TOME_NAME_LENGTH);
			
			if(description == nil)			output[cache].description[0] = 0;
			else							wcsncpy(output[cache].description, (charType*) [description cStringUsingEncoding:NSUTF32StringEncoding], TOME_DESCRIPTION_LENGTH);
			
			if(priceObj == nil)				output[cache].price = INVALID_VALUE;
			else							output[cache].price = [priceObj unsignedIntValue];
			
			cache++;
		}
		
		*nbElem = cache;
		
		if(cache == 0)
		{
			free(output);
			output = NULL;
		}
		else if(cache < nbElemMax)
		{
			void * tmp = realloc(output, cache * sizeof(META_TOME));
			if(tmp != NULL)
				output = tmp;
		}
	}
	
	return output;
}

NSArray * recoverVolumeBloc(META_TOME * volume, uint length, BOOL paidContent)
{
	if(volume == NULL)
		return nil;
	
	NSMutableArray *output = [NSMutableArray array];
	NSMutableDictionary * dict;
	
	for(uint pos = 0; pos < length; pos++)
	{
		if(volume[pos].ID == INVALID_VALUE)
			break;

		dict = [NSMutableDictionary dictionaryWithObject:@(volume[pos].ID) forKey:JSON_PROJ_VOL_INTERNAL_ID];
		
		if(volume[pos].description[0])
			[dict setObject:getStringForWchar(volume[pos].description) forKey:JSON_PROJ_DESCRIPTION];
		
		if(volume[pos].readingName[0])
			[dict setObject:getStringForWchar(volume[pos].readingName) forKey:JSON_PROJ_VOL_READING_NAME];

		[dict setObject:@(volume[pos].readingID) forKey:JSON_PROJ_VOL_READING_ID];
		
		if(paidContent && volume[pos].price != UINT_MAX)
			[dict setObject:@(volume[pos].price) forKey:JSON_PROJ_PRICE];
		
		if(volume[pos].details != NULL)
		{
			NSArray * data = recoverChapterStructure(volume[pos].details, NO, NULL, volume[pos].lengthDetails);
			if(data != nil)
				[dict setObject:data forKey:JSON_PROJ_CHAPTERS];
		}
		
		[output addObject:dict];
	}
	
	return [NSArray arrayWithArray:output];
}

NSArray * reverseTag(PROJECT_DATA project)
{
	NSMutableArray * tagArray = [NSMutableArray array];
	if(tagArray != nil)
	{
		TAG * tags = project.tags;
		for(uint i = 0; i < project.nbTags; i++)
		{
			[tagArray addObject:@(tags[i].ID)];
		}

		if([tagArray count] > 0)
			return [NSArray arrayWithArray: tagArray];
	}

	//Backup solution!

	return @[@(project.mainTag)];
}

PROJECT_DATA parseBloc(NSDictionary * bloc)
{
	PROJECT_DATA data = getEmptyProject();
	
	uint * chapters = NULL, * chaptersPrices = NULL;
	uint nbChapters = 0, nbVolumes = 0;
	META_TOME * volumes = NULL;
	
	//We create all variable first, otherwise ARC complain
	NSNumber *ID, *status = nil, *rightToLeft = nil, *paidContent = nil, *DRM = nil, * isLocale = nil, * category = nil;
	NSString * projectName = nil, *description = nil, *authors = nil;
	NSArray *tagData = nil;
	
	ID = objectForKey(bloc, JSON_PROJ_ID, @"ID", [NSNumber class]);
	if(ID == nil)
	{
#ifdef EXTENSIVE_LOGGING
		NSLog(@"Project parser error: couldn't find ID in %@", bloc);
#endif
		goto end;
	}
	
	projectName = objectForKey(bloc, JSON_PROJ_PROJECT_NAME, @"projectName", [NSString class]);
	if(projectName == nil || [projectName length] == 0)
	{
#ifdef EXTENSIVE_LOGGING
		NSLog(@"Project parser error: couldn't find name for ID %@ in %@", ID, bloc);
#endif
		goto end;
	}

	isLocale = objectForKey(bloc, JSON_PROJ_ISLOCAL, nil, [NSNumber class]);
	DRM = objectForKey(bloc, JSON_PROJ_DRM, nil, [NSNumber class]);
	paidContent = objectForKey(bloc, JSON_PROJ_PRICE, @"price", [NSNumber class]);

	BOOL isPaidContent = paidContent == nil ? NO : [paidContent boolValue];
	
	chapters = parseChapterStructure(objectForKey(bloc, JSON_PROJ_CHAPTERS, @"chapters", [NSArray class]), &nbChapters, YES, isPaidContent, &chaptersPrices);
	volumes = getVolumes(objectForKey(bloc, JSON_PROJ_VOLUMES, @"volumes", [NSArray class]), &nbVolumes, isPaidContent, NO);

	if(nbChapters == 0)
	{
		free(chapters);
		chapters = NULL;
	}
	
	if(nbChapters == 0 && nbVolumes == 0)
	{
#ifdef EXTENSIVE_LOGGING
		NSLog(@"Project parser warning: no chapter nor volumes for ID %@ (%@) in %@", ID, projectName, bloc);
#endif
	}
	
	description = objectForKey(bloc, JSON_PROJ_DESCRIPTION, @"description", [NSString class]);
	if(description == nil || [description length] == 0)	description = nil;
	
	authors = objectForKey(bloc, JSON_PROJ_AUTHOR , @"author", [NSString class]);
	if(authors == nil || [authors length] == 0)
	{
#ifdef REQUIRE_AUTHOR_TO_IMPORT
	#ifdef EXTENSIVE_LOGGING
		NSLog(@"Project parser error: no author for project of ID %@ (%@) in %@", ID, projectName, bloc);
	#endif
		goto end;
#else
		authors = nil;
#endif
	}
	
	status = objectForKey(bloc, JSON_PROJ_STATUS , @"status", [NSNumber class]);
	if(status == nil)
	{
#ifdef EXTENSIVE_LOGGING
		NSLog(@"Project parser error: no status for project of ID %@ (%@) in %@", ID, projectName, bloc);
#endif
		goto end;
	}
	
	rightToLeft = objectForKey(bloc, JSON_PROJ_RIGHT_TO_LEFT , @"asian_order_of_reading", [NSNumber class]);
	if(rightToLeft == nil)
	{
#ifdef EXTENSIVE_LOGGING
		NSLog(@"Project parser error: invalid asian_order_of_reading for project of ID %@ (%@) in %@", ID, projectName, bloc);
#endif
		goto end;
	}

	category = objectForKey(bloc, JSON_PROJ_TAG_CATEGORY, @"category", [NSNumber class]);
	if(category == nil)
	{
#ifdef EXTENSIVE_LOGGING
		NSLog(@"Project parser error: invalid category for project of ID %@ (%@) in %@", ID, projectName, bloc);
#endif
		goto end;
	}

	tagData = objectForKey(bloc, JSON_PROJ_TAG_DATA , @"tagData", [NSArray class]);
	if(tagData == nil)
	{
#ifdef EXTENSIVE_LOGGING
		NSLog(@"Project parser error: invalid tag data for project of ID %@ (%@) in %@", ID, projectName, bloc);
#endif
		goto end;
	}
	
	data.projectID = [ID unsignedIntValue];
	data.isPaid = isPaidContent;
	data.chaptersPrix = chaptersPrices;
	data.chaptersFull = chapters;		data.nbChapter = nbChapters;
	data.volumesFull = volumes;			data.nbVolumes = nbVolumes;
	data.status = [status unsignedCharValue];
	if(data.status > STATUS_MAX)	data.status = STATUS_INVALID;

	data.category = [category unsignedIntValue];
	if(!doesCatOfIDExist(data.category))
	{
#ifdef EXTENSIVE_LOGGING
		NSLog(@"Project parser error: valid category formating but still unknown for project of ID %@ (%@) in %@", ID, projectName, bloc);
#endif
		goto end;
	}

	//Failure at loading tags
	if(!convertTagMask(tagData, &(data.tags), &(data.nbTags), &(data.mainTag)))
		goto end;

	data.locale = isLocale != nil && [isLocale boolValue];
	data.haveDRM = (DRM != nil && [DRM boolValue]) | (DRM == nil && isPaidContent);
	data.rightToLeft = [rightToLeft boolValue];
	data.isInitialized = true;
	
	wcsncpy(data.projectName, (charType*) [projectName cStringUsingEncoding:NSUTF32StringEncoding], LENGTH_PROJECT_NAME);
	
#ifndef REQUIRE_AUTHOR_TO_IMPORT
	if(authors != nil)
#endif
		wcsncpy(data.authorName, (charType*) [authors cStringUsingEncoding:NSUTF32StringEncoding], LENGTH_AUTHORS);
	
	if(description != nil)
	{
		wcsncpy(data.description, (charType*) [description cStringUsingEncoding:NSUTF32StringEncoding], [description length]);
		data.description[LENGTH_DESCRIPTION-1] = 0;
	}
	else
		memset(&data.description, 0, sizeof(data.description));
	
	chapters = NULL;
	chaptersPrices = NULL;
	volumes = NULL;
end:
	
	free(chapters);
	free(chaptersPrices);
	freeTomeList(volumes, nbVolumes, true);
	return data;
}

NSDictionary * reverseParseBloc(PROJECT_DATA_PARSED project)
{
	if(!project.project.isInitialized)
		return nil;

	//No project remaining
	if(isLocalProject(project.project) && project.project.nbChapter == 0 && project.project.nbVolumes == 0)
		return nil;
	
	id buf;
	NSMutableDictionary * output = [NSMutableDictionary dictionary];
	
	[output setObject:@(project.project.projectID) forKey:JSON_PROJ_ID];
	[output setObject:getStringForWchar(project.project.projectName) forKey:JSON_PROJ_PROJECT_NAME];
	
	buf = recoverChapterStructure(project.project.chaptersFull, YES, project.project.chaptersPrix, project.project.nbChapter);
	if(buf != nil)		[output setObject:buf forKey:JSON_PROJ_CHAPTERS];

	buf = recoverChapterStructure(project.chaptersRemote, YES, NULL, project.nbChapterRemote);
	if(buf != nil)		[output setObject:buf forKey:JSON_PROJ_CHAP_REMOTE];

	buf = recoverChapterStructure(project.chaptersLocal, YES, NULL, project.nbChapterLocal);
	if(buf != nil)		[output setObject:buf forKey:JSON_PROJ_CHAP_LOCAL];

	buf = recoverVolumeBloc(project.project.volumesFull, project.project.nbVolumes, project.project.isPaid);
	if(buf != nil)		[output setObject:buf forKey:JSON_PROJ_VOLUMES];

	buf = recoverVolumeBloc(project.tomeRemote, project.nbVolumesRemote, NO);
	if(buf != nil)		[output setObject:buf forKey:JSON_PROJ_VOL_REMOTE];

	buf = recoverVolumeBloc(project.tomeLocal, project.nbVolumesLocal, NO);
	if(buf != nil)		[output setObject:buf forKey:JSON_PROJ_VOL_LOCAL];

	if(project.project.description[0])
		[output setObject:getStringForWchar(project.project.description) forKey:JSON_PROJ_DESCRIPTION];
	
	if(project.project.authorName[0])
		[output setObject:getStringForWchar(project.project.authorName) forKey:JSON_PROJ_AUTHOR];
	
	[output setObject:@(project.project.status) forKey:JSON_PROJ_STATUS];

	[output setObject:@(project.project.category) forKey:JSON_PROJ_TAG_CATEGORY];

	[output setObject:reverseTag(project.project) forKey:JSON_PROJ_TAG_DATA];

	[output setObject:@(project.project.rightToLeft) forKey:JSON_PROJ_RIGHT_TO_LEFT];
	[output setObject:@(project.project.haveDRM) forKey:JSON_PROJ_DRM];

	if(isLocalProject(project.project))
		[output setObject:@(YES) forKey:JSON_PROJ_ISLOCAL];
	
	if(project.project.isPaid)
		[output setObject:@(YES) forKey:JSON_PROJ_PRICE];
	
	return [NSDictionary dictionaryWithDictionary:output];
}

PROJECT_DATA_PARSED parseDataLocal(NSDictionary * bloc)
{
	PROJECT_DATA_PARSED output = getEmptyParsedProject();
	PROJECT_DATA shortData = parseBloc(bloc);

	if(!shortData.isInitialized)
		return output;

	output.project = shortData;

	output.chaptersRemote = parseChapterStructure(objectForKey(bloc, JSON_PROJ_CHAP_REMOTE, nil, [NSArray class]), &output.nbChapterRemote, YES, NO, NULL);
	output.chaptersLocal = parseChapterStructure(objectForKey(bloc, JSON_PROJ_CHAP_LOCAL, nil, [NSArray class]), &output.nbChapterLocal, YES, NO, NULL);
	output.tomeRemote = getVolumes(objectForKey(bloc, JSON_PROJ_VOL_REMOTE, nil, [NSArray class]), &output.nbVolumesRemote, NO, YES);
	output.tomeLocal = getVolumes(objectForKey(bloc, JSON_PROJ_VOL_LOCAL, nil, [NSArray class]), &output.nbVolumesLocal, NO, NO);

	BOOL needRebuildCT = NO;

	//Some inconsistency, weird, let's try to recover
	if(output.chaptersLocal == NULL && output.chaptersRemote == NULL && output.project.chaptersFull != NULL)
	{
		//Hum, let's try to copy what can be copied
		output.nbChapterLocal = 0;

		output.chaptersLocal = malloc(output.project.nbChapter * sizeof(uint));
		if(output.chaptersLocal != NULL)
		{
			//We move what is installed
			for(uint currentChap = 0; currentChap < output.project.nbChapter; currentChap++)
			{
				if(checkChapterReadable(output.project, output.project.chaptersFull[currentChap]))
				{
					output.chaptersLocal[output.nbChapterLocal++] = output.project.chaptersFull[currentChap];
				}
			}

			//Nothing remaining, oh shit
			if(output.nbChapterLocal == 0)
			{
				free(output.chaptersLocal);			output.chaptersLocal = NULL;
				free(output.project.chaptersFull);		output.project.chaptersFull = NULL;
				output.project.nbChapter = 0;
			}

			//Need to reduce our allocation and update chaptersFull
			else if(output.nbChapterLocal < output.project.nbChapter)
			{
				void * tmp = realloc(output.chaptersLocal, output.nbChapterLocal * sizeof(uint));
				if(tmp != NULL)
					output.chaptersLocal = tmp;

				output.project.nbChapter = output.nbChapterLocal;
				tmp = realloc(output.project.chaptersFull, output.project.nbChapter * sizeof(uint));
				if(tmp != NULL)
					output.project.chaptersFull = tmp;

				memcpy(output.project.chaptersFull, output.chaptersLocal, output.nbChapterLocal * sizeof(uint));
			}
		}
	}
	else if(output.chaptersLocal != NULL)
	{
		//Ensure everything is installed
		uint length = output.nbChapterLocal;
		for(uint copyPos = 0, checkPos = 0; checkPos < output.nbChapterLocal; checkPos++)
		{
			if(checkChapterReadable(output.project, output.chaptersLocal[checkPos]))
			{
				if(checkPos != copyPos)
					output.chaptersLocal[copyPos] = output.chaptersLocal[checkPos];

				copyPos++;
			}
			else
				length--;
		}

		if(length == 0)
		{
			free(output.chaptersLocal);
			output.chaptersLocal = NULL;
			output.nbChapterLocal = 0;
			needRebuildCT = YES;
		}
		else if(length < output.nbChapterLocal)
		{
			void * tmp = realloc(output.chaptersLocal, length * sizeof(uint));
			if(tmp != NULL)
				output.chaptersLocal = tmp;

			output.nbChapterLocal = length;
			needRebuildCT = YES;
		}
	}

	if(output.tomeLocal == NULL && output.tomeRemote == NULL && output.project.volumesFull != NULL)
	{
		output.nbVolumesLocal = 0;

		output.tomeLocal = malloc(output.project.nbVolumes * sizeof(META_TOME));
		if(output.tomeLocal != NULL)
		{
			//We move what is installed
			for(uint currentVol = 0; currentVol < output.project.nbVolumes; currentVol++)
			{
				if(checkTomeReadable(output.project, output.project.volumesFull[currentVol].ID))
					output.tomeLocal[output.nbVolumesLocal++] = output.project.volumesFull[currentVol];
				else
					freeSingleTome(output.project.volumesFull[currentVol]);
			}

			//Nothing remaining, oh shit
			if(output.nbVolumesLocal == 0)
			{
				free(output.tomeLocal);				output.tomeLocal = NULL;
				free(output.project.volumesFull);		output.project.volumesFull = NULL;
				output.project.nbVolumes = 0;
			}

			//Need to reduce our allocation and update chaptersFull
			else if(output.nbVolumesLocal < output.project.nbVolumes)
			{
				void * tmp = realloc(output.tomeLocal, output.nbVolumesLocal * sizeof(META_TOME));
				if(tmp != NULL)
					output.tomeLocal = tmp;

				output.project.nbVolumes = output.nbVolumesLocal;
				tmp = realloc(output.project.volumesFull, output.project.nbVolumes * sizeof(META_TOME));
				if(tmp != NULL)
					output.project.volumesFull = tmp;
			}

			//We need to copy either if there is any data remaining, and if there is none, this is a no-op so let's go
			copyTomeList(output.tomeLocal, output.nbVolumesLocal, output.project.volumesFull);
		}
	}
	else if(output.tomeLocal != NULL)
	{
		//Ensure everything is installed
		uint length = output.nbVolumesLocal;
		for(uint copyPos = 0, checkPos = 0; checkPos < output.nbVolumesLocal; checkPos++)
		{
			if(checkTomeReadable(output.project, output.tomeLocal[checkPos].ID))
			{
				if(checkPos != copyPos)
					output.tomeLocal[copyPos] = output.tomeLocal[checkPos];

				copyPos++;
			}
			else
			{
				freeSingleTome(output.tomeLocal[checkPos]);
				length--;
			}
		}

		if(length == 0)
		{
			free(output.tomeLocal);
			output.tomeLocal = NULL;
			output.nbVolumesLocal = 0;
			needRebuildCT = YES;
		}
		else if(length < output.nbVolumesLocal)
		{
			void * tmp = realloc(output.tomeLocal, length * sizeof(META_TOME));
			if(tmp != NULL)
				output.tomeLocal = tmp;

			output.nbVolumesLocal = length;
			needRebuildCT = YES;
		}
	}

	if(needRebuildCT)
		generateCTUsable(&output);

	//Eh, no data
	if(output.project.chaptersFull == NULL && output.project.volumesFull == NULL)
	{
		releaseParsedData(output);
		output = getEmptyParsedProject();
	}

	return output;
}

PROJECT_DATA_EXTRA parseBlocExtra(NSDictionary * bloc)
{
	PROJECT_DATA_EXTRA output = getEmptyExtraProject();
	PROJECT_DATA shortData = parseBloc(bloc);
	
	if(shortData.isInitialized)
	{
		output.data.project = shortData;

		NSString * URL, * CRC;
		NSArray * IDURL = @[JSON_PROJ_URL_SRGRID, JSON_PROJ_URL_SRGRID_2X, JSON_PROJ_URL_HEAD, JSON_PROJ_URL_HEAD_2X, JSON_PROJ_URL_CT, JSON_PROJ_URL_CT_2X, JSON_PROJ_URL_DD, JSON_PROJ_URL_DD_2X], * IDHash = @[JSON_PROJ_HASH_SRGRID, JSON_PROJ_HASH_SRGRID_2X, JSON_PROJ_HASH_HEAD, JSON_PROJ_HASH_HEAD_2X, JSON_PROJ_HASH_CT, JSON_PROJ_HASH_CT_2X, JSON_PROJ_HASH_DD, JSON_PROJ_HASH_DD_2X];

		for(byte i = 0; i < NB_IMAGES; i++)
		{
			URL = objectForKey(bloc, IDURL[i], nil, [NSString class]);
			CRC = objectForKey(bloc, IDHash[i], nil, [NSString class]);
			
			if(URL == nil || CRC == nil)
				output.haveImages[i] = false;
			else
			{
				char * URLCopy = strdup([URL UTF8String]);
				
				if(URLCopy != NULL)
				{
					strncpy((void*) &(output.hashesImages[i]), [CRC UTF8String], LENGTH_CRC);
					output.URLImages[i] = URLCopy;
					output.haveImages[i] = true;
				}
				else
				{
					output.haveImages[i] = false;
				}
			}
		}
	}

	return output;
}

void* parseProjectJSON(REPO_DATA* repo, NSDictionary * remoteData, uint * nbElem, bool parseExtra)
{
	void * outputData = NULL;
	bool isInit;
	NSArray * projects = objectForKey(remoteData, JSON_PROJ_PROJECTS, @"projects", [NSArray class]);
	
	if(projects == nil)
	{
#ifdef EXTENSIVE_LOGGING
		NSLog(@"Project parser error: invalid 'projects' in %@", remoteData);
#endif
		return NULL;
	}
	
	size_t size = [projects count];
	outputData = malloc(size * (parseExtra ? sizeof(PROJECT_DATA_EXTRA) : sizeof(PROJECT_DATA_PARSED)));
	
	if(outputData != NULL)
	{
		size_t validElements = 0;
		
		for(remoteData in projects)
		{
			if(validElements >= size)
				break;
			else if(ARE_CLASSES_DIFFERENT(remoteData, [NSDictionary class]))
			{
#ifdef EXTENSIVE_LOGGING
				NSLog(@"Project parser error: invalid bloc %@", remoteData);
#endif
				continue;
			}
			
			if(parseExtra)
			{
				((PROJECT_DATA_EXTRA*)outputData)[validElements] = parseBlocExtra(remoteData);
				((PROJECT_DATA_EXTRA*)outputData)[validElements].data.project.locale = false;
				isInit = ((PROJECT_DATA_EXTRA*)outputData)[validElements].data.project.isInitialized;
			}
			else
			{
				((PROJECT_DATA_PARSED*)outputData)[validElements] = parseDataLocal(remoteData);
				isInit = ((PROJECT_DATA_PARSED*)outputData)[validElements].project.isInitialized;
			}
		
			if(isInit)
			{
				PROJECT_DATA * project;
				
				if(parseExtra)
					project = &(((PROJECT_DATA_EXTRA*) outputData)[validElements++].data.project);
				else
					project = &((PROJECT_DATA_PARSED*)outputData)[validElements++].project;
				
				project->repo = repo;
			}
		}
		
		if(nbElem != NULL)
			*nbElem = validElements;
	}
	
	return outputData;
}

PROJECT_DATA_EXTRA * parseRemoteData(REPO_DATA* repo, char * remoteDataRaw, uint * nbElem)
{
	NSError * error = nil;
	NSMutableDictionary * remoteData = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:remoteDataRaw length:ustrlen(remoteDataRaw)] options:0 error:&error];
	
	if(error != nil || remoteData == nil || ARE_CLASSES_DIFFERENT(remoteData, [NSDictionary class]))
	{
		if(error != nil)
			NSLog(@"%@", error.description);
		else
			NSLog(@"Parse error when analysing remote project file for %@", repo != NULL ? getStringForWchar(repo->name) : @"local repo");
		return NULL;
	}
		
	PROJECT_DATA_EXTRA * output = parseProjectJSON(repo, remoteData, nbElem, true);

	if(output != NULL)
	{
		for(uint pos = 0; pos < *nbElem; pos++)
		{
			output[pos].data.chaptersRemote = output[pos].data.project.chaptersFull;
			output[pos].data.nbChapterRemote = output[pos].data.project.nbChapter;
			output[pos].data.tomeRemote = output[pos].data.project.volumesFull;
			output[pos].data.nbVolumesRemote = output[pos].data.project.nbVolumes;

#ifndef EXPOSE_DECIMAL_VOLUMES
			for(uint i = 0, length = output[pos].data.nbVolumesRemote; i < length; ++i)
			{
				if(output[pos].data.tomeRemote[i].readingID != INVALID_SIGNED_VALUE)
					output[pos].data.tomeRemote[i].readingID *= 10;
			}
#endif

			output[pos].data.project.chaptersFull = NULL;
			output[pos].data.project.nbChapter = 0;
			output[pos].data.project.volumesFull = NULL;
			output[pos].data.project.nbVolumes = 0;
		}
	}

	return output;
}

PROJECT_DATA_PARSED * parseLocalData(REPO_DATA ** repo, uint nbRepo, unsigned char * remoteDataRaw, uint *nbElem)
{
	if(nbElem == NULL)
		return NULL;
	
	NSError * error = nil;
	NSMutableDictionary * remoteData = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:remoteDataRaw length:ustrlen(remoteDataRaw)] options:0 error:&error];
	
	if(error != nil || remoteData == nil || ARE_CLASSES_DIFFERENT(remoteData, [NSArray class]))
	{
#ifdef EXTENSIVE_LOGGING
		NSLog(@"Local project parser error: invalid 'projects' in %@", remoteData);
#endif
		return NULL;
	}
	
	uint nbElemPart, posRepo;
	PROJECT_DATA_PARSED *output = NULL, *currentPart;
	id repoID;
	
	for(NSDictionary * remoteDataPart in remoteData)
	{
		if(ARE_CLASSES_DIFFERENT(remoteDataPart, [NSDictionary class]))
			continue;
		
		repoID = objectForKey(remoteDataPart, JSON_PROJ_AUTHOR_ID, nil, [NSNumber class]);
		if(repoID == nil)
		{
#ifdef EXTENSIVE_LOGGING
			NSLog(@"Project parser error: no authorID %@", remoteDataPart);
#endif
			continue;
		}
		
		bool isLocal = [(NSNumber*) repoID unsignedLongLongValue] == LOCAL_REPO_ID;
		
		//No repo, so we don't exactly have a choice
		if(!isLocal && repo == NULL)
			continue;

		for(posRepo = 0; posRepo < nbRepo || isLocal; posRepo++)
		{
			if(!isLocal && repo[posRepo] == NULL)
				continue;

			if(isLocal || [(NSNumber*) repoID unsignedLongLongValue] == getRepoID(repo[posRepo]))
			{
				nbElemPart = 0;
				currentPart = (PROJECT_DATA_PARSED*) parseProjectJSON(isLocal ? NULL : repo[posRepo], remoteDataPart, &nbElemPart, false);

				if(nbElemPart)
				{
					void * buf = realloc(output, (*nbElem + nbElemPart) * sizeof(PROJECT_DATA_PARSED));
					if(buf != NULL)
					{
						output = buf;
						memcpy(&output[*nbElem], currentPart, nbElemPart * sizeof(PROJECT_DATA_PARSED));
						*nbElem += nbElemPart;
					}
				}
				free(currentPart);
				break;
			}
		}
	}
	
	return output;
}

char * reversedParseData(PROJECT_DATA_PARSED * data, uint nbElem, REPO_DATA ** repo, uint nbRepo, size_t * sizeOutput)
{
	if(data == NULL || !nbElem)
		return NULL;
	
	uint counters[nbRepo + 1], jumpTable[nbRepo + 1][nbElem];
	bool projectLinkedToRepo = false, fullLocal = repo == NULL || !nbRepo, haveLocal = false;
	
	memset(counters, 0, sizeof(counters));
	memset(jumpTable, 0, sizeof(jumpTable));
	
	//Create a table linking projects to a repo
	for(uint pos = 0, posRepo; pos < nbElem; pos++)
	{
		if(isLocalRepo(data[pos].project.repo))
		{
			jumpTable[nbRepo][counters[nbRepo]++] = pos;
			projectLinkedToRepo = haveLocal = true;
		}
		else if(!fullLocal)
		{
			uint64_t repoID = getRepoID(data[pos].project.repo);
			for(posRepo = 0; posRepo < nbRepo; posRepo++)
			{
				if(repoID == getRepoID(repo[posRepo]))
				{
					jumpTable[posRepo][counters[posRepo]++] = pos;
					projectLinkedToRepo = true;
					break;
				}
			}
		}
	}
	
	if(!projectLinkedToRepo)
		return NULL;
	
	NSMutableArray *root = [NSMutableArray array], *projects;
	NSDictionary * currentNode;
	id currentProject;
	
	for(uint pos = 0; pos <= nbRepo; pos++)
	{
		if(!counters[pos])	continue;
		
		projects = [NSMutableArray array];
		
		for(uint index = 0; index < counters[pos]; index++)
		{
			currentProject = reverseParseBloc(data[jumpTable[pos][index]]);
			if(currentProject != nil)
				[projects addObject:currentProject];
		}
		
		if([projects count])
		{
			currentNode = [NSDictionary dictionaryWithObjects:@[@(getRepoID(pos < nbRepo ? repo[pos] : NULL)), projects] forKeys:@[JSON_PROJ_AUTHOR_ID, JSON_PROJ_PROJECTS]];
			if(currentNode != nil)
				[root addObject:currentNode];
		}
	}
	
	if(![root count])
		return NULL;
	
	NSError * error = nil;
	NSData * dataOutput = [NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
	
	size_t length = [dataOutput length];
	void * outputDataC = malloc(length);

	if(dataOutput == NULL)
		return NULL;
	
	[dataOutput getBytes:outputDataC length:length];
	
	char * output = base64_encode(outputDataC, length, sizeOutput);
	
	free(outputDataC);
	
	return output;
}

#pragma mark - Toolbox

id objectForKey(NSDictionary * dict, NSString * ID, NSString * fullName, Class expectedClass)
{
	id value = [dict objectForKey : ID];
	
	if(value == nil && fullName != nil)
	{
		value = [dict objectForKey:fullName];
	}

	if(value == nil || (expectedClass != [NSObject class] && ARE_CLASSES_DIFFERENT(value, expectedClass)))
		return nil;
	
	return value;
}

void moveProjectExtraToParsed(const PROJECT_DATA_EXTRA input, PROJECT_DATA_PARSED * output)
{
	if(!input.data.project.isInitialized || output == NULL)
		return;

	*output = input.data;
}

bool convertTagMask(NSArray * input, TAG ** tagData, uint32_t * nbTags, uint32_t * mainTag)
{
	if(input == nil || [input count] == 0 || [input count] > UINT_MAX)
		return false;

	//We allocate enough memory to load everything
	uint validCount = 0;
	TAG * tmpTag = malloc([input count] * sizeof(TAG));

	if(tmpTag == NULL)
		return false;

	for(NSNumber * tagEntry in input)
	{
		//Ensure tag is valid
		if(ARE_CLASSES_DIFFERENT(tagEntry, [NSNumber class]))
			continue;

		uint32_t tag = [tagEntry unsignedIntValue];
		if(!doesTagOfIDExist(tag))
			continue;

		//The first tag is the main tag
		if(validCount == 0)
			*mainTag = tag;

		tmpTag[validCount++].ID = tag;
	}

	//No data
	if(validCount == 0)
	{
		free(tmpTag);
		return false;
	}

	//Less data than expected, let's not waste memory
	if(validCount < [input count])
	{
		void * tmp = realloc(tmpTag, validCount * sizeof(TAG));
		if(tmp != NULL)
			tmpTag = tmp;
	}

	*nbTags = validCount;
	*tagData = tmpTag;

	return true;
}