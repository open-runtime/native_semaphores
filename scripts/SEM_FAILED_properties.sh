#!/bin/bash

# This script prints out a representation of SEM_FAILED and its size.

# Create a C source file
cat > print_sem_failed.c << 'EOF'
#include <stdio.h>
#include <semaphore.h>
#include <stdint.h>

int main() {
    // Print SEM_FAILED as a pointer and as an unsigned integer
    printf("SEM_FAILED = %p (as a pointer), %ju (as an unsigned integer)\n", SEM_FAILED, (uintptr_t)SEM_FAILED);

    // Print the size of SEM_FAILED, which is the size of a pointer on this system
    printf("Size of SEM_FAILED (size of a pointer): %zu bytes\n", sizeof(SEM_FAILED));
    return 0;
}
EOF

# Compile the C program
gcc print_sem_failed.c -o print_sem_failed -pthread

# Check if the compilation succeeded
if [ $? -eq 0 ]; then
    # Execute the compiled program if compilation was successful
    ./print_sem_failed
else
    echo "Compilation failed."
fi

# Clean up: remove the source file and the executable
rm -f print_sem_failed.c print_sem_failed
