local dat_path = string.sub(windower.pol_path, 1, -17) .. 'FINAL FANTASY XI/'
local ftable
do
	local f = io.open(dat_path .. 'FTABLE.DAT', 'rb')
	ftable = f:read('*a')
	f:close()
end
local lookup = require('libs/datrw/lookup').en
local datrw = {}

-- datrw.pack
-- -- local dat = datrw.open('sts_icon')
-- -- write(dat:unpack(8, 'Icon'))
-- datrw.unpack
local floor = require('math').floor
local byte = require('string').byte
local function read_ftable(id)
	local offset = 2*(id-1) + 1
	local packed_16bit = byte(ftable, offset + 1) * 256 + byte(ftable, offset) -- LE
	local dir = floor(packed_16bit / 128)
	local file = packed_16bit - dir * 128

	return dat_path .. 'ROM/' .. tostring(dir) .. '/' .. tostring(file) .. '.DAT'
end

-- datrw.open('items', 'armor')?
-- datrw.open(items.armor)
-- datrw.open('items.armor')
-- datrw.open('Items:Armor')
function datrw.open(...)
	local id = lookup[select(1, ...)]
	for i = 2, select('#', ...) do -- gross
		id = id[select(i, ...)]
	end
	
	return io.open(read_ftable(id), 'rb')
end
-- datrw.write

return datrw
