--!nocheck
-- XDFLEX UI v3
-- Futuristic / Jarvis-inspired UI library for Roblox executors
-- Includes: animated loader, window, tabs, sections, toggle, button, slider,
-- dropdown, multi-dropdown, input, keybind, label, status card, game card.

local XDFLEX = {}
XDFLEX.__index = XDFLEX

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer

local Theme = {
    Bg = Color3.fromRGB(4, 7, 13),
    Bg2 = Color3.fromRGB(7, 11, 18),
    Panel = Color3.fromRGB(9, 14, 23),
    Panel2 = Color3.fromRGB(12, 18, 29),
    Panel3 = Color3.fromRGB(16, 24, 38),
    Hover = Color3.fromRGB(20, 32, 49),
    Border = Color3.fromRGB(27, 49, 76),
    BorderStrong = Color3.fromRGB(15, 101, 182),
    Accent = Color3.fromRGB(0, 145, 255),
    Accent2 = Color3.fromRGB(0, 222, 255),
    Accent3 = Color3.fromRGB(65, 105, 255),
    Text = Color3.fromRGB(238, 245, 252),
    Sub = Color3.fromRGB(145, 160, 181),
    Muted = Color3.fromRGB(86, 103, 126),
    Success = Color3.fromRGB(55, 227, 153),
    Warning = Color3.fromRGB(255, 190, 70),
    Danger = Color3.fromRGB(255, 88, 110),
}

local function New(className, props)
    local o = Instance.new(className)
    if props then
        for k,v in pairs(props) do
            o[k] = v
        end
    end
    return o
end

local function Corner(parent, r)
    return New("UICorner", {
        CornerRadius = UDim.new(0, r or 6),
        Parent = parent
    })
end

local function Stroke(parent, color, transparency, thickness)
    return New("UIStroke", {
        Color = color or Theme.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function Pad(parent, l, r, t, b)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or l or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or t or 0),
        Parent = parent
    })
end

local function Tween(obj, time, props, style, dir)
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(time or .18, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function SafeCall(fn, ...)
    if typeof(fn) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(function()
            fn(table.unpack(args, 1, args.n))
        end)
        if not ok then
            warn("[XDFLEX UI] Callback error:", err)
        end
    end)
end

local function Txt(parent, text, size, color, bold)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or Theme.Text,
        TextSize = size or 12,
        Font = bold and Enum.Font.GothamSemibold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = parent
    })
end

local function ResolveParent()
    local ok, hui = pcall(function()
        if typeof(gethui) == "function" then
            return gethui()
        end
    end)
    if ok and hui then return hui end
    return CoreGui
end

local function MakeDraggable(handle, target)
    local dragging = false
    local startMouse
    local startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startMouse = input.Position
            startPos = target.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or not startMouse or not startPos then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - startMouse
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
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

local function AutoCanvas(scroll, layout, extra)
    local function update()
        scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + (extra or 12))
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    update()
end

local function ButtonBase(parent, text)
    local b = New("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        Text = text or "",
        TextColor3 = Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        Parent = parent
    })
    Corner(b, 5)
    Stroke(b, Theme.Border, 0)
    b.MouseEnter:Connect(function()
        Tween(b, .12, {BackgroundColor3 = Theme.Hover})
    end)
    b.MouseLeave:Connect(function()
        Tween(b, .12, {BackgroundColor3 = Theme.Panel3})
    end)
    return b
end

local function CreateRow(parent, h)
    local r = New("Frame", {
        BackgroundColor3 = Theme.Panel2,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, h or 42),
        Parent = parent
    })
    Corner(r, 5)
    Stroke(r, Theme.Border, .18)
    return r
end

local function TitleBlock(parent, title, desc, rightReserve)
    rightReserve = rightReserve or 180

    local t = Txt(parent, title or "Item", 12, Theme.Text, true)
    t.Position = UDim2.fromOffset(11, desc and 4 or 0)
    t.Size = UDim2.new(1, -(rightReserve + 16), 0, desc and 18 or 42)

    if desc and desc ~= "" then
        local d = Txt(parent, desc, 9, Theme.Sub, false)
        d.Position = UDim2.fromOffset(11, 21)
        d.Size = UDim2.new(1, -(rightReserve + 16), 0, 15)
        d.TextTruncate = Enum.TextTruncate.AtEnd
    end
end

-- =========================================================
-- LOADER
-- =========================================================

