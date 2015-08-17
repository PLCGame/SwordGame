PowerUp = {}
PowerUp.pickupSound = love.audio.newSource("Sounds/PowerUp.wav", "static")

local spriteImage = love.graphics.newImage("Sprites/Objects.png")
spriteImage:setFilter("nearest", "nearest")
PowerUp.sprites = SpriteFrame.new(spriteImage, 32, 32, 8, 8)

function PowerUp.new(level, x, y)
	local self = Entity.new(level, BoundingBox.new(0, 0, 7, 7))
	self.x = x
	self.y = y

	self.globalY = y;

	self:changeAction(PowerUp.update)
	self.message = PowerUp.message
	self.entityDidEnter = PowerUp.entityDidEnter

	self.type = "powerup"

	-- sprite
	local spriteFrame = {}
	self.sprite = PowerUp.sprites.frames[0]

	return self
end

function PowerUp:update(dt)
	-- nothing to do
	self.animationTimer = self.animationTimer + dt
	self.y = math.floor(math.cos(self.animationTimer * 12.0 + self.x * 0.12) * 3 - 3)  + self.globalY
end

function PowerUp:message(from, type, info)
	if type == "pickup" then
		-- give health
		from.health = from.health + 10

		PowerUp.pickupSound:stop()
		PowerUp.pickupSound:play()

		-- destroy self
		self.level:removeEntity(self)

		-- we handle the message
		return true
	end
end

function PowerUp:entityDidEnter(entity)
end

EntityFactory["PowerUp"] = PowerUp.new

Bullet = {}

function Bullet.new(level, x, y) 
	local self = Entity.new(level, BoundingBox.new(0, 0, 9, 8))
	self.x = x
	self.y = y

	self:changeAction(Bullet.update)
	self.message = Bullet.message
	self.entityDidEnter = Bullet.entityDidEnter

	self.speedX = 256
	self.speedY = 0

	self.sprite = PowerUp.sprites.frames[8]

	self.owner = nil

	return self
end

function Bullet:update(dt)
	self.speedY = math.min(self.speedY + 16.0 * dt, 192.0)
	aabb = self:getAABB()

	-- compute displacement
	local xdisp = self.speedX * dt
	local ydisp = self.speedY * dt

	local v = {}
	v[0] = xdisp
	v[1] = ydisp

	u, n = self.level.map:AABBCast(aabb, v)

	if u < 1.0 then
		self.level:removeEntity(self)
	end

	-- update position
	self.x = self.x + xdisp
	self.y = self.y + ydisp

	self:updateAnimation(2, 1.0 / 20.0)
	self.sprite = PowerUp.sprites.frames[self.animationFrame + 8]
end

function Bullet:message(from, type, info)
end

function Bullet:entityDidEnter(entity)
	if entity.type == "enemy" or (entity.type == "player" and entity ~= self.owner) then
		local dir = 0
		if entity.x < self.x then
			dir = 1
		end

		entity:message(self, "hit", {power = 100, direction = dir})
		self.level:removeEntity(self)
	end
end

EntityFactory["Bullet"] = Bullet.new

Trigger = {}
function Trigger.new(level, x, y, width, height, target, callback) 
	local self = Entity.new(level, BoundingBox.new(0, 0, width, height))
	self.level = level
	self.x = x 
	self.y = y

	self:changeAction(Trigger.update)
	self.entityDidEnter = Trigger.entityDidEnter
	self.entityDidLeave = Trigger.entityDidLeave

	self.target = target
	self.callback = callback
	return self
end

function Trigger:update(dt)
	-- do nothing
end

function Trigger:entityDidEnter(entity)
	self.callback(self.target, self, entity, true)
end

function Trigger:entityDidLeave(entity)
	self.callback(self.target, self, entity, false)
end