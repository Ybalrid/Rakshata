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

#include <openssl/bio.h>
#include <openssl/pem.h>
#include <openssl/x509.h>
#include <openssl/ssl.h>

static CURLSH* cacheDNS;

extern atomic_bool quit;

static void downloadChapterCore(DL_DATA *data);
static bool shouldNotifyPercentageUpdate(PROXY_DATA_LOADED * metadata);
static int handleDownloadMetadata(DL_DATA* ptr, double TotalToDownload, double NowDownloaded, double TotalToUpload, double NowUploaded);
static size_t writeDataChapter(void *ptr, size_t size, size_t nmemb, DL_DATA *downloadData);
static size_t write_data(void *ptr, size_t size, size_t nmemb, FILE* input);
static CURLcode ssl_add_rsp_certificate(CURL * curl, void * sslctx, void * parm);
static CURLcode sslAddRSPAndRepoCertificate(CURL * curl, void * sslctx, void * parm);
static void defineUserAgent(CURL *curl);

#pragma mark - DNS cache

void initializeDNSCache()
{
	curl_global_init(CURL_GLOBAL_ALL);

	cacheDNS = curl_share_init();
	if(cacheDNS != NULL)
		curl_share_setopt(cacheDNS, CURLSHOPT_SHARE, CURL_LOCK_DATA_DNS);
}

void useDNSCache(CURL* curl)
{
	if(cacheDNS != NULL)
		curl_easy_setopt(curl, CURLOPT_SHARE, cacheDNS);
}

void releaseDNSCache()
{
	if(cacheDNS != NULL)
	{
		curl_share_cleanup(cacheDNS);
		cacheDNS = NULL;
	}

	curl_global_cleanup();
}

#pragma mark - Chapter download

int downloadChapter(TMP_DL *output, PROXY_DATA_LOADED * metadata, uint currentPos, uint nbElem)
{
	THREAD_TYPE threadData;
	DL_DATA downloadData;
	double percentage;
	uint64_t prevDLBytes = 0, downloadSpeed = 0, delay;
	struct timeval anchor1, anchor2;

	downloadData.bytesDownloaded = downloadData.totalExpectedSize = downloadData.errorCode = 0;
	downloadData.outputContainer = output;
	downloadData.curlHandler = metadata->curlHandler;
	downloadData.aborted = metadata->downloadSuspended;
	downloadData.retryAttempt = 0;
	
	METADATA_LOADED * DLMetadata = metadata->metadata;

	threadData = createNewThreadRetValue(downloadChapterCore, &downloadData);

	//Early initialization

	while(isThreadStillRunning(threadData) && !quit && downloadData.totalExpectedSize == 0)
		usleep(50000);	//0.05s

	gettimeofday(&anchor1, NULL);

	while(isThreadStillRunning(threadData) && !quit)
	{
		if(shouldNotifyPercentageUpdate(metadata) && (*(downloadData.aborted) & DLSTATUS_SUSPENDED) == 0)
		{
			if(prevDLBytes != downloadData.bytesDownloaded)
			{
				gettimeofday(&anchor2, NULL);
				delay = (anchor2.tv_sec - anchor1.tv_sec) * 1000 + (anchor2.tv_usec - anchor1.tv_usec) / 1000.0;

				if(delay > 200)
				{
					if(delay)
						downloadSpeed = (downloadData.bytesDownloaded - prevDLBytes) * 1000 / delay;
					else
						downloadSpeed = 0;

					prevDLBytes = downloadData.bytesDownloaded;
					anchor1 = anchor2;
				}

				if(nbElem != 0 && downloadData.totalExpectedSize != 0)
					percentage = (currentPos * 100 / nbElem) + (downloadData.bytesDownloaded * 100) / (downloadData.totalExpectedSize * nbElem);
				else
					percentage = 0;

				DLMetadata->percentage = percentage;
				DLMetadata->speed = downloadSpeed;

				if(!DLMetadata->initialized)
					DLMetadata->initialized = true;

				updatePercentage(metadata, percentage, downloadSpeed);

				usleep(50000);	//100 ms
			}
			else
				usleep(1000);	//1 ms
		}
		else
			usleep(67000);	// 4/60 second, ~ 67 ms
	}

	if(quit)
	{
		while(isThreadStillRunning(threadData))
			usleep(100);
	}

#ifdef _WIN32
	CloseHandle(threadData);
#endif

	return downloadData.errorCode;
}

