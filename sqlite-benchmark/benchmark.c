#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>
#include "benchmark.h"
#include "mocker.h"
#include "sqlite3.h"
#include "util.h"

/**
 * The operation performed while doing a random read from database
 */
enum RandomReadOperation {
    RandomReadUser,
    RandomReadGood,
    RandomReadOrderNoJoin,
    RandomReadOrderJoin,
};

/**
 * The operation performed while doing a random write to database
 */
enum RandomWriteOperation {
    RandomWriteUser,
    RandomWriteGood,
    RandomWriteOrder,
};

/**
 * Checks if at least @p deadline seconds has passed from @p start_time
 * @param start_time
 * @param deadline
 * @return True if deadline has passed
 */
static bool deadline_reached(struct timeval start_time, uint32_t deadline) {
    struct timeval now;
    gettimeofday(&now, NULL);
    return (now.tv_sec - start_time.tv_sec) > deadline;
}

/**
 * Generates a random read operation.
 * @return The operation to do.
 */
static enum RandomReadOperation get_random_read_operation() {
    double rng = rand_double();
    if (rng < 0.3) // 30%
        return RandomReadUser;
    if (rng < 0.6) // 30%
        return RandomReadGood;
    if (rng < 0.8) // 20%
        return RandomReadOrderNoJoin;
    // 20%
    return RandomReadOrderJoin;
}

/**
 * Generates a random write operation.
 * @return The operation to do.
 */
static enum RandomWriteOperation get_random_write_operation() {
    double rng = rand_double();
    if (rng < 0.3) // 30%
        return RandomWriteUser;
    if (rng < 0.6) // 30%
        return RandomWriteGood;
    // 40%
    return RandomWriteOrder;
}

/**
 * Performs a single database read
 * @param db The database to perform the read on
 * @param users Number of users in database
 * @param goods Number of goods in database
 */
static void perform_database_read(sqlite3 *db, uint32_t users, uint32_t goods) {
    sqlite3_stmt *stmt = NULL;
    int rc, id;
    switch (get_random_read_operation()) {
        case RandomReadUser:
            // Create query
            rc = sqlite3_prepare_v2(db, "SELECT first_name, last_name, address, age, coordinates FROM users WHERE id=?",
                                    -1,
                                    &stmt, NULL);
            if (rc != SQLITE_OK) {
                printf("Cannot select users: %s\n", sqlite3_errmsg(db));
                exit(1);
            }
            // Bind
            id = rand_range(1, (int) users + 1); // id starts from 1!
            sqlite3_bind_int(stmt, 1, id);
            // Query
            rc = sqlite3_step(stmt);
            if (rc != SQLITE_ROW) {
                printf("Cannot step users with %d id: %s\n", id, sqlite3_errmsg(db));
                exit(1);
            }
            // Read
            sqlite3_column_text(stmt, 1);
            sqlite3_column_text(stmt, 2);
            sqlite3_column_text(stmt, 3);
            sqlite3_column_int(stmt, 4);
            if (sqlite3_column_type(stmt, 5) != SQLITE_NULL)
                sqlite3_column_double(stmt, 5);
            break;
        case RandomReadGood:
            // Create query
            rc = sqlite3_prepare_v2(db, "SELECT name, price, available FROM goods WHERE id=?", -1,
                                    &stmt, NULL);
            if (rc != SQLITE_OK) {
                printf("Cannot select goods: %s\n", sqlite3_errmsg(db));
                exit(1);
            }
            // Bind
            id = rand_range(1, (int) goods + 1);
            sqlite3_bind_int(stmt, 1, id);
            // Query
            rc = sqlite3_step(stmt);
            if (rc != SQLITE_ROW) {
                printf("Cannot step goods with %d id: %s\n", id, sqlite3_errmsg(db));
                exit(1);
            }
            // Read
            sqlite3_column_text(stmt, 1);
            sqlite3_column_text(stmt, 2);
            sqlite3_column_int(stmt, 3);
            break;
        case RandomReadOrderNoJoin:
            // Create query
            rc = sqlite3_prepare_v2(db, "SELECT order_date, delivery_time FROM orders WHERE user_id=? AND good_id=?",
                                    -1,
                                    &stmt, NULL);
            if (rc != SQLITE_OK) {
                printf("Cannot select orders: %s\n", sqlite3_errmsg(db));
                exit(1);
            }
            // Bind
            sqlite3_bind_int(stmt, 1, rand_range(1, (int) users + 1));
            sqlite3_bind_int(stmt, 2, rand_range(1, (int) goods + 1));
            // Query
            rc = sqlite3_step(stmt);
            if (rc == SQLITE_ROW) { // here, we can read a non-existent row
                sqlite3_column_text(stmt, 1);
                if (sqlite3_column_type(stmt, 2) != SQLITE_NULL)
                    sqlite3_column_text(stmt, 2);
            }
            break;
        case RandomReadOrderJoin:
            // Create query
            rc = sqlite3_prepare_v2(db,
                                    "SELECT users.first_name, users.last_name, goods.name, goods.price, orders.order_date, orders.delivery_time FROM orders INNER JOIN users ON orders.user_id = users.id INNER JOIN goods ON orders.good_id = goods.id WHERE orders.user_id=? AND orders.good_id=?",
                                    -1, &stmt, NULL);
            if (rc != SQLITE_OK) {
                printf("Cannot select orders (join): %s\n", sqlite3_errmsg(db));
                exit(1);
            }
            // Bind
            sqlite3_bind_int(stmt, 1, rand_range(1, (int) users + 1));
            sqlite3_bind_int(stmt, 2, rand_range(1, (int) goods + 1));
            // Query
            rc = sqlite3_step(stmt);
            if (rc == SQLITE_ROW) { // here, we can read a non-existent row
                sqlite3_column_text(stmt, 1);
                sqlite3_column_text(stmt, 2);
                sqlite3_column_text(stmt, 3);
                sqlite3_column_int64(stmt, 4);
                sqlite3_column_text(stmt, 5);
                if (sqlite3_column_type(stmt, 6) != SQLITE_NULL)
                    sqlite3_column_text(stmt, 6);
            }
            break;
    }
    sqlite3_finalize(stmt);
}

