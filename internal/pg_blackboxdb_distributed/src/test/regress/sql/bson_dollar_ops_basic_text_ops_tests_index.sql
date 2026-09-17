set search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
SET citus.next_shard_id TO 450000;
SET blackboxdb.next_collection_id TO 4500;
SET blackboxdb.next_collection_index_id TO 4500;

BEGIN;
set local enable_seqscan = off;
\i sql/bson_dollar_ops_basic_text_ops_tests_core.sql
ROLLBACK;