#!/bin/bash

# This script prints out the values and sizes of O_CREAT and O_EXCL.

# Create a C source file using a heredoc for correct formatting
cat > print_flags.c << 'EOF'
#include <stdio.h>
#include <fcntl.h>

int main() {
    // Print the values of O_CREAT and O_EXCL
    printf("O_CREAT = %d\n", O_CREAT);
    printf("O_EXCL = %d\n", O_EXCL);

    // Print the size of the flags, which is the size of an int
    printf("Size of the flags (size of an int): %zu bytes\n", sizeof(int));

    // Note: Since O_CREAT and O_EXCL are macros (compile-time constants),
    // they do not have a runtime memory address, and thus you cannot
    // directly obtain a pointer to them.
    return 0;
}
EOF

# Compile the C program
gcc print_flags.c -o print_flags

# Check if the compilation succeeded
if [ $? -eq 0 ]; then
    # Execute the compiled program if compilation was successful
    ./print_flags
else
    echo "Compilation failed."
fi

# Clean up: remove the source file and the executable
rm -f print_flags.c print_flags
