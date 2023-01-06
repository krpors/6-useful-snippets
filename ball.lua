local Object = require("classic")

local Ball = Object:extend()

function Ball:new()
    self.radius = love.math.random(40, 50)
    self.pos = Vector(love.math.random(radius, WIDTH - radius), love.math.random(radius, HEIGHT - radius))
    self.prevpos = position,
    self.mass = radius * 2,
    self.color = {
        r = love.math.random(),
        g = love.math.random(),
        b = love.math.random(),
    }
end

function Ball:update(dt)
end

function Ball:draw()
end

function Ball:__tostring()
    return string.format("Ball[radius=%d]", self.radius)
end

return Ball
