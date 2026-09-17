/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * include/distributed_hooks.h
 *
 * The implementation for shard colocation for BlackboxDB with citus.
 *
 *-------------------------------------------------------------------------
 */
#ifndef BLACKBOXDB_DISTRIBUTED_HOOKS_H
#define BLACKBOXDB_DISTRIBUTED_HOOKS_H

void InitializeBlackboxDBDistributedHooks(void);
void RegisterDistributedExplainStageHook(void);

#endif
