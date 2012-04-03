# API::ACL::GroupList - represents a list of API::ACL::Group.
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

package API::ACL::GroupList;
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
    my ($self, $group_name) = @_;
    $group_name = lc trim($group_name);

    # if the group name doesn't exist, return nothing
    if (!defined $self->{$group_name}) {
        return;
    }

    # return the group
    return $self->{$group_name};
}

sub add {
    my ($self, $group) = @_;

    # if $group isn't an API::ACL::Group, then do nothing
    if (!ref $group || ref $group ne 'API::ACL::Group') {
        return;
    }

    # if the group is not valid, meaning it does not
    # have the minimal required fields, then don't add the group
    if (!$group->is_valid()) {
        return;
    }

    # if the group already exist, do nothing
    if (defined $self->find_group($group)) {
        return;
    }

    # add the group
    my $group_name = lc trim($group->get('_name'));
    $self->{$group_name} = $group;

    return 1;
}

sub del {
    my ($self, $group_name) = @_;
    $group_name = lc trim($group_name);

    # if there are no groups by that name,
    # do nothing
    if (!defined $self->get($group_name)) {
        return;
    }

    # remove the group
    delete $self->{$group_name};

    return 1;
}

sub find_group {
    my ($self, $group) = @_;

    # if the group doesn't exist, return
    my $group_name = $group->get('_name');
    if (!defined $self->get($group_name)) {
        return;
    }

    # return the group object
    return $self->get($group_name);
}

sub update_index {
    my ($self, $old, $new) = @_;
    $old = lc trim($old);
    $new = lc trim($new);

    # if old index doesn't exist, do nothing
    if (!defined $self->get($old)) {
        return;
    }

    # if new index already exists, do nothing
    if (defined $self->get($new)) {
        return;
    }

    # map the new name to the old value
    $self->{$new} = $self->get($old);

    # delete the old name
    $self->del($old);

    return 1;
}

1;
