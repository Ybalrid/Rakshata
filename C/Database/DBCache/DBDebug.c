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

#include "dbCache.h"

sqlite3_stmt * createRequest(sqlite3 *db, const char *zSql)
{
	if(db == NULL)
		return NULL;

	sqlite3_stmt *ppStmt = NULL;

	int output = sqlite3_prepare_v2(db, zSql, -1, &ppStmt, NULL);
	
#ifdef VERBOSE_REQUEST
	printf("Creating request %p with `%s` (status: %d)\n", ppStmt, zSql, output);
#endif
	
#ifdef EXTENSIVE_LOGGING
	if(output != SQLITE_OK && ppStmt == NULL)
	{
		printf("Failed at creating request for %s (status: %d)\nError: %s", zSql, output, sqlite3_errmsg(db));
	}
#endif

	if(output != SQLITE_OK && ppStmt != NULL)
	{
		destroyRequest(ppStmt);
		ppStmt = NULL;
	}

	return ppStmt;
}

int destroyRequest(sqlite3_stmt *pStmt)
{
	int output;

	if(pStmt != NULL)
		output = sqlite3_finalize(pStmt);
	else
		output = SQLITE_ABORT;
	
#ifdef VERBOSE_REQUEST
	printf("Finalizing request %p (status: %d)\n", pStmt, output);
#endif
	
	return output;
}

#ifdef EXTENSIVE_LOGGING

void errorLogCallback(void *pArg, int iErrCode, const char *zMsg)
{
	fprintf(stderr, "(%d) %s\n", iErrCode, zMsg);
}

#endif
