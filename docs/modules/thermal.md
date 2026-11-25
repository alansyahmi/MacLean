# Thermal Efficiency Research Specification

## Goal

Observe thermal conditions and their relationship to performance, fan activity, and energy without modifying cooling or processor safety behaviour.

## Read-only measurements

Foundation ProcessInfo exposes a coarse system thermal state and change notifications. Record the state as a categorical OS signal, not a Celsius reading. Exact CPU/GPU temperatures, fan RPM, and thermal pressure detail may be unavailable or model-specific; use only a documented, validated source and mark it accordingly.

## Hypotheses

- Reducing MacLean's own work during elevated thermal state can avoid adding load.
- Lower temperature alone does not prove lower energy; workload duration, fan energy, and system power must be considered.
- Thermal throttling may lengthen a benchmark enough to change energy per task.

## Boundaries

Do not write fan curves, SMC keys, thermal limits, or cooling policy. Never disable thermal protections. Do not substitute fan speed for temperature or temperature for power.

## Open questions

- Which thermal-state values and notifications are available on the target OS?
- Which physical sensors are publicly readable without private interfaces?
- How should trials be conditioned on ambient temperature and fan state?
