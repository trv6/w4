--[[
	This is not intended to be run via the debug command or
    any time outside of a dsp server.
    It injects a series of incomplete 0x0C8/0x0DD chunks. The
    client builds the display, but sends two x76 chunks to the
    server.
    It was (poorly) written to test a packet parsing function 
    which has since been removed, but it remains useful upon
    occasion.
    Generally, the inviting, kicking and stat_change tests
    should be run instead.
--]]

do return end

do
    local testing = false

    function start()
        testing = true
    end

    function stop()
        testing = false
    end

    function state()
        return testing
    end
end

windower.register_event('outgoing chunk', function(id)
	if state() and id ~= 0x015 then
		print(id)
		return true
	end
end)

--[[windower.register_event('incoming chunk', function(id)
	if id ~= 0x00D and id ~= 0x00E then
		print('Incoming', id)
	end
end)--]]

require 'lists'
require 'pack'
require 'strings'
require 'math'

packets = require 'packets'
packets.raw_fields.incoming[0x0DD][18].ctype = 'char[16]'

local pc = windower.ffxi.get_player()
local pc_mob = windower.ffxi.get_mob_by_index(pc.index)
local zone = windower.ffxi.get_info().zone

local id_counter = pc.id + 1
local index_counter = pc.index + 2223

math.randomseed(os.time())

names = {
	Nerfblu = true,
	Tiamat = true,
	Fenrir = true,
	Opoopo = true,
	Cardian = true,
	Crawler = true,
	Nerfgeo = true,
	Balance = true,
	Matsui = true,
	Heartthunder = true,
	Whatsnu = true,
	Nidhogg = true,
	Adamantoise = true,
	Aspid = true,
	Behemoth = true,
	Valkurm = true,
	Sandoria = true,
	Windurst = true,
	Bastok = true,
	Coffee = true,
}

function new_player()
	id_counter = id_counter + 1
	index_counter = index_counter + 1
	
	local player = {
		ID = id_counter,
		Index = index_counter,
		HP = 249 + math.random(1500),
		MP = 325 + math.random(1800),
		TP = math.random(2999),
		Zone = zone,
		mJob = 18,
		mJob_level = 99,
		sJob = 11,
		sJob_level = 49,
	}
	
	player.HPP = math.floor((player.HP/1749)*100)
	player.MPP = math.floor((player.MP/2125)*100)
	player.name = next(names, nil)
	names[player.name] = nil
	
	return player
end

alliance = {L{}, L{}, L{}}

alliance[1]:append({
	ID = pc.id,
	Index = pc.index,
	name = pc.name,
	Zone = zone,
	mJob = pc.main_job_id,
	sJob = pc.sub_job_id,
	mJob_level = pc.main_job_level,
	sJob_level = pc.sub_job_level,
	HP = pc.vitals.hp,
	MP = pc.vitals.mp,
	HPP = pc.vitals.hpp,
	MPP = pc.vitals.mpp,
	TP = pc.vitals.tp,
	number = 1, -- 0?
	flags = 0,
})

function invite(party)
	if not party or party < 1 or party > 3 then print('Specify party') return end
	local party = alliance[party]

	if party.n >= 6 then
		print('Attempt to add player to full party.')
		return
	end
	
	local player = new_player()
	party:append(player)
	
	local n = party.n
	player.number = n
	
	print('Player ' .. player.name .. ' added to party ' .. tostring(party))
end

function kick(party, n)
	if not n then print('Specify number') return end
	
	local party = alliance[party]
	
	local player = party:remove(n)
	
	-- recycle name
	names[player.name] = true
end

function create_alliance_packet()
	local packet = L{}
	
	packet:append('c':pack(0))
	packet:append(64:char())
	packet:append(7:char())
	packet:append(1:char())
	
	for i = 1, 3 do
		for j = 1, 6 do
			local player = alliance[i][j]
			
			if not player then
				packet:append('I':pack(0))
				packet:append('H':pack(0))
				packet:append('H':pack(0))
				packet:append('H':pack(0))
				packet:append('H':pack(0))
			else
				packet:append('I':pack(player.ID))
				packet:append('H':pack(player.Index))
				packet:append('H':pack((j == 1 and 4 or 0) + i)) -- flags: not sure if p2/3 leader's are also 4 or if there was a bit for each
				packet:append('H':pack(player.Zone))
				packet:append('H':pack(0))
			end
		end
	end
	
	packet:append(0:char():rep(24))
	
	return 0:char():rep(4) .. _raw.table.concat(packet)
