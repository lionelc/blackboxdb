/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * blackboxdb_tests/tests/unauthenticated_tests.rs
 *
 *-------------------------------------------------------------------------
 */

use blackboxdb_tests::{
    commands::constant,
    test_setup::{clients, initialize},
};
use mongodb::error::Error;

#[tokio::test]
async fn is_master() -> Result<(), Error> {
    let _ = initialize::initialize().await?;

    let client = clients::get_client_unauthenticated()?;

    constant::validate_is_master_unauthenticated(&client).await
}
