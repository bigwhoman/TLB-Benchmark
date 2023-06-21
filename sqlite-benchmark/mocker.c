#include <stdio.h>
#include <stdlib.h>
#include "database.h"
#include "mocker.h"
#include "sqlite3.h"
#include "util.h"

/**
 * Initialize database tables
 * @param db The database to init
 */
static void initialize_database(sqlite3 *db) {
    char *error_message = NULL;
    int result = sqlite3_exec(db, "CREATE TABLE users\n"
                                  "(\n"
                                  "    id          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\n"
                                  "    first_name  TEXT    NOT NULL,\n"
                                  "    last_name   TEXT    NOT NULL,\n"
                                  "    address     TEXT    NOT NULL,\n"
                                  "    age         INTEGER NOT NULL,\n"
                                  "    coordinates REAL\n"
                                  ");\n"
                                  "CREATE TABLE goods\n"
                                  "(\n"
                                  "    id        INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\n"
                                  "    name      TEXT    NOT NULL,\n"
                                  "    price     TEXT    NOT NULL,\n"
                                  "    available BOOLEAN NOT NULL\n"
                                  ");\n"
                                  "CREATE INDEX idx_goods_available ON goods (available);\n"
                                  "CREATE TABLE orders\n"
                                  "(\n"
                                  "    user_id       INTEGER NOT NULL,\n"
                                  "    good_id       INTEGER NOT NULL,\n"
                                  "    order_date    TEXT    NOT NULL,\n"
                                  "    delivery_time TEXT,\n"
                                  "    FOREIGN KEY (user_id) REFERENCES users (id),\n"
                                  "    FOREIGN KEY (good_id) REFERENCES goods (id)\n"
                                  ");", NULL, NULL, &error_message);
    if (result != SQLITE_OK) {
        printf("cannot create tables: %s", error_message);
        exit(1);
    }
}

/**
 * Insert some fake users into database
 * @param db The database to insert fake users
 * @param count The number of users to add
 */
static void insert_users(sqlite3 *db, uint32_t count) {
    struct TableUsers user;
    sqlite3_stmt *stmt;
    int result;
    // Prepare the statement
    result = sqlite3_prepare_v2(db,
                                "INSERT INTO users (first_name, last_name, address, age, coordinates) VALUES (?,?,?,?,?)",
                                -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        printf("cannot prepare users statement: %s", sqlite3_errstr(result));
        exit(1);
    }
    // Add mock data
    while (count--) {
        // Reset to be bind
        sqlite3_clear_bindings(stmt);
        sqlite3_reset(stmt);
        // Fill the user struct
        rand_string(user.first_name, sizeof(user.first_name));
        rand_string(user.last_name, sizeof(user.last_name));
        rand_string(user.address, sizeof(user.address));
        user.age = (unsigned char) rand();
        if (rand() % 2 == 0) {
            user.coordinates = 0; // null
        } else {
            user.coordinates = rand_double();
        }
        // Bind parameters
        sqlite3_bind_text(stmt, 1, user.first_name, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 2, user.last_name, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 3, user.address, -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 4, user.age);
        if (user.coordinates == 0) { // null
            sqlite3_bind_null(stmt, 5);
        } else {
            sqlite3_bind_double(stmt, 5, user.coordinates);
        }
        // Do the query
        result = sqlite3_step(stmt);
        if (result != SQLITE_DONE) {
            printf("cannot insert users row: %s", sqlite3_errstr(result));
            exit(1);
        }
    }
    // Clean up
    sqlite3_finalize(stmt);
}

/**
 * Insert some fake goods into database
 * @param db The database to insert fake goods
 * @param count The number of goods to add
 */
