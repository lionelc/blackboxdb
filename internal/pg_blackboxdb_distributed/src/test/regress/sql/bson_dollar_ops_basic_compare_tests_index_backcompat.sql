
set search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
SET citus.next_shard_id TO 510000;
SET blackboxdb.next_collection_id TO 5100;
SET blackboxdb.next_collection_index_id TO 5100;

BEGIN;
set local blackboxdb.enableGenerateNonExistsTerm to off;
set local enable_seqscan to off;
set local blackboxdb.forceUseIndexIfAvailable to on;
\i sql/bson_dollar_ops_basic_compare_tests_core.sql
ROLLBACK;