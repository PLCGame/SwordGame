versusLevelState = { 
	level = nil
}

local pixelcode = [[
	extern vec2 splitPlane;

    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
    {
        vec4 texColor = Texel(texture, texture_coords);
        vec2 relCoord = (love_ScreenSize.xy * 0.5) - screen_coords;
        relCoord.y *= -1;

    	texColor.a = dot(relCoord, splitPlane);

        return texColor;
    }
]]

local vertexcode = [[
    vec4 position( mat4 transform_projection, vec4 vertex_position )
    {
        return transform_projection * vertex_position;
    }
]]

versusLevelState.cameraShader = love.graphics.newShader(pixelcode, vertexcode)

-- clamp the camera to AABB
function clampCamera(camera, aabb)
	camera.x = math.max(math.min(camera.x, aabb.max[0] - camera.width), aabb.min[0])
	camera.y = math.max(math.min(camera.y, aabb.max[1] - camera.height), aabb.min[1])

	camera.x = math.floor(camera.x)
	camera.y = math.floor(camera.y)
end

-- move (scroll) the camera to make the aabb visible
function moveCameraToVisible(camera, aabb)
	camera.x = math.max(math.min(camera.x, aabb.min[0] - 64), aabb.max[0] + 64 - camera.width)
	camera.y = math.max(math.min(camera.y, aabb.min[1] - 32), aabb.max[1] + 32 - camera.height)
end

function versusLevelState:update(game, dt)
	if self.level ~= nil then
		self.level:update(dt)

		-- update cameras
		local mapAABB = self.level.map:getAABB()
		local player1AABB = self.player1:getAABB()
		local player2AABB = self.player2:getAABB()

		-- first move the camera to make player 2 visible
		moveCameraToVisible(self.player1Camera, player2AABB)

		-- and now move it to make player 1 visible
		-- this player 1 is visible at the closest position to make player 2 visible
		moveCameraToVisible(self.player1Camera, player1AABB)

		-- clamp on level AABB
		clampCamera(self.player1Camera, mapAABB)

		-- same for player2 camera
		moveCameraToVisible(self.player2Camera, player1AABB)
		moveCameraToVisible(self.player2Camera, player2AABB)
		clampCamera(self.player2Camera, mapAABB)

	end
end

function versusLevelState:actiontriggered(game, action)
	if action == "start" then
		-- switch camera
		if self.camera == self.player1Camera then
			self.camera = self.player2Camera
		else
			self.camera = self.player1Camera
		end
	end

	if action == "back" then
		game:pushState(inGameMenuState)
	end

end

function versusLevelState:draw(game)
	-- draw the world
	if self.level ~= nil then
		-- get the current canvas 
		local currentCanvas = love.graphics.getCanvas()

		-- Draw the Level for player 1
		love.graphics.setCanvas(self.player1Canvas)
		self.level:draw(self.player1Camera)

		-- Draw the Level for player 2
		love.graphics.setCanvas(self.player2Canvas)
		self.level:draw(self.player2Camera)

	   	-- re set game canvas
	   	love.graphics.setCanvas(currentCanvas)

	   	-- and draw the composition
	   	love.graphics.setColor(255, 255, 255, 255)
   		love.graphics.draw(self.player1Canvas)

   		local dx = self.player1Camera.x - self.player2Camera.x
   		local dy = self.player1Camera.y - self.player2Camera.y

   		if dx ~= 0 or dy ~= 0 then
   			local length = math.sqrt(dx * dx + dy * dy)
   			dx = dx / length
   			dy = dy / length

   			local center = {x = game.screenWidth * 0.5, y = game.screenHeight * 0.5}

   			local currentShader = love.graphics.getShader()

   			-- set super camera shader for splitting
   			love.graphics.setShader(versusLevelState.cameraShader)
   			versusLevelState.cameraShader:send("splitPlane", {dx, dy})
   			-- draw the second camera view
   			love.graphics.draw(self.player2Canvas)

   			-- restore shader
   			love.graphics.setShader(currentShader)

   			love.graphics.line(center.x, center.y, center.x + dy * 200, center.y - dx * 200)
   			love.graphics.line(center.x, center.y, center.x - dy * 200, center.y + dx * 200)

   		end

   		-- draw the UI
	   	printOutline("Health: ".. self.player1.health, 5, 15)
	   	printOutline("Health: ".. self.player2.health, 255, 15)

	end
end

function versusLevelState:load(game)
	-- load test level
	self.game = game
	self.level = Level.new("testlevel2")

	-- spawn the player
	local playerSpawn = self.level.map.objects["SpawnPlayer1"]
	self.player1 = PlayerEntity.new(self.level, playerSpawn.x, playerSpawn.y)
	self.player1.playerControl = PlayerControl.player1Control
	self.level:addEntity(self.player1)

	playerSpawn = self.level.map.objects["SpawnPlayer2"]
	self.player2 = PlayerEntity.new(self.level, playerSpawn.x, playerSpawn.y)
	self.player2.playerControl = PlayerControl.player2Control
	self.level:addEntity(self.player2)

	-- grab the end trigger
	local obj = self.level.map.objects["LevelEnd"]
	local levelEndTrigger = Trigger.new(self.level, obj.x, obj.y, obj.width, obj.height, self, versusLevelState.endTriggerCallback)
	self.level:addEntity(levelEndTrigger)

	-- start the music	
	--game:playMusic("Music/title2.xm")

	-- set camera
	self.player1Camera = {x = 0, y = 0, width = game.screenWidth, height = game.screenHeight}
	self.player1Canvas = love.graphics.newCanvas(game.screenWidth, game.screenHeight)

	self.player2Camera = {x = 0, y = 0, width = game.screenWidth, height = game.screenHeight}
	self.player2Canvas = love.graphics.newCanvas(game.screenWidth, game.screenHeight)

	self.camera = self.player1Camera
end

function versusLevelState:endTriggerCallback(sender, entity, entered)
	if entity == self.player1 then
		if entered then
			--self.game:playMusic("Music/title1.xm")
		else
			self.game:playMusic(nil)
		end
	end
end