
set search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
SET citus.next_shard_id TO 513000;
SET blackboxdb.next_collection_id TO 5130;
SET blackboxdb.next_collection_index_id TO 5130;

SET client_min_messages=WARNING;
SELECT blackboxdb_api.drop_collection('db', 'simple_negation_tests_explain');
SELECT blackboxdb_api.create_collection('db', 'simple_negation_tests_explain');


BEGIN;
SET local search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
\o /dev/null
\o
set local enable_seqscan to off;
set local blackboxdb.forceUseIndexIfAvailable to on;
\i sql/bson_dollar_operators_negation_tests_explain_core.sql
ROLLBACK;