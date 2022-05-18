local prims = require 'libs/widgets/prims'
local groups = require 'libs/widgets/groups'
local primitives = require 'libs/widgets/primitives'
local arrangements = require 'libs/widgets/arrangements'

local meta = {}
local scrolling_texts = {}

_meta = _meta or {}
_meta.Scrolling_Text = _meta.Scrolling_Text or {}
_meta.Scrolling_Text.__index = setmetatable(scrolling_texts, {__index = _meta.Group.__index})
-- Do not inherit the __newindex behavior... Defining st methods becomes awkward

if _libs and _libs.widgets then
	_libs.widgets.hook_class(_meta.Scrolling_Text)
end

local concat = _raw and _raw.table and _raw.table.concat or table.concat

local function get_handle_height(t)
	local m = meta[t]
	local n = m.lines.n

	if n == 0 then return m.h end

	local h = m.h / n * m.lines_displayed

	return h > m.min_handle_h and h or m.min_handle_h
end

local function get_handle_position(t)
	local m = meta[t]
	local n = m.lines.n

	if n == 0 or n <= m.lines_displayed then return 0 end

	return m.h / n * (m.from - 1)
end

local function range_finder(t, from)
	local m = meta[t]

	from = from > 0 and from or 1

	local to = from + m.lines_displayed - 1
	local n = m.lines.n

	if n <= m.lines_displayed then
		from, to = 1, n
	elseif to > n then
		from, to = n - m.lines_displayed + 1, n
		from = from > 0 and from or 1
	end

	return from, to
end

local function draw_text(t, from, to)
	local m = meta[t]
	local d = m.lines_display
	local colors = m.color_formatting
	local lines = m.lines

	if to > 0 and from > 0 then
		for i = from, to do
			d[i] = d[i] or colors[i] and '\\cs(' .. concat(colors[i], ',') .. ')' .. lines[i] .. '\\cr' or lines[i]
		end
		m.text('set_text', '\n' .. concat(d, '\n', from, to)) -- see windower/issues/issues/#655
	end

end

-- settings = {
--	   w = n,
--	   line_height = n,
--	   min_handle_h = n,
--	   lines_displayed = n,
--	   lines = {},
--	   color_formatting = {}, -- NR

--	   bg = {}, -- primitive
--	   text = {}, -- primitive

--	   track = {}, -- primitive
--	   handle = {}, -- primitive
-- }

function scrolling_texts.new(x, y, visible, settings)
	local m = {}
	local t = groups.new(x, y, visible)

	meta[t] = m

	m.w				   = settings.w
	m.line_height	   = settings.line_height
	m.min_handle_h	   = settings.min_handle_h
	m.lines_displayed  = settings.lines_displayed

	m.h = m.line_height * m.lines_displayed
	settings.track.h = m.h
	settings.handle.h = m.h -- overwritten later
	settings.bg.set_size = {m.w, m.h}

	m.text = primitives.new('text', settings.text)

	settings.bg.visible = visible
	settings.text.visible = visible

	local body = arrangements.new(x, y, visible)

	body:add_element(primitives.new('prim', settings.bg), 'background', 0, 0, visible)
	body:add_element(m.text, 'text', 0, -m.line_height, visible)

	t:add_object(body, 'body')

	local track = prims.new(x + m.w, y, visible, settings.track)
	local handle = prims.new(x + m.w, y, visible, settings.handle)

	t:add_object(track, 'track')
	t:add_object(handle, 'handle')

	scrolling_texts.build(t, settings.lines, settings.color_formatting, 1)

	setmetatable(t, _meta.Scrolling_Text)

	local widgets = _libs and _libs.widgets

	if widgets then
		widgets.start_tracking_object(t, nil, m.w, m.h)
		t:register_event('scroll', function(b, x, y, delta)
			scrolling_texts.scroll(t, delta)
			
			return true
		end)
		
		widgets.start_tracking_object(t.handle)
		t.handle:register_event('left button down', function(b, x, y)
			widgets.grab_object(t.handle, x, y)

			return true
		end)

		t.handle:register_event('drag', function(b, x, y)
			local contact_x, contact_y = widgets.get_contact_point()
			local increment_height = m.h / #settings.lines
			local obj_x, obj_y = groups.pos(t)
			-- local from, to = range_finder(t, (y - contact_y - obj_y) / increment_height)
			scrolling_texts.jump(t, math.ceil((y - contact_y - obj_y) / increment_height))

			return true
			-- draw_text(t, from, to) -- update the text

			-- t.handle:pos_y((from - 1) * increment_height + obj_y) -- position the handle

		end)
		-- t.track:register_event('left button down') TODO
	end

	return t
