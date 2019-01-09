/** \file    NGram.h
 *  \brief   Declarations of ngram related utility functions.
 *  \author  Dr. Johannes Ruscheinski
 */

/*
 *  Copyright 2003-2009 Project iVia.
 *  Copyright 2003-2009 The Regents of The University of California.
 *  Copyright 2019 Universitätsbibliothek Tübingen.
 *
 *  This file is part of the libiViaCore package.
 *
 *  The libiViaCore package is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  libiViaCore is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with libiViaCore; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
#pragma once


#include <sstream>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>


namespace NGram {


// Language extraction parameters.  These defaults are the same as the reference
// implementation (i.e. the perl "text_cat" program) except where noted.
const unsigned DEFAULT_NGRAM_NUMBER_THRESHOLD  =   0; // 0 means no threshold.
const unsigned DEFAULT_TOPMOST_USE_COUNT       = 400;
const double DEFAULT_ALTERNATIVE_CUTOFF_FACTOR = 1.0; // textcat = 1.05


typedef std::unordered_map<std::string, double> NGramCounts;


class SortedNGramCounts: public std::vector<std::pair<std::string, double>> {
public:
	enum SortOrder { ASCENDING_ORDER, DESCENDING_ORDER };
public:
	SortedNGramCounts(): std::vector<std::pair<std::string, double>>() { }
	explicit SortedNGramCounts(const NGramCounts &ngram_counts, const SortOrder sort_order);
private:
	static bool IsLessThan(const std::pair<std::string, double> &lhs, const std::pair<std::string, double> &rhs);
	static bool IsGreaterThan(const std::pair<std::string, double> &lhs, const std::pair<std::string, double> &rhs);
};


/** \brief  Tell which language(s) "input" might be.
 *  \param  input                   Where to read the input text from.
 *  \param  ngram_counts            A map from resulting ngrams to their respective counts.
 *  \param  top_ngrams              The most frequent ngrams and their counts, sorted in decreasing
 *                                  order of frequency.
 *  \param  ngram_number_threshold  Don't used ngrams that occur less than this many times.
 *                                  A value of 0 means: use all ngrams.
 *  \param  topmost_use_count       The topmost number of ngrams that should be used.
 */
void CreateLanguageModel(std::istream &input, NGramCounts * const ngram_counts,
			 SortedNGramCounts * const top_ngrams,
			 const unsigned ngram_number_threshold = DEFAULT_NGRAM_NUMBER_THRESHOLD,
			 const unsigned topmost_use_count = DEFAULT_TOPMOST_USE_COUNT);


/** \brief  Tell which language(s) "input_text" might be.
 *  \param  input_text              The input text.
 *  \param  ngram_counts            A map from resulting ngrams to their respective counts.
 *  \param  top_ngrams              The most frequent ngrams and their counts, sorted in decreasing
 *                                  order of frequency.
 *  \param  ngram_number_threshold  Don't used ngrams that occur less than this many times.
 *                                  A value of 0 means: use all ngrams.
 *  \param  topmost_use_count       The topmost number of ngrams that should be used.
 */
inline void CreateLanguageModel(const std::string &input_text, NGramCounts * const ngram_counts,
				SortedNGramCounts * const top_ngrams,
				const unsigned ngram_number_threshold = DEFAULT_NGRAM_NUMBER_THRESHOLD,
				const unsigned topmost_use_count = DEFAULT_TOPMOST_USE_COUNT)
{
    std::istringstream input(input_text);
    CreateLanguageModel(input, ngram_counts, top_ngrams, ngram_number_threshold, topmost_use_count);
}


enum DistanceType { SIMPLE_DISTANCE, WEIGHTED_DISTANCE };


/** \brief  Tell which language(s) "input" might contain.
 *  \param  input                      Where to read the to be classified text from.
 *  \param  top_languages              The list of most likely languages with the most likely language first.
 *  \param  distance_type              ?
 *  \param  ngram_number_threshold     Don't used ngrams that occur less than this many times.
 *                                     A value of 0 means: use all ngrams.
 *  \param  topmost_use_count          ?
 *  \param  alternative_cutoff_factor  Include languages in "top_languages" that received scores no less
 *                                     than "alternative_cutoff_factor" * alternative_language's_score/
 *                                     score_of_highest_scoring_language.
 *  \param  override_language_models_directory  If set, it specifies alternative location of language models.
 *
 *  \note    By default, the language models are located in the libiViCore share/language_models directory.
 */
void ClassifyLanguage(std::istream &input, std::vector<std::string> * const top_languages,
		      const DistanceType distance_type = SIMPLE_DISTANCE,
		      const unsigned ngram_number_threshold = DEFAULT_NGRAM_NUMBER_THRESHOLD,
		      const unsigned topmost_use_count = DEFAULT_TOPMOST_USE_COUNT,
		      const double alternative_cutoff_factor = DEFAULT_ALTERNATIVE_CUTOFF_FACTOR,
		      const std::string &override_language_models_directory = "");


/** \brief  Tell which language(s) "input_text" might be.
 *  \param  input_text                 The text to classify.
 *  \param  top_languages              The list of most likely languages with the most likely language first.
 *  \param  distance_type              ?
 *  \param  ngram_number_threshold     Don't used ngrams that occur less than this many times.
 *                                     A value of 0 means: use all ngrams.
 *  \param  topmost_use_count          ?
 *  \param  alternative_cutoff_factor  Include languages in "top_languages" that received scores no less
 *                                     than "alternative_cutoff_factor" * alternative_language's_score/
 *                                     score_of_highest_scoring_language.
 *  \param  override_language_models_directory  If set, it specifies alternative location of language models.
 *
 *  \note   By default, the language models are located in the libiViaCore share/language_models directory.
 */
inline void ClassifyLanguage(const std::string &input_text, std::vector<std::string> * const top_languages,
			     const DistanceType distance_type = SIMPLE_DISTANCE,
			     const unsigned ngram_number_threshold = DEFAULT_NGRAM_NUMBER_THRESHOLD,
			     const unsigned topmost_use_count = DEFAULT_TOPMOST_USE_COUNT,
			     const double alternative_cutoff_factor = DEFAULT_ALTERNATIVE_CUTOFF_FACTOR,
			     const std::string &override_language_models_directory = "")
{
    std::istringstream input(input_text);
    ClassifyLanguage(input, top_languages, distance_type, ngram_number_threshold, topmost_use_count, alternative_cutoff_factor,
                     override_language_models_directory);
}


} // namespace NGram