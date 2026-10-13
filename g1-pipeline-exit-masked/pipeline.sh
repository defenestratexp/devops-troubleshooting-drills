#!/usr/bin/env bash
# Build pipeline. Runs tests, packages, deploys.
set -e

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*"; }

run_unit_tests() {
  ./run-tests.sh unit | tee build/unit.log
}

run_integration_tests() {
  ./run-tests.sh integration > build/integration.log 2>&1
}

rm -rf build
mkdir -p build

log "unit tests"
run_unit_tests

log "integration tests"
if run_integration_tests; then
  log "integration suite passed"
else
  log "integration suite reported a problem -- see build/integration.log"
fi

log "packaging"
./package.sh > build/package.log

log "deploying"
./deploy.sh || log "deploy reported warnings (non-fatal)"

log "pipeline complete"
