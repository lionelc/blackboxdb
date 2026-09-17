SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 6770000;
SET blackboxdb.next_collection_id TO 6770;
SET blackboxdb.next_collection_index_id TO 6770;


-- cannot create indexes for cosmos_search without the flag enabled.
SELECT blackboxdb_api.create_collection('db', 'create_indexes_text');

-- invalid scenarios
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": "text", "b": 1, "c": "text" } } ] }', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": "hashed", "b": 1, "c": "text" } } ] }', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "c": "text" }, "name": "foo",  "expireAfterSeconds": 10 } ] }', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "c": "text" }, "name": "foo",  "unique": true } ] }', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "c.$**": "text" }, "name": "foo" } ] }', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "$**": "text" }, "name": "foo", "wildcardProjection": { "a": 1 } } ] }', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "$**": "text" }, "name": "idx1", "default_language": "ok" } ] }', true);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "$**": "text" }, "name": "idx1", "weights": { "a": 2, "b": 3, "c": 4, "d": 5 } } ] }', true);

-- create a valid indexes
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": "text" }, "name": "a_text" } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
SELECT * FROM blackboxdb_api_catalog.collection_indexes WHERE collection_id = 6770 ORDER BY 1,2,3;
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "a_text" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": "text", "b": "text", "c": 1 }, "name": "idx1" } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": 1, "b": "text", "c": 1 }, "name": "idx1" } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": 1, "b": "text", "c": "text" }, "name": "idx1" } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "$**": "text" }, "name": "idx1" } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": "text" }, "name": "idx1", "default_language": "es" } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": "text", "b": "text", "c": 1 }, "name": "idx1", "weights": { "b": 100, "c": 200 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": "text", "b": "text", "c": 1 }, "name": "idx1", "weights": { "c": 200, "d": 10 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": 1, "$**": "text" }, "name": "idx1" } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "$**": "text", "a": 1 }, "name": "idx1" } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": "text" }, "language_override": "idioma", "name": "idx1" } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

-- more tests with wildcard text indexes
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [{ "key": { "$**": "text", "a": "text" }, "name": "idx1" }]}', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
SELECT * FROM blackboxdb_api_catalog.collection_indexes WHERE collection_id = 6770 ORDER BY 1,2,3;
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [{ "key": { "a": "text", "$**": "text" }, "name": "idx1" }]}', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
SELECT * FROM blackboxdb_api_catalog.collection_indexes WHERE collection_id = 6770 ORDER BY 1,2,3;
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [{ "key": { "a": "text" }, "name": "idx1", "weights": { "$**": 1 } }]}', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
SELECT * FROM blackboxdb_api_catalog.collection_indexes WHERE collection_id = 6770 ORDER BY 1,2,3;
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [{ "key": { "a": "text" }, "name": "idx1", "weights": { "$**": 1, "b": 2 } }]}', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
SELECT * FROM blackboxdb_api_catalog.collection_indexes WHERE collection_id = 6770 ORDER BY 1,2,3;
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [{ "key": { "a": "text" }, "name": "idx1", "weights": { "b": 2, "$**": 1 } }]}', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
SELECT * FROM blackboxdb_api_catalog.collection_indexes WHERE collection_id = 6770 ORDER BY 1,2,3;
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [{ "key": { "a": "text", "$**": "text" }, "name": "idx1", "weights": { "b": 2 } }]}', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
SELECT * FROM blackboxdb_api_catalog.collection_indexes WHERE collection_id = 6770 ORDER BY 1,2,3;
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "$**": "text" }, "name": "idx1", "default_language": "es" } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

-- more tests with wildcard text indexes
-- this index spec corresponds to the index spec in the JS test: fts_blogwild.js
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [{ "key": { "dummy": "text" }, "name": "idx1", "weights": { "$**": 1, "title": 2 } }]}', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

-- test variations of the index spec - with the order of the weights, and with the wildcard
-- being specified in the key document
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [{ "key": { "dummy": "text" }, "name": "idx1", "weights": { "title": 2, "$**": 1 } }]}', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [{ "key": { "dummy": "text", "$**": "text" }, "name": "idx1", "weights": { "title": 2 } }]}', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');


