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

extern bool quit;
char password[100];

bool MDLPHandle(DATA_LOADED ** data, int8_t *** status, uint * IDToPosition, uint length)
{
    uint *index = NULL;
	
	if(COMPTE_PRINCIPAL_MAIL == NULL)	//We check if we need the email address
	{
		for(uint i = 0, pos; i < length; i++)
		{
			pos = IDToPosition != NULL ? IDToPosition[i] : i;
			if(data[pos] != NULL && data[pos]->datas != NULL && data[pos]->datas->haveDRM)
				return false;
		}
	}
	
	else if(!MDLPCheckAnythingPayable(data, *status, IDToPosition, length))
        return true;
	
	else if(!getPassFromCache(NULL))
		return false;

    index = MDLPGeneratePaidIndex(data, *status, IDToPosition, length);
    if(index != NULL)
    {
        uint factureID = INVALID_VALUE, sizeIndex;
        char * POSTRequest = MDLPCraftPOSTRequest(data, index);

        if(POSTRequest != NULL)
        {
            char *bufferOut = NULL, *bufferOutBak;
			size_t downloadLength;
			
            for(sizeIndex = 0; index[sizeIndex] != INVALID_VALUE; sizeIndex++);

			/*Interrogration du serveur*/
			if(download_mem(SERVEUR_URL"/checkPaid.php", POSTRequest, &bufferOut, &downloadLength, SSL_ON) == CODE_RETOUR_OK && bufferOut != NULL && downloadLength != 0 && isNbr(bufferOut[0]))
			{
				int prix;
				uint pos = 0, detail;

				bufferOutBak = bufferOut;
				
				if(sscanf(bufferOut, "%d\n%d", &prix, &factureID) == 2 && prix != -1 && factureID != INVALID_VALUE)
				{
					uint posStatusLocal = 0;
					int8_t ** statusLocal = calloc(sizeIndex+1, sizeof(int8_t*));
					if(statusLocal != NULL)
					{
						bool somethingToPay = false, needLogin = false;
						
						/*Chargement du fichier*/

						//We need to drop the first two lines we already parsed
						for(; *bufferOut && *bufferOut != '\n'; bufferOut++);
						for(; *bufferOut == '\n' || *bufferOut == '\r'; bufferOut++);
						for(; *bufferOut && *bufferOut != '\n'; bufferOut++);
						for(; *bufferOut == '\n' || *bufferOut == '\r'; bufferOut++);

						while(pos < sizeIndex && *bufferOut)
						{
							for(; *bufferOut && !isNbr(*bufferOut) && *bufferOut != MDLP_CODE_ERROR; bufferOut++);
							
							/*Sachant que la liste peut être réorganisée, on va copier les adresses
							 des données dont on a besoin dans un tableau qui sera envoyé au thread*/
							
							switch(*bufferOut)
							{
								case MDLP_CODE_ERROR:
								{
									*(*status)[index[pos++]] = MDL_CODE_INTERNAL_ERROR;
									break;
								}
								case MDLP_CODE_PAID:
								{
									*(*status)[index[pos]] = MDL_CODE_WAITING_LOGIN;
									statusLocal[posStatusLocal++] = (*status)[index[pos++]]; //on assume que posStatusLocal <= pos donc check limite supérieure inutile
									needLogin = true;
									break;
								}
								default:
								{
									bufferOut += sscanf(bufferOut, "%d", &detail);	//If required, the price of the element
									
									*(*status)[index[pos]] = MDL_CODE_WAITING_PAY;
									statusLocal[posStatusLocal++] = (*status)[index[pos++]]; //on assume que posStatusLocal <= pos donc check limite supérieure inutile
									needLogin = somethingToPay = true;
								}
							}
							
							bufferOut++;
						}
						
						for(; pos < sizeIndex; *(*status)[index[pos++]] = MDL_CODE_INTERNAL_ERROR);	//Manque
						
						if(needLogin)
						{
							DATA_PAY * arg = malloc(sizeof(DATA_PAY));
							if(arg != NULL)
							{
								arg->prix = prix;
								arg->somethingToPay = somethingToPay;
								arg->sizeStatusLocal = posStatusLocal;
								arg->statusLocal = statusLocal;
								arg->factureID = factureID;
								createNewThread(MDLPHandlePayProcedure, arg);
							}
							else
								free(statusLocal);
						}
						else
							free(statusLocal);
					}
				}
				else
				{
					for(pos = 0; pos < sizeIndex; *(*status)[index[pos++]] = MDL_CODE_INTERNAL_ERROR);
				}
				
			}
			else
			{
				for(uint pos = 0; pos < sizeIndex; *(*status)[index[pos++]] = MDL_CODE_INTERNAL_ERROR);
				bufferOutBak = bufferOut;
			}
			
			free(bufferOutBak);
		}

		free(POSTRequest);
        free(index);
    }

    return true;
}

