Level = {}
Level.__index = Level

-- create a new level from a map
function Level.new(mapName)
	local self = setmetatable({score = 0}, Level)

	self.entities = list()
	self.collisionPairs = {}

	print("loading map : "..mapName)
	self.map = Map.new("Levels/" .. mapName..".lua", self)

	return self
end

-- crappy function use as an entity factory
function Level:spawnEntity(entityType, x, y, entityProperties)
	-- get entity constructor function 
	local entityConstructor = EntityFactory[entityType]
	if entityConstructor ~= nil then
		-- create the entity
		local newEntity = entityConstructor(self, x, y)

		-- add it to entity list
		self.entities:push(newEntity)

		if entityType == "Player" then
			local playerID = 1

			if entityProperties and entityProperties.playerID then
				playerID = tonumber(entityProperties.playerID)
			end

			if playerID == 1 then
				self.playerEntity = newEntity
				self.playerEntity.playerControl = PlayerControl.player1Control
			end

			if playerID == 2 then
				newEntity.playerControl = PlayerControl.player2Control
			end

		end

		return newEntity
	end
end

function Level:addEntity(newEntity)
	-- add it to entity list
	self.entities:push(newEntity)

	-- do post insertion init
	if newEntity.inserted then
		newEntity:inserted(self)
	end
end

function Level:removeEntity(entity)
	self.entities:remove(entity)
end

-- return the list of entity intersecting the AABB
function Level:intersectingEntities(aabb, firstEntity)
	entity = self.entities.first
	if firstEntity ~= nil then
		entity = firstEntity
	end

	res = {}

	while entity ~= nil do
		local entityAABB = entity:getAABB()

		if AABBOverlap(entityAABB, aabb) then
			table.insert(res, entity)
		end

		entity = entity._next
	end

	return res
end

function Level:handleCollision()
	-- test overlapp
	-- not very good...
	local newCollisionPairs = {}
	local entity = self.entities.first
	while entity ~= nil and entity._next ~= nil do -- check also next, as this is the first element we will check
		local entityAABB = entity:getAABB()
		local overlappingEntities = self:intersectingEntities(entityAABB, entity._next)

		for _, otherEntity in ipairs(overlappingEntities) do
			-- handle collision pair
			local key = string.format("%p - %p", entity, otherEntity)
			newCollisionPairs[key] = {obj1 = entity, obj2 = otherEntity}
		end

		entity = entity._next
	end

	-- loop on new pair list
	for key, pair in pairs(newCollisionPairs) do
		-- is it a new pair?
		local key2 = string.format("%p - %p", pair.obj2, pair.obj1)

		if not self.collisionPairs[key] and not self.collisionPairs[key2] then
			-- callback
			if pair.obj1.entityDidEnter then
				pair.obj1:entityDidEnter(pair.obj2)
			end

			if pair.obj2.entityDidEnter then
				pair.obj2:entityDidEnter(pair.obj1)
			end
		end
	end

	-- loop on old list
	for key, pair in pairs(self.collisionPairs) do
		-- did the object are still in collision?
		local key2 = string.format("%p - %p", pair.obj2, pair.obj1)

		if not newCollisionPairs[key] and not newCollisionPairs[key2] then
			-- callback
			if pair.obj1.entityDidLeave then
				pair.obj1:entityDidLeave(pair.obj2)
			end

			if pair.obj2.entityDidLeave then
				pair.obj2:entityDidLeave(pair.obj1)
			end
		end
	end

	self.collisionPairs = newCollisionPairs
end

-- update the level
function Level:update(dt)
	self:handleCollision()

	-- update entities
	-- they can be removed on their action function, 
	-- so keep track of the next one in the list
	entity = self.entities.first
	while entity ~= nil do
		local nextEntity = entity._next

		entity:action(dt)
		
		entity = nextEntity
	end
end

-- draw the level
function Level:draw(camera)
	-- use white color
	love.graphics.setColor(255, 255, 255, 255)	
   	
   	love.graphics.push()   	
   	-- translate according to current world scrolling
  	love.graphics.translate(-camera.x, -camera.y)

	-- draw the map background
   	self.map:draw(camera.x, camera.y, camera.width, camera.height, false)

   	-- draw the entities
	for entity in self.entities:iterate() do
		-- update entity
		entity:draw()
	end

	if self.playerEntity ~= nil then
		self.playerEntity:draw()
	end

	-- draw the map foreground
   	self.map:draw(camera.x, camera.y, camera.width, camera.height, true)

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
		local entityAABB = self.player1:getAABB()

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
	   	printOutline("Health: ".. self.player1.health, 5, 15)
	   	printOutline("ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_'abcdefghijklmnopqrstuvwxyz{|}", 0, 25)

	end
end

function levelState:load(game)
	-- load test level
	self.game = game
	self.level = Level.new(game.levels[self.levelIndex].map)

	-- spawn the player
	playerSpawn = self.level.map.objects["SpawnPlayer1"]
	self.player1 = PlayerEntity.new(self.level, playerSpawn.x + playerSpawn.width * 0.5, playerSpawn.x + playerSpawn.height)
	self.player1.playerControl = PlayerControl.player1Control
	self.level:addEntity(self.player1)

	-- grab the end trigger
	local obj = self.level.map.objects["LevelEnd"]
	local levelEndTrigger = Trigger.new(self.level, obj.x, obj.y, obj.width, obj.height, self, levelState.endTriggerCallback)
	self.level:addEntity(levelEndTrigger)

	-- start the music	
	--game:playMusic("Music/title2.xm")

	-- set camera
	self.camera = {x = 0, y = 0, width = game.screenWidth, height = game.screenHeight}
end

function levelState:endTriggerCallback(sender, entity, entered)
	if entity == self.player1 then
		if entered then
			self.game:playMusic("Music/title1.xm")
		else
			self.game:playMusic(nil)
		end
	end
end