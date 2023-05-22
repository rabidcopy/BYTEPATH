Projectile = GameObject:extend()

function Projectile:new(area, x, y, opts)
    Projectile.super.new(self, area, x, y, opts)
	if self.attack ~= "Flame" then
		playGameShoot1()
	end

	local p_size = opts.s or 2.5
	if current_room.player.size_multiplier > 1 then
		self.s = p_size * (current_room.player.projectile_size_multiplier + ((current_room.player.size_multiplier - 1) / 1.5))
	else
		self.s = p_size * current_room.player.projectile_size_multiplier
	end

	local attack = attacks[self.attack]
	self.v = (opts.v or 200) * current_room.player.pspd_multiplier.value
	self.vy = self.v * math.sin(self.r)
	self.vx = self.v * math.cos(self.r)
	self.h = self.s
	self.w = self.s
	self.color = opts.color or attack.color
	self.shape = HC.circle(self.x, self.y, self.s)
	self.shape.id = self.id
	self.shape.object = self
	self.shape.tag = "Projectile"
	self.damage = attack.damage or 100
	self.shield = not self.no_shield and not self.mine and current_room.player.chances.shield_projectile_chance:next()
	self.pierce = current_room.player.projectile_pierce
	self.duration = (attack.duration and random(attack.duration[1], attack.duration[2]))
		or (self.mine and random(8, 12))
		or (self.shield and 6)
		or 20
	self.duration = self.duration * current_room.player.projectile_duration_multiplier

	-- Attack-specific stats
	if self.attack == "Rapid" then
		self.graphics_types = { "rgb_shift" }
	elseif self.attack == "Spread" then
		self.graphics_types = { "rgb_shift" }
	elseif self.attack == "Homing" then
		local function makeTrail()
			local angle = Vector.angle(self.vx, self.vy)
			local part_x = self.x - self.s * math.cos(angle)
			local part_y = self.y - self.s * math.sin(angle)
			self.area.room.trail_particles:add(part_x, part_y, self.attack)
		end
		self.timer:every(0.02, makeTrail)
		self.v = self.v * current_room.player.homing_speed_multiplier
		self.vy = self.v * math.sin(self.r)
		self.vx = self.v * math.cos(self.r)
		local keep_looking = true
		local tries = 0
		while keep_looking and tries < 20 do
			self.target = table.random(self.area.enemies)
			if self.target and self.target.x < gw and self.target.x > 0 and self.target.y < gh and self.target.y > 0 then
				keep_looking = false
			end
			tries = tries + 1
		end
		local function newTarget()
			if self.target and self.target.dead then
				self.target = table.random(self.area.enemies)
			end
		end
		self.timer:every(1, newTarget)
	elseif self.attack == "Blast" then
		self.color = table.random(negative_colors)
		if self.shield and current_room.player.blast_shield then
			self.duration = self.duration * 6
		end
	elseif self.attack == "Spin" then
		if current_room.player.fixed_spin_direction then
			self.rv = random(math.pi, 2 * math.pi)
		else
			self.rv = table.random({random(-2 * math.pi, -math.pi), random(math.pi, 2 * math.pi)})
		end
		function makeTrail()
			self.area.room.projectile_trails:add(self)
		end
		self.timer:every(0.02, makeTrail)
	elseif self.attack == "Flame" then
		playGameFlame()
		local function makeTrail()
			self.area.room.projectile_trails:add(self)
		end
		self.timer:every(0.05, makeTrail)
	elseif self.attack == "2Split" then
		local function makeTrail()
			local angle = Vector.angle(self.vx, self.vy)
			local part_x = self.x - self.s * math.cos(angle)
			local part_y = self.y - self.s * math.sin(angle)
			self.area.room.trail_particles:add(part_x, part_y, self.attack)
		end
		self.timer:every(0.02, makeTrail)
	elseif self.attack == "4Split" then
		local function makeTrail()
			local angle = Vector.angle(self.vx, self.vy)
			local part_x = self.x - self.s * math.cos(angle)
			local part_y = self.y - self.s * math.sin(angle)
			self.area.room.trail_particles:add(part_x, part_y, self.attack)
		end
		self.timer:every(0.02, makeTrail)
	elseif self.attack ==  "Explode" then
		local function makeTrail()
			local angle = Vector.angle(self.vx, self.vy)
			local part_x = self.x - self.s * math.cos(angle)
			local part_y = self.y - self.s * math.sin(angle)
			self.area.room.trail_particles:add(part_x, part_y, self.attack)
		end
		self.timer:every(0.02, makeTrail)
	end

	if self.mine then
		self.rv = table.random({
			random(-12 * math.pi, -10 * math.pi),
			random(10 * math.pi, 12 * math.pi)
		})
	end

	if current_room.player.projectile_ninety_degree_change then
		local function startAngleChange()
			self.ninety_degree_direction = table.random({-1, 1})
			self.r = self.r + self.ninety_degree_direction * math.pi / 2
			local function changeAngleFirst()
				self.r = self.r - self.ninety_degree_direction * math.pi / 2
				local function changeAngleSecond()
					self.r = self.r - self.ninety_degree_direction * math.pi / 2
					self.ninety_degree_direction = -1 * self.ninety_degree_direction
				end
				self.timer:after("ninety_degree_second", 0.1 / current_room.player.projectile_angle_change_frequency_multiplier, changeAngleSecond)
			end
			self.timer:every("ninety_degree_first", 0.25 / current_room.player.projectile_angle_change_frequency_multiplier, changeAngleFirst)
		end
		self.timer:after(0.2, startAngleChange)
	end

	if current_room.player.projectile_random_degree_change then
		local function startAngleChange()
			self.r = self.r + table.random({-1, 1}) * math.pi / 6
			local function changeAngle()
				self.r = self.r + random(-math.pi / 2, math.pi / 2)
			end
			self.timer:every("forty_five_degree", 0.25 / current_room.player.projectile_angle_change_frequency_multiplier, changeAngle)
		end
		self.timer:after(0.2, startAngleChange)
	end

	if current_room.player.wavy_projectiles then
		local wave_dir = table.random({-1, 1})

		local function doTheWave()
			self.timer:tween(0.25, self, {r = self.r - current_room.player.projectile_waviness_multiplier * wave_dir * math.pi / 4}, "linear")
		end
		self.timer:tween(0.25, self, {r = self.r + current_room.player.projectile_waviness_multiplier * wave_dir * math.pi / 8}, "linear", doTheWave)

		local function startTheWave()
			local function waveBack()
				self.timer:tween(0.5, self, {r = self.r - current_room.player.projectile_waviness_multiplier * wave_dir * math.pi / 4}, "linear")
			end
			self.timer:tween(0.25, self, {r = self.r + current_room.player.projectile_waviness_multiplier * wave_dir * math.pi / 4}, "linear", waveBack)
		end
		self.timer:every(0.75, startTheWave)
	end

	if current_room.player.fast_slow then
		local old_v = self.v
		local function becomeSlow()
			self.timer:tween("fast_slow_second", 0.3, self, {v = current_room.player.projectile_deceleration_multiplier * old_v / 2}, "linear")
		end
		self.timer:tween("fast_slow_first", 0.2, self, {v = 2 * self.v * current_room.player.projectile_acceleration_multiplier}, "in-out-cubic", becomeSlow)
	end

	if current_room.player.slow_fast then
		local old_v = self.v
		local function becomeFast()
			self.timer:tween("slow_fast_second", 0.3, self, {v = 2 * old_v * current_room.player.projectile_acceleration_multiplier}, "linear")
		end
		self.timer:tween("slow_fast_first", 0.2, self, {v = current_room.player.projectile_deceleration_multiplier * self.v / 2}, "in-out-cubic", becomeFast)
	end

	self.damage = self.damage * (self.damage_multiplier or 1) * (current_room.player.damage_multiplier or 1)

	if self.shield then
		self.damage = self.damage * current_room.player.shield_projectile_damage_multiplier
		self.orbit_distance = random(32, 64)
		self.orbit_speed = table.random({
			random(-6, -1),
			random(1, 6)
		}) * current_room.player.pspd_multiplier.value
		self.orbit_offset = random(0, 2 * math.pi)

		self.invisible = true
		local function becomeVisible() self.invisible = false end
		self.timer:after(0.05, becomeVisible)
	end

	self.previous_x, self.previous_y = self.shape:center()

	if self.attack == "Homing" or self.attack == "2Split" or self.attack == "4Split" or self.attack == "Explode" then
		self.mesh_left = love.graphics.newMesh({
			{ -2 * self.s, 0 },
			{ 0, -1.5 * self.s },
			{ 0, 1.5 * self.s }
		}, "fan", "static")
		self.mesh_right = love.graphics.newMesh({
			{ 0, -1.5 * self.s },
			{ 0, 1.5 * self.s },
			{ 1.5 * self.s, 0 }
		}, "fan", "static")
	else
		local length = 2 * self.s
		local width = self.s * 0.375
		self.mesh_left = love.graphics.newMesh({
			{ -length, -width },
			{ 0, -width },
			{ 0, width },
			{ -length, width }
		}, "fan", "static")
		self.mesh_right = love.graphics.newMesh({
			{ 0, -width },
			{ length, -width },
			{ length, width },
			{ 0, width }
		}, "fan", "static")
	end

	self.timer:after(self.duration, self:expire())
