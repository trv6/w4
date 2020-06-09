_addon.name = 'AltE'

local string = require 'string'
local math = require 'math'
local stall = require 'libs/stall'
local widgets = require 'libs/widgets'
local datrw = require 'libs/datrw'
local settings = require 'configuration'
local extractor = require('libs/icon_extractor').item_icon
local coroutine = require 'coroutine'
local window = require 'ui'
require 'pack'

local visible = true
function visible()
	visible = not visible
	widgets.visibility(visible)
end

windower.addon_path = string.gsub(windower.addon_path, '\\', '/') -- make console printing pretty
windower.pol_path = string.gsub(windower.pol_path, '\\', '/')

local weapons_dat = datrw.open('items', 'weapons')
local armor_dat = datrw.open('items', 'armor')
local armor2_dat = datrw.open('items', 'armor2')

local temporary_files = {n=0}

windower.register_event('unload', function()
	for i = 1, temporary_files.n do
		os.remove(temporary_files[i])
	end
end)

local function get_icon_path(item_id)
	local expected_path = windower.addon_path .. '/icons/' .. tostring(item_id) .. '.bmp'
	local f = io.open(expected_path, 'rb')
	if f then
		f:close()
		return expected_path
	end
	if item_id > 23039 then
		extractor(item_id - 23040, armor2_dat, expected_path)
	elseif item_id > 16383 then
		extractor(item_id - 16384, weapons_dat, expected_path)
	else
		extractor(item_id - 10240, armor_dat, expected_path)
	end

	local n = temporary_files.n
	n = n + 1
	temporary_files[n] = expected_path
	temporary_files.n = n

	return expected_path
end

local slots = {}
for i = 0, 15 do
	slots[i] = window:element(i)
end

local timestamp = 0
local function run_conditions() -- player structure must exist and inventory should be finished loading
	if not windower.ffxi.get_player() then return false end
	local _, inventory_finished_time = windower.packets.last_incoming(0x01D)
	local _, inventory_assign_time = windower.packets.last_incoming(0x01F)
	local _, zone_out_time = windower.packets.last_outgoing(0x00D)
	
	if not inventory_finished_time then return false end
	if zone_out_time and zone_out_time > inventory_finished_time then return false end
	
	return true
end

local big_bag = {}
local function first_pass()
	local bag_names = {}
	for k, v in pairs(require('resources').bags) do
		bag_names[k] = string.gsub(string.lower(v.name), ' ', '')
	end
	local items = windower.ffxi.get_items()
	for i = 0, 12 do
		local bag = items[bag_names[i]]
		if bag then
			for j = 1, 80 do
				local item = bag[j]
				big_bag[i*80 + j] = item and item.id or 0
			end
		end
	end
	local equipment = items.equipment
	local slot_names = require('resources').slots
	for i = 0, 15 do
		local gross_api_name = string.gsub(string.lower(slot_names[i].name), ' ', '_') -- windower api is not always a joy to work with
		local bag, index = bag_names[equipment[gross_api_name .. '_bag']], equipment[gross_api_name]
		if index ~= 0 then
			local id = items[bag][index].id
			window:element_visibility(i, true)
			slots[i]('set_texture', get_icon_path(id))
		else
			window:element_visibility(i, false)
		end
	end
	
	widgets.visibility(true)
	window:visible(true)
end

local carry = false
local clock
local function timeout()
	if settings.track_mouse and carry then return end
	
	local diff = os.clock() - clock
	if diff >= settings.timeout or settings.timeout - diff < 0.5 then
		window:visible(false)
	end
end
if settings.timeout > 0 and settings.track_mouse then
	window:register_event('grab', function() carry = true end)
	window:register_event('drop', function() carry = false coroutine.schedule(timeout, settings.timeout) end)
end

local unpack = string.unpack
windower.register_event('incoming chunk', function(id, data)
	if id == 0x01F then
		local id, bag, index = unpack(data, 'HCC', 9)
		big_bag[bag * 80 + index] = id
	elseif id == 0x050 then
		local index, slot, bag = unpack(data, 'CCC', 5)
		if index == 0 then
			window:element_visibility(slot, false)
			if settings.timeout > 0 then
				window:visible(true)
				clock = os.clock()
				coroutine.schedule(timeout, settings.timeout)
			end

			return
		end
		
		local item = big_bag[bag * 80 + index]
		if not item then return end -- still loading
		
		window:element_visibility(slot, true)
		slots[slot]('set_texture', get_icon_path(item))
		
		if settings.timeout > 0 then
			window:visible(true)
			clock = os.clock()
			coroutine.schedule(timeout, settings.timeout)
		end
	end
end)

windower.register_event('login', 'load', function()
	stall.for_condition(run_conditions, first_pass, 'start the thing')
end)
windower.register_event('logout', function()
	widgets.visibility(false)
	for k in pairs(big_bag) do
		big_bag[k] = nil
	end
end)
