SET search_path TO blackboxdb_api,blackboxdb_core,blackboxdb_api_catalog;

SET blackboxdb.next_collection_id TO 1700;
SET blackboxdb.next_collection_index_id TO 1700;

SET blackboxdb.enableCompositeReducedCorrelatedTermsOnCommonSubPath TO on;

-- =====================================================================
-- 1) Common prefix: a.b, a.c → both share prefix "a" → rct=true
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "common_prefix", "indexes": [ { "key": { "a.b": 1, "a.c": 1 }, "name": "idx_ab_ac" } ] }');
\d blackboxdb_data.documents_1701

-- =====================================================================
-- 2) Different prefixes: a.b, c.d → no common prefix → no rct
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "diff_prefix", "indexes": [ { "key": { "a.b": 1, "c.d": 1 }, "name": "idx_ab_cd" } ] }');
\d blackboxdb_data.documents_1702

-- =====================================================================
-- 3) No dots: a, b → no dotted prefix extracted → no rct
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "no_dots", "indexes": [ { "key": { "a": 1, "b": 1 }, "name": "idx_a_b" } ] }');
\d blackboxdb_data.documents_1703

-- =====================================================================
-- 4) Single key a.b → not multi-path → no rct
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "single_key", "indexes": [ { "key": { "a.b": 1 }, "name": "idx_ab_only" } ] }');
\d blackboxdb_data.documents_1704

-- =====================================================================
-- 5) _id prefix: _id.a, _id.b → prefix is "_id" which is excluded → no rct
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "id_prefix", "indexes": [ { "key": { "_id.a": 1, "_id.b": 1 }, "name": "idx_ida_idb" } ] }');
\d blackboxdb_data.documents_1705

-- =====================================================================
-- 6) Mixed: a.b, a.c, d.e → "a" appears twice → rct=true
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "mixed_common", "indexes": [ { "key": { "a.b": 1, "a.c": 1, "d.e": 1 }, "name": "idx_ab_ac_de" } ] }');
\d blackboxdb_data.documents_1706

-- =====================================================================
-- 7) _id paths plus non-_id common prefix: _id.a, _id.b, x.y, x.z
--    _id is excluded, but "x" appears twice → rct=true
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "id_plus_common", "indexes": [ { "key": { "_id.a": 1, "_id.b": 1, "x.y": 1, "x.z": 1 }, "name": "idx_ida_idb_xy_xz" } ] }');
\d blackboxdb_data.documents_1707

-- =====================================================================
-- 8) Mix of dotted and non-dotted: a, a.b → "a" has no dot so prefix
--    is empty; only one "a" prefix from "a.b" → no common → no rct
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "dot_nodot", "indexes": [ { "key": { "a": 1, "a.b": 1 }, "name": "idx_a_ab" } ] }');
\d blackboxdb_data.documents_1708

-- =====================================================================
-- 9) Three different prefixes: a.b, c.d, e.f → all different → no rct
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "three_diff", "indexes": [ { "key": { "a.b": 1, "c.d": 1, "e.f": 1 }, "name": "idx_ab_cd_ef" } ] }');
\d blackboxdb_data.documents_1709

-- =====================================================================
-- 10) Deeper paths with same top-level prefix: a.b.c, a.d.e
--     prefix is "a" for both (up to first dot) → rct=true
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "deep_common", "indexes": [ { "key": { "a.b.c": 1, "a.d.e": 1 }, "name": "idx_abc_ade" } ] }');
\d blackboxdb_data.documents_1710

-- =====================================================================
-- 11) Unique index with common prefix: a.b, a.c (unique)
--     The common sub-path flag applies regardless of unique → rct=true
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "unique_common", "indexes": [ { "key": { "a.b": 1, "a.c": 1 }, "name": "idx_unique_ab_ac", "unique": true } ] }');
\d blackboxdb_data.documents_1711

-- =====================================================================
-- 12) Unique index without common prefix: a.b, c.d (unique)
--     No common prefix → no rct
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "unique_diff", "indexes": [ { "key": { "a.b": 1, "c.d": 1 }, "name": "idx_unique_ab_cd", "unique": true } ] }');
\d blackboxdb_data.documents_1712

-- =====================================================================
-- 13) Flag OFF: common prefix a.b, a.c but flag disabled → no rct
-- =====================================================================
SET blackboxdb.enableCompositeReducedCorrelatedTermsOnCommonSubPath TO off;
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "flag_off", "indexes": [ { "key": { "a.b": 1, "a.c": 1 }, "name": "idx_flag_off" } ] }');
\d blackboxdb_data.documents_1713
SET blackboxdb.enableCompositeReducedCorrelatedTermsOnCommonSubPath TO on;

-- =====================================================================
-- 14) Only _id prefix paths among dotted: _id.x, _id.y, a, b
--     _id is excluded, a and b have no dots → no rct
-- =====================================================================
SELECT blackboxdb_api_internal.create_indexes_non_concurrently(
    'rct_sub_db', '{ "createIndexes": "id_and_nodot", "indexes": [ { "key": { "_id.x": 1, "_id.y": 1, "a": 1, "b": 1 }, "name": "idx_idx_idy_a_b" } ] }');
\d blackboxdb_data.documents_1714
