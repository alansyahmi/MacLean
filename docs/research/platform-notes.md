# Intel Mac Platform Research Notes

These notes provide initial target context only. The current subsystem specifications and source catalogue are maintained in [Research](../RESEARCH.md), [CPU](../modules/cpu.md), [Graphics](../GRAPHICS.md), [Thunderbolt](../THUNDERBOLT.md), and [T2](../T2.md).

These notes describe research questions, not guaranteed capabilities. Verify every item against the exact machine and macOS build.

## CPU

The target machine is a 2019 16-inch Intel MacBook Pro with a Core i9. The precise processor SKU must be confirmed from the running system before model-specific assumptions are made.

Research areas include Intel Speed Shift / hardware-managed P-states (if supported and exposed), Turbo Boost behaviour, core and package C-state residency, thermal and package power limits, hyper-threading behaviour under representative workloads, and wakeups/interrupt activity.

Do not assume macOS exposes a supported interface for changing these settings.

## GPU

The target configuration includes an AMD Radeon Pro 5500M discrete GPU. Investigate when the discrete GPU is activated, which applications or display configurations require it, whether external displays change GPU residency, available GPU telemetry, and the impact of graphics workloads on total system energy.

Avoid disabling graphics devices or drivers through unsupported methods.

## Thunderbolt and USB

Investigate attached-device wakeups, external storage activity, bus-powered peripherals, external display effects, and sleep/wake behaviour and power assertions.

Distinguish device power from host-controller and display power. A single observed battery change cannot isolate the contribution of a Thunderbolt link.

## Apple T2 Security Chip

The T2 is a security and system-management coprocessor with its own firmware environment. It should not be treated as a general-purpose application processor available to ordinary macOS software.

Research questions:
- What telemetry or management functions are legitimately exposed to macOS?
- What development and debugging interfaces exist for supported research?
- Is any narrowly scoped offload experiment technically feasible?
- Would communication and integration energy outweigh any potential benefit?

Do not assume the T2 can run arbitrary macOS applications or provide a practical Safari/runtime offload path. Any T2 work is a separate exploratory track and must not compromise device security or boot integrity.

## General caveat

Apple firmware, macOS power management, and hardware capabilities vary across model generations. All conclusions must be tied to a precise hardware and software configuration.

## Workspace discovery snapshot — 2026-11-25

The read-only inventory in the Codex workspace reported x86_64, macOS 26.7.3 build 25G342, an 8-core 2.4 GHz CPU, 64 GB memory, Intel UHD Graphics 630, and AMD Radeon Pro 5500M with 4 GB VRAM. The model identifier and processor name were unavailable; sysctl hardware fields and the CPU/memory summary were blocked by the execution environment. These observations are consistent with the stated target but do not confirm the exact Mac model or CPU SKU. Refresh this inventory on the target machine before treating it as a benchmark baseline. No unique device identifiers were recorded.
