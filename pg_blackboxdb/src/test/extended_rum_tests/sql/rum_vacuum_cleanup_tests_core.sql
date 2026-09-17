
SELECT name, setting, reset_val, boot_val FROM pg_settings WHERE name in ('blackboxdb_rum.track_incomplete_split', 'blackboxdb_rum.fix_incomplete_split');

SELECT blackboxdb_api.drop_collection('pvacuum_db', 'pclean');
SELECT blackboxdb_api.create_collection('pvacuum_db', 'pclean');

SELECT collection_id AS vacuum_col FROM blackboxdb_api_catalog.collections WHERE database_name = 'pvacuum_db' AND collection_name = 'pclean' \gset

-- disable autovacuum to have predicatability
SELECT FORMAT('ALTER TABLE blackboxdb_data.documents_%s set (autovacuum_enabled = off, toast.autovacuum_enabled = off, vacuum_index_cleanup = on, toast.vacuum_index_cleanup = on)', :vacuum_col) \gexec


SELECT COUNT(blackboxdb_api.insert_one('pvacuum_db', 'pclean',  FORMAT('{ "_id": %s, "a": %s }', i, i)::bson)) FROM generate_series(1, 1000) AS i;

SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'pvacuum_db',
    '{ "createIndexes": "pclean", "indexes": [ { "key": { "a": 1 }, "name": "a_1", "enableCompositeTerm": true } ] }', TRUE);

SELECT index_id AS vacuum_index_id FROM blackboxdb_api_catalog.collection_indexes WHERE collection_id = :vacuum_col AND index_id != :vacuum_col \gset

-- use the index - 
set blackboxdb.enableExtendedExplainPlans to on;
set blackboxdb.forceDisableSeqScan to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pvacuum_db', '{ "count": "pclean", "query": { "a": { "$exists": true } } }') $cmd$);

-- drop all the rows now
reset blackboxdb.forceDisableSeqScan;
SELECT blackboxdb_api.delete('pvacuum_db', '{ "delete": "pclean", "deletes": [ { "q": { "_id": { "$gte": 10 } }, "limit": 0 } ]}');
-- wait for the xmin horizon to advance past the DELETE so VACUUM is guaranteed
-- to consider the deleted tuples fully dead and run ambulkdelete
CALL blackboxdb_test_helpers.wait_for_vacuum_horizon();
set blackboxdb.forceDisableSeqScan to on;

-- query again (should return 10 rows with 1000 loops)
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pvacuum_db', '{ "count": "pclean", "query": { "a": { "$exists": true } } }') $cmd$);

-- vacuum the collection
SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP ON, DISABLE_PAGE_SKIPPING ON, PARALLEL 0) blackboxdb_data.documents_%s;', :vacuum_col) \gexec


-- query again (should return 10 rows but still with 1000 loops since we don't clean entries).
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pvacuum_db', '{ "count": "pclean", "query": { "a": { "$exists": true } } }') $cmd$);

reset blackboxdb.forceDisableSeqScan;
SELECT COUNT(blackboxdb_api.insert_one('pvacuum_db', 'pclean',  FORMAT('{ "_id": %s, "a": %s }', i, i)::bson)) FROM generate_series(1001, 2000) AS i;
SELECT blackboxdb_api.delete('pvacuum_db', '{ "delete": "pclean", "deletes": [ { "q": { "_id": { "$gte": 1010 } }, "limit": 0 } ]}');
-- wait for the xmin horizon to advance past the DELETE so VACUUM is guaranteed
-- to consider the deleted tuples fully dead and run ambulkdelete
CALL blackboxdb_test_helpers.wait_for_vacuum_horizon();
set blackboxdb.forceDisableSeqScan to on;

-- now set the guc to clean the entries
SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP ON, DISABLE_PAGE_SKIPPING ON, PARALLEL 0) blackboxdb_data.documents_%s;', :vacuum_col) \gexec
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pvacuum_db', '{ "count": "pclean", "query": { "a": { "$exists": true } } }') $cmd$);

