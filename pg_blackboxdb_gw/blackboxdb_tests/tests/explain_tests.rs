/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * blackboxdb_tests/tests/explain_tests.rs
 *
 *-------------------------------------------------------------------------
 */

use blackboxdb_tests::{commands::explain, test_setup::initialize};
use mongodb::error::Error;

#[tokio::test]
async fn explain() -> Result<(), Error> {
    let db = initialize::initialize_with_db("explain").await?;

    explain::validate_explain(&db).await
}