static void downloadChapterCore(DL_DATA *data)
{
	if(data == NULL || data->outputContainer == NULL || data->retryAttempt > 3)
		quit_thread(0);

	CURLcode res; //Get return from download

	//Start the main work

	CURL* curl = curl_easy_init();
	if(curl != NULL)
	{
		char * proxy = NULL;
		if(getSystemProxy(&proxy))
			curl_easy_setopt(curl, CURLOPT_PROXY, proxy); //Proxy

		curl_easy_setopt(curl, CURLOPT_URL, data->outputContainer->URL); //URL
		curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);
		curl_easy_setopt(curl, CURLOPT_MAXREDIRS, 5);
		defineUserAgent(curl);

		if(!strncmp(data->outputContainer->URL, SERVEUR_URL, strlen(SERVEUR_URL)) || !strncmp(data->outputContainer->URL, STORE_URL, strlen(STORE_URL))) //RSP
		{
			curl_easy_setopt(curl,CURLOPT_SSLCERTTYPE,"PEM");
			curl_easy_setopt(curl,CURLOPT_SSL_CTX_FUNCTION, sslAddRSPAndRepoCertificate);
		}
		else	//We don't ship all existing certificates, so we don't check it on non-critical transactions
			curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);

		curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0);
		curl_easy_setopt(curl, CURLOPT_PROGRESSDATA, data);
		curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, handleDownloadMetadata);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, data);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writeDataChapter);
		useDNSCache(curl);

		*(data->curlHandler) = curl;
		res = curl_easy_perform(curl);
		*(data->curlHandler) = NULL;
		curl_easy_cleanup(curl);
		
		free(proxy);

		if(res != CURLE_OK) //Si problème
		{
			data->errorCode = libcurlErrorCode(res); //On va interpreter et renvoyer le message d'erreur

			if(data->errorCode == CODE_RETOUR_PARTIAL)	//On va retenter une fois le téléchargement
			{
				data->retryAttempt++;
				data->bytesDownloaded = data->totalExpectedSize = data->errorCode = 0;
				((TMP_DL*) data->outputContainer)->current_pos = 0;

				downloadChapterCore(data);
			}

#ifdef EXTENSIVE_LOGGING
			if(data->errorCode != CODE_RETOUR_DL_CLOSE)
				logR("An error occured during the download of %s", data->outputContainer->URL);
#endif
		}
	}

	quit_thread(0);
}

#pragma mark - Chapter download utilities

static bool shouldNotifyPercentageUpdate(PROXY_DATA_LOADED * metadata)
{
	if(metadata->rowViewResponsible != NULL)
		return true;
	
#if TARGET_OS_IPHONE
	if(getActiveProjectForTab(TAB_CT) == metadata->datas->cacheDBID)
		return true;
#endif
	
	return false;
}

static int handleDownloadMetadata(DL_DATA* ptr, double totalToDownload, double nowDownloaded, double totalToUpload, double nowUploaded)
{
	if(quit)						//Global message to quit
		return -1;

	if(ptr != NULL)
	{
		ptr->bytesDownloaded = nowDownloaded;
		ptr->totalExpectedSize = totalToDownload;
	}

	return 0;
}

