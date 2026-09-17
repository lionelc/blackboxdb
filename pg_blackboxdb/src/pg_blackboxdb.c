/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * src/pg_blackboxdb.c
 *
 * Initialization of the shared library for the BlackboxDB API.
 *-------------------------------------------------------------------------
 */
#include <postgres.h>
#include <fmgr.h>
#include <miscadmin.h>
#include <utils/guc.h>

#include "bson_init.h"
#include "utils/feature_counter.h"
#include "blackboxdb_api_init.h"

PG_MODULE_MAGIC;
PG_FUNCTION_INFO_V1(test_bson_mem_vtable_uses_palloc);

void _PG_init(void);
void _PG_fini(void);
static void UseRBACCompliantSchemas(void);

bool SkipBlackboxDBLoad = false;
extern bool EnableRbacCompliantSchemas;
extern char *ApiSchemaName;
extern char *ApiSchemaNameV2;


/*
 * BlackboxDB_InstallBsonMemVTablesLocal sets the libbson memory vtable
 * for pg_blackboxdb.so's own statically-linked copy of libbson.
 *
 * This MUST be a non-inline exported function so that service shared object can
 * call it to set this .so's vtable (since service code is the real _PG_init
 * entry point and pg_blackboxdb's _PG_init is skipped via SkipBlackboxDBLoad).
 */
void
BlackboxDB_InstallBsonMemVTablesLocal(void)
{
	InstallBsonMemVTablesLocal();
}


/*
 * _PG_init gets called when the extension is loaded.
 */
void
_PG_init(void)
{
	if (SkipBlackboxDBLoad)
	{
		return;
	}

	if (!process_shared_preload_libraries_in_progress)
	{
		ereport(ERROR, (errmsg(
							"pg_blackboxdb can only be loaded via shared_preload_libraries"),
						errdetail_log(
							"Add pg_blackboxdb to shared_preload_libraries configuration "
							"variable in postgresql.conf. ")));
	}

	BlackboxDB_InstallBsonMemVTablesLocal();

	InitApiConfigurations("blackboxdb", "blackboxdb");
	InitializeSharedMemoryHooks();
	MarkGUCPrefixReserved("blackboxdb");

	InitializeBackgroundWorkerJobAllowedCommands();
	InitializeBlackboxDBBackgroundWorker("pg_blackboxdb", "blackboxdb", "blackboxdb");
	RegisterBlackboxDBBackgroundWorkerJobs();

	InstallBlackboxDBApiPostgresHooks();

	/* Use RBAC compliant schemas based on GUC*/
	if (EnableRbacCompliantSchemas)
	{
		UseRBACCompliantSchemas();
	}

	ereport(LOG, (errmsg("Initialized pg_blackboxdb extension")));
}


/*
 * UseRBACCompliantSchemas sets up the schema name globals based on feature flags
 */
static void
UseRBACCompliantSchemas(void)
{
	ApiSchemaName = "blackboxdb_api_v2";
	ApiSchemaNameV2 = "blackboxdb_api_v2";
}


/*
 * test_bson_mem_vtable_uses_palloc verifies that libbson allocations in
 * this .so go through palloc.  The actual test logic lives in
 * BsonMemVTableSelfTest() in bson_init.h so every .so tests its own
 * statically-linked libbson copy without duplicating code.
 */
Datum
test_bson_mem_vtable_uses_palloc(PG_FUNCTION_ARGS)
{
	PG_RETURN_BOOL(BsonMemVTableSelfTest());
}


/*
 * _PG_fini is called before the extension is reloaded.
 */
void
_PG_fini(void)
{
	if (SkipBlackboxDBLoad)
	{
		return;
	}

	UninstallBlackboxDBApiPostgresHooks();
}