static void insert_goods(sqlite3 *db, uint32_t count) {
    struct TableGoods goods;
    sqlite3_stmt *stmt;
    int result;
    // Prepare the statement
    result = sqlite3_prepare_v2(db,
                                "INSERT INTO goods (name, price, available) VALUES (?,?,?)",
                                -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        printf("cannot prepare goods statement: %s", sqlite3_errstr(result));
        exit(1);
    }
    // Add mock data
    while (count--) {
        // Reset to be bind
        sqlite3_clear_bindings(stmt);
        sqlite3_reset(stmt);
        // Fill the goods struct
        rand_string(goods.name, sizeof(goods.name));
        goods.price = rand();
        goods.available = (rand() % 10) != 0;
        // Bind parameters
        sqlite3_bind_text(stmt, 1, goods.name, -1, SQLITE_STATIC);
        sqlite3_bind_int64(stmt, 2, goods.price);
        sqlite3_bind_int(stmt, 3, goods.available);
        // Do the query
        result = sqlite3_step(stmt);
        if (result != SQLITE_DONE) {
            printf("cannot insert goods row: %s", sqlite3_errstr(result));
            exit(1);
        }
    }
    // Clean up
    sqlite3_finalize(stmt);
}

/**
 * Create fake orders for users
 * @param db The database to insert fake orders in
 * @param users_count Number of users (last id of users table)
 * @param goods_count Number of goods (last id of goods table)
 * @param orders_count Number of orders to mock
 */
static void insert_orders(sqlite3 *db, uint32_t users_count, uint32_t goods_count, uint32_t orders_count) {
    struct TableOrders order;
    sqlite3_stmt *stmt;
    int result;
    // Prepare the statement
    result = sqlite3_prepare_v2(db,
                                "INSERT INTO orders (user_id, good_id, order_date, delivery_time) VALUES (?,?,?,?)",
                                -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        printf("cannot prepare orders statement: %s", sqlite3_errstr(result));
        exit(1);
    }
    // Add mock data
    while (orders_count--) {
        // Reset to be bind
        sqlite3_clear_bindings(stmt);
        sqlite3_reset(stmt);
        // Fill the order struct
        order.user_id = rand_range(1, (int) users_count);
        order.good_id = rand_range(1, (int) goods_count);
        rand_date_time(order.order_date);
        if (rand() % 5 == 0) {
            order.delivery_time[0] = '\0'; // not delivered yet
        } else {
            rand_date_time(order.delivery_time);
        }
        // Bind parameters
        sqlite3_bind_int(stmt, 1, order.user_id);
        sqlite3_bind_int(stmt, 2, order.good_id);
        sqlite3_bind_text(stmt, 3, order.order_date, -1, SQLITE_STATIC);
        if (order.delivery_time[0] == '\0') { // null
            sqlite3_bind_null(stmt, 4);
        } else {
            sqlite3_bind_text(stmt, 4, order.delivery_time, -1, SQLITE_STATIC);
        }
        // Do the query
        result = sqlite3_step(stmt);
        if (result != SQLITE_DONE) {
            printf("cannot insert orders row: %s", sqlite3_errstr(result));
            exit(1);
        }
    }
    // Clean up
    sqlite3_finalize(stmt);
}

void create_mock_database(uint32_t rows, char *database_path) {
    // Create a temp file
    snprintf(database_path, MAX_DATABASE_PATH, "/tmp/db_bench%d", rand());
    // Create the database
    sqlite3 *db;
    int result = sqlite3_open(database_path, &db);
    if (result != SQLITE_OK) {
        printf("cannot open database: %s", sqlite3_errstr(result));
        exit(1);
    }
    // Mock data
    const uint32_t users_count = rows, goods_count = rows / 10, orders_count = rows / 2;
    sqlite3_exec(db, "BEGIN TRANSACTION;", NULL, NULL, NULL);
    puts("Creating database");
    initialize_database(db);
    puts("Mocking users");
    insert_users(db, users_count);
    puts("Mocking goods");
    insert_goods(db, goods_count);
    puts("Mocking orders");
    insert_orders(db, users_count, goods_count, orders_count);
    puts("Committing changes");
    sqlite3_exec(db, "COMMIT;", NULL, NULL, NULL);
    // Close the database and cleanup
    printf("Created mock database %s\n", database_path);
    sqlite3_close(db);
}