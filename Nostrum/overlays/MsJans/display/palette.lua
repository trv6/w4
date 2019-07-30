local strings = require 'strings'
local groups = require 'widgets/groups'
local buttons = require 'widgets/buttons'
local settings = require 'settings'
local textdb = require('text_dimensions').read('data/textdb.lua')
local primitives = require 'widgets/primitives'
local prims = require 'widgets/prims'
local widgets = require 'widgets'
local profiles = require 'profiles'

local palette = setmetatable({}, {__index = groups})
local palette_meta = {__index = palette}

widgets.hook_class(palette_meta)

local function block_mouse_input()
    return true
end

function palette.new(x, y, visible, button_settings)
    local t = groups.new(x, y, visible)
    rawset(t, 'settings', button_settings) -- simple is fine

    if settings.palette_region.backdrop.visible then
        local c = settings.palette_region.backdrop.color
        local n = #button_settings
        t.backdrop = prims.new(x, y, visible, {
            h = 0,
            w = -1 * n * settings.palette_region.button_width + (n > 0 and -1 or 0),
            set_color = {c.a, c.r, c.g, c.b}
        })
    end

    return setmetatable(t, palette_meta)
end

function palette.update_settings(t, new_settings)
    if not new_settings then return end

    t.settings = new_settings

    if settings.palette_region.backdrop.visible then
        local n = #new_settings
        t.backdrop:size(-1 * n * settings.palette_region.button_width + (n > 0 and -1 or 0), 0)

        n = #t
        for _ = 1, n do
            palette.remove_row(t)
        end
        for _ = 1, n do
            palette.append_row(t)
        end
    end
end

function palette.append_row(t, button_settings)
    button_settings = button_settings or t.settings -- allow override
    local row = #t + 1
    local r = {}
    t[row] = r

    if t.backdrop then
        t.backdrop:height(row * settings.unit_height + 1)
    end

    local group_x, group_y = groups.pos(t)
    local group_visibility = groups.visible(t)
    local palette_settings = settings.palette_region
    local w, h = palette_settings.button_width, settings.unit_height
    local background_visible = palette_settings.button.background_visibility
    -- local image = palette_settings.button.image_visibility

    for i = 1, #button_settings do
        local template = {w = w, h = h}
        local settings = button_settings[i]
        -- local x = group_x + (i - 1) * w + 1
        local x = group_x - (i * w + 1)
        local y = group_y + (row - 1) * h + 1

        if background_visible or settings.color then
            local color = palette_settings.button.color

            template.bg = {
                x = 1,
                y = 0,
                set_color = settings.color or {color.a, color.r, color.g, color.b},
                set_size = {w - 1, h - 1}, -- subtract 1 to spoof a border
            }
        else
            template.bg = {x = 1, y = 0, set_color = {100, 100, 100, 100}, set_size = {w - 1, h - 1}, set_visibility = false}
        end

        local button = buttons.new(x, y, true, template)
        r[i] = button

        if not (background_visible or settings.color) then
            button:element_visibility('background', false)
        end

        if settings.icon then
            local icon = primitives.new('prim', {
                set_texture = addon_path .. 'icons/' .. settings.icon .. '.png',
                set_fit_to_texture = false,
                set_size = settings.icon_size or {w - 1, h - 1},
                set_color = settings.icon_color,
            })

            local off_x, off_y = 0, 0

            if settings.icon_size then
                off_x, off_y = (w - settings.icon_size[1]) / 2, (h - settings.icon_size[2]) / 2
            end

            button:add_element(icon, 'icon', off_x, off_y, true)
        end

        if palette_settings.button.text.visible and settings.text then
            local palette_text_settings = palette_settings.button.text
            local c = palette_text_settings.color
            local font = settings.font or palette_text_settings.font
            local font_size = settings.size or palette_text_settings.size
            local text_settings = {
                set_font_size = font_size,
                set_font = font,
                set_right_justified = settings.right_justified or palette_text_settings.right_justified,
                set_bold = settings.bold or palette_text_settings.bold,
                set_italic = settings.italic or palette_text_settings.italic,
                set_color = settings.text_color or {c.a, c.r, c.g, c.b},
                set_text = tostring(settings.text)
            }

            local dimensions = textdb[font][font_size][settings.text]

            text_settings.x = (w - dimensions.x) / 2
            text_settings.y = (h - dimensions.y) / 2
            text_settings.visible = true

            if settings.stroke_visibility
                or palette_text_settings.stroke_visibility
                and settings.stroke_visibility ~= false then

                local c = palette_text_settings.stroke_color

                text_settings.set_stroke =  true
                text_settings.set_stroke_color = settings.stroke_color or {c.a, c.r, c.g, c.b}
                text_settings.set_stroke_width = settings.stroke_width or palette_text_settings.stroke_width
            end

            button:add_label(text_settings, 'title')
        end

        groups.add_object(t, button, ('button %d %d'):format(row, i))
        if not group_visibility then
            button:visible(false)
        end

        button:track()
        button:register_event('focus change', function(blocked, b)
            if b then
                local bg = button:element('background')

                bg('set_color', 100, 255, 255, 255)
                bg('set_visibility', true)
            else
                if settings.color then
                    button:element('background')('set_color', unpack(settings.color))
                elseif background_visible then
                    local c = palette_settings.button.color
                    button:element('background')('set_color', c.a, c.r, c.g, c.b)
                else
                    button:element('background')('set_visibility', false)
                end
            end
        end)
        button:register_event('left button down', block_mouse_input)
    end
end

function palette.remove_row(t, n)
    n = n or #t
    local identifier = 'button ' .. tostring(n)

    for i, button in pairs(t[n]) do
        button:do_not_track()
        button:destroy()

        local id = identifier .. ' ' .. tostring(i)

        groups.remove_object(t, id)
        t[id] = nil
    end

    t[n] = nil

    if t.backdrop then
        t.backdrop:height((n - 1) * settings.unit_height + (n > 1 and 1 or 0))
    end
end

function palette.destroy(t)
    -- local n = #t

    -- for _ = 1, n do
    --     palette.remove_row(t)
    -- end

    groups.destroy(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

-- dumb functions for spoofing widget alignment
function palette.width(t)
    local n = #t.settings
    return -1 * n * settings.palette_region.button_width + (n > 0 and -1 or 0)
end

function palette.height(t)
    return settings.unit_height * #t
end

function palette.size(t)
    return palette.width(t), settings.unit_height * #t
end

return palette

