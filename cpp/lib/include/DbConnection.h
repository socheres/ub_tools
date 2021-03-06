/** \file   DbConnection.h
 *  \brief  Interface for the DbConnection class.
 *  \author Dr. Johannes Ruscheinski (johannes.ruscheinski@uni-tuebingen.de)
 *
 *  \copyright 2015-2019 Universitätsbibliothek Tübingen.  All rights reserved.
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


#include <string>
#include <vector>
#include <mysql/mysql.h>
#ifdef MARIADB_PORT
#       define MYSQL_PORT MARIADB_PORT
#endif
#include <sqlite3.h>
#include "DbResultSet.h"
#include "MiscUtil.h"
#include "util.h"


// Forward declaration:
class IniFile;


class DbConnection {
public:
    enum Charset { UTF8MB3, UTF8MB4 };
    enum Collation { UTF8MB3_BIN, UTF8MB4_BIN };
    enum DuplicateKeyBehaviour { DKB_FAIL, DKB_IGNORE, DKB_REPLACE };
    enum OpenMode { READONLY, READWRITE, CREATE };
    enum TimeZone { TZ_SYSTEM, TZ_UTC };
    enum Type { T_MYSQL, T_SQLITE };
    enum MYSQL_PRIVILEGE { P_SELECT, P_INSERT, P_UPDATE, P_DELETE, P_CREATE, P_DROP, P_REFERENCES,
                           P_INDEX, P_ALTER, P_CREATE_TEMPORARY_TABLES, P_LOCK_TABLES, P_EXECUTE,
                           P_CREATE_VIEW, P_SHOW_VIEW, P_CREATE_ROUTINE, P_ALTER_ROUTINE,
                           P_EVENT, P_TRIGGER};
    static const std::unordered_set<MYSQL_PRIVILEGE> MYSQL_ALL_PRIVILEGES;
    static const std::string DEFAULT_CONFIG_FILE_PATH;
private:
    Type type_;
    sqlite3 *sqlite3_;
    sqlite3_stmt *stmt_handle_;
    mutable MYSQL mysql_;
    bool initialised_;
    std::string database_name_;
    std::string user_;
    std::string passwd_;
    std::string host_;
    unsigned port_;
    Charset charset_;
    TimeZone time_zone_;
public:
    explicit DbConnection(const TimeZone time_zone = TZ_SYSTEM); // Uses the ub_tools database.

    DbConnection(const std::string &database_name, const std::string &user, const std::string &passwd = "",
                 const std::string &host = "localhost", const unsigned port = MYSQL_PORT, const Charset charset = UTF8MB4,
                 const TimeZone time_zone = TZ_SYSTEM)
        { type_ = T_MYSQL; init(database_name, user, passwd, host, port, charset, time_zone); }

    // Expects to find entries named "sql_database", "sql_username" and "sql_password".  Optionally there may also
    // be an entry named "sql_host".  If this entry is missing a default value of "localhost" will be assumed.
    // Another optional entry is "sql_port".  If that entry is missing the default value MYSQL_PORT will be used.
    explicit DbConnection(const IniFile &ini_file, const std::string &ini_file_section = "Database", const TimeZone time_zone = TZ_SYSTEM);

    DbConnection(const std::string &database_path, const OpenMode open_mode);

    /** \brief Attemps to parse something like "mysql://ruschein:xfgYu8z@localhost:3345/vufind" */
    explicit DbConnection(const std::string &mysql_url, const Charset charset = UTF8MB4, const TimeZone time_zone = TZ_SYSTEM);

    virtual ~DbConnection();

    inline Type getType() const { return type_; }
    inline std::string getDbName() const { return database_name_; }
    inline std::string getUser() const { return user_; }
    inline std::string getPasswd() const { return passwd_; }
    inline std::string getHost() const { return host_; }
    inline unsigned getPort() const { return port_; }
    inline Charset getCharset() const { return charset_; }
    inline TimeZone getTimeZone() const { return time_zone_; }
    int getLastErrorCode() const;

    /** \note If the environment variable "UTIL_LOG_DEBUG" has been set "true", query statements will be
     *        logged to /usr/local/var/log/tuefind/sql_debug.log.
     */
    bool query(const std::string &query_statement);

    /** \brief Executes an SQL statement and aborts printing an error message to stderr if an error occurred.
     *  \note If the environment variable "UTIL_LOG_DEBUG" has been set "true", query statements will be
     *        logged to /usr/local/var/log/tuefind/sql_debug.log.
     */
    void queryOrDie(const std::string &query_statement);

    /** \brief Reads SQL statements from "filename" and executes them.
     *  \note  Aborts if "filename" can't be read.
     *  \note  If the environment variable "UTIL_LOG_DEBUG" has been set "true", query statements will be
     *         logged to /usr/local/var/log/tuefind/sql_debug.log.
     */
    bool queryFile(const std::string &filename);

    /** \brief Reads SQL statements from "filename" and executes them.
     *  \note  Aborts printing an error message to stderr if an error occurred.
     *  \note  If the environment variable "UTIL_LOG_DEBUG" has been set "true", query statements will be
     *         logged to /usr/local/var/log/tuefind/sql_debug.log.
     */
    void queryFileOrDie(const std::string &filename);

    /** \note Currently only works w/ Sqlite.
     *  \note Supports online backups of a running database.
     */
    bool backup(const std::string &output_filename, std::string * const err_msg);
    void backupOrDie(const std::string &output_filename);

    void insertIntoTableOrDie(const std::string &table_name, const std::map<std::string, std::string> &column_names_to_values_map,
                              const DuplicateKeyBehaviour duplicate_key_behaviour = DKB_FAIL);

    DbResultSet getLastResultSet();
    inline std::string getLastErrorMessage() const
        { return (type_ == T_MYSQL) ? ::mysql_error(&mysql_) : ::sqlite3_errmsg(sqlite3_); }

    /** \return The the number of rows changed, deleted, or inserted by the last statement if it was an UPDATE,
     *          DELETE, or INSERT.
     *  \note   Must be called immediately after calling "query()".
     */
    inline unsigned getNoOfAffectedRows() const
        { return (type_ == T_MYSQL) ? ::mysql_affected_rows(&mysql_) : ::sqlite3_changes(sqlite3_); }

    /** \note Converts the binary contents of "unescaped_string" into a form that can used as a string.
     *  \note This probably breaks for Sqlite if the string contains binary characters.
     */
    std::string escapeString(const std::string &unescaped_string, const bool add_quotes = false);
    inline std::string escapeAndQuoteString(const std::string &unescaped_string) {
        return escapeString(unescaped_string, /* add_quotes = */true);
    }

    inline void mySQLCreateDatabase(const std::string &database_name, const Charset charset = UTF8MB4,
                                    const Collation collation = UTF8MB4_BIN)
    {
        queryOrDie("CREATE DATABASE " + database_name + " CHARACTER SET " + CharsetToString(charset) + " COLLATE "
                   + CollationToString(collation) + ";");
    }

    void mySQLCreateUser(const std::string &new_user, const std::string &new_passwd, const std::string &host = "localhost") {
        queryOrDie("CREATE USER " + new_user + "@" + host + " IDENTIFIED BY '" + new_passwd + "';");
    }

    bool mySQLDatabaseExists(const std::string &database_name);

    bool tableExists(const std::string &database_name, const std::string &table_name);

    bool mySQLDropDatabase(const std::string &database_name);

    std::vector<std::string> mySQLGetDatabaseList();

    std::vector<std::string> mySQLGetTableList();

    void mySQLGrantAllPrivileges(const std::string &database_name, const std::string &database_user,
                                 const std::string &host = "localhost") {
        queryOrDie("GRANT ALL PRIVILEGES ON " + database_name + ".* TO '" + database_user + "'@'" + host + "';");
    }

    std::unordered_set<MYSQL_PRIVILEGE> mySQLGetUserPrivileges(const std::string &user, const std::string &database_name,
                                                               const std::string &host = "localhost");

    inline void mySQLSelectDatabase(const std::string &database_name) {
        ::mysql_select_db(&mysql_, database_name.c_str());
    }

    void mySQLSyncMultipleResults();

    bool mySQLUserExists(const std::string &user, const std::string &host);

    inline bool mySQLUserHasPrivileges(const std::string &database_name, const std::unordered_set<MYSQL_PRIVILEGE> &privileges,
                                const std::string &user, const std::string &host = "localhost")
    {
        return MiscUtil::AbsoluteComplement(privileges, mySQLGetUserPrivileges(user, database_name, host)).empty();
    }

    inline bool mySQLUserHasPrivileges(const std::string &database_name, const std::unordered_set<MYSQL_PRIVILEGE> &privileges) {
        return mySQLUserHasPrivileges(database_name, privileges, getUser(), getHost());
    }
