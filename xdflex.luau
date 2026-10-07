--!strict
-- XDFLEX UI Library v2
-- Compact modern dark UI, designed for PC + Mobile.
-- API: Window -> Tab -> Section -> Toggle/Button/Slider/Dropdown/MultiDropdown/Input/Keybind/Label/GameCard

local XDFLEX = {}
XDFLEX.__index = XDFLEX

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Theme = {
	Background = Color3.fromRGB(7, 10, 15),
	Sidebar = Color3.fromRGB(9, 12, 18),
	Panel = Color3.fromRGB(12, 16, 23),
	Panel2 = Color3.fromRGB(15, 20, 29),
	Panel3 = Color3.fromRGB(18, 25, 36),
	Hover = Color3.fromRGB(22, 31, 44),
	Line = Color3.fromRGB(30, 42, 58),
	Line2 = Color3.fromRGB(22, 32, 46),
	Accent = Color3.fromRGB(25, 126, 255),
	Accent2 = Color3.fromRGB(0, 204, 255),
	Text = Color3.fromRGB(238, 243, 249),
	SubText = Color3.fromRGB(134, 146, 162),
	Muted = Color3.fromRGB(76, 91, 110),
	Success = Color3.fromRGB(67, 224, 164),
	Danger = Color3.fromRGB(255, 93, 111),
}

local ICONS = {
	Home = "⌂",
	Main = "◆",
	Visuals = "◉",
	Player = "♙",
	Teleports = "➤",
	Settings = "⚙",
}

local function New(className: string, props: {[string]: any}?)
	local obj = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			(obj :: any)[k] = v
		end
	end
	return obj
end

local function Corner(parent: Instance, r: number?)
	return New("UICorner", {CornerRadius = UDim.new(0, r or 6), Parent = parent})
end

local function Stroke(parent: Instance, color: Color3?, transparency: number?)
	return New("UIStroke", {
		Color = color or Theme.Line,
		Transparency = transparency or 0,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function Pad(parent: Instance, l: number, r: number?, t: number?, b: number?)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l),
		PaddingRight = UDim.new(0, r or l),
		PaddingTop = UDim.new(0, t or l),
		PaddingBottom = UDim.new(0, b or t or l),
		Parent = parent,
	})
end

local function Tween(obj: Instance, t: number, props: {[string]: any})
	local tw = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function Safe(cb, ...)
	if typeof(cb) ~= "function" then return end
	task.spawn(function(...)
		local ok, err = pcall(cb, ...)
		if not ok then warn("[XDFLEX UI]", err) end
	end, ...)
end

local function Label(parent: Instance, text: string, size: number, color: Color3?, bold: boolean?)
	return New("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color or Theme.Text,
		TextSize = size,
		Font = bold and Enum.Font.GothamSemibold or Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = parent,
	})
end

local function resolveParent()
	local ok, hui = pcall(function()
		if typeof(gethui) == "function" then
			return gethui()
		end
	end)
	if ok and hui then return hui end
	return CoreGui
end

local function draggable(handle: GuiObject, target: GuiObject)
	local dragging = false
	local startPos: UDim2? = nil
	local startMouse: Vector2? = nil

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = target.Position
			startMouse = input.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging or not startPos or not startMouse then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - startMouse
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local function autoCanvas(scroll: ScrollingFrame, layout: UIListLayout, extra: number?)
	local function update()
		scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + (extra or 10))
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
	update()
end

local function row(parent: Instance, h: number?)
	local f = New("Frame", {
		BackgroundColor3 = Theme.Panel2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, h or 42),
		Parent = parent,
	})
	Corner(f, 5)
	Stroke(f, Theme.Line2, 0.12)
	return f
end

local function titleBlock(parent: Instance, title: string, desc: string?)
	local t = Label(parent, title, 13, Theme.Text, true)
	t.Position = UDim2.fromOffset(11, desc and 5 or 0)
	t.Size = UDim2.new(0.6, -8, 0, desc and 18 or 42)
	if desc and desc ~= "" then
		local d = Label(parent, desc, 10, Theme.SubText, false)
		d.Position = UDim2.fromOffset(11, 22)
		d.Size = UDim2.new(0.62, -8, 0, 14)
	end
