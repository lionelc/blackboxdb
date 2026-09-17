SET search_path TO blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal,blackboxdb_core;

SET citus.next_shard_id TO 680000;
SET blackboxdb.next_collection_id TO 68000;
SET blackboxdb.next_collection_index_id TO 68000;

\i sql/bson_composite_order_by_index_tests_core.sql