local playerSprites
local enemySprites

local level
local font

require("list")

SpriteFrame = require "SpriteFrame"
Map = require "Map"
PlayerControl = require "PlayerControl"
Entity = require "Entity"
PlayerStates = require "PlayerStates"
EnemyStates = require "EnemyStates"

Levels = {"testlevel", "testlevel2", "testlevel3"}

local Level = {}
Level.__index = Level

function Level.new(mapName)
	local self = setmetatable({}, Level)

	self.playerEntity = nil
	self.enemies = list()

	self.map = Map.new(require(mapName), self)
	self.map:setSize(320, 192)

	return self
end

function Level:spawnEntity(entityType, x, y) 
	if entityType == "Player" then
		self.playerEntity = Entity.new(8, 15, level)
		self.playerEntity.sprites = playerSprites
		self.playerEntity:changeAction(PlayerStates.idle)
		self.playerEntity.x = x
		self.playerEntity.y = y
		self.playerEntity.level = self

		local playerControl = PlayerControl.new()

		-- if there's a connected joystick
		if love.joystick.getJoystickCount() > 0 then
			local joysticks = love.joystick.getJoysticks()
			playerControl.joystick = joysticks[1]
		end

		self.playerEntity.playerControl = playerControl
	end

	if entityType == "Snake" then
		local snakeEntity = Entity.new(14, 16, level)
		snakeEntity:changeAction(EnemyStates.snakeGo)
		snakeEntity.sprites = enemySprites

		snakeEntity.level = self
		snakeEntity.x = x
		snakeEntity.y = y

		self.enemies:push(snakeEntity)
	end
end

function Level:update(dt)
	-- update enemies
	for entity in self.enemies:iterate() do
		-- update entity
		entity:action(dt)
	end

	if self.playerEntity ~= nil then
		-- update player
		self.playerEntity:action(dt)

		-- update scrolling to show the player
		self.map:scrollTo(self.playerEntity)			
	end
end

function Level:draw()
	-- draw the map
   	self.map:draw()
   	
   	love.graphics.push()
   	-- draw the entities
   	-- translate according to current world scrolling
  	love.graphics.translate(-self.map.dx, -self.map.dy)

	for entity in self.enemies:iterate() do
		-- update entity
		entity:draw()
	end

	if self.playerEntity ~= nil then
		self.playerEntity:draw()
	end

	-- restore transform
	love.graphics.pop()

end

currentLevel = 0
function warpLevel()
	currentLevel = (currentLevel + 1) % #Levels

	-- load new level
	level = Level.new(Levels[currentLevel + 1])
end

function love.keypressed(key, isrepeat)
	if key == "a" and not isrepeat then
		warpLevel()
	end
end

function love.load()
	-- change window mode
	success = love.window.setMode(1280, 768, {resizable=false, vsync=true, fullscreen=false})
	love.window.setTitle("Sword Game")

	-- load Player sprites
	local spriteImage = love.graphics.newImage("Player Sprites.png")
	spriteImage:setFilter("nearest", "nearest")
	playerSprites = SpriteFrame.new(spriteImage, love.graphics.newImage("Player Mask.png"), love.graphics.newImage("Player Mark.png"))
	playerSprites.runAnimation = { 10, 11, 10, 12 }
	playerSprites.attackAnimation = { 14, 15, 16, 17, 17, 10 }

	-- load enemy sprites
	spriteImage = love.graphics.newImage("Enemy Sprites.png")
	spriteImage:setFilter("nearest", "nearest")
	enemySprites = SpriteFrame.new(spriteImage, love.graphics.newImage("Enemy Mask.png"), love.graphics.newImage("Enemy Mark.png"))

	-- load test level
	level = Level.new(Levels[1])

	font = love.graphics.newImageFont("rotunda.png",
    " !\"#$%&`()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_'abcdefghijklmnopqrstuvwxyz{|}" )
    font:setFilter("nearest", "nearest")
    love.graphics.setFont(font)
end

local time_acc = 0.0

function love.update(dt)
	-- get elapsed time since last frame
	--dt = love.timer.getDelta()

	-- fixed time step
	local timeStep = 1.0 / 60.0

	time_acc = time_acc + dt

	while time_acc > timeStep do
		time_acc = time_acc - timeStep
		
		level:update(timeStep)
	end
end

function printOutline(str, x, y)
	love.graphics.setColor(0, 0, 0, 255)
    love.graphics.print(str, x-1, y-1)
    love.graphics.print(str, x, y-1)
	love.graphics.print(str, x+1, y-1)
    love.graphics.print(str, x-1, y)
	love.graphics.print(str, x+1, y)
    love.graphics.print(str, x-1, y+1)
    love.graphics.print(str, x, y+1)
	love.graphics.print(str, x+1, y+1)

	love.graphics.setColor(255, 255, 255, 255)	
    love.graphics.print(str, x, y)
end

function love.draw()
	-- use scalling, make pixel bigger 
   	love.graphics.scale(4.0, 4.0)

	-- draw the world
	level:draw()

   	printOutline("Current Level : "..Levels[currentLevel + 1], 5, 5)
   	printOutline("Current FPS: "..tostring(love.timer.getFPS( )), 5, 17)
end