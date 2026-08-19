#pragma once

#include <cstddef>

namespace field_device {

struct VoltsRms {
    double value;
};

struct AmperesRms {
    double value;
};

struct Hertz {
    double value;
};

enum class Phase {
    a,
    b,
    c,
};

namespace detail {

[[nodiscard]] std::size_t phase_index(Phase phase);

}  // namespace detail

}  // namespace field_device
