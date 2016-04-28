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



#
# Local variables:
# compile-command: "perl -c extract-code-added-in-commits.plx"
# End:
