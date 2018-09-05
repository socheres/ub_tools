/*  \brief Utility Functions for Normalizing and Augmenting Data obtained by Zotero
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
#pragma once

#include "MARC.h"
#include "UrlUtil.h"
#include "Zotero.h"


namespace Zotero {

namespace ZoteroTransformation {

   extern const std::map<std::string, std::string> CREATOR_TYPES_TO_MARC21_MAP;
   extern const std::map<std::string, std::string> CREATOR_TYPES_TO_MARC21_MAP;
   extern const std::map<std::string, MARC::Record::BibliographicLevel> ITEM_TYPE_TO_BIBLIOGRAPHIC_LEVEL_MAP;

   const std::string GetCreatorTypeForMarc21(const std::string &zotero_creator_type);
   MARC::Record::BibliographicLevel MapBiblioLevel(const std::string item_type);
   bool IsValidItemType(const std::string item_type);
   std::string DownloadAuthorPPN(const std::string &author, const struct SiteParams &site_params);

} // end ZoteroTransformation

} // end Zotero
