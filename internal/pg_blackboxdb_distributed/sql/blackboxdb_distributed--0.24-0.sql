CREATE SCHEMA blackboxdb_api_distributed;
GRANT USAGE ON SCHEMA blackboxdb_api_distributed TO __API_ADMIN_ROLE__;
GRANT USAGE ON SCHEMA blackboxdb_api_distributed TO __API_READONLY_ROLE__;
CREATE TABLE blackboxdb_api_distributed.blackboxdb_cluster_data
(
    metadata __CORE_SCHEMA__.bson
);
-- seed the table with a baseline version.
INSERT INTO blackboxdb_api_distributed.blackboxdb_cluster_data (metadata) VALUES ( '{ "last_deploy_version": "0.0-0" }'::__CORE_SCHEMA__.bson );

#include "udfs/clustermgmt/cluster_operations--0.21-0.sql"
#include "udfs/clustermgmt/cluster_version_utils--0.21-0.sql"

ALTER TABLE blackboxdb_api_distributed.blackboxdb_cluster_data ADD PRIMARY KEY (metadata);

#include "udfs/rebalancer/rebalancer_operations--0.24-0.sql"
