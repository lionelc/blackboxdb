#!/bin/bash

# Cleanup function to handle container shutdown gracefully
cleanup() {
    echo "Shutting down BlackboxDB components..."
    
    # Kill log streaming processes if they exist
    for pid_var in PG_LOG_TAIL_PID SYSTEM_PG_LOG_TAIL_PID OSS_LOG_TAIL_PID GATEWAY_LOG_TAIL_PID; do
        pid_value=$(eval echo \$${pid_var})
        if [ -n "$pid_value" ]; then
            echo "Stopping log streaming process $pid_var (PID: $pid_value)"
            kill $pid_value 2>/dev/null || true
        fi
    done
    
    # Kill gateway process if it exists
    if [ -n "${gateway_pid:-}" ]; then
        echo "Stopping gateway process (PID: $gateway_pid)"
        kill $gateway_pid 2>/dev/null || true
    fi
    
    echo "Cleanup completed"
    exit 0
}

# Set up signal handlers for graceful shutdown
trap cleanup SIGTERM SIGINT

# Function to start log streaming
start_log_streaming() {
    local log_file="$1"
    local log_prefix="$2"
    local pid_var="$3"
    
    if [ -f "$log_file" ]; then
        echo "Starting log streaming from $log_file with prefix [$log_prefix]..."
        tail -F "$log_file" 2>/dev/null | while IFS= read -r line; do
            echo "[$log_prefix] $line"
        done &
        local tail_pid=$!
        eval "$pid_var=$tail_pid"
        echo "Log streaming started with PID: $tail_pid"
        return 0
    else
        echo "Log file $log_file not found, skipping streaming"
        return 1
    fi
}

# Print help message
usage() {
    cat << EOF
Launches BlackboxDB

Optional arguments:
  -h, --help            Display information on available configuration
  --cert-path [PATH]    Specify a path to a PEM certificate for securing traffic. You need to mount this file into
                        the container (e.g. if CERT_PATH=/mycert.pem, you'd add an option like the following to your
                        docker run: --mount type=bind,source=./mycert.pem,target=/mycert.pem)
                        PEM certificates must be provided together with --key-file.
                        Overrides CERT_PATH environment variable.
  --key-file [PATH]     Specify the PEM private key that matches --cert-path. You need to mount this file into the
                        container (e.g. if KEY_FILE=/mykey.key, you'd add an option like the following to your
                        docker run: --mount type=bind,source=./mykey.key,target=/mykey.key)
                        Overrides KEY_FILE environment variable.
  --data-path [PATH]    Specify a directory for data. Frequently used with docker run --mount option 
                        (e.g. if DATA_PATH=/usr/blackboxdb/data, you'd add an option like the following to your 
                        docker run: --mount type=bind,source=./.local/data,target=/usr/blackboxdb/data)
                        Defaults to /data
                        Overrides DATA_PATH environment variable.
  --blackboxdb-port     The port of the BlackboxDB endpoint on the container. 
                        You still need to publish this port (e.g. -p 10260:10260).
                        Defaults to 10260
                        Overrides PORT environment variable.
  --enable-telemetry    Enable telemetry data sent to the usage colletor (an anonymized telemetry service). 
                        Overrides ENABLE_TELEMETRY environment variable.
  --log-level           The verbosity of logs that will be emitted.
                        Overrides LOG_LEVEL environment variable.
                          quiet, error, warn, info (default), debug, trace
  --username            Specify the username for the BlackboxDB.
                        Defaults to default_user
                        Overrides USERNAME environment variable.
  --password            Specify the password for the BlackboxDB.
                        REQUIRED.
                        Overrides PASSWORD environment variable.
  --create-user         Specify whether to create a user. 
                        Defaults to true.
  --start-pg            Specify whether to start the PostgreSQL server.
                        Defaults to true.
  --pg-port             Specify the port for the PostgreSQL server.
                        Defaults to 9712.
                        Overrides PG_PORT environment variable.
  --owner               Specify the owner of the BlackboxDB.
                        Overrides OWNER environment variable.
                        defaults to blackboxdb.
  --allow-external-connections
                        Allow external connections to PostgreSQL.
                        Defaults to false.
                        Overrides ALLOW_EXTERNAL_CONNECTIONS environment variable.
  --init-data [true|false]
                        Enable initialization with built-in sample data.
                        Seeded once per data volume (on a fresh volume); re-create the
                        volume to seed again.
                        Defaults to false.
                        Overrides INIT_DATA environment variable.
  --init-data-path [PATH]
                        Specify a directory containing JavaScript files for database initialization.
                        Files will be executed in alphabetical order using mongosh.
                        Runs once per data volume (on a fresh volume), so scripts should be
                        idempotent; a failed run is not retried on restart. To re-run, start
                        with a fresh data volume.
                        Defaults to /init_doc_db.d
                        Overrides INIT_DATA_PATH environment variable.
  --skip-init-data      Skip initialization with built-in sample data.
                        Legacy alias for --init-data false.
                        Does not affect --init-data-path; custom data is
                        still loaded once per fresh data volume.
                        Overrides SKIP_INIT_DATA environment variable.
  --disable-extended-rum
                        Disable the use of extended_rum for indexes.
                        By default, extended rum is enabled.
                        Overrides DISABLE_EXTENDED_RUM environment variable.
  --tlsMode [MODE]      Set the TLS mode for client connections.
                        Supported modes: disabled, allowTLS, requireTLS.
                        By default, the gateway accepts both plain and TLS connections (allowTLS).
                        disabled behaves the same as allowTLS; the gateway has no plain-only mode.
                        When set to requireTLS, plain (non-TLS) connections are rejected.
                        Overrides TLS_MODE environment variable.
  --toast-compression [lz4|pglz|default]
                        Compression for values PostgreSQL stores out of line (TOAST).
                        lz4 (the default) is used only when this PostgreSQL build supports it;
                        pglz is PostgreSQL's own default; default leaves the server setting
                        alone. Affects newly written values only, and applies only when this
                        container starts PostgreSQL.
                        Overrides BLACKBOXDB_TOAST_COMPRESSION environment variable.
EOF
}

