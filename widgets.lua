local events = require 'libs/events'
local primitives = require 'libs/widgets/primitives'

local widgets = {}

_libs = _libs or {}
_libs.widgets = widgets

_meta = _meta or {}

local click_types = {
	[0]='movement',
	'left button down',
	'left button up',
	nil,
	'right button down',
	'right button up',
	'middle button down',
	'middle button up',
	nil,
	nil,
	'scroll',
	'x button down',
	'x button up',
}

local block_mouse_event = {
	[1] = false, -- 2
	[2] = false,
	[4] = false, -- 5
	[5] = false,
	[6] = false, -- 7
	[7] = false,
	[10] = false,
	[11] = false, -- 12
	[12] = false,
}

local type_to_block = {
	2,
	[4] = 5,
	[6] = 7,
	[11] = 12,
}

local z_order = {}
local hidden = false
local carried_object
local group_with_focus
local object_with_focus
local widget_groups = {}
local contact_point = {nil, nil}
local click = setmetatable({}, {__mode = 'k'})
local global_click = {}
local group_focus_change_lookup = {}
local tracked_objects = {}
local object_event_map = {}

local widget_object = {}

function widget_object.register_event(obj, event, fn)
	local object_events = object_event_map[obj]
	if not object_events then 
		print('track it, dummy')
		return
	end

	return object_events:register_event(event, fn)
end

function widget_object.unregister_event(obj, id)
	local object_events = object_event_map[obj]

	return object_events:unregister_event(id)
end

_meta.WidgetObject = {__index = widget_object}

function widgets.hook_class(class_name)
	if not class_name then return end

	local meta = type(class_name) == 'table' and class_name
		or type(class_name) == 'string' and _meta[class_name]

	if not meta then return end

	local index

	if meta.__index then
		index = meta.__index
	else
		index = {}
		meta.__index = index
	end

	for k, v in pairs(widget_object) do
		index[k] = index[k] or v
	end
	-- local index

	-- repeat
	--	   index = meta.__index
	--	   meta = getmetatable(index)
	-- until not meta

	-- if index ~= widget_object then
	--	   setmetatable(index, _meta.WidgetObject)
	-- end
end

function widgets.define_event(obj, event)
	object_event_map[obj]:define(event)
end

function widgets.set_object_z_order(obj, n)
	if not tracked_objects[obj] then return end

	for i = 1, #z_order do
		local o = z_order[i]

		if o == obj then
			table.remove(z_order, i)
		end
	end

	table.insert(z_order, n, obj)
end

function widgets.visibility(b)
	hidden = not b
	primitives.low_level_visibility(b)
end

function widgets.get_contact_point()
	return contact_point[1], contact_point[2]
end

function widgets.get_object_with_focus()
	return not hidden and object_with_focus
end

function widgets.get_group_with_focus()
	return group_with_focus
end

function widgets.grab_object(obj, x, y)
	if carried_object then
		widgets.drop_object()
	end

	local obj_x, obj_y = obj:pos()

	contact_point[1] = x - obj_x
	contact_point[2] = y - obj_y
	carried_object = obj
	object_event_map[carried_object]:trigger('grab')
end

function widgets.drop_object()
	object_event_map[carried_object]:trigger('drop')
	carried_object = false
	contact_point[1] = 0
	contact_point[2] = 0
end

local function point_collision(obj, x, y)
	local corners = tracked_objects[obj]
	local x1, x2, y1, y2 = corners[1], corners[2], corners[3], corners[4]

	-- print(x1, x2, y1, y2)
	-- print(x >= x1
	--	   and x < x2
	--	   and y >= y1
	--	   and y < y2)

	return x >= x1
		and x < x2
		and y >= y1
		and y < y2
end

