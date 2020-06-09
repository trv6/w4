local lookup = {}
local en = {}
lookup.en = en

en.sts_icon = 88

local items = {}
en.items = items

-- I might be off by one
items.general = 74
items.usable = 75
items.weapons = 76 --8
items.armor = 77 --9
items.armor2 = 55669 --55549
items.automaton = 78

-- local maps = {} -- I have no idea how these are arranged.

-- this block courtesy of fface
en.areas = 55465
en.statuses = 55725
en.job_short = 55468
en.job_long = 55467
en.spells = 55702
en.abilities = 55701
en.weather = 55657
en.days = 55658
en.moon_phase = 55660
en.regions = 55654
en.races = 55469

return lookup
