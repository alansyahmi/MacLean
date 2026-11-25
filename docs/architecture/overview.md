# MacLean Architecture Overview

The canonical architecture now lives in [docs/ARCHITECTURE.md](../ARCHITECTURE.md). This file remains as a compatibility link for earlier repository references.

Shared telemetry contracts stay language-independent. The current Swift package separates those records from macOS collectors and the CLI. Read-only discovery and telemetry are the first implementation work; system-changing controls remain out of scope until their interfaces and rollback paths are documented.

Related specifications:

- [Roadmap](../ROADMAP.md)
- [Telemetry](../TELEMETRY.md)
- [Research overview](../RESEARCH.md)
- [CPU](../modules/cpu.md)
- [Graphics](../GRAPHICS.md)
- [Thunderbolt and PCIe](../THUNDERBOLT.md)
- [T2](../T2.md)
