local SpriteFrame = require "SpriteFrame"

local spriteImage = love.graphics.newImage("Player Sprites.png")
spriteImage:setFilter("nearest", "nearest")
local maskImage = love.graphics.newImage("Player Mask.png")
local markImage = love.graphics.newImage("Player Mark.png")

local playerSprites = SpriteFrame.new(spriteImage, maskImage, markImage)
playerSprites.runAnimation = { 10, 11, 10, 12 }
playerSprites.attackAnimation = { 14, 15, 16, 17, 17, 10 }

return playerSprites