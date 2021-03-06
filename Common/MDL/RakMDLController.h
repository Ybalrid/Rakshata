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

#define MDLCTRL_getDataFull(data, index, isTome)		ACCESS_CT(isTome, data.chaptersFull, data.volumesFull, index)
#define MDLCTRL_getDataInstalled(data, index, isTome)	ACCESS_CT(isTome, data.chaptersInstalled, data.volumesInstalled, index)

@interface RakMDLController : NSObject
{
	MDL* __weak _tabMDL;
	
	PROJECT_DATA ** cache;
	uint sizeCache;
	
	THREAD_TYPE coreWorker;
	DATA_LOADED *** todoList;
	uint	* IDToPosition;
	int8_t ** status;

	uint nbElem;
	uint discardedCount;

	bool quit;
	
	//Credential request
	BOOL requestForPurchase;
}

@property RakMDLList * __weak list;
@property BOOL requestCredentials;
@property (readonly) BOOL isSerieMainThread;

- (instancetype) init : (MDL *) tabMDL : (NSString *) state;

- (void) needToQuit;
- (NSString *) serializeData;

- (uint) getNbElem : (BOOL) considerDiscarded;
- (uint) getNbElemToProcess;
- (DATA_LOADED **) getData : (uint) row;
- (DATA_LOADED **) getData : (uint) row  bypassDiscarded : (BOOL) bypassDiscarded;

- (int8_t) statusOfID : (uint) row;
- (int8_t) statusOfID : (uint) row bypassDiscarded : (BOOL) bypassDiscarded;
- (void) discardInstalled;
- (void) setStatusOfID : (uint) row bypassDiscarded : (BOOL) bypassDiscarded withValue: (int8_t) value;
- (void) removingEmailAddress;
- (void) addElement : (uint) cacheDBID : (BOOL) isTome : (uint) element : (BOOL) partOfBatch;
- (uint) addBatch : (PROJECT_DATA) data : (BOOL) isTome : (BOOL) launchAtTheEnd;
- (void) reorderElements : (uint) posStart : (uint) posEnd : (uint) injectionPoint;
- (BOOL) checkForCollision : (PROJECT_DATA) data : (BOOL) isTome : (uint) element;
- (void) discardElement : (uint) element withSimilar: (BOOL) similar;

- (BOOL) areCredentialsComplete;
- (RakTabForegroundView *) getForegroundView;
- (void) setWaitingLogin : (NSNumber *) request;

- (void) collapseStateUpdate : (BOOL) wantCollapse;

@end
