#ifndef SQLITE_BENCHMARK_ARGUMENTS_H
#define SQLITE_BENCHMARK_ARGUMENTS_H

#endif //SQLITE_BENCHMARK_ARGUMENTS_H

#include "stdint.h"

struct ParsedArguments {
    /**
     * How many threads should open the database as read only
     */
    uint8_t threads_reader;
    /**
     * How many threads should open the database as write only
     */
    uint8_t threads_writer;
    /**
     * Threads which are both writing and reading from database
     */
    uint8_t threads_mixed;
    /**
     * Number of rows in table
     */
    uint32_t table_rows;
};

/**
 * Parse arguments of program
 */
void parse_arguments(int argc, char **argv, struct ParsedArguments *);