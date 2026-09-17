
-- top level
SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 1, "a": []}', NULL);

SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 2, "a": [1, 2]}', NULL);

SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 3, "a": ["a", "a"]}', NULL);

SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 4, "a": 1}', NULL);

SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 5, "b": [1, 2]}', NULL);

-- nested object
SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 6, "a": {"b":[]}}', NULL);

SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 7, "a": {"b":[1, 2]}}', NULL);

SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 8, "a": {"b":["a", "a"]}}', NULL);

SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 9, "a": {"b":1}}', NULL);

SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 10, "b": {"b":[1, 2]}}', NULL);

-- nested array
SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 11, "c": [{"b":[]}]}', NULL);

SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 12, "c": [{"b":[1, 2]}]}', NULL);

SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 13, "c": [{"b":["a", "a"]}]}', NULL);

SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 14, "c": [{"b":1}]}', NULL);

SELECT blackboxdb_api.insert_one('db','arraysize','{"_id": 15, "b": [{"b":[1, 2]}]}', NULL);

-- assert that size returns the correct number of rows.
SELECT COUNT(*) FROM blackboxdb_api.collection('db', 'arraysize') where document @@# '{ "a" : 0 }';

SELECT COUNT(*) FROM blackboxdb_api.collection('db', 'arraysize') where document @@# '{ "a" : 2 }';

SELECT COUNT(*) FROM blackboxdb_api.collection('db', 'arraysize') where document @@# '{ "a.b" : 0 }';

SELECT COUNT(*) FROM blackboxdb_api.collection('db', 'arraysize') where document @@# '{ "a.b" : 2 }';

SELECT COUNT(*) FROM blackboxdb_api.collection('db', 'arraysize') where document @@# '{ "c.b" : 0 }';

SELECT COUNT(*) FROM blackboxdb_api.collection('db', 'arraysize') where document @@# '{ "c.b" : 2 }';
