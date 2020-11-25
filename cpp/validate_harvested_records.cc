/** \brief Utility for validating and fixing up records harvested by zts_harvester
 *  \author Dr. Johannes Ruscheinski (johannes.ruscheinski@uni-tuebingen.de)
 *
 *  \copyright 2018-2020 Universitätsbibliothek Tübingen.  All rights reserved.
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
#include "DnsUtil.h"
#include "EmailSender.h"
#include "IniFile.h"
#include "MARC.h"
#include "StringUtil.h"
#include "UBTools.h"
#include "util.h"
#include "ZoteroHarvesterUtil.h"


namespace {


enum FieldPresence { ALWAYS, SOMETIMES, IGNORE };


FieldPresence StringToFieldPresence(const std::string &field_presence_str) {
    if (field_presence_str == "ALWAYS")
        return ALWAYS;
    if (field_presence_str == "SOMETIMES")
        return SOMETIMES;
    if (field_presence_str == "IGNORE")
        return IGNORE;

    LOG_ERROR("unknown field presence \"" + field_presence_str + "\"!");
}


class FieldRule {
    std::map<char, FieldPresence> subfield_code_to_field_presence_map_;
public:
    FieldRule(const char subfield_code, const FieldPresence field_presence);
    void addRule(const char subfield_code, const FieldPresence field_presence);
    void findRuleViolations(const MARC::Subfields &subfields, std::string * const reason_for_being_invalid) const;
};


FieldRule::FieldRule(const char subfield_code, const FieldPresence field_presence) {
    subfield_code_to_field_presence_map_[subfield_code] = field_presence;
}


void FieldRule::addRule(const char subfield_code, const FieldPresence field_presence) {
    if (unlikely(subfield_code_to_field_presence_map_.find(subfield_code) != subfield_code_to_field_presence_map_.end()))
        LOG_ERROR("Attempt to insert a second rule for subfield code '" + std::string(1, subfield_code) + "'!");
    subfield_code_to_field_presence_map_[subfield_code] = field_presence;
}


void FieldRule::findRuleViolations(const MARC::Subfields &subfields, std::string * const reason_for_being_invalid) const {
    std::set<char> found_subfield_codes;
    for (const auto &subfield : subfields)
        found_subfield_codes.emplace(subfield.code_);

    for (const auto &subfield_code_and_field_presence : subfield_code_to_field_presence_map_) {
        const auto iter(found_subfield_codes.find(subfield_code_and_field_presence.first));
        if (iter == found_subfield_codes.end() and subfield_code_and_field_presence.second == ALWAYS) {
            if (not reason_for_being_invalid->empty())
                reason_for_being_invalid->append("; ");
            reason_for_being_invalid->append("required subfield " + std::string(1, subfield_code_and_field_presence.first)
                                             + " is missing");
        }
    }
}


class Validator {
public:
    ~Validator() {}

    /** \return True if we found rules for all subfields in "field" o/w false.
     *  \note   If a rule violation was found, "reason_for_being_invalid" w/ be non-empty after the call and
     *          we will return true.
     */
    virtual bool foundRuleMatch(const std::string &journal_id, const MARC::Record::Field &field,
                                std::string * const reason_for_being_invalid) const = 0;

    virtual void findMissingTags(const std::string &journal_id, const std::set<std::string> &present_tags,
                                 std::set<std::string> * const missing_tags) const = 0;
};


class GeneralValidator final : public Validator {
    std::unordered_map<std::string, FieldRule> tags_to_rules_map_;
public:
    void addRule(const std::string &tag, const char subfield_code, const FieldPresence field_presence);
    virtual bool foundRuleMatch(const std::string &journal_id, const MARC::Record::Field &field,
                                std::string * const reason_for_being_invalid) const;
    virtual void findMissingTags(const std::string &journal_id, const std::set<std::string> &present_tags,
                                 std::set<std::string> * const missing_tags) const;
};


void GeneralValidator::addRule(const std::string &tag, const char subfield_code,
                               const FieldPresence field_presence)
{
    auto tag_and_rule(tags_to_rules_map_.find(tag));
    if (tag_and_rule == tags_to_rules_map_.end())
        tags_to_rules_map_.emplace(tag, FieldRule(subfield_code, field_presence));
    else
        tag_and_rule->second.addRule(subfield_code, field_presence);
}


bool GeneralValidator::foundRuleMatch(const std::string &/*journal_id*/, const MARC::Record::Field &field,
                                      std::string * const reason_for_being_invalid) const
{
    const std::string tag(field.getTag().toString());
    const auto tags_and_rules(tags_to_rules_map_.find(tag));
    if (tags_and_rules == tags_to_rules_map_.cend())
        return false;

    std::string rule_violations;
    tags_and_rules->second.findRuleViolations(field.getSubfields(), &rule_violations);
    if (not rule_violations.empty())
        *reason_for_being_invalid = tag + ": " + rule_violations;

    return true;
}


