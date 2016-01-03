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

@implementation RakTabView

- (void) awakeFromNib
{
	[self configureView];
	[RakApp registerTabBarController:self.tabBarController];
}

- (void) setInitWithNoContent:(BOOL)initWithNoContent
{
	[super setInitWithNoContent:initWithNoContent];
	[self.tabBarItem setEnabled:!initWithNoContent];
}

#pragma mark - Transition

- (void) viewWillFocus
{
	
}

- (void) didTransition
{
	
}

- (void) initiateTransition
{
	UITabBarController * tabBarController = [RakApp tabBarController];
	
	if(tabBarController.selectedIndex == tabBarIndex)
		return;
	
	if(!alreadyOpenedOnce)
	{
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		NSUInteger oldSelectedIndex = tabBarController.selectedIndex;
		tabBarController.selectedIndex = tabBarIndex;
		tabBarController.selectedIndex = oldSelectedIndex;
		[CATransaction commit];
		alreadyOpenedOnce = YES;
	}
	
	RakTabView * toController = tabBarController.viewControllers[tabBarIndex];
	UIView * fromView = tabBarController.selectedViewController.view, * toView = toController.view;
	
	[toController viewWillFocus];
	
	// Get the size of the view area.
	CGRect viewSize = fromView.frame, newView = toView.frame, workingFrame = newView;
	BOOL scrollRight = tabBarIndex > tabBarController.selectedIndex;
	const CGFloat windowWidth = scrollRight ? viewSize.size.width : -viewSize.size.width;
	
	// Add the to view to the tab bar view.
	[fromView.superview addSubview:toView];
	
	// Position it off screen.
	if(!alreadyOpenedOnce)
		workingFrame.origin.y = 20;
	
	workingFrame.origin.x += windowWidth;
	toView.frame = workingFrame;
	workingFrame.origin.x -= windowWidth;
	
	[UIView animateWithDuration:0.3
					 animations: ^{
						 // Animate the views on and off the screen. This will appear to slide.
						 fromView.frame = CGRectMake(-windowWidth, viewSize.origin.y, windowWidth, viewSize.size.height);
						 toView.frame = workingFrame;
					 }
	 
					 completion:^(BOOL finished) {
						 if (finished)
						 {
							 // Remove the old view from the tabbar view.
							 toView.frame = newView;
							 [fromView removeFromSuperview];
							 tabBarController.selectedIndex = tabBarIndex;
							 [self didTransition];
						 }
					 }];
}

#pragma mark - Compatibility layer

- (CGRect) frame
{
	return self.view.frame;
}

- (CGRect) bounds
{
	return self.view.bounds;
}

@end
