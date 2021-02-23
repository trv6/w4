local primitives = require 'libs/widgets/primitives'

local prims = {}
local meta = {}

_meta = _meta or {}
_meta.Prim = _meta.Prim or {}
_meta.Prim.__index = prims

if _libs and _libs.widgets then
	_libs.widgets.hook_class(_meta.Prim)
end

--[[
	settings = {
		w = number,
		h = number,
		set_color = {n, n, n, n}
		set_texture = s,
		...
	}
--]]

function prims.new(x, y, visible, settings)
	local t = {}
	local m = {}

	meta[t] = m

	m.x = x
	m.y = y
	m.w = settings.w
	m.h = settings.h
	m.visible = visible

	if settings.set_color then
		m.a = settings.set_color[1]
		m.r = settings.set_color[2]
		m.g = settings.set_color[3]
		m.b = settings.set_color[4]
	else
		m.a, m.r, m.g, m.b = 255, 255, 255, 255
	end

	if settings.set_visibility == nil then
		settings.set_visibility = visible
	end
	
	m.primitive = primitives.new('prim', settings)
	m.primitive('set_size', settings.w, settings.h)
	m.primitive('set_position', x, y)

	return setmetatable(t, _meta.Prim)
end

function prims.pos(t, x, y)
	local m = meta[t]

	if not y then return m.x, m.y end

	m.primitive('set_position', x, y)
	m.x, m.y = x, y
end

function prims.pos_x(t, x)
	if not x then return meta[t].x end

	local m = meta[t]

	m.primitive('set_position', x, m.y)
	m.x = x
end

function prims.pos_y(t, y)
	if not y then return meta[t].y end

	local m = meta[t]

	m.primitive('set_position', m.x, y)
	m.y = y
end

function prims.destroy(t)
	meta[t].primitive('delete')
	meta[t] = nil

	if _libs.widgets and _libs.widgets.tracking(t) then
		_libs.widgets.stop_tracking_object(t)
	end
end

function prims.size(t, w, h)
	local m = meta[t]

	if not h then return m.w, m.h end

	m.primitive('set_size', w, h)
	m.w, m.h = w, h
end

function prims.width(t, w)
	local m = meta[t]

	if not w then return m.w end

	m.primitive('set_size', w, m.h)
	m.w = w
end

function prims.height(t, h)
	local m = meta[t]

	if not h then return m.h end

	m.primitive('set_size', m.w, h)
	m.h = h
end

function prims.visible(t, b)
	local m = meta[t]

	if b == nil then return m.visible end

	m.primitive('set_visibility', b)
	m.visible = b
end

function prims.hide(t)
	prims.visible(t, false)
end

function prims.show(t)
	prims.visible(t, true)
end

function prims.argb(t, a, r, g, b)
	local m = meta[t]

	m.primitive('set_color', a, r, g, b)
	m.a, m.r, m.g, m.b = a, r, g, b
end

function prims.color(t, r, g, b)
	local m = meta[t]

	if not b then return m.r, m.g, m.b end

	m.primitive('set_color', m.a, r, g, b)

	m.r, m.g, m.b = r, g, b
end

function prims.alpha(t, a)
	local m = meta[t]

	if not a then return m.a end

	m.primitive('set_color', a, m.r, m.g, m.b)

	m.a = a
end

function prims.texture(t, path)
	meta[t].primitive('set_texture', path)
end

function prims.tile(t, x, y)
	meta[t].primitive('set_repeat', x, y)
end

function prims.fit(t, b)
	meta[t].primitive('set_fit_to_texture', b)
end

return prims

