SET search_path TO blackboxdb_api, blackboxdb_core, blackboxdb_api_catalog;
SET blackboxdb.next_collection_id TO 27100000;
SET blackboxdb.next_collection_index_id TO 27100000;

-- MongoDB's $count stage is a $group on null followed by a $project, so over an empty input it returns no
-- document; an aggregate without GROUP BY returns one row. With blackboxdb.enable_count_stage_empty_input off
-- the stage returns { n: 0 } over an empty input (an empty match, a missing or empty collection, an $unwind with
-- nothing to unwind), also inside $facet and $lookup sub-pipelines; with it on it returns no document, as MongoDB
-- 8.0.32 does. Non-empty inputs, $group on null and the count command (n: 0 over an empty input) are unchanged.

SELECT blackboxdb_api.insert_one('cntempty', 'c', '{"_id": 1, "g": 1}');
SELECT blackboxdb_api.insert_one('cntempty', 'c', '{"_id": 2, "g": 0}');
SELECT blackboxdb_api.insert_one('cntempty', 'c', '{"_id": 3, "g": 1}');
SELECT blackboxdb_api.insert_one('cntempty', 'c', '{"_id": 4, "g": 0}');
SELECT blackboxdb_api.insert_one('cntempty', 'c', '{"_id": 5, "g": 1}');
SELECT blackboxdb_api.create_collection('cntempty', 'e');

SET blackboxdb.enable_count_stage_empty_input TO off;
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$match": {"_id": -1}}, {"$count": "n"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "m", "pipeline": [{"$count": "n"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "e", "pipeline": [{"$count": "n"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$count": "n"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$facet": {"a": [{"$match": {"_id": -1}}, {"$count": "n"}], "b": [{"$count": "n"}]}}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$lookup": {"from": "c", "pipeline": [{"$match": {"_id": -1}}, {"$count": "n"}], "as": "k"}}, {"$project": {"k": 1}}, {"$sort": {"_id": 1}}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$match": {"_id": -1}}, {"$count": "n"}, {"$project": {"m": "$n"}}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$unwind": "$nothing"}, {"$count": "n"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$match": {"_id": {"$lt": 3}}}, {"$count": "cnt"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$match": {"_id": 1}}, {"$count": "n"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$lookup": {"from": "c", "pipeline": [{"$count": "n"}], "as": "k"}}, {"$project": {"k": 1}}, {"$sort": {"_id": 1}}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$match": {"_id": -1}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}');
SELECT document FROM bson_aggregation_count('cntempty', '{"count": "c", "query": {"_id": -1}}');
SELECT document FROM bson_aggregation_count('cntempty', '{"count": "m"}');
SELECT document FROM bson_aggregation_count('cntempty', '{"count": "c", "query": {"g": 1}}');

SET blackboxdb.enable_count_stage_empty_input TO on;
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$match": {"_id": -1}}, {"$count": "n"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "m", "pipeline": [{"$count": "n"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "e", "pipeline": [{"$count": "n"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$count": "n"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$facet": {"a": [{"$match": {"_id": -1}}, {"$count": "n"}], "b": [{"$count": "n"}]}}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$lookup": {"from": "c", "pipeline": [{"$match": {"_id": -1}}, {"$count": "n"}], "as": "k"}}, {"$project": {"k": 1}}, {"$sort": {"_id": 1}}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$match": {"_id": -1}}, {"$count": "n"}, {"$project": {"m": "$n"}}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$unwind": "$nothing"}, {"$count": "n"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$match": {"_id": {"$lt": 3}}}, {"$count": "cnt"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$match": {"_id": 1}}, {"$count": "n"}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$lookup": {"from": "c", "pipeline": [{"$count": "n"}], "as": "k"}}, {"$project": {"k": 1}}, {"$sort": {"_id": 1}}], "cursor": {}}');
SELECT document FROM bson_aggregation_pipeline('cntempty', '{"aggregate": "c", "pipeline": [{"$match": {"_id": -1}}, {"$group": {"_id": null, "n": {"$sum": 1}}}], "cursor": {}}');
SELECT document FROM bson_aggregation_count('cntempty', '{"count": "c", "query": {"_id": -1}}');
SELECT document FROM bson_aggregation_count('cntempty', '{"count": "m"}');
SELECT document FROM bson_aggregation_count('cntempty', '{"count": "c", "query": {"g": 1}}');

RESET blackboxdb.enable_count_stage_empty_input;
