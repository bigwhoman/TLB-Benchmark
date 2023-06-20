#ifndef SQLITE_BENCHMARK_DATABASE_H
#define SQLITE_BENCHMARK_DATABASE_H

#endif //SQLITE_BENCHMARK_DATABASE_H

#include <stdbool.h>

struct TableUsers {
    int id;
    char first_name[16];
    char last_name[16];
    char address[64];
    unsigned char age;
    double coordinates;
};

struct TableGoods {
    int id;
    char name[16];
    long long price;
    bool available;
};

struct TableOrders {
    int user_id;
    int good_id;
    char order_date[20]; // 2023-06-20 09:36:18
    char delivery_time[20]; // 2023-06-20 09:36:18, nullable
};