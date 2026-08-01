# ADR 0003: Represent measurement usability and reasons explicitly

Status: accepted

Date: 2026-08-01

## Context

The monitoring IED must distinguish a trustworthy abnormal electrical condition from a
broken, missing, estimated, or stale observation. A voltage sag can be a valid
measurement of an abnormal feeder state; treating every abnormal value as bad data
would prevent correct event detection.

Quality may also differ between values in one three-phase frame. Rejecting a whole
frame because one phase is unavailable would discard usable measurements. Conversely,
numeric sentinels and one Boolean `valid` flag would make absence, uncertainty, and
known invalidity ambiguous.

Future IEC adapters have their own quality representations, but the core domain must
remain independent of any protocol layout.

## Decision

Every electrical measurement is a qualified value composed of:

```text
optional numeric value + usability state + zero or more quality reasons
```

### Usability states

The protocol-neutral usability states are:

- `good`: a value is present and suitable for normal calculation and event decisions;
- `questionable`: a value is present but requires an explicit consumer policy before
  use;
- `invalid`: a value is present for diagnosis but must not be used as an electrical
  measurement; and
- `unavailable`: no numeric value was produced.

Good values normally have no quality reasons. Questionable, invalid, and unavailable
values carry at least one reason; `unknown` may be used only when no more specific
reason can be established.

The initial protocol-neutral reason vocabulary is:

- `out_of_physical_range`;
- `sensor_fault`;
- `calculation_failed`;
- `insufficient_samples`;
- `estimated`;
- `substituted`;
- `source_stale`;
- `configuration_error`;
- `overflow`; and
- `unknown`.

More than one reason may apply. A reason explains the state; it does not replace the
usability decision.

### Per-measurement quality

Quality is attached to each measurement rather than collapsed into one frame-level
state. A structurally valid frame may therefore contain good Phase-A and Phase-C values
while Phase B is unavailable. Calculations continue only when their required inputs
satisfy an explicit usability policy.

An observation containing partial, invalid, or unavailable values is still published
and consumes its sequence number as established by ADR 0002.

### Abnormal electrical conditions

Electrical severity and measurement quality are independent. A trustworthy value
outside an operational threshold remains `good` and may start a sag, swell, overcurrent,
or frequency event. A physically impossible or otherwise unusable value is `invalid`
and produces a data-quality condition instead of an electrical event.

### Frame validation

Structural faults such as missing identity, malformed sequence or time, unsupported
schema, corrupt serialization, or duplicate identity with different content are
ingestion errors. They may reject the frame and are not represented as electrical-value
quality.

### Missing values and staleness

Unavailable data is represented by an absent numeric value, never by a sentinel, NaN,
or magic number.

`source_stale` describes a producer intentionally publishing an older or held value.
Receiver-observed staleness caused by a lack of new frames is stream or communication
health and does not mutate the last frame's original quality.

### Default consumption policy

- Good values participate in calculations and electrical-event decisions.
- Questionable values are excluded unless a calculation or rule explicitly permits
  them.
- Invalid and unavailable values are excluded and update an appropriate data-quality or
  availability condition.
- Loss of usable data does not silently close an active electrical event. Its
  observation becomes interrupted or uncertain until a later event-lifecycle decision
  defines recovery behavior.

UTC synchronization quality, sequence continuity, simulation provenance, device
metadata, communication state, and electrical-event severity remain separate concerns.

## Consequences

### Benefits

- Real grid abnormalities remain distinguishable from measurement failures.
- Partial three-phase observations retain their usable values.
- Missing values cannot accidentally enter calculations as numeric sentinels.
- Consumers must make their tolerance for uncertain data explicit.
- Quality can later map to multiple protocols without making the domain model
  protocol-specific.
- Source-reported quality and receiver-observed communication health remain auditable.

### Costs and constraints

- Every measurement carries more state than a plain number.
- Producers must assign usability and reasons consistently.
- Calculations need documented quality-propagation policies.
- Event handling must account for interruption by unusable data.
- Serializers and tests must preserve combinations of absence, usability, and reasons.

## Alternatives considered

### One frame-level valid flag

Rejected because it would discard usable phases or conceal which measurement failed and
why.

### Numeric sentinels or NaN

Rejected because sentinels can enter calculations accidentally, NaN does not explain
absence, and their behavior across serialization and external systems is inconsistent.

### One quality enumeration containing every condition

Rejected because combinations such as `questionable + substituted + source_stale`
would require an expanding set of compound states. Usability and reasons express these
dimensions separately.

### Reuse an IEC protocol quality layout internally

Rejected because it would couple the domain model to one adapter and make meanings from
other sources harder to represent honestly.

## Deferred decisions

This ADR deliberately does not select:

- concrete C++ types or storage layout;
- numeric representation and units;
- the complete set of valid usability/reason combinations;
- quality propagation for each derived electrical quantity;
- timeout thresholds for receiver-observed staleness;
- active-event recovery after unavailable data;
- serialization encoding; or
- mappings to IEC 60870-5-104 or IEC 61850 quality fields.

Those choices will be recorded when the corresponding implementation requires them.
