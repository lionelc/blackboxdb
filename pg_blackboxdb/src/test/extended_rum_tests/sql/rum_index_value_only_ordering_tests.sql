SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

CREATE SCHEMA value_ordered_test_schema;

-- converts index term bytea to bson with flags
CREATE FUNCTION value_ordered_test_schema.gin_bson_index_term_to_bson(bytea) 
RETURNS bson
LANGUAGE c
AS '$libdir/pg_blackboxdb', 'gin_bson_index_term_to_bson';

CREATE FUNCTION value_ordered_test_schema.gin_bson_get_composite_path_generated_terms(blackboxdb_core.bson, text, int4, bool)
    RETURNS SETOF blackboxdb_core.bson LANGUAGE C IMMUTABLE PARALLEL SAFE STRICT AS '$libdir/pg_blackboxdb',
$$gin_bson_get_composite_path_generated_terms$$;

-- debug function to read index pages
CREATE OR REPLACE FUNCTION value_ordered_test_schema.blackboxdb_rum_page_get_entries(page bytea, indexRelId Oid)
RETURNS SETOF jsonb
LANGUAGE c
AS '$libdir/pg_blackboxdb_extended_rum_core', 'blackboxdb_rum_page_get_entries';

SET blackboxdb.next_collection_id TO 300;
SET blackboxdb.next_collection_index_id TO 300;

set blackboxdb.defaultUseCompositeOpClass to on;

SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'comp_odb', '{ "createIndexes": "comp_value_ordering", "indexes": [ { "name": "path1_1", "key": { "path1": 1 } }, { "name": "path1_-1", "key": { "path1": -1 } } ] }', TRUE);

-- insert only even values
set blackboxdb.enableValueOnlyIndexTerms to off;
SELECT COUNT(blackboxdb_api.insert_one('comp_odb', 'comp_value_ordering', bson_build_document('_id'::text, i, 'path1'::text, i * 2))) FROM generate_series(1, 10) i;

-- now set the GUC to on and insert only odd terms
set blackboxdb.enableValueOnlyIndexTerms to on;
SELECT COUNT(blackboxdb_api.insert_one('comp_odb', 'comp_value_ordering', bson_build_document('_id'::text, i + 10, 'path1'::text, (i * 2) - 1))) FROM generate_series(1, 10) i;

-- now walk the index terms and assert that they're ordered correctly and every odd term is value only
SELECT entry->> 'offset',
    value_ordered_test_schema.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea)
        FROM value_ordered_test_schema.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_302', 1), 'blackboxdb_data.documents_rum_index_302'::regclass) entry;

SELECT entry->> 'offset',
    value_ordered_test_schema.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea)
        FROM value_ordered_test_schema.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_303', 1), 'blackboxdb_data.documents_rum_index_303'::regclass) entry;

-- note that the terms are co-comparable - adding even values again does not add new terms
set blackboxdb.enableValueOnlyIndexTerms to on;
SELECT COUNT(blackboxdb_api.insert_one('comp_odb', 'comp_value_ordering', bson_build_document('_id'::text, i + 20, 'path1'::text, i * 2))) FROM generate_series(1, 10) i;

-- count should be 30
SELECT COUNT(*) FROM blackboxdb_api.collection('comp_odb', 'comp_value_ordering');

SELECT entry->> 'offset',
    value_ordered_test_schema.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea)
        FROM value_ordered_test_schema.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_302', 1), 'blackboxdb_data.documents_rum_index_302'::regclass) entry;

SELECT entry->> 'offset',
    value_ordered_test_schema.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea)
        FROM value_ordered_test_schema.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_303', 1), 'blackboxdb_data.documents_rum_index_303'::regclass) entry;

-- same is true when factoring in truncation.
TRUNCATE blackboxdb_data.documents_301;

-- insert with value only terms
set blackboxdb.enableValueOnlyIndexTerms to on;
SELECT blackboxdb_api.insert_one('comp_odb', 'comp_value_ordering', bson_build_document('_id'::text, 'trunc1'::text, 'path1'::text, ('abcde' || repeat('z', 3000) || '1')::text));

-- insert with value off terms
set blackboxdb.enableValueOnlyIndexTerms to off;
SELECT blackboxdb_api.insert_one('comp_odb', 'comp_value_ordering', bson_build_document('_id'::text, 'trunc2'::text, 'path1'::text, ('zyxwv' || repeat('z', 3000) || '1')::text));

-- now insert the other value with opposite flags
set blackboxdb.enableValueOnlyIndexTerms to off;
SELECT blackboxdb_api.insert_one('comp_odb', 'comp_value_ordering', bson_build_document('_id'::text, 'trunc3'::text, 'path1'::text, ('abcde' || repeat('z', 3000) || '1')::text));

-- insert with value off terms
set blackboxdb.enableValueOnlyIndexTerms to on;
SELECT blackboxdb_api.insert_one('comp_odb', 'comp_value_ordering', bson_build_document('_id'::text, 'trunc4'::text, 'path1'::text, ('zyxwv' || repeat('z', 3000) || '1')::text));

-- add non-truncated versions with that prefix with one with the flag and one not.
set blackboxdb.enableValueOnlyIndexTerms to off;
SELECT blackboxdb_api.insert_one('comp_odb', 'comp_value_ordering', bson_build_document('_id'::text, 'trunc5'::text, 'path1'::text, ('abcde' || repeat('z', 10) || '1')::text));

-- insert with value off terms
set blackboxdb.enableValueOnlyIndexTerms to on;
SELECT blackboxdb_api.insert_one('comp_odb', 'comp_value_ordering', bson_build_document('_id'::text, 'trunc6'::text, 'path1'::text, ('zyxwv' || repeat('z', 10) || '1')::text));


