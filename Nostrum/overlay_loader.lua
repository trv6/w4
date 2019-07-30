require 'strings'
local windower = _G.windower
local sandbox = require 'sandbox'

local tcid

local target
local get_target = windower.ffxi.get_mob_by_target

local function initialize(name)
    -- try to load the overlay
    local fn, err = loadfile(('%soverlays/%s/%s.lua'):format(windower.addon_path, name, name))

    if not fn then
        print(err)
        return false
    end

    -- sandbox
    local sb = sandbox.new(name)

    -- create overlay
    setfenv(fn, sb)
    fn()

    if sb.overlay:count('target change') + sb.overlay:count('target hpp change') > 0 then
        if not tcid then
            -- prerender?: target change was slow and frequently missed events
            tcid = windower.register_event('prerender', function()
                local t = get_target('st') or get_target('t')

                if target then
                    if not t then
                        sb.overlay:trigger('target change', false)
                        target = false
                    elseif target.id ~= t.id then
                        sb.overlay:trigger('target change', t)
                        target = t
                    elseif target.hpp ~= t.hpp then
                        sb.overlay:trigger('target hpp change', t.hpp, target.hpp)
                        target = t
                    end
                elseif t then
                    target = t
                    sb.overlay:trigger('target change', t)
                end
            end)
        end
    elseif tcid then
        windower.unregister_event(tcid)
    end

    return sb
end

return initialize

