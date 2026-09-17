
set search_path to blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;
SET citus.next_shard_id TO 1500000;
SET blackboxdb.next_collection_id TO 1500;
SET blackboxdb.next_collection_index_id TO 1500;

SELECT blackboxdb_api.drop_collection('db', 'queryregexopstest') IS NOT NULL;
SELECT blackboxdb_api.create_collection('db', 'queryregexopstest');

-- Create a wildcard index by using CREATE INDEX command instead of
-- using blackboxdb_api_internal.create_indexes_non_concurrently. This is because, we will use
-- that index to test whether we can use the index via query operators
-- other than "@@".
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', blackboxdb_distributed_test_helpers.generate_create_index_arg('queryregexopstest', 'index_2', '{"$**": 1}'), TRUE);

-- avoid plans that use the primary key index
SELECT blackboxdb_distributed_test_helpers.drop_primary_key('db','queryregexopstest');

SELECT blackboxdb_api.drop_collection('db', 'querytextopstest') IS NOT NULL;
SELECT blackboxdb_api.create_collection('db', 'querytextopstest');

-- avoid plans that use the primary key index
SELECT blackboxdb_distributed_test_helpers.drop_primary_key('db','querytextopstest');

BEGIN;
-- avoid sequential scan (likely to be preferred on small tables)
set local enable_seqscan = off;
set local blackboxdb.forceUseIndexIfAvailable to on;
\i sql/bson_dollar_ops_basic_text_ops_tests_explain_core.sql
END;
