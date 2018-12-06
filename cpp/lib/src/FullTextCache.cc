/** \file   FullTextCache.cc
 *  \brief  Implementation of functions relating to our full-text cache.
 *  \author Dr. Johannes Ruscheinski (johannes.ruscheinski@uni-tuebingen.de)
 *
 *  \copyright 2017,2018 Universitätsbibliothek Tübingen.  All rights reserved.
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
#include "FullTextCache.h"
#include <algorithm>
#include <ctime>
#include "Compiler.h"
#include "DbRow.h"
#include "Random.h"
#include "SqlUtil.h"
#include "StringUtil.h"
#include "TimeUtil.h"
#include "UrlUtil.h"
#include "util.h"
#include "VuFind.h"


constexpr unsigned MIN_CACHE_EXPIRE_TIME_ON_ERROR(42300 * 60); // About 1 month in seconds.
constexpr unsigned MAX_CACHE_EXPIRE_TIME_ON_ERROR(42300 * 60 * 2); // About 2 months in seconds.


FullTextCache::FullTextCache(const bool use_elasticsearch) {
    std::string mysql_url;
    VuFind::GetMysqlURL(&mysql_url);
    db_connection_.reset(new DbConnection(mysql_url));
    if (use_elasticsearch)
        elasticsearch_.reset(new Elasticsearch);
}


bool FullTextCache::getDomainFromUrl(const std::string &url, std::string * const domain) {
    std::string scheme, username_password, authority, port, path, params, query, fragment, relative_url;

    bool result = UrlUtil::ParseUrl(url, &scheme, &username_password, &authority, &port, &path, &params, &query, &fragment, &relative_url);

    if (result)
        *domain = authority;

    return result;
}


std::vector<std::string> FullTextCache::getDomains() {
    db_connection_->queryOrDie("SELECT url FROM full_text_cache_urls");

    DbResultSet result_set(db_connection_->getLastResultSet());
    std::vector<std::string> domains;
    while (const DbRow row = result_set.getNextRow()) {
        std::string domain;
        FullTextCache::getDomainFromUrl(row["url"], &domain);
        domains.emplace_back(domain);
    }
    return domains;
}


bool FullTextCache::entryExpired(const std::string &id, std::vector<std::string> urls) {
    Entry entry;
    if (not getEntry(id, &entry))
        return true;

    const time_t now(std::time(nullptr));
    if (entry.expiration_ == TimeUtil::BAD_TIME_T or now < entry.expiration_) {
        std::vector<std::string> existing_urls(FullTextCache::getEntryUrlsAsStrings(id));
        std::sort(existing_urls.begin(), existing_urls.end());
        std::sort(urls.begin(), urls.end());
        if (urls == existing_urls)
            return false;
    }

    db_connection_->queryOrDie("DELETE FROM full_text_cache WHERE id=\"" + db_connection_->escapeString(id) + "\"");
    return true;
}


void FullTextCache::expireEntries() {
    db_connection_->queryOrDie("DELETE FROM full_text_cache WHERE expiration IS NOT NULL AND expiration < NOW()");
}


bool FullTextCache::getEntry(const std::string &id, Entry * const entry) {
    db_connection_->queryOrDie("SELECT expiration FROM full_text_cache WHERE id=\""
                              + db_connection_->escapeString(id) + "\"");
    DbResultSet result_set(db_connection_->getLastResultSet());
    if (result_set.empty())
        return false;

    const DbRow row(result_set.getNextRow());
    entry->id_ = id;
    if (row["expiration"].empty())
        entry->expiration_ = TimeUtil::BAD_TIME_T;
    else
        entry->expiration_ = SqlUtil::DatetimeToTimeT(row["expiration"]);
    return true;
}


std::vector<FullTextCache::EntryUrl> FullTextCache::getEntryUrls(const std::string &id) {
    db_connection_->queryOrDie("SELECT url, domain, error_message FROM full_text_cache_urls "
                               "WHERE id=\"" + db_connection_->escapeString(id) + "\"");

    DbResultSet result_set(db_connection_->getLastResultSet());
    std::vector<EntryUrl> entry_urls;
    while (const DbRow row = result_set.getNextRow()) {
        EntryUrl entry_url;
        entry_url.id_ = id;
        entry_url.url_ = row["url"];
        entry_url.domain_ = row["domain"];
        entry_url.error_message_ = row["error_message"];
        entry_urls.emplace_back(entry_url);
    }
    return entry_urls;
}


std::vector<std::string> FullTextCache::getEntryUrlsAsStrings(const std::string &id) {
    db_connection_->queryOrDie("SELECT url FROM full_text_cache_urls "
                               "WHERE id=\"" + db_connection_->escapeString(id) + "\"");

    DbResultSet result_set(db_connection_->getLastResultSet());
    std::vector<std::string> urls;
    while (const DbRow row = result_set.getNextRow()) {
        urls.emplace_back(row["url"]);
    }
    return urls;
}


unsigned FullTextCache::getErrorCount() {
    db_connection_->queryOrDie("SELECT count(*) AS count FROM ("
                                    "SELECT cache.id FROM full_text_cache_urls AS urls "
                                    "LEFT JOIN full_text_cache AS cache "
                                    "ON cache.id = urls.id "
                                    "WHERE error_message IS NOT NULL "
                                    "GROUP BY cache.id "
                               ") AS subselect");

    DbResultSet result_set(db_connection_->getLastResultSet());
    const DbRow row(result_set.getNextRow());
    return StringUtil::ToUnsigned(row["count"]);
}


bool FullTextCache::getFullText(const std::string &id, std::string * const full_text) {
    db_connection_->queryOrDie("SELECT full_text FROM full_text_cache "
                               "WHERE id=\"" + db_connection_->escapeString(id) + "\"");

    DbResultSet result_set(db_connection_->getLastResultSet());
    if (result_set.empty())
        return false;

    const DbRow row(result_set.getNextRow());
    *full_text = row["full_text"];
    return true;
}


std::vector<FullTextCache::EntryGroup> FullTextCache::getEntryGroupsByDomainAndErrorMessage() {
    std::vector<EntryGroup> groups;

    // In a group statement you can only select fields that are part of the group.
    // Get first part.
    db_connection_->queryOrDie("SELECT domain, error_message, count(*) AS count FROM full_text_cache_urls AS urls "
                               "LEFT JOIN full_text_cache AS cache ON cache.id = urls.id WHERE urls.error_message IS NOT NULL "
                               "GROUP BY urls.error_message, urls.domain ORDER BY count DESC ");
    { // Indented block because DbResultSet needs to get out of scope for connection to be free again.
        DbResultSet result_set(db_connection_->getLastResultSet());
        while (const DbRow row = result_set.getNextRow()) {
            EntryGroup group;

            group.count_ = StringUtil::ToUnsigned(row["count"]);
            group.domain_ = row["domain"];
            group.error_message_ = row["error_message"];

            groups.emplace_back(group);
        }
    }

    // get example entry
    for (auto &group : groups)
        group.example_entry_ = getJoinedEntryByDomainAndErrorMessage(group.domain_, group.error_message_);

    return groups;
}


std::vector<FullTextCache::JoinedEntry> FullTextCache::getJoinedEntriesByDomainAndErrorMessage(const std::string &domain,
                                                                                               const std::string &error_message)
{
    std::vector<JoinedEntry> entries;
    db_connection_->queryOrDie("SELECT cache.id, url FROM full_text_cache_urls AS urls LEFT JOIN full_text_cache AS cache "
                               "ON cache.id = urls.id WHERE urls.error_message='" + db_connection_->escapeString(error_message) + "' "
                               "AND urls.domain='" + db_connection_->escapeString(domain) + "' ");

    DbResultSet result_set(db_connection_->getLastResultSet());
    while (const DbRow row = result_set.getNextRow()) {
        JoinedEntry entry;

        entry.id_ = row["id"];
        entry.url_ = row["url"];
        entry.domain_ = domain;
        entry.error_message_ = error_message;

        entries.emplace_back(entry);
    }

    return entries;
}


FullTextCache::JoinedEntry FullTextCache::getJoinedEntryByDomainAndErrorMessage(const std::string &domain, const std::string &error_message)
{
    db_connection_->queryOrDie("SELECT cache.id, url FROM full_text_cache_urls AS urls LEFT JOIN full_text_cache AS cache "
                               "ON cache.id = urls.id WHERE urls.error_message='" + db_connection_->escapeString(error_message) + "' "
                               "AND urls.domain='" + db_connection_->escapeString(domain) + "' LIMIT 1 ");

    DbResultSet result_set(db_connection_->getLastResultSet());
    if (unlikely(result_set.empty()))
        LOG_ERROR("we need at least a single result! (domain: " + domain + ")");
    const DbRow row(result_set.getNextRow());

    JoinedEntry entry;
    entry.id_ = row["id"];
    entry.url_ = row["url"];
    entry.domain_ = domain;
    entry.error_message_ = error_message;

    return entry;
}


unsigned FullTextCache::getSize() {
    return SqlUtil::GetTableSize(db_connection_.get(), "full_text_cache");
}


void FullTextCache::insertEntry(const std::string &id, const std::string &full_text, const std::vector<EntryUrl> &entry_urls) {
    const time_t now(std::time(nullptr));
    Random::Rand rand(now);
    time_t expiration(TimeUtil::BAD_TIME_T);
    for (const auto &entry_url : entry_urls) {
        if (full_text.empty() and entry_url.error_message_.empty())
            LOG_ERROR("you must provide either data to be cached or a non-empty error message! (id " + id + ")");

        if (not entry_url.error_message_.empty())
            expiration = now + MIN_CACHE_EXPIRE_TIME_ON_ERROR + rand(MAX_CACHE_EXPIRE_TIME_ON_ERROR - MIN_CACHE_EXPIRE_TIME_ON_ERROR);
    }

    if (elasticsearch_ != nullptr) {
        LOG_DEBUG("updating Elasticsearch fulltext for " + id);
        elasticsearch_->insertDocument(id, full_text);
    } else {
        std::string expiration_string;
        if (expiration == TimeUtil::BAD_TIME_T)
            expiration_string = "NULL";
        else
            expiration_string = "\"" + SqlUtil::TimeTToDatetime(expiration) + "\"";

        const std::string escaped_id(db_connection_->escapeString(id));
        db_connection_->queryOrDie("INSERT INTO full_text_cache SET id=\"" + escaped_id + "\",expiration=" + expiration_string + ","
                                   "full_text=\"" + db_connection_->escapeString(full_text) + "\"");

        for (const auto &entry_url : entry_urls) {
            db_connection_->queryOrDie("INSERT INTO full_text_cache_urls SET id=\"" + escaped_id + "\",url=\""
                                       + db_connection_->escapeString(entry_url.url_) + "\",domain=\""
                                       + db_connection_->escapeString(entry_url.domain_) + "\""
                                       + (entry_url.error_message_.empty()
                                              ? ""
                                              : ", error_message=\"" + db_connection_->escapeString(entry_url.error_message_) + "\""));
        }
    }
}
