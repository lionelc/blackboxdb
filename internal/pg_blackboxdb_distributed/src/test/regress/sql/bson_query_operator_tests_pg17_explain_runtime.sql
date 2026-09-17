SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 1300000;
SET blackboxdb.next_collection_id TO 1300;
SET blackboxdb.next_collection_index_id TO 1300;

SELECT blackboxdb_api.drop_collection('db', 'queryoperator');
SELECT blackboxdb_api.create_collection('db', 'queryoperator');

SELECT blackboxdb_api.drop_collection('db', 'nullfield');
SELECT blackboxdb_api.create_collection('db', 'nullfield');

SELECT blackboxdb_api.drop_collection('db', 'singlepathindexexists');
SELECT blackboxdb_api.create_collection('db', 'singlepathindexexists');

\i sql/bson_query_operator_tests_explain_core.sql
