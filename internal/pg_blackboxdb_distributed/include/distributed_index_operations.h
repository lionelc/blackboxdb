/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * include/distributed_index_operations.h
 *
 * The implementation for distributed index operations.
 *
 *-------------------------------------------------------------------------
 */
#ifndef BLACKBOXDB_DISTRIBUTED_INDEX_OPS_H
#define BLACKBOXDB_DISTRIBUTED_INDEX_OPS_H

void UpdateDistributedPostgresIndex(uint64_t collectionId, int indexId, int operation,
									bool value);

#endif
