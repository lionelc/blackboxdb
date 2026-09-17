SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,pg_catalog;

SET citus.next_shard_id TO 1117000;
SET blackboxdb.next_collection_id TO 11170;
SET blackboxdb.next_collection_index_id TO 11170;

-- =============================================================================
-- Test 1: $group + $max/$min on string fields (with and without collations)
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_string_test','{ "_id": 1, "category": "A", "name": "apple" }');
SELECT blackboxdb_api.insert_one('db','maxmin_string_test','{ "_id": 2, "category": "A", "name": "BANANA" }');
SELECT blackboxdb_api.insert_one('db','maxmin_string_test','{ "_id": 3, "category": "A", "name": "Cherry" }');
SELECT blackboxdb_api.insert_one('db','maxmin_string_test','{ "_id": 4, "category": "B", "name": "date" }');
SELECT blackboxdb_api.insert_one('db','maxmin_string_test','{ "_id": 5, "category": "B", "name": "FIG" }');
SELECT blackboxdb_api.insert_one('db','maxmin_string_test','{ "_id": 6, "category": "B", "name": "grape" }');

-- $max on string field without collation (BSON type ordering)
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_string_test", "pipeline": [ { "$group": { "_id": "$category", "maxName": { "$max": "$name" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_string_test", "pipeline": [ { "$group": { "_id": "$category", "maxName": { "$max": "$name" } } }, { "$sort": { "_id": 1 } } ] }');

-- $min on string field without collation
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_string_test", "pipeline": [ { "$group": { "_id": "$category", "minName": { "$min": "$name" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_string_test", "pipeline": [ { "$group": { "_id": "$category", "minName": { "$min": "$name" } } }, { "$sort": { "_id": 1 } } ] }');

-- $max and $min together without collation
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_string_test", "pipeline": [ { "$group": { "_id": "$category", "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_string_test", "pipeline": [ { "$group": { "_id": "$category", "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } }, { "$sort": { "_id": 1 } } ] }');


-- =============================================================================
-- Test 2: $group + $max/$min on different types
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 1, "group": "mixed", "val": null }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 2, "group": "mixed", "val": 42 }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 3, "group": "mixed", "val": "hello" }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 4, "group": "mixed", "val": true }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 5, "group": "mixed", "val": { "$date": "2024-01-01T00:00:00Z" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 6, "group": "mixed", "val": { "$numberDouble": "3.14" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 7, "group": "mixed", "val": { "$numberDecimal": "99.99" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 8, "group": "mixed", "val": { "$oid": "507f1f77bcf86cd799439011" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 9, "group": "mixed", "val": [1, 2, 3] }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 10, "group": "mixed", "val": { "nested": "doc" } }');

-- Same type tests
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 11, "group": "ints", "val": 10 }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 12, "group": "ints", "val": 50 }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 13, "group": "ints", "val": 25 }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 14, "group": "strings", "val": "aaa" }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 15, "group": "strings", "val": "zzz" }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 16, "group": "strings", "val": "mmm" }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 17, "group": "dates", "val": { "$date": "2020-01-01T00:00:00Z" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 18, "group": "dates", "val": { "$date": "2025-12-31T23:59:59Z" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_types_test','{ "_id": 19, "group": "dates", "val": { "$date": "2022-06-15T12:00:00Z" } }');

-- $max across mixed types (BSON type ordering)
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_types_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_types_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" } } }, { "$sort": { "_id": 1 } } ] }');

-- $min across mixed types
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_types_test", "pipeline": [ { "$group": { "_id": "$group", "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_types_test", "pipeline": [ { "$group": { "_id": "$group", "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');

-- Both $max and $min
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_types_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_types_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');

-- =============================================================================
-- Test 3: Behavior when $match filters all documents before $group
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_empty_test','{ "_id": 1, "category": "A", "value": 10 }');
SELECT blackboxdb_api.insert_one('db','maxmin_empty_test','{ "_id": 2, "category": "A", "value": 20 }');
SELECT blackboxdb_api.insert_one('db','maxmin_empty_test','{ "_id": 3, "category": "B", "value": 30 }');

-- Match filters everything - should return empty result
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_empty_test", "pipeline": [ { "$match": { "_id": { "$eq": "nonexistent" } } }, { "$group": { "_id": null, "maxVal": { "$max": "$value" }, "minVal": { "$min": "$value" } } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_empty_test", "pipeline": [ { "$match": { "_id": { "$eq": "nonexistent" } } }, { "$group": { "_id": null, "maxVal": { "$max": "$value" }, "minVal": { "$min": "$value" } } } ] }');

-- Match filters everything with _id grouping
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_empty_test", "pipeline": [ { "$match": { "category": "Z" } }, { "$group": { "_id": "$category", "maxVal": { "$max": "$value" } } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_empty_test", "pipeline": [ { "$match": { "category": "Z" } }, { "$group": { "_id": "$category", "maxVal": { "$max": "$value" } } } ] }');