-- count should be 6
SELECT COUNT(*) FROM blackboxdb_api.collection('comp_odb', 'comp_value_ordering');

-- should have only 2 index terms with the truncation flags on (one value only, the other one not) and the lengths should match, and non-truncated sort before truncated
SELECT entry->> 'offset',
    value_ordered_test_schema.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea) ->> '$flags',
    length(value_ordered_test_schema.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea)::bytea),
    SUBSTRING(value_ordered_test_schema.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea) ->> '$', 0, 15)
        FROM value_ordered_test_schema.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_302', 1), 'blackboxdb_data.documents_rum_index_302'::regclass) entry;

SELECT entry->> 'offset',
    value_ordered_test_schema.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea) ->> '$flags',
    length(value_ordered_test_schema.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea)::bytea),
    SUBSTRING(value_ordered_test_schema.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea) ->> '$', 0, 15)
        FROM value_ordered_test_schema.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_303', 1), 'blackboxdb_data.documents_rum_index_303'::regclass) entry;

-- ensure value only truncation works the same with > 16 paths
set blackboxdb.enableValueOnlyIndexTerms to off;
SELECT * FROM
    value_ordered_test_schema.gin_bson_get_composite_path_generated_terms(
        '{ "a1": "aaaaaaaaaaaaaaa", "a2": "aaaaaaaaaaaaaaa", "a3": "aaaaaaaaaaaaaaa", "a4": "aaaaaaaaaaaaaaa", "a5": "aaaaaaaaaaaaaaa", "a6": "aaaaaaaaaaaaaaa", "a7": "aaaaaaaaaaaaaaa", "a8": "aaaaaaaaaaaaaaa", "a9": "aaaaaaaaaaaaaaa", "a10": "aaaaaaaaaaaaaaa", "a11": "aaaaaaaaaaaaaaa", "a12": "aaaaaaaaaaaaaaa", "a13": "aaaaaaaaaaaaaaa", "a14": "aaaaaaaaaaaaaaa", "a15": "aaaaaaaaaaaaaaa", "a16": "aaaaaaaaaaaaaaa", "a17": "aaaaaaaaaaaaaaa" }',
        '[ "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10", "a11", "a12", "a13", "a14", "a15", "a16", "a17" ]', 350, true);

SELECT * FROM
    value_ordered_test_schema.gin_bson_get_composite_path_generated_terms(
        '{ "a1": "aaaaaaaaaaaaaaa", "a2": "aaaaaaaaaaaaaaa", "a3": "aaaaaaaaaaaaaaa", "a4": "aaaaaaaaaaaaaaa", "a5": "aaaaaaaaaaaaaaa", "a6": "aaaaaaaaaaaaaaa", "a7": "aaaaaaaaaaaaaaa", "a8": "aaaaaaaaaaaaaaa", "a9": "aaaaaaaaaaaaaaa", "a10": "aaaaaaaaaaaaaaa", "a11": "aaaaaaaaaaaaaaa", "a12": "aaaaaaaaaaaaaaa", "a13": "aaaaaaaaaaaaaaa", "a14": "aaaaaaaaaaaaaaa", "a15": "aaaaaaaaaaaaaaa", "a16": "aaaaaaaaaaaaaaa", "a17": "aaaaaaaaaaaaaaa" }',
        '[ "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10", "a11", "a12", "a13", "a14", "a15", "a16", "a17" ]', 306, true);

set blackboxdb.enableValueOnlyIndexTerms to on;
SELECT * FROM
    value_ordered_test_schema.gin_bson_get_composite_path_generated_terms(
        '{ "a1": "aaaaaaaaaaaaaaa", "a2": "aaaaaaaaaaaaaaa", "a3": "aaaaaaaaaaaaaaa", "a4": "aaaaaaaaaaaaaaa", "a5": "aaaaaaaaaaaaaaa", "a6": "aaaaaaaaaaaaaaa", "a7": "aaaaaaaaaaaaaaa", "a8": "aaaaaaaaaaaaaaa", "a9": "aaaaaaaaaaaaaaa", "a10": "aaaaaaaaaaaaaaa", "a11": "aaaaaaaaaaaaaaa", "a12": "aaaaaaaaaaaaaaa", "a13": "aaaaaaaaaaaaaaa", "a14": "aaaaaaaaaaaaaaa", "a15": "aaaaaaaaaaaaaaa", "a16": "aaaaaaaaaaaaaaa", "a17": "aaaaaaaaaaaaaaa" }',
        '[ "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10", "a11", "a12", "a13", "a14", "a15", "a16", "a17" ]', 350, true);

SELECT * FROM
    value_ordered_test_schema.gin_bson_get_composite_path_generated_terms(
        '{ "a1": "aaaaaaaaaaaaaaa", "a2": "aaaaaaaaaaaaaaa", "a3": "aaaaaaaaaaaaaaa", "a4": "aaaaaaaaaaaaaaa", "a5": "aaaaaaaaaaaaaaa", "a6": "aaaaaaaaaaaaaaa", "a7": "aaaaaaaaaaaaaaa", "a8": "aaaaaaaaaaaaaaa", "a9": "aaaaaaaaaaaaaaa", "a10": "aaaaaaaaaaaaaaa", "a11": "aaaaaaaaaaaaaaa", "a12": "aaaaaaaaaaaaaaa", "a13": "aaaaaaaaaaaaaaa", "a14": "aaaaaaaaaaaaaaa", "a15": "aaaaaaaaaaaaaaa", "a16": "aaaaaaaaaaaaaaa", "a17": "aaaaaaaaaaaaaaa" }',
        '[ "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10", "a11", "a12", "a13", "a14", "a15", "a16", "a17" ]', 306, true);
