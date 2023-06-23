#ifndef SQLITE_BENCHMARK_BENCHMARK_H
#define SQLITE_BENCHMARK_BENCHMARK_H

#endif //SQLITE_BENCHMARK_BENCHMARK_H

#include <stdint.h>
#include "sqlite3.h"

struct BenchmarkArguments {
    /**
     * The open database connection
     */
    sqlite3 *db;
    /**
     * How long should we keep running?
     */
    uint32_t running_time;
    /**
     * Number of rows of users
     */
    _Atomic uint32_t users_count;
    /**
     * Number of rows of goods
     */
    _Atomic uint32_t goods_count;
};

struct BenchmarkResult {
    uint32_t reads;
    uint32_t writes;
};

/**
 * Opens the database connection to be used for benchmarks
 * @param path The path of database
 * @return The opened database handler
 */
sqlite3 *benchmark_open_database(const char *path);

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