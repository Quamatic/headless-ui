local GuiService = game:GetService("GuiService")

local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object
local Array = LuauPolyfill.Array

type Array<T> = LuauPolyfill.Array<T>

local match = require(src.ReactHeadless.utils.match)
local createContext = require(src.ReactHeadless.utils.createContext)
local _render = require(src.ReactHeadless.utils.render)
local render = _render.render
local forwardWithRefAs = _render.forwardWithRefAs

local useCallbackRef = require(src.ReactHeadless.hooks.useCallbackRef)
local useControllableState = require(src.ReactHeadless.hooks.useControllableState)
local useFlags = require(src.ReactHeadless.hooks.useFlags)
local useLatestValue = require(src.ReactHeadless.hooks.useLatestValue)
local useSyncRefs = require(src.ReactHeadless.hooks.useSyncRefs)

-- Types

type Option<T = unknown> = {
	id: string,
	element: { current: GuiObject? },
	propsRef: { current: { value: T, disabled: boolean } },
}

type StateDefinition<T = unknown> = {
	options: Array<Option<T>>,
}

type ActionType = "REGISTER_OPTION" | "UNREGISTER_OPTION"
type RegisterOptionAction = { type: "REGISTER_OPTION" } & Option
type UnregisterOptionAction = { type: "UNREGISTER_OPTION", id: string }
type Actions = RegisterOptionAction | UnregisterOptionAction

-- State reducers
local reducers: {
	[ActionType]: (state: StateDefinition, action: Actions) -> StateDefinition,
} = {
	REGISTER_OPTION = function(state: StateDefinition, action: RegisterOptionAction)
		local nextOptions = Object.assign({}, state.options)
		table.insert(nextOptions, { id = action.id, element = action.element, propsRef = action.propsRef })

		return Object.assign({}, state, {
			options = nextOptions,
		})
	end,

	UNREGISTER_OPTION = function(state: StateDefinition, action: UnregisterOptionAction)
		local options = Array.slice(state.options)
		local idx = Array.findIndex(state.options, function(radio)
			return radio.id == action.id
		end)

		if idx == -1 then
			return state
		end

		Array.splice(options, 1)
		return Object.assign({}, state, options)
	end,
}

type RadioDataGroupContext = {
	value: unknown,
	firstOption: Option?,
	containsCheckedOption: boolean,
	disabled: boolean,
	compare: (a: unknown, z: unknown) -> boolean,
} & StateDefinition

local RadioGroupDataProvider, useData = createContext({
	name = "RadioDataGroupContext",
	rootComponentName = "RadioGroup",
})

type RadioGroupActionsContext = {
	registerOption: (option: Option) -> () -> (),
	change: (value: unknown) -> boolean,
}

local RadioGroupActionsProvider, useActions = createContext({
	name = "RadioGroupActionsContext",
	rootComponentName = "RadioGroup",
})

local function reducer<T>(state: StateDefinition<T>, action: Actions)
	return match(action.type, reducers, state, action)
end

local DEFAULT_RADIO_GROUP_TAG = React.Fragment

--[=[
    @interface RadioGroupProps
]=]
export type RadioGroupProps<T = string> = {
	value: T?,
	defaultValue: T?,
	onChange: ((value: T) -> ())?,
	by: (T & string) | ((a: T, b: T) -> boolean)?,
	disabled: boolean?,
	name: string?,
}

