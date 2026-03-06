---
name: backup-manager
description: Local backup orchestration with rsync, tmutil, and diskutil helpers. Trigger this skill when a user wants to check backup status, run or plan a backup, list available backups, prune old snapshots, restore data, or otherwise interact with Time Machine/rsync archives.
---

# Purpose
Describe the policy, status, and planning steps for coordinating local backups on macOS. Use this skill when Time Machine, rsync archives, or disk health checks are part of the requested workflow rather than ad-hoc file copies.

# Triggers
- “backup” or “run my backup”
- “restore from backup”
- “backup status” / “time machine status”
- “list backups” / “show snapshots”
- “prune old backups” / “thin Time Machine”
- Mentions of `rsync`, `tmutil`, `diskutil`, or rotating archives with retention requirements

# Commands
All commands are implemented as stubs in `backup-manager/backup-manager.sh` and default to dry-run mode. Pass `--yes` when the user explicitly consents to run live helpers (the script still only prints the planned command for final implementation).

## status
Summarize configured sources and destinations, the current Time Machine phase, and disk health. Refer to `/Volumes/Backups` and the primary rsync plan (`~/Documents` → `/Volumes/Backups/Primary/Documents`).

## start
Plan an rsync-based mirror. Use: `backup-manager.sh start [source target] [--yes]`. When the user provides a source and destination, include them in the summary; otherwise fall back to `~/Documents` → `/Volumes/Backups/Primary/Documents`. Emphasize that this command prints the rsync invocation and stays in dry-run mode unless explicitly elevated. Raise awareness that `rsync --delete` removes files on the destination that do not exist on the source, a behavior that can delete data quickly when a live destination is targeted—double-check the destination before running live.

## list
List Time Machine snapshots and archived rsync folders. Run `tmutil listbackups` when available and describe alternate directories when tmutil is missing.

## prune
Explain a pruning strategy (keep daily/weekly/monthly tiers, use `tmutil thinlocalsnapshots`, manually delete aged rsync snapshots) without performing deletions automatically.

## restore
Plan restores with `tmutil restore --source <snapshot> --destination <path>`. Default to the latest snapshot when the user omits it, and never execute the restore command without explicit human approval.

# Safety Rules
1. Always keep the script in dry-run mode—`backup-manager.sh` should not modify data unless the user says `--yes` and acknowledges that the implementation block is still a stub.
2. Remind users to verify source/destination paths before copying or deleting any data.
3. Pruning and restores are descriptive only; they should never run destructive commands automatically.
4. Document which tool (`rsync`, `tmutil`, `diskutil`) is responsible for each action so operators can audit the planned command before execution.
5. Any future non-dry-run destructive action (pruning, `rsync --delete` live syncs, restores, etc.) must only proceed after explicit `--yes` confirmation from the user.

# Examples
- “What is the current state of my Time Machine backups?” → run `backup-manager.sh status` and explain the output.
- “I want to back up my Documents folder to the nightly archive.” → prepare `backup-manager.sh start ~/Documents /Volumes/Backups/Primary/Documents` and describe the rsync command.
- “Show me all available snapshots.” → `backup-manager.sh list` and explain how tmutil lists backups.
- “How should I prune seven days of local snapshots?” → `backup-manager.sh prune` and describe `tmutil thinlocalsnapshots` plus manual removal steps.
- “Restore last week’s snapshot to ~/Restored” → `backup-manager.sh restore --yes` (with the requested snapshot) and outline the tmutil restore flow.

# Implementation Notes
- **rsync:** Use `rsync -aEHAX --delete --info=progress2` with `--link-dest` pointing at the last snapshot when available. `--delete` aggressively removes destination files that do not exist on the source, so call this out as high risk (especially when live mode is possible) and verify the destination path before executing live. Include `--dry-run` by default and explain how `--yes` and `rsync --delete` would work together once implemented.
- **tmutil:** Use `tmutil listbackups`, `tmutil latestbackup`, `tmutil thinlocalsnapshots`, and `tmutil restore`. Wrap each command with availability checks so scripts don’t crash on non-macOS hosts.
- **diskutil:** Query relevant volumes with `diskutil info /` and `diskutil verifyVolume <target>` to inform the user if a destination disk isn’t healthy before scheduling backups.
