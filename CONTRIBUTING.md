# Contributing to MacLean

MacLean is an evidence-first research project. Contributions should improve measurement quality, reproducibility, safety, or clearly scoped functionality.

## Before opening an issue

- Search existing issues and discussions.
- Include the exact Mac model, CPU/GPU, macOS version/build, and relevant firmware details.
- Describe the observed behaviour and how it was measured.
- Separate observations from hypotheses.

## Experiment reports

Where possible, include:
- Hardware and OS configuration
- Battery health / full-charge capacity, if relevant
- Workload and exact reproduction steps
- Power mode, display brightness, network state, and attached peripherals
- Sampling method, interval, and duration
- Repeated trial results and variability
- Performance or task-completion time
- Known confounders and limitations

Do not publish personal data, serial numbers, or other device identifiers.

## Code expectations

- Prefer read-only telemetry initially.
- Keep hardware-specific code isolated behind explicit capability checks.
- Never silently apply power-management changes.
- Document privilege requirements and rollback behaviour.
- Handle unavailable telemetry as unavailable; do not substitute guessed values.
- Avoid busy polling and high-frequency sampling that materially changes the workload.
- Add tests for parsing, policy decisions, and safety guards.

## Safety

Contributions that write undocumented MSRs, alter firmware, disable thermal protections, bypass security controls, or force voltage changes are out of scope for the initial project phase. Discuss a research proposal before implementing potentially hazardous controls.

## Pull requests

Keep changes focused. Explain the problem, design, test evidence, supported hardware, limitations, and any user-visible effects.
