/*********************************************************************************************
 **	__________         __           .__            __                 ________   _______   	**
 **	\______   \_____  |  | __  _____|  |__ _____ _/  |______   	___  _\_____  \  \   _  \  	**
 **	 |       _/\__  \ |  |/ / /  ___/  |  \\__  \\   __\__  \  	\  \/ //  ____/  /  /_\  \ 	**
 **	 |    |   \ / __ \|    <  \___ \|   Y  \/ __ \|  |  / __ \_  \   //       \  \  \_/   \	**
 **	 |____|_  /(____  /__|_ \/____  >___|  (____  /__| (____  /	  \_/ \_______ \ /\_____  /	**
 **	        \/      \/     \/     \/     \/     \/          \/ 	              \/ \/     \/ 	**
 **                                                                                          **
 **			This Source Code Form is subject to the terms of the Mozilla Public				**
 **			License, v. 2.0. If a copy of the MPL was not distributed with this				**
 **			file, You can obtain one at https://mozilla.org/MPL/2.0/.						**
 **                                                                                         **
 **                     			© Taiki 2011-2016                                       **
 **                                                                                          **
 *********************************************************************************************/

#include <sys/types.h>
#include <wchar.h>

//hexadecimal

void hexToDec(const char *input, unsigned char *output);
void hexToCGFloat(const char *input, uint32_t length, double *output);
void decToHex(const unsigned char *input, size_t length, char *output);

//base-64

char * base64_encode_wchar(const charType *data, size_t input_length, size_t *output_length);
char *base64_encode(const unsigned char *data, size_t input_length, size_t *output_length);
unsigned char *base64_decode(const char *data, size_t input_length, size_t *output_length);

//UTF-8

size_t utf8_to_wchar(const char *in, size_t insize, wchar_t *out, size_t outsize, int flags);
size_t wchar_to_utf8(const wchar_t *in, size_t insize, char *out, size_t outsize, int flags);