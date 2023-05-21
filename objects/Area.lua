Area = Object:extend()

function Area:new(room)
    self.room = room
    self.game_objects = {}
    self.frame_stopped_object_types = {}
    self.enemies = {}
    self.projectile_amount = 0
    self.projectile_cap = 1000
    self.down_fps_timer = 0
    self.up_fps_timer = 0
    self.ammo_amount = 0
    self.ammo_cap = 200
    self.info_text_amount = 0
    self.info_text_cap = 20
end

function Area:update(dt)

    -- Adjust projectile cap based on FPS
    local fps = love.timer.getFPS()
    self.down_fps_timer = self.down_fps_timer + dt
    self.up_fps_timer = self.up_fps_timer + dt
    if fps < 50 then
		if self.down_fps_timer > 2 then
			self.projectile_cap = math.max(self.projectile_cap / 2, 100)
			self.down_fps_timer = 0
		end
		self.up_fps_timer = 0
	elseif fps >= 50 then
		if self.up_fps_timer > 2 then
			self.projectile_cap = math.min(self.projectile_cap + 100, 1000)
			self.up_fps_timer = 1.5
		end
		self.down_fps_timer = 0
    end

    -- Set some projectiles as dead if above projectile cap
	if self.projectile_amount > self.projectile_cap then
		local projs_to_kill = self.projectile_amount - self.projectile_cap
        for _, game_object in ipairs(self.game_objects) do
            if game_object.class_name == 'Projectile' then
                game_object.dead = true
				projs_to_kill = projs_to_kill - 1
				if projs_to_kill <= 0 then break end
            end
        end
    end

    -- Update all objects
    for i = #self.game_objects, 1, -1 do
        local game_object = self.game_objects[i]
        game_object:update(dt)

        -- Remove dead objects
        if game_object.dead then
            if game_object:is(Projectile) and not game_object.proj_spawned then
				self.projectile_amount = self.projectile_amount - 1
			end
            if game_object:is(Ammo) then
				self.ammo_amount = self.ammo_amount - 1
			end
            if game_object:is(InfoText) then
				self.info_text_amount = self.info_text_amount - 1
			end
            game_object:destroy()
			table.remove(self.game_objects, i)
        end
    end

    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        local outside_game_boundaries = false
		if enemy.x > gw + 120 or enemy.x < -120 or enemy.y < -120 or enemy.y > gh + 120 then
			outside_game_boundaries = true
			enemy.dead = true
		end
        if enemy.dead then
            if not outside_game_boundaries then
				self.room.enemies_killed = self.room.enemies_killed + 1
			end
            table.remove(self.enemies, i)
        end
    end

    table.sort(self.game_objects, function(a, b)
        if a.depth == b.depth then return a.creation_time < b.creation_time
        else return a.depth < b.depth end
    end)
end

function Area:draw()
    for _, game_object in ipairs(self.game_objects) do game_object:draw() end
end

function Area:drawExcept(types)
    for _, game_object in ipairs(self.game_objects) do 
        if not game_object.graphics_types then game_object:draw() 
        else
            if #fn.intersection(types, game_object.graphics_types) == 0 then
                game_object:draw()
            end
        end
    end
end

function Area:drawOnly(types)
    for _, game_object in ipairs(self.game_objects) do 
        if game_object.graphics_types then
            if #fn.intersection(types, game_object.graphics_types) > 0 then
                game_object:draw() 
            end
        end
    end
end

function Area:addGameObject(obj_type, x, y, opts)
    if obj_type == 'Projectile' and not opts.proj_spawned then
		if self.projectile_amount > self.projectile_cap then
			return
		else
			self.projectile_amount = self.projectile_amount + 1
		end
	end
    if obj_type == 'Ammo' then
		if self.ammo_amount > self.ammo_cap then
			return
		else
			self.ammo_amount = self.ammo_amount + 1
		end
	end
    if obj_type == 'InfoText' then
		if self.info_text_amount > self.info_text_cap then
			return
		else
			self.info_text_amount = self.info_text_amount + 1
		end
	end

    local new_obj = _G[obj_type](self, x or 0, y or 0, opts or {})
	new_obj.class_name = obj_type
	table.insert(self.game_objects, new_obj)
	if fn.any(enemies, obj_type) then
		self.room.enemies_created = self.room.enemies_created + 1
		table.insert(self.enemies, new_obj)
	end
    return new_obj
end

function Area:addPhysicsWorld()
    self.world = Physics.newWorld(0, 0, true)
end

function Area:destroy()
    for i = #self.game_objects, 1, -1 do
        local game_object = self.game_objects[i]
        game_object:destroy()
        table.remove(self.game_objects, i)
    end
    self.game_objects = {}

    if self.world then
        self.world:destroy()
        self.world = nil
    end
end

function Area:getAllGameObjectsThat(filter)
    local out = {}
    for _, game_object in pairs(self.game_objects) do
        if filter(game_object) then
            table.insert(out, game_object)
        end
    end
    return out
end

function Area:frameStop(duration, object_types)
    self.frame_stopped_object_types = object_types

    if object_types[1] == 'All' then
        local all = {}
        for _, game_object in ipairs(self.game_objects) do
            if not fn.any(all, game_object.class_name) then
                table.insert(all, game_object.class_name)
            end
        end
        local except = object_types.except or {}
        local result = fn.difference(all, except)
        self.frame_stopped_object_types = result
    end

    -- Save object physics state
    for _, game_object in ipairs(self.game_objects) do
        if fn.any(object_types, game_object.class_name) then
            if game_object.body then
                game_object.frame_stopped_velocity = {game_object.body:getLinearVelocity()}
                game_object.body:setLinearVelocity(0, 0)
            end
        end
    end

    timer:after('frame_stop', duration, function()
        self.frame_stopped_object_types = {}

        -- Restore object physics state
        for _, game_object in ipairs(self.game_objects) do
            if fn.any(object_types, game_object.class_name) then
                if game_object.body then
                    game_object.body:setLinearVelocity(unpack(game_object.frame_stopped_velocity))
                    game_object.frame_stopped_velocity = nil
                end
            end
        end
    end)
end


function Area:queryCircleArea(x, y, radius, object_types)
    if not object_types then object_types = {} end
    return self:getAllGameObjectsThat(function(e)
        if fn.include(object_types, e.class_name) and Math.polygon.getCircleIntersection(x, y, radius, rectangleToVertexList(e.x - e.w/2, e.y - e.h/2, e.w, e.h)) then
            return true
        end
    end)
end

function Area:queryPolygonArea(vertices, object_types)
    if not object_types then object_types = {} end
    return self:getAllGameObjectsThat(function(e)
        if fn.include(object_types, e.class_name) and Math.polygon.isPolygonInside(vertices, e.vertices or rectangleToVertexList(e.x - e.w/2, e.y - e.h/2, e.w, e.h)) then
            return true
        end
    end)
end
