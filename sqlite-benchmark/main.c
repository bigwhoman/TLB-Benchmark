#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <pthread.h>
#include <unistd.h>
#include "arguments.h"
#include "benchmark.h"
#include "database.h"
#include "mocker.h"

int main(int argc, char **argv) {
    srand(time(NULL));
    // Parse arguments
    struct ParsedArguments parsed_arguments;
    parse_arguments(argc, argv, &parsed_arguments);
    // Create the mock data
    struct BenchmarkArguments benchmark_arguments;
    char database_path[MAX_DATABASE_PATH];
    create_mock_database(parsed_arguments.table_rows, database_path);
    benchmark_arguments.db = benchmark_open_database(database_path);
    benchmark_arguments.running_time = parsed_arguments.test_time;
    benchmark_arguments.users_count = parsed_arguments.table_rows;
    benchmark_arguments.goods_count = parsed_arguments.table_rows / 10;
    // Wait for user
    printf("Program's PID is %d\n", getpid());
    puts("Press enter to start the benchmark...");
    getchar();
    // Create threads and wait for them
    puts("Starting benchmark...");
    pthread_t threads[
            parsed_arguments.threads_reader + parsed_arguments.threads_writer + parsed_arguments.threads_mixed];
    /**
     * Note for myself: The lifetime of benchmark_arguments is all of the application running time so we can
     * just pass a reference to it to our benchmark functions.
     */
    for (uint32_t i = 0; i < parsed_arguments.threads_reader; i++) {
        pthread_create(&threads[i], NULL, benchmark_reader, &benchmark_arguments);
    }
    for (uint32_t i = 0; i < parsed_arguments.threads_writer; i++) {
        pthread_create(&threads[parsed_arguments.threads_reader + i], NULL, benchmark_writer, &benchmark_arguments);
    }
    for (uint32_t i = 0; i < parsed_arguments.threads_mixed; i++) {
        pthread_create(&threads[parsed_arguments.threads_reader + parsed_arguments.threads_writer + +i], NULL,
                       benchmark_mixed, &benchmark_arguments);
    }
    // Wait for all of them
    struct BenchmarkResult *result;
    for (uint32_t i = 0; i < parsed_arguments.threads_reader; i++) {
        pthread_join(threads[i], (void **) &result);
        printf("Reader thread %lu finished with %u iterations.\n", threads[i], result->reads);
        free(result);
    }
    for (uint32_t i = 0; i < parsed_arguments.threads_writer; i++) {
        pthread_join(threads[parsed_arguments.threads_reader + i], (void **) &result);
        printf("Writer thread %lu finished with %u iterations.\n", threads[parsed_arguments.threads_reader + i],
               result->writes);
        free(result);
    }
    for (uint32_t i = 0; i < parsed_arguments.threads_mixed; i++) {
        pthread_join(threads[parsed_arguments.threads_reader + parsed_arguments.threads_writer + i], (void **) &result);
        printf("Mixed thread %lu finished with %u reads and %u writes.\n",
               threads[parsed_arguments.threads_reader + parsed_arguments.threads_writer + i],
               result->reads, result->writes);
        free(result);
    }
    // Cleanup
    sqlite3_close(benchmark_arguments.db);
    remove(database_path);
}
