# Development Roadmap

MacLean advances only when each phase produces reviewable evidence. Safety requirements apply to every phase, not just the final integration milestone.

| Phase | Focus | Deliverable | Exit evidence |
|---|---|---|---|
| 0 | Hardware discovery | Privacy-conscious host inventory and capability matrix | Initial `doctor` inventory exists; target model/build and remaining unknown capabilities still need confirmation |
| 1 | Baseline measurement and extended telemetry | Repeatable JSON benchmark trials, native battery current/voltage reads, comparison utility, optional privileged diagnostics | Tooling is implemented; repeated, quiet idle trials on a confirmed target model and valid energy coverage remain outstanding |
| 2 | CPU research | C-state, frequency, wakeup, and race-to-idle analysis | Findings tied to exact hardware/OS; no frequency-only claims; measurement limits recorded |
| 3 | Background work | Recommendations for MacLean-owned work using QoS, timer tolerance, and system deferral | Demonstrated effect on MacLean's own energy cost without harming foreground responsiveness |
| 4 | Graphics | Read-only integrated/discrete GPU activity and switching study | Scenarios mapped to OS/driver behaviour; no forced GPU disablement |
| 5 | Thunderbolt and PCIe | Peripheral activity, link, sleep/wake, and ASPM research | Device/controller effects distinguished; connectivity and wake behaviour preserved |
| 6 | Adaptive engine | Explainable workload-aware power-profile simulation | Stable state transitions, hysteresis, dwell times, and offline results; still no automatic writes |
| 7 | Experimental research | Isolated T2, deep-idle, PCIe ASPM, and power-gating feasibility studies | Written feasibility and safety review before any prototype that can alter system state |
| 8 | Additional modules | Memory, thermal, network, and storage research | Each module has a source inventory and controlled workload evidence |
| 9 | Integration and safety | Optional controls only where a documented interface exists | Compatibility checks, consent, watchdog, verified rollback, and sleep/wake/peripheral regression evidence |

## Immediate work

1. Confirm the exact test model and OS build, then run three ten-minute `desktop-idle` trials on a quiet system while recording power source and background conditions.
2. Review each trial's battery voltage/current availability, watt-hour coverage, metric variation, and collector overhead. Do not claim energy savings from AC-only or incomplete data.
3. Verify the optional powermetrics output and privilege requirement on the target before using its additional CPU metrics.
4. Research public GPU and Thunderbolt activity interfaces; keep unsupported metrics unavailable.
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
