_addon.name = 'Nostrum'
_addon.author = 'trv'
_addon.version = '3.0'
_addon.commands = {'nostrum', 'nos'}

require 'strings'
local globals = require 'big_g'
local files = require 'files'
local windower = _G.windower
local widgets = require 'libs/widgets'
local settings = require 'settings'
local parse = require 'packet_parser'
local stall = require 'stall'
local sandbox = require 'sandbox'
local overlay_loader = require 'overlay_loader'
local primitives = require 'libs/widgets/primitives'

-- Unpack the status icons if the icons folder isn't full
do
	-- local export = require('datrw').sts_icon.export.by_id
    local rom_path = settings.client_path
    if rom_path and rom_path ~= '' and windower.dir_exists(rom_path) then
        rom_path = rom_path .. '/SquareEnix/FINAL FANTASY XI/ROM'
        local apath = windower.addon_path
        local extractor, dat

        for i = 0, 639 do
            local path = 'icons/sts_icon/' .. tostring(i) .. '.bmp'
            if not files.exists(path) then
                if not extractor then
                    dat = io.open(rom_path .. '/119/57.DAT', 'rb')
                    if not dat then
                        print('Could not read DAT file. Unable to extract icons.')
                        break
                    end

                    extractor = loadfile(apath .. 'sts_bmp_unpacker.lua')()
                end

                extractor.by_id(dat, i, apath .. path)
            end
        end

        if extractor then dat:close() end
    else
        print('Nostrum: Could not extract icons.')
        print('Nostrum: Please point client_path in settings.xml to the playonline folder.')
        print('Ex: C:/Program Files (x86)/PlayOnline/')
    end
end

local hidden = false
local ready = false
local overlay_sandbox = false

local get_party = windower.ffxi.get_party
local alliance = {
    'p0', 'p1', 'p2', 'p3', 'p4', 'p5';
    'a10', 'a11', 'a12', 'a13', 'a14', 'a15';
    'a20', 'a21', 'a22', 'a23', 'a24', 'a25';
}
local displayed_buffs = {
    {clock = 0, t = nil},
    {clock = 0, t = nil},
    {clock = 0, t = nil},
    {clock = 0, t = nil},
    {clock = 0, t = nil},
    {clock = 0, t = nil},
}
local displayed_jobs = {}
local blank = {name = '', hp = -1, mp = -1, hpp = -1, mpp = -1, tp = -1, zone = -1, mob = {}}
local valid_targets = {}
local out_of_zone = {}
local empty = {party1_count = 0, party2_count = 0, party3_count = 0}
local party = empty
local nowhere_to_be_seen = {
    valid_target = false,
    distance = -1
}
local buffs = globals.buffs
local jobs = globals.jobs

