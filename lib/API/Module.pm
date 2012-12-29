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

class API::Module
{
    has 'name',     is => 'ro', isa => 'Str';
    has 'version',  is => 'ro', isa => 'Str',   default => '1.0';

    method init
    {
        return;
    }

    method run
    {
        return;
    }

    method destroy
    {
        return;
    }
}
