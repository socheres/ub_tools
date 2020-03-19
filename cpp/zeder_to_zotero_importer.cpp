/** \brief Utility to automatically update the Zotero Harvester configuration from Zeder.
 *  \author Madeeswaran Kannan
 *
 *  \copyright 2020 Universitätsbibliothek Tübingen.  All rights reserved.
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
#include <unordered_set>
#include <cstdio>
#include <cstdlib>
#include "FileUtil.h"
#include "IniFile.h"
#include "util.h"
#include "ZoteroHarvesterConfig.h"
#include "ZoteroHarvesterUtil.h"
#include "ZoteroHarvesterZederInterop.h"


namespace {


using namespace ZoteroHarvester;


[[noreturn]] void Usage() {
    std::cerr << "Usage: " << ::progname << " [options] config_file_path mode zeder_flavour zeder_ids update_fields\n"
              << "\n"
              << "\tOptions:\n"
              << "\t[--min-log-level=log_level]     Possible log levels are ERROR, WARNING (default), INFO and DEBUG\n"
              << "\t[--overwrite]                   Overwrite existing fields and/or sections\n"
              << "\n"
              << "\tconfig_file_path                Path to the Zotero Harvester config file\n"
              << "\tmode                            Either IMPORT or UPDATE\n"
              << "\tzeder_flavour                   Either IXTHEO or KRIMDOK\n"
              << "\tzeder_ids                       Comma-separated list of Zeder entry IDs to import/update.\n"
              << "\t                                Special-case for updating: Use '*' to update all entries found in the config that belong to the Zeder flavour\n"
              << "\tupdate_fields                   Comma-separated list of the following fields to update: \n"
              << "\t                                \tONLINE_PPN, PRINT_PPN, ONLINE_ISSN, PRINT_ISSN, EXPECTED_LANGUAGES, ENTRY_POINT_URL, UPLOAD_OPERATION, UPDATE_WINDOW.\n"
              << "\t                                Ignored when importing entries (all importable fields will be imported).\n\n";
    std::exit(EXIT_FAILURE);
}


struct CommandLineArgs {
    enum Mode { INVALID, IMPORT, UPDATE };

    bool overwrite_;
    std::string config_path_;
    Mode mode_;
    Zeder::Flavour zeder_flavour_;
    std::set<unsigned> zeder_ids_;
    std::set<Config::JournalParams::IniKey> update_fields_;
public:
    explicit CommandLineArgs() : overwrite_(false), mode_(INVALID) {}
};


void ParseCommandLineArgs(int * const argc, char *** const argv, CommandLineArgs * const commandline_args) {
    while (StringUtil::StartsWith((*argv)[1], "--")) {
        if (std::strcmp((*argv)[1], "--overwrite") == 0) {
            commandline_args->overwrite_ = true;
            --*argc, ++*argv;
            continue;
        }
    }

    if (*argc < 5)
        Usage();

    commandline_args->config_path_ = (*argv)[1];
    --*argc, ++*argv;

    const std::string mode((*argv)[1]);
    --*argc, ++*argv;

    if (::strcasecmp(mode.c_str(), "IMPORT") == 0)
        commandline_args->mode_ = CommandLineArgs::Mode::IMPORT;
    else if (::strcasecmp(mode.c_str(), "UPDATE") == 0)
        commandline_args->mode_ = CommandLineArgs::Mode::UPDATE;
    else
        Usage();

    const std::string zeder_flavour((*argv)[1]);
    --*argc, ++*argv;

    commandline_args->zeder_flavour_ = Zeder::ParseFlavour(zeder_flavour);

    const std::string zeder_id_list((*argv)[1]);
    --*argc, ++*argv;

    std::set<std::string> buffer;
    if (zeder_id_list != "*") {
        StringUtil::SplitThenTrimWhite(zeder_id_list, ',', &buffer);
        for (const auto &id_str : buffer)
            commandline_args->zeder_ids_.emplace(StringUtil::ToUnsigned(id_str));
    } else if (commandline_args->mode_ == CommandLineArgs::Mode::IMPORT)
        LOG_ERROR("cannot import all Zeder entries at once");

    if (commandline_args->mode_ == CommandLineArgs::Mode::IMPORT)
        return;

    static const std::set<Config::JournalParams::IniKey> ALLOWED_INI_KEYS {
        Config::JournalParams::ENTRY_POINT_URL,
        Config::JournalParams::UPLOAD_OPERATION,
        Config::JournalParams::ONLINE_PPN,
        Config::JournalParams::PRINT_PPN,
        Config::JournalParams::ONLINE_ISSN,
        Config::JournalParams::PRINT_ISSN,
        Config::JournalParams::UPDATE_WINDOW,
        Config::JournalParams::EXPECTED_LANGUAGES,
    };

    const std::string update_fields_list((*argv)[1]);
    --*argc, ++*argv;

    buffer.clear();
    StringUtil::SplitThenTrimWhite(update_fields_list, ',', &buffer);
    for (const auto &update_field_str : buffer) {
        const auto ini_key(Config::JournalParams::GetIniKey(update_field_str));
        if (ALLOWED_INI_KEYS.find(ini_key) == ALLOWED_INI_KEYS.end())
            LOG_ERROR("update field '" + update_field_str + "' is invalid");

        commandline_args->update_fields_.emplace(ini_key);
    }

    if (commandline_args->update_fields_.empty())
        LOG_ERROR("no fields were provided to be updated");
}


void DownloadZederEntries(const Zeder::Flavour flavour, const std::unordered_set<unsigned> &entries_to_download,
                          Zeder::EntryCollection * const downloaded_entries)
{
    const auto endpoint_url(Zeder::GetFullDumpEndpointPath(flavour));
    const std::unordered_set<std::string> columns_to_download {};  // intentionally empty
    const std::unordered_map<std::string, std::string> filter_regexps {}; // intentionally empty
    std::unique_ptr<Zeder::FullDumpDownloader::Params> downloader_params(new Zeder::FullDumpDownloader::Params(endpoint_url,
                                                                         entries_to_download, columns_to_download, filter_regexps));

    auto downloader(Zeder::FullDumpDownloader::Factory(Zeder::FullDumpDownloader::Type::FULL_DUMP, std::move(downloader_params)));
    if (not downloader->download(downloaded_entries))
        LOG_ERROR("couldn't download full dump for " + Zeder::FLAVOUR_TO_STRING_MAP.at(flavour));
}


struct HarvesterConfig {
    std::unique_ptr<IniFile> config_file_;
    std::unique_ptr<Config::GlobalParams> global_params_;
    std::vector<std::unique_ptr<Config::GroupParams>> group_params_;
    std::vector<std::unique_ptr<Config::JournalParams>> journal_params_;
public:
    HarvesterConfig(const std::string &config_file_path) {
        Config::LoadHarvesterConfigFile(config_file_path, &global_params_, &group_params_, &journal_params_, &config_file_);
    }
};


std::vector<std::reference_wrapper<Config::JournalParams>> FetchJournalParamsForZederFlavour(const Zeder::Flavour zeder_flavour,
                                                                                             const HarvesterConfig &harvester_config)
{
    std::vector<std::reference_wrapper<Config::JournalParams>> journal_params;

    for (const auto &journal_param : harvester_config.journal_params_) {
        if (ZederInterop::GetZederInstanceForJournal(*journal_param) == zeder_flavour)
            journal_params.emplace_back(std::cref(*journal_param));
    }

    return journal_params;
}


void DetermineZederEntriesToBeDownloaded(const CommandLineArgs &commandline_args,
                                         const std::vector<std::reference_wrapper<Config::JournalParams>> &existing_journal_params,
                                         std::unordered_set<unsigned> * const entries_to_download)
{
    switch (commandline_args.mode_) {
    case CommandLineArgs::Mode::IMPORT:
        for (const auto id : commandline_args.zeder_ids_)
            entries_to_download->emplace(id);

        break;
    case CommandLineArgs::Mode::UPDATE:
        if (commandline_args.zeder_ids_.empty()) {
            // update all existing journals in the config
            for (const auto &journal_param : existing_journal_params)
               entries_to_download->emplace(journal_param.get().zeder_id_);
        }

        break;
    default:
        break;
    }

    if (entries_to_download->empty())
        LOG_ERROR("no entries to import/update");
}



} // unnamed namespace


int Main(int argc, char *argv[]) {
    if (argc < 2)
        Usage();

    CommandLineArgs commandline_args;
    ParseCommandLineArgs(&argc, &argv, &commandline_args);

    HarvesterConfig harvester_config(commandline_args.config_path_);
    const auto existing_journal_params(FetchJournalParamsForZederFlavour(commandline_args.zeder_flavour_, harvester_config));

    Zeder::EntryCollection downloaded_entries;
    std::unordered_set<unsigned> entries_to_download;

    DetermineZederEntriesToBeDownloaded(commandline_args, existing_journal_params, &entries_to_download);
    DownloadZederEntries(commandline_args.zeder_flavour_, entries_to_download, &downloaded_entries);




    return EXIT_SUCCESS;
}
