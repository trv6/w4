local widgets = require 'widgets'
local prims = require 'widgets/prims'
local groups = require 'widgets/groups'
local buttons = require 'widgets/buttons'
local progress_bars = require 'widgets/progress_bar'
local settings = require 'settings'
local stat_settings = settings.stat_region

local stat_display = setmetatable({}, {__index = groups})
local stat_meta = {__index = stat_display}

widgets.hook_class(stat_meta)

do
    for _, text_settings in pairs(settings.stat_region.text) do
        local c = text_settings.color
        if c then
            text_settings.color = {c.a, c.r, c.g, c.b}
        end
    end
end

local function new(x, y, visible)
    local w = stat_settings.prim.width
    local button = buttons.new(x, y, true, { -- visible to spoof group
        w = w,
        h = settings.unit_height,
    })

    for text, settings in pairs(stat_settings.text) do
        if settings.visible then
            button:add_label({
                x = settings.offset.x + w, -- Whoooooops
                y = settings.offset.y,
                visible = settings.visible,
                set_bold = settings.bold,
                set_italic = settings.italic,
                set_color = settings.color,
                set_font_size = settings.font_size,
                set_font = settings.font,
                set_right_justified = settings.right_justified,
            }, text)
        end
    end

    local hpp = progress_bars.new(x + 1, y + 1, visible, {
        w = w - 2,
        h = settings.unit_height - 2,
    })

    local mph = settings.stat_region.prim.mp_bar.height
    -- mp_bar.color
    local mpc = settings.stat_region.prim.mp_bar.color
    local mpp = progress_bars.new(x + 1, y + settings.unit_height - mph, visible, {
        w = w - 2,
        h = mph,
        set_color = {mpc.a, mpc.r, mpc.g, mpc.b},
    })


    return button, hpp, mpp
end

function stat_display.new(x, y, visible)
    local t = groups.new(x, y, visible)

    if stat_settings.prim.bg.visible then
        local c = stat_settings.prim.bg.color

        t.bg = prims.new(x, y, visible, {
            w = stat_settings.prim.width,
            h = 0,
            visible = visible,
            set_color = {c.a, c.r, c.g, c.b}
        })
    end

    return setmetatable(t, stat_meta)
end

function stat_display.append_row(t)
    local x, y = groups.pos(t)
    local n = #t
    local b, p, q = new(x, y + settings.unit_height * n, groups.visible(t))

    t[n + 1] = {stats = b, hpp = p, mpp = q}

    if t.bg then
        t.bg:height(settings.unit_height * (n + 1))
    end

    local ns = tostring(n + 1)
    groups.add_object(t, b, 'button ' .. ns)
    groups.add_object(t, p, 'hpp bar ' .. ns)
    groups.add_object(t, q, 'mpp bar ' .. ns)
end

function stat_display.remove_row(t)
    local n = #t
    local u = t[n]

    u.stats:destroy()
    u.hpp:destroy()
    groups.remove_object(t, u.stats)
    groups.remove_object(t, u.hpp)

    t.bg:height(settings.unit_height * (n - 1))

    u.stats = nil
    u.hpp = nil
    t[n] = nil
end

function stat_display.destroy(t)
    groups.destroy(t)

    for i = 1, #t do
        t[i] = nil
    end

    t.bg = nil
end

-- dumb functions added for widget alignment
function stat_display.width(t)
    return settings.stat_region.prim.width
end

function stat_display.height(t)
    return settings.unit_height * #t
end

function stat_display.size(t)
    return settings.stat_region.prim.width, settings.unit_height * #t
end

return stat_display

