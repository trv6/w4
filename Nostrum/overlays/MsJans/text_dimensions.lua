local files = require 'files'
local lists = require 'lists'
local serpent = require 'serpent'
local coroutine = require 'coroutine'
local primitives = require 'widgets/primitives'
local profiles = require 'profiles'
local settings = require 'settings'

local L = _G.L

local dimensions = {}

function dimensions.read(path)
    if files.exists(path) then
        local s, err = files.read(path)
        local t

        if s then
            s, t = serpent.load(s, {safe = true})
        end

        -- if not s then
        --     error(t)
        -- end

        return s and type(t) == 'table' and t or {}
    else
        files.new(path):create()
        return {}
    end
end

function dimensions.write(t, path)
    local textdb = files.new(path)

    textdb:write(serpent.block(t, {comment = false}))
end

function dimensions.measure(label_list)
    for i = 1, label_list.n do
        local label = label_list[i]
        local text = primitives.new('text', label)

        label.primitive = text
        text('set_position', i * -50, i * -50)
    end

    coroutine.sleep(1)

    for i = 1, label_list.n do
        local label = label_list[i]
        local w, h = label.primitive('get_extents')

        label.primitive('delete')
        for k, _ in pairs(label) do
            label[k] = nil
        end

        label.x, label.y = w, h
    end
end

function dimensions.update(t)
    local text_settings = settings.palette_region.button.text
    local to_measure = L{}

    for _, profile in pairs(profiles) do
        for _, palette in pairs(profile) do
            for _, action in ipairs(palette) do
                if action.text then
                    local font = action.font or text_settings.font
                    local size = action.font_size or text_settings.size

                    local u = t[font] or {}
                    t[font] = u
                    local s = u[size] or {}
                    u[size] = s

                    if not s[action.text] then
                        local label_template = {
                            set_text = action.text,
                            set_font = font,
                            set_font_size = size,
                            set_bold = action.bold or text_settings.bold,
                            set_italic = action.italic or text_settings.italic,
                            set_visibility = true,
                        }
                        s[action.text] = label_template
                        to_measure:append(label_template)
                    end
                end
            end
        end
    end

    -- update textdb if necessary
    if not to_measure:empty() then
        dimensions.measure(to_measure)
    end
end

return dimensions

