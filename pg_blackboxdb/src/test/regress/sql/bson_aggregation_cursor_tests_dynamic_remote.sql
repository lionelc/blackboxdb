SET search_path TO blackboxdb_api_catalog, blackboxdb_api, blackboxdb_core, public;
SET blackboxdb.next_collection_id TO 13200;
SET blackboxdb.next_collection_index_id TO 13200;

SET blackboxdb.enableDynamicCursors TO on;
SET blackboxdb.useLocalExecutionShardQueries TO off;


\i sql/bson_aggregation_cursor_tests_core.sql
