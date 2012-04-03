# API::ACL - The basic core structure of an ACL system for an instance of sophia.
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

package API::ACL;
use strict;
use warnings;
use API::ACL::GroupList;
use API::ACL::UserList;

sub new {
    my ($class) = @_;
    my $self = {
        _groups     => API::ACL::GroupList->new,
        _users      => API::ACL::UserList->new,
        _host2uid   => {},
    };
    bless $self, $class;
    return $self;
}

sub get {
    my ($self, $key) = @_;
    
    # if the key value doesn't exist
    # or isn't defined, return nothing
    if (!defined $self->{$key}) {
        return;
    }

    return $self->{$key};
}

1;
