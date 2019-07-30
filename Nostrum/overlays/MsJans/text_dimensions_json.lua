local sets = require 'sets'
local files = require 'files'
local lists = require 'lists'
local table = require 'table'
local json = require 'json'
local coroutine = require 'coroutine'
local primitives = require 'widgets/primitives'
local profiles = require 'profiles'
local settings = require 'settings'

local L = _G.L
local S = _G.S

local dimensions = {}

function dimensions.read(path)
    if files.exists(path) then
        return json.read(path) or {}
    else
        files.new(path):create()
        return {}
    end
end

function dimensions.write(t, path)
    local json_file = files.new(path)
    local font_json = L{}

    for font, size_bin in pairs(t) do
        local size_json = L{}

        for font_size, label_bin in pairs(size_bin) do
            local label_json = L{}

            for label, dimension_bin in pairs(label_bin) do
                label_json:append(
                    '\n\t\t\t"' .. label .. '":{"x":' .. dimension_bin.x
                    .. ',"y":' .. dimension_bin.y .. '}'
                )
            end

            size_json:append(
                '\n\t\t' .. font_size .. ':{' .. label_json:concat(',')
                .. '\n\t\t}'
            )
        end

        font_json:append(
            '"' .. font .. '":{' .. size_json:concat(',')
            .. '\n\t}'
        )
    end

    json_file:write('{\n\t' .. font_json:concat(',\n\t') .. '\n}')
end

function dimensions.measure(label_list, settings)
    local t = {}
    local template = {
        set_bold = settings.bold,
        set_font = settings.font,
        set_font_size = settings.size,
        set_italic = settings.italic,
        set_visibility = true,
    }

    for i = 1, label_list.n do
        t[i] = primitives.new('text', template)
        t[i]('set_position', i * -50, i * -50)
		t[i]('set_text', label_list[i])
    end

    coroutine.sleep(1)

    for i = 1, label_list.n do
        local w, h = t[i]('get_extents')
        t[i]('delete')
		t[i] = nil
        t[label_list[i]] = {x = w, y = h}
    end

    return t
end

function dimensions.update(t)
    local latest = S{}
    local current = S{}

    for _, profile in pairs(profiles) do
        for _, action in ipairs(profile.palette) do
            latest:add(action.text)
        end
    end

    for font, size_bin in pairs(t) do
        for size, label_bin in pairs(size_bin) do
            for label, dimensions in pairs(label_bin) do
                current:add(label)
            end
        end
    end

    local missing = latest - current

    -- update textdb if necessary
    if not missing:empty() then
        local text_settings = settings.palette_region.main.button.text
        local update = {
            [text_settings.font] = {
                [text_settings.size] = dimensions.measure(L(missing), text_settings)
            }
        }

        table.update(t, update)
    end
end

return dimensions

