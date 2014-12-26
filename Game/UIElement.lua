require "Vector"

UIElement = {}
UIElement.__index = UIElement

function UIElement.new(t)
	return setmetatable(t or {}, UIElement)
end

function UIElement.foo()
	return "bar";
end

TextElement = {}
TextElement.__index = function(table, key)
	-- look in textelement
	res = TextElement[key]

	print(key)

	if res == nil then
		return UIElement[key]
	end

	return res
end

function TextElement.new(t)
	return setmetatable(t or {}, TextElement)
end