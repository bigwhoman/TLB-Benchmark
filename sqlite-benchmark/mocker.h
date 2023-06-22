#ifndef SQLITE_BENCHMARK_MOCKER_H
#define SQLITE_BENCHMARK_MOCKER_H

#endif //SQLITE_BENCHMARK_MOCKER_H

#include <stdint.h>
#include "sqlite3.h"

/**
 * Create a mock database and populate it with random data
 * @param rows The number of rows in each table
 * @param database_path [OUT] The path of database which will be created.
 * The size should be at least MAX_DATABASE_PATH bytes
 */
void create_mock_database(uint32_t rows, char *database_path);

/**
 * Insert some fake users into database
 * @param db The database to insert fake users
 * @param count The number of users to add
 */
void insert_mock_users(sqlite3 *db, uint32_t count);

/**
 * Insert some fake goods into database
 * @param db The database to insert fake goods
 * @param count The number of goods to add
 */
void insert_mock_goods(sqlite3 *db, uint32_t count);

/**
 * Create fake orders for users
 * @param db The database to insert fake orders in
 * @param users_count Number of users (last id of users table)
 * @param goods_count Number of goods (last id of goods table)
 * @param orders_count Number of orders to mock
 */
void insert_mock_orders(sqlite3 *db, uint32_t users_count, uint32_t goods_count, uint32_t orders_count);