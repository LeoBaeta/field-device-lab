# Development Roadmap

Status: initial plan, 2026-07-31.

This roadmap turns the [product concept](product-concept.md) into bounded, verifiable
increments. It describes intended outcomes rather than committing prematurely to
specific libraries, algorithms, thresholds, or hardware interfaces.

## Guiding principles

- Keep the electrical domain model independent of transport and utility protocols.
- Maintain a host-only path even after hardware targets are introduced.
- Introduce hardware only after the corresponding responsibility works in simulation.
- Support every real-time or performance claim with a reproducible measurement.
- Keep protocol-specific addresses, timestamps, and quality descriptors at adapters.
- Use synthetic signals, identifiers, configurations, and operating scenarios only.
- Do not imply protection suitability, standards conformance, or production readiness.
- Discuss and record detailed design decisions before implementation.

## Milestone overview

| Version | Focus | Status |
|---|---|---|
| v1 | Measurement-frame and event foundation | Design |
| v2 | Complete calculated electrical quantities | Planned |
| v3 | Waveform and DSP simulation | Planned |
| v4 | Equipment and operational state | Planned |
| v5 | Real-time hardware experiment | Planned |
| v6 | Protocol interoperability | Planned |
| v7 | Real-time HMI | Planned |

Versions describe capability milestones, not necessarily public release numbers. A
milestone may be divided into smaller releases when its implementation is planned.

## v1 — Measurement-frame and event foundation

### Intent

Establish the protocol-neutral core using calculated measurements as synthetic input.
This deliberately starts after waveform acquisition and electrical calculation.

### Planned capabilities

- Represent one three-phase feeder observation.
- Carry source identity, sequence, timestamp, and protocol-neutral quality.
- Carry per-phase RMS voltage and RMS current.
- Carry system frequency.
- Validate structural and physical plausibility.
- Apply configurable event rules.
- Model event start, continuation, recovery, and duration.
- Generate deterministic synthetic scenarios.
- Produce diagnostics suitable for automated tests and human inspection.

### Explicitly deferred

- Raw waveforms and sampling.
- Derived power and energy quantities.
- Physical equipment state.
- Hardware, graphical interfaces, and utility protocols.

### Acceptance direction

A deterministic scenario must produce an independently testable sequence of
measurements and expected event transitions. Repeating the scenario must produce the
same results.

## v2 — Complete calculated electrical quantities

### Intent

Expand the protocol-neutral electrical model and calculation engine while retaining the
v1 event boundary.

### Planned capabilities

- Per-phase and aggregate active power.
- Reactive and apparent power.
- Power factor.
- Phase-angle representation.
- Energy import and export totals.
- Phase imbalance.
- Positive-, negative-, and zero-sequence quantities if a scenario justifies them.
- Configuration and tests covering nominal and abnormal conditions.

### Acceptance direction

Calculations must be checked against analytically known cases, with units, conventions,
signs, numerical tolerances, and aggregation behavior documented.

## v3 — Waveform and DSP simulation

### Intent

Move the simulation boundary from calculated measurements to synchronized raw samples.
The DSP pipeline must produce the measurement-frame abstraction established by v1.

### Planned capabilities

- Generate three voltage and three current waveforms.
- Configure sampling frequency and scenario timing.
- Represent synchronized, timestamped sample blocks.
- Model noise, offsets, harmonics, distortion, jitter, gaps, and corrupted samples.
- Calculate RMS values, frequency, phase, power, power factor, and energy.
- Calculate harmonic spectrum and total harmonic distortion.
- Detect or propagate insufficient and unreliable input quality.
- Record numerical accuracy and processing-cost experiments.

### Candidate scenarios

- Normal balanced operation.
- Voltage sag and swell.
- Phase loss and phase imbalance.
- Overcurrent and current transients.
- Frequency deviation.
- Harmonic distortion.
- Missing, delayed, duplicated, or corrupted sample blocks.

### Acceptance direction

Known synthetic signals must produce expected quantities within declared tolerances.
The same downstream event logic must accept frames produced by either the simple v1
generator or the waveform pipeline.

## v4 — Equipment and operational state

### Intent

Represent timestamped physical and operational state separately from continuous
electrical measurements.

### Planned capabilities

