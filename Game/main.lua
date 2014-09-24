local playerSprites
local enemySprites

local levelMap
local font

SpriteFrame = require "SpriteFrame"
Map = require "Map"

PlayerControl = {}
PlayerControl.__index = PlayerControl

function PlayerControl.new() 
	local self = setmetatable({}, PlayerControl)

	self.event = { 	left 	= 	{"left", 	"dpleft", 	"leftx", 	true},
					right 	=	{"right", 	"dpright", 	"leftx", 	false},
					up	 	= 	{"up", 		"dpup", 	"lefty", 	true},
					down	= 	{"down", 	"dpdown", 	"lefty", 	false},
					jump	= 	{"z", 		"a", 		nil, 		nil},
					attack 	= 	{"q", 		"x", 		nil,		nil},
					defend 	= 	{"d", 		"b", 		nil, 		nil}}

	return self
end

function PlayerControl:testInput(event)
	local res = false

	eventArray = self.event[event]

	if eventArray[1] ~= nil then
		res = res or love.keyboard.isDown(eventArray[1])
	end

	if self.joystick ~= nil then
		if eventArray[2] ~= nil then
			res = res or self.joystick:isGamepadDown(eventArray[2])
		end

		if eventArray[3] ~= nil then
			if eventArray[4] then
				res = res or (self.joystick:getGamepadAxis(eventArray[3]) < -0.5)
			else
				res = res or (self.joystick:getGamepadAxis(eventArray[3]) > 0.5)
			end
		end
	end

	return res	
end

function PlayerControl:canGoLeft()
	return self:testInput("left")
end

function PlayerControl:canGoRight()
	return self:testInput("right")
end

function PlayerControl:canGoUp()
	return self:testInput("up")
end

function PlayerControl:canGoDown()
	return self:testInput("down")
end

function PlayerControl:canJump()
	return self:testInput("jump")
end

function PlayerControl:canAttack()
	return self:testInput("attack")
end

function PlayerControl:canDefend()
	return self:testInput("defend")
end

local Entity = {}
Entity.__index = Entity

-- create a new entity instance, with default values
function Entity.new(width, height)
	local self = setmetatable({}, Entity)

	-- start position
	self.x = 16
	self.y = 128

	-- idling
	self.speedX = 0
	self.speedY = 0

	-- use for motion
	self.maxSpeed = 64
	self.acceleration = 512

	-- reset animation timer 
	self.animationFrame = 0
	self.animationTimer = 0

	-- look right
	self.direction = 1

	-- no sprite
	self.sprite = nil

	-- bounding box
	self.width = width
	self.height = height

	-- no action
	self.action = nil

	-- hit
	self.hit = false
	self.hitDirection = 0

	self.health = 100

	return self
end

-- draw the entity
function Entity:draw()
	--love.graphics.polygon("fill", self.x - self.width * 0.5, self.y - self.height, self.x + self.width * 0.5, self.y - self.height, self.x + self.width * 0.5, self.y, self.x - self.width * 0.5, self.y)

	if self.sprite ~= nil then
		love.graphics.draw(self.sprite.image, self.sprite.quad, self.x, self.y, 0, 1.0, 1.0, -self.sprite.xoffset, -self.sprite.yoffset + 1) -- +1 because the character positin is at the bottom (and the mark on the sprite is on the last row)
	end
end

-- update animation timer and frame (based on animation frame count and frame rate)
function Entity:updateAnimation(frameCount, frameRate)
  	local dt = love.timer.getDelta()

	self.animationTimer = self.animationTimer + dt

	if self.animationTimer > frameRate then
		self.animationFrame = (self.animationFrame + 1) % frameCount
		self.animationTimer = self.animationTimer - frameRate
	end
end

-- change the action of the entity
-- this reset the animation timer & frame
function Entity:changeAction(newAction)
	self.animationTimer = 0
	self.animationFrame = 0

	self.action = newAction
end

function Entity:getAABB()
	local aabb = { min = {}, max = {} }
	aabb.min[0] = self.x - self.width * 0.5
	aabb.max[0] = self.x + self.width * 0.5
	aabb.min[1] = self.y - self.height
	aabb.max[1] = self.y

	return aabb
end

function Entity:OnGround()
	-- just do a cast 1px below
	local aabb = self:getAABB()
	return levelMap:AABBCast(aabb, {[0] = 0, [1] = 1}) == 0
end

