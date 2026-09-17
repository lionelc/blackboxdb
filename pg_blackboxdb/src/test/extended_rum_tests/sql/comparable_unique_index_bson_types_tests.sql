
SET search_path TO blackboxdb_api, blackboxdb_core, blackboxdb_api_catalog, blackboxdb_api_internal;

SET blackboxdb.next_collection_id TO 1900;
SET blackboxdb.next_collection_index_id TO 1900;

SET blackboxdb.enableComparableTerms TO on;

-- ========================================================================
-- Section 1: Create unique index FIRST, then insert all BSON types
-- ========================================================================

SELECT blackboxdb_api.create_collection('comp_unique_db', 'idx_first');

-- Create a single-field unique index
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
  'comp_unique_db',
  '{ "createIndexes": "idx_first", "indexes": [
      { "key": { "val": 1 }, "name": "val_unique", "unique": true, "enableOrderedIndex": true }
  ]}', true);

-- Insert documents covering all major BSON types for the unique field
-- int32
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 1, "val": {"$numberInt": "42"}}');
-- int64
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 2, "val": {"$numberLong": "9223372036854775807"}}');
-- double
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 3, "val": {"$numberDouble": "3.14"}}');
-- string
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 4, "val": "hello"}');
-- boolean true
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 5, "val": true}');
-- boolean false
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 6, "val": false}');
-- null
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 7, "val": null}');
-- objectId
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 8, "val": {"$oid": "507f1f77bcf86cd799439011"}}');
-- date
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 9, "val": {"$date": {"$numberLong": "1627846267000"}}}');
-- timestamp
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 10, "val": {"$timestamp": {"t": 1627846267, "i": 1}}}');
-- binary
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 11, "val": {"$binary": {"base64": "SGVsbG8=", "subType": "00"}}}');
-- regex
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 12, "val": {"$regularExpression": {"pattern": "abc", "options": "i"}}}');
-- nested document
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 13, "val": {"a": 1, "b": "text"}}');
-- array
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 14, "val": [1, "two", 3]}');
-- decimal128
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 15, "val": {"$numberDecimal": "123.456"}}');
-- minKey
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 16, "val": {"$minKey": 1}}');
-- maxKey
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 17, "val": {"$maxKey": 1}}');

-- Document with NO fields matching the unique index key (missing "val" entirely)
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 18, "other_field": "no val here"}');

-- A second document missing "val" should fail (duplicate null key)
SELECT blackboxdb_api.insert_one('comp_unique_db', 'idx_first', '{"_id": 19, "another_field": "also no val"}');

-- Verify all inserted docs via the index
SELECT document FROM blackboxdb_api.collection('comp_unique_db', 'idx_first') ORDER BY object_id;

-- ========================================================================
-- Section 2: Create composite unique index FIRST, then insert
-- ========================================================================

SELECT blackboxdb_api.create_collection('comp_unique_db', 'comp_idx_first');

-- Composite unique index on (a, b)
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
  'comp_unique_db',
  '{ "createIndexes": "comp_idx_first", "indexes": [
      { "key": { "a": 1, "b": 1 }, "name": "ab_unique", "unique": true, "enableOrderedIndex": true }
  ]}', true);