static size_t writeDataChapter(void *ptr, size_t size, size_t nmemb, DL_DATA *downloadData)
{
	const size_t invalidCode = size * nmemb + 1;

	if(quit)						//Global message to quit
		return invalidCode;

	else if(downloadData == NULL)
		return invalidCode;

	else if(downloadData->aborted != NULL && *downloadData->aborted & DLSTATUS_ABORT)
		return invalidCode;

	else if(!size || !nmemb)		//Rien à écrire
		return 0;

	TMP_DL *data = downloadData->outputContainer;

	if(data == NULL)
		return invalidCode;

	DATA_DL_OBFS *output = data->buf;
	char *input = ptr;

	if(output == NULL)
		return invalidCode;

	if(output->data == NULL || output->mask == NULL || data->length != downloadData->totalExpectedSize || size * nmemb >= data->length - data->current_pos || MIN(data->length, data->current_pos) == data->length)
	{
		if(output->data == NULL || output->mask == NULL)
		{
			data->current_pos = 0;
			if(!downloadData->totalExpectedSize)
				data->length = 30*1024*1024;
			else
				data->length = 3 * downloadData->totalExpectedSize / 2; //50% de marge

			output->data = calloc(1, data->length);
			if(output->data == NULL)
				return invalidCode;

			output->mask = malloc(data->length);
			if(output->mask == NULL)
				return invalidCode;
		}
		else //Buffer trop petit, on l'agrandit
		{
			if(data->length != downloadData->totalExpectedSize)
				data->length = downloadData->totalExpectedSize;

			if(size * nmemb >= data->length - data->current_pos)
				data->length += (downloadData->totalExpectedSize > size * nmemb ? downloadData->totalExpectedSize : size * nmemb);

			void *internalBufferTmp = realloc(output->data, data->length);
			if(internalBufferTmp == NULL)
				return invalidCode;
			output->data = internalBufferTmp;

			internalBufferTmp = realloc(output->mask, data->length);
			if(internalBufferTmp == NULL)
				return invalidCode;
			output->mask = internalBufferTmp;
		}
	}

	//Tronquer ne devrait plus être requis puisque nous agrandissons le buffer avant

#ifndef __clang_analyzer__
	for(uint i = 0; i < size * nmemb; data->current_pos++)
	{
		output->data[data->current_pos] = (~input[i++]) ^ output->mask[data->current_pos];
	}
#endif

	return size*nmemb;
}

static int internal_download_easy(char* adresse, char* POST, bool printToAFile, char **buffer_out, size_t * buffer_length, bool SSL_enabled);
static size_t save_data_easy(void *ptr, size_t size, size_t nmemb, void *buffer_dl_void);

int download_mem(char* adresse, char *POST, char **buffer_out, size_t * buffer_length, bool SSL_enabled)
{
	if(checkNetworkState(CONNEXION_DOWN)) //Si reseau down
		return CODE_RETOUR_DL_CLOSE;

	int retValue = internal_download_easy(adresse, POST, false, buffer_out, buffer_length, SSL_enabled);

	if(*buffer_length == 0)
	{
		free(*buffer_out);
		*buffer_out = NULL;
	}

	return retValue;
}

int download_disk(char* adresse, char * POST, char *file_name, bool SSL_enabled)
{
	if(checkNetworkState(CONNEXION_DOWN)) //Si reseau down
		return CODE_RETOUR_DL_CLOSE;

	return internal_download_easy(adresse, POST, true, &file_name, NULL, SSL_enabled);
}

static int internal_download_easy(char* adresse, char* POST, bool printToAFile, char **buffer_out, size_t * buffer_length, bool SSL_enabled)
{
	TMP_DL outputData;
	FILE* output = NULL;
	CURLcode res;

	if(!printToAFile && buffer_length == NULL)
		return CODE_RETOUR_INTERNAL_FAIL;

	CURL * curl = curl_easy_init();
	if(curl == NULL)
	{
		logR("Memory error");
		return CODE_RETOUR_INTERNAL_FAIL;
	}
	
	char * proxy = NULL;
	if(getSystemProxy(&proxy))
		curl_easy_setopt(curl, CURLOPT_PROXY, proxy); //Proxy

	curl_easy_setopt(curl, CURLOPT_URL, adresse);
	curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);
	curl_easy_setopt(curl, CURLOPT_MAXREDIRS, 5);
	curl_easy_setopt(curl, CURLOPT_TIMEOUT, 90);

	defineUserAgent(curl);
	useDNSCache(curl);

	if(POST != NULL)
		 curl_easy_setopt(curl, CURLOPT_POSTFIELDS, POST);

	if(SSL_enabled == SSL_ON)
	{
		if(!strncmp(adresse, SERVEUR_URL, strlen(SERVEUR_URL)) || !strncmp(adresse, STORE_URL, strlen(STORE_URL))) //RSP
		{
			curl_easy_setopt(curl,CURLOPT_SSLCERTTYPE,"PEM");
			curl_easy_setopt(curl,CURLOPT_SSL_CTX_FUNCTION, ssl_add_rsp_certificate);
		}
		else
			curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);
	}

	if(printToAFile)
	{
		output = fopen(*buffer_out, "wb");
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, output);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
	}
	else
	{
		if(*buffer_out == NULL)
			*buffer_length = 0;

		outputData.buf = buffer_out;
		outputData.length = *buffer_length;
		outputData.current_pos = 0;

		curl_easy_setopt(curl, CURLOPT_WRITEDATA, &outputData);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, save_data_easy);

		buffer_out[0] = 0;
	}

	res = curl_easy_perform(curl);
	curl_easy_cleanup(curl);
	free(proxy);

	if(output != NULL && printToAFile)
		fclose(output);

	if(res != CURLE_OK) //Si problème
		return libcurlErrorCode(res); //On va interpreter et renvoyer le message d'erreur

	if(!printToAFile)
	{
		*buffer_length = outputData.length;
		if(*buffer_out == NULL)
			return CODE_RETOUR_INTERNAL_FAIL;
	}

	return CODE_RETOUR_OK;
}

