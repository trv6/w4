local bind = require 'libs/keybind'

local cases = {
    {sequence = '{Num_0}', string = 'Num_0', dik = tostring(0x52)},
    {sequence = '<C-{F9}>', string = '[C + F9]', dik = '289',},
    {sequence = '<C-a{Num_0}{F9}e>', string = '[C + a > Num_0 > F9 > e]', dik = '289 > 341 > 326 > 277',},
    {sequence = 'abc<C-abc>', string = 'a > b > c > [C + a > b > c]', dik = '30 > 48 > 46 > 289 > 307 > 305',},
    {sequence = '<C-a>', string = '[C + a]', dik = 289,},
    {sequence = '<AC-a>', string = '[A + C + a]', dik = '291',},
    {sequence = '<S-a>', string = '[S + a]', dik = '286',},
    {sequence = '<C-->', string = '[C + -]', dik = '271',},
    {sequence = '<ACWS- >', string = '[A + C + W + S +  ]', dik = '327',},
    {sequence = ' ', string = ' ', dik = '57',},
    {sequence = 'ab', string = 'a > b', dik = '30 > 48',},
    {sequence = '<W-a><W-b><C-w><A-p>', string = '[W + a] > [W + b] > [C + w] > [A + p]', dik = '293 > 311 > 276 > 282',},
    {sequence = 'a{F9}<C-b>', string = 'a > F9 > [C + b]', dik = '30 > 67 > 307'},
}

for _, case in pairs(cases) do
    local string = bind.tostring(case.sequence)
    assert(string == case.string, 'Expected ' .. case.string .. ' got ' .. string)
    local dik_sequence = bind.dik_tostring(case.sequence)
    assert(dik_sequence == case.dik, 'Expected ' .. case.dik .. ' got ' .. dik_sequence)
end

