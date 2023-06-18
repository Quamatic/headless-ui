local src = script.Parent.Parent.Parent
local React = require(src.React)

local function useLatestValue<T>(value: T)
	local ref = React.useRef(value)

	React.useEffect(function()
		ref.current = value
	end, { value })

	return ref
end

return useLatestValue
