/** \brief Utility for finding missing metadata that we used to get in the past.
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
#include <map>
#include <unordered_set>
#include <cstdio>
#include <cstdlib>
#include "Compiler.h"
#include "DbConnection.h"
#include "DbResultSet.h"
#include "DbRow.h"
#include "IniFile.h"
#include "FileUtil.h"
#include "MARC.h"
#include "util.h"


namespace {


[[noreturn]] void Usage() {
    std::cerr << "Usage: " << ::progname << " marc_file missed_expectations_list\n";
    std::exit(EXIT_FAILURE);
}


enum FieldPresence { ALWAYS, SOMETIMES, IGNORE };


struct FieldInfo {
    std::string name_;
    FieldPresence presence_;
public:
    FieldInfo(const std::string &name, const FieldPresence presence): name_(name), presence_(presence) { }
};


class JournalInfo {
    bool not_in_database_yet_;
    std::vector<FieldInfo> field_infos_;
public:
    using const_iterator = std::vector<FieldInfo>::const_iterator;
    using iterator = std::vector<FieldInfo>::iterator;
public:
    explicit JournalInfo(const bool not_in_database_yet): not_in_database_yet_(not_in_database_yet) { }
    JournalInfo() = default;
    JournalInfo(const JournalInfo &rhs) = default;

    size_t size() const { return field_infos_.size(); }
    bool isInDatabase() const { return not not_in_database_yet_; }
    void addField(const std::string &field_name, const FieldPresence field_presence)
        { field_infos_.emplace_back(field_name, field_presence); }
    const_iterator begin() const { return field_infos_.cbegin(); }
    const_iterator end() const { return field_infos_.cend(); }
    iterator begin() { return field_infos_.begin(); }
    iterator end() { return field_infos_.end(); }
    iterator find(const std::string &field_name) {
        return std::find_if(field_infos_.begin(), field_infos_.end(),
                            [&field_name](const FieldInfo &field_info){ return field_name == field_info.name_; });
    }
};


std::string GetJournalNameOrDie(const MARC::Record &record) {
    const auto _773_field(record.getFirstField("773"));
    if (unlikely(_773_field == record.end()))
        LOG_ERROR("record w/ control number \"" + record.getControlNumber() + "\" is missing a 773-field!");
    const auto journal_name(_773_field->getFirstSubfieldWithCode('a'));
    if (unlikely(journal_name.empty()))
        LOG_ERROR("the first 773-field of the record w/ control number \"" + record.getControlNumber() + "\" is missing a $a-subfield!");

    return journal_name;
}


FieldPresence StringToFieldPresence(const std::string &s) {
    if (s == "always")
        return ALWAYS;
    if (s == "sometimes")
        return SOMETIMES;
    if (s == "ignore")
        return IGNORE;
    LOG_ERROR("unknown enumerated value \"" + s + "\"!");
}


std::string FieldPresenceToString(const FieldPresence field_presence) {
    switch (field_presence) {
    case ALWAYS:
        return "always";
    case SOMETIMES:
        return "sometimes";
    case IGNORE:
        return "ignore";
    default:
        LOG_ERROR("we should *never get here!");
    }
}


void LoadFromDatabaseOrCreateFromScratch(DbConnection * const db_connection, const std::string &journal_name,
                                         JournalInfo * const journal_info)
{
    db_connection->queryOrDie("SELECT metadata_field_name,field_presence FROM metadata_presence_tracer WHERE journal_name='"
                              + db_connection->escapeString(journal_name)
                              + "'");
    DbResultSet result_set(db_connection->getLastResultSet());
    if (result_set.empty()) {
        LOG_INFO("\"" + journal_name + "\" was not yet in the database.");
        *journal_info = JournalInfo(/* not_in_database_yet = */true);
        return;
    }

    *journal_info = JournalInfo(/* not_in_database_yet = */false);
    while (auto row = result_set.getNextRow())
        journal_info->addField(row["metadata_field_name"], StringToFieldPresence(row["field_presence"]));
    LOG_INFO("Loadad " + std::to_string(journal_info->size()) + " entries for \"" + journal_name + "\" from the database.");
}


