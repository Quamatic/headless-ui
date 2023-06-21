local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object
local Array = LuauPolyfill.Array
local Set = LuauPolyfill.Set

type Set<T> = LuauPolyfill.Set<T>
type Array<T> = LuauPolyfill.Array<T>

local useControllableState = require(src.ReactHeadless.hooks.useControllableState)
local useCallbackRef = require(src.ReactHeadless.hooks.useCallbackRef)
local useSyncRefs = require(src.ReactHeadless.hooks.useSyncRefs).useSyncRefs

local createContext = require(src.ReactHeadless.utils.createContext)
local getBoundingClientRect = require(src.ReactHeadless.utils.getBoundingClientRect)

local _render = require(src.ReactHeadless.utils.render)
local render = _render.render
local forwardWithRefAs = _render.forwardWithRefAs

local PAGE_KEYS = { Enum.KeyCode.PageUp, Enum.KeyCode.PageDown }
local ARROW_KEYS = { Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Right, Enum.KeyCode.Left }

-- TODO: use this later in order to be more like the style of Headless
local SliderOrientation = {
	Horizontal = bit32.lshift(1, 0),
	Vertical = bit32.lshift(1, 1),
}

-- Slider utilities

local function getNextSortedValues(prevValues: Array<number>?, nextValue: number, atIndex: number)
	if prevValues == nil then
		prevValues = {}
	end

	-- Luau FIXME: type checker does not understand that prevValues cannot be nil here
	local nextValues = table.clone(prevValues :: Array<number>)
	nextValues[atIndex] = nextValue

	return Array.sort(nextValues, function(a, b)
		return a - b
	end)
end

local function convertValueToPercentage(value: number, min: number, max: number)
	local maxSteps = max - min
	local percentPerStep = 100 / maxSteps
	local percentage = percentPerStep * (value - min)
	return math.clamp(percentage, 0, 100)
end