/**
 * Performs a single database write
 * @param db The database to perform the read on
 * @param arguments The arguments. This is used to manipulate the number of rows
 */
static void perform_database_write(sqlite3 *db, struct BenchmarkArguments *arguments) {
    switch (get_random_write_operation()) {
        case RandomWriteUser:
            insert_mock_users(db, 1);
            arguments->users_count++;
            break;
        case RandomWriteGood:
            insert_mock_goods(db, 1);
            arguments->goods_count++;
            break;
        case RandomWriteOrder:
            insert_mock_orders(db, arguments->users_count, arguments->goods_count, 1);
            break;
    }
}

void *benchmark_reader(void *arguments_void) {
    // Parse arguments and prepare results from now
    struct timeval start_time;
    gettimeofday(&start_time, NULL);
    struct BenchmarkArguments *arguments = (struct BenchmarkArguments *) arguments_void;
    struct BenchmarkResult *result = calloc(1, sizeof(struct BenchmarkResult));
    // Open database
    sqlite3 *db;
    int result_code = sqlite3_open_v2(arguments->database_path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, NULL);
    if (result_code != SQLITE_OK) {
        printf("cannot open database: %s", sqlite3_errstr(result_code));
        exit(1);
    }
    sqlite3_exec(db, "PRAGMA busy_timeout = 10000;", NULL, NULL, NULL);
    // Main loop
    while (!deadline_reached(start_time, arguments->running_time)) {
        perform_database_read(db, arguments->users_count, arguments->goods_count);
        result->reads++;
    }
    // Done
    sqlite3_close(db);
    return result;
}

void *benchmark_writer(void *arguments_void) {
    // Parse arguments and prepare results from now
    struct timeval start_time;
    gettimeofday(&start_time, NULL);
    struct BenchmarkArguments *arguments = (struct BenchmarkArguments *) arguments_void;
    struct BenchmarkResult *result = calloc(1, sizeof(struct BenchmarkResult));
    // Open database
    sqlite3 *db;
    int result_code = sqlite3_open_v2(arguments->database_path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_NOMUTEX, NULL);
    if (result_code != SQLITE_OK) {
        printf("cannot open database: %s", sqlite3_errstr(result_code));
        exit(1);
    }
    sqlite3_exec(db, "PRAGMA busy_timeout = 10000;", NULL, NULL, NULL);
    // Main loop
    while (!deadline_reached(start_time, arguments->running_time)) {
        perform_database_write(db, arguments);
        result->writes++;
    }
    // Done
    sqlite3_close(db);
    return result;
}

void *benchmark_mixed(void *arguments_void) {
    // Parse arguments and prepare results from now
    struct timeval start_time;
    gettimeofday(&start_time, NULL);
    struct BenchmarkArguments *arguments = (struct BenchmarkArguments *) arguments_void;
    struct BenchmarkResult *result = calloc(1, sizeof(struct BenchmarkResult));
    // Open database
    sqlite3 *db;
    int result_code = sqlite3_open_v2(arguments->database_path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_NOMUTEX, NULL);
    if (result_code != SQLITE_OK) {
        printf("cannot open database: %s", sqlite3_errstr(result_code));
        exit(1);
    }
    sqlite3_exec(db, "PRAGMA busy_timeout = 10000;", NULL, NULL, NULL);
    // Main loop
    while (!deadline_reached(start_time, arguments->running_time)) {
        // Do either a read or write with 50% chance
        if (rand_bool()) {
            perform_database_write(db, arguments);
            result->writes++;
        } else {
            perform_database_read(db, arguments->users_count, arguments->goods_count);
            result->reads++;
        }
    }
    // Done
    sqlite3_close(db);
    return result;
}