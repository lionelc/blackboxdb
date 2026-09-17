SET blackboxdb.next_collection_id TO 1983000;
SET blackboxdb.next_collection_index_id TO 1983000;

SET blackboxdb.maxUserLimit TO 10;
\set VERBOSITY TERSE

-- Enable role CRUD operations for testing
SET blackboxdb.enableRoleCrud TO ON;

-- Enable db admin requirement for testing
SET blackboxdb.enableRolesAdminDBCheck TO ON;

-- Create a custom role for testing rolesInfo with a custom role
SELECT blackboxdb_api.create_role('{"createRole":"test_custom_role", "roles":["readAnyDatabase"], "privileges":[], "$db":"admin"}');

-- ********* Test rolesInfo with int value *********
-- Test rolesInfo with 1
SELECT blackboxdb_api.roles_info('{"rolesInfo":1, "$db":"admin"}');

-- Test rolesInfo with int value other than 1, which is not allowed
SELECT blackboxdb_api.roles_info('{"rolesInfo":0, "$db":"admin"}');

-- Test rolesInfo with showPrivileges
SELECT blackboxdb_api.roles_info('{"rolesInfo":1, "showPrivileges":true, "$db":"admin"}');

-- Test rolesInfo with invalid showPrivileges type
SELECT blackboxdb_api.roles_info('{"rolesInfo":1, "showPrivileges":1, "$db":"admin"}');

-- Test rolesInfo with showBuiltInRoles
SELECT blackboxdb_api.roles_info('{"rolesInfo":1, "showBuiltInRoles":true, "$db":"admin"}');

-- Test rolesInfo with showBuiltInRoles and showPrivileges
SELECT blackboxdb_api.roles_info('{"rolesInfo":1, "showBuiltInRoles":true, "showPrivileges":true, "$db":"admin"}');

-- Test rolesInfo with invalid showBuiltInRoles type
SELECT blackboxdb_api.roles_info('{"rolesInfo":1, "showBuiltInRoles":1, "$db":"admin"}');

-- Test rolesInfo with unsupported field at root level
SELECT blackboxdb_api.roles_info('{"rolesInfo":1, "unsupportedField":"value", "$db":"admin"}');

-- Test rolesInfo with ignorable field at root level
SELECT blackboxdb_api.roles_info('{"rolesInfo":1, "lsid":"value", "$db":"admin"}');

-- Test rolesInfo with missing mandatory rolesInfo field
SELECT blackboxdb_api.roles_info('{"$db":"admin"}');

-- Test rolesInfo with null value
SELECT blackboxdb_api.roles_info('{"rolesInfo":null, "$db":"admin"}');

-- ********* Test rolesInfo with string value *********
-- Test rolesInfo with string value of built-in role
-- which also doesn't require showBuiltInRoles since it's only an addon flag for rolesInfo:1
SELECT blackboxdb_api.roles_info('{"rolesInfo":"clusterAdmin", "showPrivileges":true, "$db":"admin"}');
SELECT blackboxdb_api.roles_info('{"rolesInfo":"readWriteAnyDatabase", "showPrivileges":true, "$db":"admin"}');

-- Test rolesInfo with string value of custom role
SELECT blackboxdb_api.roles_info('{"rolesInfo":"test_custom_role", "showPrivileges":true, "$db":"admin"}');

-- Test rolesInfo with string value of not-exist role
SELECT blackboxdb_api.roles_info('{"rolesInfo":"not_exist_role", "$db":"admin"}');

-- Test rolesInfo with empty string value, which is the same as specifying a not-exist role
SELECT blackboxdb_api.roles_info('{"rolesInfo":"", "$db":"admin"}');

-- Test rolesInfo with a Postgres role with oid < FirstNormalObjectId, which is not allowed
SELECT blackboxdb_api.roles_info('{"rolesInfo":"pg_signal_backend", "$db":"admin"}');

