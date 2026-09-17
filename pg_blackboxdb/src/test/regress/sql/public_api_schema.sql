-- show all functions, procedures, aggregates and window aggregates exported in blackboxdb_api.
\df blackboxdb_api.*

\df blackboxdb_api_catalog.*

\df blackboxdb_api_internal.*

\df blackboxdb_data.*

-- Access methods + Operator families
\dA *blackboxdb*

\dAc *blackboxdb*

\dAf *blackboxdb*

\dX *blackboxdb*

-- This is last (Tables/indexes)
\d blackboxdb_api.*

\d blackboxdb_api_internal.*

\d blackboxdb_api_catalog.*

\d blackboxdb_data.*

-- show all functions, procedures, aggregates and window aggregates in blackboxdb_api_v2.
\df blackboxdb_api_v2.*

-- show all functions, procedures, aggregates and window aggregates in blackboxdb_api_internal_readonly.
\df blackboxdb_api_internal_readonly.*

-- show all functions, procedures, aggregates and window aggregates in blackboxdb_api_internal_readwrite.
\df blackboxdb_api_internal_readwrite.*

-- show all functions, procedures, aggregates and window aggregates in blackboxdb_api_internal_admin.
\df blackboxdb_api_internal_admin.*

-- show all functions, procedures, aggregates and window aggregates in blackboxdb_api_internal_bgworker.
\df blackboxdb_api_internal_bgworker.*

-- show roles and privileges per schema using has_function_privilege
SELECT n.nspname AS schema, proname,
       has_function_privilege('blackboxdb_readonly_role', p.oid, 'EXECUTE') AS readonly_role_has_exec,
       has_function_privilege('blackboxdb_readwrite_role', p.oid, 'EXECUTE') AS readwrite_role_has_exec,
       has_function_privilege('blackboxdb_admin_role', p.oid, 'EXECUTE') AS admin_role_has_exec,
       has_function_privilege('blackboxdb_api_find_role', p.oid, 'EXECUTE') AS find_role_has_exec,
       has_function_privilege('blackboxdb_api_insert_role', p.oid, 'EXECUTE') AS insert_role_has_exec,
       has_function_privilege('blackboxdb_api_update_role', p.oid, 'EXECUTE') AS update_role_has_exec,
       has_function_privilege('blackboxdb_api_remove_role', p.oid, 'EXECUTE') AS remove_role_has_exec
FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'blackboxdb_api_v2' ORDER BY n.nspname, proname;

-- For internal schemas, check schema USAGE privileges per role (functions use default PUBLIC ACL,
-- so access is controlled at the schema level).
SELECT n.nspname AS schema, proname,
       has_schema_privilege('blackboxdb_readonly_role', n.nspname, 'USAGE') AS readonly_role_has_exec,
       has_schema_privilege('blackboxdb_readwrite_role', n.nspname, 'USAGE') AS readwrite_role_has_exec,
       has_schema_privilege('blackboxdb_admin_role', n.nspname, 'USAGE') AS admin_role_has_exec,
       has_schema_privilege('blackboxdb_api_find_role', n.nspname, 'USAGE') AS find_role_has_exec,
       has_schema_privilege('blackboxdb_api_insert_role', n.nspname, 'USAGE') AS insert_role_has_exec,
       has_schema_privilege('blackboxdb_api_update_role', n.nspname, 'USAGE') AS update_role_has_exec,
       has_schema_privilege('blackboxdb_api_remove_role', n.nspname, 'USAGE') AS remove_role_has_exec
FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'blackboxdb_api_internal_readonly' ORDER BY n.nspname, proname;

SELECT n.nspname AS schema, proname,
       has_schema_privilege('blackboxdb_readonly_role', n.nspname, 'USAGE') AS readonly_role_has_exec,
       has_schema_privilege('blackboxdb_readwrite_role', n.nspname, 'USAGE') AS readwrite_role_has_exec,
       has_schema_privilege('blackboxdb_admin_role', n.nspname, 'USAGE') AS admin_role_has_exec,
       has_schema_privilege('blackboxdb_api_find_role', n.nspname, 'USAGE') AS find_role_has_exec,
       has_schema_privilege('blackboxdb_api_insert_role', n.nspname, 'USAGE') AS insert_role_has_exec,
       has_schema_privilege('blackboxdb_api_update_role', n.nspname, 'USAGE') AS update_role_has_exec,
       has_schema_privilege('blackboxdb_api_remove_role', n.nspname, 'USAGE') AS remove_role_has_exec
FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'blackboxdb_api_internal_readwrite' ORDER BY n.nspname, proname;

SELECT n.nspname AS schema, proname,
       has_schema_privilege('blackboxdb_readonly_role', n.nspname, 'USAGE') AS readonly_role_has_exec,
       has_schema_privilege('blackboxdb_readwrite_role', n.nspname, 'USAGE') AS readwrite_role_has_exec,
       has_schema_privilege('blackboxdb_admin_role', n.nspname, 'USAGE') AS admin_role_has_exec,
       has_schema_privilege('blackboxdb_api_find_role', n.nspname, 'USAGE') AS find_role_has_exec,
       has_schema_privilege('blackboxdb_api_insert_role', n.nspname, 'USAGE') AS insert_role_has_exec,
       has_schema_privilege('blackboxdb_api_update_role', n.nspname, 'USAGE') AS update_role_has_exec,
       has_schema_privilege('blackboxdb_api_remove_role', n.nspname, 'USAGE') AS remove_role_has_exec
FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'blackboxdb_api_internal_admin' ORDER BY n.nspname, proname;

SELECT n.nspname AS schema, proname,
       has_schema_privilege('blackboxdb_readonly_role', n.nspname, 'USAGE') AS readonly_role_has_exec,
       has_schema_privilege('blackboxdb_readwrite_role', n.nspname, 'USAGE') AS readwrite_role_has_exec,
       has_schema_privilege('blackboxdb_admin_role', n.nspname, 'USAGE') AS admin_role_has_exec,
       has_schema_privilege('blackboxdb_api_find_role', n.nspname, 'USAGE') AS find_role_has_exec,
       has_schema_privilege('blackboxdb_api_insert_role', n.nspname, 'USAGE') AS insert_role_has_exec,
       has_schema_privilege('blackboxdb_api_update_role', n.nspname, 'USAGE') AS update_role_has_exec,
       has_schema_privilege('blackboxdb_api_remove_role', n.nspname, 'USAGE') AS remove_role_has_exec
FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'blackboxdb_api_internal_bgworker' ORDER BY n.nspname, proname;
