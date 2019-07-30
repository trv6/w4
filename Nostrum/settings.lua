local windower = _G.windower
local os = require 'os'
local io = require 'io'
local table = require 'table'

-- clean up old files
local out_of_date = false
local old_files = {}

for _, old_file in pairs({
    'helperfunctions.lua',
    'variables.lua',
    'prims.lua',
}) do
    local file_path = windower.addon_path .. old_file

    if windower.file_exists(file_path) then
        out_of_date = true
        old_files[file_path] = true
    end
end

if out_of_date then
    local settings_path = windower.addon_path .. 'data/settings.xml'

    if windower.file_exists(settings_path) then
        local hf = loadfile(windower.addon_path .. 'helperfunctions.lua')
        local vars = loadfile(windower.addon_path .. 'variables.lua')
        local sb = setmetatable({}, {__index = _G})

        require 'lists'
        require 'sets'
        require 'tables'

        sb.bit = {}
        setfenv(hf, sb); setfenv(vars, sb); hf(); vars();
        sb.settings = require('config').load()

        local alias = {
            ["Sacrifice"]="S", ["Erase"]="E", ["Blindna"]="B", ["Viruna"]="V",
            ["Cursna"]="C", ["Haste"]="H", ["Haste II"]="H2", ["Flurry"]="F",
            ["Poisona"]={text = "P", text_color = {255, 0, 0, 255}},
            ["Stona"]={text = "S", text_color = {255, 255, 255, 0}},
            ["Paralyna"]={text = "P", text_color = {255, 0, 255, 255}},
            ["Silena"]={text = "S", text_color = {255, 0, 255, 0}},
            ["Protect"]={text = "I", text_color = {255, 0, 255, 255}},
            ["Protect II"]={text = "II", text_color = {255, 0, 255, 255}},
            ["Protect III"]={text = "III", text_color = {255, 0, 255, 255}},
            ["Protect IV"]={text = "IV", text_color = {255, 0, 255, 255}},
            ["Protect V"]={text = "V", text_color = {255, 0, 255, 255}},
            ["Shell"]={text = "I", text_color = {255, 0, 255, 0}},
            ["Shell II"]={text = "II", text_color = {255, 0, 255, 0}},
            ["Shell III"]={text = "III", text_color = {255, 0, 255, 0}},
            ["Shell IV"]={text = "IV", text_color = {255, 0, 255, 0}},
            ["Shell V"]={text = "V", text_color = {255, 0, 255, 0}},
            ["Refresh"]={text = "R", text_color = {255, 0, 0, 255}},
            ["Refresh II"]={text = "R", text_color = {255, 0, 0, 255}},
            ["Flurry II"]="F2", ["Regen"]="R", ["Regen II"]="R", ["Regen III"]="R",
            ["Regen IV"]="R", ["Regen V"]="R", ["Phalanx II"]="X", ["Adloquium"]="A",
            ["Animus Augeo"]="E+", ["Animus Minuo"]="E-", ["Embrava"]="E", ["Healing Waltz"]="W",
        }

        local function aliases(s)
            return alias[s] or sb.options.aliases[s] or '???'
        end

        local profile = {}

        for name, spell_set in pairs(sb.settings.profiles) do
            sb.macro_order = T{nil, L{}, nil, L{}, L{}}
            sb.count_cures(spell_set)
            sb.count_na(spell_set)
            sb.count_buffs(spell_set)

            local main = sb.macro_order[1]:reverse()
            local buff = sb.macro_order[5]:reverse()
            local debuff = sb.macro_order[4]:reverse()
            local p = {main = {}, debuff = {}, buff = {}}
            profile[name] = p

            for i = 1, main.n do
                local a = aliases(main[i])

                if type(a) == 'string' then
                    p.main[i] = {action = main[i], text = aliases(main[i])}
                elseif type(a) == 'table' then
                    a.action = main[i]
                    p.main[i] = table.copy(a)
                end
            end

            for i = 1, buff.n do
                local a = aliases(buff[i])

                if type(a) == 'string' then
                    p.buff[i] = {action = buff[i], text = aliases(buff[i])}
                elseif type(a) == 'table' then
                    a.action = buff[i]
                    p.buff[i] = table.copy(a)
                end
            end

            for i = 1, debuff.n do
                local a = aliases(debuff[i])

                if type(a) == 'string' then
                    p.debuff[i] = {action = debuff[i], text = aliases(debuff[i])}
                elseif type(a) == 'table' then
                    a.action = debuff[i]
                    p.debuff[i] = table.copy(a)
                end
            end
        end

        os.rename(settings_path, windower.addon_path .. 'overlays/MsJans/data/old_v1_settings_copy.xml')

        local f = io.open(windower.addon_path .. 'overlays/MsJans/data/auto_converted_profile.lua', 'w')
        f:write(require('libs/serpent').block(profile, {comment = false, fatal = true, nohuge = true}))
        f:close()
    end

    for old_file in pairs(old_files) do
        os.remove(old_file)
    end
end

return require('config').load({
    overlay = out_of_date and 'MsJans' or '',
    send_commands_to = '',
    debug = false,
    client_path = ''
})

