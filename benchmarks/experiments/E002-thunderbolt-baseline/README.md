# E002 — Thunderbolt peripheral baseline

## Hypothesis

An attached Thunderbolt peripheral may change whole-system discharge power, interrupts, or CPU package idle residency during matched idle periods. The proposed controller-to-package-wakeup mechanism remains a hypothesis.

## Controlled variables

Keep the Mac model/build, battery state, screen brightness, displays, apps, network, workload, thermal state, sample interval, and trial duration fixed. Change only one peripheral connection. Record the device class and port without saving serial numbers, UUIDs, route strings, or unrelated device identifiers. Use at least three repeats per condition and alternate trial order.

## Measurement sources

- Battery discharge watts and integrated watt-hours from MacLean when battery-powered coverage is valid.
- Optional explicitly authorized `powermetrics` interrupts and package C-state data; package-power estimates are separate and labeled as OS estimates.
- `system_profiler` Thunderbolt topology counts from `maclean doctor`; counts do not imply runtime power state.
- Thunderbolt controller power, PCIe ASPM, and power-gating state: unavailable from a validated source.

## Procedure

1. Inventory connected devices and confirm which are nonessential. Do not disconnect required storage, displays, networking, charging, or safety equipment.
2. Run at least three 10-minute desktop-idle trials with the selected peripheral connected, then three with it disconnected. The operator handles physical connections; MacLean does not alter device state.
3. Keep all other conditions fixed, record trial order, and reject trials with sleep/wake, AC transitions, thermal pressure, or substantial user activity.
4. Compare system energy, package estimates, interrupt evidence, and C-state data separately. Restore the original connections and verify normal operation.

## Acceptance criteria

Three valid repeats per condition; 95% or greater battery-power coverage; the peripheral is the only intended independent variable; measured energy and performance/availability effects are reported; no claim of controller power gating without a direct validated state reading.

## Results

Not run. On this host, System Profiler exposes a Thunderbolt data type and MacLean can report controller/receptacle counts. This does not establish that any controller or port is suspended.

## Limitations

Interrupt counts are evidence of activity, not proof of controller watts or link power state. A peripheral may affect unrelated subsystems. Do not use private driver properties or infer power gating from a missing device.
