/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * src/blackboxdb_distributed.c
 *
 * Initialization of the shared library.
 *-------------------------------------------------------------------------
 */
#include <postgres.h>
#include <fmgr.h>
#include <miscadmin.h>
#include <bson.h>
#include <utils/guc.h>
#include <access/xact.h>
#include <utils/version_utils.h>
#include "bson_init.h"
#include "distributed_hooks.h"
#include "blackboxdb_distributed_init.h"

extern bool SkipBlackboxDBLoad;

PG_MODULE_MAGIC;
PG_FUNCTION_INFO_V1(test_bson_distributed_mem_vtable_uses_palloc);

void _PG_init(void);
void _PG_fini(void);

/*
 * BlackboxDBDistributed_InstallBsonMemVTablesLocal sets the libbson memory vtable
 * for pg_blackboxdb_distributed.so's own statically-linked copy of libbson.
 *
 * This MUST be a non-inline exported function so that service shared object can
 * call it to set this .so's vtable (since service code is the real _PG_init
 * entry point and pg_blackboxdb's _PG_init is skipped via SkipBlackboxDBLoad).
 */
void
BlackboxDBDistributed_InstallBsonMemVTablesLocal(void)
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
							"pg_blackboxdb_distributed can only be loaded via shared_preload_libraries. "
							"Add pg_blackboxdb_distributed to shared_preload_libraries configuration "
							"variable in postgresql.conf in coordinator and workers. "
							"Note that pg_blackboxdb_distributed should be placed right after citus and pg_blackboxdb.")));
	}

	BlackboxDBDistributed_InstallBsonMemVTablesLocal();

	InitializeBlackboxDBDistributedHooks();
	InitBlackboxDBDistributedConfigurations("blackboxdb_distributed");
	MarkGUCPrefixReserved("blackboxdb_distributed");
}


/*
 * test_bson_distributed_mem_vtable_uses_palloc verifies that libbson
 * allocations in pg_blackboxdb_distributed.so go through palloc.
 * See BsonMemVTableSelfTest() in bson_init.h for the shared logic.
 */
Datum
test_bson_distributed_mem_vtable_uses_palloc(PG_FUNCTION_ARGS)
{
	PG_RETURN_BOOL(BsonMemVTableSelfTest());
}


/*
 * _PG_fini is called before the extension is reloaded.
 */
void
_PG_fini(void)
{ }
