# API::ACL::Flags - This module holds all of sophia's ACL flags and utility functions.
# Copyright (C) 2011 Kenneth K. Sham 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package API::ACL::Flags;
use strict;
use warnings;
use Exporter;
use base qw(Exporter);

our @EXPORT_OK = qw(
    ACL_NONE ACL_VOICE ACL_AUTOVOICE ACL_OP ACL_AUTOOP
    ACL_CHANGETOPIC ACL_USEGRANT ACL_BANNED
    ACL_FRIEND ACL_ADMIN ACL_MASTER
    ACL_VOICE_ALL ACL_OP_ALL ACL_VOICE_OP
    SOPHIA_FRIEND SOPHIA_ADMIN SOPHIA_MASTER
    SOPHIA_ACL_ALL
    %ACL_FLAGS
    modify_bits convert_bits_to_flags
);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

use constant {
    ACL_NONE            => 0x0000,
    ACL_VOICE           => 0x0001,
    ACL_AUTOVOICE       => 0x0002,
    ACL_OP              => 0x0004,
    ACL_AUTOOP          => 0x0008,
    
    ACL_CHANGETOPIC     => 0x0010,
    ACL_USEGRANT        => 0x0020,
    ACL_BANNED          => 0x0040,

    ACL_FRIEND          => 0x0100,
    ACL_ADMIN           => 0x0200,
    ACL_MASTER          => 0x0400,
};

use constant ACL_VOICE_ALL              => ACL_VOICE | ACL_AUTOVOICE;
use constant ACL_OP_ALL                 => ACL_OP | ACL_AUTOOP;
use constant ACL_VOICE_OP               => ACL_VOICE_ALL | ACL_OP_ALL;

use constant SOPHIA_FRIEND              => ACL_VOICE_OP | ACL_CHANGETOPIC | ACL_USEGRANT | ACL_FRIEND;
use constant SOPHIA_ADMIN               => SOPHIA_FRIEND | ACL_ADMIN;
use constant SOPHIA_MASTER              => SOPHIA_ADMIN | ACL_MASTER;

use constant SOPHIA_ACL_ALL             => SOPHIA_MASTER;

my %ACL_FLAG_TO_BIT = (
    b   => ACL_BANNED,
    v   => ACL_VOICE,
    V   => ACL_AUTOVOICE,
    o   => ACL_OP,
    O   => ACL_AUTOOP,
    t   => ACL_CHANGETOPIC,
    s   => ACL_USEGRANT,
    f   => ACL_FRIEND,
    A   => ACL_FRIEND,
    F   => ACL_MASTER,
);

sub modify_bits {
    my ($bits, $flags) = @_;

    # get a list of flags
    my @flags = split '', $flags;

    my $dir = undef;

    # loop and assign them
    FLAG: for my $flag (@flags) {
        if ($flag eq '+') {
            $dir = 1;
            next FLAG;
        }

        if ($flag eq '-') {
            $dir = 0;
            next FLAG;
        }

        # if $dir is neither + nor -, then
        # this is an invalid flag regardless
        if (!defined $dir) {
            next FLAG;
        }

        # if the flag is '*', then set add or remove all flags
        # minus the ACL_MASTER
        if ($flag eq '*') {
            # if we are adding:
            if ($dir) {
                $bits |= ACL_ADMIN;
                next FLAG;
            }

            # otherwise, removing:
            $bits &= ~ACL_ADMIN;
            next FLAG;
        }

        # if the flag doesn't exist, skip it
        if (!defined $ACL_FLAG_TO_BIT{$flag}) {
            next FLAG;
        }

        # the flag is valid, so add/remove it
        if ($dir) {
            $bits |= $ACL_FLAG_TO_BIT{$flag};
            next FLAG;
        }

        $bits &= ~$ACL_FLAG_TO_BIT{$flag};
    }

    return $bits;
}

sub convert_bits_to_flags {
    my ($bits) = @_;
    
    # no bits?
    if (!$bits) {
        return;
    }

    my $flags;

    FLAG: for my $flag (keys %ACL_FLAG_TO_BIT) {
        # if the bits have this flag, add it to $flags
        if ($bits & $ACL_FLAG_TO_BIT{$flag}) {
            $flags .= $flag;
        }
    }

    return $flags;
}

1;
