/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * blackboxdb_gateway_core/src/postgres/mod.rs
 *
 *-------------------------------------------------------------------------
 */

pub mod conn_mgmt;
mod data_client;
pub(crate) mod document;
mod blackboxdb_data_client;
mod query_catalog;
mod scoped_transaction;
mod transaction;

pub use data_client::PgDataClient;
pub use document::PgDocument;
pub use blackboxdb_data_client::{remap_error, BlackboxDBDataClient};
pub use query_catalog::{create_query_catalog, QueryCatalog};
pub use scoped_transaction::ScopedTransaction;
pub use transaction::Transaction;
