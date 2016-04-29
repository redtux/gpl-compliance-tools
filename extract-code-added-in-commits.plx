#!/usr/bin/perl -w
# extract-code-added-in-commits.plx                                            -*- Perl -*-
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

#  This script takes as standard input a list of commit ids.  This is called
#  the "whitelisted commits" for the process.

#  The output is a series of directories for each COMMIT_ID (all placed under
#  the directory specified in $ARGV[1]).  Under each COMMIT_ID directory,
#  there is a redacted copy of the files specifically changed or added by the
#  operations perfomed in COMMIT_ID.  The redcated copy will contain only
#  lines that were added or changed in that file by any operation in the
#  "whitelisted commits".

#  Motivation for this process:

#   The idea is to create a corpus of code that we know received
#   contributions from the whitelisted commits.  Note that across the various
#   COMMIT_ID directories, there will be substantial duplication.  However,
#   the full corpus requires building but in some cases, where code has been
#   rewritten.


# Clear Flaw in this process:

# In "Estimating the Total Cost of a Linux Distribution", found at
# https://www.linuxfoundation.org/sites/main/files/publications/estimatinglinux.html,
# McPherson, Proffitt, and Hale-Evans write:

#   The biggest weakness in SLOC analysis is its focus on net additions to
#   software projects. Anyone who is familiar with kernel development, for
#   instance, realizes that the highest man-power cost in its development is
#   when code is deleted and modified. The amount of effort that goes into
#   deleting and changing code, not just adding to it, is not reflected in
#   the values associated with this estimate. Because in a collaborative
#   development model, code is developed and then changed and deleted, the
#   true value is far greater than the existing code base. Just think about
#   the process: when a few lines of code are added to the kernel, for
#   instance, many more have to be modified to be compatible with that
#   change. The work that goes into understanding the dependencies and
#   outcomes and then changing that code is not well represented in this
#   study.

# Therefore, this process, which ignores lines that are *deleted*, thus
# streamlining and improving code, ignore a fundamental tenant of software
# development: that making code smaller, more expressive, and more concise
# yeilds better designed software.  While the process herein *can* produce a
# clear list of code whose known introduction is directly attributable to the
# whitelisted commits, the analysis produced by this process does not do
# justice to the full weight of the contributions made in those whitelisted
# commits, since removed code is outright ignored in this process.

# In other words, this process measures only quantity of code written and
# fails to examine the quality of the code.

use Git::Repository 'Log';
use POSIX ":sys_wait_h";
use File::Spec;
use File::Path qw(make_path remove_tree);
use autodie qw(:all);
use POSIX qw(strftime);

if (@ARGV != 2 and @ARGV != 3 and @ARGV != 4) {
  print "usage: $0 <GIT_REPOSITORY_PATH> ", "<OUTPUT_DIRECTORY> [<FORK_LIMIT>] [<VERBOSE_LEVEL>]\n";
  exit 1;
}
my($GIT_REPOSITORY_PATH, $OUTPUT_DIRECTORY, $FORK_LIMIT, $VERBOSE) = @ARGV;
$VERBOSE = 0 if not defined $VERBOSE;
$FORK_LIMIT = 1 if not defined $FORK_LIMIT;

my $LOG_DIR = File::Spec->catfile($OUTPUT_DIRECTORY, ".logs");
remove_tree($LOG_DIR) if -d $LOG_DIR;
make_path($LOG_DIR, {mode => 0750});
die "The directory, $OUTPUT_DIRECTORY, must be a writeable directory" unless -d $OUTPUT_DIRECTORY and -w $OUTPUT_DIRECTORY;
die "The log directory, $LOG_DIR, must be a writeable directory" unless -d $LOG_DIR and -w $LOG_DIR;
##############################################################################
sub ProcessCommit($$) {
  my($commitId, $pid) = @_;
  my $logFile = File::Spec->catfile($LOG_DIR, "${commitId}.${pid}.log");
  open(LOG, ">", $logFile);
  my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
  print LOG "Started $commitId in $pid at $now\n";
  sleep 5;
  $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
  print "Finished $commitId in $pid at $now\n";
  close LOG;
}
##############################################################################
# Mainline of script

my @unfinishedCommitIds;

while (my $line = <STDIN>) {
  chomp $line;
  die "badly formatted commit ID: $line" unless $line =~ /^[a-z0-9]{40,40}$/;
  push(@unfinishedCommitIds, $line);
}

my %childProcesses;
my %finishedCommits;

$SIG{CHLD} = sub {
  # don't change $! and $? outside handler
  local ($!, $?);
  while ( (my $pid = waitpid(-1, WNOHANG)) > 0 ) {
    my($errCode, $errString) = ($?, $!);
    my $commitId = $childProcesses{$pid};
    my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
    print STDERR "Finished commit $commitId $childProcesses{$pid} in $pid ($!, $?) at $now\n" if $VERBOSE;
    $finishedCommits{$commitId} = { pid => $pid, time => $now, errCode => $errCode, errString => $errString };
    delete $childProcesses{$pid};
  }
};

foreach my $commitId (@unfinishedCommitIds) {
  while (scalar(keys %childProcesses) >=  $FORK_LIMIT) {
    print STDERR "Sleep a bit while children going for ", join(", ", sort values %childProcesses), "\n" if $VERBOSE;
    sleep 10;
  }
  my $forkCount = scalar(keys %childProcesses)  + 1;
  my $pid = fork();
  die "cannot fork: $!" unless defined $pid;
  if ($pid == 0) {
    print STDERR "Launched $forkCount child to handle $commitId\n" if $VERBOSE;
    exit 0;
  } else {
    $childProcesses{$pid} = $commitId;
    ProcessCommit($commitId, $pid);
  }
}

while (scalar(keys %childProcesses) >=  0) {
  print STDERR "Sleep a bit while children going for ", join(", ", sort values %childProcesses), "\n" if $VERBOSE;
  sleep 10;
}

my $startCnt = scalar(@unfinishedCommitIds);
my $doneCnt = scalar(keys %finishedCommits);
print STDERR "ERROR: all children completed but ", $doneCnt - $startCnt, " not completed\n";

foreach my $commitId (keys %finishedCommits) {
  print STDERR "Completed $commitId at $finishedCommits{$commitId}{time} in $finishedCommits{$commitId}{pid}\n" if $VERBOSE;
  print STDERR "ERROR: $commitId had non-zero  exit status of $finishedCommits{$commitId}{errCode} ",
    "with message \"$finishedCommits{$commitId}{errString}\"",
    " at $finishedCommits{$commitId}{now} in $finishedCommits{$commitId}{pid}\n"
    unless $finishedCommits{$commitId}{errCode} == 0;
}


# git show --pretty="format:" --name-only
# git blame  -M -M -M -C -C -C -w -f -n -l

#
# Local variables:
# compile-command: "perl -c extract-code-added-in-commits.plx"
# End:
