require("list")
SpriteFrame = require "SpriteFrame"
Map = require "Map"
PlayerControl = require "PlayerControl"
Entity = require "Entity"
require "PlayerEntity"
require "Enemies"

mainPlayerControl = nil

local Level = {}
Level.__index = Level

-- create a new level from a map
function Level.new(mapName)
	local self = setmetatable({score = 0}, Level)

	self.playerEntity = nil
	self.enemies = list()

	self.map = Map.new(require(mapName), self)
	ww, wh = love.window.getDimensions()
	self.map:setSize(ww / 4, wh / 4)

	return self
end

-- crappy function use as an entity factory
function Level:spawnEntity(entityType, x, y) 
	if entityType == "Player" then
		self.playerEntity = PlayerEntity.new(self, x, y)
		self.playerEntity.playerControl = mainPlayerControl
	end

	if entityType == "Snake" then
		local snakeEntity = SnakeEntity.new(self, x, y)
		self.enemies:push(snakeEntity)
	end
end

-- update the level
function Level:update(dt)
	-- update enemies
	-- they can be removed on their action function, 
	-- so keep track of the next one in the list
	local enemy = self.enemies.first
	while enemy ~= nil do
		local nextEnemy = enemy._next

		enemy:action(dt)
		
		enemy = nextEnemy
	end

	-- update the player entity
	if self.playerEntity ~= nil then
		-- update player
		self.playerEntity:action(dt)

		-- update scrolling to show the player
		self.map:scrollTo(self.playerEntity)			
	end
end

-- draw the level
function Level:draw()
	-- use white color
	love.graphics.setColor(255, 255, 255, 255)	

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

-- UI element animator
function fadeInAlpha(self, elem, dt, inc)
	elem.color[4] = math.min(elem.color[4] + inc * dt, 255)
	return elem.color[4] == 255
end

function fadeOutAlpha(self, elem, dt, inc)
	elem.color[4] = math.max(elem.color[4] - inc * dt, 0)
	return elem.color[4] == 0
end

function typeWritter(self, elem, dt, text)
	self.timer = self.timer + dt

	if self.timer > 0.05 then
		-- increment ptr
		self.current = self.current + 1

		-- if it's space, continue to increment
		while text:sub(self.current, self.current) == " " do
			self.current = self.current + 1
		end

		-- copy to current character
		elem.text = text:sub(1, self.current)

		self.timer = self.timer - 0.05
	end

	return self.current == text:len()
end


textElement = {}
textElement.__index = textElement

function textElement.new(label, x, y)
	local self = setmetatable({}, textElement)
	self.text = label
	self.color = {255, 255, 255, 255}

	self.x = x
	self.y = y

	self.animators = list()

	return self
end

function textElement:update(dt)
	-- enumerate animators
	local animator = self.animators.first

	while animator do
		local _next = animator._next

		-- execute
		local res = animator:execute(self, dt, animator.param)
		if res then
			self.animators:remove(animator)
		end

		animator = _next
	end
end

function textElement:draw()
	love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4])	
	love.graphics.print(self.text, self.x, self.y)
end

function textElement:fadeIn(speed)
	animator = { execute = fadeInAlpha, param = speed }
	self.animators:push(animator)
end

function textElement:fadeOut(speed)
	animator = { execute = fadeOutAlpha, param = speed }
	self.animators:push(animator)
end

function textElement:typeWrite(text)
	animator = { execute = typeWritter, param = text, timer = 0, current = 0 }
	self.animators:push(animator)
end


titleScreenState = { thread = nil, game = nil }

function wait(time)
	while time > 0 do
		self, game, dt = coroutine.yield(true)
		time = time - dt
	end
end

function titleScreenState:updateThread(game, dt)
	wait(1)
	-- fade text it
	local text1 = textElement.new("Get ready!", 20, 100)
	self.elements:push(text1)
	text1.color[4] = 0
	text1:fadeIn(1024)

	text2 = textElement.new("", 20, 150)
	self.elements:push(text2)
	text2:typeWrite("It will start soon :)")

	wait(2)
	text1:fadeOut(1024)
	wait(0.5)
	text2:fadeOut(1024)
	wait(1)

	-- start a levek
	-- change state
	game.states:pop()

	-- set level state
	levelState.levelIndex = 1
	game.states:push(levelState)
	game.states.last:load(game)
end

function titleScreenState:update(game, dt)
	self:thread(game, dt)

	for elem in self.elements:iterate() do
		-- update entity
		elem:update(dt)
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

	self.elements = list()
end

inGameMenuState = {}
inGameMenuState.__index = inGameMenuState

function inGameMenuState.new()
	local self = setmetatable({}, inGameMenuState)

	self.index = 1

	return self
end

