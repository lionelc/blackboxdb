SET blackboxdb.next_collection_id TO 1972800;
SET blackboxdb.next_collection_index_id TO 1972800;

SET blackboxdb.maxUserLimit TO 10;
\set VERBOSITY TERSE

show blackboxdb.blockedRolePrefixList;

SET blackboxdb.blockedRolePrefixList TO '';
SELECT blackboxdb_api.create_user('{"createUser":"blackboxdb_unblocked", "pwd":"test_password", "roles":[{"role":"readWriteAnyDatabase","db":"admin"}, {"role":"clusterAdmin","db":"admin"}], "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"blackboxdb_unblocked", "$db":"admin"}');
SET blackboxdb.blockedRolePrefixList TO 'blackboxdb';
SELECT blackboxdb_api.drop_user('{"dropUser":"blackboxdb_unblocked", "$db":"admin"}');

SET blackboxdb.blockedRolePrefixList TO 'newBlock, newBlock2';
SELECT blackboxdb_api.create_user('{"createUser":"newBlock_user", "pwd":"test_password", "roles":[{"role":"readWriteAnyDatabase","db":"admin"}, {"role":"clusterAdmin","db":"admin"}], "$db":"admin"}');
SELECT blackboxdb_api.create_user('{"createUser":"newBlock2_user", "pwd":"test_password", "roles":[{"role":"readWriteAnyDatabase","db":"admin"}, {"role":"clusterAdmin","db":"admin"}], "$db":"admin"}');

RESET blackboxdb.blockedRolePrefixList;

--Enable DB admin requirement feature flag
SET blackboxdb.enableUsersAdminDBCheck TO ON;

-- Test user APIs with non-admin database - all should fail
-- Test create_user with non-admin database
SELECT blackboxdb_api.create_user('{"createUser":"test_user", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"nonAdminDatabase"}');

-- Test users_info with non-admin database
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user", "$db":"nonAdminDatabase"}');

-- Test update_user with non-admin database
SELECT blackboxdb_api.update_user('{"updateUser":"test_user", "pwd":"new_password", "$db":"nonAdminDatabase"}');

-- Test drop_user with non-admin database
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user", "$db":"nonAdminDatabase"}');

-- Test user APIs with no database parameter - all should fail
-- Test create_user with no database parameter
SELECT blackboxdb_api.create_user('{"createUser":"test_user", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}]}');

-- Test users_info with no database parameter
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user"}');

-- Test update_user with no database parameter
SELECT blackboxdb_api.update_user('{"updateUser":"test_user", "pwd":"new_password"}');

-- Test drop_user with no database parameter
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user"}');

-- Test user APIs with admin check disabled - all should succeed
SET blackboxdb.enableUsersAdminDBCheck TO OFF;

-- Test create_user with non-admin database
SELECT blackboxdb_api.create_user('{"createUser":"test_user", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"nonAdminDatabase"}');

-- Verify that the user is created
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user", "$db":"admin"}');

-- Test update_user with non-admin database
SELECT blackboxdb_api.update_user('{"updateUser":"test_user", "pwd":"new_password", "$db":"nonAdminDatabase"}');

-- Test drop_user with non-admin database
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user", "$db":"nonAdminDatabase"}');

-- Verify that the user is dropped
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user", "$db":"admin"}');

-- Test user APIs with no $db parameter when admin check is disabled - all should succeed
-- Test create_user with no database parameter
SELECT blackboxdb_api.create_user('{"createUser":"test_user_no_db", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}]}');

-- Test users_info with no database parameter
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user_no_db"}');

-- Test update_user with no database parameter
SELECT blackboxdb_api.update_user('{"updateUser":"test_user_no_db", "pwd":"Updated$123Pass"}');

-- Test drop_user with no database parameter
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user_no_db"}');

-- Verify that the user is dropped
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user_no_db", "$db":"admin"}');

-- Re-enable admin DB check
SET blackboxdb.enableUsersAdminDBCheck TO ON;      

--Create a readOnly user
SELECT blackboxdb_api.create_user('{"createUser":"test_user", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');

--Verify that the user is created
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user", "$db":"admin"}');

--Create an admin user
SELECT blackboxdb_api.create_user('{"createUser":"test_user2", "pwd":"test_password", "roles":[{"role":"readWriteAnyDatabase","db":"admin"}, {"role":"clusterAdmin","db":"admin"}], "$db":"admin"}');

--Verify that the user is created
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user2", "$db":"admin"}');

