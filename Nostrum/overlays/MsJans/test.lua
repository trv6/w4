_addon.command = 'd'

windower.register_event('addon command', function(...)
	assert(loadstring(table.concat({...}, ' ')))()
end)

loadfile '->/better_msj/tests/palette_creation.lua' ()
