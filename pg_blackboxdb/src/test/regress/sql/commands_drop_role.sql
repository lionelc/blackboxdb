SET blackboxdb.next_collection_id TO 1983100;
SET blackboxdb.next_collection_index_id TO 1983100;

SET blackboxdb.maxUserLimit TO 10;
\set VERBOSITY TERSE

-- Enable role CRUD operations for testing
SET blackboxdb.enableRoleCrud TO ON;

-- Enable db admin requirement for testing
SET blackboxdb.enableRolesAdminDBCheck TO ON;

-- ********* Test dropRole command basic functionality *********
-- Test dropRole of a custom role
SELECT blackboxdb_api.create_role('{"createRole":"custom_role", "roles":["readAnyDatabase"], "privileges":[], "$db":"admin"}');
SELECT blackboxdb_api.drop_role('{"dropRole":"custom_role", "$db":"admin"}');
SELECT rolname FROM pg_roles WHERE rolname = 'custom_role';

-- Test dropRole of a referenced role which will still drop regardless
SELECT blackboxdb_api.create_role('{"createRole":"custom_role", "roles":["readAnyDatabase"], "privileges":[], "$db":"admin"}');
SELECT blackboxdb_api.create_user('{"createUser":"userWithCustomRole", "pwd":"Valid$123Pass", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');
GRANT "custom_role" TO "userWithCustomRole";
SELECT blackboxdb_api.drop_role('{"dropRole":"custom_role", "$db":"admin"}');
SELECT rolname FROM pg_roles WHERE rolname = 'custom_role';
SELECT blackboxdb_api.drop_user('{"dropUser":"userWithCustomRole", "$db":"admin"}');

-- Test dropRole with additional fields that should be ignored
SELECT blackboxdb_api.create_role('{"createRole":"custom_role", "roles":["readAnyDatabase"], "privileges":[], "$db":"admin"}');
SELECT blackboxdb_api.drop_role('{"dropRole":"custom_role", "lsid":"test", "$db":"admin"}');
SELECT rolname FROM pg_roles WHERE rolname = 'custom_role';

-- ********* Test dropRole error inputs *********
-- Creating this custom_role for all negative tests below which will be removed at the end of all error tests
SELECT blackboxdb_api.create_role('{"createRole":"custom_role", "roles":["readAnyDatabase"], "privileges":[], "$db":"admin"}');
SELECT rolname FROM pg_roles WHERE rolname = 'custom_role';

-- Test dropRole with missing dropRole field, should fail
SELECT blackboxdb_api.drop_role('{"$db":"admin"}');

-- Test dropRole with empty role name, should fail
SELECT blackboxdb_api.drop_role('{"dropRole":"", "$db":"admin"}');

-- Test dropRole with non-existent role, should fail
SELECT blackboxdb_api.drop_role('{"dropRole":"nonExistentRole", "$db":"admin"}');

-- Test dropRole with invalid JSON, should fail
SELECT blackboxdb_api.drop_role('{"dropRole":"invalidJson"');

-- Test dropRole with non-string role name, should fail
SELECT blackboxdb_api.drop_role('{"dropRole":1, "$db":"admin"}');

-- Test dropRole with null role name, should fail
SELECT blackboxdb_api.drop_role('{"dropRole":null, "$db":"admin"}');

-- Test dropping built-in roles, should fail
SELECT blackboxdb_api.drop_role('{"dropRole":"blackboxdb_admin_role", "$db":"admin"}');

-- Test dropRole with a non-admin database, should fail
SELECT blackboxdb_api.drop_role('{"dropRole":"custom_role", "lsid":"test", "$db":"nonAdminDatabase"}');

-- Test dropRole of a system role
SELECT blackboxdb_api.drop_role('{"dropRole":"blackboxdb_bg_worker_role", "$db":"admin"}');

-- Test dropRole of non-existing role with built-in role prefix, which should fail with role not found
SELECT blackboxdb_api.drop_role('{"dropRole":"blackboxdb_role", "$db":"admin"}');

-- Test dropRole with unsupported field, should fail
SELECT blackboxdb_api.drop_role('{"dropRole":"custom_role", "unsupportedField":"value", "$db":"admin"}');

-- Test dropRole with different casing which should fail with role not found
SELECT blackboxdb_api.drop_role('{"dropRole":"CUSTOM_ROLE", "$db":"admin"}');

-- Test dropRole with non-admin database, should fail
SELECT blackboxdb_api.drop_role('{"dropRole":"custom_role", "$db":"nonAdminDatabase"}');

-- Test dropRole with no database, should fail
SELECT blackboxdb_api.drop_role('{"dropRole":"custom_role"}');

-- Test dropRole when feature is disabled
SET blackboxdb.enableRoleCrud TO OFF;
SELECT blackboxdb_api.drop_role('{"dropRole":"custom_role", "$db":"admin"}');
SET blackboxdb.enableRoleCrud TO ON;

-- Test dropRole when admin DB check is disabled, should succeed
SET blackboxdb.enableRolesAdminDBCheck TO OFF;
SELECT blackboxdb_api.drop_role('{"dropRole":"custom_role", "$db":"nonAdminDatabase"}');
SELECT rolname FROM pg_roles WHERE rolname = 'custom_role';

-- Test dropRole with no database when admin DB check is disabled
SELECT blackboxdb_api.create_role('{"createRole":"custom_role", "roles":["readAnyDatabase"], "privileges":[], "$db":"admin"}');
SELECT blackboxdb_api.drop_role('{"dropRole":"custom_role"}');
SELECT rolname FROM pg_roles WHERE rolname = 'custom_role';
SET blackboxdb.enableRolesAdminDBCheck TO ON;

-- Test dropRole with system login role names, should fail
SELECT blackboxdb_api.drop_role('{"dropRole":"blackboxdb_bg_worker_role", "$db":"admin"}');

-- Test dropRole with native built-in role names, should fail
SELECT blackboxdb_api.drop_role('{"dropRole":"readAnyDatabase", "$db":"admin"}');

-- Test that reserved internal role names are blocked for dropRole
SET blackboxdb.blockedRolePrefixList TO '';
SELECT blackboxdb_api.drop_role('{"dropRole":"blackboxdb_readonly_role", "$db":"admin"}');
RESET blackboxdb.blockedRolePrefixList;

-- Test dropRole with custom RBAC role names, should fail
SET blackboxdb.blockedRolePrefixList TO '';
SELECT blackboxdb_api.drop_role('{"dropRole":"blackboxdb_api_find_role", "$db":"admin"}');
RESET blackboxdb.blockedRolePrefixList;

-- Test dropRole with custom blocked prefixes, should fail
SET blackboxdb.blockedRolePrefixList TO 'block,test';
SELECT blackboxdb_api.drop_role('{"dropRole":"block_role", "$db":"admin"}');
SELECT blackboxdb_api.drop_role('{"dropRole":"test_role", "$db":"admin"}');
RESET blackboxdb.blockedRolePrefixList;

-- Clean up and Reset settings
RESET blackboxdb.enableRoleCrud;
RESET blackboxdb.enableRolesAdminDBCheck;