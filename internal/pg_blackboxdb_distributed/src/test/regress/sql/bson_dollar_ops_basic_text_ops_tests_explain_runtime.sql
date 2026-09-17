
set search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
SET citus.next_shard_id TO 1400000;
SET blackboxdb.next_collection_id TO 1400;
SET blackboxdb.next_collection_index_id TO 1400;

SELECT blackboxdb_api.create_collection('db', 'queryregexopstest');
SELECT blackboxdb_api.create_collection('db', 'querytextopstest');

\i sql/bson_dollar_ops_basic_text_ops_tests_explain_core.sql
