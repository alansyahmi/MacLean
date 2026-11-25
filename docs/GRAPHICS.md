# Graphics Efficiency Research Specification

## Goal

Determine which workloads and display configurations activate the integrated GPU, discrete GPU, or both, and measure the effect on total task energy and performance.

## Target context

The initial target description includes Intel integrated graphics and an AMD Radeon Pro 5500M discrete GPU. Confirm the actual GPU models and macOS build on the machine before starting. External displays, rendering APIs, app behaviour, and driver policy may change which GPU drives a display.

## Native behaviour and limits

Apple documents automatic graphics switching on supported dual-GPU MacBook Pro models. The system selects devices based on workload and display configuration. Apple's Metal guidance notes that the discrete GPU may be required to drive external displays on certain dual-GPU Intel Macs. Copying rendered frames between a rendering GPU and a different display-driving GPU can add cost.

The NSSupportsAutomaticGraphicsSwitching property applies to whether an OpenGL app may use the integrated GPU. It is an app-level compatibility declaration, not a global GPU-selection control for MacLean to apply to other software. Metal apps can inspect/select devices for their own rendering, which does not provide system-wide switching authority.

GPU activity, power, temperature, and clock fields published through driver properties are not guaranteed. Missing fields must remain unavailable. Seeing a GPU in the inventory does not prove that it is active or drawing a known number of watts.

## Read-only experiment matrix

Hold the same workload, brightness, network state, battery range, OS build, and thermal starting condition. Compare:

1. Built-in display only, idle desktop.
2. Built-in display with a fixed lightweight workload.
3. A controlled accelerated workload using a recorded API and version.
4. Each supported external-display arrangement.
5. A known app set that can trigger discrete graphics, with application versions recorded.

For each run, record display topology, reported active GPUs, GPU activity fields and their provenance, battery status, task time, thermal state, and any missing data. Repeat and alternate order where possible.

## Hypotheses

- Avoiding unnecessary discrete-GPU activation may reduce energy in some built-in-display workloads.
- External displays and app requirements can make discrete GPU use necessary.
- Attempting to force integrated-only operation can cause display loss, app failure, or worse transfer/performance cost.
- A less active GPU reading does not prove lower total system energy.

## Boundaries

No driver unloading, device disabling, undocumented GPU-selection defaults writes, private SMC/IORegistry writes, or external-display changes without user control. MacLean initially observes and recommends only. Preserve display output and application correctness.

## Open questions

- Which utilization and power properties are available from the target AMD and Intel drivers?
- What is the cost of each display topology on this exact Mac?
- Can activity changes be correlated with repeatable battery-energy changes?
- Is any system-wide GPU policy control documented and reversible on the target OS?

## References

- [Apple: Selecting device objects for graphics rendering](https://developer.apple.com/documentation/metal/selecting-device-objects-for-graphics-rendering)
- [Apple: Assessing multi-GPU and multi-display setups on an Intel-based Mac](https://developer.apple.com/documentation/metal/assessing-multi-gpu-and-multi-display-setups-on-an-intel-based-mac)
- [Apple: NSSupportsAutomaticGraphicsSwitching](https://developer.apple.com/documentation/bundleresources/information-property-list/nssupportsautomaticgraphicsswitching)
- [MacPulse Intel and AMD telemetry notes](https://github.com/vluncasu/macpulse)
