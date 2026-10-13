SET search_path TO blackboxdb_api, blackboxdb_core, blackboxdb_api_catalog;
SET blackboxdb.next_collection_id TO 26950000;
SET blackboxdb.next_collection_index_id TO 26950000;

-- { elem: { $elemMatch: { k: { $exists: false } } } } matches a document when some element has no k, even if
-- a sibling element has one. With blackboxdb.enable_elemmatch_exists_false_null_bounds on, an ordered index on
-- elem.k (ci) finds those documents, as a collection scan (c) and a single-path index (cs) do.
-- Document-level $exists: false (no element has k) doesn't change.
SELECT COUNT(*) FROM (SELECT blackboxdb_api.insert_one('emexistsdb', 'c', d::blackboxdb_core.bson) FROM (VALUES
  ('{"_id": 1, "elem": [{"j": 1}]}'),
  ('{"_id": 2, "elem": [{"j": 1}, {"k": 5}]}'),
  ('{"_id": 3, "elem": [{"k": 5}, {"j": 1}]}'),
  ('{"_id": 4, "elem": [{"j": 1}, {"k": {"$maxKey": 1}}]}'),
  ('{"_id": 5, "elem": [{"k": {"$maxKey": 1}}, {"j": 1}]}'),
  ('{"_id": 6, "elem": [{"j": 1}, {"k": null}]}'),
  ('{"_id": 7, "elem": [{"j": 1}, {"k": {"$minKey": 1}}]}'),
  ('{"_id": 8, "elem": [{"j": 1}, {"k": "s"}]}'),
  ('{"_id": 9, "elem": [{"j": 1}, {"k": [1, 2]}]}'),
  ('{"_id": 10, "elem": [{"k": 5}]}'),
  ('{"_id": 11, "elem": [{"j": 1}, {"k": {"a": 1}}]}'),
  ('{"_id": 12, "elem": [{"j": 1}, {"k": true}]}'),
  ('{"_id": 13, "elem": [7, {"k": 5}]}'),
  ('{"_id": 14, "elem": []}'),
  ('{"_id": 15, "elem": {"k": 5}}'),
  ('{"_id": 16, "other": 1}'),
  ('{"_id": 17, "elem": [[{"j": 1}], {"k": 5}]}'),
  ('{"_id": 18, "elem": [{"k": null}]}')) v(d)) x;
SELECT COUNT(*) FROM (SELECT blackboxdb_api.insert_one('emexistsdb', 'ci', d::blackboxdb_core.bson) FROM (VALUES
  ('{"_id": 1, "elem": [{"j": 1}]}'),
  ('{"_id": 2, "elem": [{"j": 1}, {"k": 5}]}'),
  ('{"_id": 3, "elem": [{"k": 5}, {"j": 1}]}'),
  ('{"_id": 4, "elem": [{"j": 1}, {"k": {"$maxKey": 1}}]}'),
  ('{"_id": 5, "elem": [{"k": {"$maxKey": 1}}, {"j": 1}]}'),
  ('{"_id": 6, "elem": [{"j": 1}, {"k": null}]}'),
  ('{"_id": 7, "elem": [{"j": 1}, {"k": {"$minKey": 1}}]}'),
  ('{"_id": 8, "elem": [{"j": 1}, {"k": "s"}]}'),
  ('{"_id": 9, "elem": [{"j": 1}, {"k": [1, 2]}]}'),
  ('{"_id": 10, "elem": [{"k": 5}]}'),
  ('{"_id": 11, "elem": [{"j": 1}, {"k": {"a": 1}}]}'),
  ('{"_id": 12, "elem": [{"j": 1}, {"k": true}]}'),
  ('{"_id": 13, "elem": [7, {"k": 5}]}'),
  ('{"_id": 14, "elem": []}'),
  ('{"_id": 15, "elem": {"k": 5}}'),
  ('{"_id": 16, "other": 1}'),
  ('{"_id": 17, "elem": [[{"j": 1}], {"k": 5}]}'),
  ('{"_id": 18, "elem": [{"k": null}]}')) v(d)) x;
SELECT COUNT(*) FROM (SELECT blackboxdb_api.insert_one('emexistsdb', 'cs', d::blackboxdb_core.bson) FROM (VALUES
  ('{"_id": 1, "elem": [{"j": 1}]}'),
  ('{"_id": 2, "elem": [{"j": 1}, {"k": 5}]}'),
  ('{"_id": 3, "elem": [{"k": 5}, {"j": 1}]}'),
  ('{"_id": 4, "elem": [{"j": 1}, {"k": {"$maxKey": 1}}]}'),
  ('{"_id": 5, "elem": [{"k": {"$maxKey": 1}}, {"j": 1}]}'),
  ('{"_id": 6, "elem": [{"j": 1}, {"k": null}]}'),
  ('{"_id": 7, "elem": [{"j": 1}, {"k": {"$minKey": 1}}]}'),
  ('{"_id": 8, "elem": [{"j": 1}, {"k": "s"}]}'),
  ('{"_id": 9, "elem": [{"j": 1}, {"k": [1, 2]}]}'),
  ('{"_id": 10, "elem": [{"k": 5}]}'),
  ('{"_id": 11, "elem": [{"j": 1}, {"k": {"a": 1}}]}'),
  ('{"_id": 12, "elem": [{"j": 1}, {"k": true}]}'),
  ('{"_id": 13, "elem": [7, {"k": 5}]}'),
  ('{"_id": 14, "elem": []}'),
  ('{"_id": 15, "elem": {"k": 5}}'),
  ('{"_id": 16, "other": 1}'),
  ('{"_id": 17, "elem": [[{"j": 1}], {"k": 5}]}'),
  ('{"_id": 18, "elem": [{"k": null}]}')) v(d)) x;
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('emexistsdb', '{ "createIndexes": "ci", "indexes": [ { "key": { "elem.k": 1 }, "name": "ek_1", "enableOrderedIndex": 1 } ] }', TRUE);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('emexistsdb', '{ "createIndexes": "cs", "indexes": [ { "key": { "elem.k": 1 }, "name": "ek_1", "enableOrderedIndex": false } ] }', TRUE);

