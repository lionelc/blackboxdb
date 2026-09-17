
CREATE OPERATOR __API_SCHEMA_INTERNAL_V2__.|<> (
    LEFTARG =  __CORE_SCHEMA__.bson,
    RIGHTARG = __CORE_SCHEMA__.bson,
    PROCEDURE = __API_SCHEMA_INTERNAL_V2__.bson_orderby_index
);

CREATE OPERATOR __API_SCHEMA_INTERNAL_V2__.<>| (
    LEFTARG =  __CORE_SCHEMA__.bson,
    RIGHTARG = __CORE_SCHEMA__.bson,
    PROCEDURE = __API_SCHEMA_INTERNAL_V2__.bson_orderby_index_reverse
);