if [[ -f "/version.txt" ]]; then
  BlackboxDB_RELEASE_VERSION=$(cat /version.txt)
  echo "Release Version: $BlackboxDB_RELEASE_VERSION"
fi

echo "[ENTRYPOINT] BlackboxDB container starting..."
echo "[ENTRYPOINT] Log streaming will be enabled for PostgreSQL logs"

# Handle arguments

while [[ $# -gt 0 ]];
do
  case $1 in
    -h|--help) 
        usage;
        exit 0;;

    --cert-path)
        shift
        export CERT_PATH=$1
        shift;;

    --key-file)
        shift
        export KEY_FILE=$1
        shift;;

    --data-path)
        shift
        export DATA_PATH=$1
        shift;;

    --blackboxdb-port)
        shift
        export BLACKBOXDB_PORT=$1
        shift;;

    --enable-telemetry)
        shift
        export ENABLE_TELEMETRY=$1
        shift;;
        
    --log-level)
        shift
        export LOG_LEVEL=$1
        shift;;

    --username)
        shift
        export USERNAME=$1
        shift;;

    --password)
        shift
        export PASSWORD=$1
        shift;;

    --create-user)
        shift
        export CREATE_USER=$1
        shift;;

    --start-pg)
        shift
        export START_POSTGRESQL=$1
        shift;;

    --pg-port)
        shift
        export POSTGRESQL_PORT=$1
        shift;;

    --owner)
        shift
        export OWNER=$1
        shift;;

    --allow-external-connections)
        shift
        export ALLOW_EXTERNAL_CONNECTIONS=$1
        shift;;

    --init-data)
        shift
        export INIT_DATA=$1
        shift;;

    --init-data-path)
        shift
        export INIT_DATA_PATH=$1
        shift;;

    --skip-init-data)
        export INIT_DATA=false
        export SKIP_INIT_DATA=true
        shift;;

    --disable-extended-rum)
        export DISABLE_EXTENDED_RUM=true
        shift;;

    --tlsMode)
        export TLS_MODE="$2"
        shift; shift;;

    --toast-compression)
        export BLACKBOXDB_TOAST_COMPRESSION="$2"
        shift; shift;;

    -*)
        echo "Unknown option $1"
        exit 1;; 
  esac
done

