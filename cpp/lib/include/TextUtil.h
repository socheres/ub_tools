/** \file    TextUtil.h
 *  \brief   Declarations of text related utility functions.
 *  \author  Dr. Johannes Ruscheinski
 *  \author  Jiangtao Hu
 */

/*
 *  Copyright 2003-2009 Project iVia.
 *  Copyright 2003-2009 The Regents of The University of California.
 *  Copyright 2015,2017,2018 Universitätsbibliothek Tübingen.
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


#include <memory>
#include <string>
#include <unordered_set>
#include <vector>
#include <cwchar>
#include <iconv.h>


namespace TextUtil {


constexpr uint32_t REPLACEMENT_CHARACTER(0xFFFDu);
constexpr uint32_t EN_DASH(0x2013u);
constexpr uint32_t EM_DASH(0x2014u);
constexpr uint32_t TWO_EM_DASH(0x2E3Au);
constexpr uint32_t THREE_EM_DASH(0x2E3Bu);
constexpr uint32_t SMALL_EM_DASH(0xFE58u);


/** \brief Converter between many text encodings.
 */
class EncodingConverter {
    friend class IdentityConverter;
    const std::string from_encoding_;
    const std::string to_encoding_;
protected:
    const iconv_t iconv_handle_;
public:
    static const std::string CANONICAL_UTF8_NAME;
public:
    virtual ~EncodingConverter();

    const std::string &getFromEncoding() const { return from_encoding_; }
    const std::string &getToEncoding() const { return to_encoding_; }

    /** \brief Converts "input" to "output".
     *  \return True if the conversion succeeded, otherwise false.
     *  \note When this function returns false "*output" contains the unmodified copy of "input"!
     */
    virtual bool convert(const std::string &input, std::string * const output);

    /** \return Returns a nullptr if an error occurred and then sets *error_message to a non-empty string.
     *          O/w an EncodingConverter instance will be returned and *error_message will be cleared.
     */
    static std::unique_ptr<EncodingConverter> Factory(const std::string &from_encoding, const std::string &to_encoding,
                                                      std::string * const error_message);
private:
    explicit EncodingConverter(const std::string &from_encoding, const std::string to_encoding, const iconv_t iconv_handle)
        : from_encoding_(from_encoding), to_encoding_(to_encoding), iconv_handle_(iconv_handle) { }
};


class IdentityConverter: public EncodingConverter {
    friend std::unique_ptr<EncodingConverter> EncodingConverter::Factory(const std::string &from_encoding, const std::string &to_encoding,
                                                                         std::string * const error_message);
    IdentityConverter(): EncodingConverter(/* from_encoding = */"", /* to_encoding = */"", (iconv_t)-1) { }
public:
    virtual bool convert(const std::string &input, std::string * const output) final override { *output = input; return true; }

    static std::unique_ptr<EncodingConverter> Factory()
        { return std::unique_ptr<EncodingConverter>(new IdentityConverter()); }
};


/** \brief Strips HTML tags and converts entities.
 *  \param html             The HTML to process.
 *  \param initial_charset  Typically the content-type header's charset, if any.
 *  \return The extracted and converted text as UTF-8.
 */
std::string ExtractTextFromHtml(const std::string &html, const std::string &initial_charset = "");


/** \brief Extracts text from TEI files.
 *         Can only be used for non-generic idb/diglit TEI files.
 *  \param tei The TEI content to process.
 *  \return The extracted text with collapsed whitespaces.
 */
std::string ExtractTextFromUBTei(const std::string &tei);


/** \brief Recognises roman numerals up to a few thousand. */
bool IsRomanNumeral(const std::string &s);


/** \brief Recognises base-10 unsigned integers. */
bool IsUnsignedInteger(const std::string &s);


/** \brief Convert UTF8 to wide characters. */
bool UTF8ToWCharString(const std::string &utf8_string, std::wstring * wchar_string);


/** \brief Convert wide characters to UTF8. */
bool WCharToUTF8String(const std::wstring &wchar_string, std::string * utf8_string);


/** \brief Convert a wide character to UTF8. */
bool WCharToUTF8String(const wchar_t wchar, std::string * utf8_string);


/** \brief Converts a UTF8 string to lowercase.
 *  \return True if no character set conversion error occurred, o/w false.
 */
bool UTF8ToLower(const std::string &utf8_string, std::string * const lowercase_utf8_string);


