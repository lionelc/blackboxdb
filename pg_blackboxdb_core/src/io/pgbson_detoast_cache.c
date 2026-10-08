/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * src/io/pgbson_detoast_cache.c
 *
 * A small per-backend cache of detoasted documents that are stored out of
 * line (TOAST). Every operator call on a document detoasts its argument, so a
 * row whose document is used by several calls (a filter, a group key, an
 * accumulator argument, sort keys) otherwise fetches and reassembles the same
 * TOAST value several times. Entries are keyed by the TOAST pointer (toast
 * relation and value id) and are only reused within the statement that cached
 * them; the cache is also emptied at transaction end. Callers always receive
 * their own palloc'd copy, exactly as from a regular detoast, so they may free
 * or modify it.
 *
 * Storing a value costs one extra copy, which is wasted when a statement never
 * asks for the same document twice (for example a single detoast per row), so a
 * statement that sees no hit in its first DETOAST_CACHE_PROBE_MISSES misses stops
 * storing values until the next statement.
 *
 *-------------------------------------------------------------------------
 */
#include <postgres.h>
#include <access/detoast.h>
#include <access/xact.h>
#include <utils/memutils.h>
#include <utils/timestamp.h>

#include "io/bson_core.h"

/* Number of documents kept: enough for the documents of one joined row. */
#define DETOAST_CACHE_ENTRIES 4

/* Documents larger than this are not cached. */
#define DETOAST_CACHE_MAX_BYTES (1024 * 1024)

/* Misses without any hit after which a statement stops storing values. */
#define DETOAST_CACHE_PROBE_MISSES 64

typedef struct DetoastCacheEntry
{
	Oid toastRelId;
	Oid valueId;
	TimestampTz statementStart;
	uint64 lastUsed;
	Size size;
	struct varlena *value;      /* NULL when the slot is empty */
} DetoastCacheEntry;

static DetoastCacheEntry DetoastCache[DETOAST_CACHE_ENTRIES];
static MemoryContext DetoastCacheContext = NULL;
static uint64 DetoastCacheClock = 0;
static bool DetoastCacheCallbackRegistered = false;

/* Hit and miss counts of the current statement (adaptive bypass). */
static TimestampTz DetoastStatsStatement = 0;
static uint64 DetoastStatementHits = 0;
static uint64 DetoastStatementMisses = 0;

static void ResetDetoastCache(void);
static void DetoastCacheTransactionCallback(XactEvent event, void *arg);


/*
 * Returns a detoasted copy of an out-of-line (on disk) TOAST value, served from
 * the cache when the same value was detoasted earlier in the current statement.
 */
struct varlena *
PgbsonDetoastExternalCached(struct varlena *attr)
{
	struct varatt_external toastPointer;
	VARATT_EXTERNAL_GET_POINTER(toastPointer, attr);
	TimestampTz statementStart = GetCurrentStatementStartTimestamp();
	if (DetoastStatsStatement != statementStart)
	{
		DetoastStatsStatement = statementStart;
		DetoastStatementHits = 0;
		DetoastStatementMisses = 0;
	}

	DetoastCacheEntry *victim = &DetoastCache[0];
	for (int i = 0; i < DETOAST_CACHE_ENTRIES; i++)
	{
		DetoastCacheEntry *entry = &DetoastCache[i];
		if (entry->value != NULL &&
			entry->valueId == toastPointer.va_valueid &&
			entry->toastRelId == toastPointer.va_toastrelid &&
			entry->statementStart == statementStart)
		{
			entry->lastUsed = ++DetoastCacheClock;
			DetoastStatementHits++;
			struct varlena *copy = (struct varlena *) palloc(entry->size);
			memcpy(copy, entry->value, entry->size);
			return copy;
		}

		if (entry->value == NULL ||
			(victim->value != NULL && entry->lastUsed < victim->lastUsed))
		{
			victim = entry;
		}
	}

	struct varlena *result = detoast_attr(attr);
	DetoastStatementMisses++;

	/* No repeats so far in this statement: do not pay for storing the value */
	if (DetoastStatementHits == 0 && DetoastStatementMisses > DETOAST_CACHE_PROBE_MISSES)
	{
		return result;
	}

	Size size = VARSIZE_ANY(result);
	if (size > DETOAST_CACHE_MAX_BYTES)
	{
		return result;
	}

	if (DetoastCacheContext == NULL)
	{
		DetoastCacheContext = AllocSetContextCreate(TopMemoryContext,
													"BlackboxDB detoast cache",
													ALLOCSET_DEFAULT_SIZES);
	}

	if (!DetoastCacheCallbackRegistered)
	{
		RegisterXactCallback(DetoastCacheTransactionCallback, NULL);
		DetoastCacheCallbackRegistered = true;
	}

	/* Empty the slot first so that an error below never leaves a dangling entry */
	if (victim->value != NULL)
	{
		struct varlena *oldValue = victim->value;
		victim->value = NULL;
		pfree(oldValue);
	}

	struct varlena *cached = (struct varlena *) MemoryContextAlloc(DetoastCacheContext, size);
	memcpy(cached, result, size);

	victim->toastRelId = toastPointer.va_toastrelid;
	victim->valueId = toastPointer.va_valueid;
	victim->statementStart = statementStart;
	victim->lastUsed = ++DetoastCacheClock;
	victim->size = size;
	victim->value = cached;
	return result;
}


static void
ResetDetoastCache(void)
{
	for (int i = 0; i < DETOAST_CACHE_ENTRIES; i++)
	{
		DetoastCache[i].value = NULL;
	}

	if (DetoastCacheContext != NULL)
	{
		MemoryContextReset(DetoastCacheContext);
	}
}


/*
 * Empties the cache whenever a transaction ends (commit, abort or prepare), so
 * no detoasted value outlives the transaction that read it.
 */
static void
DetoastCacheTransactionCallback(XactEvent event, void *arg)
{
	switch (event)
	{
		case XACT_EVENT_COMMIT:
		case XACT_EVENT_PARALLEL_COMMIT:
		case XACT_EVENT_ABORT:
		case XACT_EVENT_PARALLEL_ABORT:
		case XACT_EVENT_PREPARE:
		{
			ResetDetoastCache();
			break;
		}

		default:
		{
			break;
		}
	}
}
