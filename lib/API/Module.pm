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

    has 'settings'  => (
        default     => sub { {} },
        is          => 'rw',
        isa         => 'HashRef',
        required    => FALSE,
    );

    has 'ratelimit' => (
        default     => sub { [1, 2] },  # 1 every 2 seconds
        is          => 'ro',
        isa         => 'ArrayRef',
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
    method on_join ($event)
    {
        return;
    }

    method on_kick ($event)
    {
        return;
    }

    method on_nick ($event)
    {
        return;
    }

    method on_notice ($event)
    {
        return;
    }

    method on_part ($event)
    {
        return;
    }

    method on_privmsg ($event)
    {
        return;
    }

    method on_public ($event)
    {
        return;
    }

    method on_quit ($event)
    {
        return;
    }

    method on_topic ($event)
    {
        return;
    }
}
