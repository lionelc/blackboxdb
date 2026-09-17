SET search_path TO blackboxdb_api_catalog, blackboxdb_core, public;
SET blackboxdb.next_collection_id TO 500;
SET blackboxdb.next_collection_index_id TO 500;

set blackboxdb_rum.enable_new_bulk_delete to on;
set blackboxdb_rum.enable_new_bulk_delete_inline_data_pages to on;
set blackboxdb_rum.prune_rum_empty_pages to off;
\i sql/rum_vacuum_cleanup_tests_core.sql