inputConfigState = {}
function inputConfigState:update(game, dt)
end

function inputConfigState:draw(game)
	love.graphics.setColor(255, 255, 255, 255)	
	love.graphics.print("Input config", 50, 20)
	love.graphics.print("Player1", 50, 30)

end

function inputConfigState:load(game)
end