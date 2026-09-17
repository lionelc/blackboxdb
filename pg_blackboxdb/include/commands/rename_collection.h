/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * include/commands/rename_collection.h
 *
 * Declarations for the rename_collection command implementation.
 *
 *-------------------------------------------------------------------------
 */

#ifndef RENAME_COLLECTION_H
#define RENAME_COLLECTION_H

#include "io/bson_core.h"

/*
 * Parsed arguments for the renameCollection command.
 */
typedef struct RenameCollectionArgs
{
	char *databaseName;
	char *sourceCollectionName;
	char *targetCollectionName;
	bool dropTarget;
} RenameCollectionArgs;

void ParseRenameCollectionSpec(pgbson *commandSpec, RenameCollectionArgs *args);
void ExecuteRenameCollection(char *databaseName, char *sourceCollectionName,
							 char *targetCollectionName, bool dropTarget);

#endif
