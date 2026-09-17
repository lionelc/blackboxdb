SET search_path TO blackboxdb_api_catalog, blackboxdb_api, blackboxdb_core, public;
SET blackboxdb.next_collection_id TO 3100;
SET blackboxdb.next_collection_index_id TO 3100;

\i sql/bson_aggregation_cursor_tests_core.sql
