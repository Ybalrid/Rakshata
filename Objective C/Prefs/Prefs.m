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
 ********************************************************************************************/

Prefs * __strong prefsCache;

// Contexte
static uint mainThread = TAB_SERIES;
static uint stateTabsReader = STATE_READER_TAB_DEFAULT;
static bool favoriteAutoDL = true;
static byte activePrefsPanel = PREFS_BUTTON_CODE_DEFAULT;

enum
{
	SERIESMODE_MAX_WIDTH_WHEN_INACTIVE = 225,
	READERMODE_MAX_WIDTH_WHEN_INACTIVE = 320
};

@implementation Prefs

+ (void) initCache
{
	[self initCache:nil];
}

+ (void) initCache : (NSString *) data
{
	if(prefsCache == nil)
		prefsCache = [[Prefs alloc] init : data];
	
	else if(data != nil)
		[prefsCache updateContext:data];
	
	((RakAppDelegate *) [NSApp delegate]).haveDistractionFree = mainThread == TAB_READER;
}

+ (NSString *) dumpPrefs
{
	return prefsCache != nil ? [prefsCache dumpPrefs] : nil;
}

+ (void) deletePrefs
{
	prefsCache = nil;
}

+ (uint) getCurrentTheme : (id) registerForChanges
{
	if(prefsCache == nil)
		[self initCache];
	
	if(registerForChanges != nil)
	{
		[prefsCache addObserver:registerForChanges forKeyPath:@"themeCode" options:NSKeyValueObservingOptionNew context:nil];
	}
	
	return prefsCache.themeCode;
}

+ (void) deRegisterForChanges : (id) object
{
	if(prefsCache != nil && object != nil)
	{
		[prefsCache removeObserver:object forKeyPath:@"themeCode"];
	}
}

+ (void) setCurrentTheme : (uint) newTheme
{
	if(prefsCache == nil)
		[self initCache];
	
	if(prefsCache.themeCode == newTheme)
		return;
	
	prefsCache.themeCode = newTheme;
	
	RakAppDelegate * core = [NSApp delegate];
	if([core class] == [RakAppDelegate class] && [core.window.contentView class] == [RakContentViewBack class])
		[(RakContentViewBack*) core.window.contentView updateUI];
}

+ (NSColor*) getSystemColor : (byte) context : (id) senderToRegister
{
	switch ([self getCurrentTheme : senderToRegister])
	{
		case THEME_CODE_DARK:
			return [self getColorDarkTheme : context];
			
		case THEME_CODE_LIGHT:
			return [self getColorLightTheme : context];
	}
	return nil;
}

