local src = script.Parent.Parent.Parent
local React = require(src.React)
local ReactRoblox = require(src.ReactRoblox)
local ReactSpring = require(src.ReactSpring)

local Switch = require(script.Parent.Switch)

local e = React.createElement

local function Example()
	local enabled, setEnabled = React.useState(false)

	local styles = ReactSpring.useSpring({
		origin = if enabled then Vector2.new(1, 0.5) else Vector2.new(0, 0.5),
		position = if enabled then UDim2.fromScale(1, 0.5) else UDim2.fromScale(0, 0.5),
		transparency = if enabled then 0 else 0.6,
		config = { duration = 0.2, easing = ReactSpring.easings.easeInOutCubic },
	}, { enabled })

	return e(
		Switch,
		{
			checked = enabled,
			onChange = setEnabled,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(74, 38),
			BackgroundColor3 = Color3.fromHex("#000000"),
			BackgroundTransparency = styles.transparency,
			AutoButtonColor = false,
		},
		e("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		e("UIPadding", {
			PaddingLeft = UDim.new(0, 3),
			PaddingRight = UDim.new(0, 3),
		}),
		e(
			"Frame",
			{
				AnchorPoint = styles.origin,
				Position = styles.position,
				Size = UDim2.fromOffset(32, 32),
				BackgroundColor3 = Color3.fromHex("#ffffff"),
			},
			e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			})
		)
	)
end

return function(target: Frame)
	local root = ReactRoblox.createRoot(Instance.new("Folder"))

	root:render(ReactRoblox.createPortal({
		App = e(Example),
	}, target))

	return function()
		root:unmount()
	end
end