function XDFLEX:ShowLoader(cfg)
    cfg = cfg or {}
    local gui = New("ScreenGui", {
        Name = "XDFLEX_Loader",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = ResolveParent()
    })

    local root = New("Frame", {
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1,1),
        Parent = gui
    })

    local vignette = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = .35,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1,1),
        Parent = root
    })

    local grid = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,1),
        Parent = root
    })

    for i = 1, 14 do
        New("Frame", {
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = .93,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, i/14, 0),
            Size = UDim2.new(1, 0, 0, 1),
            Parent = grid
        })
    end

    for i = 1, 20 do
        New("Frame", {
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = .95,
            BorderSizePixel = 0,
            Position = UDim2.new(i/20, 0, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            Parent = grid
        })
    end

    local topLine = New("Frame", {
        BackgroundColor3 = Theme.Accent2,
        BackgroundTransparency = .4,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1,0,0,2),
        Parent = root
    })

    local logoWrap = New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(.5,.5),
        Position = UDim2.fromScale(.5,.37),
        Size = UDim2.fromOffset(220,220),
        Parent = root
    })

    -- scanner ring 1
    local ring1 = New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(.5,.5),
        Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromOffset(210,210),
        Parent = logoWrap
    })
    Corner(ring1, 999)
    local s1 = Stroke(ring1, Theme.Accent, .25, 2)

    -- scanner ring 2
    local ring2 = New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(.5,.5),
        Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromOffset(170,170),
        Parent = logoWrap
    })
    Corner(ring2, 999)
    local s2 = Stroke(ring2, Theme.Accent2, .45, 1)

    local logo = New("ImageLabel", {
        BackgroundTransparency = 1,
        Image = cfg.Logo or "rbxthumb://type=Asset&id=79389153354922&w=420&h=420",
        ScaleType = Enum.ScaleType.Fit,
        AnchorPoint = Vector2.new(.5,.5),
        Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromOffset(125,125),
        Parent = logoWrap
    })

    local brand = Txt(root, cfg.Title or "XDFLEX HUB", 28, Theme.Text, true)
    brand.AnchorPoint = Vector2.new(.5,0)
    brand.Position = UDim2.new(.5,0,.52,0)
    brand.Size = UDim2.fromOffset(450,40)
    brand.TextXAlignment = Enum.TextXAlignment.Center

    local sub = Txt(root, cfg.Subtitle or "INITIALIZING CORE SYSTEM", 11, Theme.Accent2, true)
    sub.AnchorPoint = Vector2.new(.5,0)
    sub.Position = UDim2.new(.5,0,.565,0)
    sub.Size = UDim2.fromOffset(500,24)
    sub.TextXAlignment = Enum.TextXAlignment.Center

    local barBack = New("Frame", {
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(.5,0),
        Position = UDim2.new(.5,0,.625,0),
        Size = UDim2.fromOffset(520,16),
        Parent = root
    })
    Corner(barBack, 99)
    Stroke(barBack, Theme.BorderStrong, .1)

    local bar = New("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0,0,1,0),
        Parent = barBack
    })
    Corner(bar, 99)

    local barGlow = Stroke(bar, Theme.Accent2, .1, 1)

    local pct = Txt(root, "0%", 16, Theme.Text, true)
    pct.AnchorPoint = Vector2.new(.5,0)
    pct.Position = UDim2.new(.5,0,.652,0)
    pct.Size = UDim2.fromOffset(120,25)
    pct.TextXAlignment = Enum.TextXAlignment.Center

    local status = Txt(root, "Boot sequence started...", 10, Theme.Sub, false)
    status.AnchorPoint = Vector2.new(.5,0)
    status.Position = UDim2.new(.5,0,.69,0)
    status.Size = UDim2.fromOffset(560,24)
    status.TextXAlignment = Enum.TextXAlignment.Center

    -- left module list
    local modulesPanel = New("Frame", {
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = .1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(28, 72),
        Size = UDim2.fromOffset(260, 360),
        Parent = root
    })
    Corner(modulesPanel, 7)
    Stroke(modulesPanel, Theme.BorderStrong, .25)

    local mpTitle = Txt(modulesPanel, "SYSTEM INITIALIZATION", 11, Theme.Accent2, true)
    mpTitle.Position = UDim2.fromOffset(12,8)
    mpTitle.Size = UDim2.new(1,-24,0,24)

    local mList = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10,40),
        Size = UDim2.new(1,-20,1,-50),
        Parent = modulesPanel
    })
    local mLayout = New("UIListLayout", {
        Padding = UDim.new(0,6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = mList
    })

    local moduleNames = cfg.Modules or {
        "UI Core",
        "Visual Engine",
        "Config Manager",
        "Input Layer",
        "Automation Module",
        "Teleport System",
        "Player Enhancements",
        "Script Engine",
    }
    local moduleRows = {}

    for _, name in ipairs(moduleNames) do
        local rr = New("Frame", {
            BackgroundColor3 = Theme.Panel2,
            BorderSizePixel = 0,
            Size = UDim2.new(1,0,0,32),
            Parent = mList
        })
        Corner(rr, 4)
        Stroke(rr, Theme.Border, .3)

        local dot = New("Frame", {
            BackgroundColor3 = Theme.Muted,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(9,13),
            Size = UDim2.fromOffset(6,6),
            Parent = rr
        })
        Corner(dot,99)

        local tx = Txt(rr, name, 9, Theme.Text, true)
        tx.Position = UDim2.fromOffset(23,0)
        tx.Size = UDim2.new(1,-50,1,0)

        local state = Txt(rr, "WAIT", 8, Theme.Muted, true)
        state.AnchorPoint = Vector2.new(1,.5)
        state.Position = UDim2.new(1,-7,.5,0)
        state.Size = UDim2.fromOffset(42,18)
        state.TextXAlignment = Enum.TextXAlignment.Right

        table.insert(moduleRows, {Dot=dot, State=state})
    end

    -- diagnostics panel
    local diag = New("Frame", {
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = .1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1,0),
        Position = UDim2.new(1,-28,0,72),
        Size = UDim2.fromOffset(250,210),
        Parent = root
    })
    Corner(diag,7)
    Stroke(diag,Theme.BorderStrong,.25)

    local dt = Txt(diag, "CORE MODULES", 11, Theme.Accent2, true)
    dt.Position = UDim2.fromOffset(12,8)
    dt.Size = UDim2.new(1,-24,0,22)

    local diagRows = {
        {"Assets Validation","Pending"},
        {"Module Sync","Pending"},
        {"Interface Prep","Pending"},
        {"Components","Pending"},
        {"Network Services","Pending"},
        {"Finalizing","Pending"},
    }

    for i, pair in ipairs(diagRows) do
        local y = 36 + (i-1)*27
        local name = Txt(diag, pair[1], 9, Theme.Sub, false)
        name.Position = UDim2.fromOffset(12,y)
        name.Size = UDim2.new(1,-86,0,20)

        local state = Txt(diag, pair[2], 8, Theme.Muted, true)
        state.AnchorPoint = Vector2.new(1,0)
        state.Position = UDim2.new(1,-10,0,y)
        state.Size = UDim2.fromOffset(65,20)
        state.TextXAlignment = Enum.TextXAlignment.Right
        diagRows[i][3] = state
    end

    -- bottom diagnostics
    local bottom = New("Frame", {
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = .1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(.5,1),
        Position = UDim2.new(.5,0,1,-28),
        Size = UDim2.fromOffset(640,110),
        Parent = root
    })
    Corner(bottom,7)
    Stroke(bottom,Theme.BorderStrong,.25)

    local bt = Txt(bottom, "SYSTEM DIAGNOSTICS", 10, Theme.Accent2, true)
    bt.Position = UDim2.fromOffset(12,7)
    bt.Size = UDim2.new(1,-24,0,20)

    local graph = New("Frame", {
        BackgroundColor3 = Theme.Bg2,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12,34),
        Size = UDim2.new(1,-24,0,28),
        Parent = bottom
    })
    Corner(graph,4)

    local bars = {}
    for i=1,32 do
        local h = 4 + math.random(2,22)
        bars[i] = New("Frame", {
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = .2,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0,1),
            Position = UDim2.new((i-1)/32,1,1,-2),
            Size = UDim2.new(0,4,0,h),
            Parent = graph
        })
    end

    local stats = Txt(bottom, "CPU  32%     MEMORY  48%     NETWORK  STABLE     REGION  ASIA", 9, Theme.Sub, true)
    stats.Position = UDim2.fromOffset(12,70)
    stats.Size = UDim2.new(1,-24,0,24)
    stats.TextXAlignment = Enum.TextXAlignment.Center

    -- scan line
    local scan = New("Frame", {
        BackgroundColor3 = Theme.Accent2,
        BackgroundTransparency = .72,
        BorderSizePixel = 0,
        Position = UDim2.new(0,0,-.1,0),
        Size = UDim2.new(1,0,0,2),
        Parent = root
    })

    local alive = true
    task.spawn(function()
        while alive and gui.Parent do
            scan.Position = UDim2.new(0,0,-.05,0)
            Tween(scan, 2.2, {Position=UDim2.new(0,0,1.05,0)}, Enum.EasingStyle.Linear)
            task.wait(2.25)
        end
    end)

    task.spawn(function()
        local rot = 0
        while alive and gui.Parent do
            rot += 1.4
            ring1.Rotation = rot
            ring2.Rotation = -rot * .7
            task.wait()
        end
    end)

    task.spawn(function()
        while alive and gui.Parent do
            for _,b in ipairs(bars) do
                local h = math.random(4,24)
                Tween(b, .25, {Size=UDim2.new(0,4,0,h)}, Enum.EasingStyle.Linear)
            end
            task.wait(.28)
        end
    end)

    local duration = cfg.Duration or 3.8
    local steps = {
        {0.08,"Loading UI core..."},
        {0.18,"Initializing visual engine..."},
        {0.30,"Reading configuration..."},
        {0.42,"Connecting input layer..."},
        {0.56,"Starting automation module..."},
        {0.68,"Loading teleport services..."},
        {0.80,"Syncing player enhancements..."},
        {0.92,"Preparing execution environment..."},
        {1.00,"System ready."},
    }

    for i, st in ipairs(steps) do
        local p = st[1]
        local msg = st[2]
        local target = math.floor(p * 100)
        status.Text = msg
        Tween(bar, duration/#steps*.85, {Size=UDim2.new(p,0,1,0)}, Enum.EasingStyle.Quart)
        local start = tonumber(pct.Text:match("%d+")) or 0
        for n = start, target do
            pct.Text = tostring(n) .. "%"
            task.wait((duration/#steps)/math.max(target-start+1,1))
        end

        if moduleRows[i] then
            moduleRows[i].Dot.BackgroundColor3 = Theme.Success
            moduleRows[i].State.Text = "OK"
            moduleRows[i].State.TextColor3 = Theme.Success
        end

        if i <= #diagRows then
            local s = diagRows[i][3]
            s.Text = "Complete"
            s.TextColor3 = Theme.Success
        end
    end

    task.wait(.25)

    alive = false
    for _,d in ipairs(root:GetDescendants()) do
        if d:IsA("GuiObject") then
            pcall(function()
                Tween(d,.35,{BackgroundTransparency=1})
            end)
        end
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            pcall(function()
                Tween(d,.35,{TextTransparency=1})
            end)
        end
        if d:IsA("ImageLabel") or d:IsA("ImageButton") then
            pcall(function()
                Tween(d,.35,{ImageTransparency=1})
            end)
        end
    end
    task.wait(.4)
    gui:Destroy()
end

-- =========================================================
-- WINDOW / TAB / SECTION
-- =========================================================

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

function XDFLEX:CreateWindow(cfg)
    cfg = cfg or {}

    local gui = New("ScreenGui", {
        Name = cfg.Name or "XDFLEX_UI",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = ResolveParent()
    })

    local root = New("Frame", {
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(.5,.5),
        Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromOffset(cfg.Width or 980, cfg.Height or 620),
        Parent = gui
    })
    Corner(root,9)
    Stroke(root,Theme.BorderStrong,.12,1)

    local scale = New("UIScale",{Scale=1,Parent=root})
    local function updateScale()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        scale.Scale = math.clamp(math.min(vp.X/1100, vp.Y/720), .62, 1)
    end
    updateScale()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    end

    -- top accent
    local topAccent = New("Frame", {
        BackgroundColor3 = Theme.Accent2,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0,0),
        Size = UDim2.new(1,0,0,2),
        Parent = root
    })

    local header = New("Frame", {
        BackgroundColor3 = Theme.Bg2,
        BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,66),
        Parent = root
    })
    Corner(header,9)

    local logo = New("ImageLabel", {
        BackgroundTransparency=1,
        Image=cfg.Logo or "rbxthumb://type=Asset&id=79389153354922&w=150&h=150",
        ScaleType=Enum.ScaleType.Fit,
        Position=UDim2.fromOffset(14,9),
        Size=UDim2.fromOffset(48,48),
        Parent=header
    })

    local title = Txt(header,cfg.Title or "XDFLEX HUB",17,Theme.Text,true)
    title.Position=UDim2.fromOffset(69,9)
    title.Size=UDim2.fromOffset(310,24)

    local subtitle = Txt(header,cfg.Subtitle or "Premium Roblox Script Hub",9,Theme.Sub,false)
    subtitle.Position=UDim2.fromOffset(69,31)
    subtitle.Size=UDim2.fromOffset(380,17)

    local tagline = Txt(header,cfg.Tagline or "POWER  •  AUTOMATE  •  DOMINATE",8,Theme.Accent2,true)
    tagline.Position=UDim2.fromOffset(69,47)
    tagline.Size=UDim2.fromOffset(390,13)

    local userBox = New("Frame", {
        BackgroundColor3=Theme.Panel,
        BorderSizePixel=0,
        AnchorPoint=Vector2.new(1,.5),
        Position=UDim2.new(1,-124,.5,0),
        Size=UDim2.fromOffset(155,42),
        Parent=header
    })
    Corner(userBox,6)
    Stroke(userBox,Theme.Border,.1)

    local uDot = New("Frame", {
        BackgroundColor3=Theme.Success,
        BorderSizePixel=0,
        Position=UDim2.fromOffset(10,17),
        Size=UDim2.fromOffset(7,7),
        Parent=userBox
    })
    Corner(uDot,99)

    local uname = Txt(userBox,cfg.UserName or "XDFLEX User",10,Theme.Text,true)
    uname.Position=UDim2.fromOffset(26,5)
    uname.Size=UDim2.new(1,-32,0,17)

    local tier = Txt(userBox,cfg.UserTier or "Premium",9,Theme.Accent2,true)
    tier.Position=UDim2.fromOffset(26,21)
    tier.Size=UDim2.new(1,-32,0,15)

    local min = ButtonBase(header,"—")
    min.Position=UDim2.new(1,-80,0,18)
    min.Size=UDim2.fromOffset(28,28)

    local close = ButtonBase(header,"×")
    close.Position=UDim2.new(1,-44,0,18)
    close.Size=UDim2.fromOffset(28,28)
    close.TextSize=16

    MakeDraggable(header,root)

    local sidebar = New("Frame", {
        BackgroundColor3=Theme.Bg2,
        BorderSizePixel=0,
        Position=UDim2.fromOffset(8,74),
        Size=UDim2.new(0,190,1,-82),
        Parent=root
    })
    Corner(sidebar,7)
    Stroke(sidebar,Theme.Border,.22)

    local tabList = New("Frame", {
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(8,8),
        Size=UDim2.new(1,-16,1,-74),
        Parent=sidebar
    })
    local tl = New("UIListLayout",{
        Padding=UDim.new(0,5),
        SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=tabList
    })

    local foot = New("Frame",{
        BackgroundColor3=Theme.Panel,
        BorderSizePixel=0,
        Position=UDim2.new(0,8,1,-61),
        Size=UDim2.new(1,-16,0,52),
        Parent=sidebar
    })
    Corner(foot,5)
    Stroke(foot,Theme.Border,.25)

    local ft = Txt(foot,(cfg.Title or "XDFLEX HUB").."  v3",10,Theme.Text,true)
    ft.Position=UDim2.fromOffset(9,5)
    ft.Size=UDim2.new(1,-18,0,17)
    local fs = Txt(foot,"Stable Release  •  Modern UI",8,Theme.Sub,false)
    fs.Position=UDim2.fromOffset(9,23)
    fs.Size=UDim2.new(1,-18,0,16)

    local main = New("Frame", {
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(206,74),
        Size=UDim2.new(1,-214,1,-82),
        Parent=root
    })

    local pageHolder = New("Frame",{
        BackgroundTransparency=1,
        Size=UDim2.fromScale(1,1),
        Parent=main
    })

    local popupLayer = New("Frame",{
        BackgroundTransparency=1,
        Size=UDim2.fromScale(1,1),
        ZIndex=100,
        Parent=gui
    })

    local self=setmetatable({
        Gui=gui,Root=root,Header=header,Sidebar=sidebar,TabList=tabList,
        Main=main,PageHolder=pageHolder,PopupLayer=popupLayer,
        Tabs={},ActiveTab=nil,PopupClosers={}
    },Window)

    close.MouseButton1Click:Connect(function() self:Destroy() end)
    min.MouseButton1Click:Connect(function()
        main.Visible=not main.Visible
        sidebar.Visible=main.Visible
        root.Size=main.Visible
            and UDim2.fromOffset(cfg.Width or 980,cfg.Height or 620)
            or UDim2.fromOffset(cfg.Width or 980,66)
    end)

    UserInputService.InputBegan:Connect(function(input,gp)
        if gp then return end
        if cfg.ToggleKey and input.KeyCode==cfg.ToggleKey then
            self:Toggle()
        end
    end)

    return self
end

function Window:_registerPopup(fn)
    table.insert(self.PopupClosers,fn)
end

function Window:_closePopups()
    for _,fn in ipairs(self.PopupClosers) do pcall(fn) end
end

function Window:Toggle()
    self.Root.Visible=not self.Root.Visible
end

function Window:SetVisible(v)
    self.Root.Visible=v==true
end

function Window:Destroy()
    if self.Gui then self.Gui:Destroy() end
end

function Window:Tab(cfg)
    cfg=cfg or {}
    local name=cfg.Name or cfg.Title or "Tab"

    local btn=New("TextButton",{
        AutoButtonColor=false,
        BackgroundColor3=Theme.Panel3,
        BackgroundTransparency=1,
        BorderSizePixel=0,
        Text="",
        Size=UDim2.new(1,0,0,44),
        Parent=self.TabList
    })
    Corner(btn,6)

    local icon=Txt(btn,cfg.Icon or "•",15,Theme.Sub,true)
    icon.Position=UDim2.fromOffset(11,0)
    icon.Size=UDim2.fromOffset(28,44)
    icon.TextXAlignment=Enum.TextXAlignment.Center

    local tx=Txt(btn,name,11,Theme.Sub,true)
    tx.Position=UDim2.fromOffset(46,4)
    tx.Size=UDim2.new(1,-52,0,19)

    if cfg.Description then
        local ds=Txt(btn,cfg.Description,8,Theme.Muted,false)
        ds.Position=UDim2.fromOffset(46,22)
        ds.Size=UDim2.new(1,-52,0,15)
    end

    local page=New("Frame",{
        BackgroundTransparency=1,
        Visible=false,
        Size=UDim2.fromScale(1,1),
        Parent=self.PageHolder
    })

    local title=Txt(page,cfg.PageTitle or name,11,Theme.Sub,true)
    title.Size=UDim2.new(1,0,0,20)

    local cols=New("Frame",{
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,24),
        Size=UDim2.new(1,0,1,-24),
        Parent=page
    })

    local columns={}
    for i=1,3 do
        local x=(i-1)/3
        local col=New("ScrollingFrame",{
            BackgroundTransparency=1,
            BorderSizePixel=0,
            ScrollBarThickness=2,
            ScrollBarImageColor3=Theme.Accent,
            Position=UDim2.new(x, i==1 and 0 or 4,0,0),
            Size=UDim2.new(1/3, -6,1,0),
            CanvasSize=UDim2.new(),
            Parent=cols
        })
        local layout=New("UIListLayout",{
            Padding=UDim.new(0,8),
            SortOrder=Enum.SortOrder.LayoutOrder,
            Parent=col
        })
        Pad(col,0,0,0,8)
        AutoCanvas(col,layout,10)
        columns[i]=col
    end

    local tab=setmetatable({
        Window=self,Name=name,Button=btn,Icon=icon,Label=tx,Page=page,Columns=columns
    },Tab)

    function tab:Select()
        self.Window:_closePopups()
        for _,o in ipairs(self.Window.Tabs) do
            local active=o==self
            o.Page.Visible=active
            Tween(o.Button,.14,{
                BackgroundTransparency=active and 0 or 1,
                BackgroundColor3=active and Color3.fromRGB(10,48,88) or Theme.Panel3
            })
            o.Icon.TextColor3=active and Theme.Accent2 or Theme.Sub
            o.Label.TextColor3=active and Theme.Text or Theme.Sub
        end
        self.Window.ActiveTab=self
    end

    btn.MouseButton1Click:Connect(function() tab:Select() end)
    table.insert(self.Tabs,tab)
    if #self.Tabs==1 then tab:Select() end
    return tab
