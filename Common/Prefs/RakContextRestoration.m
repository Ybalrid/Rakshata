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

#define NB_CONTEXT 5

@implementation RakContextRestoration

+ (void) saveContextPrefs : (NSString *) contextPrefs  series: (NSString *) contextSerie CT: (NSString *) contextCT reader: (NSString *) contextReader MDL: (NSString *) contextMDL
{
	FILE * output = fopen(CONTEXT_FILE".new", "w+");
	
	if(output == NULL)
		return;
	
	if(contextPrefs == nil)		contextPrefs = STATE_EMPTY;
	if(contextSerie == nil)		contextSerie = STATE_EMPTY;
	if(contextCT == nil)		contextCT = STATE_EMPTY;
	if(contextMDL == nil)		contextMDL = STATE_EMPTY;
	if(contextReader == nil)		contextReader = STATE_EMPTY;
	
	byte pos = 0;
	for(NSString * element in @[contextPrefs, contextSerie, contextCT, contextMDL, contextReader])
	{
		const char * intermediaryBuffer = [element UTF8String];
		size_t length = strlen(intermediaryBuffer);
		
		char * stringOutput = malloc(length * 2 + 1);
		
		if(stringOutput == NULL)
		{
			memoryError(2 * length + 1);
			fclose(output);
			remove(CONTEXT_FILE".new");
			return;
		}
		
		decToHex((const unsigned char*) intermediaryBuffer, length, stringOutput);
		stringOutput[length*2] = 0;
		
		fputs(stringOutput, output);
		free(stringOutput);
		
		if(pos++ < NB_CONTEXT - 1)
			fputc(' ', output);
	}
	
	fclose(output);
	remove(CONTEXT_FILE);
	rename(CONTEXT_FILE".new", CONTEXT_FILE);
}

+ (NSArray *) newContext
{
	NSString * fileContent = [NSString stringWithContentsOfFile:@CONTEXT_FILE encoding:NSASCIIStringEncoding error:NULL];
	
	if(fileContent == nil)
		return nil;
	
	NSArray *componentsWithSpaces = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSArray *data = [componentsWithSpaces filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
	
	byte count, pos = 0;
	if([data count] >= NB_CONTEXT)
		count = NB_CONTEXT;
	else
		count = [data count];
	
	NSString * buffer;
	const char *bufferC;
	NSMutableArray * output = [NSMutableArray arrayWithCapacity:5];
	
	while(pos < count)
	{
		buffer = [data objectAtIndex:pos];
		
		if([buffer length] & 1)	//Impaire, il faut ajouter un espace
		{
			NSLog(@"[Warning]: weird data received, will try to deal with it...");
			
			NSMutableString * recovery = [NSMutableString stringWithString:buffer];
			[recovery insertString:@"0" atIndex:0];
			buffer = recovery;
		}
		
		bufferC = [buffer cStringUsingEncoding : NSASCIIStringEncoding];
		
		unsigned char decodedString[strlen(bufferC) / 2 + 1];
		
		hexToDec(bufferC, decodedString);
		
		decodedString[sizeof(decodedString) - 1] = 0;
		
		output[pos++] = [NSString stringWithUTF8String: (const char*) decodedString];
	}
	
	while(pos < NB_CONTEXT)
		output[pos++] = @"";
	
	return [NSArray arrayWithArray:output];
}

@end
