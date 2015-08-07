#!/bin/python2
# -*- coding: utf-8 -*-
#
#    @brief  A very simple black box tester for web sites.
#    @author Dr. Johannes Ruscheinski (johannes.ruscheinski@uni-tuebingen.de)
#
#    Copyright (C) 2015, Library of the University of Tübingen
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

import re
import sys
import traceback
import urllib2
import util


DEFAULT_TIMEOUT = 20 # seconds


def RunTest(test_name, url, timeout, expected):
    if timeout is None:
        timeout = DEFAULT_TIMEOUT
    try:
        request = urllib2.Request(url, headers={"Accept-Language" : "de"})
        response = urllib2.urlopen(request, timeout=timeout)
        page_content = response.read()
        if expected is None:
            return True
        return re.match(expected, page_content, re.DOTALL) is not None
    except Exception as e:
        util.Error("Caught an exception in RunTest(): " + str(e))


def Main():
    util.default_email_sender = "black_box_monitor@ub.uni-tuebingen.de"
    util.default_email_recipient = sys.argv[1]
    config = util.LoadConfigFile()

    for section in config.sections():
        if section == "SMTPServer":
            continue
        url = config.get(section, "url")
        expected = None
        if config.has_option(section, "expected"):
            expected = config.get(section, "expected")
        timeout = None
        if config.has_option(section, "timeout"):
            timeout = config.getfloat(section, "timeout")
        if not RunTest(section, url, timeout, expected):
            util.SendEmail("Black Box Test Failed!",
                           "Test " + section + " failed!\n\n--Your friendly black box monitor",
                           "no_reply@uni-tuebingen.de")


try:
    Main()
except Exception as e:
    util.SendEmail("Black Box Monitor", "An unexpected error occurred: "
                   + str(e) + "\n\n" + traceback.format_exc(20))
