-- Incomplete structure for 32 bit files:
-- All values LE
-- <description>\[<size in bytes>\]
--
-- mystery_bytes[44]
-- description[128] -- not ascii -- fits for blink/utsesumi, but not signet
-- padding1[468]
-- offset_to_end_of_pixel_data[4] -- 39 10 00 00 or 39 08 00 00 (see "note")
-- file_name[17] -- not clear if the first byte is part of the name
-- bmp_header[40] -- see "small problem" -- important colors set to x20?
-- pixel_data[4096]
-- padding2[1346]
-- eof[1] -- always FF
-- Total size: 6144
--
-- note: ex. 39 10 = x1039 = x11 + x28 + x1000 = file name + header + pixels
-- There are thirty-six files with offset 39 08 00 00. They are 8-bit indexed
-- color bitmaps, with a 256*4 byte color table followed by 32*32 pixel-codes.
-- There is additional padding so that the size in the DAT is still 0x1800.
-- According to MSDN, BI_BITFIELDS is only valid for 16 and 32-bit bitmaps. In
-- order to display the alpha bytes correctly, these have to be converted to
-- the 32-bit format.
--
-- A small problem: 119/57.DAT uses a 40 byte header with a structure matching
-- BITMAPINFOHEADER, and uses the fourth byte in each pixel's data as an alpha
-- value. However, the BMP file format did not have support for alpha data
-- until BITMAPV3INFOHEADER.
-- Windower (and firefox, windows image viewer, etc.) does not support the
-- alpha byte when using a 40 byte header. Swapping the header to the
-- BITMAPV4HEADER structure resolves the issue.

-- f = io.popen([[where.exe /R C:\ pol.exe]], 'r')
-- = f:read('*all')
-- f:close()

local string = require 'string'
local io = require 'io'

-- BMP header [14] (prepend 'BM' in ascii)
local file_size = '\122\16\00\00' -- 7A 10 00 00 header lengths plus pixel data
local reserved1 = '\00\00'
local reserved2 = '\00\00'
local starting_address = '\122\00\00\00' -- headers are 14 + 108 = 122

local default = '\00\00\00\00'

-- DIB header [108]
local dib_header_size = '\108\00\00\00'
local bitmap_width = '\32\00\00\00'
local bitmap_height = '\32\00\00\00'
local n_color_planes = '\01\00'
local bits_per_pixel = '\32\00'
local compression_type = '\03\00\00\00' -- enable masks
local image_size = '\00\16\00\00' -- (dec) 32 * 32 * 4 = 0x1000
local h_resolution_target = default
local v_resolution_target = default
local default_n_colors = default -- 0 means use maximum available
local important_colors = default -- 0 means all are important
local alpha_mask = '\00\00\00\255' -- bgra
local red_mask = '\00\00\255\00'
local green_mask = '\00\255\00\00'
local blue_mask = '\255\00\00\00'
local colorspace = default
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
local bmp_segments = {}

for i = 0, 255 do
	color_lookup[string.char(i)] = ''
end


-- C:/Program Files (x86)/PlayOnline/SquareEnix/FINAL FANTASY XI/ROM/119/57.DAT
local function all(input, target_directory)
    local info = input:read('*a')

    for i = 1, (#info / 0x1800) do
        local offset = (i - 1) * 0x1800
        local data_length = string.sub(info, offset + 0x280 + 1, offset + 0x284)

        if data_length == '\57\16\00\00' then -- see "note"
            local pixel_data = string.sub(info, offset + 0x2BE, offset + 0x2BD + 0x1000)
            pixel_data = string.gsub(pixel_data, '(...)\128', '%1\255')

            local bmp = header .. pixel_data
            local f = io.open(target_directory .. tostring(i - 1) .. '.bmp', 'wb')

            f:write(bmp)
            f:close()
        elseif data_length == '\57\08\00\00' then
            local color_table = string.sub(info, offset + 0x2BE, offset + 0x2BD + 0x400)
            local pixel_bytes = string.sub(info, offset + 0x6BE, offset + 0x2BD + 0x800)

            color_table = string.gsub(color_table, '(...)\128', '%1\255')

            local n = 0
            for j = 1, 1024, 4 do
                color_lookup[string.char(n)] = string.sub(color_table, j, j + 3)
                n = n + 1
            end

            for j = 1, 1024 do
                bmp_segments[j] = color_lookup[string.sub(pixel_bytes, j, j)]
            end

            local pixel_data = table.concat(bmp_segments, '')
            local bmp = header .. pixel_data
            local f = io.open(target_directory .. tostring(i - 1) .. '.bmp', 'wb')

            f:write(bmp)
            f:close()
        end
    end
end

local extract = {}

extract.all = all

function extract.by_id(input, id, output_path)
    input:seek('set', id * 0x1800)
    local info = input:read(0x1800)

    local data_length = string.sub(info, 0x281, 0x284)

    if data_length == '\57\16\00\00' then
		-- The alpha bytes in the DAT file max out at x80 (why?). Swap xFF in for x80
        local pixel_data = string.sub(info, 0x2BE, 0x12BD)
        pixel_data = string.gsub(pixel_data, '(...)\128', '%1\255')
        local bmp = header .. pixel_data
		
        local f = io.open(output_path, 'wb')
        f:write(bmp)
        f:close()
    elseif data_length == '\57\08\00\00' then
        local color_table = string.sub(info, 0x2BE, 0x6BD)
        color_table = string.gsub(color_table, '(...)\128', '%1\255')
        local pixel_bytes = string.sub(info, 0x6BE, 0xABD)

		-- convert the color table (string) to a Lua table
        local n = 0
        for j = 1, 1024, 4 do
            color_lookup[string.char(n)] = string.sub(color_table, j, j + 3)
            n = n + 1
        end

		-- convert the color codes to pixel data
        for j = 1, 1024 do
            bmp_segments[j] = color_lookup[string.sub(pixel_bytes, j, j)]
        end

        local pixel_data = table.concat(bmp_segments, '')
        local bmp = header .. pixel_data
        local f = io.open(output_path, 'wb')

        f:write(bmp)
        f:close()
    end
end

return extract
