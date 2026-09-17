
set search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
SET citus.next_shard_id TO 440000;
SET blackboxdb.next_collection_id TO 4400;
SET blackboxdb.next_collection_index_id TO 4400;

\set QUIET on
\set prevEcho :ECHO
\set ECHO none
\o /dev/null

SELECT blackboxdb_api.drop_collection('db', 'dollaralltests') IS NOT NULL;
SELECT blackboxdb_api.create_collection('db', 'dollaralltests') IS NOT NULL;

\o
\set ECHO :prevEcho

-- avoid plans that use the primary key index
SELECT blackboxdb_distributed_test_helpers.drop_primary_key('db','dollaralltests');

BEGIN;
set local enable_seqscan TO on;

\i sql/bson_dollar_ops_query_all_tests_core.sql

ROLLBACK;

\set QUIET off