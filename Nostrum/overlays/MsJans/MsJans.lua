do
    require 'tables'
    package.loaded.tables = table
    table.concat = _raw and _raw.table.concat or table.concat
    require 'strings'
    package.loaded.strings = string
end

-- Text dimensions have to be measured here (can't sleep within a call to require)
do
    local dimensions = require 'text_dimensions'
    local path = 'data/textdb.lua'
    local textdb = dimensions.read(path)

    dimensions.update(textdb)
    dimensions.write(textdb, path)
end

local math = require 'math'
local string = require 'string'
local res = require 'resources'
local align = require 'align'
local widgets = require 'widgets'
local primitives = require 'widgets/primitives'
local arrangements = require 'widgets/arrangements'
local buttons = require 'widgets/buttons'
local palettes = require 'display/palette'
local stats = require 'display/stats'
local targets = require 'display/target'
local settings = require 'settings'
local profiles = require 'profiles'

local function block_mouse_input()
    return true
end

local palette_ui = {}

do
    local party_main, party_buff, party_debuff
    local ally_main, ally_buff, ally_debuff
    local default = profiles.default
    local blank = {}

    if default then
        party_main = default.party.main or blank
        party_buff = default.party.buff or blank
        party_debuff = default.party.debuff or blank
        ally_main = default.alliance.main or blank
        ally_buff = default.alliance.buff or blank
        ally_debuff = default.alliance.debuff or blank
    else
        party_main, party_buff, party_debuff = blank, blank, blank
        ally_main, ally_buff, ally_debuff = blank, blank, blank
    end

    palette_ui[1] = {
        palettes.new(0, 0, false, party_main),
        palettes.new(0, 0, false, party_buff),
        palettes.new(0, 0, false, party_debuff),
    }

    for i = 2, 3 do
        palette_ui[i] = {
            palettes.new(0, 0, false, ally_main),
            palettes.new(0, 0, false, ally_buff),
            palettes.new(0, 0, false, ally_debuff),
        }
    end
end

local party_ui = {
    stats.new(0, 0, false),
    stats.new(0, 0, false),
    stats.new(0, 0, false),
}

for i = 1, 3 do
    party_ui[i]:track()
    party_ui[i]:register_event('left button down', block_mouse_input)
    party_ui[i]:register_event('left click', function(b, x, y)
        local _, pos_y = party_ui[i]:pos()
        local n = math.ceil((y - pos_y) / settings.unit_height)
        if n == 0 then return end

        action('target', get_alliance_key(i, n))
    end)
end

local buff_ui

-- Create the buff display if the settings say to (default true)
if icon_path and settings.status_effect_region.display_party_status_effects then
    buff_ui = arrangements.new(0, 0, true)

    local d = settings.unit_height / 2

    for p = 1, 6 do
        for b = 0, 31 do
            local id = 'stsicon' .. tostring(p) .. tostring(b + 1)
            local prim_x, prim_y = -((b % 16 + 1) * d), (p - 1) * 2 * d + math.floor(b / 16) * d

            buff_ui:add_element(primitives.new('prim', {set_size = {d, d}, set_fit_to_texture = false,}), id, prim_x, prim_y, false)
        end
    end

    overlay:register_event('statuses updated', function(blocked, pos, buff_table)
        pos = tostring(pos)
        local n = buff_table.n

        if n > 16 then
            for i = 32, n + 1, -1 do
                buff_ui:element_visibility('stsicon' .. pos .. tostring(i), false)
            end

            for i = 16, 1, -1 do
                local id = 'stsicon' .. pos .. tostring(i)

                buff_ui:element(id)('set_texture', icon_path .. 'sts_icon/' .. tostring(buff_table[16 - i + 1]) .. '.bmp')
                buff_ui:element_visibility(id, true)
            end

            for i = n, 17, -1 do
                local id = 'stsicon' .. pos .. tostring(i)

                buff_ui:element(id)('set_texture', icon_path .. tostring(buff_table[16 + n - i + 1]) .. '.bmp')
                buff_ui:element_visibility(id, true)
            end
        else
            for i = 32, n + 1, -1 do
                buff_ui:element_visibility('stsicon' .. pos .. tostring(i), false)
            end

            for i = n, 1, -1 do
                local id = 'stsicon' .. pos .. tostring(i)

                buff_ui:element(id)('set_texture', icon_path .. tostring(buff_table[n - i + 1]) .. '.bmp')
                buff_ui:element_visibility(id, true)
            end
        end
    end)
end

local expand_buttons = {}
do
    local s = {
        w = -30,
        h = 0,
        bg = {
            set_size = {-15, 0},
            -- set_color = {65, 0, 0, 0}
            set_texture = overlay_path .. 'open.png',
            set_color = {150, 255, 255, 255},
            set_fit_to_texture = false,
        }
    }
    for i = 1, 3 do
        local b = buttons.new(0, 0, false, s)

        b.state = 0
        b:track()

        b:register_event('left click', function()
            if b.state == 0 then
                for j = 1, 3 do
                    if #palette_ui[i][j].settings ~= 0 then
                        palette_ui[i][j]:visible(true)
                        b.state = j
                        b:element('background')('set_texture', overlay_path .. 'scroll.png')
                        break
                    end
                end
            else
                palette_ui[i][b.state]:visible(false)
                b:element('background')('set_texture', overlay_path .. 'open.png')
                b.state = 0
            end
        end)

        b:register_event('scroll', function(blocked, x, y, delta)
            if b.state == 0 then return end

            if delta < 0 then
                local n = 0
                local state = b.state

                repeat
                    state = state % 3 + 1 -- 0 closed, 1 2 3 palettes
                    n = n + 1
                until n == 3 or not (#palette_ui[i][state].settings == 0)

                if state ~= b.state then
                    palette_ui[i][b.state]:visible(false)
                    palette_ui[i][state]:visible(true)
                    b.state = state
                end
            else
                local n = 0
                local state = b.state

                repeat
                    state = ((state - 2) + 3) % 3 + 1
                    n = n + 1
                until n == 3 or not (#palette_ui[i][state].settings == 0)

                if state ~= b.state then
                    palette_ui[i][state]:visible(true)
                    palette_ui[i][b.state]:visible(false)
                    b.state = state
                end
            end

            return true
        end)

        b:register_event('left button down', block_mouse_input)

        b:register_event('focus change', function(blocked, gain)
            local _, h = b:size()
            local bg = b:element('background')

            if gain then
                bg('set_size', -30, h)
            elseif b.state == 0 then
                bg('set_size', -15, h)
            end
        end)

        expand_buttons[i] = b
    end

    expand_buttons[1]:register_event('left click', function()
        buff_ui:visible(expand_buttons[1].state == 0)
    end)
end

local selector_buttons = {}
do
    local w = settings.stat_region.prim.width
    local h = -20
    local s = {w = w, h = h}

    for i = 1, 3 do
        local b = buttons.new(0, 0, false, s)
        selector_buttons[i] = b

        b:track()

        local _w = w / 3
        local red_block = primitives.new('prim')
        red_block('set_size', _w, h)
        red_block('set_color', 255, 225, 122, 0)
        local green_block = primitives.new('prim')
        green_block('set_size', _w, h)
        green_block('set_color', 255, 0, 125, 177)
        local blue_block = primitives.new('prim')
        blue_block('set_size', _w, h)
        blue_block('set_color', 255, 175, 0, 125)

        b:add_element(red_block, 'red', 0, 0, true)
        b:add_element(green_block, 'green', _w, 0, true)
        b:add_element(blue_block, 'blue', _w * 2, 0, true)

        b:register_event('left button down', block_mouse_input)
        b:register_event('left click', function(_, x)
            local bx = b:pos()
            local n = math.ceil((x - bx) / _w)
            if n == 0 then return end
            local eb = expand_buttons[i]
            local state = eb.state

            if state ~= 0 then
                palette_ui[i][state]:visible(false)
                eb.state = 0

                local _, eb_h = eb:size()
                local bg = eb:element('background')
                bg('set_size', -15, eb_h)

                if state == n then return true end
            end
            if #palette_ui[i][n].settings ~= 0 then
                palette_ui[i][n]:visible(true)
                eb.state = n

                local _, eb_h = eb:size()
                local bg = eb:element('background')
                bg('set_size', -30, eb_h)

            end

            return true
        end)
    end
end

-- position the gui
do
    local b = function(obj, offset)
        align.bottom(obj, offset - settings.location.y_offset)
    end
    local r = function(obj, offset)
       align.right(obj, offset - settings.location.x_offset)
    end
    for i = 1, 3 do
        for j = 1, 3 do
            r(palette_ui[i][j], -1 * settings.stat_region.prim.width - 30)
        end
        r(party_ui[i], 0)
        r(selector_buttons[i], 0)
        r(expand_buttons[i], -1 * settings.stat_region.prim.width)
    end

    -- {0, 288, 389} -- offsets from tparty
    for i, offset in ipairs({settings.location.y_offset_pt1, settings.location.y_offset_pt2, settings.location.y_offset_pt3}) do
        for j = 1, 3 do
            b(palette_ui[i][j], -offset)
        end
        b(party_ui[i], -offset)
        b(selector_buttons[i], -offset)
        b(expand_buttons[i], -offset)
    end

    if buff_ui then
        local x, y = party_ui[1]:pos()

        buff_ui:pos(x - 15, y)
    end

    for i = 2, 3 do
        widgets.update_object(selector_buttons[i])
    end
end

local function hide_buffs(n)
    if settings.status_effect_region.display_party_status_effects then
        n = tostring(n)
        for i = 1, 32 do
            buff_ui:element_visibility('stsicon' .. n .. tostring(i), false)
        end
    end
end

-- Create the target display if the settings say to (default true)
local target_ui
if settings.target_region.create_target_display then
    local x, y = party_ui[1]:pos()
    local _, selector_height = selector_buttons[1]:size() -- selector_height is negative
    target_ui = targets.new(x, y - settings.target_region.height + selector_height, false)

    overlay:register_event('target change', function(blocked, target)
        if target and target.valid_target then
            if not target_ui:visible() then
                target_ui:visible(true)
            end

            target_ui:update(target)
        else
            target_ui:visible(false)
        end
    end)

    overlay:register_event('target hpp change', function(blocked, new, old)
        target_ui:update_hpp(new, old)
    end)
end

local function truncate_name(s)
    local n = settings.stat_region.text.name.truncate

    return #s < n and s or string.sub(s, 1, n) .. '.'
end

local party_lengths = {}

overlay:register_event('display populated', function(blocked, party, position)
    party_lengths[party] = position

    local pt_ui = party_ui[party]
    if not pt_ui:visible() then pt_ui:visible(true) selector_buttons[party]:visible(true) end

    if not pt_ui[position] then
        pt_ui:append_row()
        for i = 1, 3 do
            local palette = palette_ui[party][i]
            palette:append_row()

            for j = 1, #palette.settings do
                local s = palette.settings[j]
                local key = get_alliance_key(party, position)

                palette[position][j]:register_event('left click', function()
                    action(s.action, key)
                end)
            end
        end

        if party == 1 then
            local x, y = pt_ui:pos()
            y = y - settings.unit_height

            pt_ui:pos(x, y)
            local selectors = selector_buttons[1]
            selectors:pos(x, y)
            widgets.update_object(selectors)

            for i = 1, 3 do
                palette_ui[1][i]:pos(x - 30, y)
            end

            if target_ui then
                local _, selector_height = selectors:size()
                target_ui:pos(x, y - settings.target_region.height + selector_height)
            end

            if buff_ui then
                buff_ui:pos(x - 15, y)
            end

            expand_buttons[1]:pos(x, y)
        end
    end

    local ui = pt_ui[position]
    local stats = ui.stats

    ui.hpp:visible(true) -- not a group... lazily put them in a table
    stats:visible(true)
    ui.mpp:visible(true)

    local exp_b = expand_buttons[party]
    local _, h = pt_ui:size()
    local w = exp_b:size()

    exp_b:size(w, h)
    exp_b:element('background')('set_size', exp_b.state == 0 and -15 or -30, h)

    if not exp_b:visible() then
        exp_b:visible(true)
    end

    widgets.update_object(exp_b)
    widgets.update_object(pt_ui)
    for i = 1, 3 do
        local palette = palette_ui[party][i]

        for j = 1, position do
            for k = 1, #palette.settings do
                widgets.update_object(palette[j][k])
            end
        end
    end
end)

overlay:register_event('display vacant', function(blocked, party, position)
    local ui = party_ui[party][position]

    ui.hpp:visible(false)
    ui.mpp:visible(false)
    ui.stats:visible(false)

    if position == 1 then
        party_ui[party]:visible(false)
        for i = 1, 3 do
            palette_ui[party][i]:visible(false)
        end
    end

    if party == 1 then
        hide_buffs(position)
    end
end)

for _, stat in pairs({'hp', 'mp', 'tp', 'hpp'}) do
    if settings.stat_region.text[stat].visible then
        overlay:register_event(stat .. ' change', function(blocked, party, position, value)
            party_ui[party][position].stats:element(stat)('set_text', tostring(value))
        end)
    end
end

if settings.stat_region.text.name.visible then
    overlay:register_event('name change', function(blocked, party, position, name)
        party_ui[party][position].stats:element('name')('set_text', truncate_name(name))
    end)
end

overlay:register_event('hpp change', function(blocked, party, position, new, old)
    local phpp = party_ui[party][position].hpp
    phpp:percent(new)
    local n = math.ceil(new / 25)
    if new ~= 0 and n ~= math.ceil(old / 25) then
        local c = settings.stat_region.prim.hp_bar_percentage_colors[n * 25]
        phpp:color(c.a, c.r, c.g, c.b)
    end
end)

overlay:register_event('mpp change', function(blocked, party, position, mpp)
    party_ui[party][position].mpp:percent(mpp)
end)

overlay:register_event('in view', function(blocked, party, position)
    party_ui[party][position].stats:element('name')('set_italic', false)
end)

do
    local out_of_range = {}

    overlay:register_event('out of view', function(blocked, party, position)
        local name = party_ui[party][position].stats:element('name')
        name('set_italic', true)

        -- if they're out of view, they're out of range
        local color = settings.stat_region.text.name.out_of_range_color
        local key = get_alliance_key(party, position)

        name('set_color', color.a, color.r, color.g, color.b)
        out_of_range[key] = true
    end)

    overlay:register_event('distance change', function(blocked, party, position, distance_squared)
        local key = get_alliance_key(party, position)
        if out_of_range[key] then
            local name = party_ui[party][position].stats:element('name')

            if distance_squared < 441 then
                out_of_range[key] = false
                name('set_bold', true)

                local color = settings.stat_region.text.name.color
                if color then
                    name('set_color', color.a, color.r, color.g, color.b)
                else
                    name('set_color', 255, 255, 255, 255)
                end
            end
        elseif distance_squared >= 441 then
            local name = party_ui[party][position].stats:element('name')
            out_of_range[key] = true
            name('set_bold', false)

            local color = settings.stat_region.text.name.out_of_range_color
            name('set_color', color.a, color.r, color.g, color.b)
        end
    end)
end

overlay:register_event('zone in', function(blocked, party, position)
    local ui = party_ui[party][position]
    ui.hpp:visible(true)
    ui.mpp:visible(true)

    local stats = ui.stats
    local text_settings = settings.stat_region.text

    for _, stat in pairs({'hp', 'mp', 'hpp', 'tp'}) do
        if text_settings[stat].visible then
            stats:element_visibility(stat, true)
        end
    end
    if text_settings.zone.visible then
        stats:element_visibility('zone', false)
    end
end)

overlay:register_event('zone out', function(blocked, party, position, zone)
    zone = res.zones[zone].search
    local ui = party_ui[party][position]

    ui.hpp:visible(false)
    ui.mpp:visible(false)

    local stats = ui.stats
    local text_settings = settings.stat_region.text

    for _, stat in pairs({'hp', 'mp', 'hpp', 'tp'}) do
        if text_settings[stat].visible then
            stats:element_visibility(stat, false)
        end
    end

    stats:element_visibility('name', true)

    local name = stats:element('name')
    local color = settings.stat_region.text.name.color

    if color then
        name('set_color', color.a, color.r, color.g, color.b)
    else
        name('set_color', 255, 255, 255, 255)
    end

    name('set_bold', true)
    name('set_italic', false)

    if text_settings.zone.visible then
        stats:element_visibility('zone', true)
        stats:element('zone')('set_text', zone)
    end

    if party == 1 then
        hide_buffs(position)
    end
end)

if settings.stat_region.text.zone.visible then
    overlay:register_event('zone change', function(blocked, party, position, zone)
        zone = res.zones[zone].search

        party_ui[party][position].stats:element('zone')('set_text', zone)
    end)
end

overlay:register_event('overlay command', function(blocked, cmd, ...)
    if cmd == 'help' or cmd == 'h' then
        return [[
            profile(p) <profile>: Rebuilds palettes using the specified table
             - from data/user_profiles.lua.
            cut(c): Trims vacant spots from the display.
         ]]
    elseif cmd == 'cut' or cmd == 'c' then
        -- The display for party 1 moves up as members join;
        -- Move the display back down.
        local stat1 = party_ui[1]
        local vacancies = #stat1 - party_lengths[1]

        if vacancies > 0 then
            local x, y = stat1:pos()
            y = y + vacancies * settings.unit_height

            stat1:pos(x, y)
            for i = 1, 3 do
                palette_ui[1][i]:pos(x, y)
            end
            expand_buttons[1]:pos(x, y)
        end

        -- Remove vacant display lines.
        for party = 1, 3 do
            local stat = party_ui[party]
            local p_ui = palette_ui[party]
            local expb = expand_buttons[party]

            for _ = 1, #stat - party_lengths[party] do
                stat:remove_row()
                for i = 1, 3 do
                    p_ui[i]:remove_row()
                end
                expb:size((expb:size()), settings.unit_height * party_lengths[party])
            end
        end
    elseif cmd == 'profile' or cmd == 'p' then
        local name = ...
        if not name then print('Specify a profile.') return end

        local profile = profiles[name]
        if not profile then print('The profile ' .. name .. ' does not exist.') return end

        local blank = {}
        local party_main = profile.party.main or blank
        local party_buff = profile.party.buff or blank
        local party_debuff = profile.party.debuff or blank
        local ally_main = profile.alliance.main or blank
        local ally_buff = profile.alliance.buff or blank
        local ally_debuff = profile.alliance.debuff or blank

        local p = {party_main, party_buff, party_debuff}
        local a = {ally_main, ally_buff, ally_debuff}

        for i = 1, 3 do
            palette_ui[1][i]:update_settings(p[i])
        end

        for j = 2, 3 do
            for i = 1, 3 do
                palette_ui[j][i]:update_settings(a[i])
            end
        end

        for party = 1, 3 do
            local p_ui = palette_ui[party]

            for i = 1, 3 do
                local palette = p_ui[i]

                for pos = 1, #palette do
                    local key = get_alliance_key(party, pos)

                    for k = 1, #palette.settings do
                        local s = palette.settings[k]

                        palette[pos][k]:register_event('left click', function()
                            action(s.action, key)
                        end)
                    end
                end
            end
        end
    elseif cmd == '?' then
        aaa()
    end
end)

function aaa()
    widgets.dbg_where(selector_buttons[1])
end

