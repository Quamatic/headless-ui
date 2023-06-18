local src = script.Parent.Parent.Parent
local React = require(src.React)

local function useCallbackRef<T>(callback: T?): T
	local callbackRef = React.useRef(callback)

	React.useEffect(function()
		callbackRef.current = callback
	end)

	return React.useMemo(function()
		return function(...)
			return callbackRef.current and callbackRef.current(...)
		end
	end, {}) :: T
end

return useCallbackRef
