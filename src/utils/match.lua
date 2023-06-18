local src = script.Parent.Parent.Parent
local LuauPolyfill = require(src.LuauPolyfill)
local Error = LuauPolyfill.Error
local Object = LuauPolyfill.Object
local Array = LuauPolyfill.Array

local function match<T, R>(value: T, lookup: { [T]: R | ((...any) -> R) }, ...): R
	if lookup[value] ~= nil then
		local returnValue = lookup[value]
		return if typeof(returnValue) == "function" then returnValue(...) else returnValue
	end

	local problem = Error.new(
		`Tried to handle "{value}" but there is no handler defined. Only defined handlers are: {Array.join(
			Array.map(Object.keys(lookup), function(key)
				return `"{key}"`
			end),
			", "
		)}`
	)

	Error.captureStackTrace(problem, match)

	error(problem)
end

return match
