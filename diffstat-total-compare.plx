#!/usr/bin/perl -w
# diffstat-total-compare.plx                                         -*- Perl -*-

# Copyright (C) 2013 Bradley M. Kuhn <bkuhn@ebb.org>
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

# The problem this script is trying to solve:

#   You have a source release separated from the a git repository.
#   Non-hypothetical example: a CCS release from a GPL compliance source dump
#   from a cmopany.
#   You want to know the git revision it's closest to.
#   Well, the only way I've found to solve this problem is this way:

#   build a list of commit ids that are the candidates for the base revision
#   for this sort release, and put them in commit-list, one per line, and run:

#   for i in `cat commit-list `; do
#       echo Doing $i
#       git checkout -q $i; diff -wB -N -x .git -ru . /path/to/source/release > /path/to/diffs/${i}.log
#       cat /path/to/diffs/${i}.log |diffstat > /path/to/diffs//${i}.diffstat
#       rm /path/to/diffs/${i}.log
#       echo Done $i
#    done

# Then, this script is run across that directory.

my %commitTotals;
for my $file (<*.diffstat>) {
  my $commitID = $file;
  $commitID =~ s/\.diffstat$// or die "$file isn't ending in .diffstat, huh?";
  my %commit;
  open(DIFFSTAT, "<", $file) or die "unable to open $file for reading: $!";
  while (my $line = <DIFFSTAT>) {
    if ($line =~ /^\s*(\d+)\s*files\s+changed\s*,\s*(\d+)\s*insertion[^\d]+\s+(\d+)\s*deletion.*$/) {
      ($commit{files}, $commit{insertions}, $commit{deletions}) = ($1, $2, $3);
      last;
    }
  }
  die "unable to find diffstat summary line in $file"
    unless defined $commit{files} and defined $commit{insertions} 
      and defined $commit{deletions};
  close DIFFSTAT;    die "error reading $file: $!" unless ($? == 0);
  $commitTotals{$commitID} = \%commit;
}

foreach my $type (qw/files insertions deletions/) {
  print "Sorted by $type:\n";
  foreach my $commitID (
        sort { $commitTotals{$a}{$type} <=> $commitTotals{$b}{$type} }
                        keys %commitTotals) {
    print "     $commitID $commitTotals{$commitID}{$type}\n";
  }
}

#
# Local variables:
# compile-command: "perl -c diffstat-total-compare.plx"
# End:
