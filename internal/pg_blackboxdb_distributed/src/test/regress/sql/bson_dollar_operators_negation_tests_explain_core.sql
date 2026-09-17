
SELECT blackboxdb_api.insert_one('db','simple_negation_tests_explain', '{"_id": 1, "a" : { "b" : 0 }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests_explain', '{"_id": 2, "a" : { "b" : 1 }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests_explain', '{"_id": 3, "a" : { "b" : 2.0 }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests_explain', '{"_id": 4, "a" : { "b" : null }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests_explain', '{"_id": 5, "a" : { "b" : true }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests_explain', '{"_id": 6, "a" : { "b" : { "$numberDouble": "Infinity" } }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests_explain', '{"_id": 7, "a" : { "b" : { "$numberDouble": "NaN" } }}', NULL);

SELECT blackboxdb_api.insert_one('db','simple_negation_tests_explain', '{"_id": 8, "a" : { "b" : "stringb8" }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests_explain', '{"_id": 9, "a" : { "b" : "stringb9" }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests_explain', '{"_id": 10, "a" : { "b" : "stringb10" }}', NULL);

-- do a search
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests_explain') WHERE document @@ '{ "a.b": { "$gt": 2 }}';

-- do the complement
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests_explain') WHERE document @@ '{ "a.b": { "$lte": 2 }}';

-- do the NOTs
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests_explain') WHERE document @@ '{ "a.b": { "$not": { "$gt": 2 } }}';
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests_explain') WHERE document @@ '{ "a.b": { "$not": { "$lte": 2 } }}';

-- Now try $gte/$lt
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests_explain') WHERE document @@ '{ "a.b": { "$gte": 2 }}';
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests_explain') WHERE document @@ '{ "a.b": { "$lt": 2 }}';
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests_explain') WHERE document @@ '{ "a.b": { "$not": { "$gte": 2 } }}';
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests_explain') WHERE document @@ '{ "a.b": { "$not": { "$lt": 2 } }}';

-- $gte: Minkey (Exists doesn't factor in this)
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests_explain') WHERE document @@ '{ "a.b": { "$exists": true } }';
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests_explain') WHERE document @@ '{ "a.b": { "$exists": false } }';

EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests_explain') WHERE document @@ '{ "a.b": { "$not": { "$exists": true } } }';
EXPLAIN (COSTS OFF, VERBOSE ON) SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests_explain') WHERE document @@ '{ "a.b": { "$not": { "$exists": false } } }';