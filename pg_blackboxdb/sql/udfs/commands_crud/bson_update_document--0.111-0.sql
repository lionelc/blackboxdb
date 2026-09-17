/* Command: update */

-- The bson_update_document is a legacy UDF which is going to deprecated soon in favor of new update_bson_document UDF.
DROP FUNCTION IF EXISTS __API_SCHEMA_INTERNAL__.bson_update_document;
CREATE OR REPLACE FUNCTION __API_SCHEMA_INTERNAL__.bson_update_document(
    document __CORE_SCHEMA__.bson,
    updateSpec __CORE_SCHEMA__.bson,
    querySpec __CORE_SCHEMA__.bson,
    arrayFilters __CORE_SCHEMA__.bson DEFAULT NULL,
    buildUpdateDesc bool DEFAULT false,
    variableSpec __CORE_SCHEMA__.bson DEFAULT NULL,
    OUT newDocument __CORE_SCHEMA__.bson,
    OUT updateDesc __CORE_SCHEMA__.bson)
 RETURNS RECORD
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS 'MODULE_PATHNAME', $function$bson_update_document$function$;


-- Base overload of update_bson_document without update tracking params.
-- Used by callers that do not pass physical row identifiers (ctid/tableOid).
CREATE OR REPLACE FUNCTION __API_SCHEMA_INTERNAL_V2__.update_bson_document(
    document __CORE_SCHEMA__.bson,
    updateSpec __CORE_SCHEMA__.bson,
    querySpec __CORE_SCHEMA__.bson,
    arrayFilters __CORE_SCHEMA__.bson,
    variableSpec __CORE_SCHEMA__.bson,
    collationString text,
    OUT newDocument __CORE_SCHEMA__.bson)
 RETURNS __CORE_SCHEMA__.bson
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS 'MODULE_PATHNAME', $function$bson_update_document$function$;


-- Extended overload of update_bson_document with sourceCTID and sourceTableOid
-- for identification of documents getting updated at the physical storage level.
-- Used for change stream update description tracking.
CREATE OR REPLACE FUNCTION __API_SCHEMA_INTERNAL_V2__.update_bson_document(
    document __CORE_SCHEMA__.bson,
    updateSpec __CORE_SCHEMA__.bson,
    querySpec __CORE_SCHEMA__.bson,
    arrayFilters __CORE_SCHEMA__.bson,
    variableSpec __CORE_SCHEMA__.bson,
    collationString text,
    sourceCTID tid,
    sourceTableOid oid,
    OUT newDocument __CORE_SCHEMA__.bson)
 RETURNS __CORE_SCHEMA__.bson
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS 'MODULE_PATHNAME', $function$bson_update_document$function$;
