SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

SET blackboxdb.next_collection_id TO 12200;
SET blackboxdb.next_collection_index_id TO 12200;

SELECT blackboxdb_api.insert_one('db','salesTest',' { "_id" : 1, "product" : "beer", "pricingInfo" : { "msrp": 10, "retailPrice": 15 }, "stock" : 2, "year": 2020 }', NULL);
SELECT blackboxdb_api.insert_one('db','salesTest','{ "_id" : 2, "product" : "red wine", "pricingInfo" : { "msrp": 10, "retailPrice": 9 }, "stock" : 1, "year": 2021 }', NULL);
SELECT blackboxdb_api.insert_one('db','salesTest',' { "_id" : 3, "product" : "bread", "pricingInfo" : { "msrp": 10, "retailPrice": 15 }, "stock" : 5 , "year": 2020}', NULL);
SELECT blackboxdb_api.insert_one('db','salesTest',' { "_id" : 4, "product" : "whiskey", "pricingInfo" : { "msrp": 4, "retailPrice": 10 }, "stock" : 3 , "year": 2022}', NULL);
SELECT blackboxdb_api.insert_one('db','salesTest','{ "_id" : 5, "product" : "bread", "pricingInfo" : { "msrp": 75, "retailPrice": 100 }, "stock" : 1, "year": 2021 }', NULL);
SELECT blackboxdb_api.insert_one('db','salesTest','{ "_id" : 6, "product" : "bread", "pricingInfo" : { "msrp": 75, "retailPrice": 100 }, "stock" : 1, "year": 2021 }', NULL);
SELECT blackboxdb_api.insert_one('db','salesTest','{ "_id" : 7, "product" : "bread", "pricingInfo" : { "retailPrice": 15, "msrp": 10 }, "stock" : 1, "year": 2020 }', NULL);

/* running multiple $addToSet accumulators with different expressions */

SET blackboxdb.enableAddToSetAggregationRewrite to off;

SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "itemsSold": { "$addToSet": { "product" : "$product" } } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "itemsSold": { "$addToSet": "$product" } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "pricingDeals": { "$addToSet": "$pricingInfo" } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "retailPrices": { "$addToSet": "$pricingInfo.retailPrice" } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "retailPrices": { "$addToSet": "$noValue" } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "items": { "$addToSet": { "$getField": { "field": "a", "input": { "b": 1 } } } } } } ] }');

EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "itemsSold": { "$addToSet": { "product" : "$product" } } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "itemsSold": { "$addToSet": "$product" } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "pricingDeals": { "$addToSet": "$pricingInfo" } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "retailPrices": { "$addToSet": "$pricingInfo.retailPrice" } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "retailPrices": { "$addToSet": "$noValue" } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "items": { "$addToSet": { "$getField": { "field": "a", "input": { "b": 1 } } } } } } ] }');

SET blackboxdb.enableAddToSetAggregationRewrite to on;

SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "itemsSold": { "$addToSet": { "product" : "$product" } } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "itemsSold": { "$addToSet": "$product" } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "pricingDeals": { "$addToSet": "$pricingInfo" } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "retailPrices": { "$addToSet": "$pricingInfo.retailPrice" } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "retailPrices": { "$addToSet": "$noValue" } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "items": { "$addToSet": { "$getField": { "field": "a", "input": { "b": 1 } } } } } } ] }');

EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "itemsSold": { "$addToSet": { "product" : "$product" } } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "itemsSold": { "$addToSet": "$product" } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "pricingDeals": { "$addToSet": "$pricingInfo" } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "retailPrices": { "$addToSet": "$pricingInfo.retailPrice" } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "retailPrices": { "$addToSet": "$noValue" } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "items": { "$addToSet": { "$getField": { "field": "a", "input": { "b": 1 } } } } } } ] }');

/* running $addToSet with document that exceeds 16MB */
DO $$
DECLARE i int;
BEGIN
-- each doc is "c": 5 MB - ~5.5 MB & there's 25 of them
FOR i IN 1..25 LOOP
PERFORM blackboxdb_api.insert_one('db', 'sizes_test', FORMAT('{ "_id": %s, "groupName": "A", "c": [ %s "d" ] }', i, repeat('"' || i || repeat('a', 1000) || '", ', 5000))::blackboxdb_core.bson);
END LOOP;
END;
$$;

/* should fail with intermediate size error */
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "sizes_test", "pipeline": [ { "$group": { "_id": "$groupName", "data": { "$addToSet": "$c" } } } ] }');

/* shard collection */
SELECT blackboxdb_api.shard_collection('db', 'salesTest', '{ "_id": "hashed" }', false);

/* run same $addToSet queries to ensure consistency */
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "itemsSold": { "$addToSet": { "product" : "$product" } } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "itemsSold": { "$addToSet": "$product" } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "pricingDeals": { "$addToSet": "$pricingInfo" } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "retailPrices": { "$addToSet": "$pricingInfo.retailPrice" } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "retailPrices": { "$addToSet": "$noValue" } } } ] }');
SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "items": { "$addToSet": { "$getField": { "field": "a", "input": { "b": 1 } } } } } } ] }');

EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "itemsSold": { "$addToSet": { "product" : "$product" } } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "itemsSold": { "$addToSet": "$product" } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "pricingDeals": { "$addToSet": "$pricingInfo" } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "retailPrices": { "$addToSet": "$pricingInfo.retailPrice" } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "retailPrices": { "$addToSet": "$noValue" } } } ] }');
EXPLAIN (VERBOSE ON, COSTS OFF) SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('db', '{ "aggregate": "salesTest", "pipeline": [ { "$group": { "_id": "$year", "items": { "$addToSet": { "$getField": { "field": "a", "input": { "b": 1 } } } } } } ] }');
