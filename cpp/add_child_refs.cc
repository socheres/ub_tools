/** \file    add_child_refs.cc
 *  \author  Dr. Johannes Ruscheinski
 *
 *  A tool for adding parent->child references to MARC data. In addition to the MARC data that should be
 *  augmented are two files, typically called "child_refs" and "child_titles" which can be generated via
 *  the create_child_refs.sh shell script.
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

#include <fstream>
#include <iostream>
#include <memory>
#include <unordered_map>
#include <cstdlib>
#include <cstring>
#include "DirectoryEntry.h"
#include "File.h"
#include "Leader.h"
#include "MarcUtil.h"
#include "StringUtil.h"
#include "Subfields.h"
#include "util.h"
#include "XmlWriter.h"


static unsigned modified_count(0);
static std::unordered_map<std::string, std::string> parent_to_children_map;
static std::unordered_map<std::string, std::string> id_to_title_map;


void Usage() {
    std::cerr << "Usage: " << progname << " marc_input marc_output child_refs child_titles\n";

    std::exit(EXIT_FAILURE);
}


void ProcessRecord(XmlWriter * const xml_writer, MarcUtil::Record * const record) {
    record->setRecordWillBeWrittenAsXml(true);

    const std::vector<DirectoryEntry> &dir_entries(record->getDirEntries());
    if (dir_entries.at(0).getTag() != "001")
        Error("First field of record is not \"001\"!");

    const std::vector<std::string> field_data(record->getFields());
    const auto map_iter(parent_to_children_map.find(field_data.at(0)));
    if (map_iter != parent_to_children_map.end()) {
        std::vector<std::string> child_ids;
        StringUtil::Split(map_iter->second, ':', &child_ids);
        for (const auto &child_id : child_ids) {
            const auto id_and_title_iter(id_to_title_map.find(child_id));
            if (id_and_title_iter == id_to_title_map.end()) {
                Warning("Can't find title for \"" + child_id + "\"!");
                continue;
            }

            Subfields subfields(/* indicator1 = */' ', /* indicator2 = */' ');
            subfields.addSubfield('a', child_id);
            subfields.addSubfield('b', id_and_title_iter->second);

            if (not record->insertField("CLD", subfields.toString())) {
               Warning("Not enough room to add a CLD field! (Control number: " + field_data[0] + ")");
               break;
            }
        }
	++modified_count;
    }

    record->write(xml_writer);
}


void AddChildRefs(File * const input, File * const output) {
    XmlWriter xml_writer(output);
    xml_writer.openTag("marc:collection",
                       { std::make_pair("xmlns:marc", "http://www.loc.gov/MARC21/slim"),
                         std::make_pair("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance"),
                         std::make_pair("xsi:schemaLocation", "http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd")});

    while (MarcUtil::Record record = MarcUtil::Record::XmlFactory(input))
	ProcessRecord(&xml_writer, &record);

    xml_writer.closeTag();

    std::cerr << "Modified " << modified_count << " record(s).\n";
}


// LoadRefs -- reads lines from "child_refs_filename".  Each line is expected to contain at least a single colon.
//             Each line will be split on the first colon and the part before the colon used as key and the part
//             after the colon as value and inserted into "*parent_to_children_map".
void LoadRefs(const std::string &child_refs_filename) {
    std::ifstream child_refs(child_refs_filename.c_str());
    if (not child_refs.is_open())
        Error("Failed to open \"" + child_refs_filename + "\" for reading!");

    std::string line;
    unsigned line_no(0);
    while (std::getline(child_refs, line)) {
        ++line_no;
        const std::string::size_type first_colon_pos = line.find(':');
        if (first_colon_pos == std::string::npos)
            Error("Bad data in \"" + child_refs_filename + "\", could not find a colon on line "
                  + std::to_string(line_no) + "!");

        const std::string key(line.substr(0, first_colon_pos));
        if (key.empty())
            Error("Empty parent key in \"" + child_refs_filename + "\" on line " + std::to_string(line_no) + "!");
        if (parent_to_children_map.find(key) != parent_to_children_map.end())
            Error("Duplicate parent key \"" + key + "\" in \"" + child_refs_filename + "\"!");
        const std::string value(line.substr(first_colon_pos + 1));
        if (value.empty())
            Error("Empty child refs in \"" + child_refs_filename + "\" on line " + std::to_string(line_no) + "!");
        parent_to_children_map[key] = value;
    }

    if (parent_to_children_map.empty())
        Error("Found no data in \"" + child_refs_filename+ "\"!");
    std::cerr << "Read " << line_no << " parent-to-children references.\n";
}


// LoadTitles -- reads lines from "child_titles_filename".  Each line is expected to contain an ID followed by a
//               colon, followed by a subfield code, followed by another colon, followed by a title.
void LoadTitles(const std::string &child_titles_filename) {
    std::ifstream titles(child_titles_filename.c_str());
    if (not titles.is_open())
        Error("Failed to open \"" + child_titles_filename + "\" for reading!");

    std::string line;
    unsigned line_no(0);
    while (std::getline(titles, line)) {
        ++line_no;
        const std::string::size_type first_colon_pos = line.find(':');
        if (first_colon_pos == std::string::npos)
            Error("Bad data in \"" + child_titles_filename + "\", could not find a colon on line "
                  + std::to_string(line_no) + "!");

        const std::string key(line.substr(0, first_colon_pos));
        if (key.empty())
            Error("Empty ID in \"" + child_titles_filename + "\" on line " + std::to_string(line_no) + "!");
        if (id_to_title_map.find(key) != id_to_title_map.end())
            Error("Duplicate ID in \"" + child_titles_filename + "\"!");

        const std::string::size_type second_colon_pos = line.find(':', first_colon_pos + 1);
        if (second_colon_pos == std::string::npos)
            Error("Bad data in \"" + child_titles_filename + "\", could not find a 2nd colon on line "
                  + std::to_string(line_no) + "!");
        
        std::string title(line.substr(second_colon_pos + 1));
        if (title.empty())
            Error("Empty title in \"" + child_titles_filename + "\" on line " + std::to_string(line_no) + "!");

        StringUtil::RightTrim(" :./", &title);
        if (title.empty())
            Warning("Trimmed title is empty! (Original was \"" + line.substr(second_colon_pos + 1) + "\".)");
        else
            id_to_title_map[key] = title;
    }

    if (id_to_title_map.empty())
        Error("Found no data in \"" + child_titles_filename + "\"!");
    std::cerr << "Read " << line_no << " id-to-title mappings.\n";
}


int main(int argc, char **argv) {
    progname = argv[0];

    if (argc != 5)
        Usage();

    const std::string marc_input_filename(argv[1]);
    File marc_input(marc_input_filename, "rm");
    if (not marc_input)
        Error("can't open \"" + marc_input_filename + "\" for reading!");

    const std::string marc_output_filename(argv[2]);
    File marc_output(marc_output_filename, "w");
    if (not marc_output)
        Error("can't open \"" + marc_output_filename + "\" for writing!");

    try {
	LoadRefs(argv[3]);
	LoadTitles(argv[4]);
    } catch (const std::exception &x) {
	Error("caught exception: " + std::string(x.what()));
    }

    AddChildRefs(&marc_input, &marc_output);
}
