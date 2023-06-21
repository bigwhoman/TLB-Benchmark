#ifndef SQLITE_BENCHMARK_MOCKER_H
#define SQLITE_BENCHMARK_MOCKER_H

#endif //SQLITE_BENCHMARK_MOCKER_H

#include <stdint.h>

/**
 * Create a mock database and populate it with random data
 * @param rows The number of rows in each table
 * @param database_path [OUT] The path of database which will be created.
 * The size should be at least MAX_DATABASE_PATH bytes
 */
void create_mock_database(uint32_t rows, char *database_path);