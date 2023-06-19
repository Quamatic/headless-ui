local src = script.Parent.Parent.Parent
local React = require(src.React)

local useCallbackRef = require(src.ReactHeadless.hooks.useCallbackRef)

local StackMessage = {
	Add = 0,
	Remove = 1,
}

type StackMessage = typeof(StackMessage)
type OnUpdate = (message: StackMessage, type: string, element: { current: GuiObject? }) -> ()

local StackContext = React.createContext(function() end :: OnUpdate)
StackContext.displayName = "StackContext"

local function useStackContext()
	return React.useContext(StackContext)
end

local function StackProvider(props: {
	children: React.ReactNode,
	onUpdate: OnUpdate?,
	type: string,
	element: { current: GuiObject? },
	enabled: boolean?,
})
	local enabled = props.enabled
	local element = props.element
	local type_ = props.type
	local onUpdate = props.onUpdate
	local children = props.children

	local parentOnUpdate = useStackContext()

	local notify = useCallbackRef(function(...)
		if onUpdate ~= nil then
			onUpdate(...)
		end

		parentOnUpdate(...)
	end)

	React.useLayoutEffect(function()
		local shouldNotify = enabled == nil or enabled == true
		if shouldNotify then
			notify(StackMessage.Add, type_, element)
		end

		return function()
			if shouldNotify then
				notify(StackMessage.Remove, type_, element)
			end
		end
	end, { notify, type_, element, enabled })

	return React.createElement(StackContext.Provider, { value = notify }, children)
end

return {
	useStackContext = useStackContext,
	StackProvider = StackProvider,
	StackMessage = StackMessage,
}
