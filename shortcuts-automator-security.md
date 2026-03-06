# Shortcuts Automator Security Policy

## Purpose
Provide a companion policy to `shortcuts-automator.skill` that documents how `/usr/bin/shortcuts` is used safely. This policy exists because the binary skill is not easily edited, so we surface the security expectations in a separate, human-readable document.

## General Principle
Any automation that touches macOS Shortcuts commands must run only with explicit human consent. This includes reviewing the shortcut, understanding what it does, and recording that the user agreed to it before any potentially destructive or credential-sensitive action occurs.

## `shortcuts run` policy
1. Always describe the shortcut being executed: name, identifier (if available), and a brief summary of its purpose.
2. Confirm with the user that they trust the shortcut and understand its effects. This confirmation must be explicit (for example, the user replies with `yes, run <shortcut>` or a dedicated `--yes` flag) and must mention the shortcut name to avoid ambiguity.
3. When the shortcut is unknown, new, or hosted outside the trusted catalog, require additional approval: ask the user to verify the shortcut contents (script, URL, input/output expectations) before agreeing to run it.
4. After the user consents, log that consent in the interaction (e.g., “User approved running shortcut Foo with `--yes`”) so there is an audit trail for future review.

## `shortcuts sign` policy
1. Signing a shortcut may grant it broader privileges; do not proceed unless the user explicitly requests it and confirms they understand the implications.
2. State the file/shortcut being signed, why signing is needed (e.g., to run on another device), and the security trade-offs (signed shortcuts can bypass some gatekeeping protections).
3. Require explicit user approval for each signing request, even if the shortcut was previously signed. Preferably, the approval should include the shortcut name and the purpose of the signing operation.
4. If the shortcut is new to the environment or was downloaded from an untrusted source, consult the user on its provenance before signing.

## Unknown or New Shortcuts
- Any shortcut that has not been seen before (new name, new ID, new bundle) must be treated as untrusted until the user explicitly reviews it.
- Record that the user was informed of the unknown status and still consented to the action.
- If the user declines to run or sign an unknown shortcut, abort the command and note that it was skipped for safety.

## Confirmation Format
Whenever the automation is about to run or sign a shortcut, require a confirmation phrased like:
- `Confirm shortcuts run <shortcut-name> --yes`
- `Confirm shortcuts sign <shortcut-name> --yes`

This ensures that consent is explicit, contextualized, and not assumed by omission.
