# Thunderbolt, USB, and PCIe Efficiency Research Specification

## Goal

Identify how attached devices, display links, storage activity, and sleep/wake behaviour affect system energy while preserving connectivity and data integrity.

## Scope

Observe the complete device chain: peripheral, cable, dock, display, host controller, PCIe path, and workload. Do not attribute a battery change to the Thunderbolt controller unless the experiment can distinguish it from the attached device and other system activity.

## Read-only research

- Record connected device classes and topology without publishing unique device identifiers.
- Compare idle and controlled I/O with the same peripheral and host workload.
- Record sleep, wake, reconnect, and data-integrity outcomes.
- Inspect supported operating-system diagnostics and power assertions.
- Treat bus power, host-controller energy, link state, and endpoint-device power as separate unknowns.

## Current telemetry boundary

On the validation host, `system_profiler -listDataTypes` lists `SPThunderboltDataType` and `SPPCIDataType`. MacLean's doctor command reads a privacy-filtered topology count from the Thunderbolt inventory; this is an inventory snapshot, not a runtime sampler.

The installed `powermetrics(1)` manual documents an `interrupts` sampler with per-CPU interrupt frequencies and device labels, and an Intel `cpu_power` sampler with package and per-core C-state residency. MacLean now parses the target text format and emits per-label interrupt rates summed across logical CPUs. The label remains an opaque OS abbreviation: it does not measure controller power or prove that the controller caused a package idle exit. Package-power readings are estimates from Intel's energy model, not a substitute for battery discharge measurements.

An explicitly authorized three-sample capture on the target OS build reported 0% package C-state residency in every roughly five-second sample, with active CPU/GPU fields and an average of about 3.1–3.5 active cores. It also included interrupt labels such as `IGPU`, `IOBC`, `ANS2`, and `ARPT`, but no Thunderbolt-specific label. This was a short, busy diagnostic capture, not an idle baseline; it neither identifies the source of activity nor proves that Thunderbolt produced no interrupts outside those windows. `IOBC` is not mapped to Thunderbolt.

Apple's public PCIDriverKit documentation describes `IOPCIDevice` as a provider passed to a custom PCI driver's `IOService` subclass and includes device power-management and ASPM methods. That is a driver development interface for matching PCI hardware, not a general app-level API for observing a built-in Thunderbolt host controller. The reviewed public documentation does not establish a supported MacLean user-space source for live controller/link power state. Do not infer such a source from private IOKit classes or undocumented registry properties. See [PCIDriverKit](https://developer.apple.com/documentation/pcidriverkit) and [IOPCIDevice](https://developer.apple.com/documentation/pcidriverkit/iopcidevice).

The next evidence step is a quiet, structured diagnostic session and an overhead check before using privileged sampling in repeated battery benchmarks. Keep raw output local and avoid process/task samplers for this experiment. If no interrupt source can be associated reliably with a selected peripheral, report that limitation and continue comparing whole-system battery energy without attributing a cause.

## PCIe ASPM and power gating

PCIe Active State Power Management and controller power-gating behaviour are coordinated across hardware, firmware, drivers, and OS power policy. Apple PCIDriverKit provides power-management and ASPM methods to custom PCI device drivers, but this does not establish an app-level control for MacLean or availability for a built-in host controller. A visible link or device property is not evidence that MacLean has a supported control path. Do not write PCIe configuration space, change undocumented NVRAM settings, unload drivers, or force controller suspension.

The ASPM, deep-idle, and power-gating directories are research-only and disabled by default. A DriverKit approach would require a separate proposal covering supported macOS versions, signing and user approval, device matching, failure modes, independent recovery, and effects on sleep/wake and attached storage before any prototype.

## Experiment outline

Use a baseline with no external device, then one device at a time. Keep display layout, workload, battery state, and network conditions matched. Record device class, link arrangement, OS version, transfer bytes, completion time, and wake/sleep events. Repeat each condition. Never hot-unplug active storage as an experimental intervention.

## Safety invariants

- Do not interrupt active writes or mounted filesystems.
- Do not disable a controller or port.
- Do not prevent charging or disconnect required peripherals.
- Do not alter sleep policy as a side effect.
- Keep user-directed disconnect and recovery available.
- Stop if wake, reconnect, charging, or data integrity differs from the baseline.

## Open questions

- Which Intel Mac models expose useful public topology or link-state information?
- Can host-controller power be measured independently from the device?
- Which device classes alter package sleep residency or wake frequency?
- Does macOS expose any documented control for runtime power management of these controllers?
- What is the measurement uncertainty of battery discharge during low-power peripheral trials?

## References

- [Apple PCIDriverKit](https://developer.apple.com/documentation/PCIDriverKit)
- [Apple IOPCIDevice power-management methods](https://developer.apple.com/documentation/pcidriverkit/iopcidevice)
