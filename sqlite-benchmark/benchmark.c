#include <stdlib.h>
#include "benchmark.h"

void *benchmark_writer(void *arguments_void) {
    // Parse arguments and prepare results from now
    struct BenchmarkArguments *arguments = (struct BenchmarkArguments *) arguments;
    struct BenchmarkResult *result = malloc(sizeof(struct BenchmarkResult));
    // TODO: Open database
    // Done
    return result;
}

void *benchmark_reader(void *arguments_void) {
    // Parse arguments and prepare results from now
    struct BenchmarkArguments *arguments = (struct BenchmarkArguments *) arguments;
    struct BenchmarkResult *result = malloc(sizeof(struct BenchmarkResult));
    // TODO: Open database
    // Done
    return result;
}

void *benchmark_mixed(void *arguments_void) {
    // Parse arguments and prepare results from now
    struct BenchmarkArguments *arguments = (struct BenchmarkArguments *) arguments;
    struct BenchmarkResult *result = malloc(sizeof(struct BenchmarkResult));
    // TODO: Open database
    // Done
    return result;
}