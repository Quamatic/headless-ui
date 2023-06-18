local src = script.Parent.Parent.Parent
local React = require(src.React)

local useCallbackRef = require(script.Parent.useCallbackRef)

type UseUncontrolledStateParams<T> = {
	onChange: ((state: T) -> ())?,
	defaultProp: T?,
}

type UseControllableStateParams<T> = UseUncontrolledStateParams<T> & {
	prop: T?,
}

type SetStateFn<T> = (prevState: T?) -> T

local function noop() end

local function useUncontrolledState<T>(props: UseUncontrolledStateParams<T>)
	local defaultProp = props.defaultProp
	local onChange = props.onChange

	local value, setUncontrolledState = React.useState(defaultProp :: T?)
	local prevValueRef = React.useRef(value)
	local handleChange = useCallbackRef(onChange)

	React.useEffect(function()
		if prevValueRef.current ~= value then
			handleChange(value :: T)
			prevValueRef.current = value
		end
	end, { value, prevValueRef, handleChange })

	return value :: T, setUncontrolledState
end

local function useControllableState<T>(props: UseControllableStateParams<T>)
	local prop = props.prop
	local defaultProp = props.defaultProp
	local onChange = props.onChange or noop

	local uncontrolledProp, setUncontrolledProp = useUncontrolledState({
		defaultProp = defaultProp,
		prop = prop,
	})

	local isControlled = prop ~= nil
	local value = if isControlled then prop else uncontrolledProp
	local handleChange = useCallbackRef(onChange)

	local setValue = React.useCallback(function(nextValue: T | SetStateFn<T>)
		if isControlled then
			local value_ = if type(nextValue) == "function" then nextValue(prop) else nextValue

			if value_ ~= prop then
				handleChange(value_ :: T)
			end
		else
			print("A")
			setUncontrolledProp(nextValue)
		end
	end, { isControlled, prop, setUncontrolledProp, handleChange })

	return value, setValue
end

return useControllableState
