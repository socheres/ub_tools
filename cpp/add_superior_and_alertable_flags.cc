/** \file    add_superior_and_alertable_flags.cc
 *  \author  Oliver Obenland
 *  \author  Dr. Johannes Ruscheinski
 *
 *  A tool for marking superior records that have associated inferior records in our data sets.
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

#include <fstream>
#include <iostream>
#include <memory>
#include <unordered_map>
#include <cstdlib>
#include <cstring>
#include "Compiler.h"
#include "DirectoryEntry.h"
#include "FileUtil.h"
#include "Leader.h"
#include "MarcReader.h"
#include "MarcRecord.h"
#include "MarcWriter.h"
#include "StringUtil.h"
#include "Subfields.h"
#include "util.h"


static unsigned modified_count(0);
static std::set<std::string> superior_ppns;


void Usage() {
    std::cerr << "Usage: " << ::progname << " marc_input marc_output superior_ppns\n";
    std::exit(EXIT_FAILURE);
}


bool SeriesHasNotBeenCompleted(const MarcRecord &record) {
    const size_t _008_index(record.getFieldIndex("008"));
    if (unlikely(_008_index == MarcRecord::FIELD_NOT_FOUND))
        return false;

    const std::string &_008_contents(record.getFieldData(_008_index));
    return _008_contents.substr(11, 4) == "9999";
}


void ProcessRecord(File * const output, MarcRecord * const record) {
    // Don't add the flag twice:
    if (record->getFieldIndex("SPR") != MarcRecord::FIELD_NOT_FOUND) {
        MarcWriter::Write(*record, output);
        return;
    }

    Subfields superior_subfield(/* indicator1 = */' ', /* indicator2 = */' ');

    // Set the we are a "superior" record, if appropriate:
    const auto iter(superior_ppns.find(record->getControlNumber()));
    if (iter != superior_ppns.end())
        superior_subfield.addSubfield('a', "1"); // Could be anything but we can't have an empty field.

    // Set the, you-can-subscribe-to-this flag, if appropriate:
    if (record->getLeader().isSerial() and SeriesHasNotBeenCompleted(*record))
        superior_subfield.addSubfield('b', "1");

    if (not superior_subfield.empty()) {
        record->insertField("SPR", superior_subfield.toString());
        ++modified_count;
    }

    MarcWriter::Write(*record, output);
}


void AddSuperiorFlag(File * const input, File * const output) {
    while (MarcRecord record = MarcReader::Read(input))
        ProcessRecord(output, &record);

    std::cerr << "Modified " << modified_count << " record(s).\n";
}


void LoadSuperiorPPNs(File * const input) {
    unsigned line_no(0);
    std::string line;
    while (input->getline(&line)) {
        ++line_no;
        superior_ppns.emplace(line);
    }

    if (unlikely(superior_ppns.empty()))
        Error("Found no data in \"" + input->getPath() + "\"!");
    std::cerr << "Read " << line_no << " superior PPNs.\n";
}


int main(int argc, char **argv) {
    ::progname = argv[0];

    if (argc != 4)
        Usage();

    const std::unique_ptr<File> marc_input(FileUtil::OpenInputFileOrDie(argv[1]));
    const std::unique_ptr<File> marc_output(FileUtil::OpenOutputFileOrDie(argv[2]));
    const std::unique_ptr<File> superior_ppn_input(FileUtil::OpenInputFileOrDie(argv[3]));

    try {
        LoadSuperiorPPNs(superior_ppn_input.get());
        AddSuperiorFlag(marc_input.get(), marc_output.get());
    } catch (const std::exception &x) {
        Error("caught exception: " + std::string(x.what()));
    }
}
