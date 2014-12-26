Vector = {}
Vector.__index = Vector

function Vector.new(x, y) 
	return setmetatable({x = x or 0, y = y or 0}, Vector)
end

function Vector.__tostring(v)
	return "(" .. v.x .. ", " .. v.y ..")"
end

function Vector.__add(v1, v2)
	return Vector(v1.x + v2.x, v1.y + v2.y)
end

function Vector.__mul(v, m)
	if type(m) == "number" then
		return Vector(v.x * m, v.y * m)
	end

	-- else cross product
	return v.x * m.y - v.y * m.x
end

function Vector.__unm(v)
	return Vector(-v.x, -v.y)
end

function Vector.__eq(v1, v2)
	return v1.x == v2.x and v1.y == v2.y
end

function Vector.dot(v1, v2)
	return v1.x * v2.x + v1.y * v2.y
end

function Vector.lenSQ(v)
	return v:dot(v)
end

function Vector.len(v)
	return math.sqrt(v:lenSQ())
end

setmetatable(Vector, { __call = function(_, ...) return Vector.new(...) end })