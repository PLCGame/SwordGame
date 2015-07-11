inputConfigState = {}
function inputConfigState:load(game)
	self.keyboard_img = love.graphics.newImage("keyboard.png")
	self.keyboard_img:setFilter("nearest", "nearest")
end

function inputConfigState:update(game, dt)
end

function inputConfigState:draw(game)
	love.graphics.setColor(255, 255, 255, 255)	
	love.graphics.print("Input config", 50, 20)
	love.graphics.print("Player1", 50, 30)

	love.graphics.draw(self.keyboard_img)
end
