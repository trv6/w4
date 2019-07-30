-- Parameters: <party number> <position> <zone id>
dbg_sandbox = dbg_get_sandbox()
local party = dbg_get_party()

return 'Changes zone for specified display', function(pt_n, pos, zone_id)
    pt_n, pos, zone_id = tonumber(pt_n), tonumber(pos), tonumber(zone_id)
    if not (pt_n and pos) then return end

    local key = dbg_sandbox.get_alliance_key(pt_n, pos)
    local player = party[key]
    local old_zone = player.zone

    if key == 'p0' then return end
    if not player then return end
    if old_zone == zone_id then return end

    dbg_sandbox.overlay:trigger('zone change', pt_n, pos, zone_id)
    party[key].zone = zone_id

    local pz = party.p0.zone

    if pz == zone_id then
        dbg_sandbox.overlay:trigger('zone in', pt_n, pos)
    elseif pz == old_zone then
        dbg_sandbox.overlay:trigger('zone out', pt_n, pos, zone_id)
    end
end