/** \brief Converts a UTF8 string to lowercase.
 *  \return The converted string.
 *  \note Throws an exception if an error occurred.
 */
std::string UTF8ToLower(std::string * const utf8_string);
inline std::string UTF8ToLower(std::string utf8_string) { return UTF8ToLower(&utf8_string); }


/** \brief Converts a UTF8 string to uppercase.
 *  \return True if no character set conversion error occurred, o/w false.
 */
bool UTF8ToUpper(const std::string &utf8_string, std::string * const uppercase_utf8_string);


/** \brief Converts a UTF8 string to uppercase.
 *  \return The converted string.
 *  \note Throws an exception if an error occurred.
 */
std::string UTF8ToUpper(std::string * const utf8_string);


/** Converts UTF-32 a.k.a. UCS-4 to UTF-8. */
std::string UTF32ToUTF8(const uint32_t code_point);


/** \brief Attempts to convert "utf8_string" to a sequence of UTF32 code points.
 *  \return True if the conversion succeeded and false if "utf8_string" was an invalid UTF8 sequence.
 */
bool UTF8ToUTF32(const std::string &utf8_string, std::vector<uint32_t> * utf32_chars);


/** \brief Converts a UTF8 string to lowercase.
 *  \return The converted string.
 *  \note Throws an exception if an error occurred.
 */
uint32_t UTF32ToLower(const uint32_t code_point);


std::wstring &ToLower(std::wstring * const s);


/** \brief Converts a UTF8 string to uppercase.
 *  \return True if no character set conversion error occurred, o/w false.
 */
uint32_t UTF32ToUpper(const uint32_t code_point);


/** Converts single UTF-16 characters and surrogate pairs to UTF-32 a.k.a. UCS-4. */
inline uint32_t UTF16ToUTF32(const uint16_t u1, const uint16_t u2 = 0) {
    if (u2 == 0)
        return u1;

    return ((u1 & 0x3Fu) << 10u) | (u2 & 0x3Fu);
}


/** \return True if "u1" is a valid first UTF-16 character in a surrogate pair. */
inline bool IsFirstHalfOfSurrogatePair(const uint16_t u1) {
    return (u1 & 0xD800u) == 0xD800u;
}


/** \return True if "u2" is a valid second UTF-16 character in a surrogate pair. */
inline bool IsSecondHalfOfSurrogatePair(const uint16_t u2) {
    return (u2 & 0xDC00) == 0xDC00;
}


/** \return True if "u" is might be a valid single UTF-16 character, i.e. not part of a surrogate pair. */
inline bool IsValidSingleUTF16Char(const uint16_t u) {
    return (u <= 0xD7FFu) or (0xE000u <= u);
}


/** \brief Break up text into individual lowercase "words".
 *
 *  \param text             Assumed to be in UTF8.
 *  \param words            The individual words, also in UTF8.
 *  \param min_word_length  Reject chunks that are shorter than this.
 *  \return True if there were no character conversion problems, else false.
 */
bool ChopIntoWords(const std::string &text, std::unordered_set<std::string> * const words,
                   const unsigned min_word_length = 1);


/** \brief Break up text into individual lowercase "words".
 *
 *  \param text             Assumed to be in UTF8.
 *  \param words            The individual words, also in UTF8.
 *  \param min_word_length  Reject chunks that are shorter than this.
 *  \return True if there were no character conversion problems, else false.
 */
bool ChopIntoWords(const std::string &text, std::vector<std::string> * const words,
                   const unsigned min_word_length = 1);


/** \return The position at which "needle" starts in "haystack" or "haystack.cend()" if "needle"
    is not in "haystack". */
std::vector<std::string>::const_iterator FindSubstring(const std::vector<std::string> &haystack,
                                                       const std::vector<std::string> &needle);


/** \brief  Base64 encodes a string.
 *  \param  s                   The string that will be encoded.
 *  \param  symbol63            The character that will be used for symbol 63.
 *  \param  symbol64            The character that will be used for symbol 64.
 *  \param  use_output_padding  Nomen est omen.
 *  \return The encoded string.
 */
std::string Base64Encode(const std::string &s, const char symbol63 = '+', const char symbol64 = '/',
                         const bool use_output_padding = true);


/** \brief  Base64 decodes a string.
 *  \param  s         The string that will be decoded.
 *  \param  symbol63  The character that was used for symbol 63.
 *  \param  symbol64  The character that was used for symbol 64.
 *  \return The decoded string.
 */
