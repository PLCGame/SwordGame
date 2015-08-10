PowerUp = {}
PowerUp.pickupSound = love.audio.newSource("Sounds/PowerUp.wav", "static")

function PowerUp.new(level, x, y)
	local self = Entity.new(7, 7, level)
	self.x = x
	self.y = y
	self:changeAction(PowerUp.update)
	self.message = PowerUp.message
	self.collideWith = PowerUp.collideWith

	self.type = "powerup"

	-- sprite
	local spriteFrame = {}
	spriteFrame.image = love.graphics.newImage("Levels/testlevel_obj.png")
	spriteFrame.quad = love.graphics.newQuad(72, 25, 7, 7, spriteFrame.image:getWidth(), spriteFrame.image:getHeight())
	spriteFrame.xoffset = -4
	spriteFrame.yoffset = -6
	self.sprite = spriteFrame

	return self
end

function PowerUp:update(dt)
	-- nothing to do
	self.animationTimer = self.animationTimer + dt
	self.sprite.yoffset = math.floor(math.cos(self.animationTimer * 18.0 + self.x * 4.4) * -2) - 6

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

function PowerUp:collideWith(entity)
end

EntityFactory["PowerUp"] = PowerUp.new

Bullet = {}
-- Sprites
local spriteImage = love.graphics.newImage("Sprites/Bullets Sprites.png")
spriteImage:setFilter("nearest", "nearest")

Bullet.sprites = SpriteFrame.new(spriteImage, love.graphics.newImage("Sprites/Bullets Mask.png"), love.graphics.newImage("Sprites/Bullets Mark.png"))


function Bullet.new(level, x, y) 
	local self = Entity.new(9, 8, level)
	self.x = x
	self.y = y

	self:changeAction(Bullet.update)
	self.message = Bullet.message
	self.collideWith = Bullet.collideWith

	self.speedX = 256
	self.speedY = 0

	self.sprite = Bullet.sprites.frames[0]

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
	self.sprite = Bullet.sprites.frames[self.animationFrame]
end

function Bullet:message(from, type, info)
end

function Bullet:collideWith(entity)
	if entity.type == "enemy" then
		local dir = 0
		if entity.x < self.x then
			dir = 1
		end

		entity:message(self, "hit", {power = 100, direction = dir})
		self.level:removeEntity(self)
	end
end

EntityFactory["Bullet"] = Bullet.new