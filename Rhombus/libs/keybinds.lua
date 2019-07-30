local io = require 'io'
local flag_map = require 'libs/kb/flags'
local dik_map = require 'libs/kb/dik_codes'
package.loaded['libs/kb/flags'] = nil
package.loaded['libs/kb/dik_codes'] = nil

dik_map['Shift'] = nil
dik_map['Ctrl'] = nil
dik_map['Alt'] = nil
dik_map['Win'] = nil
dik_map['Menu'] = nil

local function load_binds(path)
    if not (path and type(path) == 'string') then
        return false, 'Bad or no path: expected string, got ' ..  type(path) .. ' ' .. tostring(path)
    end

    local t, err = loadfile(path)

    if not t then
        local f = io.open(path, 'r')
        if not f then
            return false, 'No bind file at path ' .. path
        end

        local s = f:read('*all')
        f:close()

        t, err = loadstring('return ' .. s)
        if not t then
            return false, err
        end
    end

    setfenv(t, {})
    t = t()

    if type(t) ~= 'table' then
        return false, 'Expected table from bind file, got ' .. type(t)
    end

    -- for k, v in pairs(t) do
    --     if not (type(k) == 'string' and type(v) == 'string') then
    --         return false, 'Bad bind formatting for pair ' .. tostring(k) .. ' = ' .. tostring(v)
    --     end
    -- end

    return true, t
end

local function tokenizer(sequence)
    local sequence_length = #sequence
    local tokens = {n = 0}
    local i = 1

    while i < sequence_length + 1 do
        local c = string.sub(sequence, i, i)

        if c == '>' then
            error('Mismatched angle bracket at index ' .. tostring(i) .. ' in sequence ' .. sequence)
        elseif c == '}' then
            error('Mismatched curly bracket at index ' .. tostring(i) .. ' in sequence ' .. sequence)
        elseif c == '<' then
            local start, fin, mod_sequence, key_sequence = string.find(sequence, '^<(%u+)-(.-)>', i)
            if not mod_sequence then
                error('Bad formatting for modified sequence at index ' .. tostring(i) .. ' in sequence ' .. sequence)
            elseif key_sequence == '' then
                error('Empty string in modified sequence: ' .. sequence)
            end

            -- local mod_flags = 0xFF
            local t = {n = 0}
            t.m = {n = 0}

            for j = 1, #mod_sequence do
                local modifier_c = string.sub(mod_sequence, j, j)
                if not flag_map[modifier_c] then error('Bad modifier ' .. modifier_c .. ' in sequence ' .. sequence) end

                local n = t.m.n + 1
                t.m.n = n
                t.m[n] = modifier_c
            end

            local j = 1
            local seq_end = #key_sequence + 1

            while j < seq_end do
                local modified_c = string.sub(key_sequence, j, j)

                if modified_c == '{' then
                    local start, fin, long_key = string.find(key_sequence, '^{([^{}]+)}', j)
                    if not long_key then error('Mismatched curly bracket at index ' .. tostring(i + j) .. ' in sequence ' .. sequence) end
                    if not dik_map[long_key] then error('Unknown modified long key ' .. long_key .. ' in sequence ' .. sequence) end

                    local n = t.n + 1
                    t[n] = long_key
                    t.n = n
                    -- dik_sequence[#dik_sequence + 1] = dik_map[long_key] + mod_flags
                    j = fin + 1
                else
                    if not dik_map[modified_c] then error('Unknown modified key ' .. modified_c .. ' in sequence ' .. sequence) end

                    local n = t.n + 1
                    t[n] = modified_c
                    t.n = n
                    -- dik_sequence[#dik_sequence + 1] = dik_map[modified_c] + mod_flags
                    j = j + 1
                end
            end

            local n = tokens.n + 1
            tokens.n = n
            tokens[n] = t

            i = fin + 1
        elseif c == '{' then
            local start, fin, long_key = string.find(sequence, '^{([^{}]+)}', i)
            if not long_key then error('Mismatched curly bracket at index ' .. tostring(i) .. ' in sequence ' .. sequence) end
            if not dik_map[long_key] then error('Unknown long key ' .. long_key .. ' in sequence ' .. sequence) end

            -- dik_sequence[#dik_sequence + 1] = dik_map[long_key]
            local n = tokens.n + 1
            tokens.n = n
            tokens[n] = long_key

            i = fin + 1
        else
            if not dik_map[c] then error('Unknown key ' .. c .. 'in sequence' .. sequence) end

            -- dik_sequence[#dik_sequence + 1] = dik_map[c]
            local n = tokens.n + 1
            tokens.n = n
            tokens[n] = c

            i = i + 1
        end
    end

    return tokens
end

local function tokens_to_dik_codes(tokens)
    local dik_sequence = {n = 0}

    for i = 1, tokens.n do
        local token = tokens[i]

        if type(token) == 'table' then
            local flags = 0xFF

            for j = 1, token.m.n do
                flags = flags + flag_map[token.m[j]]
            end

            local n = dik_sequence.n
            for j = 1, token.n do
                dik_sequence[n + j] = dik_map[token[j]] + flags
            end
            dik_sequence.n = n + token.n
        else
            local n = dik_sequence.n + 1
            dik_sequence.n = n

            dik_sequence[n] = dik_map[token]
        end
    end

    return dik_sequence
end

local function get_bind_table(t)
    local binds = {}

    for sequence, v in pairs(t) do
        local mark = binds
        local dik_sequence = tokens_to_dik_codes(tokenizer(sequence))

        for i = 1, dik_sequence.n - 1 do
            local code = dik_sequence[i]
            local m = mark[code]

            if not m then
                m = {}
                mark[code] = m
            elseif type(m) == 'string' then
                local s = m
                m = {}
                mark[code] = m
                m.input = s
            end

            mark = m
        end

        local dik = dik_sequence[dik_sequence.n]
        local m = mark[dik]

        if m then
            m.input = v
        else
            mark[dik] = v
        end

    end

    return binds
end

local function dbg_tostring(sequence)
    local tokens = tokenizer(sequence)
    local t = {}

    for i = 1, tokens.n do
        local token = tokens[i]

        if type(token) == 'table' then
            t[i] = '[' .. table.concat(token.m, ' + ') .. ' + ' .. table.concat(token, ' > ') .. ']'
        else
            t[i] = token
        end
    end

    return table.concat(t, ' > ')
end

local keybinds = {}

keybinds.load = load_binds
keybinds.get_bind_table = get_bind_table
keybinds.tostring = dbg_tostring
keybinds.dik_tostring = function(sequence)
    local t = tokens_to_dik_codes(tokenizer(sequence))
    for i = 1, t.n do
        t[i] = tostring(t[i])
    end

    return table.concat(t, ' > ')
end

return keybinds

