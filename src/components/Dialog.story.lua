local src = script.Parent.Parent.Parent
local React = require(src.React)
local ReactRoblox = require(src.ReactRoblox)
local ReactSpring = require(src.ReactSpring)

local Dialog = require(script.Parent.Dialog)

local e = React.createElement

local function Example()
	local open, setOpen = React.useState(false)
	local styles = ReactSpring.useSpring({
		opacity = if open then 0 else 1,
		position = if open then UDim2.fromScale(0.5, 0.5) else UDim2.new(0.5, 0, 0.5, 10),
		config = ReactSpring.config.stiff,
	}, { open })

	local function openModal()
		setOpen(true)
	end

	local function closeModal()
		setOpen(false)
	end

	return e(React.Fragment, nil, {
		-- Button
		Button = e("TextButton", {
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("#000000"),
			BackgroundTransparency = 0.6,
			TextSize = 16,
			FontFace = Font.fromName("SourceSans", Enum.FontWeight.Medium),
			TextColor3 = Color3.fromHex("#ffffff"),
			Text = "Open Dialog",
			[React.Event.Activated] = openModal,
		}, {
			Radius = e("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),

			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
			}),
		}),

		-- Dialog
		Dialog = e(
			Dialog,
			{
				static = true,
				open = open,
				onClose = closeModal,
			},
			e(Dialog.Panel, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = styles.position,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromOffset(435, 0),
				ClipsDescendants = true,
				GroupTransparency = styles.opacity,
				BackgroundColor3 = Color3.fromHex("#ffffff"),
			}, {
				Radius = e("UICorner", {
					CornerRadius = UDim.new(0, 16),
				}),

				Padding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 24),
					PaddingRight = UDim.new(0, 24),
					PaddingTop = UDim.new(0, 24),
					PaddingBottom = UDim.new(0, 24),
				}),

				Layout = e("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 18),
				}),

				Div = e("Frame", {
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundTransparency = 1,
				}, {
					Layout = e("UIListLayout", {
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 6),
					}),

					Title = e("TextLabel", {
						AutomaticSize = Enum.AutomaticSize.XY,
						FontFace = Font.fromName("SourceSansPro", Enum.FontWeight.Medium),
						TextSize = 24,
						Text = "Payment successful",
						TextColor3 = Color3.fromHex("#111827"),
						BackgroundTransparency = 1,
					}),

					Description = e("TextLabel", {
						AutomaticSize = Enum.AutomaticSize.XY,
						FontFace = Font.fromEnum(Enum.Font.SourceSans),
						TextSize = 18,
						Text = "Your payment has been successfully submitted. We’ve sent you an email with all of the details of your order.",
						TextColor3 = Color3.fromHex("#6b7280"),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextWrapped = true,
						BackgroundTransparency = 1,
					}),
				}),

				Confirm = e("TextButton", {
					AutomaticSize = Enum.AutomaticSize.XY,
					TextColor3 = Color3.fromHex("#1e3a8a"),
					BackgroundColor3 = Color3.fromHex("#dbeafe"),
					FontFace = Font.fromName("SourceSansPro", Enum.FontWeight.Medium),
					Text = "Got it, thanks!",
					TextSize = 18,
					LayoutOrder = 0xffff,
					[React.Event.Activated] = closeModal,
				}, {
					Radius = e("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),

					Padding = e("UIPadding", {
						PaddingLeft = UDim.new(0, 16),
						PaddingRight = UDim.new(0, 16),
						PaddingTop = UDim.new(0, 10),
						PaddingBottom = UDim.new(0, 10),
					}),
				}),
			})
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
