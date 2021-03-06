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

/**Chapitre.c**/
void refreshChaptersList(PROJECT_DATA *projectDB);
bool checkChapterReadable(PROJECT_DATA projectDB, uint chapitre);
void getChapterInstalled(PROJECT_DATA *projectDB);
void getUpdatedChapterList(PROJECT_DATA *projectDB, bool getInstalled);
void internalDeleteChapitre(PROJECT_DATA projectDB, uint chapitreDelete, bool careAboutLinkedChapters);
bool isChapterShared(char *path, PROJECT_DATA data, uint ID);

/**check.c**/
void networkAndVersionTest(void);
bool checkNetworkState(int state);

/**CTCommon.c**/
#define ACCESS_DATA(isTome, dataChap, dataTome) (isTome ? dataTome : dataChap)
#define ACCESS_CT(isTome, dataChap, dataTome, index) (isTome ? ((META_TOME *) dataTome)[index].ID : ((uint *) dataChap)[index])
#define ACCESS_ID(isTome, dataChap, dataTome) (isTome ? dataTome : (uint) dataChap)
void nullifyCTPointers(PROJECT_DATA * project);
void nullifyParsedPointers(PROJECT_DATA_PARSED * project);
void getUpdatedCTList(PROJECT_DATA *projectDB, bool isTome);
void getCTInstalled(PROJECT_DATA * project, bool isTome);
void generateCTUsable(PROJECT_DATA_PARSED * project);
bool checkSoonToBeReadable(PROJECT_DATA project, bool isTome, uint data);
bool checkReadable(PROJECT_DATA projectDB, bool isTome, uint data);
bool checkAlreadyRead(PROJECT_DATA projectDB, bool isTome, uint data);
bool haveUnread(PROJECT_DATA project);
void internalDeleteCT(PROJECT_DATA projectDB, bool isTome, uint selection);
bool consolidateCTLocale(PROJECT_DATA_PARSED * project, bool isTome);
void * buildInstalledList(void * fullData, uint nbFull, uint * installed, uint nbInstalled, bool isTome);
void releaseParsedData(PROJECT_DATA_PARSED data);
void releaseCTData(PROJECT_DATA data);

/**Download.c**/
void initializeDNSCache(void);
void releaseDNSCache(void);
int download_mem(char* adresse, char *POST, char **buffer_out, size_t * buffer_length, bool SSL_enabled);
int download_disk(char* adresse, char * POST, char *file_name, bool SSL_enabled);

/**Error.c**/
void logR(const char *error, ...);
int libcurlErrorCode(CURLcode code);
void memoryError(size_t size);

/**Favoris.c**/
bool checkIfFaved(PROJECT_DATA* projectDB, char **favs);
bool setFavorite(PROJECT_DATA* projectDB);
void updateFavorites(void);
bool checkFavoriteUpdate(PROJECT_DATA project, PROJECT_DATA * projectInPipeline, bool * isTomePipeline, uint * elementInPipeline, bool checkOnly);
void getNewFavs(void);

/**JSONParser.m**/
PROJECT_DATA_EXTRA * parseRemoteData(REPO_DATA* repo, char * remoteDataRaw, uint * nbElem);
PROJECT_DATA_PARSED * parseLocalData(REPO_DATA ** repo, uint nbRepo, unsigned char * remoteDataRaw, uint *nbElem);
char * reversedParseData(PROJECT_DATA_PARSED * data, uint nbElem, REPO_DATA ** repo, uint nbRepo, size_t * sizeOutput);
void moveProjectExtraToParsed(const PROJECT_DATA_EXTRA input, PROJECT_DATA_PARSED * output);

ROOT_REPO_DATA * parseRemoteRepo(char * parseDataRaw);
ROOT_REPO_DATA ** parseLocalRepo(char * parseDataRaw, uint * nbElem);
char * linearizeRepoData(ROOT_REPO_DATA ** root, uint rootLength, size_t * sizeOutput);

/**Keys.c**/
byte getMasterKey(unsigned char *input);
void generateRandomKey(unsigned char output[SHA256_DIGEST_LENGTH]);
void updateEmail(const char * email);
void deleteEmail(void);
void addPassToCache(const char * hashedPassword);
bool getPassFromCache(char pass[2 * SHA256_DIGEST_LENGTH + 1]);
bool validateEmail(const char* adresseEmail);
byte checkLogin(const char adresseEmail[100]);
int loginToRSP(const char * adresseEmail, const char * password, bool createAccount);
void saltPassword(char passwordSalted[2*SHA256_DIGEST_LENGTH+1]);
byte createSecurePasswordDB(unsigned char *key_sent);
bool createNewMK(char password[50], unsigned char key[SHA256_DIGEST_LENGTH]);
bool recoverPassFromServ(unsigned char key[SHA256_DIGEST_LENGTH]);

/**lecteur_loading**/
char ** loadChapterConfigDat(char* input, uint *nbPage, uint ** nameID);

/**Native.c**/
int mkdirR(const char *path);
void strend(char *recepter, size_t length, const char *sender);
size_t ustrlen(const void *input);
size_t wstrlen(const charType * input);
int wstrcmp(const charType * a, const charType * b);
charType * wstrdup(const charType * input);
void wstrncpy(charType * output, size_t length, const charType * input);
void usstrcpy(void* output, size_t length, const void* input);

