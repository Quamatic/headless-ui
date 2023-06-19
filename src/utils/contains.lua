local function contains(parent: GuiObject, element: GuiObject)
	local descendants = parent:GetDescendants()

	for _, descendant in descendants do
		if descendant == element then
			return true
		end
	end

	return false
end

return contains
