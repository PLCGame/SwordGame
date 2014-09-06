local Map = {}
Map.__index = Map

function loadTileset(data)
	local tileset = {}

	tileset.image = love.graphics.newImage(data.image)
	tileset.image:setFilter("nearest", "nearest") 

	-- create the quad
	sw = tileset.image:getWidth() / data.tilewidth
	sh = tileset.image:getHeight() / data.tileheight

	tileset.tiles = {}
	for y = 0, sh do 
		for x = 0, sw do
			tileset.tiles[x + y * sw] = {}
			tileset.tiles[x + y * sw].quad = love.graphics.newQuad(x * 16, y * 16, 16, 16, tileset.image:getWidth(), tileset.image:getHeight())
		end
	end

	-- loop trough properties
	for i, tile in ipairs(data.tiles) do
		tileset.tiles[tile.id].collision = tonumber(tile.properties["collision"])

		tileset.tiles[tile.id].type = tile.properties["type"]
	end

	return tileset
end

function Map.new(mapData) 
	local self = setmetatable({}, Map)

	self.screen_width = 256
	self.screen_height = 192

	self.dx = 0
	self.dy = 0

	self.width = mapData.width
	self.height = mapData.height
	self.tile_width = mapData.tilewidth
	self.tile_height = mapData.tileheight

	-- load tile set
	self.backgroundTiles = loadTileset(mapData.tilesets[1])

	-- create background tile map
	backgroundLayer = mapData.layers[1]
	self.backgroundMap = {}

	for i = 0, self.width * self.height - 1 do
		self.backgroundMap[i] = backgroundLayer.data[1 + i] - 1
	end

	-- create object map
	self.objectTiles = loadTileset(mapData.tilesets[2])

	objectLayer = mapData.layers[2]
	self.objectsMap = {}

	for i = 0, self.width * self.height - 1 do
		self.objectsMap[i] = objectLayer.data[1 + i] - mapData.tilesets[2].firstgid
	end

	return self
end

-- draw the map
-- x, y position on the screen 
-- width, height size in pixels
-- dx, dy scrolling position
function Map.draw(self)
	tilex = math.floor(self.dx / self.tile_width)
	tiley = math.floor(self.dy / self.tile_height)
	tilew = math.min(self.screen_width / self.tile_width, self.width - 1 - tilex)
	tileh = math.min(self.screen_height / self.tile_height, self.height-1 - tiley)

	-- draw background
	for ty = 0, tileh do 
		for tx = 0, tilew do
			tile = self.backgroundTiles.tiles[self.backgroundMap[(tx + tilex) + (ty + tiley) * self.width]]

			if tile == nil then
				print(tilex, tiley, tilew, tileh)
			end

			love.graphics.draw(self.backgroundTiles.image, tile.quad, (tx + tilex) * self.tile_width - self.dx, (ty + tiley) * self.tile_height - self.dy, 0, 1.0, 1.0, 0.0, 0.0)
		end
	end

	-- draw objects
	for ty = 0, tileh do 
		for tx = 0, tilew do
			tile = self.objectTiles.tiles[self.objectsMap[(tx + tilex) + (ty + tiley) * self.width]]

			if tile ~= nil then			
				love.graphics.draw(self.objectTiles.image, tile.quad, (tx + tilex) * self.tile_width - self.dx, (ty + tiley) * self.tile_height - self.dy, 0, 1.0, 1.0, 0.0, 0.0)
			end
		end
	end

end

function Map.setSize(self, width, height)
	self.screen_width = width
	self.screen_height = height
end

function Map.scrollTo(self, object)
	self.dx = math.min(math.max(object.x - 64, 0), self.dx) -- lower x bound
	self.dx = math.max(math.min(object.x + object.width + 64 - self.screen_width, self.width * self.tile_width - self.screen_width), self.dx) -- higher x bound

	self.dy = math.min(math.max(object.y - 32, 0), self.dy) -- lower y bound
	self.dy = math.max(math.min(object.y + object.height + 32 - self.screen_height, self.height * self.tile_height - self.screen_height), self.dy) -- higher x bound
end

-- return the distance the character can travel in the down direction
function Map.distanceDown(self, entity)
	-- get the entity position in tile space
	xmin = math.floor((entity.x - entity.width * 0.5) / self.tile_width)
	xmax = math.floor((entity.x + entity.width * 0.5 - 1) / self.tile_width)
	y = math.floor((entity.y - 1)/ self.tile_height)

	if xmin < 0 then
		return 0
	end

	if xmax > self.width then
		return 0
	end

	-- offset to the bottom of the tile
	distance = ((y + 1) * self.tile_height) - entity.y

	if y >= self.height - 1 then
		return distance
	end

	y = y + 1

	-- now iterate
	while y < self.height and (self.backgroundTiles.tiles[self.backgroundMap[xmin + y * self.width]].collision ~= 15) and (self.backgroundTiles.tiles[self.backgroundMap[xmax + y * self.width]].collision ~= 15) do
		distance = distance + self.tile_height
		--print(map[x + y * 16])


		y = y + 1
	end

	return distance
