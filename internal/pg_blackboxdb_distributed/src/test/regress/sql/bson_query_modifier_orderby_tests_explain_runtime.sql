
set search_path to blackboxdb_api_catalog;
SET citus.next_shard_id TO 3400000;
SET blackboxdb.next_collection_id TO 3400;
SET blackboxdb.next_collection_index_id TO 3400;

SELECT 1 FROM blackboxdb_api.drop_collection('db', 'bsoexplainnorderby');
SELECT blackboxdb_api.create_collection('db', 'bsoexplainnorderby');

BEGIN;
set enable_seqscan to on;
set local citus.enable_local_execution TO OFF;
\i sql/bson_query_modifier_orderby_tests_explain_core.sql
ROLLBACK;