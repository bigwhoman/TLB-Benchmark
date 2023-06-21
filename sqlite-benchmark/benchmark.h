#ifndef SQLITE_BENCHMARK_BENCHMARK_H
#define SQLITE_BENCHMARK_BENCHMARK_H

#endif //SQLITE_BENCHMARK_BENCHMARK_H

#include <stdint.h>
#include "database.h"

struct BenchmarkArguments {
    /**
     * Path of database to do operations on it
     */
    char database_path[MAX_DATABASE_PATH];
    /**
     * How long should we keep running?
     */
    uint32_t running_time;
};

struct BenchmarkResult {
    /**
     * How many iterations (operations) has been done
     */
    uint64_t iterations;
};

/**
 * A writer thread to write data in database (only writes)
 * @param arguments The arguments with type of pointer to @see{struct BenchmarkArguments}
 * @return The result with type of pointer to @see{struct BenchmarkResult}
 */
void *benchmark_writer(void *arguments);

/**
 * A reader thread to read data from database (only reads)
 * @param arguments The arguments with type of pointer to @see{struct BenchmarkArguments}
 * @return The result with type of pointer to @see{struct BenchmarkResult}
 */
void *benchmark_reader(void *arguments);

/**
 * A mixed thread to read and write data from/to database
 * @param arguments The arguments with type of pointer to @see{struct BenchmarkArguments}
 * @return The result with type of pointer to @see{struct BenchmarkResult}
 */
void *benchmark_mixed(void *arguments);