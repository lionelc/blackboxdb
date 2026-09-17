#!/bin/bash
# Run BlackboxDB functional tests locally using the pinned upstream image.
#
# Modes:
#   allowlist  Run the required PR-gate allowlist and summarize gate results.
#   single     Run one pytest node ID. Pass the node ID positionally or with --test.
#   smoke      Run upstream smoke tests, excluding no_parallel tests.
#   full       Run the full upstream suite.
#   daily      Run the full upstream suite and summarize daily delta results.
#   bootstrap  Generate an allowlist candidate from tests that pass every run.
#
# Examples:
#   ./blackboxdb-local/functional-tests/scripts/run-functional-tests.sh allowlist
#   ./blackboxdb-local/functional-tests/scripts/run-functional-tests.sh single --test compatibility/tests/core/query-and-write/commands/find/test_find_basic_queries.py::test_find_all_documents
#   ./blackboxdb-local/functional-tests/scripts/run-functional-tests.sh allowlist --build-and-start-blackboxdb
#   ./blackboxdb-local/functional-tests/scripts/run-functional-tests.sh allowlist --use-existing-blackboxdb-image ghcr.io/anonymous/blackboxdb/blackboxdb-local:latest
#   ./blackboxdb-local/functional-tests/scripts/run-functional-tests.sh smoke --workers 4
#   ./blackboxdb-local/functional-tests/scripts/run-functional-tests.sh full --workers 4
#   ./blackboxdb-local/functional-tests/scripts/run-functional-tests.sh daily --workers 4
#   ./blackboxdb-local/functional-tests/scripts/run-functional-tests.sh bootstrap --runs 3 --output allowlist-candidate.yml
#
# Additional pytest arguments can be passed after --.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTIONAL_TESTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$FUNCTIONAL_TESTS_DIR/../.." && pwd)"

CONFIG_DIR="$FUNCTIONAL_TESTS_DIR/config"
IMAGE_YML="$CONFIG_DIR/image.yml"
ALLOWLIST_YML="$CONFIG_DIR/allowlist.yml"
PLUGIN="$FUNCTIONAL_TESTS_DIR/tools/conftest_allowlist.py"
GATE_TOOL="$FUNCTIONAL_TESTS_DIR/tools/functional_gate.py"

MODE="${1:-}"
CONNECTION_STRING_EXPLICIT=false
if [ -n "${CONNECTION_STRING+x}" ]; then
    CONNECTION_STRING_EXPLICIT=true
fi
ENGINE_NAME="${ENGINE_NAME:-blackboxdb}"
WORKERS=4
RESULTS_DIR=""
TEST_ID=""
RUNS=1
OUTPUT="allowlist-candidate.yml"
BUILD_BLACKBOXDB=false
START_BLACKBOXDB=false
PULL_BLACKBOXDB_IMAGE=false
KEEP_BLACKBOXDB=false
BLACKBOXDB_IMAGE="blackboxdb-local:functional-tests"
BLACKBOXDB_CONTAINER="blackboxdb-functional-tests"
BLACKBOXDB_PORT="${BLACKBOXDB_PORT:-10260}"
BLACKBOXDB_USER="${BLACKBOXDB_USER:-docdb_admin}"
BLACKBOXDB_PASSWORD="${BLACKBOXDB_PASSWORD:-Admin100}"
# Local-dev defaults only. Do not use these credentials for deployed environments;
# CI generates per-run credentials in .github/workflows/functional_tests.yml.
DEFAULT_CONNECTION_STRING="mongodb://${BLACKBOXDB_USER}:${BLACKBOXDB_PASSWORD}@host.docker.internal:${BLACKBOXDB_PORT}/?tls=true&tlsAllowInvalidCertificates=true"
CONNECTION_STRING="${CONNECTION_STRING:-$DEFAULT_CONNECTION_STRING}"
PG_VERSION="${PG_VERSION:-17}"
PACKAGE_OS="deb13"
BLACKBOXDB_BUILD_DIR="$REPO_ROOT/.test-results/functional-tests/blackboxdb-build"
BLACKBOXDB_BASE_IMAGE="debian:trixie-slim"
BLACKBOXDB_READY_TIMEOUT=180
MANAGED_BLACKBOXDB_STARTED=false
PYTEST_ARGS=()
PYTEST_ARGS_PRESENT=false