local function mouse_event_listener(type, x, y, delta, blocked)
	if blocked or hidden then return end

	if carried_object then
		if type == 0 then -- drag event
			local bail = object_event_map[carried_object] and object_event_map[carried_object]:trigger('drag')

			if not bail then -- Allow objects to define their own drag behavior e.g. scroll bars only drag vertically
				local w, h = carried_object:size()

				carried_object:pos(x - contact_point[1] + (w < 0 and -w or 0), y - contact_point[2] + (h < 0 and -h or 0))

				return true -- Should not call other events if an object is being carried
			end
		elseif type == 2 then -- drop event
			if tracked_objects[carried_object] then
				widgets.update_object(carried_object)
			end

			widgets.drop_object()
			block_mouse_event[2] = false

			return true
		end
	end

	local current_clock = os.clock()

	if type ~= 0 then
		if type_to_block[type] then
			global_click.type = type
			global_click.clock = current_clock
		elseif global_click.type and type == global_click.type + 1 and current_clock - global_click.clock < 0.2 then
			global_click.event = type == 2 and 'left click'
				or type == 5 and 'right click'
				or type == 7 and 'middle click'
				or type == 12 and 'x button click'
		else
			global_click.type = nil
			global_click.clock = nil
			global_click.event = nil
		end
	end

	local hit
	-- determine which object was hit
	-- stop at the first object
	-- for i = #z_order, 1, -1 do
	--	   local obj = z_order[i]

	--	   if obj:visible() and (obj.hover or point_collision)(obj, x, y) then
	--		   hit = obj
	--		   break
	--	   end
	-- end

	local n = #z_order
	if n == 0 then return end

	repeat
		local obj = z_order[n]

		hit = obj:visible() and (obj.hover or point_collision)(obj, x, y) and obj
		n = n - 1
	until hit or n == 0


	if not hit then
		if object_with_focus and object_event_map[object_with_focus] then
			object_event_map[object_with_focus]:trigger('focus change', false)
		end

		object_with_focus = false

		return
	end

	-- focus change
	if type == 0 then
		if object_with_focus then
			if hit ~= object_with_focus then
				local owf = object_with_focus

				object_with_focus = hit
				if object_event_map[owf] then
					object_event_map[owf]:trigger('focus change', false)
				end
				if object_event_map[hit] then
					object_event_map[hit]:trigger('focus change', true)
				end
			end
		else
			object_with_focus = hit
			if object_event_map[hit] then
				object_event_map[hit]:trigger('focus change', true)
			end
		end
	end

	-- process mouse events
	local bail = false
	local click_event

	if type_to_block[type] then
		click[hit] = click[hit] or {}
		click[hit].type = type
		click[hit].clock = current_clock
	elseif click[hit] and click[hit].type == global_click.type and global_click.event then
		click_event = global_click.event
		click[hit] = nil
	end

	if click_event then
		bail = object_event_map[hit]:trigger(click_event, x, y)
	end

	bail = bail or object_event_map[hit]:trigger(click_types[type], x, y, delta)

	if bail then
		block_mouse_event[type] = true
		local paired_click = type_to_block[type]
		if paired_click then block_mouse_event[paired_click] = true end
	end

	if global_click.event then
		global_click.event = nil
		global_click.clock = nil
		global_click.type = nil
	end

	-- block the mouse input
	if block_mouse_event[type] then
		block_mouse_event[type] = false
		return true
	end
end

local function get_boundaries(d, z)
	if d < 0 then
		return z + d, z
	else
		return z, z + d
	end
end

widgets.mouse_listener = mouse_event_listener

function widgets.tracking(obj)
	return tracked_objects[obj] and true
end

function widgets.update_object(obj, x1, x2, y1, y2)
	if not y2 then
		local w, h = obj:size()
		x1, y1 = obj:pos()

		x1, x2 = get_boundaries(w, x1)
		y1, y2 = get_boundaries(h, y1)
	end

	if not tracked_objects[obj] then
		tracked_objects[obj] = {}
	end

	local t = tracked_objects[obj]

	t[1], t[2], t[3], t[4] = x1, x2, y1, y2
end

function widgets.start_tracking_object(obj, z_index, w, h)
	if not h then
		w, h = obj:size()
	end
	local x1, y1 = obj:pos()

	local x2, y2

	x1, x2 = get_boundaries(w, x1)
	y1, y2 = get_boundaries(h, y1)

	local t = {}

	t[1], t[2], t[3], t[4] = x1, x2, y1, y2
	tracked_objects[obj] = t

	if z_index then
		table.insert(z_order, z_index, obj)
	else
		z_order[#z_order + 1] = obj
	end

	object_event_map[obj] = events.new(
		'drag', 'movement', 'left click', 'right click', 'middle click', 'x button click',
		'focus change', 'left button down', 'right button down', 'left button up',
		'right button up', 'middle button down', 'middle button up', 'scroll',
		'x button down', 'x button up', 'grab', 'drop'
	)
end

widget_object.track = widgets.start_tracking_object

function widgets.stop_tracking_object(obj)
	object_event_map[obj]:destroy()
	object_event_map[obj] = nil
	tracked_objects[obj] = nil
	widget_groups[obj] = nil
	for i = 1, #z_order do
		if z_order[i] == obj then
			table.remove(z_order, i)
		end
	end
end

function widgets.stop_tracking()
	for obj in pairs(object_event_map) do
		object_event_map[obj]:destroy()
		object_event_map[obj] = nil
		tracked_objects[obj] = nil
		widget_groups[obj] = nil
	end
	for i = 1, #z_order do
		z_order[i] = nil
	end
end

widget_object.do_not_track = widgets.stop_tracking_object

function widgets.add_object_to_group(obj, group_name)
	widget_groups[obj] = group_name
end

function widgets.remove_object_from_group(obj)
	widget_groups[obj] = nil
end

function widgets.define_group_focus_change(group_name, fn)
	group_focus_change_lookup[group_name] = fn
end

return widgets
