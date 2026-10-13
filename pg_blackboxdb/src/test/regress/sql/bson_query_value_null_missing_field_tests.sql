SET search_path TO blackboxdb_api, blackboxdb_core, blackboxdb_api_catalog;
SET blackboxdb.next_collection_id TO 26940000;
SET blackboxdb.next_collection_index_id TO 26940000;

-- A missing field compares like null. So when a query runs on a single value ($elemMatch, a $pull condition,
-- arrayFilters), an element without k matches { k: { $lte: null } } and { k: { $gte: null } }, as it matches
-- { k: null }, also through arrays inside the element; the $not forms exclude it. With blackboxdb.enable_value_null_missing_field_match
-- on, a collection scan, an ordered index on elem.k (ci) and a single-path index on elem.k (cs) all return that.
SELECT COUNT(*) FROM (SELECT blackboxdb_api.insert_one('valnulldb', 'c', d::blackboxdb_core.bson) FROM (VALUES
  ('{"_id": 1, "elem": [{"j": 1}]}'),
  ('{"_id": 2, "elem": [{"k": 5}]}'),
  ('{"_id": 3, "elem": [{"k": null}]}'),
  ('{"_id": 4, "elem": [{"j": 1}, {"k": {"$maxKey": 1}}]}'),
  ('{"_id": 5, "elem": [7]}'),
  ('{"_id": 6, "elem": [{"k": {"$minKey": 1}}]}'),
  ('{"_id": 7, "elem": [{"k": []}]}'),
  ('{"_id": 8, "elem": [{"a": [{}, {"k": 1}]}]}'),
  ('{"_id": 9, "elem": [{"a": [{"k": 1}, {}]}]}'),
  ('{"_id": 10, "elem": [{"a": [{"k": null}]}]}'),
  ('{"_id": 11, "elem": [{"k": [null]}]}'),
  ('{"_id": 12, "elem": [{"a": 1}]}'),
  ('{"_id": 13, "elem": [{"a": []}]}'),
  ('{"_id": 14, "elem": [{"a": {"k": 2}}]}')) v(d)) x;
SELECT COUNT(*) FROM (SELECT blackboxdb_api.insert_one('valnulldb', 'ci', d::blackboxdb_core.bson) FROM (VALUES
  ('{"_id": 1, "elem": [{"j": 1}]}'),
  ('{"_id": 2, "elem": [{"k": 5}]}'),
  ('{"_id": 3, "elem": [{"k": null}]}'),
  ('{"_id": 4, "elem": [{"j": 1}, {"k": {"$maxKey": 1}}]}'),
  ('{"_id": 5, "elem": [7]}'),
  ('{"_id": 6, "elem": [{"k": {"$minKey": 1}}]}'),
  ('{"_id": 7, "elem": [{"k": []}]}'),
  ('{"_id": 8, "elem": [{"a": [{}, {"k": 1}]}]}'),
  ('{"_id": 9, "elem": [{"a": [{"k": 1}, {}]}]}'),
  ('{"_id": 10, "elem": [{"a": [{"k": null}]}]}'),
  ('{"_id": 11, "elem": [{"k": [null]}]}'),
  ('{"_id": 12, "elem": [{"a": 1}]}'),
  ('{"_id": 13, "elem": [{"a": []}]}'),
  ('{"_id": 14, "elem": [{"a": {"k": 2}}]}')) v(d)) x;
SELECT COUNT(*) FROM (SELECT blackboxdb_api.insert_one('valnulldb', 'cs', d::blackboxdb_core.bson) FROM (VALUES
  ('{"_id": 1, "elem": [{"j": 1}]}'),
  ('{"_id": 2, "elem": [{"k": 5}]}'),
  ('{"_id": 3, "elem": [{"k": null}]}'),
  ('{"_id": 4, "elem": [{"j": 1}, {"k": {"$maxKey": 1}}]}'),
  ('{"_id": 5, "elem": [7]}'),
  ('{"_id": 6, "elem": [{"k": {"$minKey": 1}}]}'),
  ('{"_id": 7, "elem": [{"k": []}]}'),
  ('{"_id": 8, "elem": [{"a": [{}, {"k": 1}]}]}'),
  ('{"_id": 9, "elem": [{"a": [{"k": 1}, {}]}]}'),
  ('{"_id": 10, "elem": [{"a": [{"k": null}]}]}'),
  ('{"_id": 11, "elem": [{"k": [null]}]}'),
  ('{"_id": 12, "elem": [{"a": 1}]}'),
  ('{"_id": 13, "elem": [{"a": []}]}'),
  ('{"_id": 14, "elem": [{"a": {"k": 2}}]}')) v(d)) x;
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('valnulldb', '{ "createIndexes": "ci", "indexes": [ { "key": { "elem.k": 1 }, "name": "ek_1", "enableOrderedIndex": 1 } ] }', TRUE);
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('valnulldb', '{ "createIndexes": "cs", "indexes": [ { "key": { "elem.k": 1 }, "name": "ek_1", "enableOrderedIndex": false } ] }', TRUE);