std::string Base64Decode(const std::string &s, const char symbol63 = '+', const char symbol64 = '/');


/** \brief Replaces non-printable characters with octal C-style escapes.
 *  \param also_escape_whitespace  if true, whitespace characters tab, vertical tab, newline, space and
 *         hard space will also be escaped.
 */
std::string EscapeString(const std::string &original_string, const bool also_escape_whitespace = false);


/** \brief Escapes "value" as a comma-separated value.
 *  \param value       The UTF-8 character sequence to be encoded.
 *  \param add_quotes  If true, enclosing qotes are added about the escaped value.
 *  \return The converted (double quotes being replaced by two consecutive double quotes) value.
 *  \note Enclosing double are not included in the returned escaped value.
 */
std::string CSVEscape(const std::string &value, const bool add_quotes = true);

inline std::string CSVEscape(const unsigned value, const bool add_quotes = true)
    { return CSVEscape(std::to_string(value), add_quotes); }


/** Parses a CSV file that follows the standard specified by RFC 4180 (when "separator," and "quote" have their default values)
 *  with the exception that line breaks may be be either carriage-return/linefeed pair or just individual linefeed characters.
 */
void ParseCSVFileOrDie(const std::string &path, std::vector<std::vector<std::string>> * const lines, const char separator = ',',
                       const char quote = '"');


/** \brief Removes the final UTF-8 logical character from "*s".
 *  \return True if we succeeded and false if "*s" is empty or malformed UTF-8.
 */
bool TrimLastCharFromUTF8Sequence(std::string * const s);


bool UTF32CharIsAsciiLetter(const uint32_t ch);
bool UTF32CharIsAsciiDigit(const uint32_t ch);


class ToUTF32Decoder {
protected:
    static const std::string CANONICAL_UTF32_NAME;
    static const uint32_t NULL_CHARACTER;
public:
    enum State {
        NO_CHARACTER_PENDING, //< getUTF32Char() should not be called.
        CHARACTER_PENDING,    //< getUTF32Char() should be called to get the next character.
        CHARACTER_INCOMPLETE  //< addByte() must be called at least one more time to complete a character.
    };

    virtual ~ToUTF32Decoder() = default;

    /** Feed bytes into this until it returns false.  Then call getCodePoint() to get the translated UTF32 code
     *  point.  Then you can call this function again.
     *
     * \return True if we need more bytes to complete a UTF-8 single-code-point sequence, false if a sequence has
     *         been decoded, signalling that getUTF32Char() should be called now.
     * \throw std::runtime_error if we're being fed an invalid UTF-8 sequence of characters
     */
    virtual bool addByte(const char ch) = 0;

    virtual State getState() const = 0;

     /** Returns the UTF-32 character converted from the input sequence. Can only be called after
     *  addByte() returns false.
     *
     * \throw std::runtime_error if the character is yet to be fully decoded
     */
    virtual uint32_t getUTF32Char() = 0;

    virtual const std::string &getInputEncoding() const = 0;
};


class AnythingToUTF32Decoder : public ToUTF32Decoder {
    iconv_t converter_handle_;
    const std::string input_encoding_;
    uint32_t utf32_char_;
    std::vector<char> accum_buffer_;
    State current_state_;
    bool permissive_;
public:
    /** \param permissive  If false, we throw a std::runtime_error on encoding errors,
     *                     when attempting to accumulate before consuming a pending codepoint and
     *                     when attempting to consume a as-of-yet non-existing codepoint.
     *                     If true, we return Unicode replacement characters.
     */
    AnythingToUTF32Decoder(const std::string &input_encoding, const bool permissive = true);
    virtual ~AnythingToUTF32Decoder() override final;

    virtual bool addByte(const char ch) override final;

    virtual State getState() const override final;

    virtual uint32_t getUTF32Char() override final;

    virtual const std::string &getInputEncoding() const override final;
private:
    uint32_t consumeAndReset();
};


class UTF8ToUTF32Decoder : public ToUTF32Decoder {
    int required_count_;
    uint32_t utf32_char_;
    bool permissive_;
public:
    /** \param permissive  If false, we throw a std::runtime_error on encoding errors, if true we return Unicode replacement
     *                     characters.
     */
    UTF8ToUTF32Decoder(const bool permissive = true): required_count_(-1), permissive_(permissive) { }
    virtual ~UTF8ToUTF32Decoder() = default;

