/** \file    json_grep.cc
 *  \brief   A simple tool for performing single lookups in a JSON file.
 *  \author  Dr. Johannes Ruscheinski
 *
 *  \copyright (C) 2017-2020 Library of the University of Tübingen
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <iostream>
#include <cstdlib>
#include "FileUtil.h"
#include "JSON.h"
#include "util.h"


[[noreturn]] void Usage() {
    ::Usage("[--print] json_input_file [lookup_path [default]]");
}


int Main(int /*argc*/, char *argv[]) {
    ++argv;

    if (*argv == nullptr)
        Usage();

    bool print(false);
    if (std::strcmp(*argv, "--print") == 0) {
        print = true;
        ++argv;
    }

    if (*argv == nullptr)
        Usage();

    const std::string json_input_filename(*argv);
    ++argv;

    std::string lookup_path;
    if (*argv != nullptr) {
        lookup_path = *argv;
        ++argv;
    }

    std::string default_value;
    if (*argv != nullptr) {
        default_value = *argv;
        ++argv;
    }

    std::string json_document;
    if (not FileUtil::ReadString(json_input_filename, &json_document))
        LOG_ERROR("could not read \"" + json_input_filename + "\"!");

    JSON::Parser parser(json_document);
    std::shared_ptr<JSON::JSONNode> tree;
    if (not parser.parse(&tree))
        LOG_ERROR(parser.getErrorMessage());

    if (print)
        std::cout << tree->toString() << '\n';

    if (not lookup_path.empty())
        std::cout << lookup_path << ": "
                  << (default_value.empty() ? JSON::LookupString(lookup_path, tree) : JSON::LookupString(lookup_path, tree, default_value))
                  << '\n';
    else
        LOG_DEBUG("lookup_path is empty!");

    return EXIT_SUCCESS;
}