-- ids that a find returns, by a collection scan or through the hinted elem.k index, with the flag off or on
CREATE FUNCTION pg_temp.ids(coll text, filter text, use_index bool, flag bool) RETURNS text LANGUAGE plpgsql AS $fn$
DECLARE spec text; result text;
BEGIN
  spec := '{ "find": "' || coll || '", "filter": ' || filter || ', "projection": { "_id": 1 }' ||
          CASE WHEN use_index THEN ', "hint": "ek_1" }' ELSE ' }' END;
  PERFORM set_config('blackboxdb.enable_value_null_missing_field_match', CASE WHEN flag THEN 'on' ELSE 'off' END, true);
  PERFORM set_config('enable_seqscan', CASE WHEN use_index THEN 'off' ELSE 'on' END, true);
  PERFORM set_config('enable_indexscan', CASE WHEN use_index THEN 'on' ELSE 'off' END, true);
  PERFORM set_config('enable_bitmapscan', CASE WHEN use_index THEN 'on' ELSE 'off' END, true);
  EXECUTE format('SELECT string_agg(i::text, '','' ORDER BY i) FROM (SELECT substring(t.d::text from ''"\$numberInt" : "(\d+)"'')::int AS i FROM (SELECT document AS d FROM bson_aggregation_find(''valnulldb'', %L::blackboxdb_core.bson)) t) n', spec) INTO result;
  RETURN COALESCE(result, '');
END $fn$;

-- the documents after an update on a fresh copy (without the scalar element), with the flag off or on
CREATE FUNCTION pg_temp.after_update(coll text, upd text, flag bool) RETURNS text LANGUAGE plpgsql AS $fn$
DECLARE result text;
BEGIN
  PERFORM set_config('blackboxdb.enable_value_null_missing_field_match', CASE WHEN flag THEN 'on' ELSE 'off' END, true);
  PERFORM blackboxdb_api.insert_one('valnulldb', coll, d::blackboxdb_core.bson) FROM (VALUES ('{"_id": 1, "elem": [{"j": 1}]}'), ('{"_id": 2, "elem": [{"k": 5}]}'), ('{"_id": 3, "elem": [{"k": null}]}'), ('{"_id": 4, "elem": [{"j": 1}, {"k": {"$maxKey": 1}}]}'), ('{"_id": 6, "elem": [{"k": {"$minKey": 1}}]}'), ('{"_id": 7, "elem": [{"k": []}]}'), ('{"_id": 8, "elem": [{"a": [{}, {"k": 1}]}]}'), ('{"_id": 9, "elem": [{"a": [{"k": 1}, {}]}]}'), ('{"_id": 10, "elem": [{"a": [{"k": null}]}]}'), ('{"_id": 11, "elem": [{"k": [null]}]}'), ('{"_id": 12, "elem": [{"a": 1}]}'), ('{"_id": 13, "elem": [{"a": []}]}'), ('{"_id": 14, "elem": [{"a": {"k": 2}}]}')) v(d);
  PERFORM blackboxdb_api.update('valnulldb', format('{ "update": "%s", "updates": [ %s ] }', coll, upd)::blackboxdb_core.bson);
  EXECUTE format('SELECT string_agg(t.d::text, '' ; '' ORDER BY substring(t.d::text from ''"\$numberInt" : "(\d+)"'')::int) FROM (SELECT document AS d FROM bson_aggregation_find(''valnulldb'', %L::blackboxdb_core.bson)) t', '{ "find": "' || coll || '", "projection": { "elem": 1 } }') INTO result;
  RETURN result;
END $fn$;

