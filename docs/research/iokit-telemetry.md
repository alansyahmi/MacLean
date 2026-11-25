# Read-only IOKit telemetry research

## Battery electrical readings

MacLean uses Apple's public `IOPowerSources` copy/list/description accessors first and reads only the allowlisted `Type`, `Is Present`, `Voltage`, `Current`, `Power Source State`, and `Is Charging` fields from a present internal battery. If voltage or current is missing, it falls back to the documented `IOPMPowerSource` registry interface: match the generic class, require exactly one service with `BatteryInstalled == true`, and request only the scalar `Voltage` and/or `Amperage` property through `IORegistryEntryCreateCFProperty`. It never copies or serializes the full registry property table. If the service is ambiguous, absent, or returns a nonnumeric value, the metric remains unavailable. Apple's installed IOKit headers define IOPS voltage/current as signed integer mV/mA; IOPMPowerSource documents voltage as unsigned mV and amperage as signed mA. The fallback source is recorded separately for each metric.

The monitor exposes the raw signed current in amperes and voltage in volts when published. It derives signed electrical power as:

```text
power_W = voltage_mV × signed_current_mA / 1,000,000
```

The sign convention is retained as supplied. MacLean derives a positive discharge-power magnitude only when the source state is `Battery Power`, `Is Charging` is false, and both inputs are present. Benchmark watt-hours use trapezoidal integration over monotonic sample offsets, and require at least 95% coverage of the run. This keeps charging, AC use, missing readings, and long gaps from being presented as battery discharge.

On the target Intel Mac, the generic IOPMPowerSource match returned one installed battery service. A live read-only sample confirmed the per-property voltage fallback works while IOPS omitted voltage. A 15-minute real-use capture and later release samples showed IOPowerSources reporting `Battery Power`, not charging, and a negative signed current while `pmset -g batt` reported `AC Power`. MacLean retains both observations and derives discharge power only from the IOPowerSources battery state and signed electrical readings. The repeated disagreement remains unresolved; record both source states and do not treat an affected trial as a confirmed whole-system battery baseline until the source semantics or physical power condition are established. The first 15-minute run used the earlier release and therefore had no integrated energy coverage; a subsequent run achieved full energy coverage, but its normal-use workload is not an idle baseline. Apple does not document a freshness interval for registry values, so readings are timestamped at collection time without claiming an underlying driver-update age. No raw registry output, process names, or device identifiers are retained.

Apple's API docs say clients should obtain descriptions through accessor functions rather than reading the opaque IOPS snapshot directly. The installed `IOPSKeys.h` describes voltage/current fields and their units, and cautions that individual dictionary keys may be absent. IOPMPowerSource documents the registry property names, types, and units; it does not specify how recently each driver value was updated. See [IOPowerSources API](https://developer.apple.com/documentation/iokit/1523839-iopscopypowersourcesinfo), [IOPowerSources.h](https://developer.apple.com/documentation/iokit/iopowersources_h), and [IOPM power source overview](https://developer.apple.com/documentation/kernel/iopmpowersource).

## Optional powermetrics collection

The local `powermetrics(1)` manual and installed help list `tasks`, `interrupts`, `cpu_power`, and `gpu_power` samplers. The manual describes CPU activity, frequency distribution, package C-state statistics, and hardware-dependent power estimates. It says Intel `cpu_power` values come from the Intel energy model, are proprietary estimates, and are generally not comparable between machine models. The `battery` sampler can report battery discharge rates, but its values may be out of phase with sample intervals and can be inaccurate across sleep/wake or AC connection changes. The `interrupts` sampler provides device interrupt evidence, not proof of a Thunderbolt controller power state. Help text was inspected without starting a sampler. A bounded no-prompt authorization attempt found no cached administrator authorization and exited before powermetrics started; no privileged output was collected.

MacLean's backend is disabled by default. The `--powermetrics` option requires the CLI process to already be running as root and invokes `/usr/bin/powermetrics` directly for one 1-second sample per requested benchmark interval. It does not call `sudo`, open an authorization prompt, or change any state. This puts the whole explicitly launched CLI process in a privileged context; the mode is for deliberate diagnostics only. The Intel text parser recognizes average frequency, total package C-state residency, and package power. Package power is labeled `osEstimate`. Frequency distribution, individual C-state bins, interrupts, and task wakeup attribution remain unavailable until representative output from the exact target OS is captured in a separately authorized session, reviewed, and covered by parser fixtures. CPU package power remains an estimate for the processor package and must not be labeled whole-system power.

