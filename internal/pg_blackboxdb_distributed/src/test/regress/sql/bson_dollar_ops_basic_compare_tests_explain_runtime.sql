
set search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
SET citus.next_shard_id TO 52000;
SET blackboxdb.next_collection_id TO 5200;
SET blackboxdb.next_collection_index_id TO 5200;

SELECT blackboxdb_api.drop_collection('db', 'querydollartest');
SELECT blackboxdb_api.create_collection('db', 'querydollartest');

SET client_min_messages=WARNING;

-- avoid plans that use primary key index
\i sql/bson_dollar_ops_basic_compare_tests_explain_core.sql
