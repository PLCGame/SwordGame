local playerSprites
local enemySprites

local level
local font

SpriteFrame = require "SpriteFrame"
Map = require "Map"
PlayerControl = require "PlayerControl"
Entity = require "Entity"
PlayerStates = require "PlayerStates"
EnemyStates = require "EnemyStates"

local Level = {}
Level.__index = Level

function Level:update(dt)
	
end

function Level:draw()

end

function createPlayerEntity()
	local playerEntity = Entity.new(8, 15, level)
	playerEntity.sprites = playerSprites
	playerEntity:changeAction(PlayerStates.idle)

	local playerControl = PlayerControl.new()

	-- if there's a connected joystick
	if love.joystick.getJoystickCount() > 0 then
		local joysticks = love.joystick.getJoysticks()
		playerControl.joystick = joysticks[1]
	end

	playerEntity.playerControl = playerControl

	return playerEntity
end

function createSnakeEntity()
	local snakeEntity = Entity.new(14, 16, level)
	snakeEntity:changeAction(EnemyStates.snakeGo)
	snakeEntity.sprites = enemySprites

	return snakeEntity
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
	level = {}
	level.Map = Map.new(require "testlevel3", {["Player"] = createPlayerEntity, ["Snake"] = createSnakeEntity})
	level.Map:setSize(320, 192)

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
		
		-- update entity
		for entity in level.Map.entities:iterate() do
			-- update entity
			entity:action(timeStep)
		end


		-- update scrolling to show the player
		if level.Map.entities.first then
			level.Map:scrollTo(level.Map.entities.first)
		end
	end
end

function love.draw()
	-- use scalling, make pixel bigger 
   	love.graphics.scale(4.0, 4.0)
    -- draw the world 32 pixel from the top
   	--love.graphics.translate(0, 32)

	-- set scissor 
	--love.graphics.setScissor(0, 32 * 4, 320 * 4, 160 * 4)

	-- draw the world
   	level.Map:draw()
   	
   	-- draw the entities
   	-- translate according to current world scrolling
  	love.graphics.translate(-level.Map.dx, -level.Map.dy)

	for entity in level.Map.entities:iterate() do
		-- update entity
		entity:draw()
	end

	-- restore transform
  	love.graphics.translate(level.Map.dx, level.Map.dy)

   	love.graphics.setColor(255, 255, 255, 255)
    love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 0, 10)

	-- restore state
	--love.graphics.setScissor()
end