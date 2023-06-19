local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local function getDocument()
	return if RunService:IsStudio() then game.CoreGui else Players.LocalPlayer.PlayerGui
end

-- Gets the layer collector that renders this element.
local function getOwnerLayerCollector(element: GuiObject | { current: GuiObject? })
	if typeof(element) == "Instance" and element:IsA("GuiObject") then
		return element:FindFirstAncestorWhichIsA("LayerCollector")
	end

	if type(element) == "table" and element.current ~= nil then
		if typeof(element.current) == "Instance" and element.current:IsA("GuiObject") then
			return element.current:FindFirstAncestorWhichIsA("LayerCollector")
		end
	end

	return getDocument()
end

return getOwnerLayerCollector