# Set default values if not provided
export OWNER=${OWNER:-$(whoami)}
export DATA_PATH=${DATA_PATH:-/data}
export BLACKBOXDB_PORT=${BLACKBOXDB_PORT:-10260}
export POSTGRESQL_PORT=${POSTGRESQL_PORT:-9712}
export USERNAME=${USERNAME:-default_user}
export PASSWORD=${PASSWORD:-Admin100}
export CREATE_USER=${CREATE_USER:-true}
export START_POSTGRESQL=${START_POSTGRESQL:-true}
export INIT_DATA=${INIT_DATA:-}
export INIT_DATA_PATH=${INIT_DATA_PATH:-/init_doc_db.d}
export SKIP_INIT_DATA=${SKIP_INIT_DATA:-}
export DISABLE_EXTENDED_RUM=${DISABLE_EXTENDED_RUM:-false}
export TLS_MODE=${TLS_MODE:-allowTLS}
export GATEWAY_HOME=${GATEWAY_HOME:-/home/blackboxdb/gateway}
export BLACKBOXDB_LOG_DIR=${BLACKBOXDB_LOG_DIR:-/var/log/blackboxdb}
export POSTGRES_LOG_VERSION=${PG_VERSION_USED:-17}
export SYSTEM_POSTGRES_LOG=${SYSTEM_POSTGRES_LOG:-/var/log/postgresql/postgresql-${POSTGRES_LOG_VERSION}-main.log}
export BLACKBOXDB_RUNTIME_USER=${BLACKBOXDB_RUNTIME_USER:-blackboxdb}
export BLACKBOXDB_RUNTIME_GROUP=${BLACKBOXDB_RUNTIME_GROUP:-$BLACKBOXDB_RUNTIME_USER}

# Setup centralized log directory structure
echo "Setting up centralized log directory at $BLACKBOXDB_LOG_DIR..."
sudo mkdir -p "$BLACKBOXDB_LOG_DIR/postgres"
sudo chown -R "${BLACKBOXDB_RUNTIME_USER}:${BLACKBOXDB_RUNTIME_GROUP}" "$BLACKBOXDB_LOG_DIR"
sudo chmod -R 755 "$BLACKBOXDB_LOG_DIR"

# Define centralized log file paths
export ENTRYPOINT_LOG="$BLACKBOXDB_LOG_DIR/gateway_entrypoint.log"
export GATEWAY_LOG="$BLACKBOXDB_LOG_DIR/gateway.log"
export OSS_SERVER_LOG="$BLACKBOXDB_LOG_DIR/oss_server.log"
# Note: PostgreSQL log will be symlinked after PostgreSQL starts
export PG_LOG_FILE="$BLACKBOXDB_LOG_DIR/postgres/pglog.log"

echo "Centralized log directory created with the following structure:"
echo "  $BLACKBOXDB_LOG_DIR/gateway_entrypoint.log"
echo "  $BLACKBOXDB_LOG_DIR/gateway.log"
echo "  $BLACKBOXDB_LOG_DIR/oss_server.log"
echo "  $BLACKBOXDB_LOG_DIR/postgres/pglog.log (will be symlinked)"

# Validate required parameters
if [ -z "${PASSWORD:-}" ]; then
    echo "Error: PASSWORD is required. Please provide a password using --password argument or PASSWORD environment variable."
    exit 1
fi

echo "Using username: $USERNAME"
echo "Using owner: $OWNER"
echo "Using data path: $DATA_PATH"

if { [ -n "${CERT_PATH:-}" ] && [ -z "${KEY_FILE:-}" ]; } || \
   { [ -z "${CERT_PATH:-}" ] && [ -n "${KEY_FILE:-}" ]; }; then
    echo "Error: Both CERT_PATH and KEY_FILE must be set together, or neither should be set."
    exit 1
fi

num='^[0-9]+$'
if ! [[ "$BLACKBOXDB_PORT" =~ $num ]]; then
    echo "Invalid port value $BLACKBOXDB_PORT, must be a number"
    exit 1
fi

if ! [[ "$POSTGRESQL_PORT" =~ $num ]]; then
    echo "Invalid PostgreSQL port value $POSTGRESQL_PORT, must be a number"
    exit 1
fi

if [ -n "$ENABLE_TELEMETRY" ] && \
   [ "$ENABLE_TELEMETRY" != "true" ] && \
   [ "$ENABLE_TELEMETRY" != "false" ]; then
    echo "Invalid enable-telemetry value $ENABLE_TELEMETRY, must be true or false"
    exit 1
fi

if [ -n "$LOG_LEVEL" ] && \
   [ "$LOG_LEVEL" != "quiet" ] && \
   [ "$LOG_LEVEL" != "error" ] && \
   [ "$LOG_LEVEL" != "warn" ] && \
   [ "$LOG_LEVEL" != "info" ] && \
   [ "$LOG_LEVEL" != "debug" ] && \
   [ "$LOG_LEVEL" != "trace" ]; then
    echo "Invalid log level value $LOG_LEVEL, must be one of: quiet, error, warn, info, debug, trace"
    exit 1
fi

