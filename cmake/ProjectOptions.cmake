# Standard C++ only, without GNU extensions (-std=c++20, not -std=gnu++20). Set in the
# project rather than left to a toolchain file, so it holds whichever provider
# configured the build (Conan toolchain, Yocto SDK or recipe).
set(CMAKE_CXX_EXTENSIONS OFF)

option(
    FIELD_DEVICE_WARNINGS_AS_ERRORS
    "Treat project compiler warnings as errors"
    OFF
)

function(field_device_apply_warnings target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "Unknown target: ${target}")
    endif()

    target_compile_options(
        "${target}"
        PRIVATE
            $<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang>:
                -Wall
                -Wextra
                -Wpedantic
            >
    )

    if(FIELD_DEVICE_WARNINGS_AS_ERRORS)
        target_compile_options(
            "${target}"
            PRIVATE
                $<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang>:-Werror>
        )
    endif()
endfunction()