-- =============================================================================
-- Test 4: Behavior when all documents have null/missing field
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_null_test','{ "_id": 1, "group": "allnull", "val": null }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_test','{ "_id": 2, "group": "allnull", "val": { "$undefined": true } }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_test','{ "_id": 3, "group": "allnull" }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_test','{ "_id": 4, "group": "mixed", "val": null }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_test','{ "_id": 5, "group": "mixed", "val": 10 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_test','{ "_id": 6, "group": "mixed" }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_test','{ "_id": 7, "group": "mixed", "val": 5 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_test','{ "_id": 8, "group": "allmissing" }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_test','{ "_id": 9, "group": "allmissing" }');

-- All null/undefined/missing - should return null
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_null_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_null_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');

-- =============================================================================
-- Test 5: Extreme Int64 and Decimal128 values
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 1, "group": "int64", "val": { "$numberLong": "9223372036854775807" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 2, "group": "int64", "val": { "$numberLong": "-9223372036854775808" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 3, "group": "int64", "val": { "$numberLong": "0" } }');

SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 4, "group": "decimal", "val": { "$numberDecimal": "9.999999999999999999999999999999999E6144" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 5, "group": "decimal", "val": { "$numberDecimal": "-9.999999999999999999999999999999999E6144" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 6, "group": "decimal", "val": { "$numberDecimal": "0" } }');

SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 7, "group": "special", "val": { "$numberDecimal": "Infinity" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 8, "group": "special", "val": { "$numberDecimal": "-Infinity" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 9, "group": "special", "val": { "$numberDecimal": "NaN" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 10, "group": "special", "val": 100 }');

SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 11, "group": "mixednums", "val": { "$numberLong": "9223372036854775807" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 12, "group": "mixednums", "val": { "$numberDouble": "1.7976931348623157e308" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_extreme_test','{ "_id": 13, "group": "mixednums", "val": { "$numberDecimal": "1E6144" } }');

-- Int64 extremes
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_extreme_test", "pipeline": [ { "$match": { "group": "int64" } }, { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_extreme_test", "pipeline": [ { "$match": { "group": "int64" } }, { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ] }');

-- Decimal128 extremes
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_extreme_test", "pipeline": [ { "$match": { "group": "decimal" } }, { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_extreme_test", "pipeline": [ { "$match": { "group": "decimal" } }, { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ] }');

-- Special values (Infinity, -Infinity, NaN)
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_extreme_test", "pipeline": [ { "$match": { "group": "special" } }, { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_extreme_test", "pipeline": [ { "$match": { "group": "special" } }, { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ] }');

-- Mixed numeric types
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_extreme_test", "pipeline": [ { "$match": { "group": "mixednums" } }, { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_extreme_test", "pipeline": [ { "$match": { "group": "mixednums" } }, { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ] }');

-- All groups
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_extreme_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_extreme_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');

-- =============================================================================
-- Test 6: Using $$variable in $max/$min expression
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_variable_test','{ "_id": 1, "group": "A", "val": 10 }');
SELECT blackboxdb_api.insert_one('db','maxmin_variable_test','{ "_id": 2, "group": "A", "val": 20 }');
SELECT blackboxdb_api.insert_one('db','maxmin_variable_test','{ "_id": 3, "group": "A", "val": 15 }');
SELECT blackboxdb_api.insert_one('db','maxmin_variable_test','{ "_id": 4, "group": "B", "val": 5 }');
SELECT blackboxdb_api.insert_one('db','maxmin_variable_test','{ "_id": 5, "group": "B", "val": 25 }');

-- Using $$variable with $add
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_variable_test", "pipeline": [ { "$group": { "_id": "$group", "maxWithOffset": { "$max": { "$add": ["$val", "$$offset"] } } } }, { "$sort": { "_id": 1 } } ], "let": { "offset": 100 } }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_variable_test", "pipeline": [ { "$group": { "_id": "$group", "maxWithOffset": { "$max": { "$add": ["$val", "$$offset"] } } } }, { "$sort": { "_id": 1 } } ], "let": { "offset": 100 } }');

-- Using $$variable with $min
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_variable_test", "pipeline": [ { "$group": { "_id": "$group", "minWithOffset": { "$min": { "$add": ["$val", "$$offset"] } } } }, { "$sort": { "_id": 1 } } ], "let": { "offset": 50 } }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_variable_test", "pipeline": [ { "$group": { "_id": "$group", "minWithOffset": { "$min": { "$add": ["$val", "$$offset"] } } } }, { "$sort": { "_id": 1 } } ], "let": { "offset": 50 } }');

-- Multiple variables
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_variable_test", "pipeline": [ { "$group": { "_id": "$group", "maxCalc": { "$max": { "$add": [{ "$multiply": ["$val", "$$multiplier"] }, "$$offset"] } } } }, { "$sort": { "_id": 1 } } ], "let": { "offset": 10, "multiplier": 2 } }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_variable_test", "pipeline": [ { "$group": { "_id": "$group", "maxCalc": { "$max": { "$add": [{ "$multiply": ["$val", "$$multiplier"] }, "$$offset"] } } } }, { "$sort": { "_id": 1 } } ], "let": { "offset": 10, "multiplier": 2 } }');

-- Using $$CURRENT
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_variable_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$$CURRENT.val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_variable_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$$CURRENT.val" } } }, { "$sort": { "_id": 1 } } ] }');

-- Using $$ROOT
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_variable_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$$ROOT.val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_variable_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$$ROOT.val" } } }, { "$sort": { "_id": 1 } } ] }');

-- =============================================================================
-- Test 7: Expression evaluation within accumulator ($max: { "$add": ["$a", "$b"] })
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_expr_test','{ "_id": 1, "group": "A", "a": 10, "b": 5 }');
SELECT blackboxdb_api.insert_one('db','maxmin_expr_test','{ "_id": 2, "group": "A", "a": 3, "b": 20 }');
SELECT blackboxdb_api.insert_one('db','maxmin_expr_test','{ "_id": 3, "group": "A", "a": 8, "b": 8 }');
SELECT blackboxdb_api.insert_one('db','maxmin_expr_test','{ "_id": 4, "group": "B", "a": 100, "b": 1 }');
SELECT blackboxdb_api.insert_one('db','maxmin_expr_test','{ "_id": 5, "group": "B", "a": 50, "b": 50 }');

-- $add expression
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_expr_test", "pipeline": [ { "$group": { "_id": "$group", "maxSum": { "$max": { "$add": ["$a", "$b"] } } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_expr_test", "pipeline": [ { "$group": { "_id": "$group", "maxSum": { "$max": { "$add": ["$a", "$b"] } } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_expr_test", "pipeline": [ { "$group": { "_id": "$group", "minSum": { "$min": { "$add": ["$a", "$b"] } } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_expr_test", "pipeline": [ { "$group": { "_id": "$group", "minSum": { "$min": { "$add": ["$a", "$b"] } } } }, { "$sort": { "_id": 1 } } ] }');

-- $subtract expression
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_expr_test", "pipeline": [ { "$group": { "_id": "$group", "maxDiff": { "$max": { "$subtract": ["$a", "$b"] } } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_expr_test", "pipeline": [ { "$group": { "_id": "$group", "maxDiff": { "$max": { "$subtract": ["$a", "$b"] } } } }, { "$sort": { "_id": 1 } } ] }');

-- $multiply expression
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_expr_test", "pipeline": [ { "$group": { "_id": "$group", "maxProduct": { "$max": { "$multiply": ["$a", "$b"] } } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_expr_test", "pipeline": [ { "$group": { "_id": "$group", "maxProduct": { "$max": { "$multiply": ["$a", "$b"] } } } }, { "$sort": { "_id": 1 } } ] }');

-- Nested expression: multiply then add
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_expr_test", "pipeline": [ { "$group": { "_id": "$group", "maxCalc": { "$max": { "$add": [{ "$multiply": ["$a", 2] }, "$b"] } } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_expr_test", "pipeline": [ { "$group": { "_id": "$group", "maxCalc": { "$max": { "$add": [{ "$multiply": ["$a", 2] }, "$b"] } } } }, { "$sort": { "_id": 1 } } ] }');

-- Complex nested expression
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_expr_test", "pipeline": [ { "$group": { "_id": "$group", "maxComplex": { "$max": { "$multiply": [{ "$add": ["$a", "$b"] }, 2] } } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_expr_test", "pipeline": [ { "$group": { "_id": "$group", "maxComplex": { "$max": { "$multiply": [{ "$add": ["$a", "$b"] }, 2] } } } }, { "$sort": { "_id": 1 } } ] }');

-- =============================================================================
-- Test 8: Conditional logic in accumulator input ($max: { "$cond": [...] })
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_cond_test','{ "_id": 1, "group": "A", "val": 10, "active": true }');
SELECT blackboxdb_api.insert_one('db','maxmin_cond_test','{ "_id": 2, "group": "A", "val": 50, "active": false }');
SELECT blackboxdb_api.insert_one('db','maxmin_cond_test','{ "_id": 3, "group": "A", "val": 30, "active": true }');
SELECT blackboxdb_api.insert_one('db','maxmin_cond_test','{ "_id": 4, "group": "B", "val": 100, "active": true }');
SELECT blackboxdb_api.insert_one('db','maxmin_cond_test','{ "_id": 5, "group": "B", "val": 200, "active": false }');
SELECT blackboxdb_api.insert_one('db','maxmin_cond_test','{ "_id": 6, "group": "B", "val": 75, "active": true }');
SELECT blackboxdb_api.insert_one('db','maxmin_cond_test','{ "_id": 7, "group": "C", "val": 25, "optionalField": 999 }');
SELECT blackboxdb_api.insert_one('db','maxmin_cond_test','{ "_id": 8, "group": "C", "val": 50 }');

-- $cond: if active then val else null
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_cond_test", "pipeline": [ { "$group": { "_id": "$group", "maxActive": { "$max": { "$cond": { "if": "$active", "then": "$val", "else": null } } } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_cond_test", "pipeline": [ { "$group": { "_id": "$group", "maxActive": { "$max": { "$cond": { "if": "$active", "then": "$val", "else": null } } } } }, { "$sort": { "_id": 1 } } ] }');

-- $cond: if active then val else 0
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_cond_test", "pipeline": [ { "$group": { "_id": "$group", "minActive": { "$min": { "$cond": { "if": "$active", "then": "$val", "else": 0 } } } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_cond_test", "pipeline": [ { "$group": { "_id": "$group", "minActive": { "$min": { "$cond": { "if": "$active", "then": "$val", "else": 0 } } } } }, { "$sort": { "_id": 1 } } ] }');

-- $cond with array syntax
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_cond_test", "pipeline": [ { "$group": { "_id": "$group", "tier": { "$max": { "$cond": [{ "$gt": ["$val", 50] }, { "$multiply": ["$val", 2] }, "$val"] } } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_cond_test", "pipeline": [ { "$group": { "_id": "$group", "tier": { "$max": { "$cond": [{ "$gt": ["$val", 50] }, { "$multiply": ["$val", 2] }, "$val"] } } } }, { "$sort": { "_id": 1 } } ] }');

