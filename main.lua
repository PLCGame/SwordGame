-- garbage
local joystick
--

local playerSprites = require "PlayerSprites"

local playerSprite
local levelMap
local font

Map = require "Map"

local Entity = {}
Entity.__index = Entity

-- create a new entity instance, with default values
function Entity.new(spriteSheet)
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
	self.width = 8
	self.height = 15

	-- no action
	self.action = nil

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

-- move the entity according to its speed, and handle collsion with world
function Entity:MoveAndCollide(dt)
	-- gravity
	-- if the entity is not on a solid tile, it's falling
  	fallDistance = levelMap:distanceDown(self)
	if fallDistance > 0 then
		-- increment speed Y
  		self.speedY = math.min(self.speedY + 8.0, 256.0)
	end

	-- compute displacement
	xdisp = self.speedX * dt
	ydisp = self.speedY * dt

	-- if the entity is going down, collide with ground
	if ydisp > 0 then
		dist = fallDistance 

		-- clamp displacememt
		if ydisp > dist then
			ydisp = dist
			self.speedY = 0
		end
	end

	-- collide with roof
	if ydisp < 0 then 
		dist = levelMap:distanceUp(self)

		-- clamp displacement
		if -ydisp > dist then
			ydisp = -dist
			self.speedY = 0
		end
	end

	if xdisp < 0 then
		dist = levelMap:distanceLeft(self) 

		-- clamp displacement
		if -xdisp > dist then
			xdisp = -dist
			self.speedX = 0
		end
	end

	if xdisp > 0 then
		dist = levelMap:distanceRight(self) 

		-- clamp displacement
		if xdisp > dist then
			xdisp = dist
			self.speedX = 0
		end
	end

	self.x = self.x + xdisp
	self.y = self.y + ydisp
end

-- falling state
function fall(self, dt)
	-- we can attach will in air
  	if love.keyboard.isDown("q") or joystick:isGamepadDown("x")  then
  		-- change state
  		self:changeAction(attack)
  	end

  	-- we can move left and right
	if love.keyboard.isDown("left") then
		self.speedX = math.max(self.speedX - 16.0, -64.0)
		self.direction = 1
	end

	if love.keyboard.isDown("right") then
		self.speedX = math.min(self.speedX + 16.0, 64.0)
		self.direction = 0
	end

	-- we reach the ground, back to idle state
  	if levelMap:distanceDown(self) == 0 then
  		-- change state
  		self.action = idle
  	end

  	-- update position and velocity
  	self:MoveAndCollide(dt)

  	-- use an idling sprite
  	self.sprite = playerSprites.frames[playerSprites.runAnimation[self.animationFrame + 1] + self.direction * 10]
end

function run(self, dt)
	-- test input
  	if love.keyboard.isDown("left") or joystick:isGamepadDown("dpleft") or joystick:getGamepadAxis("leftx") < -0.5 then
  		-- accelerate to the left
  		self.speedX = math.max(self.speedX - self.acceleration * dt, -self.maxSpeed)

  		-- character look to the left
		self.direction = 1
  	elseif love.keyboard.isDown("right") or joystick:isGamepadDown("dpright") or joystick:getGamepadAxis("leftx") > 0.5 then
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
  	fallDistance = levelMap:distanceDown(self)
  	if fallDistance > 0 then
  		-- no, then go into fall state
  		self.action = fall
  	else
 		-- we're on ground
	  	if love.keyboard.isDown("z") or joystick:isGamepadDown("a") then

  			-- so we can jump
			self.speedY = -200.0
			self.action = fall
	  	end

  	end

	-- update sprite
	self:updateAnimation(4, 1.0 / 16.0)
	self.sprite = playerSprites.frames[playerSprites.runAnimation[self.animationFrame + 1] + self.direction * 10]

	-- we can attack while moving
  	if love.keyboard.isDown("q") or joystick:isGamepadDown("x")  then
  		-- change state
  		self.speedX = 0
  		self:changeAction(attack)
  	end

  	-- and defend
	if love.keyboard.isDown("s") or joystick:isGamepadDown("b") then
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
  	if love.keyboard.isDown("left") or love.keyboard.isDown("right") then
		self.action = run
  	end

  	-- attack
  	if love.keyboard.isDown("q") or joystick:isGamepadDown("x")  then
  		-- change state
  		self:changeAction(attack)
  	end

  	-- defend
	if love.keyboard.isDown("s") or joystick:isGamepadDown("b") then
  		-- change state
	  	self:changeAction(defend)
	end

	-- if we can fall, switch to fall state
  	fallDistance = levelMap:distanceDown(self)
  	if fallDistance > 0 then
  		self.action = fall
  	else 
  		-- we're on ground
	  	if love.keyboard.isDown("z") or joystick:isGamepadDown("a") then
  			-- so we can jump
			self.speedY = -200.0
			self.action = fall
	  	end
  	end

  	-- if the user can grab a ladder, do that
	if love.keyboard.isDown("up") and levelMap:canClimbLadder(self) then
		self:changeAction(ladder)
	end

	-- update position and velocity
  	self:MoveAndCollide(dt)

  	-- show idling sprite
	self.sprite = playerSprites.frames[playerSprites.runAnimation[self.animationFrame + 1] + self.direction * 10]
