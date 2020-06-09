local coroutine = require 'coroutine'
local stall = {}
local windower = _G.windower
local tracked = {}

function stall.for_condition(fn, resume, id)
	if tracked[id] then return end
	
	tracked[id] = true
	while not fn() do
		coroutine.sleep(2)
	end
	
	tracked[id] = nil
	resume()
end

return stall
