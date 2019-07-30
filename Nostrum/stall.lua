local coroutine = require 'coroutine'
local stall = {}
local windower = _G.windower

function stall.for_player(resume)
    while not windower.ffxi.get_player() do
        coroutine.sleep(2)
    end

    resume()
end

function stall.for_alliance(resume, timestamp)
    local _, clock = windower.packets.last_incoming(0x0C8)

    while clock <= timestamp do
        coroutine.sleep(2)
    end

    resume()
end

return stall

