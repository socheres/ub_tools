/** \file    marc_grep_tokenizer_test.cc
 *  \brief   A test harness for the tokenizer used by the marc_grep2 utility program.
 *  \author  Dr. Johannes Ruscheinski
 */

/*
    Copyright (C) 2015, Library of the University of Tübingen

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#include <iostream>
#include <cstdlib>
#include "MarcGrepTokenizer.h"


int main(int argc, char *argv[]) {
    if (argc != 2) {
	std::cerr << "Usage: " << argv[0] << "query_string\n";
	return EXIT_FAILURE;
    }

    Tokenizer tokenizer(argv[1]);
    TokenType token;
    while ((token = tokenizer.getToken()) != END_OF_INPUT) {
	std::cout << Tokenizer::TokenTypeToString(token);
	if (token == STRING_CONSTANT)
	    std::cout << ": \"" << Tokenizer::EscapeString(tokenizer.getLastStringConstant()) << "\"\n";
	else if (token == UNSIGNED_CONSTANT)
	    std::cout << ": " << tokenizer.getLastUnsignedConstant() << '\n';
	else if (token == INVALID_INPUT) {
	    std::cout << '\n';
	    return EXIT_SUCCESS;
	} else
	    std::cout << '\n';
    }
    std::cout << "END_OF_INPUT\n";

    return EXIT_SUCCESS;
}