end

function Tab:Section(cfg)
    cfg=cfg or {}
    local colIndex=tonumber(cfg.Column or cfg.Side or 1) or 1
    colIndex=math.clamp(colIndex,1,3)
    local parent=self.Columns[colIndex]

    local box=New("Frame",{
        BackgroundColor3=Theme.Panel,
        BorderSizePixel=0,
        AutomaticSize=Enum.AutomaticSize.Y,
        Size=UDim2.new(1,0,0,0),
        Parent=parent
    })
    Corner(box,6)
    Stroke(box,Theme.Border,.18)

    local accent=New("Frame",{
        BackgroundColor3=Theme.Accent,
        BorderSizePixel=0,
        Position=UDim2.fromOffset(0,0),
        Size=UDim2.fromOffset(2,31),
        Parent=box
    })
    Corner(accent,2)

    local title=Txt(box,cfg.Title or cfg.Name or "Section",11,Theme.Text,true)
    title.Position=UDim2.fromOffset(10,4)
    title.Size=UDim2.new(1,-20,0,18)

    if cfg.Description then
        local desc=Txt(box,cfg.Description,8,Theme.Sub,false)
        desc.Position=UDim2.fromOffset(10,20)
        desc.Size=UDim2.new(1,-20,0,14)
        desc.TextTruncate=Enum.TextTruncate.AtEnd
    end

    local contentY=cfg.Description and 39 or 31
    local content=New("Frame",{
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(6,contentY),
        Size=UDim2.new(1,-12,0,0),
        AutomaticSize=Enum.AutomaticSize.Y,
        Parent=box
    })
    local layout=New("UIListLayout",{
        Padding=UDim.new(0,4),
        SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=content
    })
    New("UIPadding",{PaddingBottom=UDim.new(0,6),Parent=content})

    return setmetatable({
        Tab=self,Window=self.Window,Root=box,Container=content
    },Section)