end

local function compactButton(parent: Instance, text: string)
	local b = New("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Panel3,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		Parent = parent,
	})
	Corner(b, 5)
	Stroke(b, Theme.Line, 0)
	b.MouseEnter:Connect(function() Tween(b, .12, {BackgroundColor3 = Theme.Hover}) end)
	b.MouseLeave:Connect(function() Tween(b, .12, {BackgroundColor3 = Theme.Panel3}) end)
	return b
end

-- =========================
-- WINDOW
-- =========================

local Window = {}
Window.__index = Window

function XDFLEX:CreateWindow(cfg)
	cfg = cfg or {}

	local gui = New("ScreenGui", {
		Name = cfg.Name or "XDFLEX_UI",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = resolveParent(),
	})

	local root = New("Frame", {
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(.5,.5),
		Position = UDim2.fromScale(.5,.5),
		Size = UDim2.fromOffset(cfg.Width or 820, cfg.Height or 520),
		Parent = gui,
	})
	Corner(root, 8)
	Stroke(root, Color3.fromRGB(20,42,70), 0)

	local scale = New("UIScale", {Scale = 1, Parent = root})
	local function updateScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		local sx = vp.X / ((cfg.Width or 820) + 80)
		local sy = vp.Y / ((cfg.Height or 520) + 80)
		scale.Scale = math.clamp(math.min(sx, sy), .68, 1)
	end
	updateScale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end

	local header = New("Frame", {
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Size = UDim2.new(1,0,0,52),
		Parent = root,
	})
	Corner(header, 8)
	New("Frame", {
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(0,0,1,-8),
		Size = UDim2.new(1,0,0,8),
		Parent = header,
	})

	local logoWrap = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12,7),
		Size = UDim2.fromOffset(40,38),
		Parent = header,
	})

	local logo = New("ImageLabel", {
		BackgroundTransparency = 1,
		Image = cfg.Logo or "rbxthumb://type=Asset&id=79389153354922&w=150&h=150",
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(1,1),
		Parent = logoWrap,
	})

	local brand = Label(header, cfg.Title or "XDFLEX HUB", 15, Theme.Text, true)
	brand.Position = UDim2.fromOffset(56,5)
	brand.Size = UDim2.new(0,250,0,24)

	local subtitle = Label(header, cfg.Subtitle or "Premium Script Interface", 9, Theme.SubText, false)
	subtitle.Position = UDim2.fromOffset(56,25)
	subtitle.Size = UDim2.new(0,280,0,16)

	local statusDot = New("Frame", {
		BackgroundColor3 = Theme.Success,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(6,6),
		Position = UDim2.new(1,-190,.5,-3),
		Parent = header,
	})
	Corner(statusDot, 99)

	local statusText = Label(header, cfg.Status or "Stable", 10, Theme.SubText, true)
	statusText.Position = UDim2.new(1,-178,0,0)
	statusText.Size = UDim2.fromOffset(68,52)

	local min = compactButton(header, "—")
	min.Size = UDim2.fromOffset(30,28)
	min.Position = UDim2.new(1,-72,0,12)

	local close = compactButton(header, "×")
	close.Size = UDim2.fromOffset(30,28)
	close.Position = UDim2.new(1,-36,0,12)

	draggable(header, root)

	local sidebar = New("Frame", {
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(8,60),
		Size = UDim2.new(0,158,1,-68),
		Parent = root,
	})
	Corner(sidebar, 7)
	Stroke(sidebar, Theme.Line2, 0)

	local tabsWrap = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8,8),
		Size = UDim2.new(1,-16,1,-70),
		Parent = sidebar,
	})
	local tabsLayout = New("UIListLayout", {
		Padding = UDim.new(0,4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabsWrap,
	})

	local foot = Label(sidebar, (cfg.Title or "XDFLEX HUB") .. "\nv2.0.0", 9, Theme.SubText, true)
	foot.Position = UDim2.new(0,10,1,-52)
	foot.Size = UDim2.new(1,-20,0,42)
	foot.TextYAlignment = Enum.TextYAlignment.Bottom

	local main = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(174,60),
		Size = UDim2.new(1,-182,1,-68),
		Parent = root,
	})

	local pageHolder = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1,1),
		Parent = main,
	})

	local popupLayer = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1,1),
		ZIndex = 100,
		Parent = gui,
	})

	local self = setmetatable({
		Gui = gui,
		Root = root,
		Header = header,
		Sidebar = sidebar,
		TabsWrap = tabsWrap,
		Main = main,
		PageHolder = pageHolder,
		PopupLayer = popupLayer,
		Tabs = {},
		ActiveTab = nil,
		PopupClosers = {},
	}, Window)

	close.MouseButton1Click:Connect(function() self:Destroy() end)
	min.MouseButton1Click:Connect(function()
		local hide = main.Visible
		main.Visible = not hide
		sidebar.Visible = not hide
		root.Size = hide and UDim2.fromOffset(cfg.Width or 820,52) or UDim2.fromOffset(cfg.Width or 820,cfg.Height or 520)
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if cfg.ToggleKey and input.KeyCode == cfg.ToggleKey then
			self.Root.Visible = not self.Root.Visible
		end
	end)

	return self
