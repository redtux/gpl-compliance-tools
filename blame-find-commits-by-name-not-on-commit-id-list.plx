#!/usr/bin/perl -w
# blame-count-lines-by-name-and-commit-list.plx                                            -*- Perl -*-
#
# Copyright (C) 2011, 2012 Bradley M. Kuhn <bkuhn@ebb.org>
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

use strict;
use warnings;

my $VERBOSE = 0;

######################################################################


if (@ARGV != 3) {
  print "usage: $0 <BLAME_DATA_FILE> ", "<NAME_REGEX> <KNOWN_COMMIT_ID_LIST_FILE>\n";
  exit 1;
}
# Note: $BLAME_DATA_FILE is in the format as output from:
# for i in `find -type f -print | egrep -v '^./.git'`; do
#      echo "FILE: $i" >> ../DATA_FILE; git blame  -M -M -M -C -C -C -w -f -n -l $i >> ../DATA_FILE
#      done

my($BLAME_DATA_FILE, $NAME_REGEX, $KNOWN_COMMIT_ID_LIST_FILE) = @ARGV;

open(KNOWN_COMMIT_IDS, "<", $KNOWN_COMMIT_ID_LIST_FILE) or die "unable to open $KNOWN_COMMIT_ID_LIST_FILE: $!";

my %knownCommitIDs;

while (my $commitLine = <KNOWN_COMMIT_IDS>) {
  die "invalid line in $KNOWN_COMMIT_ID_LIST_FILE: $commitLine"
    unless $commitLine =~ /^\s*(\S+)\s*$/;
  $knownCommitIDs{$1} = $KNOWN_COMMIT_ID_LIST_FILE;
}
close KNOWN_COMMIT_IDS;
die "error($?) closing $KNOWN_COMMIT_ID_LIST_FILE: $!" unless $? == 0;

open(DATA_FILE, "<", $BLAME_DATA_FILE) or die "unable to open $BLAME_DATA_FILE for reading: $!";

my %commitsMatchingRegex;
my $currentFile;
my $overalTotalLines = 0;

my %missingCommits;

print "LINES FOUND IN $BLAME_DATA_FILE that are on $KNOWN_COMMIT_ID_LIST_FILE: and match $NAME_REGEX:\n" if $VERBOSE;
while (my $dataLine = <DATA_FILE>) {
  if ($dataLine =~ /^\s*FILE\s*:\s*(.*?)\s*$/) {
    $currentFile = $1;
  } else {
    die "invalid line: $dataLine in blame output" unless ($dataLine =~
      /^\s*(\S+)\s+\S+\s+\d+\s+\((.+)\s+(\d{4,4}\-\d{2,2}\-\d{2,2}\s+\d{2,2}:\d{2,2}:\d{2,2})\s+([\+\-\d]+)\s+(\d+)\s*\)\s+(.*)$/);
    my($commitID, $name, $date, $tz, $curLineNumber, $actualCurrentLine) = ($1, $2, $3, $4, $5, $6);
    next if $currentFile =~ /ChangeLog/i;  # Ignore the changelog, as that may just be a dump
                                           # from the revision history.
    if ($name =~ /$NAME_REGEX/i and not defined $knownCommitIDs{$commitID}) {
      $missingCommits{$commitID} = $currentFile;
    }
  }
}
close DATA_FILE;

foreach my $commitId (sort keys %missingCommits) {
  print $commitId, "\n";
}


#
# Local variables:
# compile-command: "perl -c blame-find-commits-by-name-not-on-commit-id-list.plx"
# End:
