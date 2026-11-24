# MacLean Architecture Overview

## 1. Architectural objective

MacLean should evolve from a read-only measurement toolkit into a user-controlled optimisation framework. Its architecture must preserve a strict boundary between observing the machine, deciding what might help, and changing hardware or operating-system behaviour.

## 2. Logical components

### Telemetry engine

Collects available measurements such as CPU utilisation and load, frequency information where exposed, thermal pressure and temperatures where available, power assertions and wakeup activity, battery state and discharge estimates, GPU activity, and peripheral/I/O activity indicators.

Each measurement carries a source, timestamp, unit, sampling interval, and quality/availability status. The engine must not imply that a metric is a direct hardware measurement when it is only an OS estimate.

### Experiment runner

Runs repeatable workloads and records machine/OS configuration, power mode and environmental conditions, workload definition and version, timestamps, task completion time, telemetry samples, and measurement gaps.

### Workload classifier

The initial classifier can use explicit user-selected workload labels. Automatic classification should come later and must be explainable. Candidate classes include idle, browsing, development, compilation, rendering, and sustained compute.

### Policy engine

Evaluates a candidate profile against current workload and system state. Early versions operate in simulation or recommendation-only mode. The policy engine must use hysteresis and minimum dwell times to avoid rapid profile oscillation.

### Hardware abstraction layer

Contains platform-specific capability detection and validated controls. It must reject unsupported operations, record every requested change, and provide a rollback path. No direct hardware control is enabled merely because a register or interface appears accessible.

### User interface

A native macOS interface should make current state, data quality, active profile, experiment history, and pending changes visible. The user remains in control of applying changes.

### Experiment store

A local SQLite database is the planned initial store. Raw logs can be retained separately when appropriate. Measurements unavailable on a given system should be NULL or explicitly marked unavailable.

## 3. CPU policy concepts

The Intel CPU research track investigates idle-state residency and package sleep behaviour; wakeups, timers, and interrupt sources; hardware-managed frequency selection (including Intel Speed Shift where supported); Turbo Boost behaviour; thermal and power-limit behaviour; and workload-aware scheduling and deferral of non-urgent work.

The goal is not to force the CPU to remain at the lowest frequency. The key outcome is energy consumed per completed task, considered alongside latency and thermal behaviour.

## 4. Apple Silicon-inspired ideas

MacLean may adapt high-level principles such as workload-aware power budgets, rapid return to idle after bursts of work, deferring non-urgent background work, reducing unnecessary wakeups, balancing responsiveness against energy use, and measuring performance per watt.

These are design inspirations, not claims that Intel hardware has Apple Silicon's heterogeneous CPU topology or identical operating-system scheduling mechanisms.

## 5. Security and safety model

- Read-only by default.
- No kernel extension in the initial milestones.
- No firmware modification.
- No undocumented MSR writes in the initial milestones.
- No voltage manipulation or disabling of thermal protections.
- Privileged operations, if ever introduced, require explicit consent and narrowly scoped helpers.
- All controls must have capability checks, audit logs, and rollback behaviour.

## 6. Proposed implementation stack

- Swift and SwiftUI for the native macOS application.
- Swift modules for telemetry, policy, and hardware abstraction.
- SQLite for experiment metadata and time-series samples.
- Swift Charts for visualisation.
- Small command-line benchmark harnesses for repeatable workloads.
- Python may be used for offline analysis and plotting, not as a privileged always-running daemon by default.

## 7. Initial module boundaries

- Module 01: GPU Efficiency
- Module 02: Peripheral Efficiency (Thunderbolt / USB)
- Module 03: CPU Efficiency
- Research track: T2 Coprocessor

Modules should share experiment metadata and telemetry interfaces without assuming that every hardware subsystem exposes equivalent observability or control.
