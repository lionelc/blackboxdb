/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * src/function_stubs.c
 *
 * Function stubs for renamed/deprecated C functions.
 * When renaming/removing C functions, old extension upgrade scripts will cease to work.
 * In order to maintain compatibility, we add stubs of the renamed/deprecated functions
 * and map from the old to the new functions here.
 *-------------------------------------------------------------------------
 */

#include <postgres.h>
#include <fmgr.h>


PG_FUNCTION_INFO_V1(delete_expired_rows_for_index);
Datum
delete_expired_rows_for_index(PG_FUNCTION_ARGS)
{
	ereport(ERROR, errmsg(
				"delete_expired_rows_for_index is deprecated and should not be called."));
}
