# API::ACL::Group - represents a sophia ACL Group
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

package API::ACL::Group;
use strict;
use warnings;
use API::ACL::ChannelList;
use API::ACL::Flags qw(ACL_NONE modify_bits);
use API::ACL::UserList;
use Util::String qw(empty trim);

# the fields for a Group.
# a value of 1 means required.
my %fields = (
    _chanacs      => {
        required        => 0,
        type            => 'API::ACL::ChannelList',
    },
    _founder      => {
        required        => 1,
    },
    _globalacs    => {
        default         => ACL_NONE,
        required        => 1,
    },
    _metadata     => {
        default         => {},
        required        => 0,
        type            => 'HASHREF',
    },
    _name         => {
        required        => 1,
    },
    _users        => {
        required        => 0,
        type            => 'API::ACL::UserList',
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
    
    # if the key value doesn't exist
    # or isn't defined, return nothing
    if (!defined $self->{$key}) {
        return;
    }
    
    return $self->{$key};
}

sub set {
    my ($self, %args) = @_;

    # set the values, but only if it's in %fields.
    # It's stupid to go through %args, which can hold crap
    FIELD: for my $key (keys %fields) {
        # if args has this field, set it
        if (exists $args{$key}) {
            $self->{$key} = $args{$key};
        }
    }

    return 1;
}

sub add_channel {
    my ($self, $channel) = @_;

    # if the chanacs is not set up, do it
    # chanacs should also be a 'API::ACL::ChannelList'
    my $chanacs = $self->get('_chanacs');
    if (!defined $chanacs || ref $chanacs ne $fields{_chanacs}{type}) {
        $self->set(_chanacs => API::ACL::ChannelList->new);
        
        # update chanacs
        $chanacs = $self->get('_chanacs');
    }

    # if the channel name already exists in chanacs, do nothing
    if (defined $chanacs->find_channel($channel)) {
        return;
    }

    # add the channel to the list
    $chanacs->add($channel);

    return 1;
}

sub del_channel {
    my ($self, $channel_name) = @_;
    
    # if the chanacs is not set up or
    # if the chanacs is not a 'API::ACL::ChannelList'
    # do nothing
    my $chanacs = $self->get('_chanacs');
    if (!defined $chanacs || ref $chanacs ne $fields{_chanacs}{type}) {
        return;
    }

    # if the channel name doesn't exist, do nothing
    if (!defined $chanacs->get($channel_name)) {
        return;
    }

    # delete the channel from chanacs
    $chanacs->del($channel_name);

    return 1;
}

sub add_user {
    my ($self, $user) = @_;

    # if the users is not set up or
    # if it's not an 'API::ACL::UserList'
    # then set it up now
    my $userlist = $self->get('_users');
    if (!defined $userlist || ref $userlist ne $fields{_users}{type}) {
        $self->set(_users => API::ACL::UserList->new);

        # update the userlist
        $userlist = $self->get('_users');
    }

    # if the user already exist, do nothing
    if (defined $userlist->find_user($user)) {
        return;
    }

    # add the user
    $userlist->add($user);

    return 1;
}

sub del_user {
    my ($self, $username) = @_;

    # if the users list isn't an API::ACL::UserList, do nothing
    my $userlist = $self->get('_users');
    if (!defined $userlist || ref $userlist ne $fields{_users}{type}) {
        return;
    }

    # if the user doesn't exist, do nothing
    if (!defined $userlist->get($username)) {
        return;
    }

    # delete the user from the userlist
    $userlist->del($username);

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
        $metadata = $field{default};
    }

    # update the metadata
    METADATA: for my $key (keys %args) {
        $metadata->{$key} = $args{$key};
    }

    return 1;
}

sub update_flags {
    my ($self, $flags) = @_;

    # if this group does not have any globalacs,
    # set it to ACL_NONE
    if (!defined $self->get('_globalacs')) {
        $self->set(_globalacs => $fields{_globalacs}{default});
    }

    # update the acl with the flags
    my $modified_bits = modify_bits($self->get('_globalacs'), $flags);

    # set the updated bits
    $self->set(_globalacs => $modified_bits);

    return 1;
}

sub update_chanflags {
    my ($self, $channel_name, $flags) = @_;

    # if chanacs are not set up, do nothing
    my $chanacs = $self->get('_chanacs');
    if (!defined $self->get('_chanacs')) {
        return;
    }

    # if the channel doesn't exist, do nothing
    my $channel = $chanacs->find_channel($channel_name);
    if (!defined $channel) {
        return;
    }

    # update the chanacs
    my $modified_bits = modify_bits($channel->get('_access'), $flags);

    # set the updated bits
    $channel->set(_access => $modified_bits);

    return 1;
}

sub rename {
    my ($self, $new_name) = @_;
    $new_name = trim($new_name);

    # if the name is empty, do nothing
    if (empty($new_name)) {
        return;
    }

    # update the name attribute
    $self->set(_name => $new_name);
    
    return 1;
}

sub is_valid {
    my ($self) = @_;

    # a group is valid if all
    # of fields are defined
    FIELD: for my $key (keys %fields) {
        # if not a required field, ignore it
        if (!$fields{$key}{required}) {
            next FIELD;
        }

        # if the field is undefined, the group is invalid
        if (!defined $self->get($key)) {
            return;
        }
    }

    return 1;
}

1;
