#include <stdio.h>
#include <stdlib.h>
#include "mocker.h"
#include "sqlite3.h"

#define MAX_DATABASE_PATH 32

char *create_mock_database(uint32_t rows) {
    // Create a temp file
    char *database_path = malloc((MAX_DATABASE_PATH + 1) * sizeof(char));
    snprintf(database_path, MAX_DATABASE_PATH, "file:/tmp/db_bench%d", rand());
    // Create the database
    sqlite3 *db;
    int result = sqlite3_open(database_path, &db);
    if (result != SQLITE_OK) {
        printf("cannot open database: %s", sqlite3_errstr(result));
        exit(1);
    }
    // TODO: Create the table
    // Close the database and cleanup
    sqlite3_close(db);
    return database_path;
}