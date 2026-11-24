# MacLean

**Less power. More potential.**

MacLean is an experimental power-optimisation and hardware-research project for Intel-based Macs. It investigates how to improve energy efficiency, reduce unnecessary power consumption, and understand the behaviour of CPU, GPU, Thunderbolt peripherals, and the Apple T2 Security Chip.

The project takes an evidence-first approach: measure first, form hypotheses, run controlled experiments, and only then implement reversible optimisations.

> **Status:** Research / early development. No battery-life improvements are claimed yet.

## Project goals

- Measure real-world energy use and performance under repeatable workloads.
- Understand CPU idle states, frequency management, Turbo Boost, thermal behaviour, and wakeups.
- Investigate discrete-GPU activity and graphics power behaviour.
- Study Thunderbolt, USB, and peripheral-related power costs.
- Explore the T2 as a research target without assuming it can act as a general-purpose macOS coprocessor.
- Build a transparent macOS utility for telemetry, experiments, and eventually safe optimisation policies.

## Research modules

| Module | Focus | Initial direction |
|---|---|---|
| 01 — GPU Efficiency | Discrete GPU activity and graphics power | Observe GPU use, switching, and workload impact |
| 02 — Peripheral Efficiency | Thunderbolt, USB, and attached devices | Identify wakeups, link activity, and peripheral power costs |
| 03 — CPU Efficiency | Intel CPU power and workload management | Idle-state analysis, workload-aware policies, and controlled experiments |
| Research track — T2 | Apple T2 Security Chip | Explore architecture and feasible, safe research interfaces |

## Design principles

1. **Measure before changing.** Establish baselines before tuning.
2. **Prefer energy per task.** Lower frequency is not automatically lower energy.
3. **Respect hardware autonomy.** Avoid fighting firmware and Intel Speed Shift with constant userspace overrides.
4. **Make changes reversible.** Every optimisation must have a documented rollback path.
5. **Keep telemetry honest.** Unsupported measurements are recorded as unavailable, never fabricated.
6. **Minimise privilege.** Start read-only; introduce privileged operations only when justified.
7. **Reproduce results.** Record hardware, OS version, battery condition, workload, environment, and experiment parameters.

## Planned architecture

- **Telemetry layer:** Collects available system and hardware measurements.
- **Experiment runner:** Executes controlled workloads and records their conditions.
- **Workload classifier:** Distinguishes idle, browsing, development, compilation, rendering, and other workload classes.
- **Policy engine:** Evaluates possible power policies with conservative guardrails.
- **Hardware abstraction layer:** Exposes only validated, platform-appropriate controls.
- **macOS interface:** Presents telemetry, experiment history, and user-approved profiles.
- **Experiment store:** Persists measurements and metadata locally.

See [architecture overview](docs/architecture/overview.md), [initial experiment plan](docs/experiments/initial-plan.md), and [platform research notes](docs/research/platform-notes.md).

## Initial research platform

The first target is a 2019 16-inch Intel MacBook Pro with an Intel Core i9 processor, AMD Radeon Pro 5500M, 64 GB RAM, and macOS Tahoe. Exact CPU model, OS build, firmware details, and battery condition must be recorded for each baseline. The project should not assume all Intel Mac models expose the same controls or telemetry.

## Safety boundaries

The initial phase is read-only. MacLean will not begin by:
- writing undocumented model-specific registers (MSRs);
- modifying firmware or boot ROM;
- installing kernel extensions;
- forcing voltage changes or bypassing platform security mitigations;
- disabling thermal protections or safety mechanisms.

Any future control feature must be justified by evidence, documented for supported hardware, guarded by explicit user consent, and paired with rollback instructions.

## Roadmap

- [ ] M0 — Hardware discovery and baseline measurements
- [ ] M1 — Read-only CPU and system telemetry
- [ ] M2 — Experiment database and benchmark runner
- [ ] M3 — Workload classification and policy simulation
- [ ] M4 — Reversible, validated optimisation controls
- [ ] M5 — Native macOS menu-bar application
- [ ] M6 — Long-duration battery and performance validation

## Contributing

Research notes, reproducible measurements, hardware-specific findings, and carefully scoped code contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing changes.

## Disclaimer

MacLean is an experimental research project. It is not affiliated with or endorsed by Apple or Intel. Hardware controls and telemetry vary by model and macOS release. Use experimental software at your own risk.
