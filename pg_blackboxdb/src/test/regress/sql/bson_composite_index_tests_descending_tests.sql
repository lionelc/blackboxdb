SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

SET blackboxdb.next_collection_id TO 7400;
SET blackboxdb.next_collection_index_id TO 7400;


CREATE OR REPLACE FUNCTION blackboxdb_test_helpers.gin_bson_get_descending_composite_path_generated_terms(document blackboxdb_core.bson, pathSpec text, termLimit int4, addMetadata bool, wildcardIndex int4 = -1)
    RETURNS SETOF blackboxdb_core.bson LANGUAGE C IMMUTABLE PARALLEL SAFE STRICT AS '$libdir/pg_blackboxdb', $$gin_bson_get_composite_path_generated_terms$$;

-- test scenarios of term generation for composite path
SELECT * FROM blackboxdb_test_helpers.gin_bson_get_descending_composite_path_generated_terms('{ "a": 1, "b": 2 }', '[ "a", "b" ]', 2000, false);
SELECT * FROM blackboxdb_test_helpers.gin_bson_get_descending_composite_path_generated_terms('{ "a": [ 1, 2, 3 ], "b": 2 }', '[ "a", "b" ]', 2000, false);
SELECT * FROM blackboxdb_test_helpers.gin_bson_get_descending_composite_path_generated_terms('{ "a": 1, "b": [ true, false ] }', '[ "a", "b" ]', 2000, false);
SELECT * FROM blackboxdb_test_helpers.gin_bson_get_descending_composite_path_generated_terms('{ "a": [ 1, 2, 3 ], "b": [ true, false ] }', '[ "a", "b" ]', 2000, false);

-- test when one doesn't exist
SELECT * FROM blackboxdb_test_helpers.gin_bson_get_descending_composite_path_generated_terms('{ "b": [ true, false ] }', '[ "a", "b" ]', 2000, false);
SELECT * FROM blackboxdb_test_helpers.gin_bson_get_descending_composite_path_generated_terms('{ "a": [ 1, 2, 3 ] }', '[ "a", "b" ]', 2000, false);

-- test when one gets truncated (a has 29 letters, truncation limit is 50 /2 so 25 per path)
SELECT * FROM blackboxdb_test_helpers.gin_bson_get_descending_composite_path_generated_terms('{ "a": "aaaaaaaaaaaaaaaaaaaaaaaaaaaa", "b": 1 }', '[ "a", "b" ]', 50, true);

-- create a table and insert some data.

-- create a regular index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'comp_db', '{ "createIndexes": "comp_collection_desc", "indexes": [ { "name": "comp_index", "key": { "a": -1, "b": -1 } } ] }');

-- create a non-composite index with a different name and same key (works)
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'comp_db', '{ "createIndexes": "comp_collection_desc", "indexes": [ { "name": "comp_index1", "key": { "a": -1, "b": -1 }, "enableCompositeTerm": false } ] }', TRUE);

-- check the index
\d blackboxdb_data.documents_7400

-- now drop the regular index
CALL blackboxdb_api.drop_indexes('comp_db', '{ "dropIndexes": "comp_collection_desc", "index": "comp_index1" }');

\d blackboxdb_data.documents_7400

SELECT blackboxdb_api.insert_one('comp_db', 'comp_collection_desc', '{ "_id": 1, "a": 1, "b": true }');
SELECT blackboxdb_api.insert_one('comp_db', 'comp_collection_desc', '{ "_id": 2, "a": [ 1, 2 ], "b": true }');
SELECT blackboxdb_api.insert_one('comp_db', 'comp_collection_desc', '{ "_id": 3, "a": 1, "b": [ true, false ] }');
SELECT blackboxdb_api.insert_one('comp_db', 'comp_collection_desc', '{ "_id": 4, "a": [ 1, 2 ], "b": [ true, false ] }');

-- disable seqscan
set blackboxdb.forceDisableSeqScan to on;

