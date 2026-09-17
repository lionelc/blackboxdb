SET search_path TO blackboxdb_api_catalog, blackboxdb_core, public;
SET blackboxdb.next_collection_id TO 600;
SET blackboxdb.next_collection_index_id TO 600;

CREATE SCHEMA rum_dead_tuple_test;

-- converts index term bytea to bson with flags
CREATE FUNCTION rum_dead_tuple_test.gin_bson_index_term_to_bson(bytea) 
RETURNS bson
LANGUAGE c
AS '$libdir/pg_blackboxdb', 'gin_bson_index_term_to_bson';


-- debug function to read index pages
CREATE OR REPLACE FUNCTION rum_dead_tuple_test.blackboxdb_rum_page_get_entries(page bytea, indexOid Oid)
RETURNS SETOF jsonb
LANGUAGE c
AS '$libdir/pg_blackboxdb_extended_rum_core', 'blackboxdb_rum_page_get_entries';

CREATE OR REPLACE FUNCTION rum_dead_tuple_test.blackboxdb_rum_page_get_data_items(page bytea)
RETURNS SETOF jsonb
LANGUAGE c
AS '$libdir/pg_blackboxdb_extended_rum_core', 'blackboxdb_rum_page_get_data_items';

CREATE OR REPLACE FUNCTION rum_dead_tuple_test.blackboxdb_rum_page_get_stats(page bytea)
RETURNS jsonb
LANGUAGE c
AS '$libdir/pg_blackboxdb_extended_rum_core', 'blackboxdb_rum_page_get_stats';


CREATE OR REPLACE FUNCTION rum_dead_tuple_test.blackboxdb_rum_revive_index_tuples(index_oid oid, dry_run bool)
RETURNS void
LANGUAGE c
AS '$libdir/pg_blackboxdb_extended_rum_core', 'blackboxdb_rum_repair_revive_all_pages_and_tuples';

SELECT blackboxdb_api.drop_collection('pvacuum_db_2', 'p_dead_tup');
SELECT blackboxdb_api.create_collection('pvacuum_db_2', 'p_dead_tup');

SELECT collection_id AS vacuum_col FROM blackboxdb_api_catalog.collections WHERE database_name = 'pvacuum_db_2' AND collection_name = 'p_dead_tup' \gset

-- disable autovacuum to have predicatability
SELECT FORMAT('ALTER TABLE blackboxdb_data.documents_%s set (autovacuum_enabled = off)', :vacuum_col) \gexec


SELECT COUNT(blackboxdb_api.insert_one('pvacuum_db_2', 'p_dead_tup',  FORMAT('{ "_id": %s, "a": %s }', i, i)::bson)) FROM generate_series(1, 1000) AS i;

SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'pvacuum_db_2',
    '{ "createIndexes": "p_dead_tup", "indexes": [ { "key": { "a": 1 }, "name": "a_1", "enableCompositeTerm": true } ] }', TRUE);

\d blackboxdb_data.documents_601

set blackboxdb.enableExtendedExplainPlans to on;
set blackboxdb.forceDisableSeqScan to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

reset blackboxdb.forceDisableSeqScan;
SELECT blackboxdb_api.delete('pvacuum_db_2', '{ "delete": "p_dead_tup", "deletes": [ { "q": { "_id": { "$gte": 10 } }, "limit": 0 } ]}');
set blackboxdb.forceDisableSeqScan to on;

set blackboxdb.forceDisableSeqScan to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- vacuum the main table with FREEZE - but skip the index prune (to generate LP_DEAD scenario deterministically)
SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP OFF) blackboxdb_data.documents_%s', :vacuum_col) \gexec

-- now enable index dead tuple cleanup & run the query twice.
set blackboxdb_rum.enable_support_dead_index_items to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- recovers the dead tuple values as is.
set blackboxdb_rum.enable_support_dead_index_items to off;
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- now insert a document - should resurrect the tuple.
-- first read the tuples & metadata.
SELECT entry->> 'offset' AS offset,
    entry->> 'entryFlags' AS flags,
    rum_dead_tuple_test.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea) ->> '$' AS index_value
        FROM rum_dead_tuple_test.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_602', 3), 'blackboxdb_data.documents_rum_index_602'::regclass) entry
    LIMIT 20;

-- update a single node and write to it. The index term is "revived"
SELECT blackboxdb_api.insert_one('pvacuum_db_2', 'p_dead_tup',  '{ "_id": -1, "a": 18 }'::bson);

-- print index again.
SELECT entry->> 'offset' AS offset,
    entry->> 'entryFlags' AS flags,
    rum_dead_tuple_test.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea) ->> '$' AS index_value
        FROM rum_dead_tuple_test.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_602', 3), 'blackboxdb_data.documents_rum_index_602'::regclass) entry
    LIMIT 20;

