# API::ACL::Channel - represents a sophia ACL Channel object.
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

package API::ACL::Channel;
use strict;
use warnings;
use API::ACL::Flags qw(ACL_NONE modify_bits);

# The fields. A value of 1 means
# that the field is required for
# the Channel to be valid
my %fields = (
    _access     => {
        default         => ACL_NONE,
        required        => 1,
    },
    _metadata   => {
        default         => {},
        required        => 1,
        type            => 'HASHREF',
    },
    _name       => {
        required        => 1,
    },
);

sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;

    # set the defaults and args
    $self->_default();
    $self->set(%args);

    return $self;
}

sub _default {
    my ($self) = @_;

    # set all the default values in %fields
    FIELD: for my $key (keys %fields) {
        # if this field has a default value, set it
        if (defined $fields{$key}{default}) {
            $self->{$key} = $fields{$key}{default};
        }
    }

    return 1;
}

sub get {
    my ($self, $key) = @_;

    # if key isn't defined, return
    if (!defined $self->{$key}) {
        return;
    }

    return $self->{$key};
}

sub set {
    my ($self, %args) = @_;
    
    # set the fields if they're in %fields
    ARG: for my $key (keys %args) {
        # if the key exists in args
        if (defined $args{$key}) {
            $self->{$key} = $args{$key};
        }
    }

    return 1;
}

sub set_metadata {
    my ($self, %args) = @_;

    # the metadata field is a hash. If it's not, set it now
    my $metadata = $self->get('_metadata');
    my $field = $fields{_metadata};
    if (!defined $metadata || ref $metadata ne $field{type}) {
        $self->set(_metadata => $field{default});

        # update metadata
        $metadata = $self->get('_metadata');
    }

    # update the metadata
    METADATA: for my $key (keys %args) {
        $metadata->{$key} = $args{$key};
    }

    return 1;
}

sub update_access {
    my ($self, $flags) = @_;

    # if access is not set, set it
    if (!defined $self->get('_access')) {
        $self->set(_access => $fields{_access}{default});
    }

    # update flags
    my $modified_bits = modify_bits($self->get('_access'), $flags);
    $self->set(_access => $modified_bits);

    return 1;
}

sub is_valid {
    my ($self) = @_;

    # this channel is valid if all
    # required fields are defined
    FIELD: for my $key (keys %fields) {
        # if this field is not required, skip it
        if (!$fields{$key}{required}) {
            next FIELD;
        }

        # if this channel doesn't have this field,
        # return false
        if (!defined $self->get($key)) {
            return;
        }
    }

    return 1;
}

1;