if [ -n "$INIT_DATA" ] && \
   [ "$INIT_DATA" != "true" ] && \
   [ "$INIT_DATA" != "false" ]; then
    echo "Invalid init-data value $INIT_DATA, must be true or false"
    exit 1
fi

if [ -n "$SKIP_INIT_DATA" ] && \
   [ "$SKIP_INIT_DATA" != "true" ] && \
   [ "$SKIP_INIT_DATA" != "false" ]; then
    echo "Invalid skip-init-data value $SKIP_INIT_DATA, must be true or false"
    exit 1
fi

if [ -z "$INIT_DATA" ]; then
    if [ "$SKIP_INIT_DATA" = "false" ]; then
        export INIT_DATA=true
    else
        export INIT_DATA=false
    fi
fi

if [ "$INIT_DATA" = "true" ]; then
    export SKIP_INIT_DATA=false
else
    export SKIP_INIT_DATA=true
fi

case "$TLS_MODE" in
    disabled|allowTLS|requireTLS) ;;
    *)
        echo "Invalid tlsMode value '$TLS_MODE', must be one of: disabled, allowTLS, requireTLS"
        exit 1;;
esac

# TOAST compression for the PostgreSQL this container starts: lz4 unless overridden.
toast_requested="${BLACKBOXDB_TOAST_COMPRESSION:-}"
toast_compression="${toast_requested:-lz4}"
case "$toast_compression" in
    lz4|pglz|default) ;;
    *)
        echo "Invalid TOAST compression value '$toast_compression' (from --toast-compression or BLACKBOXDB_TOAST_COMPRESSION), must be one of: lz4, pglz, default"
        exit 1;;
esac
if [ "$START_POSTGRESQL" != "true" ] && [ -n "$toast_requested" ] && [ "$toast_requested" != "default" ]; then
    echo "Warning: TOAST compression '$toast_requested' is ignored because this container does not start PostgreSQL; set default_toast_compression on that PostgreSQL instead." >&2
fi

