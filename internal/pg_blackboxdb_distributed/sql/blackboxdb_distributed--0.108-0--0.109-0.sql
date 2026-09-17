-- version checks need this for secondary users
GRANT ALL ON TABLE blackboxdb_api_distributed.blackboxdb_cluster_data TO __API_ADMIN_ROLE__;
GRANT SELECT ON TABLE blackboxdb_api_distributed.blackboxdb_cluster_data TO __API_READONLY_ROLE__;

#include "udfs/operations/move_collection--0.109-0.sql"