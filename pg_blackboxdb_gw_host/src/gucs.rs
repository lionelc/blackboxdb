use pgrx::{ffi::CString, GucContext, GucFlags, GucRegistry, GucSetting};

pub static PG_BLACKBOXDB_GATEWAY_DATABASE: GucSetting<Option<CString>> =
    GucSetting::<Option<CString>>::new(None);

pub static PG_BLACKBOXDB_SETUP_CONFIGURATION: GucSetting<Option<CString>> =
    GucSetting::<Option<CString>>::new(None);

pub fn init() {
    GucRegistry::define_string_guc(
        c"blackboxdb_gateway.database",
        c"The database that the pg_blackboxdb_gateway BGWorker will connect to",
        c"This should be the database that you ran `CREATE EXTENSION pg_blackboxdb_gateway` in",
        &PG_BLACKBOXDB_GATEWAY_DATABASE,
        GucContext::Postmaster,
        GucFlags::SUPERUSER_ONLY,
    );
    GucRegistry::define_string_guc(
        c"blackboxdb_gateway.setup_configuration_file",
        c"The setup configuration file for the pg_blackboxdb_gateway BGWorker",
        c"This should be the path to the setup configuration file",
        &PG_BLACKBOXDB_SETUP_CONFIGURATION,
        GucContext::Postmaster,
        GucFlags::SUPERUSER_ONLY,
    );
}
