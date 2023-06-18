local src = script.Parent.Parent.Parent
local React = require(src.React)
local ReactRoblox = require(src.ReactRoblox)
local Array = require(src.LuauPolyfill).Array

local RadioGroup = require(script.Parent.RadioGroup)

local e = React.createElement

local plans = {
	{
		name = "Startup",
		ram = "12GB",
		cpus = "6 CPUs",
		disk = "160 GB SSD disk",
	},
	{
		name = "Business",
		ram = "16GB",
		cpus = "8 CPUs",
		disk = "512 GB SSD disk",
	},
	{
		name = "Enterprise",
		ram = "32GB",
		cpus = "12 CPUs",
		disk = "1024 GB SSD disk",
	},
}

local function Example()
	local selected, setSelected = React.useState(plans[1])

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(0, 525, 1, 0),
		BackgroundTransparency = 1,
	}, {
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingTop = UDim.new(0, 64),
			PaddingBottom = UDim.new(0, 64),
		}),

		Layout = e("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),

		RadioGroup = e(
			RadioGroup,
			{
				value = selected,
				onChange = setSelected,
			},
			Array.map(plans, function(plan)
				return e(RadioGroup.Option, {
					key = plan.name,
					value = plan,
				}, function(data)
					local active, checked = data.active, data.checked

					return e("ImageButton", {
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundColor3 = if checked then Color3.fromHex("#085f8f") else Color3.fromHex("#ffffff"),
					}, {
						Radius = e("UICorner", {
							CornerRadius = UDim.new(0, 8),
						}),

						Padding = e("UIPadding", {
							PaddingLeft = UDim.new(0, 20),
							PaddingRight = UDim.new(0, 20),
							PaddingTop = UDim.new(0, 18),
							PaddingBottom = UDim.new(0, 18),
						}),

						Information = e("Frame", {
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
						}, {
							Layout = e("UIListLayout", {
								HorizontalAlignment = Enum.HorizontalAlignment.Left,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								FillDirection = Enum.FillDirection.Vertical,
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0, 6),
							}),

							Ring = active and e("UIStroke", {
								Thickness = 4,
								Color = Color3.fromHex("#ffffff"),
								Transparency = 0.6,
							}),

							Name = e("TextLabel", {
								AutomaticSize = Enum.AutomaticSize.XY,
								FontFace = Font.fromName("SourceSans", Enum.FontWeight.Medium),
								TextSize = 18,
								TextColor3 = if checked then Color3.fromHex("#ffffff") else Color3.fromHex("#030712"),
								Text = plan.name,
								BackgroundTransparency = 1,
								LayoutOrder = 1,
							}),

							Description = e("TextLabel", {
								AutomaticSize = Enum.AutomaticSize.XY,
								TextSize = 10,
								TextColor3 = if checked then Color3.fromHex("#e0f2fe") else Color3.fromHex("#64748b"),
								Text = `{plan.ram}/{plan.cpus} · {plan.disk}`,
								BackgroundTransparency = 1,
								LayoutOrder = 2,
							}),
						}),

						Checked = checked and e("Frame", {
							Position = UDim2.fromScale(1, 0.5),
							AnchorPoint = Vector2.new(1, 0.5),
							Size = UDim2.fromOffset(24, 24),
							BackgroundColor3 = Color3.fromHex("#bfdbfe"),
							BackgroundTransparency = 0.7,
						}, {
							Radius = e("UICorner", {
								CornerRadius = UDim.new(1, 0),
							}),

							Padding = e("UIPadding", {
								PaddingLeft = UDim.new(0, 2),
								PaddingRight = UDim.new(0, 2),
								PaddingTop = UDim.new(0, 2),
								PaddingBottom = UDim.new(0, 2),
							}),

							Image = e("ImageLabel", {
								Size = UDim2.fromScale(1, 1),
								Image = "http://www.roblox.com/asset/?id=13794111091",
								ImageColor3 = Color3.fromHex("#ffffff"),
								BackgroundTransparency = 1,
							}),
						}),
					})
				end)
			end)
		),
	})
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
