/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * src/blackboxdb_extended_rum_adapter.c
 *
 * Initialize rum at the initialization of the index.
 * This has overrides for the blackboxdb_rum index that is an
 * extensibility access method for blackboxdb's query engine.
 *
 * This provides an alternate index_am that can be enabled in documentbd
 * using the AlternateIndexHandler before creating indexes.
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include <miscadmin.h>
#include "pg_blackboxdb_rum.h"
#include <catalog/pg_am.h>
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "commands/defrem.h"

#include "index_am/index_am_exports.h"
#include "index_am/blackboxdb_rum.h"
#include "query/bson_dollar_selectivity.h"


PG_MODULE_MAGIC;

void _PG_init(void);

/* Data Type declarations */
typedef struct BlackboxDBRumOidCacheData
{
	Oid BlackboxDBRumAmOid;
	Oid BsonBlackboxDBRumSinglePathOperatorFamilyId;
	Oid BsonBlackboxDBRumCompositePathOperatorFamilyId;
	Oid BsonBlackboxDBRumHashedPathOperatorFamilyId;
	Oid BlackboxDbExtendedRumUniquePathOperatorFamilyId;
} BlackboxDBRumOidCacheData;


/* Method Declarations */
static Oid BlackboxDBExtendedRumIndexAmId(void);
static Oid BlackboxDBExtendedRumSinglePathOpFamilyOid(void);
static Oid BlackboxDBExtendedRumCompositePathOpFamilyOid(void);
static Oid BlackboxdbExtendedRumHashedPathOpsFamilyOid(void);
static Oid BlackboxDbExtendedRumUniquePathOperatorFamilyOid(void);
static const char * GetBlackboxDBCatalogSchema(void);
static void LoadBaseIndexAmRoutine(void);

extern PGDLLIMPORT Datum try_explain_blackboxdb_rum_index(PG_FUNCTION_ARGS);
extern PGDLLIMPORT Datum blackboxdb_rumhandler(PG_FUNCTION_ARGS);
extern PGDLLIMPORT Datum blackboxdb_rum_get_multi_key_status(PG_FUNCTION_ARGS);
extern PGDLLIMPORT Datum blackboxdb_rum_get_opclass_metadata(PG_FUNCTION_ARGS);
extern PGDLLIMPORT Datum blackboxdb_rum_update_multi_key_status(PG_FUNCTION_ARGS);
extern PGDLLIMPORT Datum blackboxdb_rum_get_current_index_key(PG_FUNCTION_ARGS);
extern PGDLLIMPORT Datum blackboxdb_rum_skip_tids_on_current_entry(PG_FUNCTION_ARGS);
extern PGDLLIMPORT Datum BlackboxDBRumOrderedCostEstimate(PG_FUNCTION_ARGS);

/* Static Globals */
static BsonIndexAmEntry BlackboxDBIndexAmEntry = {
	.is_single_path_index_supported = true,
	.is_wild_card_supported = true,
	.is_wild_card_projection_supported = false,
	.is_order_by_supported = true,
	.is_backwards_scan_supported = true,
	.is_index_only_scan_supported = true,
	.can_support_parallel_scans = true,
	.get_am_oid = BlackboxDBExtendedRumIndexAmId,
	.get_single_path_op_family_oid = BlackboxDBExtendedRumSinglePathOpFamilyOid,
	.get_composite_path_op_family_oid = BlackboxDBExtendedRumCompositePathOpFamilyOid,
	.get_text_path_op_family_oid = NULL,
	.get_unique_path_op_family_oid = BlackboxDbExtendedRumUniquePathOperatorFamilyOid,
	.get_hashed_path_op_family_oid = BlackboxdbExtendedRumHashedPathOpsFamilyOid,
	.add_explain_output = try_explain_blackboxdb_rum_index,
	.am_name = "extended_rum",
	.get_opclass_catalog_schema = GetBlackboxDBCatalogSchema,
	.get_opclass_internal_catalog_schema = GetBlackboxDBCatalogSchema,
	.get_multikey_status = blackboxdb_rum_get_multi_key_status,
	.get_opclass_metadata = blackboxdb_rum_get_opclass_metadata,
	.get_truncation_status = RumGetTruncationStatus,
	.supports_ordered_operator_scans = true,
	.create_indexes_support_funcs = NULL,
	.query_index_path_support_funcs = NULL,
	.get_current_index_key = blackboxdb_rum_get_current_index_key,
	.skip_tids_on_current_entry = blackboxdb_rum_skip_tids_on_current_entry,
	.force_path_key_summarization = true,
};
static BlackboxDBRumOidCacheData Cache = { 0 };
static bool has_custom_routine = false;
static IndexAmRoutine core_rum_routine = { 0 };
static void InitializeBlackboxDBRum(void);