--[=[
    @within Components
    @function RadioGroup
    @tag Contextable
]=]
local function RadioGroupFn<T>(props: RadioGroupProps<T>, ref: React.Ref<GuiObject>)
	local controlledValue = props.value
	local defaultValue = props.defaultValue
	local controlledOnChange = props.onChange
	local by = props.by or function(a: T, b: T)
		return a == b
	end
	local disabled = props.disabled or false
	local theirProps = Object.assign({}, props, {
		value = Object.None,
		defaultValue = Object.None,
		onChange = Object.None,
		by = Object.None,
		disabled = Object.None,
		name = Object.None,
	})

	local compare = useCallbackRef(if typeof(by) == "string"
		then function(a: T, z: T)
			local property = (by :: unknown) :: T
			return (a :: any)[property] == (z :: any)[property]
		end
		else by)

	local state, dispatch = React.useReducer(reducer, { options = {} } :: StateDefinition<T>)
	local options = state.options :: Array<Option<T>>

	local value, onChange = useControllableState({
		prop = controlledValue,
		defaultProp = defaultValue,
		onChange = controlledOnChange,
	})

	local firstOption = React.useMemo(function()
		return Array.find(options, function(option)
			return not option.propsRef.current.disabled
		end)
	end, { options })

	local containsCheckedOption = React.useMemo(function()
		return Array.some(options, function(option)
			return compare(option.propsRef.current.value :: T, value)
		end)
	end, { options, value })

	local triggerChange = useCallbackRef(function(nextValue: T)
		if disabled then
			return false
		end

		if compare(nextValue, value) then
			return false
		end

		local nextOption = (Array.find(options, function(option)
			return compare(option.propsRef.current.value :: T, nextValue)
		end) or {}).propsRef.current

		if nextOption ~= nil and nextOption.disabled then
			return false
		end

		onChange(nextValue)

		return true
	end)

	local registerOption = useCallbackRef(function(option: Option)
		dispatch(Object.assign({ type = "REGISTER_OPTION" }, option))
		return function()
			dispatch({ type = "UNREGISTER_OPTION", id = option.id })
		end
	end)

	local radioGroupData = React.useMemo(function()
		return Object.assign({
			value = value,
			firstOption = firstOption,
			containsCheckedOption = containsCheckedOption,
			disabled = disabled,
			compare = compare,
		}, state)
	end, { value, firstOption, containsCheckedOption, disabled, compare, state })

	local radioGroupActions = React.useMemo(function()
		return {
			registerOption = registerOption,
			change = triggerChange,
		}
	end, { registerOption, triggerChange })

	local slot = React.useMemo(function()
		return { value = value }
	end, { value })

	local ourProps = {
		ref = ref,
	}

	return React.createElement(
		RadioGroupActionsProvider,
		radioGroupActions,
		React.createElement(
			RadioGroupDataProvider,
			radioGroupData,
			render({
				ourProps = ourProps,
				theirProps = theirProps,
				slot = slot,
				defaultTag = DEFAULT_RADIO_GROUP_TAG,
				name = "RadioGroup",
			})
		)
	)
end

local OptionState = {
	Empty = bit32.lshift(1, 0),
	Active = bit32.lshift(1, 1),
}

local DEFAULT_OPTION_TAG = React.Fragment

type RadioOptionProps = {
	id: string,
	value: string,
	disabled: boolean?,
}

--[=[
    @within Components
    @function RadioGroup
    @tag Contextable
]=]
local function OptionFn(props: RadioOptionProps, ref: React.Ref<GuiObject>)
	local id = `headless-radiogroup-option-{props.id}`
	local value = props.value
	local disabled = props.disabled or false
	local theirProps = Object.assign({}, props, {
		id = Object.None,
		value = Object.None,
		disabled = Object.None,
	})

	local flags = useFlags(OptionState.Empty)

	local internalOptionRef = React.useRef(nil :: GuiObject?)
	local optionRef = useSyncRefs(internalOptionRef, ref)

	local propsRef = useLatestValue({ value = value, disabled = disabled })
	local data = useData("RadioGroup.Option") :: RadioDataGroupContext
	local actions = useActions("RadioGroup.Option") :: RadioGroupActionsContext

	React.useLayoutEffect(function()
		return actions.registerOption({ id = id, element = internalOptionRef, propsRef = propsRef })
	end, { id, actions, internalOptionRef, props })

	local handleClick = useCallbackRef(function()
		if not actions.change(value) then
			return
		end

		if internalOptionRef.current then
			pcall(GuiService.Select, GuiService, internalOptionRef.current)
		end
	end)

	local handleFocus = useCallbackRef(function()
		flags.addFlag(OptionState.Active)
	end)

	local handleBlur = useCallbackRef(function()
		flags.removeFlag(OptionState.Active)
	end)

	local isFirstOption = data.firstOption ~= nil and data.firstOption.id == id
	local isDisabled = data.disabled or disabled

	local checked = data.compare(data.value, value)
	local ourProps = {
		ref = optionRef,
		Selectable = (function()
			if isDisabled then
				return false
			end

			return checked or (data.containsCheckedOption and isFirstOption)
		end)(), -- Disable selectability for gamepads
		NextSelectionUp = nil,
		NextSelectionDown = nil, -- TODO: can selection groups support roving focus?
		[React.Event.Activated] = if isDisabled then nil else handleClick,
		[React.Event.SelectionGained] = if isDisabled then nil else handleFocus,
		[React.Event.SelectionLost] = if isDisabled then nil else handleBlur,
	}

	local slot = React.useMemo(function()
		return {
			checked = checked,
			disabled = isDisabled,
			active = flags.hasFlag(OptionState.Active),
		}
	end, { checked, isDisabled, flags.hasFlag })

	return render({
		ourProps = ourProps,
		theirProps = theirProps,
		slot = slot,
		defaultTag = DEFAULT_OPTION_TAG,
		name = "RadioGroup.Option",
	})
end

local RadioGroupRoot = forwardWithRefAs(RadioGroupFn)
local Option = forwardWithRefAs(OptionFn)

return Object.assign(RadioGroupRoot, {
	Option = Option,
})
