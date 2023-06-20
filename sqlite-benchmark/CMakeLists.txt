cmake_minimum_required(VERSION 3.25)
project(sqlite_benchmark C)

set(CMAKE_C_STANDARD 11)

add_executable(sqlite_benchmark main.c sqlite3.c arguments.c mocker.c util.c)
