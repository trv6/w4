--[[Copyright © 2014-2018, trv
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Nostrum nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL trv BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.--]]

local globals = require 'big_g'
local string = require 'strings'
local os = require 'os'
require 'pack'

local parse = {
    incoming = {},
    outgoing = {},
    last_incoming = {},
}

local ignore_0x063 = false

local jobs = globals.jobs
local buffs = globals.buffs

parse.incoming[0x063] = function(data)
    if data:byte(5) == 9 then
        if ignore_0x063 then
            ignore_0x063 = false
            return
        end

        local clock = os.clock()
        local player_buffs = buffs.player
        local n = 0

        for i = 1, 32 do
            local buff_id = data:unpack('H', 7 + i * 2)

            if buff_id == 255  then
                break
            else
                if player_buffs[i] ~= buff_id then
                    player_buffs.clock = clock
                    player_buffs[i] = buff_id
                end

                n = i
            end
        end

        if n ~= player_buffs.n then
            player_buffs.n = n
            player_buffs.clock = clock
        end
    end
end

parse.incoming[0x076] = function(data)
    local clock = os.clock()

    for i = 0, 4 do
        local id = data:unpack('I', i*48+5)

        if id == 0 then
            break
        else
            local n = 0
            local b = buffs[id]
            if not b then b = {}; buffs[id] = b end

            for j = 1, 32 do
                local buff = data:byte(i*48+5+16+j-1) + 256*( math.floor( data:byte(i*48+5+8+ math.floor((j-1)/4)) / 4^((j-1)%4) )%4) -- Credit: Byrth, GearSwap

                if buff == 255 then
                    break
                else
                    if buff ~= b[j] then
                        b[j] = buff
                        b.clock = clock
                    end
                    n = j
                end
            end

            if b.n ~= n then
                b.n = n
                b.clock = clock
            end
        end
    end
end

parse.outgoing[0x00D] = function()
    ignore_0x063 = true
end

parse.incoming[0x0DD] = function(data)
    jobs[data:unpack('I', 5)] = data:unpack('C', 23)
end

parse.incoming[0x0C8] = function(data)
    local alliance = {player = true}

    for i = 9, 213, 12 do
        alliance[data:unpack('I', i)] = true
    end

    for id in pairs(buffs) do
        if not alliance[id] then
            buffs[id] = nil
        end
    end

    for id in pairs(jobs) do
        if not alliance[id] then
            jobs[id] = nil
        end
    end
end

parse.last_incoming[0x0C8] = function(data)
    local solo = false

    for i = 1, 3 do -- probably only need to check the first, but I don't remember if that's always the case
        local offset = 9 + 12*6*(i-1)

        local first_id = data:unpack('I', offset)

        if first_id ~= 0 then -- this party isn't empty
            local flags = data:unpack('H', offset + 6)
            local party = flags % 4 -- the lowest two bits indicate which party (though the order is unreliable)

            solo = party == 0 -- the bits are 0 if the party is empty(?) or if the player is solo with trusts
            if solo then break end
        end
    end

    return solo
end

do
    local parse_i = parse.incoming
    windower.register_event('incoming chunk', function(id, data)
        if parse_i[id] then
            parse_i[id](data)
        end
    end)

    local parse_o = parse.outgoing
    windower.register_event('outgoing chunk', function(id, data)
        if parse_o[id] then
            parse_o[id](data)
        end
    end)
end

return parse