if [ "$START_POSTGRESQL" = "true" ]; then
    echo "Starting PostgreSQL server on port $POSTGRESQL_PORT..."
    exec > >(tee -a "$ENTRYPOINT_LOG") 2> >(tee -a "$ENTRYPOINT_LOG" >&2)
    
    # Fix permissions on data directory to prevent "Permission denied" errors
    echo "Ensuring proper permissions on data directory: $DATA_PATH"
    if [ ! -d "$DATA_PATH" ]; then
        echo "Creating data directory: $DATA_PATH"
        sudo mkdir -p "$DATA_PATH"
    fi
    
    # Change ownership to the runtime user to ensure we can write/delete files
    echo "Setting ownership of $DATA_PATH to ${BLACKBOXDB_RUNTIME_USER}:${BLACKBOXDB_RUNTIME_GROUP}"
    sudo chown -R "${BLACKBOXDB_RUNTIME_USER}:${BLACKBOXDB_RUNTIME_GROUP}" "$DATA_PATH"
    
    # Ensure we have full permissions on the directory
    echo "Setting permissions on $DATA_PATH"
    sudo chmod -R 750 "$DATA_PATH"
    
    if ALLOW_EXTERNAL_CONNECTIONS="true"; then
        echo "Allowing external connections to PostgreSQL..."
        export PGOPTIONS="-e"
    fi
    echo "Starting OSS server..."
    EXTENDED_RUM_FLAG="-r"
    if [ "$DISABLE_EXTENDED_RUM" = "true" ]; then
        EXTENDED_RUM_FLAG=""
    fi
    start_oss_server_args=()
    if [ -n "$EXTENDED_RUM_FLAG" ]; then
        start_oss_server_args+=("$EXTENDED_RUM_FLAG")
    fi
    if [ -n "${PGOPTIONS:-}" ]; then
        IFS=' ' read -r -a pgoptions_array <<< "$PGOPTIONS"
        start_oss_server_args+=("${pgoptions_array[@]}")
    fi
    if [ "$CREATE_USER" = "false" ]; then
        start_oss_server_args+=(-u "")
    else
        start_oss_server_args+=(-u "$USERNAME" -a "$PASSWORD")
    fi
    start_oss_server_args+=(-d "$DATA_PATH" -p "$POSTGRESQL_PORT")

    # TOAST compression. The setting lives in a fragment outside the data directory that is
    # rewritten on every start (a changed value applies at the next restart) and included from
    # postgresql.conf. start_oss_server.sh appends the include whenever -f is passed, so -f is
    # passed only while the data directory does not include the fragment yet. Servers started
    # without this entrypoint (development, regression tests) keep the PostgreSQL default.
    TOAST_COMPRESSION_CONF="${TOAST_COMPRESSION_CONF:-$GATEWAY_HOME/blackboxdb_toast_compression.conf}"
    case "$TOAST_COMPRESSION_CONF" in
        /*) ;;
        *)
            echo "Error: TOAST_COMPRESSION_CONF must be an absolute path (got '$TOAST_COMPRESSION_CONF')." >&2
            exit 1;;
    esac
    case "$TOAST_COMPRESSION_CONF" in
        "${DATA_PATH%/}"/*|*\'*|*\\*|*$'\n'*)
            echo "Error: TOAST_COMPRESSION_CONF must lie outside the data directory and must not contain quotes, backslashes or newlines." >&2
            exit 1;;
    esac
    if [ -d "$TOAST_COMPRESSION_CONF" ]; then
        echo "Error: TOAST_COMPRESSION_CONF must name a file, but '$TOAST_COMPRESSION_CONF' is a directory." >&2
        exit 1
    fi
    if [ "$toast_compression" = "lz4" ]; then
        # PostgreSQL refuses to start with lz4 if it was built without it.
        toast_lz4_support=unknown
        toast_pg_config="${PG_CONFIG:-$(command -v pg_config || true)}"
        toast_configure=""
        if [ -n "$toast_pg_config" ] && ! toast_configure="$("$toast_pg_config" --configure 2>/dev/null)"; then
            toast_configure=""
        fi
        if [ -n "$toast_configure" ]; then
            case "$toast_configure" in
                *--with-lz4*) toast_lz4_support=yes ;;
                *) toast_lz4_support=no ;;
            esac
        else
            toast_postgres="$(command -v postgres || true)"
            if [ -n "$toast_postgres" ] && command -v ldd > /dev/null 2>&1; then
                if ldd "$toast_postgres" 2>/dev/null | grep -q 'liblz4'; then
                    toast_lz4_support=yes
                else
                    toast_lz4_support=no
                fi
            fi
        fi
        if [ "$toast_lz4_support" = "no" ] && [ -n "$toast_requested" ]; then
            echo "Error: TOAST compression lz4 was requested, but this PostgreSQL build has no lz4 support." >&2
            exit 1
        elif [ "$toast_lz4_support" = "no" ]; then
            echo "Warning: this PostgreSQL build has no lz4 support; leaving default_toast_compression to the server." >&2
            toast_compression=default
        elif [ "$toast_lz4_support" = "unknown" ] && [ -z "$toast_requested" ]; then
            echo "Warning: could not check this PostgreSQL build for lz4 support; leaving default_toast_compression to the server." >&2
            toast_compression=default
        fi
    fi
    if [ "$toast_compression" = "default" ]; then
        toast_line="# default_toast_compression is left to the server default"
    else
        toast_line="default_toast_compression = '$toast_compression'"
    fi
    if ! { printf '%s\n' "$toast_line" > "$TOAST_COMPRESSION_CONF.tmp" && mv -f "$TOAST_COMPRESSION_CONF.tmp" "$TOAST_COMPRESSION_CONF"; }; then
        echo "Error: could not write $TOAST_COMPRESSION_CONF." >&2
        exit 1
    fi
    echo "TOAST compression: $toast_compression ($TOAST_COMPRESSION_CONF)"
    if ! grep -qsF "include '$TOAST_COMPRESSION_CONF'" "$DATA_PATH/postgresql.conf"; then
        start_oss_server_args+=(-f "$TOAST_COMPRESSION_CONF")
    fi

    $GATEWAY_HOME/scripts/start_oss_server.sh "${start_oss_server_args[@]}" | tee -a "$OSS_SERVER_LOG"

    echo "OSS server started."
    echo "[ENTRYPOINT] Setting up PostgreSQL log streaming..."

    # Start streaming PostgreSQL logs to docker logs
    # Note: We exclude ENTRYPOINT_LOG_TAIL_PID to prevent recursion
    PG_LOG_TAIL_PID=""
    SYSTEM_PG_LOG_TAIL_PID=""
    OSS_LOG_TAIL_PID=""
    GATEWAY_LOG_TAIL_PID=""
    
    echo "Setting up PostgreSQL log streaming from $PG_LOG_FILE..."
    
    # Wait for PostgreSQL log file to be created in the data directory
    ACTUAL_PG_LOG="$DATA_PATH/pglog.log"
    i=0
    while [ ! -f "$ACTUAL_PG_LOG" ] && [ $i -lt 30 ]; do
        sleep 1
        i=$((i + 1))
    done
    
    # Create symlink from centralized location to actual PostgreSQL log
    if [ -f "$ACTUAL_PG_LOG" ]; then
        echo "Creating symlink: $PG_LOG_FILE -> $ACTUAL_PG_LOG"
        ln -sf "$ACTUAL_PG_LOG" "$PG_LOG_FILE"
    else
        echo "Warning: PostgreSQL log file not found at $ACTUAL_PG_LOG"
    fi
    
    # Start streaming main PostgreSQL log
    start_log_streaming "$PG_LOG_FILE" "POSTGRES" "PG_LOG_TAIL_PID"
    
    # Also stream system PostgreSQL logs if they exist
    SYSTEM_PG_LOG="$SYSTEM_POSTGRES_LOG"
    start_log_streaming "$SYSTEM_PG_LOG" "POSTGRES-SYSTEM" "SYSTEM_PG_LOG_TAIL_PID"
    
    # Stream OSS server logs
    start_log_streaming "$OSS_SERVER_LOG" "OSS-SERVER" "OSS_LOG_TAIL_PID"
    
    # NOTE: We do NOT stream entrypoint logs to prevent infinite recursion!
    # The entrypoint messages are already going to stdout/stderr and appear in docker logs
    # ENTRYPOINT_LOG="$GATEWAY_HOME/entrypoint.log"
    # start_log_streaming "$ENTRYPOINT_LOG" "ENTRYPOINT" "ENTRYPOINT_LOG_TAIL_PID"

    echo "Checking if PostgreSQL is running..."
    i=0
    while [ ! -f "$DATA_PATH/postmaster.pid" ]; do
        sleep 1
        if [ $i -ge 60 ]; then
            echo "PostgreSQL failed to start within 60 seconds."
            cat "$OSS_SERVER_LOG"
            exit 1
        fi
        i=$((i + 1))
    done
    echo "PostgreSQL is running."
else
    echo "Skipping PostgreSQL server start."
fi

# Setting up the configuration file
mkdir -p "$GATEWAY_HOME/pg_blackboxdb_gw/target"
configFile="$GATEWAY_HOME/pg_blackboxdb_gw/target/SetupConfiguration_temp.json"
cp "$GATEWAY_HOME/pg_blackboxdb_gw/SetupConfiguration.json" "$configFile"
sudo chmod 755 "$configFile"

if [ -n "${BLACKBOXDB_PORT:-}" ]; then
    echo "Updating GatewayListenPort in the configuration file..."
    jq ".GatewayListenPort = $BLACKBOXDB_PORT" "$configFile" > "$configFile.tmp" && \
    mv "$configFile.tmp" "$configFile"
fi

if [ -n "${POSTGRESQL_PORT:-}" ]; then
    echo "Updating PostgresPort in the configuration file..."
    jq ".PostgresPort = $POSTGRESQL_PORT" "$configFile" > "$configFile.tmp" && \
    mv "$configFile.tmp" "$configFile"
fi

if [ -n "${CERT_PATH:-}" ] && [ -n "${KEY_FILE:-}" ]; then
    echo "Adding CertificateOptions to the configuration file..."
    jq --arg certPath "$CERT_PATH" --arg keyFilePath "$KEY_FILE" \
       '.CertificateOptions = { "CertType": "PemFile", "FilePath": $certPath, "KeyFilePath": $keyFilePath }' \
       "$configFile" > "$configFile.tmp" && \
    mv "$configFile.tmp" "$configFile"
fi

echo "Setting TLS mode to '$TLS_MODE'..."
jq --arg tlsMode "$TLS_MODE" '.TlsMode = $tlsMode' "$configFile" > "$configFile.tmp" && \
mv "$configFile.tmp" "$configFile"

# Translate the requested TLS mode into the EnforceTls flag the gateway actually
# reads. requireTLS enforces TLS for every connection; allowTLS and disabled let
# the gateway accept both plain (non-TLS) and TLS clients on the same port.
if [ "$TLS_MODE" = "requireTLS" ]; then
    enforceTls=true
else
    enforceTls=false
    if [ "$TLS_MODE" = "disabled" ]; then
        echo "Warning: tlsMode 'disabled' does not turn TLS off. The gateway has no plain-only mode, so it behaves like 'allowTLS' and still accepts TLS connections (plain connections are accepted as well)." >&2
    fi
fi

# Fail fast if the EnforceTls write does not succeed: a stale config would leave
# EnforceTls unset, which the gateway treats as "enforce TLS", silently rejecting
# the plain connections this setting is meant to allow.
if ! jq --argjson enforceTls "$enforceTls" '.EnforceTls = $enforceTls' "$configFile" > "$configFile.tmp"; then
    echo "Error: failed to write EnforceTls to the gateway configuration file." >&2
    exit 1
fi
mv "$configFile.tmp" "$configFile"

echo "Starting gateway in the background..."
if [ "$CREATE_USER" = "false" ]; then
    echo "Skipping user creation and starting the gateway..."
    $GATEWAY_HOME/scripts/build_and_start_gateway.sh -s -d $configFile -P $POSTGRESQL_PORT -o $OWNER | tee -a "$GATEWAY_LOG" &
else
    $GATEWAY_HOME/scripts/build_and_start_gateway.sh -u $USERNAME -p $PASSWORD -d $configFile -P $POSTGRESQL_PORT -o $OWNER | tee -a "$GATEWAY_LOG" &
fi

gateway_pid=$! # Capture the PID of the gateway process

# Wait for the gateway to be ready before attempting initialization
echo "Waiting for gateway to be ready..."
max_attempts=60
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if nc -z localhost "$BLACKBOXDB_PORT"; then
        echo "Gateway is ready on localhost:$BLACKBOXDB_PORT"
        break
    fi
    echo "Attempt $((attempt + 1))/$max_attempts: Gateway not ready yet, waiting..."
    sleep 1
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo "Error: Gateway failed to start within $max_attempts seconds"
    exit 1
fi

# First-boot data-initialization markers (#612).
# Markers live inside the persistent data dir ($DATA_PATH) so they survive container
# restarts, `docker compose down && up`, host reboots, and volume backups. They make data
# initialization one-shot and prevent the restart loop caused by re-running non-idempotent
# seed scripts against already-seeded data. Like common database container images,
# initialization runs only on a fresh data directory; to re-initialize, start the container
# with an empty/new data volume.
INIT_MARKER_DIR="$DATA_PATH/.blackboxdb-local"

# init_marker_present <marker-file>: succeeds when initialization already ran on this volume.
init_marker_present() {
    [ -f "$1" ]
}

# write_init_marker <marker-file>: record a successful initialization. A failure to write is
# only a warning; it would cause a redundant re-init attempt on the next boot, not data loss.
write_init_marker() {
    if ! mkdir -p "$INIT_MARKER_DIR" 2>/dev/null || ! touch "$1" 2>/dev/null; then
        echo "Warning: could not write init marker $1; initialization may run again on restart."
    fi
}

# Initialize database with custom (user-provided) data if the directory has JS files.
# One-shot per data volume: init_blackboxdb_data.sh records $custom_attempt_marker right
# before the first user script runs, so a non-idempotent custom init that fails partway is
# not re-run on restart and cannot loop (#612). User scripts should still be idempotent.
# To re-run after fixing scripts, start with a fresh data volume.
custom_data_initialized=false
custom_attempt_marker="$INIT_MARKER_DIR/custom_data_attempted"
custom_success_marker="$INIT_MARKER_DIR/custom_data_succeeded"
if [ -d "$INIT_DATA_PATH" ] && [ "$(ls -A "$INIT_DATA_PATH"/*.js 2>/dev/null)" ] && init_marker_present "$custom_attempt_marker"; then
    if init_marker_present "$custom_success_marker"; then
        echo "Custom data already initialized (found $custom_success_marker); skipping. To re-run, start with a fresh data volume."
    else
        echo "Warning: a previous custom data initialization was attempted but its success was not recorded; it may have failed or only partially applied."
        echo "Skipping to avoid re-running non-idempotent scripts. To retry from clean, start with a fresh data volume."
    fi
    custom_data_initialized=true
elif [ -d "$INIT_DATA_PATH" ] && [ "$(ls -A "$INIT_DATA_PATH"/*.js 2>/dev/null)" ]; then
    echo "Initializing database with custom data from: $INIT_DATA_PATH"
    
    # Use the dedicated initialization script
    init_script="$GATEWAY_HOME/scripts/init_blackboxdb_data.sh"
    if [ -f "$init_script" ]; then
        echo "Using custom initialization data from: $INIT_DATA_PATH"
        if "$init_script" -H localhost -P "$BLACKBOXDB_PORT" -u "$USERNAME" -p "$PASSWORD" -d "$INIT_DATA_PATH" --attempt-marker "$custom_attempt_marker" -v; then
            echo "Custom data initialization completed."
            write_init_marker "$custom_success_marker"
            custom_data_initialized=true
        else
            echo "Error: Custom data initialization failed; it will not be retried on restart if it had begun applying data."
            echo "Fix your initialization scripts and start with a fresh data volume to re-run."
            exit 1
        fi
    else
        echo "Warning: Initialization script not found at $init_script"
    fi
fi

# Initialize database with built-in sample data if explicitly enabled.
# Guarded by a one-shot marker (in $DATA_PATH) so a restart with a persistent volume does
# not re-run the seed and crash with a duplicate-key error (#612).
sample_init_marker="$INIT_MARKER_DIR/sample_data_initialized"
if [ "$INIT_DATA" = "true" ] && init_marker_present "$sample_init_marker"; then
    echo "Sample data already initialized (found $sample_init_marker); skipping. To re-run, start with a fresh data volume."
elif [ "$INIT_DATA" = "true" ]; then
    echo "Initializing database with built-in sample data..."
    
    # Use the sample data directory
    sample_data_path="$GATEWAY_HOME/sample-data"
    init_script="$GATEWAY_HOME/scripts/init_blackboxdb_data.sh"
    
    if [ -f "$init_script" ] && [ -d "$sample_data_path" ]; then
        echo "Loading sample data from: $sample_data_path"
        if "$init_script" -H localhost -P "$BLACKBOXDB_PORT" -u "$USERNAME" -p "$PASSWORD" -d "$sample_data_path" -v; then
            echo "Sample data initialization completed."
            write_init_marker "$sample_init_marker"
        else
            echo "Error: Sample data initialization failed"
            exit 1
        fi
        echo ""
        echo "Sample data has been loaded into the 'sampledb' database with the following collections:"
        echo "  - users (5 sample users)"
        echo "  - products (5 sample products)"  
        echo "  - orders (4 sample orders)"
        echo "  - analytics (sample metrics and activity data)"
        echo ""
        echo "Connect to your BlackboxDB instance and use: use('sampledb')"
    else
        echo "Warning: Sample data or initialization script not found"
        if [ ! -f "$init_script" ]; then
            echo "  - Missing: $init_script"
        fi
        if [ ! -d "$sample_data_path" ]; then
            echo "  - Missing: $sample_data_path"
        fi
    fi
fi

if [ "$custom_data_initialized" = "false" ] && [ "$INIT_DATA" != "true" ]; then
    echo "No initialization data loaded."
    echo "To load data: use --init-data true for built-in sample data, or --init-data-path [PATH] for custom data."
fi
# Also stream existing gateway logs (for historical logs that might already exist)
if [ -f "$GATEWAY_LOG" ]; then
    echo "Starting gateway log streaming for existing logs..."
    tail -F "$GATEWAY_LOG" 2>/dev/null | while IFS= read -r line; do
        echo "[GATEWAY-FILE] $line"
    done &
    GATEWAY_LOG_TAIL_PID=$!
    echo "Gateway log file streaming started with PID: $GATEWAY_LOG_TAIL_PID"
fi

echo "Gateway started with PID: $gateway_pid"
echo ""
echo "=== BlackboxDB is ready ==="
echo "All logs are being streamed to docker logs with prefixes:"
echo "  [POSTGRES] - PostgreSQL database logs ($PG_LOG_FILE)"
echo "  [POSTGRES-SYSTEM] - System PostgreSQL logs ($SYSTEM_POSTGRES_LOG)"
echo "  [OSS-SERVER] - OSS server logs ($OSS_SERVER_LOG)"
echo "  [ENTRYPOINT] - Entrypoint script logs ($ENTRYPOINT_LOG)"
echo "  [GATEWAY] - Gateway application logs (live output via tee)"
echo "  [GATEWAY-FILE] - Gateway log file content ($GATEWAY_LOG)"
echo ""
echo "Centralized log directory structure:"
echo "  $BLACKBOXDB_LOG_DIR/"
echo "  ├── gateway_entrypoint.log"
echo "  ├── gateway.log"
echo "  ├── oss_server.log"
echo "  └── postgres/"
echo "      └── pglog.log -> $DATA_PATH/pglog.log"
echo ""
echo "View all logs with: docker logs <container_name>"
echo "View live logs with: docker logs -f <container_name>"
echo "Filter specific logs: docker logs <container_name> | grep '[PREFIX]'"
echo "Example: docker logs <container_name> | grep '[POSTGRES]'"
echo "=========================="
echo ""

# Wait for the gateway process to keep the container alive
# The wait will be interrupted by signals, allowing cleanup to run
wait $gateway_pid
