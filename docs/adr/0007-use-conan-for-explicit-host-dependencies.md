# ADR 0007: Use Conan for explicit host dependencies

Status: accepted

Date: 2026-08-01

## Context

The first executable needs correct JSON serialization and GoogleTest-based unit tests.
The career plan also calls for authored CMake and a demonstrated Conan workflow while
preserving Yocto as the future target dependency authority.

CMake can consume dependencies from many providers. Making it download packages or
invoke a package manager during configuration would mix responsibilities, obscure
network access, and complicate offline, CI, SDK, and cross-compilation workflows.

The project needs a host flow that is explicit and reproducible without coupling the
core domain library or future Yocto recipe to Conan.

## Decision

Conan 2 resolves pinned host dependencies in an explicit step before CMake
configuration.

### Dependencies

- `nlohmann_json/3.12.0` is a normal host requirement.
- `gtest/1.17.0` is a test-only host requirement and can be disabled.
- `grid-monitor` links privately to `nlohmann_json::nlohmann_json`.
- Unit tests link privately to `GTest::gtest_main` and use CMake test discovery.
- `field_device_core` links to neither dependency.

The application serializer uses `nlohmann::ordered_json` through explicit adapter
functions. Domain headers do not include JSON headers or define intrusive JSON
conversions.

### Conan and CMake boundary

- A root `conanfile.py` declares exact dependency versions, host settings, an optional
  test dependency, `cmake_layout`, `CMakeToolchain`, and `CMakeDeps`.
- Developers and CI run `conan install` explicitly before CMake.
- CMake never invokes Conan and never downloads a fallback dependency.
- CMake uses config-mode `find_package` and standard imported targets.
- CMake remains unaware whether a package came from Conan, a system installation, or a
  cross-compilation sysroot.
- The stable `CMakeDeps` generator is used while `CMakeConfigDeps` remains experimental.

### Host and target package authority

- Conan owns dependency resolution for native host builds and tests.
- The future Yocto/BitBake build owns target dependency resolution.
- Target builds disable host tests and obtain nlohmann/json from the Yocto sysroot.
- Conan is not invoked from the BitBake target build.

### Reproducibility and generated state

- Dependency versions are pinned in the recipe.
- Conan caches, generated toolchains, generated dependency files, and build trees are
  not committed.
- A Conan lockfile is considered after GCC and Clang host flows are working and its
  profile implications are understood.
- Third-party licenses are recorded before the first public executable release.
- `--build=missing` is used visibly in developer/CI commands rather than hidden in CMake.

No CLI, logging, formatting, units, validation, or scenario-file dependency is added in
the first slice.

The concrete flow is maintained in
[the v1 build and dependency design](../design/v1-build-and-dependencies.md).

## Consequences

### Benefits

- Dependency network access is explicit and separable from CMake configuration.
- CMake demonstrates standard imported-target consumption rather than package-manager
  scripting.
- The domain library remains dependency-light and reusable.
- Host tests do not leak into the target image.
- Yocto can replace Conan as package authority without rewriting target CMake logic.
- JSON escaping and structure rely on a mature library rather than handwritten output.

### Costs and constraints

- A fresh host requires Conan and an install step before configuration.
- Conan and CMake build types and compilers must remain aligned.
- Native and Yocto providers must expose compatible CMake package targets.
- Exact version pins require deliberate upgrades.
- Ordered golden JSON output becomes part of process-level compatibility tests.

## Alternatives considered

### Handwrite JSON serialization

Rejected because correct escaping, nested structures, optional values, and stable output
would create avoidable application code and testing burden.

### Use CMake FetchContent

Rejected because CMake configuration would perform dependency acquisition, duplicate
Conan's role, and make offline and provider substitution less explicit.

### Make CMake invoke Conan automatically

Rejected because Conan's documented explicit install-before-CMake flow is clearer and
more stable for CI, profiles, IDEs, and cross compilation.

### Use CMakeConfigDeps immediately

Rejected for the initial build because current Conan documentation marks it
experimental and subject to breaking changes. The stable CMakeDeps flow is sufficient
for these dependencies.

### Use Conan for Yocto target dependencies

Rejected because BitBake must remain the target image, sysroot, license, and package
authority.

### Vendor dependency source trees

Rejected because it would add third-party code and update work to this portfolio without
improving the demonstrated architecture.

## Deferred decisions

This ADR deliberately does not select:

- Conan profile files and lockfile policy;
- exact GCC and Clang preset wiring;
- CI cache keys and remote policy;
- the Yocto recipe and nlohmann-json package integration;
- third-party notice format;
- JSON schema versioning beyond the v1 executable contract; or
- dependency vulnerability-scanning policy.

Those choices will be recorded or implemented when their increment requires them.

## References

- [Conan CMake integration](https://docs.conan.io/2/integrations/cmake.html)
- [Conan CMakeConfigDeps status](https://docs.conan.io/2/reference/tools/cmake/cmakeconfigdeps.html)
- [nlohmann/json CMake integration](https://json.nlohmann.me/integration/cmake/)
- [nlohmann_json on Conan Center](https://conan.io/center/recipes/nlohmann_json)
- [GoogleTest on Conan Center](https://conan.io/center/recipes/gtest)
- [GoogleTest CMake quickstart](https://google.github.io/googletest/quickstart-cmake.html)
