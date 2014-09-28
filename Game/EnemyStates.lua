local EnemyStates = {}

function EnemyStates.snakeDead(self, dt)
	-- move it away
	self.x = -400000000
	self.y = -400000000
end

function EnemyStates.snakeRecover(self, dt)
	-- death animation
	if self.health <= 0 then
		self:updateAnimation(3, 1.0 / 8.0)

		if self.animationFrame == 2 then
			self:changeAction(EnemyStates.snakeDead)
			return
		end

		self.sprite = self.sprites.frames[7 + 3 + self.animationFrame + self.direction * 5]
	else
		if self.speedX > 0 then
			self.speedX = math.max(0, self.speedX - 1024 * dt)
		else
			self.speedX = math.min(0, self.speedX + 1024 * dt)
		end

		if self.speedX == 0 then
			self:changeAction(EnemyStates.snakeGo)
			self.hit = false
		end

		self:MoveAndCollide(dt)		
	end
end

function EnemyStates.snakeHit(self, dt)

	-- move in the direction
	if self.hitDirection == 0 then
		self.speedX = 256.0
	else
		self.speedX = -256.0
	end
	self.speedY = -32.0

	self:changeAction(EnemyStates.snakeRecover)

	self.sprite = self.sprites.frames[7 + 2 + self.direction * 5]

	self:MoveAndCollide(dt)
end

function EnemyStates.snakeGo(self, dt)
	local aabb = self:getAABB()

	if self.direction == 1 then
		self.speedX = 32.0
	else
		self.speedX = -32.0
	end

	-- fall straight
	if self.level.map:AABBCast(aabb, {[0] = 0, [1] = 1}) > 0 then
		self.speedX = 0
	else
		-- test if we can move left or right
		if self.speedX < 0 then
			-- if we can move left
			if self.level.map:AABBCast(aabb, {[0] = -1, [1] = 0}) < 1 then
				-- change direction
				self.speedX = 32.0
				self.direction = 1
			else
				-- test the edge of the platform, go as far as half width
				c = self.level.map:AABBCast(aabb, {[0] = -self.width, [1] = 0})

				local dist = c * self.width
				aabb.min[0] = aabb.min[0] - dist
				aabb.max[0] = aabb.max[0] - dist

				-- we will reach the end of the platform
				if self.level.map:AABBCast(aabb, {[0] = 0, [1] = 1}) == 1 then
					self.speedX = 32.0
					self.direction = 1
				end
			end
		elseif self.speedX > 0 then
			if self.level.map:AABBCast(aabb, {[0] = 1, [1] = 0}) < 1 then
				self.speedX = -32.0
				self.direction = 0
			else
				-- test the edge of the platform, go as far as half width
				c = self.level.map:AABBCast(aabb, {[0] = self.width, [1] = 0})

				local dist = c * self.width
				aabb.min[0] = aabb.min[0] + dist
				aabb.max[0] = aabb.max[0] + dist

				if self.level.map:AABBCast(aabb, {[0] = 0, [1] = 1}) == 1 then
					self.speedX = -32.0
					self.direction = 0
				end
			end
		end
	end

	if self.hit then
		self:changeAction(EnemyStates.snakeHit)
	end

  	self:MoveAndCollide(dt)

	self:updateAnimation(2, 1.0 / 8.0)
	self.sprite = self.sprites.frames[7 + self.animationFrame + self.direction * 5]
end

return EnemyStates