-- $ifNull expression
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_cond_test", "pipeline": [ { "$group": { "_id": "$group", "maxWithDefault": { "$max": { "$ifNull": ["$optionalField", 0] } } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_cond_test", "pipeline": [ { "$group": { "_id": "$group", "maxWithDefault": { "$max": { "$ifNull": ["$optionalField", 0] } } } }, { "$sort": { "_id": 1 } } ] }');

-- Nested $cond
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_cond_test", "pipeline": [ { "$group": { "_id": "$group", "categorized": { "$max": { "$cond": { "if": { "$gt": ["$val", 100] }, "then": 3, "else": { "$cond": { "if": { "$gt": ["$val", 50] }, "then": 2, "else": 1 } } } } } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_cond_test", "pipeline": [ { "$group": { "_id": "$group", "categorized": { "$max": { "$cond": { "if": { "$gt": ["$val", 100] }, "then": 3, "else": { "$cond": { "if": { "$gt": ["$val", 50] }, "then": 2, "else": 1 } } } } } } }, { "$sort": { "_id": 1 } } ] }');

-- =============================================================================
-- Test 9: Different type values on different shards (type coercion across shards)
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_shard_types_test','{ "_id": 1, "group": "mixed", "val": 42 }');
SELECT blackboxdb_api.insert_one('db','maxmin_shard_types_test','{ "_id": 2, "group": "mixed", "val": "100" }');
SELECT blackboxdb_api.insert_one('db','maxmin_shard_types_test','{ "_id": 3, "group": "mixed", "val": { "$numberDouble": "42.0" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_shard_types_test','{ "_id": 4, "group": "mixed", "val": true }');
SELECT blackboxdb_api.insert_one('db','maxmin_shard_types_test','{ "_id": 5, "group": "mixed", "val": [50] }');
SELECT blackboxdb_api.insert_one('db','maxmin_shard_types_test','{ "_id": 6, "group": "mixed", "val": { "$numberLong": "99" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_shard_types_test','{ "_id": 7, "group": "nums", "val": 10 }');
SELECT blackboxdb_api.insert_one('db','maxmin_shard_types_test','{ "_id": 8, "group": "nums", "val": { "$numberDouble": "25.5" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_shard_types_test','{ "_id": 9, "group": "nums", "val": { "$numberLong": "50" } }');
SELECT blackboxdb_api.insert_one('db','maxmin_shard_types_test','{ "_id": 10, "group": "nums", "val": { "$numberDecimal": "75.25" } }');

