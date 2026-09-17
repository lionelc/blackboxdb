/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * include/node_distributed_operations.h
 *
 * The implementation for node level distributed operations.
 *
 *-------------------------------------------------------------------------
 */
#ifndef BLACKBOXDB_NODE_DISTRIBUTED_OPS_H
#define BLACKBOXDB_NODE_DISTRIBUTED_OPS_H

List * ExecutePerNodeCommand(Oid nodeFunction, pgbson *nodeFunctionArg, bool readOnly,
							 const char *distributedTableName,
							 bool backFillCoordinator);

#endif
