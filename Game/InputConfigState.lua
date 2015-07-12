inputConfigState = {}

inputConfigState.keyboard_img = love.graphics.newImage("keyboard.png")
inputConfigState.keyboard_img:setFilter("nearest", "nearest")

inputConfigState.pad_img = love.graphics.newImage("xpad.png")
inputConfigState.pad_img:setFilter("nearest", "nearest")

-- Sounds
inputConfigState.menuChangeSound = love.audio.newSource("Menu Select.wav", "static")
inputConfigState.menuValidSound = love.audio.newSource("Menu Valid.wav", "static")


function inputConfigState:load(game)
	self.selectedEvent = 1
end

function inputConfigState:update(game, dt)
	if PlayerControl.player1Control:testTrigger("down") and self.selectedEvent < 7 then
		self.selectedEvent = self.selectedEvent + 1
		inputConfigState.menuChangeSound:play()
	end

	if PlayerControl.player1Control:testTrigger("up") and self.selectedEvent > 1 then
		self.selectedEvent = self.selectedEvent - 1
		inputConfigState.menuChangeSound:play()
	end

	if PlayerControl.player1Control:testTrigger("start") or PlayerControl.player1Control:testTrigger("attack") then
		inputConfigState.menuValidSound:play()
	end
end

function inputConfigState:drawKeyboard()
	local events = {"up", "down", "left", "right", "jump", "attack", "defend"}
	for i, event in ipairs(events) do
		local y = 70 + i * 12

		if i == self.selectedEvent then
			love.graphics.setColor(255, 255, 0, 255)
		else
			love.graphics.setColor(255, 255, 255, 255)
		end	


		love.graphics.print(event, 10, y)

		local keys = PlayerControl.player1Control.event[event] 

		if keys[1] ~= nil then
			love.graphics.print(keys[1], 80, y)
		end

		if keys[2] ~= nil then
			love.graphics.print(keys[2], 150, y)
		end

		if keys[3] ~= nil then
			love.graphics.print(keys[3], 220, y)
		end

	end	

	love.graphics.setColor(255, 255, 255, 255)

end

function inputConfigState:draw(game)
	love.graphics.setColor(255, 255, 255, 255)	
	love.graphics.print("Choose controller", 50, 20)
	love.graphics.print("Player1", 50, 30)

	love.graphics.draw(self.keyboard_img, 32, 60)
	love.graphics.draw(self.pad_img, 192, 60)

	-- print config
	self:drawKeyboard()
end
