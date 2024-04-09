#!/bin/bash

# Define the C program using a Bash heredoc to ensure proper formatting
cat > sem_size.c << 'EOF'
#include <stdio.h>
#include <semaphore.h>
int main() {
    printf("sizeof(sem_t) = %zu bytes\n", sizeof(sem_t));
    return 0;
}
EOF

# Compile the C program
gcc sem_size.c -o sem_size -pthread

# Check if the compilation succeeded
if [ $? -eq 0 ]; then
    # Run the compiled program if compilation was successful
    ./sem_size
else
    echo "Compilation failed."
fi

# Clean up: remove the source and binary files
rm -f sem_size.c sem_size