--[[
	Gets an array of steps between each value.
]]
local function getStepsBetweenValues(values: Array<number>)
	-- DEVIATION: can't do slice(values, 0, -1) here
	return Array.map(Array.slice(values, 1, #values), function(value, index)
		return values[index + 1] - value
	end)
end

--[[
 	Verifies the minimum steps between all values is greater than or equal
	to the expected minimum steps.
]]
local function hasMinStepsBetweenValues(values: Array<number>, minStepsBetweenValues: number)
	if minStepsBetweenValues > 0 then
		local stepsBetweenValues = getStepsBetweenValues(values)
		local actualMinStepsBetweenValues = math.min(unpack(stepsBetweenValues))
		return actualMinStepsBetweenValues >= minStepsBetweenValues
	end
	return true
end

-- https://github.com/tmcw-up-for-adoption/simple-linear-scale/blob/master/index.js
local function linearScale(input: Array<number>, output: Array<number>)
	return function(value: number)
		local inputMin, inputMax = input[1], input[2]
		local outputMin, outputMax = output[1], output[2]

		if inputMin == inputMax or outputMin == outputMax then
			return outputMin
		end

		local ratio = (outputMax - outputMin) / (inputMax - inputMin)
		return outputMin + ratio * (value - inputMin)
	end
end

--[[
    Given a `values` array and a `nextValue`, determine which value in
    the array is closest to `nextValue` and return its index.

    @example
    ```lua
    -- returns 1
    getClosestValueIndex({10, 30}, 25)
    ```
]]
local function getClosestValueIndex(values: Array<number>, nextValue: number)
	if #values == 1 then
		return 1 -- Shorthand optimization
	end

	local distances = Array.map(values, function(value)
		return math.abs(value - nextValue)
	end)

	local closestDistance = math.min(unpack(distances))
	return Array.indexOf(distances, closestDistance)
end

--[[
    Offsets the thumb centre point while sliding to ensure it remains
    within the bounds of the slider when reaching the edges
]]
local function getThumbInBoundsOffset(width: number, left: number, direction: number)
	local halfWidth = width / 2
	local halfPercent = 50
	local offset = linearScale({ 0, halfPercent }, { 0, halfWidth })
	return (halfWidth - offset(left) * direction) * direction
end

local function getDecimalCount(value: number)
	return string.len(string.split(tostring(value), ".")[2] or "")
end

local function roundValue(value: number, decimalCount: number)
	local rounder = 10 ^ decimalCount
	return math.round(value * rounder) / rounder
end

-- Data context
type SliderDataContext = {
	min: number,
	max: number,
	disabled: number,
	values: Array<number>,
	thumbs: Array<Frame>,
	orientation: "horizontal" | "vertical",
}

local SliderDataProvider, useData = createContext({
	name = "SliderDataContext",
	rootComponentName = "Slider",
})

-- Actions context
type SliderActionsContext = {}

local SliderActionsProvider, useActions = createContext({
	name = "SliderActionsContext",
	rootComponentName = "Slider",
})

local DEFAULT_SLIDER_TAG = "Frame"

--[=[
    @interface SliderProps
]=]
export type SliderProps = {
	value: Array<number>?,
	defaultValue: Array<number>?,
	min: number?,
	max: number?,
	step: number?,
	disabled: boolean?,
	orientation: "horizontal" | "vertical"?,
	minStepsBetweenThumbs: number?,
	onValueChange: ((value: Array<number>) -> ())?,
	onValueCommit: ((value: Array<number>) -> ())?,
}

local function noop() end

local function SliderFn(props: SliderProps, ref: React.Ref<GuiObject>)
	local min = props.min or 0
	local max = props.max or 100
	local step = props.step or 1
	local orientation = props.orientation or "horizontal"
	local disabled = props.disabled or false
	local minStepsBetweenThumbs = props.minStepsBetweenThumbs or 0
	local defaultValue = props.defaultValue or { min }
	local value = props.value
	local onValueChange = props.onValueChange or noop
	local onValueCommit = props.onValueCommit or noop
	local theirProps = Object.assign({}, props, {
		min = Object.None,
		max = Object.None,
		step = Object.None,
		orientation = Object.None,
		disabled = Object.None,
		minStepsBetweenThumbs = Object.None,
		defaultValue = Object.None,
		value = Object.None,
		onValueChange = Object.None,
		onValueCommit = Object.None,
	})

	local internalSliderRef = React.useRef(nil :: GuiObject?)
	local sliderRef = useSyncRefs(ref, internalSliderRef)
	local thumbsRef = React.useRef(Set.new() :: Set<GuiObject>)

	local dragging, setDragging = React.useState(false)
	local valueIndexToChangeRef = React.useRef(1)

	local values, setValues = useControllableState({
		prop = value,
		defaultProp = defaultValue,
		onChange = onValueChange,
	})

	local valuesBeforeSliderStartRef = React.useRef(values)

	-- Returns the relative position to the slider from the client's given pointer.
	local getValueFromPointer = useCallbackRef(function(position: Vector3)
		if not internalSliderRef.current then
			return 0 -- TODO: more elegant approach?
		end

		local axis = if orientation == "horizontal" then position.X else position.Y
		local rect = getBoundingClientRect(internalSliderRef.current)
		local input = { 0, if orientation == "horizontal" then rect.width else rect.height }
		local output = if orientation == "horizontal" then { min, max } else { max, min }
		local value = linearScale(input, output)
		local dimension = if orientation == "horizontal" then rect.left else rect.top

		return value(axis - dimension)
	end)

	local updateValues = useCallbackRef(function(value: number, atIndex: number, commit: boolean?)
		if commit == nil then
			commit = false
		end

		local decimalCount = getDecimalCount(value)
		local snapToStep = roundValue(math.round((value - min) / step) * step + min, decimalCount)
		local nextValue = math.clamp(snapToStep, min, max)

		setValues(function(prevValues)
			if prevValues == nil then
				prevValues = {}
			end

			local nextValues = getNextSortedValues(prevValues, nextValue, atIndex)
			if hasMinStepsBetweenValues(values, minStepsBetweenThumbs * step) then
				valueIndexToChangeRef.current = Array.indexOf(nextValues, nextValue)

				local hasChanged = nextValues ~= prevValues
				if hasChanged and commit then
					onValueCommit(nextValues)
				end

				return if hasChanged then nextValues else prevValues
			else
				return prevValues
			end
		end)
	end)

	local handleInputBegan = useCallbackRef(function(_, input: InputObject)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if Array.includes(Array.concat(PAGE_KEYS, ARROW_KEYS), input.KeyCode) then
				local isPageKey = Array.includes(PAGE_KEYS, input.KeyCode)
				local isSkipKey = isPageKey
					or (input:IsModifierKeyDown(Enum.ModifierKey.Shift) and Array.includes(ARROW_KEYS, input.KeyCode))
				local direction = if Array.includes({ Enum.KeyCode.Down, Enum.KeyCode.Left }, input.KeyCode)
					then -1
					else 1 -- TODO: change

				local multiplier = if isSkipKey then 10 else 1
				local atIndex = valueIndexToChangeRef.current
				local value = values[atIndex]
				local stepInDirection = step * multiplier * direction

				updateValues(value + stepInDirection, atIndex, true)
			elseif input.KeyCode == Enum.KeyCode.Home then
				updateValues(min, 1, true) -- Set to the minimum value
			elseif input.KeyCode == Enum.KeyCode.End then
				updateValues(max, #values, true) -- Set to the max value
			end
		elseif
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if dragging then
				return
			end

			local value = getValueFromPointer(input.Position)
			local closestIndex = getClosestValueIndex(values, value)

			setDragging(true)
			updateValues(value, closestIndex)
		end
	end)

	local handleInputChanged = useCallbackRef(function(_, input: InputObject)
		if
			input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if not dragging then
			return
		end

		local value = getValueFromPointer(input.Position)
		updateValues(value, valueIndexToChangeRef.current)
	end)

	local handleInputEnded = useCallbackRef(function(_, input: InputObject)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if not dragging then
			return
		end

		local prevValue = valuesBeforeSliderStartRef.current[valueIndexToChangeRef.current]
		local nextValue = values[valueIndexToChangeRef.current]

		if prevValue ~= nextValue then
			onValueCommit(values)
		end

		setDragging(false)
	end)

	-- TODO
	local setSliderValue = useCallbackRef(function(value: Array<number>) end)

	local actions = React.useMemo(function()
		return { setSliderValue = setSliderValue }
	end, {})

	local data = React.useMemo(function()
		return {
			min = min,
			max = max,
			values = values,
			disabled = disabled,
			thumbs = thumbsRef.current,
			orientation = orientation,
		}
	end, { min, max, values, disabled, thumbsRef, orientation })

	local slot = React.useMemo(function()
		return {
			disabled = disabled,
			dragging = dragging,
		}
	end, { disabled, dragging })

	local ourProps = {
		ref = sliderRef,
		Selectable = false,
		[React.Event.InputBegan] = handleInputBegan,
		[React.Event.InputChanged] = handleInputChanged,
		[React.Event.InputEnded] = handleInputEnded,
	}

	return React.createElement(
		SliderDataProvider,
		data,
		React.createElement(
			SliderActionsProvider,
			actions,
			render({
				ourProps = ourProps,
				theirProps = theirProps,
				slot = slot,
				defaultTag = DEFAULT_SLIDER_TAG,
				name = "Slider",
			})
		)
	)
end

local DEFAULT_THUMB_TAG = "Frame"

--[=[
    @interface SliderThumbProps
]=]
export type SliderThumbProps = {
	index: number,
}

local function ThumbFn(props: SliderThumbProps, ref: React.Ref<Frame>)
	local index = props.index
	local theirProps = Object.assign({}, props, { index = Object.None })

	local internalThumbRef = React.useRef(nil :: Frame?)
	local thumbRef = useSyncRefs(ref, internalThumbRef)
	local data = useData("Slider.Thumb")
	local actions = useActions("Slider.Thumb")

	local size = if internalThumbRef.current then internalThumbRef.current.AbsoluteSize else Vector2.zero
	local value = data.values[index] :: number?
	local percent = if value == nil then 0 else convertValueToPercentage(value, data.min, data.max)
	local thumbInBoundsOffset = getThumbInBoundsOffset(size.X, percent, 1)

	React.useEffect(function()
		if not internalThumbRef.current then
			return
		end

		data.thumbs:add(internalThumbRef.current)

		return function()
			data.thumbs:delete(internalThumbRef.current)
		end
	end, { data.thumbs, internalThumbRef })

	local slot = React.useMemo(function()
		return { percent = percent }
	end, { percent })

	local ourProps = {
		ref = thumbRef,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(percent / 100, thumbInBoundsOffset, 0.5, 0),
		Selectable = not data.disabled,
	}

	return render({
		ourProps = ourProps,
		theirProps = theirProps,
		slot = slot,
		defaultTag = DEFAULT_THUMB_TAG,
		name = "Slider.Thumb",
	})
end

local DEFAULT_TRACK_TAG = "Frame"

--[=[
    @interface SliderTrackProps
]=]
export type SliderTrackProps = {}

--[=[
    The track part of the slider. 
]=]
local function TrackFn(props: SliderTrackProps, ref: React.Ref<Frame>)
	local theirProps = props
	local ourProps = { ref = ref }

	return render({
		ourProps = ourProps,
		theirProps = theirProps,
		defaultTag = DEFAULT_TRACK_TAG,
		name = "Slider.Track",
	})
end

local DEFAULT_RANGE_TAG = "Frame"

--[=[
    @interface SliderRangeProps
]=]
export type SliderRangeProps = {}

--[=[
    The range part of the slider. Must live inside `<Slider.Track />`
]=]
local function RangeFn(props: SliderRangeProps, ref: React.Ref<Frame>)
	local theirProps = props
	local data = useData("Slider.Range")

	local internalRangeRef = React.useRef(nil :: Frame?)
	local rangeRef = useSyncRefs(ref, internalRangeRef)

	local valuesCount = #data.values
	local percentages = Array.map(data.values, function(value)
		return convertValueToPercentage(value, data.min, data.max)
	end)

	local offsetStart = if valuesCount > 1 then math.min(unpack(percentages)) else 0
	local offsetEnd = (100 - math.max(unpack(percentages))) * -1

	local ourProps = {
		ref = rangeRef,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(offsetEnd / 100, 0),
	}

	return render({
		ourProps = ourProps,
		theirProps = theirProps,
		defaultTag = DEFAULT_RANGE_TAG,
		name = "Slider.Range",
	})
end

local SliderRoot = forwardWithRefAs(SliderFn)
local Thumb = forwardWithRefAs(ThumbFn)
local Track = forwardWithRefAs(TrackFn)
local Range = forwardWithRefAs(RangeFn)

return Object.assign(SliderRoot, {
	Thumb = Thumb,
	Track = Track,
	Range = Range,
})
