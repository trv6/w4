local target = require 'display/target'
local coroutine = require 'coroutine'

-- visually check the target is created
print('create')
foo = target.new(500, 500, true)
assert(foo, 'target.new returned nothing')
foo:update({name = 'test', hpp = 100})

-- visually check the target moves
print('pos')
coroutine.sleep(3)
foo:pos(100, 100)
local x, y = foo:pos()
assert(x == 100 and y == 100, 'position didn\'t update')

-- visually check the target hides
print('visibility')
coroutine.sleep(3)
foo:visible(false)
assert(not foo:visible(), 'visibility not false')
coroutine.sleep(3)
foo:visible(true)
assert(foo:visible(), 'visibility not true')

--update
foo:update({name = 'new', hpp = 77})
coroutine.sleep(3)

-- hpp
foo:update_hpp(100, 100)
coroutine.sleep(3)
foo:update_hpp(75, 100)
coroutine.sleep(3)
foo:update_hpp(50, 75)
coroutine.sleep(3)
foo:update_hpp(25, 50)
coroutine.sleep(3)
foo:update_hpp(0, 25)
