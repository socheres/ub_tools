/** \brief Utility for generating a listing of select journals' latest years.
 *  \note  See https://github.com/ubtue/tuefind/issues/238 for details.
 *  \author Dr. Johannes Ruscheinski (johannes.ruscheinski@uni-tuebingen.de)
 *
 *  \copyright 2018 Universitätsbibliothek Tübingen.  All rights reserved.
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
#include <stdexcept>
#include <unordered_map>
#include <vector>
#include <cstdio>
#include <cstdlib>
#include "FileUtil.h"
#include "MARC.h"
#include "TextUtil.h"
#include "TimeUtil.h"
#include "StringUtil.h"
#include "util.h"


namespace {


[[noreturn]] void Usage() {
    std::cerr << "Usage: " << ::progname << " journal_list marc_data report\n";
    std::exit(EXIT_FAILURE);
}


constexpr unsigned INVALID_YEAR(0);


class JournalDescriptor {
public:
    enum Type { PRINT, ELECTRONIC };
private:
    std::string id_, ppn_;
    Type type_;
    unsigned most_recent_year_;
public:
    JournalDescriptor(const std::string &id, const std::string &ppn, const Type type)
        : id_(id), ppn_(ppn), type_(type), most_recent_year_(INVALID_YEAR) { }
    JournalDescriptor() = default;
    JournalDescriptor(const JournalDescriptor &rhs) = default;

    inline bool operator<(const JournalDescriptor &rhs) const { return id_ < rhs.id_; }
    inline const std::string &getId() const { return id_; }
    inline const std::string &getPPN() const { return ppn_; }
    inline Type getType() const { return type_; }
    inline unsigned getMostRecentYear() const { return most_recent_year_; }
    void updateMostRecentYear(const unsigned year);
};


bool IsPlausibleYear(const unsigned year) {
    const unsigned current_year(StringUtil::ToUnsigned(TimeUtil::GetCurrentYear()));
    return year >= 1900 and year <= current_year + 1;
}


void JournalDescriptor::updateMostRecentYear(const unsigned year) {
    if (IsPlausibleYear(year) and year > most_recent_year_)
        most_recent_year_ = year;
}


void LoadJournalPPNs(const std::string &path,
                     std::unordered_map<std::string, JournalDescriptor> * const ppn_to_journal_desc_map)
{
    std::vector<std::vector<std::string>> lines;
    TextUtil::ParseCSVFileOrDie(path, &lines);
    INFO("Found " + std::to_string(lines.size() - 1) + " journal entries.");

    auto line(lines.cbegin());
    if (line == lines.cend())
        ERROR("Empty input file: \"" + path + "\"!");

    for (++line /* Skip over header. */; line != lines.cend(); ++line) {
        if (line->size() != 3)
            ERROR("logical line #" + std::to_string(line - lines.cbegin()) + " does not contain 3 values! (Instead we have "
                  + std::to_string(line->size()) + " values.)");
        if (unlikely((*line)[0].empty()))
            ERROR("logical line #" + std::to_string(line - lines.cbegin()) + " is missing the ID!");
        if (unlikely((*line)[1].empty() and (*line)[2].empty()))
            ERROR("logical line #" + std::to_string(line - lines.cbegin()) + " is missing a PPN!");
        if (not (*line)[1].empty())
            ppn_to_journal_desc_map->emplace((*line)[1], JournalDescriptor((*line)[0], (*line)[1], JournalDescriptor::PRINT));
        if (not (*line)[2].empty())
           ppn_to_journal_desc_map->emplace((*line)[2], JournalDescriptor((*line)[0], (*line)[2], JournalDescriptor::PRINT));
    }

    INFO("Found " + std::to_string(ppn_to_journal_desc_map->size()) + " journal PPN's.");
}


static const std::set<std::string> UPLINK_TAGS{ "800", "810", "830", "773", "776" };


