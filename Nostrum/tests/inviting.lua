-- Parameters: <party number> <number of players to invite>
local coroutine = require 'coroutine'
local math = require 'math'

dbg_sandbox = dbg_get_sandbox()

local party = dbg_get_party()

local zone = windower.ffxi.get_info().zone

return 'Invites dummy players', function(pt_n, count)
	pt_n = tonumber(pt_n)
	count = tonumber(count)
	count = count and count > 0 and count < 7 and count or 6

	local names = {
		Bahamut = true,
		Tiamat = true,
		Fenrir = true,
		Opoopo = true,
		Cardian = true,
		Ose = true,
		Black3Stars = true,
		Beist = true,
		Habetrot = true,
		BigmouthBilly = true,
		BloodtearBaldurf = true,
		BombKing = true,
		BedrockBarry = true,
		StingingSophie = true,
		LeapingLizzy = true,
		ValkurmEmperor = true,
		JaggedyEaredJack = true,
		SharpEaredRopipi = true,
		TomTitTat = true,
		SpinySpipi = true,
	}

	local function spoof_player()
        local player = {}
		player.hp = math.random(1, 3000)
		player.mp = math.random(1, 3000)
		player.tp = math.random(1, 3000)
		player.hpp = math.random(1, 100)
		player.mpp = math.random(1, 100)
		player.zone = zone
		player.name = next(names)
		player.mob = {
            valid_target = true,
            distance = 10,
            id = math.random(2, 1000),
        }

		names[player.name] = nil

		return player
	end

	if not pt_n then
		for i = 1, count do
			for j = 1, 3 do
                local key = dbg_sandbox.get_alliance_key(j, i)
				local player = party[key]

				if not player then
					player = spoof_player()
					dbg_sandbox.overlay:trigger('display populated', j, i, player)
					dbg_sandbox.overlay:trigger('name change', j, i, player.name)
					dbg_sandbox.overlay:trigger('zone change', j, i, player.zone, 0)
					dbg_sandbox.overlay:trigger('hpp change', j, i, player.hpp, 0)
					dbg_sandbox.overlay:trigger('hp change', j, i, player.hp, 0)
					dbg_sandbox.overlay:trigger('mp change', j, i, player.mp, 0)
					dbg_sandbox.overlay:trigger('mpp change', j, i, player.mpp, 0)
					dbg_sandbox.overlay:trigger('tp change', j, i, player.tp, 0)
					coroutine.sleep(0.3)
                    party[key] = player
				end
			end
		end
	else
		for i = 1, count do
                local key = dbg_sandbox.get_alliance_key(pt_n, i)
				local player = party[key]

				if not player then
					player = spoof_player()
					dbg_sandbox.overlay:trigger('display populated', pt_n, i, player)
					dbg_sandbox.overlay:trigger('zone change', pt_n, i, player.zone, 0)
					dbg_sandbox.overlay:trigger('zone in', pt_n, i)
					dbg_sandbox.overlay:trigger('hpp change', pt_n, i, player.hpp, 0)
					dbg_sandbox.overlay:trigger('hp change', pt_n, i, player.hp, 0)
					dbg_sandbox.overlay:trigger('mp change', pt_n, i, player.mp, 0)
					dbg_sandbox.overlay:trigger('name change', pt_n, i, player.name)
					dbg_sandbox.overlay:trigger('mpp change', pt_n, i, player.mpp, 0)
					dbg_sandbox.overlay:trigger('tp change', pt_n, i, player.tp, 0)
					coroutine.sleep(0.3)
                    party[key] = player
				end
		end
	end
end
