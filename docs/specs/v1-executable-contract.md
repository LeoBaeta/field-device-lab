# V1 Executable Contract

Status: accepted scope, 2026-08-01.

This specification defines the observable boundary of the first `grid-monitor`
executable selected by [ADR 0005](../adr/0005-start-with-deterministic-host-cli.md).
It does not define C++ types or internal component structure.

## Invocation

The first supported command is:

```bash
grid-monitor --scenario phase-b-voltage-sag
```

The executable:

1. selects the named built-in scenario;
2. generates its frames in sequence order;
3. performs structural and qualified-value validation;
4. processes the frames through one per-phase voltage-sag detector;
5. emits measurement and event records;
6. emits one final summary; and
7. terminates.

No interactive input, files, network access, random values, wall-clock reads, or sleeps
affect a successful run.

## Deterministic source

The scenario uses:

```text
source_id:  lab/feeder-01/measurements
session_id: phase-b-voltage-sag-001
```

Sequence starts at zero. Measurement time is logical elapsed time from the start of the
scenario and advances by 20 milliseconds per frame. UTC time is unavailable.

## Feeder and event configuration

The fictional feeder configuration is:

| Setting | Value |
|---|---:|
| Topology | Three-phase, four-wire wye |
| Nominal line-to-neutral voltage | 230 V RMS |
| Nominal frequency | 60 Hz |
| Voltage-sag detection threshold | below 207.0 V RMS |
| Voltage-sag recovery threshold | at or above 211.6 V RMS |

The detection threshold is 90% of nominal voltage and the recovery threshold is 92%.
Separate thresholds provide deterministic hysteresis. These are fictional scenario
values, not protection settings or claims about a deployed grid.

## Scenario frames

All present values have `good` usability with no reasons. All phase currents are
10.0 A RMS, all Phase-A and Phase-C voltages are 230.0 V RMS, and frequency is 60.0 Hz.
Only Phase-B voltage changes:

| Sequence | Time (ms) | Phase-B voltage (V RMS) | Expected transition |
|---:|---:|---:|---|
| 0 | 0 | 230.0 | none |
| 1 | 20 | 230.0 | none |
| 2 | 40 | 200.0 | sag started on Phase B |
| 3 | 60 | 190.0 | none; sag remains active |
| 4 | 80 | 205.0 | none; hysteresis keeps sag active |
| 5 | 100 | 215.0 | sag ended on Phase B after 60 ms |

The event begins at the first frame below the detection threshold. It ends at the first
frame at or above the recovery threshold. Duration is the difference between those two
source measurement times.

## Standard output

Standard output is UTF-8 JSON Lines. Each line contains one compact JSON object followed
by LF. Records appear in processing order:

- one `measurement` record for every frame;
- an `event` record immediately after the measurement that causes a transition; and
- one `summary` record after all frames and transitions.

### Measurement record

A measurement record exposes at least:

- `type` with value `measurement`;
- `source_id`;
- `session_id`;
- `sequence`;
- `measurement_time_ms`;
- Phase A/B/C qualified RMS line-to-neutral voltage in volts;
- Phase A/B/C qualified RMS line current in amperes; and
- qualified system frequency in hertz.

Each qualified value exposes its optional numeric value, usability, and reason list.
UTC is omitted because it is unavailable in this scenario.

### Event record

An event record exposes:

- `type` with value `event`;
- `event` with value `voltage_sag`;
- `phase` with value `b`;
- `transition` with value `started` or `ended`;
- `measurement_time_ms`;
- the observed RMS voltage in volts; and
- `duration_ms` on the ended transition.

The started event occurs at 40 ms. The ended event occurs at 100 ms and reports a
duration of 60 ms.

### Summary record

The final record exposes:

```json
{"type":"summary","frames":6,"events_started":1,"events_ended":1,"active_events":0}
```

The implementation will add a checked-in golden-output fixture when the JSON field
layout is implemented. That fixture will own exact key order and numeric lexical
formatting. Until then, this specification owns semantic fields, record order, and
values rather than an unpublished byte sequence.

## Standard error and exit status

- A successful scenario writes no standard-error output and exits with status `0`.
- Invalid command-line usage writes a concise usage diagnostic to standard error and
  exits non-zero.
- An unknown scenario writes a diagnostic naming the unsupported scenario and exits
  non-zero.
- Structural, validation, or processing failure writes a diagnostic to standard error,
  emits no successful summary, and exits non-zero.

Specific non-zero values remain an implementation decision. Tests must assert the
documented success/non-success distinction and relevant diagnostics.

## Explicit exclusions

V1 does not include:

- external scenario files;
- raw waveform generation or RMS calculation;
- real-time pacing or concurrency;
- networking or IPC;
- persistence;
- hardware execution;
- IEC protocols;
- graphical interfaces;
- multiple electrical event types; or
- production logging and configuration frameworks.

These capabilities remain in the development roadmap.

## Acceptance criteria

- [ ] The documented command runs successfully on a supported host.
- [ ] Six measurement records are emitted in sequence order.
- [ ] Exactly one Phase-B voltage-sag start and one end are emitted.
- [ ] The ended event reports 60 ms duration.
- [ ] The final summary matches the specified values.
- [ ] Repeated runs produce byte-for-byte identical standard output.
- [ ] Unit tests cover sag start, continuation, hysteresis, recovery, and duration.
- [ ] A process-level test executes the binary and verifies output and exit status.
- [ ] Invalid arguments and an unknown scenario fail with useful diagnostics.
- [ ] No wall-clock, random, file, network, or sleep behavior affects the scenario.
