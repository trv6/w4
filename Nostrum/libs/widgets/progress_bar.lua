local primitives = require 'libs/widgets/primitives'

local meta = {}
local progress_bar = {}

_meta = _meta or {}
_meta.Progress_Bar = _meta.Progress_Bar or {}
_meta.Progress_Bar.__index = progress_bar

function progress_bar.new(x, y, visible, settings)
    local t = {}
    local m = {}

    meta[t] = m

    m.x = x
    m.y = y
    m.w = settings.w
    m.h = settings.h
    m.visible = visible
    m.percent = settings.percent or 100

    settings.set_position = {x, y}
    settings.set_size = {m.w * m.percent / 100, m.h}
    settings.set_visibility = visible

    m.primitive = primitives.new('prim', settings)

    return setmetatable(t, _meta.Progress_Bar)
end

function progress_bar.destroy(t)
    meta[t].primitive('delete')
    meta[t] = nil

	if _libs.widgets and _libs.widgets.tracking(t) then
		_libs.widgets.stop_tracking_object(t)
	end
end

function progress_bar.percent(t, percent)
    if not percent then return meta[t].percent end

    local m = meta[t]

    m.percent = percent
    m.primitive('set_size', m.w * m.percent / 100, m.h)
end

function progress_bar.pos(t, x, y)
    local m = meta[t]

    if not y then return m.x, m.y end

    m.primitive('set_position', x, y)
    m.x, m.y = x, y
end

function progress_bar.visible(t, visible)
    if visible == nil then return meta[t].visible end

    local m = meta[t]

    m.primitive('set_visibility', visible)
    m.visible = visible
end

function progress_bar.color(t, a, r, g, b)
    meta[t].primitive('set_color', a, r, g, b)
end

return progress_bar

