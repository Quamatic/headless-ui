local src = script.Parent.Parent.Parent
local React = require(src.React)

local ForcePortalRootContext = React.createContext(false)

local function usePortalRoot()
	return React.useContext(ForcePortalRootContext)
end

type ForcePortalRootProps = {
	force: boolean,
	children: React.ReactNode,
}

local function ForcePortalRoot(props: ForcePortalRootProps)
	return React.createElement(ForcePortalRootContext.Provider, {
		value = props.force,
	}, props.children)
end

return {
	usePortalRoot = usePortalRoot,
	ForcePortalRoot = ForcePortalRoot,
}
