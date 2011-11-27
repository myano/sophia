# API::ACL::UserList - represents a list of API::ACL::User
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

package API::ACL::UserList;
use strict;
use warnings;
use Util::String qw(trim);

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub get {
    my ($self, $username) = @_;
    $username = lc trim($username);

    # if the username doesn't exist, return nothing
    if (!defined $self->{$username}) {
        return;
    }

    # return the user
    return $self->{$username};
}

sub add {
    my ($self, $user) = @_;

    # if $user isn't an API::ACL::User, then do nothing
    if (!ref $user || ref $user ne 'API::ACL::User') {
        return;
    }

    # if the user is not valid, meaning not all
    # required fields are defined, then do nothing
    if (!$user->is_valid()) {
        return;
    }

    # if this user already exist, do nothing
    if (defined $self->find_user($user)) {
        return;
    }

    # add the user
    my $username = lc trim($user->get('_name'));
    $self->{$username} = $user;

    return 1;
}

sub del {
    my ($self, $username) = @_;
    $username = lc trim($username);

    # if the username doesn't exist, do nothing
    if (!defined $self->get($username)) {
        return;
    }

    # remove the user
    delete $self->{$username};

    return 1;
}

sub find_user {
    my ($self, $user) = @_;

    # if the user doesn't exist, return nothing
    my $username = $user->get('_name');
    if (!defined $self->get($username)) {
        return;
    }

    # return the user
    return $self->get($username);
}

sub update_index {
    my ($self, $old, $new) = @_;
    $old = lc trim($old);
    $new = lc trim($new);

    # if the old index doesn't exist, do nothing
    if (!defined $self->get($old)) {
        return;
    }

    # if the new index already exists, do nothing
    if (defined $self->get($new)) {
        return;
    }

    # set the new index value
    $self->{$new} = $self->get($old);

    # delete the old name
    $self->del($old);

    return 1;
}

1;
