local g = {}

g.menus = {}
g.job_points = 0 -- this should be the number of job points for the current job
g.ws = {} -- set of all current weapon skills (api function)
g.skills = {} -- map skill name -> skill int
g.ja = {} -- set of all current job abilities (api function)
g.ja_cooldown = {} -- map ja id -> boolean indicating whether or not cooling down
g.ma_cooldown = {}
g.buffs = {} -- set of all current buffs
g.blue_magic_spell_set = {} -- set of current blue magic spells

return g