end

function Projectile:expire()
	return function()
		if self.attack ~= "2Split" and self.attack ~= "4Split" and self.attack ~= "Explode" and (self.mine or (current_room.player.projectiles_explode_on_expiration and not self.dont_explode)) then
			self.area:addGameObject("Explosion", self.x, self.y, {
				color = self.color,
				w = random(24, 28),
				from_explode_on_expiration = true,
				attack = self.attack
			})
		end
		self:die()
		if self.attack == "Spin" and not self.proj_spawned and current_room.player.chances.spin_projectile_on_expiration_chance:next() then
			self.area:addGameObject("Projectile", self.x, self.y, {
				attack = "Spin",
				color = self.color,
				r = self.r,
				no_shield = true,
				dont_explode = true
			})
		end
	end
end

function Projectile:update(dt)
    Projectile.super.update(self, dt)

    -- Collision
    if self.bounce and self.bounce > 1 then
        if self.x < 0 then
            self.r = math.pi - self.r
            self.bounce = self.bounce - 1
        end
        if self.y < 0 then
            self.r = 2*math.pi - self.r
            self.bounce = self.bounce - 1
        end
        if self.x > gw then
            self.r = math.pi - self.r
            self.bounce = self.bounce - 1
        end
        if self.y > gh then
            self.r = 2*math.pi - self.r
            self.bounce = self.bounce - 1
        end
    else
        if self.x < 0 then self:die({wall_split_angle = 0}) end
        if self.y < 0 then self:die({wall_split_angle = math.pi/2}) end
        if self.x > gw then self:die({wall_split_angle = -math.pi}) end
        if self.y > gh then self:die({wall_split_angle = -math.pi/2}) end
    end

    -- Spin or Mine
    if self.attack == 'Spin' or self.mine then self.r = self.r + self.rv*dt end

    -- Homing
    if self.attack == 'Homing' then
        -- Move towards target
        if self.target then
            local projectile_heading_x, projectile_heading_y = Vector.normalize(self.vx, self.vy)
            local angle = math.atan2(self.target.y - self.y, self.target.x - self.x)
            local to_target_heading_x, to_target_heading_y = Vector.normalize(math.cos(angle), math.sin(angle))
            local final_heading_x, final_heading_y = Vector.normalize(projectile_heading_x + 0.1*current_room.player.pspd_multiplier.value*to_target_heading_x, 
            projectile_heading_y + 0.1*current_room.player.pspd_multiplier.value*to_target_heading_y)
            self.vx, self.vy = self.v*final_heading_x, self.v*final_heading_y
        end

    -- Normal movement
    else self.vx, self.vy = self.v*math.cos(self.r), self.v*math.sin(self.r) end

    -- Shield
    if self.shield then
        local player = current_room.player
        self.shape:moveTo(player.x + self.orbit_distance*math.cos(self.orbit_speed*time + self.orbit_offset), player.y + self.orbit_distance*math.sin(self.orbit_speed*time + self.orbit_offset))
        local x, y = self.shape:center()
        local dx, dy = x - self.previous_x, y - self.previous_y
        self.r = Vector.angle(dx, dy)
    end

    --[[
    for _, shape in ipairs(self:enter('Enemy')) do
        local object = shape.object
        if object then
            object:hit(self.damage, self.x, self.y, self.r)
            if object.hp <= 0 then current_room.player:onKill(object) end
            if self.pierce > 0 then 
                self.pierce = self.pierce - 1
                if self.attack == 'Explode' then self.area:addGameObject('Explosion', self.x, self.y, {color = self.color}) end
            else self:die() end
        end
    end
    ]]--

    -- Move
    self.previous_x, self.previous_y = self.shape:center()
    self.shape:move(self.vx*dt, self.vy*dt)
    self.shape:setRotation(self.r)
    self.x, self.y = self.shape:center()