-- Pre-sharding results
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');

-- Shard the collection
SELECT blackboxdb_api.shard_collection('db', 'maxmin_shard_types_test', '{ "_id": "hashed" }', false);

-- Post-sharding results (should be same as pre-sharding)
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
EXPLAIN (COSTS OFF) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_shard_types_test", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');

-- =============================================================================
-- Test 10: BSONMAXWITHEXPR - Query plan verification
-- =============================================================================

-- EXPLAIN to verify query plan for $group
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_cache_test", "pipeline": [ { "$group": { "_id": "$category", "maxA": { "$max": "$fieldA" }, "maxB": { "$max": "$fieldB" } } }, { "$sort": { "_id": 1 } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_cache_test", "pipeline": [ { "$group": { "_id": "$category", "maxA": { "$max": "$fieldA" }, "maxB": { "$max": "$fieldB" } } }, { "$sort": { "_id": 1 } } ] }');

-- EXPLAIN to verify query plan for $setWindowFields
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_variable_test", "pipeline": [ { "$setWindowFields": { "partitionBy": "$group", "sortBy": { "val": 1 }, "output": { "maxVal": { "$max": "$val", "window": { "documents": ["unbounded", "current"] } }, "minVal": { "$min": "$val", "window": { "documents": ["unbounded", "current"] } } } } } ] }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_variable_test", "pipeline": [ { "$setWindowFields": { "partitionBy": "$group", "sortBy": { "val": 1 }, "output": { "maxVal": { "$max": "$val", "window": { "documents": ["unbounded", "current"] } }, "minVal": { "$min": "$val", "window": { "documents": ["unbounded", "current"] } } } } } ] }');

-- =============================================================================
-- Test 11: $group + $max/$min collation applies to accumulators, not grouping
-- Grouping key uses binary comparison (so "A" and "a" stay separate groups),
-- but $min/$max comparisons within each group respect collation.
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_collation_test','{ "_id": 1, "group": "A", "name": "cherry" }');
SELECT blackboxdb_api.insert_one('db','maxmin_collation_test','{ "_id": 2, "group": "A", "name": "BANANA" }');
SELECT blackboxdb_api.insert_one('db','maxmin_collation_test','{ "_id": 3, "group": "A", "name": "Apple" }');
SELECT blackboxdb_api.insert_one('db','maxmin_collation_test','{ "_id": 4, "group": "a", "name": "date" }');
SELECT blackboxdb_api.insert_one('db','maxmin_collation_test','{ "_id": 5, "group": "a", "name": "FIG" }');

SET blackboxdb_core.enableCollation TO on;
SET blackboxdb.enableNewWithExprAccumulators TO on;
SET blackboxdb.enableCollationWithNewGroupAccumulators TO on;

