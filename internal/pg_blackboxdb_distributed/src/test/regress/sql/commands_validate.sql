SET search_path TO blackboxdb_core,blackboxdb_api,blackboxdb_api_catalog,blackboxdb_api_internal;
SET citus.next_shard_id TO 870000;
SET blackboxdb.next_collection_id TO 8700;
SET blackboxdb.next_collection_index_id TO 8700;

SELECT blackboxdb_api.drop_collection('db', 'validatecoll');

-- Empty collection name
SELECT blackboxdb_api.validate('db','{}');
SELECT blackboxdb_api.validate('db', '{"validate" : ""}');

-- Collection does not exist
SELECT blackboxdb_api.validate('db', '{"validate" : "missingcoll"}');

-- Create Collection
SELECT blackboxdb_api.create_collection('db', 'validatecoll');

-- Collection without docs and with only id index/no user defined indexes
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll"}');

-- Collection with id index and an additional index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('db', blackboxdb_distributed_test_helpers.generate_create_index_arg('validatecoll', 'index_1', '{"a": 1}'), true);
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll"}');

-- Insert few docs
SELECT blackboxdb_api.insert_one('db','validatecoll','{"_id":"1", "a": 100 }');
SELECT blackboxdb_api.insert_one('db','validatecoll','{"_id":"1", "a": 101, "b": 201 }');
SELECT blackboxdb_api.insert_one('db','validatecoll','{"_id":"1", "a": 102, "b": 202 }');

-- Collection with docs and user defined index
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll"}');

-- Valid input options --
-- only validate
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll"}');

-- validate with repair: true or repair: false remains same
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll", "full" : null, "repair" : false}');

-- validate with full: true or full: false remains same
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll", "full" : false}');
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll", "full" : true}');

-- validate with metadata: true or metadata: false remains same
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll", "full" : null, "repair" : null, "metadata" : false}');
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll", "full" : null, "repair" : null, "metadata" : true}');

-- Invalid input options --
--validate with repair: true
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll", "repair" : true}');

-- validate with repair and full
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll", "full" : true, "repair" : true}');

-- validate with repair and metadata
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll", "repair" : true, "metadata" : true}');

-- validate with full and metadata
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll", "full" : true,  "metadata" : true}');

-- validate with repair, full and metadata
SELECT blackboxdb_api.validate('db', '{"validate" : "validatecoll", "full" : true, "metadata" : true, "repair" : true}');

-- validate field is an object
SELECT blackboxdb_api.validate('db','{"validate":{}}');