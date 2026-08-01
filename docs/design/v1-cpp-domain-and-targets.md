# V1 C++ Domain and Target Design

Status: accepted direction, 2026-08-01.

This document elaborates [ADR 0006](../adr/0006-use-strong-domain-types-and-thin-cli.md).
The declarations below are design sketches, not a frozen source-level API. Names may be
refined during implementation while preserving the accepted semantics and boundaries.

## Design goals

- Make incompatible quantities and identities distinct to the compiler.
- Own data that may later cross queue, process, or hardware boundaries.
- Keep the electrical/event core independent of CLI and serialization concerns.
- Use bounded storage where the domain is naturally bounded.
- Support malformed-input and transition tests without exceptions as normal control
  flow.
- Avoid polymorphism and target fragmentation until variation requires them.

## Quantity types

Initial quantity wrappers are conceptually:

```cpp
struct VoltsRms {
    double value;
};

struct AmperesRms {
    double value;
};

struct Hertz {
    double value;
};
```

Construction does not silently convert between quantity types. Boundary code performs
explicit unit conversion before creating domain values. Validation owns finite,
positive, and non-negative invariants rather than relying on debug assertions.

The implementation may remove repetition with a small internal template, provided the
public types remain distinct and diagnostics retain meaningful quantity names.

## Quality types

```cpp
enum class Usability {
    good,
    questionable,
    invalid,
    unavailable,
};

enum class QualityReason {
    out_of_physical_range,
    sensor_fault,
    calculation_failed,
    insufficient_samples,
    estimated,
    substituted,
    source_stale,
    configuration_error,
    overflow,
    unknown,
};

class QualityReasons;

template <typename Quantity>
struct Qualified {
    std::optional<Quantity> value;
    Usability usability;
    QualityReasons reasons;
};
```

`QualityReasons` provides named operations such as `contains`, `add`, `empty`, and
iteration over known reasons. Callers do not manipulate its raw bit representation.

Validation enforces ADR 0003, including value presence for good/questionable/invalid,
absence for unavailable, and appropriate reasons for non-good states.

## Identity and time

```cpp
struct SourceId {
    std::string value;
};

struct SessionId {
    std::string value;
};

struct FrameIdentity {
    SourceId source;
    SessionId session;
    std::uint64_t sequence;
};

struct MeasurementTime {
    std::chrono::nanoseconds since_session_start;
};

enum class UtcQuality {
    unavailable,
    unsynchronized,
    estimated,
    synchronized,
};

struct AbsoluteTime {
    std::optional<std::chrono::sys_time<std::chrono::nanoseconds>> value;
    UtcQuality quality;
};
```

Ordering comparisons require matching source and session identity. The domain does not
offer an operation that subtracts measurement times from different sessions.

## Phases and measurement frame

```cpp
enum class Phase {
    a,
    b,
    c,
};

struct PhaseMeasurement {
    Qualified<VoltsRms> voltage_line_to_neutral;
    Qualified<AmperesRms> line_current;
};

struct MeasurementFrame {
    FrameIdentity identity;
    MeasurementTime measurement_time;
    AbsoluteTime absolute_time;
    std::array<PhaseMeasurement, 3> phases;
    Qualified<Hertz> frequency;

    PhaseMeasurement& for_phase(Phase phase);
    const PhaseMeasurement& for_phase(Phase phase) const;
};
```

`for_phase` owns the mapping between the phase enum and fixed storage. Other code does
not depend on enum ordinals or perform unchecked casts.

## Validation

The initial boundary is conceptually:

```cpp
ValidationResult validate(const MeasurementFrame& frame);
```

`ValidationResult` can report more than one error so an adapter or test receives useful
diagnostics in one pass. Expected validation failures do not throw exceptions.

Stateless validation includes:

- source and session identifier presence and configured length/character rules;
- non-negative source measurement time;
- UTC value and quality consistency;
- qualified-value presence and reason invariants;
- finite numeric values;
- non-negative RMS voltage and current; and
- positive frequency.

Sequence gaps, duplicates, inactive sessions, and time regression require receiver
history and remain outside this stateless operation.

## Voltage-sag configuration and transitions

```cpp
struct VoltageSagConfiguration {
    VoltsRms detection_threshold;
    VoltsRms recovery_threshold;
};

enum class EventTransitionKind {
    started,
    ended,
};

struct VoltageSagTransition {
    Phase phase;
    EventTransitionKind kind;
    MeasurementTime time;
    VoltsRms observed_voltage;
    std::optional<std::chrono::nanoseconds> duration;
};
```

Configuration is valid only when the recovery threshold is greater than the detection
threshold. Nominal voltage is useful to construct the scenario configuration but is not
required by the detector after absolute thresholds have been calculated.

```cpp
class VoltageSagDetector {
public:
    explicit VoltageSagDetector(VoltageSagConfiguration configuration);

    std::vector<VoltageSagTransition> process(const MeasurementFrame& frame);

private:
    // One bounded active-sag state per phase.
};
```

The detector expects structurally validated frames, processes good voltage values, and
emits only state transitions. It has no dependency on JSON, standard streams, wall
clocks, command-line arguments, or protocol types.

The first implementation must make validation-before-processing visible in the caller.
If that convention proves too easy to bypass, introduce a validated-frame wrapper in a
later change rather than preemptively creating a complex construction framework.

## Deterministic scenario

```cpp
std::vector<MeasurementFrame> make_phase_b_voltage_sag_scenario();
```

The returned six frames implement the values and timing in the
[v1 executable contract](../specs/v1-executable-contract.md). A vector is acceptable for
this finite fixture. Incremental producer interfaces belong to later live and hardware
increments.

## Serialization and executable boundary

The application layer owns:

- command-line parsing;
- built-in scenario selection;
- calls to validation and the detector;
- conversion of measurements and transitions to JSON Lines;
- standard output and standard error; and
- exit-status mapping.

The JSON serializer consumes domain values but does not add JSON knowledge to them. The
diagnostic schema is not an inter-device or IEC protocol.

## Initial CMake targets

```text
field_device_core
└── alias: field_device::core

grid-monitor
└── private dependency: field_device::core

field-device-unit-tests
└── private dependency: field_device::core + test framework

CTest process-level test
└── invokes: grid-monitor
```

`field_device_core` publishes only its own include directory and C++20 requirement.
Warnings and analysis are applied through project-owned target helpers without leaking
flags to external consumers.

The executable owns any JSON dependency privately. GoogleTest is a host-only test
dependency. Exact dependency acquisition is the next design decision.

## Proposed source layout

```text
include/field_device/
  measurement.hpp
  quality.hpp
  scenario.hpp
  voltage_sag.hpp

src/
  measurement.cpp
  quality.cpp
  scenario.cpp
  voltage_sag.cpp

app/
  diagnostic_json.cpp
  diagnostic_json.hpp
  grid_monitor_main.cpp

tests/
  unit/
  integration/
```

This layout may evolve mechanically during implementation. A change in filenames is
not an architectural change; merging serialization into the core or weakening the
strong domain boundaries would require revisiting ADR 0006.

## Initial test seams

- Quantity and qualified-value validation.
- UTC value/quality invariants.
- Phase access and fixed storage.
- Frame validation with multiple reported failures.
- Sag start, continuation, hysteresis, recovery, and duration.
- Phase independence.
- Deterministic scenario content.
- JSON serialization for every quality state and event transition.
- Process output and exit status against a checked-in golden fixture.
