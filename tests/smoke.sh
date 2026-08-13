#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_dir/versions.env"

image="gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"
name="gd-smoke-$$"
readonly_name="gd-smoke-readonly-$$"
tmp_dir=$(mktemp -d)

cleanup() {
  local status=$?
  set +e
  docker rm -f "$name" "$readonly_name" >/dev/null 2>&1 || true
  bash "$repo_dir/tests/lib/cleanup-bind-mount.sh" "$image" "$tmp_dir" >/dev/null 2>&1
  return "$status"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/config" "$tmp_dir/output" "$tmp_dir/read-only"

start_container() {
  docker run -d --name "$name" \
    -e USER_ID=1000 -e GROUP_ID=1000 \
    -p 127.0.0.1::5800 \
    -v "$tmp_dir/config:/config:rw" \
    -v "$tmp_dir/output:/output:rw" \
    "$image" >/dev/null
}

wait_for_ui() {
  local port
  port=$(docker port "$name" 5800/tcp | sed 's/.*://')
  for _ in $(seq 1 120); do
    curl -fsS "http://127.0.0.1:$port/" >/dev/null && return 0
    sleep 1
  done
  docker logs "$name" >&2
  return 1
}

wait_for_app() {
  for _ in $(seq 1 120); do
    if test -f "$tmp_dir/config/logs/current.log" &&
      grep -Fq 'GDownloader is initialized' "$tmp_dir/config/logs/current.log"; then
      return 0
    fi
    if [[ $(docker inspect --format '{{.State.Running}}' "$name") != true ]]; then
      docker logs "$name" >&2
      return 1
    fi
    sleep 1
  done
  docker logs "$name" >&2
  return 1
}

wait_for_health() {
  for _ in $(seq 1 120); do
    [[ $(docker inspect --format '{{.State.Health.Status}}' "$name") == healthy ]] && return 0
    sleep 1
  done
  docker inspect --format '{{json .State.Health}}' "$name" >&2
  return 1
}

start_container
wait_for_ui
wait_for_app
jq -e '.DownloadsPath == "/output" and .AutomaticUpdates == false and .PreferSystemExecutables == true' "$tmp_dir/config/config.json"
jq -e '.GalleryDLSettings.Enabled == false and .SpotDLSettings.Enabled == false' "$tmp_dir/config/config.json"
grep -F 'GDownloader is initialized' "$tmp_dir/config/logs/current.log"
! grep -F 'Starting download GDownloader' "$tmp_dir/config/logs/current.log"
[[ $(docker exec -u app "$name" id -u) == 1000 ]]
[[ $(docker exec -u app "$name" id -g) == 1000 ]]
docker exec -u app "$name" sh -c 'echo persisted > /output/persistence-marker'
if ! docker info --format '{{.OperatingSystem}}' | grep -Fqi 'Docker Desktop'; then
  [[ $(docker exec "$name" stat -c '%u:%g' /output/persistence-marker) == 1000:1000 ]]
fi

docker rm -f "$name" >/dev/null
start_container
wait_for_ui
wait_for_app
wait_for_health
test -f "$tmp_dir/output/persistence-marker"
jq -e '.DownloadsPath == "/output"' "$tmp_dir/config/config.json"
[[ $(docker inspect --format '{{.State.Health.Status}}' "$name") == healthy ]]

docker run -d --name "$readonly_name" \
  -e USER_ID=1000 -e GROUP_ID=1000 \
  -v "$tmp_dir/config:/config:rw" \
  -v "$tmp_dir/read-only:/output:ro" \
  "$image" >/dev/null
[[ $(docker wait "$readonly_name") == 1 ]]
[[ $(docker inspect --format '{{.State.Status}}' "$readonly_name") == exited ]]
docker logs "$readonly_name" 2>&1 | grep -F 'Directory is not writable by app: /output (uid=1000, gid=1000)'
