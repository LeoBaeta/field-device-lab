# ADR 0001: Separate measurement time from system-processing time

Status: accepted

Date: 2026-08-01

## Context

A measurement may be observed, transported, received, and processed at different
times. The host simulation must be deterministic, while later ESP32 and BeagleBone
experiments must support restarts, transport delays, latency measurement, and clocks
that may not be synchronized to UTC.

A single timestamp cannot describe all of these meanings safely. UTC clocks can move
when corrected and therefore are unsuitable for measuring durations. A source-relative
monotonic clock supports durations but cannot by itself correlate observations between
devices or provide calendar time to an operator or remote system.

## Decision

A measurement frame represents values calculated over an observation window.

- Every frame carries a mandatory source-relative monotonic measurement time.
- That time identifies the end of the observation window.
- The monotonic time never moves backward within one source session.
- Monotonic times are comparable only within the same source session.
- A frame may additionally carry the corresponding UTC time.
- UTC availability and trust are explicit. The semantic states initially considered
  are unavailable, unsynchronized, estimated, and synchronized.
- Event ordering and duration use source measurement time, not UTC.
- The receiver records arrival time using its own monotonic clock.
- Processing start and completion times are receiver-side diagnostic metadata.
- Staleness, transport delay, queue delay, processing time, and end-to-end latency use
  the relevant receiver-local timing observations; they are not inferred silently from
  UTC.
- The host simulator uses a deterministic logical clock by default. A later live mode
  may pace logical time against elapsed real time without changing scenario semantics.

A future source-session identity will distinguish a restarted source from duplicated,
reordered, or delayed frames. Its representation is a separate decision.

## Consequences

### Benefits

- Deterministic simulations do not depend on the computer's current time.
- Event durations remain stable across UTC corrections.
- An ESP32 can produce valid measurements without owning a synchronized calendar
  clock.
- The BeagleBone can measure receiver-side latency and staleness independently.
- Later HMI and protocol adapters can expose UTC time together with honest time quality.
- Restart and clock-synchronization behavior remain visible rather than implicit.

### Costs and constraints

- Frames carry richer time metadata than a single timestamp.
- Consumers must not compare source-monotonic values across source sessions.
- Correlating source time with receiver or UTC time requires an explicit clock-mapping
  mechanism in later hardware experiments.
- Tests must cover missing, uncertain, corrected, and restarted clocks.

## Alternatives considered

### UTC only

Rejected because UTC may be absent or corrected, and elapsed-time calculations would
then be unreliable.

### Source-monotonic time only

Rejected as the complete design because operators, event logs, and remote utility
systems eventually require cross-device and calendar-time correlation.

### Receiver arrival time as measurement time

Rejected because transport and scheduling delay would be mistaken for the time at
which the electrical condition was observed.

## Deferred decisions

This ADR deliberately does not select:

- C++ time types;
- timestamp resolution or wire encoding;
- whether the full observation-window interval is carried in each frame;
- the source-session identifier representation;
- the clock-synchronization or clock-mapping mechanism;
- how UTC uncertainty is quantified; or
- mappings to IEC 60870-5-104 or IEC 61850 time-quality fields.

Those choices will be recorded when the next bounded increment requires them.
