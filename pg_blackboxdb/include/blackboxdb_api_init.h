/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * include/blackboxdb_api_init.h
 *
 * Exports related to shared library initialization for the API.
 *
 *-------------------------------------------------------------------------
 */
#ifndef BLACKBOXDB_API_INIT_H
#define BLACKBOXDB_API_INIT_H

void InitApiConfigurations(char *prefix, char *newGucPrefix);
void InstallBlackboxDBApiPostgresHooks(void);
void UninstallBlackboxDBApiPostgresHooks(void);
void InitializeBlackboxDBBackgroundWorker(char *libraryName, char *gucPrefix,
										  char *extensionObjectPrefix);
void InitializeSharedMemoryHooks(void);
void InitializeBackgroundWorkerJobAllowedCommands(void);
void RegisterBlackboxDBBackgroundWorkerJobs(void);
void BlackboxDB_InstallBsonMemVTablesLocal(void);
#endif
