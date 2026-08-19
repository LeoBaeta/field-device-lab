#include "field_device/measurement.hpp"

#include <stdexcept>

namespace field_device::detail {

std::size_t phase_index(const Phase phase)
{
    switch (phase) {
    case Phase::a:
        return 0;
    case Phase::b:
        return 1;
    case Phase::c:
        return 2;
    }

    throw std::invalid_argument{"Unknown electrical phase"};
}

}  // namespace field_device::detail
