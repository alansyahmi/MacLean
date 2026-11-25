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
