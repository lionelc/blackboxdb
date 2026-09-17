SET citus.next_shard_id TO 95100000;
SET blackboxdb.next_collection_id TO 95100;
SET blackboxdb.next_collection_index_id TO 95100;

SET blackboxdb_api.forceUseIndexIfAvailable TO on;
SET blackboxdb.enableCollationWithNonUniqueOrderedIndexes TO on;
SET blackboxdb.defaultUseCompositeOpClass TO on;
SET blackboxdb.enableExtendedExplainPlans TO on;
SET enable_seqscan TO OFF;

-- ======================================================================
-- Create collation-aware indexes (en, strength 1) on every runtime collection
-- the core body queries. The core body subsequently inserts rows and
-- shards the collections; indexes propagate to all shards.
-- ======================================================================

-- coll_lookup_d: $lookup join key on `a.b`.
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('coll_q_dist_db',
  '{ "createIndexes": "coll_lookup_d",
     "indexes": [{ "key": {"a.b": 1}, "name": "idx_ab_en_s1",
                   "collation": {"locale": "en", "strength": 1} }] }', TRUE);

-- coll_graph_src_d: $graphLookup startWith on `pet`.
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('coll_q_dist_db',
  '{ "createIndexes": "coll_graph_src_d",
     "indexes": [{ "key": {"pet": 1}, "name": "idx_pet_en_s1",
                   "collation": {"locale": "en", "strength": 1} }] }', TRUE);

-- coll_graph_dst_d: $graphLookup connectToField `name`.
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('coll_q_dist_db',
  '{ "createIndexes": "coll_graph_dst_d",
     "indexes": [{ "key": {"name": 1}, "name": "idx_name_en_s1",
                   "collation": {"locale": "en", "strength": 1} }] }', TRUE);

-- coll_agg_d: equality / aggregation predicates on `a`.
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('coll_q_dist_db',
  '{ "createIndexes": "coll_agg_d",
     "indexes": [{ "key": {"a": 1}, "name": "idx_a_en_s1",
                   "collation": {"locale": "en", "strength": 1} }] }', TRUE);

-- single_field_d: aggregation predicates on `a`.
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('coll_q_dist_db',
  '{ "createIndexes": "single_field_d",
     "indexes": [{ "key": {"a": 1}, "name": "idx_a_en_s1",
                   "collation": {"locale": "en", "strength": 1} }] }', TRUE);

-- coll_delete_d: delete predicates on `a` (also the shard key).
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('coll_q_dist_db',
  '{ "createIndexes": "coll_delete_d",
     "indexes": [{ "key": {"a": 1}, "name": "idx_a_en_s1",
                   "collation": {"locale": "en", "strength": 1} }] }', TRUE);

-- coll_qm_d: bson_query_match predicates on `a`.
SELECT blackboxdb_api_internal.create_indexes_non_concurrently('coll_q_dist_db',
  '{ "createIndexes": "coll_qm_d",
     "indexes": [{ "key": {"a": 1}, "name": "idx_a_en_s1",
                   "collation": {"locale": "en", "strength": 1} }] }', TRUE);

\i sql/bson_collation_query_tests_dist_core.sql
