local settings = windower.get_windower_settings()
local align = {}

function align.left(obj, offset)
    if not obj then return end
    offset = offset or 0

    local _, y = obj:pos()
    local w = obj:size()

    obj:pos(w < 0 and offset - w or offset, y)
end

function align.right(obj, offset)
    if not obj then return end
    offset = offset or 0

    local _, y = obj:pos()
    local w, _ = obj:size()

    obj:pos(settings.ui_x_res - (w > 0 and w or 0) + offset, y)
end

function align.horizontal_center(obj, offset)
    if not obj then return end
    offset = offset or 0

    local _, y = obj:pos()

    obj:pos((settings.ui_x_res - (obj:size())) / 2 + offset, y)
end

function align.vertical_center(obj, offset)
    if not obj then return end
    offset = offset or 0

    local x = obj:pos()
    local _, h = obj:size()

    obj:pos(x, (settings.ui_y_res - h) / 2 + offset)
end

function align.top(obj, offset)
    if not obj then return end
    offset = offset or 0

    local x = obj:pos()
    local _, h = obj:size()

    obj:pos(x, h < 0 and offset - h or offset)
end

function align.bottom(obj, offset)
    if not obj then return end
    offset = offset or 0

    local x = obj:pos()
    local _, h = obj:size()

    obj:pos(x, settings.ui_y_res + (h < 0 and offset or offset - h))
end

return align

