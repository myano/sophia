# API::ACL::ChannelList - represents a list of API::ACL::Channel
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

package API::ACL::ChannelList;
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
    my ($self, $channel_name) = @_;
    $channel_name = lc trim($channel_name);

    # if channel name doesn't exit, do nothing
    if (!defined $self->{$channel_name}) {
        return;
    }

    return $self->{$channel_name};
}

sub add {
    my ($self, $channel) = @_;

    # if channel isn't a API::ACL::Channel, then do nothing
    if (!ref $channel || ref $channel ne 'API::ACL::Channel') {
        return;
    }

    # if the channel isn't valid, don't add it.
    # The channel object must have all required
    # fields for it to be considered valid
    if (!$channel->is_valid()) {
        return;
    }

    # if the channel is already in the list,
    # don't add (test is case-insensitive)
    my $channel_name = lc trim($channel->get('_name'));

    if (defined $self->find_channel($channel_name)) {
        return;
    }

    # add the group
    $self->{$channel_name} = $channel;
    
    return 1;
}

sub del {
    my ($self, $channel_name) = @_;
    $channel_name = lc trim($channel_name);
    
    # if the channel doesn't exist, can't delete
    if (!defined $self->find_channel($channel_name)) {
        return;
    }

    # delete it
    delete $self->{$channel_name};

    return 1;
}

sub find_channel {
    my ($self, $channel) = @_;

    # if channel isn't a channel obj, then do nothing
    if (!ref $channel || ref $channel ne 'API::ACL::Channel') {
        return;
    }

    $channel_name = lc trim($channel->get('_name'));

    # if the channel_name does exist, return it
    if (!defined $self->get($channel_name)) {
        return;
    }

    # return the channel object
    return $self->get($channel_name);
}

sub rename {
    my ($self, $old, $new) = @_;
    $old = lc trim($old);
    $new = lc trim($new);

    # if old index doesn't exist, do nothing
    if (!defined $self->find_channel($old)) {
        return;
    }

    # if the new index already exist, do nothing
    if (defined $self->find_channel($new)) {
        return;
    }

    # map the old channel to new name
    $self->{$new} = $self->find_channel($old);

    # delete the old
    $self->del($old);

    return 1;
}

1;
