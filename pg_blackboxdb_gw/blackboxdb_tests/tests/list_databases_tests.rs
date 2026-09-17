/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * blackboxdb_tests/tests/list_databases_tests.rs
 *
 *-------------------------------------------------------------------------
 */

use blackboxdb_tests::{commands::list_databases, test_setup::initialize};

#[tokio::test]
async fn list_databases() -> Result<(), mongodb::error::Error> {
    let client = initialize::initialize().await?;

    list_databases::validate_list_databases(&client).await
}
