#define _POSIX_C_SOURCE 200809L

#include <signal.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>

static volatile sig_atomic_t keep_running = 1;

static void handle_signal(int signal_number)
{
    (void)signal_number;
    keep_running = 0;
}

int main(void)
{
    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);

    puts("myproject-app started");
    fflush(stdout);

    while (keep_running) {
        time_t now = time(NULL);
        struct tm local_time;
        char timestamp[32];

        if (localtime_r(&now, &local_time) != NULL &&
            strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", &local_time) > 0) {
            printf("myproject-app heartbeat: %s\n", timestamp);
        } else {
            puts("myproject-app heartbeat");
        }

        fflush(stdout);
        sleep(30);
    }

    puts("myproject-app stopped");
    return 0;
}
