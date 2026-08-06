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