-- ids that a find returns: mode 'seq' (collection scan) or 'idx' (hinted elem.k index)
CREATE FUNCTION pg_temp.ids(coll text, filter text, mode text, flag bool) RETURNS text LANGUAGE plpgsql AS $fn$
DECLARE spec text; result text;
BEGIN
  spec := '{ "find": "' || coll || '", "filter": ' || filter || ', "projection": { "_id": 1 }' ||
          CASE WHEN mode = 'idx' THEN ', "hint": "ek_1" }' ELSE ' }' END;
  PERFORM set_config('blackboxdb.enable_elemmatch_exists_false_null_bounds', CASE WHEN flag THEN 'on' ELSE 'off' END, true);
  PERFORM set_config('enable_seqscan', CASE WHEN mode = 'idx' THEN 'off' ELSE 'on' END, true);
  PERFORM set_config('enable_indexscan', CASE WHEN mode = 'seq' THEN 'off' ELSE 'on' END, true);
  PERFORM set_config('enable_bitmapscan', CASE WHEN mode = 'seq' THEN 'off' ELSE 'on' END, true);
  EXECUTE format('SELECT string_agg(i::text, '','' ORDER BY i) FROM (SELECT substring(t.d::text from ''"\$numberInt" : "(\d+)"'')::int AS i FROM (SELECT document AS d FROM bson_aggregation_find(''emexistsdb'', %L::blackboxdb_core.bson)) t) n', spec) INTO result;
  RETURN COALESCE(result, '');
END $fn$;

SELECT 'em k exists false' AS filter, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$exists": false}}}}', 'idx', false) AS off_ordered_index, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$exists": false}}}}', 'idx', true) AS ordered_index, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$exists": false}}}}', 'seq', true) AS collection_scan, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$exists": false}}}}', 'idx', true) AS single_path_index;
SELECT 'em k exists false j 1' AS filter, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$exists": false}, "j": 1}}}', 'idx', false) AS off_ordered_index, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$exists": false}, "j": 1}}}', 'idx', true) AS ordered_index, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$exists": false}, "j": 1}}}', 'seq', true) AS collection_scan, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$exists": false}, "j": 1}}}', 'idx', true) AS single_path_index;
SELECT 'em k exists 0' AS filter, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$exists": 0}}}}', 'idx', false) AS off_ordered_index, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$exists": 0}}}}', 'idx', true) AS ordered_index, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$exists": 0}}}}', 'seq', true) AS collection_scan, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$exists": 0}}}}', 'idx', true) AS single_path_index;
SELECT 'em k not exists true' AS filter, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$not": {"$exists": true}}}}}', 'idx', false) AS off_ordered_index, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$not": {"$exists": true}}}}}', 'idx', true) AS ordered_index, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$not": {"$exists": true}}}}}', 'seq', true) AS collection_scan, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$not": {"$exists": true}}}}}', 'idx', true) AS single_path_index;
SELECT 'em k exists true' AS filter, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$exists": true}}}}', 'idx', false) AS off_ordered_index, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$exists": true}}}}', 'idx', true) AS ordered_index, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$exists": true}}}}', 'seq', true) AS collection_scan, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$exists": true}}}}', 'idx', true) AS single_path_index;
SELECT 'em k eq null' AS filter, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": null}}}', 'idx', false) AS off_ordered_index, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": null}}}', 'idx', true) AS ordered_index, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": null}}}', 'seq', true) AS collection_scan, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": null}}}', 'idx', true) AS single_path_index;
SELECT 'em k exists false k2 lt 9' AS filter, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$exists": false}, "j": {"$lt": 9}}}}', 'idx', false) AS off_ordered_index, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$exists": false}, "j": {"$lt": 9}}}}', 'idx', true) AS ordered_index, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$exists": false}, "j": {"$lt": 9}}}}', 'seq', true) AS collection_scan, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$exists": false}, "j": {"$lt": 9}}}}', 'idx', true) AS single_path_index;
SELECT 'doc elem.k exists false' AS filter, pg_temp.ids('ci', '{"elem.k": {"$exists": false}}', 'idx', false) AS off_ordered_index, pg_temp.ids('ci', '{"elem.k": {"$exists": false}}', 'idx', true) AS ordered_index, pg_temp.ids('c', '{"elem.k": {"$exists": false}}', 'seq', true) AS collection_scan, pg_temp.ids('cs', '{"elem.k": {"$exists": false}}', 'idx', true) AS single_path_index;

-- The ordered index answers the $elemMatch, and the $elemMatch qual is rechecked
SET blackboxdb.enable_elemmatch_exists_false_null_bounds TO on;
SET enable_seqscan TO off;
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_find('emexistsdb', '{ "find": "ci", "filter": { "elem": { "$elemMatch": { "k": { "$exists": false } } } } }');
RESET enable_seqscan;
RESET blackboxdb.enable_elemmatch_exists_false_null_bounds;