end

function Projectile:draw()
    if self.invisible then return end
    pushRotate(self.x, self.y, Vector.angle(self.vx, self.vy))
    if self.attack == 'Homing' or self.attack == '2Split' or self.attack == '4Split' or self.attack == 'Explode' then
        love.graphics.setColor(color255To1(self.color))
        love.graphics.draw(self.mesh_left, self.x, self.y)
        love.graphics.setColor(color255To1(default_color))
        love.graphics.draw(self.mesh_right, self.x, self.y)
    else
        love.graphics.setColor(color255To1(self.color))
        if self.attack == 'Spread' then love.graphics.setColor(color255To1(table.random(all_colors))) end
        if self.attack == 'Bounce' then love.graphics.setColor(color255To1(table.random(default_colors))) end
        love.graphics.draw(self.mesh_left, self.x, self.y)
        love.graphics.setColor(color255To1(default_color))
        if self.attack == 'Flame' then love.graphics.setColor(color255To1(self.color)) end
        love.graphics.draw(self.mesh_right, self.x, self.y)
        love.graphics.setLineWidth(1)
    end
    love.graphics.pop()
end

function Projectile:destroy()
    Projectile.super.destroy(self)
end

function Projectile:die(opts)
	local opts = opts or {}
	self.dead = true

	-- Make death particle
	if self.attack == "Spread" then
		self.area:addGameObject("ProjectileDeathEffect", self.x, self.y, {
			color = table.random(all_colors),
			w = 3 * self.s
		})
	else
		self.area:addGameObject("ProjectileDeathEffect", self.x, self.y, {
			color = self.color or default_color,
			w = 3 * self.s
		})
	end

	-- 2Split makes 2 projectiles in directions diagonal to the impact/velocity
	if self.attack == "2Split" and opts.wall_split_angle then
		local split_split = current_room.player.chances.split_projectiles_split_chance:next()
		if self.split_split then
			split_split = false
		end
		self.area:addGameObject("Projectile",
			self.x + 10 * math.cos(opts.wall_split_angle - math.pi / 4),
			self.y + 10 * math.sin(opts.wall_split_angle - math.pi / 4),
			{
				r = opts.wall_split_angle - math.pi / 4,
				attack = split_split and "2Split" or "Neutral",
				color = self.color,
				split_split = split_split,
				proj_spawned = true,
				no_shield = true
			}
		)
		self.area:addGameObject("Projectile",
			self.x + 10 * math.cos(opts.wall_split_angle + math.pi / 4),
			self.y + 10 * math.sin(opts.wall_split_angle + math.pi / 4),
			{
				r = opts.wall_split_angle + math.pi / 4,
				attack = split_split and "2Split" or "Neutral",
				color = self.color,
				split_split = split_split,
				proj_spawned = true,
				no_shield = true
			}
		)
	elseif self.attack == "2Split" and not opts.wall_split_angle then
		local split_split = current_room.player.chances.split_projectiles_split_chance:next()
		if self.split_split then
			split_split = false
		end
		self.area:addGameObject("Projectile",
			self.x + 10 * math.cos(self.r - math.pi / 4),
			self.y + 10 * math.sin(self.r - math.pi / 4),
			{
				r = self.r - math.pi / 4,
				attack = split_split and "2Split" or "Neutral",
				color = self.color,
				split_split = split_split,
				proj_spawned = true,
				no_shield = true
			}
		)
		self.area:addGameObject("Projectile",
			self.x + 10 * math.cos(self.r + math.pi / 4),
			self.y + 10 * math.sin(self.r + math.pi / 4),
			{
				r = self.r + math.pi / 4,
				attack = split_split and "2Split" or "Neutral",
				color = self.color,
				split_split = split_split,
				proj_spawned = true,
				no_shield = true
			}
		)
	end

	-- 4Split makes 4 projectiles in the diagonal directions
	if self.attack == "4Split" then
		local split_split = current_room.player.chances.split_projectiles_split_chance:next()
		if self.split_split then
			split_split = false
		end
		local angles = {
			math.pi / 4,
			3 * math.pi / 4,
			-math.pi / 4,
			-3 * math.pi / 4
		}
		for _, angle in ipairs(angles) do
			self.area:addGameObject("Projectile",
				self.x + 10 * math.cos(angle),
				self.y + 10 * math.sin(angle),
				{
					r = angle,
					attack = split_split and "4Split" or "Neutral",
					color = self.color,
					split_split = split_split,
					proj_spawned = true,
					no_shield = true
				}
			)
		end
	end

	-- Explode attack creates an explosion
	if self.attack == "Explode" then
		self.area:addGameObject("Explosion", self.x, self.y, {
			color = self.color,
			attack = self.attack,
			no_projectiles = self.proj_spawned
		})
	end
end
