#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")
DRY_RUN=true

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [--yes] <command> [args]

Global options:
  --yes            Run destructive helpers outside dry-run mode (still stubbed).
  -h, --help       Show this help message.

Commands:
  status           Report configured backup sources, snapshots, and volume health.
  start [src dst] Plan an rsync backup and (dry-run) summary.
  list             List known Time Machine snapshots and archive folders.
  prune            Show rotation/pruning guidance (no deletions).
  restore [snap dest] Plan a restore, defaulting to the latest snapshot.
EOF
}

ensure_tmutil() {
  if ! command -v tmutil >/dev/null 2>&1; then
    echo "tmutil not installed or unavailable." >&2
    return 1
  fi
  return 0
}

ensure_diskutil() {
  if ! command -v diskutil >/dev/null 2>&1; then
    echo "diskutil not installed or unavailable." >&2
    return 1
  fi
  return 0
}

cmd_status() {
  local phase="$(ensure_tmutil && tmutil currentphase 2>/dev/null || echo 'unknown')"
  local disk_summary="$(ensure_diskutil && diskutil info / 2>/dev/null | head -n 3 || echo 'diskutil unavailable')"

  cat <<EOF
Backup status (dry-run only):
- Time Machine phase: $phase
- Last snapshot (plan): $(ensure_tmutil && tmutil latestbackup 2>/dev/null || echo 'N/A')
- Disk summary:
$disk_summary
- Primary rsync plan: ~/Documents → /Volumes/Backups/Primary/Documents
EOF
}

cmd_start() {
  local source=${1:-"$HOME/Documents"}
  local destination=${2:-"/Volumes/Backups/Primary/Documents"}
  local rsync_cmd=(rsync -aEHAX --delete --info=progress2 "$source" "$destination")

  echo "Plan: sync $source → $destination"
  echo "Rsync (dry-run by default): ${rsync_cmd[*]}"

  if $DRY_RUN; then
    echo "Dry-run mode: rsync will not execute. Re-run with --yes to exit dry-run mode once a real command has been implemented."
    return
  fi

  echo "(stub) --yes passed but no live rsync is executed. Replace this block when ready."
}

cmd_list() {
  if ensure_tmutil >/dev/null 2>&1; then
    echo "Time Machine snapshots:"
    tmutil listbackups 2>/dev/null || echo "(tmutil listbackups failed)" >&2
  else
    echo "Time Machine snapshots: tmutil unavailable; list backups from /Volumes/Backups manually."
  fi
  echo "Archive folders:"
  echo "- /Volumes/Backups/Primary/" "$HOME/Archives" "(treat as manual rsync targets)"
}

cmd_prune() {
  echo "Pruning guidance (no deletions performed):"
  echo "1. Keep daily backups for 7 days, weekly for 4 weeks, monthly for 6 months."
  echo "2. Use 'tmutil thinlocalsnapshots / <hours> --target <keep>' when comfortable."
  echo "3. Manually delete outdated rsync snapshot folders after verifying checksum."
  echo "Add --yes to record that you reviewed this guidance; the script still won't delete anything."
}

cmd_restore() {
  local snapshot="${1:-}"
  local destination=${2:-"$HOME/Restored"}

  if [[ -z "$snapshot" ]]; then
    if ensure_tmutil >/dev/null 2>&1; then
      snapshot=$(tmutil listbackups | tail -n 1 | awk -F/ '{print $NF}' 2>/dev/null || echo '')
      echo "No snapshot provided; planning to restore the latest snapshot: $snapshot"
    else
      echo "No snapshot provided and tmutil unavailable. Please specify a snapshot name."
      snapshot="<snapshot-name>"
    fi
  fi

  echo "Restore plan: $snapshot → $destination"
  echo "tmutil restore --source \"$snapshot\" --destination \"$destination\""

  if $DRY_RUN; then
    echo "Dry-run (safe) mode: restore command not executed. Use --yes after confirming snapshot to proceed once implementation is ready."
    return
  fi

  echo "(stub) --yes acknowledged but restore not implemented. Replace with actual tmutil restore logic once tested."
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

COMMAND=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)
      DRY_RUN=false
      shift
      ;;  
    -h|--help)
      usage
      exit 0
      ;;  
    status|start|list|prune|restore)
      COMMAND="$1"
      shift
      break
      ;;  
    *)
      echo "Unknown option or command: $1" >&2
      usage
      exit 1
      ;;  
  esac
done

COMMAND_ARGS=()
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "--yes" ]]; then
    DRY_RUN=false
    shift
    continue
  fi
  COMMAND_ARGS+=("$1")
  shift
done

if [[ -z "$COMMAND" ]]; then
  echo "No command specified." >&2
  usage
  exit 1
fi

case "$COMMAND" in
  status)
    cmd_status "${COMMAND_ARGS[@]}"
    ;;
  start)
    cmd_start "${COMMAND_ARGS[@]}"
    ;;
  list)
    cmd_list "${COMMAND_ARGS[@]}"
    ;;
  prune)
    cmd_prune "${COMMAND_ARGS[@]}"
    ;;
  restore)
    cmd_restore "${COMMAND_ARGS[@]}"
    ;;
  *)
    echo "Unsupported command: $COMMAND" >&2
    usage
    exit 1
    ;;
esac
