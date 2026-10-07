--!strict
local XDFLEX = {}
XDFLEX.__index = XDFLEX

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Theme = {
	Background = Color3.fromRGB(5, 12, 24),
	Panel = Color3.fromRGB(8, 19, 36),
	Panel2 = Color3.fromRGB(10, 24, 45),
	Panel3 = Color3.fromRGB(12, 30, 57),
	Border = Color3.fromRGB(25, 92, 160),
	BorderSoft = Color3.fromRGB(18, 52, 92),
	Accent = Color3.fromRGB(0, 153, 255),
	Accent2 = Color3.fromRGB(0, 225, 255),
	Text = Color3.fromRGB(238, 247, 255),
	SubText = Color3.fromRGB(145, 171, 198),
	Success = Color3.fromRGB(46, 220, 146),
	Danger = Color3.fromRGB(255, 93, 112),
	Muted = Color3.fromRGB(26, 40, 58),
}

local function New(className: string, props: {[string]: any}?)
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			(inst :: any)[k] = v
		end
	end
	return inst
end

local function Corner(parent: Instance, radius: number?)
	return New("UICorner", {
		CornerRadius = UDim.new(0, radius or 8),
		Parent = parent,
	})
end

local function Stroke(parent: Instance, color: Color3?, transparency: number?)
	return New("UIStroke", {
		Color = color or Theme.BorderSoft,
		Transparency = transparency or 0.25,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function Padding(parent: Instance, l: number, r: number?, t: number?, b: number?)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l),
		PaddingRight = UDim.new(0, r or l),
		PaddingTop = UDim.new(0, t or l),
		PaddingBottom = UDim.new(0, b or t or l),
		Parent = parent,
	})
end

local function Tween(obj: Instance, duration: number, props: {[string]: any})
	local tw = TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function SafeCall(cb, ...)
	if typeof(cb) == "function" then
		task.spawn(function(...)
			local ok, err = pcall(cb, ...)
			if not ok then
				warn("[XDFLEX UI] callback error:", err)
			end
		end, ...)
	end
end

local function Text(parent: Instance, value: string, size: number, color: Color3?, bold: boolean?)
	local label = New("TextLabel", {
		BackgroundTransparency = 1,
		Text = value,
		TextSize = size,
		TextColor3 = color or Theme.Text,
		Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = parent,
	})
	return label
end

local function ResolveParent()
	local ok, hui = pcall(function()
		if typeof(gethui) == "function" then
			return gethui()
		end
	end)
	if ok and hui then
		return hui
	end
	return CoreGui
end

local function MakeDraggable(handle: GuiObject, target: GuiObject)
	local dragging = false
	local dragStart: Vector2? = nil
	local startPos: UDim2? = nil
	local activeInput: InputObject? = nil

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			activeInput = input
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging or not dragStart or not startPos then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input == activeInput
			or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			activeInput = nil
		end
	end)
end

local function AutoCanvas(scroll: ScrollingFrame, layout: UIListLayout, extra: number?)
	local function update()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + (extra or 14))
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
	update()
end

local function MakeCard(parent: Instance, height: number?)
	local card = New("Frame", {
		BackgroundColor3 = Theme.Panel2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height or 58),
		Parent = parent,
	})
	Corner(card, 8)
	Stroke(card, Theme.BorderSoft, 0.25)
	return card
end

local function MakeTitleBlock(parent: Instance, title: string, desc: string?)
	local titleLabel = Text(parent, title, 15, Theme.Text, true)
	titleLabel.Position = UDim2.fromOffset(14, 8)
	titleLabel.Size = UDim2.new(1, -28, 0, 22)

	if desc and desc ~= "" then
		local sub = Text(parent, desc, 12, Theme.SubText, false)
		sub.Position = UDim2.fromOffset(14, 29)
		sub.Size = UDim2.new(1, -28, 0, 18)
	end
end

local function MakeButtonBase(parent: Instance, textValue: string)
	local b = New("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Panel3,
		BorderSizePixel = 0,
		Text = textValue,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Enum.Font.GothamSemibold,
		Parent = parent,
	})
	Corner(b, 7)
	Stroke(b, Theme.Border, 0.35)
	b.MouseEnter:Connect(function()
		Tween(b, 0.12, {BackgroundColor3 = Color3.fromRGB(14, 42, 76)})
	end)
	b.MouseLeave:Connect(function()
		Tween(b, 0.12, {BackgroundColor3 = Theme.Panel3})
	end)
	return b
end

