SET search_path TO blackboxdb_api_catalog, blackboxdb_api, blackboxdb_core, public;
SET citus.next_shard_id TO 11800000;
SET blackboxdb.next_collection_id TO 11800;
SET blackboxdb.next_collection_index_id TO 11800;

SET citus.multi_shard_modify_mode TO 'sequential';

-- Route unsharded-collection cursor queries through the remote unsharded code
-- path: disabling local-execution shard queries marks the single shard as
-- remote, and dynamic cursors must be enabled for the remote dispatch.
SET blackboxdb.enableDynamicCursors TO on;
SET blackboxdb.useLocalExecutionShardQueries TO off;

-- The remote dynamic cursor's worker continuation embeds a per-run unique cursor
-- id / file name (masked in-test via aggregation_cursor_test.mask_continuation).
-- Use unaligned output so psql column widths do not depend on the (pre-masking)
-- length of those volatile values.
\a

SET blackboxdb.enablePerCollectionPlannerStatistics TO on;
SET blackboxdb.enableCompositeIndexPlanner TO on;
SET blackboxdb.enablePlannerStatisticsNewCollections TO on;

\i sql/bson_aggregation_cursor_tests_core.sql
\i sql/bson_aggregation_cursor_integration_tests_core.sql
