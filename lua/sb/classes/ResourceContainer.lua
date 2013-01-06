--[[
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

-- Lua specific
local type = type;
local tostring = tostring;
local pairs = pairs;
local table = table

-- Gmod Specific
local CurTime = CurTime
local net = net

-- Class specific
local C = CLASS
local sb = sb;
local class = sb.core.class
local core = sb.core

function C:isA(className)
    return className == "ResourceContainer"
end

function C:init(syncid)
    self.syncid = syncid;
    self.resources = {}
    self.modified = CurTime()
    self.start_sync_after = CurTime() + 1
end

function C:getID()
    return self.syncid;
end

function C:addResources(resources)
    for k, v in pairs(resources) do
        self:addResource(v.name, v.maxamount, v.amount)
    end
end

function C:containsResource(name)
   return self.resources[name] ~= nil
end

function C:addResource(name, maxAmount, amount)
    if not name then error("ResourceContainer:addResource requires a name!") end
    name = tostring(name)
    if not amount or type(amount) ~= "number" or amount < 0 then amount = 0 end
    if not maxAmount or type(maxAmount) ~= "number" or maxAmount < 0 then maxAmount = amount end
    local res = self.resources[name];
    if not res then
        res = class.create("Resource", name, maxAmount, amount);
        self.resources[name] = res
    else
        res:setMaxAmount(res:getMaxAmount() + maxAmount)
        res:supply(amount)
    end
    if self.modified < res:getModified() then
        self.modified = res:getModified()
    end
    return res
end

function C:removeResource(name, maxAmount, amount)
    if not name then error("ResourceContainer:removeResource requires a name!") end
    name = tostring(name)
    if not amount or type(amount) ~= "number" or amount < 0 then amount = 0 end
    if not maxAmount or type(maxAmount) ~= "number" or maxAmount < 0 then maxAmount = amount end
    if not self:containsResource(name) then error("ResourceContainer:removeResource couldn't find the resource") end

    local res = self.resources[name];
    res:consume(amount)
    res:setMaxAmount(res:getMaxAmount() - maxAmount)

    if self.modified < res:getModified() then
        self.modified = res:getModified()
    end
end

local res, ret

function C:supplyResource(name, amount)
    if not self:containsResource(name) then return amount end
    res = self.resources[name]
    ret = res:supply(amount)
    if self.modified < res:getModified() then
        self.modified = res:getModified()
    end
    return ret
end

function C:consumeResource(name, amount)
    if not self:containsResource(name) then return amount end
    res = self.resources[name]
    ret = res:consume(amount)
    if self.modified < res:getModified() then
        self.modified = res:getModified()
    end
    return ret
end

function C:getResource(name)
    return self.resources[name]
end

function C:getResources()
    return self.resources
end

function C:getResourceAmount(name)
    if not self:containsResource(name) then return 0 end
    return self.resources[name]:getAmount()
end

function C:getMaxResourceAmount(name)
    if not self:containsResource(name) then return 0 end
    return self.resources[name]:getMaxAmount()
end

function C:link(container, dont_link)
    error("ResourceContainer:link is not supported")
end

function C:unlink(container, dont_unlink)
    error("ResourceContainer:unlink is not supported")
end

function C:canLink(container)
    return false
end

function C:getEntity()
    return self.syncid and Entity(self.syncid);
end

function C:send(modified, ply)
    if modified >= self.start_sync_after then
        if self.start_sync_after > 0 then
            modified = 0
            self.start_sync_after = 0
        end
        if self.modified > modified then
            net.Start("SBRU")
            core.net.writeShort(self.syncid)
            self:_sendContent(modified)
            if ply then
                net.Send(ply)
            else
                net.Broadcast()
            end
        end
    end
end

function C:_sendContent(modified)
    core.net.writeTiny(table.Count(self.resources))
    for _, v in pairs(self.resources) do
        v:send(modified)
    end
end

function C:receive()
    local nrRes = core.net.readTiny()
    local am
    local name
    local id
    for am = 1, nrRes do
        id = core.net.readTiny()
        name = sb.getResourceInfoFromID(id):getName()
        if not self.resources[name] then
            self.resources[name] = class.create("Resource", name);
        end
        self.resources[name]:receive()
    end
end

function C:getModified()
    return self.modified;
end

-- Start Save/Load functions

function C:onRestore(ent)
    self:onLoad(ent.oldrdobject)
    ent.oldrdobject = nil
end

function C:applyDupeInfo(data, newent, CreatedEntities)
    local res
    for _, v in pairs(data.resources) do
        res = self:addResource(v.name, 0, 0)
        res:onLoad(v)
        res:setAmount(0)
    end
    self.modified = CurTime()
    self.start_sync_after = CurTime() + 1
end



function C:onSave()
    return self
end

function C:onLoad(data)
    self.syncid = data.syncid
    local res
    for k, v in pairs(data.resources) do
       res = self:addResource(v.name)
       res:onLoad(v)
    end
end

-- End Save/Load functions