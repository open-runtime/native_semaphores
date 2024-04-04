// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include "hello.h"
#include <fcntl.h> // Include for O_CREAT definition
#include <stdlib.h>
#include <semaphore.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/types.h>
#include <stdarg.h>
//include errno
#include <errno.h>

int main()
{
//    hello_world();
    return 0;
}



// Note:
// ---only on Windows---
// Every function needs to be exported to be able to access the functions by dart.
// Refer: https://stackoverflow.com/q/225432/8608146
sem_t *hello_world(const char *name, int oflag, ...){
    // Print the string parameter
    printf("Name: %s\n", name);
    // Print the integer parameter
    printf("Oflag decimal: %d\n", oflag);
    printf("Oflag octal: 0%o\n", oflag);

    printf("O_CREAT decimal: %d\n", O_CREAT);
    printf("O_CREAT octal: 0%o\n", O_CREAT);

    printf("O_EXCL decimal: %d\n", O_EXCL);
    printf("O_EXCL octal: 0%o\n", O_EXCL);

//    printf("mode_t: %d\n", mode);
//
//    printf("%o\n", mode);
//
//    printf("value: %d\n", value);

     va_list args;
     mode_t mode;
     unsigned int value;
     int originalModeInteger;
     int originalValueInteger;

    // Initialize the variadic arguments list without checking oflag
    va_start(args, oflag);

    // Directly retrieve `mode` and `value`
    mode = va_arg(args, mode_t);   // Get `mode`
    value = va_arg(args, unsigned int); // Get `value`

    // Print the retrieved `mode` and `value`
    printf("Mode (as int): %d\n", mode); // Assuming mode_t is an int for this example
    printf("Mode (octal): 0%o\n", mode);  // Print `mode` as octal for clarity
    printf("Value: %u\n", value);  // Print `value` as unsigned integer

     // Clean up the variadic list
     va_end(args);

      int val;
      int index = 2;


      va_start(args, oflag); // Initialize args to retrieve variable arguments after fixedArg.
      while((val = va_arg(args, int)) != -1) {

      printf("arg as decimal int: %d, arg as octal int: 0%o, index: %d\n", val, val, index);
      index++;

      }
      va_end(args); // Clean up the va_list.

      printf("Mode: %d\n", mode);
      printf("Value: %d\n", value);



    // Check if oflag is equivalent to O_CREAT
    if (oflag == O_CREAT) {
        printf("oflag is equivalent to O_CREAT\n");
    }

    if (oflag == O_EXCL) {
        printf("oflag is equivalent to O_EXCL\n");
    }

    // Print the value of O_CREAT
    printf("The value of O_CREAT is: %d\n", O_CREAT);

     sem_t *sem;

        // Try to create a semaphore with initial value = 1.
        sem = sem_open(name, oflag, mode, 1);

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
//        getchar();

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
        if (sem_unlink(name) < 0) {
            perror("sem_unlink error");
            exit(EXIT_FAILURE);
        }

        return EXIT_SUCCESS;


}