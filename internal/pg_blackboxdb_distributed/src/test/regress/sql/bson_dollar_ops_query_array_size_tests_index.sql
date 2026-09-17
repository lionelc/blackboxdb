
set search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
SET citus.next_shard_id TO 430000;
SET blackboxdb.next_collection_id TO 4300;
SET blackboxdb.next_collection_index_id TO 4300;

\set QUIET on
\set prevEcho :ECHO
\set ECHO none

SELECT blackboxdb_api.drop_collection('db', 'arraysize') IS NOT NULL;
SELECT blackboxdb_api.create_collection('db', 'arraysize') IS NOT NULL;
 
\o /dev/null
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', blackboxdb_distributed_test_helpers.generate_create_index_arg('arraysize', 'testgin_arraysize', '{"$**": 1}'), TRUE);
\o
\set ECHO :prevEcho

-- avoid plans that use the primary key index
SELECT blackboxdb_distributed_test_helpers.drop_primary_key('db','arraysize');

BEGIN;
set local enable_seqscan TO off;
set local blackboxdb.forceUseIndexIfAvailable to on;

\i sql/bson_dollar_ops_query_array_size_tests_core.sql

ROLLBACK;

\set QUIET off