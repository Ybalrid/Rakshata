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

@interface RakSRHeaderText : RakMenuText

@end

@interface RakSRSubMenu : RakMenuText

@end

@interface RakTableRowView : NSTableRowView
{
	BOOL haveForcedWidth;
}

@property BOOL drawBackground;
@property (nonatomic) CGFloat forcedWidth;

@end

#import "RakButtonMorphic.h"

#import "RakSRSearchBar.h"
#import "RakSRTagRail.h"
#import "RakSRHeader.h"
#import "RakSRSearchTab.h"

@class RakSRContentManager;

#import "RakGridView.h"

#import "RakSRContentManager.h"

#import "RakSerieMainList.h"
#import "RakSerieList.h"

#import "RakSerieView.h"