end

-- =========================================================
-- SPECIAL CARDS
-- =========================================================

function Tab:GameCard(cfg)
    cfg=cfg or {}
    local col=math.clamp(tonumber(cfg.Column or 1) or 1,1,3)
    local parent=self.Columns[col]

    local card=New("Frame",{
        BackgroundColor3=Theme.Panel,
        BorderSizePixel=0,
        Size=UDim2.new(1,0,0,cfg.Height or 190),
        Parent=parent
    })
    Corner(card,7)
    Stroke(card,Theme.BorderStrong,.22)

    local img=New("ImageLabel",{
        BackgroundColor3=Theme.Panel2,
        BorderSizePixel=0,
        Image=cfg.Image or "",
        ScaleType=Enum.ScaleType.Crop,
        Position=UDim2.fromOffset(6,6),
        Size=UDim2.new(1,-12,0,96),
        Parent=card
    })
    Corner(img,6)

    local tag=Txt(img,cfg.Tag or "CURRENT GAME",8,Theme.Accent2,true)
    tag.Position=UDim2.fromOffset(8,5)
    tag.Size=UDim2.fromOffset(120,18)

    local title=Txt(card,cfg.Title or "Game",14,Theme.Text,true)
    title.Position=UDim2.fromOffset(9,108)
    title.Size=UDim2.new(1,-18,0,21)

    local desc=Txt(card,cfg.Description or "",9,Theme.Sub,false)
    desc.Position=UDim2.fromOffset(9,128)
    desc.Size=UDim2.new(1,-116,0,42)
    desc.TextWrapped=true
    desc.TextYAlignment=Enum.TextYAlignment.Top

    local b=ButtonBase(card,cfg.ButtonText or "Execute")
    b.AnchorPoint=Vector2.new(1,1)
    b.Position=UDim2.new(1,-8,1,-8)
    b.Size=UDim2.fromOffset(95,28)
    b.BackgroundColor3=Theme.Accent
    b.MouseButton1Click:Connect(function() SafeCall(cfg.Callback) end)

    return {
        Instance=card,
        SetImage=function(_,v) img.Image=v end,
        SetTitle=function(_,v) title.Text=tostring(v) end,
    }
