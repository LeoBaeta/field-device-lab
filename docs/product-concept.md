# Product Concept

## Purpose

Field Device Lab emulates a fictional three-phase distribution-feeder monitoring
intelligent electronic device (IED). It processes synthetic electrical measurements,
calculates grid quantities, detects and records abnormal conditions, and presents
device and feeder status locally and remotely.

The project begins as a host-based simulation and may later be distributed across an
ESP32 RTOS measurement node and a BeagleBone Black running a custom Yocto Linux image.
Future increments may provide a real-time local HMI and standards-informed
IEC 60870-5-104 and IEC 61850 interoperability experiments.

This is an educational monitoring system. It is not protection equipment, production
control equipment, or a standards-conformant utility product.

## Fictional deployment

The emulated IED is installed at a distribution feeder. A measurement front end
provides three-phase electrical information to the device. The device evaluates feeder
conditions, maintains timestamped events, makes current state available to a local
operator, and may publish selected information to a station or control-center system.

Everything outside the IED is simulated. The project does not require or permit direct
connection to mains voltage.

Candidate scenarios include:

- normal balanced operation;
- voltage sag and swell;
- phase loss or imbalance;
- overcurrent;
- frequency deviation;
- simulated breaker transitions;
- communication interruption;
- invalid or corrupted measurements;
- event bursts; and
- restart and recovery.

These scenarios describe the intended product space. Their precise definitions,
thresholds, and implementation order remain open design decisions.

## Development horizons

### 1. Host-based functional simulation

The first horizon runs on a development computer. It establishes the electrical domain
model, deterministic synthetic input, measurement processing, event behavior, testing,
and reproducible build workflow without requiring hardware.

### 2. Real-time hardware demonstration

An ESP32 may act as an RTOS-based measurement node or signal simulator. It may generate
or acquire synthetic samples, execute periodic work, timestamp data, report missed
deadlines, and deliver measurements to the Linux device.

A BeagleBone Black may host the monitoring IED on a custom Yocto image. It may receive
measurements, process and store events, expose device health, and run local services.
Experiments may compare scheduling, latency, load, failure, and recovery behavior.

Arduino Mega or similar boards may optionally emulate equipment states, digital inputs,
relay feedback, or independent fault injection. They are not required by the core
architecture.

### 3. HMI and interoperability lab

A later local HMI may display a single-line representation, electrical quantities,
waveforms, trends, active alarms, event history, breaker state, communication status,
and device health in real time.

IEC 60870-5-104 may later represent northbound telecontrol communication with a
simulated SCADA or control center. IEC 61850 may later inform the semantic model, SCL
configuration, MMS reporting, or other bounded interoperability experiments. The
internal domain model should remain independent of either protocol.

## Product boundaries

- The initial product is a monitoring and event-recording IED, not a protection relay.
- All signals, identifiers, configurations, and operational scenarios are synthetic.
- Hardware integration is optional; host execution remains a supported path.
- Real-time claims must be supported by measurements and clearly distinguish soft,
  firm, and hard real-time behavior.
- Standards-related work is described as standards-informed or interoperable only to
  the extent demonstrated. Conformance is not implied.
- Employer code, proprietary protocols, customer requirements, field data, production
  keys, confidential architectures, and internal terminology are outside the project.
- No feature may operate real electrical equipment or require unsafe mains access.

## Deliberately open decisions

This concept does not yet choose:

- whether the first input contains raw waveform samples or calculated measurements;
- sampling frequency, windowing, synchronization, or numerical methods;
- nominal voltage, current, and frequency values;
- event thresholds, timing requirements, or severity rules;
- the initial host/ESP32/BeagleBone responsibility split;
- the link and application protocol between hardware nodes;
- the HMI framework or graphics stack;
- an IEC 60870-5-104 or IEC 61850 library;
- storage technology; or
- a product name.

Each decision should be discussed and recorded only when it becomes necessary for the
next bounded increment.
