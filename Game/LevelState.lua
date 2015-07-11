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

inGameMenuState = {}
inGameMenuState.__index = inGameMenuState

function inGameMenuState.new()
	local self = setmetatable({}, inGameMenuState)

	self.index = 1

	return self
end

function inGameMenuState:update(game, dt)
	if PlayerControl.player1Control:testTrigger("down") then
		self.index = math.min(self.index + 1, #game.levels)
	end

	if PlayerControl.player1Control:testTrigger("up") then
		self.index = math.max(self.index - 1, 1)		
	end

	if PlayerControl.player1Control:testTrigger("back") then
		-- go back
		game.states:pop()
	end


	if PlayerControl.player1Control:testTrigger("attack") or PlayerControl.player1Control:testTrigger("start") then
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

	if PlayerControl.player1Control:testTrigger("back") then
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
	game.musicSource:play()
end