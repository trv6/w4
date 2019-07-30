local meta = {}
local arrangements = {}

_meta = _meta or {}
_meta.Arrangement = _meta.Arrangement or {__index = arrangements}

function arrangements.new(x, y, visible)
    local t = {}
    local m = {}
    meta[t] = m

    m.x_offsets = {}
    m.y_offsets = {}
    m.map = {}
    m.element_visibility = {}
    m.visible = visible
    m.x = x
    m.y = y

    return setmetatable(t, _meta.Arrangement)
end

function arrangements.add_element(t, obj, identifier, x_offset, y_offset, visible)
    local m = meta[t]

    m.x_offsets[obj] = x_offset
    m.y_offsets[obj] = y_offset
    m.map[identifier] = obj
    m.element_visibility[obj] = visible
    
    obj('set_position', m.x + x_offset, m.y + y_offset)
    obj('set_visibility', m.visible and visible)
end

function arrangements.remove_element(t, identifier)
    local m = meta[t]
    local obj = m.map[identifier]
    
    m.x_offsets[obj] = nil
    m.y_offsets[obj] = nil
    m.map[identifier] = nil
    m.element_visibility[obj] = nil

    obj('delete')
end

function arrangements.element_position(t, identifier, x, y)
    local m = meta[t]
    local obj = m.map[identifier]

    m.x_offsets[obj] = x
    m.y_offsets[obj] = y

    obj('set_position', m.x + x, m.y + y)
end

function arrangements.element_visibility(t, identifier, b)
    local m = meta[t]
    local obj = m.map[identifier]

    m.element_visibility[obj] = b

    obj('set_visibility', m.visible and b)
end

function arrangements.pos(t, x, y)
    local m = meta[t]

    if not y then return m.x, m.y end

    m.x, m.y = x, y

    for obj, offset in pairs(m.x_offsets) do
        obj('set_position', m.x + offset, m.y + m.y_offsets[obj])
    end
end

function arrangements.visible(t, b)
    local m = meta[t]

    if b == nil then return m.visible end

    for obj, element_visible in pairs(m.element_visibility) do
        if element_visible then
            obj('set_visibility', b)
        end
    end

    m.visible = b
end

function arrangements.element(t, identifier)
    return meta[t].map[identifier]
end

function arrangements.destroy(t)
    local m = meta[t]

    for _, obj in pairs(m.map) do
        obj('delete')
        m.map[_] = nil
    end

    meta[t] = nil

	if _libs.widgets and _libs.widgets.tracking(t) then
		_libs.widgets.stop_tracking_object(t)
	end
end

return arrangements

