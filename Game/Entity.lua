-- Entity factory contains entity constructor functions for entity name
EntityFactory = {}

BoundingBox = {}
BoundingBox.__index = BoundingBox

function BoundingBox.new(x, y, width, height)
	self = setmetatable({}, BoundingBox)

	self.x = x
	self.y = y
	self.width = width
	self.height = height

	return self
end

Entity = {}
Entity.__index = Entity

-- create a new entity instance, with default values
function Entity.new(level, boundingBox)
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
	self.boundingBox = boundingBox

	-- no action
	self.action = nil

	-- hit
	self.hit = false
	self.hitDirection = 0

	self.health = 100

	self.level = level

	return self
end

-- draw the entity
function Entity:draw()
	-- pixel perfect coordinate for drawing
	local _x = math.floor(self.x)
	local _y = math.floor(self.y)

	if self.boundingBox ~= nil then
		love.graphics.setColor(255, 0, 255, 64)	

		love.graphics.rectangle("fill", _x + self.boundingBox.x, _y + self.boundingBox.y, self.boundingBox.width,self.boundingBox.height)	
	end

	-- draw the entity if it has a sprite component
	if self.sprite ~= nil then
		love.graphics.setColor(255, 255, 255, 255)	
		love.graphics.draw(self.sprite.image, self.sprite.quad, _x, _y, 0, 1.0, 1.0, self.sprite.xoffset, self.sprite.yoffset)
	elseif self.boundingBox ~= nil then
		love.graphics.rectangle("fill", _x + self.boundingBox.x, _y + self.boundingBox.y, self.boundingBox.width,self.boundingBox.height)
	end

	if self.attachement ~= nil then
		-- pixel perfect coordinate for drawing
		local _x = math.floor(self.x + self.attachement.x)
		local _y = math.floor(self.y + self.attachement.y)
		local sprite = self.attachement.sprite
		love.graphics.draw(sprite.image, sprite.quad, _x, _y, 0, 1.0, 1.0, sprite.xoffset, sprite.yoffset)		
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
	assert(newAction ~= nil)

	self.animationTimer = 0
	self.animationFrame = 0

	self.action = newAction
end

function Entity:getAABB()
	local aabb = { min = {}, max = {} }
	aabb.min[0] = self.x + self.boundingBox.x
	aabb.max[0] = self.x + self.boundingBox.x + self.boundingBox.width
	aabb.min[1] = self.y + self.boundingBox.y
	aabb.max[1] = self.y + self.boundingBox.y + self.boundingBox.height

	return aabb
end

function Entity:OnGround()
	-- just do a cast 1px below
	local aabb = self:getAABB()
	return self.level.map:AABBCast(aabb, {[0] = 0, [1] = 1}) == 0
end

-- move the entity according to its speed, and handle collsion with world
function Entity:MoveAndCollide(dt)
	local aabb = self:getAABB()

	-- gravity
	-- if the entity is not on a solid tile, it's falling
	if not self:OnGround() then
		-- increment speed Y
  		self.speedY = math.min(self.speedY + 768.0 * dt, 192.0)
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

		u, n = self.level.map:AABBCast(aabb, v)

		if u < 0 then
			-- we are stuck inside something, don't care and move all the way... (not very good)
			-- this can happen on ladder tile
			
			u = 1
		end

		if u < 1.0 then
			-- limit the displacement
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

function Entity:collideWith(entity)
	-- do nothing
end

function Entity:message(type, info)
	-- do nothing
end