    virtual bool addByte(const char ch) override final;

    virtual State getState() const override final {
        return (required_count_ == -1) ? NO_CHARACTER_PENDING
                                       : ((required_count_  > 0) ? CHARACTER_INCOMPLETE : CHARACTER_PENDING);
    }

    virtual uint32_t getUTF32Char() override final { required_count_ = -1; return utf32_char_; }

    virtual const std::string &getInputEncoding() const override final { return EncodingConverter::CANONICAL_UTF8_NAME; }
};


/* En- and decode text to and from the encoded-printable format. */
std::string EncodeQuotedPrintable(const std::string &s);
std::string DecodeQuotedPrintable(const std::string &s);


extern const std::unordered_set<uint32_t> UNICODE_WHITESPACE;


/** \return True if "utf32_char" is one of the code points listed here: https://en.wikipedia.org/wiki/Whitespace_character,
            else false. */
inline bool IsWhitespace(const uint32_t utf32_char) {
    return UNICODE_WHITESPACE.find(utf32_char) != UNICODE_WHITESPACE.end();
}


/** \return True if "ch" is an ASCII character, i.e. if the high bit is not set, else false. */
inline bool IsASCIIChar(const char ch) { return (static_cast<unsigned char>(ch) & 0x80u) == 0; }


/** \brief Replaces any sequence of "whitespace" characters listed here: https://en.wikipedia.org/wiki/Whitespace_character
 *         to a single space (0x20) character.
 *  \return A reference to the modified string "*utf8_string".
 */
std::string &CollapseWhitespace(std::string * const utf8_string);


inline std::string CollapseWhitespace(const std::string &utf8_string) {
    std::string temp_utf8_string(utf8_string);
    return CollapseWhitespace(&temp_utf8_string);
}


/** \brief like CollapseWhitespace() but also removes leading and trailing whitespace characters.
 *  \return A reference to the modified string "*utf8_string".
 */
std::string &CollapseAndTrimWhitespace(std::string * const utf8_string);


inline std::string CollapseAndTrimWhitespace(const std::string &utf8_string) {
    std::string temp_utf8_string(utf8_string);
    return CollapseAndTrimWhitespace(&temp_utf8_string);
}


/** \return True if "ch" was successfully converted to a value in the range [0..15] else false. */
bool FromHex(const char ch, unsigned * const u);


/** \brief Converts \n, \t, \b, \r, \f, \v, \a, \\, \xnn, \uNNNN and \UNNNNNNNN and octal escape sequences to the corresponding
 *         byte sequences.
 *  \note Octal escape sequences consists of a backslash followed by one, two, or three octal digits, e,g. \1111 is the
 *        octal escape sequence \111 followed by the digit 1.
 *  \return The converted string.
 */
std::string &CStyleUnescape(std::string * const s);
inline std::string CStyleUnescape(std::string s) {
    return CStyleUnescape(&s);
}


/** \brief The counterpart to CStyleUnescape(). */
std::string &CStyleEscape(std::string * const s);


/** \brief The counterpart to CStyleUnescape(). */
inline std::string CStyleEscape(std::string s) {
    return CStyleEscape(&s);
}


/** \brief Converts the first character of "text" to uppercase and the remainder to lowercase, if possible.
 *  \note  We treat "text" as UTF-8.
 */
std::string InitialCaps(const std::string &text);


/** \brief Returns the canonical form of a charset string.
 */
std::string CanonizeCharset(std::string charset);


/** \brief Truncates "utf8_string" to a maximum length of "max_length" codepoints.
 *  \return False if conversion errors occurred, else true.
 */
bool UnicodeTruncate(std::string * const utf8_string, const size_t max_length);


inline bool IsGeneralPunctuationCharacter(const wchar_t ch) { return ch >= 0x2000 and ch <= 0x206F; }
bool IsSpaceSeparatorCharacter(const wchar_t ch);


// \return 0.0 if the texts are identical and a large score <= 1.0 if they are not.
double CalcTextSimilarity(const std::string &text1, const std::string &text2, const bool ignore_case = true);


bool IsSomeKindOfDash(const uint32_t ch);


std::wstring ExpandLigatures(const std::wstring &string);
std::string ExpandLigatures(const std::string &utf8_string);


} // namespace TextUtil