end

function Tab:StatusCard(cfg)
    cfg=cfg or {}
    local col=math.clamp(tonumber(cfg.Column or 1) or 1,1,3)
    local parent=self.Columns[col]

    local card=New("Frame",{
        BackgroundColor3=Theme.Panel,
        BorderSizePixel=0,
        Size=UDim2.new(1,0,0,66),
        Parent=parent
    })
    Corner(card,6)
    Stroke(card,Theme.Border,.2)

    local icon=Txt(card,cfg.Icon or "◈",18,cfg.Color or Theme.Accent2,true)
    icon.Position=UDim2.fromOffset(10,0)
    icon.Size=UDim2.fromOffset(28,66)
    icon.TextXAlignment=Enum.TextXAlignment.Center

    local title=Txt(card,cfg.Title or "Status",9,Theme.Sub,false)
    title.Position=UDim2.fromOffset(45,8)
    title.Size=UDim2.new(1,-55,0,16)

    local value=Txt(card,cfg.Value or "Ready",15,Theme.Text,true)
    value.Position=UDim2.fromOffset(45,23)
    value.Size=UDim2.new(1,-55,0,22)

    local sub=Txt(card,cfg.Description or "",8,Theme.Muted,false)
    sub.Position=UDim2.fromOffset(45,45)
    sub.Size=UDim2.new(1,-55,0,14)

    return {
        Instance=card,
        SetValue=function(_,v) value.Text=tostring(v) end
    }