private:
    /** \note This constructor is for operations which do not require any existing database.
     *        It should only be used in static functions.
     */
    DbConnection(const std::string &user, const std::string &passwd, const std::string &host, const unsigned port, const Charset charset)
        { type_ = T_MYSQL; init(user, passwd, host, port, charset, TZ_SYSTEM); }

    void setTimeZone(const TimeZone time_zone);
    void init(const std::string &database_name, const std::string &user, const std::string &passwd,
              const std::string &host, const unsigned port, const Charset charset, const TimeZone time_zone);

    void init(const std::string &user, const std::string &passwd, const std::string &host, const unsigned port, const Charset charset,
              const TimeZone time_zone);
public:
    static std::string CharsetToString(const Charset charset);

    static std::string CollationToString(const Collation collation);

    static void MySQLCreateDatabase(const std::string &database_name, const std::string &admin_user, const std::string &admin_passwd,
                                    const std::string &host = "localhost", const unsigned port = MYSQL_PORT,
                                    const Charset charset = UTF8MB4, const Collation collation = UTF8MB4_BIN)
    {
        DbConnection db_connection(admin_user, admin_passwd, host, port, charset);
        db_connection.mySQLCreateDatabase(database_name, charset, collation);
    }

    static void MySQLCreateUser(const std::string &new_user, const std::string &new_passwd, const std::string &admin_user,
                                const std::string &admin_passwd, const std::string &host = "localhost", const unsigned port = MYSQL_PORT,
                                const Charset charset = UTF8MB4)
    {
        DbConnection db_connection(admin_user, admin_passwd, host, port, charset);
        db_connection.mySQLCreateUser(new_user, new_passwd, host);
    }

    static bool MySQLDatabaseExists(const std::string &database_name, const std::string &admin_user, const std::string &admin_passwd,
                                    const std::string &host = "localhost", const unsigned port = MYSQL_PORT,
                                    const Charset charset = UTF8MB4)
    {
        DbConnection db_connection(admin_user, admin_passwd, host, port, charset);
        return db_connection.mySQLDatabaseExists(database_name);
    }

    static bool MySQLDropDatabase(const std::string &database_name, const std::string &admin_user, const std::string &admin_passwd,
                                  const std::string &host = "localhost", const unsigned port = MYSQL_PORT,
                                  const Charset charset = UTF8MB4)
    {
        DbConnection db_connection(admin_user, admin_passwd, host, port, charset);
        return db_connection.mySQLDropDatabase(database_name);
    }

    static std::vector<std::string> MySQLGetDatabaseList(const std::string &admin_user, const std::string &admin_passwd,
                                                         const std::string &host = "localhost", const unsigned port = MYSQL_PORT,
                                                         const Charset charset = UTF8MB4)
    {
        DbConnection db_connection(admin_user, admin_passwd, host, port, charset);
        return db_connection.mySQLGetDatabaseList();
    }

    static void MySQLGrantAllPrivileges(const std::string &database_name, const std::string &database_user, const std::string &admin_user,
                                        const std::string &admin_passwd, const std::string &host = "localhost",
                                        const unsigned port = MYSQL_PORT, const Charset charset = UTF8MB4)
    {
        DbConnection db_connection(admin_user, admin_passwd, host, port, charset);
        return db_connection.mySQLGrantAllPrivileges(database_name, database_user, host);
    }

    static bool MySQLUserExists(const std::string &database_user, const std::string &admin_user, const std::string &admin_passwd,
                                const std::string &host = "localhost", const unsigned port = MYSQL_PORT,
                                const Charset charset = UTF8MB4)
    {
        DbConnection db_connection(admin_user, admin_passwd, host, port, charset);
        return db_connection.mySQLUserExists(database_user, host);
    }

    /** \note This function will enable "multiple statement execution support".
     *        To avoid problems with other operations, this function should always create a new connection which is not reusable.
     */
    static void MySQLImportFile(const std::string &sql_file, const std::string &database_name, const std::string &admin_user,
                                const std::string &admin_passwd, const std::string &host = "localhost", const unsigned port = MYSQL_PORT,
                                const Charset charset = UTF8MB4);
};


/** \brief Represents a database transaction.
 *  \note  Restores the autocommit state after going out of scope.
 *  \note  Cannot be nested at this time.
 */
class DbTransaction final {
    static unsigned active_count_;
    DbConnection &db_connection_;
    bool autocommit_was_on_;
    bool rollback_when_exceptions_are_in_flight_;
public:
    /** \param rollback_when_exceptions_are_in_flight  If true, the destructor issue a ROLLBACK instead of a commit if
     *         current thread has a live exception object derived from std::exception.
     */
    explicit DbTransaction(DbConnection * const db_connection, const bool rollback_when_exceptions_are_in_flight = true);
    ~DbTransaction();
};
