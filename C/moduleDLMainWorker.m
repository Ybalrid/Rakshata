/*********************************************************************************************
 **	__________         __           .__            __                 ________   _______   	**
 **	\______   \_____  |  | __  _____|  |__ _____ _/  |______   	___  _\_____  \  \   _  \  	**
 **	 |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \  	\  \/ //  ____/  /  /_\  \ 	**
 **	 |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \__ \   //       \  \  \_/   \	**
 **	 |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /	  \_/ \_______ \ /\_____  /	**
 **	        \/      \/     \/     \/     \/     \/          \/ 	              \/ \/     \/ 	**
 **                                                                                          **
 **		Source code and assets are property of Taiki, distribution is stricly forbidden		**
 **                                                                                          **
 *********************************************************************************************/

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
	mainTab							=	arg->mainTab;
	int8_t ***			status		=	arg->status;
	uint *				nbElemTotal =	arg->nbElemTotal;
	uint **				IDToPosition =	arg->IDToPosition;
	
	free(arg);
	
	uint dataPos;
	char **historiqueTeam = calloc(1, sizeof(char*));
	
	requestID = RID_DEFAULT;
	
	MDLUpdateKillState(*quit);
	
	//On va lancer le premier élément
	for(dataPos = 0; dataPos < *nbElemTotal && *((*status)[(*IDToPosition)[dataPos]]) != MDL_CODE_DEFAULT; dataPos++); //Les éléments peuvent être réorganisés
	if(dataPos < *nbElemTotal && *((*status)[(*IDToPosition)[dataPos]]) == MDL_CODE_DEFAULT)
	{
		MDLStartHandler((*IDToPosition)[dataPos], *nbElemTotal, **todoList, status, &historiqueTeam);
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
				for(i = 0; i < *nbElemTotal && *((*status)[(*IDToPosition)[dataPos]]) != MDL_CODE_DL; i++);
				
				if(i == *nbElemTotal)
					requestID = RID_UPDATE_STATUS;
			}
			
			if(requestID == RID_UPDATE_STATUS)
			{
				if(IDToPosition == NULL)
					break;
					
				for(dataPos = 0; dataPos < *nbElemTotal && *((*status)[(*IDToPosition)[dataPos]]) != MDL_CODE_DEFAULT; dataPos++); //Les éléments peuvent être réorganisés
				
				if(dataPos < *nbElemTotal)
				{
					MDLStartHandler((*IDToPosition)[dataPos], *nbElemTotal, **todoList, status, &historiqueTeam);
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
				for(dataPos = 0; dataPos < *nbElemTotal && *((*status)[(*IDToPosition)[dataPos]]) != MDL_CODE_INSTALL; dataPos++);

				if(dataPos == *nbElemTotal)
				{
					for(dataPos = 0; dataPos < *nbElemTotal && *((*status)[(*IDToPosition)[dataPos]]) != MDL_CODE_DL_OVER; dataPos++);
					
					if(dataPos != *nbElemTotal) //une installation a été trouvée
						*((*status)[(*IDToPosition)[dataPos]]) = MDL_CODE_INSTALL;
				}
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
	for(dataPos = 0; historiqueTeam[dataPos] != NULL; free(historiqueTeam[dataPos++]));
	free(historiqueTeam);
	
	pthread_cond_broadcast(&condResumeExecution);
	pthread_mutex_trylock(&mutexLockMainThread);
	MUTEX_UNLOCK(mutexLockMainThread);

	quit_thread(0);
}

void MDLSetThreadID(THREAD_TYPE *thread)
{
	threadID = thread;
}

void MDLStartHandler(uint posElement, uint nbElemTotal, DATA_LOADED ** todoList, int8_t *** status, char ***historiqueTeam)
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

		MDLUpdateIcons(posElement, todoList[posElement]->rowViewResponsible);
		
		argument->todoList = todoList[posElement];
        argument->currentState = (*status)[posElement];
        argument->historiqueTeam = historiqueTeam;
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
		pthread_cond_wait(&condResumeExecution, &mutexLockMainThread);
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

void MDLUpdateIcons(uint selfCode, void * UIInstance)
{
	if(UIInstance != NULL)
		[(RakMDLListView*) UIInstance performSelectorOnMainThread:@selector(updateContext) withObject:nil waitUntilDone:NO];
	
	else if(mainTab != nil && [mainTab respondsToSelector:@selector(getData::)])
	{
		DATA_LOADED ** todoList = [mainTab getData:selfCode : YES];
		if(todoList != NULL && *todoList != NULL && (*todoList)->rowViewResponsible != NULL)
		{
			[(RakMDLListView *) (*todoList)->rowViewResponsible performSelectorOnMainThread:@selector(updateContext) withObject:nil waitUntilDone:YES];
		}
	}
}

void updatePercentage(void * rowViewResponsible, float percentage, size_t speed)
{
	if(rowViewResponsible != NULL)
	{
		[(RakMDLListView*) rowViewResponsible updatePercentage:percentage :speed];
	}
}

void dataRequireLogin(DATA_LOADED ** data, int8_t ** status, uint * IDToPosition, uint length, void* mainTabController)
{
	bool all = COMPTE_PRINCIPAL_MAIL == NULL;
	
	for(uint pos = 0, index; pos < length; pos++)
	{
		index = IDToPosition[pos];
		
		if(all || (data[index] != NULL && data[index]->datas != NULL && isPaidProject(*data[index]->datas)))
		{
			*(status[index]) = MDL_CODE_WAITING_LOGIN;
		}
	}
	
	RakMDLController * controller = mainTabController;
	
	[controller requestCredentials : !all];
}

//We recycle the MDL_MWORKER_ARG structure
void watcherForLoginRequest(MDL_MWORKER_ARG * arg)
{
	bool *				quit		=	arg->quit;
	RakMDLController *	_mainTab	=	arg->mainTab;
	int8_t ***			status		=	arg->status;
	uint *				nbElemTotal =	arg->nbElemTotal;
	uint **				IDToPosition =	arg->IDToPosition;
	
	free(arg);
	
	MUTEX_VAR lock = PTHREAD_MUTEX_INITIALIZER;
	MUTEX_LOCK(lock);
	
	[_mainTab performSelectorOnMainThread:@selector(setWaitingLogin:) withObject:@(true) waitUntilDone:NO];
	
	while([mainTab areCredentialsComplete])
	{
		pthread_cond_wait([[NSApp delegate] sharedLoginLock], &lock);
	}
	
	[_mainTab performSelectorOnMainThread:@selector(setWaitingLogin:) withObject:@(false) waitUntilDone:NO];
	
	MUTEX_DESTROY(lock);
	
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