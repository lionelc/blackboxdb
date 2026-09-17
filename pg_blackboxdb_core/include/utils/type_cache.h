/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * utils/type_cache.h
 *
 * Common declarations for metadata caching functions.
 *
 *-------------------------------------------------------------------------
 */

#ifndef TYPE_CACHE_H
#define TYPE_CACHE_H

extern PGDLLIMPORT char *CoreSchemaName;
extern PGDLLIMPORT char *CoreSchemaNameV2;

/* types */
PGDLLEXPORT Oid BsonTypeId(void);
PGDLLEXPORT Oid BsonQueryTypeId(void);
PGDLLEXPORT Oid BlackboxDBCoreBsonTypeId(void);
PGDLLEXPORT Oid BlackboxDBCoreBsonSequenceTypeId(void);

#endif
