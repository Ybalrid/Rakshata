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

@class RakAuthController;

#include "RakAuthTools.h"

@interface RakAuthController : NSViewController
{
	IBOutlet RakView * container;
	IBOutlet RakView * _containerMail;
	IBOutlet RakView * _containerPass;
	
	RakAuthForegroundView * foreground;
	
	//Main view elements
	IBOutlet RakText * header;
	
	IBOutlet RakText * labelMail;
	IBOutlet RakText * labelPass;
	
	RakEmailField * mailInput;
	RakPassField * passInput;
	
	//Container
	RakText * footerPlaceholder;
	
	//Login
	RakButton * forgottenPass, * _login;
	
	//Signup
	RakClickableText * privacy, * terms;
	RakAuthTermsButton * accept;
	RakButton * confirm;
	
	//Data
	byte currentMode;
	BOOL initialAnimation;
	
	CGFloat baseHeight;
	CGFloat baseContainerHeight;
}

@property BOOL postProcessing;
@property BOOL offseted;

- (void) launch;

- (void) wakePassUp;
- (void) validEmail : (BOOL) newAccount : (uint) session;

- (void) switchOver : (NSNumber*) isDisplayed;
- (void) focusLeft : (id) caller : (NSUInteger) flag;

@end