-- we now create the same indexes as above, but with the metadata term `{ _fts: 'text', _ftsx: 1 }`
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "_fts": "text", "_ftsx": 1 }, "name": "a_text", "weights": { "a": 1 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
SELECT * FROM blackboxdb_api_catalog.collection_indexes WHERE collection_id = 6770 ORDER BY 1,2,3;
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "a_text" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "_fts": "text", "_ftsx": 1, "c": 1 }, "name": "idx1", "weights": { "a": 1, "b": 1 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": 1, "_fts": "text", "_ftsx": 1, "c": 1 }, "name": "idx1", "weights": { "b": 1 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": 1, "_fts": "text", "_ftsx": 1 }, "name": "idx1", "weights": { "b": 1, "c": 1 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "_fts": "text", "_ftsx": 1 }, "name": "idx1", "weights": { "$**": 1 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "_fts": "text", "_ftsx": 1 }, "name": "idx1", "default_language": "es", "weights": { "a": 1 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "_fts": "text", "_ftsx": 1, "c": 1 }, "name": "idx1", "weights": { "a": 1, "b": 100, "c": 200 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "_fts": "text", "_ftsx": 1, "c": 1 }, "name": "idx1", "weights": { "a": 1, "b": 1, "c": 200, "d": 10 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": 1, "_fts": "text", "_ftsx": 1 }, "name": "idx1", "weights": { "$**": 1 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "_fts": "text", "_ftsx": 1, "a": 1 }, "name": "idx1", "weights": { "$**": 1 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "_fts": "text", "_ftsx": 1 }, "language_override": "idioma", "name": "idx1", "weights": { "a": 1 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "_fts": "text", "_ftsx": 1 }, "name": "idx1", "default_language": "es", "weights": { "$**": 1 } } ] }', true);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770


-- shard and re-observe
SELECT blackboxdb_api.shard_collection('db', 'create_indexes_text', '{ "_id" : "hashed" }', false);
SELECT blackboxdb_api.list_indexes_cursor_first_page('db', '{ "listIndexes": "create_indexes_text" }');
\d blackboxdb_data.documents_6770

CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx1" }');


-- now create an index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": "text" }, "name": "a_text" } ] }', true);

-- creating more text indexes should just fail.
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "b": "text" }, "name": "b_text" } ] }', true);

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "c": 1, "b": "text" }, "name": "c_b_text" } ] }', true);

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "c": 1, "d": 1, "b": "text" }, "name": "c_b_text" } ] }', true);

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "c": 1, "d": "text", "b": "text" }, "name": "c_b_text" } ] }', true);

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "$**": "text" }, "name": "idx1", "weights": { "a": 2, "b": 3, "c": 4, "d": 5 } } ] }', true);

SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "f": "text" }, "name": "idx2", "default_language": "de" } ] }', true);

-- Validate enableDottedTerms opclass option with GUC on/off
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "a_text" }');

-- Create text index with GUC off: enabledottedterms should NOT appear in PG index options
SET blackboxdb.enableDottedValueTextIndexTerms to off;
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": "text" }, "name": "a_text" } ] }', true);
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "a_text" }');

-- Create text index with GUC on: enabledottedterms=true should appear in PG index options
SET blackboxdb.enableDottedValueTextIndexTerms to on;
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "a": "text" }, "name": "a_text" } ] }', true);
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "a_text" }');

-- Wildcard text index with GUC on: enabledottedterms=true should also appear
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', '{ "createIndexes": "create_indexes_text", "indexes": [ { "key": { "$**": "text" }, "name": "idx_wild_dotted" } ] }', true);
\d blackboxdb_data.documents_6770
CALL blackboxdb_api.drop_indexes('db', '{ "dropIndexes": "create_indexes_text", "index": "idx_wild_dotted" }');

RESET blackboxdb.enableDottedValueTextIndexTerms;
