/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * blackboxdb_tests/tests/rename_collection_tests.rs
 *
 *-------------------------------------------------------------------------
 */

use blackboxdb_tests::{commands::rename_collection, test_setup::initialize};
use mongodb::error::Error;

#[tokio::test]
async fn validate_rename_collection_basic() -> Result<(), Error> {
    let db = initialize::initialize_with_db("rename_tests_basic").await?;

    rename_collection::validate_rename_collection_basic(&db).await
}

#[tokio::test]
async fn validate_rename_collection_with_drop_target() -> Result<(), Error> {
    let db = initialize::initialize_with_db("rename_tests_drop_target").await?;

    rename_collection::validate_rename_collection_with_drop_target(&db).await
}

#[tokio::test]
async fn validate_rename_collection_cross_db_error() -> Result<(), Error> {
    let db = initialize::initialize_with_db("rename_tests_cross_db").await?;

    rename_collection::validate_rename_collection_cross_db_error(&db).await;
    Ok(())
}

#[tokio::test]
async fn validate_rename_collection_self_rename_error() -> Result<(), Error> {
    let db = initialize::initialize_with_db("rename_tests_self_rename").await?;

    rename_collection::validate_rename_collection_self_rename_error(&db).await;
    Ok(())
}

#[tokio::test]
async fn validate_rename_collection_not_found_error() -> Result<(), Error> {
    let db = initialize::initialize_with_db("rename_tests_not_found").await?;

    rename_collection::validate_rename_collection_not_found_error(&db).await;
    Ok(())
}

#[tokio::test]
async fn validate_rename_collection_unknown_field_error() -> Result<(), Error> {
    let db = initialize::initialize_with_db("rename_tests_unknown_field").await?;

    rename_collection::validate_rename_collection_unknown_field_error(&db).await;
    Ok(())
}
