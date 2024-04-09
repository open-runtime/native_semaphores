#!/bin/bash

# This script prints out the values and sizes of O_CREAT and O_EXCL.

# Create a C source file using a heredoc for correct formatting
cat > test_semaphore.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <semaphore.h>
#include <fcntl.h>           /* For O_* constants */
#include <sys/stat.h>        /* For mode constants */
#include <unistd.h>

#define SEM_NAME "/my_named_semaphore"

int main() {
    sem_t *sem;

    // Try to create a semaphore with initial value = 1.
    // | O_EXCL
    sem = sem_open(SEM_NAME, O_CREAT, 0644, 1);

    printf("Value of O_CREAT: %d\n", O_CREAT);
    printf("Value of O_EXCL: %d\n", O_EXCL);

    if (sem == SEM_FAILED) {
        perror("sem_open error");
        exit(EXIT_FAILURE);
    }

    printf("Locking the semaphore...\n");

    // Lock the semaphore by decrementing its value by one.
    // If the value is already 0, this call will block until it can decrement the value.
    if (sem_wait(sem) < 0) {
        perror("sem_wait error");
        exit(EXIT_FAILURE);
    }

    printf("Inside critical section. Press enter to unlock...\n");
    // Wait for user input to simulate critical section work.
    getchar();

    // Unlock the semaphore by incrementing its value by one.
    // If there are any processes or threads waiting, one will become unblocked.
    if (sem_post(sem) < 0) {
        perror("sem_post error");
        exit(EXIT_FAILURE);
    }

    printf("Semaphore unlocked. Exiting...\n");

    // Close the semaphore.
    if (sem_close(sem) < 0) {
        perror("sem_close error");
        exit(EXIT_FAILURE);
    }

    // Unlink the semaphore. After this point, the name can be reused.
    if (sem_unlink(SEM_NAME) < 0) {
        perror("sem_unlink error");
        exit(EXIT_FAILURE);
    }

    return EXIT_SUCCESS;
}
EOF

# Compile the C program
gcc test_semaphore.c -o test_semaphore

# Check if the compilation succeeded
if [ $? -eq 0 ]; then
    # Execute the compiled program if compilation was successful
    ./test_semaphore
else
    echo "Compilation failed."
fi

# Clean up: remove the source file and the executable
rm -f test_semaphore.c test_semaphore
