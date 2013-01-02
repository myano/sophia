# API::Module - The basic core structure of a Module
# Copyright (C) 2012 Kenneth K. Sham 
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

use MooseX::Declare;
use Method::Signatures::Modifiers;

role API::Module
{
    use Constants;

    has 'name'      => (
        is          => 'ro',
        isa         => 'Str',
        required    => TRUE,
    );

    has 'version'   => (
        default     => '1.0',
        is          => 'ro',
        isa         => 'Str',
        required    => TRUE,
    );

    has 'cache'     => (
        default     => sub { {} },
        is          => 'rw',
        isa         => 'HashRef',
        required    => FALSE,
    );

    method access ($event)
    {
        return TRUE;
    }

    method init
    {
        return;
    }

    method run ($event)
    {
        return;
    }

    method destroy
    {
        return;
    }


    # action methods
    # these are methods that will be called upon an IRC event
    # such as: public, privmsg, kick, part, etc.
    #
    # naming conventions should follow the ones in Protocol::IRC::Response
    # without leading _
    #
    # For example: if you are writing a game that wants to keep
    # track of active players, then you can store active players
    # into this cache. But then if you want to remove active
    # players when someone quits or parts, then you will create
    # two methods 'quit' and 'part' that will remove them from
    # the cache.
}
