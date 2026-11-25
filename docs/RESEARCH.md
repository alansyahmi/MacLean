# Research Overview

## Research rule

Start with Apple documentation and locally installed macOS manuals, then inspect open-source implementations to learn about real hardware coverage and failure handling. A project README is evidence of its own design, not proof that every metric is correct or supported on MacLean's target. Verify source code, license, OS version, metric provenance, and target hardware before adopting an implementation.

All findings below are hypotheses or interface notes until reproduced on the exact Intel Mac and macOS build.

## Native macOS capabilities

### Work scheduling and energy

Apple's Energy Efficiency Guide recommends allowing work to become idle, minimizing timers and unnecessary wakeups, batching work, and using system scheduling. NSBackgroundActivityScheduler provides flexible, low-priority scheduling for an application's own deferrable work. QoS expresses relative importance to the scheduler; it is not a mechanism for globally downgrading unrelated applications.

App Nap, timer coalescing, and automatic graphics switching are system policies. MacLean should observe their behaviour and avoid fighting them with constant overrides.

### Telemetry

- The host CPU statistics interface can support utilization deltas. It does not report energy or guarantee a useful C-state view.
- IOKit power-source APIs expose operating-system battery status and estimates. A battery remaining-time estimate is not a calibrated power meter.
- ProcessInfo exposes a coarse thermal state and a notification when that state changes. It does not promise exact die temperature.
- powermetrics can report CPU activity, wakeups, and hardware-dependent counter data. Its available samplers and access requirements vary with hardware and macOS. Consult the local powermetrics(1) manual each time platform support is added.
- Activity Monitor, Instruments, and Apple's energy diagnostics are useful reference tools. Their composite energy-impact displays should not be reverse-engineered into a purported physical watt value.

### Controls

Documented APIs for an app's own QoS, discretionary tasks, and timers are distinct from system-wide controls. The reviewed public documentation does not identify a general app-level interface for setting CPU C-states, voltage, package power limits, or arbitrary device power gates. Apple PCIDriverKit exposes power-management and ASPM methods to custom PCI device drivers, but that is not a general user-space control for MacLean or proof that an internal controller is available to a third-party driver. No control should be inferred from an observable property or a tool that can inspect a value.

### Intel CPU facts

The target description is consistent with an Intel Core i9-9980HK, but the workspace inventory did not expose the CPU name or model identifier. Intel's product specification lists that SKU as an 8-core, 16-thread mobile processor with Speed Shift and idle-state support. This establishes silicon capability only; it does not establish which counters or controls macOS exposes on the target.

## Open-source prior art reviewed

### MacPulse

[MacPulse](https://github.com/vluncasu/macpulse) documents a read-only monitor for Intel and Apple Silicon Macs. It describes CPU utilization from public Mach host statistics and GPU fields from IORegistry properties published by drivers. Its Intel/AMD support and explicit unavailable states are useful design references. Driver-published GPU properties are hardware- and OS-dependent and must not be treated as a stable cross-model contract.

### Gauge

[Gauge](https://github.com/lightwaslost/gauge) describes a native macOS monitor using Mach CPU/memory statistics, IOKit battery and storage sources, and IOAccelerator GPU utilization where reported. Its source map and unavailable handling are useful examples of decomposing collectors by data source. Its documented version requirements and features must be checked against MacLean's target before reuse.

### Better Mac Stats

[Better Mac Stats](https://github.com/ariwisnu/better-mac-stats) describes a small native monitor targeting both Apple Silicon and Intel, with conditional handling for absent sensors. It is a useful reference for keeping platform data readers separate from presentation. Its compatibility claims are project-specific and do not establish that all Intel Macs expose the same SMC or graphics fields.

These projects are research references, not dependencies selected for MacLean. Do not copy code without reading the relevant source and license.

## Target-specific unknowns

1. Exact Mac model identifier and CPU SKU.
2. macOS product version, build, firmware, and available powermetrics samplers.
3. Whether the CPU exposes usable residency or frequency data on this system.
4. Which GPU activity properties the installed Intel and AMD drivers publish.
5. Which battery counters are stable enough for repeated short experiments.
6. The effects of display configuration, external devices, and power source on graphics and Thunderbolt behaviour.
7. Whether any candidate control has a documented, supported, reversible interface.
8. Whether T2 research can be performed without compromising boot integrity or device security.

## Source catalogue

- [Apple Energy Efficiency Guide: Best Practices](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/BestPractices.html)
- [Apple Energy Efficiency Guide: Monitor Usage Regularly](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/MonitoringEnergyUsage.html)
- [Apple Energy Efficiency Guide: Extend App Nap](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/AppNap.html)
- [Apple Energy Efficiency Guide: Prioritize Work at the Task Level](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/PrioritizeWorkAtTheTaskLevel.html)
- [Apple NSBackgroundActivityScheduler](https://developer.apple.com/documentation/foundation/nsbackgroundactivityscheduler)
- [Apple ProcessInfo thermalState](https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.property)
- [Apple IOPSGetTimeRemainingEstimate](https://developer.apple.com/documentation/iokit/1523835-iopsgettimeremainingestimate)
- [Apple host_cpu_load_info_t](https://developer.apple.com/documentation/kernel/host_cpu_load_info_t)
- [Apple IOPM assertions](https://developer.apple.com/documentation/iokit/iopmassertiontypes)
- [Apple Metal multi-GPU rendering guidance](https://developer.apple.com/documentation/metal/selecting-device-objects-for-graphics-rendering)
- [Apple Intel multi-GPU and display assessment](https://developer.apple.com/documentation/metal/assessing-multi-gpu-and-multi-display-setups-on-an-intel-based-mac)
- [Apple NSSupportsAutomaticGraphicsSwitching](https://developer.apple.com/documentation/bundleresources/information-property-list/nssupportsautomaticgraphicsswitching)
- [Apple PCIDriverKit](https://developer.apple.com/documentation/PCIDriverKit)
- [Apple IOPCIDevice power-management methods](https://developer.apple.com/documentation/pcidriverkit/iopcidevice)
- [Apple hardware security overview](https://support.apple.com/guide/security/hardware-security-overview-secf020d1074/web)
- [Apple boot process for an Intel-based Mac](https://support.apple.com/guide/security/boot-process-for-an-intel-based-mac-sec5d0fab7c6/web)
- [Apple: Mac computers with the T2 Security Chip](https://support.apple.com/en-us/103265)
- [Intel Core i9-9980HK specifications](https://www.intel.com/content/www/us/en/products/sku/192990/intel-core-i99980hk-processor-16m-cache-up-to-5-00-ghz/specifications.html)
- [Intel 8th/9th Generation Core processor datasheet](https://cdrdv2-public.intel.com/337344/337344_8th-gen-core-family-datasheet-vol-1_Rev009.pdf)
- [MacPulse source repository](https://github.com/vluncasu/macpulse)
- [Gauge source repository](https://github.com/lightwaslost/gauge)
- [Better Mac Stats source repository](https://github.com/ariwisnu/better-mac-stats)

The online Apple Energy Efficiency Guide is archived documentation. Confirm current SDK availability, deprecations, and deployment support against the installed SDK before implementation.
