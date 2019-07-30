local serpent = loadfile('C:/users/t/desktop/windower4/addons/Nostrum/libs/serpent.lua')
serpent = serpent()

local res = loadfile('C:/users/t/desktop/windower4/res/job_abilities.lua')
res = res()

local name_map = {}
for id, info in pairs(res) do
    name_map[info.en] = info
end

local jobs = loadfile('C:/users/t/desktop/windower4/res/jobs.lua')
jobs = jobs()

-- local ja_job_map = {}
local map = {}
map.levels = {}
map.jobs = {}
map.meritable = {n = 0}
-- job = id, level = number, merit = boolean
-- local meta = {__tostring = function(t) return '{job=' .. tostring(t.job) .. ',level=' .. tostring(t.level) .. ',merit=' .. tostring(t.merit) .. '}' end}

local n = map.meritable.n

for i = 1, 22 do
    local job = string.lower(jobs[i].ens)

    for line in io.lines('C:/users/t/desktop/windower4/addons/rhombus_dev/notma/' .. job .. '.txt') do
        -- local entry = {}
        local _, mp = string.find(line, 'Merit Points')
        local level = tonumber(string.match(line, '^%d+'))

        local name = string.match(line, '%s+(%u.+)$', mp)
        -- ja_job_map[res[name].id] = entry
        -- setmetatable(entry, meta)
        local id = name_map[name].id
        map.levels[id] = level
        map.jobs[id] = i
        -- entry.l = level
        if mp then -- omit m key for space unless it would be true
            -- entry.m = true
            n = n + 1
            map.meritable[n] = id
            -- map.meritable[id] = true
        end
        -- entry.j = i

    end
end

map.meritable.n = n

local category = {
    'Stratagems', 'Blood Pact: Rage', 'Sambas', 'Waltzes', 'Steps', 'Flourishes I', 'Flourishes II', 'Flourishes III',
    'Blood Pact: Ward', 'Phantom Roll', 'Rune Enchantment', 'Jigs', 'Ready', 'Quick Draw'
}

do
	local t = {}
	for _, v in pairs(category) do
		t[v] = true
	end
	
	category = t
end

for id, t in pairs(res) do
	if not map.jobs[id] then
		if t.type == 'CorsairShot' then
			map.jobs[id] = 17
			map.levels[id] = 40
		elseif not (
		category[t.en]
		or string.find(t.en, 'Healing Breath')
		or (t.en ~= 'Choke Breath' and string.find(t.en, 'Breath')) then
			map.jobs[id] = 9
		end
	end
end

map.jobs[382] = 23
map.levels[382] = 1

local out = io.open('C:/users/t/desktop/windower4/addons/rhombus_dev/notma/out.lua', 'w')

out:write(serpent.line(map, {comment = false, compact = true}))

-- 75 Merit Points 	Rayke
-- 85 	Liement
