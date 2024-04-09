#!/bin/bash

# This script prints out the value of SEM_VALUE_MAX,
# its size, and demonstrates using a named semaphore.

# Create a C source file
cat > print_sem_value_max.c << 'EOF'
#include <stdio.h>
#include <stdlib.h> // Include for EXIT_SUCCESS and EXIT_FAILURE
#include <limits.h>
#include <semaphore.h>
#include <fcntl.h> // For O_CREAT, O_EXCL
#include <sys/stat.h> // For mode constants

int main() {
    sem_t *semExample;
    const char *semName = "/exampleSem";

    printf("SEM_VALUE_MAX = %ld\n", (long)SEM_VALUE_MAX);
    printf("Size of SEM_VALUE_MAX: %zu bytes\n", sizeof(SEM_VALUE_MAX));

    // Create a new named semaphore with an initial value of 1
    semExample = sem_open(semName, O_CREAT | O_EXCL, 0644, 1);
    if (semExample == SEM_FAILED) {
        perror("Failed to open semaphore");
        return EXIT_FAILURE;
    }

    printf("Pointer to the opened semaphore: %p\n", (void *)semExample);

    // Close the semaphore
    if (sem_close(semExample) != 0) {
        perror("Failed to close semaphore");
        // Attempt to unlink to clean up
        sem_unlink(semName);
        return EXIT_FAILURE;
    }

    // Unlink the semaphore, removing its name
    if (sem_unlink(semName) != 0) {
        perror("Failed to unlink semaphore");
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
EOF

# Compile the C program
gcc print_sem_value_max.c -o print_sem_value_max -pthread

# Check if the compilation succeeded
if [ $? -eq 0 ]; then
    # Execute the compiled program if compilation was successful
    ./print_sem_value_max
else
    echo "Compilation failed."
fi

# Clean up: remove the source file and the executable
rm -f print_sem_value_max.c print_sem_value_max
