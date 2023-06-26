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
#include "ControlNumberGuesser.h"
#include "FileUtil.h"
#include "IssnLookup.h"
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

struct DebugInfo {
    std::map<std::string, std::string> ppns_use_issn_org_, ppns_use_k10_, ppns_with_issn_not_recognized_,
        ppns_with_issn_in_k10_but_invalid_;
    std::set<std::string> issns_not_found_;
    DebugInfo() = default;
};

struct TitleInfo773 {
    std::string title_, subfield_w_;
    char ind1_, ind2_;

    TitleInfo773() = default;

    bool IsEqual(const TitleInfo773 &ti) const {
        if ((title_ == ti.title_) && (ind1_ == ti.ind1_) && (ind2_ == ti.ind2_) && (subfield_w_ == ti.subfield_w_))
            return true;

        return false;
    }

    bool CompareButIgnoreW(const TitleInfo773 &ti) const {
        if ((title_ == ti.title_) && (ind1_ == ti.ind1_) && (ind2_ == ti.ind2_))
            return true;

        return false;
    }

    void Update(const MARC::Record::Field &field) {
        title_ = ControlNumberGuesser::NormaliseTitle(field.getFirstSubfieldWithCode('t'));
        subfield_w_ = field.getFirstSubfieldWithCode('w');
        ind1_ = field.getIndicator1();
        ind2_ = field.getIndicator2();
    }
};

bool IsInTitleInfo773Cache(const std::vector<TitleInfo773> &title_info_cache, const TitleInfo773 &title_info, const bool &ignore_w) {
    for (const auto &ti : title_info_cache) {
        if (not ignore_w) {
            if (ti.IsEqual(title_info))
                return true;
        } else {
            if (ti.CompareButIgnoreW(title_info))
                return true;
        }
    }
    return false;
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
    std::string preferred_title_;
    std::string preferred_issn_;
    std::string preferred_ppn_;
    std::map<std::string, std::vector<std::string>> related_ppn_and_its_issns;
    std::vector<std::string> issns_;
    bool is_online_;
    bool is_valid_;

    CacheEntry() {
        preferred_ppn_ = "";
        is_valid_ = false;
        is_online_ = false;
        preferred_title_ = "";
        preferred_issn_ = "";
    }

    CacheEntry(MARC::Record &record) {
        is_valid_ = false;
        is_online_ = record.isElectronicResource();

        for (auto &field : record) {
            if (field.getTag() == "001")
                preferred_ppn_ = field.getContents();

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
                    preferred_title_ = subfield_a + " " + subfield_b;
                else if ((not subfield_a.empty()) && subfield_b.empty())
                    preferred_title_ = subfield_a;
                else if (subfield_a.empty() && (not subfield_b.empty()))
                    preferred_title_ = subfield_b;
                else
                    preferred_title_ = "";
            }
        }
    }
};


void PrettyPrintCacheEntry(const CacheEntry &ce) {
    std::cout << "ppn: " << ce.preferred_ppn_ << std::endl;
    std::cout << "title (t): " << ce.preferred_title_ << std::endl;
    std::cout << "issn (x): " << ce.preferred_issn_ << std::endl;
    std::cout << "online: " << (ce.is_online_ ? "yes" : "no") << std::endl;
    std::cout << "valid: " << (ce.is_valid_ ? "yes" : "no") << std::endl;
    std::cout << "related ppn(s) and its issn(s)" << std::endl;

    for (const auto &ppn : ce.related_ppn_and_its_issns) {
        if (ppn.first != ce.preferred_ppn_) {
            std::cout << "+++ " << ppn.first << ": " << std::endl;
            for (const auto &issn : ppn.second)
                if (not issn.empty())
                    std::cout << "** " << issn << std::endl;
        }
    }

    std::cout << "related issn(s): " << std::endl;
    for (const auto &issn : ce.issns_)
        if (issn != ce.preferred_issn_)
            std::cout << "* " << issn << std::endl;
}


