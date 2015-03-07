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

@implementation RakMDLController

#pragma mark - Controller internal

- (id) init : (MDL *) tabMDL : (NSString *) state
{
	self = [super init];
	
	if(self != nil)
	{
		_tabMDL = tabMDL;
		IDToPosition = NULL;
		quit = false;
		
		//We have to make reference to entries of cache. In order to keep it updatable, we have to allocate memory for each entry
		PROJECT_DATA * _cache = getCopyCache(RDB_LOADALL | SORT_NAME, &sizeCache);
		PROJECT_DATA ** futureCache = calloc(sizeCache, sizeof(PROJECT_DATA *));
		if(futureCache == NULL)
		{
			memoryError(sizeCache * sizeof(PROJECT_DATA *));
			freeProjectData(_cache);
			return nil;
		}
		
		for (uint i = 0; i < sizeCache; i++)
		{
			futureCache[i] = malloc(sizeof(PROJECT_DATA));
			if(futureCache[i] == NULL)
			{
				while (i-- > 0)
					free(futureCache[i]);
				free(futureCache);
				
				memoryError(sizeof(PROJECT_DATA));
				freeProjectData(_cache);
				return nil;
			}
			else
				*futureCache[i] = _cache[i];
		}
		
		free(_cache);
		cache = futureCache;
		
		char * stateChar = NULL;
		if(state != nil && [state isNotEqualTo:STATE_EMPTY])
			stateChar = (char *) [state UTF8String];
		
		if(startMDL(stateChar, cache, &coreWorker, &todoList, &status, &IDToPosition, &nbElem, &quit, (__bridge void *)(self)))
		{
			IDToPosition = malloc(nbElem * sizeof(uint));
			if(IDToPosition != NULL)
			{
				for(discardedCount = 0; discardedCount < nbElem; discardedCount++)
					IDToPosition[discardedCount] = discardedCount;
				
				[RakDBUpdate registerForUpdate:self :@selector(DBUpdated:)];
			}
			else
				self = nil;
		}
		else
			self = nil;
	}
	
	return self;
}

- (void) needToQuit
{
	quit = true;
	if(isThreadStillRunning(coreWorker))
		MDLQuit();
}

- (NSString *) serializeData
{
	char * data = MDLParseFile(*todoList, status, IDToPosition, discardedCount);
	NSString * output = nil;

	if(data != NULL && strlen(data))
	{
		output = [NSString stringWithUTF8String: data];
	}

	free(data);
	return output;
}

- (void) DBUpdated : (NSNotification *) notification
{
	uint updatedID;
	PROJECT_DATA prevData;
	
	if([RakDBUpdate getIDUpdated:notification.userInfo :&updatedID])
	{
		uint pos = 0;
		
		for(; pos < sizeCache && cache[pos]->cacheDBID != updatedID; pos++);
		if(pos < sizeCache)
		{
			prevData = *cache[pos];
			*cache[pos] = getElementByID(updatedID);
			releaseCTData(prevData);
		}
	}
	else	//Full update
	{
		uint newSize;
		PROJECT_DATA * _cache = getCopyCache(RDB_LOADALL | SORT_NAME, &newSize);
		
		if(_cache != NULL && newSize != 0)
		{
			BOOL usedOld[sizeCache], usedNew[newSize], firstPass = YES;
			memset(usedOld, 0, sizeof(usedOld));
			memset(usedNew, 0, sizeof(usedNew));

			//We update the current cache
			for(uint posFinal = 0, posNew = 0; posFinal < sizeCache; posFinal++)
			{
				//We find the entry in the new structure
				for(; posNew < newSize && cache[posFinal]->cacheDBID != _cache[posNew].cacheDBID; posNew++);
				if(posNew == newSize)
				{
					if(firstPass)
					{
						firstPass = NO;
						posFinal--;
					}

					posNew = 0;
					continue;
				}
				else
					firstPass = YES;
				
				//We note the item still exist
				usedOld[posFinal] = usedNew[posNew] = YES;
				
				//We update the data
				releaseCTData(*cache[posFinal]);
				*cache[posFinal] = _cache[posNew];
			}
			
			//Ok, now, let's check if things were added, if some were removed
			for (uint posFinal = 0, posNew = 0; posFinal < sizeCache; posFinal++)
			{
    			if(usedOld[posFinal])
					continue;
				else
					usedOld[posFinal] = YES;
				
				releaseCTData(*cache[posFinal]);

				//We check if we can recycle an item to fit this hole
				if(posNew != newSize)
				{
					for(; posNew < newSize && usedNew[posNew]; posNew++);
					
					if(posNew < newSize)
					{
						usedNew[posNew] = YES;
						*cache[posFinal] = _cache[posNew];
						continue;
					}
				}
				
				free(cache[posFinal]);
				
				memcpy(&(cache[posFinal]), &(cache[posFinal + 1]), (sizeCache - posFinal - 1) * sizeof(PROJECT_DATA *));
				sizeCache--;
			}
			
			//We insert the new elements
			if(sizeCache != newSize)
			{
				void * new = realloc(cache, newSize * sizeof(PROJECT_DATA *));
				if(new != NULL)
				{
					uint posNew = 0;
					cache = new;
					
					while(posNew < newSize)
					{
						for(; posNew < newSize && !usedNew[posNew]; posNew++);
						
						if(posNew < newSize)
						{
							cache[sizeCache] = malloc(sizeof(PROJECT_DATA));
							if(cache[sizeCache] != NULL)
							{
								*cache[sizeCache++] = _cache[posNew];
							}
						}
					}
				}
				else
				{
					for(uint posNew = 0; posNew < newSize; posNew++)
					{
						if(!usedNew[posNew])
							releaseCTData(_cache[posNew]);
					}
				}
			}
		}
		
		free(_cache);
	}
}
		   
