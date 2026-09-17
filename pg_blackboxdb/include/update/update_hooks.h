/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * include/update/update_hooks.h
 *
 * Hook definitions for update tracking in change streams.
 * These hooks allow the hosting extension layer to provide
 * implementations for tracking field-level changes during
 * document updates.
 *
 *-------------------------------------------------------------------------
 */

#ifndef UPDATE_HOOKS_H
#define UPDATE_HOOKS_H

#include "api_hooks_common.h"

/*
 * Hook for creating an update tracker if tracking is enabled.
 */
typedef BsonUpdateTracker *(*CreateBsonUpdateTracker_HookType)(BsonUpdateSource *);
extern CreateBsonUpdateTracker_HookType create_update_tracker_hook;

typedef pgbson *(*BuildUpdateDescription_HookType)(BsonUpdateTracker *,
												   CommandUpdateType);
extern BuildUpdateDescription_HookType build_update_description_hook;

/* Update tracker method hooks */
typedef void (*NotifyRemovedField_HookType)(BsonUpdateTracker *tracker, const
											char *relativePath);
extern NotifyRemovedField_HookType notify_remove_field_hook;

typedef void (*NotifyUpdatedField_HookType)(BsonUpdateTracker *tracker, const
											char *relativePath,
											const bson_value_t *value);
extern NotifyUpdatedField_HookType notify_updated_field_hook;

typedef void (*StartPositionalUpdate_HookType)(BsonUpdateTracker *tracker,
											   uint32 positionalType,
											   bool isRootNode,
											   const StringView *relativePath,
											   const StringView *pathFromRoot);
extern StartPositionalUpdate_HookType start_positional_update_hook;

typedef void (*NotifyPositionalMatchIndex_HookType)(BsonUpdateTracker *tracker,
													const StringView *matchedIndex);
extern NotifyPositionalMatchIndex_HookType notify_positional_match_index_hook;

typedef void (*RemoveLastMatchedIndex_HookType)(BsonUpdateTracker *tracker);
extern RemoveLastMatchedIndex_HookType remove_last_matched_index_hook;

typedef void (*EndPositionalUpdate_HookType)(BsonUpdateTracker *tracker,
											 const bson_value_t *value);
extern EndPositionalUpdate_HookType end_positional_update_hook;

#endif
