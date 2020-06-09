local config = require 'config'
local settings = require 'configuration'
local widgets = require 'libs/widgets'
local primitives = require 'libs/widgets/primitives'
local arrangements = require 'libs/widgets/arrangements'

widgets.visibility(false)

windower.register_event('zone change', function()
	widgets.visibility(true)
end)
windower.register_event('status change', function(new, old)
	if new == 4 then
		widgets.visibility(false)
	elseif old == 4 then
		widgets.visibility(true)
	end
end)
windower.register_event('outgoing chunk', function(id)
	if id == 0x00D then
		widgets.visibility(false)
	end
end)

local slots = {}
local window = arrangements.new(settings.pos.x, settings.pos.y, true)
window:add_element(
	primitives.new('prim', {
		set_size = {settings.size, settings.size},
		set_color = {settings.alpha, 0, 0, 0}}
	),
	'bg', 0, 0, true
)

local size = settings.size / 4
local slot_order = {[0] = 0, 1, 2, 3, 4, 9, 11, 12, 5, 6, 13, 14, 15, 10, 7, 8} -- rearrange the slots
for i = 0, 15 do
	local p = primitives.new('prim', {
		set_size = {size, size},
		set_fit_to_texture = false,
		set_visibility = false
	})
	window:add_element(p, slot_order[i], i%4 * size, math.floor(i/4) * size, false)
--	slots[slot_order[i]] = p
end

if settings.track_mouse then
	windower.register_event('mouse', widgets.mouse_listener)

	function window.size(t) -- spoof
		return settings.size, settings.size
	end
	widgets.start_tracking_object(window)

	window:register_event('left button down', function(b, x, y)
		widgets.grab_object(window, x, y)
		return true
	end)
	window:register_event('drop', function()
		local x, y = window:pos()
		settings.pos.x = x
		settings.pos.y = y
		config.save(settings)
	end)
end

config.register(settings, function(s)
	window:pos(s.pos.x, s.pos.y)
	if widgets.tracking(window) then
		widgets.update_object(window)
	end
end)

return window