end

function Map.distanceUp(self, entity)
	-- get the entity position in tile space
	xmin = math.floor((entity.x - entity.width * 0.5) / self.tile_width)
	xmax = math.floor((entity.x + entity.width * 0.5 - 1) / self.tile_width)
	y = math.floor((entity.y - entity.height)/ self.tile_height)

	if xmin < 0 then
		return 0
	end

	if xmax > self.width then
		return 0
	end

	-- offset to the bottom of the tile
	distance = (entity.y - entity.height) - (y * self.tile_height)

	if y == 0 then
		return distance
	end

	y = y - 1

	-- now iterate
	while y >= 0 and (self.backgroundTiles.tiles[self.backgroundMap[xmin + y * self.width]].collision ~= 15) and (self.backgroundTiles.tiles[self.backgroundMap[xmax + y * self.width]].collision ~= 15) do
		distance = distance + self.tile_height
		y = y - 1
	end

	return distance
end

function Map.distanceLeft(self, entity)
	x = math.floor((entity.x - entity.width * 0.5) / self.tile_width)
	ymin = math.floor((entity.y - entity.height) / self.tile_height)
	ymax = math.floor((entity.y - 1) / self.tile_height)

	-- offset to the left of the tile
	distance = (entity.x - entity.width * 0.5) - (x * self.tile_width)

	if x <= 0 then
		return distance
	end

	x = x - 1

	-- now iterate
	while x >= 0 and self.backgroundTiles.tiles[self.backgroundMap[x + ymin * self.width]].collsion ~= 15 and self.backgroundTiles.tiles[self.backgroundMap[x + ymax * self.width]].collision ~= 15 do
		distance = distance + 16
		--print(map[x + y * 16])
		x = x - 1
	end

	--print(distance)

	return distance
end

function Map.distanceRight(self, entity)
	x = math.floor((entity.x + entity.width * 0.5 - 1) / self.tile_width)
	ymin = math.floor((entity.y - entity.height) / self.tile_height)
	ymax = math.floor((entity.y - 1) / self.tile_height)

	-- offset to the left of the tile
	distance = ((x + 1) * self.tile_width) - (entity.x + entity.width * 0.5)

	if x > self.width then
		return distance
	end

	x = x + 1

	-- now iterate
	while x < self.width and self.backgroundTiles.tiles[self.backgroundMap[x + ymin * self.width]].collision ~= 15 and self.backgroundTiles.tiles[self.backgroundMap[x + ymax * self.width]].collision ~= 15 do
		distance = distance + self.tile_width
		--print(map[x + y * 16])
		x = x + 1
	end

	--print(distance)

	return distance
end

function Map.canClimbLadder(self, entity)
	xmin = math.floor((entity.x - entity.width * 0.5) / self.tile_width)
	xmax = math.floor((entity.x + entity.width * 0.5 - 1) / self.tile_width)
	ymin = math.floor((entity.y - entity.height) / self.tile_height)
	ymax = math.floor((entity.y - 1) / self.tile_height)

	if self.backgroundTiles.tiles[self.backgroundMap[xmin + ymin * self.width]].type == "ladder" or self.backgroundTiles.tiles[self.backgroundMap[xmax + ymin * self.width]].type == "ladder" then
		return true
	end

	return false
end

function Map.distanceToLadder(self, entity)
	xmin = math.floor((entity.x - entity.width * 0.5) / self.tile_width)
	xmax = math.floor((entity.x + entity.width * 0.5 - 1) / self.tile_width)
	ymin = math.floor((entity.y - entity.height) / self.tile_height)
	ymax = math.floor((entity.y - 1) / self.tile_height)

	if self.backgroundTiles.tiles[self.backgroundMap[xmin + ymin * self.width]].type == "ladder" or self.backgroundTiles.tiles[self.backgroundMap[xmin + ymax * self.width]].type == "ladder" then
		return (xmin + 0.5) * self.tile_width - entity.x -- distance from center to center
	end

	if self.backgroundTiles.tiles[self.backgroundMap[xmax + ymin * self.width]].type == "ladder" or self.backgroundTiles.tiles[self.backgroundMap[xmax + ymax * self.width]].type == "ladder" then
		return (xmax + 0.5) * self.tile_width - entity.x -- distance from center to center
	end

end

return Map