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
 ********************************************************************************************/

enum
{
	THUMBVIEW_CLICK_PROJECT = 1,
	THUMBVIEW_CLICK_AUTHOR,
	THUMBVIEW_CLICK_TAG,
	THUMBVIEW_CLICK_CAT,
	THUMBVIEW_CLICK_NONE	
};

@interface RakBasicProjectView : RakView
{
	PROJECT_DATA _project;
	NSRect _workingArea;
	
	BOOL _animationRequested, registerdPref;
	
	NSImageView * thumbnail;
	RakText * projectName, * projectAuthor;
}

@property (readonly) uint elementID;
@property (readonly) NSRect workingArea;
@property NSDictionary * insertionPoint;

- (instancetype) initWithProject : (PROJECT_DATA) project;
- (instancetype) initWithProject : (PROJECT_DATA) project withInsertionPoint : (NSDictionary *) insertionPoint;

- (void) initContent;
- (void) updateProject : (PROJECT_DATA) project;
- (void) updateProject : (PROJECT_DATA) project withInsertionPoint : (NSDictionary *) insertionPoint;

- (RakText *) getTextElement : (NSString *) string : (RakColor *) color : (byte) fontCode : (CGFloat) fontSize;

- (RakColor *) getTextColor;
- (RakColor *) getTagTextColor;
- (RakColor *) backgroundColor;
- (void) reloadColors;

- (NSSize) defaultWorkingSize;

- (NSSize) thumbSize;
- (NSPoint) originOfThumb : (NSRect) frameRect;
- (NSPoint) originOfName : (NSRect) frameRect : (NSPoint) thumbOrigin;
- (NSPoint) originOfAuthor : (NSRect) frameRect : (NSPoint) nameOrigin;

- (NSPoint) resizeContent : (NSSize) newSize : (BOOL) animated;
- (NSPoint) reloadOrigin;

@end

@interface RakThumbProjectView : RakBasicProjectView
{
	RakText * typeProject, * tagProject;
}

@property (nonatomic) BOOL mustHoldTheWidth;
@property byte reason;

@property id controller;
@property SEL clickValidation;	//Expect a selector that looks like - (BOOL) receiveClick : (RakThumbProjectView *) project forClick : (byte) selection

- (instancetype) initWithProject:(PROJECT_DATA)project reason : (byte) reason insertionPoint : (NSDictionary *) insertionPoint;
- (void) updateProject : (PROJECT_DATA) project insertionPoint : (NSDictionary *) insertionPoint;

- (CGFloat) getMinimumHeight;
- (RakColor *) borderColor;

@end

