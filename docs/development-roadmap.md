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
  Every command passes through the management interface (see "Device platform and
  security track"): it is attributed to an authenticated user, authorized by role, and
  audited.
- Restart and state-recovery scenarios.

### Acceptance direction

Deterministic scenarios must demonstrate normal transitions as well as rejection or
reporting of unsafe, contradictory, stale, failed, and unauthorized operations. All
control remains simulated.

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
- Consider simulated commands only after the v4 state model, interlocks and role-based
  authorization exist.

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

## Device platform and security track

### Intent

Build the [device platform layer](product-concept.md#product-layers) in parallel with
the application milestones above. This track is not numbered with them: it starts with
v1 and each capability attaches to the first application milestone that needs it.
Security work follows the structure of ISA/IEC 62443-4-1 (development lifecycle) and
62443-4-2 (component requirements), and is described as standards-informed only.

### Planned capabilities

- Reproducible build, tests, sanitizers, static analysis, compiler hardening flags,
  SBOM and vulnerability scanning in CI.
- Protected build and release: branch protection, pinned CI actions, signed tags,
  signed or checksummed release artefacts and build provenance.
- Security context, interface inventory, threat model and a requirement-to-test
  traceability table for the targeted 62443-4-2 requirements (target: capability
  level 2).
- Vulnerability handling: intake, advisories with severity and affected versions, a
  stated fix-time policy and release notes that say how to verify an update.
- Embedded Linux image with a hardened, least-privileged and sandboxed service,
  default-deny network policy and documented debug-interface state.
- **Security guidelines** for integrators and operators: defense-in-depth layers, what
  the environment must provide, default configuration and further lock-down steps,
  secure operation, accounts and roles, secure decommissioning.
- Separate management and SCADA/telemetry networks on the board's two Ethernet ports.
- A **management interface** with users, roles and audit:
  - every command is attributed to an authenticated user and authorized by role;
  - roles follow the IEC 62351-8 model (viewer, operator, engineer, security
    administrator, security auditor), with separation of duties;
  - user identity and role come from the client's mTLS certificate; one local
    break-glass account covers password strength and failed-login lockout;
  - an authorized role can change which permissions each role holds;
  - certificates are validated, including revocation, and mapped to a user;
  - sessions time out, can be terminated and are limited per user;
  - every command, successful or rejected, produces a tamper-evident audit record
    (time, user, category, type, event ID, result) with synchronized UTC time;
  - audit storage is bounded, warns before it fills, and never stops the essential
    functions.
- Lifecycle and availability commands: security self-test, configuration integrity
  check, signed backup and restore, decommissioning with verified erase, a
  machine-readable security-settings report and the device's component inventory.
- The defined fail state (see the product concept), and essential functions that keep
  running under a flood on the management port.
- Device identity, supplier and asset-owner roots of trust, verified boot, tamper
  detection, encrypted data at rest and signed, recoverable A/B updates.
- Verification beyond unit tests: fuzzing, an attack-surface scan of the image against
  an expected-ports list, and a written self-run penetration test. One developer cannot
  provide independent testing; this limitation is stated rather than hidden.

### Explicitly deferred

- Centralized authentication (RADIUS, LDAP) and remote role-information services.
- Conformance claims against IEC 62443, IEC 62351 or IEEE 1686; these inform the design
  only.

### Acceptance direction

Each targeted requirement has an artefact and a test that fails closed. For the
management interface: an unauthorized command is rejected and audited, no default
credentials exist, repeated failed logins lock the account, a security administrator
cannot change device configuration, and no role can delete or alter the audit log.
The traceability table cites requirement identifiers and describes the device's own
behaviour; it does not reproduce text from the standards.

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

Accepted decisions:

- [ADR 0001](adr/0001-time-semantics.md) separates source measurement time, optional
  UTC time, receiver arrival time, and processing time.
- [ADR 0002](adr/0002-source-session-sequence-identity.md) scopes monotonic time and
  frame ordering with a stable logical source, explicit session, and sequence number.
- [ADR 0003](adr/0003-protocol-neutral-measurement-quality.md) represents each
  measurement with explicit usability and protocol-neutral reasons.
- [ADR 0004](adr/0004-three-phase-measurements-and-units.md) fixes Phase A/B/C
  positions and schema-defined RMS voltage, current, and frequency units.
- [ADR 0005](adr/0005-start-with-deterministic-host-cli.md) starts executable evidence
  with a finite, deterministic host CLI.
- [The v1 executable contract](specs/v1-executable-contract.md) defines the first
  scenario, observable output, exclusions, and acceptance criteria.
- [ADR 0006](adr/0006-use-strong-domain-types-and-thin-cli.md) selects owning strong
  domain types, explicit validation, a reusable core, and a thin CLI boundary.
- [The v1 C++ design](design/v1-cpp-domain-and-targets.md) sketches the initial domain
  representation, target graph, source layout, and test seams.
- [ADR 0007](adr/0007-use-conan-for-explicit-host-dependencies.md) assigns explicit
  host dependency resolution to Conan while keeping CMake and Yocto provider-neutral.
- [The v1 build design](design/v1-build-and-dependencies.md) defines dependency versions,
  target consumption, JSON isolation, and the smallest mechanical build slice.

The v1 design and dependency boundaries are now sufficient for the first mechanical
implementation slice. Before creating files, agree on:

- the exact first-file sequence and review checkpoints.

No C++ representation should be selected until these semantics are agreed.
