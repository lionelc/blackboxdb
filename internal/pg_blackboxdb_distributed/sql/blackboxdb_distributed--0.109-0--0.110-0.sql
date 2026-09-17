-- Admin role needs LOGIN privilege to run move collection functions
ALTER ROLE __API_ADMIN_ROLE__ WITH LOGIN;

GRANT SELECT ON TABLE blackboxdb_api_distributed.blackboxdb_cluster_data TO blackboxdb_readwrite_role;
GRANT USAGE ON SCHEMA blackboxdb_api_distributed TO blackboxdb_readwrite_role;

GRANT SELECT ON TABLE blackboxdb_api_distributed.blackboxdb_cluster_data TO blackboxdb_api_find_role;
GRANT SELECT ON TABLE blackboxdb_api_distributed.blackboxdb_cluster_data TO blackboxdb_api_insert_role;
GRANT SELECT ON TABLE blackboxdb_api_distributed.blackboxdb_cluster_data TO blackboxdb_api_update_role;
GRANT SELECT ON TABLE blackboxdb_api_distributed.blackboxdb_cluster_data TO blackboxdb_api_remove_role;
GRANT USAGE ON SCHEMA blackboxdb_api_distributed TO blackboxdb_api_find_role;
GRANT USAGE ON SCHEMA blackboxdb_api_distributed TO blackboxdb_api_insert_role;
GRANT USAGE ON SCHEMA blackboxdb_api_distributed TO blackboxdb_api_update_role;
GRANT USAGE ON SCHEMA blackboxdb_api_distributed TO blackboxdb_api_remove_role;
