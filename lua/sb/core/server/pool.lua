﻿--[[
Copyright (C) 2012-2013 Spacebuild Development Team

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
 ]]
local sb = sb

-- Add data to be pooled here
local net_pools = { "SBRU", "SBRPU", "SBMU", "SBEU"};
for _, v in pairs(net_pools) do
    MsgN("Pooling ", v, " for net library");
    util.AddNetworkString(v)
end