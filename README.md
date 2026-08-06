# Field Device Lab

Field Device Lab is an educational C++ simulation of a fictional three-phase
distribution-feeder monitoring device. It begins as a deterministic host application
and may later expand into RTOS, embedded Linux, HMI, and utility-protocol experiments.

All measurements and operating scenarios are synthetic. This project is not protection
equipment, production control equipment, or a standards-conformant utility product.

See the [product concept](docs/product-concept.md) and
[development roadmap](docs/development-roadmap.md) for the intended scope and
milestones.

## Prerequisites

The native development workflow uses:

- GCC with C++20 support;
- CMake 3.25 or newer;
- Ninja;
- Conan 2; and
- Python with `pipx` for an isolated Conan installation.

On Ubuntu, Ninja and pipx can be installed through APT, and Conan through pipx:

```bash
sudo apt-get install ninja-build pipx
pipx install conan
```

## First-time Conan setup

Create a Conan profile once for the local compiler and platform:

```bash
conan profile detect
```

Review the generated profile before using it:

```bash
conan profile show
```

Conan stores this machine-local configuration outside the repository under
`~/.conan2/profiles/`.

## Configure and build

Run dependency resolution explicitly before CMake configuration:

```bash
conan install . \
  --build=missing \
  -s build_type=Debug \
  -s compiler.cppstd=20 \
  -c tools.cmake.cmaketoolchain:generator=Ninja
```

Then configure and build with the authored GCC Debug preset:

```bash
cmake --preset gcc-debug
cmake --build --preset gcc-debug
```

Once test targets are present, run them with:

```bash
ctest --preset gcc-debug
```

The current mechanical checkpoint has no source or test targets yet, so configuration
and the empty build succeed, while the strict test preset intentionally reports an
error until the first test is registered.

Generated Conan metadata, CMake user presets, and build output are placed under
`build/` or other ignored paths and must not be committed.

## Build-system boundary

- Conan resolves pinned dependencies and generates integration metadata.
- CMake defines project targets and consumes dependencies through imported targets.
- Ninja executes the generated compiler and linker commands.
- CMake does not download dependencies or invoke Conan.

The accepted rationale and detailed dependency graph are documented in
[ADR 0007](docs/adr/0007-use-conan-for-explicit-host-dependencies.md) and the
[v1 build and dependency design](docs/design/v1-build-and-dependencies.md).

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