end

-- attack state
function attack(self, dt)
  	-- update animation
  	self:updateAnimation(6, 1.0 / 30.0)
	self.sprite = playerSprites.frames[playerSprites.attackAnimation[self.animationFrame + 1] + self.direction * 10]

	-- we can still be moving
  	self:MoveAndCollide(dt)

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
	if not love.keyboard.isDown("s") then
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
	delta = levelMap:distanceToLadder(self) -- return the distance from center to center

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

		if love.keyboard.isDown("up") then
			local distup = levelMap:distanceUp(self)
			if distup > 0 then
				-- animate
				print(levelMap:distanceUp(self))
				self:updateAnimation(2, 1.0 / 8.0)
				self.sprite = playerSprites.frames[31 + self.animationFrame]

				-- and move up
				self.y = self.y - math.min(48 * dt, distup)
			end
		elseif love.keyboard.isDown("down") then
			-- if we can go down 
			if levelMap:distanceDown(self) > 0 then
				-- animation
				self:updateAnimation(2, 1.0 / 8.0)
				self.sprite = playerSprites.frames[31 + self.animationFrame]

				-- and move down
				self.y = self.y + 48 * dt
			else
				-- we can't move down, so change state back to idling
				self:changeAction(idle)
			end
		else
			-- state idling on the ladder, use idling sprite
			self.sprite = playerSprites.frames[30]
		end
	end
end

function love.load()
	-- change window mode
	success = love.window.setMode(1280, 768, {resizable=false, vsync=true, fullscreen=false})
	love.window.setTitle("Sword Game")

	-- create player sprite
	playerSprite = Entity.new()
	playerSprite.action = idle

	-- load test level
	levelMap = Map.new(require "testlevel")
	levelMap:setSize(320, 160)

	-- use joystick (for testing puprose)
	joysticks = love.joystick.getJoysticks()
	joystick = joysticks[1]

	font = love.graphics.newImageFont("test_font.png",
    " !\"#$%&`()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_'abcdefghijklmnopqrstuvwxyz{:}" )
    font:setFilter("nearest", "nearest")
    love.graphics.setFont(font)
end

function love.update(dt)
	-- get elapsed time since last frame
	dt = love.timer.getDelta()

	-- update player entity
	playerSprite:action(dt)

	-- update scrolling to show the player
	levelMap:scrollTo(playerSprite)
end

function love.draw()
	-- use scalling, make pixel bigger 
   	love.graphics.scale(4.0, 4.0)
   	love.graphics.setColor(255, 255, 255, 255)
   	--love.graphics.polygon("fill", 0, 0, 320, 0, 320, 160, 0, 160)
    love.graphics.print("Hello World 93556", 0, 0)

    -- draw the world 32 pixel from the top
   	love.graphics.translate(0, 32)

	-- set scissor 
	love.graphics.setScissor(0, 32 * 4, 320 * 4, 160 * 4)

	-- draw the world
   	levelMap:draw()
   	
   	-- draw the entities
   	-- translate according to current world scrolling
  	love.graphics.translate(-levelMap.dx, -levelMap.dy)

	-- draw character
	playerSprite:draw()

	-- restore state
	love.graphics.setScissor()
end