-- repeat one more time
reset blackboxdb.forceDisableSeqScan;
SELECT COUNT(blackboxdb_api.insert_one('pvacuum_db', 'pclean',  FORMAT('{ "_id": %s, "a": %s }', i, i)::bson)) FROM generate_series(2001, 3000) AS i;
SELECT blackboxdb_api.delete('pvacuum_db', '{ "delete": "pclean", "deletes": [ { "q": { "_id": { "$gte": 2010 } }, "limit": 0 } ]}');
-- wait for the xmin horizon to advance past the DELETE so VACUUM is guaranteed
-- to consider the deleted tuples fully dead and run ambulkdelete
CALL blackboxdb_test_helpers.wait_for_vacuum_horizon();
set blackboxdb.forceDisableSeqScan to on;

-- now set the guc to clean the entries
SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP ON, DISABLE_PAGE_SKIPPING ON, PARALLEL 0) blackboxdb_data.documents_%s;', :vacuum_col) \gexec
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pvacuum_db', '{ "count": "pclean", "query": { "a": { "$exists": true } } }') $cmd$);

reset blackboxdb.forceDisableSeqScan;

-- insert some entries to create posting trees.
SELECT COUNT(blackboxdb_api.insert_one('pvacuum_db', 'pclean',  FORMAT('{ "_id": -%s, "a": 500 }', i)::bson)) FROM generate_series(1, 3000) AS i;

-- now delete everything includig posting tree entries.
SELECT blackboxdb_api.delete('pvacuum_db', '{ "delete": "pclean", "deletes": [ { "q": { "_id": { "$lt": 2000 } }, "limit": 0 } ]}');
-- wait for the xmin horizon to advance past the DELETE so VACUUM is guaranteed
-- to consider the deleted tuples fully dead and run ambulkdelete
CALL blackboxdb_test_helpers.wait_for_vacuum_horizon();

set blackboxdb.forceDisableSeqScan to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pvacuum_db', '{ "count": "pclean", "query": { "a": { "$exists": true } } }') $cmd$);

-- now set the guc to clean up entry pages
set blackboxdb_rum.prune_rum_empty_pages to on;
set client_min_messages to DEBUG1;
SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP ON, DISABLE_PAGE_SKIPPING ON, PARALLEL 0) blackboxdb_data.documents_%s;', :vacuum_col) \gexec
reset client_min_messages;

-- delete one more row to ensure vacuum has a chance to clean up
reset blackboxdb.forceDisableSeqScan;
SELECT blackboxdb_api.delete('pvacuum_db', '{ "delete": "pclean", "deletes": [ { "q": { "_id": { "$lte": 2000 } }, "limit": 0 } ]}');
-- wait for the xmin horizon to advance past the DELETE so VACUUM is guaranteed
-- to consider the deleted tuples fully dead and run ambulkdelete
CALL blackboxdb_test_helpers.wait_for_vacuum_horizon();
set client_min_messages to DEBUG1;
SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP ON, DISABLE_PAGE_SKIPPING ON, PARALLEL 0) blackboxdb_data.documents_%s;', :vacuum_col) \gexec
reset client_min_messages;

set blackboxdb.forceDisableSeqScan to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pvacuum_db', '{ "count": "pclean", "query": { "a": { "$exists": true } } }') $cmd$);

-- introduce dead pages and use the repair functions to clean up the index.
reset blackboxdb.forceDisableSeqScan;
SELECT FORMAT('TRUNCATE blackboxdb_data.documents_%s;', :vacuum_col) \gexec

-- insert 3000 docs
SELECT COUNT(blackboxdb_api.insert_one('pvacuum_db', 'pclean',  FORMAT('{ "_id": %s, "a": %s }', i, i)::bson)) FROM generate_series(1, 3000) AS i;

set blackboxdb.forceDisableSeqScan to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pvacuum_db', '{ "count": "pclean", "query": { "a": { "$exists": true } } }') $cmd$);
reset blackboxdb.forceDisableSeqScan;

-- delete 3000 docs
set blackboxdb_rum.prune_rum_empty_pages to off;
SELECT blackboxdb_api.delete('pvacuum_db', '{ "delete": "pclean", "deletes": [ { "q": { "_id": { "$exists": true } }, "limit": 0 } ]}');
-- wait for the xmin horizon to advance past the DELETE so VACUUM is guaranteed
-- to consider the deleted tuples fully dead and run ambulkdelete
CALL blackboxdb_test_helpers.wait_for_vacuum_horizon();
SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP ON, DISABLE_PAGE_SKIPPING ON, PARALLEL 0) blackboxdb_data.documents_%s;', :vacuum_col) \gexec

