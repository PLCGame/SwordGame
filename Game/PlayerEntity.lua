PlayerEntity = {}

-- Sounds
PlayerEntity.swordSound = love.audio.newSource("Sounds/Sword.wav", "static")
PlayerEntity.jumpSound = love.audio.newSource("Sounds/Jump.wav", "static")

-- Sprites
local spriteImage = love.graphics.newImage("Sprites/Player Sprites.png")
spriteImage:setFilter("nearest", "nearest")

PlayerEntity.sprites = SpriteFrame.new(spriteImage, love.graphics.newImage("Sprites/Player Mask.png"), love.graphics.newImage("Sprites/Player Mark.png"))
PlayerEntity.sprites.runAnimation = { 10, 11, 10, 12 }
PlayerEntity.sprites.attackAnimation = { 14, 15, 16, 17, 17, 10 }

function PlayerEntity.new(level, x, y)
	local self = Entity.new(8, 15, level)
	self:changeAction(PlayerEntity.idle)
	self.x = x
	self.y = y
	self.maxSpeed = 96
	self.acceleration = 1024

	self.entityDidEnter = PlayerEntity.entityDidEnter
	self.message = PlayerEntity.message

	self.type = "player"

	return self
end

function PlayerEntity.begin_jump(self)
	-- init basic 
	PlayerEntity.jumpSound:play()
	self.speedY = -170.0 -- start impulse
	self:changeAction(PlayerEntity.jump)
end

function PlayerEntity.begin_attack(self)
	PlayerEntity.swordSound:stop()
	PlayerEntity.swordSound:play()
	self:changeAction(PlayerEntity.attack)

	local bullet = self.level:spawnEntity("Bullet", self.x, self.y - 5)
	bullet.owner = self

	if self.direction == 1 then
		bullet.speedX = -bullet.speedX
	end

end


-- falling state
function PlayerEntity.fall(self, dt)
	-- we can attack while in air
  	if self.playerControl:canAttack() then
  		-- change state
  		PlayerEntity.begin_attack(self)
  	end

  	-- we can move left and right
	if self.playerControl:canGoLeft() then
		self.speedX = math.max(self.speedX - 4.0, -self.maxSpeed)
		self.direction = 1
	end

	if self.playerControl:canGoRight() then
		self.speedX = math.min(self.speedX + 4.0, self.maxSpeed)
		self.direction = 0
	end

	-- we reach the ground, back to idle state
  	if self:OnGround() then
  		-- change state
  		self:changeAction(PlayerEntity.idle)
  	end

  	-- if the user can grab a ladder, do that
	if self.playerControl:canGoUp() and self.level.map:distanceToLadder(self) ~= nil then
		self:changeAction(PlayerEntity.ladder)
	end

  	-- update position and velocity
  	self:MoveAndCollide(dt)

  	-- use an idling sprite
  	self.sprite = PlayerEntity.sprites.frames[PlayerEntity.sprites.runAnimation[self.animationFrame + 1] + self.direction * 10]
end

function PlayerEntity.jump(self, dt)
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
  		self:changeAction(PlayerEntity.fall)
  	end

  	if self.playerControl:canAttack() then
  		-- change state
  		PlayerEntity.begin_attack(self)
  	end

end

function PlayerEntity.run(self, dt)
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
		self:changeAction(PlayerEntity.idle)
  	end

  	-- update position and velocity
  	self:MoveAndCollide(dt)

  	-- are we still on the ground?
  	if not self:OnGround() then
  		-- no, then go into fall state
  		self:changeAction(PlayerEntity.fall)
	end
	-- jump
	if self.playerControl:testTrigger("jump") then
		-- so we can jump
	  	PlayerEntity.begin_jump(self)
	end

	-- update sprite
	self:updateAnimation(4, 1.0 / 16.0)
	self.sprite = PlayerEntity.sprites.frames[PlayerEntity.sprites.runAnimation[self.animationFrame + 1] + self.direction * 10]

	-- we can attack while moving
  	if self.playerControl:canAttack() then
  		-- change state
  		PlayerEntity.begin_attack(self)
  	end

  	-- and defend
	if self.playerControl:canDefend() then
  		-- change state
	  	self:changeAction(PlayerEntity.defend)
	end
end

