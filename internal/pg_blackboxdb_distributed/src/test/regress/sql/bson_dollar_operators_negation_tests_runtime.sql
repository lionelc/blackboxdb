
set search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
SET citus.next_shard_id TO 512000;
SET blackboxdb.next_collection_id TO 5120;
SET blackboxdb.next_collection_index_id TO 5120;

SET client_min_messages=WARNING;
SELECT blackboxdb_api.drop_collection('db', 'simple_negation_tests') IS NULL;
SELECT blackboxdb_api.create_collection('db', 'simple_negation_tests') IS NULL;
\o /dev/null
\o

BEGIN;
set local enable_seqscan to off;
set local blackboxdb.forceUseIndexIfAvailable to on;
\i sql/bson_dollar_operators_negation_tests_core.sql
ROLLBACK;

SELECT blackboxdb_api.shard_collection('db', 'simple_negation_tests', '{ "_id": "hashed" }', false);
BEGIN;
set local enable_seqscan to off;
set local blackboxdb.forceUseIndexIfAvailable to on;
\i sql/bson_dollar_operators_negation_tests_core.sql
ROLLBACK;