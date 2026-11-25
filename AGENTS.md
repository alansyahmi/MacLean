# MacLean Development Principles

These instructions apply to all code, research notes, experiments, and generated reports in this repository.

## Start from the repository

- Inspect existing source, build tooling, supported OS versions, and module boundaries before adding dependencies or choosing a runtime.
- Preserve working implementations. Prefer a small adapter or extension over replacing a working subsystem.
- Keep architecture and data contracts portable unless an existing implementation establishes a platform choice.
- Use docs/ARCHITECTURE.md as a guide; do not create a framework or daemon merely to fill a directory.

## Evidence first

- State the hypothesis before measuring.
- Prefer Apple documentation, installed system manuals, and maintained source code over guesses or forum summaries.
- Record source, OS build, hardware capabilities, units, sampling window, and uncertainty for each metric.
- Distinguish direct measurements, derived values, and operating-system estimates.
- Missing and unsupported values stay unavailable; never replace them with zero or a guessed proxy.
- Do not claim an optimization from frequency, temperature, utilization, or one battery run alone.
- Compare energy per completed task with performance, responsiveness, thermal behaviour, and repeat-to-repeat variation.

## Safety and compatibility

- Start read-only. Keep experimental controls isolated and disabled by default.
- Never write undocumented MSRs, SMC keys, firmware settings, PCIe registers, or private driver properties.
- Never disable thermal protection, security controls, charging, sleep/wake support, or required peripheral connectivity.
- Any future control requires an exact capability check, explicit user action, a narrow documented interface, verified postconditions, a watchdog, and a tested rollback.
- If the control state cannot be verified or restored, do not apply it.
- Do not ask users to run privileged commands by default. If a future feature truly needs privilege, document why and minimize its scope.

## Low overhead and privacy

- Keep collectors on demand until their need and cost are measured.
- Avoid busy loops, high-frequency polling, unnecessary timers, process scans, and background network activity.
- Record collection overhead as part of benchmark methodology.
- Keep data local. Do not add telemetry upload, analytics, or cloud dependencies without a separately reviewed requirement.
- Never store or publish serial numbers, account names, hostnames, SSIDs, IP addresses, or unrelated process details.

## Module discipline

- A module owns its capability requirements, data sources, limits, workload, and rollback proposal.
- Platform-specific code stays behind a capability boundary.
- Unsupported hardware is a normal result, not an error that blocks other modules.
- Experimental modules do not become implicit dependencies of stable paths.
- User-facing recommendations explain expected trade-offs and uncertainty.

## Changes and review

- Keep changes focused and document unresolved questions before implementing invasive behaviour.
- Add verification for parsers, policy rules, compatibility gates, and rollback paths when implementation code exists.
- Do not commit private experiment output or machine-specific identifiers.
- Update the relevant module specification when a new source, limitation, or result changes a claim.
- For benchmark reports, include repeat count, trial order, task completion time, measurement method, conditions, and confounders.
