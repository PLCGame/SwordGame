Map = {}
Map.__index = Map

function AABBOverlap(A, B)
	local Tx = (A.min[0] + A.max[0]) * 0.5 - (B.min[0] + B.max[0]) * 0.5
	local Ty = (A.min[1] + A.max[1]) * 0.5 - (B.min[1] + B.max[1]) * 0.5

	local width = (A.max[0] - A.min[0]) * 0.5 + (B.max[0] - B.min[0]) * 0.5
	local height = (A.max[1] - A.min[1]) * 0.5 + (B.max[1] - B.min[1]) * 0.5

	if math.abs(Tx) < width and math.abs(Ty) < height then
		return true
	end

	return false
end

function AABBSweepTest(A, vA, B, vB)
	local xInvEntry, yInvEntry
	local xInvExit, yInvExit

	-- distance between object
	if vA[0] > 0 then
		xInvEntry = B.min[0] - A.max[0]
		xInvExit = B.max[0] - A.min[0]
	else
		xInvEntry = B.max[0] - A.min[0]
		xInvExit = B.min[0] - A.max[0]
	end

	if vA[1] > 0 then
		yInvEntry = B.min[1] - A.max[1]
		yInvExit = B.max[1] - A.min[1]
	else
		yInvEntry = B.max[1] - A.min[1]
		yInvExit = B.min[1] - A.max[1]
	end

	-- collision time
	local xEntry, yEntry
	local xExit, yExit

	if vA[0] == 0.0 then
		xEntry = -1e6
		xExit = 1e6
	else
		xEntry = xInvEntry / vA[0]
		xExit = xInvExit / vA[0]
	end

	if vA[1] == 0.0 then
		yEntry = -1e6
		yExit = 1e6
	else
		yEntry = yInvEntry / vA[1]
		yExit = yInvExit / vA[1]
	end

	local entryTime = math.max(xEntry, yEntry)
	local exitTime = math.min(xExit, yExit)

	-- if there's no collision
	if entryTime > exitTime or xEntry < 0.0 and yEntry < 0.0 or xEntry > 1.0 or yEntry > 1.0 then
		return 1.0, 0
	end

	-- else
	local n = 0
	-- collision
	if xEntry > yEntry then
		n = 0
	else
		n = 1
	end
	
	return entryTime, n
end

function Map.new(mapFilename, entityFactory) 
	local mapPath = ""
	local separatorIndex =  mapFilename:find("/", -mapFilename:len())

	if separatorIndex ~= nil then
		mapPath = mapFilename:sub(0, separatorIndex)
	end

	local mapFile = love.filesystem.load(mapFilename)
	local mapData = mapFile()

	local self = setmetatable({}, Map)

	self.width = mapData.width
	self.height = mapData.height
	self.tile_width = mapData.tilewidth
	self.tile_height = mapData.tileheight

	-- load tilesets
	self.tiles = {}
	for _, tileset in ipairs(mapData.tilesets) do
		self:loadTileset(tileset, mapPath)
	end

	-- create background tile map
	self:createBackgroundLayer(mapData.layers[1])

	local objectLayer = mapData.layers[2]
	self.objectsMap = {}

	for i = 0, self.width * self.height - 1 do
		self.objectsMap[i] = objectLayer.data[1 + i]
	end

	-- parse object layers
	self:createEntityLayer(mapData.layers[3], entityFactory)

	return self
end

function Map:loadTileset(data, path)
	local tilesetImage = love.graphics.newImage(path .. data.image)
	tilesetImage:setFilter("nearest", "nearest") 

	-- create the quad
	sw = tilesetImage:getWidth() / data.tilewidth
	sh = tilesetImage:getHeight() / data.tileheight

	for y = 0, sh do 
		for x = 0, sw do
			local gid = x + y * sw + data.firstgid
			local tile = {}

			tile.image = tilesetImage
			tile.quad = love.graphics.newQuad(x * data.tilewidth, y * data.tileheight, data.tilewidth, data.tileheight, tilesetImage:getWidth(), tilesetImage:getHeight())

			-- insert in tiles
			self.tiles[gid] = tile
		end
	end

	-- loop trough tiles
	for i, tile in ipairs(data.tiles) do
		local gid = tile.id + data.firstgid

		if tile.properties ~= nil then
			self.tiles[gid].type = tile.properties["type"]
		end

		-- use Tiled tile editor
		-- start with nil, no collision
		self.tiles[gid].collision = nil

		-- just use one object per tile by now
		if tile.objectGroup ~= nil and #tile.objectGroup.objects > 0 and tile.objectGroup.objects[1].shape == "rectangle" then
			local aabb = { min = {}, max = {} }
			aabb.min[0] = tile.objectGroup.objects[1].x
			aabb.max[0] = tile.objectGroup.objects[1].x + tile.objectGroup.objects[1].width
			aabb.min[1] = tile.objectGroup.objects[1].y
			aabb.max[1] = tile.objectGroup.objects[1].y + tile.objectGroup.objects[1].height

			self.tiles[gid].collision = aabb
		end
	end
end

function Map:createBackgroundLayer(backgroundLayer)
	self.backgroundMap = {}

	for i = 0, self.width * self.height - 1 do
		self.backgroundMap[i] = backgroundLayer.data[1 + i]
	end
end

function Map:createEntityLayer(entityLayer, entityFactory)
	if entityLayer ~= nil then
		for i = 1, #entityLayer.objects do
			local obj = entityLayer.objects[i]

			--print(obj.type)

			-- create the entity
			local x = obj.x + obj.width * 0.5
			local y = obj.y + obj.height
			entityFactory:spawnEntity(obj.type, x, y)
		end
	end
end