/* Top level method exports */
PG_FUNCTION_INFO_V1(blackboxdb_extended_rumhandler);

PGDLLEXPORT void
_PG_init(void)
{
	InitializeBlackboxDBRum();
}


static void
InitializeBlackboxDBRum(void)
{
	if (!process_shared_preload_libraries_in_progress)
	{
		ereport(ERROR, (errmsg(
							"pg_blackboxdb_extended_rum can only be loaded via shared_preload_libraries"),
						errdetail_log(
							"Add pg_blackboxdb_extended_rum to shared_preload_libraries configuration "
							"variable in postgresql.conf. ")));
	}

	LoadBaseIndexAmRoutine();
	RegisterIndexAm(BlackboxDBIndexAmEntry);
}


/* Method implementations */

inline static void
EnsureBlackboxDBExtendedRumLib(void)
{
	if (unlikely(!has_custom_routine))
	{
		ereport(ERROR, (errmsg(
							"The blackboxdb_rum library should be loaded as part of shared_preload_libraries")));
	}
}


static IndexScanDesc
extension_blackboxdb_extended_rumbeginscan(Relation rel, int nkeys, int norderbys)
{
	EnsureBlackboxDBExtendedRumLib();
	return extension_blackboxdb_rumbeginscan_core(rel, nkeys, norderbys,
												  &core_rum_routine);
}


static void
extension_blackboxdb_extended_rumrescan(IndexScanDesc scan, ScanKey scankey, int
										nscankeys,
										ScanKey orderbys, int norderbys)
{
	EnsureBlackboxDBExtendedRumLib();
	extension_blackboxdb_rumrescan_core(scan, scankey, nscankeys,
										orderbys, norderbys, &core_rum_routine);
}


static IndexBuildResult *
extension_blackboxdb_extended_rumbuild(Relation heapRelation,
									   Relation indexRelation,
									   struct IndexInfo *indexInfo)
{
	return extension_rumbuild_core(heapRelation, indexRelation,
								   indexInfo, &core_rum_routine,
								   blackboxdb_rum_update_multi_key_status);
}


static bool
extension_blackboxdb_extended_ruminsert(Relation indexRelation,
										Datum *values,
										bool *isnull,
										ItemPointer heap_tid,
										Relation heapRelation,
										IndexUniqueCheck checkUnique,
										bool indexUnchanged,
										struct IndexInfo *indexInfo)
{
	return extension_ruminsert_core(indexRelation, values, isnull,
									heap_tid, heapRelation, checkUnique,
									indexUnchanged, indexInfo,
									&core_rum_routine,
									blackboxdb_rum_update_multi_key_status);
}


static void
LoadBaseIndexAmRoutine(void)
{
	LOCAL_FCINFO(fcinfo, 0);
	InitFunctionCallInfoData(*fcinfo, NULL, 1, InvalidOid, NULL, NULL);
	IndexAmRoutine *amroutine = (IndexAmRoutine *) DatumGetPointer(blackboxdb_rumhandler(
																	   fcinfo));

	/* Store the base routine */
	core_rum_routine = *amroutine;
	has_custom_routine = true;
}


static const char *
GetBlackboxDBCatalogSchema(void)
{
	return "blackboxdb_extended_rum_catalog";
}


static Oid
BlackboxDBExtendedRumIndexAmId(void)
{
	if (Cache.BlackboxDBRumAmOid == InvalidOid)
	{
		HeapTuple tuple = SearchSysCache1(AMNAME, CStringGetDatum(
											  "blackboxdb_extended_rum"));
		if (!HeapTupleIsValid(tuple))
		{
			return InvalidOid;
		}

		Form_pg_am accessMethodForm = (Form_pg_am) GETSTRUCT(tuple);
		Cache.BlackboxDBRumAmOid = accessMethodForm->oid;
		ReleaseSysCache(tuple);
	}

	return Cache.BlackboxDBRumAmOid;
}


