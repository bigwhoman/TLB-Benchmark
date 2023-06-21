#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <pthread.h>
#include "arguments.h"
#include "benchmark.h"
#include "mocker.h"

int main(int argc, char **argv) {
    srand(time(NULL));
    // Parse arguments
    struct ParsedArguments parsed_arguments;
    parse_arguments(argc, argv, &parsed_arguments);
    // Create the mock data
    struct BenchmarkArguments benchmark_arguments;
    create_mock_database(parsed_arguments.table_rows, benchmark_arguments.database_path);
    benchmark_arguments.running_time = parsed_arguments.test_time;
    // Create threads and wait for them
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
        printf("Reader thread %lu finished with %lu iterations.\n", threads[i], result->iterations);
        free(result);
    }
    for (uint32_t i = 0; i < parsed_arguments.threads_writer; i++) {
        pthread_join(threads[parsed_arguments.threads_reader + i], (void **) &result);
        printf("Writer thread %lu finished with %lu iterations.\n", threads[parsed_arguments.threads_reader + i],
               result->iterations);
        free(result);
    }
    for (uint32_t i = 0; i < parsed_arguments.threads_mixed; i++) {
        pthread_join(threads[parsed_arguments.threads_reader + parsed_arguments.threads_writer + i], (void **) &result);
        printf("Mixed thread %lu finished with %lu iterations.\n",
               threads[parsed_arguments.threads_reader + parsed_arguments.threads_writer + i], result->iterations);
        free(result);
    }
    // Cleanup
    remove(benchmark_arguments.database_path);
}
