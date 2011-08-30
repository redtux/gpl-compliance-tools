#!/usr/bin/perl -w
# blame-counter.plx                                            -*- Perl -*-
#
# Copyright (C) 2011 Bradley M. Kuhn <bkuhn@ebb.org>
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

######################################################################


if (@ARGV != 3) {
  print "usage: $0 <DATA_FILE> ",
        "<ALL_COMMITS_IN_PERIOD_OF_INTEREST> <CONFIRMED_COMMITS>\n";
  exit 1;
}
# Note: $DATA_FILE is in the format as output from:
# for i in `find -type f -print | egrep -v '^./.git'`; do
#      echo "FILE: $i" >> ../DATA_FILE; git blame  -M -M -M -C -C -C -w -f -n -l $i >> ../DATA_FILE
#      done

my($DATA_FILE, $COMMITS_IN_RANGE_FILE, $CONFIRMED_COMMITS_FILE) = @ARGV;


sub ReadCommitsFile ($) {
  my($file) = @_;

  open(COMMITS_FILE, "<", $file) or die "unable to pen $file for reading: $!";

  my %commits;
  while (my $line = <COMMITS_FILE>) {
    chomp $line;
    die "strange commit ID, $line, found in $file" unless $line =~ /^[a-f0-9]+$/;
    $commits{$line} = $file;
  }
  close COMMITS_FILE;
  return \%commits;
}

my $commitsInRange = ReadCommitsFile($COMMITS_IN_RANGE_FILE);

my $confirmedCommits = ReadCommitsFile($CONFIRMED_COMMITS_FILE);



open(DATA_FILE, "<", $DATA_FILE) or die "unable to open $DATA_FILE for reading: $!";

my %data;
my $currentFile;

while (my $dataLine = <DATA_FILE>) {
  if ($dataLine =~ /^\s*FILE\s*:\s*(.*?)\s*$/) {
    $currentFile = $1;
    $data{$currentFile} = { commitsInRange => 0, confirmedCommits => 0 };
  } else {
    die "invalid line: $dataLine in blame output" unless ($dataLine =~
      /^\s*(\S+)\s+\S+\s+\d+\s+\((.+)\s+(\d{4,4}\-\d{2,2}\-\d{2,2}\s+\d{2,2}:\d{2,2}:\d{2,2})\s+([\+\-\d]+)\s+(\d+)\s*\)\s+(.*)$/);
    my($commitID, $name, $date, $tz, $curLineNumber, $actualCurrentLine) = ($1, $2, $3, $4, $5, $6);

    if (defined $commitsInRange->{$commitID}) {
      $data{$currentFile}{commitsInRange}++;
      if (defined $confirmedCommits->{$commitID}) {
        $data{$currentFile}{confirmedCommits}++;
    }

    }
  }
}
close DATA_FILE;
foreach my $file (sort { $data{$b}{confirmedCommits} <=> $data{$a}{confirmedCommits} }
                  keys %data) {
  next if $data{$file}{commitsInRange} == 0 or  $data{$file}{confirmedCommits} == 0;

  print sprintf("%6d lines confirmed in %38s:  (%6d in range), making %6.2f%% of file from confirmed list\n",
    $data{$file}{confirmedCommits}, $file, $data{$file}{commitsInRange},
($data{$file}{confirmedCommits} / $data{$file}{commitsInRange}) * 100.00);
}
#
# Local variables:
# compile-command: "perl -c blame-counter.plx"
# End:
