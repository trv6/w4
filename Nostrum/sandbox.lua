--luacheck: std lua51
-- Sandboxing was a big mistake. Do not recommend. 1/5 stars "cannot rate 0 stars"
require 'strings'
local io = require 'io'
local res = require 'resources'
local events = require 'events'
local windower = _G.windower

local sandbox = {}

local function readonly(t)
    return setmetatable({}, {
        __index = t,
        __newindex = function(t, k, v)
            print("Error: Attempt to modify read-only table", k, v)
        end,
        __metatable = false -- prevents user from yanking table anyway
    })
end

local function get_action_interpreter()
    local cache = {}

    return function(act_string, target_string)
        if not target_string then return end

        act_string = act_string:lower()

        local action
        local player = windower.ffxi.get_player()

        if cache[act_string] then
            action = cache[act_string]
        elseif act_string == 'target' then
            action = {}
            action.name = ''
            action.prefix = '/target'
        elseif player and player.main == 23 then -- 'Monipulator' (hopefully)
            for _, mabil in ipairs(res.monster_abilities) do
                if mabil.name:lower() == act_string then
                    action = mabil
                    mabil.prefix = '/monsterskill'

                    cache[act_string] = action
                    sandbox.user_action.spell = action
                end
            end
        else
            for _, category in ipairs{
                'spells', 'job_abilities', 'weapon_skills',
            } do
                for id, resource_entry in pairs(res[category]) do
                    if resource_entry.name:lower() == act_string then
                        action = resource_entry
                        break
                    end
                end

                if action then break end
            end
        end

        if action then
            cache[act_string] = action

            sandbox.user_action.spell = action
            sandbox.user_action.target = target_string
            sandbox.user_action.queued = true

            return action
        end
    end
end

