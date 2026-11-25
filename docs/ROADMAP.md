# Development Roadmap

MacLean advances only when each phase produces reviewable evidence. Safety requirements apply to every phase, not just the final integration milestone.

| Phase | Focus | Deliverable | Exit evidence |
|---|---|---|---|
| 0 | Hardware discovery | Privacy-conscious host inventory and capability matrix | Exact target model, CPU/GPU, OS build, battery condition, and unknown fields recorded without unique identifiers |
| 1 | Read-only telemetry | Low-overhead metric adapters and a documented metric-quality model | Source, units, cadence, permissions, unavailable behaviour, and measurement cost recorded for each field |
| 2 | Baseline experiments | Repeatable idle, compilation, wakeup, and graphics procedures | Multiple trials, workload completion time, energy indicator, conditions, variance, and confounders captured |
| 3 | CPU research | C-state, frequency, wakeup, and race-to-idle analysis | Findings tied to exact hardware/OS; no frequency-only claims; measurement limits recorded |
| 4 | Background work | Recommendations for MacLean-owned work using QoS, timer tolerance, and system deferral | Demonstrated effect on MacLean's own energy cost without harming foreground responsiveness |
| 5 | Graphics | Read-only integrated/discrete GPU activity and switching study | Scenarios mapped to OS/driver behaviour; no forced GPU disablement |
| 6 | Thunderbolt and PCIe | Peripheral activity, link, sleep/wake, and ASPM research | Device/controller effects distinguished; connectivity and wake behaviour preserved |
| 7 | Adaptive engine | Explainable workload-aware policy simulation | Stable state transitions, hysteresis, dwell times, and offline results; still no automatic writes |
| 8 | Experimental research | Isolated T2, deep-idle, PCIe ASPM, and power-gating feasibility studies | Written feasibility and safety review before any prototype that can alter system state |
| 9 | Additional modules | Memory, thermal, network, and storage research | Each module has a source inventory and controlled workload evidence |
| 10 | Integration and safety | Optional controls only where a documented interface exists | Compatibility checks, consent, watchdog, verified rollback, and sleep/wake/peripheral regression evidence |

## Immediate work

1. Maintain the directory scaffold and module specifications.
2. Collect a hardware inventory on the actual 2019 Intel test Mac using the read-only CLI.
3. Record any unavailable field and check the local macOS manual for supported powermetrics samplers without assuming privileges.
4. Define a low-overhead telemetry contract and a manual baseline worksheet.
5. Do not implement invasive hardware controls until the corresponding research note answers the unresolved questions and a reversible supported interface is identified.

## Promotion criteria

A feature can move from research to a stable module only when its source is understood, capability checks are explicit, missing data is safe, overhead is measured, the effect is repeatable, and regressions are documented. A control remains experimental if the only path is private, undocumented, privileged without narrow justification, or difficult to roll back.

## Success measures

- Energy or discharge change under matched repeated workloads, with uncertainty.
- Task completion time and responsiveness.
- Thermal state and fan behaviour.
- Sleep/wake success, battery charging, peripheral connectivity, and security posture.
- MacLean's own idle CPU, wakeup, and memory cost.

Lower frequency, fewer wakeups, or lower temperature alone do not establish an energy benefit.
