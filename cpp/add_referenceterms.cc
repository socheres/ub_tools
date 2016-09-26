/** \file    add_referenceterms.cc
 *  \brief   Read in a list of IDs and reference terms (Hinweissätze) and add it to the Marc Title Data
 *  \author  Johannes Riedl
 */

/*
    Copyright (C) 2016, Library of the University of Tübingen

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

/*  We offer a list of tags and subfields where the primary data resides along
    with a list of tags and subfields where the synonym data is found and
    a list of unused fields in the title data where the synonyms can be stored 
*/

#include <iostream>
#include <map>
#include <vector>
#include <cstdlib>
#include "Compiler.h"
#include "FileUtil.h"
#include "MarcUtil.h"
#include "MarcXmlWriter.h"
#include "MediaTypeUtil.h"
#include "StringUtil.h"
#include "Subfields.h"
#include "util.h"


static unsigned record_count(0);
static unsigned modified_count(0);

void Usage() {
    std::cerr << "Usage: " << ::progname << " reference_data_id_term_list marc_input marc_output\n";
    std::exit(EXIT_FAILURE);
}


std::string GetTag(const std::string &tag_and_subfields_spec) {
    return tag_and_subfields_spec.substr(0, 3);
}


std::string GetSubfieldCodes(const std::string &tag_and_subfields_spec) {
    return tag_and_subfields_spec.substr(3);
}


void ExtractSynonyms(File * const reference_data_id_term_list_input, std::map<std::string, std::string> * synonym_map) 
{
    while (not reference_data_id_term_list_input->eof()) {
        std::string line(reference_data_id_term_list_input->getline());
        std::vector<std::string> ids_and_terms;
        if (unlikely(StringUtil::SplitThenTrim(line, '|', "\"", &ids_and_terms) < 2))
            Error("Invalid line");
        std::string id(ids_and_terms[0]);
        ids_and_terms.erase(ids_and_terms.begin());
        (*synonym_map)[id] = StringUtil::Join(ids_and_terms, ',');
    }
}


void ProcessRecord(MarcUtil::Record * const record, const std::string &output_tag_and_subfield_code, const std::map<std::string, std::string> &synonym_map) {

    std::map<std::string, std::string>::const_iterator iter(synonym_map.find(record->getControlNumber()));

    // Abort if not found
    if (iter == synonym_map.cend())
         return;

    std::string synonyms(iter->second);
    

    // Insert synonyms
    // Abort if field is already populated
    const std::string tag(GetTag(output_tag_and_subfield_code));
    if (record->getFieldIndex(tag) != -1)
        Error("Field with tag " + tag + " is not empty for PPN " + record->getControlNumber() + '\n');
    std::string subfield_spec(GetSubfieldCodes(output_tag_and_subfield_code));
    if (subfield_spec.size() != 1)
        Error("We currently only support a single subfield and thus specifying " + subfield_spec + " as output subfield is not valid\n");
    Subfields subfields(' ', ' '); // <- indicators must be set explicitly although empty
    subfields.addSubfield(subfield_spec[0], synonyms);
    if (not(record->insertField(tag, subfields.toString())))
        Warning("Could not insert field " + tag + " for PPN " + record->getControlNumber());
    ++modified_count;
}


void InsertSynonyms(File * const marc_input, File * marc_output, const std::string &output_tag_and_subfield_code, const std::map<std::string, std::string> &synonym_map)
{
    MarcXmlWriter xml_writer(marc_output);

    while (MarcUtil::Record record = MarcUtil::Record::XmlFactory(marc_input)) {
        ProcessRecord(&record, output_tag_and_subfield_code, synonym_map);
        record.write(&xml_writer);
        ++record_count;
    }

    std::cerr << "Modified " << modified_count << " of " << record_count << " record(s).\n";
}


int main(int argc, char **argv) {
    ::progname = argv[0];

    if (argc != 4)
        Usage();

    const std::string reference_data_id_term_list_filename(argv[1]);
    std::unique_ptr<File> reference_data_id_term_list_input(FileUtil::OpenInputFileOrDie(reference_data_id_term_list_filename));

    const std::string marc_input_filename(argv[2]);
    const std::unique_ptr<File> marc_input(FileUtil::OpenInputFileOrDie(marc_input_filename));

    const std::string marc_output_filename(argv[3]);
    if (unlikely(marc_input_filename == marc_output_filename))
        Error("Title data input file name equals output file name!");

    if (unlikely(reference_data_id_term_list_filename == marc_output_filename))
        Error("Reference data id term list input file name equals output file name!");

    std::unique_ptr<File> marc_output(FileUtil::OpenOutputFileOrDie(marc_output_filename));

    const std::string TITLE_DATA_UNUSED_FIELD_FOR_SYNONYMS("187a");

    try {
        std::map<std::string, std::string> synonym_map;
        // Extract the synonyms from reference marc data
        ExtractSynonyms(reference_data_id_term_list_input.get(), &synonym_map);
        InsertSynonyms(marc_input.get(), marc_output.get(), TITLE_DATA_UNUSED_FIELD_FOR_SYNONYMS, synonym_map);
    } catch (const std::exception &x) {
        Error("caught exception: " + std::string(x.what()));
    }
}