## GPU activity and power properties

Apple's IOKit APIs provide registry matching and property snapshots, but do not document a cross-model contract for GPU-active status, switching state, or watts. The MacLean collector matches `IOAccelerator` services, reads only the `PerformanceStatistics` dictionary, and extracts the allowlisted `Device Utilization %` number. It discards the rest of that property value immediately and never serializes a raw registry tree. The metric is labeled as driver-published because its key and semantics are not an Apple API contract. Open-source monitors such as [MacPulse](https://github.com/vluncasu/macpulse) also report this property as driver-dependent GPU utilization and describe gaps across devices and versions; this supports investigating the field, not treating it as a stable interface.

An exploratory read on the target x86_64 Intel Mac, macOS 26.7.3 build 25G342, matched two accelerator services. The Intel driver exposed a numeric `Device Utilization %` value; the AMD driver did not expose that key in the same read. This confirms the collector's allowlist works on one driver and that missing data must remain unavailable. It was one sample during normal computer use, not a controlled workload or energy result. The driver's update window and freshness are undocumented.

MacLean emits utilization under a driver-class-specific metric name and derives `graphics.activity_observed` only from values greater than zero. If a driver publishes multiple matching services of the same class, the highest valid value is reported for that class because the registry does not provide a validated stable per-device identity for this collector. The activity summary lists classes with reported work and calls out classes whose utilization is unavailable. This describes driver-reported work observed at collection time; it does not establish that the device is powered, selected as the display GPU, or drawing a particular amount of power. `graphics.active_device`, `graphics.power_state`, and `graphics.power` remain unavailable. GPU inventory from System Profiler remains separate from activity and power-state observations.

Reference interfaces: [IORegistryEntryCreateCFProperty](https://developer.apple.com/documentation/iokit/1514293-ioregistryentrycreatecfproperty), [IORegistryEntry](https://developer.apple.com/documentation/kernel/ioregistryentry), and [IOServiceGetMatchingServices](https://developer.apple.com/documentation/iokit/1514494-ioservicegetmatchingservices). These APIs describe mechanisms for reading/matching registry entries, not GPU telemetry semantics.

## Thunderbolt topology and power state

`system_profiler`'s `SPThunderboltDataType` is an on-demand inventory source. Its current JSON output exposed controller and receptacle records; MacLean stores only their counts. It does not establish that an idle controller is suspended or expose a validated controller wattage. Public IOKit service enumeration can expose matching service properties, but no stable, documented property has been validated for Thunderbolt runtime power, PCIe ASPM, or controller power-gating state on the Intel target.

MacLean therefore reports topology counts separately from telemetry and leaves controller power unavailable. It does not query private driver keys, infer state from a missing device, or change controller, PCIe, or peripheral settings. `system_profiler` JSON is an OS-maintained inventory format rather than a stable IOKit telemetry contract; unrecognized or missing schema is reported as unavailable. Further work should capture only a small allowlist after the target model/OS and property owner are identified; connectivity and sleep/wake behaviour must remain part of any later study.

## Open questions

1. Does the exact Intel target publish a fresh, consistent battery voltage throughout repeated battery trials, and how much time alignment error exists between IOPowerSources and IOPMPowerSource reads?
2. Does the generic signed Amperage fallback agree with IOPowerSources current during repeated discharge sessions?
3. Which exact `powermetrics` fields and samplers are available on the target's OS build, and which require root? Can task names and wakeups be parsed without retaining unrelated process details?
4. How frequently is the target driver's utilization value updated, and does its meaning remain stable across OS and driver versions? Is there any documented cross-model power-state source?
5. Can Thunderbolt controller state be observed through a public, stable interface without driver-specific undocumented keys?
6. What collection cadence provides adequate resolution without changing idle wakeups or battery drain? E005's single AC pass shows collector cost falls at coarser intervals, but repeat and battery trials are needed.

## Sources reviewed

- Apple's IOPowerSources public API and installed IOKit headers for field types and units.
- The installed `powermetrics(1)` manual for sampler behavior and estimate caveats.
- [MacPulse](https://github.com/vluncasu/macpulse) and [Gauge](https://github.com/lightwaslost/gauge) as examples of GPU activity-property coverage varying by device/driver; neither is treated as an API contract.
- Apple's IOKit registry APIs for enumeration mechanics, not for undocumented property meaning.
