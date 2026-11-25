# MacLean

**Less power. More potential.**

MacLean is an experimental energy-efficiency and hardware-research project for Intel-based Macs. It investigates how to measure system energy use, understand hardware behaviour, and eventually evaluate safe, reversible power policies.

> **Status:** Early research. No battery-life improvements are claimed. The initial work is hardware discovery and read-only observation.

## Principles

- Measure before changing anything.
- Compare energy per completed task alongside latency, thermals, and responsiveness.
- Treat unavailable data as unavailable; never fill gaps with guessed values.
- Prefer macOS-managed scheduling and documented interfaces.
- Keep hardware-specific and experimental work isolated.
- Make no system changes without capability checks, explicit user action, and a documented rollback.
- Keep collection local, infrequent, and low overhead.

## First step

Run the one-shot, read-only capability report on a Mac:

    swift run maclean doctor

Use swift run maclean doctor --json for structured output. The command reports selected model, CPU, memory, graphics, OS, battery, thermal state, and available native tools when exposed. It does not print serial numbers, save a report, invoke privileged samplers, or change settings. The output is a capability inventory, not a benchmark or a component-power measurement. A shell-only fallback remains at interfaces/cli/maclean-discover.sh.

Collect a short telemetry sample as JSON Lines with `swift run maclean monitor --interval 5 --count 12`. The monitor runs only while invoked, prints to stdout, and does not save or upload data. It reports the OS build and non-unique host model context, Mach CPU utilization after the first counter interval, `pmset` battery status, and Foundation's coarse thermal state. Each record includes collection wall time and process/child CPU time. Unsupported or unvalidated measurements remain unavailable; the command never requests administrator privileges.

Run repeated baselines with `swift run maclean benchmark run --scenario desktop-idle --repetitions 3 --output /private/tmp/maclean-idle.json`. Results include native signed battery current and voltage when available, derived discharge watts and integrated watt-hours only with valid coverage, metric provenance, repeat variation, and MacLean's collector overhead. The benchmark does not start the workload or change system settings. See [benchmark instructions](benchmarks/README.md) and [IOKit telemetry research](docs/research/iokit-telemetry.md).

## Architecture map

- core/ — policy, scheduling concepts, profiles, and capability contracts
- modules/ — independently scoped CPU, memory, graphics, Thunderbolt, background, thermal, network, and storage research
- experimental/ — disabled-by-default T2, PCIe ASPM, deep-idle, and power-gating investigations
- telemetry/ — battery, powermetrics, sensors, and reporting
- platform/ — Intel, Apple T2, and macOS-specific adapters
- safety/ — compatibility, watchdog, and rollback requirements
- benchmarks/ — baselines, repeatable workloads, and reviewed results
- interfaces/ — CLI, GUI, and future daemon boundaries
- tests/ — unit, integration, and regression verification
- docs/ — architecture, roadmap, and research specifications

Research and control directories remain scaffolding until a module has an evidence-backed implementation. The current Swift 6 package separates shared telemetry contracts, macOS collectors and adapters, and the CLI. The contracts and module boundaries remain language-independent.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)
- [Research overview and source catalogue](docs/RESEARCH.md)
- [Read-only telemetry specification](docs/TELEMETRY.md)
- [CPU research specification](docs/modules/cpu.md)
- [Background scheduling specification](docs/modules/background.md)
- [Graphics research specification](docs/GRAPHICS.md)
- [Thunderbolt and PCIe specification](docs/THUNDERBOLT.md)
- [T2 research track](docs/T2.md)
- [Memory specification](docs/modules/memory.md)
- [Thermal specification](docs/modules/thermal.md)
- [Network specification](docs/modules/network.md)
- [Storage specification](docs/modules/storage.md)
- [Contributing](CONTRIBUTING.md)
- [Development principles for Codex and contributors](AGENTS.md)

The initial target described in the research notes is a 2019 16-inch Intel MacBook Pro with a Core i9 and Radeon Pro 5500M. Confirm its exact model identifier, CPU SKU, OS build, and battery condition on the test machine before drawing model-specific conclusions. Do not publish serial numbers or other unique device identifiers.

MacLean is not affiliated with or endorsed by Apple or Intel. See [LICENSE](LICENSE).
