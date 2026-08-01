# V1 Build and Dependency Design

Status: accepted direction, 2026-08-01.

This document elaborates
[ADR 0007](../adr/0007-use-conan-for-explicit-host-dependencies.md). Code fragments are
design sketches to guide the first build slice, not files that have already been
implemented.

## Dependency graph

```text
field_device_core
  no third-party runtime dependency

grid-monitor
  field_device::core
  nlohmann_json::nlohmann_json (private)

field-device-unit-tests
  field_device::core
  GTest::gtest_main (private, host tests only)
```

The process-level test invokes `grid-monitor` and does not link to its implementation.

## Conan recipe direction

The root recipe is expected to resemble:

```python
from conan import ConanFile
from conan.tools.cmake import CMakeDeps, CMakeToolchain, cmake_layout


class FieldDeviceLabConan(ConanFile):
    package_type = "application"
    settings = "os", "arch", "compiler", "build_type"

    options = {"with_tests": [True, False]}
    default_options = {"with_tests": True}

    def requirements(self):
        self.requires("nlohmann_json/3.12.0")
        if self.options.with_tests:
            self.test_requires("gtest/1.17.0")

    def layout(self):
        cmake_layout(self)

    def generate(self):
        toolchain = CMakeToolchain(self)
        toolchain.variables["BUILD_TESTING"] = bool(self.options.with_tests)
        toolchain.generate()

        dependencies = CMakeDeps(self)
        dependencies.generate()
```

The implementation must validate this sketch against the installed Conan version.
Recipe behavior, not textual similarity to this example, is the acceptance criterion.

## CMake dependency consumption

The root build remains provider-neutral:

```cmake
find_package(nlohmann_json 3.12 CONFIG REQUIRED)

target_link_libraries(grid-monitor
    PRIVATE
        field_device::core
        nlohmann_json::nlohmann_json
)

include(CTest)

if(BUILD_TESTING)
    find_package(GTest CONFIG REQUIRED)
    target_link_libraries(field-device-unit-tests
        PRIVATE
            field_device::core
            GTest::gtest_main
    )
    include(GoogleTest)
    gtest_discover_tests(field-device-unit-tests)
endif()
```

There is no `FetchContent`, vendored subdirectory, package-manager invocation, or
network fallback in CMake.

## JSON adapter

The application layer owns explicit conversion functions:

```cpp
nlohmann::ordered_json to_json(const MeasurementFrame& frame);
nlohmann::ordered_json to_json(const VoltageSagTransition& transition);
```

The functions live with the executable rather than in domain headers. They insert keys
in the order established by the golden-output fixture and convert:

- strong quantities to values in documented domain units;
- measurement time to integer milliseconds for v1 output;
- enums to stable lowercase strings;
- quality reasons to a deterministic array order;
- absent qualified values to JSON `null`; and
- optional UTC by omitting it in the first scenario as specified.

Each output record uses compact serialization followed by one LF. No locale-sensitive
iomanip formatting participates in JSON generation.

## Developer flow

Dependency resolution is a visible prerequisite:

```text
conan profile detect --force  # only when establishing a local profile
conan install . --build=missing -s build_type=Debug
cmake --preset <generated-or-authored-debug-preset>
cmake --build --preset <debug-build-preset>
ctest --preset <debug-test-preset>
```

The exact preset names and output folders are selected when the first files are
implemented. Project documentation must distinguish one-time profile creation from the
normal build loop.

CMake and Conan must use the same compiler, standard library ABI, architecture, and
build type. CI starts from explicit profiles rather than relying on a developer's
auto-detected state.

## Yocto boundary

The future target flow is:

```text
BitBake recipe
  DEPENDS on nlohmann-json
  supplies the target toolchain and sysroot
  configures BUILD_TESTING=OFF
  invokes normal CMake
```

CMake continues to call `find_package(nlohmann_json CONFIG REQUIRED)`. The Yocto SDK or
recipe sysroot, rather than Conan, satisfies it. If the Yocto package does not expose a
compatible config target, the integration will add a target-side adapter rather than
teaching the application CMake about two package managers.

## Generated and committed files

Commit:

- `conanfile.py`;
- authored `CMakeLists.txt` files and presets;
- project Conan profiles when they become necessary and portable;
- an evaluated lockfile when the supported profile policy is clear; and
- later third-party license notices.

Do not commit:

- Conan cache contents;
- generated Conan toolchains and dependency config files;
- `CMakeUserPresets.json` when it contains machine-local generated paths;
- build trees;
- compiler caches; or
- downloaded package artifacts.

## Smallest mechanical build slice

The first implementation slice proves wiring rather than the full scenario:

1. Add `conanfile.py` with the two pinned dependencies.
2. Add the root target-based CMake build and one project-options helper.
3. Add one authored GCC Debug preset using Ninja and the Conan-generated toolchain flow.
4. Add the smallest compilable strong quantity/frame declaration.
5. Build `field_device_core` as C++20.
6. Build a placeholder `grid-monitor` linked privately to nlohmann/json.
7. Build and discover one GoogleTest linked to the core.
8. Run the build and test commands from a clean build directory.

The placeholder executable need not yet satisfy the full v1 scenario contract. The
slice is complete only when dependency resolution, target boundaries, compilation, and
test discovery work without a CMake download.

## Validation checklist

- [ ] Conan resolves `nlohmann_json/3.12.0`.
- [ ] Conan resolves `gtest/1.17.0` only when tests are enabled.
- [ ] The generated toolchain and CMake build type agree.
- [ ] CMake finds both dependencies through config-mode imported targets.
- [ ] `field_device_core` has no third-party link dependency.
- [ ] `grid-monitor` links nlohmann/json privately.
- [ ] GoogleTest discovery produces at least one passing test.
- [ ] Ninja performs the native GCC Debug build.
- [ ] CMake performs no network access.
- [ ] Generated dependency and build artifacts remain ignored.
