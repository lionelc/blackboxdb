SET citus.next_shard_id TO 60000;
SET blackboxdb.next_collection_id TO 6000;
SET blackboxdb.next_collection_index_id TO 6000;
SET blackboxdb.enableNewMinMaxAccumulators TO off;
SET blackboxdb.enableNewWithExprAccumulators TO off;

\i sql/bson_aggregation_stage_lookup_tests_core.sql