char *MDLPCraftPOSTRequest(DATA_LOADED ** data, uint *index)
{
	if(COMPTE_PRINCIPAL_MAIL == NULL)
		return NULL;
	
	uint emailLength = strlen(COMPTE_PRINCIPAL_MAIL), length = 3 * emailLength + 50, compteur;
    char *output = NULL, *bufferEmail, buffer[500];
    void *buf;

    output = malloc(length * sizeof(char));
	bufferEmail = malloc(length * sizeof(char));
    if(output != NULL && bufferEmail != NULL)
    {
		char bufferURLDepot[3*LONGUEUR_URL];
		
		checkIfCharToEscapeFromPOST(COMPTE_PRINCIPAL_MAIL, emailLength, bufferEmail);
        snprintf(output, length - 1, "ver="CURRENTVERSIONSTRING"&mail=%s", bufferEmail);

        for(compteur = 0; index[compteur] != INVALID_VALUE; compteur++)
        {
			checkIfCharToEscapeFromPOST(data[index[compteur]]->datas->repo->URL, LONGUEUR_URL, bufferURLDepot);
			
            snprintf(buffer, 500, "&data[%d][editor]=%s&data[%d][IDProject]=%d&data[%d][isTome]=%d&data[%d][ID]=%d", compteur, data[index[compteur]]->datas->repo->URL, compteur, data[index[compteur]]->datas->projectID, compteur, data[index[compteur]]->listChapitreOfTome != NULL, compteur, data[index[compteur]]->identifier);
            length += strlen(buffer);
            buf = realloc(output, length * sizeof(char));
            if(buf != NULL)
            {
                output = buf;
                strend(output, length, buffer);
            }
        }
    }
	else
	{
		free(output);		output = NULL;
	}
	
	free(bufferEmail);	bufferEmail = NULL;
	
    return output;
}

