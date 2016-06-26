cmake_minimum_required(VERSION 2.8)

if (CMAKE_TOOLCHAIN_FILE AND EXISTS ${CMAKE_TOOLCHAIN_FILE})
  message("==> Loading \${CMAKE_TOOLCHAIN_FILE} == ${CMAKE_TOOLCHAIN_FILE}")

else()

  set(CMAKE_SYSTEM_NAME      Generic)
  set(CMAKE_SYSTEM_PROCESSOR avr)

  if ("${CROSS_COMPILE}" STREQUAL "")
    set (CROSS_COMPILE "avr-")
  endif()

  set (CMAKE_C_COMPILER   "${CROSS_COMPILE}gcc")
  set (CMAKE_CXX_COMPILER "${CROSS_COMPILE}g++")
  set (CMAKE_ASM_COMPILER "${CROSS_COMPILE}as")
  #set (CMAKE_MAKE_PROGRAM "make") # "mingw32-make" "mingw64-make"

  
endif()


#######

project(led_project)



## find binutils (CMAKE_CXX_FILT, CMAKE_SIZE)

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

## CMake only defines a few binutils such as CMAKE_OBJCOPY and CMAKE_NM (see https://github.com/Kitware/CMake/blob/master/Modules/CMakeFindBinUtils.cmake )
## We use the common prefix of those two, which will help us find other binutils such as CMAKE_CXX_FILT and CMAKE_SIZE (see further below)
common_prefix(
  ${CMAKE_OBJCOPY} # e.g. /usr/bin/avr-objcopy
  ${CMAKE_NM}      # e.g. /usr/bin/avr-nm
                   #      --------------------
  prefix)          #      /usr/bin/avr-          ## ${prefix} will get this value

get_filename_component(toolchain_prefix   ${prefix} NAME)      # avr-          ## ${toolchain_prefix}   will get this value
get_filename_component(toolchain_location ${prefix} DIRECTORY) # /usr/bin      ## ${toolchain_location} will get this value

find_program(CMAKE_CXX_FILT  NAMES ${toolchain_prefix}c++filt  HINTS ${toolchain_location})
find_program(CMAKE_SIZE      NAMES ${toolchain_prefix}size     HINTS ${toolchain_location})






###########
# Debug or Release
###########
if (NOT CMAKE_BUILD_TYPE)
  ## set default to Release
  set(CMAKE_BUILD_TYPE Release)  # override with -DCMAKE_BUILD_TYPE=Debug
  message("==> CMAKE_BUILD_TYPE empty. Changing it to Release.")
else()
  message("==> CMAKE_BUILD_TYPE == ${CMAKE_BUILD_TYPE}.")
endif()


###########
# Warnings
###########
if (CMAKE_COMPILER_IS_GNUCC)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -pedantic")
  # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unused-parameter -Wno-unused-variable -Wno-unused-but-set-variable")  # suppress
  # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations") # suppress
endif ()



##############
# C++ Standard
##############
if (NOT    CMAKE_VERSION VERSION_LESS 3.1)
  set(CMAKE_CXX_STANDARD   14)
  set(CMAKE_CXX_EXTENSIONS OFF)
else()
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
endif()



# for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)





###############
# Flags
###############
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mmcu=atmega328p -fsigned-char")

# get rid of -rdynamic
set (CMAKE_SHARED_LIBRARY_LINK_C_FLAGS)
set (CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS)



macro(replace_flag list flag repl_flag)
  string(REPLACE "${flag}" "${repl_flag}" ${list} "${${list}}")
endmacro()

# When cmake'ing with -DCMAKE_BUILD_TYPE=Release then
# by default "${CMAKE_CXX_FLAGS_RELEASE}"   ...            is "-O3 -DNDEBUG"
replace_flag(   CMAKE_CXX_FLAGS_RELEASE "-O3" "-O2") ## change -O3 to -O2


##############
# Build
##############
set(target led)
set(CMAKE_EXECUTABLE_SUFFIX ".elf")
set(src crt0.s led.cpp)


if (ON)
  # https://github.com/projectNe10/Ne10/blob/a08b29d88e3c94d32b5b8f827e7fcf0bc2b34ac2/modules/CMakeLists.txt#L41
  set_property(SOURCE         crt0.s PROPERTY LANGUAGE CXX)
  set_source_files_properties(crt0.s PROPERTIES COMPILE_FLAGS "-x assembler")
else()
  #alternative
  enable_language(ASM)
  set(CMAKE_ASM_FLAGS         "-mmcu=atmega328p")
  set(CMAKE_ASM_FLAGS_RELEASE "")
endif()




include_directories(.)


set(CMAKE_SHARED_LINKER_FLAGS "-nostartfiles -nostdlib -Wl,-T${CMAKE_CURRENT_SOURCE_DIR}/avr.ld,-Map,${CMAKE_BINARY_DIR}/${target}.map")
set(CMAKE_MODULE_LINKER_FLAGS "-nostartfiles -nostdlib -Wl,-T${CMAKE_CURRENT_SOURCE_DIR}/avr.ld,-Map,${CMAKE_BINARY_DIR}/${target}.map")
set(CMAKE_EXE_LINKER_FLAGS    "-nostartfiles -nostdlib -Wl,-T${CMAKE_CURRENT_SOURCE_DIR}/avr.ld,-Map,${CMAKE_BINARY_DIR}/${target}.map")


add_executable(${target} ${src})
#set_target_properties (${target}
#  PROPERTIES LINK_FLAGS "-nostartfiles -nostdlib -Wl,-T${CMAKE_CURRENT_SOURCE_DIR}/avr.ld,-Map,${CMAKE_BINARY_DIR}/${target}.map")




set(target_with_suffix "${target}${CMAKE_EXECUTABLE_SUFFIX}")

add_custom_command (TARGET ${target}  POST_BUILD
  COMMENT "Extract  : executable hex file : from ${target_with_suffix}"
  COMMAND ${CMAKE_OBJCOPY} -O ihex                $<TARGET_FILE:${target}>    $<TARGET_FILE_DIR:${target}>/${target}.hex
  )

add_custom_command (TARGET ${target}  POST_BUILD
  COMMENT "Extract  : assembly list file  : from ${target_with_suffix}"
  COMMAND ${CMAKE_OBJDUMP} -h -S                  $<TARGET_FILE:${target}>  > $<TARGET_FILE_DIR:${target}>/${target}.lss
  )

add_custom_command (TARGET ${target}  POST_BUILD
  COMMENT "Extract  : size information    : from ${target_with_suffix}"
  COMMAND ${CMAKE_SIZE} -A -t                     $<TARGET_FILE:${target}>  > $<TARGET_FILE_DIR:${target}>/${target}_size.txt
  )

add_custom_command (TARGET ${target}  POST_BUILD
  COMMENT "Extract  : name information    : from ${target_with_suffix}"
  COMMAND ${CMAKE_NM} --numeric-sort --print-size $<TARGET_FILE:${target}>  > $<TARGET_FILE_DIR:${target}>/${target}_nm.txt
  )

add_custom_command (TARGET ${target}  POST_BUILD
  COMMENT "Extract  : demangled names     : from ${target_with_suffix}"
  COMMAND ${CMAKE_NM} --numeric-sort --print-size $<TARGET_FILE:${target}>  | ${CMAKE_CXX_FILT}  > $<TARGET_FILE_DIR:${target}>/${target}_cppfilt.txt
)
