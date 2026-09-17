CREATE SCHEMA regex_options;
SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal,public,regex_options;
SET citus.next_shard_id TO 700000;
SET blackboxdb.next_collection_id TO 700;
SET blackboxdb.next_collection_index_id TO 700;

SELECT create_collection('db','regex_options');

BEGIN;
set local enable_seqscan TO ON;
\i sql/regex_options_core.sql
ROLLBACK;

SELECT drop_collection('db','regex_options');
DROP SCHEMA regex_options CASCADE;
