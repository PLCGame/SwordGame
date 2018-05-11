PlayerControl = {}
PlayerControl.__index = PlayerControl

function PlayerControl.new(eventTable, joystick) 
	local self = setmetatable({}, PlayerControl)

	if eventTable == nil then
		--							keyboard 	DPad        Axis     Invert Axis
		self.event = { 	left 	= 	{"left", 	"dpleft", 	"leftx", 	true},
						right 	=	{"right", 	"dpright", 	"leftx", 	false},
						up	 	= 	{"up", 		"dpup", 	"lefty", 	true},
						down	= 	{"down", 	"dpdown", 	"lefty", 	false},
						jump	= 	{"z", 		"a", 		nil, 		nil},
						attack 	= 	{"q", 		"x", 		nil,		nil},
						defend 	= 	{"d", 		"b", 		nil, 		nil},
						back 	=	{"escape",	"back",		nil, 		nil},
						start 	=	{"return",	"start", 	nil, 		nil}}
	else
		self.event = eventTable
	end

	self.joystick = joystick

	self.eventValue = {}
	self.eventTrigger = {}

	return self
end

-- return the new actions triggered
function PlayerControl:update()
	local actions = {}

	-- test each event
	for key, value in pairs(self.event) do
		local value = self:testInput(key)
		local oldValue = self.eventValue[key]

		if oldValue == nil then
			oldValue = false
		end

		if value ~= oldValue then
			if value == true then
				self.eventTrigger[key] = true
				table.insert(actions, key)
			else
				self.eventTrigger[key] = false
			end
		else
			-- no change
			self.eventTrigger[key] = false
		end

		self.eventValue[key] = value
	end

	return actions
end

-- return the current status of an event
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

-- return true if the event has been triggered since last update
function PlayerControl:testTrigger(event)
	local value = self.eventTrigger[event]

	if value == nil then
		return false
	end

	-- else
	return value
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

-- used for navigating menu
function PlayerControl:menuUp()
	return love.keyboard.isDown("up") or self:testInput("up")
end

function PlayerControl:menuDown()
	return love.keyboard.isDown("down") or self:testInput("down")
end

function PlayerControl:menuLeft()
	return love.keyboard.isDown("left") or self:testInput("left")
end

function PlayerControl:menuRight()
	return love.keyboard.isDown("right") or self:testInput("right")
end

function PlayerControl:menuValidate()
	return love.keyboard.isDown("enter") or self:testInput("jump")
end

function PlayerControl:menuCancel()
	return love.keyboard.isDown("escape") or self:testInput("defend")
end

-- initialize default PlayerControl
local joysticks = love.joystick.getJoysticks()

local player1Joystick = nil
if #joysticks > 0 then
	player1Joystick = joysticks[1]
end
--		  						keyboard 	DPad        Axis     Invert Axis
player1Event = { 	left 	= 	{"left", 	"dpleft", 	"leftx", 	true},
	 				right 	=	{"right", 	"dpright", 	"leftx", 	false},
					up	 	= 	{"up", 		"dpup", 	"lefty", 	true},
					down	= 	{"down", 	"dpdown", 	"lefty", 	false},
					jump	= 	{"z", 		"a", 		nil, 		nil},
					attack 	= 	{"q", 		"x", 		nil,		nil},
					defend 	= 	{"d", 		"b", 		nil, 		nil},
					back 	=	{"escape",	"back",		nil, 		nil},
					start 	=	{"return",	"start", 	nil, 		nil}}

if #joysticks > 1 then
	player1Joystick = joysticks[2]
end

local player2Joystick = nil
--	    						keyboard 	DPad        Axis     Invert Axis
player2Event = { 	left 	= 	{"j",		"dpleft", 	"leftx", 	true},
	 				right 	=	{"l", 		"dpright", 	"leftx", 	false},
					up	 	= 	{"i", 		"dpup", 	"lefty", 	true},
					down	= 	{"k",	 	"dpdown", 	"lefty", 	false},
					jump	= 	{"r", 		"a", 		nil, 		nil},
					attack 	= 	{"t", 		"x", 		nil,		nil},
					defend 	= 	{"y", 		"b", 		nil, 		nil},
					back 	=	{"escape",	"back",		nil, 		nil},
					start 	=	{"return",	"start", 	nil, 		nil}}


PlayerControl.player1Control = PlayerControl.new(player1Event, player2Joystick)
PlayerControl.player2Control = PlayerControl.new(player2Event, player1Joystick)