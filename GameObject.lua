GameObject = Object:extend()

function GameObject:new(area, x, y, opts)
    local opts = opts or {}
    if opts then for k, v in pairs(opts) do self[k] = v end end

    self.area = area
    self.x, self.y = x, y
    self.id = UUID()
    self.creation_time = love.timer.getTime()
    self.timer = Timer()
    self.dead = false
    self.depth = 50

    self.previous_collisions = {}
    self.current_collisions = {}
end

function GameObject:update(dt)
    if self.timer then self.timer:update(dt) end
    if self.shape then 
        self.previous_collisions = table.copy(self.current_collisions) 
        self.current_collisions = {}
    end
end

function GameObject:draw()

end

function GameObject:destroy()
    self.timer:destroy()
    if self.shape then HC.remove(self.shape) end
    self.shape = nil
end

function GameObject:enter(tag)
    local shapes = {}
    for shape in pairs(HC.neighbors(self.shape)) do
        if shape.tag == tag then
            if self.shape:collidesWith(shape) then
                self.current_collisions[shape.id] = true
                if not self.previous_collisions[shape.id] then table.insert(shapes, shape) end
            end
        end
    end
    return shapes
end

function GameObject:enemyProjectileCollisions()
    for _, proj in ipairs(self:enter('Projectile')) do
        if proj.object then
			self:hit(proj.object.damage, proj.object.x, proj.object.y, proj.object.r)
			if self.hp <= 0 then
				current_room.player:onKill(self)
			end
			if proj.object.pierce > 0 then
				proj.object.pierce = proj.object.pierce - 1
				if proj.object.attack == "Explode" then
					proj.object.area:addGameObject("Explosion", proj.object.x, proj.object.y, {
						color = proj.object.color,
						attack = proj.object.attack,
						no_projectiles = proj.object.proj_spawned
					})
				end
            else
				proj.object:die()
			end
        end
        if self.dead then
			break
		end
    end
end