show_help() {
    cat <<EOF
Run BlackboxDB functional tests locally using the pinned upstream image.

Usage:
  $0 <mode> [options] [-- <pytest args>]

Modes:
  allowlist  Run the required PR-gate allowlist and summarize gate results.
  single     Run one pytest node ID. Pass the node ID positionally or with --test.
  smoke      Run upstream smoke tests, excluding no_parallel tests.
  full       Run the full upstream suite.
  daily      Run the full upstream suite and summarize daily delta results.
  bootstrap  Generate an allowlist candidate from tests that pass every run.

Examples:
  $0 allowlist
  $0 single compatibility/tests/core/query-and-write/commands/find/test_find_basic_queries.py::test_find_all_documents
  $0 single --test compatibility/tests/core/query-and-write/commands/find/test_find_basic_queries.py::test_find_all_documents
  $0 allowlist --build-and-start-blackboxdb
  $0 allowlist --use-existing-blackboxdb-image ghcr.io/anonymous/blackboxdb/blackboxdb-local:latest
  $0 smoke --workers 4
  $0 full --workers 4
  $0 daily --workers 4
  $0 bootstrap --runs 3 --output allowlist-candidate.yml

Options:
  --connection-string <url>  Override the BlackboxDB connection string, including
                             the managed container connection string.
  --engine-name <name>       Engine name passed to upstream pytest and the
                             allowlist plugin (default: blackboxdb).
  --workers <n>              Number of pytest-xdist workers (default: 4).
  --results-dir <path>       Output directory (default: .test-results/functional-tests/<mode>).
  --test <nodeid>            Pytest node ID for single mode.
  --runs <n>                 Number of bootstrap runs (default: 1).
  --output <path>            Bootstrap candidate output path (default: allowlist-candidate.yml).
  --build-blackboxdb         Build the local blackboxdb-local Docker image before running tests.
  --start-blackboxdb         Start blackboxdb-local, wait for readiness, then run tests.
  --build-and-start-blackboxdb
                             Build, start, wait, and run tests in one command.
  --use-existing-blackboxdb-image <image>
                             Start a prebuilt image ref without rebuilding; pulls if missing locally.
  --blackboxdb-image <image> Managed blackboxdb-local image ref for build/start (default: blackboxdb-local:functional-tests).
  --blackboxdb-container <name>
                             Managed container name (default: blackboxdb-functional-tests).
  --blackboxdb-port <port>   Managed BlackboxDB host port (default: 10260).
  --blackboxdb-user <user>   Managed BlackboxDB username (default: docdb_admin).
  --blackboxdb-password <pw> Managed BlackboxDB password (default: Admin100).
  --pg-version <ver>         PostgreSQL major version for local image builds (default: 17).
  --package-os <os>          Package OS for local image builds (default: deb13).
  --build-dir <path>         Repo-local build artifact directory.
  --base-image <image>       Base image for blackboxdb-local Docker build (default: debian:trixie-slim).
  --ready-timeout <seconds>  Startup readiness timeout (default: 180).
  --keep-blackboxdb          Leave the managed container running after tests.
  --help                     Show this help.
  -- <pytest args>           Extra arguments passed through to pytest.

Environment:
  CONNECTION_STRING          Alternative way to set the connection string.
                             Preserved when using managed BlackboxDB startup.
EOF
}

repo_relative_path() {
    python3 -c "import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$1" "$2"
}

redact_connection_string() {
    python3 - "$1" <<'PY'
import sys
from urllib.parse import urlsplit

try:
    parsed = urlsplit(sys.argv[1])
    scheme = parsed.scheme or "mongodb"
    host = parsed.hostname
    port = parsed.port
except ValueError:
    print("<redacted>")
    raise SystemExit(0)

if not host:
    print("<redacted>")
    raise SystemExit(0)

if ":" in host and not host.startswith("["):
    host = f"[{host}]"

port_suffix = f":{port}" if port is not None else ""
print(f"{scheme}://{host}{port_suffix}")
PY
}