-- move the entity according to its speed, and handle collsion with world
function Entity:MoveAndCollide(dt)
	local aabb = self:getAABB()

	-- gravity
	-- if the entity is not on a solid tile, it's falling
	if not self:OnGround() then
		-- increment speed Y
  		self.speedY = math.min(self.speedY + 768.0 * dt, 256.0)
  	end

	--print("")
	--print("----------------------------------")
	--print("old position", self.x, self.y, self.speedX, self.speedY, xdisp, ydisp)

	local timeLeft = dt
	while timeLeft > 0.0 do
		aabb = self:getAABB()

		-- compute displacement
		local xdisp = self.speedX * timeLeft
		local ydisp = self.speedY * timeLeft

		local v = {}
		v[0] = xdisp
		v[1] = ydisp

		u, n = levelMap:AABBCast(aabb, v)

		if u < 1.0 then
			xdisp = xdisp * u
			ydisp = ydisp * u

			if n == 0 then
				self.speedX = 0
			elseif n == 1 then
				self.speedY = 0
			end
		end

		-- update position
		self.x = self.x + xdisp
		self.y = self.y + ydisp

		-- update time counter
		timeLeft = timeLeft - (u * timeLeft)
	end

	--print("new position", self.x, self.y, self.speedX, self.speedY, xdisp, ydisp)
end

function Entity:Hit(power, direction)
	self.health = self.health - power
	self.hit = true
	self.hitDirection = direction
end

-- falling state
function fall(self, dt)
	-- we can attach will in air
  	if self.playerControl:canAttack() then
  		-- change state
  		self:changeAction(attack)
  	end

  	-- we can move left and right
	if self.playerControl:canGoLeft() then
		self.speedX = math.max(self.speedX - 4.0, -64.0)
		self.direction = 1
	end

	if self.playerControl:canGoRight() then
		self.speedX = math.min(self.speedX + 4.0, 64.0)
		self.direction = 0
	end

	-- we reach the ground, back to idle state
  	if self:OnGround() then
  		-- change state
  		self.action = idle
  	end

  	-- if the user can grab a ladder, do that
	if self.playerControl:canGoUp() and levelMap:distanceToLadder(self) ~= nil then
		self:changeAction(ladder)
	end

  	-- update position and velocity
  	self:MoveAndCollide(dt)

  	-- use an idling sprite
  	self.sprite = playerSprites.frames[playerSprites.runAnimation[self.animationFrame + 1] + self.direction * 10]
end

function begin_jump(self)
	-- init basic 
	self.speedY = -170.0
	self:changeAction(jump)
end

function jump(self, dt)
	-- update position and velocity, and apply gravity
  	self:MoveAndCollide(dt)

  	if self.playerControl:canJump() then
  		self.speedY = self.speedY - 430.0 * dt
  	end

  	-- we can move left and right
	if self.playerControl:canGoLeft() then
		self.speedX = math.max(self.speedX - 16.0, -self.maxSpeed)
		self.direction = 1
	end

	if self.playerControl:canGoRight() then
		self.speedX = math.min(self.speedX + 16.0, self.maxSpeed)
		self.direction = 0
	end

  	if self.speedY >= 0 then
  		self:changeAction(fall)
  	end
end

function run(self, dt)
	-- test input
  	if self.playerControl:canGoLeft() then
  		-- accelerate to the left
  		self.speedX = math.max(self.speedX - self.acceleration * dt, -self.maxSpeed)

  		-- character look to the left
		self.direction = 1
  	elseif self.playerControl:canGoRight() then
  		-- accelerate to the right
  		self.speedX = math.min(self.speedX + self.acceleration * dt, self.maxSpeed)

  		-- character look to the right
		self.direction = 0
	else
		-- no input? go back in idling state
		self.action = idle
  	end

  	-- update position and velocity
  	self:MoveAndCollide(dt)

  	-- are we still on the ground?
  	if not self:OnGround() then
  		-- no, then go into fall state
  		self.action = fall
	end
	-- jump
	if self.playerControl:canJump() then
		-- so we can jump
	  	begin_jump(self)
	end

	-- update sprite
	self:updateAnimation(4, 1.0 / 16.0)
	self.sprite = playerSprites.frames[playerSprites.runAnimation[self.animationFrame + 1] + self.direction * 10]

	-- we can attack while moving
  	if self.playerControl:canAttack() then
  		-- change state
  		self.speedX = 0
  		self:changeAction(attack)
  	end

  	-- and defend
	if self.playerControl:canDefend() then
  		-- change state
	  	self:changeAction(defend)
	end
end

