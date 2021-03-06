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

@implementation RakAppiOSDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[self awakeFromNib];
	
	NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
	if(url != nil)
		[self application:application openURL:url sourceApplication:nil annotation:nil];
	
#ifdef DEV_VERSION
	if(checkDirExist("Inbox"))
	{
		//Check if we don't have a file to load, simplify import module dev
		NSError * error = nil;
		NSArray * array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"Inbox/" error:&error];
		if(array != nil && [array count] != 0 && error == nil)
		{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[self application:application
						  openURL:[NSURL URLWithString:[NSString stringWithFormat:@"Inbox/%@", [array firstObject]]]
				sourceApplication:nil
					   annotation:nil];
			});
		}
		else if(error != nil)
			NSLog(@"Error in early loading: %@", error);
	}
#endif
	
	return YES;
}

- (BOOL) hasFocus
{
	return RakRealApp.applicationState != UIApplicationStateBackground;
}

- (void) applicationWillTerminate:(UIApplication *)application
{
	[self flushState];
}

#pragma mark - Register the tabs controller

- (void) registerTabBarController : (UITabBarController *) _tabBarController
{
	if(tabBarController == nil)
	{
		tabBarController = _tabBarController;
		tabBarController.delegate = self;
	}
}

- (void) registerSeries : (Series *) series
{
	if(tabSerie == nil)
		tabSerie = series;
}

- (Series *) _serie
{
	if(tabSerie == nil)
	{
		UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
		if(storyboard != nil)
			[storyboard instantiateViewControllerWithIdentifier:@"SR"];
	}
	
	return [super _serie];
}

- (void) registerCT : (CTSelec *) CT
{
	if(tabCT == nil)
		tabCT = CT;
}

- (CTSelec *) _CT
{
	if(tabCT == nil)
	{
		UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
		if(storyboard != nil)
			[storyboard instantiateViewControllerWithIdentifier:@"CT"];
	}
	
	return [super _CT];
}

- (void) registerMDL : (RakMDLCoreController *) MDL
{
	if(tabMDL == nil)
		tabMDL = MDL;
}

- (MDL *) _MDL
{
	if(tabMDL == nil)
	{
		UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
		if(storyboard != nil)
			[storyboard instantiateViewControllerWithIdentifier:@"MDL"];
	}

	return [super _MDL];
}

- (void) registerReader : (Reader *) reader
{
	if(tabReader == nil)
		tabReader = reader;
}

- (Reader *) _reader
{
	if(tabReader == nil)
	{
		UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
		if(storyboard != nil)
			[storyboard instantiateViewControllerWithIdentifier:@"RD"];
	}

	return [super _reader];
}

#pragma mark - Tab bar controller

- (UITabBarController *) tabBarController
{
	return tabBarController;
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
	//Warn the RakTabView that it's about to be selected
#if 0
	if([viewController isKindOfClass:[UINavigationController class]])
		viewController = [((UINavigationController *) viewController).viewControllers firstObject];
#endif
	
	if([viewController isKindOfClass:[RakTabView class]])
	{
		[(RakTabView *) viewController viewWillFocus];
		return !((RakTabView *) viewController).initWithNoContent;
	}
	
	return YES;
}

#pragma mark - Extension handling

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	RakImportBaseController <RakImportIO> * IOController = createIOForFilename([url path]);
	
	if(IOController != nil)
	{
		_currentImportURL = url;
		[RakImportController importFile:@[IOController]];
	}
	
	return YES;
}

@end
