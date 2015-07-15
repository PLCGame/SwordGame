Level = {}
Level.__index = Level

-- create a new level from a map
function Level.new(mapName)
	local self = setmetatable({score = 0}, Level)

	self.playerEntity = nil
	self.enemies = list()

	print("loading map : "..mapName)
	mapFile = love.filesystem.load(mapName..".lua")
	self.map = Map.new(mapFile(), self)
	ww, wh = love.window.getDimensions()
	self.map:setSize(ww / 4, wh / 4)

	return self
end

-- crappy function use as an entity factory
function Level:spawnEntity(entityType, x, y) 
	if entityType == "Player" then
		self.playerEntity = PlayerEntity.new(self, x, y)
		self.playerEntity.playerControl = PlayerControl.player1Control
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

levelLoadState = {timer = 0}
function levelLoadState:load(game)
	game:playMusic(nil)
	self.timer = 0
end

function levelLoadState:update(game, dt)
	self.timer = self.timer + dt

	if self.timer > 1 then
		game:popState()
		game:pushState(levelState)
	end
end

function levelLoadState:actiontriggered(game, action)
end


function levelLoadState:draw(game)
	local alpha = math.min((1.0 - self.timer) * 4.0, 1.0)
	love.graphics.setColor(255, 255, 255, 255 * alpha)	
	love.graphics.print("Loading level", 100, 80)
end

inGameMenuState = {index = 1}
function inGameMenuState:load(game)
end

function inGameMenuState:update(game, dt)
end

function inGameMenuState:actiontriggered(game, action)
	if action == "back" then
		game:popState()
	end

	if action == "up" and self.index > 1 then
		self.index = self.index - 1
		sound.menu_select:play()
	end

	if action == "down" and self.index < #game.levels then
		self.index = self.index + 1
		sound.menu_select:play()
	end

	if action =="attack" or action == "start" then
		-- change state
		game:popState() -- pop ingame menu
		game:popState() -- pop level state

		levelState.levelIndex = self.index

		game:pushState(levelLoadState)

		sound.menu_valid:play()
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

levelState = { levelIndex = 1}
function levelState:update(game, dt)
	if game.level ~= nil then
		game.level:update(dt)
	end
end

function levelState:actiontriggered(game, action)
	if action == "back" then
		game:pushState(inGameMenuState)
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

	-- start the music	
	game:playMusic("Music/" .. game.levels[self.levelIndex].music)
end