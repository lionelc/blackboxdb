-- Test: enableGroupByCompoundIdIndexPushdown=on
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 862000;
SET blackboxdb.next_collection_id TO 8620;
SET blackboxdb.next_collection_index_id TO 8620;

SET blackboxdb.enableGroupByCompoundIdIndexPushdown TO on;

\i sql/bson_group_compound_id_correctness_core.sql
