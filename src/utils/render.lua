local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object
local Array = LuauPolyfill.Array
local Boolean = LuauPolyfill.Boolean
local Error = LuauPolyfill.Error

local Features = {
	None = 0,
	RenderStrategy = 1,
	Static = 2,
}

local RenderStrategy = {
	Unmount = 0,
	Hidden = 1,
}

type RenderOptions = {
	ourProps: any,
	theirProps: any,
	slot: any,
	defaultTag: string,
	features: any,
	visible: boolean?,
	name: string,
}

local mergeProps
local mergeRefs
local _render

local function render(options: RenderOptions)
	local ourProps = options.ourProps
	local theirProps = options.theirProps
	local slot = options.slot
	local defaultTag = options.defaultTag
	local features = options.features
	local visible = if options.visible == nil then true else options.visible
	local name = options.name

	local props = mergeProps(theirProps, ourProps)

	if visible then
		return _render(props, slot, defaultTag, name)
	end

	local featureFlags = features or Features.None

	if Boolean.toJSBoolean(bit32.band(featureFlags, Features.Static)) then
		local isStatic = props.static or false
		local rest = Object.assign({}, props, { static = Object.None })

		if isStatic then
			return _render(rest, slot, defaultTag, name)
		end
	end

	if Boolean.toJSBoolean(bit32.band(featureFlags, Features.RenderStrategy)) then
		local unmount = props.unmount or true
		local rest = Object.assign({}, props, { static = Object.None })
		local strategy = if unmount then RenderStrategy.Unmount else RenderStrategy.Hidden

		if strategy == RenderStrategy.Unmount then
			return nil -- This causes nothing to be rendered
		elseif strategy == RenderStrategy.Hidden then
			-- This will render, but have the Visible property set to false.
			return _render(Object.assign({}, rest, { Visible = false }), slot, defaultTag, name)
		end
	end

	return _render(props, slot, defaultTag, name)
end

local omit

function _render(_props, slot, tag, name)
	local props = omit(_props, { "unmount", "static" })

	local Component = props.as or tag
	local children = props.children
	local refName = props.refName or "ref"
	local rest = Object.assign({}, props, {
		as = Object.None,
		children = Object.None,
		refName = Object.None,
	})

	local refRelatedProps = if props.ref ~= nil then { [refName] = props.ref } else {}
	local resolvedChildren = if typeof(children) == "function" then children(slot) else children

	if Component == React.Fragment then
		if #Object.keys(rest) > 0 then
			if
				not React.isValidElement(resolvedChildren)
				or (Array.isArray(resolvedChildren) and #resolvedChildren > 1)
			then
				error(Error.new(Array.join({
					'Passing props on "Fragment!"',
					"",
					`The current component <{name} /> is rendering a "Fragment"`,
					"However, we need to pass through the following props:",
					Array.join(
						Array.map(Object.keys(rest), function(line)
							return `  - {line}`
						end),
						"\n"
					),
					"You can apply a few solutions:",
					Array.join(
						Array.map({
							'Add an `as="..."` prop, to ensure that we render an actual element instead of a "Fragment".',
							"Render a single element as the child so that we can forward the props onto that element.",
						}, function(line)
							return `  - {line}`
						end),
						"\n"
					),
				}, "\n")))
			end

			return React.cloneElement(
				resolvedChildren,
				Object.assign(
					{},
					mergeProps(resolvedChildren.props, omit(rest, { "ref" })),
					refRelatedProps,
					mergeRefs(resolvedChildren.ref, refRelatedProps.ref)
				)
			)
		end
	end

	return React.createElement(
		Component,
		Object.assign({}, omit(rest, { "ref" }), Component ~= React.Fragment and refRelatedProps),
		resolvedChildren
	)
end

function mergeRefs(...: React.Ref<any>)
	local refs = { ... }
	return {
		ref = if Array.every(refs, function(ref)
				return ref == nil
			end)
			then nil
			else function(value: any)
				for _, ref in refs do
					if typeof(ref) == "function" then
						ref(value)
					else
						ref.current = value
					end
				end
			end,
	}
end

function mergeProps(...)
	local listOfProps = { ... }

	if #listOfProps == 0 then
		return {}
	elseif #listOfProps == 1 then
		return listOfProps[1]
	end

	local target = {}
	local eventHandlers = {}

	for _, props in listOfProps do
		for prop, value in props do
			-- Check if the prop is from React.Event or React.Change
			if string.match(tostring(prop), "RoactHost") ~= nil and typeof(value) == "function" then
				eventHandlers[prop] = eventHandlers[prop] or {}
				table.insert(eventHandlers[prop], value)
			else
				target[prop] = value
			end
		end
	end

	if target.disabled then
		return Object.assign(
			target,
			Array.map(Object.keys(eventHandlers), function(eventName)
				return { eventName, React.None }
			end)
		)
	end

	for eventName, handlers in eventHandlers do
		Object.assign(target, {
			[eventName] = function(rbx, ...)
				for _, handler in handlers do
					handler(rbx, ...)
				end
			end,
		})
	end

	return target
end

function omit(object, keys)
	local clone = table.clone(object)

	for _, key in keys do
		if clone[key] ~= nil then
			clone[key] = nil
		end
	end

	return clone
end

local function forwardWithRefAs<T>(Component: T & { name: string, displayName: string? })
	local ForwardedComponent = React.forwardRef((Component :: unknown) :: any)

	if typeof(Component) == "table" then
		ForwardedComponent.displayName = Component.displayName or Component.name
	end

	return ForwardedComponent
end

return {
	render = render,
	forwardWithRefAs = forwardWithRefAs,
	Features = Features,
}
