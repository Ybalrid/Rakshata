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

#import "RakWindow.h"

#import "RakTextCell.h"
#import "RakButton.h"
#import "RakScroller.h"
#import "RakBorder.h"
#import "RakText.h"
#import "RakSegmentedButtonCell.h"
#import "RakMenuText.h"
#import "RakProgressBar.h"
#import "RakBackButton.h"
#import "RakPopover.h"

#import "RakForegroundView.h"
#import "RakTabView.h"
#import "RakTabContentTemplate.h"
#import "RakDragView.h"
#import "RakDragItem.h"
#import "RakDragResponder.h"
#import "RakList.h"

#define NSCenteredRect(base, content) NSMakePoint(base.size.width / 2 - content.size.width / 2, base.size.height / 2 - content.size.height / 2)
#define NSCenteredViews(parent, subview) NSCenteredRect(parent.bounds, subview.bounds)