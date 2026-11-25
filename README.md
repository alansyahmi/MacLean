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

Empty implementation directories are intentional scaffolding. The repository initially had no source code or build system. The first CLI now uses Swift 6 and Swift Package Manager to call native macOS tools and Foundation; the core contracts and module boundaries remain language-independent.

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
