#include <sys/types.h>
#include <semaphore.h>
#include <errno.h>

#define SEM_NAME "/20240404-1655-8b34-9829-eb8dabd81c5f"


sem_t *hello_world(const char *name, int oflag, ...);