local coroutine = require 'coroutine'
local dbg_sandbox = dbg_get_sandbox()
local party = dbg_get_party()

return 'Status change event with predetermined buffs.', function(pos)
    if not party['p' .. tostring(pos - 1)] then
        print('Couldn\'t add statuses at position ' .. tostring(pos) .. '. No player in position.')
        return
    end

    dbg_sandbox.overlay:trigger('statuses updated', pos, {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, n = 10})

    coroutine.sleep(3)

    dbg_sandbox.overlay:trigger('statuses updated', pos,
    {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, n = 26})

    coroutine.sleep(3)

    dbg_sandbox.overlay:trigger('statuses updated', pos, {22, 222, 33, 333, n = 4})
end
