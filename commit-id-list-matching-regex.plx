#!/usr/bin/perl -w
# commit-id-list-matching-regex.plx                                            -*- Perl -*-
#
# Copyright (C) 2016 Bradley M. Kuhn <bkuhn@ebb.org>
#
# This software's license gives you freedom; you can copy, convey,
# propogate, redistribute and/or modify this program under the terms of
# the GNU  General Public License (GPL) as published by the Free
# Software Foundation (FSF), either version 3 of the License, or (at your
# option) any later version of the GPL published by the FSF.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program in a file in the toplevel directory called
# "GPLv3".  If not, see <http://www.gnu.org/licenses/>.
#
# Motivation for this script:

#  The goal in this script is to take a large Git repostiory and find a
#  simple list of all commit ids that match certain criteria, specifically,
#  either an Author: field or


#  The initial implementation looks


use Git::Repository 'Log';

if (@ARGV != 2) {
  print "usage: $0 <GIT_REPOSITORY_PATH> ", "<NAME_REGEX>\n";
  exit 1;
}
my($GIT_REPOSITORY_PATH, $NAME_REGEX) = @ARGV;

my $gitRepository = Git::Repository->new(git_dir => $GIT_REPOSITORY_PATH);

my $logIterator = $gitRepository->log();
while ( my $gitLog = $logIterator->next() ) {
  print ref $gitLog, "\n";
}

#
# Local variables:
# compile-command: "perl -c commit-id-list-matching-regex.plx"
# End:
