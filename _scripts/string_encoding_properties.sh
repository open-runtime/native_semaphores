#!/bin/bash

# Create a C source file
cat > string_encoding_properties.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <semaphore.h>
#include <fcntl.h> // For O_CREAT, O_EXCL
#include <sys/stat.h> // For mode constants
#include <stdio.h>
#include <string.h>
#include <wchar.h>

void printCharAndRadixW(const wchar_t* string) {
    wprintf(L"Characters: ");
    printf("Radix 16: ");
    while (*string) {
        // Print character
        // wprintf(L"%lc ", *string);
        // Print hexadecimal value
        printf("%04x ", (unsigned int)*string);
        string++;
    }
    wprintf(L"\n");
    printf("\n");
}


void printCharacterCodesInHexC(const char* input) {
    printf("Hex: ");
    while (*input) {
        printf("0x%04x ", (unsigned char)*input); // Cast to unsigned char to avoid sign extension
        input++;
    }
    printf("\n");
}

int main() {
    wchar_t string[] = L"/test_semaphore"; // Example UTF-16 string
    printCharAndRadixW(string);
    const char* name = "/test_semaphore"; // Example C string
    printCharacterCodesInHexC(name);
    return 0;
}
EOF

# Compile the C program
gcc string_encoding_properties.c -o string_encoding_properties -pthread

# Check if the compilation succeeded
if [ $? -eq 0 ]; then
    # Execute the compiled program if compilation was successful
    ./string_encoding_properties
else
    echo "Compilation failed."
fi

# Clean up: remove the source file and the executable
rm -f string_encoding_properties.c string_encoding_properties