--Try to create a readOnly user without passing in the role as  part of an array
SELECT blackboxdb_api.create_user('{"createUser":"test_user", "pwd":"Valid$123Pass", "roles":{"role":"readAnyDatabase","db":"admin"}, "$db":"admin"}');

--Create a user with a blocked prefix
SELECT blackboxdb_api.create_user('{"createUser":"blackboxdb_user2", "pwd":"test_password", "roles":[{"role":"readWriteAnyDatabase","db":"admin"}, {"role":"clusterAdmin","db":"admin"}], "$db":"admin"}');

--Create an already existing user
SELECT blackboxdb_api.create_user('{"createUser":"test_user2", "pwd":"test_password", "roles":[{"role":"readWriteAnyDatabase","db":"admin"}, {"role":"clusterAdmin","db":"admin"}], "$db":"admin"}');

--Create a user with no role
SELECT blackboxdb_api.create_user('{"createUser":"test_user4", "pwd":"test_password", "roles":[], "$db":"admin"}');

--Create a user without specifying role parameter
SELECT blackboxdb_api.create_user('{"createUser":"test_user4", "pwd":"test_password", "$db":"admin"}');

--Create a user with a disallowed parameter
SELECT blackboxdb_api.create_user('{"createUser":"test_user", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "testParam":"This is a test", "$db":"admin"}');

--Create a user with a disallowed DB
SELECT blackboxdb_api.create_user('{"createUser":"test_user4", "pwd":"test_password", "roles":[{"role":"readWriteAnyDatabase","db":"Test"}, {"role":"clusterAdmin","db":"admin"}], "$db":"admin"}');

--Create a user with a disallowed role
SELECT blackboxdb_api.create_user('{"createUser":"test_user4", "pwd":"test_password", "roles":[{"role":"read","db":"admin"}, {"role":"clusterAdmin","db":"admin"}], "$db":"admin"}');

--Create a user with no DB
SELECT blackboxdb_api.create_user('{"createUser":"test_user4", "pwd":"test_password", "roles":[{"role":"readWriteAnyDatabase"}, {"role":"clusterAdmin"}], "$db":"admin"}');

-- Create a user with an empty password should fail
SELECT blackboxdb_api.create_user('{"createUser":"test_user_empty_pwd", "pwd":"", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');

-- Create a user with password less than 8 characters and drop it
SELECT blackboxdb_api.create_user('{"createUser":"test_user_short_pwd", "pwd":"Short1!", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user_short_pwd", "$db":"admin"}');

-- Create a user with password more than 256 characters and drop it
SELECT blackboxdb_api.create_user('{"createUser":"test_user_long_pwd", "pwd":"ThisIsAVeryLongPasswordThatExceedsTheTwoHundredFiftySixCharacterLimitAndThereforeShouldFailValidation1!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user_long_pwd", "$db":"admin"}');

--Verify that the user is created
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user4", "$db":"admin"}');

--Create a user with no DB in just one role
SELECT blackboxdb_api.create_user('{"createUser":"test_user5", "pwd":"test_password", "roles":[{"role":"readWriteAnyDatabase"}, {"role":"clusterAdmin","db":"admin"}], "$db":"admin"}');

--Verify that the user is created
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user5", "$db":"admin"}');

--Create a user with no parameters at all
SELECT blackboxdb_api.create_user('{"$db":"admin"}');

--Get all users
SELECT blackboxdb_api.users_info('{"usersInfo":1, "$db":"admin"}');

--Test SQL injection attack
SELECT blackboxdb_api.create_user('{"createUser":"test_user_injection_attack", "pwd":"; DROP TABLE users; --", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');

--Verify that the user is created
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user_injection_attack", "$db":"admin"}');

--Get all users
SELECT blackboxdb_api.users_info('{"usersInfo":1, "$db":"admin"}');

--Drop a user
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user5", "$db":"admin"}');

--Verify successful drop
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user5", "$db":"admin"}');

--Drop a reserved user, should fail
SELECT blackboxdb_api.drop_user('{"dropUser":"blackboxdb_user", "$db":"admin"}');

--Drop non-existent user
SELECT blackboxdb_api.drop_user('{"dropUser":"nonexistent_user", "$db":"admin"}');

--Drop a system user
SELECT blackboxdb_api.drop_user('{"dropUser":"blackboxdb_bg_worker_role", "$db":"admin"}');

--Drop a built-in user
SELECT blackboxdb_api.drop_user('{"dropUser":"blackboxdb_admin_role", "$db":"admin"}');

