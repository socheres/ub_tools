/** \file   DbConnection.h
 *  \brief  Interface for the DbConnection class.
 *  \author Dr. Johannes Ruscheinski (johannes.ruscheinski@uni-tuebingen.de)
 *
 *  \copyright 2015 Universitätsbiblothek Tübingen.  All rights reserved.
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
#ifndef DB_CONNECTION_H
#define DB_CONNECTION_H


#include <string>
#include <mysql/mysql.h>
#include "DbResultSet.h"


class DbConnection {
    mutable MYSQL mysql_;
    bool initialised_;
public:
    DbConnection(const std::string &database_name, const std::string &user, const std::string &passwd = "",
		 const std::string &host = "localhost", const unsigned port = MYSQL_PORT);
    
    virtual ~DbConnection();

    bool query(const std::string &query_statement) { return ::mysql_query(&mysql_, query_statement.c_str()) == 0; }
    DbResultSet getLastResultSet();
    std::string getLastErrorMessage() const { return ::mysql_error(&mysql_); }

    /** Converts the binary contents of "unescaped_string" into a form that can used as a string (you still
	need to add quotes around it) in SQL statements. */
    std::string escapeString(const std::string &unescaped_string);
};


#endif // ifndef DB_CONNECTION_H
