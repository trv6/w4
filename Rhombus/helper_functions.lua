--[[Copyright © 2014-2015, trv
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Rhombus nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL trv BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.--]]

function remove_categories_from_ja_template(template)
    local u = {}
    local n = 0
	local res = res.job_abilities
    
	for i = 1, #template do
        if res[template[i]] and not not_a_spell:contains(res[template[i]].en) then
            n = n + 1
			u[n] = template[i]
        end
    end
	
    return u
end

function get_string_from_id(n)
    return (spell_aliases[n] or res[category_to_resources[last_menu_open.type]][n].en)
end

function flatten(t)
    local s = S{}
	
    if t.sub_menus then
        for i = 1, #t.sub_menus do
            s = s + flatten(t[t.sub_menus[i]])
        end
    end
	
    for i = 1, #t do
        s:add(t[i])
    end
	
    return s
end

function count_job_points()
    local n = 0
    for _,v in pairs(windower.ffxi.get_player().job_points[res.jobs[player_info.main_job].ens:lower()]) do
        n = n + v*(v+1)
    end 
    return n/2
end

function bit.is_set(val, pos) -- Credit: Arcon
    return bit.band(val, 2^(pos - 1)) > 0
end
