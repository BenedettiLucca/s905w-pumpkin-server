# AGENTS.md

## Project context

- This repository documents and automates a headless Minecraft Java server using Pumpkin on repurposed Amlogic S905W hardware. Target: ARM64 Linux on internal eMMC, managed over Ethernet/SSH.
- The development host is CachyOS (x86-64); the target is the TV box. Keep host-side and target-side commands distinct. Do not assume a command executed locally ran on the target.
- Hardware reference: `B00-MX3mini-REV1.7`, S905W marking, estimated 2 GiB RAM, SanDisk 16 GB eMMC. HDMI is unreliable and there is no physical USB OTG port. Do not assume the commercial model name identifies a compatible device tree or installer profile.

## Repository references

- `README.md`: project overview and reproduction entry point.
- `PLAN.md`: experimental procedure, installation phases, acceptance criteria and recovery paths. Consult the relevant section for provisioning or deployment changes.
- `docs/hardware.md`: hardware inventory and unresolved identification details.
- `docs/experiment-log.md`: observed results, versions, failures and decisions.
- `docs/front-panel.md`: optional display integration, after the core server is stable.
- `scripts/`: operational utilities; `scripts/diagnostics.sh` is the read-only Linux target inventory.

## Implementation conventions

- Keep dependencies and resource usage appropriate for a small ARM64 device. Prefer the native Pumpkin binary under systemd with an unprivileged service account; Docker is a fallback, not a requirement.
- Keep runtime data and configuration separate from versioned code. Commit sanitized configuration examples, not live world data or credentials.
- Use Bash for shell utilities. Quote expansions, validate inputs, return meaningful exit codes, and handle failures explicitly. Make diagnostics read-only and provisioning repeatable where possible. Never hardcode disk device names, private IP addresses or credentials.
- Verify installer arguments, DTB/profile mappings, Pumpkin options and configuration schemas against the exact upstream release in use. Record artifact URLs, versions and SHA-256 hashes; distinguish local hashes from upstream-verified checksums.
- Keep display integration optional and isolated from server startup. A display failure must not prevent SSH or Pumpkin from operating.

## Verification

Run relevant local checks from the repository root:

```sh
bash -n scripts/diagnostics.sh
# If installed:
shellcheck scripts/diagnostics.sh
```

Apply equivalent checks to each changed shell script; review Markdown links and `git diff --check` in a Git checkout. No full automated build/test suite exists in the initial scaffold; use any project checks added subsequently.

On the target, `bash scripts/diagnostics.sh` is a read-only inventory check; sanitize its output before publishing. For deployment changes, verify architecture, actual root storage, service health, Minecraft connectivity and world persistence as applicable. Hardware tests must be identified separately from host-side checks. Do not claim tests passed without executing them.

## Hardware and operational safety

- Local code edits and non-destructive checks may proceed without per-command approval. Obtain explicit operator confirmation before writing or repartitioning storage, changing bootloader/DTB, rebooting the target, or changing live network access. Verify the actual device, command and effect first. The owner permits replacing Android, but that does not identify the correct block device.
- Validate external Linux boot and Ethernet/SSH before installing to eMMC. Follow the release-specific installer documented in `PLAN.md`; do not raw-flash eMMC or force a generic bootloader. Keep a working recovery path where possible.
- Never disable thermal protections, increase voltage or apply unsupported clocks. Verify UART signal levels and pinout before connecting; do not connect VCC. Physical manipulation is performed by the operator.
- Keep Minecraft LAN-only by default, with authentication enabled. Back up world data consistently, off the target when possible, and test restoration. Do not commit secrets, private network identifiers, firmware dumps or world saves.

## Changes and evidence

- Keep changes scoped to the requested task. Preserve unrelated working configurations and document rollback for operational changes.
- Record hardware experiments in `docs/experiment-log.md` with command, environment, version, sanitized output, result and decision. Label estimates, hypotheses and untested behavior as such; retain negative results.
- Update the relevant documentation when behavior, interfaces or hardware findings change. Add rules here only for durable project conventions or recurring pitfalls; keep current tasks, progress, model-specific prompts and step-by-step procedures elsewhere.