-- Test a user role with oid >= FirstNormalObjectId. Create a user then try to fetch it
SELECT blackboxdb_api.create_user('{"createUser":"test_user", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');
SELECT blackboxdb_api.roles_info('{"rolesInfo":"test_user", "$db":"admin"}');

-- ********* Test rolesInfo with role document *********
-- Test rolesInfo with basic role document
SELECT blackboxdb_api.roles_info('{"rolesInfo": {"role":"readAnyDatabase", "db":"admin"}, "$db":"admin"}');

-- Test rolesInfo with bson document with empty role or db
SELECT blackboxdb_api.roles_info('{"rolesInfo": {"role":"", "db":""}, "$db":"admin"}');

-- Test rolesInfo with bson document with miss db which is not allowed
SELECT blackboxdb_api.roles_info('{"rolesInfo": {"role":"readAnyDatabase"}, "$db":"admin"}');

-- Test rolesInfo with bson document with miss role which is not allowed
SELECT blackboxdb_api.roles_info('{"rolesInfo": {"db":"admin"}, "$db":"admin"}');

-- Test rolesInfo with bson document of invalid role field type
SELECT blackboxdb_api.roles_info('{"rolesInfo":{"role":1, "db":"admin"}, "$db":"admin"}');

-- Test rolesInfo with bson document of invalid role field type
SELECT blackboxdb_api.roles_info('{"rolesInfo":{"role":"readAnyDatabase", "db":1}, "$db":"admin"}');

-- Test rolesInfo with bson document with unknown field, which is not allowed
SELECT blackboxdb_api.roles_info('{"rolesInfo":{"role":"readAnyDatabase", "db":"admin", "unknownField":"value"}, "$db":"admin"}');

-- Test rolesInfo with non-admin database, should fail
SELECT blackboxdb_api.roles_info('{"rolesInfo":{"role":"readAnyDatabase", "db":"admin"}, "$db":"nonAdminDatabase"}');

-- Test rolesInfo with no database, should fail
SELECT blackboxdb_api.roles_info('{"rolesInfo":{"role":"readAnyDatabase", "db":"admin"}}');

-- ********* Test rolesInfo with array *********
-- Test rolesInfo with empty array
SELECT blackboxdb_api.roles_info('{"rolesInfo":[], "$db":"admin"}');

-- Test rolesInfo with array of role names, including empty string
SELECT blackboxdb_api.roles_info('{"rolesInfo":["readAnyDatabase", "test_custom_role", "not_exist_role", ""], "$db":"admin"}');

-- Test rolesInfo with array of mixed bson document and string
SELECT blackboxdb_api.roles_info('{"rolesInfo":[{"role":"readAnyDatabase", "db":"admin"}, "test_custom_role"], "$db":"admin"}');

-- Test rolesInfo for multiple built-in roles
SELECT blackboxdb_api.roles_info('{"rolesInfo":["readAnyDatabase", "clusterAdmin"], "showBuiltInRoles":true, "$db":"admin"}');

-- Test rolesInfo when feature is disabled
SET blackboxdb.enableRoleCrud TO OFF;
SELECT blackboxdb_api.roles_info('{"rolesInfo":1, "$db":"admin"}');
SET blackboxdb.enableRoleCrud TO ON;

-- Test rolesInfo with non-admin database when admin DB check is disabled, should succeed
SET blackboxdb.enableRolesAdminDBCheck TO OFF;
SELECT blackboxdb_api.roles_info('{"rolesInfo":1, "$db":"nonAdminDatabase"}');

-- Test rolesInfo with no database when admin DB check is disabled
SELECT blackboxdb_api.roles_info('{"rolesInfo":1}');
SET blackboxdb.enableRolesAdminDBCheck TO ON;

-- Clean up test roles created for rolesInfo testing
DROP ROLE IF EXISTS "test_custom_role";

-- Reset settings
RESET blackboxdb.enableRoleCrud;
RESET blackboxdb.enableRolesAdminDBCheck;
