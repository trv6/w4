require 'strings'
local math = require 'math'
local string = require 'string'
local coroutine = require 'coroutine'
local res = require 'resources'
local align = require 'align'
local widgets = require 'widgets'
local primitives = require 'widgets/primitives'
local buttons = require 'widgets/buttons'
local groups = require 'widgets/groups'
local settings = require 'settings'
local keybinds = require 'keybinds'

local font_w, font_h = {}
do
    local text = primitives.new('text')
    text('set_bold', true)
    text('set_font', 'Consolas')
    text('set_font_size', settings.font_size)
    text('set_position', -50, -50)

    -- I assumed primitive width would be n * character width for monospaced fonts
    -- This does not seem to be the case
    local s = ''
    for i = 1, 5 do
        s = s .. 'A'
        text('set_text', s)
        coroutine.sleep(0.2)
        local w, h = text('get_extents')
        font_w[i] = w
        font_h = h
    end

    text('delete')
end

local group = groups.new(0, 0, true)

local grid = {}
local labels = {}

local size = settings.grid_size

for i = 1, 18 do
    local n = (i - 1) % 6
    local x = n * (size.w + settings.padding)
    local y = math.ceil(i / 6) * (size.h + settings.padding)
    local b = buttons.new(x, y, false, {
        w = size.w,
        h = size.h,
        bg = {
            set_texture = overlay_path .. 'gradient.png',
            set_fit_to_texture = false,
        },
        labels = {
            name_or_hpp_est = {
                x = (size.w - font_w[4]) / 2,
                y = (size.h - font_h) / 2,
                visible = true,
                set_font = 'Consolas',
                set_font_size = settings.font_size,
                set_stroke_width = 0.5,
                set_stroke_color = {80, 0, 0, 0}
            }
        }
    })

    labels[i] = b:element('name_or_hpp_est')

    local fg = primitives.new('prim')
    fg('set_size', size.w, -size.h)
    fg('set_color', 188, 0, 0, 0)
    b:add_element(fg, 'foreground', 0, size.h, true)

    grid[i] = b
    group:add_object(b, tostring(i))
end

rawset(group, 'size', function() -- spoof a size function so that align works
    local size = settings.grid_size
    local pad = settings.padding
    return -(size.w * 6 + pad * 5), -(size.h * 3 + pad * 2)
end)
align.right(group, -settings.offset.x)
align.bottom(group, -settings.offset.y)

local function paint_grid(n, r, g, b)
    local grid_n = grid[n]
    local min = math.min

    grid_n:element('background')('set_color', 255, r, g, b)
    grid_n:element('name_or_hpp_est')('set_color', 255, min(r + 60, 255), min(g + 60, 255), min(b + 60, 255))
end

local names = {}
local label_lengths = {
    4, 4, 4, 4, 4, 4;
    4, 4, 4, 4, 4, 4;
    4, 4, 4, 4, 4, 4;
}
local hpp = {
    0, 0, 0, 0, 0, 0;
    0, 0, 0, 0, 0, 0;
    0, 0, 0, 0, 0, 0;
}
local hp = {
    0, 0, 0, 0, 0, 0;
    0, 0, 0, 0, 0, 0;
    0, 0, 0, 0, 0, 0;
}

local grid_map = {}

for i = 1, 3 do
    for j = 1, 6 do
        grid_map[grid[(i - 1) * 6 + j]] = get_alliance_key(i, j)
    end
end

local function center_text(n, s)
    local l = #s

    if l ~= label_lengths[n] then
        label_lengths[n] = l
        grid[n]:element_position('name_or_hpp_est', (size.w - font_w[l]) / 2,(size.h - font_h) / 2)
    end

    labels[n]('set_text', s)
end

overlay:register_event('name change', function(b, party, pos, name)
    local n = (party - 1) * 6 + pos
    names[n] = string.sub(name, 1, 4)

    if hpp[n] > 90 then
        center_text(n, names[n])
    end
end)