end

-- =========================================================
-- ELEMENTS
-- =========================================================

function Section:Label(cfg)
    cfg=cfg or {}
    local r=CreateRow(self.Container,cfg.Description and 46 or 36)
    TitleBlock(r,cfg.Title or cfg.Name or "Label",cfg.Description,8)
    return r
end

function Section:Button(cfg)
    cfg=cfg or {}
    local r=CreateRow(self.Container,42)
    TitleBlock(r,cfg.Title or cfg.Name or "Button",cfg.Description,130)

    local b=ButtonBase(r,cfg.ButtonText or "Execute")
    b.AnchorPoint=Vector2.new(1,.5)
    b.Position=UDim2.new(1,-8,.5,0)
    b.Size=UDim2.fromOffset(cfg.Width or 112,28)

    b.MouseButton1Click:Connect(function()
        Tween(b,.08,{BackgroundColor3=Theme.Accent})
        task.delay(.1,function()
            if b.Parent then Tween(b,.12,{BackgroundColor3=Theme.Panel3}) end
        end)
        SafeCall(cfg.Callback)
    end)

    return {
        Instance=r,
        Press=function() SafeCall(cfg.Callback) end
    }
end

function Section:Toggle(cfg)
    cfg=cfg or {}
    local state=cfg.Default==true
    local r=CreateRow(self.Container,cfg.Description and 46 or 38)
    TitleBlock(r,cfg.Title or cfg.Name or "Toggle",cfg.Description,60)

    local track=New("TextButton",{
        AutoButtonColor=false,
        BackgroundColor3=state and Theme.Accent or Color3.fromRGB(29,39,53),
        BorderSizePixel=0,
        Text="",
        AnchorPoint=Vector2.new(1,.5),
        Position=UDim2.new(1,-9,.5,0),
        Size=UDim2.fromOffset(34,18),
        Parent=r
    })
    Corner(track,99)

    local knob=New("Frame",{
        BackgroundColor3=Color3.fromRGB(245,248,252),
        BorderSizePixel=0,
        Position=state and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2),
        Size=UDim2.fromOffset(14,14),
        Parent=track
    })
    Corner(knob,99)

    local api={Instance=r}
    local function set(v,silent)
        state=v==true
        Tween(track,.13,{BackgroundColor3=state and Theme.Accent or Color3.fromRGB(29,39,53)})
        Tween(knob,.13,{Position=state and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2)})
        if not silent then SafeCall(cfg.Callback,state) end
    end

    track.MouseButton1Click:Connect(function() set(not state,false) end)
    function api:SetValue(v,silent) set(v,silent) end
    function api:GetValue() return state end
    return api
