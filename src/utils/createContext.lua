local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Error = LuauPolyfill.Error
local Object = LuauPolyfill.Object

type CreateContextOptions<T> = {
	name: string,
	defaultValue: T?,
	rootComponentName: string,
}

local function createContext<T>(options: CreateContextOptions<T>)
	local Context = React.createContext(options.defaultValue :: T?)
	Context.displayName = options.name

	local function useContext(component: string): T
		local context = React.useContext(Context)
		if context == nil then
			local err = Error.new(`<{component} /> is missing a parent <{options.rootComponentName} /> component.`)
			Error.captureStackTrace(err, useContext)
			error(err)
		end

		return context
	end

	local function Provider(props: T & { children: React.ReactNode })
		local children = props.children
		local context = Object.assign({}, props, { children = Object.None })

		local value = React.useMemo(function()
			return context
		end, Object.values(context)) :: T

		return React.createElement(Context.Provider, { value = value }, children)
	end

	return Provider, useContext, Context
end

return createContext
