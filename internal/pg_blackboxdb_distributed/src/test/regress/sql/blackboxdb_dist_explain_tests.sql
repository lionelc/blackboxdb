SET search_path TO blackboxdb_api_catalog, blackboxdb_api, blackboxdb_core, blackboxdb_api_internal, public;
SET citus.next_shard_id TO 655000;
SET blackboxdb.next_collection_id TO 6550;
SET blackboxdb.next_collection_index_id TO 6550;

SELECT pg_catalog.set_config('blackboxdb.alternate_index_handler_name', 'extended_rum', false), extname FROM pg_extension WHERE extname = 'blackboxdb_extended_rum';

set blackboxdb.defaultUseCompositeOpClass to on;

CREATE OR REPLACE FUNCTION blackboxdb_distributed_test_helpers.blackboxdb_explain(
    p_explain_spec bson,
    p_append_cursor_params boolean DEFAULT FALSE)
 RETURNS bson
 LANGUAGE c
 VOLATILE
AS 'pg_blackboxdb', $$blackboxdb_explain$$;


CREATE OR REPLACE FUNCTION blackboxdb_distributed_test_helpers.explain_and_mask_numbers(
    p_explain_spec bson,
    p_append_cursor_params boolean DEFAULT FALSE)
 RETURNS SETOF text AS $$
 DECLARE
     explain_result bson;
 BEGIN
    SELECT blackboxdb_distributed_test_helpers.blackboxdb_explain(p_explain_spec, p_append_cursor_params) INTO explain_result;

    SELECT regexp_replace(explain_result::text, '"startupCost" : { "\$numberDouble" : "[0-9eE\.]+" }', '"startupCost" : { "$numberDouble" : "0.0" }', 1, 0, 'g')::bson INTO explain_result;
    SELECT regexp_replace(explain_result::text, '"totalCost" : { "\$numberDouble" : "[0-9eE\.]+" }', '"totalCost" : { "$numberDouble" : "0.0" }', 1, 0, 'g')::bson INTO explain_result;
    SELECT regexp_replace(explain_result::text, '"executionStartAtTimeMillis" : { "\$numberDouble" : "[0-9eE\.]+" }', '"executionStartAtTimeMillis" : { "$numberDouble" : "0.0" }', 1, 0, 'g')::bson INTO explain_result;
    SELECT regexp_replace(explain_result::text, '"executionTimeMillis" : { "\$numberDouble" : "[0-9eE\.]+" }', '"executionTimeMillis" : { "$numberDouble" : "0.0" }', 1, 0, 'g')::bson INTO explain_result;
    SELECT regexp_replace(explain_result::text, '"numBlocksFromCache" : { "\$numberDouble" : "[0-9eE\.]+" }', '"numBlocksFromCache" : { "$numberDouble" : "0.0" }', 1, 0, 'g')::bson INTO explain_result;
    SELECT regexp_replace(explain_result::text, '"numBlocksFromDisk" : { "\$numberDouble" : "[0-9eE\.]+" }', '"numBlocksFromDisk" : { "$numberDouble" : "0.0" }', 1, 0, 'g')::bson INTO explain_result;
    SELECT regexp_replace(explain_result::text, '"ioReadTimeMillis" : { "\$numberDouble" : "[0-9eE\.]+" }', '"ioReadTimeMillis" : { "$numberDouble" : "0.0" }', 1, 0, 'g')::bson INTO explain_result;
    SELECT regexp_replace(explain_result::text, '"totalDataSizeSortedBytesEstimate" : { "\$numberDouble" : "[0-9eE\.]+" }', '"totalDataSizeSortedBytesEstimate" : { "$numberDouble" : "0.0" }', 1, 0, 'g')::bson INTO explain_result;
    SELECT regexp_replace(explain_result::text, '"estimatedTotalKeysExamined" : { "\$numberDouble" : "[0-9eE\.]+" }', '"estimatedTotalKeysExamined" : { "$numberDouble" : "0.0" }', 1, 0, 'g')::bson INTO explain_result;

    RETURN QUERY WITH r1 AS (SELECT explain_result AS explain_val),
        r2 AS (SELECT regexp_split_to_table(explain_val::text, ',') AS line from r1),
        r3 AS ( SELECT row_number() over () as rn, line FROM r2)
        SELECT STRING_AGG(line, ',' ORDER BY rn ASC) || ',' FROM r3 GROUP BY round(rn / 4);
 END;
 $$ LANGUAGE plpgsql;


-- test index scan with a RUM index - here we print the extended details.
SELECT blackboxdb_api.insert_one('expdb', 'coll1', '{ "_id": 1, "a": 1, "b": 2 }');
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('expdb', '{ "createIndexes": "coll1", "indexes": [ { "key": { "a": 1, "b": 1 }, "name": "a_b_1" } ] }'::bson, TRUE);

set enable_seqscan to off;
set blackboxdb.forceDisableSeqScan to on;
SELECT blackboxdb_distributed_test_helpers.explain_and_mask_numbers('{ "explain": { "find": "coll1", "projection": { "c": 1 }, "filter": { "a": { "$gt": 1 }, "d": 1 }, "limit": 2 }, "$db": "expdb", "verbosity": "executionStats" }'::bson);

SELECT blackboxdb_distributed_test_helpers.explain_and_mask_numbers('{ "explain": { "find": "coll1", "projection": { "c": 1 }, "filter": { "a": { "$gt": 1 }, "d": 1 }, "sort": { "a": 1 }, "limit": 2 }, "$db": "expdb", "verbosity": "executionStats" }'::bson);

-- incremental sort.
SELECT blackboxdb_distributed_test_helpers.explain_and_mask_numbers('{ "explain": { "find": "coll1", "projection": { "c": 1 }, "filter": { "a": { "$gt": 1 }, "d": 1 }, "sort": { "a": 1, "d": 1 }, "limit": 2 }, "$db": "expdb", "verbosity": "executionStats" }'::bson);


-- now try with local execution off.
set citus.enable_local_execution to off;
set blackboxdb.useLocalExecutionShardQueries to off;
SELECT blackboxdb_distributed_test_helpers.explain_and_mask_numbers('{ "explain": { "find": "coll1", "projection": { "c": 1 }, "filter": { "a": { "$gt": 1 }, "d": 1 }, "sort": { "a": 1 }, "limit": 2 }, "$db": "expdb", "verbosity": "executionStats" }'::bson);
