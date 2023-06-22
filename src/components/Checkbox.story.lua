local src = script.Parent.Parent.Parent
local React = require(src.React)
local ReactRoblox = require(src.ReactRoblox)

local Checkbox = require(script.Parent.Checkbox)

local e = React.createElement

local function Example()
	return e(
		"Frame",
		{
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		},
		e("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 15),
		}),
		e(
			Checkbox,
			{
				defaultChecked = true,
				BackgroundColor3 = Color3.fromHex("#ffffff"),
				Size = UDim2.fromOffset(25, 25),
			},
			e("UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),
			e(Checkbox.Indicator, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -5, 1, -5),
				Image = "http://www.roblox.com/asset/?id=13794111091",
				ImageColor3 = Color3.fromHex("#6404b3"),
				BackgroundTransparency = 1,
			})
		),
		e("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.XY,
			TextColor3 = Color3.fromHex("#ffffff"),
			TextSize = 12,
			Text = "Accept terms and conditions.",
			BackgroundTransparency = 1,
		})
	)
end

return function(target: Frame)
	local root = ReactRoblox.createRoot(Instance.new("Frame"))

	root:render(ReactRoblox.createPortal({
		App = e(Example),
	}, target))

	return function()
		root:unmount()
	end
end
