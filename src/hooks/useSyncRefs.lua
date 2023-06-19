local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local Symbol = LuauPolyfill.Symbol

local useCallbackRef = require(script.Parent.useCallbackRef)

local Optional = Symbol("Optional")

local optionalRefs = {}

local function optionalRef<T>(cb: (ref: T) -> (), isOptional: boolean?)
	if isOptional == nil then
		isOptional = true
	end

	optionalRefs[cb] = true

	return cb
end

local function useSyncRefs<T>(...: React.Ref<T>)
	local refs = { ... }
	local cache = React.useRef(refs)

	React.useEffect(function()
		cache.current = refs
	end, { refs })

	local syncRefs = useCallbackRef(function(value: T)
		for _, ref in cache.current do
			if type(ref) == "function" then
				ref(value)
			else
				ref.current = value
			end
		end
	end)

	return if Array.every(refs, function(ref)
			return ref == nil or optionalRefs[ref] ~= nil
		end)
		then nil
		else syncRefs
end

return {
	useSyncRefs = useSyncRefs,
	optionalRef = optionalRef,
}
