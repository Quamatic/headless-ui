local function getBoundingClientRect(element: GuiObject)
	local position = element.AbsolutePosition
	local size = element.AbsoluteSize

	return {
		x = position.X,
		y = position.Y,
		width = size.X,
		height = size.Y,
		top = position.Y,
		left = position.X,
		bottom = position.Y + size.Y,
		right = position.X + size.X,
	}
end

return getBoundingClientRect