void GeneralValidator::findMissingTags(const std::string &/*journal_id*/, const std::set<std::string> &present_tags,
                                       std::set<std::string> * const missing_tags) const
{
    for (const auto &[required_tag, rule] : tags_to_rules_map_) {
        if (present_tags.find(required_tag) == present_tags.cend())
            missing_tags->emplace(required_tag);
    }
}


class JournalSpecificValidator final : public Validator {
    std::unordered_map<std::string, GeneralValidator> journal_ids_to_validators_map_;
public:
    void addRule(const std::string &journal_id, const std::string &tag, const char subfield_code,
                 const FieldPresence field_presence);
    virtual bool foundRuleMatch(const std::string &journal_id, const MARC::Record::Field &field,
                                std::string * const reason_for_being_invalid) const;
    virtual void findMissingTags(const std::string &journal_id, const std::set<std::string> &present_tags,
                                 std::set<std::string> * const missing_tags) const;
};


void JournalSpecificValidator::addRule(const std::string &journal_id, const std::string &tag, const char subfield_code,
                                       const FieldPresence field_presence)
{
    auto journal_id_and_validators(journal_ids_to_validators_map_.find(journal_id));
    if (journal_id_and_validators == journal_ids_to_validators_map_.end()) {
        GeneralValidator new_general_validator;
        new_general_validator.addRule(tag, subfield_code, field_presence);
        journal_ids_to_validators_map_.emplace(journal_id, new_general_validator);
    } else
        journal_id_and_validators->second.addRule(tag, subfield_code, field_presence);
}


bool JournalSpecificValidator::foundRuleMatch(const std::string &journal_id, const MARC::Record::Field &field,
                                              std::string * const reason_for_being_invalid) const
{
    const auto journal_id_and_validators(journal_ids_to_validators_map_.find(journal_id));
    if (journal_id_and_validators == journal_ids_to_validators_map_.cend())
        return false;
    return journal_id_and_validators->second.foundRuleMatch(journal_id, field, reason_for_being_invalid);
}


void JournalSpecificValidator::findMissingTags(const std::string &journal_id, const std::set<std::string> &present_tags,
                                               std::set<std::string> * const missing_tags) const
{
    const auto journal_id_and_validators(journal_ids_to_validators_map_.find(journal_id));
    if (journal_id_and_validators == journal_ids_to_validators_map_.cend())
        return;
    journal_id_and_validators->second.findMissingTags(journal_id, present_tags, missing_tags);
}


void LoadRules(DbConnection * const db_connection, GeneralValidator * const general_regular_article_validator,
               JournalSpecificValidator * const journal_specific_regular_article_validator,
               GeneralValidator * const general_review_article_validator,
               JournalSpecificValidator * const journal_specific_review_article_validator)
{
    db_connection->queryOrDie(
        "SELECT marc_field_tag,marc_subfield_code,field_presence,record_type FROM metadata_presence_tracer");
    DbResultSet result_set(db_connection->getLastResultSet());
    while (const auto row = result_set.getNextRow()) {
        if (row["record_type"] == "regular_article") {
            if (row.isNull("journal_id"))
                general_regular_article_validator->addRule(row["marc_field_tag"], row["marc_subfield_code"][0],
                                                           StringToFieldPresence(row["field_presence"]));
            else
                journal_specific_regular_article_validator->addRule(row["journal_id"], row["marc_field_tag"],
                                                                    row["marc_subfield_code"][0],
                                                                    StringToFieldPresence(row["field_presence"]));
        } else { // Assume that record_type == review.
            if (row.isNull("journal_id"))
                general_review_article_validator->addRule(row["marc_field_tag"], row["marc_subfield_code"][0],
                                                          StringToFieldPresence(row["field_presence"]));
            else
                journal_specific_review_article_validator->addRule(row["journal_id"], row["marc_field_tag"],
                                                                   row["marc_subfield_code"][0],
                                                                   StringToFieldPresence(row["field_presence"]));
        }
    }
}


void SendEmail(const std::string &email_address, const std::string &message_subject, const std::string &message_body) {
    const auto reply_code(EmailSender::SendEmail("zts_harvester_delivery_pipeline@uni-tuebingen.de",
                          email_address, message_subject, message_body,
                          EmailSender::MEDIUM, EmailSender::PLAIN_TEXT, /* reply_to = */ "",
                          /* use_ssl = */ true, /* use_authentication = */ true));

    if (reply_code >= 300)
        LOG_WARNING("failed to send email, the response code was: " + std::to_string(reply_code));
}


