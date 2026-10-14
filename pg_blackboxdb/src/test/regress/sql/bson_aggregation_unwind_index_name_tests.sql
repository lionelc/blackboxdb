SET search_path TO blackboxdb_api, blackboxdb_core, blackboxdb_api_catalog;
SET blackboxdb.next_collection_id TO 27000000;
SET blackboxdb.next_collection_index_id TO 27000000;

-- An $unwind includeArrayIndex name is a field path. Besides an empty name and one that starts with
-- '$', MongoDB rejects a name that ends with '.' (40353), and one with an empty field name (15998), a field
-- name that starts with '$' other than $id, $ref, $db and $sortKey (16410) or a NUL character (16411).
-- With blackboxdb.enable_unwind_index_field_path_check off the old parser accepts these names; with it on
-- every name has MongoDB 8.0.32's outcome.

-- the rows of a query, or its SQLSTATE and message (the gateway maps the SQLSTATE to the MongoDB code)
CREATE FUNCTION public.uidxname_outcome(query text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE
    result text;
BEGIN
    EXECUTE 'SELECT string_agg(document::text, '', '') FROM (' || query || ') q' INTO result;
    RETURN 'rows: ' || coalesce(result, '');
EXCEPTION WHEN OTHERS THEN
    RETURN 'error ' || SQLSTATE || ': ' || SQLERRM;
END $$;

SELECT blackboxdb_api.insert_one('uidxname', 'c', '{"_id": 1, "items": [1, 2]}');
SELECT blackboxdb_api.insert_one('uidxname', 'c', '{"_id": 2, "items": [3]}');

SET blackboxdb.enable_unwind_index_field_path_check TO off;
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "x"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.b"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.$id"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.$ref"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.$db"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.$sortKey"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": ".x"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "x."}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a..b"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "."}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": ".."}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.b."}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.$b"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a\u0000b"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);

SET blackboxdb.enable_unwind_index_field_path_check TO on;
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "x"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.b"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.$id"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.$ref"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.$db"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.$sortKey"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": ".x"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "x."}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a..b"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "."}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": ".."}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.b."}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a.$b"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);
SELECT public.uidxname_outcome($q$SELECT document FROM bson_aggregation_pipeline('uidxname', '{"aggregate": "c", "pipeline": [{"$unwind": {"path": "$items", "includeArrayIndex": "a\u0000b"}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}')$q$);

RESET blackboxdb.enable_unwind_index_field_path_check;
DROP FUNCTION public.uidxname_outcome(text);
