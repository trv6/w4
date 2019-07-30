local coroutine = require 'coroutine'

dbg_sandbox = dbg_get_sandbox()
local party = dbg_get_party()

return 'Kicks dummy players', function(pt_n, pos)
    pt_n = tonumber(pt_n)
    pos = tonumber(pos)
	pos = pos and pos > 0 and pos < 7 and pos or 6
    if not pos then print('need arguments') return end

    local key = dbg_sandbox.get_alliance_key(pt_n, pos)
    if party[key] then
        dbg_sandbox.overlay:trigger('display vacant', pt_n, pos)
        party[key] = nil
        coroutine.sleep(0.3)
    else
        print('no player with key ' .. key)
    end
end