-- pushes to the composite index
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": 1, "b": true } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": 2, "b": true } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": 2, "b": false } }');

-- validate specifying just one path
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": 2 } }');

-- this fails (requires specifiying column 0)
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "b": false } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$exists": true }, "b": false } }');

-- prefix inequality
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$gt": 0 }, "b": false } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$gt": 1 }, "b": false } }');

-- suffix inequality
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": 1, "b":  { "$gt": false } } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": 2, "b":  { "$gt": false } } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": 1, "b":  { "$gt": true } } }');

-- now add some cross-type members
SELECT blackboxdb_api.insert_one('comp_db', 'comp_collection_desc', '{ "_id": 5, "a": "string1", "b": true }');
SELECT blackboxdb_api.insert_one('comp_db', 'comp_collection_desc', '{ "_id": 6, "a": "string2", "b": true }');

SELECT blackboxdb_api.insert_one('comp_db', 'comp_collection_desc', '{ "_id": 7, "a": { "key": "string2" }, "b": true }');

-- has cross type values
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$exists": true }, "b": true } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$gte": { "$minKey": 1 } }, "b": true } }');

-- applies type bracketing
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$gt": 0 }, "b": true } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$gte": "string0" }, "b": true } }');

SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$type": "string" }, "b": true } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$type": "object" }, "b": true } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$type": "number" }, "b": true } }');

-- runtime recheck
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$regex": ".+2$" }, "b": true } }');

-- add large keys
SELECT blackboxdb_api.insert_one('comp_db', 'comp_collection_desc', FORMAT('{ "_id": 8, "a": { "key": "%s" }, "b": "%s" }', repeat('a', 10000), repeat('a', 10000))::bson);

SELECT FORMAT('{ "find": "comp_collection_desc", "filter": { "a": { "key": "%s" }, "b": "%s" }, "projection": { "_id": 1 } }', repeat('a', 5000), repeat('a', 5000)) AS q1 \gset
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', :'q1'::bson);

SELECT FORMAT('{ "find": "comp_collection_desc", "filter": { "a": { "key": "%s" }, "b": "%s" }, "projection": { "_id": 1 } }', repeat('a', 8000), repeat('a', 8000)) AS q1 \gset
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', :'q1'::bson);

SELECT FORMAT('{ "find": "comp_collection_desc", "filter": { "a": { "key": "%s" }, "b": "%s" }, "projection": { "_id": 1 } }', repeat('a', 10000), repeat('a', 10000)) AS q1 \gset
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', :'q1'::bson);

SELECT FORMAT('{ "find": "comp_collection_desc", "filter": { "a": { "key": "%s" } }, "projection": { "_id": 1 } }', repeat('a', 10000)) AS q1 \gset
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', :'q1'::bson);

-- this fails since column 0 is not specified
SELECT FORMAT('{ "find": "comp_collection_desc", "filter": { "b": "%s" }, "projection": { "_id": 1 } }', repeat('a', 10000)) AS q1 \gset
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', :'q1'::bson);

SELECT FORMAT('{ "find": "comp_collection_desc", "filter": { "a": { "$exists": true }, "b": "%s" }, "projection": { "_id": 1 } }', repeat('a', 10000)) AS q1 \gset
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', :'q1'::bson);

-- multi-bound queries
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$in": [ 1, 2 ] }, "b": true } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$in": [ 1, 2 ] }, "b": false } }');

SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$in": [ 2, "string1" ] }, "b": { "$in": [ true, false ] } } }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$in": [ 1, 2 ] }, "b": { "$in": [ true, false ] } } }');

SELECT document FROM blackboxdb_api_catalog.bson_aggregation_find('comp_db', '{ "find": "comp_collection_desc", "filter": { "a": { "$in": [ 1, 2 ] }, "a": { "$lt": 2 }, "b": { "$in": [ true, false ] } } }');
