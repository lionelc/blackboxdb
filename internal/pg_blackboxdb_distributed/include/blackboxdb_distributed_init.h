/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * include/blackboxdb_distributed_init.h
 *
 * The implementation for shard colocation for blackboxdb with citus.
 *
 *-------------------------------------------------------------------------
 */
#ifndef BLACKBOXDB_DISTRIBUTED_INIT_H
#define BLACKBOXDB_DISTRIBUTED_INIT_H

void InitBlackboxDBDistributedConfigurations(const char *prefix);
void BlackboxDBDistributed_InstallBsonMemVTablesLocal(void);

#endif
