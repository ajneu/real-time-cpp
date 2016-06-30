function(common_prefix str1 str2 prefix)
  set(len 1)
  while (ON)
    string(SUBSTRING ${str1} 0 ${len} substr1)
    string(SUBSTRING ${str2} 0 ${len} substr2)
    if (NOT ${substr1} STREQUAL ${substr2})
      break()
    endif()
    MATH(EXPR len "${len}+1")
  endwhile()

  MATH(EXPR len "${len}-1")
  string(SUBSTRING ${str1} 0 ${len} substr)
  set(${prefix} ${substr} PARENT_SCOPE)
endfunction()

## CMake only defines a few binutils such as
## CMAKE_AR CMAKE_RANLIB CMAKE_STRIP CMAKE_LINKER CMAKE_NM CMAKE_OBJDUMP CMAKE_OBJCOPY
## (see https://github.com/Kitware/CMake/blob/master/Modules/CMakeFindBinUtils.cmake )

## We use the common prefix of those CMAKE_OBJCOPY and CMAKE_NM, which will help us find other binutils such as CMAKE_CXX_FILT and CMAKE_SIZE (see further below)
common_prefix(
  ${CMAKE_OBJCOPY} # e.g. /usr/bin/avr-objcopy
  ${CMAKE_NM}      # e.g. /usr/bin/avr-nm
                   #      --------------------
  prefix)          #      /usr/bin/avr-          ## ${prefix} will get this value

get_filename_component(toolchain_prefix   ${prefix} NAME)      # avr-          ## ${toolchain_prefix}   will get this value
get_filename_component(toolchain_location ${prefix} DIRECTORY) # /usr/bin      ## ${toolchain_location} will get this value

find_program(CMAKE_ADDR2LINE NAMES ${toolchain_prefix}addr2line HINTS ${toolchain_location})
find_program(CMAKE_CXX_FILT  NAMES ${toolchain_prefix}c++filt   HINTS ${toolchain_location})
find_program(CMAKE_SIZE      NAMES ${toolchain_prefix}size      HINTS ${toolchain_location})
find_program(CMAKE_LD_BFD    NAMES ${toolchain_prefix}ld.bfd    HINTS ${toolchain_location})
find_program(CMAKE_LD_GOLD   NAMES ${toolchain_prefix}ld.gold   HINTS ${toolchain_location})
find_program(CMAKE_GOLD      NAMES ${toolchain_prefix}gold      HINTS ${toolchain_location})
find_program(CMAKE_STRINGS   NAMES ${toolchain_prefix}strings   HINTS ${toolchain_location})
find_program(CMAKE_GPROF     NAMES ${toolchain_prefix}gprof     HINTS ${toolchain_location})
find_program(CMAKE_NLMCONV   NAMES ${toolchain_prefix}nlmconv   HINTS ${toolchain_location})
find_program(CMAKE_READELF   NAMES ${toolchain_prefix}readelf   HINTS ${toolchain_location})
find_program(CMAKE_ELFEDIT   NAMES ${toolchain_prefix}elfedit   HINTS ${toolchain_location})
find_program(CMAKE_DWP       NAMES ${toolchain_prefix}dwp       HINTS ${toolchain_location})
find_program(CMAKE_WINDMC    NAMES ${toolchain_prefix}windmc    HINTS ${toolchain_location})
find_program(CMAKE_WINDRES   NAMES ${toolchain_prefix}windres   HINTS ${toolchain_location})
find_program(CMAKE_DLLTOOL   NAMES ${toolchain_prefix}dlltool   HINTS ${toolchain_location})
find_program(CMAKE_GCOV      NAMES ${toolchain_prefix}gcov      HINTS ${toolchain_location})

mark_as_advanced(CMAKE_ADDR2LINE CMAKE_CXX_FILT CMAKE_SIZE CMAKE_LD_BFD CMAKE_LD_GOLD CMAKE_GOLD
  CMAKE_STRINGS CMAKE_GPROF CMAKE_NLMCONV CMAKE_READELF CMAKE_ELFEDIT CMAKE_DWP
  CMAKE_WINDMC CMAKE_WINDRES CMAKE_DLLTOOL CMAKE_GCOV)
