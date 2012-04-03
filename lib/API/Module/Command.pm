# API::Module::Command - A basic command for a module
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

package API::Module::Command;
use strict;
use warnings;

# fields for a Command
# a value of 1 means a required field
my %fields = (
    _hook       => {
        required        => 1,
    },
    _name       => {
        required        => 1,
    },
    _perms      => {
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
    
    # set the fields if they're in %fields
    ARG: for my $key (keys %args) {
        # if the key exists in args
        if (defined $args{$key}) {
            $self->{$key} = $args{$key};
        }
    }

    return 1;
}

sub is_valid {
    my ($self) = @_;

    # this command is valid if all
    # required fields are defined
    FIELD: for my $key (keys %fields) {
        # if this field is not required, skip it
        if (!$fields{$key}{required}) {
            next FIELD;
        }

        # if this command doesn't have this field,
        # return false
        if (!defined $self->get($key)) {
            return;
        }
    }

    return 1;
}

sub run {
    my ($self, @args) = @_;
    &{ $self->get(
}

1;

__END__