end

function Window:_closePopups()
	for _,fn in ipairs(self.PopupClosers) do pcall(fn) end
end

function Window:_registerPopup(fn)
	table.insert(self.PopupClosers, fn)
end

function Window:Destroy()
	if self.Gui then self.Gui:Destroy() end
end

function Window:SetVisible(v)
	self.Root.Visible = v == true
end

function Window:Toggle()
	self.Root.Visible = not self.Root.Visible
end

-- =========================
-- TAB
-- =========================

local Tab = {}
Tab.__index = Tab

function Window:Tab(cfg)
	cfg = cfg or {}
	local name = cfg.Name or cfg.Title or "Tab"

	local b = New("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Panel3,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		Size = UDim2.new(1,0,0,36),
		Parent = self.TabsWrap,
	})
	Corner(b, 5)

	local icon = Label(b, cfg.Icon or ICONS[name] or "•", 13, Theme.SubText, true)
	icon.Position = UDim2.fromOffset(10,0)
	icon.Size = UDim2.fromOffset(22,36)
	icon.TextXAlignment = Enum.TextXAlignment.Center

	local txt = Label(b, name, 11, Theme.SubText, true)
	txt.Position = UDim2.fromOffset(40,0)
	txt.Size = UDim2.new(1,-46,1,0)

	local page = New("Frame", {
		BackgroundTransparency = 1,
		Visible = false,
		Size = UDim2.fromScale(1,1),
		Parent = self.PageHolder,
	})

	local title = Label(page, cfg.PageTitle or name, 12, Theme.SubText, true)
	title.Size = UDim2.new(1,0,0,20)

	local cols = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0,24),
		Size = UDim2.new(1,0,1,-24),
		Parent = page,
	})

	local left = New("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		Size = UDim2.new(.5,-5,1,0),
		CanvasSize = UDim2.new(),
		Parent = cols,
	})
	local right = New("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		Position = UDim2.new(.5,5,0,0),
		Size = UDim2.new(.5,-5,1,0),
		CanvasSize = UDim2.new(),
		Parent = cols,
	})
	Pad(left,0,4,0,8); Pad(right,4,0,0,8)
	local ll = New("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,Parent=left})
	local rl = New("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,Parent=right})
	autoCanvas(left,ll,10); autoCanvas(right,rl,10)

	local tab = setmetatable({
		Window = self,
		Name = name,
		Button = b,
		Icon = icon,
		Label = txt,
		Page = page,
		Left = left,
		Right = right,
	}, Tab)

	function tab:Select()
		self.Window:_closePopups()
		for _,other in ipairs(self.Window.Tabs) do
			local active = other == self
			other.Page.Visible = active
			Tween(other.Button,.12,{
				BackgroundTransparency = active and 0 or 1,
				BackgroundColor3 = active and Color3.fromRGB(15,48,88) or Theme.Panel3
			})
			other.Icon.TextColor3 = active and Theme.Accent2 or Theme.SubText
			other.Label.TextColor3 = active and Theme.Text or Theme.SubText
		end
		self.Window.ActiveTab = self
	end

	b.MouseButton1Click:Connect(function() tab:Select() end)
	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then tab:Select() end
	return tab
end

-- =========================
-- SECTION + ELEMENTS
-- =========================

local Section = {}
Section.__index = Section

function Tab:Section(cfg)
	cfg = cfg or {}
	local parent = ((cfg.Side or "Left") == "Right") and self.Right or self.Left

	local box = New("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1,0,0,0),
		Parent = parent,
	})
	Corner(box, 6)
	Stroke(box, Theme.Line2, 0)

	local accent = New("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0,0),
		Size = UDim2.fromOffset(2,28),
		Parent = box,
	})
	Corner(accent, 2)

	local title = Label(box, cfg.Title or cfg.Name or "Section", 12, Theme.Text, true)
	title.Position = UDim2.fromOffset(10,3)
	title.Size = UDim2.new(1,-20,0,22)

	local content = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(7,31),
		Size = UDim2.new(1,-14,0,0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = box,
	})
	local layout = New("UIListLayout", {
		Padding = UDim.new(0,5),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = content,
	})
	New("UIPadding",{PaddingBottom=UDim.new(0,7),Parent=content})

	return setmetatable({
		Tab = self,
		Window = self.Window,
		Root = box,
		Container = content,
	}, Section)