#pragma mark - Parsing functions

static size_t save_data_easy(void *ptr, size_t size, size_t nmemb, void *buffer_dl_void)
{
	const size_t blockSize = size * nmemb;
	char *input = ptr;
	TMP_DL *buffer_dl = buffer_dl_void;
	char * dataField = *((char**)buffer_dl->buf);

	//Realloc memory if needed
	if(buffer_dl->current_pos + blockSize > buffer_dl->length)
	{
		void * tmp = realloc(dataField, buffer_dl->current_pos + blockSize + 1);
		if(tmp != NULL)
		{
			dataField = * (char**) (buffer_dl->buf) = tmp;
			buffer_dl->length = buffer_dl->current_pos + blockSize + 1;
		}
		else
			return 0;
	}

	memcpy(&(dataField[buffer_dl->current_pos]), input, blockSize);
	buffer_dl->current_pos += blockSize;

	dataField[buffer_dl->current_pos] = 0;

	return blockSize;
}

static size_t write_data(void *ptr, size_t size, size_t nmemb, FILE* input)
{
	return fwrite(ptr, size, nmemb, input);
}

static void defineUserAgent(CURL *curl)
{
	curl_easy_setopt(curl, CURLOPT_USERAGENT, PROJECT_NAME"_"BUILD);
}

#pragma mark - SSL related portion

BIO * getBIORSPCertificate()
{
	char * pem_cert = "-----BEGIN CERTIFICATE-----\n\
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\n\
-----END CERTIFICATE-----";
  /* get a BIO */
  return BIO_new_mem_buf(pem_cert, -1);
}

BIO * getBIORepoCertificate()
{
	char * pem_cert = "-----BEGIN CERTIFICATE-----\n\
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\n\
4R8CFg==\n\
-----END CERTIFICATE-----";
	return BIO_new_mem_buf(pem_cert, -1);
}

static CURLcode ssl_add_rsp_certificate(CURL * curl, void * sslctx, void * parm)
{
	X509 * certRSP = NULL;
	X509_STORE * store = SSL_CTX_get_cert_store((SSL_CTX *) sslctx);  // get a pointer to the X509 certificate store (which may be empty!)
	BIO * bio = getBIORSPCertificate();

	PEM_read_bio_X509(bio, &certRSP, 0, NULL);           // use the BIO to read the PEM formatted certificate from memory into an X509 structure that SSL can use
	BIO_free(bio);

	/* add our certificates to this store */
	if(certRSP == NULL || !X509_STORE_add_cert(store, certRSP))
		return CURLE_SSL_CERTPROBLEM;

	return CURLE_OK;
}

static CURLcode sslAddRSPAndRepoCertificate(CURL * curl, void * sslctx, void * parm)
{
	X509 *certRSP = NULL, *certDpt = NULL;

	X509_STORE * store = SSL_CTX_get_cert_store((SSL_CTX *)sslctx);  // get a pointer to the X509 certificate store (which may be empty!)

	BIO * bio = getBIORSPCertificate();						//Certificat du RSP (services internes)
	PEM_read_bio_X509(bio, &certRSP, 0, NULL);
	BIO_free(bio);
	if(certRSP == NULL)
		return CURLE_SSL_CERTPROBLEM;

	bio = getBIORepoCertificate();                          //On ajoute le certificat root des dépôts
	PEM_read_bio_X509(bio, &certDpt, 0, NULL);
	BIO_free(bio);
	if(certDpt == NULL)
		return CURLE_SSL_CERTPROBLEM;

	/* add our certificates to this store */
	if(!X509_STORE_add_cert(store, certRSP) || !X509_STORE_add_cert(store, certDpt))
		return CURLE_SSL_CERTPROBLEM;

	return CURLE_OK;
}