-- we should have a lot of empty pages
set blackboxdb.forceDisableSeqScan to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pvacuum_db', '{ "count": "pclean", "query": { "a": { "$exists": true } } }') $cmd$);
reset blackboxdb.forceDisableSeqScan;

-- call the repair function.
SELECT blackboxdb_api_internal.rum_prune_empty_entries_on_index(('blackboxdb_data.documents_rum_index_' || :vacuum_index_id)::regclass);

-- should have fewer entries due to pruning.
set blackboxdb.forceDisableSeqScan to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pvacuum_db', '{ "count": "pclean", "query": { "a": { "$exists": true } } }') $cmd$);
reset blackboxdb.forceDisableSeqScan;

set blackboxdb_rum.prune_rum_empty_pages to on;
SELECT blackboxdb_api_internal.rum_prune_empty_entries_on_index(('blackboxdb_data.documents_rum_index_' || :vacuum_index_id)::regclass);

set blackboxdb.forceDisableSeqScan to on;
SELECT blackboxdb_test_helpers.run_explain_and_trim($cmd$ EXPLAIN (COSTS OFF, ANALYZE ON, VERBOSE OFF, BUFFERS OFF, SUMMARY OFF, TIMING OFF) SELECT document FROM bson_aggregation_count('pvacuum_db', '{ "count": "pclean", "query": { "a": { "$exists": true } } }') $cmd$);
reset blackboxdb.forceDisableSeqScan;

-- test multi-level posting tree cleanup
SELECT FORMAT('TRUNCATE blackboxdb_data.documents_%s;', :vacuum_col) \gexec

-- insert some entries
SELECT COUNT(blackboxdb_api.insert_one('pvacuum_db', 'pclean',  FORMAT('{ "_id": %s, "a": %s }', i, i)::bson)) FROM generate_series(1, 1000) AS i;

-- now insert entries that trigger a multi-level posting tree (allow only 50 entries per data page)
set blackboxdb_rum.data_page_posting_tree_size = 3;
SELECT COUNT(blackboxdb_api.insert_one('pvacuum_db', 'pclean',  FORMAT('{ "_id": -%s, "a": 500 }', i)::bson)) FROM generate_series(1, 15000) AS i;

-- now assert that it produces a multi-level tree
SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP ON, DISABLE_PAGE_SKIPPING ON, PARALLEL 0) blackboxdb_data.documents_%s;', :vacuum_col) \gexec
SELECT blackboxdb_api_internal.blackboxdb_rum_get_meta_page_info(public.get_raw_page(('blackboxdb_data.documents_rum_index_' || :vacuum_index_id), 0));

WITH r1 AS (SELECT i, blackboxdb_api_internal.blackboxdb_rum_page_get_stats(public.get_raw_page(('blackboxdb_data.documents_rum_index_' || :vacuum_index_id), i)) AS entry FROM generate_series(1, 21) i)
SELECT * FROM r1 WHERE entry->>'flagsStr' LIKE '%DATA%' ORDER by (entry->>'flags')::int8, i ASC;

-- now delete everything.
SELECT blackboxdb_api.delete('pvacuum_db', '{ "delete": "pclean", "deletes": [ { "q": { "_id": { "$exists": true } }, "limit": 0 } ]}');
-- wait for the xmin horizon to advance past the DELETE so VACUUM is guaranteed
-- to consider the deleted tuples fully dead and run ambulkdelete
CALL blackboxdb_test_helpers.wait_for_vacuum_horizon();
set client_min_messages to LOG;
SELECT FORMAT('VACUUM (FREEZE ON, INDEX_CLEANUP ON, DISABLE_PAGE_SKIPPING ON, PARALLEL 0) blackboxdb_data.documents_%s;', :vacuum_col) \gexec

WITH r1 AS (SELECT i, blackboxdb_api_internal.blackboxdb_rum_page_get_stats(public.get_raw_page(('blackboxdb_data.documents_rum_index_' || :vacuum_index_id), i)) AS entry FROM generate_series(1, 21) i)
SELECT * FROM r1 WHERE entry->>'flagsStr' LIKE '%DATA%' ORDER by (entry->>'flags')::int8, i ASC;