SELECT 'em k eq null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": null}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": null}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": null}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": null}}}', true, true) AS single_path_index;
SELECT 'em k lte null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$lte": null}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$lte": null}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$lte": null}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$lte": null}}}}', true, true) AS single_path_index;
SELECT 'em k gte null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$gte": null}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$gte": null}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$gte": null}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$gte": null}}}}', true, true) AS single_path_index;
SELECT 'em k lt null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$lt": null}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$lt": null}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$lt": null}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$lt": null}}}}', true, true) AS single_path_index;
SELECT 'em k gt null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$gt": null}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$gt": null}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$gt": null}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$gt": null}}}}', true, true) AS single_path_index;
SELECT 'em k in null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$in": [null]}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$in": [null]}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$in": [null]}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$in": [null]}}}}', true, true) AS single_path_index;
SELECT 'em k in null 5' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$in": [null, 5]}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$in": [null, 5]}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$in": [null, 5]}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$in": [null, 5]}}}}', true, true) AS single_path_index;
SELECT 'em k nin null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$nin": [null]}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$nin": [null]}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$nin": [null]}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$nin": [null]}}}}', true, true) AS single_path_index;
SELECT 'em k ne null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$ne": null}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$ne": null}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$ne": null}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$ne": null}}}}', true, true) AS single_path_index;
SELECT 'em k not lte null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$not": {"$lte": null}}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$not": {"$lte": null}}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$not": {"$lte": null}}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$not": {"$lte": null}}}}}', true, true) AS single_path_index;
SELECT 'em k not gte null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$not": {"$gte": null}}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$not": {"$gte": null}}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$not": {"$gte": null}}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$not": {"$gte": null}}}}}', true, true) AS single_path_index;
SELECT 'em k exists true' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$exists": true}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$exists": true}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$exists": true}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$exists": true}}}}', true, true) AS single_path_index;
SELECT 'em ak eq null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"a.k": null}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"a.k": null}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"a.k": null}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"a.k": null}}}', true, true) AS single_path_index;
SELECT 'em ak lte null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"a.k": {"$lte": null}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"a.k": {"$lte": null}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"a.k": {"$lte": null}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"a.k": {"$lte": null}}}}', true, true) AS single_path_index;
SELECT 'em ak gte null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"a.k": {"$gte": null}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"a.k": {"$gte": null}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"a.k": {"$gte": null}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"a.k": {"$gte": null}}}}', true, true) AS single_path_index;
SELECT 'em ak in null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"a.k": {"$in": [null]}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"a.k": {"$in": [null]}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"a.k": {"$in": [null]}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"a.k": {"$in": [null]}}}}', true, true) AS single_path_index;
SELECT 'em ak ne null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"a.k": {"$ne": null}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"a.k": {"$ne": null}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"a.k": {"$ne": null}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"a.k": {"$ne": null}}}}', true, true) AS single_path_index;
SELECT 'em ak nin null' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"a.k": {"$nin": [null]}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"a.k": {"$nin": [null]}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"a.k": {"$nin": [null]}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"a.k": {"$nin": [null]}}}}', true, true) AS single_path_index;
SELECT 'em k lte 5' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$lte": 5}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$lte": 5}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$lte": 5}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$lte": 5}}}}', true, true) AS single_path_index;
SELECT 'em k gte 5' AS filter, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$gte": 5}}}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem": {"$elemMatch": {"k": {"$gte": 5}}}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem": {"$elemMatch": {"k": {"$gte": 5}}}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem": {"$elemMatch": {"k": {"$gte": 5}}}}', true, true) AS single_path_index;
SELECT 'doc elem.k lte null' AS filter, pg_temp.ids('c', '{"elem.k": {"$lte": null}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem.k": {"$lte": null}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem.k": {"$lte": null}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem.k": {"$lte": null}}', true, true) AS single_path_index;
SELECT 'doc elem.a.k eq null' AS filter, pg_temp.ids('c', '{"elem.a.k": null}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem.a.k": null}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem.a.k": null}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem.a.k": null}', true, true) AS single_path_index;
SELECT 'doc elem.a.k lte null' AS filter, pg_temp.ids('c', '{"elem.a.k": {"$lte": null}}', false, false) AS off_collection_scan, pg_temp.ids('c', '{"elem.a.k": {"$lte": null}}', false, true) AS collection_scan, pg_temp.ids('ci', '{"elem.a.k": {"$lte": null}}', true, true) AS ordered_index, pg_temp.ids('cs', '{"elem.a.k": {"$lte": null}}', true, true) AS single_path_index;
SELECT 'pull k lte null' AS update, pg_temp.after_update('u0_off', '{"q": {}, "u": {"$pull": {"elem": {"k": {"$lte": null}}}}, "multi": true}', false) AS off_documents, pg_temp.after_update('u0_on', '{"q": {}, "u": {"$pull": {"elem": {"k": {"$lte": null}}}}, "multi": true}', true) AS documents;
SELECT 'pull k gte null' AS update, pg_temp.after_update('u1_off', '{"q": {}, "u": {"$pull": {"elem": {"k": {"$gte": null}}}}, "multi": true}', false) AS off_documents, pg_temp.after_update('u1_on', '{"q": {}, "u": {"$pull": {"elem": {"k": {"$gte": null}}}}, "multi": true}', true) AS documents;
SELECT 'pull k eq null' AS update, pg_temp.after_update('u2_off', '{"q": {}, "u": {"$pull": {"elem": {"k": null}}}, "multi": true}', false) AS off_documents, pg_temp.after_update('u2_on', '{"q": {}, "u": {"$pull": {"elem": {"k": null}}}, "multi": true}', true) AS documents;
SELECT 'pull k in null' AS update, pg_temp.after_update('u3_off', '{"q": {}, "u": {"$pull": {"elem": {"k": {"$in": [null]}}}}, "multi": true}', false) AS off_documents, pg_temp.after_update('u3_on', '{"q": {}, "u": {"$pull": {"elem": {"k": {"$in": [null]}}}}, "multi": true}', true) AS documents;
SELECT 'pull ak eq null' AS update, pg_temp.after_update('u4_off', '{"q": {}, "u": {"$pull": {"elem": {"a.k": null}}}, "multi": true}', false) AS off_documents, pg_temp.after_update('u4_on', '{"q": {}, "u": {"$pull": {"elem": {"a.k": null}}}, "multi": true}', true) AS documents;
SELECT 'pull ak lte null' AS update, pg_temp.after_update('u5_off', '{"q": {}, "u": {"$pull": {"elem": {"a.k": {"$lte": null}}}}, "multi": true}', false) AS off_documents, pg_temp.after_update('u5_on', '{"q": {}, "u": {"$pull": {"elem": {"a.k": {"$lte": null}}}}, "multi": true}', true) AS documents;
SELECT 'af k lte null' AS update, pg_temp.after_update('u6_off', '{"q": {}, "u": {"$set": {"elem.$[x].m": 1}}, "multi": true, "arrayFilters": [{"x.k": {"$lte": null}}]}', false) AS off_documents, pg_temp.after_update('u6_on', '{"q": {}, "u": {"$set": {"elem.$[x].m": 1}}, "multi": true, "arrayFilters": [{"x.k": {"$lte": null}}]}', true) AS documents;
SELECT 'af k gte null' AS update, pg_temp.after_update('u7_off', '{"q": {}, "u": {"$set": {"elem.$[x].m": 1}}, "multi": true, "arrayFilters": [{"x.k": {"$gte": null}}]}', false) AS off_documents, pg_temp.after_update('u7_on', '{"q": {}, "u": {"$set": {"elem.$[x].m": 1}}, "multi": true, "arrayFilters": [{"x.k": {"$gte": null}}]}', true) AS documents;
SELECT 'af k eq null' AS update, pg_temp.after_update('u8_off', '{"q": {}, "u": {"$set": {"elem.$[x].m": 1}}, "multi": true, "arrayFilters": [{"x.k": null}]}', false) AS off_documents, pg_temp.after_update('u8_on', '{"q": {}, "u": {"$set": {"elem.$[x].m": 1}}, "multi": true, "arrayFilters": [{"x.k": null}]}', true) AS documents;
SELECT 'af k in null' AS update, pg_temp.after_update('u9_off', '{"q": {}, "u": {"$set": {"elem.$[x].m": 1}}, "multi": true, "arrayFilters": [{"x.k": {"$in": [null]}}]}', false) AS off_documents, pg_temp.after_update('u9_on', '{"q": {}, "u": {"$set": {"elem.$[x].m": 1}}, "multi": true, "arrayFilters": [{"x.k": {"$in": [null]}}]}', true) AS documents;
SELECT 'af ak eq null' AS update, pg_temp.after_update('u10_off', '{"q": {}, "u": {"$set": {"elem.$[x].m": 1}}, "multi": true, "arrayFilters": [{"x.a.k": null}]}', false) AS off_documents, pg_temp.after_update('u10_on', '{"q": {}, "u": {"$set": {"elem.$[x].m": 1}}, "multi": true, "arrayFilters": [{"x.a.k": null}]}', true) AS documents;
SELECT 'af ak lte null' AS update, pg_temp.after_update('u11_off', '{"q": {}, "u": {"$set": {"elem.$[x].m": 1}}, "multi": true, "arrayFilters": [{"x.a.k": {"$lte": null}}]}', false) AS off_documents, pg_temp.after_update('u11_on', '{"q": {}, "u": {"$set": {"elem.$[x].m": 1}}, "multi": true, "arrayFilters": [{"x.a.k": {"$lte": null}}]}', true) AS documents;
