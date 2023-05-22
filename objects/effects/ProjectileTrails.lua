ProjectileTrails = Object:extend()

function ProjectileTrails:new()
	--self.trails = {}
	self.psize = 2.5
	self.recalcPrototype = true
end

function ProjectileTrails:update(dt)
	for _, psystem in pairs(self.psystems or {}) do
		psystem:update(dt)
	end
end

function ProjectileTrails:draw()
	if self.recalcPrototype then
		if not self.prototype then
			self.prototype = love.graphics.newCanvas(32, 2)
		end
		local oldCanvas = love.graphics.getCanvas()
		love.graphics.setCanvas(self.prototype)
		love.graphics.clear()
		love.graphics.push()
		love.graphics.setColor(color255To1(255, 255, 255, 255))
		love.graphics.scale(self.psize, 1)
		love.graphics.rectangle("fill", 0, 0, 4, 2)
		love.graphics.pop()
		love.graphics.setCanvas(oldCanvas)
	end
	if not self.psystems then
		self.psystems = {
			Spin = love.graphics.newParticleSystem(self.prototype, 5000),
			Flame = love.graphics.newParticleSystem(self.prototype, 5000)
		}
		local r, g, b = unpack(attacks.Spin.color)
		r, g, b, _ = color255To1(r, g, b)
		self.psystems.Spin:setColors(r, g, b, 128, r, g, b, 0)
		self.psystems.Spin:setParticleLifetime(0.2, 0.3)
		self.psystems.Spin:start()
		r, g, b = unpack(attacks.Flame.color)
		r, g, b, _ = color255To1(r, g, b)
		self.psystems.Flame:setColors(r, g, b, 128, r, g, b, 0)
		self.psystems.Flame:setParticleLifetime(0.2, 0.3)
		self.psystems.Flame:start()
	end
	for _, psystem in pairs(self.psystems) do
		love.graphics.draw(psystem)
	end
end


function ProjectileTrails:add(parent)
	if parent.s ~= self.psize then
		self.recalcPrototype = true
		self.psize = parent.s
	end
	local psystem = self.psystems[parent.attack]
	psystem:setRotation(parent.r)
	psystem:setPosition(parent.x, parent.y)
	psystem:emit(1)
end
