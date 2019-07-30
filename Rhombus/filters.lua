local res = require 'resources'
local big_g = require 'big_g'
local add_ja_res = require 'additional_ja_res'
local add_ws_res = require 'additional_ws_res'
-- local res = require 'resources'

local filters = {}
local main_job, main_job_level, sub_job, sub_job_level = 0, 0, 0, 0

filters['/monsterskill'] = function(t)
    return main_job >= t.monster_level
end

do
    local ja_category = {
        ['Stratagems'] = true, ['Blood Pact: Rage'] = true, ['Sambas'] = true,
        ['Waltzes'] = true, ['Steps'] = true, ['Flourishes I'] = true,
        ['Flourishes II'] = true, ['Flourishes III'] = true,
        ['Blood Pact: Ward'] = true, ['Phantom Roll'] = true,
        ['Rune Enchantment'] = true, ['Jigs'] = true, ['Ready'] = true,
        ['Quick Draw'] = true
    }
    filters['/jobability'] = function(t)
        if ja_category[t.name] then return false end

        local jobs = add_ja_res.jobs[t.id] -- category ja are nil
        if jobs then
            if jobs == main_job then
                local levels = add_ja_res.levels[t.id]
                if levels and levels > main_job_level then return false end
            elseif jobs == sub_job then
                local levels = add_ja_res.levels[t.id]
                if levels and levels > sub_job_level then return false end
            else
                return false
            end
        end

        local meritable = add_ja_res.meritable[t.id]
        if meritable then
            return big_g.merits[res.jobs[main_job].name][string.gsub(string.lower(t.name), ' ', '_')] > 0 -- ...
        end

        return true
    end
end

do
    local band = require('bit').band
    local function bit_is_set(mask, nth)
        return band(mask, 2^(nth - 1)) ~= 0
    end
    local main_only = add_ws_res.main_only
    local either = add_ws_res.either

    filters['/weaponskill'] = function(t)
        local id = t.id
        if main_job == 0 then return true end -- can't filter

        local main = main_job
        local either_id = either[id]
        return not (bit_is_set(main_only[id], main) or bit_is_set(either_id, main) or bit_is_set(either_id, sub_job))
    end
end

filters['/magic'] = function(t)
    local levels = res.spells[t.id].levels
    local main = levels[main_job]
    if main then
        if main > 99 then
            return main_job_level == 99 and big_g.job_points >= main
        else
            return main <= main_job_level
        end
    end

    local sub = levels[sub_job]
    if sub then
        return sub <= sub_job_level
    end

    return false
end

filters['/pet'] = filters['/jobability']

filters.gray_out = {}

do
    local skill_req = add_ws_res.skill_level
    filters.gray_out['/weaponskill'] = function(t)
        return not big_g.ws[t.name] or skill_req[t.id] > big_g.skills[t.skill]
    end
end

do
    filters.gray_out['/jobability'] = function(t)
        return not big_g.ja[t.id] or big_g.ja_cooldown[t.recast_id] > 0
    end
end

filters.by_resource_entry = {} -- filters which return true if the associated action should be grayed out in the menu

local function tabula_rasa()
    return not big_g.buffs[377]
end

filters.by_resource_entry[res.spells[478]] = tabula_rasa
filters.by_resource_entry[res.spells[502]] = tabula_rasa

do
    local addendum_white = {[14]="Poisona",[15]="Paralyna",[16]="Blindna",[17]="Silena",[18]="Stona",[19]="Viruna",[20]="Cursna",
        [143]="Erase",[13]="Raise II",[140]="Raise III",[141]="Reraise II",[142]="Reraise III",[135]="Reraise"}
    local addendum_black = {[253]="Sleep",[259]="Sleep II",[260]="Dispel",[162]="Stone IV",[163]="Stone V",[167]="Thunder IV",
    [168]="Thunder V",[157]="Aero IV",[158]="Aero V",[152]="Blizzard IV",[153]="Blizzard V",[147]="Fire IV",[148]="Fire V",
    [172]="Water IV",[173]="Water V",[255]="Break"}

    function filters.gray_out.add_white(t)
        return not (big_g.buffs[401] or big_g.buffs[416]) or big_g.ma_cooldown[t.id]
    end

    function filters.gray_out.add_black(t)
        return not (big_g.buffs[402] or big_g.buffs[416]) or big_g.ma_cooldown[t.id]
    end

    function filters.gray_out.stratagems()
        return big_g.ja_cooldown[231]
    end

    windower.register_event('job change', function(main, main_level, sub, sub_level)
        main_job, main_job_level, sub_job, sub_job_level = main, main_level, sub, sub_level

        if main == 23 then -- I have no idea if this works
            local player = windower.ffxi.get_mob_by_target('me')
            local class_info = require('monstrosity_classes')[player.name]

            if class_info then
                main_job = class_info.main
                sub_job = class_info.sub -- TODO convert to id
            else
                print('Could not convert monstrosity class (' .. tostring(player.name) .. ')... Errors inbound.')
                main_job, sub_job = 0, 0
            end
        end

        local sch, lvl
        if main == 20 then
            sch = true
            lvl = sub_level
        elseif sub == 20 then
            sch = true
            lvl = main_level
        end

        for id in pairs(addendum_white) do
            local levels = res.spells[id].levels[20]
            filters.by_resource_entry[res.spells[id]] = sch and not (levels and levels <= lvl) and filters.gray_out.add_white
        end

        for id in pairs(addendum_black) do
            local levels = res.spells[id].levels[20]
            filters.by_resource_entry[res.spells[id]] = not (levels and levels <= lvl) and filters.gray_out.add_black
        end
    end)
end

do
    local unbridled_learning_set = {['Thunderbolt']=true,['Harden Shell']=true,['Absolute Terror']=true,
        ['Gates of Hades']=true,['Tourbillion']=true,['Pyric Bulwark']=true,['Bilgestorm']=true,
        ['Bloodrake']=true,['Droning Whirlwind']=true,['Carcharian Verve']=true,['Blistering Roar']=true,
        ['Uproot']=true,['Crashing Thunder']=true,['Polar Roar']=true,['Mighty Guard']=true,['Cruel Joke']=true,
        ['Cesspool']=true,['Tearing Gust']=true}

    function filters.gray_out.unbridled_learning(t)
        return not big_g.buffs[485] or big_g.ma_cooldown[t.id]
    end

    function filters.gray_out.blu(t)
        return not big_g.blue_magic_spell_set[t.id] or big_g.ma_cooldown[t.id]
    end

    for id, v in pairs(res.spells) do
        if v.type == 'BlueMagic' then
            if unbridled_learning_set[v.english] then
                filters.by_resource_entry[v] = filters.gray_out.unbridled_learning
            else
                filters.by_resource_entry[v] = filters.gray_out.blu
            end
        end
    end
end

for id, v in pairs(res.job_abilities) do
    if v.type == 'Scholar' then
        filters.by_resource_entry[v] = filters.gray_out.stratagems
    end
end

