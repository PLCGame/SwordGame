require "Vector"

UIElement = { opacity = 255}
UIElement.__index = UIElement

function UIElement.new()
	local self = {}
	setmetatable(self, UIElement)
	self.animations = {}

	return self
end

function UIElement:update(dt)
	-- update animation
	self:updateAnimations(dt)

end

function UIElement:draw()
end

-- animation handling
function UIElement:addAnimation(animation, animationKey)
	self.animations[animationKey] = animation
end

function UIElement:updateAnimations(dt)
	for key,animation in pairs(self.animations) do 
		newValue, complete = animation:update(dt)

		-- if it's a relative animation, add the result
		if animation.relative then
			local value = self[animation.key]
			self[animation.key] = value + newValue
		else
			self[animation.key] = newValue
		end

		-- if the animation is completed, remove it
		if complete then
			self.animations[key] = nil
		end
	end	
end

TextElement = {}
TextElement.__index = function(table, key)
	-- look in table
	res = rawget(table, key)

	if res ~= nil then
		return res
	end

	-- look in textelement
	res = TextElement[key]

	if res == nil then
		return UIElement[key]
	end

	return res
end

function TextElement.new(text, position)
	local self = UIElement.new()
	setmetatable(self, TextElement)

	self.text = text or ""
	self.position = position or Vector(0, 0)
	return self
end
setmetatable(TextElement, { __call = function(_, ...) return TextElement.new(...) end })

function TextElement:draw()
	love.graphics.setColor(255, 255, 255, self.opacity)	
	love.graphics.print(self.text, self.position.x, self.position.y)
end

TypeWritterTextElement = {}
TypeWritterTextElement.__index = TypeWritterTextElement

function TypeWritterTextElement.new(text, position)
	local self = setmetatable({}, TypeWritterTextElement)
	self.animations = {}

	self.text = text or ""
	self.position = position or Vector(0, 0)
	self.printedLenTimer = 0

	-- use add animation from UIElement
	self.addAnimation = UIElement.addAnimation

	return self
end
setmetatable(TypeWritterTextElement, { __call = function(_, ...) return TypeWritterTextElement.new(...) end })

function TypeWritterTextElement:draw()
	love.graphics.setColor(255, 255, 255, self.opacity)	

	-- compute the number of character to print (one per 0.02 second)
	local textLen = math.min(self.text:len(), self.printedLenTimer / 0.04)

	-- print the sub string from 0 to textLen
	love.graphics.print(self.text:sub(0, textLen), self.position.x, self.position.y)
end

function TypeWritterTextElement:update(dt)
	-- update animation
	UIElement.updateAnimations(self, dt)

	self.printedLenTimer = self.printedLenTimer + dt
end

-- basic animation class
BasicAnimation = {}
BasicAnimation.__index = BasicAnimation

function BasicAnimation.new(key, fromValue, toValue, duration, loop, relative)
	local self = {}
	setmetatable(self, BasicAnimation)

	self.key = key
	self.fromValue = fromValue
	self.toValue = toValue
	self.duration = duration
	self.time = 0
	self.loop = loop or false
	self.relative = relative or false

	return self
end
setmetatable(BasicAnimation, { __call = function(_, ...) return BasicAnimation.new(...) end })

function BasicAnimation:update(dt)
	-- compute the new value
	local a = math.min(self.time / self.duration, 1)
	local newValue = self.toValue * a + self.fromValue * (1 - a)

	self.time = self.time + dt
	local completed = self.time > self.duration

	if completed and self.loop then
		-- start again!
		self.time = self.time - self.duration
		local tmp = self.toValue
		self.toValue = self.fromValue
		self.fromValue = tmp
		completed = false
	end

	return newValue, completed
end