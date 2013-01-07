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
    method join ($event)
    {
        return;
    }

    method kick ($event)
    {
        return;
    }

    method nick ($event)
    {
        return;
    }

    method notice ($event)
    {
        return;
    }

    method part ($event)
    {
        return;
    }

    method privmsg ($event)
    {
        return;
    }

    method public ($event)
    {
        return;
    }

    method quit ($event)
    {
        return;
    }

    method topic ($event)
    {
        return;
    }
}