end

function Section:Label(cfg)
	cfg = cfg or {}
	local r = row(self.Container, cfg.Description and 48 or 36)
	titleBlock(r, cfg.Title or cfg.Name or "Label", cfg.Description)
	return r
end

function Section:Button(cfg)
	cfg = cfg or {}
	local r = row(self.Container, 42)
	titleBlock(r, cfg.Title or cfg.Name or "Button", cfg.Description)
	local b = compactButton(r, cfg.ButtonText or "Execute")
	b.AnchorPoint = Vector2.new(1,.5)
	b.Position = UDim2.new(1,-8,.5,0)
	b.Size = UDim2.fromOffset(cfg.Width or 130,28)
	b.MouseButton1Click:Connect(function()
		Tween(b,.08,{BackgroundColor3=Theme.Accent})
		task.delay(.1,function() if b.Parent then Tween(b,.12,{BackgroundColor3=Theme.Panel3}) end end)
		Safe(cfg.Callback)
	end)
	return {Instance=r, Press=function() Safe(cfg.Callback) end}
end

function Section:Toggle(cfg)
	cfg = cfg or {}
	local state = cfg.Default == true
	local r = row(self.Container, cfg.Description and 48 or 42)
	titleBlock(r, cfg.Title or cfg.Name or "Toggle", cfg.Description)

	local track = New("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(30,40,54),
		BorderSizePixel = 0,
		Text = "",
		AnchorPoint = Vector2.new(1,.5),
		Position = UDim2.new(1,-9,.5,0),
		Size = UDim2.fromOffset(34,18),
		Parent = r,
	})
	Corner(track,99)

	local knob = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(245,248,252),
		BorderSizePixel = 0,
		Position = state and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2),
		Size = UDim2.fromOffset(14,14),
		Parent = track,
	})
	Corner(knob,99)

	local api = {Instance=r}
	local function set(v,silent)
		state = v == true
		Tween(track,.13,{BackgroundColor3=state and Theme.Accent or Color3.fromRGB(30,40,54)})
		Tween(knob,.13,{Position=state and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2)})
		if not silent then Safe(cfg.Callback,state) end
	end
	track.MouseButton1Click:Connect(function() set(not state,false) end)
	function api:SetValue(v,silent) set(v,silent) end
	function api:GetValue() return state end
	return api
end