-- $max on string field with collation (locale: en, strength: 1 = case-insensitive)
-- Uses maxmin_string_test collection from Test 1: apple, BANANA, Cherry (cat A), date, FIG, grape (cat B)
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_string_test", "pipeline": [ { "$group": { "_id": "$category", "maxName": { "$max": "$name" } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "strength": 1 } }');

-- $min on string field with collation
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_string_test", "pipeline": [ { "$group": { "_id": "$category", "minName": { "$min": "$name" } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "strength": 1 } }');

-- $max and $min together with collation strength 2 (case-insensitive, accent-sensitive)
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_string_test", "pipeline": [ { "$group": { "_id": "$category", "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "strength": 2 } }');

-- Case-insensitive collation (strength 1): accumulator comparison is case-insensitive
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_test", "pipeline": [ { "$group": { "_id": "$group", "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "strength": 1 } }');
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_test", "pipeline": [ { "$group": { "_id": "$group", "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "strength": 1 } }');

-- Without collation baseline (binary comparison for both grouping and accumulators)
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_test", "pipeline": [ { "$group": { "_id": "$group", "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } }, { "$sort": { "_id": 1 } } ] }');
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_test", "pipeline": [ { "$group": { "_id": "$group", "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } }, { "$sort": { "_id": 1 } } ] }');

-- =============================================================================
-- Test 12: collation with $min/$max on constant group _id (all docs in one group)
-- =============================================================================

-- With constant _id: null, all documents aggregate into a single group
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_test", "pipeline": [ { "$group": { "_id": null, "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } } ], "collation": { "locale": "en", "strength": 1 } }');

-- Without collation baseline on constant group
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_test", "pipeline": [ { "$group": { "_id": null, "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } } ] }');

-- With constant _id: 1
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_test", "pipeline": [ { "$group": { "_id": 1, "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } } ], "collation": { "locale": "en", "strength": 1 } }');

-- =============================================================================
-- Test 13: collation with $min/$max on mixed types
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_collation_mixed','{ "_id": 1, "group": "G", "val": "banana" }');
SELECT blackboxdb_api.insert_one('db','maxmin_collation_mixed','{ "_id": 2, "group": "G", "val": "CHERRY" }');
SELECT blackboxdb_api.insert_one('db','maxmin_collation_mixed','{ "_id": 3, "group": "G", "val": 42 }');
SELECT blackboxdb_api.insert_one('db','maxmin_collation_mixed','{ "_id": 4, "group": "G", "val": null }');

-- With collation: string ordering changes but cross-type ordering follows BSON type order
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_mixed", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ], "collation": { "locale": "en", "strength": 1 } }');

-- Without collation baseline
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_mixed", "pipeline": [ { "$group": { "_id": "$group", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ] }');

-- =============================================================================
-- Test 14: collation with numericOrdering on $min/$max
-- With numericOrdering: "item2" < "item10" (numeric), without: "item10" < "item2" (lexical)
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_numeric_order','{ "_id": 1, "val": "item1" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numeric_order','{ "_id": 2, "val": "item10" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numeric_order','{ "_id": 3, "val": "item2" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numeric_order','{ "_id": 4, "val": "item20" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numeric_order','{ "_id": 5, "val": "item3" }');

-- numericOrdering=true: $max should be "item20", $min should be "item1"
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_numeric_order", "pipeline": [ { "$group": { "_id": null, "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ], "collation": { "locale": "en", "numericOrdering": true } }');
-- numericOrdering=false: $max should be "item3" (lexical), $min should be "item1"
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_numeric_order", "pipeline": [ { "$group": { "_id": null, "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ], "collation": { "locale": "en", "numericOrdering": false } }');

-- Without collation baseline (binary/BSON ordering): same as numericOrdering=false
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_numeric_order", "pipeline": [ { "$group": { "_id": null, "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ] }');

-- numericOrdering with non-constant group _id
SELECT blackboxdb_api.insert_one('db','maxmin_numeric_grp','{ "_id": 1, "cat": "A", "val": "item1" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numeric_grp','{ "_id": 2, "cat": "A", "val": "item10" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numeric_grp','{ "_id": 3, "cat": "A", "val": "item3" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numeric_grp','{ "_id": 4, "cat": "B", "val": "item2" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numeric_grp','{ "_id": 5, "cat": "B", "val": "item20" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numeric_grp','{ "_id": 6, "cat": "B", "val": "item5" }');

-- numericOrdering=true: A -> max "item10", min "item1"; B -> max "item20", min "item2"
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_numeric_grp", "pipeline": [ { "$group": { "_id": "$cat", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "numericOrdering": true } }');

-- Without collation: A -> max "item3" (lexical), min "item1"; B -> max "item5", min "item2"
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_numeric_grp", "pipeline": [ { "$group": { "_id": "$cat", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');

-- =============================================================================
-- Test 15: collation blocked when enableNewWithExprAccumulators is off
-- =============================================================================

SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
SET blackboxdb.enableCollationWithNewGroupAccumulators TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_test", "pipeline": [ { "$group": { "_id": "$group", "maxName": { "$max": "$name" } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "strength": 1 } }');
SET blackboxdb.enableNewWithExprAccumulators TO on;
SET blackboxdb.enableCollationWithNewGroupAccumulators TO on;

-- =============================================================================
-- Test 16: sharded collection with collation on $min/$max
-- Exercises the combine function (send/recv) path with collation across shards.
-- =============================================================================

