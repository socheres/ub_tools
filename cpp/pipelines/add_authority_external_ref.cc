/** \file add_authority_wikidata_ids.cc
 *  \brief functionality to acquire wikidata id corresponding to their gnds
 *  \author andreas-ub
 *  \author Steven Lolong (steven.lolong@uni-tuebingen.de)
 *
 *  \copyright 2021-22 Universitätsbibliothek Tübingen.  All rights reserved.
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

#include <chrono>
#include <fstream>
#include <iostream>
#include <regex>
#include <string>
#include <nlohmann/json.hpp>
#include "BeaconFile.h"
#include "FileUtil.h"
#include "MARC.h"
#include "StringUtil.h"
#include "TextUtil.h"
#include "util.h"


[[noreturn]] void Usage() {
    ::Usage(
        "\t:\n"
        "\tinvocation modes:\n"
        "\t1.)  norm_data_marc_input norm_data_marc_output mapping_txt_file\n"
        "\t2.)  --create_mapping_file input_txt_file output_csv_file"
        "\n\n"
        "--create_mapping_file input_txt_file output_csv_file\n"
        "\t- input_txt_file: the file that generated with command: \n"
        "\t\tjq -c --stream '.' < authorities-gnd-person_lds.jsonld |grep -E 'https\\:/\\/d-nb\\.info\\/gnd\\/|wikidata|wikipedia'\n"
        "\t- output_csv_file: the gnd_to_wiki file to write to, it is a csv with ';' as delimiter.\n"
        "\t\tThe format: \n"
        "\t\t\tGND-ID;Wikidata-Entity-Id;Wikipedia-Address\n");
}


void ParseGndWikidataMappingFile(std::string filename,
                                 std::unordered_map<std::string, std::vector<std::string>> * const gnd_to_wikidataid_and_wikipedia_link) {
    std::ifstream file(filename);
    if (file.is_open()) {
        std::string line;
        std::string act_gnd;
        std::string act_wikidata;
        std::string act_wikipedia;
        while (std::getline(file, line)) {
            const std::string NAME = "Name:";
            const std::string GND = "GND:";
            const std::string WIKIDATA = "Wikidata:";
            const std::string WIKIPEDIA = "Wikipedia:";
            if (StringUtil::StartsWith(line, NAME) and StringUtil::Contains(line, GND) and StringUtil::Contains(line, WIKIDATA)
                and StringUtil::Contains(line, WIKIPEDIA))
            {
                act_gnd = line.substr(line.find(GND) + GND.length());
                act_gnd = act_gnd.substr(0, act_gnd.find(WIKIDATA));
                act_wikidata = line.substr(line.find(WIKIDATA) + WIKIDATA.length());
                act_wikidata = act_wikidata.substr(0, act_wikidata.find(WIKIPEDIA));
                act_wikipedia = line.substr(line.find(WIKIPEDIA) + WIKIPEDIA.length());
                std::vector<std::string> wiki_elements = { StringUtil::TrimWhite(act_wikidata), StringUtil::TrimWhite(act_wikipedia) };
                gnd_to_wikidataid_and_wikipedia_link->emplace(StringUtil::TrimWhite(act_gnd), wiki_elements);
            }
        }
        file.close();
    } else
        LOG_ERROR("input or output files could not be opened");
}

struct GNDStructure {
    std::string gnd_id, wikidata_personal_entity_id, wikipedia_personal_address;
};

bool IsThisCloseBracketForId(const std::string &url) {
    int url_length = url.length();
    std::string is_about(url.substr(url_length - 5, 5));
    if (is_about.compare("about") == 0)
        return true;

    return false;
}

bool DoesItMatch(const std::string &url_based, const std::string &url_comp) {
    const int base_string_lenght = url_based.length();
    const std::string sub_string_url_comp = url_comp.substr(0, base_string_lenght);
    if (url_based.compare(sub_string_url_comp) == 0)
        return true;

    return false;
}

bool GenerateGNDAuthorityExternalRef(char *argv[]) {
    const auto load_file_start(std::chrono::high_resolution_clock::now());
    std::ifstream input_file(argv[2]);

    if (!input_file.is_open()) {
        LOG_ERROR("can't open input file");
        return false;
    }

    const auto csv_file(FileUtil::OpenOutputFileOrDie(argv[3]));


    const std::string dnb_address("https://d-nb.info/gnd/");
    const std::string wikidata_address("http://www.wikidata.org/entity/");
    const std::string wikipedia_address("https://de.wikipedia.org/wiki/");
    std::string gnd_id;
    bool is_start_group = false;
    GNDStructure gnd_data;
    int top_level_number(-1), second_level_number(-1), total_numbers_of_gnd_id_generated(0), total_line_parsed(0),
        total_number_of_wikidata(0), total_number_of_wikipedia(0);

    const int dnb_add_str_lenght(dnb_address.length()), wikidata_address_str_lenght(wikidata_address.length());

    std::string line, id_annotaton(""), second_element_of_array;
    nlohmann::json line_parsed;
    std::string gnd_id_temp_string;
    std::string wikidata_temp_string;
    std::string tmp_id;


    while (std::getline(input_file, line)) {
        line_parsed = nlohmann::json::parse(line);
        // get information on first element of array
        if (line_parsed[0].is_array() && line_parsed[0][2].is_string()) {
            id_annotaton = line_parsed[0][2].get<std::string>();
            if (id_annotaton.compare("@id") == 0) {
                // the second element of array is not an array nor object
                if (!line_parsed[1].is_structured()) {
                    // if id without about, this means the beginning of group or opening bracket.
                    if (!IsThisCloseBracketForId(line_parsed[1])) {
                        // get gnd id, set is_start_group to true, set top_level_number, set second_level_number
                        // tmp_id = nlohmann::to_string(line_parsed[1]);
                        if (line_parsed[1].is_string()) {
                            top_level_number = line_parsed[0][0].get<int>();
                            second_level_number = line_parsed[0][1].get<int>();
                            is_start_group = true;
                            gnd_id_temp_string = line_parsed[1].get<std::string>();
                            gnd_data.gnd_id =
                                gnd_id_temp_string.substr(dnb_add_str_lenght, (gnd_id_temp_string.length() - dnb_add_str_lenght));

                            ++total_numbers_of_gnd_id_generated;
                        }
                    }
                }
                // if id -> about, this means the last of group or this is the closing bracket.
                // then print the accumulation of last result data and reset all info
                if (IsThisCloseBracketForId(line_parsed[1])) {
                    csv_file->write(TextUtil::CSVEscape(gnd_data.gnd_id) + ";");
                    csv_file->write(TextUtil::CSVEscape(gnd_data.wikidata_personal_entity_id) + ";");
                    csv_file->write(TextUtil::CSVEscape(gnd_data.wikipedia_personal_address) + "\n");
                    top_level_number = -1;
                    second_level_number = -1;
                    is_start_group = false;
                    gnd_id_temp_string = "";
                    gnd_data = {};
                }
            }

            if (is_start_group) {
                // std::cout << top_level_number << " , " << second_level_number << std::endl;
                if (line_parsed[0][0].get<int>() == top_level_number && line_parsed[0][1].get<int>() == second_level_number) {
                    if (!line_parsed[1].is_structured()) {
                        if (line_parsed[1].is_string()) {
                            if (DoesItMatch(wikipedia_address, line_parsed[1].get<std::string>())) {
                                gnd_data.wikipedia_personal_address = line_parsed[1].get<std::string>();

                                ++total_number_of_wikipedia;
                            }

                            // if wikidata
                            if (DoesItMatch(wikidata_address, line_parsed[1].get<std::string>())) {
                                wikidata_temp_string = nlohmann::to_string(line_parsed[1]);
                                gnd_data.wikidata_personal_entity_id = wikidata_temp_string.substr(
                                    wikidata_address_str_lenght + 1, (wikidata_temp_string.length() - (wikidata_address_str_lenght + 2)));

                                ++total_number_of_wikidata;
                            }
                        }
                    }
                }
            }
        }
        std::cout << "\r"
                  << "Parsed: " << total_line_parsed << " line(s), "
                  << " Total GND-ID: " << total_numbers_of_gnd_id_generated << ", Total GND with Wikidata: " << total_number_of_wikidata
                  << ", Total GND with Wikipedia: " << total_number_of_wikipedia;
        //   << "GND-ID url: " << tmp_id;
        std::cout.flush();
        ++total_line_parsed;
    }

    const auto load_file_end(std::chrono::high_resolution_clock::now());
    auto duration = std::chrono::duration_cast<std::chrono::seconds>(load_file_end - load_file_start);

    std::cout << std::endl
              << "Total GND-ID: " << total_numbers_of_gnd_id_generated << std::endl
              << "Total GND with Wikidata: " << total_number_of_wikidata << std::endl
              << "Total GND with Wikipedia: " << total_number_of_wikipedia << std::endl;
    std::cout << "Total time of computation: " << duration.count() << " second(s)" << std::endl;

    input_file.close();
    return true;
}

int Main(int argc, char *argv[]) {
    if (argc < 4)
        Usage();

    const std::string marc_input_filename_or_create_flag(argv[1]);
    const std::string marc_output_filename_or_dnb_input(argv[2]);
    const std::string mapping_txt_filename(argv[3]);

    if (marc_input_filename_or_create_flag == "--create_mapping_file") {
        if (argc != 4)
            Usage();

        if (GenerateGNDAuthorityExternalRef(argv))
            return EXIT_SUCCESS;

        return EXIT_FAILURE;
    }

    std::unordered_map<std::string, std::vector<std::string>> gnd_to_wikielements;
    ParseGndWikidataMappingFile(mapping_txt_filename, &gnd_to_wikielements);

    std::unique_ptr<MARC::Reader> marc_reader(MARC::Reader::Factory(marc_input_filename_or_create_flag));
    std::unique_ptr<MARC::Writer> marc_writer(MARC::Writer::Factory(marc_output_filename_or_dnb_input));

    if (unlikely(marc_input_filename_or_create_flag == marc_output_filename_or_dnb_input))
        LOG_ERROR("Norm data input file name equals output file name!");

    while (MARC::Record record = marc_reader.get()->read()) {
        // 035|a (DE-588)118562215
        std::string record_gnd;
        std::string wikidata_id;
        std::string wikidata_id_orig;
        std::string wikipedia_link;
        std::string wikipedia_link_orig;
        std::vector<std::string> wiki_elements;

        MARC::GetGNDCode(record, &record_gnd);
        MARC::GetWikidataId(record, &wikidata_id_orig);
        MARC::GetWikipediaLink(record, &wikipedia_link_orig);

        // record lookup
        if (not record_gnd.empty()) {
            auto gnd_to_wikielements_iter = gnd_to_wikielements.find(record_gnd);
            if (gnd_to_wikielements_iter != gnd_to_wikielements.end()) {
                wiki_elements = gnd_to_wikielements_iter->second;
                if (wiki_elements.size() > 0)
                    wikidata_id = wiki_elements[0];
                if (wiki_elements.size() > 1)
                    wikipedia_link = wiki_elements[1];
            }
        }

        if (not wikidata_id.empty() and wikidata_id_orig != wikidata_id)
            record.insertField("024", { { 'a', wikidata_id }, { '2', "wikidata" }, { '9', "PipeLineGenerated" } }, /*indicator 1*/ '7');
        if (not wikipedia_link.empty() and wikipedia_link != wikipedia_link_orig)
            record.insertField("670", { { 'a', "Wikipedia" }, { 'u', wikipedia_link }, { '9', "PipeLineGenerated" } });

        marc_writer.get()->write(record);
    }

    return EXIT_SUCCESS;
}
