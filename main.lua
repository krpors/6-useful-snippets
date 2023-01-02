local Object = require("classic")
local Vector = require("vector")
local Lume = require("lume")

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
local balls = {}

function init()
	balls = {}
	for x = 1, 21 do
		local radius = love.math.random(2, 40)
		local position = Vector(love.math.random(radius, WIDTH - radius), love.math.random(radius, HEIGHT - radius))
		local ball = {
			radius = radius,
			pos = position,
			prevpos = position,
			mass = radius * 2,
			color = {
				r = love.math.random(),
				g = love.math.random(),
				b = love.math.random(),
			}
		}
		table.insert(balls, ball)
	end
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
		nextpos = nextpos:mix(maxed_vec, 0.1)

		ball.prevpos = ball.pos
		ball.pos = nextpos
	end
end

function love.draw()
	for _, ball in ipairs(balls) do
		love.graphics.setColor(ball.color.r, ball.color.g, ball.color.b, 1)
		love.graphics.circle("fill", ball.pos.x, ball.pos.y, ball.radius)
	end
end

function love.keypressed(key)
	if key == "space" then
		init()
	end
end

function love.keyreleased(key)
end