SELECT blackboxdb_api.shard_collection('db', 'maxmin_numeric_grp', '{ "_id": "hashed" }', false);

-- Post-sharding numericOrdering=true (should match pre-sharding results)
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_numeric_grp", "pipeline": [ { "$group": { "_id": "$cat", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "numericOrdering": true } }');

-- Post-sharding without collation baseline
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_numeric_grp", "pipeline": [ { "$group": { "_id": "$cat", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ] }');

SELECT blackboxdb_api.shard_collection('db', 'maxmin_collation_test', '{ "_id": "hashed" }', false);

-- Post-sharding case-insensitive collation
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_test", "pipeline": [ { "$group": { "_id": "$group", "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "strength": 1 } }');

-- Post-sharding constant group with collation
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_test", "pipeline": [ { "$group": { "_id": null, "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } } ], "collation": { "locale": "en", "strength": 1 } }');

set citus.enable_local_execution to off;

-- Post-sharding case-insensitive collation
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_test", "pipeline": [ { "$group": { "_id": "$group", "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "strength": 1 } }');

-- Post-sharding constant group with collation
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_collation_test", "pipeline": [ { "$group": { "_id": null, "maxName": { "$max": "$name" }, "minName": { "$min": "$name" } } } ], "collation": { "locale": "en", "strength": 1 } }');

RESET citus.enable_local_execution;

-- =============================================================================
-- Test 17: $min/$max numericOrdering collation with remote/sharded execution
-- Verifies that collation-aware comparisons work correctly in the transition
-- function on worker nodes during distributed aggregation.
-- We insert enough documents per group (10+) to ensure that multiple documents
-- in the same group land on the same shard, exercising the comparison path
-- in the transition function (not just the combine path on the coordinator).
-- =============================================================================

-- Group "x": numbers as strings where binary vs numeric orderings disagree
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 1,  "grp": "x", "val": "10" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 2,  "grp": "x", "val": "2" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 3,  "grp": "x", "val": "20" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 4,  "grp": "x", "val": "3" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 5,  "grp": "x", "val": "9" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 6,  "grp": "x", "val": "100" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 7,  "grp": "x", "val": "1" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 8,  "grp": "x", "val": "50" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 9,  "grp": "x", "val": "5" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 10, "grp": "x", "val": "200" }');

-- Group "y": different range of numeric strings
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 11, "grp": "y", "val": "8" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 12, "grp": "y", "val": "80" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 13, "grp": "y", "val": "800" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 14, "grp": "y", "val": "4" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 15, "grp": "y", "val": "40" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 16, "grp": "y", "val": "400" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 17, "grp": "y", "val": "6" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 18, "grp": "y", "val": "60" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 19, "grp": "y", "val": "600" }');
SELECT blackboxdb_api.insert_one('db','maxmin_numord_dist_test','{ "_id": 20, "grp": "y", "val": "7" }');

-- Shard the collection
SELECT blackboxdb_api.shard_collection('db', 'maxmin_numord_dist_test', '{ "_id": "hashed" }', false);

-- Force remote execution to exercise worker-side transition comparisons
SET citus.enable_local_execution TO off;

-- Post-shard remote execution: grouped (exercises transition comparison on workers)
-- Expected: x => max "200", min "1"; y => max "800", min "4"
-- Without fix, binary ordering gives wrong results (e.g. max "9" instead of "200")
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_numord_dist_test", "pipeline": [ { "$group": { "_id": "$grp", "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } }, { "$sort": { "_id": 1 } } ], "collation": { "locale": "en", "numericOrdering": true } }');

-- Post-shard remote execution: constant group (exercises combine on coordinator)
-- Expected: max "800", min "1"
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_numord_dist_test", "pipeline": [ { "$group": { "_id": null, "maxVal": { "$max": "$val" }, "minVal": { "$min": "$val" } } } ], "collation": { "locale": "en", "numericOrdering": true } }');

RESET citus.enable_local_execution;
SET blackboxdb.enableCollationWithNewGroupAccumulators TO off;
SET blackboxdb_core.enableCollation TO off;

-- =============================================================================
-- Test: reshaping ($project) stage before $group on a sharded collection.
-- The $project makes the $max/$min accumulator's document argument a computed
-- expression (not the raw stored column), and sharding forces two-phase
-- distributed aggregation (partial aggregate on the shards, combined on the
-- coordinator). The document argument must present a type that exactly matches
-- the WithExpr aggregate signature or the distributed partial aggregation aborts.
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_project_group_test','{ "_id": 1, "g": "A", "a": 5, "b": 1 }');
SELECT blackboxdb_api.insert_one('db','maxmin_project_group_test','{ "_id": 2, "g": "A", "a": 7, "b": 2 }');
SELECT blackboxdb_api.insert_one('db','maxmin_project_group_test','{ "_id": 3, "g": "B", "a": 3, "b": 3 }');
SELECT blackboxdb_api.insert_one('db','maxmin_project_group_test','{ "_id": 4, "g": "B", "a": 9, "b": 4 }');

SELECT blackboxdb_api.shard_collection('db', 'maxmin_project_group_test', '{ "_id": "hashed" }', false);

SET blackboxdb.enableNewMinMaxAccumulators TO on;
SET citus.enable_local_execution TO off;

