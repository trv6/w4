-- A few functions for extracting 32 x 32 bitmap icons from the DATs.
-- In order to allow Windower 4 to display the alpha channels correctly,
-- the header is replaced and the pixel data is decompressed in each image.

local string = require 'string'
local io = require 'io'
local math = require 'math'

local floor = math.floor
local byte = string.byte
local char = string.char
local sub = string.sub

local file_size = '\122\16\00\00'
local reserved1 = '\00\00'
local reserved2 = '\00\00'
local starting_address = '\122\00\00\00'

local default = '\00\00\00\00'

local dib_header_size = '\108\00\00\00'
local bitmap_width = '\32\00\00\00'
local bitmap_height = '\32\00\00\00'
local n_color_planes = '\01\00'
local bits_per_pixel = '\32\00'
local compression_type = '\03\00\00\00'
local image_size = '\00\16\00\00'
local h_resolution_target = default
local v_resolution_target = default
local default_n_colors = default
local important_colors = default
local alpha_mask = '\00\00\00\255'
local red_mask = '\00\00\255\00'
local green_mask = '\00\255\00\00'
local blue_mask = '\255\00\00\00'
local colorspace = 'sRGB'
local endpoints = string.rep('\00', 36)
local red_gamma = default
local green_gamma = default
local blue_gamma = default

local header = 'BM' .. file_size .. reserved1 .. reserved2 .. starting_address
		.. dib_header_size .. bitmap_width .. bitmap_height .. n_color_planes
		.. bits_per_pixel .. compression_type .. image_size
		.. h_resolution_target .. v_resolution_target
		.. default_n_colors .. important_colors
		.. red_mask .. green_mask .. blue_mask .. alpha_mask
		.. colorspace .. endpoints .. red_gamma .. green_gamma .. blue_gamma

local color_lookup = {}
for i = 0, 255 do
	color_lookup[char(i)] = ''
end

local extract = {}

local function index_color_table(index_as_char)
	return color_lookup[index_as_char]
end

-- A mix of 32 bit color uncompressed and *color palette-indexed bitmaps
-- Offsets defined specifically for status icons
-- * some maps use this format as well, but at 512 x 512
function extract.sts_icon(n, input, out_path)
	input:seek('set', n * 0x1800)
	local data = input:read(0x1800)
	local length = byte(data, 0x282) -- The length is technically sub(0x281, 0x284), but only 0x282 is unique

	if length == 16 then -- uncompressed
		data = sub(data, 0x2BE, 0x12BD)
		data = string.gsub(data, '(...)\128', '%1\255') -- All of the alpha bytes are currently 0 or 0x80.
	elseif length == 08 then -- color table
		local color_palette = sub(data, 0x2BE, 0x6BD)
		color_palette = string.gsub(color_palette, '(...)\128', '%1\255')

		local n = 0
		for i = 1, 1024, 4 do
			color_lookup[char(n)] = sub(color_palette, i, i + 3)
			n = n + 1
		end

		data = string.gsub(sub(data, 0x6BE, 0xABD), '(.)', index_color_table)
	elseif length == 04 then -- XIVIEW
		data = sub(data, 0x2BE, 0x12BD)
	else
		print('Unrecognized format from id ' .. tostring(n), tostring(length))
		data = sub(data, 0x2BE, 0x12BD) -- give it a shot
	end

	local f = io.open(out_path, 'wb')
	f:write(header .. data)
	f:close()
end

local encoded_to_decoded_char = {}
local encoded_byte_to_rgba = {}
local alpha_encoded_to_decoded_adjusted_char = {}
local decoded_byte_to_encoded_char = {}
for i = 0, 255 do
	encoded_byte_to_rgba[i] = ''

	local n = (i % 32) * 8 + floor(i / 32)
	encoded_to_decoded_char[char(i)] = char(n)
	decoded_byte_to_encoded_char[n] = char(i)
	n = n * 2
	n = n < 256 and n or 255
	alpha_encoded_to_decoded_adjusted_char[char(i)] = char(n)
end

local decoder = function(a, b, c, d)
	return encoded_to_decoded_char[a]..
		encoded_to_decoded_char[b]..
		encoded_to_decoded_char[c]..
		alpha_encoded_to_decoded_adjusted_char[d]
end


-- 32 bit color palette-indexed bitmaps. Bits are rotated and must be decoded.
function extract.item_icon(n, input, out_path)
    input:seek('set', n * 3072 + 701)
    local data = input:read(2048)
	local color_palette = string.gsub(sub(data, 1, 1024), '(.)(.)(.)(.)', decoder)
	-- rather than decoding all 2048 bytes, decode only the palette and index it by encoded byte
	for i = 0, 255 do
		local offset = i * 4 + 1
		encoded_byte_to_rgba[decoded_byte_to_encoded_char[i]] = sub(color_palette, offset, offset + 3)
	end

	local f = io.open(out_path, 'wb')
	f:write(header .. string.gsub(sub(data, 1025, 2048), '(.)', function(a) return encoded_byte_to_rgba[a] end))
	f:close()
end

-- n: number indicating which icon file to extract from the DAT
-- input: file object of open DAT e.g. input = io.open('P:ath/to/some/DAT.dat', 'rb') *don't forget b option on windows
-- out_path: string indicating file path where the image should be created

return extract
