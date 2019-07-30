local primitives = require 'libs/widgets/primitives'
local arrangements = require 'libs/widgets/arrangements'

local buttons = {}
local meta = {}

_meta = _meta or {}
_meta.Button = _meta.Button or {}
_meta.Button.__index = setmetatable(buttons, _meta.Arrangement)

if _libs and _libs.widgets then
    _libs.widgets.hook_class(_meta.Button)
end

--[[
    x = number,
    y = number,
    visible = b,
    settings = {
        w = number,
        h = number,
        bg = {
            x = x_offset,
            y = y_offset,
            set_color = {n, n, n, n}
            set_texture = s,
        },
        labels = {},
    }
    labels = {
        foo = {
            x = x_offset,
            y = y_offset,
            set_text = s,
            set_font = s,
            ...
        },
        ...
    }
--]]

function buttons.new(x, y, visible, settings)
    local t = arrangements.new(x, y, visible)
    local m = {}

    meta[t] = m

    m.w = settings.w
    m.h = settings.h

    if settings.bg then
        settings.bg.set_size = settings.bg.set_size or {settings.w, settings.h}
        t:add_element(primitives.new('prim', settings.bg), 'background', settings.bg.x or 0, settings.bg.y or 0, true)
    end

    if settings.labels then
        for id, label in pairs(settings.labels) do
            t:add_element(primitives.new('text', label), id, label.x or 0, label.y or 0, label.visible)
        end
    end

    return setmetatable(t, _meta.Button)
end

function buttons.add_label(t, label, id)
    arrangements.add_element(t, primitives.new('text', label), id, label.x, label.y, label.visible)
end

function buttons.remove_label(t, id)
    arrangements.remove_element(t, id)
end

function buttons.destroy(t)
    meta[t] = nil
    arrangements.destroy(t)
end

function buttons.size(t, w, h)
    local m = meta[t]

    if not h then return m.w, m.h end

    m.w, m.h = w, h
end

function buttons.width(t, w)
    return meta[t].w
end

function buttons.height(t, h)
    return meta[t].h
end

return buttons

