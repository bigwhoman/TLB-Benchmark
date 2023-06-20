#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include "arguments.h"
#include "mocker.h"

int main(int argc, char **argv) {
    srand(time(NULL));
    // Parse arguments
    struct ParsedArguments parsed_arguments;
    parse_arguments(argc, argv, &parsed_arguments);
    // Create the mock data
    const char *db_filename = create_mock_database(parsed_arguments.table_rows);

    //remove(db_filename); // cleanup
}
