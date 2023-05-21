Stage = Object:extend()

function Stage:new()
    self.timer = Timer()
    self.area = Area(self)

    input:bind('f7', function() self.area:addGameObject('Glitcher', 0, 0) end)

    self.font = fonts.m5x7_16
    self.main_canvas = love.graphics.newCanvas(gw, gh)
    self.final_canvas = love.graphics.newCanvas(gw, gh)
    self.rgb_shift_canvas = love.graphics.newCanvas(gw, gh)
    self.rgb_shift_mag = 2
    self.rgb_shift_mag_2 = 0
    self.shockwave_canvas = love.graphics.newCanvas(gw, gh)
    self.temp_canvas = love.graphics.newCanvas(gw, gh)
    self.temp_canvas_2 = love.graphics.newCanvas(gw, gh)
    self.temp_canvas_3 = love.graphics.newCanvas(gw, gh)
    self.glitch_canvas = love.graphics.newCanvas(gw, gh)
    self.rgb_canvas = love.graphics.newCanvas(gw, gh)

    self.player = self.area:addGameObject('Player', gw/2, gh - gh/4)
    self.director = Director(self)
    self.score = 0
    self.paused = false
    self.scorescreen = false
    self.start_sp = skill_points
    self.enemies_created = 1
    self.enemies_killed = 0

    self.projectile_trails = ProjectileTrails()
    self.trail_particles = TrailParticles()
    self.explode_particles = ExplodeParticles()

    if run <= 3 then self.tutorial = Tutorial(gw/2, gh/2) end

    camera:lookAt(gw/2, gh/2)
    camera.scale = 1

    input:unbindAll()
    input:bind('left', 'left')
    input:bind('right', 'right')
    input:bind('up', 'up')
    input:bind('down', 'down')
    input:bind('a', 'left')
    input:bind('d', 'right')
    input:bind('w', 'up')
    input:bind('s', 'down')
    input:bind('mouse1', 'left_click')
    input:bind('return', 'return')
    input:bind('escape', 'escape')
    input:bind('dpleft', 'left')
    input:bind('dpright', 'right')
    input:bind('dpup', 'up')
    input:bind('dpdown', 'down')
    input:bind('fup', 'down')
    input:bind('fright', 'down')
    input:bind('fdown', 'up')
    input:bind('fleft', 'up')
    input:bind('r1', 'up')
    input:bind('l1', 'down')
    input:bind('back', 'escape')
    input:bind('start', 'escape')
    input:bind('q', 'restart')
    input:bind('fleft', 'restart')
    input:bind('fdown', 'restart')
    input:bind('tab', 'tab')

    fadeVolume('music', 5, 0.5)
    fadeVolume('game', 5, 1)
    if not isAnySongPlaying() and not muted then playRandomSong() end

    self.timer:every(0.1, function() 
        self.area:addGameObject('GlitchDisplacement') 
        self.area:addGameObject('RGBShift') 
    end)

    self.info_text_grid = Grid(gw/60, gh/15, 0)
end

function Stage:getInfoTextPosition(x, y)
    local found_grid_spot = false
    local runs = 0
    local function snap(v, x) return math.floor(v/x)*x end
    local grid_x, grid_y = math.floor(snap(x, 60)/60)+1, math.floor(snap(y, 15)/15)+1
    if grid_x > 2 then grid_x = grid_x + love.math.random(0, 2)-2 end

    if self.info_text_grid:get(grid_x, grid_y) == 0 then 
        self.info_text_grid:set(grid_x, grid_y, 1)
        return 60*grid_x - 30, 15*grid_y, grid_x, grid_y
    end

    while runs < 1000 do
        grid_x, grid_y = love.math.random(1, 8), love.math.random(1, 18)
        if self.info_text_grid:get(grid_x, grid_y) == 0 then 
            found_grid_spot = true
            self.info_text_grid:set(grid_x, grid_y, 1)
            return 60*grid_x - 30, 15*grid_y, grid_x, grid_y
        end
        runs = runs + 1
    end
end

function Stage:update(dt)
    if input:pressed('escape') and not self.scorescreen then self:pause() end
    if self.paused then self.paused_object:update(dt) end
    if self.paused then return end
    self.timer:update(dt)
    if self.scorescreen then self.scorescreen_object:update(dt) end

    if not self.scorescreen then self.director:update(dt) end
    if self.tutorial then self.tutorial:update(dt) end

    camera.smoother = Camera.smooth.damped(5)
    camera:lockPosition(dt, gw/2, gh/2)

    self.area:update(dt)
    self.projectile_trails:update(dt)
    self.trail_particles:update(dt)
    self.explode_particles:update(dt)