- (void) dealloc
{
	[RakDBUpdate unRegister : self];

	MDLCleanup(nbElem, status, todoList, cache, sizeCache);
	free(IDToPosition);
}

#pragma mark - Get data about download list

- (uint) getNbElem : (BOOL) considerDiscarded
{
	return considerDiscarded ? discardedCount : nbElem;
}

- (uint) convertRowToPos : (uint) row
{
	return (row >= discardedCount) ? -1 : IDToPosition[row];
}

- (DATA_LOADED **) getData : (uint) row : (BOOL) considerDiscarded
{
	if(row >= (considerDiscarded ? discardedCount : nbElem))
		return NULL;
	
	return &(*todoList)[considerDiscarded ? IDToPosition[row] : row];
}

- (int8_t) statusOfID : (uint) row : (BOOL) considerDiscarded
{
	if(row >= (considerDiscarded ? discardedCount : nbElem) || status == NULL)
		return MDL_CODE_INTERNAL_ERROR;
	
	if(considerDiscarded)
		row = IDToPosition[row];
	
	return *(status[row]);
}

- (BOOL) checkForCollision : (PROJECT_DATA) data : (BOOL) isTome : (int) element
{
	return nbElem && MDLisThereCollision(data, isTome, element, *todoList, status, nbElem);
}

#pragma mark - Tools

- (void) addElement : (PROJECT_DATA) data : (BOOL) isTome : (int) element : (BOOL) partOfBatch
{
	if (element == VALEUR_FIN_STRUCT)
		return;
	
	uint pos;
	for (pos = 0; pos < sizeCache && cache[pos]->cacheDBID != data.cacheDBID ; pos++);
	
	if(pos == sizeCache || cache[pos]->cacheDBID != data.cacheDBID)
		return;
	
	if(!nbElem || !MDLisThereCollision(data, isTome, element, *todoList, status, nbElem))
	{
		DATA_LOADED * newElement = MDLCreateElement(cache[pos], isTome, element);
		
		if(newElement == NULL)
		{
			free(newElement);
			return;
		}
		
		int8_t **newStatus = realloc(status, (nbElem + 1) * sizeof(int8_t*));
		uint *newIDToPosition = realloc(IDToPosition, (discardedCount + 1) * sizeof(uint));
		
		//Even if one of them failed, we need to update the pointer of the other
		if(newStatus == NULL || newIDToPosition == NULL)
		{
			if(newStatus != NULL)
				status = newStatus;
			
			if(newIDToPosition != NULL)
				IDToPosition = newIDToPosition;
			
			return;
		}
		
		status = newStatus;
		IDToPosition = newIDToPosition;
		
		//Increase the size of the status buffer
		status[nbElem] = malloc(sizeof(int8_t));
		
		if(status[nbElem] == NULL)
			return;
		
		*status[nbElem] = MDL_CODE_DEFAULT;
		IDToPosition[discardedCount++] = nbElem++;
		
		DATA_LOADED ** newTodoList = realloc(*todoList, nbElem * sizeof(DATA_LOADED *));
		
		if(newTodoList == NULL)
		{
			free(status[nbElem]);			status[nbElem] = NULL;
		}

		int curPos = nbElem - 1;
		*todoList = MDLInjectElementIntoMainList(newTodoList, &nbElem, &curPos, &newElement);
	}
	
	if(!partOfBatch && discardedCount)
	{
		//Great, the injection is now over... We need to reanimate what needs to be
		if(!isThreadStillRunning(coreWorker))
			startMDL(NULL, cache, &coreWorker, &todoList, &status, &IDToPosition, &discardedCount, &quit, (__bridge void *)(self));
		else
			MDLDownloadOver(true);
		
		//Worker should be at work, now, let's wake the UI up
		[_tabMDL wakeUp];
	}
}