void removeFolder(const char *path);
char ** listDir(const char * dirName, uint * nbElements);
void ouvrirSite(const char *URL);
#define checkFileExist(filename) (access(filename, F_OK) != -1)
bool checkDirExist(const char *dirname);
void createPath(const char *output);
uint32_t getFileSize(const char *filename);
uint64_t getFileSize64(const char * filename);

/**Repo.c**/
bool getRepoData(byte type, char * repoURL, char ** output, size_t * sizeOutput);
char * getPathForRepo(REPO_DATA * repo);
char * getPathForProject(PROJECT_DATA project);
char * getPathForRootRepo(ROOT_REPO_DATA * repo);
byte defineTypeRepo(char *URL);

/**Securite.c**/
void decryptPage(void *password, rawData *buffer_int, rawData *buffer_out, size_t length);
void generateFingerPrint(unsigned char output[SHA256_DIGEST_LENGTH+1]);
void getFileDate(const char *filename, char *date, void* internalData);
IMG_DATA *loadSecurePage(char *pathRoot, char *pathPage, uint numeroChapitre, uint page);
void loadKS(char killswitch_string[NUMBER_MAX_REPO_KILLSWITCHE][2*SHA256_DIGEST_LENGTH+1]);
bool checkKS(ROOT_REPO_DATA dataCheck, char dataKS[NUMBER_MAX_REPO_KILLSWITCHE][2*SHA256_DIGEST_LENGTH+1]);
void KSTriggered(REPO_DATA team);
uint getRandom(void);
bool checkSignature(const byte * input, const size_t inputLength, const byte * signature, const size_t signatureLength);

/**Settings.c**/
char *loadPrefFile(void);
void addToPref(char* flag, char *stringToAdd);
void removeFromPref(char* flag);
void updatePrefs(char* flag, char *stringToAdd);
bool loadEmailProfile(void);
char* loadLargePrefs(char* flag);

/**Sorting.c**/
int sortNumbers(const void *a, const void *b);
int sortTomesWithReadingID(const void *a, const void *b);
int sortTomes(const void *a, const void *b);
int sortProjects(const void *a, const void *b);
int sortRepo(const void *a, const void *b);
int sortRootRepo(const void *a, const void *b);
bool areProjectsIdentical(PROJECT_DATA_PARSED a, PROJECT_DATA_PARSED b);
int strnatcmp(const void *a, const void *b);

/**Thread.c**/
void createNewThread(void *function, void *arg);
THREAD_TYPE createNewThreadRetValue(void *function, void *arg);
bool isThreadStillRunning(THREAD_TYPE hThread);

/**Tome.c**/
uint getPosForID(PROJECT_DATA data, bool installed, uint ID);
void refreshTomeList(PROJECT_DATA *projectDB);
void setTomeReadable(PROJECT_DATA projectDB, uint ID);
bool checkTomeReadable(PROJECT_DATA projectDB, uint ID);
void getTomeInstalled(PROJECT_DATA *project);
void getUpdatedTomeList(PROJECT_DATA *projectDB, bool getInstalled);
void copyTomeList(META_TOME * input, uint nbVolumes, META_TOME * output);
void freeTomeList(META_TOME * data, uint length, bool includeDetails);
void freeSingleTome(META_TOME data);
void internalDeleteTome(PROJECT_DATA projectDB, uint tomeDelete, bool careAboutLinkedChapters);

/**Unzip.c**/
bool decompressChapter(void *inputData, size_t sizeInput, char *outputPath, PROJECT_DATA project, int entryDetail);
void finishInstallationAtPath(const char * path);

/**Utilitaires**/
void checkIfCharToEscapeFromPOST(char * input, uint length, char * output);
IMG_DATA* readFile(char * path);
bool isDownloadValid(char *input);
bool haveSuffixCaseInsensitive(const char *input, const char * stringToFind);
bool isStringLongerOrAsLongThan(const char * input, uint length);

#define crashTemp(string, length) bzero(string, length)
#define isHexa(caract) ((caract >= '0' && caract <= '9') || (caract >= 'a' && caract <= 'f') || (caract >= 'A' && caract <= 'F'))
#define isNbr(caract) isdigit(caract)
#define isJPEG(input) (((rawData *) input)[0] == (rawData) '\xff' && ((rawData *) input)[1] == (rawData) '\xd8')
#define isPNG(input) (((rawData *) input)[0] == (rawData) '\x89' && ((rawData *) input)[1] == (rawData) 'P' && ((rawData *) input)[2] == (rawData) 'N' && ((rawData *) input)[3] == (rawData) 'G')
#define isZIP(input) (((rawData *) input)[0] == (rawData) 'P' && ((rawData *) input)[1] == (rawData) 'K' && ((rawData *) input)[2] == (rawData) 0x3 && ((rawData *) input)[3] == (rawData) 0x4)
#define isRAR(input) (((rawData *) input)[0] == (rawData) 'R' && ((rawData *) input)[1] == (rawData) 'a' && ((rawData *) input)[2] == (rawData) 'r' && ((rawData *) input)[3] == (rawData) '!')
#define isPDF(input) (((rawData *) input)[0] == (rawData) '%' && ((rawData *) input)[1] == (rawData) 'P' && ((rawData *) input)[2] == (rawData) 'D' && ((rawData *) input)[3] == (rawData) 'F')

#if !TARGET_OS_IPHONE || !defined(__OBJC__)
	#define MIN(a, b) ((a) < (b) ? (a) : (b))
	#define MAX(a, b) ((a) > (b) ? (a) : (b))
#endif
