from conan import ConanFile
from conan.tools.cmake import CMakeDeps, CMakeToolchain, cmake_layout

required_conan_version = ">=2.0"


class FieldDeviceLabConan(ConanFile):
    package_type = "application"
    settings = "os", "arch", "compiler", "build_type"

    options = {"with_tests": [True, False]}
    default_options = {"with_tests": True}

    def requirements(self):
        self.requires("nlohmann_json/3.12.0")

    def build_requirements(self):
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
