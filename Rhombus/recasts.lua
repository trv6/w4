local big_g = require 'big_g'

local recasts = {}

recasts.ma = {} -- map id -> timestamp when recast ends
recasts.ja = {}
recasts.ma_cooldown = {} -- set of spells which are cooling down
recasts.ja_cooldown = {}
recasts.charges = {}

local max_strategem_charges
local strategem_recast

local function strategems(recast_time)
    local remaining_strategems = max_strategem_charges - math.ceil(recast_time / strategem_recast)
    recasts.ja_cooldown[231] = remaining_strategems == 0
    recasts.charges[231] = remaining_strategems
end

windower.register_event('job change', function(main, main_level, sub, sub_level)
    recasts.ma = {}
    recasts.ma_cooldown = {}
    recasts.ja = {[0] = recasts.ja[0], [254] = recasts.ja[254]}
    recasts.ja_cooldown = {[0] = recasts.ja_cooldown[0], [254] = recasts.ja_cooldown[254]}
    recasts.charges = {}

    if main_level > 9 then
        local sch, lvl
        if main == 20 then
            sch, lvl = true, main_level
        elseif sub == 20 then
            sch, lvl = true, sub_level
        end

        if sch then
            max_strategem_charges = math.ceil((lvl - 9) / 20)
            strategem_recast = max_strategem_charges == 1 and 240
                or max_strategem_charges == 2 and 120
                or max_strategem_charges == 3 and 80
                or max_strategem_charges == 4 and 60
                or max_strategem_charges == 5 and 48
            if lvl == 99 and big_g.job_points > 549 then
                strategem_recast = strategem_recast - 15
            end
        end
    end
end)

