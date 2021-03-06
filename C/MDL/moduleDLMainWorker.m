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

pthread_mutex_t installSharedMemoryReadWrite= PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t asynchronousTaskInThreads	= PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t mutexLockMainThread			= PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t condResumeExecution			= PTHREAD_COND_INITIALIZER;

THREAD_TYPE *threadID = NULL;

static uint requestID;

RakMDLController *	mainTab;

void mainDLProcessing(MDL_MWORKER_ARG * arg)
{
	pthread_mutex_trylock(&mutexLockMainThread);
	
	DATA_LOADED ****	todoList	=	arg->todoList;
	bool *				quit		=	arg->quit;
	mainTab							=	(__bridge RakMDLController *)(arg->mainTab);
	int8_t ***			status		=	arg->status;
	uint *				nbElemTotal =	arg->nbElemTotal;
	uint **				IDToPosition =	arg->IDToPosition;
	
	free(arg);
	
	uint dataPos;
	
	requestID = RID_DEFAULT;
	
	MDLUpdateKillState(*quit);
	
	//On va lancer le premier élément
	for(dataPos = 0; dataPos < *nbElemTotal && *((*status)[(*IDToPosition)[dataPos]]) != MDL_CODE_DEFAULT; dataPos++); //Les éléments peuvent être réorganisés
	if(dataPos < *nbElemTotal && *((*status)[(*IDToPosition)[dataPos]]) == MDL_CODE_DEFAULT)
	{
		MDLStartHandler((*IDToPosition)[dataPos], *nbElemTotal, **todoList, status);
	}
	
	while(1)
	{
		MUTEX_LOCK(mutexLockMainThread); //Ce seconde lock bloque l'execution jusqu'à que pthread_cond le débloque
		
		if(*quit)
		{
			MDLUpdateKillState(*quit);
			pthread_cond_broadcast(&condResumeExecution);
			MUTEX_UNLOCK(mutexLockMainThread);
			break;
		}
		
		else if(requestID != RID_DEFAULT)
		{
			if(requestID == RID_UPDATE_STATUS_REANIMATE)
			{
				uint i;
				for(i = 0; i < *nbElemTotal && *((*status)[(*IDToPosition)[i]]) != MDL_CODE_DL; i++);
				
				if(i == *nbElemTotal)
					requestID = RID_UPDATE_STATUS;
			}
			
			if(requestID == RID_UPDATE_STATUS)
			{
				if(IDToPosition == NULL)
					break;
				
				char copiedStatus;
				
				//We search from the beginning (as moves are possible) for items available to download
				for(dataPos = 0; dataPos < *nbElemTotal; dataPos++)
				{
					copiedStatus = *((*status)[(*IDToPosition)[dataPos]]);
					
					if(copiedStatus == MDL_CODE_DEFAULT || copiedStatus == MDL_CODE_DL)
						break;
				}
				
				//We check there isn't something already downloading, as I caught a race condition that would duplicated downloader
				//This doesn't cause any significant problem but I want to keep control on it
				uint seekDL = dataPos;
				for(; seekDL < *nbElemTotal && *((*status)[(*IDToPosition)[seekDL]]) != MDL_CODE_DL; seekDL++);
				
				if(dataPos < *nbElemTotal && seekDL == *nbElemTotal)
				{
					MDLStartHandler((*IDToPosition)[dataPos], *nbElemTotal, **todoList, status);
				}
				else
				{
					//On regarde si on a plus que des éléments qui sont en attente d'une action extérieure
					for(dataPos = 0; dataPos < *nbElemTotal && *((*status)[(*IDToPosition)[dataPos]]) != MDL_CODE_WAITING_LOGIN && *((*status)[(*IDToPosition)[dataPos]]) != MDL_CODE_WAITING_PAY; dataPos++);
					
					if(dataPos == *nbElemTotal)	//Non, on se casse
					{
						pthread_cond_broadcast(&condResumeExecution);
						MUTEX_UNLOCK(mutexLockMainThread);
						
						break;
					}
				}
			}
			else if(requestID == RID_UPDATE_INSTALL)
			{
				MUTEX_LOCK(installSharedMemoryReadWrite);
				for(dataPos = 0; dataPos < *nbElemTotal && *((*status)[(*IDToPosition)[dataPos]]) != MDL_CODE_INSTALL; dataPos++);

				if(dataPos == *nbElemTotal)
				{
					for(dataPos = 0; dataPos < *nbElemTotal && *((*status)[(*IDToPosition)[dataPos]]) != MDL_CODE_DL_OVER; dataPos++);
					
					if(dataPos != *nbElemTotal) //une installation a été trouvée
						*((*status)[(*IDToPosition)[dataPos]]) = MDL_CODE_INSTALL;
				}
				MUTEX_UNLOCK(installSharedMemoryReadWrite);
			}
		}
		
		pthread_cond_broadcast(&condResumeExecution);	//On a reçu la requête, le thread sera libéré dès que le mutex sera debloqué
		MUTEX_UNLOCK(mutexLockMainThread);
		
		if(!*quit)
		{
			usleep(5);
			while(!pthread_mutex_trylock(&mutexLockMainThread))   //On attend le lock
			{
				MUTEX_UNLOCK(mutexLockMainThread);
				if(requestID != RID_DEFAULT)	//Si nouvelle requête reçue
					break;
				else
					usleep(10);
			}
        }
	}
	
	threadID = NULL;
	
	pthread_cond_broadcast(&condResumeExecution);
	pthread_mutex_trylock(&mutexLockMainThread);
	MUTEX_UNLOCK(mutexLockMainThread);
	
	notifyDownloadOver();

	quit_thread(0);
}