-- Various type combinations for composite keys
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_idx_first', '{"_id": 1, "a": {"$numberInt": "1"}, "b": "x"}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_idx_first', '{"_id": 2, "a": {"$numberInt": "1"}, "b": "y"}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_idx_first', '{"_id": 3, "a": "str", "b": {"$numberDouble": "2.5"}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_idx_first', '{"_id": 4, "a": true, "b": {"$oid": "507f1f77bcf86cd799439011"}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_idx_first', '{"_id": 5, "a": null, "b": {"$date": {"$numberLong": "1627846267000"}}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_idx_first', '{"_id": 6, "a": {"$numberDecimal": "99.9"}, "b": {"$timestamp": {"t": 100, "i": 1}}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_idx_first', '{"_id": 7, "a": {"$binary": {"base64": "AQID", "subType": "00"}}, "b": {"$minKey": 1}}');

-- Document with no matching fields (both a and b missing)
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_idx_first', '{"_id": 8, "c": "irrelevant"}');

-- Second doc missing both a and b should fail (duplicate null compound key)
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_idx_first', '{"_id": 9, "d": "also irrelevant"}');

-- Duplicate composite key should fail
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_idx_first', '{"_id": 10, "a": {"$numberInt": "1"}, "b": "x"}');

SELECT document FROM blackboxdb_api.collection('comp_unique_db', 'comp_idx_first') ORDER BY object_id;

-- ========================================================================
-- Section 3: Insert documents FIRST, then create unique index
-- ========================================================================

SELECT blackboxdb_api.create_collection('comp_unique_db', 'ins_first');

-- Insert all BSON types before index exists
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 1, "val": {"$numberInt": "42"}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 2, "val": {"$numberLong": "9223372036854775807"}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 3, "val": {"$numberDouble": "3.14"}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 4, "val": "hello"}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 5, "val": true}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 6, "val": false}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 7, "val": null}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 8, "val": {"$oid": "507f1f77bcf86cd799439011"}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 9, "val": {"$date": {"$numberLong": "1627846267000"}}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 10, "val": {"$timestamp": {"t": 1627846267, "i": 1}}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 11, "val": {"$binary": {"base64": "SGVsbG8=", "subType": "00"}}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 12, "val": {"$regularExpression": {"pattern": "abc", "options": "i"}}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 13, "val": {"a": 1, "b": "text"}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 14, "val": [1, "two", 3]}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 15, "val": {"$numberDecimal": "123.456"}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 16, "val": {"$minKey": 1}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 17, "val": {"$maxKey": 1}}');

-- Now create the unique index over existing data (should succeed — all values are distinct)
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
  'comp_unique_db',
  '{ "createIndexes": "ins_first", "indexes": [
      { "key": { "val": 1 }, "name": "val_unique", "unique": true, "enableOrderedIndex": true }
  ]}', true);

-- Insert a document with no "val" field after index exists (missing = null for uniqueness)
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 18, "other_field": "no val here"}');

-- A second missing-field doc should conflict with _id:18's null
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 20, "yet_another": "also missing val"}');

-- Verify uniqueness enforced after index creation
SELECT blackboxdb_api.insert_one('comp_unique_db', 'ins_first', '{"_id": 19, "val": {"$numberInt": "42"}}');

SELECT document FROM blackboxdb_api.collection('comp_unique_db', 'ins_first') ORDER BY object_id;

-- ========================================================================
-- Section 4: Insert FIRST, then create composite unique index
-- ========================================================================

SELECT blackboxdb_api.create_collection('comp_unique_db', 'comp_ins_first');

SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_ins_first', '{"_id": 1, "a": {"$numberInt": "1"}, "b": "x"}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_ins_first', '{"_id": 2, "a": {"$numberInt": "1"}, "b": "y"}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_ins_first', '{"_id": 3, "a": "str", "b": {"$numberDouble": "2.5"}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_ins_first', '{"_id": 4, "a": true, "b": {"$oid": "507f1f77bcf86cd799439011"}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_ins_first', '{"_id": 5, "a": null, "b": {"$date": {"$numberLong": "1627846267000"}}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_ins_first', '{"_id": 6, "a": {"$numberDecimal": "99.9"}, "b": {"$timestamp": {"t": 100, "i": 1}}}');
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_ins_first', '{"_id": 7, "a": {"$binary": {"base64": "AQID", "subType": "00"}}, "b": {"$minKey": 1}}');
-- Document with no matching fields
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_ins_first', '{"_id": 8, "c": "irrelevant"}');

-- Create composite unique index over existing data
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
  'comp_unique_db',
  '{ "createIndexes": "comp_ins_first", "indexes": [
      { "key": { "a": 1, "b": 1 }, "name": "ab_unique", "unique": true, "enableOrderedIndex": true }
  ]}', true);

-- Duplicate compound key should fail
SELECT blackboxdb_api.insert_one('comp_unique_db', 'comp_ins_first', '{"_id": 9, "a": {"$numberInt": "1"}, "b": "x"}');

SELECT document FROM blackboxdb_api.collection('comp_unique_db', 'comp_ins_first') ORDER BY object_id;

-- ========================================================================
-- Section 5: Null-equivalent duplicate violations on a single-field index
-- All of the following should be treated as "null" for uniqueness:
--   missing field, literal null, literal undefined,
--   array containing null, array containing undefined
-- ========================================================================

SELECT blackboxdb_api.create_collection('comp_unique_db', 'null_dupes');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
  'comp_unique_db',
  '{ "createIndexes": "null_dupes", "indexes": [
      { "key": { "val": 1 }, "name": "val_unique", "unique": true, "enableOrderedIndex": true }
  ]}', true);

