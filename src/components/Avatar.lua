local Players = game:GetService("Players")

local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object

local _render = require(src.ReactHeadless.utils.render)
local render = _render.render
local forwardWithRefAs = _render.forwardWithRefAs

local DEFAULT_AVATAR_TAG = "ImageLabel"

type AvatarProps = {
	user: number,
	size: Enum.ThumbnailSize?,
	type: Enum.ThumbnailType?,
}

local function AvatarFn(props: AvatarProps, ref: React.Ref<ImageLabel>)
	local userId = props.user
	local thumbnailSize = props.size or Enum.ThumbnailSize.Size180x180
	local thumbnailType = props.type or Enum.ThumbnailType.HeadShot
	local theirProps = {}

	local thumbnail, setThumbnail = React.useState("")
	local status, setStatus = React.useState("loading")

	React.useEffect(function()
		task.spawn(function()
			local thumbnail_, isReady = Players:GetUserThumbnailAsync(userId, thumbnailType, thumbnailSize)
			if not isReady then
				setStatus("error")
				return
			end

			setThumbnail(thumbnail_)
		end)
	end, { userId, thumbnailSize, thumbnailType })

	local slot = React.useMemo(function()
		return { status = status }
	end, { status })

	local ourProps = {
		ref = ref,
		Image = `rbxassetid://{thumbnail}`,
	}

	return render({
		ourProps = ourProps,
		theirProps = theirProps,
		slot = slot,
		defaultTag = DEFAULT_AVATAR_TAG,
		name = "Avatar",
	})
end

local AvatarRoot = forwardWithRefAs(AvatarFn)

return Object.assign(AvatarRoot)
