# Read-only IOKit telemetry research

## Battery electrical readings

MacLean uses Apple's public `IOPowerSources` copy/list/description accessors and reads only the allowlisted `Type`, `Is Present`, `Voltage`, `Current`, `Power Source State`, and `Is Charging` fields from a present internal battery. It does not serialize the complete power-source dictionary, which may contain identifiers or other unrelated fields. Apple's installed IOKit headers define voltage as a signed integer in millivolts and current as a signed integer in milliamps; both are recommended rather than guaranteed fields. Missing keys remain unavailable.

The monitor exposes the raw signed current in amperes and voltage in volts when published. It derives signed electrical power as:

```text
power_W = voltage_mV × signed_current_mA / 1,000,000
```

The sign convention is retained as supplied. MacLean derives a positive discharge-power magnitude only when the source state is `Battery Power`, `Is Charging` is false, and both inputs are present. Benchmark watt-hours use trapezoidal integration over monotonic sample offsets, and require at least 95% coverage of the run. This keeps charging, AC use, missing readings, and long gaps from being presented as battery discharge.

On the current validation host, IOPowerSources returned a signed current while charging from AC, but did not publish voltage. The current value was positive during that charging observation. This is a single host observation, not validation of the sign convention while discharging. The test host's model and processor strings were unavailable through the current process context, so no target-model claim is made from that observation.

Apple's API docs say clients should obtain descriptions through the accessor functions rather than reading the opaque snapshot directly. The installed `IOPSKeys.h` describes voltage/current fields and their units, and cautions that individual dictionary keys may be absent. See [IOPowerSources API](https://developer.apple.com/documentation/iokit/1523839-iopscopypowersourcesinfo), [IOPowerSources.h](https://developer.apple.com/documentation/iokit/iopowersources_h), and [IOPM power source overview](https://developer.apple.com/documentation/kernel/iopmpowersource).

## Optional powermetrics collection

The local `powermetrics(1)` manual describes CPU activity, frequency distribution, package C-state statistics, and hardware-dependent power estimates. It says Intel `cpu_power` values come from the Intel energy model, are proprietary estimates, and are generally not comparable between machine models. The `battery` sampler can report battery discharge rates, but its values may be out of phase with sample intervals and can be inaccurate across sleep/wake or AC connection changes. The `interrupts` sampler provides device interrupt evidence, not proof of a Thunderbolt controller power state.

MacLean's backend is disabled by default. The `--powermetrics` option requires the CLI process to already be running as root and invokes `/usr/bin/powermetrics` directly for one 1-second sample per requested benchmark interval. It does not call `sudo`, open an authorization prompt, or change any state. This puts the whole explicitly launched CLI process in a privileged context; the mode is for deliberate diagnostics only. The Intel text parser currently recognizes average frequency, package C-state residency, and package power. Package power is labeled `osEstimate`. Wakeup and other output remain unavailable until a representative output from the exact target OS is reviewed and parser fixtures are added.

## GPU activity and power properties

Apple exposes general IOKit registry enumeration and property-copying APIs. Those APIs provide access to a registry snapshot; they do not document a cross-model contract for GPU-active status, switching state, or watts. Existing open-source monitors report reading driver-published IOAccelerator properties, but available keys vary by GPU, driver, and OS. Such a property is evidence of what that driver publishes, not a stable Apple interface. MacLean has not selected a property or implemented GPU sampling. No IORegistry tree or raw accelerator property is collected.

The capability should only move forward if a narrowly allowlisted property can be tied to an Apple-documented key or verified driver/version contract, its meaning and update rate are validated on both integrated and discrete GPUs, and absence is handled as unavailable. GPU inventory from System Profiler remains separate from active-device and power-state readings.

Reference interfaces: [IORegistryEntryCreateCFProperties](https://developer.apple.com/documentation/iokit/1514310-ioregistryentrycreatecfpropertie) and [IOServiceGetMatchingServices](https://developer.apple.com/documentation/iokit/1514494-ioservicegetmatchingservices). These APIs describe mechanisms for reading/matching registry entries, not specific GPU telemetry semantics.

## Thunderbolt topology and power state

`system_profiler`'s `SPThunderboltDataType` is an on-demand inventory source. It can describe host controllers, ports, and attached devices when the current macOS release exposes those fields. It does not establish that an idle controller is suspended or expose a validated controller wattage. Public IOKit service enumeration can expose matching service properties, but no stable, documented property has been validated for Thunderbolt runtime power, PCIe ASPM, or controller power-gating state on the Intel target.

MacLean therefore records Thunderbolt topology separately from telemetry and leaves controller power unavailable. It does not query private driver keys, infer state from a missing device, or change controller, PCIe, or peripheral settings. Further work should capture only a small allowlist after the target model/OS and property owner are identified; connectivity and sleep/wake behaviour must remain part of any later study.

## Open questions

1. Does the exact Intel target publish voltage consistently on battery power, and what current sign does it use while discharging?
2. How much time alignment error exists between IOPowerSources updates and MacLean's requested sample interval?
3. Which exact `powermetrics` fields and samplers are available on the target's OS build, and which require root?
4. Does the target driver expose a documented or supportable active-GPU property?
5. Can Thunderbolt controller state be observed through a public, stable interface without driver-specific undocumented keys?
6. What collection cadence provides adequate resolution without changing idle wakeups or battery drain?

## Sources reviewed

- Apple's IOPowerSources public API and installed IOKit headers for field types and units.
- The installed `powermetrics(1)` manual for sampler behavior and estimate caveats.
- [MacPulse](https://github.com/vluncasu/macpulse) and [Gauge](https://github.com/lightwaslost/gauge) as examples of GPU activity-property coverage varying by device/driver; neither is treated as an API contract.
- Apple's IOKit registry APIs for enumeration mechanics, not for undocumented property meaning.
