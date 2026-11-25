# MacLean Architecture

## Purpose and status

MacLean is a research framework for measuring and evaluating energy-efficiency ideas on Intel Macs. Its first deliverables are inventory, read-only telemetry, and reproducible experiments. It does not currently implement system-changing controls.

The repository had no source code, package manifest, or build system when inspected. Component contracts therefore stay language-independent. The one-shot shell inventory is an operator tool, not a framework runtime decision.

## System boundary

MacLean observes the machine and, in later phases, may recommend or apply narrowly scoped policies after the user approves them. macOS, firmware, the System Management Controller, CPU microcode, graphics drivers, and peripheral firmware remain the owners of their respective safety and power-management decisions. MacLean must not claim authority over a control it cannot observe or reverse.

Initial data flow:

1. A platform adapter discovers the host and the interfaces it appears to support.
2. Read-only collectors produce timestamped observations with provenance and quality.
3. A normalizer maps observations into common metric records without inventing values.
4. An experiment runner records the workload and conditions alongside those records.
5. A policy engine may simulate or recommend an action; it cannot silently write settings.
6. A safety gate validates compatibility, reversibility, and the user's explicit request before any future control path.

The initial CLI runs on demand. There is no background daemon, launch agent, continuous poller, database, or network service.

## Component responsibilities

### Core

- Policy evaluates a profile against workload class, power source, thermal condition, and capability state. Early operation is simulation or recommendation only.
- Scheduler describes MacLean's own collection and research work. It must yield, batch, and prefer system-managed deferral where a native API supports it.
- Profiles define intent and constraints, not machine-specific register values. Every profile has a stable identifier, supported capability set, and explanation.
- Hardware contains capability records and normalized platform facts. Discovery is separate from control.

### Modules

Each module owns its questions, collector inputs, confidence limits, benchmark workloads, and eventual control proposal. Modules communicate through shared telemetry and capability contracts. A module may report unsupported or unavailable without blocking others.

CPU, memory, graphics, Thunderbolt, background work, thermal behaviour, networking, and storage have separate research specifications. A module is not permission to alter that subsystem.

### Experimental area

T2 offload, PCIe ASPM, deep-idle controls, and power gating are isolated research tracks. They are disabled by default, excluded from normal profiles, and must not be imported by stable modules as implicit dependencies.

### Telemetry

Collectors are read-only and return observations rather than presentation strings. A metric includes:

- stable metric name and unit;
- value, or an explicit unavailable state;
- source interface and method;
- observed-at timestamp and sampling window;
- quality such as direct, derived, operating-system estimate, stale, unsupported, or failed;
- host capability and OS-build context needed to interpret it;
- optional uncertainty or notes.

The schema must distinguish a measured zero from missing, unsupported, stale, or invalid data. A battery discharge estimate is not CPU package power. CPU utilization is not energy. A metric whose source changes meaning between OS releases needs a versioned adapter or a visible quality downgrade.

### Platform adapters

The macOS adapter uses supported system APIs and tools where their semantics are understood. The Intel adapter reports CPU-family-specific facts and never assumes all Intel Macs expose the same counters. The Apple T2 adapter remains a research boundary, not a general-purpose compute provider.

### Safety

Compatibility gates, user consent, action audit records, watchdogs, and rollback are independent of the module proposing an action. A collector cannot gain write access by sharing a module with a future controller.

### Benchmarks and storage

An experiment records the machine class, OS build, battery condition if available, power source, workload revision, environment, instrumentation, trial order, task time, energy indicator, thermal response, and confounders. Personal identifiers and serial numbers are excluded. The initial persistence choice is deliberately open; a local append-only data format or SQLite can be selected after the first telemetry prototype establishes query needs.

## Native macOS boundary

The design prefers existing macOS behaviour and public interfaces:

- Use host-level CPU statistics for utilization and available Foundation/IOKit APIs for system state.
- Use battery power-source APIs for battery status and estimates, while clearly marking estimates.
- Use ProcessInfo thermal state as a coarse system signal, not as a per-die temperature.
- Use NSBackgroundActivityScheduler, discretionary work, QoS, and flexible timers for MacLean's own work. These mechanisms do not let MacLean reschedule arbitrary applications globally.
- Treat App Nap and system graphics switching as OS-managed. Measure their effects before proposing policy.
- Use powermetrics only after checking the local manual, supported samplers, privilege requirements, and the exact macOS version. Its estimated power values are not a substitute for external measurement or a cross-device ground truth.
- Use Activity Monitor, Instruments, and the system's own energy diagnostics as reference tools rather than reimplementing private energy-impact calculations.
- Apple PCIDriverKit includes power-management and ASPM methods for custom PCI device drivers. That driver-development surface is not a general app-level switch for system policy or built-in controllers; any DriverKit proposal needs its own compatibility, security, privilege, and rollback review.

No undocumented SMC keys, private IOReport channels, undocumented MSR writes, firmware edits, forced voltage changes, thermal-protection bypasses, or security-policy weakening are part of the initial architecture. DriverKit is not selected for the initial read-only phase.

## Sampling and overhead

Every collector documents expected cost, cadence, permissions, and the sleep/wake behaviour of its source. Collection is on-demand or event-driven first. A visible UI may use a bounded, adaptive cadence, but the closed or idle product should return to near-zero work. No sub-second or busy polling is allowed without evidence that it is necessary and that its own energy cost is acceptably small.

When values cannot be collected safely or accurately, the interface reports unavailable with a reason. It does not fall back to scraping private data or guessing from unrelated counters.

## Policy lifecycle

Future controls, if justified, move through this sequence:

1. Research hypothesis and source review.
2. Read-only observation and controlled baseline.
3. Offline analysis and policy simulation.
4. Capability-specific proposal with predicted effect and known trade-offs.
5. Compatibility check and explicit user approval.
6. Apply through the narrowest documented interface.
7. Verify the actual postcondition; stop if it differs from the expected state.
8. Watch for performance, thermal, sleep/wake, charging, security, or peripheral regressions.
9. Roll back on timeout, failed verification, user request, or safety threshold.
10. Publish the result with trial count, variation, and limitations.

Failure to demonstrate repeatable benefit means the policy stays disabled or is removed.

## Initial CLI implementation

The repository initially contained only documentation and an MIT license, with no source code or build tooling. The first executable command uses Swift 6 and Swift Package Manager, with Foundation and native macOS command-line tools. This keeps the CLI close to macOS APIs without adding third-party dependencies. This choice does not bind the future UI, daemon, experimental modules, or portable data contracts to Swift.

Revisit the implementation stack if native API coverage, maintenance cost, supported macOS versions, packaging, privilege boundaries, idle overhead, or target-machine validation indicate a better fit.

## Open decisions

- Which oldest macOS release can be supported without relying on private interfaces?
- Which read-only CPU, battery, thermal, GPU, and peripheral metrics exist on the exact target model?
- Can battery energy change be measured with enough repeatability for short trials, or is an external power instrument required?
- Which benchmark workloads and trial lengths are useful without causing unacceptable wear or heat?
- What data should be persisted locally, and for how long?
- Is any user-visible control both supported and independently reversible on target systems?

See [Research](RESEARCH.md), [Telemetry](TELEMETRY.md), and [Roadmap](ROADMAP.md).