-- that row is returned properly but the count of rows is correct.
set blackboxdb_rum.enable_support_dead_index_items to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);


-- repeat with multi-key scenarios with posting lists
SELECT FORMAT('TRUNCATE blackboxdb_data.documents_%s', :vacuum_col) \gexec
SELECT COUNT(blackboxdb_api.insert_one('pvacuum_db_2', 'p_dead_tup',  FORMAT('{ "_id": %s, "a": [ %s, %s, %s ] }', i, i, i * 2, i * 3)::bson)) FROM generate_series(1, 10000) AS i;


set blackboxdb.enableExtendedExplainPlans to on;
set blackboxdb.forceDisableSeqScan to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- here we leave behind index tuples 1 to 10, even numbers and multiples of 3 until 30.
reset blackboxdb.forceDisableSeqScan;
SELECT blackboxdb_api.delete('pvacuum_db_2', '{ "delete": "p_dead_tup", "deletes": [ { "q": { "_id": { "$gte": 10 } }, "limit": 0 } ]}');
set blackboxdb.forceDisableSeqScan to on;


-- vacuum the main table with FREEZE - but skip the index prune (to generate LP_DEAD scenario deterministically)
SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP OFF) blackboxdb_data.documents_%s', :vacuum_col) \gexec

-- now enable index dead tuple cleanup & run the query twice.
set blackboxdb_rum.enable_support_dead_index_items to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- this will only clean up even more occurrences (since duplicate TID bitmap won't track kill_prior_tuple).
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- this will only clean up even more occurrences (since duplicate TID bitmap won't track kill_prior_tuple).
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- this will only clean up even more occurrences (since duplicate TID bitmap won't track kill_prior_tuple).
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- recovers the dead tuple values as is.
set blackboxdb_rum.enable_support_dead_index_items to off;
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- now resurrect multiple terms (should resurrect even when flag is off)
set blackboxdb_rum.enable_support_dead_index_items to off;

-- now insert a document - should resurrect the tuple.
-- first read the tuples & metadata.
SELECT entry->> 'offset' AS offset,
    entry->> 'entryFlags' AS flags,
    rum_dead_tuple_test.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea) ->> '$' AS index_value
        FROM rum_dead_tuple_test.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_602', 3),  'blackboxdb_data.documents_rum_index_602'::regclass) entry
    LIMIT 20;

-- update a single node and write to it. The index term is "revived"
SELECT blackboxdb_api.insert_one('pvacuum_db_2', 'p_dead_tup',  '{ "_id": -1, "a": [ 17, 12, 19 ] }'::bson);

-- print index again.
SELECT entry->> 'offset' AS offset,
    entry->> 'entryFlags' AS flags,
    rum_dead_tuple_test.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea) ->> '$' AS index_value
        FROM rum_dead_tuple_test.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_602', 3),  'blackboxdb_data.documents_rum_index_602'::regclass) entry
    LIMIT 20;

-- now revive all the tuples using the repair function
SELECT rum_dead_tuple_test.blackboxdb_rum_revive_index_tuples('blackboxdb_data.documents_rum_index_602'::regclass::oid, false);

-- check which entries are dead (should be none)
SELECT entry->> 'offset' AS offset, entry->> 'entryFlags' AS flags
        FROM rum_dead_tuple_test.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_602', 3),  'blackboxdb_data.documents_rum_index_602'::regclass) entry
    WHERE entry->> 'entryFlags' != '1' LIMIT 20;

-- now repeat the scenarios above with posting trees.
SELECT FORMAT('TRUNCATE blackboxdb_data.documents_%s', :vacuum_col) \gexec
SELECT COUNT(blackboxdb_api.insert_one('pvacuum_db_2', 'p_dead_tup',  FORMAT('{ "_id": %s, "a": 5 }', i, i)::bson)) FROM generate_series(1, 10000) AS i;

SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

reset blackboxdb.forceDisableSeqScan;
SELECT blackboxdb_api.delete('pvacuum_db_2', '{ "delete": "p_dead_tup", "deletes": [ { "q": { "_id": { "$gte": 10 } }, "limit": 0 } ]}');
set blackboxdb.forceDisableSeqScan to on;

-- vacuum the main table with FREEZE - but skip the index prune (to generate LP_DEAD scenario deterministically)
SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP OFF) blackboxdb_data.documents_%s', :vacuum_col) \gexec

-- read the entry tree
SELECT entry->> 'offset' AS offset,
    entry ->> 'entryType' AS postingType,
    entry ->> 'tupleTid' AS postingTreeRoot,
    rum_dead_tuple_test.gin_bson_index_term_to_bson((entry->>'firstEntry')::bytea) ->> '$' AS index_value
        FROM rum_dead_tuple_test.blackboxdb_rum_page_get_entries(public.get_raw_page('blackboxdb_data.documents_rum_index_602', 1),  'blackboxdb_data.documents_rum_index_602'::regclass) entry
    LIMIT 20;

