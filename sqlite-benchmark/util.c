#include <stdlib.h>
#include <stdio.h>
#include "util.h"

int rand_range(int min, int max) {
    return (rand() % (max - min)) + min;
}

void rand_string(char *str, int size) {
    for (int i = 0; i < size; i++)
        str[i] = (char) rand_range('0', 'Z' + 1);
    str[size] = '\0';
}

double rand_double() {
    return (double) rand() / RAND_MAX;
}

void rand_date_time(char *buffer) {
    /**
     * Some small notes for myself:
     * I used 28 for day because it's hard to handle months like Feb and stuff.
     * I also use range of [1, 23) for hours to handle daylight time savings.
     */
    snprintf(buffer, 20, "%04d-%02d-%02d %02d:%02d:%02d",
             rand_range(1900, 2100), rand_range(1, 12 + 1), rand_range(1, 28),
             rand_range(1, 23), rand_range(0, 60), rand_range(0, 60));
}