end

function scrolling_texts.build(t, lines, colors, from)
	local m = meta[t]

	if not colors then
		colors = {}
	elseif type(colors) == 'number' then
		colors, from = {}, colors
	end

	from = from or 1

	local n = #lines

	m.lines = lines
	m.lines.n = n
	m.color_formatting = colors

	local to
	from, to = range_finder(t, from)

	m.from = from
	m.lines_display = {}

	draw_text(t, from, to)

	if n > m.lines_displayed then
		local _, y = groups.pos(t)

		t.handle:pos_y(y + get_handle_position(t))
		t.handle:height(get_handle_height(t))
		t.handle:show()
		t.track:show()
	else
		t.handle:hide()
		t.track:hide()
	end
end

function scrolling_texts.jump(t, line_number)
	local from, to = range_finder(t, line_number)
print('jump', line_number, from, to)
	draw_text(t, from, to)
	meta[t].from = from

	local _, y = groups.pos(t)

	t.handle:pos_y(y + get_handle_position(t))
end

function scrolling_texts.scroll(t, delta)
-- print('scroll', delta)
	local m = meta[t]

	if delta == 0 or delta == -0 or m.lines.n <= m.lines_displayed then return end

	scrolling_texts.jump(t, m.from - delta)
end

function scrolling_texts.size(t)
	local m = meta[t]

	return m.w, m.h
end

function scrolling_texts.width(t, w)
	if not w then return meta[t].w end

	local m = meta[t]

	t.body:element('background')('set_size', w, m.h)

	local x, _ = groups.pos(t)

	t.track:pos_x(x + w)
	t.handle:pos_x(x + w)

	m.w = w
end

function scrolling_texts.height(t)
	return meta[t].h
end

function scrolling_texts.get_line(t, n)
	return meta[t].lines[n]
end

function scrolling_texts.line_count(t)
	return meta[t].lines.n
end

function scrolling_texts.get_line_height(t)
	return meta[t].line_height
end

function scrolling_texts.get_number_of_lines_displayed(t)
	return meta[t].lines_displayed
end

function scrolling_texts.get_scroll_offset(t)
	return meta[t].from
end

function scrolling_texts.append_line(t, text, r, g, b)
	local m = meta[t]
	local n = m.lines.n + 1

	m.lines[n] = text
	m.lines.n = n

	if b then
		m.color_formatting[n] = {r, g, b}
		m.lines_display[n] = '\\cs(' .. concat(m.color_formatting[n], ',') .. ')' .. text .. '\\cr'
	else
		m.lines_display[n] = text
	end

	if n < m.lines_displayed then
		draw_text(t, 1, n)
	end
end

function scrolling_texts.refresh(t, ...)
	local m = meta[t]
	local from, to = range_finder(t, m.from)

	draw_text(t, from, to)
end

function scrolling_texts.refresh_if_in_range(t, lines)
	local from, to = range_finder(t, meta[t].from)

	for i = 1, #lines do
		local line_number = lines[i]

		if line_number >= from and line_number <= to then
			draw_text(t, from, to)

			break
		end
	end
end

function scrolling_texts.cs(t, line_number, r, g, b)
	local m = meta[t]

	local color = {r, g, b}
	m.color_formatting[line_number] = color
	m.lines_display[line_number] = '\\cs(' .. concat(color, ',') .. ')' .. m.lines[line_number] .. '\\cr'
end

function scrolling_texts.cr(t, line_number)
	local m = meta[t]

	m.color_formatting[line_number] = nil
	m.lines_display[line_number] = m.lines[line_number]
end

function scrolling_texts.destroy(t)
	if _libs and _libs.widgets then
		_libs.widgets.stop_tracking_object(t)
		_libs.widgets.stop_tracking_object(t.handle)
		-- _libs.widgets.stop_tracking_object(t.track) TODO
	end

	meta[t] = nil

	groups.destroy(t)
end

return scrolling_texts