static Oid
BlackboxDBExtendedRumSinglePathOpFamilyOid(void)
{
	if (Cache.BsonBlackboxDBRumSinglePathOperatorFamilyId == InvalidOid)
	{
		bool missingOk = false;
		Cache.BsonBlackboxDBRumSinglePathOperatorFamilyId = get_opfamily_oid(
			BlackboxDBExtendedRumIndexAmId(),
			list_make2(makeString((char *) GetBlackboxDBCatalogSchema()), makeString(
						   "bson_extended_rum_single_path_ops")),
			missingOk);
	}

	return Cache.BsonBlackboxDBRumSinglePathOperatorFamilyId;
}


static Oid
BlackboxdbExtendedRumHashedPathOpsFamilyOid(void)
{
	if (Cache.BsonBlackboxDBRumHashedPathOperatorFamilyId == InvalidOid)
	{
		bool missingOk = false;
		Cache.BsonBlackboxDBRumHashedPathOperatorFamilyId = get_opfamily_oid(
			BlackboxDBExtendedRumIndexAmId(),
			list_make2(makeString((char *) GetBlackboxDBCatalogSchema()), makeString(
						   "blackboxdb_extended_rum_hashed_ops")),
			missingOk);
	}

	return Cache.BsonBlackboxDBRumHashedPathOperatorFamilyId;
}


static Oid
BlackboxDbExtendedRumUniquePathOperatorFamilyOid(void)
{
	if (Cache.BlackboxDbExtendedRumUniquePathOperatorFamilyId == InvalidOid)
	{
		bool missingOk = false;
		Cache.BlackboxDbExtendedRumUniquePathOperatorFamilyId = get_opfamily_oid(
			BlackboxDBExtendedRumIndexAmId(),
			list_make2(makeString((char *) GetBlackboxDBCatalogSchema()), makeString(
						   "bson_extended_rum_unique_shard_path_ops")),
			missingOk);
	}

	return Cache.BlackboxDbExtendedRumUniquePathOperatorFamilyId;
}


static Oid
BlackboxDBExtendedRumCompositePathOpFamilyOid(void)
{
	if (Cache.BsonBlackboxDBRumCompositePathOperatorFamilyId == InvalidOid)
	{
		bool missingOk = false;
		Cache.BsonBlackboxDBRumCompositePathOperatorFamilyId = get_opfamily_oid(
			BlackboxDBExtendedRumIndexAmId(),
			list_make2(makeString((char *) GetBlackboxDBCatalogSchema()), makeString(
						   "bson_extended_rum_composite_path_ops")),
			missingOk);
	}

	return Cache.BsonBlackboxDBRumCompositePathOperatorFamilyId;
}


static void
extension_blackboxdb_extended_rumcostestimate(PlannerInfo *root, IndexPath *path,
											  double loop_count,
											  Cost *indexStartupCost,
											  Cost *indexTotalCost,
											  Selectivity *indexSelectivity,
											  double *indexCorrelation,
											  double *indexPages)
{
	/* Do not force index cost to zero unless explicitly requested */
	bool enableCompositePlannerCosts = EnablePlannerCostSelectivityFromRelOptInfo(root,
																				  path->
																				  indexinfo
																				  ->rel);
	bool forceIndexCostToZero = !enableCompositePlannerCosts;
	extension_rumcostestimate_core(root, path, loop_count, indexStartupCost,
								   indexTotalCost, indexSelectivity, indexCorrelation,
								   indexPages, &core_rum_routine,
								   forceIndexCostToZero, enableCompositePlannerCosts,
								   BlackboxDBRumOrderedCostEstimate);
}


PGDLLEXPORT Datum
blackboxdb_extended_rumhandler(PG_FUNCTION_ARGS)
{
	/* Ensure that the base rum handler is loaded */
	if (!has_custom_routine)
	{
		LoadBaseIndexAmRoutine();
	}

	IndexAmRoutine *amroutine = (IndexAmRoutine *) palloc0(sizeof(IndexAmRoutine));
	*amroutine = core_rum_routine;

	amroutine->ambeginscan = extension_blackboxdb_extended_rumbeginscan;
	amroutine->amrescan = extension_blackboxdb_extended_rumrescan;
	amroutine->ambuild = extension_blackboxdb_extended_rumbuild;
	amroutine->aminsert = extension_blackboxdb_extended_ruminsert;
	amroutine->amcostestimate = extension_blackboxdb_extended_rumcostestimate;
	PG_RETURN_POINTER(amroutine);
}
