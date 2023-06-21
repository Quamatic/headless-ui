local src = script.Parent.Parent.Parent
local React = require(src.React)
local ReactRoblox = require(src.ReactRoblox)

local Slider = require(script.Parent.Slider)

local e = React.createElement

local function SliderThumb(props)
	return e(Slider.Thumb, {
		index = props.index,
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = Color3.fromHex("#ffffff"),
	}, {
		Radius = e("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
	})
end

local function Example()
	return e(
		Slider,
		{
			defaultValue = { 50 },
			step = 1,
			--minStepsBetweenThumbs = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(200, 20),
			BackgroundTransparency = 1,
		},
		e(Slider.Track, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = Color3.fromHex("#000000"),
			BackgroundTransparency = 0.48,
			ClipsDescendants = true,
		}, {
			Radius = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),

			Range = e(Slider.Range, {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromHex("#ffffff"),
				BorderSizePixel = 1,
			}, {
				Radius = e("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}),
		}),
		e(SliderThumb, { index = 1 })
		--e(SliderThumb, { index = 2 })
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
