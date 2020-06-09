local fields = {}

local sts_compressed = {
	-- TODO
}
local sts_uncompressed = {
	length = 0x1800,
	_unknown1 = {
		offset = 0,
		length = 0x2C,
	},
	marquee_text = {
		offset = 0x2C,
		length = 0x80,

	},
	padding1 = {
		offset = 0xAC,
		length = 0x1D4,
	},
	offset_to_end_of_pixel_data = {
		offset = 0x280,
		length = 4,
	},
	file_name = {
		offset = 0x284,
		length = 0x11,
	},
	dib_header = {
		offset = 0x295,
		length = 0x28,
	},
	pixel_data = {
		offset = 0x2BD,
		length = 0x1000,
	},
	padding2 = {
		offset = 0x12BD,
		length = 0x542,
	},
	eof_marker = {
		offset = 0x17FF,
		lenth = 1,
	},
}

fields['sts_icon'] = {
	{
		struct = sts_uncompressed,
		count = 0, -- TODO get the counts
	},
	{
		struct = sts_compressed,
		count = 0,
	},
	{
		struct = sts_uncompressed,
		count = 0,
	}
}