-- idling state, the character does nothing
function PlayerEntity.idle(self, dt)
	-- we need to slow donw in order to stop moving
	if self.speedX > 0.0 then
		self.speedX = math.max(self.speedX - self.acceleration * dt, 0.0)
	end

	if self.speedX < 0.0 then
		self.speedX = math.min(self.speedX + self.acceleration * dt, 0.0)
	end

	-- if the players wants to move, change to run state
  	if self.playerControl:canGoLeft() or self.playerControl:canGoRight() then
  		self:changeAction(PlayerEntity.run)
  	end

  	-- attack
  	if self.playerControl:canAttack() then
  		-- change state
  		PlayerEntity.begin_attack(self)
  	end

  	-- defend
	if self.playerControl:canDefend() then
  		-- change state
	  	self:changeAction(PlayerEntity.defend)
	end

	-- if we can fall, switch to fall state
  	if not self:OnGround() then
  		self:changeAction(PlayerEntity.fall)
  	end
  	
  	-- jump
	if self.playerControl:testTrigger("jump") then
  		-- so we can jump
  		PlayerEntity.begin_jump(self)
  	end

  	-- if the user can grab a ladder, do that
	if (self.playerControl:canGoDown() or self.playerControl:canGoUp()) then
		x, t, b = self.level.map:distanceToLadder(self)
		if x ~= nil and ((self.playerControl:canGoDown() and b > 0) or (self.playerControl:canGoUp() and t > 0))  then
			self:changeAction(PlayerEntity.ladder)
		end
	end

	-- update position and velocity
  	self:MoveAndCollide(dt)

  	-- show idling sprite
	self.sprite = PlayerEntity.sprites.frames[PlayerEntity.sprites.runAnimation[self.animationFrame + 1] + self.direction * 10]
end

-- attack state
function PlayerEntity.attack(self, dt)
	-- we need to slow down in order to stop moving if we are on the ground
	aabb = self:getAABB()
  	if self.level.map:AABBCast(aabb, {[0] = 0, [1] = 1}) == 0.0 then
		if self.speedX > 0.0 then
			self.speedX = math.max(self.speedX - self.acceleration * dt, 0.0)
		end

		if self.speedX < 0.0 then
			self.speedX = math.min(self.speedX + self.acceleration * dt, 0.0)
		end
	end

  	-- update animation
  	self:updateAnimation(6, 1.0 / 30.0)
	self.sprite = PlayerEntity.sprites.frames[PlayerEntity.sprites.attackAnimation[self.animationFrame + 1] + self.direction * 10]

	-- we can still be moving
  	self:MoveAndCollide(dt)

  	if self.animationFrame >= 3 then
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

		local enemies = self.level:intersectingEntities(swordAABB)

		for _, enemy in ipairs(enemies) do
  			if enemy ~= self then
				-- kill the enemy!
  				--enemy:Hit(40, self.direction)
  				enemy:message(self, "hit", {power = 40, direction = self.direction})
  			end
  		end
  	end

  	-- end of the animation, go back to idling state
	if self.animationFrame == 5 then
		self:changeAction(PlayerEntity.idle)
	end
end

-- defend, just stop and use shield
function PlayerEntity.defend(self, dt)
	-- slow down
	if self.speedX > 0.0 then
		self.speedX = math.max(self.speedX - self.acceleration * dt, 0.0)
	end

	if self.speedX < 0.0 then
		self.speedX = math.min(self.speedX + self.acceleration * dt, 0.0)
	end

	-- no longer in defense
	if not self.playerControl:canDefend() then
		self:changeAction(PlayerEntity.idle)
	end

	-- use shield sprite
	self.sprite = PlayerEntity.sprites.frames[13 + self.direction * 10]

	-- update position and velocity
	self:MoveAndCollide(dt)
end

-- ladder state
function PlayerEntity.ladder(self, dt)
	-- move the sprite to the ladder
	delta, distanceToTop, distanceToBottom = self.level.map:distanceToLadder(self) -- return the distance from center to center

	-- delta == nil means the character is no longer on a ladder tile
	if delta == nil then
		-- so switch back to idling state
		self:changeAction(PlayerEntity.idle)
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
			u, n = self.level.map:AABBCast(aabb, {[0] = 0, [1] = disp}, "ladder")

			if u < 1.0 then
				-- we can't go lower, go back to idle state
				if disp > 0 then
					self:changeAction(PlayerEntity.idle)
				end

				disp = disp * u

			end

			if disp < -distanceToTop or disp > distanceToBottom then
				-- clamp
				disp = math.min(math.max(disp, -distanceToTop), distanceToBottom)

				self:changeAction(PlayerEntity.idle)
			end

			self.y = self.y + disp

			-- update animation
			self:updateAnimation(2, 1.0 / 8.0)
			self.sprite = PlayerEntity.sprites.frames[31 + self.animationFrame]
		else
			-- state idling on the ladder, use idling sprite
			self.sprite = PlayerEntity.sprites.frames[30]
		end

		-- jump
	  	if self.playerControl:canJump() then
			self.speedY = -10.0
			self.action = fall

			self:changeAction(PlayerEntity.fall)
	  	end

	end
end

function PlayerEntity:entityDidEnter(entity)
	if entity.type == "powerup" then
		entity:message(self, "pickup", nil)
	end
end

function PlayerEntity:message(from, type, info)
	if type == "hit" then
		self.health = self.health - info.power
	end

end

-- this entity can't be spawned at map loading
-- but it should be in the factory...
--EntityFactory["Player"] = PlayerEntity.new