end

function Stage:draw()
	-- Draw shockwaves
    love.graphics.setCanvas(self.shockwave_canvas)
    love.graphics.clear()
	camera:attach(0, 0, gw, gh)
	love.graphics.setColor(color255To1(127, 127, 127))
	love.graphics.rectangle('fill', 0, 0, gw, gh)
	love.graphics.setColor(color255To1(255, 255, 255))
	self.area:drawOnly({'shockwave'})
	camera:detach()
    love.graphics.setCanvas()

	-- Draw glitches
    love.graphics.setCanvas(self.glitch_canvas)
    love.graphics.clear()
	camera:attach(0, 0, gw, gh)
	love.graphics.setColor(color255To1(127, 127, 127))
	love.graphics.rectangle('fill', 0, 0, gw, gh)
	love.graphics.setColor(color255To1(255, 255, 255))
	self.area:drawOnly({'glitch'})
	camera:detach()
    love.graphics.setCanvas()

	-- Draw rgb shifts
    love.graphics.setCanvas(self.rgb_shift_canvas)
    love.graphics.clear()
	camera:attach(0, 0, gw, gh)
	self.trail_particles:draw()
	self.area:drawOnly({'rgb_shift'})
	camera:detach()
    love.graphics.setCanvas()

	-- Draw rgb glitches
    love.graphics.setCanvas(self.rgb_canvas)
    love.graphics.clear()
	camera:attach(0, 0, gw, gh)
	love.graphics.setColor(color255To1(127, 127, 127))
	love.graphics.rectangle('fill', 0, 0, gw, gh)
	love.graphics.setColor(color255To1(255, 255, 255))
	self.area:drawOnly({'rgb'})
	camera:detach()
    love.graphics.setCanvas()

	-- Main draw start
    love.graphics.setCanvas(self.main_canvas)
    love.graphics.clear()
	camera:attach(0, 0, gw, gh)
	self.explode_particles:draw()
	self.projectile_trails:draw()
	self.area:drawExcept({'rgb_shift', 'rgb', 'shockwave', 'glitch', 'glitch_block'})
	camera:detach()
	love.graphics.setFont(self.font)

	-- Draw tutorial buttons
	if self.tutorial then
		self.tutorial:draw()
	end

	-- Draw Score display
	love.graphics.setColor(color255To1(default_color))
	love.graphics.print(self.score, gw - 20, 10, 0, 1, 1, math.floor(self.font:getWidth(self.score) / 2), math.floor(self.font:getHeight() / 2))
	love.graphics.setColor(color255To1(255, 255, 255))

	-- Draw Skill points display
	love.graphics.setColor(color255To1(skill_point_color))
	love.graphics.print(skill_points .. 'SP', gw - 20, 22, 0, 1, 1, math.floor(self.font:getWidth(skill_points .. 'SP') / 2), math.floor(self.font:getHeight() / 2))
	love.graphics.setColor(color255To1(255, 255, 255))

	-- Draw ammo display
	local r, g, b = unpack(ammo_color)
	love.graphics.setColor(color255To1(r, g, b))
	love.graphics.rectangle('fill', gw / 2 - 52, 16, math.max(48 * (self.player.ammo / self.player.max_ammo), 0), 4)
	love.graphics.setColor(color255To1(r - 32, g - 32, b - 32))
	love.graphics.rectangle('line', gw/2 - 52, 16, 48, 4)
	love.graphics.print('AMMO', gw / 2 - 52 + 24, 26, 0, 1, 1, math.floor(self.font:getWidth('AMMO') / 2), math.floor(self.font:getHeight() / 2) )
	local ammoText = math.floor(self.player.ammo) .. '/' .. math.floor(self.player.max_ammo)
	love.graphics.print(ammoText, gw / 2 - 52 + 24, 8, 0, 1, 1, math.floor(self.font:getWidth(ammoText) / 2), math.floor(self.font:getHeight() / 2))
	love.graphics.setColor(color255To1(255, 255, 255))

	-- Draw boost display
	local r, g, b = unpack(boost_color)
	love.graphics.setColor(color255To1(r, g, b))
	love.graphics.rectangle('fill', gw / 2 + 4, 16, math.max(48 * (self.player.boost / self.player.max_boost), 0), 4)
	love.graphics.setColor(color255To1(r - 32, g - 32, b - 32))
	love.graphics.rectangle('line', gw / 2 + 4, 16, 48, 4)
	love.graphics.print('BOOST', gw / 2 + 4 + 24, 26, 0, 1, 1, math.floor(self.font:getWidth('BOOST') / 2), math.floor(self.font:getHeight() / 2))
	local boostText = math.floor(self.player.boost).."/"..math.floor(self.player.max_boost)
	love.graphics.print(boostText, gw / 2 + 4 + 24, 8, 0, 1, 1, math.floor(self.font:getWidth(boostText) / 2), math.floor(self.font:getHeight() / 2))
	love.graphics.setColor(color255To1(255, 255, 255))

	-- Draw HP display
	local r, g, b = unpack(hp_color)
	if self.player.energy_shield then
		r, g, b = unpack(default_color)
	end
	love.graphics.setColor(color255To1(r, g, b))
	love.graphics.rectangle('fill', gw / 2 - 52, gh - 16, math.max(48 * (self.player.hp / self.player.max_hp), 0), 4)
	love.graphics.setColor(color255To1(r - 32, g - 32, b - 32))
	love.graphics.rectangle('line', gw / 2 - 52, gh - 16, 48, 4)
	if self.player.energy_shield then
		love.graphics.print('ES', gw / 2 - 52 + 24, gh - 24, 0, 1, 1,math.floor(self.font:getWidth('ES') / 2), math.floor(self.font:getHeight() / 2))
	else
		love.graphics.print('HP', gw / 2 - 52 + 24, gh - 24, 0, 1, 1, math.floor(self.font:getWidth('HP') / 2), math.floor(self.font:getHeight() / 2))
	end
	local hpText = math.floor(self.player.hp).."/"..math.floor(self.player.max_hp)
	love.graphics.print(hpText, gw / 2 - 52 + 24, gh - 6, 0, 1, 1, math.floor(self.font:getWidth(hpText) / 2), math.floor(self.font:getHeight() / 2))
	love.graphics.setColor(color255To1(255, 255, 255))

	-- Draw first cycle bar
	local r, g, b = unpack(default_color)
	love.graphics.setColor(color255To1(r, g, b))
	love.graphics.rectangle('fill', gw / 2 + 4, gh - 16, 48 * (self.player.cycle_timer / self.player.cycle_cooldown), 4)
	love.graphics.setColor(color255To1(r - 32, g - 32, b - 32))
	love.graphics.rectangle('line', gw / 2 + 4, gh - 16, 48, 4)

	-- Draw Threader cycle bars
	if self.player.threader then
		love.graphics.rectangle('fill', gw / 2 + 4, gh - 24, 48 * (self.player.cycle_timer_2 / self.player.cycle_cooldown_2), 4)
		love.graphics.setColor(color255To1(r - 32, g - 32, b - 32))
		love.graphics.rectangle('line', gw / 2 + 4, gh - 24, 48, 4)
		love.graphics.rectangle('fill', gw / 2 + 4, gh - 32, 48 * (self.player.cycle_timer_3 / self.player.cycle_cooldown_3), 4)
		love.graphics.setColor(color255To1(r - 32, g - 32, b - 32))
		love.graphics.rectangle('line', gw / 2 + 4, gh - 32, 48, 4)
		love.graphics.rectangle('fill', gw / 2 + 4, gh - 40, 48 * (self.player.cycle_timer_4 / self.player.cycle_cooldown_4), 4)
		love.graphics.setColor(color255To1(r - 32, g - 32, b - 32))
		love.graphics.rectangle('line', gw / 2 + 4, gh - 40, 48, 4)
		love.graphics.print('CYCLE', gw / 2 + 4 + 24, gh - 48, 0, 1, 1, math.floor(self.font:getWidth('CYCLE') / 2), math.floor(self.font:getHeight() / 2))
	else
		love.graphics.print('CYCLE', gw / 2 + 4 + 24, gh - 24, 0, 1, 1, math.floor(self.font:getWidth('CYCLE') / 2), math.floor(self.font:getHeight() / 2))
	end
	love.graphics.setColor(color255To1(255, 255, 255))

	-- Draw rampage counter
	if self.player.rampage then
		local r, g, b = unpack(skill_point_color)
		love.graphics.setColor(color255To1(r, g, b))
		love.graphics.rectangle('fill', gw - 34, gh - 16, 24 * (1 - (self.player.rampage_timer / self.player.rampage_cooldown)), 4)
		love.graphics.setColor(color255To1(r - 32, g - 32, b - 32))
		love.graphics.rectangle('line', gw - 34, gh - 16, 24, 4)
		love.graphics.print(self.player.rampage_counter, gw - 10 - 12, gh - 24, 0, 1, 1, math.floor(self.font:getWidth(self.player.rampage_counter) / 2), math.floor(self.font:getHeight() / 2))
		love.graphics.setColor(color255To1(255, 255, 255))
	end

	-- Draw difficulty meter
	local r, g, b = unpack(default_color)
	love.graphics.setColor(color255To1(r, g, b))
	love.graphics.rectangle('fill', 10, 10, 24 * (self.director.round_timer / (self.director.round_duration / (self.player.enemy_spawn_rate_multiplier * self.director.adaptive_difficulty_enemy_spawn_rate_multiplier))), 4)
	love.graphics.setColor(color255To1(r - 32, g - 32, b - 32))
	love.graphics.rectangle('line', 10, 10, 24, 4)
	love.graphics.print(self.director.difficulty, 38, 11, 0, 1, 1, 0, math.floor(self.font:getHeight() / 2))

	-- Display resource meter
	local r, g, b = unpack(ammo_color)
    if self.player.only_spawn_attack then
        r, g, b = unpack(skill_point_color)
    elseif self.player.only_spawn_boost then
        r, g, b = unpack(boost_color)
    end
	love.graphics.setColor(color255To1(r, g, b))
	love.graphics.rectangle('fill', 10, 18, 24 * (self.director.resource_timer / (self.director.resource_duration / (self.player.resource_spawn_rate_multiplier + self.director.first_10_runs_resource_spawn_rate))), 4)
	love.graphics.setColor(color255To1(r - 32, g - 32, b - 32))
	love.graphics.rectangle('line', 10, 18, 24, 4)

	-- Display attack meter
	local r, g, b = unpack(skill_point_color)
    if self.player.only_spawn_boost then
        r, g, b = unpack(boost_color)
    end
	love.graphics.setColor(color255To1(r, g, b))
	love.graphics.rectangle('fill', 10, 26, 24 * (self.director.attack_timer / (self.director.attack_duration / self.player.attack_spawn_rate_multiplier)), 4)
	love.graphics.setColor(color255To1(r - 32, g - 32, b - 32))
	love.graphics.rectangle('line', 10, 26, 24, 4)

    -- Display item meter
    local maxItems = math.floor(5 * self.player.item_spawn_rate_multiplier)
	if self.director.spawned_item_count < maxItems then
		local r, g, b = unpack(default_color)
		love.graphics.setColor(color255To1(r, g, b))
		love.graphics.rectangle('fill', 10, 34, 24 * (self.director.item_timer / (self.director.item_duration / (self.player.luck_multiplier * self.player.item_spawn_rate_multiplier + self.director.first_10_runs_item_spawn_rate))), 4)
		love.graphics.setColor(color255To1(r - 32, g - 32, b - 32))
		love.graphics.rectangle('line', 10, 34, 24, 4)
        love.graphics.print(maxItems - self.director.spawned_item_count, 38, 35, 0, 1, 1, 0, math.floor(self.font:getHeight() / 2))
	end

	-- Display the current amount of game objects, and what they are
	--local font_height = math.floor(self.font:getHeight() / 2)
	--love.graphics.setColor(default_color)
	--love.graphics.print(self.area.projectile_amount, 10, 40, 0, 1, 1, 0, font_height)
	--love.graphics.print(love.timer.getFPS(), 10, 50, 0, 1, 1, 0, font_height)
	--[[local offset_y = 0
	local offset_x = 0
	for _, obj in ipairs(self.area.game_objects) do
		if obj.class_name ~= "Projectile" and obj.class_name ~= "Ammo" then
			love.graphics.print(obj.class_name, 10 + offset_x, 50 + offset_y, 0, 1, 1, 0, font_height)
			offset_y = offset_y + 10
			if offset_y % 200 == 0 then
				offset_x = offset_x + 60
				offset_y = 0
			end
		end
	end]]

	-- Display "key found" text
	if self.key_found then
		love.graphics.setColor(color255To1(default_color))
		local textWidth = self.font:getWidth(self.key_found)
		local height = gh / 2
		local width = gw / 2 - textWidth / 2
		love.graphics.rectangle('fill', width - 5, height - 12, textWidth + 10, 24)
		love.graphics.setColor(color255To1(background_color))
		love.graphics.print(self.key_found, math.floor(width), math.floor((gh / 2) - 8))
	end

	-- Display score readout
	if self.scorescreen then
		self.scorescreen_object:draw()
	end

	-- Display pause screen
	if self.paused then
		self.paused_object:draw()
	end

    love.graphics.setCanvas()
    love.graphics.setCanvas(self.temp_canvas)
    love.graphics.clear()
	love.graphics.setColor(color255To1(255, 255, 255))
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.setShader(shaders.rgb_shift)
	shaders.rgb_shift:send('amount', {
		random(-self.rgb_shift_mag, self.rgb_shift_mag) / gw,
		random(-self.rgb_shift_mag, self.rgb_shift_mag) / gh
	})
	love.graphics.draw(self.rgb_shift_canvas, 0, 0, 0, 1, 1)
	love.graphics.setShader()
	shaders.displacement:send('displacement_map', self.shockwave_canvas)
	love.graphics.setShader(shaders.displacement)
	love.graphics.draw(self.main_canvas, 0, 0, 0, 1, 1)
	love.graphics.setBlendMode('alpha')
	love.graphics.setShader()
  	love.graphics.setCanvas()
    love.graphics.setCanvas(self.temp_canvas_2)
    love.graphics.clear()
	love.graphics.setColor(color255To1(255, 255, 255))
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.setShader(shaders.glitch)
	shaders.glitch:send('glitch_map', self.glitch_canvas)
	love.graphics.draw(self.temp_canvas, 0, 0, 0, 1, 1)
	love.graphics.setShader()
	love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()
    love.graphics.setCanvas(self.temp_canvas_3)
    love.graphics.clear()
	love.graphics.setColor(color255To1(255, 255, 255))
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.setShader(shaders.rgb_shift)
	shaders.rgb_shift:send('amount', {
		random(-self.rgb_shift_mag_2, self.rgb_shift_mag_2) / gw,
		random(-self.rgb_shift_mag_2, self.rgb_shift_mag_2) / gh
	})
	love.graphics.draw(self.temp_canvas_2, 0, 0, 0, 1, 1)
	love.graphics.setShader()
	love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()
    love.graphics.setCanvas(self.final_canvas)
    love.graphics.clear()
	love.graphics.setColor(color255To1(255, 255, 255))
	love.graphics.setBlendMode("alpha", "premultiplied")

	-- Draw glitches
	if glitch ~= 0 then
		love.graphics.setShader(shaders.rgb)
		shaders.rgb:send('rgb_map', self.rgb_canvas)
	end

	love.graphics.draw(self.temp_canvas_3, 0, 0, 0, 1, 1)
	love.graphics.setShader()
	love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()

	-- Do distortion shaders
    if not disable_expensive_shaders then
        love.graphics.setShader(shaders.distort)
        shaders.distort:send('time', time)
        shaders.distort:send('horizontal_fuzz', 0.6 * (distortion / 10))
        shaders.distort:send('rgb_offset', 0.4 * (distortion / 10))
    end

    love.graphics.setColor(color255To1(255, 255, 255, 255))
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.draw(self.final_canvas, 0, 0, 0, sx, sy)
    love.graphics.setBlendMode('alpha')
    love.graphics.setShader()