local function hpp_change(b, party, pos, new, old)
    local n = (party - 1) * 6 + pos

    if new > 90 then
        if old < 91 then
            center_text(n, names[n])
        end
    elseif new == 0 then
        center_text(n, 'DEAD')
    end

    hpp[n] = new

    local fg = grid[n]:element('foreground')
    fg('set_size', size.w, -size.h * new / 100)
end

overlay:register_event('hpp change', hpp_change)

local function hp_change(b, party, pos, new)
    local n = (party - 1) * 6 + pos
    hp[n] = new

    if new == 0 then return end
    local hpp = hpp[n]
    if hpp > 90 then return end

    local guess = 100 * new / hpp - new
    local fmt = string.format
    center_text(n, guess >= 999.5 and fmt('-%.1f', guess / 1000) or fmt('-%.0f', guess)) -- string.format does not support unspecified precision
end

overlay:register_event('hp change', hp_change)

overlay:register_event('display populated', function(b, party, pos)
    grid[(party - 1) * 6 + pos]:visible(true)
end)

overlay:register_event('display vacant', function(b, party, pos)
    grid[(party - 1) * 6 + pos]:visible(false)
end)

overlay:register_event('zone out', function(b, party, pos)
    local n = (party - 1) * 6 + pos
    center_text(n, names[n])
    grid[n]:element('foreground')('set_size', size.w, -size.h)
end)

overlay:register_event('zone in', function(b, party, pos)
    local n = (party - 1) * 6 + pos

    hpp_change(b, party, pos, hpp[n], -1)
    hp_change(b, party, pos, hp[n], -1)
end)

if settings.use_job_colors then
    overlay:register_event('job change', function(b, party, pos, id)
        local job = string.lower(res.jobs[id].name_short)
        local c = settings.job_colors[job]

        paint_grid((party - 1) * 6 + pos, c.r, c.g, c.b)
    end)
else
    local c = settings.grid_color
    local r, g, b = c.r, c.g, c.b

    for i = 1, 18 do
        paint_grid(i, r, g, b)
    end
end

local root
local user_binds = {}
do
    local b, binds_string_table = keybinds.load(overlay_path .. '/data/binds.lua')

    if b then
        for profile, binds in pairs(binds_string_table) do
            user_binds[profile] = keybinds.get_bind_table(binds)
        end

        root = user_binds.default
        if not root then
            print('No default profile found in binds file.')
        end
    else
        print('Error loading binds file', binds_string_table)
    end
end

local trace = {clock = 0}
overlay:register_event('overlay command', function(b, cmd, ...)
    if cmd == 'profile' or cmd == 'p' then
        local p = ...
        if type(p) ~= 'string' then return end

        if user_binds and user_binds[p] then
            root = user_binds[p]
            trace.pos = root
        else
            print('Did not find profile', p)
        end
    end
end)

local function reset_trace()
    trace.pos = root
end

for i = 1, 18 do
    local g = grid[i]
    g:register_event('focus change', reset_trace)
    g:track()
end

overlay:register_event('keyboard', function(b, dik, down, flags, blocked)
    if not (root and down) or blocked then return end
    local grid = widgets.get_object_with_focus()
    if not grid then return end

    flags = flags > 31 and flags - 32 or flags -- scrape off the chat-line-open bit
    flags = flags > 0 and flags + 0xFF or 0

    local clock = os.clock()
    if clock - trace.clock >= 1 then
        trace.pos = root
    end
    trace.clock = clock

    trace.pos = trace.pos[dik + flags]

    if not trace.pos then
        trace.pos = root
        return false
    end

    if type(trace.pos) == 'string' then
        action(trace.pos, grid_map[grid])
        trace.pos = root

        return true
    -- elseif trace.pos.input then
    --     return function()
    --         if trace.clock == clock then
    --             local s = trace.pos.input
    --             trace.pos = root

    --             return s
    --         end

    --         return false
    --     end
    end

    return true
end)

