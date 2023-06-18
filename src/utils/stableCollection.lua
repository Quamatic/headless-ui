local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Map = LuauPolyfill.Map
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error
local Symbol = LuauPolyfill.Symbol
local Boolean = LuauPolyfill.Boolean

type Map<K, V> = LuauPolyfill.Map<K, V>
type Array<T> = LuauPolyfill.Array<T>

type CollectionKey = string
type CollectionItem = { number | () -> () }
type Collection = {
	groups: Map<string, Map<string, number>>,
	get: (self: Collection, group: string, key: CollectionKey) -> CollectionItem,
}
type CollectionRef = { current: Collection }

local StableCollectionContext = React.createContext(nil :: CollectionRef?)

local function createCollection(): Collection
	return {
		groups = Map.new(),
		get = function(self, group, key)
			local list = self.groups:get(group)
			if not list then
				list = Map.new()
				self.groups:set(group, list)
			end

			local renders = list:get(key) or 0
			list:set(key, renders + 1)

			local index = Array.indexOf(Array.from(list:keys()), key)
			local function release()
				local renders = list:get(key)
				if renders > 1 then
					list:set(key, renders - 1)
				else
					list:delete(key)
				end
			end

			return index, release
		end,
	}
end

local function StableCollection(props: { children: React.ReactNode | Array<React.ReactNode> })
	local children = props.children
	local collection = React.useRef(createCollection())

	return React.createElement(StableCollectionContext.Provider, {
		value = collection,
	}, children)
end

local useStableCollectionKey

local function useStableCollectionIndex(group: string)
	local collection = React.useContext(StableCollectionContext)
	if collection == nil then
		error(Error.new("You must wrap your component in a <StableCollection>"))
	end

	local key = useStableCollectionKey()
	local idx, cleanupIdx = collection.current:get(group, key)

	React.useEffect(function()
		return cleanupIdx
	end, {})

	return idx
end

function useStableCollectionKey()
	local owner = React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentOwner.current

	if not owner then
		return Symbol()
	end

	local indexes = {}
	local fiber = owner

	while Boolean.toJSBoolean(fiber) do
		table.insert(indexes, fiber.index)
		fiber = fiber.value -- TODO: find the actual value.
	end

	return `$.{Array.join(indexes, ".")}`
end

return {
	StableCollection = StableCollection,
	useStableCollectionIndex = useStableCollectionIndex,
}