-- Global group after a $project: $max/$min on a projected field.
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_project_group_test", "pipeline": [ { "$project": { "_id": 0, "a": 1, "b": 1 } }, { "$group": { "_id": null, "hi": { "$max": "$a" }, "lo": { "$min": "$a" } } } ] }');

-- Grouped by a non shard-key field after a $project, with a following $sort.
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_project_group_test", "pipeline": [ { "$project": { "_id": 0, "g": 1, "a": 1 } }, { "$group": { "_id": "$g", "hi": { "$max": "$a" }, "lo": { "$min": "$a" } } }, { "$sort": { "_id": 1 } } ] }');

-- Accumulator taking an expression argument after a $project.
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_project_group_test", "pipeline": [ { "$project": { "_id": 0, "a": 1, "b": 1 } }, { "$group": { "_id": null, "hi": { "$max": { "$add": ["$a", "$b"] } } } } ] }');

RESET citus.enable_local_execution;
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SELECT blackboxdb_api.drop_collection('db', 'maxmin_project_group_test');

-- =============================================================================
-- Test 18: $group with enable_min_max_skip_null_values propagated to workers.
-- A plain session-level SET does not reach the Citus workers (so the worker-side
-- transition keeps skipping nulls regardless); this test enables
-- citus.propagate_set_commands = 'local' and issues the flag as a SET LOCAL
-- inside a transaction. Citus then ships the GUC to the workers, so the
-- worker-side $min/$max transition honors it. With skipping off, explicit null
-- is considered again across shards; on the legacy path a missing field
-- (projected to null) is also considered, while the WithExpr path still excludes
-- missing regardless of the flag.
-- =============================================================================

-- Group "mixed": explicit null + missing + numbers. Skip on => min 5, max 100.
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 1,  "grp": "mixed", "val": 50 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 2,  "grp": "mixed", "val": null }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 3,  "grp": "mixed", "val": 5 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 4,  "grp": "mixed", "val": null }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 5,  "grp": "mixed", "val": 100 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 6,  "grp": "mixed" }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 7,  "grp": "mixed", "val": 30 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 8,  "grp": "mixed", "val": null }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 9,  "grp": "mixed", "val": 65 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 10, "grp": "mixed", "val": null }');

-- Group "allnull": every value is null or missing. Always min/max null.
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 11, "grp": "allnull", "val": null }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 12, "grp": "allnull" }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 13, "grp": "allnull", "val": null }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 14, "grp": "allnull" }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 15, "grp": "allnull", "val": null }');

-- Group "mk": MinKey (sorts below null) mixed with null.
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 16, "grp": "mk", "val": { "$minKey": 1 } }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 17, "grp": "mk", "val": null }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 18, "grp": "mk", "val": { "$minKey": 1 } }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 19, "grp": "mk", "val": null }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 20, "grp": "mk", "val": null }');

-- Group "missingonly": numbers + missing, no explicit null. Isolates the
-- legacy-vs-WithExpr divergence with skipping off: legacy projects missing to
-- null and considers it (min null), WithExpr excludes missing (min 5).
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 21, "grp": "missingonly", "val": 30 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 22, "grp": "missingonly", "val": 5 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 23, "grp": "missingonly" }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 24, "grp": "missingonly", "val": 42 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_dist_test','{ "_id": 25, "grp": "missingonly", "val": 7 }');

SELECT blackboxdb_api.shard_collection('db', 'maxmin_null_prop_dist_test', '{ "_id": "hashed" }', false);

-- Propagate SET LOCAL commands to workers for the queries below.
SET citus.propagate_set_commands TO 'local';

-- Legacy accumulator path, skipping ON (propagated): nulls/missing skipped.
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
BEGIN;
SET LOCAL citus.enable_local_execution TO off;
SET LOCAL blackboxdb.enable_min_max_skip_null_values TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_null_prop_dist_test", "pipeline": [ { "$group": { "_id": "$grp", "minVal": { "$min": "$val" }, "maxVal": { "$max": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
COMMIT;

-- Legacy accumulator path, skipping OFF (propagated): explicit null and missing
-- (projected to null) are considered on the workers.
BEGIN;
SET LOCAL citus.enable_local_execution TO off;
SET LOCAL blackboxdb.enable_min_max_skip_null_values TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_null_prop_dist_test", "pipeline": [ { "$group": { "_id": "$grp", "minVal": { "$min": "$val" }, "maxVal": { "$max": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
COMMIT;

-- WithExpr accumulator path, skipping ON (propagated).
SET blackboxdb.enableNewMinMaxAccumulators TO on;
SET blackboxdb.enableNewWithExprAccumulators TO on;
BEGIN;
SET LOCAL citus.enable_local_execution TO off;
SET LOCAL blackboxdb.enable_min_max_skip_null_values TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_null_prop_dist_test", "pipeline": [ { "$group": { "_id": "$grp", "minVal": { "$min": "$val" }, "maxVal": { "$max": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
COMMIT;

-- WithExpr accumulator path, skipping OFF (propagated): explicit null considered,
-- missing still excluded.
BEGIN;
SET LOCAL citus.enable_local_execution TO off;
SET LOCAL blackboxdb.enable_min_max_skip_null_values TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_null_prop_dist_test", "pipeline": [ { "$group": { "_id": "$grp", "minVal": { "$min": "$val" }, "maxVal": { "$max": "$val" } } }, { "$sort": { "_id": 1 } } ] }');
COMMIT;