- Simulated breaker and disconnector positions.
- Local/remote operating state.
- Simulated protection indications and alarm contacts.
- Communication and device-health state.
- State-transition and sequence-of-events records.
- Unknown, contradictory, stale, and bouncing digital input behavior.
- Simulated commands with validation, interlocks, feedback, timeout, and failure.
- Restart and state-recovery scenarios.

### Acceptance direction

Deterministic scenarios must demonstrate normal transitions as well as rejection or
reporting of unsafe, contradictory, stale, and failed operations. All control remains
simulated.

## v5 — Real-time hardware experiment

### Intent

Distribute selected responsibilities onto available hardware and measure timing,
capacity, failure, and recovery behavior.

### Candidate allocation

- ESP32 with an RTOS: waveform/sample generation, periodic acquisition work,
  timestamps, deadline monitoring, and bounded transport.
- BeagleBone Black with Yocto Linux: measurement/event services, persistence,
  observability, communication, and later local graphics.
- Arduino Mega or similar boards: optional digital equipment-state emulation or
  independent fault injection.

### Planned experiments

- RTOS task periods, priorities, queues, buffer bounds, and overload policies.
- Scheduling jitter and missed deadlines.
- Transport latency, loss, duplication, reordering, and reconnection.
- Linux scheduling and load behavior.
- Standard versus PREEMPT_RT Yocto configurations if useful.
- End-to-end event latency.
- Process, link, device, and power-cycle recovery.

### Acceptance direction

Publish the hardware, software versions, workload, clocks, methodology, raw results,
and limitations for each timing claim. Clearly classify demonstrated behavior as soft,
firm, or hard real-time and avoid protection-grade claims.

## v6 — Protocol interoperability

### Intent

Expose the protocol-neutral domain through bounded utility-automation adapters and
simulated peers.

### Planned IEC 60870-5-104 work

- Map selected measurements, equipment states, quality, and timestamped events.
- Connect to a simulated SCADA or control-center client.
- Exercise interrogation, spontaneous reporting, connection loss, and recovery.
- Consider simulated commands only after the v4 state model and interlocks exist.

### Planned IEC 61850 work

- Define a bounded information model for the fictional IED.
- Create relevant SCL artifacts.
- Demonstrate MMS reporting through a simulated client.
- Consider GOOSE or Sampled Values only for a specific, measurable experiment.

### Acceptance direction

Document the selected standard editions, licensed references, library licenses,
mappings, interoperability procedure, observed results, and unsupported features. Use
"standards-informed" or "interoperability demonstration" unless conformance has been
established through an appropriate process.

## v7 — Real-time HMI

### Intent

Provide an operator-facing, continuously updating view of the simulated feeder, IED,
and experiment health.

### Planned capabilities

- Single-line representation.
- Per-phase electrical quantities.
- Live and historical waveforms.
- Phasor or phase-relationship visualization.
- Power, power factor, energy, harmonic spectrum, and THD.
- Active alarms and event history.
- Breaker and other equipment state.
- Communication, timing, data-quality, and device-health status.
- Scenario selection and fault injection.
- Operation on a development host and, if practical, the BeagleBone display stack.

### Acceptance direction

An operator must be able to initiate a scenario and correlate the visual response with
recorded measurements, event transitions, remote reports, and measured latency without
the HMI becoming part of the safety-critical processing path.

## End-to-end definition of completeness

The intended simulation is complete when a repeatable scenario such as a distorted
Phase-B voltage sag can be observed across the whole system:

1. The synthetic waveform changes.
2. Acquisition timestamps and transports the samples.
3. DSP calculates electrical quantities and quality.
4. Event logic detects, times, and eventually closes the condition.
5. Event and energy records are updated.
6. The local HMI presents the condition and recovery.
7. A simulated remote system receives the mapped information.
8. The experiment reports measured processing and end-to-end latency.
9. The system behaves predictably during overload, communication loss, and recovery.

## Current design frontier

The next decision is the exact semantic contract for the v1 measurement frame,
especially:

- timestamp and clock behavior;
- sequence and source identity;
- protocol-neutral data quality;
- per-phase representation and units; and
- how partial or unavailable measurements are expressed.

No C++ representation should be selected until these semantics are agreed.
