Level = {}
Level.__index = Level

-- create a new level from a map
function Level.new(mapName, screen_width, screen_height)
	local self = setmetatable({score = 0}, Level)

	self.playerEntity = nil
	self.entities = list()

	print("loading map : "..mapName)
	self.map = Map.new("Levels/" .. mapName..".lua", self)
	ww, wh = love.window.getDimensions()
	--self.map:setSize(ww / 4, wh / 4)

	self.screenWidth = screen_width
	self.screenHeight = screen_height

	return self
end

-- crappy function use as an entity factory
function Level:spawnEntity(entityType, x, y) 
	if entityType == "Player" then
		self.playerEntity = PlayerEntity.new(self, x, y)
		self.playerEntity.playerControl = PlayerControl.player1Control
		self.entities:push(self.playerEntity)
	end

	if entityType == "Snake" then
		local snakeEntity = SnakeEntity.new(self, x, y)
		self.entities:push(snakeEntity)
	end
end

-- update the level
function Level:update(dt)
	-- update entities
	-- they can be removed on their action function, 
	-- so keep track of the next one in the list
	local enemy = self.entities.first
	while enemy ~= nil do
		local nextEnemy = enemy._next

		enemy:action(dt)
		
		enemy = nextEnemy
	end
end

-- draw the level
function Level:draw(camera)
	-- use white color
	love.graphics.setColor(255, 255, 255, 255)	
   	
   	love.graphics.push()   	
   	-- translate according to current world scrolling
  	love.graphics.translate(-camera.x, -camera.y)

	-- draw the map
   	self.map:draw(camera.x, camera.y, camera.width, camera.height)

   	-- draw the entities
	for entity in self.entities:iterate() do
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

levelSelectionState = {index = 1}
function levelSelectionState:load(game)
end

function levelSelectionState:update(game, dt)
end

function levelSelectionState:actiontriggered(game, action)
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


function levelSelectionState:draw(game)
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

inGameMenuState = {
	index = 1,

	entries = {"Quit"}
}
function inGameMenuState:load(game)
	self.index = 1
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

	if action == "down" and self.index < #self.entries then
		self.index = self.index + 1
		sound.menu_select:play()
	end

	if action =="attack" or action == "start" then
		if self.index == 1 then
			love.event.quit()
		end
		
		sound.menu_valid:play()
	end
end


function inGameMenuState:draw(game)
	love.graphics.setColor(255, 255, 255, 255)	
	love.graphics.print("Menu", 100, 80)

	-- draw level name	
	i = 0
	for key, entry in pairs(self.entries) do
		if key == self.index then
			love.graphics.setColor(255, 0, 0, 255)	
		else
			love.graphics.setColor(255, 255, 255, 255)	
		end

		love.graphics.print(entry, 100, 100 + i)
		i = i + 12
	end
end

levelState = { 
	levelIndex = 1, 
	level = nil
}

function levelState:update(game, dt)
	if self.level ~= nil then
		self.level:update(dt)

		-- update camera
		local mapAABB = self.level.map:getAABB()
		local entityAABB = self.level.playerEntity:getAABB()

		-- first "center" on entity AABB
		self.camera.x = math.max(math.min(self.camera.x, entityAABB.min[0] - 128), entityAABB.max[0] + 128 - self.camera.width)
		self.camera.y = math.max(math.min(self.camera.y, entityAABB.min[1] - 64), entityAABB.max[1] + 64 - self.camera.height)

		-- clamp on level AABB
		self.camera.x = math.max(math.min(self.camera.x, mapAABB.max[0] - self.camera.width), mapAABB.min[0])
		self.camera.y = math.max(math.min(self.camera.y, mapAABB.max[1] - self.camera.height), mapAABB.min[1])

		-- use pixel perfect scrolling
		self.camera.x = math.floor(self.camera.x)
		self.camera.y = math.floor(self.camera.y)
	end
end

function levelState:actiontriggered(game, action)
	if action == "start" then
		game:pushState(levelSelectionState)
	end

	if action == "back" then
		game:pushState(inGameMenuState)
	end

end

function levelState:draw(game)
	-- draw the world
	if self.level ~= nil then
		-- Draw the Level
		self.level:draw(self.camera)
	
		-- draw the UI
	   	--printOutline("Current Level : "..self.levels[self.levelIndex].map, 5, 5)
	   	--printOutline("Current FPS: "..tostring(love.timer.getFPS( )), 5, 17)
	   	printOutline("Score: ".. self.level.score, 5, 5)

	end
end

function levelState:load(game)
	-- load test level
	self.game = game
	self.level = Level.new(game.levels[self.levelIndex].map, game.screenWidth, game.screenHeight)

	-- start the music	
	game:playMusic("Music/" .. game.levels[self.levelIndex].music)

	-- set camera
	self.camera = {x = 0, y = 0, width = game.screenWidth, height = game.screenHeight}
end