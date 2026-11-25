#!/usr/bin/env bash
set -euo pipefail

CONTAINER="secure-app-hardened"
URL="http://localhost:13000"

echo "=== Docker Security Validation ==="

check() {
    if "$@"; then
        echo "[PASS] $2"
    else
        echo "[FAIL] $2"
        exit 1
    fi
}

USER_ID=$(docker inspect "$CONTAINER" --format '{{.Config.User}}')
READ_ONLY=$(docker inspect "$CONTAINER" --format '{{.HostConfig.ReadonlyRootfs}}')
PRIVILEGED=$(docker inspect "$CONTAINER" --format '{{.HostConfig.Privileged}}')
CAP_DROP=$(docker inspect "$CONTAINER" --format '{{json .HostConfig.CapDrop}}')
NO_NEW_PRIV=$(docker inspect "$CONTAINER" --format '{{json .HostConfig.SecurityOpt}}')
MEMORY=$(docker inspect "$CONTAINER" --format '{{.HostConfig.Memory}}')
CPU=$(docker inspect "$CONTAINER" --format '{{.HostConfig.NanoCpus}}')
HEALTH=$(docker inspect "$CONTAINER" --format '{{.State.Health.Status}}')

[[ "$USER_ID" == "1000:1000" ]] && echo "[PASS] Non-root user" || { echo "[FAIL] Non-root user"; exit 1; }
[[ "$READ_ONLY" == "true" ]] && echo "[PASS] Read-only filesystem" || { echo "[FAIL] Read-only filesystem"; exit 1; }
[[ "$PRIVILEGED" == "false" ]] && echo "[PASS] Privileged mode disabled" || { echo "[FAIL] Privileged mode"; exit 1; }
[[ "$CAP_DROP" == '["ALL"]' ]] && echo "[PASS] All capabilities dropped" || { echo "[FAIL] Capabilities"; exit 1; }
[[ "$NO_NEW_PRIV" == *"no-new-privileges:true"* ]] && echo "[PASS] No new privileges" || { echo "[FAIL] No-new-privileges"; exit 1; }
[[ "$MEMORY" == "268435456" ]] && echo "[PASS] 256 MiB memory limit" || { echo "[FAIL] Memory limit"; exit 1; }
[[ "$CPU" == "500000000" ]] && echo "[PASS] 0.5 CPU limit" || { echo "[FAIL] CPU limit"; exit 1; }
[[ "$HEALTH" == "healthy" ]] && echo "[PASS] Container healthy" || { echo "[FAIL] Container health"; exit 1; }

RESPONSE=$(curl -fsS "$URL")
[[ "$RESPONSE" == *'"status":"running"'* ]] && echo "[PASS] Application HTTP response" || { echo "[FAIL] Application HTTP response"; exit 1; }

echo "=== All security checks passed ==="