-- read the posting root
SELECT entry FROM rum_dead_tuple_test.blackboxdb_rum_page_get_data_items(public.get_raw_page('blackboxdb_data.documents_rum_index_602', 2)) entry OFFSET 1;

WITH r1 AS (SELECT i, rum_dead_tuple_test.blackboxdb_rum_page_get_stats(public.get_raw_page('blackboxdb_data.documents_rum_index_602', i)) as entry FROM generate_series(3, 8) i)
SELECT i AS pageId, entry-> 'flagsStr' AS flagsStr, entry-> 'leftLink' AS leftLink, entry->'rightLink' AS rightLink FROM r1 ORDER by i ASC;

-- query right after delete: estimatedEntryCount shows up at 1000
set blackboxdb_rum.enable_support_dead_index_items to off;
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- now set the GUC and query twice
set blackboxdb_rum.enable_support_dead_index_items to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- now set the GUC and query twice
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- check page metadata
WITH r1 AS (SELECT i, rum_dead_tuple_test.blackboxdb_rum_page_get_stats(public.get_raw_page('blackboxdb_data.documents_rum_index_602', i)) as entry FROM generate_series(3, 8) i)
SELECT i AS pageId, entry-> 'flagsStr' AS flagsStr, entry-> 'leftLink' AS leftLink, entry->'rightLink' AS rightLink FROM r1 ORDER by i ASC;


WITH r1 AS (SELECT i AS pageId FROM generate_series(3, 8) i)
SELECT pageId, rightQuery.* FROM r1 JOIN LATERAL (
    SELECT COUNT(entry) FROM rum_dead_tuple_test.blackboxdb_rum_page_get_data_items(public.get_raw_page('blackboxdb_data.documents_rum_index_602', pageId)) entry
) AS rightQuery ON true ORDER BY pageId ASC;

-- kill the remaining rows
reset blackboxdb.forceDisableSeqScan;
SELECT blackboxdb_api.delete('pvacuum_db_2', '{ "delete": "p_dead_tup", "deletes": [ { "q": { "_id": { "$gte": 0 } }, "limit": 0 } ]}');
set blackboxdb.forceDisableSeqScan to on;

SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP OFF) blackboxdb_data.documents_%s', :vacuum_col) \gexec

-- now set the GUC and query twice
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- check page metadata
WITH r1 AS (SELECT i, rum_dead_tuple_test.blackboxdb_rum_page_get_stats(public.get_raw_page('blackboxdb_data.documents_rum_index_602', i)) as entry FROM generate_series(3, 8) i)
SELECT i AS pageId, entry-> 'flagsStr' AS flagsStr, entry-> 'leftLink' AS leftLink, entry->'rightLink' AS rightLink FROM r1 ORDER by i ASC;


-- insert rows (to revive data pages)
SELECT COUNT(blackboxdb_api.insert_one('pvacuum_db_2', 'p_dead_tup',  FORMAT('{ "_id": %s, "a": 5 }', i, i)::bson)) FROM generate_series(-100, -1) AS i;


WITH r1 AS (SELECT i, rum_dead_tuple_test.blackboxdb_rum_page_get_stats(public.get_raw_page('blackboxdb_data.documents_rum_index_602', i)) as entry FROM generate_series(3, 8) i)
SELECT i AS pageId, entry-> 'flagsStr' AS flagsStr, entry-> 'leftLink' AS leftLink, entry->'rightLink' AS rightLink FROM r1 ORDER by i ASC;


WITH r1 AS (SELECT i AS pageId FROM generate_series(3, 8) i)
SELECT pageId, rightQuery.* FROM r1 JOIN LATERAL (
    SELECT COUNT(entry) FROM rum_dead_tuple_test.blackboxdb_rum_page_get_data_items(public.get_raw_page('blackboxdb_data.documents_rum_index_602', pageId)) entry
) AS rightQuery ON true ORDER BY pageId ASC;

-- query returns correct rows
SELECT blackboxdb_test_helpers.run_explain_and_trim(
    $cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_find('pvacuum_db_2', '{ "find": "p_dead_tup", "filter": { "a": { "$exists": true } } }') $cmd$);

-- revive and print
SELECT rum_dead_tuple_test.blackboxdb_rum_revive_index_tuples('blackboxdb_data.documents_rum_index_602'::regclass::oid, false);
WITH r1 AS (SELECT i, rum_dead_tuple_test.blackboxdb_rum_page_get_stats(public.get_raw_page('blackboxdb_data.documents_rum_index_602', i)) as entry FROM generate_series(3, 8) i)
SELECT i AS pageId, entry-> 'flagsStr' AS flagsStr, entry-> 'leftLink' AS leftLink, entry->'rightLink' AS rightLink FROM r1 ORDER by i ASC;
