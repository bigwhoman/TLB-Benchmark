#ifndef SQLITE_BENCHMARK_UTIL_H
#define SQLITE_BENCHMARK_UTIL_H

#endif //SQLITE_BENCHMARK_UTIL_H

/**
 * Generate a random number in range of [min, max)
 * @param min Min
 * @param max Max
 * @return The generated random number
 */
int rand_range(int min, int max);

/**
 * Fill an buffer with random string data
 * @param str The string buffer to fill it
 * @param size The size of string buffer
 */
void rand_string(char *str, int size);

/**
 * Return a random double in range of [0, 1)
 * @return The generated random number
 */
double rand_double();

/**
 * Create random date and time for sqlite
 * @param buffer The buffer to put the random data in. Must be 20 bytes long at least
 */
void rand_date_time(char *buffer);