-- ========= Element builders =========

local ElementAPI = {}

function ElementAPI:Label(config)
	config = config or {}
	local title = config.Title or config.Name or "Label"
	local desc = config.Description or config.Desc or ""
	local card = MakeCard(self.Container, desc ~= "" and 64 or 44)
	MakeTitleBlock(card, title, desc)
	return card
end

function ElementAPI:Button(config)
	config = config or {}
	local title = config.Title or config.Name or "Button"
	local desc = config.Description or config.Desc or ""
	local callback = config.Callback
	local card = MakeCard(self.Container, 66)
	MakeTitleBlock(card, title, desc)

	local button = MakeButtonBase(card, config.ButtonText or "Execute")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -12, 0.5, 0)
	button.Size = UDim2.fromOffset(150, 36)
	button.MouseButton1Click:Connect(function()
		Tween(button, 0.08, {BackgroundColor3 = Theme.Accent})
		task.delay(0.08, function()
			if button.Parent then
				Tween(button, 0.14, {BackgroundColor3 = Theme.Panel3})
			end
		end)
		SafeCall(callback)
	end)

	return {
		Instance = card,
		Press = function()
			SafeCall(callback)
		end,
	}
end

function ElementAPI:Toggle(config)
	config = config or {}
	local title = config.Title or config.Name or "Toggle"
	local desc = config.Description or config.Desc or ""
	local state = config.Default == true
	local callback = config.Callback

	local card = MakeCard(self.Container, 66)
	MakeTitleBlock(card, title, desc)

	local toggle = New("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = state and Theme.Accent or Theme.Muted,
		BorderSizePixel = 0,
		Text = "",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(46, 24),
		Parent = card,
	})
	Corner(toggle, 99)

	local knob = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(248, 252, 255),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(18, 18),
		Position = state and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
		Parent = toggle,
	})
	Corner(knob, 99)

	local api = {}

	local function set(v: boolean, silent: boolean?)
		state = v == true
		Tween(toggle, 0.15, {BackgroundColor3 = state and Theme.Accent or Theme.Muted})
		Tween(knob, 0.15, {Position = state and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)})
		if not silent then
			SafeCall(callback, state)
		end
	end

	toggle.MouseButton1Click:Connect(function()
		set(not state)
	end)

	function api:SetValue(v, silent)
		set(v == true, silent)
	end
	function api:GetValue()
		return state
	end
	api.Instance = card
	return api
end

function ElementAPI:Slider(config)
	config = config or {}
	local title = config.Title or config.Name or "Slider"
	local desc = config.Description or config.Desc or ""
	local min = tonumber(config.Min) or 0
	local max = tonumber(config.Max) or 100
	local step = tonumber(config.Step) or 1
	local value = math.clamp(tonumber(config.Default) or min, min, max)
	local callback = config.Callback

	local card = MakeCard(self.Container, 80)
	MakeTitleBlock(card, title, desc)

	local valueBox = New("TextLabel", {
		BackgroundColor3 = Theme.Panel3,
		BorderSizePixel = 0,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Enum.Font.GothamSemibold,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 10),
		Size = UDim2.fromOffset(56, 28),
		Parent = card,
	})
	Corner(valueBox, 6)
	Stroke(valueBox, Theme.BorderSoft, 0.25)

	local track = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(19, 42, 72),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 14, 1, -18),
		Size = UDim2.new(1, -88, 0, 6),
		Parent = card,
	})
	Corner(track, 99)

	local fill = New("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = track,
	})
	Corner(fill, 99)

	local knob = New("Frame", {
		BackgroundColor3 = Theme.Accent2,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		Parent = track,
	})
	Corner(knob, 99)
	Stroke(knob, Color3.fromRGB(235, 250, 255), 0.15)

	local dragging = false
	local api = {}

	local function quantize(v)
		if step <= 0 then return v end
		return math.floor((v / step) + 0.5) * step
	end

	local function set(v, silent)
		value = math.clamp(quantize(tonumber(v) or min), min, max)
		local alpha = (max == min) and 0 or ((value - min) / (max - min))
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueBox.Text = tostring(value)
		if not silent then
			SafeCall(callback, value)
		end
	end

	local function updateFromX(x)
		local alpha = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		set(min + (max - min) * alpha)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	function api:SetValue(v, silent) set(v, silent) end
	function api:GetValue() return value end
	api.Instance = card
	set(value, true)
	return api
end