- (uint) addBatch : (PROJECT_DATA) data : (BOOL) isTome : (BOOL) launchAtTheEnd
{
	//We assume our data are up-to-date
	int previousElem = VALEUR_FIN_STRUCT;
	uint posFull = 0, posInst = 0, nbFull, nbInst, countInjected = 0;
	
	if (isTome)
	{
		if(data.tomesFull == NULL || data.tomesInstalled == NULL || data.tomesFull[0].ID == VALEUR_FIN_STRUCT)
			return countInjected;
		
		nbFull = data.nombreTomes;
		nbInst = data.nombreTomesInstalled;
	}
	else
	{
		if(data.chapitresFull == NULL || data.chapitresInstalled == NULL || data.chapitresFull[0] == VALEUR_FIN_STRUCT)
			return countInjected;

		nbFull = data.nombreChapitre;
		nbInst = data.nombreChapitreInstalled;
	}
	
	//On choppe les trous
	for (; posFull < nbFull && MDLCTRL_getDataFull(data, posFull, isTome) != VALEUR_FIN_STRUCT && posInst < nbInst && MDLCTRL_getDataInstalled(data, posInst, isTome) != VALEUR_FIN_STRUCT; posFull++)
	{
		if (MDLCTRL_getDataFull(data, posFull, isTome) == MDLCTRL_getDataInstalled(data, posInst, isTome))
			posInst++;
		else
		{
			if(previousElem != VALEUR_FIN_STRUCT)
			{
				[self addElement:data :isTome :previousElem :YES];
				countInjected++;
			}
			
			previousElem = MDLCTRL_getDataFull(data, posFull, isTome);
		}
	}
	
	//Le burst de fin
	while (posFull < nbFull && MDLCTRL_getDataFull(data, posFull, isTome) != VALEUR_FIN_STRUCT)
	{
		if(previousElem != VALEUR_FIN_STRUCT)
		{
			[self addElement:data :isTome :previousElem :YES];
			countInjected++;
		}
		
		previousElem = MDLCTRL_getDataFull(data, posFull++, isTome);
	}
	
	if(previousElem != VALEUR_FIN_STRUCT)
	{
		[self addElement:data :isTome :previousElem :!launchAtTheEnd];
		countInjected++;
	}
	
	return countInjected;
}

- (void) reorderElements : (uint) posStart : (uint) posEnd : (uint) injectionPoint
{
	if(IDToPosition == NULL)
		return;
	
	if (posStart > posEnd || posEnd >= discardedCount || (injectionPoint >= posStart && injectionPoint <= posEnd))
	{
#ifdef DEV_VERSION
		NSLog(@"Invalid data when reorder: posStart: %d, posEnd: %d, injectionPoint:%d, discardedCount: %d", posStart, posEnd, injectionPoint, discardedCount);
#endif
		return;
	}
	
	if(injectionPoint == discardedCount)
		injectionPoint--;

	uint size = (posEnd - posStart + 1);
	bool isMovingPartBeforeInsertion = posEnd < injectionPoint;
	uint * movingPart = malloc(size * sizeof(uint));
	
	if (movingPart == NULL)
	{
		memoryError(size * sizeof(uint));
		return;
	}
	else
		memcpy(movingPart, &IDToPosition[posStart], size * sizeof(uint));
	
	if(isMovingPartBeforeInsertion)
		memcpy(&IDToPosition[posStart], &IDToPosition[posStart + size], (--injectionPoint - posStart) * sizeof(uint));
	else
		memcpy(&IDToPosition[injectionPoint + size], &IDToPosition[injectionPoint], (posStart - injectionPoint) * sizeof(uint));
	
	memcpy(&IDToPosition[injectionPoint], movingPart, size * sizeof(uint));
	free(movingPart);
}

- (void) discardElement : (uint) element withSimilar: (BOOL) similar
{
	if(element < discardedCount)
	{
		PROJECT_DATA project;
		if(similar)
			project = *(*todoList)[IDToPosition[element]]->datas;
		
		if(similar)
		{
			uint indexRemoved[discardedCount], nbRemoved = 0;

			for(uint posDiscarded = 0; posDiscarded < discardedCount; posDiscarded++)
			{
				//We remove every similar project from which the download is done
				if((*todoList)[IDToPosition[posDiscarded]]->datas->cacheDBID == project.cacheDBID && (status[IDToPosition[posDiscarded]]) != NULL && *(status[IDToPosition[posDiscarded]]) == MDL_CODE_INSTALL_OVER)
					indexRemoved[nbRemoved++] = posDiscarded;
				else
					IDToPosition[posDiscarded - nbRemoved] = IDToPosition[posDiscarded + 1];
			}
			
			discardedCount -= nbRemoved;
		
			[_list deleteElements : indexRemoved : nbRemoved];
		}
		else
		{
			discardedCount--;
			for(uint posDiscarded = element; posDiscarded < discardedCount; posDiscarded++)
			{
				IDToPosition[posDiscarded] = IDToPosition[posDiscarded+1];
			}
		}
	}
}

- (void) setStatusOfID : (uint) row : (BOOL) considerDiscarded : (int8_t) value
{
	if(row >= (considerDiscarded ? discardedCount : nbElem) || status == NULL)
		return;
	
	if(considerDiscarded)
		row = IDToPosition[row];
	
	if(status[row] != NULL)
		*(status[row]) = value;
}

#pragma mark - Main view control

- (BOOL) areCredentialsComplete
{
	return COMPTE_PRINCIPAL_MAIL != NULL && (!self.requestCredentials || getPassFromCache(NULL));
}

- (RakTabForegroundView *) getForegroundView
{
	return [_tabMDL getForgroundView];
}

- (void) setWaitingLogin : (NSNumber *) request
{
	[_tabMDL setWaitingLoginWrapper : request];
}

@end
