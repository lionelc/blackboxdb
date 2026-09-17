SET search_path TO blackboxdb_api_catalog, blackboxdb_api, blackboxdb_core, public;
SET citus.next_shard_id TO 3120000;
SET blackboxdb.next_collection_id TO 3120;
SET blackboxdb.next_collection_index_id TO 3120;

SET citus.multi_shard_modify_mode TO 'sequential';

\i sql/bson_aggregation_cursor_tests_core.sql
\i sql/bson_aggregation_cursor_integration_tests_core.sql