end

function Stage:destroy()
    self.area:destroy()
    self.area = nil
    self.player = nil
end

function Stage:finish()
    timer:after(1, function() 
        score = self.score
        if score > high_score then high_score = score end

        if device == 'Fighter' and score >= 10000 then unlockAchievement('10K Fighter') end
        if device == 'Crusader' and score >= 10000 then unlockAchievement('10K Crusader') end
        if device == 'Rogue' and score >= 10000 then unlockAchievement('10K Rogue') end
        if device == 'Bit Hunter' and score >= 10000 then unlockAchievement('10K Bit Hunter') end
        if device == 'Sentinel' and score >= 50000 then unlockAchievement('50K Sentinel') end
        if device == 'Striker' and score >= 50000 then unlockAchievement('50K Striker') end
        if device == 'Nuclear' and score >= 50000 then unlockAchievement('50K Nuclear') end
        if device == 'Cycler' and score >= 50000 then unlockAchievement('50K Cycler') end
        if device == 'Wisp' and score >= 50000 then unlockAchievement('50K Wisp') end

        if device == 'Fighter' and score >= 100000 then unlockAchievement('100K Fighter') end
        if device == 'Crusader' and score >= 100000 then unlockAchievement('100K Crusader') end
        if device == 'Rogue' and score >= 100000 then unlockAchievement('100K Rogue') end
        if device == 'Bit Hunter' and score >= 100000 then unlockAchievement('100K Bit Hunter') end
        if device == 'Sentinel' and score >= 100000 then unlockAchievement('100K Sentinel') end
        if device == 'Striker' and score >= 100000 then unlockAchievement('100K Striker') end
        if device == 'Nuclear' and score >= 100000 then unlockAchievement('100K Nuclear') end
        if device == 'Cycler' and score >= 100000 then unlockAchievement('100K Cycler') end
        if device == 'Wisp' and score >= 100000 then unlockAchievement('100K Wisp') end

        if device == 'Fighter' and score >= 500000 then unlockAchievement('500K Fighter') end
        if device == 'Crusader' and score >= 500000 then unlockAchievement('500K Crusader') end
        if device == 'Rogue' and score >= 500000 then unlockAchievement('500K Rogue') end
        if device == 'Bit Hunter' and score >= 500000 then unlockAchievement('500K Bit Hunter') end
        if device == 'Sentinel' and score >= 500000 then unlockAchievement('500K Sentinel') end
        if device == 'Striker' and score >= 500000 then unlockAchievement('500K Striker') end
        if device == 'Nuclear' and score >= 500000 then unlockAchievement('500K Nuclear') end
        if device == 'Cycler' and score >= 500000 then unlockAchievement('500K Cycler') end
        if device == 'Wisp' and score >= 500000 then unlockAchievement('500K Wisp') end

        if device == 'Fighter' and score >= 1000000 then unlockAchievement('1KK Fighter') end
        if device == 'Crusader' and score >= 1000000 then unlockAchievement('1KK Crusader') end
        if device == 'Rogue' and score >= 1000000 then unlockAchievement('1KK Rogue') end
        if device == 'Bit Hunter' and score >= 1000000 then unlockAchievement('1KK Bit Hunter') end
        if device == 'Sentinel' and score >= 1000000 then unlockAchievement('1KK Sentinel') end
        if device == 'Striker' and score >= 1000000 then unlockAchievement('1KK Striker') end
        if device == 'Nuclear' and score >= 1000000 then unlockAchievement('1KK Nuclear') end
        if device == 'Cycler' and score >= 1000000 then unlockAchievement('1KK Cycler') end
        if device == 'Wisp' and score >= 1000000 then unlockAchievement('1KK Wisp') end

        run = run + 1
        save()
        self.scorescreen = true
        self.difficulty_reached = self.director.difficulty
        self.scorescreen_object = ScoreScreen(self)
    end)
end

function Stage:pause()
    self.paused = not self.paused 
    if self.paused then self.paused_object = Paused(self)
    else self.paused_object = nil end
end

function Stage:rgbShift()
    self.rgb_shift_mag_2 = random(2, 4)
    self.timer:tween('rgb_shift', 0.25, self, {rgb_shift_mag_2 = 0}, 'in-out-cubic')
end

function Stage:glitch(x, y, w, h)
    local w = w or random(8, 16)
    local h = h or random(8, 16)
    for i = 1, love.math.random(0, 3) do
        self.timer:after(0.1*i, function()
            self.area:addGameObject('GlitchDisplacement', 0, 0, {x = x + random(-w/2, w/2), y = y + random(-h/2, h/2), w = random(w/1.5, 1.5*w), h = random(h/1.5, 1.5*h), type = 'rectangular_block_shift'}) 
        end)
    end
end

function Stage:glitchError()
    for i = 1, 10 do self.timer:after(0.1*i, function() self.area:addGameObject('GlitchDisplacement') end) end
    self.rgb_shift_mag_2 = random(4, 8)
    self.timer:tween('rgb_shift', 0.35, self, {rgb_shift_mag_2 = 0}, 'in-out-cubic')
end
