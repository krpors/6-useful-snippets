local Object = require("classic")
local Vector = require("vector")
local Lume = require("lume")
local Log = require("logger")
local MultiMap = require("multimap")

-- Source: https://blog.bruce-hill.com/6-useful-snippets

--[[
Some languages include this as a built-in function (like GLSL), but most don’t,
and that’s a shame. Some languages or libraries do include it, but call it “lerp”
(short for “linear interpolation”), which I think is a bad name. The core concept
of mixing two values is simple, so a simple name is best, and here’s the full
implementation.

Amount should be a value (percentage) between 0 and 1 inclusive.
]]
function mix(a, b, amount)
	return (1 - amount) * a + amount * b
end

--[[
Golden ratio sampling is a technique that uses the golden ratio (5+1)/2
(often represented with the Greek phi: φ) to generate values evenly distributed
between 0 and 1, where the number of values is not known in advance.

Each new value will be in the largest gap between two previously generated
numbers, and each adjacent pair of values will be a fixed distance apart from
each other. The trick is to multiply a counter by the golden ratio and take the
result modulo one
]]
GOLDEN_RATIO = (math.sqrt(5) + 1) / 2
i = 0
function goldenRatioNextSample()
	i = i + 1
	return (i * GOLDEN_RATIO) % 1
end

--[[
Verlet integration;

vel = (pos - prev_pos)/dt
new_vel = vel + dt*accel
new_pos = pos + dt*new_vel

simplified:

new_pos = 2*pos - prev_pos + dt*dt*accel

What’s really useful about this approach is that velocity is implicitly derived
from the position and previous position, so if you have to impose constraints
on the position, then the correct velocities are automatically calculated! For
instance, if you need to keep an object’s position between 0,0 and WIDTH,HEIGHT:

new_pos = 2*pos - prev_pos
new_pos = vec(
		clamp(new_pos.x, 0, WIDTH),
		clamp(new_pos.y, 0, HEIGHT)
	)
]]

local WIDTH = 960
local HEIGHT = 540
local GRAVITY = Vector(0, 1000)
local BUCKETSIZE = 100
local balls = {}

function init()
	balls = {}
	for x = 1, 20 do
		local radius = love.math.random(20, 50)
		local position = Vector(love.math.random(radius, WIDTH - radius), love.math.random(radius, HEIGHT - radius))
		local ball = {
			id = x,
			radius = radius,
			pos = position,
			prevpos = position,
			mass = radius,
			color = {
				r = love.math.random(),
				g = love.math.random(),
				b = love.math.random(),
			}
		}
		table.insert(balls, ball)
	end
end

--[[
To do collision checking with spatial hashing, you divide the world into large
grid cells (buckets). For each object, you find all the buckets that it
approximately touches (it’s okay to be overly inclusive, as long as you don’t
miss any) and add the object to each bucket’s list of members. As you do, mark
the object as potentially colliding with the bucket’s existing members. After
processing each object, you’ll have a list of all potential collisions, which
you can then process to filter out any false positives (things that fall into
the same bucket but don’t actually overlap). For most use cases, this process is
very close to linear in speed, because most hash buckets can only fit a couple
of objects, and most objects only touch a couple of buckets.
]]
function collision_between(balls, bucketsize)
	local buckets = {}
	local maybe_collisions = MultiMap()

	-- Broad phase collision candidate detection:
	for k, ball in ipairs(balls) do
		local xmin = math.floor((ball.pos.x - ball.radius) / bucketsize)
		local xmax = math.floor((ball.pos.x + ball.radius) / bucketsize)
		local ymin = math.floor((ball.pos.y - ball.radius) / bucketsize)
		local ymax = math.floor((ball.pos.y + ball.radius) / bucketsize)
		for x = xmin, xmax do
			for y = ymin, ymax do
				-- Determine in which 'bucket' the ball should reside. Lua
				-- does not allow compound keys in tables so we will have to
				-- transform the key into a string.
				local key = x .. "," .. y
				if buckets[key] == nil then
					buckets[key] = {}
				else
					for _, other in ipairs(buckets[key]) do
						-- Get unique combinations of collisions.
						maybe_collisions:add(ball, other)
					end
				end
				table.insert(buckets[key], ball)
			end
		end
	end

	-- Narrow phase collision detection. This is simply checking the candidates
	-- if the *really* collide.
	local collisions = {}
	for _, collisionCandidate in pairs(maybe_collisions:combinations()) do
		local a = collisionCandidate.first
		local b = collisionCandidate.second
		if a.pos:dist(b.pos) - a.radius - b.radius <= 0 then
			table.insert(collisions, {a = a, b = b})
		end
	end

	return collisions
end

function love.load(args)
	love.window.setTitle("6 Useful Snippets")
	love.window.setMode(WIDTH, HEIGHT, { display = 1})

	init()
end

function love.update(dt)
	if love.keyboard.isDown("rctrl") and love.keyboard.isDown("q") then
		love.event.quit()
	end

	for k, ball in ipairs(balls) do
		-- Verlet integration:
		local nextpos = 2 * ball.pos - ball.prevpos + dt * dt * GRAVITY

		-- Make sure we do not go out of bounds of the screen in the x and y direction:
		local clamped_x = Lume.clamp(nextpos.x, ball.radius, WIDTH - ball.radius)
		local clamped_y = Lume.clamp(nextpos.y, -1000, HEIGHT - ball.radius)
		local maxed_vec = Vector(clamped_x, clamped_y)

		-- Make it bouncy:
		nextpos = nextpos:mix(maxed_vec, 0.6)

		ball.prevpos = ball.pos
		ball.pos = nextpos
	end

	local coll = collision_between(balls, BUCKETSIZE)
	for x = 1, 5 do
		-- This part makes sure the balls don't overlap and bounce against
		-- each other.
		for _, ballCollisions in ipairs(coll) do
			-- Log.info("Coll: %d", v.a.id)
			local a = ballCollisions.a
			local b = ballCollisions.b

			-- Calculate the difference between vector a and b, normalized.
			-- This results in a vector. So far so good
			local a2b = (b.pos - a.pos):norm()
			-- How much do they overlap (this is a number)
			local overlap = (a.radius + b.radius) - a.pos:dist(b.pos)
			-- Calculate the new position of the balls by doing some calculation.
			a.pos = a.pos - 0.5 * a2b * overlap * b.mass / (a.mass + b.mass)
			b.pos = b.pos + 0.5 * a2b * overlap * a.mass / (a.mass + b.mass)
		end

		for _, v in ipairs(balls) do
			-- TODO: stay on scren
		end
	end
end

function love.draw()
	for _, ball in ipairs(balls) do
		love.graphics.setColor(ball.color.r, ball.color.g, ball.color.b, 1)
		love.graphics.circle("fill", ball.pos.x, ball.pos.y, ball.radius)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("" .. ball.id, ball.pos.x - ball.radius / 2 / 2, ball.pos.y - ball.radius*2)
	end


	-- for x = 0, WIDTH, BUCKETSIZE do
	-- 	love.graphics.line(x, 0, x, HEIGHT)
	-- end

	-- for y = 0, HEIGHT, BUCKETSIZE do
	-- 	love.graphics.line(0, y, WIDTH, y)
	-- end
end

function love.keypressed(key)
	if key == "space" then
		init()
	end
end

function love.keyreleased(key)
end
