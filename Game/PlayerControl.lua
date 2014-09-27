local PlayerControl = {}
PlayerControl.__index = PlayerControl

function PlayerControl.new(eventTable) 
	local self = setmetatable({}, PlayerControl)

	if eventTable == nil then
		self.event = { 	left 	= 	{"left", 	"dpleft", 	"leftx", 	true},
						right 	=	{"right", 	"dpright", 	"leftx", 	false},
						up	 	= 	{"up", 		"dpup", 	"lefty", 	true},
						down	= 	{"down", 	"dpdown", 	"lefty", 	false},
						jump	= 	{"z", 		"a", 		nil, 		nil},
						attack 	= 	{"q", 		"x", 		nil,		nil},
						defend 	= 	{"d", 		"b", 		nil, 		nil}}
	else
		self.event = eventTable
	end

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

return PlayerControl