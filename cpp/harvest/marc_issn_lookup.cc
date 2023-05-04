/**
 * \brief Utility for updating issn information
 * \author Steven Lolong (steven.lolong@uni-tuebingen.de)
 *
 * \copyright 2023 Tübingen University Library.  All rights reserved.
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
#include <map>
#include "CORE.h"
#include "FileUtil.h"
#include "MARC.h"
#include "StringUtil.h"
#include "util.h"

namespace {


[[noreturn]] void Usage() {
    ::Usage(
        "marc_input_articles marc_input_journals marc_output_articles [--verbose]"
        "\n"
        "- marc_input_articles is a file containing all article information taken from CORE.\n"
        "- marc_input_journals is a file containing journal information. Please use issn_lookup.py to generate this file.\n"
        "- marc_output_articles is an output file generated by this tool.\n"
        "- --verbose, print to standart output the information of issn");

    std::exit(EXIT_FAILURE);
}

// avoiding duplication in issns's cache
void InsertIssnIfNotExist(const std::string &issn, std::vector<std::string> * const issns) {
    if (std::find(issns->begin(), issns->end(), StringUtil::ASCIIToUpper(issn)) == issns->end())
        issns->emplace_back(StringUtil::ASCIIToUpper(issn));
}


void InsertIfNotExist(const std::vector<std::string> &issns_input, std::vector<std::string> * const issns) {
    for (const auto &issn : issns_input)
        InsertIssnIfNotExist(issn, issns);
}


struct CacheEntry {
    std::string title_;
    std::string preferred_issn_;
    std::string ppn_;
    std::map<std::string, std::vector<std::string>> issns_of_ppn_;
    std::vector<std::string> issns_;
    bool is_online_;
    bool is_valid_;

    CacheEntry() {
        ppn_ = "";
        is_valid_ = false;
        is_online_ = false;
        title_ = "";
        preferred_issn_ = "";
    }

    CacheEntry(MARC::Record &record) {
        is_valid_ = false;
        is_online_ = false;
        for (auto &field : record) {
            if (field.getTag() == "001")
                ppn_ = field.getContents();

            if (field.getTag() == "022") {
                if (not field.getFirstSubfieldWithCode('a').empty()) {
                    preferred_issn_ = StringUtil::ASCIIToUpper(field.getFirstSubfieldWithCode('a'));
                    InsertIssnIfNotExist(preferred_issn_, &issns_);
                }

                if (not field.getFirstSubfieldWithCode('l').empty())
                    InsertIssnIfNotExist(StringUtil::ASCIIToUpper(field.getFirstSubfieldWithCode('l')), &issns_);
            }

            if (field.getTag() == "245") {
                MARC::Subfields subfields(field.getSubfields());
                std::string subfield_a(subfields.getFirstSubfieldWithCode('a'));
                std::string subfield_b(subfields.getFirstSubfieldWithCode('b'));
                if ((not subfield_a.empty()) && (not subfield_b.empty()))
                    title_ = subfield_a + " " + subfield_b;
                else if ((not subfield_a.empty()) && subfield_b.empty())
                    title_ = subfield_a;
                else if (subfield_a.empty() && (not subfield_b.empty()))
                    title_ = subfield_b;
                else
                    title_ = "";
            }

            if (field.getTag() == "300")
                is_online_ = (field.getFirstSubfieldWithCode('a') == "Online-Ressource");
        }
    }
};


void PrettyPrintCacheEntry(const CacheEntry &ce) {
    std::cout << "ppn: " << ce.ppn_ << std::endl;
    std::cout << "title (t): " << ce.title_ << std::endl;
    std::cout << "w: "
              << "(DE-627)" + ce.ppn_ << std::endl;
    std::cout << "issn (x): " << ce.preferred_issn_ << std::endl;
    std::cout << "online: " << (ce.is_online_ ? "yes" : "no") << std::endl;
    std::cout << "valid: " << (ce.is_valid_ ? "yes" : "no") << std::endl;
    std::cout << "related ppn(s) and its issn(s)" << std::endl;
    for (const auto &ppn : ce.issns_of_ppn_) {
        if (ppn.first != ce.ppn_) {
            std::cout << "+++ " << ppn.first << ": " << std::endl;
            for (const auto &issn : ppn.second) {
                if (not issn.empty())
                    std::cout << "** " << issn << std::endl;
            }
        }
    }
    std::cout << "related issn(s): " << std::endl;
    for (const auto &issn : ce.issns_)
        if (issn != ce.preferred_issn_)
            std::cout << "* " << issn << std::endl;
}


void PrettyPrintCache(const std::vector<CacheEntry> &journal_cache) {
    unsigned i(1);
    std::cout << "********* Cache *********" << std::endl;
    for (const auto &jc : journal_cache) {
        std::cout << "=== Record - " << i << std::endl;
        PrettyPrintCacheEntry(jc);
        std::cout << std::endl;
        ++i;
    }
    std::cout << "******** End of Cache ***********" << std::endl;
}


bool IsInISSNs(const std::vector<std::string> &issns, const std::string &issn) {
    return (std::find(issns.begin(), issns.end(), StringUtil::ASCIIToUpper(issn)) != issns.end() ? true : false);
}


bool IsInISSNs(const std::vector<std::string> &issns, const std::vector<std::string> &issns_input) {
    for (const auto &issn : issns_input)
        if (IsInISSNs(issns, issn))
            return true;

    return false;
}


void UpdateSubfield(MARC::Subfields &subfields, const CacheEntry &cache_entry) {
    if (!subfields.replaceFirstSubfield('i', "In:"))
        subfields.addSubfield('i', "In:");
    if (!subfields.replaceFirstSubfield('x', cache_entry.preferred_issn_))
        subfields.addSubfield('x', cache_entry.preferred_issn_);
    if (!subfields.replaceFirstSubfield('w', "(DE-627)" + cache_entry.ppn_))
        subfields.addSubfield('w', "(DE-627)" + cache_entry.ppn_);

    if (not cache_entry.title_.empty())
        if (!subfields.replaceFirstSubfield('t', cache_entry.title_))
            subfields.addSubfield('t', cache_entry.title_);
}


void UpdateCacheEntry(CacheEntry &ce, const CacheEntry &new_ce, const bool is_online) {
    ce.title_ = new_ce.title_;
    ce.ppn_ = new_ce.ppn_;
    ce.preferred_issn_ = new_ce.preferred_issn_;
    ce.is_online_ = is_online;
    InsertIfNotExist(new_ce.issns_, &ce.issns_);
}


void UpdateCacheAndCombineIssn(CacheEntry * const ce, const CacheEntry &new_ce) {
    bool subset(true);

    for (const auto &v1 : new_ce.issns_)
        subset = (subset || IsInISSNs(ce->issns_, v1));

    if (not subset) {
        if (ce->is_online_ && new_ce.is_online_) {
            ce->is_valid_ = false;
        }

        if (!ce->is_online_ && new_ce.is_online_) {
            ce->is_valid_ = true;
            ce->title_ = new_ce.title_;
            ce->ppn_ = new_ce.ppn_;
            ce->preferred_issn_ = new_ce.preferred_issn_;
        }

        if (!ce->is_online_ && !new_ce.is_online_)
            ce->is_valid_ = false;

        InsertIfNotExist(new_ce.issns_, &ce->issns_);
    }
}


std::vector<CacheEntry> MergeDuplicateCacheEntrys(std::vector<CacheEntry> &journal_cache) {
    std::vector<CacheEntry> new_journal_cache, temp_cache;
    std::vector<CacheEntry>::iterator iter;
    CacheEntry content;
    bool restart(false);

    // Iteration of multiple checking (multi-pass checking)
    for (unsigned i = 0; i < journal_cache.size(); i++) {
        content = journal_cache[i];

        do {
            restart = false;

            for (unsigned j = i + 1; j < journal_cache.size(); j++) {
                if (IsInISSNs(content.issns_, journal_cache[j].issns_)) {
                    UpdateCacheAndCombineIssn(&content, journal_cache[j]);
                    iter = journal_cache.begin() + j;
                    journal_cache.erase(iter);
                    restart = true;
                    break;
                }
            }

        } while (restart);
        temp_cache.emplace_back(content);
        restart = false;
    }

    // remove data without issn
    for (unsigned i = 0; i < temp_cache.size(); i++) {
        content = temp_cache[i];
        if (not content.preferred_issn_.empty())
            new_journal_cache.emplace_back(content);
    }

    return new_journal_cache;
}

void UpdateISSNsOfPPN(const CacheEntry inputitlesbi, CacheEntry * const targetitlesbi) {
    targetitlesbi->issns_of_ppn_.insert(std::pair<std::string, std::vector<std::string>>(inputitlesbi.ppn_, inputitlesbi.issns_));
}

std::vector<CacheEntry> BuildJournalCache(const std::string &inputitlejournal_filename) {
    std::vector<CacheEntry> journal_cache;
    auto inputitlejournal_file(MARC::Reader::Factory(inputitlejournal_filename));

    while (MARC::Record record = inputitlejournal_file->read()) {
        CacheEntry cache_entry_of_record(record);
        bool exist_in_journal_cache(false);

        for (auto &elemt : journal_cache) {
            if (IsInISSNs(cache_entry_of_record.issns_, elemt.issns_)) {
                exist_in_journal_cache = true;
                UpdateISSNsOfPPN(cache_entry_of_record, &elemt);

                if (elemt.is_online_) {
                    if (cache_entry_of_record.is_online_)
                        elemt.is_valid_ = false;

                    InsertIfNotExist(cache_entry_of_record.issns_, &elemt.issns_);
                } else {
                    if (cache_entry_of_record.is_online_) {
                        UpdateCacheEntry(elemt, cache_entry_of_record, true);
                        elemt.is_valid_ = true;
                    } else {
                        // print issn refer to other print issn
                        elemt.is_valid_ = false;
                        InsertIssnIfNotExist(cache_entry_of_record.preferred_issn_, &elemt.issns_);
                    }
                }
            }
        }

        if (not exist_in_journal_cache) {
            cache_entry_of_record.is_valid_ = true;
            journal_cache.emplace_back(cache_entry_of_record);
        }
    }

    return MergeDuplicateCacheEntrys(journal_cache);
}


void ISSNLookup(char **argv, std::vector<CacheEntry> &journal_cache) {
    auto inputitlefile(MARC::Reader::Factory(argv[1]));
    auto outputitlefile(MARC::Writer::Factory(argv[3]));
    std::vector<std::string> updated_ppn, ignored_ppn;

    while (MARC::Record record = inputitlefile->read()) {
        std::string ppn("");
        for (auto &field : record) {
            if (field.getTag() == "001")
                ppn = field.getContents();

            if (field.getTag() == "773") {
                const std::string issn(StringUtil::ASCIIToUpper(field.getFirstSubfieldWithCode('x')));
                if (not issn.empty()) {
                    // data is found
                    for (const auto &elemt : journal_cache) {
                        bool is_in_l = (std::find(elemt.issns_.begin(), elemt.issns_.end(), issn) != elemt.issns_.end() ? true : false);
                        if (((elemt.preferred_issn_ == issn) || is_in_l) && elemt.is_valid_) {
                            MARC::Subfields subfields(field.getSubfields());
                            UpdateSubfield(subfields, elemt);
                            field.setSubfields(subfields);
                        }
                    }
                }
            }
        }
        outputitlefile->write(record);
    }
}


} // end of namespace


int Main(int argc, char **argv) {
    if (argc < 4 || argc > 5)
        Usage();

    std::vector<CacheEntry> journal_cache(BuildJournalCache(argv[2]));
    ISSNLookup(argv, journal_cache);

    if (argc == 5 && (std::strcmp(argv[4], "--verbose") == 0))
        PrettyPrintCache(journal_cache);

    return EXIT_SUCCESS;
}
