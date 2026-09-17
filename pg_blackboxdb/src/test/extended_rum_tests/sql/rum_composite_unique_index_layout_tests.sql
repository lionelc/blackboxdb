SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

SET blackboxdb.next_collection_id TO 700;
SET blackboxdb.next_collection_index_id TO 700;

set blackboxdb.defaultUseCompositeOpClass to on;

-- first create with unique hash off.
set blackboxdb.enableCompositeUniqueHash to off;
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('uniquedb', '{ "createIndexes": "uniqueColl", "indexes": [ { "key": { "a": 1 }, "name": "a_1", "unique": true } ]}', TRUE);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('uniquedb', '{ "createIndexes": "uniqueColl", "indexes": [ { "key": { "b": 1, "c": 1 }, "name": "b_c_1", "unique": true } ]}', TRUE);

\d blackboxdb_data.documents_701

SELECT COUNT(blackboxdb_api.insert_one('uniquedb', 'uniqueColl', bson_build_document('_id'::text, i, 'a'::text, i, 'b'::text, i, 'c'::text, i))) FROM generate_series(1, 10) i;

VACUUM (FREEZE ON, INDEX_CLEANUP ON) blackboxdb_data.documents_701;

-- now query the layout of both indexes
SELECT blackboxdb_api_internal.blackboxdb_rum_get_meta_page_info(public.get_raw_page('blackboxdb_data.documents_rum_index_702', 0));
SELECT blackboxdb_api_internal.blackboxdb_rum_get_meta_page_info(public.get_raw_page('blackboxdb_data.documents_rum_index_703', 0));

SELECT i, (entry->>'offset')::int8, (entry->>'attrNumber')::int8, (entry->>'firstEntry') FROM generate_series(1, 1) i JOIN LATERAL (
    SELECT entry FROM blackboxdb_api_internal.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_703', i), 'blackboxdb_data.documents_rum_index_703'::regclass) entry) right_query ON TRUE
ORDER BY i, (entry->>'offset')::int8;

SELECT i, (entry->>'offset')::int8, (entry->>'attrNumber')::int8, (entry->>'firstEntry') FROM generate_series(1, 1) i JOIN LATERAL (
    SELECT entry FROM blackboxdb_api_internal.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_702', i), 'blackboxdb_data.documents_rum_index_702'::regclass) entry) right_query ON TRUE
ORDER BY i, (entry->>'offset')::int8;

-- recheck with composite unique hash
set blackboxdb.enableCompositeUniqueHash to on;
CALL blackboxdb_api.drop_indexes('uniquedb', '{ "dropIndexes": "uniqueColl", "index": [ "a_1", "b_c_1" ]}');
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('uniquedb', '{ "createIndexes": "uniqueColl", "indexes": [ { "key": { "a": 1 }, "name": "a_1", "unique": true } ]}', TRUE);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('uniquedb', '{ "createIndexes": "uniqueColl", "indexes": [ { "key": { "b": 1, "c": 1 }, "name": "b_c_1", "unique": true } ]}', TRUE);

-- now query the layout of both indexes
SELECT blackboxdb_api_internal.blackboxdb_rum_get_meta_page_info(public.get_raw_page('blackboxdb_data.documents_rum_index_704', 0));
SELECT blackboxdb_api_internal.blackboxdb_rum_get_meta_page_info(public.get_raw_page('blackboxdb_data.documents_rum_index_705', 0));

SELECT i, (entry->>'offset')::int8, (entry->>'attrNumber')::int8, (entry->>'firstEntry') FROM generate_series(1, 1) i JOIN LATERAL (
    SELECT entry FROM blackboxdb_api_internal.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_704', i), 'blackboxdb_data.documents_rum_index_704'::regclass) entry) right_query ON TRUE
ORDER BY i, (entry->>'offset')::int8;

SELECT i, (entry->>'offset')::int8, (entry->>'attrNumber')::int8, (entry->>'firstEntry') FROM generate_series(1, 1) i JOIN LATERAL (
    SELECT entry FROM blackboxdb_api_internal.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_705', i), 'blackboxdb_data.documents_rum_index_705'::regclass) entry) right_query ON TRUE
ORDER BY i, (entry->>'offset')::int8;
