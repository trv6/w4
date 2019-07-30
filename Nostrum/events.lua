local meta = {}
_meta = _meta or {}

local events = {}
_meta.Events = {__index = events}
local registry = {}
_meta.Registry = {__index = registry}

function registry.new()
    return setmetatable({n = 0}, _meta.Registry)
end

function registry.add(t, fn)
    if type(fn) ~= 'function' then return end

    local n

    for i = 1, t.n do
        if not t[i] then
            n = i
            break
        end
    end

    if not n then
        n = t.n + 1
        t.n = n
    end

    t[n] = fn
end

function registry.count(t)
    local n = 0

    for i = 1, t.n do
        if t[i] then
            n = n + 1
        end
    end

    return n
end

function registry.remove(t, n)
    if type(n) ~= 'number' then print('Expected number, got ' .. type(n), 2) end

    local fn = t[n]
    if not fn then print('There was no entry at position ' .. tostring(n)) end
    t[n] = nil

    if n == t.n then
        for i = t.n - 1, 0, -1 do
            t.n = i

            if t[i] then
                break
            end
        end
    end

    return fn
end

function events.new(...)
    local l = {...}
    local z = {}
    local m = {}
    local t = {}
    meta[t] = m

    for _, v in pairs(l) do
        z[v] = true
        l[_] = nil
    end
    l[0] = z
    m.registries = l
    m.map = {n = 0}

    return setmetatable(t, _meta.Events)
end

function events.count(t, event)
    local r = meta[t].registries[event]
    return r and r:count() or 0
end

function events.define(t, event)
    meta[t].registries[0][event] = true
end

function events.register_event(t, event, fn)
    if not event then
        print('Event not specified', 2)
    elseif type(event) ~= 'string' then
        print('Expected string, got ' .. type(event), 2)
    end

    local m = meta[t]

    if not m.registries[0][event] then
        print('Event not defined: ' .. event, 2)
    end

    local r = m.registries[event]
    if not r then
        r = registry.new()
        m.registries[event] = r
    end

    local id = r:add(fn)
    local map = m.map
    local n

    for i = 1, map.n do
        if not map[i] then
            n = i
            break
        end
    end

    if not n then
        n = map.n + 1
        map.n = n
    end

    map[n] = {id = id, event = event}

    return n
end

function events.unregister_event(t, n)
    if type(n) ~= 'number' then
        print('Expected number, got ' .. type(n), 2)
    end

    local m = meta[t]
    local map = m.map[n]

    if not map then
        print('No event registered with id ' .. tostring(n), 2)
    end

    local f = m.registries[map.event]:remove(m.id)
    map[n] = nil

    return f
end

function events.trigger(t, event, ...)
    if not meta[t].registries[0][event] then
        print('No such event: ' .. tostring(event))
        return
    end

    local m = event and meta[t].registries[event]
    if not m then return end

    local b = false

    for i = 1, m.n do
        if m[i] then
            -- have to pass the "blocked" argument first, I guess
            local success, retval = pcall(m[i], b, ...)
            if not success then
                print(retval)
            end

            b = b or retval
        end
    end

    return b
end

function events.destroy(t)
    meta[t] = nil
end

return events

