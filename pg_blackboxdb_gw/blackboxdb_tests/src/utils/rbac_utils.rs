/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * blackboxdb_tests/src/utils/rbac_utils.rs
 *
 *-------------------------------------------------------------------------
 */

/// Used in role and user CRUD tests to verify these names are rejected.
pub const RESERVED_ROLE_NAMES: &[&str] = &[
    "blackboxdb_admin_role",
    "blackboxdb_api_find_role",
    "blackboxdb_api_insert_role",
    "blackboxdb_api_remove_role",
    "blackboxdb_api_update_role",
    "blackboxdb_bg_worker_role",
    "blackboxdb_cluster_admin_role",
    "blackboxdb_readonly_role",
    "blackboxdb_readwrite_role",
    "blackboxdb_root_role",
    "blackboxdb_user_admin_role",
];

/// Used in role CRUD tests to verify these names cannot be used for custom roles.
pub const NATIVE_BUILTIN_ROLE_NAMES: &[&str] = &[
    "__system",
    "autoCompact",
    "backup",
    "backupAndRestore",
    "clusterAdmin",
    "clusterManager",
    "clusterMonitor",
    "dbAdmin",
    "dbAdminAnyDatabase",
    "dbOwner",
    "directShardOperations",
    "enableSharding",
    "killOpSession",
    "manageShardBalancer",
    "MongodbAutomationAgentUserRole",
    "read",
    "readAnyDatabase",
    "readWrite",
    "readWriteAnyDatabase",
    "restore",
    "root",
    "searchCoordinator",
    "userAdmin",
    "userAdminAnyDatabase",
];
