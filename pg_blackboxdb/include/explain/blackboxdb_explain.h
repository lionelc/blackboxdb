/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * include/explain/blackboxdb_explain.h
 *
 * Common declarations for explain functionality in blackboxdb.
 *
 *-------------------------------------------------------------------------
 */

#ifndef BLACKBOXDB_EXPLAIN_H
#define BLACKBOXDB_EXPLAIN_H

#include "io/bson_core.h"

typedef bool (*BlackboxDBExplainStageHook)(pgbson_writer *writer, QueryDesc *queryDesc,
										   PlanState *planState,
										   void (*stageWriteFunc)(pgbson_writer *, const
																  char *,
																  QueryDesc *,
																  PlanState *));

extern BlackboxDBExplainStageHook explain_stage_hook;
#endif