void MDLPHandlePayProcedure(DATA_PAY * arg)
{
    bool toPay = arg->somethingToPay, cancel = false;
    uint sizeStatusLocal = arg->sizeStatusLocal;
	int8_t **statusLocal = arg->statusLocal;
    unsigned int factureID = arg->factureID;
    free(arg);

	//prix = arg->prix
	
    if(COMPTE_PRINCIPAL_MAIL != NULL)
    {
        for(uint i = 0; i < sizeStatusLocal; i++)
        {
            if(*statusLocal[i] == MDL_CODE_WAITING_LOGIN)
			{
                *statusLocal[i] = MDL_CODE_DEFAULT;
				MDLUpdateIcons(i, NULL);
			}
        }

        if(toPay)
        {
            int out = 0;
            if(out == 1)   //Nop
            {
                for(uint i = 0; i < sizeStatusLocal; i++)
                {
                    if(*statusLocal[i] == MDL_CODE_WAITING_PAY)
                        *statusLocal[i] = MDL_CODE_UNPAID;
                }
                cancel = true;
            }
            else
            {
				uint length = strlen(COMPTE_PRINCIPAL_MAIL);
                char *URLStore = malloc((length + 50) * sizeof(char));
				
				if(URLStore != NULL)
				{
					snprintf(URLStore, length + 50, STORE_URL"/?mail=%s&id=%d", COMPTE_PRINCIPAL_MAIL, factureID);
					ouvrirSite(URLStore);
					free(URLStore);
				}
            }
        }
    }
    else
        cancel = true;

    if(!cancel && toPay)
    {
        if(waitToGetPaid(factureID) == true)
        {
            for(uint i = 0; i < sizeStatusLocal; i++)
            {
                if(*statusLocal[i] == MDL_CODE_WAITING_PAY)
                    *statusLocal[i] = MDL_CODE_DEFAULT;
            }
			MDLDownloadOver(true);
        }
    }
	else if(cancel)
	{
		for(uint i = 0; i < sizeStatusLocal; i++)
		{
			if(*statusLocal[i] == MDL_CODE_WAITING_PAY)
				*statusLocal[i] = MDL_CODE_ABORTED;
		}
	}

    free(statusLocal);

    if(cancel)
        MDLPDestroyCache(factureID);

    quit_thread(0);
}

bool waitToGetPaid(unsigned int factureID)
{
    do
    {
        usleep(500);
    } while(!MDLPCheckIfPaid(factureID) && quit == false);

    if(quit == false)
        return true;
    return false;
}

void MDLPDestroyCache(unsigned int factureID)
{
	if(COMPTE_PRINCIPAL_MAIL == NULL)	//Order couldn't be created in this case
		return;
	
	uint length = strlen(COMPTE_PRINCIPAL_MAIL);
	size_t outputLength;
    char *output = NULL, POST[length + 100];

	snprintf(POST, sizeof(POST), "mail=%s&id=%d", COMPTE_PRINCIPAL_MAIL, factureID);
	download_mem(SERVEUR_URL"/cancelOrder.php", POST, &output, &outputLength, SSL_ON);
	free(output);
}

/** Checks **/

bool MDLPCheckAnythingPayable(DATA_LOADED ** data, int8_t ** status, uint * IDToPosition, uint length)
{
    for(uint i = 0, pos; i < length; i++)
    {
		if(IDToPosition != NULL)
			pos = IDToPosition[i];
		else
			pos = i;
		
        if(data[pos] != NULL && data[pos]->datas != NULL && data[pos]->datas->repo != NULL && data[pos]->datas->repo->type == TYPE_DEPOT_PAID && *status[pos] == MDL_CODE_DEFAULT)
            return true;
    }
    return false;
}

uint * MDLPGeneratePaidIndex(DATA_LOADED ** data, int8_t ** status, uint * IDToPosition, uint length)
{
    uint * output = malloc((length +1) * sizeof(uint));
    if(output != NULL)
    {
        uint outputLength = 0;
        for(uint i = 0, pos; i < length; i++)
        {
			if(IDToPosition != NULL)
				pos = IDToPosition[i];
			else
				pos = i;
			
            if(data[pos] != NULL && data[pos]->datas != NULL && data[pos]->datas->repo != NULL && data[pos]->datas->repo->type == TYPE_DEPOT_PAID && *status[pos] == MDL_CODE_DEFAULT)
                output[outputLength++] = pos;
        }
		
		void * tmp = realloc(output, (outputLength + 1) * sizeof(uint));
		if(tmp != NULL)
			output = tmp;
		
        output[outputLength] = INVALID_VALUE;
    }
    return output;
}

bool MDLPCheckIfPaid(unsigned int factureID)
{
    char URL[300], *output = NULL;
	size_t length;

	snprintf(URL, 300, SERVEUR_URL"/order/%d", factureID);
	
	bool retValue = download_mem(URL, NULL, &output, &length, SSL_ON) == CODE_RETOUR_OK && output != NULL && length > 0 && output[0] == '1';
	
	free(output);
	
	return retValue;
}
