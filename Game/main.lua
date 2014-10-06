require("list")
SpriteFrame = require "SpriteFrame"
Map = require "Map"
PlayerControl = require "PlayerControl"
Entity = require "Entity"
PlayerStates = require "PlayerStates"
EnemyStates = require "EnemyStates"

PlayerEntity = {
	width = 8,
	height = 15,
	action = PlayerStates.idle,
	sprites = nil, -- to be set!
	control = nil -- to be set!
}

SnakeEntity = {
	width = 14,
	height = 16,
	action = EnemyStates.snakeGo
}

Entities = { Player = PlayerEntity, Snake = SnakeEntity }


local Level = {}
Level.__index = Level

-- create a new level from a map
function Level.new(mapName)
	local self = setmetatable({}, Level)

	self.playerEntity = nil
	self.enemies = list()

	self.map = Map.new(require(mapName), self)
	ww, wh = love.window.getDimensions()
	self.map:setSize(ww / 4, wh / 4)

	return self
end

-- crappy function use as an entity factory
function Level:spawnEntity(entityType, x, y) 
	local entityData = Entities[entityType]

	if entityType == "Player" then
		assert(entityData.sprites ~= nil)

		self.playerEntity = Entity.new(entityData.width, entityData.height, self)
		self.playerEntity.sprites = entityData.sprites
		self.playerEntity:changeAction(entityData.action)
		self.playerEntity.x = x
		self.playerEntity.y = y

		self.playerEntity.playerControl = entityData.control
	end

	if entityType == "Snake" then
		assert(entityData.sprites ~= nil)
		local snakeEntity = Entity.new(entityData.width, entityData.height, self)
		snakeEntity:changeAction(entityData.action)
		snakeEntity.sprites = entityData.sprites

		snakeEntity.x = x
		snakeEntity.y = y

		self.enemies:push(snakeEntity)
	end
end

-- update the level
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

-- draw the level
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

textElement = {}
textElement.__index = textElement

function textElement.new(label, x, y)
	local self = setmetatable({}, textElement)
	self.text = label
	self.color = {255, 255, 255, 255}

	self.x = x
	self.y = y

	return self
end

function textElement:draw()
	love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4])	
	love.graphics.print(self.text, self.x, self.y)
end

titleScreenState = { thread = nil, game = nil }

function wait(time)
	while time > 0 do
		self, dt = coroutine.yield(true)
		time = time - dt
	end
end

function titleScreenState:updateThread(dt)
	-- fade text it
	while self.text1.color[4] < 255 do
		self, dt = coroutine.yield(true)
		self.text1.color[4] = math.min(self.text1.color[4] + dt * 1024, 255)
	end

	-- display for 2s
	wait(2)

	-- fade out
	while self.text1.color[4] > 0 do
		self, dt = coroutine.yield(true)
		self.text1.color[4] = math.max(self.text1.color[4] - dt * 1024, 0)
	end

	wait(500)
end

function titleScreenState:update(game, dt)
	self:thread(dt)

	for animator in self.animators:iterate() do
		-- update entity
		animator:update(dt)
	end

end

function titleScreenState:draw(game)
	for element in self.elements:iterate() do
		-- update entity
		element:draw()
	end

end

function titleScreenState:load(game)
	self.game = game
	self.thread = coroutine.wrap(self.updateThread)
	self.textAlpha = 0

	self.elements = list()
	self.animators = list()

	self.text1 = textElement.new("This is a test text", 20, 100)
	self.text1.color[4] = 0
	self.elements:push(self.text1)
end

levelState = {}
function levelState.update(game, dt)
	if game.level ~= nil then
		game.level:update(dt)
	end
end

function levelState.draw(game)
	-- draw the world
	if game.level ~= nil then
		game.level:draw()
	
	   	printOutline("Current Level : "..game.levelNames[game.currentLevel + 1], 5, 5)
	   	printOutline("Current FPS: "..tostring(love.timer.getFPS( )), 5, 17)
	end
end

function levelState.load(game)
	-- load test level
	game.level = Level.new(game.levelNames[1])
end


-- main game class
local Game = { 
	playerSprites = nil,
	enemySprites = nil,
	font = nil,

	player1Control = nil,

	level = nil,
	levelNames = {"testlevel", "testlevel2", "testlevel3"},
	currentLevel = 0,

	currentState = nil
}

-- load the game
function Game:load()
    -- default controller
    self.player1Control = PlayerControl.new()

    -- load the default font
	self.font = love.graphics.newImageFont("rotunda.png",
    " !\"#$%&`()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_'abcdefghijklmnopqrstuvwxyz{|}" )
    self.font:setFilter("nearest", "nearest")
    love.graphics.setFont(self.font)

    -- entity
	-- load Player sprites
	local spriteImage = love.graphics.newImage("Player Sprites.png")
	spriteImage:setFilter("nearest", "nearest")
	self.playerSprites = SpriteFrame.new(spriteImage, love.graphics.newImage("Player Mask.png"), love.graphics.newImage("Player Mark.png"))
	self.playerSprites.runAnimation = { 10, 11, 10, 12 }
	self.playerSprites.attackAnimation = { 14, 15, 16, 17, 17, 10 }

    PlayerEntity.control = self.player1Control
    PlayerEntity.sprites = self.playerSprites

	-- load enemy sprites
	spriteImage = love.graphics.newImage("Enemy Sprites.png")
	spriteImage:setFilter("nearest", "nearest")
	self.enemySprites = SpriteFrame.new(spriteImage, love.graphics.newImage("Enemy Mask.png"), love.graphics.newImage("Enemy Mark.png"))
	SnakeEntity.sprites = self.enemySprites


    --mainMenu:load()
    --currentMenu = mainMenu

    self.currentState = titleScreenState
    self.currentState:load(self)
end

function Game:update(dt) 
	-- we always have to update this (maybe it should be done somewhere else?)
	self.player1Control:update()
	
	if self.currentState ~= nil then
		self.currentState:update(self, dt)
	end
	
end

function Game:draw(dt)
	if self.currentState ~= nil then
		self.currentState:draw(self)
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

function love.load()
	-- change window mode
	success = love.window.setMode(1280, 768, {resizable=false, vsync=true, fullscreen=false})
	love.window.setTitle("Sword Game")

	Game:load()
end

local time_acc = 0.0
local total_time = 0.0
local total_frame = 0

function love.update(dt)
	-- fixed time step
	local timeStep = 1.0 / 60.0

	time_acc = time_acc + dt

	while time_acc > timeStep do
		Game:update(dt)

		time_acc = time_acc - timeStep
		total_time = total_time + timeStep
		total_frame = total_frame + 1
	end

end

function love.draw()
	-- use scalling, make pixel bigger 
   	love.graphics.scale(4.0, 4.0)

   	Game:draw()
end