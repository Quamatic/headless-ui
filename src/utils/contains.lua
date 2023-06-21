local src = script.Parent.Parent.Parent
local Array = require(src.LuauPolyfill).Array

local function contains(parent: GuiObject, element: GuiObject)
	return Array.includes(parent:GetDescendants(), element)
end

return contains
