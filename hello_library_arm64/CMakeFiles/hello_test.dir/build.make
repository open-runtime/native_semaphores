# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.29

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /opt/homebrew/Cellar/cmake/3.29.0/bin/cmake

# The command to remove a file.
RM = /opt/homebrew/Cellar/cmake/3.29.0/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64

# Include any dependencies generated for this target.
include CMakeFiles/hello_test.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include CMakeFiles/hello_test.dir/compiler_depend.make

# Include the progress variables for this target.
include CMakeFiles/hello_test.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/hello_test.dir/flags.make

CMakeFiles/hello_test.dir/hello.c.o: CMakeFiles/hello_test.dir/flags.make
CMakeFiles/hello_test.dir/hello.c.o: hello.c
CMakeFiles/hello_test.dir/hello.c.o: CMakeFiles/hello_test.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object CMakeFiles/hello_test.dir/hello.c.o"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/hello_test.dir/hello.c.o -MF CMakeFiles/hello_test.dir/hello.c.o.d -o CMakeFiles/hello_test.dir/hello.c.o -c /Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64/hello.c

CMakeFiles/hello_test.dir/hello.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing C source to CMakeFiles/hello_test.dir/hello.c.i"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64/hello.c > CMakeFiles/hello_test.dir/hello.c.i

CMakeFiles/hello_test.dir/hello.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling C source to assembly CMakeFiles/hello_test.dir/hello.c.s"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64/hello.c -o CMakeFiles/hello_test.dir/hello.c.s

# Object files for target hello_test
hello_test_OBJECTS = \
"CMakeFiles/hello_test.dir/hello.c.o"

# External object files for target hello_test
hello_test_EXTERNAL_OBJECTS =

hello_test: CMakeFiles/hello_test.dir/hello.c.o
hello_test: CMakeFiles/hello_test.dir/build.make
hello_test: CMakeFiles/hello_test.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --bold --progress-dir=/Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking C executable hello_test"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/hello_test.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/hello_test.dir/build: hello_test
.PHONY : CMakeFiles/hello_test.dir/build

CMakeFiles/hello_test.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/hello_test.dir/cmake_clean.cmake
.PHONY : CMakeFiles/hello_test.dir/clean

CMakeFiles/hello_test.dir/depend:
	cd /Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64 && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64 /Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64 /Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64 /Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64 /Users/tsavo/Development/Runtime/aot_monorepo/packages/libraries/dart/native_semaphores/hello_library_arm64/CMakeFiles/hello_test.dir/DependInfo.cmake "--color=$(COLOR)"
.PHONY : CMakeFiles/hello_test.dir/depend

