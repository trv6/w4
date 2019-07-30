local settings = require 'settings'
local helpers = {}

function helpers.unpack_color(t)
    return t.a, t.r, t.g, t.b
end

function helpers.truncate_name(s)
    local n = settings.stat_region.text.name.truncate

    return #s < n and s or string.sub(s, 1, n) .. '.'
end

return helpers
