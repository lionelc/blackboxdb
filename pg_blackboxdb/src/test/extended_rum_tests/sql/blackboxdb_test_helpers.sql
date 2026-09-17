\i ../regress/sql/blackboxdb_test_helpers.sql

CREATE OR REPLACE FUNCTION blackboxdb_api_internal.rum_prune_empty_entries_on_index(index_relid regclass)
RETURNS void
LANGUAGE c
AS '$libdir/pg_blackboxdb_extended_rum_core', 'blackboxdb_rum_prune_empty_entries_on_index';

CREATE OR REPLACE FUNCTION blackboxdb_api_internal.blackboxdb_rum_page_get_stats(page bytea)
RETURNS jsonb
LANGUAGE c
AS '$libdir/pg_blackboxdb_extended_rum_core', 'blackboxdb_rum_page_get_stats';

CREATE OR REPLACE FUNCTION blackboxdb_api_internal.blackboxdb_rum_get_meta_page_info(page bytea)
RETURNS jsonb
LANGUAGE c
AS '$libdir/pg_blackboxdb_extended_rum_core', 'blackboxdb_rum_get_meta_page_info';

CREATE OR REPLACE FUNCTION blackboxdb_api_internal.blackboxdb_rum_page_get_entries(page bytea, indexRelId Oid)
RETURNS SETOF jsonb
LANGUAGE c
AS '$libdir/pg_blackboxdb_extended_rum_core', 'blackboxdb_rum_page_get_entries';

-- Turn off cron jobs to avoid flakiness in tests.
UPDATE cron.job set active = false;