end

function inject_packet()
	start()
	local packet = create_alliance_packet()
	
	if not packet or type(packet) ~= 'string' then print('Malformed packet!') return end
	
	windower.packets.inject_incoming(0x0C8, packet)
	
	for i = 1, 3 do
		for j = 1, 6 do
			local player = alliance[i][j]
			local packet
			
			if player then
				packet = packets.new('incoming', 0x0DD, {
					ID = player.ID,
					HP = player.HP,
					MP = player.MP,
					TP = player.TP,
					Flags = player.flags or ((j == 1 and 4 or 0) + i), -- no idea
					_unknown1 = 0,
					Index = player.Index,
					_unknown2 = player.number,
					_unknown3 = 0,
					['HP%'] = player.HPP,
					['MP%'] = player.MPP,
					_unknown4 = 0,
					Zone = player.Zone == zone and 0 or player.Zone,
					['Main job'] = player.mJob,
					['Main job level'] = player.mJob_level,
					['Sub job'] = player.sJob,
					['Sub job level'] = player.sJob_level,
					Name = player.name,
				})				
			else
				packet = packets.new('incoming', 0x0DD, {
					ID = 0,
					HP = 0,
					MP = 0,
					TP = 0,
					Flags = 0, -- no idea
					_unknown1 = 0,
					Index = 0,
					_unknown2 = 0,
					_unknown3 = 0,
					['HP%'] = 0,
					['MP%'] = 0,
					_unknown4 = 0,
					Zone = 0,
					['Main job'] = 0,
					['Main job level'] = 0,
					['Sub job'] = 0,
					['Sub job level'] = 0,
					Name = '',
				})
			end
			
			-- set flags for player
			if j == 1 and i == 1 then
				if alliance[2].n > 0 or alliance[3].n > 0 then
					packet.Flags = 13 -- there's an alliance
				elseif alliance[1].n > 1 then
					packet.Flags = 5 -- there's a party
				else
					packet.Flags = 0 -- solo
				end
			end
			
			packets.inject(packet)	
		end
	end
end

function adjust_stat(name, stat, n)
	if not stat then return end
	if not n then return end
	
	local player_table
	for i = 1, 3 do
		local party = alliance[i]
		
		for j = 1, 6 do
			local player = party[j]
			if not player then break end
			
			if player.name == name then
				player_table = player
			end
		end
	end
	
	if not player_table then print('Couldn\'t find ' .. tostring(name)) return end
			
	local player = {
		ID = player_table.ID,
		Index = player_table.Index,
		HP = player_table.HP,
		MP = player_table.MP,
		TP = player_table.TP,
		HPP = player_table.HPP,
		MPP = player_table.MPP,
		_unknown1 = 0,
		_unknown2 = 0,
		_unknown3 = 0,
		['Main job'] = player_table.mJob,
		['Main job level'] = player_table.mJob_level,
		['Sub job'] = player_table.sJob,
		['Sub job level'] = player_table.sJob_level,
	}
	
	if not player[stat] then print('Couldn\'t find stat ' .. tostring(stat)) return end
	
	player[stat] = n
	player_table[stat] = n
	
	print('Adjusted stat %s to %d':format(stat, n))
	
	if player_table.Zone == zone then
		local packet = packets.new('incoming', 0x0DF, player)
	
		packets.inject(packet)
	end
end

function change_zone(name, zone)
	local player_table
	for i = 1, 3 do
		local party = alliance[i]
		
		for j = 1, 6 do
			local player = party[j]
			if not player then break end
			
			if player.name == name then
				player_table = player
			end
		end
	end
	
	if not player_table then print('Couldn\'t find ' .. tostring(name)) return end
	
	if not zone or type(zone) ~= 'number' then
		print('Bad zone? ' .. tostring(zone))
		return
	end
	
	player_table.Zone = zone
	
	inject_packet()
end

