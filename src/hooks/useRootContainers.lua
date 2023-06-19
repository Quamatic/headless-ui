local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Array = LuauPolyfill.Array

local useCallbackRef = require(script.Parent.useCallbackRef)
local useOwnerLayerCollector = require(script.Parent.useOwnerLayerCollector)

type Container = { GuiObject | { current: GuiObject? } }

local function extendsGuiElement(x: any)
	return typeof(x) == "Instance" and x:IsA("GuiObject")
end

local function contains(parent: GuiObject, element: GuiObject)
	local descendants = parent:GetDescendants()

	for _, descendant in descendants do
		if descendant == element then
			return true
		end
	end

	return false
end

local function useRootContainers(defaultContainers: Container?, portals: { current: { GuiObject } }?)
	defaultContainers = defaultContainers or {} :: Container

	local mainTreeNodeRef = React.useRef(nil :: GuiObject?)
	local ownerLayerCollector = useOwnerLayerCollector(mainTreeNodeRef)

	local resolveContainers = useCallbackRef(function()
		local containers: { GuiObject } = {}

		for _, container in defaultContainers :: Container do
			if extendsGuiElement(container) then
				table.insert(containers, container)
			elseif container.current ~= nil and extendsGuiElement(container.current) then
				table.insert(containers, container.current)
			end
		end

		if portals and portals.current then
			for _, portal in portals.current do
				table.insert(containers, portal)
			end
		end

		-- Healess UI does querySelectorAll("html > *, body > *) here, but we can just get the descendants instead.
		for _, container in ownerLayerCollector:GetDescendants() do
			if not container:IsA("GuiObject") then
				continue -- Skip non GuiObjects
			end

			if container.Name == "headlessui-portal-root" then
				continue -- Skip the Headless UI oortal root
			end

			if contains(container, mainTreeNodeRef.current) then
				continue -- Skip if it is the main app
			end

			if
				Array.some(containers, function(defaultContainer)
					return contains(container, defaultContainer)
				end)
			then
				continue -- Skip if the current container is part of a container we've already seen (e.g.: default container / portal)
			end

			table.insert(containers, container)
		end

		return containers
	end)

	return {
		resolveContainers = resolveContainers,
		contains = useCallbackRef(function(element: GuiObject)
			return Array.some(resolveContainers(), function(container)
				return contains(container, element)
			end)
		end),
		mainTreeNodeRef = mainTreeNodeRef,
		MainTreeNode = React.useMemo(function()
			local function MainTreeNode()
				return React.createElement(React.Fragment)
			end

			return MainTreeNode
		end, { mainTreeNodeRef }),
	}
end

return useRootContainers