void MDLSetThreadID(THREAD_TYPE *thread)
{
	threadID = thread;
}

void MDLStartHandler(uint posElement, uint nbElemTotal, DATA_LOADED ** todoList, int8_t *** status)
{
    if(todoList[posElement] != NULL)
    {
        MDL_HANDLER_ARG* argument = malloc(sizeof(MDL_HANDLER_ARG));
        if(argument == NULL)
        {
            memoryError(sizeof(MDL_HANDLER_ARG));
            return;
        }
		
        *((*status)[posElement]) = MDL_CODE_DL; //Permet à la boucle de mainDL de ce poursuivre tranquillement

		MDLUpdateIcons(posElement, todoList[posElement]);
		
		argument->todoList = todoList[posElement];
        argument->currentState = (*status)[posElement];
		argument->fullStatus = status;
		argument->statusLength = nbElemTotal;
		
        createNewThread(MDLHandleProcess, argument);
    }
    else
    {
        *(*status)[posElement] = MDL_CODE_INTERNAL_ERROR;
    }
}

bool MDLSendMessage(uint code)
{
	bool ret_value = false;
	
	MUTEX_LOCK(asynchronousTaskInThreads);

	if(threadID != NULL && isThreadStillRunning(*threadID))
	{
		requestID = code;
		
		//We timeout after one second
		struct timeval tv;
		struct timespec ts;
		gettimeofday(&tv, NULL);
		ts.tv_sec = tv.tv_sec + 1;
		ts.tv_nsec = tv.tv_usec * 1000;

		//We timedout, so probably a deadlock, great...
		if(pthread_cond_timedwait(&condResumeExecution, &mutexLockMainThread, &ts) == ETIMEDOUT)
		{
#ifdef EXTENSIVE_LOGGING
			//We don't have much to do though
			logR("Timed out while waiting for the broker to release us :/");
#endif
		}
		
		ret_value = true;
	}
	
	MUTEX_UNLOCK(asynchronousTaskInThreads);
	
	return ret_value;
}

bool MDLDownloadOver(bool reanimateOnly)
{
	return MDLSendMessage(reanimateOnly ? RID_UPDATE_STATUS_REANIMATE : RID_UPDATE_STATUS);
}

bool MDLStartNextInstallation()
{
	return MDLSendMessage(RID_UPDATE_INSTALL);
}

void MDLQuit()
{
	if(threadID == NULL || !isThreadStillRunning(*threadID))
		return;
		
	MUTEX_LOCK(asynchronousTaskInThreads);
	
	pthread_cond_wait(&condResumeExecution, &mutexLockMainThread);
	
	MUTEX_UNLOCK(asynchronousTaskInThreads);
}

