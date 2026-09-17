-- blackboxdb_core GUC snake_case naming convention enforcement.
--
-- All GUCs registered under the 'blackboxdb_core.' prefix must be snake_case, i.e. match
-- '^blackboxdb_core\.[a-z0-9_]+$' (lowercase letters, digits and underscores; no uppercase,
-- camelCase or nested dots).
--
-- The baseline table below grandfathers GUCs that predate this convention. It is expected
-- to only shrink over time (never grow):
--   * A NEW non-conforming GUC makes 'all_snake_case' false and lists the name(s) in
--     'violations' -- rename the GUC to snake_case.
--   * A baseline entry whose GUC no longer exists makes 'baseline_is_current' false and
--     lists the name(s) in 'stale_baseline_entries' -- remove it from the baseline below.
--
-- When clean, the output is stable ('t' with empty text columns), so the expected file
-- does not need routine updates and merge conflicts are minimized.
CREATE TEMP TABLE blackboxdb_core_guc_naming_baseline (name text);
INSERT INTO blackboxdb_core_guc_naming_baseline (name) VALUES
    ('blackboxdb_core.bsonUseEJson'),
    ('blackboxdb_core.enableBsonSelectivityFromBtreeStats'),
    ('blackboxdb_core.enableCollation'),
    ('blackboxdb_core.enableWriteDocumentsInRepath'),
    ('blackboxdb_core.skipBsonArrayTraverseOptimization');

-- Non-conforming GUCs that are not grandfathered by the baseline.
SELECT
    NOT EXISTS (
        SELECT 1
        FROM pg_settings s
        LEFT JOIN blackboxdb_core_guc_naming_baseline b ON b.name = s.name
        WHERE s.name ~ '^blackboxdb_core\.'
          AND s.name !~ '^blackboxdb_core\.[a-z0-9_]+$'
          AND b.name IS NULL
    ) AS all_snake_case,
    (
        SELECT 'GUCs should follow snake casing and not contain nested dots. The following GUCs do not: ' || string_agg(s.name, ', ' ORDER BY s.name)
        FROM pg_settings s
        LEFT JOIN blackboxdb_core_guc_naming_baseline b ON b.name = s.name
        WHERE s.name ~ '^blackboxdb_core\.'
          AND s.name !~ '^blackboxdb_core\.[a-z0-9_]+$'
          AND b.name IS NULL
    ) AS violations;

-- Baseline entries whose GUC no longer exists; these must be pruned from the baseline.
SELECT
    NOT EXISTS (
        SELECT 1
        FROM blackboxdb_core_guc_naming_baseline b
        LEFT JOIN pg_settings s ON s.name = b.name
        WHERE s.name IS NULL
    ) AS baseline_is_current,
    (
        SELECT 'Baseline entries no longer exist as GUCs and must be removed from this test: ' || string_agg(b.name, ', ' ORDER BY b.name)
        FROM blackboxdb_core_guc_naming_baseline b
        LEFT JOIN pg_settings s ON s.name = b.name
        WHERE s.name IS NULL
    ) AS stale_baseline_entries;

DROP TABLE blackboxdb_core_guc_naming_baseline;
