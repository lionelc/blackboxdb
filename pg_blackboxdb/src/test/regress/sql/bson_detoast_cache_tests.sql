SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

SET blackboxdb.next_collection_id TO 26870000;
SET blackboxdb.next_collection_index_id TO 26870000;

-- 200 documents stored out of line: 12,800 characters of md5 hex text each (does not compress).
DO $$
DECLARE i int;
BEGIN
FOR i IN 1..200 LOOP
PERFORM blackboxdb_api.insert_one('detoastdb', 'docs', FORMAT('{ "_id": %s, "g": %s, "v": %s, "big": "%s" }', i, i % 5, (i * 37) % 200, (SELECT string_agg(md5((i * 1000 + j)::text), '') FROM generate_series(1, 400) j))::blackboxdb_core.bson);
END LOOP;
END;
$$;

-- The documents really are out of line.
SELECT pg_total_relation_size(reltoastrelid) > 200 * 8192 AS stored_out_of_line
FROM pg_class WHERE relname = (SELECT 'documents_' || collection_id FROM blackboxdb_api_catalog.collections WHERE database_name = 'detoastdb' AND collection_name = 'docs');

-- With the cache off, no read path may touch it: after a filter with a projection, a group and a sort over the
-- documents, the session has no cache memory at all.
SET blackboxdb_core.enable_detoast_cache TO off;
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "docs", "pipeline": [ { "$match": { "v": { "$gte": 190 } } }, { "$project": { "_id": 1, "len": { "$strLenCP": "$big" } } }, { "$sort": { "_id": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "docs", "pipeline": [ { "$group": { "_id": "$g", "len": { "$max": { "$strLenCP": "$big" } } } }, { "$sort": { "_id": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "docs", "pipeline": [ { "$sort": { "v": -1, "_id": 1 } }, { "$limit": 3 }, { "$project": { "_id": 1, "v": 1 } } ], "cursor": {} }');
SELECT count(*) AS cache_contexts FROM pg_backend_memory_contexts WHERE name = 'BlackboxDB detoast cache';

-- Each query runs with the cache off and then on; the results must be identical.
SET blackboxdb_core.enable_detoast_cache TO off;
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "docs", "pipeline": [ { "$group": { "_id": "$g", "n": { "$sum": 1 }, "s": { "$sum": "$v" }, "len": { "$max": { "$strLenCP": "$big" } } } }, { "$sort": { "_id": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "docs", "pipeline": [ { "$match": { "g": { "$gte": 2 }, "v": { "$lt": 150 } } }, { "$sort": { "v": -1, "_id": 1 } }, { "$limit": 5 }, { "$project": { "_id": 1, "v": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "docs", "pipeline": [ { "$match": { "_id": { "$lte": 3 } } }, { "$lookup": { "from": "docs", "localField": "g", "foreignField": "g", "as": "same" } }, { "$project": { "_id": 1, "n": { "$size": "$same" }, "first": { "$min": "$same.v" } } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "docs", "pipeline": [ { "$match": { "_id": 42 } }, { "$project": { "_id": 1, "head": { "$substrCP": [ "$big", 0, 16 ] }, "len": { "$strLenCP": "$big" } } } ], "cursor": {} }');
SET blackboxdb_core.enable_detoast_cache TO on;
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "docs", "pipeline": [ { "$group": { "_id": "$g", "n": { "$sum": 1 }, "s": { "$sum": "$v" }, "len": { "$max": { "$strLenCP": "$big" } } } }, { "$sort": { "_id": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "docs", "pipeline": [ { "$match": { "g": { "$gte": 2 }, "v": { "$lt": 150 } } }, { "$sort": { "v": -1, "_id": 1 } }, { "$limit": 5 }, { "$project": { "_id": 1, "v": 1 } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "docs", "pipeline": [ { "$match": { "_id": { "$lte": 3 } } }, { "$lookup": { "from": "docs", "localField": "g", "foreignField": "g", "as": "same" } }, { "$project": { "_id": 1, "n": { "$size": "$same" }, "first": { "$min": "$same.v" } } } ], "cursor": {} }');
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "docs", "pipeline": [ { "$match": { "_id": 42 } }, { "$project": { "_id": 1, "head": { "$substrCP": [ "$big", 0, 16 ] }, "len": { "$strLenCP": "$big" } } } ], "cursor": {} }');

-- A document updated inside the transaction is read back with its new content.
BEGIN;
SET LOCAL blackboxdb_core.enable_detoast_cache TO on;
SELECT document FROM bson_aggregation_find('detoastdb', '{ "find": "docs", "filter": { "_id": 7 }, "projection": { "v": 1, "g": 1 } }');
SELECT blackboxdb_api.update('detoastdb', '{ "update": "docs", "updates": [ { "q": { "_id": 7 }, "u": { "$set": { "v": 999 } } } ] }');
SELECT document FROM bson_aggregation_find('detoastdb', '{ "find": "docs", "filter": { "_id": 7 }, "projection": { "v": 1, "g": 1 } }');
ROLLBACK;
SET blackboxdb_core.enable_detoast_cache TO on;
SELECT document FROM bson_aggregation_find('detoastdb', '{ "find": "docs", "filter": { "_id": 7 }, "projection": { "v": 1, "g": 1 } }');

-- With the cache, a row whose document feeds two sort keys detoasts it once: fewer buffer hits.
CREATE FUNCTION detoast_cache_hits(pipeline text) RETURNS bigint AS $$
DECLARE plan json;
BEGIN
    EXECUTE 'EXPLAIN (ANALYZE ON, BUFFERS ON, TIMING OFF, SUMMARY OFF, FORMAT JSON) SELECT document FROM bson_aggregation_pipeline(''detoastdb'', ' || quote_literal(pipeline) || '::bson)' INTO plan;
    RETURN (plan->0->'Plan'->>'Shared Hit Blocks')::bigint;
END;
$$ LANGUAGE plpgsql;

SET blackboxdb_core.enable_detoast_cache TO off;
SELECT detoast_cache_hits('{ "aggregate": "docs", "pipeline": [ { "$sort": { "v": -1, "_id": 1 } }, { "$limit": 3 } ], "cursor": {} }') > 0 AS warm;
CREATE TEMP TABLE detoast_hits AS SELECT detoast_cache_hits('{ "aggregate": "docs", "pipeline": [ { "$sort": { "v": -1, "_id": 1 } }, { "$limit": 3 } ], "cursor": {} }') AS off_hits;
SET blackboxdb_core.enable_detoast_cache TO on;
SELECT detoast_cache_hits('{ "aggregate": "docs", "pipeline": [ { "$sort": { "v": -1, "_id": 1 } }, { "$limit": 3 } ], "cursor": {} }') < 0.75 * off_hits AS fewer_buffer_hits FROM detoast_hits;

-- A document is reused only within its statement: the second statement of a transaction reads it again.
SET blackboxdb_core.enable_detoast_cache TO on;
SELECT detoast_cache_hits('{ "aggregate": "docs", "pipeline": [ { "$match": { "_id": 42 } }, { "$project": { "len": { "$strLenCP": "$big" } } } ], "cursor": {} }') > 0 AS warm;
BEGIN;
SELECT detoast_cache_hits('{ "aggregate": "docs", "pipeline": [ { "$match": { "_id": 42 } }, { "$project": { "len": { "$strLenCP": "$big" } } } ], "cursor": {} }') AS first_statement_hits \gset
SELECT detoast_cache_hits('{ "aggregate": "docs", "pipeline": [ { "$match": { "_id": 42 } }, { "$project": { "len": { "$strLenCP": "$big" } } } ], "cursor": {} }') = :first_statement_hits AS second_statement_reads_again;
COMMIT;

-- The cache holds documents until the transaction ends, and is empty after it.
BEGIN;
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "docs", "pipeline": [ { "$group": { "_id": "$g", "len": { "$max": { "$strLenCP": "$big" } }, "total": { "$sum": { "$strLenCP": "$big" } } } }, { "$sort": { "_id": 1 } } ], "cursor": {} }');
SELECT used_bytes > 12800 AS holds_documents FROM pg_backend_memory_contexts WHERE name = 'BlackboxDB detoast cache';
COMMIT;
SELECT used_bytes < 4096 AS empty_after_commit FROM pg_backend_memory_contexts WHERE name = 'BlackboxDB detoast cache';

-- A document over 1 MB is never kept.
SELECT blackboxdb_api.insert_one('detoastdb', 'huge', FORMAT('{ "_id": 1, "big": "%s" }', (SELECT string_agg(md5(j::text), '') FROM generate_series(1, 49152) j))::blackboxdb_core.bson);
BEGIN;
SELECT document FROM bson_aggregation_pipeline('detoastdb', '{ "aggregate": "huge", "pipeline": [ { "$project": { "_id": 1, "len": { "$strLenCP": "$big" }, "head": { "$substrCP": [ "$big", 0, 8 ] } } } ], "cursor": {} }');
SELECT used_bytes < 1048576 AS huge_document_not_kept FROM pg_backend_memory_contexts WHERE name = 'BlackboxDB detoast cache';
COMMIT;

DROP FUNCTION detoast_cache_hits(text);
RESET blackboxdb_core.enable_detoast_cache;
