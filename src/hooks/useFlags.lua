local src = script.Parent.Parent.Parent
local React = require(src.React)
local Boolean = require(src.LuauPolyfill).Boolean

local function useFlags(initialFlags: number?)
	initialFlags = initialFlags or 0

	local flags, setFlags = React.useState(initialFlags)

	local addFlag = React.useCallback(function(flag: number)
		setFlags(function(flags)
			return bit32.bor(flags, flag)
		end)
	end, { flags })

	local hasFlag = React.useCallback(function(flag: number)
		return Boolean.toJSBoolean(bit32.band(flags, flag))
	end, { flags })

	local removeFlag = React.useCallback(function(flag: number)
		setFlags(function(flags)
			return bit32.band(flags, bit32.bnot(flag))
		end)
	end, { setFlags })

	local toggleFlag = React.useCallback(function(flag: number)
		setFlags(function(flags)
			return bit32.bxor(flags, flag)
		end)
	end, { setFlags })

	return {
		flags = flags,
		addFlag = addFlag,
		hasFlag = hasFlag,
		removeFlag = removeFlag,
		toggleFlag = toggleFlag,
	}
end

return useFlags
