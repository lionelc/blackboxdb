
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 250000;
SET blackboxdb.next_collection_id TO 2500;
SET blackboxdb.next_collection_index_id TO 2500;

BEGIN;
set local enable_seqscan TO off;
set local blackboxdb.forceUseIndexIfAvailable to on;
\i sql/bson_query_operator_tests_core.sql