local function BuildDropdown(owner, config, multi)
	config = config or {}
	local title = config.Title or config.Name or (multi and "Multi Dropdown" or "Dropdown")
	local desc = config.Description or config.Desc or ""
	local values = config.Values or config.Options or {}
	local callback = config.Callback
	local selected = multi and {} or (config.Default or values[1])
	if multi and type(config.Default) == "table" then
		for _, v in ipairs(config.Default) do
			selected[v] = true
		end
	end

	local card = MakeCard(owner.Container, 72)
	MakeTitleBlock(card, title, desc)

	local button = MakeButtonBase(card, "")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -12, 0.5, 0)
	button.Size = UDim2.fromOffset(250, 38)
	button.TextXAlignment = Enum.TextXAlignment.Left
	Padding(button, 10, 32, 0, 0)

	local arrow = Text(button, "⌄", 18, Theme.SubText, true)
	arrow.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Position = UDim2.new(1, -8, 0.5, -1)
	arrow.Size = UDim2.fromOffset(20, 20)
	arrow.TextXAlignment = Enum.TextXAlignment.Center

	local popup = New("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 50,
		Parent = owner.Window._Overlay,
	})
	Corner(popup, 8)
	Stroke(popup, Theme.Border, 0.15)

	local sc = New("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 51,
		Parent = popup,
	})
	Padding(sc, 6, 6, 6, 6)
	local list = New("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = sc,
	})
	AutoCanvas(sc, list, 8)

	local opened = false
	local api = {}

	local function summary()
		if multi then
			local arr = {}
			for _, v in ipairs(values) do
				if selected[v] then
					table.insert(arr, tostring(v))
				end
			end
			if #arr == 0 then return config.Placeholder or "Select..." end
			if #arr <= 2 then return table.concat(arr, ", ") end
			return arr[1] .. ", " .. arr[2] .. "  +" .. tostring(#arr - 2)
		else
			return selected ~= nil and tostring(selected) or (config.Placeholder or "Select...")
		end
	end

	local function emit()
		if multi then
			local arr = {}
			for _, v in ipairs(values) do
				if selected[v] then table.insert(arr, v) end
			end
			SafeCall(callback, arr)
		else
			SafeCall(callback, selected)
		end
	end

	local function close()
		opened = false
		popup.Visible = false
		arrow.Text = "⌄"
	end

	local function positionPopup()
		local pos = button.AbsolutePosition
		local size = button.AbsoluteSize
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
		local width = math.max(size.X, 220)
		local height = math.min(#values * 34 + 12, 220)
		local x = math.clamp(pos.X, 8, vp.X - width - 8)
		local y = pos.Y + size.Y + 5
		if y + height > vp.Y - 8 then
			y = math.max(8, pos.Y - height - 5)
		end
		popup.Position = UDim2.fromOffset(x, y)
		popup.Size = UDim2.fromOffset(width, height)
	end

	local function refreshText()
		button.Text = summary()
	end

	local function rebuild()
		for _, child in ipairs(sc:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		for _, valueItem in ipairs(values) do
			local option = New("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Theme.Panel2,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 30),
				Text = tostring(valueItem),
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 52,
				Parent = sc,
			})
			Padding(option, 10, 10, 0, 0)
			Corner(option, 6)
			option.MouseButton1Click:Connect(function()
				if multi then
					selected[valueItem] = not selected[valueItem] or nil
				else
					selected = valueItem
					close()
				end
				refreshText()
				emit()
			end)
		end
	end

	button.MouseButton1Click:Connect(function()
		opened = not opened
		if opened then
			positionPopup()
			popup.Visible = true
			arrow.Text = "⌃"
		else
			close()
		end
	end)

	owner.Window:_RegisterPopupCloser(close)

	function api:SetValues(newValues)
		values = newValues or {}
		if multi then
			selected = {}
		elseif selected == nil or table.find(values, selected) == nil then
			selected = values[1]
		end
		rebuild()
		refreshText()
	end

	function api:SetValue(v, silent)
		if multi then
			selected = {}
			if type(v) == "table" then
				for _, item in ipairs(v) do selected[item] = true end
			end
		else
			selected = v
		end
		refreshText()
		if not silent then emit() end
	end

	function api:GetValue()
		if multi then
			local arr = {}
			for _, v in ipairs(values) do
				if selected[v] then table.insert(arr, v) end
			end
			return arr
		end
		return selected
	end

	api.Instance = card
	rebuild()
	refreshText()
	return api
end

function ElementAPI:Dropdown(config)
	return BuildDropdown(self, config, false)
end

function ElementAPI:MultiDropdown(config)
	return BuildDropdown(self, config, true)
end

function ElementAPI:Input(config)
	config = config or {}
	local title = config.Title or config.Name or "Input"
	local desc = config.Description or config.Desc or ""
	local callback = config.Callback
	local card = MakeCard(self.Container, 70)
	MakeTitleBlock(card, title, desc)

	local box = New("TextBox", {
		BackgroundColor3 = Theme.Panel3,
		BorderSizePixel = 0,
		Text = tostring(config.Default or ""),
		PlaceholderText = config.Placeholder or "Enter text...",
		PlaceholderColor3 = Color3.fromRGB(104, 132, 162),
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(240, 38),
		Parent = card,
	})
	Padding(box, 10, 10, 0, 0)
	Corner(box, 7)
	Stroke(box, Theme.BorderSoft, 0.25)

	box.FocusLost:Connect(function(enterPressed)
		if config.Numeric == true then
			local n = tonumber(box.Text)
			if n then
				box.Text = tostring(n)
				SafeCall(callback, n, enterPressed)
			end
		else
			SafeCall(callback, box.Text, enterPressed)
		end
	end)

	local api = {
		Instance = card,
		SetValue = function(_, v)
			box.Text = tostring(v or "")
		end,
		GetValue = function()
			return box.Text
		end,
	}
	return api
end

function ElementAPI:Keybind(config)
	config = config or {}
	local title = config.Title or config.Name or "Keybind"
	local desc = config.Description or config.Desc or ""
	local current = config.Default or Enum.KeyCode.RightShift
	local callback = config.Callback
	local card = MakeCard(self.Container, 66)
	MakeTitleBlock(card, title, desc)

	local button = MakeButtonBase(card, current.Name or tostring(current))
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -12, 0.5, 0)
	button.Size = UDim2.fromOffset(130, 36)

	local listening = false
	button.MouseButton1Click:Connect(function()
		listening = true
		button.Text = "Press a key..."
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if listening then
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				current = input.KeyCode
				button.Text = current.Name
				listening = false
			end
			return
		end
		if input.KeyCode == current then
			SafeCall(callback, current)
		end
	end)

	return {
		Instance = card,
		GetValue = function() return current end,
		SetValue = function(_, v)
			if typeof(v) == "EnumItem" then
				current = v
				button.Text = v.Name
			end
		end,
	}
end

-- ========= Section / Tab / Window =========

local SectionAPI = {}
SectionAPI.__index = SectionAPI
for name, fn in pairs(ElementAPI) do
	SectionAPI[name] = fn
end

function SectionAPI:SetVisible(v: boolean)
	self.Root.Visible = v
end

local TabAPI = {}
TabAPI.__index = TabAPI

function TabAPI:Section(config)
	config = config or {}
	local secRoot = New("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.Container,
	})
	Corner(secRoot, 10)
	Stroke(secRoot, Theme.BorderSoft, 0.2)

	local header = Text(secRoot, config.Title or config.Name or "Section", 15, Theme.Text, true)
	header.Position = UDim2.fromOffset(14, 10)
	header.Size = UDim2.new(1, -28, 0, 22)

	local sub = nil
	if config.Description or config.Desc then
		sub = Text(secRoot, config.Description or config.Desc, 11, Theme.SubText, false)
		sub.Position = UDim2.fromOffset(14, 31)
		sub.Size = UDim2.new(1, -28, 0, 18)
	end

	local content = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, sub and 56 or 42),
		Size = UDim2.new(1, -24, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = secRoot,
	})
	local layout = New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = content,
	})
	New("UIPadding", {
		PaddingBottom = UDim.new(0, 12),
		Parent = content,
	})

	local sec = setmetatable({
		Root = secRoot,
		Container = content,
		Layout = layout,
		Window = self.Window,
	}, SectionAPI)
	return sec
