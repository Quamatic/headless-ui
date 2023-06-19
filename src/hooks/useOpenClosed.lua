local src = script.Parent.Parent.Parent
local React = require(src.React)

local State = {
	Open = bit32.lshift(1, 0),
	Closed = bit32.lshift(1, 1),
	Closing = bit32.lshift(1, 2),
	Opening = bit32.lshift(1, 3),
}

export type State = typeof(State)

local Context = React.createContext(nil :: State?)
Context.displayName = "OpenClosedContext"

local function useOpenClosed()
	return React.useContext(Context)
end

local function OpenClosedProvider(props: { value: State, children: React.ReactNode })
	return React.createElement(Context.Provider, { value = props.value }, props.children)
end

return {
	State = State,
	useOpenClosed = useOpenClosed,
	OpenClosedProvider = OpenClosedProvider,
}