void MDLInstallOver(PROJECT_DATA project)
{
	[RakDBUpdate postNotificationProjectUpdate:project];
}

void MDLUpdateIcons(uint selfCode, DATA_LOADED * metadata)
{
	MDLCommunicateOC(selfCode, metadata);
}

void MDLCommunicateOC(uint selfCode, DATA_LOADED * metadata)
{
	if(metadata == NULL)
		return;
	
	//If we have to recover UIInstance
	if(mainTab != nil && [mainTab respondsToSelector:@selector(getData::)])
	{
		DATA_LOADED ** todoList = [mainTab getData:selfCode bypassDiscarded:YES];
		if(todoList != NULL && *todoList != NULL)
			metadata = *todoList;
		else
			return;
	}
	
	if(metadata->rowViewResponsible != nil)
	{
#if !TARGET_OS_IPHONE
		[(__bridge RakMDLListView *) metadata->rowViewResponsible performSelectorOnMainThread:@selector(updateContext) withObject:nil waitUntilDone:NO];
#else
		[(RakMDLCoreController *) RakApp.MDL rowUpdate:selfCode];
#endif
	}
	
#if TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MDL_STATUS_UPDATE
														object:[NSString stringWithFormat:@"%d-%d-%d", metadata->datas->cacheDBID,
																metadata->listChapitreOfTome != NULL,
																metadata->identifier]
													  userInfo:nil];
#endif
}

void updatePercentage(PROXY_DATA_LOADED * metadata, float percentage, size_t speed)
{
	if(metadata == NULL)
		return;
	
	if(metadata->rowViewResponsible != NULL)
	{
#if !TARGET_OS_IPHONE
		[(__bridge RakMDLListView *) *metadata->rowViewResponsible updatePercentage:percentage :speed];
#else
		[(RakMDLCoreController *) RakApp.MDL percentageUpdate : percentage atSpeed : speed forObject : (__bridge NSNumber *) *metadata->rowViewResponsible];
#endif
	}
	
#if TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MDL_PERCENTAGE_UPDATE
														object:[NSString stringWithFormat:@"%d-%d-%d", metadata->datas->cacheDBID,
																metadata->listChapitreOfTome != NULL,
																metadata->chapitre]
													  userInfo:@{@"percentage" : @(percentage), @"speed" : @(speed)}];
#endif
}

bool dataRequireLoginWithNotif(DATA_LOADED ** data, int8_t ** status, uint * IDToPosition, uint length, void* mainTabController)
{
	bool retValue = dataRequireLogin(data, status, IDToPosition, length, COMPTE_PRINCIPAL_MAIL == NULL);
	
	if(mainTabController != NULL)
		[(__bridge RakMDLController *) mainTabController setRequestCredentials:retValue];
	
	return retValue;
}

//We recycle the MDL_MWORKER_ARG structure
void watcherForLoginRequest(MDL_MWORKER_ARG * arg)
{
	bool *				quit		=	arg->quit;
	RakMDLController *	_mainTab	=	(__bridge RakMDLController *)(arg->mainTab);
	int8_t ***			status		=	arg->status;
	uint *				nbElemTotal =	arg->nbElemTotal;
	uint **				IDToPosition =	arg->IDToPosition;
	
	free(arg);

	MUTEX_VAR * lock = [RakApp sharedLoginMutex : YES];
	
	[_mainTab performSelectorOnMainThread:@selector(setWaitingLogin:) withObject:@(true) waitUntilDone:NO];
	
	while(![mainTab areCredentialsComplete])
	{
		pthread_cond_wait([RakApp sharedLoginLock], lock);
	}
	
	pthread_mutex_unlock(lock);
	
	[_mainTab performSelectorOnMainThread:@selector(setWaitingLogin:) withObject:@(false) waitUntilDone:NO];
	
	if(!*quit)
	{
		for(uint pos = 0, index; pos < *nbElemTotal; pos++)
		{
			index = (*IDToPosition)[pos];
			
			if(*(*status)[index] == MDL_CODE_WAITING_LOGIN)
				*(*status)[index] = MDL_CODE_DEFAULT;
		}
		
		MDLDownloadOver(true);
	}
	
	quit_thread(0);
}