-- idling state, the character does nothing
function idle(self, dt)
	-- we need to slow donw in order to stop moving
	if self.speedX > 0.0 then
		self.speedX = math.max(self.speedX - self.acceleration * dt, 0.0)
	end

	if self.speedX < 0.0 then
		self.speedX = math.min(self.speedX + self.acceleration * dt, 0.0)
	end

	-- if the players wants to move, change to run state
  	if self.playerControl:canGoLeft() or self.playerControl:canGoRight() then
		self.action = run
  	end

  	-- attack
  	if self.playerControl:canAttack() then
  		-- change state
  		self:changeAction(attack)
  	end

  	-- defend
	if self.playerControl:canDefend() then
  		-- change state
	  	self:changeAction(defend)
	end

	-- if we can fall, switch to fall state
  	if not self:OnGround() then
  		self.action = fall
  	else 
  		-- we're on ground
	  	if self.playerControl:canJump() then
	  		-- so we can jump
	  		begin_jump(self)
	  	end
  	end

  	-- if the user can grab a ladder, do that
	if (self.playerControl:canGoDown() or self.playerControl:canGoUp()) then
		x, t, b = levelMap:distanceToLadder(self)
		if x ~= nil and ((self.playerControl:canGoDown() and b > 0) or (self.playerControl:canGoUp() and t > 0))  then
			self:changeAction(ladder)
		end
	end

	-- update position and velocity
  	self:MoveAndCollide(dt)

  	-- show idling sprite
	self.sprite = playerSprites.frames[playerSprites.runAnimation[self.animationFrame + 1] + self.direction * 10]
end

-- attack state
function attack(self, dt)
	-- we need to slow down in order to stop moving if we are on the ground
	aabb = self:getAABB()
  	if levelMap:AABBCast(aabb, {[0] = 0, [1] = 1}) == 0.0 then
		if self.speedX > 0.0 then
			self.speedX = math.max(self.speedX - self.acceleration * dt, 0.0)
		end

		if self.speedX < 0.0 then
			self.speedX = math.min(self.speedX + self.acceleration * dt, 0.0)
		end
	end

  	-- update animation
  	self:updateAnimation(6, 1.0 / 30.0)
	self.sprite = playerSprites.frames[playerSprites.attackAnimation[self.animationFrame + 1] + self.direction * 10]

	-- we can still be moving
  	self:MoveAndCollide(dt)

  	if self.animationFrame >= 3 then
		for enemy in levelMap.entities:iterate() do
  			if enemy ~= self then
  				-- do we hit something?
  				local enemyAABB = enemy:getAABB()
  				local swordAABB = { min = {}, max = {}}

  				if self.direction == 0 then
  					swordAABB.min[0] = self.x + 8
  					swordAABB.max[0] = self.x + 18

  					swordAABB.min[1] = self.y - 6
  					swordAABB.max[1] = self.y - 3
  				else
  					swordAABB.min[0] = self.x - 18
  					swordAABB.max[0] = self.x - 8

  					swordAABB.min[1] = self.y - 6
  					swordAABB.max[1] = self.y - 3  			
  				end

  				-- does it overlap?
  				if not enemy.hit and AABBOverlap(swordAABB, enemyAABB) then
  					-- kill the enemy!
  					enemy:Hit(40, self.direction)
  				end
  			end
  		end
  	end

  	-- end of the animation, go back to idling state
	if self.animationFrame == 5 then
		self:changeAction(idle)
	end
end

-- defend, just stop and use shield
function defend(self, dt)
	-- slow down
	if self.speedX > 0.0 then
		self.speedX = math.max(self.speedX - self.acceleration * dt, 0.0)
	end

	if self.speedX < 0.0 then
		self.speedX = math.min(self.speedX + self.acceleration * dt, 0.0)
	end

	-- no longer in defense
	if not self.playerControl:canDefend() then
		self:changeAction(idle)
	end

	-- use shield sprite
	self.sprite = playerSprites.frames[13 + self.direction * 10]

	-- update position and velocity
	self:MoveAndCollide(dt)
end

-- ladder state
function ladder(self, dt)
	-- move the sprite to the ladder
	delta, distanceToTop, distanceToBottom = levelMap:distanceToLadder(self) -- return the distance from center to center

	-- delta == nil means the character is no longer on a ladder tile
	if delta == nil then
		-- so switch back to idling state
		self:changeAction(idle)
	else
		-- reset speed
		self.speedX = 0
		self.speedY = 0

		-- move the character on the ladder
		self.x = self.x + math.max(math.min(delta, 68.0 * dt), -64.0 * dt)

		local disp = 0.0


		if self.playerControl:canGoUp() then
			disp = -48 * dt
		elseif self.playerControl:canGoDown() then
			disp = 48 * dt
		end

		-- if the player is moving on the ladder
		if disp ~= 0 then
			local aabb = self:getAABB()
			u, n = levelMap:AABBCast(aabb, {[0] = 0, [1] = disp}, "ladder")

			if u < 1.0 then
				-- we can't go lower, go back to idle state
				if disp > 0 then
					self:changeAction(idle)
				end

				disp = disp * u

			end

			if disp < -distanceToTop or disp > distanceToBottom then
				-- clamp
				disp = math.min(math.max(disp, -distanceToTop), distanceToBottom)

				self:changeAction(idle)
			end

			self.y = self.y + disp

			-- update animation
			self:updateAnimation(2, 1.0 / 8.0)
			self.sprite = playerSprites.frames[31 + self.animationFrame]
		else
			-- state idling on the ladder, use idling sprite
			self.sprite = playerSprites.frames[30]
		end

		-- jump
	  	if self.playerControl:canJump() then
			self.speedY = -10.0
			self.action = fall

			self:changeAction(fall)
	  	end

	end
