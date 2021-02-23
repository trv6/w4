local bucket = {}
local hidden = false
local primitives = {}

for _, cat in pairs({'text', 'prim'}) do
	local t = {}
	bucket[cat] = t

	local bin = windower[cat]
	local create = bin.create
	local visibility = bin.set_visibility
	local delete = bin.delete

	windower[cat].create = function(name)
		create(name)
		t[name] = true -- prim/text are drawn by default
		if hidden then visibility(name, false) end
	end

	windower[cat].set_visibility = function(name, visible)
		if not hidden then
			visibility(name, visible)
		end

		t[name] = visible
	end

	windower[cat].delete = function(name)
		delete(name)
		t[name] = nil
	end

	windower[cat].rawset_visibility = visibility
end

-- The values returned from the text functions are scaled. Scale them back up.
do
	local windower_settings = windower.get_windower_settings()
	local ui_scale = windower_settings.x_res/windower_settings.ui_x_res

	local extents = windower.text.get_extents
	local location = windower.text.get_location

	windower.text.get_extents = function(name)
		local w, h = extents(name)

		return w * ui_scale, h * ui_scale
	end

	windower.text.get_location = function(name)
		local x, y = location(name)

		return x * ui_scale, y * ui_scale
	end
end

-- In order for this library to function properly, _addon.name must be defined and unique among loaded addons

local seq_name
do
	local n = 0
	seq_name = function(cat)
		n = n + 1
		return (_addon and _addon.name or '') .. '_' .. cat .. '_' .. tostring(n)
	end
end

local function get_name(cat)
	local name = seq_name(cat)
	local saved = bucket[cat]

	while saved[name] ~= nil do -- maybe not great
		name = seq_name(cat)
	end

	return name
end

function primitives.new(cat, settings)
	local name = get_name(cat)

	cat = windower[cat]
	cat.create(name)

	if settings then
		for func, args in pairs(settings) do
			local primitive_function = cat[func]

			if primitive_function then
				if type(args) == 'table' then
					primitive_function(name, unpack(args))
				else
					primitive_function(name, args)
				end
			end
		end
	end

	return function(func, ...)
		return cat[func](name, ...) -- need to return (e.g. get_extents)
	end
end

function primitives.low_level_visibility(b)
	hidden = not b

	for name, is_visible in pairs(bucket.prim) do
		windower.prim.rawset_visibility(name, b and is_visible)
	end

	for name, is_visible in pairs(bucket.text) do
		windower.text.rawset_visibility(name, b and is_visible)
	end
end

function primitives.count()
	local n = 0

	for _ in pairs(bucket.text) do
		n = n + 1
	end

	for _ in pairs(bucket.prim) do
		n = n + 1
	end

	return n
end

function primitives.destroy_all()
	for name in pairs(bucket.text) do
		windower.text.delete(name)
	end
	for name in pairs(bucket.prim) do
		windower.prim.delete(name)
	end
end

windower.text.set_position = windower.text.set_location

windower.register_event('unload', function()
	for name in pairs(bucket.prim) do
		windower.prim.delete(name)
	end

	for name in pairs(bucket.text) do
		windower.text.delete(name)
	end
end)

return primitives
