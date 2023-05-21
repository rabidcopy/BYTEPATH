ExplodeParticles = Object:extend()

function ExplodeParticles:new()
	return
end

function ExplodeParticles:update(dt)
	for psystem, data in pairs(self.psystems_active or {}) do
		psystem:update(dt)
		if psystem:getCount() == 0 then
			self.psystems_active[psystem] = nil
			self.psystems[psystem] = data
		end
	end
end

function ExplodeParticles:draw()
	if not self.psystems then
		self.psystems = {}
		self.psystems_active = {}
		for i = 1, 200 do
			local prototype = love.graphics.newCanvas(32, 2)
			local psystem = love.graphics.newParticleSystem(prototype, 20)

			psystem:setParticleLifetime(0.3, 0.5)
			psystem:setRelativeRotation(true)
			psystem:setLinearDamping(2)
			psystem:setSizes(1, 0)
			psystem:start()
			self.psystems[psystem] = {
				recalcPrototype = true,
				prototype = prototype,
				psize = 10
			}
		end
	end
	for psystem, data in pairs(self.psystems_active) do
		if data.recalcPrototype then
			local oldCanvas = love.graphics.getCanvas()
			love.graphics.setCanvas(data.prototype)
			love.graphics.clear()
			love.graphics.push()
			love.graphics.setColor(color255To1(255, 255, 255, 255))
			love.graphics.scale(data.psize, 1)
			love.graphics.rectangle("fill", 0, 0, 2, 2)
			love.graphics.pop()
			love.graphics.setCanvas(oldCanvas)
			data.recalcPrototype = false
		end
		love.graphics.draw(psystem)
	end
end

function ExplodeParticles:add(x, y, v, s, color, amt)
	local psystem = nil
	local data = nil
	for ps, dat in pairs(self.psystems) do
		psystem = ps
		data = dat
		self.psystems[ps] = nil
		self.psystems_active[ps] = dat
		break
	end
	if psystem then
		local psize = (s or random(2, 3)) * 2
		if psize ~= data.psize then data.recalcPrototype = true end
		data.psize = psize
		psystem:setPosition(x, y)
		psystem:setColors(color255To1(color or default_color))
		for i = 1, amt or 1 do
			psystem:setDirection(random(0, math.pi * 2))
			if type(v) == "table" then
				psystem:setSpeed(random(v[1], v[2]))
			else
				psystem:setSpeed(v or random(75, 150))
			end
			psystem:emit(1)
		end
	end
end