cleanup_managed_blackboxdb() {
    local exit_code=$?

    if [ "$MANAGED_BLACKBOXDB_STARTED" = "true" ]; then
        echo ""
        echo "Collecting managed BlackboxDB logs:"
        echo "  $RESULTS_DIR/blackboxdb.log"
        docker logs "$BLACKBOXDB_CONTAINER" > "$RESULTS_DIR/blackboxdb.log" 2>&1 || true

        if [ "$KEEP_BLACKBOXDB" = "true" ]; then
            echo "Keeping managed BlackboxDB container running:"
            echo "  $BLACKBOXDB_CONTAINER"
        else
            echo "Stopping managed BlackboxDB container:"
            echo "  $BLACKBOXDB_CONTAINER"
            docker rm -f "$BLACKBOXDB_CONTAINER" >/dev/null 2>&1 || true
        fi
    fi

    exit "$exit_code"
}

build_blackboxdb_image() {
    case "$PACKAGE_OS" in
        deb*|ubuntu*) ;;
        *)
            echo "--package-os must produce a Debian package for Dockerfile_blackboxdb_local, got: $PACKAGE_OS"
            exit 1
            ;;
    esac

    mkdir -p "$BLACKBOXDB_BUILD_DIR"
    BLACKBOXDB_BUILD_DIR="$(cd "$BLACKBOXDB_BUILD_DIR" && pwd)"
    case "$BLACKBOXDB_BUILD_DIR/" in
        "$REPO_ROOT"/*) ;;
        *)
            echo "--build-dir must be inside the repository so Docker can copy the built package: $BLACKBOXDB_BUILD_DIR"
            exit 1
            ;;
    esac

    local build_dir_rel
    local packages_dir_rel
    local packages_dir
    local deb_file
    local deb_rel

    build_dir_rel="$(repo_relative_path "$BLACKBOXDB_BUILD_DIR" "$REPO_ROOT")"
    packages_dir_rel="$build_dir_rel/downloaded-artifacts"
    packages_dir="$REPO_ROOT/$packages_dir_rel"

    echo "Building blackboxdb-local package:"
    echo "  OS:        $PACKAGE_OS"
    echo "  PG:        $PG_VERSION"
    echo "  Output:    $packages_dir"
    rm -rf "$packages_dir"
    mkdir -p "$packages_dir"
    (
        cd "$REPO_ROOT"
        ./packaging/build_packages.sh --os "$PACKAGE_OS" --pg "$PG_VERSION" --output-dir "$packages_dir_rel"
    )

    deb_file="$(find "$packages_dir" -maxdepth 1 -type f -name '*.deb' ! -name '*dbgsym*' | sort | head -1)"
    if [ -z "$deb_file" ]; then
        echo "No non-dbgsym .deb package found in $packages_dir"
        exit 1
    fi
    deb_rel="$(repo_relative_path "$deb_file" "$REPO_ROOT")"

    echo "Building blackboxdb-local Docker image:"
    echo "  Image:     $BLACKBOXDB_IMAGE"
    echo "  Base:      $BLACKBOXDB_BASE_IMAGE"
    echo "  Package:   $deb_rel"
    (
        cd "$REPO_ROOT"
        docker build \
            --build-arg BASE_IMAGE="$BLACKBOXDB_BASE_IMAGE" \
            --build-arg POSTGRES_VERSION="$PG_VERSION" \
            --build-arg DEB_PACKAGE_REL_PATH="$deb_rel" \
            -t "$BLACKBOXDB_IMAGE" \
            -f packaging/gateway/docker/Dockerfile_blackboxdb_local .
    )
}

start_managed_blackboxdb() {
    if ! docker image inspect "$BLACKBOXDB_IMAGE" >/dev/null 2>&1; then
        if [ "$PULL_BLACKBOXDB_IMAGE" = "true" ]; then
            echo "BlackboxDB image not found locally; pulling:"
            echo "  $BLACKBOXDB_IMAGE"
            docker pull "$BLACKBOXDB_IMAGE"
        else
            echo "BlackboxDB image not found: $BLACKBOXDB_IMAGE"
            echo "Use --build-blackboxdb, --build-and-start-blackboxdb, or --use-existing-blackboxdb-image <image>."
            exit 1
        fi
    fi

    echo "Removing any existing managed BlackboxDB container:"
    echo "  $BLACKBOXDB_CONTAINER"
    docker rm -f "$BLACKBOXDB_CONTAINER" >/dev/null 2>&1 || true

    echo "Starting managed BlackboxDB container:"
    echo "  Container: $BLACKBOXDB_CONTAINER"
    echo "  Image:     $BLACKBOXDB_IMAGE"
    echo "  Host port: $BLACKBOXDB_PORT"
    docker run -d \
        --name "$BLACKBOXDB_CONTAINER" \
        -p "$BLACKBOXDB_PORT:10260" \
        "$BLACKBOXDB_IMAGE" \
        --username "$BLACKBOXDB_USER" \
        --password "$BLACKBOXDB_PASSWORD" \
        --skip-init-data \
        >/dev/null
    MANAGED_BLACKBOXDB_STARTED=true

    echo "Waiting for BlackboxDB readiness log (timeout: ${BLACKBOXDB_READY_TIMEOUT}s)..."
    local elapsed=0
    while ! docker logs "$BLACKBOXDB_CONTAINER" 2>&1 | grep -q "=== BlackboxDB is ready ==="; do
        if ! docker ps --format '{{.Names}}' | grep -Fx "$BLACKBOXDB_CONTAINER" >/dev/null; then
            echo "Managed BlackboxDB container exited before readiness."
            docker logs "$BLACKBOXDB_CONTAINER" 2>&1 || true
            exit 1
        fi
        if [ "$elapsed" -ge "$BLACKBOXDB_READY_TIMEOUT" ]; then
            echo "BlackboxDB did not become ready within ${BLACKBOXDB_READY_TIMEOUT}s."
            docker logs "$BLACKBOXDB_CONTAINER" 2>&1 || true
            exit 1
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    if [ "$CONNECTION_STRING_EXPLICIT" = "true" ]; then
        echo "Using user-provided BlackboxDB connection string."
    else
        CONNECTION_STRING="mongodb://${BLACKBOXDB_USER}:${BLACKBOXDB_PASSWORD}@127.0.0.1:${BLACKBOXDB_PORT}/?tls=true&tlsAllowInvalidCertificates=true"
    fi
    echo "Waiting for BlackboxDB host port ${BLACKBOXDB_PORT}..."
    elapsed=0
    while ! timeout 1 bash -c "</dev/tcp/127.0.0.1/${BLACKBOXDB_PORT}" >/dev/null 2>&1; do
        if [ "$elapsed" -ge "$BLACKBOXDB_READY_TIMEOUT" ]; then
            echo "BlackboxDB host port ${BLACKBOXDB_PORT} did not become reachable within ${BLACKBOXDB_READY_TIMEOUT}s."
            docker logs "$BLACKBOXDB_CONTAINER" 2>&1 || true
            exit 1
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    echo "Managed BlackboxDB is ready."
}

if [ -z "$MODE" ] || [ "$MODE" = "--help" ] || [ "$MODE" = "-h" ]; then
    show_help
    exit 0
fi

case "$MODE" in
    allowlist|single|smoke|full|daily|bootstrap) shift ;;
    *)
        echo "Unknown mode: $MODE"
        echo ""
        show_help
        exit 1
        ;;
esac

while [[ $# -gt 0 ]]; do
    case "$1" in
        --connection-string) CONNECTION_STRING="$2"; CONNECTION_STRING_EXPLICIT=true; shift 2 ;;
        --engine-name) ENGINE_NAME="$2"; shift 2 ;;
        --workers) WORKERS="$2"; shift 2 ;;
        --results-dir) RESULTS_DIR="$2"; shift 2 ;;
        --test) TEST_ID="$2"; shift 2 ;;
        --runs) RUNS="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --build-blackboxdb) BUILD_BLACKBOXDB=true; shift ;;
        --start-blackboxdb) START_BLACKBOXDB=true; shift ;;
        --build-and-start-blackboxdb) BUILD_BLACKBOXDB=true; START_BLACKBOXDB=true; shift ;;
        --use-existing-blackboxdb-image) BLACKBOXDB_IMAGE="$2"; BUILD_BLACKBOXDB=false; START_BLACKBOXDB=true; PULL_BLACKBOXDB_IMAGE=true; shift 2 ;;
        --blackboxdb-image) BLACKBOXDB_IMAGE="$2"; shift 2 ;;
        --blackboxdb-container) BLACKBOXDB_CONTAINER="$2"; shift 2 ;;
        --blackboxdb-port) BLACKBOXDB_PORT="$2"; shift 2 ;;
        --blackboxdb-user) BLACKBOXDB_USER="$2"; shift 2 ;;
        --blackboxdb-password) BLACKBOXDB_PASSWORD="$2"; shift 2 ;;
        --pg-version) PG_VERSION="$2"; shift 2 ;;
        --package-os) PACKAGE_OS="$2"; shift 2 ;;
        --build-dir) BLACKBOXDB_BUILD_DIR="$2"; shift 2 ;;
        --base-image) BLACKBOXDB_BASE_IMAGE="$2"; shift 2 ;;
        --ready-timeout) BLACKBOXDB_READY_TIMEOUT="$2"; shift 2 ;;
        --keep-blackboxdb) KEEP_BLACKBOXDB=true; shift ;;
        --help|-h)
            show_help
            exit 0
            ;;
        --)
            shift
            if [ "$#" -gt 0 ]; then
                PYTEST_ARGS_PRESENT=true
                PYTEST_ARGS+=("$@")
            fi
            break
            ;;
        *)
            if [ "$MODE" = "single" ] && [ -z "$TEST_ID" ]; then
                TEST_ID="$1"
                shift
            else
                echo "Unknown option: $1"
                echo ""
                show_help
                exit 1
            fi
            ;;
    esac
done

if [ ! -f "$IMAGE_YML" ]; then
    echo "Required file not found: $IMAGE_YML"
    exit 1
fi

if [[ "$MODE" == "allowlist" || "$MODE" == "daily" ]]; then
    for f in "$ALLOWLIST_YML" "$GATE_TOOL"; do
        if [ ! -f "$f" ]; then
            echo "Required file not found: $f"
            exit 1
        fi
    done
fi

if [ "$MODE" = "allowlist" ] && [ ! -f "$PLUGIN" ]; then
    echo "Required file not found: $PLUGIN"
    exit 1
fi

if [ "$MODE" = "single" ] && [ -z "$TEST_ID" ]; then
    echo "single mode requires --test <pytest-node-id>"
    exit 1
fi

if [ "$MODE" = "bootstrap" ] && ! [[ "$RUNS" =~ ^[1-9][0-9]*$ ]]; then
    echo "bootstrap --runs must be a positive integer"
    exit 1
fi

if ! [[ "$BLACKBOXDB_READY_TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
    echo "--ready-timeout must be a positive integer"
    exit 1
fi

if ! [[ "$BLACKBOXDB_PORT" =~ ^[1-9][0-9]*$ ]]; then
    echo "--blackboxdb-port must be a positive integer"
    exit 1
fi

if ! command -v docker &>/dev/null; then
    echo "Docker is required but not found in PATH."
    exit 1
fi

if [ -z "$RESULTS_DIR" ]; then
    RESULTS_DIR="$REPO_ROOT/.test-results/functional-tests/$MODE"
fi

IMAGE=$(python3 -c 'import sys, yaml; print(yaml.safe_load(open(sys.argv[1]))["image"])' "$IMAGE_YML")
mkdir -p "$RESULTS_DIR"
chmod 777 "$RESULTS_DIR"
trap cleanup_managed_blackboxdb EXIT

if [ "$BUILD_BLACKBOXDB" = "true" ]; then
    build_blackboxdb_image
fi

if [ "$START_BLACKBOXDB" = "true" ]; then
    start_managed_blackboxdb
fi

echo "BlackboxDB functional test runner"
echo ""
echo "Mode:        $MODE"
echo "Image:       $IMAGE"
echo "Engine:      $ENGINE_NAME"
echo "Connection:  $(redact_connection_string "$CONNECTION_STRING")"
echo "Workers:     $WORKERS"
echo "Results:     $RESULTS_DIR"
if [ "$BUILD_BLACKBOXDB" = "true" ] || [ "$START_BLACKBOXDB" = "true" ]; then
    echo "BlackboxDB:"
    echo "  image:     $BLACKBOXDB_IMAGE"
    echo "  container: $BLACKBOXDB_CONTAINER"
    echo "  host port: $BLACKBOXDB_PORT"
fi
if [ -n "$TEST_ID" ]; then
    echo "Test:        $TEST_ID"
fi
if [ "$MODE" = "bootstrap" ]; then
    echo "Runs:        $RUNS"
    echo "Output:      $OUTPUT"
fi
if [ "$PYTEST_ARGS_PRESENT" = "true" ]; then
    echo "Extra args:  ${PYTEST_ARGS[*]}"
fi
echo ""

TEST_EXIT=0

case "$MODE" in
    allowlist)
        docker run --rm --network host \
            -v "$ALLOWLIST_YML:/allowlist.yml:ro" \
            -v "$PLUGIN:/extra/conftest_allowlist.py:ro" \
            -v "$RESULTS_DIR:/results" \
            -e "PYTHONPATH=/extra" \
            "$IMAGE" \
            blackboxdb_tests/compatibility/tests \
            -p conftest_allowlist \
            --allowlist /allowlist.yml \
            --engine-name "$ENGINE_NAME" \
            --allowlist-engine-name "$ENGINE_NAME" \
            --connection-string "$CONNECTION_STRING" \
            -m "not no_parallel" \
            -n "$WORKERS" \
            --json-report --json-report-file=/results/report.json \
            --junitxml=/results/results.xml \
            -v \
            ${PYTEST_ARGS[@]+"${PYTEST_ARGS[@]}"} \
            || TEST_EXIT=$?

        if [ -f "$RESULTS_DIR/report.json" ]; then
            SUMMARY_EXIT=0
            if ! python3 "$GATE_TOOL" \
                --image "$IMAGE_YML" \
                --allowlist "$ALLOWLIST_YML" \
                --engine-name "$ENGINE_NAME" \
                summarize-gate \
                --report "$RESULTS_DIR/report.json" \
                --output-dir "$RESULTS_DIR"; then
                SUMMARY_EXIT=1
            fi
            if [ "$TEST_EXIT" -ne 0 ] || [ "$SUMMARY_EXIT" -ne 0 ]; then
                TEST_EXIT=1
            fi
        else
            echo "No report.json produced. Test execution may have failed before producing results."
            TEST_EXIT=1
        fi
        ;;

    single)
        # Allow users to paste allowlist-style short node IDs.
        if [[ "$TEST_ID" == compatibility/* ]]; then
            TEST_ID="blackboxdb_tests/$TEST_ID"
        fi

        docker run --rm --network host \
            -v "$RESULTS_DIR:/results" \
            "$IMAGE" \
            "$TEST_ID" \
            --engine-name "$ENGINE_NAME" \
            --connection-string "$CONNECTION_STRING" \
            --json-report --json-report-file=/results/report.json \
            --junitxml=/results/results.xml \
            -v \
            ${PYTEST_ARGS[@]+"${PYTEST_ARGS[@]}"} \
            || TEST_EXIT=$?
        ;;

    smoke)
        docker run --rm --network host \
            -v "$RESULTS_DIR:/results" \
            "$IMAGE" \
            blackboxdb_tests/compatibility/tests \
            --engine-name "$ENGINE_NAME" \
            --connection-string "$CONNECTION_STRING" \
            -m "smoke and not no_parallel" \
            -n "$WORKERS" \
            --json-report --json-report-file=/results/report.json \
            --junitxml=/results/results.xml \
            -v \
            ${PYTEST_ARGS[@]+"${PYTEST_ARGS[@]}"} \
            || TEST_EXIT=$?
        ;;

    full|daily)
        docker run --rm --network host \
            -v "$RESULTS_DIR:/results" \
            "$IMAGE" \
            blackboxdb_tests/compatibility/tests \
            --engine-name "$ENGINE_NAME" \
            --connection-string "$CONNECTION_STRING" \
            -n "$WORKERS" \
            --json-report --json-report-file=/results/report.json \
            --junitxml=/results/results.xml \
            -v \
            ${PYTEST_ARGS[@]+"${PYTEST_ARGS[@]}"} \
            || TEST_EXIT=$?

        if [ "$MODE" = "daily" ]; then
            TEST_EXIT=0
            if [ -f "$RESULTS_DIR/report.json" ]; then
                python3 "$GATE_TOOL" \
                    --image "$IMAGE_YML" \
                    --allowlist "$ALLOWLIST_YML" \
                    --engine-name "$ENGINE_NAME" \
                    summarize-daily \
                    --report "$RESULTS_DIR/report.json" \
                    --output-dir "$RESULTS_DIR" \
                    || TEST_EXIT=$?
            else
                echo "No report.json produced. Test execution may have failed before producing results."
                TEST_EXIT=1
            fi
        fi
        ;;

    bootstrap)
        ALL_PASSING=""

        for RUN in $(seq 1 "$RUNS"); do
            RUN_DIR="$RESULTS_DIR/run-$RUN"
            mkdir -p "$RUN_DIR"
            chmod 777 "$RUN_DIR"

            echo "=== Bootstrap run $RUN/$RUNS ==="
            docker run --rm --network host \
                -v "$RUN_DIR:/results" \
                "$IMAGE" \
                blackboxdb_tests/compatibility/tests \
                --engine-name "$ENGINE_NAME" \
                --connection-string "$CONNECTION_STRING" \
                -m "not no_parallel" \
                -n "$WORKERS" \
                --json-report --json-report-file=/results/report.json \
                --junitxml=/results/results.xml \
                -v \
                ${PYTEST_ARGS[@]+"${PYTEST_ARGS[@]}"} \
                || true

            if [ ! -f "$RUN_DIR/report.json" ]; then
                echo "No report.json produced in bootstrap run $RUN."
                TEST_EXIT=1
                break
            fi

            RUN_PASSING=$(python3 -c '
import json
import sys

prefix = "blackboxdb_tests/"
with open(sys.argv[1]) as f:
    report = json.load(f)
for test in report.get("tests", []):
    if test.get("outcome") == "passed":
        nodeid = test["nodeid"]
        if nodeid.startswith(prefix):
            nodeid = nodeid[len(prefix):]
        print(nodeid)
' "$RUN_DIR/report.json" | sort)

            if [ "$RUN" -eq 1 ]; then
                ALL_PASSING="$RUN_PASSING"
            else
                ALL_PASSING=$(comm -12 <(echo "$ALL_PASSING") <(echo "$RUN_PASSING"))
            fi

            echo "Passing in run $RUN: $(echo "$RUN_PASSING" | grep -c '.' || true)"
        done

        if [ "$TEST_EXIT" -eq 0 ]; then
            python3 -c '
import sys
import yaml

output_path = sys.argv[1]
tests = sorted(line.strip() for line in sys.stdin if line.strip())
header = (
    "# Bootstrap output: every entry is a bare string (= applies to all engines).\n"
    "# Bootstrap cannot infer per-engine scoping. If a candidate test should only\n"
    "# run on one engine, convert it manually before promoting:\n"
    "#   - id: <node-id>\n"
    "#     engines: [<engine>]\n"
)
with open(output_path, "w") as f:
    f.write(header)
    yaml.dump({"schema_version": 2, "tests": tests}, f, default_flow_style=False, width=200)
print(f"Wrote {len(tests)} tests to {output_path}")
' "$OUTPUT" <<< "$ALL_PASSING"
        fi
        ;;
esac

echo ""
echo "Test run complete (exit: $TEST_EXIT)"
echo ""
echo "Result artifacts:"
echo "  $RESULTS_DIR/report.json"
echo "  $RESULTS_DIR/results.xml"
if [ -f "$RESULTS_DIR/gate-summary.md" ]; then
    echo "  $RESULTS_DIR/gate-summary.md"
fi
if [ -f "$RESULTS_DIR/daily-summary.md" ]; then
    echo "  $RESULTS_DIR/daily-summary.md"
fi
if [ -f "$RESULTS_DIR/promotion-candidates.yml" ]; then
    echo "  $RESULTS_DIR/promotion-candidates.yml"
fi
if [ "$MODE" = "bootstrap" ] && [ -f "$OUTPUT" ]; then
    echo "  $OUTPUT"
fi

exit "$TEST_EXIT"