end

function Section:Slider(cfg)
    cfg=cfg or {}
    local min=tonumber(cfg.Min) or 0
    local max=tonumber(cfg.Max) or 100
    local step=tonumber(cfg.Step) or 1
    local value=math.clamp(tonumber(cfg.Default) or min,min,max)
    local dragging=false

    local r=CreateRow(self.Container,56)
    TitleBlock(r,cfg.Title or cfg.Name or "Slider",cfg.Description,60)

    local val=Txt(r,tostring(value),9,Theme.Sub,true)
    val.AnchorPoint=Vector2.new(1,0)
    val.Position=UDim2.new(1,-9,0,4)
    val.Size=UDim2.fromOffset(48,18)
    val.TextXAlignment=Enum.TextXAlignment.Right

    local track=New("Frame",{
        BackgroundColor3=Color3.fromRGB(29,39,54),
        BorderSizePixel=0,
        Position=UDim2.new(0,11,1,-13),
        Size=UDim2.new(1,-22,0,4),
        Parent=r
    })
    Corner(track,99)

    local fill=New("Frame",{
        BackgroundColor3=Theme.Accent,
        BorderSizePixel=0,
        Size=UDim2.new(0,0,1,0),
        Parent=track
    })
    Corner(fill,99)

    local knob=New("Frame",{
        BackgroundColor3=Theme.Accent2,
        BorderSizePixel=0,
        AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.new(0,0,.5,0),
        Size=UDim2.fromOffset(10,10),
        Parent=track
    })
    Corner(knob,99)

    local api={Instance=r}
    local function quant(v)
        if step<=0 then return v end
        return math.floor((v/step)+.5)*step
    end
    local function set(v,silent)
        value=math.clamp(quant(tonumber(v) or min),min,max)
        local a=max==min and 0 or (value-min)/(max-min)
        fill.Size=UDim2.new(a,0,1,0)
        knob.Position=UDim2.new(a,0,.5,0)
        val.Text=tostring(value)
        if not silent then SafeCall(cfg.Callback,value) end
    end
    local function fromX(x)
        local a=math.clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
        set(min+(max-min)*a,false)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            fromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType==Enum.UserInputType.MouseMovement
            or input.UserInputType==Enum.UserInputType.Touch
        ) then
            fromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)

    function api:SetValue(v,silent) set(v,silent) end
    function api:GetValue() return value end
    set(value,true)
    return api
end