--Drop with disallowed parameter
SELECT blackboxdb_api.drop_user('{"user":"test_user", "$db":"admin"}');

--Update a user
SELECT blackboxdb_api.update_user('{"updateUser":"test_user", "pwd":"new_password", "$db":"admin"}');

--Update non existent user
SELECT blackboxdb_api.update_user('{"updateUser":"nonexistent_user", "pwd":"new_password", "$db":"admin"}');

--Update with disllowed parameter
SELECT blackboxdb_api.update_user('{"updateUser":"test_user", "pwd":"new_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');

--Get non existent user
SELECT blackboxdb_api.users_info('{"usersInfo":"nonexistent_user", "$db":"admin"}');

--Create a readOnly user
SELECT blackboxdb_api.create_user('{"createUser":"readOnlyUser", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');

--Create an admin user
SELECT blackboxdb_api.create_user('{"createUser":"adminUser", "pwd":"test_password", "roles":[{"role":"readWriteAnyDatabase","db":"admin"}, {"role":"clusterAdmin","db":"admin"}], "$db":"admin"}');

--Verify that we error out for external identity provider
SELECT blackboxdb_api.create_user('{"createUser":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "roles":[{"role":"readWriteAnyDatabase","db":"admin"}, {"role":"clusterAdmin","db":"admin"}], "customData":{"IdentityProvider" : {"type" : "ExternalProvider", "properties": {"principalType": "servicePrincipal"}}}, "$db":"admin"}');

SELECT current_user as original_user \gset

-- Call usersInfo with showPrivileges set to true
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user", "showPrivileges":true, "$db":"admin"}');
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user", "showPrivileges":false, "$db":"admin"}');
SELECT blackboxdb_api.users_info('{"usersInfo":"adminUser", "showPrivileges":true, "$db":"admin"}');
SELECT blackboxdb_api.users_info('{"usersInfo":"adminUser", "showPrivileges":false, "$db":"admin"}');

-- Test usersInfo command with usersInfo set to 1 and showPrivileges set to true, should fail
SELECT blackboxdb_api.users_info('{"usersInfo":1, "showPrivileges":true, "$db":"admin"}');

-- Test usersInfo command with enableUserInfoPrivileges set to false
SET blackboxdb.enableUsersInfoPrivileges TO OFF;
SELECT blackboxdb_api.users_info('{"usersInfo":"test_user", "showPrivileges":true, "$db":"admin"}');
SELECT blackboxdb_api.users_info('{"usersInfo":"adminUser", "showPrivileges":true, "$db":"admin"}');
RESET blackboxdb.enableUsersInfoPrivileges;

-- switch to read only user
\c - readOnlyUser

--Create without privileges
SELECT blackboxdb_api.create_user('{"createUser":"newUser", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');

--Drop without privileges
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user", "$db":"admin"}');

-- switch to admin user
\c - adminUser

-- Test connectionStatus command without showPrivileges parameter
SELECT blackboxdb_api.connection_status('{"connectionStatus": 1, "$db":"admin"}');

-- Test connectionStatus command with showPrivileges set to true/false
SELECT blackboxdb_api.connection_status('{"connectionStatus": 1, "showPrivileges":true, "$db":"admin"}');
SELECT blackboxdb_api.connection_status('{"connectionStatus": 1, "showPrivileges":false, "$db":"admin"}');

-- Test connectionStatus command with no parameters, should fail
SELECT blackboxdb_api.connection_status();

-- Test connectionStatus command with non-int value
SELECT blackboxdb_api.connection_status('{"connectionStatus": "1", "$db":"admin"}');

-- Test connectionStatus command with non-1 value
SELECT blackboxdb_api.connection_status('{"connectionStatus": 0, "$db":"admin"}');

-- Test connectionStatus command with no $db parameter, should fail
SELECT blackboxdb_api.connection_status('{"connectionStatus": 1}');

SET blackboxdb.enableUsersAdminDBCheck TO OFF;

-- Test connectionStatus command with no $db parameter, should succeed
SELECT blackboxdb_api.connection_status('{"connectionStatus": 1}');

SET blackboxdb.enableUsersAdminDBCheck TO ON;

--Create without privileges
SELECT blackboxdb_api.create_user('{"createUser":"newUser", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');

--Drop without privileges
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user", "$db":"admin"}');

--set Feature flag for user crud OFF
SET blackboxdb.enableUserCrud TO OFF;