-- draw the map
-- x, y position on the screen 
-- width, height size in pixels
function Map:draw(x, y , width, height)
	tilex = math.max(math.floor(x / self.tile_width), 0)
	tiley = math.max(math.floor(y / self.tile_height), 0)
	tilew = math.min(math.ceil(width / self.tile_width), self.width - 1 - tilex)
	tileh = math.min(math.ceil(height / self.tile_height), self.height - 1 - tiley)

	-- draw background
	for ty = 0, tileh do 
		for tx = 0, tilew do
			local tile = self.tiles[self.backgroundMap[(tx + tilex) + (ty + tiley) * self.width]]

			-- there can be hole in the map
			if tile ~= nil then
				love.graphics.draw(tile.image, tile.quad, (tx + tilex) * self.tile_width, (ty + tiley) * self.tile_height, 0, 1.0, 1.0, 0.0, 0.0)
			end
		end
	end

	-- draw objects
	for ty = 0, tileh do 
		for tx = 0, tilew do
			local tile = self.tiles[self.objectsMap[(tx + tilex) + (ty + tiley) * self.width]]

			if tile ~= nil then			
				love.graphics.draw(tile.image, tile.quad, (tx + tilex) * self.tile_width, (ty + tiley) * self.tile_height, 0, 1.0, 1.0, 0.0, 0.0)
			end
		end
	end

end

-- return the type of tile (ladder, etc)
function Map:tileType(x, y)
	local clampX = math.max(0, math.min(self.width - 1, x))
	local clampY = math.max(0, math.min(self.height - 1, y))
	local tile = self.tiles[self.backgroundMap[clampX + clampY * self.width]]

	if tile ~= nil then
		return tile.type
	end

	-- else
	return nil
end

-- return distance to center, distance up, distance down
-- return nil if there's no ladder next to the entity
function Map:distanceToLadder(entity)
	local xmin = math.floor((entity.x - entity.width * 0.5) / self.tile_width)
	local xmax = math.floor((entity.x + entity.width * 0.5-1) / self.tile_width)
	local ymin = math.floor((entity.y - entity.height) / self.tile_height)
	local ymax = math.floor(entity.y / self.tile_height)

	for y = ymin, ymax do
		for x = xmin, xmax do
			if self:tileType(x, y) == "ladder" then
				-- we found a valid ladder tile
				local distanceToCenter = (x + 0.5) * self.tile_width - entity.x

				local distanceToBottom = (y + 1) * self.tile_height - entity.y
				local _y = y + 1
				while _y < self.height and self:tileType(x, _y) == "ladder" do
					_y = _y + 1
					distanceToBottom = distanceToBottom + self.tile_height
				end

				local distanceToTop = entity.y - y * self.tile_height
				_y = y - 1
				while _y >= 0 and self:tileType(x, _y) == "ladder" do
					_y = _y - 1
					distanceToTop = distanceToTop + self.tile_height
				end

				return distanceToCenter, distanceToTop, distanceToBottom
			end
		end
	end

	-- no ladder tile
	return nil
end

-- return the whole level AABB
function Map:getAABB()
	local aabb = { min = {}, max = {} }
	aabb.min[0] = 0
	aabb.max[0] = self.tile_width * self.width
	aabb.min[1] = 0
	aabb.max[1] = self.tile_height * self.height

	return aabb
end

-- return the AABB for the tile at x, y
function Map:AABBForTile(x, y)
	local clampX = math.max(0, math.min(self.width - 1, x))
	local clampY = math.max(0, math.min(self.height - 1, y))

	local tile = self.tiles[self.backgroundMap[clampX + clampY * self.width]]

	if tile ~= nil then
		local col_aabb = tile.collision
		local aabb = { min = {}, max = {} }

		if col_aabb ~= nil then
			aabb.min[0] = x * self.tile_width + col_aabb.min[0]
			aabb.max[0] = x * self.tile_width + col_aabb.max[0]
			aabb.min[1] = y * self.tile_height + col_aabb.min[1]
			aabb.max[1] = y * self.tile_height + col_aabb.max[1]

			return aabb
		end
	end

	-- else
	return nil
end

-- Cast an AABB in the map along v
-- type is the type of tile to ignore 
function Map:AABBCast(aabb, v, tileType)
	-- get the tiles
	tilesAABB = { min = {}, max = {} }

	for i = 0, 1 do
		if v[i] < 0 then
			tilesAABB.min[i] = aabb.min[i] + v[i]
			tilesAABB.max[i] = aabb.max[i]
		else
			tilesAABB.min[i] = aabb.min[i]
			tilesAABB.max[i] = aabb.max[i] + v[i]
		end
	end

	tile_min = {}
	tile_max = {}
	tile_min[0] = math.floor(tilesAABB.min[0] / self.tile_width)
	tile_max[0] = math.floor(tilesAABB.max[0] / self.tile_width)

	tile_min[1] = math.floor(tilesAABB.min[1] / self.tile_height)
	tile_max[1] = math.floor(tilesAABB.max[1] / self.tile_height)

	-- iterate on the tile and do the cast for each of them
	normal = 0
	u = 1.0
	for y = tile_min[1], tile_max[1] do
		for x = tile_min[0], tile_max[0] do
			if tileType == nil or self:tileType(x, y) ~= tileType then
				tileAABB = self:AABBForTile(x, y)

				if tileAABB ~= nil and AABBOverlap(tileAABB, tilesAABB) then
					--print("tile : ", x, y, tileAABB.min[1], tileAABB.max[1])

					_u, _normal = AABBSweepTest(aabb, v, tileAABB, {[0] = 0, [1] = 0})

					if _u < 1.0 then
						if _u < u then
							normal = _normal
							u = _u
						end
					end
				end
			end
		end
	end

	--print("cast result", u, v[0], v[1])

	return u, normal
end
