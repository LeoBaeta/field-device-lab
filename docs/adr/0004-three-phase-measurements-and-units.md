# ADR 0004: Model fixed three-phase measurements in schema-defined units

Status: accepted

Date: 2026-08-01

## Context

The v1 measurement frame needs an unambiguous representation of a three-phase feeder.
A generic `voltage` field does not say whether a value is line-to-neutral or
line-to-line, and a variable collection of phases makes missing measurements ambiguous.
Allowing producers to choose units per frame would also move conversion and error risk
into every consumer.

The first version should remain small while preserving a path to line-to-line values,
power, phase angles, energy, sequence components, and waveform-derived measurements.

## Decision

V1 models one fictional three-phase, four-wire wye feeder.

### Phase representation

- Every frame has fixed Phase A, Phase B, and Phase C positions.
- Each position represents the same electrical phase across frames in a source session.
- A missing phase remains present with unavailable qualified measurements as defined by
  ADR 0003; phase entries are never shifted or omitted.
- Phase letters are domain identities. Numeric indices may be an implementation detail
  but do not define the external semantics.

### Per-phase measurements

Each phase carries:

- qualified RMS line-to-neutral voltage in volts; and
- qualified RMS line current in amperes.

The voltage reference is part of the quantity's meaning. V1 does not call a field only
`voltage`, and it does not infer line-to-line voltage by multiplying by the square root
of three. Later line-to-line measurements use explicit AB, BC, and CA quantities.

RMS voltage and current magnitudes are non-negative. Current direction is not encoded
in an RMS magnitude; later signed active power will carry an explicitly documented
import/export convention.

### System frequency

The frame carries one qualified system-frequency measurement in hertz. It is not copied
into each phase. A future calculation may use one or several voltage channels to
produce this estimate without changing the frame-level meaning.

### Units

The domain schema fixes units rather than carrying unit strings in each frame:

| Quantity | Domain unit |
|---|---|
| RMS line-to-neutral voltage | volt |
| RMS line current | ampere |
| System frequency | hertz |

Producers and adapters convert external representations at ingestion. A field never
alternates between volts and kilovolts, amperes and milliamperes, or hertz and another
frequency unit.

### Numerical and quality invariants

- Present domain values are finite; NaN and infinity are not valid measurements.
- Good and questionable RMS magnitudes are non-negative.
- Good and questionable frequency values are positive.
- An electrical value outside an operational threshold may remain good quality and
  start an event.
- A value violating physical or representation constraints is invalid with an
  appropriate ADR 0003 reason.

Nominal voltage, nominal frequency, current limits, event thresholds, and physical
plausibility bounds belong to feeder or scenario configuration rather than the frame.

## Consequences

### Benefits

- Phase identity and missing-phase behavior are deterministic.
- Voltage values cannot silently mix line-to-neutral and line-to-line meanings.
- Consumers operate on one canonical unit per quantity.
- Partial frames retain usable phases without changing their shape.
- Scenario and deployment configuration can vary nominal voltage and frequency without
  changing the frame schema.
- Later DSP can produce the same measurement abstraction from raw sample blocks.

### Costs and constraints

- V1 directly models only a four-wire wye feeder.
- Delta and three-wire topologies need explicit later modeling rather than pretending
  line-to-neutral values exist.
- Unit conversion is mandatory at external boundaries.
- Fixed phases are less generic than an arbitrary-channel collection, by design.
- Derived and aggregate quantities require future schema extensions.

## Alternatives considered

### Variable collection of phase measurements

Rejected for v1 because an absent entry could be confused with ordering or indexing,
and the product is explicitly a three-phase monitor rather than a generic channel store.

### Generic voltage without an electrical reference

Rejected because the same number has different meaning as line-to-neutral or
line-to-line voltage.

### Carry a selectable unit with every value

Rejected because it complicates every calculation and permits inconsistent producers.
Adapters should normalize values into domain units once.

### Embed nominal values and thresholds in each frame

Rejected because observations and interpretation policy are separate concerns. The same
measurement frame may be evaluated against different scenario configurations.

### Include all future electrical quantities now

Rejected because phase angle, power, energy, imbalance, harmonics, and sequence
components require additional conventions and calculations that v1 does not yet need.

## Deferred decisions

This ADR deliberately does not select:

- concrete C++ aggregate, array, enum, or strong-unit types;
- floating-point or fixed-point numeric representation;
- nominal values for the first deterministic scenario;
- line-to-line voltage representation;
- phase-angle reference and unit;
- active/reactive power sign conventions;
- energy unit and accumulation policy;
- delta and other feeder topology modeling; or
- serialization encoding.

Those choices will be recorded when the corresponding increment requires them.
