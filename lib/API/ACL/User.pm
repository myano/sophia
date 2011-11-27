# API::ACL::User - represents a sophia ACL User
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

package API::ACL::User;
use strict;
use warnings;
use API::ACL::ChannelList;
use API::ACL::Flags qw(ACL_NONE modify_bits);

# the fields for a User
# a value of 1 means required.
my %fields = (
    _chanacs    => {
        required        => 0,
        type            => 'API::ACL::ChannelList',
    },
    _globalacs  => {
        default         => ACL_NONE,
        required        => 0,
    },
    _hostmasks  => {
        default         => {},
        required        => 1,
        type            => 'HASHREF',
    },
    _metadata   => {
        default         => {},
        required        => 0,
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

    # if the key value doesn't exist
    # or isn't defined, return nothing
    if (!defined $self->{$key}) {
        return;
    }

    return $self->{$key};
}

sub set {
    my ($self, %args) = @_;

    # set the value, but only if it's in @fields.
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

sub add_hostmask {
    my ($self, $hostmask) = @_;

    # if the hostmasks is not set up or
    # it's not a hashref, then set it up now
    my $hostmasks = $self->get('_hostmasks');
    my $field = $fields{_hostmasks};
    if (!defined $hostmasks || ref $hostmasks ne $field{type}) {
        $self->set(_hostmasks => $field{default});

        # update the userlist
        $hostmasks = $self->get('_hostmasks');
    }

    # add the hostmask
    $hostmasks{$hostmask} = 1;

    return 1;
}

sub del_hostmask {
    my ($self, $hostmask) = @_;

    # if the hostmask list isn't a HASHREF, do nothing
    my $hostmasks = $self->get('_hostmasks');
    if (!defined $hostmasks || ref $hostmasks ne $fields{_hostmasks}{type}) {
        return;
    }

    # delete the user from the userlist
    delete $hostmasks{$hostmask};

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

sub rename {
    my ($self, $new_name) = @_;
    $new_name = trim($new_name);

    # if the name is empty, do nothing
    if (empty($new_name)) {
        return;
    }

    # set to the new name
    # update chanacs index first
    my $chanacs = $self->get('_chanacs');
    my $old_name = $self->get('_name');
    $chanacs->update_index($old_name, $new_name);

    # update the name attribute
    $self->set(_name => $new_name);
    
    return 1;
}

sub is_valid {
    my ($self) = @_;

    # this user is valid if all required
    # fields are defined
    FIELD: for my $key (keys %fields) {
        # if not a required field, skip
        if (!$fields{$key}{required}) {
            next FIELD;
        }

        # if the field is undefined, this user is invalid
        if (!defined $self->get($key)) {
            return;
        }
    }

    return 1;
}

1;
