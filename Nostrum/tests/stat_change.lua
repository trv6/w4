-- Parameters: <stat> <party number> <position> <value>
dbg_sandbox = dbg_get_sandbox()
local party = dbg_get_party()
return 'Calls <stat> change event', function(stat, pt_n, pos, value)
    if not value then return end
    pt_n, pos, value = tonumber(pt_n), tonumber(pos), tonumber(value)

    local key = dbg_sandbox.get_alliance_key(pt_n, pos)
    local player = party[key]
    local old_value = player[stat]

    if not old_value or old_value == value then return end

    player[stat] = value
    dbg_sandbox.overlay:trigger(stat .. ' change', pt_n, pos, value, old_value)
end

