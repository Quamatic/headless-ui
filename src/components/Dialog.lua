local ContextActionService = game:GetService("ContextActionService")

local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object

local _Portal = require(script.Parent.Portal)
local Portal = _Portal.Portal
local useNestedPortals = _Portal.useNestedPortals

local StackContext = require(src.ReactHeadless.internal.StackContext)
local StackProvider = StackContext.StackProvider
local StackMessage = StackContext.StackMessage

local PortalForceRoot = require(src.ReactHeadless.internal.PortalForceRoot)
local ForcePortalRoot = PortalForceRoot.ForcePortalRoot

local useCallbackRef = require(src.ReactHeadless.hooks.useCallbackRef)
local useSyncRefs = require(src.ReactHeadless.hooks.useSyncRefs).useSyncRefs
local useOutsideClick = require(src.ReactHeadless.hooks.useOutsideClick)
local useRootContainers = require(src.ReactHeadless.hooks.useRootContainers)

local _useOpenClosed = require(src.ReactHeadless.hooks.useOpenClosed)
local useOpenClosed = _useOpenClosed.useOpenClosed
local State = _useOpenClosed.State

local match = require(src.ReactHeadless.utils.match)
local createContext = require(src.ReactHeadless.utils.createContext)

local _render = require(src.ReactHeadless.utils.render)
local render = _render.render
local forwardWithRefAs = _render.forwardWithRefAs
local Features = _render.Features

local DialogState = {
	Open = bit32.lshift(1, 1),
	Closed = bit32.lshift(1, 0),
}

type DialogState = typeof(DialogState)

type DialogContext = {
	{
		dialogState: DialogState,
		close: () -> (),
		setTitleId: (id: string?) -> (),
	} | {}
}

local DialogContextProvider, useDialogContext, DialogContext = createContext({
	name = "DialogContext",
	rootComponentName = "<Dialog />",
})

local DEFAULT_DIALOG_TAG = React.Fragment

local DialogRenderFeatures = bit32.bor(Features.RenderStrategy, Features.Static)

type DialogProps = {
	open: boolean?,
	onClose: (value: boolean) -> (),
	initialFocus: { current: TextBox? }?,
	__demoMode: boolean?,
}

local function DialogFn(props: DialogProps, ref: React.Ref<Frame>)
	local open = props.open
	local onClose = props.onClose
	local initialFocus = props.initialFocus
	local __demoMode = props.__demoMode
	local theirProps = Object.assign({}, props, {
		open = Object.None,
		onClose = Object.None,
		initialFocus = Object.None,
		__demoMode = Object.None,
	})

	local nestedDialogCount, setNestedDialogCount = React.useState(0)
	local usesOpenClosedState = useOpenClosed()

	if open == nil and usesOpenClosedState ~= nil then
		open = bit32.lshift(usesOpenClosedState, State.Open) == State.Open
	end

	-- Ref
	local internalDialogRef = React.useRef(nil :: Frame?)
	local dialogRef = useSyncRefs(internalDialogRef, ref)

	local dialogState = if open then DialogState.Open else DialogState.Closed
	local state = {
		panelRef = React.createRef(),
	}

	local hasNestedDialogs = nestedDialogCount > 1
	local hasParentDialog = React.useContext(DialogContext) ~= nil

	local close = useCallbackRef(function()
		onClose(false)
	end)

	local portals, PortalWrapper = useNestedPortals()
	local _rootContainers = useRootContainers({ state.panelRef.current or internalDialogRef.current }, portals)

	local resolveRootContainers = _rootContainers.resolveContainers
	local mainTreeNodeRef = _rootContainers.mainTreeNodeRef
	local MainTreeNode = _rootContainers.MainTreeNode

	-- Close dialog on outside click
	local isOutsideClickEnabled = dialogState == DialogState.Open and not hasNestedDialogs
	useOutsideClick(resolveRootContainers, close, isOutsideClickEnabled)

	-- Handle gamepad B button to close or Escape
	local isEscapeToCloseEnabled = not hasNestedDialogs and dialogState == DialogState.Open
	React.useEffect(function()
		if not isEscapeToCloseEnabled then
			return
		end

		ContextActionService:BindAction("CloseDialog", function(_, state)
			if state == Enum.UserInputState.Begin then
				close()
			end
		end, false, Enum.KeyCode.B, Enum.KeyCode.Escape)

		return function()
			ContextActionService:UnbindAction("CloseDialog")
		end
	end, { isEscapeToCloseEnabled })

	local contextBag = React.useMemo(function()
		return { { dialogState = dialogState, close = close }, state }
	end, { dialogState, close })

	local slot = React.useMemo(function()
		return { open = dialogState == DialogState.Open }
	end, { dialogState })

	local ourProps = {
		ref = dialogRef,
	}

	-- Probably the weirdest thing i've ever looked at.

	return React.createElement(
		StackProvider,
		{
			type = "Dialog",
			enabled = dialogState == DialogState.Open,
			element = internalDialogRef,
			onUpdate = useCallbackRef(function(message, type_)
				if type_ ~= "Dialog" then
					return
				end

				match(message, {
					[StackMessage.Add] = function()
						return setNestedDialogCount(function(count)
							return count + 1
						end)
					end,
					[StackMessage.Remove] = function()
						return setNestedDialogCount(function(count)
							return count - 1
						end)
					end,
				})
			end),
		},
		React.createElement(
			ForcePortalRoot,
			{ force = true },
			React.createElement(
				Portal,
				{},
				React.createElement(
					DialogContextProvider,
					contextBag,
					React.createElement(
						_Portal.Group,
						{ target = internalDialogRef },
						React.createElement(
							ForcePortalRoot,
							{ force = false },
							React.createElement(
								PortalWrapper,
								nil,
								render({
									ourProps = ourProps,
									theirProps = theirProps,
									slot = slot,
									defaultTag = DEFAULT_DIALOG_TAG,
									features = DialogRenderFeatures,
									visible = dialogState == DialogState.Open,
									name = "Dialog",
								})
							)
						)
					)
				)
			)
		),
		React.createElement(MainTreeNode)
	)
end

local DEFAULT_PANEL_TAG = "CanvasGroup"

export type DialogPanelProps = {}

local function PanelFn(props: DialogPanelProps, ref: React.Ref<Frame>)
	local theirProps = props

	local context, state = unpack(useDialogContext("Dialog.Panel"))
	local dialogState = context.dialogState

	local panelRef = useSyncRefs(ref, state.panelRef)
	local slot = React.useMemo(function()
		return { open = dialogState == DialogState.Open }
	end, { dialogState })

	local ourProps = {
		ref = panelRef,
		Active = false,
	}

	return render({
		ourProps = ourProps,
		theirProps = theirProps,
		slot = slot,
		defaultTag = DEFAULT_PANEL_TAG,
		name = "Dialog.Panel",
	})
end

local DialogRoot = forwardWithRefAs(DialogFn)
local Panel = forwardWithRefAs(PanelFn)

return Object.assign(DialogRoot, {
	Panel = Panel,
})
