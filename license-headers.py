#!/usr/bin/env python
#
# Copyright (c) 2011 Free Software Foundation, Inc.
# Written by Brett Smith <brett@fsf.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This program recursively greps the current directory for things that
# look like license statements, and then prints out a report about
# which files have which statements.  This is useful for picking
# through a project that has standard license boilerplate on most
# files, but a few exceptions; it's easy to pick out the oddballs with
# the report.

# Ideas for improvement:
# * Better output formatting.  Sort by frequency.
# * Modify the grep options with command line arguments.
# * Smarter logic about what makes a license statement.  Something to make
#   this less sensitive to line wrapping issues and things like that.

import subprocess

class LicenseFilenameMismatch(Exception):
    pass


class LicenseData(object):
    def add_line(self, line):
        current_filename = getattr(self, 'filename', None)
        filename, text = line.split('\0')
        if current_filename is None:
            self.filename = filename
            self.text = [text]
        elif current_filename == filename:
            self.text.append(text)
        else:
            raise LicenseFilenameMismatch
        

class LicenseFiler(object):
    def __init__(self):
        self.licenses = {}
        self.process = subprocess.Popen(['grep', '-Zir', 'license', '.'],
                                        stdout=subprocess.PIPE)
        self.parse_grep()

    def save_license(self, license):
        if not getattr(license, 'text', None):
            return
        filenames = self.licenses.setdefault(tuple(license.text), set())
        filenames.add(license.filename)

    def parse_grep(self):
        current_license = LicenseData()
        for line in self.process.stdout:
            try:
                current_license.add_line(line)
            except LicenseFilenameMismatch:
                self.save_license(current_license)
                current_license = LicenseData()
                current_license.add_line(line)
        self.save_license(current_license)
        self.process.stdout.close()
        self.process.wait()
        
    def report(self):
        for text, filenames in self.licenses.items():
            print "".join(text)
            print "\n".join(("\t" + fn for fn in filenames))
            print


def main(args):
    filer = LicenseFiler()
    filer.report()

if __name__ == '__main__':
    main([])