function inGameMenuState:update(game, dt)
	if game.player1Control:testTrigger("down") then
		self.index = math.min(self.index + 1, #game.levels)
	end

	if game.player1Control:testTrigger("up") then
		self.index = math.max(self.index - 1, 1)		
	end

	if game.player1Control:testTrigger("back") then
		-- go back
		game.states:pop()
	end


	if game.player1Control:testTrigger("attack") or game.player1Control:testTrigger("start") then
		-- change state
		game.states:pop()
		game.states:pop()

		levelState.levelIndex = self.index
	    game.states:push(levelState)
	    game.states.last:load(game)
	end

end

function inGameMenuState:draw(game)
	love.graphics.setColor(255, 255, 255, 255)	
	love.graphics.print("Select Level", 100, 80)

	-- draw level name	
	i = 0
	for key, level in pairs(game.levels) do
		if key == self.index then
			love.graphics.setColor(255, 0, 0, 255)	
		else
			love.graphics.setColor(255, 255, 255, 255)	
		end

		love.graphics.print(level.map, 100, 100 + i)
		i = i + 12
	end
end

function inGameMenuState:load(game)

end

levelState = { levelIndex = 1}
function levelState:update(game, dt)
	if game.level ~= nil then
		game.level:update(dt)
	end

	if game.player1Control:testTrigger("back") then
		game.states:push(inGameMenuState.new())
		game.states.last:load(game)
	end
end

function levelState:draw(game)
	-- draw the world
	if game.level ~= nil then
		-- Draw the Level
		game.level:draw()
	
		-- draw the UI
	   	--printOutline("Current Level : "..game.levels[self.levelIndex].map, 5, 5)
	   	--printOutline("Current FPS: "..tostring(love.timer.getFPS( )), 5, 17)
	   	printOutline("Score: ".. game.level.score, 5, 5)

	end
end

function levelState:load(game)
	-- load test level
	self.game = game
	game.level = Level.new(game.levels[self.levelIndex].map)

	if game.musicSource ~= nil then
		game.musicSource:stop()
	end
	
	game.musicSource = love.audio.newSource("Music/" .. game.levels[self.levelIndex].music)
	game.musicSource:setLooping(true)
	game.musicSource:setVolume(1.0)
	--game.musicSource:play()
end


-- main game class
local Game = { 
	font = nil,

	player1Control = nil,

	level = nil,
	levels = {  { map = "testSegment1",	music = "title5.xm"},
				{ map = "testlevel8",	music = "title5.xm"},
				{ map = "testlevel6", 	music = "main_title.xm"},
				{ map = "testlevel2", 	music = "title1.xm"},
				{ map = "testlevel3", 	music = "title2.xm"},
				{ map = "testlevel", 	music = "title3.xm"},
				{ map = "testlevel4", 	music = "title4.xm"},
				{ map = "testlevel5",	music = "title1.xm"} }, 
	currentLevel = 0,

	musicSource = nil,
	states = list()
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
    -- set controller
    mainPlayerControl = self.player1Control

    --self.states:push(levelState)
    self.states:push(titleScreenState)
    self.states.last:load(self)

end

function Game:update(dt) 
	-- we always have to update this (maybe it should be done somewhere else?)
	self.player1Control:update()
	
	if self.states.last ~= nil then
		self.states.last:update(self, dt)
	end
	
end

function Game:draw(dt)
	-- draw every states!
	for state in self.states:iterate() do
		state:draw(self)
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

local mainCanvas;

function love.load()
	-- change window mode
	success = love.window.setMode(1280, 768, {resizable=false, vsync=true, fullscreen=false})
	love.window.setTitle("Sword Game")

	Game:load()

	mainCanvas = love.graphics.newCanvas(320, 192)

	local pixelcode = [[
        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
            int x = int(mod(screen_coords.x, 4));
            int y = int(mod(screen_coords.y, 4));

            vec4 texcolor = Texel(texture, texture_coords);

            float a = 0.6;

            if(x == 0 || x == 3) {
            	color = vec4(1, a, a, 1);
            } else if(x == 1) {
            	color = vec4(a, 1.0, a, 1);
        	} else {
        		color = vec4(a, a, 1.0, 1);
        	}

        	// scanline
        	if(y == 0) {
        		color *= 0.9;
           	} else if(y == 1) {
	       		color *= 0.97;
        	} else if(y == 2) {
        		color *= 1.0;
        	} else if(y == 3) {
        		color *= 0.97;
        	}


            return texcolor * color;
        }
    ]]

    local vertexcode = [[
        vec4 position( mat4 transform_projection, vec4 vertex_position )
        {
            return transform_projection * vertex_position;
        }
    ]]

    shader = love.graphics.newShader(pixelcode, vertexcode)
end

local time_acc = 0.0
local total_time = 0.0
local total_frame = 0

function love.update(dt)
	-- fixed time step
	local timeStep = 1.0 / 60.0

	time_acc = time_acc + dt

	while time_acc > timeStep do
		Game:update(timeStep)

		time_acc = time_acc - timeStep
		total_time = total_time + timeStep
		total_frame = total_frame + 1
	end

end

crt_emulation = false

function love.draw()
	-- use scalling, make pixel bigger
	if not crt_emulation then
   		love.graphics.scale(4.0, 4.0)
		Game:draw()
	else
		love.graphics.setShader()
   		love.graphics.setCanvas(mainCanvas)
   		Game:draw()

   		love.graphics.setShader(shader)
   		love.graphics.setCanvas()
   		love.graphics.draw(mainCanvas, 0, 0, 0, 4, 4)
   	end
end