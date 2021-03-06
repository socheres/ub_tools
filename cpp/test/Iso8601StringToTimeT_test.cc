#include <iostream>
#include <cstring>
#include "TimeUtil.h"
#include "util.h"


[[noreturn]] void Usage() {
    std::cerr << "usage: " << ::progname << " rfc3339_datetime\n";
    std::exit(EXIT_FAILURE);
}


int main(int argc, char *argv[]) {
    ::progname = argv[0];

    if (argc != 2)
        Usage();

    const std::string datetime(argv[1]);
    time_t converted_time;
    std::string err_msg;
    if (not TimeUtil::Iso8601StringToTimeT(datetime, &converted_time, &err_msg, TimeUtil::UTC))
        LOG_ERROR("failed to convert \"" + datetime + "\": " + err_msg);
    std::cout << "converted_time as time_t: " << converted_time << '\n';
    std::cout << "Converted time is " << TimeUtil::TimeTToString(converted_time, TimeUtil::DEFAULT_FORMAT, TimeUtil::UTC) << '\n';
}
