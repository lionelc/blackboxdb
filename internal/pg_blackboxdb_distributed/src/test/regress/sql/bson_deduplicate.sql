
SET search_path TO blackboxdb_api,blackboxdb_api_internal,blackboxdb_core;
SET citus.next_shard_id TO 4600000;
SET blackboxdb.next_collection_id TO 4600;
SET blackboxdb.next_collection_index_id TO 4600;

SELECT blackboxdb_api_internal.bson_deduplicate_fields(null);

SELECT blackboxdb_api_internal.bson_deduplicate_fields('{}') = '{}';

SELECT blackboxdb_api_internal.bson_deduplicate_fields('{"a":1, "a": 1}') = '{"a":1}';
SELECT blackboxdb_api_internal.bson_deduplicate_fields('{"a":1, "a": 1}') = '{"a":1}';

SELECT blackboxdb_api_internal.bson_deduplicate_fields('{"a": 1, "b": [{"c": 1, "c": 2}, {"c": {"e": 1, "z": [], "e": 2}}], "a": null}') =
                                                  '{"a": null, "b" : [{"c": 2}, {"c": {"e": 2, "z": []}}]}';
SELECT blackboxdb_api_internal.bson_deduplicate_fields('{"a": 1, "b": [{"c": 1, "c": [1, 1, "text", {"d": 1, "d": 2}]}, {"c": {"e": 1, "e": 2}}], "a": 2}') =
                                                  '{"a": 2, "b": [{"c": [1, 1, "text", {"d": 2}]}, {"c": {"e": 2}}]}';
SELECT blackboxdb_api_internal.bson_deduplicate_fields('{"a": 1, "a.b": 2, "a.b.c": "text"}') = '{"a": 1, "a.b": 2, "a.b.c": "text"}';
