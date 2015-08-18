local weaponsSpriteImage = love.graphics.newImage("Sprites/weapons.png")
weaponsSpriteImage:setFilter("nearest", "nearest")
weaponsSprites = SpriteFrame.new(weaponsSpriteImage, 32, 32)

Chainsaw = {}

function Chainsaw.new(level, x, y)
	local self = Entity.new(level, BoundingBox.new(-11, -2, 9, 5))
	self.x = x
	self.y = y

	self.sprite = weaponsSprites.frames[0]

	self:changeAction(Chainsaw.update)

	return self
end

function Chainsaw:update(dt)
	self:updateAnimation(2, 1.0 / 5.0)
	self.sprite = weaponsSprites.frames[self.animationFrame]
end

EntityFactory["Chainsaw"] = Chainsaw.new
