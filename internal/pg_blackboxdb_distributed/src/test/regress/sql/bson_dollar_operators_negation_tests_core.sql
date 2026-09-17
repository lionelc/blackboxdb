
SELECT blackboxdb_api.insert_one('db','simple_negation_tests', '{"_id": 1, "a" : { "b" : 0 }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests', '{"_id": 2, "a" : { "b" : 1 }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests', '{"_id": 3, "a" : { "b" : 2.0 }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests', '{"_id": 4, "a" : { "b" : null }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests', '{"_id": 5, "a" : { "b" : true }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests', '{"_id": 6, "a" : { "b" : { "$numberDouble": "Infinity" } }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests', '{"_id": 7, "a" : { "b" : { "$numberDouble": "NaN" } }}', NULL);

SELECT blackboxdb_api.insert_one('db','simple_negation_tests', '{"_id": 8, "a" : { "b" : "stringb8" }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests', '{"_id": 9, "a" : { "b" : "stringb9" }}', NULL);
SELECT blackboxdb_api.insert_one('db','simple_negation_tests', '{"_id": 10, "a" : { "b" : "stringb10" }}', NULL);

-- do a search
SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests') WHERE document @@ '{ "a.b": { "$gt": 2 }}';

-- do the complement
SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests') WHERE document @@ '{ "a.b": { "$lte": 2 }}';

-- do the NOTs
SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests') WHERE document @@ '{ "a.b": { "$not": { "$gt": 2 } }}';
SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests') WHERE document @@ '{ "a.b": { "$not": { "$lte": 2 } }}';

-- Now try $gte/$lt
SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests') WHERE document @@ '{ "a.b": { "$gte": 2 }}';
SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests') WHERE document @@ '{ "a.b": { "$lt": 2 }}';
SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests') WHERE document @@ '{ "a.b": { "$not": { "$gte": 2 } }}';
SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests') WHERE document @@ '{ "a.b": { "$not": { "$lt": 2 } }}';

-- $gte: Minkey (Exists doesn't factor in this)
SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests') WHERE document @@ '{ "a.b": { "$exists": true } }';
SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests') WHERE document @@ '{ "a.b": { "$exists": false } }';

SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests') WHERE document @@ '{ "a.b": { "$not": { "$exists": true } } }';
SELECT document FROM blackboxdb_api.collection('db', 'simple_negation_tests') WHERE document @@ '{ "a.b": { "$not": { "$exists": false } } }';