end

local WindowAPI = {}
WindowAPI.__index = WindowAPI

function WindowAPI:_RegisterPopupCloser(fn)
	table.insert(self._PopupClosers, fn)
end

function WindowAPI:_ClosePopups()
	for _, fn in ipairs(self._PopupClosers) do
		pcall(fn)
	end
end

function WindowAPI:SetGameCard(config)
	config = config or {}
	self.Hero.Visible = config.Visible ~= false
	self.HeroTitle.Text = config.Title or config.Name or "Current Game"
	self.HeroDesc.Text = config.Description or config.Desc or "Ready to use."
	self.HeroImage.Image = config.Image or ""
	self.HeroImage.ImageTransparency = (config.Image and config.Image ~= "") and 0 or 1
	self.HeroButton.Text = config.ButtonText or "Execute"
	if config.Callback then
		self._HeroCallback = config.Callback
	end
end

function WindowAPI:Tab(config)
	config = config or {}
	local name = config.Title or config.Name or "Tab"
	local icon = config.Icon or "•"

	local tabButton = New("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Panel2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		Size = UDim2.new(1, 0, 0, 44),
		Parent = self.SidebarList,
	})
	Corner(tabButton, 8)

	local iconLabel = Text(tabButton, icon, 17, Theme.SubText, true)
	iconLabel.Position = UDim2.fromOffset(12, 0)
	iconLabel.Size = UDim2.fromOffset(24, 44)
	iconLabel.TextXAlignment = Enum.TextXAlignment.Center

	local label = Text(tabButton, name, 14, Theme.SubText, true)
	label.Position = UDim2.fromOffset(44, 0)
	label.Size = UDim2.new(1, -52, 1, 0)

	local page = New("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(),
		Size = UDim2.fromScale(1, 1),
		Parent = self.Pages,
	})
	Padding(page, 0, 8, 0, 8)
	local layout = New("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})
	AutoCanvas(page, layout, 16)

	local tab = setmetatable({
		Name = name,
		Button = tabButton,
		Container = page,
		Layout = layout,
		Window = self,
	}, TabAPI)

	function tab:Select()
		self.Window:_ClosePopups()
		for _, other in ipairs(self.Window.Tabs) do
			local active = other == self
			other.Container.Visible = active
			Tween(other.Button, 0.15, {
				BackgroundTransparency = active and 0 or 1,
				BackgroundColor3 = active and Color3.fromRGB(9, 49, 89) or Theme.Panel2,
			})
			for _, child in ipairs(other.Button:GetChildren()) do
				if child:IsA("TextLabel") then
					child.TextColor3 = active and Theme.Text or Theme.SubText
				end
			end
		end
		self.Window.ActiveTab = self
	end

	tabButton.MouseButton1Click:Connect(function()
		tab:Select()
	end)

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		tab:Select()
	end
	return tab
end

function WindowAPI:SetVisible(v: boolean)
	self.Root.Visible = v
end

function WindowAPI:Toggle()
	self.Root.Visible = not self.Root.Visible
end

function WindowAPI:Destroy()
	self.ScreenGui:Destroy()
end

function XDFLEX:CreateWindow(config)
	config = config or {}

	local gui = New("ScreenGui", {
		Name = "XDFLEX_UI",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = ResolveParent(),
	})

	local overlay = New("Frame", {
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 40,
		Parent = gui,
	})

	local root = New("Frame", {
		Name = "Window",
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1060, 650),
		Parent = gui,
	})
	Corner(root, 12)
	Stroke(root, Theme.Accent, 0.15)

	local scale = New("UIScale", {Scale = 1, Parent = root})
	local function updateScale()
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
		local sx = math.clamp(vp.X / 1180, 0.62, 1)
		local sy = math.clamp(vp.Y / 740, 0.62, 1)
		scale.Scale = math.min(sx, sy)
	end
	updateScale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end

	local top = New("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 74),
		Parent = root,
	})
	Corner(top, 12)
	New("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -12),
		Size = UDim2.new(1, 0, 0, 12),
		Parent = top,
	})

	local brand = Text(top, config.Title or "XDFLEX HUB", 23, Theme.Text, true)
	brand.Position = UDim2.fromOffset(22, 8)
	brand.Size = UDim2.new(0, 340, 0, 34)

	local subtitle = Text(top, config.Subtitle or "MODERN UI LIBRARY", 11, Theme.SubText, true)
	subtitle.Position = UDim2.fromOffset(23, 39)
	subtitle.Size = UDim2.new(0, 340, 0, 20)

	local stable = MakeButtonBase(top, "●  Stable")
	stable.TextColor3 = Theme.Success
	stable.Size = UDim2.fromOffset(92, 32)
	stable.Position = UDim2.new(1, -335, 0, 20)

	local responsive = MakeButtonBase(top, "⚡ Responsive")
	responsive.Size = UDim2.fromOffset(112, 32)
	responsive.Position = UDim2.new(1, -235, 0, 20)

	local close = MakeButtonBase(top, "×")
	close.Size = UDim2.fromOffset(38, 32)
	close.Position = UDim2.new(1, -50, 0, 20)
	close.TextSize = 20

	local minimize = MakeButtonBase(top, "—")
	minimize.Size = UDim2.fromOffset(38, 32)
	minimize.Position = UDim2.new(1, -94, 0, 20)

	MakeDraggable(top, root)

	local sidebar = New("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, 86),
		Size = UDim2.new(0, 190, 1, -98),
		Parent = root,
	})
	Corner(sidebar, 10)
	Stroke(sidebar, Theme.BorderSoft, 0.35)
	Padding(sidebar, 10, 10, 10, 10)

	local sidebarList = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -80),
		Parent = sidebar,
	})
	local sidebarLayout = New("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = sidebarList,
	})

	local sidebarBrand = Text(sidebar, "XDFLEX HUB\nv1.0.0", 12, Theme.SubText, true)
	sidebarBrand.Position = UDim2.new(0, 0, 1, -64)
	sidebarBrand.Size = UDim2.new(1, 0, 0, 54)
	sidebarBrand.TextYAlignment = Enum.TextYAlignment.Bottom

	local content = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(214, 86),
		Size = UDim2.new(1, -226, 1, -98),
		Parent = root,
	})

	local hero = New("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, config.ShowGameCard == false and 0 or 170),
		Visible = config.ShowGameCard ~= false,
		Parent = content,
	})
	Corner(hero, 10)
	Stroke(hero, Theme.Border, 0.3)

	local heroImage = New("ImageLabel", {
		BackgroundColor3 = Theme.Panel2,
		BorderSizePixel = 0,
		Image = config.GameImage or "",
		ScaleType = Enum.ScaleType.Crop,
		Position = UDim2.new(0.44, 0, 0, 0),
		Size = UDim2.new(0.56, 0, 1, 0),
		Parent = hero,
	})
	Corner(heroImage, 10)

	local heroGradient = New("UIGradient", {
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.55, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = heroImage,
	})

	local gameTag = Text(hero, "CURRENT GAME", 11, Theme.Accent2, true)
	gameTag.Position = UDim2.fromOffset(18, 14)
	gameTag.Size = UDim2.new(0.42, -18, 0, 20)

	local heroTitle = Text(hero, config.GameTitle or "Your Game", 26, Theme.Text, true)
	heroTitle.Position = UDim2.fromOffset(18, 38)
	heroTitle.Size = UDim2.new(0.43, -24, 0, 40)

	local heroDesc = Text(hero, config.GameDescription or "Set your game name, image and description here.", 12, Theme.SubText, false)
	heroDesc.Position = UDim2.fromOffset(18, 80)
	heroDesc.Size = UDim2.new(0.43, -24, 0, 42)
	heroDesc.TextWrapped = true
	heroDesc.TextYAlignment = Enum.TextYAlignment.Top

	local heroButton = MakeButtonBase(hero, config.GameButtonText or "Execute")
	heroButton.BackgroundColor3 = Theme.Accent
	heroButton.Position = UDim2.fromOffset(18, 126)
	heroButton.Size = UDim2.fromOffset(160, 34)

	local pages = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, config.ShowGameCard == false and 0 or 182),
		Size = UDim2.new(1, 0, 1, config.ShowGameCard == false and 0 or -182),
		Parent = content,
	})

	local selfWindow = setmetatable({
		ScreenGui = gui,
		Root = root,
		Top = top,
		Sidebar = sidebar,
		SidebarList = sidebarList,
		Content = content,
		Pages = pages,
		Hero = hero,
		HeroTitle = heroTitle,
		HeroDesc = heroDesc,
		HeroImage = heroImage,
		HeroButton = heroButton,
		Tabs = {},
		ActiveTab = nil,
		_Overlay = overlay,
		_PopupClosers = {},
		_HeroCallback = config.GameCallback,
	}, WindowAPI)

	heroButton.MouseButton1Click:Connect(function()
		SafeCall(selfWindow._HeroCallback)
	end)

	close.MouseButton1Click:Connect(function()
		selfWindow:Destroy()
	end)
	minimize.MouseButton1Click:Connect(function()
		content.Visible = not content.Visible
		sidebar.Visible = content.Visible
		root.Size = content.Visible and UDim2.fromOffset(1060, 650) or UDim2.fromOffset(1060, 74)
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if config.ToggleKey and input.KeyCode == config.ToggleKey then
			selfWindow:Toggle()
		end
	end)

	return selfWindow
end

XDFLEX.Theme = Theme
return XDFLEX
