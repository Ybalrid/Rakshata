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

@class PrefsUI;

#import "RakSRRessources.h"

@interface Series : RakTabView
{
	RakSRHeader * header;
	RakSRSearchTab * searchTab;
	
	RakSerieView * coreView;
}

- (instancetype) init : (RakView*)contentView : (NSString *) state;
- (CGFloat) getHeightOfMainView;

@end

enum
{
	SR_PREF_BUTTON_BORDERS = 25,
	SR_HEADER_INTERBUTTON_WIDTH = 10,
	
	SR_READERMODE_LATERAL_BORDER = 5,
	
	SR_READERMODE_MARGIN_ELEMENT_OUTLINE = 8,
	SR_READERMODE_MARGIN_OUTLINE = 7,
	SR_READERMODE_LBWIDTH_OUTLINE = 10,		//LB = Line Break
	SR_READERMODE_ILBWIDTH_OUTLINE = 13		//ILB = Intermediary LB
};
