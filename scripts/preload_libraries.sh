#!/bin/bash

# Provides the base shared_preload_libraries list for BlackboxDB.

# Returns the base preload libraries string for BlackboxDB.
# Callers can prepend their own libraries to the output.
# Arguments:
#   --distributed: include citus and pg_blackboxdb_distributed
#   --rum: include pg_blackboxdb_extended_rum
function GetBlackboxDBBasePreloadLibraries()
{
  local distributed=false
  local rum=false

  for arg in "$@"; do
    case "$arg" in
      --distributed) distributed=true ;;
      --rum) rum=true ;;
    esac
  done

  local clusterPreloadLibraries="pg_blackboxdb_core, pg_blackboxdb"

  if [ "$distributed" == "true" ]; then
    clusterPreloadLibraries="citus, $clusterPreloadLibraries, pg_blackboxdb_distributed"
  fi

  if [ "$rum" == "true" ]; then
    clusterPreloadLibraries="$clusterPreloadLibraries, pg_blackboxdb_extended_rum"
  fi

  echo "pg_cron, $clusterPreloadLibraries"
}
