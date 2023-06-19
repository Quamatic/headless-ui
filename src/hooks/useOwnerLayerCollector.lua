local src = script.Parent.Parent.Parent
local React = require(src.React)
local getOwnerLayerCollector = require(src.ReactHeadless.utils.getOwnerLayerCollector)

local function useOwnerLayerCollector(element: GuiObject | { current: GuiObject? })
	return React.useMemo(function()
		return getOwnerLayerCollector(element)
	end, { element })
end

return useOwnerLayerCollector
