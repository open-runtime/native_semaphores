#!/bin/bash

# This script prints out the value of NAME_MAX and the size of an int.

# Create a C source file
cat > print_name_max.c << 'EOF'
#include <stdio.h>
#include <limits.h>
#include <stdlib.h>

int main() {
    printf("NAME_MAX = %d\n", NAME_MAX);
    printf("Size of NAME_MAX (size of an int): %zu bytes\n", sizeof(int));
    // While we cannot get a pointer to NAME_MAX directly (it's a macro),
    // here's how you might store and use its value dynamically:
    int *name_max_ptr = (int *)malloc(sizeof(int));
    if (name_max_ptr != NULL) {
        *name_max_ptr = NAME_MAX;
        printf("Dynamically stored NAME_MAX value: %d\n", *name_max_ptr);
        printf("Pointer to the dynamically stored NAME_MAX value: %p\n", (void *)name_max_ptr);
        free(name_max_ptr);
    } else {
        printf("Memory allocation failed\n");
    }
    return 0;
}
EOF

# Compile the C program
gcc print_name_max.c -o print_name_max

# Check if the compilation succeeded
if [ $? -eq 0 ]; then
    # Execute the compiled program if compilation was successful
    ./print_name_max
else
    echo "Compilation failed."
fi

# Clean up: remove the source file and the executable
rm -f print_name_max.c print_name_max
