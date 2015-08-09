mainMenuState = {}

mainMenuState.background = love.graphics.newImage("UI/menu_background.png")
mainMenuState.background:setFilter("nearest", "nearest")
mainMenuState.background:setWrap("repeat", "repeat")
mainMenuState.backgroundOffset = 0

function mainMenuState:load(game)
end

function mainMenuState:actiontriggered(game, action)
end

function mainMenuState:update(game, dt)
	--self.backgroundOffset = self.backgroundOffset + dt * 128.0
end

function mainMenuState:draw(game)
	quad = love.graphics.newQuad(self.backgroundOffset, self.backgroundOffset, 320, 180, 128, 128)
	love.graphics.draw(self.background, quad, 0, 0)
end