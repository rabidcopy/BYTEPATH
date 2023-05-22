Explosion = GameObject:extend()

function Explosion:new(area, x, y, opts)
    Explosion.super.new(self, area, x, y, opts)
    playGameExplosion()

    self.w = 16
    self.color = opts.color or {255, 255, 255}
    local radius = opts.w or random(48, 56)

	if current_room.player.projectiles_explosions and not self.no_projectiles then
		local function emitParticles()
			camera:shake(radius / 24, 60, radius / 48 * 0.4)
			current_room.explode_particles:add(self.x, self.y, {radius / 48 * 150, radius / 48 * 300}, random(6, 10), self.color, love.math.random(8, 12))

			local function beDead() self.dead = true end
			self.timer:tween(0.2, self, {w = 0}, "in-out-cubic", beDead)
		end
		self.timer:tween(0.1, self, {w = radius * current_room.player.area_multiplier}, "in-out-cubic", emitParticles)

		for i = 1, 4 do
			local function spawnProjectile()
				local angle = random(0, 2 * math.pi)
				self.area:addGameObject("Projectile", self.x + math.cos(angle), self.y + math.sin(angle), {
					r = angle,
					attack = self.attack or current_room.player.attack,
					dont_explode = self.from_explode_on_expiration,
					no_shield = true,
					proj_spawned = true
				})
			end
			self.timer:after((i - 1) * 0.05, spawnProjectile)
		end
	else
		local function emitParticles()
			camera:shake(radius / 48, 60, (radius / 48) * 0.4)
			current_room.explode_particles:add(self.x, self.y, {radius / 48 * 150, radius / 48 * 300}, random(6, 10), self.color, love.math.random(8, 12))

			local function beDead() self.dead = true end
			self.timer:tween(0.2, self, {w = 0}, "in-out-cubic", beDead)
		end
		self.timer:tween(0.1, self, {w = radius * current_room.player.area_multiplier}, "in-out-cubic", emitParticles)

		for i, enemy in ipairs(self.area.enemies) do
			local dist = distance(enemy.x, enemy.y, self.x, self.y)
			local dmg_radius = radius * current_room.player.area_multiplier
			if dist < dmg_radius then
				local function hitEnemy()
					if enemy.hit then
						enemy:hit(200 * (self.damage_multiplier or 1))
					else
						enemy:die()
					end
				end
				self.timer:after((i - 1) * 0.025, hitEnemy)
			end
		end
	end

	self.current_color = default_color
	local function changeColor()
		self.current_color = self.color
		local function beDead() self.dead = true end
		self.timer:after(opts.d2 or 0.2, beDead)
	end
	self.timer:after(opts.d1 or 0.1, changeColor)

	self.area:addGameObject("ShockwaveDisplacement", self.x, self.y, {
		wm = screen_shake / 10 * radius / 48
	})
	current_room:glitch(self.x, self.y, radius, radius)
end

function Explosion:update(dt)
    Explosion.super.update(self, dt)
end

function Explosion:draw()
    if current_room.player.projectiles_explosions then return end
    love.graphics.setColor(color255To1(self.current_color))
    love.graphics.rectangle('fill', self.x - self.w/2, self.y - self.w/2, self.w, self.w)
    love.graphics.setColor(color255To1(255, 255, 255))
end

function Explosion:destroy()
    Explosion.super.destroy(self)
end
