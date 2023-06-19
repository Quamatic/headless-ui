local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local src = script.Parent.Parent.Parent
local React = require(src.React)
local ReactRoblox = require(src.ReactRoblox)
local LuauPolyfill = require(src.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object

type Array<T> = LuauPolyfill.Array<T>

local _render = require(src.ReactHeadless.utils.render)
local render = _render.render
local forwardWithRefAs = _render.forwardWithRefAs

local contains = require(src.ReactHeadless.utils.contains)

local _useSyncRefs = require(src.ReactHeadless.hooks.useSyncRefs)
local useSyncRefs = _useSyncRefs.useSyncRefs
local optionalRef = _useSyncRefs.optionalRef
local useCallbackRef = require(src.ReactHeadless.hooks.useCallbackRef)
local useOwnerLayerCollector = require(src.ReactHeadless.hooks.useOwnerLayerCollector)

local ForcePortalRoot = require(src.ReactHeadless.internal.PortalForceRoot)
local usePortalRoot = ForcePortalRoot.usePortalRoot

local PortalParentContext
local PortalGroupContext

-- usePortalTarget

local function usePortalTarget(ref: { current: GuiObject? })
	local forceInPortal = usePortalRoot()
	local groupTarget = React.useContext(PortalGroupContext)

	local ownerLayerCollector = useOwnerLayerCollector(ref)

	local target: Folder?, setTarget = React.useState(function()
		if not forceInPortal and groupTarget ~= nil then
			return nil
		end

		local existingRoot = ownerLayerCollector and ownerLayerCollector:FindFirstChild("headlessui-portal-root")
		if existingRoot ~= nil then
			return existingRoot
		end

		if ownerLayerCollector == nil then
			return nil
		end

		local root = Instance.new("ScreenGui")
		root.ResetOnSpawn = false
		root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		root.Name = "headlessui-portal-root"
		root:SetAttribute("id", "headlessui-portal-root")
		root.Parent = ownerLayerCollector

		return root
	end)

	React.useEffect(function()
		if forceInPortal or groupTarget == nil then
			return
		end

		setTarget(groupTarget.current)
	end, { groupTarget, setTarget })

	return target
end

-- Portal

local DEFAULT_PORTAL_TAG = React.Fragment

export type PortalProps = {}

local function PortalFn(props: PortalProps, ref: React.Ref<GuiObject>)
	local theirProps = props
	local internalPortalRootRef = React.useRef(nil :: GuiObject?)
	local portalRef = useSyncRefs(
		optionalRef(function(ref)
			internalPortalRootRef.current = ref
		end),
		ref
	)

	-- DEVIATION: document doesnt exist
	local ownerLayerCollector = useOwnerLayerCollector(internalPortalRootRef)
	local target = usePortalTarget(internalPortalRootRef)

	local element: GuiObject? = React.useState(function()
		if ownerLayerCollector == nil then
			return nil
		end

		local div = Instance.new("Folder")
		div.Parent = ownerLayerCollector

		return div
	end)

	local parent = React.useContext(PortalParentContext)

	React.useLayoutEffect(function()
		if not target or not element then
			return
		end

		if not contains(target, element) then
			element:SetAttribute("headlessuiportal", true)
			element.Parent = target
		end
	end, { target, element })

	React.useLayoutEffect(function()
		if not element or not parent then
			return
		end

		return parent.register(element)
	end, { parent })

	React.useEffect(function()
		return function()
			if not target or not element then
				return
			end

			if contains(target, element) then
				element:Destroy()
			end

			if #target:GetChildren() == 0 then
				target:Destroy()
			end
		end
	end, {})

	local ourProps = { ref = portalRef }

	--print(target, element)

	return if not target or not element
		then nil
		else ReactRoblox.createPortal(
			render({
				ourProps = ourProps,
				theirProps = theirProps,
				defaultTag = DEFAULT_PORTAL_TAG,
				name = "Portal",
			}),
			element
		)
end

-- Portal Grouping

local DEFAULT_GROUP_TAG = React.Fragment

PortalGroupContext = React.createContext(nil :: { current: GuiObject? }?)

export type PortalGroupProps = {
	target: { current: GuiObject? },
}

local function GroupFn(props: PortalGroupProps, ref: React.Ref<GuiObject>)
	local target = props.target
	local theirProps = Object.assign({}, props, { target = Object.None })

	local groupRef = useSyncRefs(ref)
	local ourProps = { ref = groupRef }

	return React.createElement(
		PortalGroupContext.Provider,
		{ value = target },
		render({
			ourProps = ourProps,
			theirProps = theirProps,
			defaultTag = DEFAULT_GROUP_TAG,
			name = "Portal.Group",
		})
	)
end

-- Portal Parenting

type PortalParentContext = {
	register: (portal: GuiObject) -> (),
	unregister: (portal: GuiObject) -> (),
	portals: { current: Array<GuiObject> },
}

PortalParentContext = React.createContext(nil :: PortalParentContext?)

local function useNestedPortals()
	local parent = React.useContext(PortalParentContext)
	local portals = React.useRef({} :: Array<GuiObject>)

	local unregister = useCallbackRef(function(portal: GuiObject)
		local idx = Array.indexOf(portals.current, portal)
		if idx ~= -1 then
			Array.splice(portals.current, 1)
		end

		if parent ~= nil then
			parent.unregister(portal)
		end
	end)

	local register = useCallbackRef(function(portal: GuiObject)
		table.insert(portals.current, portal)

		if parent ~= nil then
			parent.register(portal)
		end

		return function()
			unregister(portal)
		end
	end)

	local api = React.useMemo(function()
		return { register = register, unregister = unregister, portals = portals }
	end, { register, unregister, portals })

	return portals,
		React.useMemo(function()
			local function PortalWrapper(props: { children: React.ReactNode })
				local children = props.children
				return React.createElement(PortalParentContext.Provider, { value = api }, children)
			end

			return PortalWrapper
		end, { api })
end

local PortalRoot = forwardWithRefAs(PortalFn)
local Group = forwardWithRefAs(GroupFn)

return {
	Portal = PortalRoot,
	Group = Group,
	useNestedPortals = useNestedPortals,
}
