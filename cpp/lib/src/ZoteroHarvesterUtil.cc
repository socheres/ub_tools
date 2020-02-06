/** \brief Utility classes related to the Zotero Harvester
 *  \author Madeeswaran Kannan
 *
 *  \copyright 2019 Universitätsbibliothek Tübingen.  All rights reserved.
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

#include "ZoteroHarvesterUtil.h"
#include <unistd.h>
#include "GzStream.h"
#include "MiscUtil.h"
#include "StringUtil.h"
#include "TextUtil.h"
#include "TimeUtil.h"
#include "util.h"
#include "ZoteroHarvesterConversion.h"


namespace ZoteroHarvester {


namespace Util {


bool HarvestableItem::operator==(const HarvestableItem &rhs) const {
    return id_ == rhs.id_ and &journal_ == &rhs.journal_ and url_.toString() == rhs.url_.toString();
}


std::string HarvestableItem::toString() const {
    std::string as_string(std::to_string(id_));
    std::string journal_name(TextUtil::CollapseAndTrimWhitespace(journal_.name_));
    TextUtil::UnicodeTruncate(&journal_name, 20);

    as_string += " [" + journal_name + "...] | " + url_.toString();
    return as_string;
}


HarvestableItemManager::HarvestableItemManager(const std::vector<std::unique_ptr<Config::JournalParams>> &journal_params) {
    for (const auto &journal_param : journal_params)
        counters_.emplace(journal_param.get(), 0);
}


HarvestableItem HarvestableItemManager::newHarvestableItem(const std::string &url, const Config::JournalParams &journal_params) {
    auto journal_param_and_counter(counters_.find(&journal_params));
    if (journal_param_and_counter == counters_.end())
        LOG_ERROR("couldn't fetch harvestable item ID for unknown journal '" + journal_params.name_ + "'");

    return HarvestableItem(++journal_param_and_counter->second, url, journal_params);
}


ZoteroLogger::ContextData::ContextData(const Util::HarvestableItem &item)
    : item_(item)
{
    buffer_.reserve(static_cast<size_t>(BUFFER_SIZE));
    buffer_ = "\n\n";
}


void ZoteroLogger::queueContextMessage(const std::string &level, std::string msg, const TaskletContext &tasklet_context) {
    std::lock_guard<std::recursive_mutex> locker(active_context_mutex_);

    auto harvestable_item_and_context(active_contexts_.find(tasklet_context.associated_item_));
    if (harvestable_item_and_context == active_contexts_.end())
        error("message from unknown tasklet!");

    formatMessage(level, &msg);
    harvestable_item_and_context->second.buffer_ += msg;
}


void ZoteroLogger::queueGlobalMessage(const std::string &level, std::string msg) {
    std::lock_guard<std::recursive_mutex> locker(log_buffer_mutex_);

    formatMessage(level, &msg);
    log_buffer_.emplace_back(std::move(msg));
}


void ZoteroLogger::flushBufferAndPrintProgressImpl(const unsigned num_active_tasks, const unsigned num_queued_tasks) {
    std::lock_guard<std::recursive_mutex> locker(log_buffer_mutex_);

    if (::isatty(fd_) == 1) {
        // reset the progress bar
        if (not progress_bar_buffer_.empty()) {
            const std::string empty_string(progress_bar_buffer_.size(), ' ');
            writeToBackingLog("\r" + empty_string + "\r");
        }
    }

    // flush buffer
    while (not log_buffer_.empty()) {
        writeToBackingLog(log_buffer_.front());
        log_buffer_.pop_front();
    }

    if (::isatty(fd_) == 1) {
        // update progress bar
        progress_bar_buffer_ = "TASKS: ACTIVE = " + std::to_string(num_active_tasks) + ", QUEUED = "
                               + std::to_string(num_queued_tasks) + "\r";
        writeToBackingLog(progress_bar_buffer_);
    }
}


void ZoteroLogger::writeToBackingLog(const std::string &msg) {
    std::lock_guard<std::mutex> locker(mutex_);
    ::write(fd_, msg.data(), msg.length());
    ::fsync(fd_);
}


void ZoteroLogger::error(const std::string &msg) {
    // This is unrecoverable, so flush the global buffer and print out a preamble
    // with Zotero related info before displaying the actual error message and terminating the process
    const auto context(TASKLET_CONTEXT_MANAGER.getThreadLocalContext());
    writeToBackingLog("FATAL ERROR: Dumping active contexts...");

    // Flush the global buffer
    {
        std::lock_guard<std::recursive_mutex> global_buffer_locker(log_buffer_mutex_);
        while (not log_buffer_.empty()) {
            writeToBackingLog(log_buffer_.front());
            log_buffer_.pop_front();
        }
    }

    std::string faulty_tasklet_buffer;
    // Flush all active contexts (except the faulting one)
    {
        std::lock_guard<std::recursive_mutex> context_locker(active_context_mutex_);
        for (auto &item_and_context : active_contexts_) {
            if (context != nullptr and context->associated_item_.operator==(item_and_context.first))
                faulty_tasklet_buffer.swap(item_and_context.second.buffer_);
            else {
                item_and_context.second.buffer_ += "\n\n";
                writeToBackingLog(item_and_context.second.buffer_);
            }
        }
    }

    if (context == nullptr)
        ::Logger::error(msg);       // pass-through

    // Flush the tasklet's buffer
    writeToBackingLog("Faulty Zotero tasklet:");
    writeToBackingLog("\tparent tasklet: " + context->description_ + " (handle: " + std::to_string(::pthread_self()) + ")\n");
    writeToBackingLog("\titem: " + context->associated_item_.toString() + "\n\n");
    writeToBackingLog(faulty_tasklet_buffer);

    // Write the final error message and terminate the process
    ::Logger::error(msg);
}


void ZoteroLogger::warning(const std::string &msg) {
    if (min_log_level_ < LL_WARNING)
        return;

    const auto context(TASKLET_CONTEXT_MANAGER.getThreadLocalContext());
    if (context == nullptr)
        queueGlobalMessage("WARN", msg);
    else
        queueContextMessage("WARN", msg, *context);
}


void ZoteroLogger::info(const std::string &msg) {
    if (min_log_level_ < LL_INFO)
        return;

    const auto context(TASKLET_CONTEXT_MANAGER.getThreadLocalContext());
    if (context == nullptr)
        queueGlobalMessage("INFO", msg);
    else
        queueContextMessage("INFO", msg, *context);
}


void ZoteroLogger::debug(const std::string &msg) {
    if ((min_log_level_ < LL_DEBUG) and (MiscUtil::SafeGetEnv("UTIL_LOG_DEBUG") != "true"))
        return;

    const auto context(TASKLET_CONTEXT_MANAGER.getThreadLocalContext());
    if (context == nullptr)
        queueGlobalMessage("DEBUG", msg);
    else
        queueContextMessage("DEBUG", msg, *context);
}


void ZoteroLogger::pushContext(const Util::HarvestableItem &context_item) {
    std::lock_guard<std::recursive_mutex> locker(active_context_mutex_);

    auto harvestable_item_and_context(active_contexts_.find(context_item));
    if (harvestable_item_and_context != active_contexts_.end())
        error("Harvestable item " + context_item.toString() + " already registered");

    active_contexts_.emplace(context_item, context_item);
}


void ZoteroLogger::popContext(const Util::HarvestableItem &context_item) {
    std::lock_guard<std::recursive_mutex> locker(active_context_mutex_);

    auto harvestable_item_and_context(active_contexts_.find(context_item));
    if (harvestable_item_and_context == active_contexts_.end())
        error("Harvestable " + context_item.toString() + " not registered");

    harvestable_item_and_context->second.buffer_ += "\n\n";
    {
        std::lock_guard<std::recursive_mutex> global_buffer_locker(log_buffer_mutex_);
        log_buffer_.emplace_back(std::move(harvestable_item_and_context->second.buffer_));
    }
    active_contexts_.erase(harvestable_item_and_context);
}


static bool zotero_logger_initialized(false);


void ZoteroLogger::Init() {
    delete logger;
    logger = new ZoteroLogger();
    zotero_logger_initialized = true;

    LOG_INFO("Zotero Logger initialized!\n\n\n");
}


void ZoteroLogger::FlushBufferAndPrintProgress(const unsigned num_active_tasks, const unsigned num_queued_tasks) {
    assert(zotero_logger_initialized == true);
    reinterpret_cast<ZoteroLogger *>(logger)->flushBufferAndPrintProgressImpl(num_active_tasks, num_queued_tasks);
}


TaskletContextManager::TaskletContextManager() {
    if (::pthread_key_create(&tls_key_, nullptr) != 0)
        LOG_ERROR("could not create tasklet context thread local key");
}


TaskletContextManager::~TaskletContextManager() {
    if (::pthread_key_delete(tls_key_) != 0)
        LOG_ERROR("could not delete tasklet context thread local key");
}


void TaskletContextManager::setThreadLocalContext(const TaskletContext &context) const {
    const auto tasklet_data(::pthread_getspecific(tls_key_));
    if (tasklet_data != nullptr)
        LOG_ERROR("tasklet local data already set for thread " + std::to_string(::pthread_self()));

    if (::pthread_setspecific(tls_key_, const_cast<TaskletContext *>(&context)) != 0)
        LOG_ERROR("could not set tasklet local data for thread " + std::to_string(::pthread_self()));
}


TaskletContext *TaskletContextManager::getThreadLocalContext() const {
    return reinterpret_cast<TaskletContext *>(::pthread_getspecific(tls_key_));
}


const TaskletContextManager TASKLET_CONTEXT_MANAGER;


ThreadUtil::ThreadSafeCounter<unsigned> tasklet_instance_counter;
ThreadUtil::ThreadSafeCounter<unsigned> future_instance_counter;


class WaitOnSemaphore {
    ThreadUtil::Semaphore * const semaphore_;
public:
    explicit WaitOnSemaphore(ThreadUtil::Semaphore * const semaphore)
        : semaphore_(semaphore) { semaphore_->wait(); }
    ~WaitOnSemaphore() { semaphore_->post(); }
};


std::string UploadTracker::Entry::toString() const {
    std::string out("delivered_marc_records entry:\n");
    out += "\turl: " + url_ + "\n";
    out += "\tdelivered_at: " + delivered_at_str_ + "\n";
    out += "\tjournal: "  + journal_name_ + "\n";
    out += "\thash: " + hash_ + "\n";
    return out;
}


static void UpdateUploadTrackerEntryFromDbRow(const DbRow &row, UploadTracker::Entry * const entry) {
    if (row.empty())
        LOG_ERROR("Couldn't extract DeliveryTracker entry from empty DbRow");

    entry->url_ = row["url"];
    entry->delivered_at_str_ = row["delivered_at"];
    entry->delivered_at_ = SqlUtil::DatetimeToTimeT(entry->delivered_at_str_);
    entry->journal_name_ = row["journal_name"];
    entry->hash_ = row["hash"];
}


bool UploadTracker::urlAlreadyDelivered(const std::string &url, Entry * const entry,
                                        DbConnection * const db_connection) const
{
    db_connection->queryOrDie("SELECT t2.url, t1.delivered_at, t1.journal_name, t1.hash FROM delivered_marc_records_urls as t2 "
                              "LEFT JOIN delivered_marc_records as t1 ON t2.record_id = t1.id WHERE t2.url='"
                              + db_connection->escapeString(SqlUtil::TruncateToVarCharMaxIndexLength(url)) + "'");
    auto result_set(db_connection->getLastResultSet());
    if (result_set.empty())
        return false;

    const auto first_row(result_set.getNextRow());
    if (entry != nullptr)
        UpdateUploadTrackerEntryFromDbRow(first_row, entry);
    return true;
}


bool UploadTracker::hashAlreadyDelivered(const std::string &hash, std::vector<Entry> * const entries,
                                         DbConnection * const db_connection) const
{
    db_connection->queryOrDie("SELECT t2.url, t1.delivered_at, t1.journal_name, t1.hash FROM delivered_marc_records_urls as t2 "
                              "LEFT JOIN delivered_marc_records as t1 ON t2.record_id = t1.id WHERE t1.hash='"
                              + db_connection->escapeString(hash) + "'");
    auto result_set(db_connection->getLastResultSet());
    if (result_set.empty())
        return false;

    if (entries == nullptr)
        return true;

    Entry buffer;
    while (const DbRow row = result_set.getNextRow()) {
        UpdateUploadTrackerEntryFromDbRow(row, &buffer);
        entries->emplace_back(buffer);
    }

    return true;
}


bool UploadTracker::recordAlreadyDelivered(const std::string &record_hash, const std::vector<std::string> &record_urls,
                                           DbConnection * const db_connection) const
{
    std::vector<Entry> hash_bucket;
    Entry buffer;
    bool already_delivered(false);
    for (const auto &url : record_urls) {
        if (urlAlreadyDelivered(url, &buffer, db_connection)) {
            if (buffer.hash_ != record_hash) {
                LOG_WARNING("record with URL '" + url + "' already delivered but with a different hash!");
                LOG_DEBUG("\tcurrent hash: " + record_hash);
                LOG_DEBUG("\t" + buffer.toString());
            } else
                LOG_WARNING("record with URL '" + url + "' already delivered with the same hash (" + record_hash + ")");

            already_delivered = true;
            break;
        }
    }

    if (not already_delivered) {
        if (hashAlreadyDelivered(record_hash, &hash_bucket, db_connection)) {
            if (hash_bucket.size() > 1) {
                LOG_WARNING("multiple records were delivered with the same hash (" + record_hash + ")!");
                for (const auto &entry : hash_bucket)
                    LOG_DEBUG(entry.toString());
            } else
                LOG_WARNING("record with URL '" + hash_bucket[0].url_ + "' already delivered with the same hash (" + record_hash + ")");

            already_delivered = true;
        }
    }

    return already_delivered;
}


bool UploadTracker::urlAlreadyDelivered(const std::string &url, Entry * const entry) const {
    WaitOnSemaphore lock(&connection_pool_semaphore_);
    DbConnection db_connection;

    return urlAlreadyDelivered(url, entry, &db_connection);
}


bool UploadTracker::hashAlreadyDelivered(const std::string &hash, std::vector<Entry> * const entries) const {
    WaitOnSemaphore lock(&connection_pool_semaphore_);
    DbConnection db_connection;

    return hashAlreadyDelivered(hash, entries, &db_connection);
}


bool UploadTracker::recordAlreadyDelivered(const MARC::Record &record) const {
    WaitOnSemaphore lock(&connection_pool_semaphore_);
    DbConnection db_connection;

    const auto hash(Conversion::CalculateMarcRecordHash(record));
    const auto urls(GetMarcRecordUrls(record));

    return recordAlreadyDelivered(hash, urls, &db_connection);
}


time_t UploadTracker::getLastUploadTime(const std::string &journal_name) const {
    WaitOnSemaphore lock(&connection_pool_semaphore_);
    DbConnection db_connection;

    db_connection.queryOrDie("SELECT delivered_at FROM delivered_marc_records WHERE journal_name='" +
                             db_connection.escapeString(journal_name) + "' ORDER BY delivered_at DESC");
    auto result_set(db_connection.getLastResultSet());
    if (result_set.empty())
        return TimeUtil::BAD_TIME_T;

    return SqlUtil::DatetimeToTimeT(result_set.getNextRow()["delivered_at"]);
}


bool UploadTracker::archiveRecord(const MARC::Record &record) {
    WaitOnSemaphore lock(&connection_pool_semaphore_);
    DbConnection db_connection;

    const auto hash(Conversion::CalculateMarcRecordHash(record));
    const auto urls(GetMarcRecordUrls(record));

    if (recordAlreadyDelivered(hash, urls, &db_connection))
        return false;

    std::string publication_year, volume, issue, pages;
    const auto _936_field(record.getFirstField("936"));
    if (_936_field != record.end()) {
        const MARC::Subfields subfields(_936_field->getSubfields());
        if (subfields.hasSubfield('j'))
            publication_year = ",publication_year=" + db_connection.escapeAndQuoteString(subfields.getFirstSubfieldWithCode('j'));
        if (subfields.hasSubfield('d'))
            volume = ",volume=" + db_connection.escapeAndQuoteString(subfields.getFirstSubfieldWithCode('d'));
        if (subfields.hasSubfield('e'))
            issue = ",issue=" + db_connection.escapeAndQuoteString(subfields.getFirstSubfieldWithCode('e'));
        if (subfields.hasSubfield('h'))
            pages = ",pages=" + db_connection.escapeAndQuoteString(subfields.getFirstSubfieldWithCode('h'));
    }

    std::string resource_type(record.getFirstFieldContents("007") == "tu" ? "print" : "online");
    const auto zeder_id(record.getFirstSubfieldValue("ZID", 'a'));
    const auto journal_name(record.getFirstSubfieldValue("JOU", 'a'));
    const auto main_title(record.getMainTitle());
    db_connection.queryOrDie("INSERT INTO delivered_marc_records SET zeder_id=" + db_connection.escapeAndQuoteString(zeder_id)
                             + ",journal_name=" + db_connection.escapeAndQuoteString(SqlUtil::TruncateToVarCharMaxIndexLength(journal_name))
                             + ",hash=" + db_connection.escapeAndQuoteString(hash)
                             + ",main_title=" + db_connection.escapeAndQuoteString(SqlUtil::TruncateToVarCharMaxIndexLength(main_title))
                             + publication_year + volume + issue + pages
                             + ",resource_type=" + db_connection.escapeAndQuoteString(SqlUtil::TruncateToVarCharMaxIndexLength(resource_type))
                             + ",record="
                             + db_connection.escapeAndQuoteString(GzStream::CompressString(record.toBinaryString(), GzStream::GZIP)));

    // Fetch the last inserted row's ID to add the URLs
    db_connection.queryOrDie("SELECT LAST_INSERT_ID() id");
    auto result_set(db_connection.getLastResultSet());
    if (result_set.empty())
        LOG_ERROR("couldn't query last insert id from delivered_marc_records!");
    const auto last_insert_id(result_set.getNextRow()["id"]);

    for (const auto &url : urls) {
        db_connection.queryOrDie("INSERT INTO delivered_marc_records_urls SET record_id=" + last_insert_id
                                 + ", url=" + db_connection.escapeAndQuoteString(SqlUtil::TruncateToVarCharMaxIndexLength(url)));
    }

    db_connection.queryOrDie("SELECT * FROM delivered_marc_records_superior_info WHERE zeder_id="
                             + db_connection.escapeAndQuoteString(zeder_id));

    if (db_connection.getLastResultSet().empty()) {
        const std::string superior_title(record.getSuperiorTitle());
        const auto superior_control_number(record.getSuperiorControlNumber());
        const std::string superior_control_number_sql(superior_control_number.empty() ? "" : ",control_number="
                                                      + db_connection.escapeAndQuoteString(superior_control_number));

        db_connection.queryOrDie("INSERT INTO delivered_marc_records_superior_info SET zeder_id="
                                 + db_connection.escapeAndQuoteString(zeder_id) + ",title="
                                 + db_connection.escapeAndQuoteString(SqlUtil::TruncateToVarCharMaxIndexLength(superior_title))
                                 + superior_control_number_sql);
    }

    return true;
}


std::recursive_mutex non_threadsafe_locale_modification_guard;


std::vector<std::string> GetMarcRecordUrls(const MARC::Record &record) {
    std::vector<std::string> urls;

    for (const auto &field : record.getTagRange("856")) {
        const auto url(field.getFirstSubfieldWithCode('u'));
        if (not url.empty())
            urls.emplace_back(url);
    }

    const auto harvest_url_field(record.findTag("URL"));
    if (harvest_url_field != record.end())
        urls.emplace_back(harvest_url_field->getFirstSubfieldWithCode('a'));

    return urls;
}


} // end namespace Util


} // end namespace ZoteroHarvester