std::string GetUplinkPPN(const MARC::Record &record) {
    for (const auto &tag : UPLINK_TAGS) {
        for (const auto &field : record.getTagRange(tag)) {
            const MARC::Subfields subfields(field.getSubfields());
            const std::string w_subfield(subfields.getFirstSubfieldWithCode('w'));
            if (not w_subfield.empty() and StringUtil::StartsWith(w_subfield, "(DE-576)"))
                return StringUtil::TrimWhite(w_subfield.substr(__builtin_strlen("(DE-576)")));
        }
    }

    return "";
}


/** Returns the 2nd year of a slash-separated pair like "1963/4", "1952/53", or 1999/2000" or returns the argument if we
    don't know what to do with it. */
std::string GetSecondYearOfRange(const std::string &year_candidate) {
    if (year_candidate.length() <= 4 or year_candidate[4] != '/')
        return year_candidate;

    const std::string fragment(year_candidate.substr(4 + 1));
    return year_candidate.substr(0, 4 - fragment.length()) + fragment;
}


void ProcessRecords(MARC::Reader * const marc_reader,
                    std::unordered_map<std::string, JournalDescriptor> * const ppn_to_journal_desc_map)
{
    unsigned record_count(0);
    while (const MARC::Record record = marc_reader->read()) {
        ++record_count;

        const std::string parent_ppn(GetUplinkPPN(record));
        if (parent_ppn.empty())
            continue;

        const auto parent_ppn_and_journal_desc(ppn_to_journal_desc_map->find(parent_ppn));
        if (parent_ppn_and_journal_desc == ppn_to_journal_desc_map->end())
            continue;

        std::string year_as_string;
        for (const auto &field : record.getTagRange("936")) {
            const MARC::Subfields subfields(field.getSubfields());
            year_as_string = subfields.getFirstSubfieldWithCode('j');
            if (not year_as_string.empty())
                break;
        }
        if (year_as_string.empty())
            continue;

        year_as_string = GetSecondYearOfRange(year_as_string);
        if (year_as_string.length() != 4) {
            INFO("Bad year: \"" + year_as_string + "\". (1)");
            continue;
        }

        unsigned year;
        if (StringUtil::ToUnsigned(year_as_string, &year))
            parent_ppn_and_journal_desc->second.updateMostRecentYear(year);
        else
            INFO("Bad year: \"" + year_as_string + "\". (2)");
    }

    INFO("Processed " + std::to_string(record_count) + " MARC record(s).");
}


void GenerateReport(const std::string &report_filename,
                    const std::unordered_map<std::string, JournalDescriptor> &ppn_to_journal_desc_map)
{
    std::vector<JournalDescriptor> journal_descs;
    journal_descs.reserve(ppn_to_journal_desc_map.size());

    for (const auto &ppn_and_journal_desc : ppn_to_journal_desc_map) {
        if (ppn_and_journal_desc.second.getMostRecentYear() != INVALID_YEAR)
            journal_descs.push_back(ppn_and_journal_desc.second);
    }
    std::sort(journal_descs.begin(), journal_descs.end());

    std::unique_ptr<File> report(FileUtil::OpenOutputFileOrDie(report_filename));
    for (const auto &journal_desc : journal_descs)
        (*report) << journal_desc.getPPN() << ", " << journal_desc.getMostRecentYear() << "\n";
}


} // unnamed namespace


int main(int argc, char *argv[]) {
    ::progname = argv[0];

    if (argc != 4)
        Usage();

    try {
        std::unordered_map<std::string, JournalDescriptor> ppn_to_journal_desc_map;
        LoadJournalPPNs(argv[1], &ppn_to_journal_desc_map);
        std::unique_ptr<MARC::Reader> marc_reader(MARC::Reader::Factory(argv[2]));
        ProcessRecords(marc_reader.get(), &ppn_to_journal_desc_map);
        GenerateReport(argv[3], ppn_to_journal_desc_map);
    } catch (const std::exception &e) {
        ERROR("caught exception: " + std::string(e.what()));
    }
}
