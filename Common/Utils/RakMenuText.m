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

@implementation RakMenuText

- (instancetype) initWithText : (NSRect) frame : (NSString *) text
{
	_widthGradient = 2 / 3.0f;
	
	self = [super initWithText : [self getMenuFrame : frame] : text : [self getTextColor]];
	if(self != nil)
	{
		self.haveBackgroundColor = YES;
		self.drawGradient = NO;
		
		[Prefs registerForChange:self forType:KVO_THEME];
		[self setFont:[[self class] getFont : [self getFontSize]]];
		[self defineBackgroundColor];
		[self sizeToFit];
	}
	
	return self;
}

- (BOOL) isFlipped
{
	return YES;
}

- (BOOL) mouseDownCanMoveWindow
{
	return YES;
}

- (CGFloat) getTextHeight
{
	return MENU_TEXT_WIDTH;
}

- (NSRect) getMenuFrame : (NSRect) parentFrame
{
	if(self.ignoreInternalFrameMagic)
		return parentFrame;
	
	NSRect frame = parentFrame;
	frame.size.height = [self getTextHeight];
	frame.origin.y = parentFrame.size.height - frame.size.height;
	
	return frame;
}

- (void) setFrame:(NSRect)frameRect
{
	NSRect frame = [self getMenuFrame:frameRect];
	
	frame.origin.x -= 1;	//On retina display, sometimes, 1 pixel (0.5 pt) wide borders may appear
	frame.size.width += 2;
	
	[super setFrame : frame];
	[self updateGradientOrigin : self.bounds.size.width];
}

- (void) resizeAnimation : (NSRect) frameRect
{
	NSRect frame = [self getMenuFrame:frameRect];
	
	frame.origin.x -= 1;
	frame.size.width += 2;
	
	[self setFrameAnimated: frame];
	[self updateGradientOrigin : frame.size.width];
}

- (void) dealloc
{
	[Prefs deRegisterForChange:self forType:KVO_THEME];
	[self removeFromSuperview];
}

#pragma mark - Drawing

- (void) additionalDrawing
{
	NSRect frame = self.bounds;
	
	frame.origin.y = frame.size.height - self.barWidth;
	frame.size.height = self.barWidth;
	
	[[self getBarColor] setFill];
	NSRectFill(frame);
	
	if(_drawGradient)
	{
		frame.size.width /= 3;
		frame.origin.x += _gradientXOrigin;
		[_gradient drawInRect : frame angle : _gradientAngle];
	}
}

#pragma mark - Gradient

- (BOOL) drawGradient
{
	return _drawGradient;
}

- (void) updateGradientOrigin : (CGFloat) width
{
	if(_drawGradient)
	{
		if(self.alignment != NSTextAlignmentRight)
		{
			_gradientXOrigin = width * _widthGradient;
			_gradientAngle = 0;
		}
		else
		{
			_gradientXOrigin = 0;
			_gradientAngle = 180;
		}
	}
}

- (void) setDrawGradient : (BOOL) drawGradient
{
	if(drawGradient == _drawGradient)
		return;
	
	_drawGradient = drawGradient;
	
	if(drawGradient)
	{
		[self updateGradientOrigin : self.bounds.size.width];
		[self generateGradient];
	}
	else
	{
		_gradientBackgroundColor = nil;
		_gradient = nil;
	}
}

- (void) generateGradient
{
	_gradient = [[NSGradient alloc] initWithStartingColor : [RakColor clearColor] endingColor : [self getGradientBackgroundColor]];
}

- (void) setAlignment:(NSTextAlignment)mode
{
	[super setAlignment:mode];
	[self updateGradientOrigin : self.bounds.size.width];
}

- (CGFloat) widthGradient
{
	return _widthGradient;
}

- (void) setWidthGradient : (CGFloat) widthGradient
{
	_widthGradient = widthGradient;
	[self updateGradientOrigin : self.bounds.size.width];
}

#pragma mark - Color

- (RakColor *) getTextColor
{
	return [Prefs getSystemColor:COLOR_INACTIVE];
}

- (RakColor *) getBarColor
{
	return [Prefs getSystemColor:COLOR_COREVIEW_BORDER];
}

- (RakColor *) getBackgroundColor
{
	if(_haveBackgroundColor)
		return [Prefs getSystemColor:COLOR_TABS_BACKGROUND];
	
	return nil;
}

- (RakColor *) getGradientBackgroundColor
{
	return [self getBackgroundColor];
}

- (CGFloat) getFontSize
{
	return 16;
}

+ (NSFont *) getFont : (CGFloat) fontSize;
{
	return [Prefs getFont:FONT_TITLE ofSize:fontSize];
}

- (void) defineBackgroundColor
{
	RakColor * background = [self getBackgroundColor];
	
	if(background != nil)
	{
		[self setBackgroundColor:background];
		[self setDrawsBackground:YES];
	}
	else
	{
		[self setBackgroundColor:[RakColor clearColor]];
		[self setDrawsBackground:NO];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([object class] != [Prefs class])
		return;
	
	[self setTextColor:[self getTextColor]];
	[self defineBackgroundColor];
	[self generateGradient];
	
	[self setNeedsDisplay:YES];
}

#pragma mark - Background

- (void) setHaveBackgroundColor:(BOOL)haveBackgroundColor
{
	if(haveBackgroundColor != _haveBackgroundColor)
	{
		_haveBackgroundColor = haveBackgroundColor;
		[self defineBackgroundColor];
	}
}

- (BOOL) haveBackgroundColor
{
	return _haveBackgroundColor;
}

#pragma mark - barWidth

- (void) setBarWidth : (CGFloat) barWidth
{
	_barWidthInitialized = YES;
	_barWidth = barWidth;
}

- (CGFloat) barWidth
{
	if(!_barWidthInitialized)
	{
		_barWidthInitialized = YES;
		_barWidth = 2;
	}
	
	return _barWidth;
}

@end
