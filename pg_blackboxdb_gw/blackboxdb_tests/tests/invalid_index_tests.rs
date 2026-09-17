/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * blackboxdb_tests/tests/invalid_index_tests.rs
 *
 *-------------------------------------------------------------------------
 */

use blackboxdb_tests::{commands::indexing, test_setup::initialize};
use mongodb::error::Error;

#[tokio::test]
async fn test_index_key_too_large_error() -> Result<(), Error> {
    let db = initialize::initialize_with_db("test_index_key_db").await?;

    indexing::validate_index_key_too_large_error(&db).await
}
