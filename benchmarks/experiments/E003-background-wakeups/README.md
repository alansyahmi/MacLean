# E003 — Background activity and wakeups

## Hypothesis

The variation in idle CPU utilization may reflect intermittent background work. Process-level timer, interrupt, and package-idle wakeups may identify candidates for later workload-specific investigation, but CPU utilization alone does not show energy cost or causality.

## Controlled variables

Use the same host/build, power source, display brightness, apps, network state, peripherals, thermal state, sampling interval, and trial duration. Record the exact trial order and any foreground interaction. Compare a stable app set with one deliberately changed app set; do not terminate system services.

## Measurement sources

- Non-privileged aggregate CPU utilization from Mach host statistics.
- Optional native `powermetrics -s tasks,interrupts,cpu_power` sampling for process wakeup categories, device interrupt rates, and package state, only in an explicitly authorized diagnostic session. MacLean's current parser does not yet consume task-level output.
- Battery discharge energy, if valid battery trials are available.

## Procedure

1. Run three 10-minute quiet desktop-idle trials with the normal app set and three with a documented, operator-selected app set. Alternate or randomize order.
2. If process attribution is needed, the operator must separately authorize and launch a privileged diagnostic process. MacLean never invokes `sudo`, prompts for a password, or elevates.
3. Record only process names and wakeup counters needed for the investigation in local, access-controlled output. Do not commit raw process lists or unrelated process details.
4. Compare task wakeups, package idle exits, interrupts, CPU utilization, and valid whole-system battery energy. Repeat any suspected activity in a controlled follow-up before calling it causal.

## Acceptance criteria

At least three valid trials per condition; task/wakeup parser validated against the exact OS output; no raw output retained in Git; attribution repeated across runs; energy conclusions supported by battery discharge measurements and considered with performance and thermal behaviour.

## Results

Not run. The initial three AC-powered idle trials averaged 8.21% CPU utilization, with 2.28 percentage points between-trial standard deviation. The single E005 screen pass later showed 3.05–3.78% mean utilization across intervals, but it was shorter and not a matched repeat; it does not establish a change. None of these data identify processes, measure energy overhead, or establish reduced package C-state residency. The optional task sampler has not been run in an authorized session.

## Limitations

Process wakeups are attribution clues, not an exact allocation of system energy. `DEAD_TASKS` may represent short-lived work. Sampler overhead and process privacy need to be recorded. A high-CPU interval is not necessarily an actionable battery drain.
