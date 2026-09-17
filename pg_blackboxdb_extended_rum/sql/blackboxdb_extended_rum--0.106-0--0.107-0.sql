
ALTER OPERATOR FAMILY blackboxdb_extended_rum_catalog.bson_extended_rum_composite_path_ops USING blackboxdb_extended_rum ADD OPERATOR 34 blackboxdb_api_internal.<>-|(blackboxdb_core.bson, blackboxdb_core.bson) FOR ORDER BY blackboxdb_core.bson_btree_ops;
ALTER OPERATOR FAMILY blackboxdb_extended_rum_catalog.bson_extended_rum_composite_path_ops USING blackboxdb_extended_rum ADD FUNCTION 9 (blackboxdb_core.bson)blackboxdb_api_internal.bson_index_transform(bytea, bytea, int2, internal);


CREATE OPERATOR CLASS blackboxdb_extended_rum_catalog.bson_extended_rum_unique_shard_path_ops
    FOR TYPE blackboxdb_core.bson using blackboxdb_extended_rum AS
        OPERATOR        1       blackboxdb_api_internal.=#= (blackboxdb_core.bson, blackboxdb_core.bson),
        FUNCTION 1 uuid_cmp(uuid,uuid),
        FUNCTION 2 blackboxdb_api_internal.gin_bson_unique_shard_extract_value(blackboxdb_core.bson, internal),
        FUNCTION 3 blackboxdb_api_internal.gin_bson_unique_shard_extract_query(blackboxdb_core.bson, internal, int2, internal, internal, internal, internal),
        FUNCTION 4 blackboxdb_api_internal.gin_bson_unique_shard_consistent(internal, int2, anyelement, int4, internal, internal),
        FUNCTION 7 (blackboxdb_core.bson) blackboxdb_api_internal.gin_bson_unique_shard_pre_consistent(internal,smallint,blackboxdb_core.bson,int,internal,internal,internal,internal),
    STORAGE uuid;