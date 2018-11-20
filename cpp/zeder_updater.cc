/** \brief Updates Zeder (via Ingo's SQL database) w/ the last N issues of harvested articles for each journal.
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
#include <iostream>
#include <ctime>
#include <cstdlib>
#include "DbConnection.h"
#include "DbResultSet.h"
#include "DbRow.h"
#include "FileUtil.h"
#include "IniFile.h"
#include "SqlUtil.h"
#include "UBTools.h"
#include "util.h"


namespace {


[[noreturn]] void Usage() {
    std::cerr << "Usage: " << ::progname
              << " [--min-log-level=log_level] sender_email_address notification_email_address\n";
    std::exit(EXIT_FAILURE);
}


const std::string TIMESTAMP_FILENAME("zeder_updater.timestamp");


// Returns the contents of the timestamp file or 0 if the file does not exist
time_t ReadTimeStamp() {
    const std::string TIMESTAMP_PATH(UBTools::GetTuelibPath() + TIMESTAMP_FILENAME);
    if (FileUtil::Exists(TIMESTAMP_PATH)) {
        time_t timestamp;
        const auto timestamp_file(FileUtil::OpenInputFileOrDie(TIMESTAMP_PATH));
        if (timestamp_file->read(reinterpret_cast<void *>(&timestamp), sizeof timestamp) != sizeof timestamp)
            LOG_ERROR("failed to read " + std::to_string(sizeof timestamp) + " bytes from \"" + TIMESTAMP_PATH + "\"!");
std::cerr << "Old timestamp: " << SqlUtil::TimeTToDatetime(timestamp) << '\n';
        return timestamp;
    } else
        return 0;
}


void WriteTimeStamp(const time_t timestamp) {
    const std::string TIMESTAMP_PATH(UBTools::GetTuelibPath() + TIMESTAMP_FILENAME);
    const auto timestamp_file(FileUtil::OpenOutputFileOrDie(TIMESTAMP_PATH));
std::cerr << "New timestamp: " << SqlUtil::TimeTToDatetime(timestamp) << '\n';
    if (timestamp_file->write(reinterpret_cast<const void *>(&timestamp), sizeof timestamp) != sizeof timestamp)
        LOG_ERROR("failed to write " + std::to_string(sizeof timestamp) + " bytes to \"" + TIMESTAMP_PATH + "\"!");
}


bool ProcessJournal(DbConnection * const db_connection, const time_t old_timestamp, const std::string &zeder_id,
                    const std::string &superior_title, const std::string &zeder_url_prefix, const unsigned max_issue_count)
{
    db_connection->queryOrDie("SELECT volume,issue,pages,created_at,resource_type FROM marc_records WHERE zeder_id="
                              + db_connection->escapeAndQuoteString(zeder_id) + " ORDER BY created_at DESC LIMIT "
                              + std::to_string(max_issue_count));

    bool found_at_least_one_new_issue;
    DbResultSet result_set(db_connection->getLastResultSet());
    while (const DbRow row = result_set.getNextRow()) {
        const time_t created_at(SqlUtil::DatetimeToTimeT(row["created_at"]));
        std::string status;
        if (created_at > old_timestamp) {
            found_at_least_one_new_issue = true;
            status = "neu";
        } else
            status = "unverändert";

        std::cout << zeder_url_prefix << zeder_id << "," << row["created_at"] << "," << superior_title << "," << row["volume"] << ";"
                  << row["issue"] << ";" << row["pages"] << "," << status << "," << row["resource_type"] << "\n";
    }

    return found_at_least_one_new_issue;
}


} // unnamed namespace


int Main(int argc, char *argv[]) {
    if (argc != 3)
        Usage();

    const std::string sender_email_address(argv[1]), notification_email_address(argv[2]);
    IniFile ini_file;
    const unsigned max_issue_count(ini_file.getUnsigned("", "max_issue_count"));
    const std::string zeder_url_prefix(ini_file.getString("", "zeder_url_prefix"));

    const time_t old_timestamp(ReadTimeStamp());
    DbConnection db_connection(DbConnection::TZ_UTC);
    db_connection.queryOrDie("SELECT DISTINCT marc_records.zeder_id,superior_info.title FROM marc_records "
                             "LEFT JOIN superior_info ON marc_records.zeder_id=superior_info.zeder_id");
    DbResultSet result_set(db_connection.getLastResultSet());
    unsigned journal_count(0), updated_journal_count(0);
    while (const DbRow row = result_set.getNextRow()) {
        if (ProcessJournal(&db_connection, old_timestamp, row["zeder_id"], row["title"], zeder_url_prefix, max_issue_count))
            ++updated_journal_count;
        ++journal_count;
    }

    WriteTimeStamp(::time(nullptr));

    LOG_INFO("Found " + std::to_string(updated_journal_count) + " out of " + std::to_string(journal_count) + " journals with new entries.");

    return EXIT_SUCCESS;
}