TrailParticles = Object:extend()

function TrailParticles:update(dt)
	for _, psystem in pairs(self.psystems or {}) do
		psystem:update(dt)
	end
end

function TrailParticles:draw()
	if not self.prototype then
		self.prototype = love.graphics.newCanvas(8, 8)
		local oldCanvas = love.graphics.getCanvas()
		love.graphics.setCanvas(self.prototype)
		love.graphics.clear()
		love.graphics.setColor(color255To1(255, 255, 255, 255))
		love.graphics.circle("fill", 4, 4, 2)
		love.graphics.setCanvas(oldCanvas)
	end
	if not self.psystems then
		self.psystems = {
			["Homing"] = love.graphics.newParticleSystem(self.prototype, 5000),
			["2Split"] = love.graphics.newParticleSystem(self.prototype, 5000),
			["4Split"] = love.graphics.newParticleSystem(self.prototype, 5000),
			["Explode"] = love.graphics.newParticleSystem(self.prototype, 5000)
		}
		local r, g, b = unpack(attacks["Homing"].color)
		self.psystems["Homing"]:setColors(color255To1(r, g, b, 255))
		self.psystems["Homing"]:setParticleLifetime(0.1, 0.15)
		self.psystems["Homing"]:setSizes(1, 0)
		self.psystems["Homing"]:start()
		r, g, b = unpack(attacks["2Split"].color)
		self.psystems["2Split"]:setColors(color255To1(r, g, b, 255))
		self.psystems["2Split"]:setParticleLifetime(0.1, 0.15)
		self.psystems["2Split"]:setSizes(1, 0)
		self.psystems["2Split"]:start()
		r, g, b = unpack(attacks["4Split"].color)
		self.psystems["4Split"]:setColors(color255To1(r, g, b, 255))
		self.psystems["4Split"]:setParticleLifetime(0.1, 0.15)
		self.psystems["4Split"]:setSizes(1, 0)
		self.psystems["4Split"]:start()
		r, g, b = unpack(attacks["Explode"].color)
		self.psystems["Explode"]:setColors(color255To1(r, g, b, 255))
		self.psystems["Explode"]:setParticleLifetime(0.1, 0.15)
		self.psystems["Explode"]:setSizes(1, 0)
		self.psystems["Explode"]:start()
	end
	for _, psystem in pairs(self.psystems) do
		love.graphics.draw(psystem)
	end
end

function TrailParticles:add(x, y, attack)
	local psystem = self.psystems[attack]
	psystem:setPosition(x, y)
	psystem:emit(1)
end
