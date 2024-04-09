#!/bin/bash

# This script prints out the value of PATH_MAX,
# the size in bytes for a path string,
# and uses a pointer example related to path handling.

# Create a C source file
cat > print_path_max.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

int main() {
    char *pathExample;

    printf("PATH_MAX = %d\n", PATH_MAX);
    printf("Size in bytes for a path (including null terminator): %lu\n", (unsigned long)PATH_MAX + 1);

    // Dynamically allocate memory for a path of PATH_MAX length
    pathExample = (char *)malloc((PATH_MAX + 1) * sizeof(char));
    if (pathExample == NULL) {
        perror("Failed to allocate memory");
        return EXIT_FAILURE;
    }

    // Example use of the pointer
    printf("Pointer to the allocated path storage: %p\n", (void *)pathExample);

    // Remember to free allocated memory
    free(pathExample);

    return EXIT_SUCCESS;
}
EOF

# Compile the C program
gcc print_path_max.c -o print_path_max

# Check if the compilation succeeded
if [ $? -eq 0 ]; then
    # Execute the compiled program if compilation was successful
    ./print_path_max
else
    echo "Compilation failed."
fi

# Clean up: remove the source file and the executable
rm -f print_path_max.c print_path_max