local function MakeDropdown(section,cfg,multi)
    cfg=cfg or {}
    local values=cfg.Values or cfg.Options or {}
    local selected=multi and {} or cfg.Default
    if not multi and selected==nil then selected=values[1] end
    if multi and type(cfg.Default)=="table" then
        for _,v in ipairs(cfg.Default) do selected[v]=true end
    end

    local r=CreateRow(section.Container,42)
    TitleBlock(r,cfg.Title or cfg.Name or (multi and "Multi Select" or "Dropdown"),cfg.Description,160)

    local field=ButtonBase(r,"")
    field.AnchorPoint=Vector2.new(1,.5)
    field.Position=UDim2.new(1,-8,.5,0)
    field.Size=UDim2.fromOffset(cfg.Width or 145,28)
    field.TextXAlignment=Enum.TextXAlignment.Left
    Pad(field,8,22,0,0)

    local arrow=Txt(field,"⌄",12,Theme.Sub,true)
    arrow.AnchorPoint=Vector2.new(1,.5)
    arrow.Position=UDim2.new(1,-4,.5,-1)
    arrow.Size=UDim2.fromOffset(16,18)
    arrow.TextXAlignment=Enum.TextXAlignment.Center

    local popup=New("Frame",{
        BackgroundColor3=Theme.Panel,
        BorderSizePixel=0,
        Visible=false,
        ZIndex=120,
        Parent=section.Window.PopupLayer
    })
    Corner(popup,6)
    Stroke(popup,Theme.BorderStrong,.15)

    local sc=New("ScrollingFrame",{
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ScrollBarThickness=2,
        ScrollBarImageColor3=Theme.Accent,
        CanvasSize=UDim2.new(),
        Size=UDim2.fromScale(1,1),
        ZIndex=121,
        Parent=popup
    })
    Pad(sc,5,5,5,5)
    local lay=New("UIListLayout",{
        Padding=UDim.new(0,3),
        SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=sc
    })
    AutoCanvas(sc,lay,8)

    local opened=false
    local api={Instance=r}

    local function textValue()
        if multi then
            local arr={}
            for _,v in ipairs(values) do
                if selected[v] then table.insert(arr,tostring(v)) end
            end
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
            for _,v in ipairs(values) do
                if selected[v] then table.insert(arr,v) end
            end
            SafeCall(cfg.Callback,arr)
        else
            SafeCall(cfg.Callback,selected)
        end
    end

    local function close()
        opened=false
        popup.Visible=false
        arrow.Text="⌄"
    end

    local function position()
        local p=field.AbsolutePosition
        local s=field.AbsoluteSize
        local cam=workspace.CurrentCamera
        local vp=cam and cam.ViewportSize or Vector2.new(1920,1080)
        local w=math.max(s.X,165)
        local h=math.min(#values*30+10,190)
        local x=math.clamp(p.X,6,vp.X-w-6)
        local y=p.Y+s.Y+4
        if y+h>vp.Y-6 then y=math.max(6,p.Y-h-4) end
        popup.Position=UDim2.fromOffset(x,y)
        popup.Size=UDim2.fromOffset(w,h)
    end

    local function refresh()
        field.Text=textValue()
    end

    local function rebuild()
        for _,c in ipairs(sc:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end

        for _,v in ipairs(values) do
            local opt=New("TextButton",{
                AutoButtonColor=false,
                BackgroundColor3=Theme.Panel2,
                BorderSizePixel=0,
                Size=UDim2.new(1,0,0,27),
                Text="",
                ZIndex=122,
                Parent=sc
            })
            Corner(opt,4)

            local tx=Txt(opt,tostring(v),10,Theme.Text,false)
            tx.Position=UDim2.fromOffset(8,0)
            tx.Size=UDim2.new(1,-30,1,0)
            tx.ZIndex=123

            local mark=Txt(opt,"",10,Theme.Accent2,true)
            mark.AnchorPoint=Vector2.new(1,.5)
            mark.Position=UDim2.new(1,-6,.5,0)
            mark.Size=UDim2.fromOffset(18,18)
            mark.TextXAlignment=Enum.TextXAlignment.Center
            mark.ZIndex=123

            local function syncMark()
                if multi then
                    mark.Text=selected[v] and "✓" or ""
                else
                    mark.Text=(selected==v) and "•" or ""
                end
            end
            syncMark()

            opt.MouseButton1Click:Connect(function()
                if multi then
                    selected[v]=not selected[v] or nil
                    syncMark()
                    refresh()
                    emit()
                else
                    selected=v
                    refresh()
                    emit()
                    close()
                end
            end)

            opt.MouseEnter:Connect(function()
                Tween(opt,.1,{BackgroundColor3=Theme.Hover})
            end)
            opt.MouseLeave:Connect(function()
                Tween(opt,.1,{BackgroundColor3=Theme.Panel2})
            end)
        end
    end

    field.MouseButton1Click:Connect(function()
        section.Window:_closePopups()
        opened=true
        position()
        popup.Visible=true
        arrow.Text="⌃"
    end)

    section.Window:_registerPopup(close)

    function api:SetValues(vs)
        values=vs or {}
        if multi then
            selected={}
        elseif table.find(values,selected)==nil then
            selected=values[1]
        end
        rebuild()
        refresh()
    end

    function api:SetValue(v,silent)
        if multi then
            selected={}
            if type(v)=="table" then
                for _,x in ipairs(v) do selected[x]=true end
            end
        else
            selected=v
        end
        rebuild()
        refresh()
        if not silent then emit() end
    end

    function api:GetValue()
        if not multi then return selected end
        local arr={}
        for _,v in ipairs(values) do
            if selected[v] then table.insert(arr,v) end
        end
        return arr
    end

    rebuild()
    refresh()
    return api
end

function Section:Dropdown(cfg)
    return MakeDropdown(self,cfg,false)
end

function Section:MultiDropdown(cfg)
    return MakeDropdown(self,cfg,true)
end

Section.MultiSelect=Section.MultiDropdown

function Section:Input(cfg)
    cfg=cfg or {}
    local r=CreateRow(self.Container,42)
    TitleBlock(r,cfg.Title or cfg.Name or "Input",cfg.Description,160)

    local box=New("TextBox",{
        BackgroundColor3=Theme.Panel3,
        BorderSizePixel=0,
        Text=tostring(cfg.Default or ""),
        PlaceholderText=cfg.Placeholder or "Enter value...",
        PlaceholderColor3=Theme.Muted,
        TextColor3=Theme.Text,
        TextSize=10,
        Font=Enum.Font.Gotham,
        ClearTextOnFocus=false,
        TextXAlignment=Enum.TextXAlignment.Left,
        AnchorPoint=Vector2.new(1,.5),
        Position=UDim2.new(1,-8,.5,0),
        Size=UDim2.fromOffset(cfg.Width or 145,28),
        Parent=r
    })
    Corner(box,5)
    Stroke(box,Theme.Border,.05)
    Pad(box,8,8,0,0)

    box.FocusLost:Connect(function(enter)
        local out=box.Text
        if cfg.Numeric then
            local n=tonumber(out)
            if n==nil then return end
            out=n
        end
        SafeCall(cfg.Callback,out,enter)
    end)

    return {
        Instance=r,
        SetValue=function(_,v) box.Text=tostring(v or "") end,
        GetValue=function()
            return cfg.Numeric and tonumber(box.Text) or box.Text
        end
    }
end

function Section:Keybind(cfg)
    cfg=cfg or {}
    local current=cfg.Default or Enum.KeyCode.RightShift
    local listening=false

    local r=CreateRow(self.Container,42)
    TitleBlock(r,cfg.Title or cfg.Name or "Keybind",cfg.Description,125)

    local b=ButtonBase(r,current.Name)
    b.AnchorPoint=Vector2.new(1,.5)
    b.Position=UDim2.new(1,-8,.5,0)
    b.Size=UDim2.fromOffset(110,28)

    b.MouseButton1Click:Connect(function()
        listening=true
        b.Text="Press key..."
    end)

    UserInputService.InputBegan:Connect(function(input,gp)
        if gp then return end
        if listening and input.KeyCode~=Enum.KeyCode.Unknown then
            current=input.KeyCode
            b.Text=current.Name
            listening=false
            SafeCall(cfg.Changed,current)
            return
        end
        if not listening and input.KeyCode==current then
            SafeCall(cfg.Callback,current)
        end
    end)

    return {
        Instance=r,
        GetValue=function() return current end,
        SetValue=function(_,v)
            if typeof(v)=="EnumItem" then
                current=v
                b.Text=v.Name
            end
        end
    }
end

XDFLEX.Theme=Theme
return XDFLEX
