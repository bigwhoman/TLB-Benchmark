#include <stdio.h>
#include <stdlib.h>
#include "arguments.h"

void parse_arguments(int argc, char **argv, struct ParsedArguments *arguments) {
    if (argc < 5) {
        puts("Run the program like this:");
        printf("%s THREADS_READ THREADS_WRITE THREADS_MIX TABLE_ROWS\n", argv[0]);
        exit(1);
    }
    // Parse
    arguments->threads_reader = strtoul(argv[1], NULL, 10);
    arguments->threads_writer = strtoul(argv[2], NULL, 10);
    arguments->threads_mixed = strtoul(argv[3], NULL, 10);
    arguments->table_rows = strtoul(argv[4], NULL, 10);
    // Validate
    if (arguments->threads_reader + arguments->threads_writer + arguments->threads_mixed == 0) {
        puts("Program should have at least 1 worker thread");
        exit(1);
    }
    if (arguments->table_rows == 0) {
        puts("Tables should have at least one row");
        exit(1);
    }
    // Log
    printf("Running with %u readers, %u writers, %u mixed threads and %u rows\n",
           arguments->threads_reader, arguments->threads_writer, arguments->threads_mixed, arguments->table_rows);
}