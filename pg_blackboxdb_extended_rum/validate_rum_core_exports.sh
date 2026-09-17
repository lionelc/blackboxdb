#!/bin/bash

leftLib=$1
rightLib=$2

echo "Validating exports in $leftLib and $rightLib"

# These symbols must be exported by leftLib (the core lib)

expectedPublicExports=(
    BlackboxDBRumInitPublic
)

expectedExports=(
    BlackboxDBRumOrderedCostEstimate
    blackboxdb_rum_get_current_index_key
    blackboxdb_rum_get_multi_key_status
    blackboxdb_rum_parallel_build_main
    blackboxdb_rum_skip_tids_on_current_entry
    blackboxdb_rum_update_multi_key_status
    try_explain_blackboxdb_rum_index
)

expectedPgExports=(
    blackboxdb_rum_get_meta_page_info
    blackboxdb_rum_page_get_data_items
    blackboxdb_rum_page_get_entries
    blackboxdb_rum_page_get_stats
    blackboxdb_rum_prune_empty_entries_on_index
    blackboxdb_rum_repair_incomplete_split_on_index
    blackboxdb_rum_repair_revive_all_pages_and_tuples
    blackboxdb_rumhandler
)



# Extract globally visible (T/D/B) symbol names from each .so, excluding standard PG extension symbols
leftExports=$(nm -D --defined-only "$leftLib" 2>/dev/null | awk '$2 ~ /^[TDB]$/ {print $3}' | grep -vxE '_PG_init|Pg_magic_func' | sort)
rightExports=$(nm -D --defined-only "$rightLib" 2>/dev/null | awk '$2 ~ /^[TDB]$/ {print $3}' | grep -vxE '_PG_init|Pg_magic_func' | sort)

failed=0

# Assert all expected symbols are exported by leftLib
for sym in "${expectedExports[@]}"; do
    if ! echo "$leftExports" | grep -qxF "$sym"; then
        echo "ERROR: expected symbol '$sym' not found in $leftLib"
        failed=1
    fi
done

for sym in "${expectedPublicExports[@]}"; do
    if ! echo "$leftExports" | grep -qxF "$sym"; then
        echo "ERROR: expected symbol '$sym' not found in $leftLib"
        failed=1
    fi
done

for sym in "${expectedPgExports[@]}"; do
    if ! echo "$leftExports" | grep -qxF "$sym"; then
        echo "ERROR: expected symbol '$sym' not found in $leftLib"
        failed=1
    fi
    if ! echo "$leftExports" | grep -qxF "pg_finfo_${sym}"; then
        echo "ERROR: expected symbol 'pg_finfo_${sym}' not found in $leftLib"
        failed=1
    fi
done

echo "Done checking exports in $leftLib"

# Assert rightLib does not export any of the expected symbols
for sym in "${expectedExports[@]}"; do
    if ! echo "$rightExports" | grep -qxF "builtin_rmgr_${sym}"; then
        echo "ERROR: expected symbol '$sym' not found in $rightLib"
        failed=1
    fi
done

for sym in "${expectedPgExports[@]}"; do
    if ! echo "$rightExports" | grep -qxF "builtin_rmgr_${sym}"; then
        echo "ERROR: expected symbol '$sym' not found in $rightLib"
        failed=1
    fi
    if ! echo "$rightExports" | grep -qxF "pg_finfo_builtin_rmgr_${sym}"; then
        echo "ERROR: expected symbol 'pg_finfo_builtin_rmgr_${sym}' not found in $rightLib"
        failed=1
    fi
done

echo "Done checking exports in $rightLib"

# Fail if any exports are common between leftLib and rightLib
duplicates=$(comm -12 <(echo "$leftExports") <(echo "$rightExports"))
if [ -n "$duplicates" ]; then
    count=$(echo "$duplicates" | wc -l)
    echo "ERROR: $count duplicate export(s) between $leftLib and $rightLib:"
    echo "$duplicates"
    failed=1
fi

# Assert that files under core/src/infra do not include pg_blackboxdb_rum.h
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/core/src/infra"
if [ -d "$INFRA_DIR" ]; then
    violations=$(grep -rn '#include.*pg_blackboxdb_rum\.h' "$INFRA_DIR" 2>/dev/null)
    if [ -n "$violations" ]; then
        echo "ERROR: core/src/infra must not include pg_blackboxdb_rum.h:"
        echo "$violations"
        failed=1
    fi
fi

if [ "$failed" -ne 0 ]; then
    exit 1
fi

echo "Export validation passed. All ${#expectedExports[@]} and ${#expectedPgExports[@]} expected symbols present in $leftLib and absent from $rightLib."