--All user crud commnads should fail
SELECT blackboxdb_api.create_user('{"createUser":"test_user", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');
SELECT blackboxdb_api.users_info('{"usersInfo":1, "$db":"admin"}');
SELECT blackboxdb_api.update_user('{"updateUser":"test_user", "pwd":"new_password", "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user5", "$db":"admin"}');

-- switch back to original user
\c - :original_user

--set Feature flag for user crud
SET blackboxdb.enableUserCrud TO ON;
\set VERBOSITY TERSE
 
 --set max user limit to 11
SET blackboxdb.maxUserLimit TO 11;

-- Keep creating users till we have 11 users
SELECT blackboxdb_api.create_user('{"createUser":"newUser7", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');
SELECT blackboxdb_api.create_user('{"createUser":"newUser8", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');
SELECT blackboxdb_api.create_user('{"createUser":"newUser9", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');
SELECT blackboxdb_api.create_user('{"createUser":"newUser10", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');
SELECT blackboxdb_api.create_user('{"createUser":"newUser11", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');

-- This call should fail since we're only allowed to create 11 users
SELECT blackboxdb_api.create_user('{"createUser":"newUser12", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');

-- Increase allowed users to 12
SET blackboxdb.maxUserLimit TO 12;

-- This should now succeed
SELECT blackboxdb_api.create_user('{"createUser":"newUser12", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');

-- This should fail
SELECT blackboxdb_api.create_user('{"createUser":"newUser13", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');

-- Delete a user and try to create again, this should succeed
SELECT blackboxdb_api.drop_user('{"dropUser":"newUser7", "$db":"admin"}');
SELECT blackboxdb_api.create_user('{"createUser":"newUser13", "pwd":"test_password", "roles":[{"role":"readAnyDatabase","db":"admin"}], "$db":"admin"}');

-- Delete all users created so we don't break other tests that also create users
SELECT blackboxdb_api.drop_user('{"dropUser":"newUser8", "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"newUser9", "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"newUser10", "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"newUser11", "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"newUser12", "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"newUser13", "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user", "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user2", "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user4", "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"test_user_injection_attack", "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"readOnlyUser", "$db":"admin"}');
SELECT blackboxdb_api.drop_user('{"dropUser":"adminUser", "$db":"admin"}');

-- Reset the max user limit to 500
SET blackboxdb.maxUserLimit TO 500;

-- Reset the feature flag for db admin requirement
RESET blackboxdb.enableUsersAdminDBCheck;

-- Unit test for IS_BUILTIN_ROLE, IS_CUSTOM_RBAC_ROLE, IS_SYSTEM_LOGIN_ROLE, and IS_NATIVE_BUILTIN_ROLE macros
CREATE OR REPLACE FUNCTION blackboxdb_test_helpers.test_is_reserved_role_name(text)
RETURNS bool
LANGUAGE C AS 'pg_blackboxdb', $$test_is_reserved_internal_role_name$$;

-- IS_BUILTIN_ROLE: all builtin roles should be reserved
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('blackboxdb_admin_role');
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('blackboxdb_cluster_admin_role');
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('blackboxdb_readonly_role');
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('blackboxdb_readwrite_role');
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('blackboxdb_root_role');
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('blackboxdb_user_admin_role');

-- IS_CUSTOM_RBAC_ROLE: all custom RBAC roles should be reserved
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('blackboxdb_api_find_role');
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('blackboxdb_api_insert_role');
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('blackboxdb_api_remove_role');
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('blackboxdb_api_update_role');

-- IS_SYSTEM_LOGIN_ROLE: system login roles should be reserved
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('blackboxdb_bg_worker_role');

-- Negative cases: normal usernames should NOT be reserved
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('normal_user');
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('admin');
SELECT blackboxdb_test_helpers.test_is_reserved_role_name('blackboxdb_some_other_thing');

-- dropUser with IS_BUILTIN_ROLE name
SELECT blackboxdb_api.drop_user('{"dropUser":"blackboxdb_readonly_role", "$db":"admin"}');
-- updateUser with IS_BUILTIN_ROLE name
SELECT blackboxdb_api.update_user('{"updateUser":"blackboxdb_readonly_role", "pwd":"New$123Pass", "$db":"admin"}');
-- usersInfo with a reserved name should still work (read-only, no blocking)
SELECT blackboxdb_api.users_info('{"usersInfo":"blackboxdb_readonly_role", "$db":"admin"}');

DROP FUNCTION blackboxdb_test_helpers.test_is_reserved_role_name(text);