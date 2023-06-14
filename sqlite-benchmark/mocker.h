#ifndef SQLITE_BENCHMARK_MOCKER_H
#define SQLITE_BENCHMARK_MOCKER_H

#endif //SQLITE_BENCHMARK_MOCKER_H

#include <stdint.h>

/**
 * Create a mock database and populate it with random data
 * @param rows The number of rows in each table
 * @return The path of the db created
 */
char *create_mock_database(uint32_t rows);