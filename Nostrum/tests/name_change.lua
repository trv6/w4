-- Parameters: <party number> <position> <name>
dbg_sandbox = dbg_get_sandbox()
local party = dbg_get_party()
return 'Updates name for given display', function(pt_n, pos, name)
    if not name then return end
    pt_n, pos = tonumber(pt_n), tonumber(pos)

    local key = dbg_sandbox.get_alliance_key(pt_n, pos)
    print(key, pt_n, pos)
    local player = party[key]

    player.name = name
    dbg_sandbox.overlay:trigger('name change', pt_n, pos, name)
end

