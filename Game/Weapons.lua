local weaponsSpriteImage = love.graphics.newImage("sprites/weapons.png")
weaponsSpriteImage:setFilter("nearest", "nearest")
weaponsSprites = SpriteFrame.new(weaponsSpriteImage, 32, 32)

Chainsaw = {}

function Chainsaw.new(level, x, y)
	local self = Entity.new(9, 8, level)
	self.x = x
	self.y = y

	self.sprite = weaponsSprites.frames[0]
	print(self.sprite)

	return self
end