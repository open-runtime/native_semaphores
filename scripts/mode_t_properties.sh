#!/bin/bash

# This script prints out common mode_t values used with semaphores,
# their size, and demonstrates a pointer to a mode_t variable.

# Create a C source file using a heredoc for correct formatting
cat > print_mode_t.c << 'EOF'
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>

int main() {
    mode_t mode1 = 0644; // Common permission: owner RW, group R, others R
    mode_t mode2 = 0666; // Common permission: owner RW, group RW, others RW
    printf("Common mode_t values for semaphores:\n");
    printf("0644 = Owner can read and write; group and others can read.\n");
    printf("0666 = Everyone can read and write.\n");

    // Print the size of mode_t
    printf("Size of mode_t: %zu bytes\n", sizeof(mode_t));

    // Demonstrating a pointer to a mode_t variable
    mode_t *mode_ptr = (mode_t *)malloc(sizeof(mode_t));
    if (mode_ptr != NULL) {
        *mode_ptr = mode1; // Use mode1 for demonstration
        printf("Pointer to a mode_t variable: %p\n", (void *)mode_ptr);
        printf("Value pointed to by mode_ptr: %o (octal)\n", *mode_ptr);
        free(mode_ptr);
    } else {
        printf("Memory allocation failed\n");
    }

    return 0;
}
EOF

# Compile the C program
gcc print_mode_t.c -o print_mode_t

# Check if the compilation succeeded
if [ $? -eq 0 ]; then
    # Execute the compiled program if compilation was successful
    ./print_mode_t
else
    echo "Compilation failed."
fi

# Clean up: remove the source file and the executable
rm -f print_mode_t.c print_mode_t
