SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

SET blackboxdb.next_collection_id TO 1100;
SET blackboxdb.next_collection_index_id TO 1100;

set blackboxdb.defaultUseCompositeOpClass to on;

-- create composite wildcard index - should be sparse already
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'wildcard_db', '{ "createIndexes": "wildcard_coll", "indexes": [ { "name": "sparse_wildcard_index", "key": { "a.$**": 1 } } ] }', TRUE);

-- insert 5000 rows that don't match the index path
SELECT COUNT(blackboxdb_api.insert_one('wildcard_db', 'wildcard_coll', bson_build_document('_id'::text, i, 'b'::text, i))) FROM generate_series(1, 5000) i;

ANALYZE blackboxdb_data.documents_1101;

-- check index size - should be empty.
SELECT blackboxdb_api_internal.blackboxdb_rum_get_meta_page_info(public.get_raw_page('blackboxdb_data.documents_rum_index_1102', 0));

-- read the root page: it should be a page that's a leaf with 0 entries.
SELECT blackboxdb_api_internal.blackboxdb_rum_page_get_stats(public.get_raw_page('blackboxdb_data.documents_rum_index_1102', 1));
SELECT jsonb_set(blackboxdb_api_internal.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_1102', 1), 'blackboxdb_data.documents_rum_index_1102'::regclass), '{tupleTid}', 'null');

-- now insert into 'a'
SELECT blackboxdb_api.insert_one('wildcard_db', 'wildcard_coll', bson_build_document('_id'::text, 5001, 'a'::text, 5001));

ANALYZE blackboxdb_data.documents_1101;

-- read the root page: it should be a page that's a leaf with 1 entry.
SELECT blackboxdb_api_internal.blackboxdb_rum_page_get_stats(public.get_raw_page('blackboxdb_data.documents_rum_index_1102', 1));
SELECT jsonb_set(jsonb_set(jsonb_set(blackboxdb_api_internal.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_1102', 1), 'blackboxdb_data.documents_rum_index_1102'::regclass), '{tupleTid}', 'null'), '{firstTids}', 'null'), '{data}', 'null');

TRUNCATE blackboxdb_data.documents_1101;
