_meta = _meta or {}

local templates = {}

_meta.templates = {__index = templates}

local function count_table_elements(t)
    for k,v in pairs(t) do
        if type(v) == 'table' then
            count_table_elements(t[k])
        end
    end
    
    t.n = #t
end

function templates.new(t)
	if not t then return end
	
	-- run count assignment
	count_table_elements(t)

	return setmetatable(t, _meta.templates)
end

function templates.merge(primary, secondary)
	if not secondary then
		return primary
	end
	
	local n = primary.n
	
	-- append secondary template array to primary template
	for i = 1, secondary.n do
		primary[n + i] = secondary[i]
	end
	
	-- merge template sub-menus
	local secondary_submenu = secondary.sub_menus
	
	if secondary_submenu then
		local primary_submenu = primary.sub_menus or {n = 0}
		local n = primary_submenu.n
		
		-- append secondary_submenu to primary_submenu (merge duplicates)
		for i = 1, secondary_submenu.n do
			local cat = secondary_submenu[i]
			
			if primary[cat] then
				primary[cat] = templates.merge(primary[cat], secondary[cat])
			else
				primary[cat] = secondary[cat]
				n = n + 1
				primary_submenu[n + 1] = cat
			end
		end
	end

	return primary
end

function templates.filter(t, filter)

end

function templates.flatten_to_set(t)
    local s = {}
	
    if t.sub_menus then
        for i = 1, #t.sub_menus do
            local u = templates.flatten_to_set(t[t.sub_menus[i]])
			
			for id in pairs(u) do
				s[id] = true
			end
        end
    end
	
    for i = 1, #t do
        s[t[i]] = true
    end
	
    return s
end

function 