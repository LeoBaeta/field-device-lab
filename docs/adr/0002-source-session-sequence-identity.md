# ADR 0002: Identify frames by source, session, and sequence

Status: accepted

Date: 2026-08-01

## Context

The monitoring IED must distinguish normal frame order from duplication, loss,
reordering, source restart, and delayed delivery from an earlier run. A source may
restart its measurement process without rebooting the whole device, and a network
connection may reconnect without resetting the producer. Monotonic time and sequence
therefore need an explicit scope.

Hardware addresses and utility-protocol addresses are poor domain identities: they may
change independently, expose transport choices, or identify a device rather than one
ordered measurement stream. Persisting one sequence forever would add storage and
failure concerns without eliminating the need to represent restarts.

## Decision

Every measurement frame is identified by the tuple:

```text
(source_id, session_id, sequence_number)
```

### Source identity

- A source ID identifies one logical, ordered measurement stream.
- It remains stable across normal software and device restarts.
- It is explicitly configured and independent of MAC addresses, serial numbers,
  transport endpoints, and IEC protocol addresses.
- A device producing independently ordered streams assigns each stream a distinct
  source ID.
- Synthetic identifiers must not reuse employer, customer, or deployed-system names.

### Session identity

- A session ID identifies one continuous sequence and source-monotonic-time epoch.
- It changes whenever the sequence or monotonic-time axis resets or continuity cannot
  be proved.
- Device reboot, measurement-process restart, pipeline reset, counter reset, and
  uncertain recovery therefore start a new session.
- A transport disconnect alone does not start a new session when the producer continues
  its clock and sequence without interruption.
- Session IDs are unique but do not need to be meaningful or chronologically ordered.
- Deterministic tests may inject fixed session IDs.

### Sequence number

- The sequence starts at zero for each session.
- It increases once for every published observation.
- Observations containing invalid, partial, or unavailable values are still published
  and consume a sequence number.
- A sequence value is never reused within one session.
- The conceptual range is an unsigned 64-bit value. A producer starts a new session
  instead of wrapping it.

The frame tuple is unique. Receiving the same tuple with the same content is a
duplicate. Receiving the same tuple with different content is an integrity or producer
fault. A gap indicates that a frame was lost or never published; quality information in
an existing frame indicates that the observation itself was incomplete or unreliable.

Receivers track ordering within a `(source_id, session_id)` pair. A new session ends
ordering and monotonic-time comparisons with the previous session. Late frames from an
inactive session are rejected or quarantined rather than merged into the active stream.
Active events from an ended session are marked interrupted or uncertain; their duration
is not silently continued across the restart.

## Consequences

### Benefits

- Restarts cannot be mistaken for clocks or sequence numbers moving backward.
- Duplicate, missing, reordered, and internally inconsistent frames are distinguishable.
- Network reconnection does not invent a new measurement epoch unnecessarily.
- Invalid measurements remain observable and distinct from missing frames.
- Domain identity stays independent of hardware and utility-protocol mappings.
- Host simulations can use readable deterministic identities while hardware can use
  generated session values.

### Costs and constraints

- Producers and consumers must manage explicit session lifecycle.
- A unique random session ID alone cannot tell a receiver which of two sessions is
  newer; transport or session-establishment behavior must define the active session.
- Receivers must retain enough recent identity state to identify duplicates and late
  frames.
- Device provenance, firmware, configuration, and calibration require separate
  metadata rather than being inferred from the source ID.

## Alternatives considered

### One persistent sequence per source

Rejected because durable counter updates introduce persistence, corruption, and wear
concerns while process restart and clock continuity still need explicit representation.

### Infer restart from decreasing sequence or time

Rejected because reordering, delayed frames, corruption, counter wrap, and restart
would remain ambiguous.

### Use hardware or protocol address as source identity

Rejected because hardware replacement, interface changes, and protocol mapping should
not change the logical measurement-stream identity.

### Omit sequence and rely on timestamps

Rejected because equal-resolution timestamps, clock uncertainty, duplication, and
reordering would make loss and ordering detection unreliable.

## Deferred decisions

This ADR deliberately does not select:

- concrete C++ identifier and integer types;
- source-ID syntax or deployment-wide allocation process;
- random nonce, UUID, persistent boot counter, or receiver-assigned session generation;
- session-establishment and authentication protocol;
- receiver buffering and reordering limits;
- duplicate-state retention duration;
- device, firmware, configuration, and calibration metadata; or
- mappings to IEC 60870-5-104 or IEC 61850 identities.

Those choices will be recorded when implementation or interoperability requires them.
