local primitives = require 'libs/widgets/primitives'
local scrolling_texts = require 'libs/widgets/scrolling_texts'

local meta = {}
local scrolling_menu = {}

_meta = _meta or {}
_meta.Scrolling_Menu = _meta.Scrolling_Menu or {}
_meta.Scrolling_Menu.__index = setmetatable(scrolling_menu, _meta.Scrolling_Text)

-- Settings are currently unforgiving: no defaults applied.
-- Use as template:
--
-- settings = {

--	   w = 150,
--	   line_height = 16,
--	   min_handle_h = 10,
--	   lines_displayed = 12,
--	   lines = {}, -- array of strings
--	   color_formatting = {[3] = {255, 0, 0}, [10] = {0, 0, 255}}, -- not required

--	   bg = {
--		   set_color = {167, 0, 0, 0}
--		   ...
--	   }, -- primitive
--	   text = {
--		   set_font = 'Consolas',
--		   set_font_size = '10', -- must match line_height
--		   set_bold = true,
--		   set_color = {255, 255, 255, 255}
--		   ...
--	   }, -- primitive

--	   track = {
--		   set_color = {180, 0, 0, 0},
--		   ...
--		   w = 10,
--	   }, -- prim... set_size ignored
--	   handle = {
--		   set_color = {200, 155, 155, 155},
--		   ...
--		   w = 10,
--	   }, -- prim... set_size ignored

--	   highlight = {
--		   set_color = {190, 155, 155, 155},
--	   }, -- prim... set_size ignored
-- }

function scrolling_menu.new(x, y, visible, settings)
	local t = scrolling_texts.new(x, y, visible, settings)

	settings.highlight.set_size = {settings.w, settings.line_height}
	settings.highlight.set_visibility = false

	t.body:add_element(primitives.new('prim', settings.highlight), 'highlight', 0, 0, false)

	setmetatable(t, _meta.Scrolling_Menu)

	if _libs and _libs.widgets then
		t:register_event('left button down', function()
			return true
		end)

		t:register_event('movement', function(b, x, y)
			local _, pos_y = t:pos()
			local line_height = settings.line_height
			local n = math.ceil((y - pos_y) / line_height)
			n = n > 0 and n or 1

			if n > t:line_count() then return end
			t.body:element_position('highlight', 0, (n - 1) * line_height)
		end)

		t:register_event('focus change', function(_, b)
			t.body:element_visibility('highlight', b)
		end)

		--[[
			To register a function to be called when a menu
			item is selected (a left click event occurs on
			the menu), rawset the function under t.left_click.

			t.left_click should expect the following parameters:
			n :: indicates the nth item of the list has been
			selected.
			s :: the string selected.

			e.g. t = scrolling_menu.new(...)
			rawset(t, 'left_click', function(n, s)
				print(n, s)
			end)
		--]]
		t:register_event('left click', function(b, x, y)
			if not t.left_click then return end

			local _, pos_y = t:pos()
			local line_height = settings.line_height
			local n = math.ceil((y - pos_y) / line_height)
			n = n > 0 and n or 1
			n = n + t:get_scroll_offset() - 1

			if n > t:line_count() then return end
			t.left_click(n, t:get_line(n))
		end)
	end

	return t
end

function scrolling_menu.select(t, line_number)
	local lines_displayed = scrolling_texts.get_number_of_lines_displayed(t)

	line_number = line_number > 0 and line_number or 1
	line_number = line_number <= lines_displayed and line_number or lines_displayed

	local h = scrolling_texts.get_line_height(t)

	t.body:element_position('highlight', 0, h * (line_number - 1))
end

function scrolling_menu.destroy(t)
	meta[t] = nil
	scrolling_texts.destroy(t)
end

return scrolling_menu
