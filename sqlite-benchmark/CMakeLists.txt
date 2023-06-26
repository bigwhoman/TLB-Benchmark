cmake_minimum_required(VERSION 3.16)
project(sqlite_benchmark C)

set(CMAKE_C_STANDARD 11)

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
add_executable(sqlite_benchmark main.c sqlite3.c arguments.c mocker.c util.c benchmark.c)
target_link_libraries(sqlite_benchmark PRIVATE Threads::Threads ${CMAKE_DL_LIBS})
