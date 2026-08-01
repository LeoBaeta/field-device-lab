# ADR 0005: Start with a deterministic finite host CLI

Status: accepted

Date: 2026-08-01

## Context

The first executable must prove one end-to-end product behavior while supporting the
Month 1 CMake, testing, analysis, and CI work. Beginning with hardware, networking, a
long-running service, or real-time pacing would introduce lifecycle and infrastructure
concerns before the measurement and event boundaries have executable evidence.

The host-first increment must remain representative of the future IED, deterministic
enough for process-level tests, and small enough to review carefully.

## Decision

The first executable is a finite host command-line program named `grid-monitor`.

It accepts a named, built-in deterministic scenario, produces measurement frames using
ADRs 0001 through 0004, validates and processes them, detects one per-phase voltage-sag
event, writes machine-readable diagnostics, emits a summary, and terminates.

The first supported invocation is:

```text
grid-monitor --scenario phase-b-voltage-sag
```

The scenario advances a logical clock without sleeping or consulting wall-clock time.
Its identifiers, measurements, event transitions, ordering, output, and exit status are
repeatable. The executable writes JSON Lines records to standard output, diagnostics
for failed invocations to standard error, and returns a non-zero status for invalid
arguments or failed processing.

Scenario data remains built into the program for this increment. A general external
scenario-file format is not selected yet.

The detailed observable contract is maintained in
[the v1 executable specification](../specs/v1-executable-contract.md).

## Consequences

### Benefits

- One process exercises the agreed domain semantics end to end.
- Logical time makes event duration deterministic and tests fast.
- JSON Lines supports human inspection, `jq`, and process-level assertions.
- A finite process is straightforward to run under sanitizers and static analysis.
- Deferring external input avoids accidentally publishing a temporary scenario schema.
- The same event engine can later sit behind live, hardware, or network producers.

### Costs and constraints

- The first binary does not yet demonstrate long-running service lifecycle behavior.
- Built-in scenarios require recompilation to add cases.
- JSON Lines is diagnostic output, not a utility protocol or stable inter-device wire
  format.
- Concurrency, pacing, persistence, and backpressure remain unproven.
- A finite host run is not itself a real-time demonstration.

## Alternatives considered

### Begin with a long-running daemon

Rejected because signal handling, lifecycle, configuration reload, persistence, and
supervision would obscure the first domain behavior and make deterministic tests harder.

### Begin on ESP32 or BeagleBone hardware

Rejected because hardware and toolchain variables would slow feedback before the
protocol-neutral semantics are executable.

### Begin with raw waveform processing

Rejected for v1 by the staged roadmap. Raw acquisition and DSP will later produce the
same measurement-frame boundary.

### Define a general external scenario format immediately

Rejected because the required scenario vocabulary is not yet understood. Built-in
fixtures can evolve without becoming an accidental compatibility promise.

### Emit only human-oriented prose

Rejected because process-level tests and later tooling need structured, deterministic
records.

## Deferred decisions

This ADR deliberately does not select:

- C++ domain and ownership types;
- build targets and dependency-management details;
- JSON library or serialization implementation;
- a general scenario-file schema;
- daemon, IPC, networking, or persistence architecture;
- live pacing and concurrency behavior; or
- hardware responsibility boundaries.

Those choices will be recorded when their increment begins.