RESET citus.propagate_set_commands;
RESET blackboxdb.enableNewMinMaxAccumulators;
RESET blackboxdb.enableNewWithExprAccumulators;
SELECT blackboxdb_api.drop_collection('db', 'maxmin_null_prop_dist_test');

-- =============================================================================
-- Test 19: $setWindowFields with enable_min_max_skip_null_values propagated to
-- workers. Sharding on the partition field executes each partition on a worker,
-- so the SET LOCAL flag must reach the worker for the window transition to honor
-- it. This exercises the window-function transition path (distinct from $group).
-- With skipping on, null/missing are excluded on the workers; with skipping off,
-- explicit null is considered; on the legacy path missing (projected to null) is
-- considered too, while the WithExpr path excludes it.
-- =============================================================================

SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_window_dist_test','{ "_id": 1, "grp": "mixed", "val": 50 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_window_dist_test','{ "_id": 2, "grp": "mixed", "val": null }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_window_dist_test','{ "_id": 3, "grp": "mixed", "val": 5 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_window_dist_test','{ "_id": 4, "grp": "mixed" }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_window_dist_test','{ "_id": 5, "grp": "allnull", "val": null }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_window_dist_test','{ "_id": 6, "grp": "allnull" }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_window_dist_test','{ "_id": 7, "grp": "missingonly", "val": 30 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_window_dist_test','{ "_id": 8, "grp": "missingonly", "val": 5 }');
SELECT blackboxdb_api.insert_one('db','maxmin_null_prop_window_dist_test','{ "_id": 9, "grp": "missingonly" }');

SELECT blackboxdb_api.shard_collection('db', 'maxmin_null_prop_window_dist_test', '{ "grp": "hashed" }', false);

SET citus.propagate_set_commands TO 'local';

-- Legacy accumulator path, skipping ON (propagated): the window transition on
-- workers excludes null/missing, so partitions with real values ignore them.
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;
BEGIN;
SET LOCAL citus.enable_local_execution TO off;
SET LOCAL blackboxdb.enable_min_max_skip_null_values TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_null_prop_window_dist_test", "pipeline": [ { "$setWindowFields": { "partitionBy": "$grp", "sortBy": { "_id": 1 }, "output": { "minVal": { "$min": "$val", "window": { "documents": [ "unbounded", "unbounded" ] } }, "maxVal": { "$max": "$val", "window": { "documents": [ "unbounded", "unbounded" ] } } } } }, { "$project": { "_id": 1, "grp": 1, "minVal": 1, "maxVal": 1 } }, { "$sort": { "_id": 1 } } ] }');
COMMIT;

-- Legacy accumulator path, skipping OFF (propagated).
BEGIN;
SET LOCAL citus.enable_local_execution TO off;
SET LOCAL blackboxdb.enable_min_max_skip_null_values TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_null_prop_window_dist_test", "pipeline": [ { "$setWindowFields": { "partitionBy": "$grp", "sortBy": { "_id": 1 }, "output": { "minVal": { "$min": "$val", "window": { "documents": [ "unbounded", "unbounded" ] } }, "maxVal": { "$max": "$val", "window": { "documents": [ "unbounded", "unbounded" ] } } } } }, { "$project": { "_id": 1, "grp": 1, "minVal": 1, "maxVal": 1 } }, { "$sort": { "_id": 1 } } ] }');
COMMIT;

-- WithExpr accumulator path, skipping ON (propagated): matches the legacy ON
-- results since both exclude null/missing in the window transition.
SET blackboxdb.enableNewMinMaxAccumulators TO on;
SET blackboxdb.enableNewWithExprAccumulators TO on;
BEGIN;
SET LOCAL citus.enable_local_execution TO off;
SET LOCAL blackboxdb.enable_min_max_skip_null_values TO on;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_null_prop_window_dist_test", "pipeline": [ { "$setWindowFields": { "partitionBy": "$grp", "sortBy": { "_id": 1 }, "output": { "minVal": { "$min": "$val", "window": { "documents": [ "unbounded", "unbounded" ] } }, "maxVal": { "$max": "$val", "window": { "documents": [ "unbounded", "unbounded" ] } } } } }, { "$project": { "_id": 1, "grp": 1, "minVal": 1, "maxVal": 1 } }, { "$sort": { "_id": 1 } } ] }');
COMMIT;

-- WithExpr accumulator path, skipping OFF (propagated).
BEGIN;
SET LOCAL citus.enable_local_execution TO off;
SET LOCAL blackboxdb.enable_min_max_skip_null_values TO off;
SELECT document FROM bson_aggregation_pipeline('db', '{ "aggregate": "maxmin_null_prop_window_dist_test", "pipeline": [ { "$setWindowFields": { "partitionBy": "$grp", "sortBy": { "_id": 1 }, "output": { "minVal": { "$min": "$val", "window": { "documents": [ "unbounded", "unbounded" ] } }, "maxVal": { "$max": "$val", "window": { "documents": [ "unbounded", "unbounded" ] } } } } }, { "$project": { "_id": 1, "grp": 1, "minVal": 1, "maxVal": 1 } }, { "$sort": { "_id": 1 } } ] }');
COMMIT;

RESET citus.propagate_set_commands;
RESET blackboxdb.enableNewMinMaxAccumulators;
RESET blackboxdb.enableNewWithExprAccumulators;
SELECT blackboxdb_api.drop_collection('db', 'maxmin_null_prop_window_dist_test');