void ShowInfoForDebugging(const std::vector<CacheEntry> &journal_cache, const std::vector<IssnLookup::ISSNInfo> &issn_org_cache,
                          const DebugInfo &debug_info) {
    unsigned i(1);
    std::cout << "********* Cache (ISSN found in K10plus) *********" << std::endl;
    for (const auto &jc : journal_cache) {
        std::cout << "=== Record - " << i << std::endl;
        PrettyPrintCacheEntry(jc);
        std::cout << std::endl;
        ++i;
    }
    std::cout << "******** End of Cache (ISSN found in K10plus) ***********\n\n";

    if (not issn_org_cache.empty()) {
        i = 1;
        std::cout << "******** Start of Cache (ISSN found in issn.org) ***********" << std::endl;
        for (auto it : issn_org_cache) {
            std::cout << "=== Cache of issn.org, record: " << i << std::endl;
            it.PrettyPrint();
            std::cout << std::endl;
            ++i;
        }
        std::cout << "******** End of Cache (ISSN found in issn.org) ***********\n\n";
    }

    if (not debug_info.ppns_use_k10_.empty()) {
        std::cout << "******** Start of PPN used issn data from K10Plus ***********" << std::endl;
        for (const auto &pu : debug_info.ppns_use_k10_)
            std::cout << "PPN: " << pu.first << ", ISSN: " << pu.second << std::endl;

        std::cout << "Total: " << debug_info.ppns_use_k10_.size() << std::endl;
        std::cout << "******** End of PPN used issn data from K10Plus ***********\n\n";
    }

    if (not debug_info.ppns_with_issn_in_k10_but_invalid_.empty()) {
        std::cout << "******** Start of PPN with ISSN found in k10plus but invalid and took information from issn.org ***********"
                  << std::endl;
        for (const auto &pnr : debug_info.ppns_with_issn_in_k10_but_invalid_)
            std::cout << "PPN: " << pnr.first << ", ISSN: " << pnr.second << std::endl;

        std::cout << "Total: " << debug_info.ppns_with_issn_in_k10_but_invalid_.size() << std::endl;
        std::cout << "******** End of PPN with ISSN found in k10plus but invalid and took information from issn.org ***********\n\n";
    }

    if (not debug_info.ppns_use_issn_org_.empty()) {
        std::cout << "******** Start of PPN used issn data from issn.org ***********" << std::endl;
        for (const auto &pu : debug_info.ppns_use_issn_org_)
            std::cout << "PPN: " << pu.first << ", ISSN: " << pu.second << std::endl;

        std::cout << "Total: " << debug_info.ppns_use_issn_org_.size() << std::endl;
        std::cout << "******** End of PPN used issn data from issn.org ***********\n\n";
    }

    if (not debug_info.ppns_with_issn_not_recognized_.empty()) {
        std::cout << "******** Start of PPN with ISSN has not found or invalid in k10plus, and not found in issn.org or timeout while "
                     "downloading ***********"
                  << std::endl;
        for (const auto &pnr : debug_info.ppns_with_issn_not_recognized_)
            std::cout << "PPN: " << pnr.first << ", ISSN: " << pnr.second << std::endl;

        std::cout << "Total: " << debug_info.ppns_with_issn_not_recognized_.size() << std::endl;
        std::cout << "******** End of PPN with ISSN has not found or invalid in k10plus, and not found in issn.org or timeout while "
                     "downloading  ***********\n\n";
    }

    if (not debug_info.issns_not_found_.empty()) {
        std::cout << "******** Start of ISSN has not found or invalid in k10plus, and not found in issn.org or timeout while downloading "
                     "***********"
                  << std::endl;
        for (const auto &isf : debug_info.issns_not_found_)
            std::cout << "ISSN: " << isf << std::endl;

        std::cout << "Total: " << debug_info.issns_not_found_.size() << std::endl;
        std::cout << "******** End of ISSN has not found or invalid in k10plus, and not found in issn.org or timeout while downloading "
                     "***********\n\n";
    }
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

bool IsInISSNInfoCache(const std::string issn, const std::vector<IssnLookup::ISSNInfo> &issn_org_cache,
                       IssnLookup::ISSNInfo * const issn_info) {
    for (const auto &issn_org : issn_org_cache) {
        if (issn == issn_org.issn_) {
            *issn_info = issn_org;
            return true;
        }
    }
    return false;
}

void UpdateSubfieldUsingK10(MARC::Subfields &subfields, const CacheEntry &cache_entry) {
    if (!subfields.replaceFirstSubfield('i', "In:"))
        subfields.addSubfield('i', "In:");
    if (!subfields.replaceFirstSubfield('x', cache_entry.preferred_issn_))
        subfields.addSubfield('x', cache_entry.preferred_issn_);
    if (!subfields.replaceFirstSubfield('w', "(DE-627)" + cache_entry.preferred_ppn_))
        subfields.addSubfield('w', "(DE-627)" + cache_entry.preferred_ppn_);

    if (not cache_entry.preferred_title_.empty())
        if (!subfields.replaceFirstSubfield('t', cache_entry.preferred_title_))
            subfields.addSubfield('t', cache_entry.preferred_title_);
}

void UpdateSubfieldUsingISSNOrg(MARC::Subfields &subfields, const IssnLookup::ISSNInfo issn_info) {
    if (not issn_info.main_titles_.empty()) {
        if (!subfields.replaceFirstSubfield('t', issn_info.main_titles_.front()))
            subfields.addSubfield('t', issn_info.main_titles_.front());

        if (!subfields.replaceFirstSubfield('i', "In:"))
            subfields.addSubfield('i', "In:");
    }
}

void UpdateCacheEntry(CacheEntry &ce, const CacheEntry &new_ce, const bool is_online) {
    ce.preferred_title_ = new_ce.preferred_title_;
    ce.preferred_ppn_ = new_ce.preferred_ppn_;
    ce.preferred_issn_ = new_ce.preferred_issn_;
    ce.is_online_ = is_online;
    InsertIfNotExist(new_ce.issns_, &ce.issns_);
}


void UpdateCacheAndCombineIssn(CacheEntry * const ce, const CacheEntry &new_ce) {
    bool subset(true);

    for (const auto &v1 : new_ce.issns_)
        subset = (subset || IsInISSNs(ce->issns_, v1));

    if (not subset) {
        if (ce->is_online_ && new_ce.is_online_)
            ce->is_valid_ = false;


        if (!ce->is_online_ && new_ce.is_online_) {
            ce->is_valid_ = true;
            ce->preferred_title_ = new_ce.preferred_title_;
            ce->preferred_ppn_ = new_ce.preferred_ppn_;
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
    targetitlesbi->related_ppn_and_its_issns.insert(
        std::pair<std::string, std::vector<std::string>>(inputitlesbi.preferred_ppn_, inputitlesbi.issns_));
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

void CleanDuplicationOfField773ByISSN(MARC::Record * const record) {
    std::vector<std::string> issns;
    for (auto field(record->begin()); field != record->end(); ++field) {
        if (field->getTag() == "773") {
            const std::string issn = field->getFirstSubfieldWithCode('x'), title = field->getFirstSubfieldWithCode('t');
            if (IsInISSNs(issns, issn))
                record->erase(field);
            else
                issns.emplace_back(issn);
        }
    }
}

void CleanDuplicationOfField773ByTitle(MARC::Record * const record, std::vector<TitleInfo773> * const found_title_info_cache) {
    for (auto field(record->begin()); field != record->end(); ++field) {
        if (field->getTag() == "773") {
            TitleInfo773 ti;
            ti.Update(*field);
            if (not ti.subfield_w_.empty()) {
                if (IsInTitleInfo773Cache(*found_title_info_cache, ti, false))
                    record->erase(field);
                else {
                    field->getSubfields().replaceFirstSubfield('t', ti.title_);
                    found_title_info_cache->emplace_back(ti);
                }
            } else {
                if (IsInTitleInfo773Cache(*found_title_info_cache, ti, true))
                    record->erase(field);
                else
                    field->getSubfields().replaceFirstSubfield('t', ti.title_);
            }
        }
    }
}

void CleanDuplicationOfField773ByTitleSecondPass(MARC::Record * const record, const std::vector<TitleInfo773> &found_title_info_cache) {
    std::map<std::string, int> found_counter;

    for (auto field(record->begin()); field != record->end(); ++field) {
        if (field->getTag() == "773") {
            TitleInfo773 ti;
            ti.Update(*field);
            if (not ti.subfield_w_.empty()) {
                if (IsInTitleInfo773Cache(found_title_info_cache, ti, false)) {
                    if (found_counter[ti.title_] > 0)
                        record->erase(field);
                    else
                        found_counter[ti.title_]++;
                }
            } else {
                if (IsInTitleInfo773Cache(found_title_info_cache, ti, true))
                    record->erase(field);
            }
        }
    }
}

void ISSNLookup(char **argv, std::vector<CacheEntry> &journal_cache, std::vector<IssnLookup::ISSNInfo> * const issn_org_cache,
                DebugInfo * const debug_info, const bool &debug_mode) {
    auto input_file(MARC::Reader::Factory(argv[1]));
    auto output_file(MARC::Writer::Factory(argv[3]));
    std::set<std::string> invalid_issns_ink10plus;

    while (MARC::Record record = input_file->read()) {
        std::string ppn("");
        for (auto &field : record) {
            MARC::Subfields subfields(field.getSubfields());
            bool is_issn_in_k10plus(false), is_in_k10plus_but_invalid(false);
            if (field.getTag() == "001")
                ppn = field.getContents();

            if (field.getTag() == "773") {
                const std::string issn(StringUtil::ASCIIToUpper(field.getFirstSubfieldWithCode('x')));
                if (not issn.empty()) {
                    // data is found or need to check it first
                    if (debug_info->issns_not_found_.find(issn) == debug_info->issns_not_found_.end()) {
                        // and invalid
                        if (invalid_issns_ink10plus.find(issn) == invalid_issns_ink10plus.end()) {
                            for (const auto &elemt : journal_cache) {
                                bool is_in_l =
                                    (std::find(elemt.issns_.begin(), elemt.issns_.end(), issn) != elemt.issns_.end() ? true : false);
                                if ((elemt.preferred_issn_ == issn) || is_in_l) {
                                    if (elemt.is_valid_) {
                                        UpdateSubfieldUsingK10(subfields, elemt);
                                        field.setSubfields(subfields);

                                        if (debug_mode)
                                            debug_info->ppns_use_k10_.insert(std::make_pair(ppn, issn));

                                    } else {
                                        is_in_k10plus_but_invalid = true;
                                        invalid_issns_ink10plus.insert(issn);
                                    }
                                    // issn is found in k10, ignoring wheather it is if valid or not
                                    is_issn_in_k10plus = true;
                                    break;
                                }
                            }
                        } else {
                            is_in_k10plus_but_invalid = true;
                        }
                        if (not is_issn_in_k10plus || is_in_k10plus_but_invalid) {
                            IssnLookup::ISSNInfo issn_info;
                            if (IsInISSNInfoCache(issn, *issn_org_cache, &issn_info)) {
                                // issn is in the issn info cache already
                                UpdateSubfieldUsingISSNOrg(subfields, issn_info);
                                field.setSubfields(subfields);
                                if (debug_mode) {
                                    (is_in_k10plus_but_invalid
                                         ? debug_info->ppns_with_issn_in_k10_but_invalid_.insert(std::make_pair(ppn, issn))
                                         : debug_info->ppns_use_issn_org_.insert(std::make_pair(ppn, issn)));
                                }

                            } else {
                                if (IssnLookup::GetISSNInfo(issn, &issn_info)) {
                                    issn_org_cache->emplace_back(issn_info);
                                    UpdateSubfieldUsingISSNOrg(subfields, issn_info);
                                    field.setSubfields(subfields);
                                    if (debug_mode) {
                                        (is_in_k10plus_but_invalid
                                             ? debug_info->ppns_with_issn_in_k10_but_invalid_.insert(std::make_pair(ppn, issn))
                                             : debug_info->ppns_use_issn_org_.insert(std::make_pair(ppn, issn)));
                                    }

                                } else {
                                    // issn was not found
                                    if (debug_mode) {
                                        debug_info->issns_not_found_.insert(issn);
                                        debug_info->ppns_with_issn_not_recognized_.insert(std::make_pair(ppn, issn));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        std::vector<TitleInfo773> found_title_info_cache;
        CleanDuplicationOfField773ByISSN(&record);
        CleanDuplicationOfField773ByTitle(&record, &found_title_info_cache);
        CleanDuplicationOfField773ByTitleSecondPass(&record, found_title_info_cache);
        output_file->write(record);
    }
}


} // end of namespace


int Main(int argc, char **argv) {
    if (argc < 4 || argc > 5)
        Usage();

    std::vector<CacheEntry> journal_cache(BuildJournalCache(argv[2]));
    std::vector<IssnLookup::ISSNInfo> issn_org_cache;
    std::map<std::string, std::string> ppns_use_issn_org, ppns_with_issn_not_recognized, ppns_with_issn_in_k10_but_invalid;
    std::set<std::string> issns_not_found;
    DebugInfo debug_info;

    const bool debug_mode(((argc == 5 && (std::strcmp(argv[4], "--verbose") == 0)) ? true : false));

    ISSNLookup(argv, journal_cache, &issn_org_cache, &debug_info, debug_mode);

    if (debug_mode)
        ShowInfoForDebugging(journal_cache, issn_org_cache, debug_info);

    return EXIT_SUCCESS;
}
