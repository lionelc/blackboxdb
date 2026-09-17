SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 1200000;
SET blackboxdb.next_collection_id TO 1200;
SET blackboxdb.next_collection_index_id TO 1200;

\i sql/bson_query_operator_tests_explain_index_comp_desc.sql