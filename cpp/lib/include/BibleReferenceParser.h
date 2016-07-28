/** \file   BibleReferenceParser.h
 *  \brief  Declaration of bits related to our bible reference parser.
 *  \author Dr. Johannes Ruscheinski (johannes.ruscheinski@uni-tuebingen.de)
 *
 *  \copyright 2014-2016 Universitätsbiblothek Tübingen.  All rights reserved.
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
#ifndef BIBLE_REFERENCE_PARSER_H
#define BIBLE_REFERENCE_PARSER_H


#include <set>
#include <string>
#include <utility>


namespace BibleReferenceParser {


const unsigned BOOK_CODE_LENGTH(2);
const unsigned MAX_CHAPTER_LENGTH(3);
const unsigned MAX_VERSE_LENGTH(3);


/** \brief Parses bible references into ranges.
 *  \param bib_ref_candidate  The hopefully syntactically correct bible chapter(s)/verse(s) reference(s).
 *  \param book_code          A two-digit code indicating the book of the bible.  Will be prepended to any
 *                            recognised chapter/verse references returned in "start_end".
 *  \param start_end          The successfully extracted bible ranges.
 *  \return If the parse succeded or not.
 */
bool ParseBibleReference(std::string bib_ref_candidate, const std::string &book_code,
                         std::set<std::pair<std::string, std::string>> * const start_end);


/** \brief Tests the validity of a possible chapter/verse reference. */
bool CanParseBibleReference(const std::string &bib_ref_candidate);


} // namespace BibleReferenceParser


#endif // ifndef BIBLE_REFERENCE_PARSER_H