-- 1) missing field
SELECT blackboxdb_api.insert_one('comp_unique_db', 'null_dupes', '{"_id": 1, "other": "x"}');
-- 2) literal null — should conflict with missing field
SELECT blackboxdb_api.insert_one('comp_unique_db', 'null_dupes', '{"_id": 2, "val": null}');
-- 3) literal undefined — should conflict
SELECT blackboxdb_api.insert_one('comp_unique_db', 'null_dupes', '{"_id": 3, "val": {"$undefined": true}}');
-- 4) array containing null — should conflict
SELECT blackboxdb_api.insert_one('comp_unique_db', 'null_dupes', '{"_id": 4, "val": [null]}');
-- 5) array containing undefined — should conflict
SELECT blackboxdb_api.insert_one('comp_unique_db', 'null_dupes', '{"_id": 5, "val": [{"$undefined": true}]}');

SELECT document FROM blackboxdb_api.collection('comp_unique_db', 'null_dupes') ORDER BY object_id;

-- ========================================================================
-- Section 6: Null-equivalent duplicate violations on a nested path "a.b"
-- with an array that has one element with "b" present and one without
-- ========================================================================

SELECT blackboxdb_api.create_collection('comp_unique_db', 'nested_null_dupes');

SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
  'comp_unique_db',
  '{ "createIndexes": "nested_null_dupes", "indexes": [
      { "key": { "a.b": 1 }, "name": "ab_unique", "unique": true, "enableOrderedIndex": true }
  ]}', true);

-- Document where a is an array: one element has b (integer), one element is missing b.
-- This produces index keys for both the integer value and null (missing).
SELECT blackboxdb_api.insert_one('comp_unique_db', 'nested_null_dupes', '{"_id": 1, "a": [{"b": 42}, {"c": "no b here"}]}');

-- Another doc with a.b missing entirely — should conflict with the null branch above
SELECT blackboxdb_api.insert_one('comp_unique_db', 'nested_null_dupes', '{"_id": 2, "other": "no a at all"}');

-- Another doc with a.b = literal null — should also conflict
SELECT blackboxdb_api.insert_one('comp_unique_db', 'nested_null_dupes', '{"_id": 3, "a": {"b": null}}');

-- Another doc with a.b = undefined — should also conflict
SELECT blackboxdb_api.insert_one('comp_unique_db', 'nested_null_dupes', '{"_id": 4, "a": {"b": {"$undefined": true}}}');

-- A non-conflicting doc with a different integer value for a.b
SELECT blackboxdb_api.insert_one('comp_unique_db', 'nested_null_dupes', '{"_id": 5, "a": {"b": 99}}');

-- Duplicate integer value for a.b — should conflict with _id: 1's a.b=42
SELECT blackboxdb_api.insert_one('comp_unique_db', 'nested_null_dupes', '{"_id": 6, "a": {"b": 42}}');

SELECT document FROM blackboxdb_api.collection('comp_unique_db', 'nested_null_dupes') ORDER BY object_id;

RESET blackboxdb.enableComparableTerms;
