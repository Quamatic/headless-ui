local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object

local useCallbackRef = require(src.ReactHeadless.hooks.useCallbackRef)
local useControllableState = require(src.ReactHeadless.hooks.useControllableState)
local useSyncRefs = require(src.ReactHeadless.hooks.useSyncRefs).useSyncRefs

local createContext = require(src.ReactHeadless.utils.createContext)

local _render = require(src.ReactHeadless.utils.render)
local render = _render.render
local forwardWithRefAs = _render.forwardWithRefAs
local Features = _render.Features

local function isIndeterminate(checked: CheckedState?)
	return checked == "indeterminate"
end

type CheckboxDataContext = {
	state: CheckedState,
	disabled: boolean,
}

local CheckboxDataProvider, useData = createContext({
	name = "CheckboxDataContext",
	rootComponentName = "Checkbox",
})

-- Checkbox START

local DEFAULT_CHECKBOX_TAG = "ImageButton"

type CheckedState = boolean | "indeterminate"

type CheckboxProps = {
	checked: CheckedState?,
	defaultChecked: CheckedState?,
	onChange: ((checked: CheckedState) -> ())?,
}

local function CheckboxFn(props: CheckboxProps, ref: React.Ref<TextButton>)
	local controlledChecked = props.checked
	local defaultChecked = props.defaultChecked
	local controlledOnChange = props.onChange
	local theirProps = Object.assign({}, props, {
		checked = Object.None,
		defaultChecked = Object.None,
		onChange = Object.None,
	})

	local checkboxRef = useSyncRefs(ref)
	local checked, setChecked = useControllableState({
		prop = controlledChecked,
		defaultProp = defaultChecked,
		onChange = controlledOnChange,
	})

	local toggle = useCallbackRef(function()
		setChecked(if isIndeterminate(checked) then true else not checked)
	end)

	local data = React.useMemo(function()
		return { state = checked, disabled = false }
	end, { checked })

	local slot = React.useMemo(function()
		return { checked = checked }
	end, { checked })

	local ourProps = {
		ref = checkboxRef,
		Selectable = true,
		[React.Event.Activated] = toggle,
	}

	return React.createElement(
		CheckboxDataProvider,
		data,
		render({
			ourProps = ourProps,
			theirProps = theirProps,
			slot = slot,
			defaultTag = DEFAULT_CHECKBOX_TAG,
			name = "Checkbox",
		})
	)
end

-- Checkbox END

-- Indicator START

local DEFAULT_INDICATOR_TAG = "ImageLabel"

local CheckboxIndicatorFeatures = bit32.bor(Features.RenderStrategy, Features.Static)

type CheckboxIndicatorProps = {}

local function IndicatorFn(props, ref)
	local theirProps = props

	local data = useData("Checkbox.Indicator") :: CheckboxDataContext
	local visible = isIndeterminate(data.state) or data.state == true

	local slot = React.useMemo(function()
		return { checked = visible }
	end, { visible })

	local ourProps = {
		ref = ref,
		Active = false,
	}

	return render({
		ourProps = ourProps,
		theirProps = theirProps,
		slot = slot,
		defaultTag = DEFAULT_INDICATOR_TAG,
		features = CheckboxIndicatorFeatures,
		visible = visible,
		name = "Checkbox.Indicator",
	})
end

-- Indicator END

local CheckboxRoot = forwardWithRefAs(CheckboxFn)
local Indicator = forwardWithRefAs(IndicatorFn)

return Object.assign(CheckboxRoot, {
	Indicator = Indicator,
})