function Section:Input(cfg)
	cfg = cfg or {}
	local r = row(self.Container, 42)
	titleBlock(r, cfg.Title or cfg.Name or "Input", cfg.Description)

	local box = New("TextBox", {
		BackgroundColor3 = Theme.Panel3,
		BorderSizePixel = 0,
		Text = tostring(cfg.Default or ""),
		PlaceholderText = cfg.Placeholder or "Enter value...",
		PlaceholderColor3 = Theme.Muted,
		TextColor3 = Theme.Text,
		TextSize = 11,
		Font = Enum.Font.Gotham,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(1,.5),
		Position = UDim2.new(1,-8,.5,0),
		Size = UDim2.fromOffset(cfg.Width or 142,28),
		Parent = r,
	})
	Corner(box,5); Stroke(box,Theme.Line,0); Pad(box,8,8,0,0)

	box.FocusLost:Connect(function(enter)
		local val:any = box.Text
		if cfg.Numeric then
			local n = tonumber(box.Text)
			if n ~= nil then val = n else return end
		end
		Safe(cfg.Callback,val,enter)
	end)

	return {
		Instance=r,
		SetValue=function(_,v) box.Text=tostring(v or "") end,
		GetValue=function() return cfg.Numeric and tonumber(box.Text) or box.Text end,
	}
end

function Section:Slider(cfg)
	cfg = cfg or {}
	local min = tonumber(cfg.Min) or 0
	local max = tonumber(cfg.Max) or 100
	local step = tonumber(cfg.Step) or 1
	local value = math.clamp(tonumber(cfg.Default) or min,min,max)
	local dragging = false

	local r = row(self.Container, 56)
	titleBlock(r, cfg.Title or cfg.Name or "Slider", cfg.Description)

	local valueText = Label(r, tostring(value), 10, Theme.SubText, true)
	valueText.AnchorPoint = Vector2.new(1,0)
	valueText.Position = UDim2.new(1,-9,0,5)
	valueText.Size = UDim2.fromOffset(52,18)
	valueText.TextXAlignment = Enum.TextXAlignment.Right

	local track = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(31,42,57),
		BorderSizePixel = 0,
		Position = UDim2.new(0,11,1,-13),
		Size = UDim2.new(1,-22,0,4),
		Parent = r,
	})
	Corner(track,99)

	local fill = New("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(fill,99)

	local knob = New("Frame", {
		BackgroundColor3 = Theme.Accent2,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(.5,.5),
		Size = UDim2.fromOffset(10,10),
		Parent = track,
	})
	Corner(knob,99)

	local function quant(v)
		if step <= 0 then return v end
		return math.floor((v/step)+.5)*step
	end

	local api = {Instance=r}
	local function set(v,silent)
		value = math.clamp(quant(tonumber(v) or min),min,max)
		local a = max==min and 0 or (value-min)/(max-min)
		fill.Size = UDim2.new(a,0,1,0)
		knob.Position = UDim2.new(a,0,.5,0)
		valueText.Text = tostring(value)
		if not silent then Safe(cfg.Callback,value) end
	end
	local function fromX(x)
		local a = math.clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
		set(min+(max-min)*a,false)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true; fromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
	end)
	function api:SetValue(v,silent) set(v,silent) end
	function api:GetValue() return value end
	set(value,true)
	return api
end