void CheckGenericRequirements(const MARC::Record &record, std::string * const reasons_for_being_invalid) {
    if (not record.hasTag("001"))
        reasons_for_being_invalid->append("control field 001 is missing\n");
    if (not record.hasTag("003"))
        reasons_for_being_invalid->append("control field 003 is missing\n");
    if (not record.hasTag("007"))
        reasons_for_being_invalid->append("control field 007 is missing\n");

    const auto _245_field(record.findTag("245"));
    if (_245_field == record.end())
        reasons_for_being_invalid->append("field 245 is missing\n");
    else if (_245_field->getFirstSubfieldWithCode('a').empty())
        reasons_for_being_invalid->append("subfield 245$a is missing\n");

    if (not record.hasTag("100") and not record.hasTag("700"))
        reasons_for_being_invalid->append("neither a field 100 nor 700 are present\n");
}


bool RecordIsValid(const MARC::Record &record, const std::vector<const Validator *> &regular_article_validators,
                   const std::vector<const Validator *> &review_article_validators,
                   std::string * const reasons_for_being_invalid)
{
    reasons_for_being_invalid->clear();

    const auto zid_field(record.findTag("ZID"));
    if (unlikely(zid_field == record.end()))
        LOG_ERROR("record is missing a ZID field!");
    else if (zid_field->getFirstSubfieldWithCode('a').empty())
        LOG_ERROR("record is missing an a-subfield in the existing ZID field!");
    const auto ZID(zid_field->getFirstSubfieldWithCode('a'));

    // 0. Check that requirements for all records, independent of type or journal are met:
    CheckGenericRequirements(record, reasons_for_being_invalid);

    // 1. Check that present fields meet all the requirements:
    MARC::Tag last_tag("   ");
    const auto &validators(record.isReviewArticle() ? review_article_validators : regular_article_validators);
    std::set<std::string> present_tags;
    for (const auto &field : record) {
        const auto current_tag(field.getTag());
        if (current_tag == last_tag and not field.isRepeatableField())
            reasons_for_being_invalid->append(current_tag.toString() + " is not a repeatable field\n");
        last_tag = current_tag;
        present_tags.emplace(current_tag.toString());

        for (const auto validator : validators) {
            std::string reason_for_being_invalid;
            if (validator->foundRuleMatch(ZID, field, &reason_for_being_invalid)) {
                if (not reason_for_being_invalid.empty())
                    reasons_for_being_invalid->append(reason_for_being_invalid + "\n");
                break;
            }
        }
    }

    // 2. Check for missing required fields:
    std::set<std::string> missing_tags;
    for (const auto validator : validators)
        validator->findMissingTags(ZID, present_tags, &missing_tags);
    for (const auto &missing_tag : missing_tags)
        reasons_for_being_invalid->append("required " + missing_tag + "-field is missing\n");

    return reasons_for_being_invalid->empty();
}


} // unnamed namespace


int Main(int argc, char *argv[]) {
    if (argc != 5)
        ::Usage("marc_input marc_output missed_expectations_file email_address");

    DbConnection db_connection;

    auto marc_reader(MARC::Reader::Factory(argv[1]));
    auto valid_records_writer(MARC::Writer::Factory(argv[2]));
    auto delinquent_records_writer(MARC::Writer::Factory(argv[3]));
    const std::string email_address(argv[4]);
    ZoteroHarvester::Util::UploadTracker upload_tracker;

    GeneralValidator general_regular_article_validator, general_review_article_validator;
    JournalSpecificValidator journal_specific_regular_article_validator, journal_specific_review_article_validator;
    LoadRules(&db_connection, &general_regular_article_validator, &journal_specific_regular_article_validator,
              &general_review_article_validator, &journal_specific_review_article_validator);
    std::vector<const Validator *> regular_article_validators{ &journal_specific_regular_article_validator,
                                                               &general_regular_article_validator },
                                   review_article_validators{ &journal_specific_review_article_validator,
                                                              &journal_specific_regular_article_validator,
                                                              &general_review_article_validator,
                                                              &general_regular_article_validator };

    unsigned total_record_count(0), missed_expectation_count(0);
    while (const auto record = marc_reader->read()) {
        ++total_record_count;

        std::string reasons_for_being_invalid;
        if (RecordIsValid(record, regular_article_validators, review_article_validators, &reasons_for_being_invalid))
            valid_records_writer->write(record);
        else {
            upload_tracker.archiveRecord(record, ZoteroHarvester::Util::UploadTracker::DeliveryState::ERROR,
                                         reasons_for_being_invalid);
            ++missed_expectation_count;
            delinquent_records_writer->write(record);
        }
    }

    if (missed_expectation_count > 0) {
        // send notification to the email address
        SendEmail(email_address, "validate_harvested_records encountered warnings (from: " + DnsUtil::GetHostname() + ")",
                  "Some records missed expectations with respect to MARC fields. "
                  "Check the log at '" + UBTools::GetTueFindLogPath() + "zts_harvester_delivery_pipeline.log' for details.");
    }

    LOG_INFO("Processed " + std::to_string(total_record_count) + " record(s) of which " + std::to_string(missed_expectation_count) +
             " record(s) missed expectations.");

    return EXIT_SUCCESS;
}
