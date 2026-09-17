setup
{
    SELECT blackboxdb_api.create_collection('ren_db', 'ren1');
}

teardown
{
	SELECT blackboxdb_api.drop_collection('ren_db', 'ren1');
    SELECT blackboxdb_api.drop_collection('ren_db', 'ren2');
}

session "s1"

step "s1-insert"
{
    SELECT COUNT(blackboxdb_api.insert_one('ren_db', 'ren1', blackboxdb_core.bson_build_document('_id', i, 'a', i))) FROM generate_series(1, 100) i;
}


step "s1-rename-collection"
{
    SELECT blackboxdb_api.rename_collection('ren_db', 'ren1', 'ren2');
}

session "s2"

step "s2-count"
{
    SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('ren_db',
        blackboxdb_core.bson_build_document('aggregate', 'ren1'::text, 'pipeline', ARRAY[blackboxdb_core.bson_build_document('$count', 'n'::text)]));
    
    SELECT document FROM blackboxdb_api_catalog.bson_aggregation_pipeline('ren_db',
        blackboxdb_core.bson_build_document('aggregate', 'ren2'::text, 'pipeline', ARRAY[blackboxdb_core.bson_build_document('$count', 'n'::text)]));
}

permutation "s1-insert" "s2-count" "s1-rename-collection" "s2-count"