local function scan_party()
    local pt = get_party()

    -- windower.ffxi.get_party seems to return garbage tables once in a rare while
    if not pt.p0 or not (pt.party1_count and pt.party1_count > 0) then return end

    local events = overlay_sandbox.overlay
    local player_zone = pt.p0.zone

    for i = 1, 3 do
        -- add or remove lines from display for joining/leaving
        local count_key = 'party' .. tostring(i) .. '_count'
        local old_count = party[count_key]
        local new_count = pt[count_key]

        if old_count > new_count then
            for j = old_count, new_count + 1, -1 do
                events:trigger('display vacant', i, j)

                -- Record the last values for valid_target, so that a comparison can
                -- be made the next time the key is used.
                local party_key = alliance[6 * (i - 1) + j]
                local p = party[party_key]
                valid_targets[party_key] = p.mob and p.mob.valid_target or false
            end
        elseif new_count > old_count then
            for j = old_count + 1, new_count do
                events:trigger('display populated', i, j)
            end
        end

        -- stat changes
        for j = 1, new_count do
            local n = 6 * (i - 1) + j
            local party_key = alliance[n]
            local old_display
            if party[party_key] then
                old_display = party[party_key]
            else
                old_display = blank
                old_display.mob.valid_target = valid_targets[party_key]
            end
            local current_display = pt[party_key]

            if current_display then -- wfgp returning bad tables?
                if current_display.name ~= old_display.name then
                    events:trigger('name change', i, j, current_display.name)
                end

                if current_display.mpp ~= old_display.mpp then
                    events:trigger('mpp change', i, j, current_display.mpp, old_display.mpp)
                end

                if old_display.hpp ~= current_display.hpp then
                    events:trigger('hpp change', i, j, current_display.hpp, old_display.hpp)
                end

                if old_display.tp ~= current_display.tp then
                    events:trigger('tp change', i, j, current_display.tp, old_display.tp)
                end

                if old_display.mp ~= current_display.mp then
                    events:trigger('mp change', i, j, current_display.mp, old_display.mp)
                end

                if old_display.hp ~= current_display.hp then
                    events:trigger('hp change', i, j, current_display.hp, old_display.hp)
                end

                if current_display.mob then
                    local player_job = jobs[current_display.mob.id]
                    if player_job and player_job ~= displayed_jobs[n] then
                        events:trigger('job change', i, j, player_job)
                        displayed_jobs[n] = player_job
                    end
                elseif displayed_jobs[n] ~= 0 then
                    events:trigger('job change', i, j, 0)
                    displayed_jobs[n] = 0
                end

                if current_display.zone ~= player_zone then
                    if not out_of_zone[party_key] then
                        events:trigger('zone out', i, j, current_display.zone)
                        out_of_zone[party_key] = true
                    end

                    if current_display.zone ~= old_display.zone then
                        events:trigger('zone change', i, j, current_display.zone)
                    end
                else
                    -- distance change
                    local nmob = current_display.mob or nowhere_to_be_seen
                    local omob = old_display.mob or nowhere_to_be_seen

                    -- zone indication
                    if out_of_zone[party_key] then
                        -- Out of view should be repeated here for convenience.
                        events:trigger('zone in', i, j)
                        out_of_zone[party_key] = false

                        if not (nmob.valid_target or omob.valid_target) then
                            events:trigger('out of view', i, j)
                        end
                    end

                    if nmob.valid_target then
                        if omob.valid_target then
                            if nmob.distance ~= omob.distance then
                                events:trigger('distance change', i, j, nmob.distance)
                            end
                        else
                            events:trigger('in view', i, j)
                        end
                    elseif omob.valid_target or old_display == blank then
                        events:trigger('out of view', i, j)
                    end
                end
            else
                -- if the table is missing, no comparison can be made and the old table needs to be carried forward
                pt[party_key] = old_display
            end
        end
    end

    -- status effects for players p1..p5
    for i = 2, 6 do
        local player = pt[alliance[i]]
        if not player then break end

        if player.mob then
            local player_buffs = buffs[player.mob.id]
            if player_buffs then -- new party member, or no members with buffs
                local display = displayed_buffs[i]
                if display.t ~= player_buffs or display.clock < player_buffs.clock then
                    display.t = player_buffs
                    display.clock = player_buffs.clock
                    events:trigger('statuses updated', i, player_buffs)
                end
            end
        else
            if displayed_buffs[i].t then
                displayed_buffs[i].t = nil
                events:trigger('statuses updated', i, {n = 0})
            end
        end
    end

    -- status effect for p0
    if displayed_buffs[1].clock ~= buffs.player.clock then
        displayed_buffs[1].clock = buffs.player.clock
        events:trigger('statuses updated', 1, buffs.player)
    end

    if pt.p0.mob then
        local pc_job = jobs[pt.p0.mob.id]
        if pc_job ~= displayed_jobs[1] then
            displayed_jobs[1] = pc_job
            events:trigger('job change', 1, pc_job)
        end
    end

    party = pt
end

do
    local party = get_party()
    local solo = party.p0 and (party.party1_count + party.party2_count + party.party3_count > 1) -- irt party.p0: get_party never returns nil
    local initializing = false -- prevent login and zone events from starting the loop if load is already spinning

    windower.register_event('load', function()
        if settings.overlay == '' then return end

        overlay_sandbox = overlay_loader(settings.overlay)

        if not overlay_sandbox then return end

        initializing = true
        if not settings.debug then
            stall.for_player(function()
                local player = windower.ffxi.get_player()
                local p0_buffs = player.buffs
                p0_buffs.n = #buffs
                p0_buffs.clock = os.clock()

                buffs.player = p0_buffs
                jobs[player.id] = player.main_job_id

                if not hidden then widgets.visibility(true) end
                initializing = false
                ready = true
            end)
        end
    end)

    windower.register_event('login', function()
        if overlay_sandbox and not initializing then
            initializing = true
            if not settings.debug then
                stall.for_player(function()
                    local player = windower.ffxi.get_player()
                    local p0_buffs = player.buffs
                    p0_buffs.n = #buffs
                    p0_buffs.clock = os.clock()

                    buffs.player = p0_buffs
                    jobs[player.id] = player.main_job_id

                    initializing = false
                    if not hidden then widgets.visibility(true) end
                    ready = true
                end)
            end
        end
    end)

    windower.register_event('logout', function()
        initializing = false
        ready = false
        widgets.visibility(false)
    end)

    local fn = parse.outgoing[0x00D]
    local timestamp

    parse.outgoing[0x00D] = function()
        fn()
        ready = false
        if not hidden then widgets.visibility(false) end

        local p
        p, timestamp = windower.packets.last_incoming(0x0C8)
        solo = not p or parse.last_incoming[0x0C8](p)
    end

    windower.register_event('zone change', function()
        if settings.debug or initializing then return end
        initializing = true

        local function begin()
            ready = true
            initializing = false
            if not hidden then widgets.visibility(true) end
        end

        if solo then
            stall.for_player(begin)
        else
            stall.for_alliance(begin, timestamp)
        end
    end)
end

