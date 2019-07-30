local io = require 'io'
local big_g = require 'big_g'
local serpent = require 'serpent'
local settings = require 'settings'
local widgets = require 'libs/widgets'
local scrolling_menus = require 'libs/widgets/scrolling_menus'

local windower = windower

local master_template -- template as loaded from file
local stable_template -- template filtered by job and merits
-- on job level change, filter by level
-- on zone change, check mog house flag to filter by merits
-- on pet gain, filter by pet additional resources
local filtered_template
local filtered_list -- only current menu, availability filters (WS) applied


local function act(t, target)
    local prefix = t.prefix
    local name = t.name

    local input = prefix
    input = name and input .. ' ' .. name or input
    input = target and input .. ' ' .. target or input

    windower.chat.input(input)
end

local rhombus_menu = scrolling_menus.new()

windower.register_event('addon command', function(cmd, ...)
    if not cmd then return end
    cmd = string.lower(cmd)

    if cmd == 'make' then
        local name = ... or 'template'
        local template, err = loadfile(windower.addon_path .. 'data/' .. name .. '.lua')
        if not template then 
            print('Could not load template', err)
            return
        end

        local env = require 'env'
        setfenv(template, env)
        local success, err = pcall(template())

        if not success then
            print('Could not make template', err)
        end

        local out = io.open(windower.addon_path .. 'data/menus/' .. name .. '.lua', 'w')
        out:write('return ' .. serpent.line(big_g.menus, {comment = false, compact = true}))
        out:close()
    elseif cmd == 'load' then
        local name = ...
        if not name then print('Name required for load command.') return end

        local template_loader, err = loadfile(windower.addon_path .. 'data/menus' .. name .. '.lua')
        if not template_loader then
            print('Could not load template.', err)
            return
        end

        local env = {}
        setfenv(template_loader, env)
        local success, template = pcall(env)
        if not success then print(err) return end

        local categories = {
            res.spells,
            res.job_abilities,
            res.weapon_skills,
            {[0] = {prefix = '/range', targets = {'TODO'}}}, -- could point targets to an appropriate table in ja_res
            res.monster_abilities,
        }
        local function decode(n)
            local id = math.floor(n / 100)
            local cat = n - id * 100

            return categories[cat][id]
        end

        for title, menu in pairs(template) do
            for n, item in pairs(menu) do
                if not template[menu] then
                    menu[n] = decode(item)
                end
            end
        end

        master_template = template
    end
end)

windower.register_event('job change', function(main_id, main_level, sub_id, sub_level)
    -- TODO rebuild template
end)

