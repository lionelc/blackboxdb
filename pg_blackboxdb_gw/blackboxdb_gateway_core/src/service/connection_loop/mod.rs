/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * blackboxdb_gateway_core/src/service/connection_loop/mod.rs
 *
 *-------------------------------------------------------------------------
 */

//! Per-connection request loop with read-ahead and request lifecycle handling.

mod error_reply;
mod read_ahead;
mod request_execution;
mod request_pipeline;
mod stream_driver;

pub use stream_driver::handle_stream;
