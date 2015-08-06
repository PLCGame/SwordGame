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
end

function PowerUp:message(from, type, info)
	if type == "pickup" then
		-- give health
		from.health = from.health + 10

		PowerUp.pickupSound:stop()
		PowerUp.pickupSound:play()

		-- destroy self
		self.level:removeEntity(self)
	end
end

function PowerUp:collideWith(entity)
end