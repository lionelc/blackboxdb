#!/bin/bash

set -eu

WORKSPACE_DIR="${1:?workspace directory is required}"
shift || true

cd "$WORKSPACE_DIR"

NEXTEST_JUNIT_OUTPUT="$WORKSPACE_DIR/target/nextest/ci/junit.xml"
TEST_RESULTS_OUTPUT="$WORKSPACE_DIR/target/test-results/junit.xml"

if command -v cargo-nextest >/dev/null 2>&1; then
  NEXTEST_STATUS=0
  cargo nextest run --workspace --no-fail-fast --test-threads=1 --profile ci "$@" || NEXTEST_STATUS=$?

  if [ -f "$NEXTEST_JUNIT_OUTPUT" ]; then
    mkdir -p "$(dirname "$TEST_RESULTS_OUTPUT")"
    cp "$NEXTEST_JUNIT_OUTPUT" "$TEST_RESULTS_OUTPUT"
    echo "JUnit report written to $TEST_RESULTS_OUTPUT"
  else
    echo "JUnit report not found at $NEXTEST_JUNIT_OUTPUT"
  fi

  exit "$NEXTEST_STATUS"
else
  echo "cargo-nextest not found; running cargo test without JUnit output"
  cargo test --workspace -- --test-threads=1
fi
