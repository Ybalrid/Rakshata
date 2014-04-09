/*********************************************************************************************
 **	__________         __           .__            __                 ________   _______   	**
 **	\______   \_____  |  | __  _____|  |__ _____ _/  |______   	___  _\_____  \  \   _  \  	**
 **	 |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \  	\  \/ //  ____/  /  /_\  \ 	**
 **	 |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \__ \   //       \  \  \_/   \	**
 **	 |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /	  \_/ \_______ \ /\_____  /	**
 **	        \/      \/     \/     \/     \/     \/          \/ 	              \/ \/     \/ 	**
 **                                                                                         **
 **    Licence propriétaire, code source confidentiel, distribution formellement interdite  **
 **                                                                                         **
 ********************************************************************************************/

@interface RakTextProjectName : RakMenuText

@end

@interface RakCTProjectImageView : NSImageView

- (id) initWithImageName : (NSString *) imageName : (NSRect) superViewFrame;
- (NSRect) getProjectImageSize : (NSRect) superViewFrame : (NSSize) imageSize;

@end

@interface RakCTContentTabView : NSView
{
	MANGAS_DATA data;
	RakCTCoreViewButtons * buttons;
	RakCTCoreContentView * tableViewControllerChapter;
	RakCTCoreContentView * tableViewControllerVolume;
}

- (id) initWithProject : (MANGAS_DATA) project : (bool) isTome : (NSRect) frame : (long [4]) context;
- (void) switchIsTome : (RakCTCoreViewButtons*) sender;
- (void) gotClickedTransmitData : (bool) isTome : (uint) index;

- (NSString *) getContextToGTFO;

@end

@interface RakChapterView : RakTabContentTemplate
{
	RakTextProjectName *projectName;
	RakCTProjectImageView * projectImage;
	RakCTContentTabView * coreView;
}

- (id)initContent:(NSRect)frame : (MANGAS_DATA) project : (bool) isTome : (long [4]) context;

@end