end

function snakeDead(self, dt)
	-- move it away
	self.x = -400000000
	self.y = -400000000
end

function snakeRecover(self, dt)
	-- death animation
	if self.health <= 0 then
		self:updateAnimation(3, 1.0 / 8.0)

		if self.animationFrame == 2 then
			self:changeAction(snakeDead)
			return
		end

		self.sprite = enemySprites.frames[7 + 3 + self.animationFrame + self.direction * 5]
	else
		if self.speedX > 0 then
			self.speedX = math.max(0, self.speedX - 1024 * dt)
		else
			self.speedX = math.min(0, self.speedX + 1024 * dt)
		end

		if self.speedX == 0 then
			self:changeAction(snakeGo)
			self.hit = false
		end

		self:MoveAndCollide(dt)		
	end
end

function snakeHit(self, dt)

	-- move in the direction
	if self.hitDirection == 0 then
		self.speedX = 256.0
	else
		self.speedX = -256.0
	end
	self.speedY = -32.0

	self:changeAction(snakeRecover)

	self.sprite = enemySprites.frames[7 + 2 + self.direction * 5]

	self:MoveAndCollide(dt)
end

function snakeGo(self, dt)
	local aabb = self:getAABB()

	if self.direction == 1 then
		self.speedX = 32.0
	else
		self.speedX = -32.0
	end

	-- fall straight
	if levelMap:AABBCast(aabb, {[0] = 0, [1] = 1}) > 0 then
		self.speedX = 0
	else
		-- test if we can move left or right
		if self.speedX < 0 then
			-- if we can move left
			if levelMap:AABBCast(aabb, {[0] = -1, [1] = 0}) < 1 then
				-- change direction
				self.speedX = 32.0
				self.direction = 1
			else
				-- test the edge of the platform, go as far as half width
				c = levelMap:AABBCast(aabb, {[0] = -self.width, [1] = 0})

				local dist = c * self.width
				aabb.min[0] = aabb.min[0] - dist
				aabb.max[0] = aabb.max[0] - dist

				-- we will reach the end of the platform
				if levelMap:AABBCast(aabb, {[0] = 0, [1] = 1}) == 1 then
					self.speedX = 32.0
					self.direction = 1
				end
			end
		elseif self.speedX > 0 then
			if levelMap:AABBCast(aabb, {[0] = 1, [1] = 0}) < 1 then
				self.speedX = -32.0
				self.direction = 0
			else
				-- test the edge of the platform, go as far as half width
				c = levelMap:AABBCast(aabb, {[0] = self.width, [1] = 0})

				local dist = c * self.width
				aabb.min[0] = aabb.min[0] + dist
				aabb.max[0] = aabb.max[0] + dist

				if levelMap:AABBCast(aabb, {[0] = 0, [1] = 1}) == 1 then
					self.speedX = -32.0
					self.direction = 0
				end
			end
		end
	end

	if self.hit then
		self:changeAction(snakeHit)
	end

  	self:MoveAndCollide(dt)

	self:updateAnimation(2, 1.0 / 8.0)
	self.sprite = enemySprites.frames[7 + self.animationFrame + self.direction * 5]
end

function createPlayerEntity()
	local playerEntity = Entity.new(8, 15)
	playerEntity.action = idle

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
	local snakeEntity = Entity.new(14, 16)
	snakeEntity.action = snakeGo

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
	levelMap = Map.new(require "testlevel3", {["Player"] = createPlayerEntity, ["Snake"] = createSnakeEntity})
	levelMap:setSize(320, 192)

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
		for entity in levelMap.entities:iterate() do
			-- update entity
			entity:action(timeStep)
		end


		-- update scrolling to show the player
		if levelMap.entities.first then
			levelMap:scrollTo(levelMap.entities.first)
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
   	levelMap:draw()
   	
   	-- draw the entities
   	-- translate according to current world scrolling
  	love.graphics.translate(-levelMap.dx, -levelMap.dy)

	for entity in levelMap.entities:iterate() do
		-- update entity
		entity:draw()
	end

	-- restore transform
  	love.graphics.translate(levelMap.dx, levelMap.dy)

   	love.graphics.setColor(255, 255, 255, 255)
    love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 0, 10)

	-- restore state
	--love.graphics.setScissor()
end