function sandbox.new(overlay)
    if not overlay then return end
    local overlay_path = windower.addon_path .. 'overlays/' .. overlay .. '/'

    local env = {
        pairs = pairs,
        ipairs = ipairs,
        assert = assert,
        error = error,
        next = next,
        pcall = pcall,
        print = print,
        select = select,
        setmetatable = setmetatable,
        getmetatable = getmetatable,
        tonumber = tonumber,
        tostring = tostring,
        type = type,
        unpack = unpack,
        xpcall = xpcall,
        rawset = rawset,
        rawget = rawget,
        setfenv = setfenv,
    }

    env._libs = {}

    env.overlay_path = overlay_path

    local icons_exist = io.open(windower.addon_path .. 'icons/0.bmp', 'r')
    if icons_exist then
        io.close(icons_exist)
        env.icon_path = windower.addon_path .. 'icons/'
    else
        env.icon_path = false
    end

    env.loadfile = function(path)
        local f, err = loadfile(path)

        if f then setfenv(f, env) end
        return f, err
    end
    env.loadstring = function(string)
        local f, err = loadstring(string)

        if f then setfenv(f, env) end
        return f, err
    end

    env._G = env
    env.package = {}
    env.package.loaded = {}

    local loaded = env.package.loaded
    -- access to base libraries
    for _, lib in pairs({'string', 'math', 'os', 'io', 'table', 'coroutine'}) do
        local t = require(lib)
        local u = {}

        for k, v in pairs(t) do
            u[k] = v
        end

        loaded[lib] = u
        env[lib] = u -- there's a cheat here: env.string is strings (it accesses windower)
    end
    env.debug = readonly(require 'debug') -- It hakuna does not matata

    loaded.strings = true
    loaded.align = readonly(require 'libs/align')
    loaded.widgets = readonly(require 'libs/widgets')
    env._libs.widgets = loaded.widgets
    loaded['libs/widgets'] = loaded.widgets
    loaded['libs/widgets/primitives'] = readonly(require 'libs/widgets/primitives') -- primitives accesses the windower table
    loaded['widgets/primitives'] = loaded['libs/widgets/primitives']
    loaded.events = readonly(require 'events')
    loaded.files = readonly(require 'files')
    loaded.config = readonly(require 'config')
    loaded.resources = res

    rawset(loaded['widgets/primitives'], 'low_level_visibility', false)
    rawset(loaded['widgets/primitives'], 'destroy_all', false)

    rawset(loaded.widgets, 'visible', false)
    rawset(loaded.widgets, 'stop_tracking', false)

    local files, config = loaded.files, loaded.config
    -- this is a bigger pain than expected
    local new_file = loaded.files.new
    rawset(files, 'new', function(path, create)
        if not (path and type(path) == 'string') then return end

        return new_file('/overlays/' .. overlay .. '/' .. path, create)
    end)

    local file_exists = loaded.files.exists
    rawset(files, 'exists', function(path)
        if not (path and type(path) == 'string') then return end

        return file_exists('/overlays/' .. overlay .. '/' .. path)
    end)

    local file_read = loaded.files.read
    rawset(files, 'read', function(path)
        if not (path and type(path) == 'string') then return end

        return file_read('/overlays/' .. overlay .. '/' .. path)
    end)

    local load = loaded.config.load
    rawset(config, 'load', function(path, defaults)
        if not path then return end

        if type(path) == 'table' then
            defaults = path
            path = '/overlays/' .. overlay .. '/data/settings.xml'
        elseif type(path) == 'string' then
            path = '/overlays/' .. overlay .. '/' .. path
        end

        return load(path, defaults)
    end)

    env.require = function(module_name)
        if not module_name then return end

        module_name = module_name:startswith('libs/') and module_name:sub(6) or module_name -- apply duct tape

        if loaded[module_name] then
            return loaded[module_name]
        end

        local nos_libs_path = windower.addon_path .. 'libs/' .. module_name .. '.lua'
        local libs_path = windower.windower_path .. 'addons/libs/' .. module_name .. '.lua'

        for _, path in ipairs({
            overlay_path .. module_name .. '.lua',
            nos_libs_path,
            libs_path
        }) do
            local f = io.open(path, 'r')

            if f then
                io.close(f)
                local module, err = loadfile(path)

                if not module then
                    error(err)
                    return
                end

                setfenv(module, env)
                local ret = module()

                if ret then
                    loaded[module_name] = ret

                    return ret
                end

                return
            end
        end

        -- spoof interpreter error message
        error('module \'' .. module_name .. '\' not found:\n'
            .. 'no field package.preload[\'' .. module_name .. '\']\n'
            .. 'no file ' .. overlay_path .. module_name .. '.lua\n'
            .. 'no file ' .. nos_libs_path .. '\n'
            .. 'no file ' .. libs_path, 2)
    end

    env.windower_settings = windower.get_windower_settings
    env.action = get_action_interpreter()

    -- the cache has to be cleared on job change
    local jceid
    jceid = windower.register_event('job change', function()
        if env and env.action then
            env.action = get_action_interpreter()
        else
            windower.unregister_event(jceid) -- is that going to work?
        end
    end)

    env.overlay = events.new(
        'display vacant', 'display populated', 'name change',
        'mpp change', 'hpp change', 'tp change', 'mp change',
        'hp change', 'zone change', 'in view', 'distance change',
        'out of view', 'statuses updated', 'overlay command',
        'zone in', 'zone out', 'member appear', 'member disappear',
        'target change', 'target hpp change', 'job change', 'keyboard'
    )
    env.overlay.destroy = function()
        error('Do not destroy event instance from within the overlay, dummy')
    end

    env.get_alliance_key = function(n, m)
        return (n == 1 and 'p' or 'a') .. tostring((n - 1) * 10 + m - 1)
    end

    return env
end

function sandbox.destroy(env)
    events.destroy(env.overlay)

    for k in pairs(env.package.loaded) do
        env.package.loaded[k] = nil
    end

    for k in pairs(env) do
        env[k] = nil
    end
end

sandbox.user_action = {
    spell = nil,
    target = nil,
    queued = false,
}

return sandbox