+ (NSColor*) getColorDarkTheme : (byte) context
{
	NSColor* output = nil;
	switch (context)
	{
		case COLOR_EXTERNALBORDER_FAREST:
		{
			output = [NSColor colorWithDeviceWhite:20/255.0f alpha:1.0];
			break;
		}
		case COLOR_EXTERNALBORDER_MIDDLE:
		case COLOR_BACKGROUND_REPO_LIST:
		{
			output = [NSColor colorWithDeviceWhite:32/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_EXTERNALBORDER_MIDDLE_NON_MAIN:
		{
			output = [NSColor colorWithDeviceWhite:40/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_EXTERNALBORDER_CLOSEST:
		{
			output = [NSColor colorWithDeviceWhite:50/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_INACTIVE:
		case COLOR_BORDERS_COREVIEWS:
		case COLOR_TEXT_CT_SELECTOR_UNAVAILABLE:
		case COLOR_FONT_BUTTON_UNAVAILABLE:
		case COLOR_SEARCHTAB_BORDER_BAR:
		case COLOR_BACKGROUND_SWITCH_BUTTON_ON:
		{
			output = [NSColor colorWithSRGBRed:78/255.0f green:118/255.0f blue:143/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_SURVOL:
		case COLOR_TEXT_CT_SELECTOR_NONCLICKED:
		case COLOR_FONT_BUTTON_NONCLICKED:
		case COLOR_SEARCHBAR_SELECTION_TEXT:
		{
			output = [NSColor colorWithSRGBRed:102/255.0f green:149/255.0f blue:176/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_ACTIVE:
		case COLOR_TEXT_CT_SELECTOR_CLICKED:
		case COLOR_FONT_BUTTON_CLICKED:
		case COLOR_PROGRESSCIRCLE_PROGRESS:
		{
			output = [NSColor colorWithSRGBRed:159/255.0f green:202/255.0f blue:227/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_TAGITEM_FONT:
		{
			output = [NSColor colorWithSRGBRed:61/255.0f green:119/255.0f blue:152/255.0f alpha:1];
			break;
		}
			
		case COLOR_CLICKABLE_TEXT:
		{
			output = [NSColor colorWithSRGBRed:227/255.0f green:227/255.0f blue:216/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_INSERTION_POINT:
		{
			output = [NSColor colorWithDeviceWhite:200/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_SEARCHBAR_SELECTION_BACKGROUND:
		{
			output = [NSColor colorWithDeviceWhite:222/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_SEARCHBAR_BACKGROUND:
		{
			output = [NSColor colorWithDeviceWhite:25/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_SEARCHBAR_BORDER:
		{
			output = [NSColor colorWithSRGBRed:227/255.0f green:227/255.0f blue:216/255.0f alpha:0.2];
			break;
		}
			
		case COLOR_SEARCHBAR_PLACEHOLDER_TEXT:
		{
			output = [NSColor colorWithSRGBRed:146/255.0f green:146/255.0f blue:141/255.0f alpha:0.4];
			break;
		}
			
		case COLOR_READER_BAR:
		{
			output = [NSColor colorWithDeviceWhite:20/255.0f alpha:0.8];
			break;
		}
		case COLOR_READER_BAR_FRONT:
		case COLOR_TAGITEM_BORDER:
		{
			output = [NSColor colorWithDeviceWhite:75/255.0f alpha:0.8];
			break;
		}
			
		case COLOR_READER_BAR_PAGE_COUNTER:
		{
			output = [NSColor colorWithDeviceWhite:25/255.0f alpha:0.3f];
			break;
		}
			
		case COLOR_BACKGROUND_READER_INTAB:
		case COLOR_TITLEBAR_BACKGROUND_MAIN:
		case COLOR_BACKGROUND_DRAG_AND_DROP:
		{
			output = [NSColor colorWithDeviceWhite:42/255.0f alpha:1.0];
			break;
		}
		case COLOR_BACKGROUND_TABS:
		case COLOR_BACKGROUND_REPO_LIST_ITEM:
		case COLOR_BACKGROUND_PREFS_HEADER:
		{
			output = [NSColor colorWithDeviceWhite:47/255.0f alpha:1.0];
			break;
		}
		case COLOR_BORDER_TABS:
		case COLOR_TITLEBAR_BACKGROUND_STANDBY:
		case COLOR_TITLEBAR_BACKGROUND_GRADIENT_END:
		{
			output = [NSColor colorWithDeviceWhite:52/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_BACKGROUND_BACK_BUTTONS:
		case COLOR_TITLEBAR_BACKGROUND_GRADIENT_START:
		{
			output = [NSColor colorWithDeviceWhite:39/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_BACKGROUND_BACK_BUTTONS_ANIMATING:
		{
			output = [NSColor colorWithSRGBRed:104/255.0f green:150/255.0f blue:176/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_BACKGROUND_COREVIEW:
		case COLOR_TAGITEM_BACKGROUND:
		case COLOR_SEARCHTAB_BACKGROUND:
		{
			output = [NSColor colorWithDeviceWhite:34/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_SEARCHTAB_BORDER_COLLAPSED:
		{
			output = [NSColor colorWithSRGBRed:52/255.0f green:83/255.0f blue:102/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_SEARCHTAB_BORDER_DEPLOYED:
		{
			output = [NSColor colorWithSRGBRed:44/255.0f green:71/255.0f blue:88/255.0f alpha:1.0];
			break;
		}
			
			//To improve
		case COLOR_BACKGROUND_CT_TVCELL:
		{
			output = [NSColor colorWithDeviceWhite:44/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_PROGRESSCIRCLE_SLOT:
		{
			output = [NSColor colorWithDeviceWhite:192/255.0f alpha:0.5];
			break;
		}
			
		case COLOR_BORDER_BUTTONS:
		{
			output = [NSColor colorWithDeviceWhite:32.0f/255.0f alpha:1.0f];
			break;
		}
			
		case COLOR_BACKGROUND_BUTTON_UNSELECTED:
		{
			output = [NSColor colorWithDeviceWhite:39.0f/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_BACKGROUND_BUTTON_SELECTED:
		{
			output = [NSColor colorWithDeviceWhite:44.0f/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_FILTER_FORGROUND:
		{
			output = [NSColor colorWithDeviceWhite:15/255.0f alpha:0.7f];
			break;
		}
			
		case COLOR_DANGER_POPOVER_BORDER:
		{
			output = [NSColor colorWithSRGBRed:255/255.0f green:38/255.0f  blue:0 alpha:1.0];
			break;
		}
			
		case COLOR_DANGER_POPOVER_TEXT_COLOR:
		{
			output = [NSColor colorWithSRGBRed:224/255.0f green:83/255.0f blue:83/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_DANGER_POPOVER_TEXT_COLOR_SELECTED:
		{
			output = [NSColor colorWithSRGBRed:255/255.0f green:148/255.0f blue:148/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_BACKGROUND_TEXTFIELD:
		{
			output = [NSColor blackColor];
			break;
		}
			
		case COLOR_CTHEADER_GRADIENT_START:
		{
			output = [NSColor colorWithDeviceWhite:0 alpha:0.7f];
			break;
		}
			
		case COLOR_CTHEADER_GRADIENT_END:
		{
			output = [NSColor colorWithDeviceWhite:0 alpha:0.4f];
			break;
		}
			
		case COLOR_SRPLACEHOLDER_TEXT:
		{
			output = [NSColor colorWithSRGBRed:27/255.0f green:162/255.0f blue:249/255.0f alpha:0.65];
			break;
		}
			
		case COLOR_CTHEADER_FONT:
		{
			output = [NSColor colorWithDeviceWhite:1 alpha:1];
			break;
		}
			
		case COLOR_BACKGROUND_GRID_FOCUS:
		{
			output = [NSColor colorWithDeviceWhite:50/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_PREFS_BUTTONS_FOCUS:
		{
			output = [NSColor colorWithDeviceWhite:65/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_BORDER_PREFS_HEADER:
		{
			output = [NSColor colorWithDeviceWhite:70/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_PLACEHOLDER_REPO:
		{
			output = [NSColor colorWithDeviceWhite:200 alpha:0.7];
			break;
		}
			
		case COLOR_BACKGROUND_ADD_REPO:
		{
			output = [NSColor colorWithDeviceWhite:60/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_BACKGROUND_SWITCH_BUTTON_OFF:
		{
			output = [NSColor colorWithDeviceWhite:58/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_BACKGROUND_SWITCH_BUTTON_MIXED:
		{
			output = [NSColor colorWithSRGBRed:90/255.0f green:136/255.0f blue:165/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_BORDER_SWITCH_BUTTON:
		{
			output = [NSColor colorWithDeviceWhite:148/255.0f alpha:1.0];
			break;
		}
			
		case COLOR_BACKGROUND_CT_LIST:
		{
			output = [NSColor colorWithDeviceWhite:28/255.0f alpha:1.0];
			break;
		}
	}
	
	return output;
}

+ (NSColor*) getColorLightTheme : (byte) context
{
	NSColor * output = nil;
	
	switch (context)
	{
		default:
			output = [NSColor colorWithDeviceWhite:0 alpha:0];
	}
	
	return output;
}

+ (NSString *) getFontName : (byte) context
{
	NSString * output = nil;
	
	switch (context)
	{
		case GET_FONT_TITLE:
		{
			output = @"Futura";
			break;
		}
		case GET_FONT_STANDARD:
		{
			output = @"Helvetica";
			break;
		}
		case GET_FONT_TAGS:
		case GET_FONT_PLACEHOLDER:
		{
			output = @"Helvetica-Oblique";
			break;
		}
		case GET_FONT_RD_BUTTONS:
		case GET_FONT_SR_TITLE:
		case GET_FONT_ABOUT:
		case GET_FONT_PREFS_TITLE:
		{
			output = @"Helvetica-Bold";
			break;
		}
	}
	
	return output;
}

+ (void) getPref : (int) requestID : (void*) outputContainer
{
	[self getPref : requestID : outputContainer : NULL];
}

+ (void) getPref : (int) requestID : (void*) outputContainer : (void*) additionalData
{
	if(prefsCache == NULL)
		[self initCache];
	
	[prefsCache getPrefInternal : requestID : outputContainer : additionalData];
}

- (void) getPrefInternal : (int) requestID : (void*) outputContainer : (void*) additionalData
{
	if (outputContainer == NULL)
		return;
	
	switch(requestID)
	{
		case PREFS_GET_MAIN_THREAD:
		{
			int* output = outputContainer;
			*output = mainThread;
			break;
		}
			
		case PREFS_GET_TAB_SERIE_WIDTH:
		{
			CGFloat * output = outputContainer;
			*output = [tabSerieSize getDataTab: mainThread : stateTabsReader].size.width;
			
			if(additionalData != NULL)
			{
				*output = percToSize(*output, (*(NSSize *) additionalData).width, mainThread != TAB_SERIES ? READERMODE_MAX_WIDTH_WHEN_INACTIVE : -1);
				
				//The CT tab may be reduced, so we need to keep that in mind when defining our width
				if(mainThread == TAB_SERIES)
				{
					CGFloat width = 0;
					[self getPrefInternal:PREFS_GET_TAB_CT_WIDTH :&width :NULL];
					
					width = percToSize(width, (*(NSSize *) additionalData).width, -1);
					if(width > SERIESMODE_MAX_WIDTH_WHEN_INACTIVE)
						*output += width - SERIESMODE_MAX_WIDTH_WHEN_INACTIVE;
				}
			}
			
			break;
		}
			
		case PREFS_GET_TAB_CT_WIDTH:
		{
			CGFloat * output = outputContainer;
			*output = [tabCTSize getDataTab: mainThread : stateTabsReader].size.width;
			
			if(additionalData != NULL)
				*output = percToSize(*output, (*(NSSize *) additionalData).width, mainThread == TAB_READER ? READERMODE_MAX_WIDTH_WHEN_INACTIVE : (mainThread == TAB_SERIES ? SERIESMODE_MAX_WIDTH_WHEN_INACTIVE : -1));
			
			break;
		}
			
		case PREFS_GET_TAB_CT_POSX:
		{
			if(mainThread == TAB_READER && stateTabsReader & (STATE_READER_TAB_SERIE_FOCUS | STATE_READER_TAB_MDL_FOCUS))
			{
				[self getPrefInternal:PREFS_GET_TAB_SERIE_WIDTH :outputContainer :additionalData];
			}
			else
			{
				NSRect frame = [tabCTSize getDataTab: mainThread : stateTabsReader];
				CGFloat * output = outputContainer;
				*output = frame.origin.x;
				
				if(additionalData != NULL)
				{
					*output = percToSize(*output, (*(NSSize *) additionalData).width, -1);
					
					if(mainThread == TAB_SERIES)
					{
						frame.size.width = percToSize(frame.size.width, (*(NSSize *) additionalData).width, -1);
						if(frame.size.width > SERIESMODE_MAX_WIDTH_WHEN_INACTIVE)
							*output += frame.size.width - SERIESMODE_MAX_WIDTH_WHEN_INACTIVE;
					}
				}
			}
			break;
		}
			
		case PREFS_GET_TAB_READER_POSX:
		{
			//Classical code
			CGFloat * output = outputContainer;
			*output = [tabReaderSize getDataTab: mainThread : stateTabsReader].origin.x;
			
			if(additionalData == NULL)
				break;
			
			*output = percToSize(*output, (*(NSSize *) additionalData).width, -1);
			
			//Reader position is highly dependant of the width of either SER/CT tabs, we need to check we're not impacted if they were maximized
			if(mainThread == TAB_READER && stateTabsReader & STATE_READER_NONE_COLLAPSED)
			{
				CGFloat data, percentage;
				
				if(stateTabsReader & (STATE_READER_TAB_SERIE_FOCUS | STATE_READER_TAB_MDL_FOCUS))
				{
					[self getPrefInternal:PREFS_GET_TAB_SERIE_WIDTH : &data : additionalData];
					if(data == READERMODE_MAX_WIDTH_WHEN_INACTIVE)	//Maximized
					{
						[self getPrefInternal : PREFS_GET_TAB_SERIE_WIDTH : &percentage : NULL];	//We get the real percentage
						*output -= percToSize(percentage, (*(NSSize *) additionalData).width, -1) - data;	//We reduced our base position by the diff between the real width, and the minimized
					}
				}
				
				//The same code for CT tab
				if(stateTabsReader & STATE_READER_TAB_CT_FOCUS)
				{
					[self getPrefInternal:PREFS_GET_TAB_CT_WIDTH : &data : additionalData];
					if(data == READERMODE_MAX_WIDTH_WHEN_INACTIVE)	//Maximized
					{
						[self getPrefInternal : PREFS_GET_TAB_CT_WIDTH : &percentage : NULL];
						*output -= percToSize(percentage, (*(NSSize *) additionalData).width, -1) - data;
					}
				}
			}
			
			break;
		}
			
		case PREFS_GET_CT_FOOTER_HEIGHT:
		{
			CGFloat *output = outputContainer;
			*output = [tabCTSize getFooterHeight];
			
			if(additionalData != NULL)
				*output = percToSize(*output, (*(NSSize *) additionalData).height, -1);
			
			break;
		}
			
		case PREFS_GET_READER_FOOTER_HEIGHT:
		{
			CGFloat *output = outputContainer;
			*output = [tabReaderSize getFooterHeight];
			
			if(additionalData != NULL)
				*output = percToSize(*output, (*(NSSize *) additionalData).height, -1);
			
			break;
		}
			
		case PREFS_GET_TAB_SERIE_FRAME:
		{
			NSRect data = [tabSerieSize getDataTab: mainThread : stateTabsReader];
			*(NSRect *) outputContainer = additionalData == NULL ? data : prefsPercToFrame(data, *(NSSize*) additionalData);
			
			if(mainThread == TAB_READER && additionalData != NULL && ((NSRect*) outputContainer)->size.width > READERMODE_MAX_WIDTH_WHEN_INACTIVE)
				((NSRect*) outputContainer)->size.width = READERMODE_MAX_WIDTH_WHEN_INACTIVE;
			
			else if(mainThread == TAB_SERIES && additionalData != NULL)
				[self getPrefInternal : PREFS_GET_TAB_SERIE_WIDTH : &(((NSRect *)outputContainer)->size.width) : additionalData];
			
			break;
		}
			
		case PREFS_GET_TAB_CT_FRAME:
		{
			NSRect data = [tabCTSize getDataTab: mainThread : stateTabsReader];
			*(NSRect *) outputContainer = additionalData == NULL ? data : prefsPercToFrame(data, *(NSSize*) additionalData);
			
			if(mainThread == TAB_READER && additionalData != NULL && ((NSRect*) outputContainer)->size.width > READERMODE_MAX_WIDTH_WHEN_INACTIVE)
			{
				((NSRect*) outputContainer)->size.width = READERMODE_MAX_WIDTH_WHEN_INACTIVE;
				[self getPrefInternal : PREFS_GET_TAB_CT_POSX : &(((NSRect *)outputContainer)->origin.x) : additionalData];
			}
			else if(mainThread == TAB_SERIES && additionalData != NULL && ((NSRect*) outputContainer)->size.width > SERIESMODE_MAX_WIDTH_WHEN_INACTIVE)
			{
				((NSRect*) outputContainer)->size.width = SERIESMODE_MAX_WIDTH_WHEN_INACTIVE;
				[self getPrefInternal : PREFS_GET_TAB_CT_POSX : &(((NSRect *)outputContainer)->origin.x) : additionalData];
			}
			
			break;
		}
			
		case PREFS_GET_TAB_READER_FRAME:
		{
			NSRect data = [tabReaderSize getDataTab: mainThread : stateTabsReader];
			*(NSRect *) outputContainer = additionalData == NULL ? data : prefsPercToFrame(data, *(NSSize*) additionalData);
			
			[self getPrefInternal: PREFS_GET_TAB_READER_POSX : &(((NSRect *) outputContainer)->origin.x) : additionalData];
			
			break;
		}
			
		case PREFS_GET_MDL_FRAME:
		{
			NSRect data = [prefsPosMDL getData: mainThread : stateTabsReader];
			*(NSRect *) outputContainer = additionalData == NULL ? data : prefsPercToFrame(data, *(NSSize*) additionalData);
			
			if(mainThread == TAB_READER && additionalData != NULL)
			{
				CGFloat maxWidth = 0;
				[self getPrefInternal: PREFS_GET_TAB_READER_POSX : &maxWidth : additionalData];
				maxWidth = MAX(READERMODE_MAX_WIDTH_WHEN_INACTIVE, maxWidth);
				
				if(((NSRect*) outputContainer)->size.width > maxWidth)
					((NSRect*) outputContainer)->size.width = maxWidth;
			}
			
			break;
		}
			
		case PREFS_GET_IS_READER_MT:
		{
			BOOL * data = outputContainer;
			*data = (mainThread & TAB_READER) != 0;
			break;
		}
			
		case PREFS_GET_READER_TABS_STATE:
		{
			uint * output = outputContainer;
			*output = stateTabsReader;
			break;
		}
			
		case PREFS_GET_SCROLLER_STYLE:
		{
			*(byte*) outputContainer = SCROLLER_STYLE_LARGE;
			break;
		}
			
		case PREFS_GET_FAVORITE_AUTODL:
		{
			* (bool *) outputContainer = favoriteAutoDL;
			break;
		}
			
		case PREFS_GET_ACTIVE_PREFS_PANEL:
		{
			* (byte *) outputContainer = activePrefsPanel;
			break;
		}
			
		default:
		{
			NSLog(@"Couldn't identify request: %d", requestID);
		}
	}
}

+ (BOOL) setPref : (uint) requestID : (uint64) value
{
	BOOL ret_value = NO;
	
	if(prefsCache == NULL)
		[self initCache];
	
	switch (requestID)
	{
		case PREFS_SET_OWNMAINTAB:
		{
			ret_value = mainThread != (uint) value;
			if(ret_value)
			{
				mainThread = value & TAB_MASK;
				[prefsCache refreshFirstResponder];
				
				[[NSApp delegate] setHaveDistractionFree : mainThread == TAB_READER];
			}
			
			break;
		}
			
		case PREFS_SET_FAVORITE_AUTODL:
		{
			ret_value = favoriteAutoDL != (bool) value;
			favoriteAutoDL = value;
			
			break;
		}
			
		case PREFS_SET_READER_TABS_STATE:
		{
			ret_value = stateTabsReader != (uint) value;
			stateTabsReader = value & STATE_READER_TAB_MASK;
			[prefsCache refreshFirstResponder];
			
			break;
		}
			
		case PREFS_SET_READER_DISTRACTION_FREE:
		{
			if(value && stateTabsReader != STATE_READER_TAB_DISTRACTION_FREE)
			{
				stateTabsReader = STATE_READER_TAB_DISTRACTION_FREE;
				ret_value = YES;
			}
			else if(!value && stateTabsReader == STATE_READER_TAB_DISTRACTION_FREE)
			{
				stateTabsReader = STATE_READER_TAB_ALL_COLLAPSED;
				ret_value = YES;
			}
			break;
		}
			
		case PREFS_SET_READER_TABS_STATE_FROM_CALLER:
		{
			//Only relevant in the reader
			if(mainThread != TAB_READER)
				break;
			
			int newValue = -1;
			switch(value)
			{
				case TAB_SERIES:
				{
					newValue = STATE_READER_TAB_SERIE_FOCUS;
					break;
				}
				case TAB_CT:
				{
					newValue = STATE_READER_TAB_CT_FOCUS;
					break;
				}
				case TAB_MDL:
				{
					newValue = STATE_READER_TAB_MDL_FOCUS;
					break;
				}
				case TAB_READER:
				{
					newValue = STATE_READER_TAB_ALL_COLLAPSED;
					break;
				}
					
				case TAB_READER_DF:
				{
					newValue = STATE_READER_TAB_DISTRACTION_FREE;
					break;
				}
			}
			if(newValue != -1)
			{
				if(stateTabsReader != STATE_READER_TAB_DISTRACTION_FREE)
				{
					ret_value = stateTabsReader != (uint) newValue;
					stateTabsReader = newValue;
				}
			}
#ifdef DEV_VERSION
			else
			{
				NSLog(@"[%s]: Couldn't identify thread :%llu", __PRETTY_FUNCTION__, value);
			}
#endif
			break;
		}
			
		case PREFS_SET_ACTIVE_PREFS_PANEL:
		{
			ret_value = activePrefsPanel != value;
			activePrefsPanel = value;
			break;
		}
			
		default:
			break;
	}
	return ret_value;
}

+ (void) directQuery : (uint8_t) request : (uint8_t) subRequest : (uint) mainThreadLocal : (uint) stateTabsReaderLocal : (void*) outputContainer
{
	if(prefsCache == NULL)
		[self initCache];
	
	[prefsCache directQueryInternal:request :subRequest :mainThreadLocal :stateTabsReaderLocal :outputContainer];
	
}

- (void) directQueryInternal : (uint8_t) request : (uint8_t) subRequest : (uint) mainThreadLocal : (uint) stateTabsReaderLocal : (CGFloat*) output
{
	if(output == NULL)
		return;
	
	if(mainThreadLocal == -1)
		mainThreadLocal = mainThread;
	
	if(stateTabsReaderLocal == -1)
		stateTabsReaderLocal = stateTabsReader;
	
	NSRect frame;
	
	switch(request)
	{
		case QUERY_SERIE:
		{
			frame = [tabSerieSize getDataTab: mainThreadLocal : stateTabsReaderLocal];
			break;
		}
		case QUERY_CT:
		{
			frame = [tabCTSize getDataTab: mainThreadLocal : stateTabsReaderLocal];
			break;
		}
		case QUERY_READER:
		{
			frame = [tabReaderSize getDataTab: mainThreadLocal : stateTabsReaderLocal];
			break;
		}
		case QUERY_MDL:
		{
			frame = [prefsPosMDL getData: mainThread : stateTabsReaderLocal];
			break;
		}
		default:
		{
#ifdef DEV_VERSION
			NSLog(@"%s: Received garbage", __PRETTY_FUNCTION__);
#endif
			*output = 0;
			return;
		}
	}
	
	if(subRequest == QUERY_GET_WIDTH)
		*output = frame.size.width;
	else if(subRequest == QUERY_GET_HEIGHT)
		*output = frame.size.height;
	else if(subRequest == QUERY_GET_POSX)
		*output = frame.origin.x;
	else if(subRequest == QUERY_GET_POSY)
		*output = frame.origin.y;
	else
		*output = -1;
}

/************		Private sections		************/

char * loadPref(char request[3], unsigned int length, char defaultChar);

- (instancetype) init : (NSString *) data
{
	self = [super init];
	if(self != nil)
	{
		if(data == nil)
			self.themeCode = 1;
		else
			[self updateContext:data];
		
		uint expectedSize[] = { [RakSizeSeries getExpectedBufferSizeVirtual], [RakSizeCT getExpectedBufferSizeVirtual], [RakSizeReader getExpectedBufferSizeVirtual], [RakMDLSize getExpectedBufferSizeVirtual] };
		uint bufferSize = expectedSize[0] + expectedSize[1] + expectedSize[2] + expectedSize[3];
		char *input = loadPref("si", bufferSize, 'f'), recoveryBuffer[bufferSize];
		
		if(input == NULL)
		{
			input = recoveryBuffer;
			for(int i = 0; i < bufferSize; input[i++] = 'f');
		}
		
		tabSerieSize = [RakSizeSeries alloc];
		tabCTSize = [RakSizeCT alloc];
		tabReaderSize = [RakSizeReader alloc];
		
		if(tabSerieSize == NULL || tabCTSize == NULL || tabReaderSize == NULL)
			[self flushMemory:YES];
		
		tabSerieSize = [tabSerieSize init: prefsCache: input];
		tabCTSize = [tabCTSize init: prefsCache: &input[expectedSize[0]]];
		tabReaderSize = [tabReaderSize init: prefsCache: &input[expectedSize[0] + expectedSize[1]]];
		
		[checkConsistencyWidthPosXRakPrefsTabDeepData performTest:prefsCache :1 :YES];
		
		//Must come after tabs prefs initialization
		prefsPosMDL = [RakMDLSize alloc];
		if(prefsPosMDL == NULL)
			[self flushMemory:YES];
		
		prefsPosMDL = [prefsPosMDL init: prefsCache: &input[expectedSize[0] + expectedSize[1] + expectedSize[2]]];
		
		if(input != recoveryBuffer)
			free(input);
		
		RakAppDelegate * core = [NSApp delegate];
		if([core class] == [RakAppDelegate class])
			firstResponder = [(RakContentViewBack *) core.window.contentView getFirstResponder];
		
		[self refreshFirstResponder];
	}
	return self;
}

- (void) updateContext : (NSString *) data
{
	NSArray *componentsWithSpaces = [data componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	NSArray *dataState = [componentsWithSpaces filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
	
	uint pos = 0;
	
	for(NSString * element in dataState)
	{
		int value = [element intValue];

		switch (pos++)
		{
			case 0:
			{
				if(value == TAB_SERIES || value == TAB_CT || value == TAB_READER)
					mainThread = value;
				break;
			}
				
			case 1:
			{
				if(value >= THEME_CODE_DARK && value <= MAX_THEME_ID)
					_themeCode = value;

				break;
			}
				
			case 2:
			{
				favoriteAutoDL = value;
				break;
			}
			
			case 3:
			{
				if(value >= PREFS_BUTTON_CODE_GENERAL && value <= PREFS_BUTTON_CODE_CUSTOM)
					activePrefsPanel = value;
				break;
			}
		}
	}
}

#ifdef MUTABLE_SIZING
- (char*) dumpPrefs
{
	char *output = NULL;
	uint expectedSize[] = { [tabSerieSize getExpectedBufferSize], [tabCTSize getExpectedBufferSize], [tabReaderSize getExpectedBufferSize], [prefsPosMDL getExpectedBufferSize] };
	
	output = calloc(expectedSize[0] + expectedSize[1] + expectedSize[2] + expectedSize[3], sizeof(char));
	
	if(output != NULL)
	{
		[tabSerieSize dumpData:		output	: expectedSize[0]];
		[tabCTSize dumpData:		&output[expectedSize[0]] :	expectedSize[1]];
		[tabReaderSize dumpData:	&output[expectedSize[0] + expectedSize[1]] :	expectedSize[2]];
		[prefsPosMDL dumpData:		&output[expectedSize[0] + expectedSize[1] + expectedSize[2]] :	expectedSize[3]];
	}
	
	return output;
}
#endif

- (NSString *) dumpPrefs
{
	return [NSString stringWithFormat:@"%d\n%d\n%d\n%d", mainThread, _themeCode, favoriteAutoDL, activePrefsPanel];
}

- (void) refreshFirstResponder
{
	[firstResponder updateContext:mainThread :stateTabsReader];
}

- (void) flushMemory : (BOOL) memoryError
{
	prefsCache = NULL;
	
	if(memoryError)
		[[NSException exceptionWithName:@"NotEnoughMemory"
								 reason:@"We didn't had enough memory to do the job, sorry =/" userInfo:nil] raise];
}

- (NSArray *) setupExecuteConsistencyChecks : (uint8) request
{
	NSArray *array = [NSArray alloc];
	if(array == nil)
		return nil;
	
	switch(request)
	{
		case 1:
		{
			array = [array initWithObjects: tabSerieSize, tabCTSize, tabReaderSize, nil];
			break;
		}
		default:
		{
#ifdef DEV_VERSION
			NSLog(@"WTF! %s couldn't identify request: %d", __PRETTY_FUNCTION__, request);
#endif
			array = nil;
			break;
		}
	}
	return array;
}

@end

char * loadPref(char request[3], unsigned int length, char defaultChar)
{
#ifdef MUTABLE_SIZING
	char * output = calloc(length, sizeof(char));
	if(output != NULL)
	{
		FILE* prefs = fopen("prefs.txt", "r");
		
		if(prefs != NULL)
		{
			bool isWritting = false;
			char c, count = 0;
			unsigned int pos = 0;
			
			while((c = fgetc(prefs)) != EOF)
			{
				if(!isWritting)
				{
					if(count == 0 && c == '<')
						count++;
					else if(count == 1 && c == request[0])
						count++;
					else if(count == 2 && c == request[1])
						count++;
					else if(count == 3 && c == '>')
					{
						count = 0;
						isWritting = YES;
					}
					else
						count = 0;
				}
				else
				{
					if(pos >= length)
						break;
					else if(isHexa(c))
						output[pos++] = c;
					else if(count == 0 && c == '<')
						count++;
					else if(count == 1 && c == '/')
						count++;
					else if(count == 2 && c == request[0])
						count++;
					else if(count == 3 && c == request[1])
						count++;
					else if(count == 4 && c == '>')	//Parsing over, on quitte
						break;
					else
						count = 0;
				}
			}
			
			fclose(prefs);
		}
		
		for(int pos = 0; pos < length; output[pos++] = defaultChar);	//On remplit la fin
	}
	return output;
#else
	return NULL;
#endif
}
