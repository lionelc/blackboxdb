/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 * SPDX-License-Identifier: MIT
 *-------------------------------------------------------------------------
 */

SET search_path TO blackboxdb_api, blackboxdb_core, blackboxdb_api_catalog;
SET blackboxdb.next_collection_id TO 8900000;
SET blackboxdb.next_collection_index_id TO 8900000;

SELECT blackboxdb_api.create_collection('full_scan_selectivity_db', 'planner_rows');

SELECT COUNT(blackboxdb_api.insert_one(
    'full_scan_selectivity_db',
    'planner_rows',
    bson_build_document('_id', value, 'value', value)))
FROM generate_series(1, 90) AS value;

ANALYZE blackboxdb_data.documents_8900001;

CREATE SCHEMA bson_full_scan_selectivity_tests;

CREATE FUNCTION bson_full_scan_selectivity_tests.get_find_plan_rows()
RETURNS TABLE(estimated_rows bigint, analyzed_rows bigint, estimates_match boolean)
LANGUAGE plpgsql AS $fn$
DECLARE
    explain_plan jsonb;
BEGIN
    EXECUTE $query$
        EXPLAIN (FORMAT JSON)
        SELECT document
        FROM blackboxdb_api_catalog.bson_aggregation_find(
            'full_scan_selectivity_db',
            '{ "find": "planner_rows", "projection": { "value": 1, "_id": 0 }, "sort": { "value": 1 } }')
    $query$
    INTO explain_plan;

    RETURN QUERY
    WITH RECURSIVE plan_nodes(node) AS
    (
        SELECT explain_plan->0->'Plan'
        UNION ALL
        SELECT child
        FROM plan_nodes
        CROSS JOIN LATERAL jsonb_array_elements(
            COALESCE(plan_nodes.node->'Plans', '[]'::jsonb)) AS child
    ),
    row_estimates AS
    (
        SELECT (node->>'Plan Rows')::bigint AS estimated_rows
        FROM plan_nodes
        WHERE node->>'Relation Name' = 'documents_8900001'
    ),
    analyzed_table AS
    (
        SELECT reltuples::bigint AS analyzed_rows
        FROM pg_catalog.pg_class
        WHERE oid = 'blackboxdb_data.documents_8900001'::regclass
    )
    SELECT row_estimates.estimated_rows,
           analyzed_table.analyzed_rows,
           row_estimates.estimated_rows = analyzed_table.analyzed_rows
    FROM row_estimates
    CROSS JOIN analyzed_table;
END;
$fn$;

-- A filterless find with projection and sort must retain the analyzed base-table
-- row estimate. The full-scan support function previously applied PostgreSQL's
-- default one-third function selectivity, reducing this estimate from 90 to 30.
SHOW blackboxdb.enable_full_scan_cost_and_selectivity;
SELECT * FROM bson_full_scan_selectivity_tests.get_find_plan_rows();

SET blackboxdb.enable_full_scan_cost_and_selectivity TO off;
SELECT * FROM bson_full_scan_selectivity_tests.get_find_plan_rows();
RESET blackboxdb.enable_full_scan_cost_and_selectivity;

SELECT blackboxdb_api.drop_collection('full_scan_selectivity_db', 'planner_rows');
DROP SCHEMA bson_full_scan_selectivity_tests CASCADE;
