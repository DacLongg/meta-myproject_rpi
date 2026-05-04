#include <stdio.h>
#include <string.h>

#ifndef HELLO_BUILD_DATE
#define HELLO_BUILD_DATE "unknown"
#endif

static void print_banner(void)
{
    printf("I am DarkDragon OS!\n");
    printf("Version 1.0\n");
    printf("Build Date: %s\n", HELLO_BUILD_DATE);
}

int main(int argc, char *argv[])
{
    if (argc > 1 && strcmp(argv[1], "--ssh-login") == 0) {
        printf("SSH login detected\n");
        print_banner();
        return 0;
    }

    print_banner();
    return 0;
}