void AnalyseNewJournalRecord(const MARC::Record &record, const bool first_record, JournalInfo * const journal_info) {
    std::unordered_set<std::string> seen_tags;
    MARC::Tag last_tag;
    for (const auto &field : record) {
        const auto current_tag(field.getTag());
        if (current_tag == last_tag)
            continue;
        seen_tags.emplace(current_tag.toString());

        if (first_record)
            journal_info->addField(current_tag.toString(), ALWAYS);
        else if (journal_info->find(current_tag.toString()) == journal_info->end())
            journal_info->addField(current_tag.toString(), SOMETIMES);

        last_tag = current_tag;
    }

    for (auto &field_info : *journal_info) {
        if (seen_tags.find(field_info.name_) == seen_tags.end())
            field_info.presence_ = SOMETIMES;
    }
}


bool RecordMeetsExpectations(const MARC::Record &record, File * const output, const std::string &journal_name,
                             const JournalInfo &journal_info)
{
    std::unordered_set<std::string> seen_tags;
    MARC::Tag last_tag;
    for (const auto &field : record) {
        const auto current_tag(field.getTag());
        if (current_tag == last_tag)
            continue;
        seen_tags.emplace(current_tag.toString());
        last_tag = current_tag;
    }

    bool missed_at_least_one_expectation(false);
    for (const auto &field_info : journal_info) {
        if (seen_tags.find(field_info.name_) == seen_tags.end() and field_info.presence_ == ALWAYS) {
            (*output) << "Record w/ control number " + record.getControlNumber() + " in \"" << journal_name
                      << "\" is missing the always expected " << field_info.name_ << " field.\n";
            missed_at_least_one_expectation = true;
        }
    }

    return not missed_at_least_one_expectation;
}


void WriteToDatabase(DbConnection * const db_connection, const std::string &journal_name, const JournalInfo &journal_info) {
    for (const auto &field_info : journal_info)
        db_connection->queryOrDie("INSERT INTO metadata_presence_tracer SET journal_name='" + journal_name
                                  + "', metadata_field_name='" + db_connection->escapeString(field_info.name_)
                                  + "', field_presence='" + FieldPresenceToString(field_info.presence_) + "'");
}


} // unnamed namespace


int Main(int argc, char *argv[]) {
    if (argc != 3)
        Usage();

    DbConnection db_connection;
    auto reader (MARC::Reader::Factory(argv[1]));
    auto missed_expectations_list(FileUtil::OpenOutputFileOrDie(argv[2]));
    std::map<std::string, JournalInfo> journal_name_to_info_map;

    unsigned total_record_count(0), new_record_count(0), missed_expectation_count(0);
    while (const auto record = reader->read()) {
        ++total_record_count;
        const auto journal_name(GetJournalNameOrDie(record));

        auto journal_name_and_info(journal_name_to_info_map.find(journal_name));
        bool first_record(false); // True if the current record is the first encounter of a journal
        if (journal_name_and_info == journal_name_to_info_map.end()) {
            first_record = true;
            JournalInfo new_journal_info;
            LoadFromDatabaseOrCreateFromScratch(&db_connection, journal_name, &new_journal_info);
            journal_name_to_info_map[journal_name] = new_journal_info;
            journal_name_and_info = journal_name_to_info_map.find(journal_name);
        }

        if (journal_name_and_info->second.isInDatabase()) {
            if (not RecordMeetsExpectations(record, missed_expectations_list.get(), journal_name_and_info->first,
                                            journal_name_and_info->second))
                ++missed_expectation_count;
        } else {
            AnalyseNewJournalRecord(record, first_record, &journal_name_and_info->second);
            ++new_record_count;
        }
    }

    for (const auto &journal_name_and_info : journal_name_to_info_map) {
        if (not journal_name_and_info.second.isInDatabase())
            WriteToDatabase(&db_connection, journal_name_and_info.first, journal_name_and_info.second);
    }

    LOG_INFO("Processed " + std::to_string(total_record_count) + " reocrd(s) of which " + std::to_string(new_record_count)
             + " was/were (a) record(s) of new journals and " + std::to_string(missed_expectation_count)
             + " record(s) missed expectations.");

    return EXIT_SUCCESS;
}