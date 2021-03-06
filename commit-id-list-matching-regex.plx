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
#  either an Author: field or if they are mentioned in the patch.

#  The recommended ATTRIBUTING_LOG_MESSAGE_REGEX is something like this:

#       (Submitted\s+by|original\s+patch|patch\s+(from|by)|originally\s+(from|by)).*

#  The idea is this: It's quite common in older times for someone to commit
#  on behalf of someone else, where the Author: field reads a particular
#  author, but the log message says that someone else wrote it.  We're
#  looking for a specific author, but we want to eliminate those commits
#  where that Author attributed them to someone else, and include those
#  commits where someone else indicated that our sought author actually wrote
#  the patch.

use Git::Repository 'Log';

if (@ARGV != 3 and @ARGV != 2 and @ARGV != 4) {
  print "usage: $0 <GIT_REPOSITORY_PATH> ", "<AUTHOR_NAME_REGEX> [<ATTRIBUTING_LOG_MESSAGE_REGEX>] [<VERBOSE_LEVEL>]\n";
  exit 1;
}
my($GIT_REPOSITORY_PATH, $AUTHOR_NAME_REGEX, $ATTRIBUTING_LOG_MESSAGE_REGEX, $VERBOSE) = @ARGV;
$VERBOSE = 0 if not defined $VERBOSE;

my $gitRepository = Git::Repository->new(git_dir => $GIT_REPOSITORY_PATH);

my $logIterator = $gitRepository->log();
while ( my $gitLog = $logIterator->next() ) {
  my $author = $gitLog->author();
  my $message = $gitLog->message();
  my $includeThis = 0;
  if ($author =~ /$AUTHOR_NAME_REGEX/im) {
    # Include all Author: lines of our author, but not if they attributed to
    # someone other than the Author in question
    $includeThis = 1 unless (defined $ATTRIBUTING_LOG_MESSAGE_REGEX
                             and $message =~ /$ATTRIBUTING_LOG_MESSAGE_REGEX/im
                             and $message !~ /$ATTRIBUTING_LOG_MESSAGE_REGEX$AUTHOR_NAME_REGEX/im);
  } elsif (defined $ATTRIBUTING_LOG_MESSAGE_REGEX and $message =~ /$ATTRIBUTING_LOG_MESSAGE_REGEX$AUTHOR_NAME_REGEX/im) {
    $includeThis = 1;
  }
  if ($includeThis) {
    print STDERR "Including: ", $gitLog->commit(), "\n", "Author: $author", "\n\n", $message,  "#" x 72, "\n"
      if $VERBOSE;
    print $gitLog->commit(), "\n";
  }
}

#
# Local variables:
# compile-command: "perl -c commit-id-list-matching-regex.plx"
# End:
