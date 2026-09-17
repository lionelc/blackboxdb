/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * blackboxdb_tests/tests/ssl_tests.rs
 *
 *-------------------------------------------------------------------------
 */

use blackboxdb_tests::{commands::constant, test_setup::initialize};
use mongodb::error::Error;

#[tokio::test]
async fn ssl_connection() -> Result<(), Error> {
    let client = initialize::initialize().await?;

    constant::validate_connectivity(&client).await
}
