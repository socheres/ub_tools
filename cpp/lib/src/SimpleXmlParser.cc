/** \file   SimpleXmlParser.cc
 *  \brief  A non-validating XML parser class.
 *  \author Dr. Johannes Ruscheinski (johannes.ruscheinski@uni-tuebingen.de)
 *
 *  \copyright 2015 Universitätsbiblothek Tübingen.  All rights reserved.
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
#include "SimpleXmlParser.h"
#include <stdexcept>
#include "Compiler.h"
#include "StringUtil.h"
#include "TextUtil.h"


namespace {


bool DecodeEnity(const std::string &entity_string, std::string * const decoded_char) {
    if (unlikely(entity_string.empty()))
	return false;

    if (entity_string[0] == '#') {
	if (entity_string.length() < 2)
	    return false;

	unsigned code_point;
	if (entity_string[1] == 'x') {
	    if (entity_string.length() < 3 or entity_string.length() > 6)
		return false;
	    if (not StringUtil::ToUnsigned(entity_string.substr(2), &code_point, 16))
		return false;
	} else {
	    if (entity_string.length() < 2 or entity_string.length() > 6)
		return false;
	    if (not StringUtil::ToUnsigned(entity_string.substr(1), &code_point))
		return false;
	}

	if (not TextUtil::WCharToUTF8String(std::wstring(1, static_cast<wchar_t>(code_point)), decoded_char))
	    return false;
    } else if (entity_string == "quot")
	*decoded_char = "\"";
    else if (entity_string =="amp")
	*decoded_char = "&";
    else if (entity_string =="apos")
	*decoded_char = "'";
    else if (entity_string =="lt")
	*decoded_char = "<";
    else if (entity_string =="gt")
	*decoded_char = ">";
    else
	return false;

    return true;
}


bool DecodeEntities(const std::string &raw_string, std::string * const decoded_string) {
    bool in_entity(false);
    std::string entity;
    for (const auto ch : raw_string) {
	if (in_entity) {
	    if (ch == ';') {
		std::string decoded_char;
		if (not DecodeEnity(entity, &decoded_char))
		    return false;
		*decoded_string += decoded_char;
		in_entity = false;
	    } else
		entity += ch;
	} else if (ch == '&') {
	    in_entity = true;
	    entity.clear();
	} else
	    *decoded_string += ch;
    }

    return not in_entity;
}


} // unnamed namespace


bool SimpleXmlParser::getNext(Type * const type, std::map<std::string, std::string> * const attrib_map, std::string * const data) {
    if (last_type_ == ERROR)
	throw std::runtime_error("in SimpleXmlParser::getNext: previous call already indicated an error!");

    attrib_map->clear();
    data->clear();

    if (last_element_was_empty_) {
	last_type_ = *type = CLOSING_TAG;
	data->swap(last_tag_name_);
	last_element_was_empty_ = false;
	last_type_ = CLOSING_TAG;
	return true;
    }

    int ch;
    if (last_type_ == OPENING_TAG) {
	last_type_ = *type = CHARACTERS;

	std::string raw_string;
	while ((ch = input_->get()) != '<') {
	    if (unlikely(ch == EOF)) {
		last_error_message_ = "Unexpected EOF while looking for the start of a closing tag!";
		return false;
	    }
	    if (ch == '\n')
		++line_no_;
	    raw_string += static_cast<char>(ch);
	}
	input_->putback(ch); // Putting back the '<'.

	if (not DecodeEntities(raw_string, data)) {
	    last_type_ = *type = ERROR;
	    last_error_message_ = "Invalid entity in character data ending on line " + std::to_string(line_no_) + "!";
	    return false;
	}
    } else { // end-of-document or opening or closing tag
	skipWhiteSpace();
	
	ch = input_->get();
	if (unlikely(ch == EOF)) {
	    last_type_ = *type = END_OF_DOCUMENT;
	    return true;
	}

	if (ch != '<') {
	    last_type_ = *type = ERROR;
            last_error_message_ = "Expected '<' on line " + std::to_string(line_no_) + ", found '"
                                  + std::string(1, static_cast<char>(ch)) + "' instead!";
	    return false;
	}
	
	// If we're at the beginning, we may have an XML prolog:
	if (unlikely(last_type_ == UNINITIALISED) and input_->peek() == '?') {
	    if (not parseProlog()) {
		last_type_ = *type = ERROR;
		return false;
	    }
	    last_type_ = *type = START_OF_DOCUMENT;
	    return true;
	}

	ch = input_->get();
	if (ch == '/') { // A closing tag.
	    if (unlikely(not parseClosingTag(data))) {
		last_type_ = *type = ERROR;
		last_error_message_ = "Error while parsing a closing tag on line " + std::to_string(line_no_) + "!";
		return false;
	    }

	    last_type_ = *type = CLOSING_TAG;
	} else { // An opening tag.
	    input_->putback(ch);
	
	    std::string error_message;
	    if (unlikely(not parseOpeningTag(data, attrib_map, &error_message))) {
		last_type_ = *type = ERROR;
		last_error_message_ = "Error while parsing an opening tag on line " + std::to_string(line_no_) + "! ("
		                      + error_message + ")";
		return false;
	    }

	    ch = input_->get();
	    if (ch == '/') {
		last_element_was_empty_ = true;
		ch = input_->get();
	    }

	    if (unlikely(ch != '>')) {
		last_type_ = *type = ERROR;
		last_error_message_ = "Error while parsing a opening tag on line " + std::to_string(line_no_) + "! ("
                                      "Closing angle bracket not found.)";
		return false;
	    }

	    last_type_ = *type = OPENING_TAG;
	}
    }

    return true;
}


void SimpleXmlParser::skipWhiteSpace() {
    for (;;) {
	const int ch(input_->get());
	if (unlikely(ch == EOF))
	    return;
	if (ch != ' ' and ch != '\t' and ch != '\n' and ch != '\r') {
	    input_->putback(ch);
	    return;
	} else if (ch == '\n')
	    ++line_no_;
    }
}


bool SimpleXmlParser::extractName(std::string * const name) {
    name->clear();

    int ch(input_->get());
    if (unlikely(ch == EOF or (not StringUtil::IsAsciiLetter(ch) and ch != '_' and ch != ':'))) {
	input_->putback(ch);
	return false;
    }

    *name += static_cast<char>(ch);
    for (;;) {
	ch = input_->get();
	if (unlikely(ch == EOF))
	    return false;
	if (not (StringUtil::IsAsciiLetter(ch) or StringUtil::IsDigit(ch) or ch == '_' or ch == ':' or ch == '.')) {
	    input_->putback(ch);
	    return true;
	}
	*name += static_cast<char>(ch);
    }
}


bool SimpleXmlParser::extractQuotedString(const int closing_quote, std::string * const s) {
    s->clear();

    for (;;) {
	const int ch(input_->get());
	if (unlikely(ch == EOF))
	    return false;
	if (ch == closing_quote)
	    return true;
	*s += static_cast<char>(ch);
    }
}


bool SimpleXmlParser::parseProlog() {
    if (input_->peek() != '?')
	return true;
    input_->get();

    std::string prolog_tag_name;
    std::map<std::string, std::string> prolog_attrib_map;
    std::string error_message;
    if (not parseOpeningTag(&prolog_tag_name, &prolog_attrib_map, &error_message)) {
	last_error_message_ = "Error in prolog! (" + error_message + ")";
	return false;
    }

    int ch(input_->get());
    if (unlikely(ch != '?')) {
	last_error_message_ = "Error in prolog, expected '?' but found '" + std::string(1, static_cast<char>(ch)) + "'!";
	return false;
    }

    ch = input_->get();
    if (unlikely(ch != '>')) {
	last_error_message_ = "Error in prolog, closing angle bracket not found!";
	return false;
    }

    const auto encoding(prolog_attrib_map.find("encoding"));
    if (encoding != prolog_attrib_map.cend()) {
	if (::strcasecmp(encoding->second.c_str(), "utf-8") != 0) {
	    last_error_message_ = "Error in prolog: We only support the UTF-8 encoding!";
	    return false;
	}
    }

    return true;
}


bool SimpleXmlParser::parseOpeningTag(std::string * const tag_name, std::map<std::string, std::string> * const attrib_map,
				      std::string * const error_message)
{
    attrib_map->clear();
    error_message->clear();

    if (unlikely(not extractName(tag_name))) {
	*error_message = "Failed to extract the tag name.";
	return false;
    }
    skipWhiteSpace();

    std::string attrib_name;
    while (extractName(&attrib_name)) {
	if (unlikely(attrib_map->find(attrib_name) != attrib_map->cend())) { // Duplicate attribute name?
	    *error_message = "Found a duplicate tag name.";
	    return false;
	}

	skipWhiteSpace();
	const int ch(input_->get());
	if (unlikely(ch != '=')) {
	    *error_message = "Could not find an equal sign as part of an attribute.";
	    return false;
	}

	skipWhiteSpace();
	const int quote(input_->get());
	if (unlikely(quote != '"' and quote != '\'')) {
	    *error_message = "Found neither a single- nor a double-quote starting an attribute value.";
	    return false;
	}
	std::string attrib_value;
	if (unlikely(not extractQuotedString(quote, &attrib_value))) {
	    *error_message = "Failed to extract the attribute value.";
	    return false;
	}

	(*attrib_map)[attrib_name] = attrib_value;

	skipWhiteSpace();
    }

    return true;
}


bool SimpleXmlParser::parseClosingTag(std::string * const tag_name) {
    tag_name->clear();

    if (not extractName(tag_name))
	return false;

    skipWhiteSpace();
    return input_->get() == '>';
}


std::string SimpleXmlParser::TypeToString(const Type type) {
    switch (type) {
    case UNINITIALISED:     return "UNINITIALISED";
    case START_OF_DOCUMENT: return "START_OF_DOCUMENT";
    case END_OF_DOCUMENT:   return "END_OF_DOCUMENT";
    case ERROR:             return "ERROR";
    case OPENING_TAG:       return "OPENING_TAG";
    case CLOSING_TAG:       return "CLOSING_TAG";
    case CHARACTERS:        return "CHARACTERS";
    }
}
