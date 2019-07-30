-- TODO 
-- Other joke functions?
-- Input for stuff with no name
-- Apply resource addendum

local string = require 'string'
local big_g = require 'big_g'
local res = require 'resources'

local env = {}
local lower = string.lower

do
    local res_spells = res.spells
    local cache = {} -- memoize ma, ja, ws, etc. mon?
    local it = pairs(res.spells)
    local last_id

    function env.ma(s)
        s = lower(s)
        if cache[s] then return cache[s] end

        for id, info in it, res_spells, last_id do
            local name = lower(info.name)
            last_id = id
            cache[name] = info

            if name == s then
                return id * 100 + 1
            end
        end

        error('Could not locate resource table for spell ' .. tostring(s))
    end
end

do
    local res_jas = res.job_abilities
    local cache = {}
    local it = pairs(res_jas)
    local last_id

    function env.ja(s)
        s = lower(s)
        if cache[s] then return cache[s] end

        for id, info in it, res_jas, last_id do
            local name = lower(info.name)
            last_id = id
            cache[name] = info

            if name == s then
                return id * 100 + 2
            end
        end

        error('Could not locate resource table for job ability ' .. tostring(s))
    end
end

env.pet = env.ja

do
    local res_ws = res.weapon_skills
    local cache = {}
    local it = pairs(res_ws)
    local last_id

    function env.ws(s)
        s = lower(s)
        if cache[s] then return cache[s] end

        for id, info in it, res_ws, last_id do
            local name = lower(info.name)
            last_id = id
            cache[name] = info

            if name == s then
                return id * 100 + 3
            end
        end

        error('Could not locate resource table for weapon skill ' .. tostring(s))
    end
end

env.ra = 4

do
    local res_ms = res.monster_abilities
    local cache = {}
    local it = pairs(res_ms)
    local last_id

    function env.ms(s)
        s = lower(s)
        if cache[s] then return cache[s] end

        for id, info in it, res_ms, last_id do
            local name = lower(info.name)
            last_id = id
            cache[name] = info

            if name == s then
                return id * 100 + 5
            end
        end

        error('Could not locate resource table for monster ability ' .. tostring(s))
    end
end

function env.menu(t)
    if type(t) ~= 'table' then error('Menu must be a table. Got ' .. tostring(t)) end
    if not t.title then error('Menu must have a title.') end

    big_g.menus[t.title] = t
    t.type = 'Menu'
end

