local PlayerStates = {}
-- falling state
function PlayerStates.fall(self, dt)
	-- we can attach will in air
  	if self.playerControl:canAttack() then
  		-- change state
  		self:changeAction(PlayerStates.attack)
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
  		self:changeAction(PlayerStates.idle)
  	end

  	-- if the user can grab a ladder, do that
	if self.playerControl:canGoUp() and self.level.map:distanceToLadder(self) ~= nil then
		self:changeAction(PlayerStates.ladder)
	end

  	-- update position and velocity
  	self:MoveAndCollide(dt)

  	-- use an idling sprite
  	self.sprite = self.sprites.frames[self.sprites.runAnimation[self.animationFrame + 1] + self.direction * 10]
end

function PlayerStates.begin_jump(self)
	-- init basic 
	self.speedY = -170.0
	self:changeAction(PlayerStates.jump)
end

function PlayerStates.jump(self, dt)
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
  		self:changeAction(PlayerStates.fall)
  	end
end

function PlayerStates.run(self, dt)
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
		self:changeAction(PlayerStates.idle)
  	end

  	-- update position and velocity
  	self:MoveAndCollide(dt)

  	-- are we still on the ground?
  	if not self:OnGround() then
  		-- no, then go into fall state
  		self:changeAction(PlayerStates.fall)
	end
	-- jump
	if self.playerControl:testTrigger("jump") then
		-- so we can jump
	  	PlayerStates.begin_jump(self)
	end

	-- update sprite
	self:updateAnimation(4, 1.0 / 16.0)
	self.sprite = self.sprites.frames[self.sprites.runAnimation[self.animationFrame + 1] + self.direction * 10]

	-- we can attack while moving
  	if self.playerControl:canAttack() then
  		-- change state
  		self.speedX = 0
  		self:changeAction(PlayerStates.attack)
  	end

  	-- and defend
	if self.playerControl:canDefend() then
  		-- change state
	  	self:changeAction(PlayerStates.defend)
	end
end

-- idling state, the character does nothing
function PlayerStates.idle(self, dt)
	-- we need to slow donw in order to stop moving
	if self.speedX > 0.0 then
		self.speedX = math.max(self.speedX - self.acceleration * dt, 0.0)
	end

	if self.speedX < 0.0 then
		self.speedX = math.min(self.speedX + self.acceleration * dt, 0.0)
	end

	-- if the players wants to move, change to run state
  	if self.playerControl:canGoLeft() or self.playerControl:canGoRight() then
  		self:changeAction(PlayerStates.run)
  	end

  	-- attack
  	if self.playerControl:canAttack() then
  		-- change state
  		self:changeAction(PlayerStates.attack)
  	end

  	-- defend
	if self.playerControl:canDefend() then
  		-- change state
	  	self:changeAction(PlayerStates.defend)
	end

	-- if we can fall, switch to fall state
  	if not self:OnGround() then
  		self:changeAction(PlayerStates.fall)
  	end
  	
  	-- jump
	if self.playerControl:testTrigger("jump") then
  		-- so we can jump
  		PlayerStates.begin_jump(self)
  	end

  	-- if the user can grab a ladder, do that
	if (self.playerControl:canGoDown() or self.playerControl:canGoUp()) then
		x, t, b = self.level.map:distanceToLadder(self)
		if x ~= nil and ((self.playerControl:canGoDown() and b > 0) or (self.playerControl:canGoUp() and t > 0))  then
			self:changeAction(PlayerStates.ladder)
		end
	end

	-- update position and velocity
  	self:MoveAndCollide(dt)

  	-- show idling sprite
	self.sprite = self.sprites.frames[self.sprites.runAnimation[self.animationFrame + 1] + self.direction * 10]
end

-- attack state
function PlayerStates.attack(self, dt)
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
	self.sprite = self.sprites.frames[self.sprites.attackAnimation[self.animationFrame + 1] + self.direction * 10]

	-- we can still be moving
  	self:MoveAndCollide(dt)

  	if self.animationFrame >= 3 then
		for enemy in self.level.enemies:iterate() do
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
		self:changeAction(PlayerStates.idle)
	end
end

-- defend, just stop and use shield
function PlayerStates.defend(self, dt)
	-- slow down
	if self.speedX > 0.0 then
		self.speedX = math.max(self.speedX - self.acceleration * dt, 0.0)
	end

	if self.speedX < 0.0 then
		self.speedX = math.min(self.speedX + self.acceleration * dt, 0.0)
	end

	-- no longer in defense
	if not self.playerControl:canDefend() then
		self:changeAction(PlayerStates.idle)
	end

	-- use shield sprite
	self.sprite = self.sprites.frames[13 + self.direction * 10]

	-- update position and velocity
	self:MoveAndCollide(dt)
end

-- ladder state
function PlayerStates.ladder(self, dt)
	-- move the sprite to the ladder
	delta, distanceToTop, distanceToBottom = self.level.map:distanceToLadder(self) -- return the distance from center to center

	-- delta == nil means the character is no longer on a ladder tile
	if delta == nil then
		-- so switch back to idling state
		self:changeAction(PlayerStates.idle)
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
					self:changeAction(PlayerStates.idle)
				end

				disp = disp * u

			end

			if disp < -distanceToTop or disp > distanceToBottom then
				-- clamp
				disp = math.min(math.max(disp, -distanceToTop), distanceToBottom)

				self:changeAction(PlayerStates.idle)
			end

			self.y = self.y + disp

			-- update animation
			self:updateAnimation(2, 1.0 / 8.0)
			self.sprite = self.sprites.frames[31 + self.animationFrame]
		else
			-- state idling on the ladder, use idling sprite
			self.sprite = self.sprites.frames[30]
		end

		-- jump
	  	if self.playerControl:canJump() then
			self.speedY = -10.0
			self.action = fall

			self:changeAction(PlayerStates.fall)
	  	end

	end
end

return PlayerStates