/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * include/planner/blackboxdb_plan_cache.h
 *
 * Common declarations for the pg_blackboxdb plan cache.
 *
 *-------------------------------------------------------------------------
 */

#ifndef BLACKBOXDB_CURSOR_STORE_H
#define BLACKBOXDB_CURSOR_STORE_H
#include <postgres.h>

typedef struct CursorFileState CursorFileState;

void SetupCursorStorage(void);
void InitializeFileCursorShmem(void);
Size FileCursorShmemSize(void);

void DeletePendingCursorFiles(void);
void GetCurrentCursorCount(int32_t *currentCursorCount, int32_t *measuredCursorCount,
						   int64_t *lastCursorSize);
void DeleteCursorFile(const char *cursorName);
CursorFileState * CreateCursorFile(const char *cursorName,
								   bool useFileBasedCursors);
void WriteToCursorFile(CursorFileState *cursorFileState, pgbson *bson);
pgbson * ReadFromCursorFile(CursorFileState *cursorFileState);
bytea * CursorFileStateClose(CursorFileState *cursorFileState, MemoryContext
							 writerContext);

CursorFileState * DeserializeFileState(bytea *cursorFileState,
									   bool useFileBasedCursors);

#endif
