local settings = require 'settings'
local stats = require 'display/stats'
local coroutine = require 'coroutine'

statbar = stats.new(500, 500, true)
assert(statbar, 'stats.new did not return an object')

for _ = 1, 6 do
    statbar:append_row()
    coroutine.sleep(0.3)
end

local function spoof_stats(t)
    local s = t.stats
    local h = t.hpp

    s:element 'hp' ('set_text', 'hp000')
    s:element 'name' ('set_text', 'name567890')
    s:element 'mp' ('set_text', 'mp000')
    s:element 'tp' ('set_text', 'tp00')

    local hpp = math.random(1, 100)
    local c = settings.stat_region.prim.hp_bar_percentage_colors[math.ceil(hpp / 25) * 25]

    s:element 'hpp' ('set_text', tostring(hpp))
    h:percent(hpp)
    h:color(c.a, c.r, c.g, c.b)
end

for i = 1, 6 do
    spoof_stats(statbar[i])
end

for _ = 1, 6 do
    statbar:remove_row()
    coroutine.sleep(1)
end

statbar:pos(100, 100)
local x, y = statbar:pos()
assert(x == 100 and y == 100, 'position not 100, 100')

statbar:append_row()
statbar:pos(500, 600)
coroutine.sleep(1)
statbar:visible(false)
assert(not statbar:visible(), 'statbar visible')
statbar:visible(true)
assert(statbar:visible(), 'statbar not visible')

statbar:destroy()
statbar = nil
