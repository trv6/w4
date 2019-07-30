local coroutine = require 'coroutine'
local dimensions = require 'text_dimensions'
local textdb = dimensions.read('data/textdb.lua')

dimensions.update(textdb)
dimensions.write(textdb, 'data/textdb.lua')

local profiles = require 'profiles'
local palettes = require 'display/palette'

addon_path = windower.addon_path

p = palettes.new(500, 500, true, profiles.example.debuff)

for _ = 1, 6 do
    p:append_row()
end

coroutine.sleep(2)

for _ = 1, 5 do
    p:remove_row()
end
