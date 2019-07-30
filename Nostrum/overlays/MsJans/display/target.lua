local math = require 'math'
local groups = require 'widgets/groups'
local buttons = require 'widgets/buttons'
local progress_bars = require 'widgets/progress_bar'
local settings = require 'settings'

local function new(x, y, visible)
    local bg_settings = settings.stat_region.prim.bg
    local target_settings = settings.target_region
    target_settings.text.name.visible = true
    local w, h = target_settings.width, target_settings.height

    local bg
    if bg_settings.visible then
        bg = {}
        bg.set_color = {
            bg_settings.color.a,
            bg_settings.color.r,
            bg_settings.color.g,
            bg_settings.color.b,
        }

    end

    local button = buttons.new(x, y, true, { -- visible to spoof group
        w = w,
        h = h,
        bg = bg,
    })

    for text, settings in pairs(target_settings.text) do
        if settings.visible then
            button:add_label({
                x = settings.offset.x + w, -- offset is defined relative to rhs
                y = settings.offset.y,
                visible = settings.visible,
                set_bold = settings.bold,
                set_font_size = settings.font_size,
                set_font = settings.font,
                set_right_justified = settings.right_justified,
            }, text)
        end
    end

    local hpp = progress_bars.new(x + 1, y + 1, visible, {
        w = w - 2,
        h = h - 2,
    })

    local color = settings.stat_region.prim.hp_bar_percentage_colors[100]
    hpp:color(color.a, color.r, color.g, color.b)

    if not visible then button:visible(false) end

    return button, hpp
end

local target = setmetatable({}, {__index = groups})

function target.new(x, y, visible)
    local t = groups.new(x, y, visible)

    t.stat, t.hpp = new(x, y, visible)

    return setmetatable(t, {__index = target})
end

function target.destroy(t)
    t.stat:destroy()
    t.hpp:destroy()
end

function target.update_name(t, s)
    t.stat:element('name')('set_text', s)
end

do
    local ceil = math.ceil

    function target.update_hpp(t, new, old)
        t.hpp:percent(new)
        t.stat:element('hpp')('set_text', tostring(new))

        if new == 0 then return end

        local n = ceil(new / 25)

        if ceil(old / 25) ~= n then
            local color = settings.stat_region.prim.hp_bar_percentage_colors[n * 25]

            t.hpp:color(color.a, color.r, color.g, color.b)
            -- the world "color" is starting to look weird
        end
    end
end

function target.update(t, new, old)
    t:update_name(new.name)
    t:update_hpp(new.hpp, old and old.hpp or t.hpp:percent())
end

return target

