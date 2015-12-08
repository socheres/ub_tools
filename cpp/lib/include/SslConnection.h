/** \file    SslConnection.h
 *  \brief   Implements class SslConnection.
 *  \author  Dr. Johannes Ruscheinski
 */

/*
 *  Copyright 2007 Project iVia.
 *  Copyright 2007 The Regents of The University of California.
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

#ifndef SSL_CONNECTION_H
#define SSL_CONNECTION_H


#include <list>
#include <mutex>
#include <cstdlib>
#include <openssl/ssl.h>


/** \class  SslConnection
 *  \brief  Represents an SSL connection.
 */
class SslConnection {
public:
	enum Method { SSL_V2, SSL_V3, TLS_V1, ALL_METHODS /* Meaning SSLv2, SSLv3 and TLSv1. */ };
	enum ClientServerMode { CLIENT, SERVER, CLIENT_AND_SERVER };
	enum ThreadingSupportMode { SUPPORT_MULTITHREADING, DO_NOT_SUPPORT_MULTITHREADING };
private:
	ThreadingSupportMode threading_support_mode_;
	SSL_CTX *ssl_context_;
	SSL *ssl_connection_;
	int last_ret_val_;

	static std::mutex mutex_;
	static bool ssl_libraries_have_been_initialised_;
public:
	struct ContextInfo {
		Method method_;
		ClientServerMode client_server_mode_;
		SSL_CTX *ssl_context_;
		unsigned usage_count_;
	public:
		ContextInfo(const Method method, const ClientServerMode client_server_mode)
		    : method_(method), client_server_mode_(client_server_mode), ssl_context_(nullptr), usage_count_(1) { }
	};
private:
	static std::list<ContextInfo> context_infos_;
public:
	explicit SslConnection(const int fd, const Method method = ALL_METHODS, const ClientServerMode client_server_mode = CLIENT,
			       const ThreadingSupportMode threading_support_mode = DO_NOT_SUPPORT_MULTITHREADING );
	~SslConnection();
	ssize_t read(void * const data, size_t data_size);
	ssize_t write(const void * const data, size_t data_size);
	int getLastErrorCode() const;
private:
	SslConnection(const SslConnection &rhs);                  // Intentionally unimplemented!
	const SslConnection &operator=(const SslConnection &rhs); // Intentionally unimplemented!
	static SSL_CTX *InitContext(const Method method, const ClientServerMode client_server_mode);
	static void ReleaseContext(const SSL_CTX * const ssl_context);
	static SSL_CTX *InitClient(const Method method);
	static SSL_CTX *InitServer(const Method method);
	static SSL_CTX *InitClientAndServer(const Method method);
};


#endif // ifndef SSL_CONNECTION_H
