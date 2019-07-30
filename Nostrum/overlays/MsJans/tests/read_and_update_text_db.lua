-- Run test twice on fresh install

local io = require 'io'
local os = require 'os'
local sets = require 'sets'
local lists = require 'lists'
local serpent = require 'serpent'
local table = require 'table'

local path = windower.addon_path .. 'data/textdb.lua'
local file = io.open(path, 'r')
local tmpdb =
[[{
    Consolas = {
        [10] = {
            A={x=10,y=10}
        }
    }
}]]

local dummy_path

if file then
    dummy_path = string.sub(path, 1, -6) .. 'real.lua'
    file:close()
    os.rename(path, dummy_path)
end

file = io.open(path, 'w')
file:write(tmpdb)
file:close()

local profiles = {
    foo = {
        palette = {
            {abc = 'fail', [3] = 'fail', text = 'pass'},
            {def = 'fail2', [2] = 'fail2', text = 'pass2'},
        },
        bar = {
            {text = 'pass3'}
        }
    },
    baz = {
        palette = {
            {abc = 'fail4', [3] = 'fail4', text = 'pass4'},
            {def = 'fail5', [2] = 'fail5', text = 'pass5'},
        },
        bar = {
            {text = 'pass6'}
        }
    }
}

local settings = {
    palette_region = {
        button = {
            text = {
                bold = true,
                italic = false,
                font = "Times",
                size = 15,
            }
        }
    }
}

package.loaded.settings = settings
package.loaded.profiles = profiles

local good_result = {
    Consolas = {
        [10] = {
            A={x=10,y=10},
        },
    },
    Times = {
        [15] = {
            pass={x=39,y=24},
            pass2={x=49,y=24},
            pass4={x=49,y=24},
            pass5={x=49,y=24},
            pass3={x=49,y=24},
            pass6={x=49,y=24},
        }
    }
}

require 'tables'

local dimensions = require 'text_dimensions'
local textdb = dimensions.read('data/textdb.lua')

dimensions.update(textdb)
dimensions.write(textdb, 'data/textdb.lua')

-- table.update sets a metatable which causes table.equals to fail
local function strip_metatable(t)
	setmetatable(t, nil)
	for _, v in pairs(t) do
		if type(v) == 'table' then
			strip_metatable(v)
		end
	end
end

strip_metatable(textdb)

-- test the update
assert(table.equals(textdb, good_result),
'text update failed: \n' .. serpent.block(textdb, {comment = false}))
print('Update passed')

-- test the write
file = io.open(path, 'r')
local success, from_disk = serpent.load(file:read('*a'))
file:close()

if not success then
    error('Couldn\'t read file')
end

strip_metatable(from_disk)

assert(table.equals(from_disk, good_result), 'read result did not match: \n' .. serpent.block(from_disk, {comment = false}))
print('Write passed')

-- do it again, but this time with no pre-existing textdb
os.remove(path)
good_result = {
    Times = {
        [15] = {
            pass={x=39,y=24},
            pass2={x=49,y=24},
            pass4={x=49,y=24},
            pass5={x=49,y=24},
            pass3={x=49,y=24},
            pass6={x=49,y=24},
        }
    }
}
textdb = dimensions.read('data/textdb.lua')
assert(table.equals(textdb, {}), 'read failed to create default')
print('init passed')

dimensions.update(textdb, good_result)
strip_metatable(textdb)
assert(table.equals(textdb, good_result), 'second update failed')

-- do it a third time, but this time with a corrupted textdb
file = io.open(path, 'w')
file:write('{asdfsdfsdfasew')
file:close()

textdb = dimensions.read('data/textdb.lua')
assert(table.equals(textdb, {}), 'read failed to handle corrupted file')
print('corruption test passed')

dimensions.update(textdb, good_result)
strip_metatable(textdb)
assert(table.equals(textdb, good_result), 'third update failed')

print('cool')
os.remove(path)

if dummy_path then
    os.rename(dummy_path, path)
end