local function makeDropdown(section, cfg, multi)
	cfg = cfg or {}
	local values = cfg.Values or cfg.Options or {}
	local selected:any = multi and {} or cfg.Default
	if not multi and selected == nil then selected = values[1] end
	if multi and type(cfg.Default)=="table" then
		for _,v in ipairs(cfg.Default) do selected[v]=true end
	end

	local r = row(section.Container, 42)
	titleBlock(r, cfg.Title or cfg.Name or (multi and "Multi Select" or "Dropdown"), cfg.Description)

	local field = compactButton(r,"")
	field.AnchorPoint = Vector2.new(1,.5)
	field.Position = UDim2.new(1,-8,.5,0)
	field.Size = UDim2.fromOffset(cfg.Width or 152,28)
	field.TextXAlignment = Enum.TextXAlignment.Left
	Pad(field,8,22,0,0)

	local arrow = Label(field,"⌄",13,Theme.SubText,true)
	arrow.AnchorPoint = Vector2.new(1,.5)
	arrow.Position = UDim2.new(1,-5,.5,-1)
	arrow.Size = UDim2.fromOffset(16,18)
	arrow.TextXAlignment = Enum.TextXAlignment.Center

	local popup = New("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 120,
		Parent = section.Window.PopupLayer,
	})
	Corner(popup,6); Stroke(popup,Theme.Line,0)

	local sc = New("ScrollingFrame",{
		BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=2,ScrollBarImageColor3=Theme.Accent,
		Size=UDim2.fromScale(1,1),CanvasSize=UDim2.new(),ZIndex=121,Parent=popup
	})
	Pad(sc,5,5,5,5)
	local lay = New("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder,Parent=sc})
	autoCanvas(sc,lay,8)

	local opened=false
	local api={Instance=r}

	local function currentText()
		if multi then
			local arr={}
			for _,v in ipairs(values) do if selected[v] then table.insert(arr,tostring(v)) end end
			if #arr==0 then return cfg.Placeholder or "Select..." end
			if #arr==1 then return arr[1] end
			if #arr==2 then return arr[1]..", "..arr[2] end
			return arr[1].." +"..tostring(#arr-1)
		end
		return selected~=nil and tostring(selected) or (cfg.Placeholder or "Select...")
	end

	local function emit()
		if multi then
			local arr={}
			for _,v in ipairs(values) do if selected[v] then table.insert(arr,v) end end
			Safe(cfg.Callback,arr)
		else
			Safe(cfg.Callback,selected)
		end
	end

	local function position()
		local pos=field.AbsolutePosition
		local sz=field.AbsoluteSize
		local cam=workspace.CurrentCamera
		local vp=cam and cam.ViewportSize or Vector2.new(1920,1080)
		local w=math.max(sz.X,165)
		local h=math.min(#values*30+10,190)
		local x=math.clamp(pos.X,6,vp.X-w-6)
		local y=pos.Y+sz.Y+4
		if y+h>vp.Y-6 then y=math.max(6,pos.Y-h-4) end
		popup.Position=UDim2.fromOffset(x,y)
		popup.Size=UDim2.fromOffset(w,h)
	end

	local function close()
		opened=false; popup.Visible=false; arrow.Text="⌄"
	end

	local function refresh()
		field.Text=currentText()
	end

	local function rebuild()
		for _,c in ipairs(sc:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for _,v in ipairs(values) do
			local opt=New("TextButton",{
				AutoButtonColor=false,BackgroundColor3=Theme.Panel2,BorderSizePixel=0,
				Size=UDim2.new(1,0,0,27),Text="",ZIndex=122,Parent=sc
			})
			Corner(opt,4)
			local tx=Label(opt,tostring(v),10,Theme.Text,false)
			tx.Position=UDim2.fromOffset(8,0); tx.Size=UDim2.new(1,-30,1,0); tx.ZIndex=123
			if multi then
				local mark=Label(opt,selected[v] and "✓" or "",11,Theme.Accent2,true)
				mark.AnchorPoint=Vector2.new(1,.5); mark.Position=UDim2.new(1,-7,.5,0)
				mark.Size=UDim2.fromOffset(18,18); mark.TextXAlignment=Enum.TextXAlignment.Center; mark.ZIndex=123
				opt.MouseButton1Click:Connect(function()
					selected[v]=not selected[v] or nil
					mark.Text=selected[v] and "✓" or ""
					refresh(); emit()
				end)
			else
				opt.MouseButton1Click:Connect(function()
					selected=v; refresh(); emit(); close()
				end)
			end
			opt.MouseEnter:Connect(function() Tween(opt,.1,{BackgroundColor3=Theme.Hover}) end)
			opt.MouseLeave:Connect(function() Tween(opt,.1,{BackgroundColor3=Theme.Panel2}) end)
		end
	end

	field.MouseButton1Click:Connect(function()
		section.Window:_closePopups()
		opened=true; position(); popup.Visible=true; arrow.Text="⌃"
	end)
	section.Window:_registerPopup(close)

	function api:SetValues(vs)
		values=vs or {}
		if multi then selected={} elseif table.find(values,selected)==nil then selected=values[1] end
		rebuild(); refresh()
	end
	function api:SetValue(v,silent)
		if multi then
			selected={}
			if type(v)=="table" then for _,x in ipairs(v) do selected[x]=true end end
		else selected=v end
		rebuild(); refresh()
		if not silent then emit() end
	end
	function api:GetValue()
		if not multi then return selected end
		local arr={}
		for _,v in ipairs(values) do if selected[v] then table.insert(arr,v) end end
		return arr
	end

	rebuild(); refresh()
	return api
end

function Section:Dropdown(cfg) return makeDropdown(self,cfg,false) end
function Section:MultiDropdown(cfg) return makeDropdown(self,cfg,true) end
Section.MultiSelect = Section.MultiDropdown

function Section:Keybind(cfg)
	cfg = cfg or {}
	local current = cfg.Default or Enum.KeyCode.RightShift
	local listening=false
	local r=row(self.Container,42)
	titleBlock(r,cfg.Title or cfg.Name or "Keybind",cfg.Description)
	local b=compactButton(r,current.Name)
	b.AnchorPoint=Vector2.new(1,.5); b.Position=UDim2.new(1,-8,.5,0); b.Size=UDim2.fromOffset(110,28)

	b.MouseButton1Click:Connect(function()
		listening=true; b.Text="Press key..."
	end)
	UserInputService.InputBegan:Connect(function(input,gp)
		if gp then return end
		if listening and input.KeyCode~=Enum.KeyCode.Unknown then
			current=input.KeyCode; b.Text=current.Name; listening=false
			Safe(cfg.Changed,current)
			return
		end
		if not listening and input.KeyCode==current then Safe(cfg.Callback,current) end
	end)

	return {
		Instance=r,
		GetValue=function() return current end,
		SetValue=function(_,v) if typeof(v)=="EnumItem" then current=v; b.Text=v.Name end end
	}
end

-- A compact game/map card for Home page.
function Tab:GameCard(cfg)
	cfg = cfg or {}
	local parent = ((cfg.Side or "Left")=="Right") and self.Right or self.Left
	local card = New("Frame", {
		BackgroundColor3=Theme.Panel,BorderSizePixel=0,
		Size=UDim2.new(1,0,0,cfg.Height or 176),Parent=parent
	})
	Corner(card,7); Stroke(card,Theme.Line2,0)

	local img = New("ImageLabel",{
		BackgroundColor3=Theme.Panel2,BorderSizePixel=0,
		Image=cfg.Image or "",ScaleType=Enum.ScaleType.Crop,
		Position=UDim2.fromOffset(7,7),Size=UDim2.new(1,-14,0,92),Parent=card
	})
	Corner(img,6)

	local title=Label(card,cfg.Title or "Current Game",14,Theme.Text,true)
	title.Position=UDim2.fromOffset(10,105); title.Size=UDim2.new(1,-20,0,22)
	local desc=Label(card,cfg.Description or "",10,Theme.SubText,false)
	desc.Position=UDim2.fromOffset(10,126); desc.Size=UDim2.new(1,-118,0,38)
	desc.TextWrapped=true; desc.TextYAlignment=Enum.TextYAlignment.Top

	local b=compactButton(card,cfg.ButtonText or "Execute")
	b.AnchorPoint=Vector2.new(1,1); b.Position=UDim2.new(1,-9,1,-9); b.Size=UDim2.fromOffset(100,28)
	b.MouseButton1Click:Connect(function() Safe(cfg.Callback) end)

	return {Instance=card,SetImage=function(_,v) img.Image=v end}
end

XDFLEX.Theme = Theme
return XDFLEX
