local serpent = loadfile('C:/users/t/desktop/windower4/addons/Nostrum/libs/serpent.lua')
serpent = serpent()

local job_res = loadfile('C:/users/t/desktop/windower4/res/jobs.lua')
job_res = job_res()

local job_lu = {}
for id, t in pairs(job_res) do
    job_lu[t.ens] = id
end
job_res = nil

local ws_res = loadfile('C:/users/t/desktop/windower4/res/weapon_skills.lua')
ws_res = ws_res()

local ws_lu = {}
for id, t in pairs(ws_res) do
    ws_lu[t.en] = id
end
ws_res = nil

local skill_res = loadfile('C:/users/t/desktop/windower4/res/skills.lua')
skill_res = skill_res()

local skill_list = {}
for i = 1, 12 do
    skill_list[i] = string.lower(skill_res[i].en)
end
for i = 25, 26 do
    table.insert(skill_list, string.lower(skill_res[i].en))
end
skill_res = nil

local f_symbols = io.open('c:/users/t/desktop/ws data/symbols.lua', 'r')
local sym_m_or_s = f_symbols:read('*l')
local sym_na = f_symbols:read('*l')
local sym_m = f_symbols:read('*l')
local sym_w = f_symbols:read('*l')
local sym_REMA = f_symbols:read('*l')
f_symbols:close()

-- format :: ws_id -> s=skill, j=jobs
local main = {}
local sub = {}
local skill = {}
local relic = {}
local merit = {}

-- FILE LOOP
for _, file_name in ipairs(skill_list) do
    local f = io.open('C:/users/t/desktop/ws data/' .. file_name .. '.txt', 'r')
    if not f then print('Could not find file ', file_name) break end

    local job_list = {}
    for job in string.gfind(f:read('*l'), '%u%u%u') do
        table.insert(job_list, job_lu[job])
    end

    for line in f:lines() do
        local first_double_space = string.find(line, '%s%s')
        if not first_double_space then
            print('no double space for line')
            print(line)
            break
        end

        local ws = string.sub(line, 1, first_double_space - 1)
        if not ws_lu[ws] then print('Could not find weapon skill', ws) break end
        ws = ws_lu[ws]

        -- t.n = string.match(l, '%d+')

        local l = line -- oops?
        if string.find(l, '(Relic)', 1, true) then
            table.insert(relic, ws)
        elseif string.find(l, '(Merit)', 1, true) then
            table.insert(merit, ws)
        end

        local start, fin = string.find(l, '%d+')
        if start then
            skill[ws] = tonumber(string.sub(l, start, fin))
        elseif string.find(l, '(Q)', 1, true) then
            skill[ws] = 230
        end

        fin = fin or string.find(l, ')', 1, true)
        l = string.sub(l, fin + 1)

        l = string.gsub(l, '%s', '')
        l = string.gsub(l, sym_m_or_s, 2)
        l = string.gsub(l, sym_na, 0)
        l = string.gsub(l, sym_m, 1)
        l = string.gsub(l, sym_w, 0)
        l = string.gsub(l, sym_REMA, 1)

        assert(#l == #job_list, 'availability does not match')

        for i = 1, #l do
            local c = string.sub(l, i, i)
            if c == '1' then
                main[ws] = main[ws] or 0
                main[ws] = main[ws] + 2 ^ job_list[i]
            elseif c == '2' then
                sub[ws] = sub[ws] or 0
                sub[ws] = sub[ws] + 2 ^ job_list[i]
            end
        end
    end

    f:close()

end
local settings = {comment = false, compact = true}
local to_string = function(t)
    return serpent.line(t, settings)
end

-- local main = {}
-- local sub = {}
-- local skill = {}
-- local relic = {}
-- local merit = {}

f = io.open('c:/users/t/desktop/ws data/out.lua', 'w')
local out_string = 'm = ' .. to_string(merit) .. '\n'
out_string = out_string .. 'r = ' .. to_string(relic) .. '\n'
out_string = out_string .. 's = ' .. to_string(skill) .. '\n'
out_string = out_string .. 'o = ' .. to_string(main) .. '\n'
out_string = out_string .. 'a = ' .. to_string(sub) .. '\n'

f:write(out_string)
f:close()

