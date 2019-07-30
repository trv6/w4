local table = require 'table'

local meta = {}
local groups = {}

_meta = _meta or {}
_meta.Group = _meta.Group or {__index = groups, __newindex = function(t, k, v)
    local m = meta[t]

    rawset(t, k, v)

    local n = m.n + 1
    m.n = n

    m.members[n] = v
end}

function groups.new(x, y, visible)
    local m = {}
    local t = {}

    meta[t] = m

    m.members = {}
    m.x = x
    m.y = y
    m.n = 0
    m.visible = visible

    return setmetatable(t, _meta.Group)
end

function groups.destroy(t)
    local m = meta[t]
    local members = m.members

    for i = 1, m.n do
        members[i]:destroy()
        members[i] = nil
    end

    meta[t] = nil

	if _libs.widgets and _libs.widgets.tracking(t) then
		_libs.widgets.stop_tracking_object(t)
	end
end

function groups.pos(t, x, y)
    local m = meta[t]

    if not y then return m.x, m.y end

    local x_distance, y_distance = x - m.x, y - m.y

    for i = 1, m.n do
        local obj = m.members[i]
        local objx, objy = obj:pos()

        obj:pos(objx + x_distance, objy + y_distance)
    end

    m.x, m.y = x, y

end

function groups.visible(t, visible)
    local m = meta[t]

    if visible == nil then return m.visible end

    if visible then
        if m.temp_visibility_record then
            for obj, v in pairs(m.temp_visibility_record) do
                if v then obj:visible(true) end
            end

            m.temp_visibility_record = nil
        else
            for i = 1, m.n do
                m.members[i]:visible(true)
            end
        end
    else
        m.temp_visibility_record = {}

        for i = 1, m.n do
            local obj = m.members[i]
            local obj_visibility = obj:visible()

            m.temp_visibility_record[obj] = obj_visibility

            if obj_visibility then
                obj:visible(false)
            end
        end

    end

    m.visible = visible
end

function groups.add_object(t, obj, id)
    local m = meta[t]
    local n = m.n + 1
    m.n = n

    m.members[n] = obj

    rawset(t, id, obj)

    -- match visibility?
    if m.temp_visibility_record then
        local visible = obj:visible()

        m.temp_visibility_record[obj] = visible

        if visible then obj:visible(false) end
    end
end

function groups.remove_object(t, obj) -- not expected to be used frequently
    local m = meta[t]
    local id

    if type(obj) == 'string' or type(obj) == 'number' then -- passed the id
        id, obj = obj, t[obj]
    else -- get the id
        for k, v in pairs(t) do
            if v == obj then
                id = k
            end
        end
    end

    local members = m.members

    for i = 1, m.n do
        if members[i] == obj then
            table.remove(members, i)
            m.n = m.n - 1
        end
    end

    t[id] = nil -- remember to destroy before removing from group?

    if m.temp_visibility_record then
        m.temp_visibility_record[obj] = nil
    end
end

return groups

