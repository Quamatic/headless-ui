local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object

local _render = require(src.ReactHeadless.utils.render)
local render = _render.render
local forwardWithRefAs = _render.forwardWithRefAs

local useCallbackRef = require(src.ReactHeadless.hooks.useCallbackRef)
local useControllableState = require(src.ReactHeadless.hooks.useControllableState)
local useSyncRefs = require(src.ReactHeadless.hooks.useSyncRefs).useSyncRefs

local DEFAULT_SWITCH_TAG = "ImageButton"

type RobloxButtonElement = TextButton | ImageButton

--[=[
    @interface SwitchProps
]=]
type SwitchProps = {
	checked: boolean?,
	defaultChecked: boolean?,
	onChange: ((checked: boolean) -> ())?,
}

--[=[
    @tag ButtonElement
]=]
local function SwitchFn(props: SwitchProps, ref: React.Ref<RobloxButtonElement>)
	local controlledChecked = props.checked
	local defaultChecked = props.defaultChecked or false
	local controlledOnChange = props.onChange
	local theirProps = Object.assign({}, props, {
		checked = Object.None,
		defaultChecked = Object.None,
		onChange = Object.None,
	})

	local internalSwitchRef = React.useRef(nil :: RobloxButtonElement?)
	local switchRef = useSyncRefs(ref, internalSwitchRef)

	local checked, onChange = useControllableState({
		prop = controlledChecked,
		defaultProp = defaultChecked,
		onChange = controlledOnChange,
	})

	local toggle = useCallbackRef(function()
		onChange(not checked)
	end)

	local slot = React.useMemo(function()
		return { checked = checked }
	end, { checked })

	local ourProps = {
		ref = switchRef,
		[React.Event.Activated] = toggle,
	}

	return render({
		ourProps = ourProps,
		theirProps = theirProps,
		slot = slot,
		defaultTag = DEFAULT_SWITCH_TAG,
		name = "Switch",
	})
end

local SwitchRoot = forwardWithRefAs(SwitchFn)

return SwitchRoot