local function user_action()
    local action = sandbox.user_action
    if action.target ~= '' then
        action.target = party[action.target] and party[action.target].name
    end
    local spell = action.spell

    if settings.debug then
        print(('%s → %s'):format(spell.prefix .. ' ' .. spell.name, action.target))
    else
        local formatted_input = spell.name == '' and ('%s %s'):format(spell.prefix, action.target)
            or _addon.language == 'Japanese' and ('%s %s %s'):format(spell.prefix, spell.name, action.target)
            or ('%s "%s" %s'):format(spell.prefix, spell.name, action.target)
        if settings.send_commands_to and settings.send_commands_to ~= '' and type(settings.send_commands_to) == 'string' then
            formatted_input = 'send ' .. settings.send_commands_to .. ' ' .. formatted_input
        end

        windower.chat.input(formatted_input)
    end
end

do
    local listener = widgets.mouse_listener
    windower.register_event('mouse', function(type, x, y, delta, blocked)
        if hidden or not (ready and overlay_sandbox) then return end

        local action = sandbox.user_action
        action.queued = false

        local block = listener(type, x, y, delta, blocked)

        if action.queued then
            user_action()
            action.queued = false
        end

        return block
    end)
end

windower.register_event('keyboard', function(dik, down, flags, blocked)
    if hidden or not (ready and overlay_sandbox) then return end
    local events = overlay_sandbox.overlay
    if not events then return end

    local action = sandbox.user_action
    action.queued = false

    local block = events:trigger('keyboard', dik, down, flags, blocked)

    if sandbox.user_action.queued then
        user_action()
        action.queued = false
    end

    return block
end)

windower.register_event('addon command', function(cmd, ...)
    cmd = cmd or 'help'

    if cmd == 'help' or cmd == 'h' then
        local help_text = [[\cs(20, 200, 120)Nostrum commands:\cr
            help(h): Prints this message.
            visible(v) [show, hide]: Toggles the overlay's visibility.
            overlay(o) <name>: Loads a new overlay.
            send(s) [name]: Requires \cs(0, 180, 255)send\cr addon. Sends commands to the
             - character whose name is provided. Revert this setting by
             - entering the send command with no name argument.
            If an overlay is loaded, it may handle other commands.
            ___________________________________________________________]]
        local overlay_message = [[
            \cs(255, 0, 0)You do not have an overlay loaded.\cr
            Use the \cs(255, 0, 0)overlay(o)\cr command to load an overlay for this
            session. To select a default overlay, edit the \cs(0, 255, 255)<overlay/>\cr
            value in the settings file located at /data/settings.xml]]
        if overlay_sandbox then
            local message = overlay_sandbox.overlay:trigger('overlay command', 'help')
            message = type(message) == 'string' and message or '\\cs(255, 0, 0)The overlay did not return a help string.\\cr'
            overlay_message = '\\cs(20, 200, 120)Overlay commands:\\cr\n' .. message
        end

        print(help_text)
        print(overlay_message)
    elseif cmd == 'visible' or cmd == 'v' then
        local c = select(1, ...)

        if c == 'show' then
            widgets.visibility(true)
            hidden = false
        elseif c == 'hide' then
            widgets.visibility(false)
            hidden = true
        else
            widgets.visibility(hidden)
            hidden = not hidden
        end
    elseif cmd == 'overlay' or cmd == 'o' then
        local overlay = select(1, ...)
        if not overlay or type(overlay) ~= 'string' then return end

        widgets.stop_tracking()
        primitives.destroy_all()

        overlay_sandbox = overlay_loader(overlay)
        party = empty
        if not settings.debug then
            stall.for_player(function()
                ready = true
            end)
        end
    elseif cmd == 'send' or cmd == 's' then
        local name = select(1, ...)

        if name and type(name) == 'string' then
            sandbox.send_target = name
            print('Commands will be sent to ' .. name .. '.')
            print('Note: verify that the send addon is loaded.')
        else
            sandbox.send_target = false
            print('Commands will be sent to current instance.')
        end
    elseif cmd == 'debug' or cmd == 'd' then
		local script = tostring(select(1, ...))
        if not script then return end

		if files.exists('/tests/' .. script .. '.lua') then
			local contents, err = loadfile(windower.addon_path .. 'tests/' .. script .. '.lua')

			if contents then
				local description, test = contents()

				print('\\cs(200, 200, 255)Running test "' .. script .. '"...\\cr')

				if description then
					print('\\cs(220, 180, 235)' .. description .. '\\cr')
				else
					print('\\cs(220, 180, 235)This test has no description.\\cr')
				end

				if test then
					test(select(2, ...))
				end

				print('\\cs(200, 200, 255)Test complete.\\cr')
			else
				print(err)
			end
		else
			print('\\cs(255, 0, 0)Script not found: \\cr' .. script)
		end
    elseif overlay_sandbox then
        local message = overlay_sandbox.overlay:trigger('overlay command', cmd, ...)
        if type(message) == 'string' then print(message) end
    end
end)

windower.register_event('prerender', function()
    if ready and overlay_sandbox then
        scan_party()
    end
end)

if settings.debug then
    function dbg_get_sandbox()
        return overlay_sandbox
    end
    function dbg_get_party()
        return party
    end
    dbg_scan_party = scan_party
    ready = true
end

