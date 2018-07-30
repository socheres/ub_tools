/** \brief Utility for displaying various bits of info about a collection of MARC records.
 *  \author Dr. Johannes Ruscheinski (johannes.ruscheinski@uni-tuebingen.de)
 *
 *  \copyright 2015-2018 Universitätsbibliothek Tübingen.  All rights reserved.
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

#include <algorithm>
#include <iostream>
#include <map>
#include <stdexcept>
#include <unordered_set>
#include <vector>
#include <cstdio>
#include <cstdlib>
#include "FileUtil.h"
#include "MARC.h"
#include "util.h"


namespace {


[[noreturn]] void Usage() {
    std::cerr << "Usage: " << ::progname << " [--verbose] marc_data\n";
    std::exit(EXIT_FAILURE);
}


void ProcessRecords(const bool verbose, MARC::Reader * const marc_reader) {
    std::string raw_record;
    unsigned record_count(0), max_record_length(0), max_local_block_count(0), oversized_record_count(0),
        max_subfield_count(0), cumulative_field_count(0);
    std::unordered_set<std::string> control_numbers;
    std::map<MARC::Record::RecordType, unsigned> record_types_and_counts;

    while (const MARC::Record record = marc_reader->read()) {
        ++record_count;
        cumulative_field_count += record.getNumberOfFields();

        if (unlikely(record.getNumberOfFields() == 0))
            logger->error("record #" + std::to_string(record_count) + " has zero fields!");
        const std::string &control_number(record.getControlNumber());

        if (control_numbers.find(control_number) != control_numbers.end())
            logger->warning("found at least one duplicate control number: " + control_number);
        control_numbers.insert(control_number);

        const MARC::Record::RecordType record_type(record.getRecordType());
        ++record_types_and_counts[record_type];
        if (verbose and record_type == MARC::Record::RecordType::UNKNOWN)
            std::cerr << "Unknown record type '" << record.getLeader()[6] << "' for PPN " << control_number
                      << ".\n";

        const unsigned record_length(record.size());
        if (record_length > max_record_length)
            max_record_length = record_length;
        if (record_length > MARC::Record::MAX_RECORD_LENGTH)
            ++oversized_record_count;

        for (const auto &field : record) {
            if (field.isControlField())
                continue;

            const MARC::Subfields subfields(field.getContents());
            const size_t subfield_count(subfields.size());
            if (unlikely(subfield_count > max_subfield_count))
                max_subfield_count = subfield_count;
        }

        const auto local_block_starts(record.findStartOfAllLocalDataBlocks());
        const size_t local_block_count(local_block_starts.size());
        if (local_block_count > max_local_block_count)
            max_local_block_count = local_block_count;
        for (const auto local_block_start : local_block_starts) {
            if (record.findFieldsInLocalBlock("001", local_block_start).size() != 1)
                LOG_ERROR("Every local data block has to have exactly one 001 field. (Record: "
                          + record.getControlNumber() + ", Local data block starts at field: "
                          + std::to_string(local_block_start - record.begin()) + ")");
        }
    }

    std::cout << "Data set contains " << record_count << " MARC record(s).\n";
    std::cout << "Largest record contains " << max_record_length << " bytes.\n";
    std::cout << "The record with the largest number of \"local\" blocks has " << max_local_block_count
              << " local blocks.\n";
    std::cout << "Counted " << record_types_and_counts[MARC::Record::RecordType::BIBLIOGRAPHIC]
              << " bibliographic record(s), " << record_types_and_counts[MARC::Record::RecordType::AUTHORITY]
              << " authority record(s), " << record_types_and_counts[MARC::Record::RecordType::CLASSIFICATION]
              << " classification record(s), and " << record_types_and_counts[MARC::Record::RecordType::UNKNOWN]
              << " record(s) of unknown record type.\n";
    std::cout << "Found " << oversized_record_count << " oversized records.\n";
    std::cout << "The field with the most subfields has " << max_subfield_count << " subfield(s).\n";
    std::cout << "The average no. of fields per record is "
              << (static_cast<double>(cumulative_field_count) / record_count) << ".\n";
    std::cout << "The average record size in bytes is "
              << (static_cast<double>(FileUtil::GetFileSize(marc_reader->getPath())) / record_count) << ".\n";
}


} // unnamed namespace


int Main(int argc, char *argv[]) {
    if (argc < 2)
        Usage();

    const bool verbose(std::strcmp(argv[1], "--verbose") == 0);
    if (verbose)
        --argc, ++argv;

    if (argc != 2)
        Usage();

    auto marc_reader(MARC::Reader::Factory(argv[1]));
    ProcessRecords(verbose, marc_reader.get());

    return EXIT_SUCCESS;
}
