local UserInputService = game:GetService("UserInputService")

local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Array = LuauPolyfill.Array
local Set = LuauPolyfill.Set
local instanceof = LuauPolyfill.instanceof

type Array<T> = LuauPolyfill.Array<T>
type Set<T> = LuauPolyfill.Set<T>

type Container = { current: GuiObject } | GuiObject | nil
type ContainerCollection = Array<Container> | Set<Container>
type ContainerInput = Container | ContainerCollection

local function contains(object: GuiObject, position: Vector3)
	return object.AbsolutePosition.X <= position.X
		and object.AbsolutePosition.Y <= position.Y
		and object.AbsolutePosition.X + object.AbsoluteSize.X >= position.X
		and object.AbsolutePosition.Y + object.AbsoluteSize.Y >= position.Y
end

local function useOutsideClick(
	containers: ContainerInput | (() -> ContainerInput),
	handler: (input: InputObject) -> (),
	enabled: boolean?
)
	if enabled == nil then
		enabled = true
	end

	local function handleOutsideClick(input: InputObject)
		if not enabled then
			return
		end

		local _containers = (function()
			if type(containers) == "function" then
				return containers()
			end

			if Array.isArray(containers) then
				return containers
			end

			if instanceof(containers, Set) then
				return containers
			end

			return { containers }
		end)()

		local position = input.Position

		for _, container in _containers do
			local node = if typeof(container) == "Instance" and container:IsA("GuiObject")
				then container
				else container.current
			if contains(node, position) then
				return
			end
		end

		return handler(input)
	end

	React.useEffect(function()
		local connection = UserInputService.InputBegan:Connect(function(input)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			handleOutsideClick(input)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})
end

return useOutsideClick
