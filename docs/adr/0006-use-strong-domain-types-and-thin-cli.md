# ADR 0006: Use strong domain types and a thin CLI boundary

Status: accepted

Date: 2026-08-01

## Context

ADRs 0001 through 0005 define the first measurement frame, event behavior, and
executable boundary without selecting C++ representations. V1 now needs a design that
makes units, identity, time, and quality difficult to mix accidentally while remaining
small enough for the Month 1 build and quality work.

A generic structure made mostly of strings, integers, and doubles would be quick to
write but would permit category and unit mistakes. At the other extreme, a hierarchy of
interfaces, per-concept libraries, dynamic polymorphism, and framework abstractions
would add indirection before variation exists.

The event logic must also remain reusable when built-in scenarios are replaced by
waveform processing, RTOS input, an HMI, or protocol adapters.

## Decision

V1 uses owning, strongly typed C++20 value objects and one reusable core library behind
a thin command-line executable.

### Domain values

- RMS voltage, RMS current, and frequency use distinct quantity wrappers rather than
  interchangeable raw doubles.
- Source and session identifiers are distinct owning string-backed types.
- Sequence uses an unsigned 64-bit conceptual range.
- Source measurement time is represented as a chrono duration since the start of the
  source session, with nanoseconds as the canonical internal duration.
- Optional UTC time and its trust state remain separate from source-monotonic time.
- Frames and events own their data; persistent domain objects do not retain borrowed
  string views.

### Measurement quality and phases

- A generic qualified-value type combines an optional quantity, usability, and bounded
  quality-reason flags.
- Quality reasons use a bounded set abstraction with no duplicate entries or per-value
  dynamic allocation.
- Phase A, B, and C use fixed storage with named phase access.
- Numeric indices may be an implementation detail but are not the public domain
  meaning.

### Validation

- Frame validation is an explicit, pure operation that reports domain errors without
  using exceptions for expected invalid input.
- Stateless validation checks identifier presence, time and UTC consistency,
  qualified-value invariants, finite values, and physical representation constraints.
- Stateful sequence and session ordering remains a receiver responsibility.
- The first implementation may use aggregates plus validation; a separate validated
  wrapper is introduced only if accidental bypass becomes a demonstrated risk.

### Event processing

- A stateful voltage-sag detector owns one active state per phase.
- It receives measurement frames and explicit voltage-sag configuration.
- It reads no wall clock and uses source measurement time for event duration.
- It emits transition value objects and performs no JSON, console, protocol, or storage
  work.

### Target boundaries

The first production targets are:

- `field_device_core`, exposed to CMake consumers as `field_device::core`, containing
  domain types, validation, the sag detector, and the deterministic scenario; and
- `grid-monitor`, containing command-line handling, scenario selection, diagnostic JSON
  serialization, standard streams, and exit-status mapping.

Unit tests link to the core target. A process-level CTest test invokes the executable.
Additional libraries are created only when a real dependency or deployment boundary
justifies them.

The concrete sketches and proposed file layout are maintained in
[the v1 C++ design](../design/v1-cpp-domain-and-targets.md).

## Consequences

### Benefits

- The compiler distinguishes electrical quantities, identifiers, and time domains.
- Value ownership makes lifetimes explicit and safe across future queues and adapters.
- Bounded quality storage is predictable for embedded targets.
- Core behavior can be tested without the CLI or JSON layer.
- Future producers and consumers can reuse the same measurement and event boundary.
- Two production targets demonstrate target-based CMake without artificial
  fragmentation.

### Costs and constraints

- Strong wrappers require explicit construction, conversion, comparison, and output.
- Qualified-value invariants require validation and thorough tests.
- One core library contains concepts that may later deserve separate targets.
- Aggregate-plus-validation design permits invalid intermediate objects until the
  processing boundary checks them.
- Nanosecond canonical time requires explicit conversion at external boundaries.

## Alternatives considered

### Use primitive values throughout

Rejected because strings, integers, and doubles would allow identifiers, units, and
time domains to be mixed without compiler help.

### Adopt a full units library immediately

Rejected because v1 has three electrical quantities and does not yet justify another
template system or runtime dependency. The wrappers preserve a migration path.

### Use inheritance and virtual interfaces for producers and detectors

Rejected because v1 has one scenario and one detector. Concrete value-oriented design
is easier to understand, test, and optimize.

### Create one CMake target per domain concept

Rejected because no current deployment or dependency boundary justifies the resulting
build graph and maintenance cost.

### Put JSON serialization in the core library

Rejected because diagnostic output, HMI models, and utility protocols are independent
adapters around the domain.

## Deferred decisions

This ADR deliberately does not select:

- exact header and namespace spelling;
- the precise strong-wrapper implementation;
- bitset versus integer-mask storage for quality reasons;
- a JSON library;
- GoogleTest and Conan integration details;
- warning, sanitizer, and static-analysis configuration;
- error aggregation and formatting types;
- a validated-frame wrapper; or
- future library splits.

Those choices remain implementation details or later decisions unless they become
architecturally significant.
