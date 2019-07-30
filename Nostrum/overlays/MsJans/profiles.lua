local serpent = require 'serpent'
local files = require 'files'

local defaults = [[{
    default = {
        main = {},
        debuff = {},
        buff = {}
    },
    example = {
        main = {
            {action = 'Curaga III', text = 'III',},
            {action = 'Curaga II', text = 'II',},
            {action = 'Curaga', text = 'I',},
            {action = 'Cure IV', text = '4',},
            {action = 'Cure III', text = '3',},
            {action = 'Cure II', text = '2',},
            {action = 'Cure', text = '1',},
        },
        debuff = {
            {action = 'Sacrifice', text = 'S',},
            {action = 'Viruna', text = 'V',},
            {action = 'Stona', text = 'S', color = {199, 255, 255, 0},},
            {action = 'Cursna', text = 'C',},
            {action = 'Blindna', text = 'B',},
            {action = 'Poisona', text = 'P',},
            {action = 'Silena', text = 'S', color = {199, 0, 255, 0},},
            {action = 'Paralyna', text = 'P', color = {199, 0, 255, 255},},
            {action = 'Erase', text = 'E',},
        },
        buff = {
            {action = 'Haste 2', color = {255, 255, 0, 0}, text = '2', text_color = {100, 0, 0, 0}},
            {action = 'Haste', color = {255, 255, 0, 0},},
        }
    }
}]]

local f = files.new('data/user_profiles.lua')
local user_profiles

if f:exists() then
    local success, err = loadfile(overlay_path .. 'data/user_profiles.lua')--loadstring(f:read())-- serpent.load(f:read())

    if not success then
        local s = f:read()

        success, err = loadstring('return ' .. s)
        if not success then
            error('Loading profiles failed:\n' .. err)
        end
    end

    setfenv(success, {})
    success = success()

    if type(success) ~= 'table' then
        error('Loaded profile has type: ' .. type(success) .. '. Table expected.')
    end

    user_profiles = success
else
    f:create()
    f:write(defaults)
    user_profiles = loadstring('return ' .. defaults)()
end

for title, profile in pairs(user_profiles) do
    local party_spells = {}
    local alliance_spells = {}

    for cat, spell_table in pairs(profile) do
        local ps = {n = 0}
        local as = {n = 0}

        party_spells[cat] = ps
        alliance_spells[cat] = as

        for i = 1, #spell_table do
            local st = spell_table[i]
            local res_entry = action(st.action, '')

            if res_entry then
                local targets = res_entry.targets

                if targets:contains('Party') then
                    local n = ps.n + 1

                    ps.n = n
                    ps[n] = st
                end

                if targets:contains('Ally') then
                    local n = as.n + 1

                    as.n = n
                    as[n] = st
                end
            else
                print('In user_profile ' .. tostring(title) .. ': no resource table for action ' .. tostring(st.action))
            end
        end
    end

    profile.party = party_spells
    profile.alliance = alliance_spells
end

return user_profiles

