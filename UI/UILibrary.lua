--[[
    amphibia — ui library for roblox (executor)
    -------------------------------------------------
    Single-file library. Load with:
        local Amphibia = loadstring(game:HttpGet("<raw url>/Amphibia.lua"))()

    Everything (key screen, loading screen, window, every component, the color
    picker window, search and config saving) is built purely from code in the
    exact "amphibia" visual style. See Loader.lua for a full showcase.

    Public API (Rayfield-like, but nicer):

        local Window = Amphibia:CreateWindow({...})
        local Tab    = Window:CreateTab({ Name = "Player", Group = "Main" })
        local Sec    = Tab:CreateSection({ Name = "Sliders", Side = "Left" })
        Sec:CreateSlider{...}  Sec:CreateToggle{...}  Sec:CreateButton{...}
        Sec:CreateColorPicker{...}  Sec:CreateSelector{...}
        Sec:CreateNumberPicker{...} Sec:CreateDropdown{...}  Sec:CreateLabel{...}
--]]

local Amphibia = {}
Amphibia.__index = Amphibia
Amphibia.Version = "0.1"

--============================================================================--
--  SERVICES
--============================================================================--
local TweenService     = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local CoreGui           = game:GetService("CoreGui")
local TextService       = game:GetService("TextService")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer and LocalPlayer:GetMouse()

--============================================================================--
--  THEME  (extracted 1:1 from the amphibia design file)
--============================================================================--
local Theme = {
    -- backgrounds
    Window        = Color3.fromRGB(13, 13, 14),
    Section       = Color3.fromRGB(27, 27, 27),
    Search        = Color3.fromRGB(30, 30, 30),
    Inset         = Color3.fromRGB(13, 13, 14),   -- number picker / buttons inner
    InsetDark     = Color3.fromRGB(16, 16, 16),   -- selector holder
    Popup         = Color3.fromRGB(18, 18, 18),   -- colorpicker / dropdown window

    -- strokes
    WindowStroke  = Color3.fromRGB(34, 34, 34),
    SectionStroke = Color3.fromRGB(60, 60, 60),
    PopupStroke   = Color3.fromRGB(40, 40, 40),
    Splitter      = Color3.fromRGB(34, 34, 34),

    -- text
    Logo          = Color3.fromRGB(255, 255, 255),
    Version       = Color3.fromRGB(111, 111, 111),
    SectionName   = Color3.fromRGB(216, 216, 216),
    ElementName   = Color3.fromRGB(200, 200, 200),
    Value         = Color3.fromRGB(226, 226, 226),
    TabIdle       = Color3.fromRGB(188, 188, 188),
    TabActive     = Color3.fromRGB(255, 255, 255),
    Muted         = Color3.fromRGB(120, 120, 120),
    Placeholder   = Color3.fromRGB(65, 65, 65),
    Status        = Color3.fromRGB(189, 189, 189),

    -- accents
    Accent        = Color3.fromRGB(255, 255, 255),
    SliderTrack   = Color3.fromRGB(94, 94, 94),
    ToggleOn      = Color3.fromRGB(48, 48, 47),
    ToggleOff     = Color3.fromRGB(33, 33, 33),
    ToggleOnStroke  = Color3.fromRGB(175, 175, 175),
    ToggleOffStroke = Color3.fromRGB(75, 75, 75),
    ToggleOffDot  = Color3.fromRGB(105, 105, 105),
    SelActive     = Color3.fromRGB(30, 30, 30),
    SelActiveStroke = Color3.fromRGB(70, 70, 70),
    SelTextIdle   = Color3.fromRGB(106, 106, 106),
    SelTextActive = Color3.fromRGB(184, 184, 184),
    Error         = Color3.fromRGB(220, 70, 70),
}

--============================================================================--
--  FONTS  (two families from the design: serif display + sans body)
--============================================================================--
local function mkfont(id, weight, style)
    return Font.new(id, weight or Enum.FontWeight.Regular, style or Enum.FontStyle.Normal)
end
local Fonts = {
    -- serif / display  (logo, section titles, values, screen titles)
    Serif        = mkfont("rbxassetid://12187368093", Enum.FontWeight.Regular),
    SerifBold    = mkfont("rbxassetid://12187368093", Enum.FontWeight.Bold),
    SerifItalic  = mkfont("rbxassetid://12187368093", Enum.FontWeight.Regular, Enum.FontStyle.Italic),
    -- sans / body
    Sans         = mkfont("rbxassetid://12187365364", Enum.FontWeight.Regular),
    Mono         = Font.fromEnum(Enum.Font.RobotoMono),
}

--============================================================================--
--  ASSETS  (exact image ids from the design)
--============================================================================--
local Icons = {
    Search    = "rbxassetid://112312028684423",
    Close     = "rbxassetid://90666376026129",
    WhiteGlow = "rbxassetid://130321961257203",
    Chevron   = "rbxassetid://82022839420755",   -- section arrow (90 closed / 180 open)
    DropArrow = "rbxassetid://71447831631799",
    ToggleGlow= "rbxassetid://104778959707215",
    Minus     = "rbxassetid://128229913388215",
    Plus      = "rbxassetid://96950735183906",
    Divider   = "rbxassetid://124160192323665",
    Shadow    = "rbxassetid://76575266047430",
    KeyArrow  = "rbxassetid://94816744026537",
    Discord   = "rbxassetid://122829741481584",
    Site      = "rbxassetid://109323416778766",
    Youtube   = "rbxassetid://80810391923936",
    KeyGlow   = "rbxassetid://70620626215499",
    KeyIcon   = "rbxassetid://134303082879830",
    Chess     = "rbxassetid://107060544057249",
    PopupClose= "rbxassetid://79136524656561",
}

--============================================================================--
--  ANIMATION  helpers + shared easing presets
--============================================================================--
local Anim = {}
Anim.Spring  = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
Anim.Fast    = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
Anim.Snappy  = TweenInfo.new(0.22, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
Anim.Slow    = TweenInfo.new(0.5,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
Anim.Linear  = TweenInfo.new(0.12, Enum.EasingStyle.Linear)

function Anim.tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end
-- shorthand: Anim.to(obj, props [, info])
function Anim.to(obj, props, info)
    return Anim.tween(obj, info or Anim.Spring, props)
end

--============================================================================--
--  UTIL  — declarative instance builder
--============================================================================--
local function Create(class, props, children)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then
                inst[k] = v
            end
        end
        if props.Parent then inst.Parent = props.Parent end
    end
    if children then
        for _, c in ipairs(children) do c.Parent = inst end
    end
    return inst
end

local function corner(radius, parent)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end
local function stroke(color, thickness, parent, transparency)
    return Create("UIStroke", {
        Color = color, Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end
local function pad(parent, l, r, t, b)
    return Create("UIPadding", {
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or 0),
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        Parent = parent,
    })
end
local function listLayout(parent, dir, gap, halign, valign)
    return Create("UIListLayout", {
        FillDirection = dir or Enum.FillDirection.Vertical,
        Padding = UDim.new(0, gap or 0),
        HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = valign or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

-- soft radial shadow behind an element
local function addShadow(parent, color, transparency, sizeScale)
    return Create("ImageLabel", {
        Name = "Shadow", BackgroundTransparency = 1,
        Image = "rbxassetid://76575266047430",
        ImageColor3 = color or Color3.new(0,0,0),
        ImageTransparency = transparency or 0.4,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(sizeScale or 1.6, sizeScale or 1.9),
        ZIndex = (parent.ZIndex or 1) - 1,
        Parent = parent,
    })
end

--============================================================================--
--  DRAGGING  — smooth, works from a handle, moves a target
--============================================================================--
local function makeDraggable(handle, target)
    target = target or handle
    local dragging, startPos, startInput
    local goal
    local conn

    handle.Active = true
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            startInput = input.Position
            startPos   = target.Position
            goal       = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput
            goal = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- smooth follow so dragging feels weighty & fluid
    if not conn then
        conn = RunService.RenderStepped:Connect(function()
            if goal and target.Parent then
                target.Position = target.Position:Lerp(goal, 0.28)
            end
        end)
    end
    return function() if conn then conn:Disconnect() end end
end

--============================================================================--
--  CUSTOM TEXTBOX  — animated input (letters fade in, caret glides, smooth
--  deletion). Built on a hidden real TextBox for reliable keyboard/clipboard
--  capture, but rendered fully custom for the "premium menu" feel.
--
--    local input = CustomInput.new(holderFrame, {
--        Placeholder = "Enter key here",
--        Font = Fonts.Mono, TextSize = 14,
--        OnChanged = function(text) end,
--        OnEnter   = function(text) end,
--    })
--============================================================================--
local CustomInput = {}
CustomInput.__index = CustomInput

function CustomInput.new(parent, o)
    o = o or {}
    local self = setmetatable({}, CustomInput)
    self.value       = o.Default or ""
    self.placeholder = o.Placeholder or ""
    self.onChanged   = o.OnChanged
    self.onEnter     = o.OnEnter
    self.numeric     = o.Numeric == true
    self.maxLen      = o.MaxLen
    self.focused     = falsed

    local font   = o.Font or Fonts.Sans
    local size   = o.TextSize or 14
    local tcol   = o.TextColor or Theme.ElementName
    local pcol   = o.PlaceholderColor or Theme.Placeholder
    local align  = o.Align or Enum.HorizontalAlignment.Left

    -- container ------------------------------------------------------------
    local root = Create("Frame", {
        Name = "CustomInput", BackgroundTransparency = 1,
        Size = o.Size or UDim2.fromScale(1, 1),
        Position = o.Position or UDim2.fromScale(0, 0),
        ClipsDescendants = true,
        Parent = parent,
    })
    self.Frame = root

    -- row that holds text + caret, aligned so caret sits right after text
    local row = Create("Frame", {
        Name = "Row", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Position = UDim2.fromScale(0, 0),
        Parent = root,
    })
    local rowLayout = listLayout(row, Enum.FillDirection.Horizontal, 2,
        (align == Enum.HorizontalAlignment.Center and Enum.HorizontalAlignment.Center)
        or (align == Enum.HorizontalAlignment.Right and Enum.HorizontalAlignment.Right)
        or Enum.HorizontalAlignment.Left,
        Enum.VerticalAlignment.Center)

    local textLbl = Create("TextLabel", {
        Name = "Text", BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        FontFace = font, TextSize = size, TextColor3 = tcol,
        Text = self.value, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        LayoutOrder = 1, TextTransparency = (self.value == "" and 1 or 0),
        Parent = row,
    })
    self.Label = textLbl

    local caret = Create("Frame", {
        Name = "Caret", BackgroundColor3 = tcol,
        Size = UDim2.new(0, 1, 0, math.floor(size * 1.15)),
        BackgroundTransparency = 1, LayoutOrder = 2,
        Parent = row,
    })
    self.Caret = caret

    -- placeholder overlay (independent so it can align on its own)
    local ph = Create("TextLabel", {
        Name = "Placeholder", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        FontFace = font, TextSize = size, TextColor3 = pcol,
        Text = self.placeholder,
        TextXAlignment = align == Enum.HorizontalAlignment.Center and Enum.TextXAlignment.Center
            or align == Enum.HorizontalAlignment.Right and Enum.TextXAlignment.Right
            or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Visible = (self.value == ""),
        Parent = root,
    })
    self.PH = ph

    -- hidden real textbox to capture keyboard / paste --------------------
    local capture = Create("TextBox", {
        Name = "Capture", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = self.value, TextTransparency = 1, TextColor3 = tcol,
        ClearTextOnFocus = false, MultiLine = false,
        FontFace = font, TextSize = size,
        TextEditable = true, ZIndex = 5,
        Parent = root,
    })
    self.Capture = capture

    -- caret blink --------------------------------------------------------
    task.spawn(function()
        while root.Parent do
            if self.focused then
                Anim.to(caret, { BackgroundTransparency = 1 }, Anim.Fast)
                task.wait(0.5)
                if not root.Parent then break end
                Anim.to(caret, { BackgroundTransparency = 0 }, Anim.Fast)
                task.wait(0.5)
            else
                caret.BackgroundTransparency = 1
                task.wait(0.1)
            end
        end
    end)

    -- render sync with animated appearance -------------------------------
    local function render(animate)
        local txt = self.value
        ph.Visible = (txt == "" and not self.focused)
        if txt == "" then
            textLbl.Text = ""
            textLbl.TextTransparency = 1
        else
            textLbl.Text = txt
            if animate then
                textLbl.TextTransparency = 0.55
                Anim.to(textLbl, { TextTransparency = 0 }, Anim.Fast)
            else
                textLbl.TextTransparency = 0
            end
        end
    end
    render(false)

    -- keep value synced to the real textbox; sanitise numeric
    capture:GetPropertyChangedSignal("Text"):Connect(function()
        local new = capture.Text
        if self.numeric then
            new = new:gsub("[^%d%.%-]", "")
        end
        if self.maxLen and #new > self.maxLen then
            new = new:sub(1, self.maxLen)
        end
        if new ~= capture.Text then
            capture.Text = new
            return
        end
        local grew = #new > #self.value
        self.value = new
        render(grew)
        if self.onChanged then task.spawn(self.onChanged, new) end
    end)

    capture.Focused:Connect(function()
        self.focused = true
        render(false)
        ph.Visible = false
    end)
    capture.FocusLost:Connect(function(enter)
        self.focused = false
        caret.BackgroundTransparency = 1
        render(false)
        if enter and self.onEnter then task.spawn(self.onEnter, self.value) end
    end)

    -- clicking anywhere on the field focuses it
    local hit = Create("TextButton", {
        Name = "Hit", BackgroundTransparency = 1, Text = "",
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 6, Parent = root,
    })
    hit.MouseButton1Click:Connect(function() capture:CaptureFocus() end)

    return self
end

function CustomInput:GetText() return self.value end
function CustomInput:SetText(t, silent)
    t = tostring(t or "")
    self.Capture.Text = t   -- triggers change handler
    if silent then self.value = t end
end
function CustomInput:Focus() self.Capture:CaptureFocus() end
function CustomInput:Clear() self:SetText("") end

Amphibia.CustomInput = CustomInput

--============================================================================--
--  GUI PARENT  (executor-safe)
--============================================================================--
local function getGuiParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return CoreGui end)
    if ok2 and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

--============================================================================--
--  CONFIG  (executor filesystem — save/load flags)
--============================================================================--
local function hasFS()
    return (writefile and readfile and isfolder and makefolder) and true or false
end
local Config = {}
Config.__index = Config
function Config.new(folder, file)
    local self = setmetatable({}, Config)
    self.enabled = hasFS()
    self.folder  = folder or "Amphibia"
    self.file    = (file or "config") .. ".json"
    self.data    = {}
    if self.enabled then
        pcall(function()
            if not isfolder(self.folder) then makefolder(self.folder) end
        end)
        self:Load()
    end
    return self
end
function Config:path() return self.folder .. "/" .. self.file end
function Config:Load()
    if not self.enabled then return end
    pcall(function()
        if isfile and isfile(self:path()) then
            self.data = HttpService:JSONDecode(readfile(self:path())) or {}
        end
    end)
end
function Config:Save()
    if not self.enabled then return end
    pcall(function()
        writefile(self:path(), HttpService:JSONEncode(self.data))
    end)
end
function Config:Set(flag, value)
    if flag == nil then return end
    self.data[flag] = value
    self:Save()
end
function Config:Get(flag, default)
    if flag ~= nil and self.data[flag] ~= nil then return self.data[flag] end
    return default
end

--============================================================================--
--  WINDOW
--============================================================================--
local Window = {}
Window.__index = Window

function Amphibia:CreateWindow(cfg)
    cfg = cfg or {}
    local self = setmetatable({}, Window)
    self.Tabs        = {}
    self.Categories  = {}          -- group name -> category frame
    self.SearchIndex = {}          -- list of {element, name, section, tab, show, hide}
    self.ActiveTab   = nil
    self.OpenPopups  = {}          -- popups to close on outside click
    self.Config      = Config.new(
        (cfg.ConfigSaving and cfg.ConfigSaving.FolderName) or "Amphibia",
        (cfg.ConfigSaving and cfg.ConfigSaving.FileName) or "config")
    self.ConfigEnabled = cfg.ConfigSaving == nil or cfg.ConfigSaving.Enabled ~= false

    ------------------------------------------------------------------ ScreenGui
    local gui = Create("ScreenGui", {
        Name = "Amphibia_" .. tostring(math.random(1000, 9999)),
        ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9999,
    })
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
    gui.Parent = getGuiParent()
    self.Gui = gui

    ------------------------------------------------------------------ main frame
    local main = Create("Frame", {
        Name = "MainBackground", BackgroundColor3 = Theme.Window,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(987, 608),
        Visible = false, Parent = gui,
    })
    corner(8, main)
    stroke(Theme.WindowStroke, 1, main)
    self.Main = main

    -- drop shadow behind the whole window
    Create("ImageLabel", {
        Name = "Shadow", BackgroundTransparency = 1, Image = Icons.Shadow,
        ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.39,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1.9, 2.35), ZIndex = 0, Parent = main,
    })

    -- subtle white glow at the top
    Create("ImageLabel", {
        Name = "WhiteGlow", BackgroundTransparency = 1, Image = Icons.WhiteGlow,
        ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.93,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.51, -0.55),
        Size = UDim2.fromOffset(1068, 1068), ZIndex = 0, Parent = main,
    })

    --============================ HEADER ============================--
    local header = Create("Frame", {
        Name = "Header", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 58), Position = UDim2.fromScale(0, 0),
        ZIndex = 10, Parent = main,
    })
    Create("Frame", {  -- bottom splitter
        Name = "Splitter", BackgroundColor3 = Theme.Splitter, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0), Parent = header,
    })
    Create("TextLabel", {
        Name = "Logo", BackgroundTransparency = 1, Text = (cfg.Name or "amphibia"),
        FontFace = Fonts.Serif, TextSize = 23, TextColor3 = Theme.Logo,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0, 120, 1, 0), Position = UDim2.new(0, 20, 0, 0), Parent = header,
    })
    local logoW = TextService:GetTextSize((cfg.Name or "amphibia"), 23, Enum.Font.SourceSans, Vector2.new(300, 60)).X
    Create("TextLabel", {
        Name = "Version", BackgroundTransparency = 1, Text = (cfg.Version or "v0.1"),
        FontFace = Fonts.Sans, TextSize = 13, TextColor3 = Theme.Version,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0, 60, 0, 20), Position = UDim2.new(0, 26 + logoW, 0, 22), Parent = header,
    })

    -- search box (top center) - functionality wired in the search section
    local searchBg = Create("Frame", {
        Name = "SearchBg", BackgroundColor3 = Theme.Search,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 300, 0, 34), ZIndex = 11, Parent = header,
    })
    corner(8, searchBg)
    stroke(Theme.SectionStroke, 0.5, searchBg)
    Create("ImageLabel", {
        Name = "SearchIcon", BackgroundTransparency = 1, Image = Icons.Search,
        ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.65,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 18, 0.5, 0),
        Size = UDim2.fromOffset(15, 15), ZIndex = 11, Parent = searchBg,
    })
    self.SearchBg = searchBg

    local closeBtn = Create("ImageButton", {
        Name = "CloseMenuButton", BackgroundTransparency = 1, Image = Icons.Close,
        ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.85,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -22, 0.5, 0),
        Size = UDim2.fromOffset(30, 30), ZIndex = 12, Parent = header,
    })
    closeBtn.MouseEnter:Connect(function() Anim.to(closeBtn, { ImageTransparency = 0.4 }, Anim.Fast) end)
    closeBtn.MouseLeave:Connect(function() Anim.to(closeBtn, { ImageTransparency = 0.85 }, Anim.Fast) end)

    --============================ TABS COLUMN ============================--
    local tabsFrame = Create("Frame", {
        Name = "TabsFrame", BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 58), Size = UDim2.new(0, 218, 1, -58 - 39),
        ZIndex = 10, Parent = main,
    })
    Create("Frame", {  -- right splitter
        Name = "Splitter", BackgroundColor3 = Theme.Splitter, BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, 0, 0, 0), Parent = tabsFrame,
    })
    local tabsHolder = Create("ScrollingFrame", {
        Name = "Holder", BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = tabsFrame,
    })
    listLayout(tabsHolder, Enum.FillDirection.Vertical, 18)
    pad(tabsHolder, 20, 10, 24, 10)
    self.TabsHolder = tabsHolder

    --============================ PAGES ============================--
    local pages = Create("Frame", {
        Name = "Pages", BackgroundTransparency = 1,
        Position = UDim2.new(0, 218, 0, 58), Size = UDim2.new(1, -218, 1, -58 - 39),
        ClipsDescendants = true, ZIndex = 10, Parent = main,
    })
    self.Pages = pages

    --============================ INFO / STATUS ============================--
    local info = Create("Frame", {
        Name = "InfoFrame", BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 39), ZIndex = 10, Parent = main,
    })
    Create("Frame", {
        Name = "Splitter", BackgroundColor3 = Theme.Splitter, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromScale(0, 0), Parent = info,
    })
    local dot = Create("Frame", {
        Name = "DotConnected", BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.3, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 22, 0.5, 0), Size = UDim2.fromOffset(7, 7), ZIndex = 2, Parent = info,
    })
    corner(999, dot)
    local dotShadow = addShadow(dot, Color3.new(1, 1, 1), 0.6, 3)
    Create("TextLabel", {
        Name = "ConnectStatusText", BackgroundTransparency = 1, Text = (cfg.Status or "Connected"),
        FontFace = Fonts.Sans, TextSize = 16, TextColor3 = Theme.Status,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 38, 0, 0), Size = UDim2.new(0, 200, 1, 0), Parent = info,
    })
    -- pulsing connected dot
    task.spawn(function()
        while gui.Parent do
            Anim.to(dot, { BackgroundTransparency = 0 }, Anim.Slow)
            Anim.to(dotShadow, { ImageTransparency = 0.35 }, Anim.Slow)
            task.wait(1.1)
            Anim.to(dot, { BackgroundTransparency = 0.45 }, Anim.Slow)
            Anim.to(dotShadow, { ImageTransparency = 0.85 }, Anim.Slow)
            task.wait(1.1)
        end
    end)

    --============================ SHOW-UI BUTTON (minimized) ============================--
    local showBtn = Create("ImageButton", {
        Name = "ShowUiButton", BackgroundColor3 = Color3.new(1, 1, 1),
        ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(236, 8),
        Visible = false, BackgroundTransparency = 0, Parent = gui,
    })
    corner(999, showBtn)
    local showGrad = Create("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(220,220,220), Color3.new(1,1,1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1) }),
        Rotation = 0, Parent = showBtn,
    })
    local showShadow = addShadow(showBtn, Color3.new(1, 1, 1), 1, 2.4)
    showBtn.MouseEnter:Connect(function() Anim.to(showShadow, { ImageTransparency = 0.55 }, Anim.Spring) end)
    showBtn.MouseLeave:Connect(function() Anim.to(showShadow, { ImageTransparency = 1 }, Anim.Spring) end)
    self.ShowBtn = showBtn

    ------------------------------------------------------------ dragging (header)
    makeDraggable(header, main)

    ------------------------------------------------------------ minimize / restore
    local minimized = false
    local function minimize()
        if minimized then return end
        minimized = true
        self:CloseAllPopups()
        Anim.to(main, { Size = UDim2.fromOffset(0, 0) }, Anim.Spring)
        task.delay(0.34, function() if minimized then main.Visible = false end end)
        showBtn.Visible = true
        showBtn.BackgroundTransparency = 1
        Anim.to(showBtn, { BackgroundTransparency = 0 }, Anim.Spring)
    end
    local function restore()
        if not minimized then return end
        minimized = false
        Anim.to(showBtn, { BackgroundTransparency = 1 }, Anim.Fast)
        Anim.to(showShadow, { ImageTransparency = 1 }, Anim.Fast)
        task.delay(0.16, function() if not minimized then showBtn.Visible = false end end)
        main.Visible = true
        main.Size = UDim2.fromOffset(0, 0)
        Anim.to(main, { Size = UDim2.fromOffset(987, 608) }, Anim.Spring)
    end
    closeBtn.MouseButton1Click:Connect(minimize)
    showBtn.MouseButton1Click:Connect(restore)

    -- toggle keybind
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == (cfg.ToggleKey or Enum.KeyCode.RightShift) then
            if minimized then restore() else minimize() end
        end
    end)

    self.Minimize = minimize
    self.Restore  = restore

    -- store cfg for screens
    self._cfg = cfg
    self._closeBtn = closeBtn

    -- build the colorpicker singleton window + outside-click watcher + search
    self:_BuildColorPickerWindow()
    self:_BuildOutsideClickWatcher()
    self:_BuildSearch()

    -- run the intro flow (key -> loading -> reveal) in the background
    task.spawn(function() self:_RunIntro() end)

    return self
end

function Window:CloseAllPopups()
    for _, p in ipairs(self.OpenPopups) do
        if p.close then pcall(p.close) end
    end
    self.OpenPopups = {}
end

function Window:_BuildOutsideClickWatcher()
    UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if #self.OpenPopups == 0 then return end
        local mpos = UserInputService:GetMouseLocation()
        local survivors = {}
        for _, p in ipairs(self.OpenPopups) do
            local f = p.frame
            local inside = false
            if f and f.Parent and f.Visible then
                local ap, sz = f.AbsolutePosition, f.AbsoluteSize
                if mpos.X >= ap.X and mpos.X <= ap.X + sz.X
                and mpos.Y >= ap.Y and mpos.Y <= ap.Y + sz.Y then inside = true end
            end
            -- also treat the owner control as "inside" so re-clicking it doesn't double-close
            if p.owner and p.owner.Parent then
                local ap, sz = p.owner.AbsolutePosition, p.owner.AbsoluteSize
                if mpos.X >= ap.X and mpos.X <= ap.X + sz.X
                and mpos.Y >= ap.Y and mpos.Y <= ap.Y + sz.Y then inside = true end
            end
            if inside then
                table.insert(survivors, p)
            else
                if p.close then pcall(p.close) end
            end
        end
        self.OpenPopups = survivors
    end)
end

--============================================================================--
--  INTRO SCREENS  (key -> loading -> reveal)
--============================================================================--

-- shared frame that looks like the window; whole thing is draggable
function Window:_makeScreenBase(name)
    local s = Create("Frame", {
        Name = name, BackgroundColor3 = Theme.Window,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(0, 0), ClipsDescendants = true, Parent = self.Gui,
    })
    corner(8, s)
    stroke(Theme.WindowStroke, 1, s)
    Create("ImageLabel", {
        Name = "Shadow", BackgroundTransparency = 1, Image = Icons.Shadow,
        ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.39,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1.9, 2.35), ZIndex = 0, Parent = s,
    })
    Create("ImageLabel", {
        Name = "WhiteGlow", BackgroundTransparency = 1, Image = Icons.WhiteGlow,
        ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.93,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.51, -0.045),
        Size = UDim2.fromOffset(1068, 1068), ZIndex = 0, Parent = s,
    })
    makeDraggable(s, s)
    return s
end

local SCREEN_SIZE = UDim2.fromOffset(700, 430)

function Window:_openScreen(frame)
    frame.Size = UDim2.fromOffset(0, 0)
    frame.Visible = true
    Anim.to(frame, { Size = SCREEN_SIZE }, Anim.Spring)
    task.wait(0.35)
end
function Window:_closeScreen(frame)
    Anim.to(frame, { Size = UDim2.fromOffset(0, 0) }, Anim.Spring)
    task.wait(0.35)
    frame:Destroy()
end

function Window:_RunIntro()
    local cfg = self._cfg
    local keyCfg = cfg.Key or {}
    if keyCfg.Enabled then
        self:_BuildKeyScreen(keyCfg)   -- yields until a valid key is entered
    end
    local loadCfg = cfg.Loading
    if loadCfg == nil or loadCfg.Enabled ~= false then
        self:_BuildLoadingScreen(loadCfg or {})   -- yields until finished
    end
    self:_RevealWindow()
end

--------------------------------------------------------------------- KEY SCREEN
function Window:_BuildKeyScreen(keyCfg)
    local screen = self:_makeScreenBase("EnterKeyScreen")

    Create("ImageLabel", {
        Name = "Icon", BackgroundTransparency = 1, Image = Icons.KeyIcon,
        ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.24,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.26),
        Size = UDim2.fromOffset(72, 72), Parent = screen,
    })
    Create("TextLabel", {
        Name = "WelcomeText", BackgroundTransparency = 1,
        Text = keyCfg.Title or ("Welcome to " .. (self._cfg.Name or "amphibia") .. "."),
        FontFace = Fonts.Serif, TextSize = 32, TextColor3 = Color3.fromRGB(213, 213, 213),
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.44),
        Size = UDim2.new(1, 0, 0, 60), Parent = screen,
    })
    Create("TextLabel", {
        Name = "WelcomeDesc", BackgroundTransparency = 1,
        Text = keyCfg.Subtitle or "Enter your key to get started.",
        FontFace = Fonts.SerifItalic, TextSize = 18, TextColor3 = Theme.Muted,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53),
        Size = UDim2.new(1, 0, 0, 40), Parent = screen,
    })

    -- glow behind input
    local glow = Create("ImageLabel", {
        Name = "KeyInputGlow", BackgroundTransparency = 1, Image = Icons.KeyGlow,
        ImageColor3 = Color3.fromRGB(95, 95, 95), ImageTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.635),
        Size = UDim2.fromOffset(483, 272), Parent = screen,
    })

    local inputBg = Create("Frame", {
        Name = "KeyInputBG", BackgroundColor3 = Color3.fromRGB(29, 29, 29),
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.63),
        Size = UDim2.fromOffset(319, 40), ZIndex = 3, Parent = screen,
    })
    local ibCorner = corner(8, inputBg)
    local ibStroke = stroke(Color3.fromRGB(55, 55, 55), 1, inputBg)

    pad(inputBg, 14, 34, 0, 0)
    local input = CustomInput.new(inputBg, {
        Placeholder = "Enter key here", Font = Fonts.Mono, TextSize = 14,
        TextColor = Color3.fromRGB(210, 210, 210),
    })

    local activate = Create("ImageButton", {
        Name = "ActivateButton", BackgroundTransparency = 1, Image = Icons.KeyArrow,
        ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.8, Rotation = 90,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -18, 0.5, 0),
        Size = UDim2.fromOffset(20, 18), ZIndex = 4, Parent = inputBg,
    })
    activate.MouseEnter:Connect(function() Anim.to(activate, { ImageTransparency = 0.3 }, Anim.Fast) end)
    activate.MouseLeave:Connect(function() Anim.to(activate, { ImageTransparency = 0.8 }, Anim.Fast) end)

    -- focus visuals
    input.Capture.Focused:Connect(function()
        Anim.to(ibStroke, { Color = Color3.fromRGB(100, 100, 100) }, Anim.Fast)
        Anim.to(glow, { ImageTransparency = 0.7 }, Anim.Fast)
    end)
    input.Capture.FocusLost:Connect(function()
        Anim.to(ibStroke, { Color = Color3.fromRGB(55, 55, 55) }, Anim.Fast)
        Anim.to(glow, { ImageTransparency = 1 }, Anim.Fast)
    end)

    -- error label
    local errLbl = Create("TextLabel", {
        Name = "ErrorText", BackgroundTransparency = 1, Text = "",
        FontFace = Fonts.SerifItalic, TextSize = 15, TextColor3 = Theme.Error,
        TextTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.72),
        Size = UDim2.new(1, 0, 0, 24), Parent = screen,
    })

    -- socials -> print name (user finishes later)
    local socials = { { Icons.Discord, "Discord" }, { Icons.Site, "Site" }, { Icons.Youtube, "Youtube" } }
    for i, s in ipairs(socials) do
        local b = Create("ImageButton", {
            Name = "Copy" .. s[2], BackgroundTransparency = 1, Image = s[1],
            ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.8,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.4 + (i - 1) * 0.1, 0.9),
            Size = UDim2.fromOffset(30, 30), Parent = screen,
        })
        b.MouseEnter:Connect(function() Anim.to(b, { ImageTransparency = 0.55 }, Anim.Fast) end)
        b.MouseLeave:Connect(function() Anim.to(b, { ImageTransparency = 0.8 }, Anim.Fast) end)
        b.MouseButton1Click:Connect(function() print("[amphibia] social clicked: " .. s[2]) end)
    end

    -- validation --------------------------------------------------------
    local validKeys = keyCfg.Keys or { keyCfg.Key or "devaccesskey1337" }
    local passed = false
    local function isValid(k)
        for _, v in ipairs(validKeys) do if k == v then return true end end
        return false
    end
    local function showError(msg)
        errLbl.Text = msg or "Invalid key — that key doesn't exist or has expired."
        errLbl.TextTransparency = 1
        Anim.to(errLbl, { TextTransparency = 0 }, Anim.Spring)
        Anim.to(ibStroke, { Color = Theme.Error }, Anim.Fast)
        -- shake
        local base = inputBg.Position
        task.spawn(function()
            for _, dx in ipairs({ 10, -8, 6, -4, 2, 0 }) do
                Anim.to(inputBg, { Position = base + UDim2.fromOffset(dx, 0) }, Anim.Linear)
                task.wait(0.04)
            end
            inputBg.Position = base
        end)
        task.delay(2.4, function()
            Anim.to(errLbl, { TextTransparency = 1 }, Anim.Spring)
            Anim.to(ibStroke, { Color = Color3.fromRGB(55, 55, 55) }, Anim.Fast)
        end)
    end
    local function submit()
        if passed then return end
        local k = input:GetText()
        if isValid(k) then
            passed = true
            Anim.to(ibStroke, { Color = Color3.fromRGB(120, 200, 140) }, Anim.Fast)
            if keyCfg.OnSuccess then task.spawn(keyCfg.OnSuccess, k) end
        else
            showError(keyCfg.ErrorText)
        end
    end
    activate.MouseButton1Click:Connect(submit)
    input.onEnter = submit

    self:_openScreen(screen)
    repeat task.wait() until passed
    self:_closeScreen(screen)
    return true
end

------------------------------------------------------------------ LOADING SCREEN
function Window:_BuildLoadingScreen(loadCfg)
    local screen = self:_makeScreenBase("LoadingScreen")
    local dur = loadCfg.Time or 6

    Create("TextLabel", {
        Name = "LoadingTitle", BackgroundTransparency = 1,
        Text = loadCfg.Title or "Just a moment\u{2026}",
        FontFace = Fonts.Serif, TextSize = 32, TextColor3 = Color3.fromRGB(213, 213, 213),
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42),
        Size = UDim2.new(1, 0, 0, 60), Parent = screen,
    })
    local line = Create("Frame", {
        Name = "LoadingLine", BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.54),
        Size = UDim2.fromOffset(224, 9), Parent = screen,
    })
    corner(999, line)
    local fill = Create("Frame", {
        Name = "Fill", BackgroundColor3 = Color3.fromRGB(225, 225, 225),
        Size = UDim2.new(0, 0, 1, 0), Parent = line,
    })
    corner(999, fill)
    Create("TextLabel", {
        Name = "LoadingDesc", BackgroundTransparency = 1,
        Text = loadCfg.Subtitle or "Setting things up \u{2014} this won't take long.",
        FontFace = Fonts.SerifItalic, TextSize = 16, TextColor3 = Theme.Muted,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6),
        Size = UDim2.new(1, 0, 0, 40), Parent = screen,
    })
    local timer = Create("TextLabel", {
        Name = "Timer", BackgroundTransparency = 1, Text = "~" .. dur .. "s",
        FontFace = Fonts.SerifItalic, TextSize = 15, TextColor3 = Color3.fromRGB(70, 70, 70),
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.66),
        Size = UDim2.new(1, 0, 0, 30), Parent = screen,
    })

    self:_openScreen(screen)
    Anim.to(fill, { Size = UDim2.new(1, 0, 1, 0) },
        TweenInfo.new(dur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
    task.spawn(function()
        for t = dur, 0, -1 do
            timer.Text = "~" .. t .. "s"
            task.wait(1)
            if not screen.Parent then return end
        end
        timer.Text = "Loaded!"
    end)
    task.wait(dur + 0.3)
    self:_closeScreen(screen)
end

--------------------------------------------------------------- REVEAL MAIN
function Window:_RevealWindow()
    local main = self.Main
    main.Visible = true
    main.Size = UDim2.fromOffset(0, 0)
    Anim.to(main, { Size = UDim2.fromOffset(987, 608) }, Anim.Spring)

    -- make sure a tab is selected & its page visible
    local first = self.Tabs[1]
    if first then
        self.ActiveTab = nil
        self:SelectTab(first)
    end

    task.wait(0.18)
    -- staggered pop-in of the active tab's sections via UIScale
    if self.ActiveTab then
        for i, sec in ipairs(self.ActiveTab.SectionList) do
            if sec.Frame then
                local sc = Create("UIScale", { Scale = 0.9, Parent = sec.Frame })
                sec.Frame.Position = sec.Frame.Position
                task.delay(0.04 * (i - 1), function()
                    Anim.to(sc, { Scale = 1 }, Anim.Snappy)
                    task.delay(0.4, function() sc:Destroy() end)
                end)
            end
        end
    end
    if self._cfg.OnLoaded then task.spawn(self._cfg.OnLoaded) end
end

--============================================================================--
--  TABS & CATEGORIES
--============================================================================--
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

function Window:_ensureCategory(group)
    group = group or "Main"
    if self.Categories[group] then return self.Categories[group] end
    local cat = Create("Frame", {
        Name = group .. "Category", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.TabsHolder,
    })
    listLayout(cat, Enum.FillDirection.Vertical, 6)
    Create("TextLabel", {
        Name = "CategoryText", BackgroundTransparency = 1, Text = group,
        FontFace = Fonts.SerifItalic, TextSize = 17, TextColor3 = Color3.new(1, 1, 1),
        TextTransparency = 0.7, TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0, Parent = cat,
    })
    local holder = Create("Frame", {
        Name = "TabsHolder", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1, Parent = cat,
    })
    listLayout(holder, Enum.FillDirection.Vertical, 2)
    pad(holder, 6, 0, 4, 0)
    self.Categories[group] = holder
    return holder
end

function Window:CreateTab(opts)
    opts = opts or {}
    local group = opts.Group or "Main"
    local holder = self:_ensureCategory(group)

    local btn = Create("TextButton", {
        Name = (opts.Name or "Tab") .. "TabButton", BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BackgroundTransparency = 1, AutoButtonColor = false,
        Text = opts.Name or "Tab", FontFace = Fonts.Sans, TextSize = 15,
        TextColor3 = Theme.TabIdle, TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 26), Parent = holder,
    })
    corner(6, btn)
    pad(btn, 10, 6, 0, 0)
    local glow = addShadow(btn, Color3.new(1, 1, 1), 1, 1.2)

    -- page ---------------------------------------------------------------
    local page = Create("ScrollingFrame", {
        Name = "Tab_" .. (opts.Name or "Tab"), BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0), Position = UDim2.fromScale(0, 0),
        ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60),
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false, Parent = self.Pages,
    })
    pad(page, 16, 6, 14, 14)
    local pageLayout = listLayout(page, Enum.FillDirection.Vertical, 12)

    -- tab info header
    local infoHolder = Create("Frame", {
        Name = "TabInfoFrameHolder", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 0, Parent = page,
    })
    listLayout(infoHolder, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    Create("TextLabel", {
        Name = "TabName", BackgroundTransparency = 1, Text = opts.Name or "Tab",
        FontFace = Fonts.SerifBold, TextSize = 25, TextColor3 = Theme.SectionName,
        TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0), LayoutOrder = 0, Parent = infoHolder,
    })
    Create("ImageLabel", {
        Name = "Divider", BackgroundTransparency = 1, Image = Icons.Divider,
        ImageColor3 = Color3.fromRGB(49, 49, 49), Size = UDim2.fromOffset(9, 9),
        LayoutOrder = 1, Parent = infoHolder,
    })
    Create("TextLabel", {
        Name = "TabGroupName", BackgroundTransparency = 1, Text = group,
        FontFace = Fonts.SerifItalic, TextSize = 19, TextColor3 = Color3.fromRGB(100, 100, 100),
        TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0), LayoutOrder = 2, Parent = infoHolder,
    })

    -- two-column body
    local columns = Create("Frame", {
        Name = "Columns", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1, Parent = page,
    })
    listLayout(columns, Enum.FillDirection.Horizontal, 14, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)
    local function mkColumn(name, order)
        local c = Create("Frame", {
            Name = name, BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -7, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = order, Parent = columns,
        })
        listLayout(c, Enum.FillDirection.Vertical, 14)
        return c
    end
    local leftCol  = mkColumn("LeftColumn", 0)
    local rightCol = mkColumn("RightColumn", 1)

    local tab = setmetatable({}, Tab)
    tab.Window      = self
    tab.Name        = opts.Name or "Tab"
    tab.Group       = group
    tab.Button      = btn
    tab.Glow        = glow
    tab.Page        = page
    tab.Left        = leftCol
    tab.Right       = rightCol
    tab.SectionList = {}
    tab._sideCount  = { Left = 0, Right = 0 }
    table.insert(self.Tabs, tab)

    btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then Anim.to(btn, { TextColor3 = Color3.fromRGB(225, 225, 225) }, Anim.Fast) end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then Anim.to(btn, { TextColor3 = Theme.TabIdle }, Anim.Fast) end
    end)
    btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)

    if not self.ActiveTab then self:SelectTab(tab) end
    return tab
end

function Window:SelectTab(tab)
    if self.ActiveTab == tab then return end
    for _, t in ipairs(self.Tabs) do
        local active = (t == tab)
        t.Page.Visible = active
        Anim.to(t.Button, {
            TextColor3 = active and Theme.TabActive or Theme.TabIdle,
            BackgroundTransparency = active and 0.9 or 1,
        }, Anim.Spring)
        Anim.to(t.Glow, { ImageTransparency = active and 0.55 or 1 }, Anim.Spring)
    end
    self.ActiveTab = tab
    self:CloseAllPopups()
end

--============================================================================--
--  SECTION  (collapsible)
--============================================================================--
function Tab:CreateSection(opts)
    opts = opts or {}
    local win = self.Window
    local side = opts.Side or (self._sideCount.Left <= self._sideCount.Right and "Left" or "Right")
    self._sideCount[side] = self._sideCount[side] + 1
    local parent = (side == "Right") and self.Right or self.Left

    local frame = Create("Frame", {
        Name = (opts.Name or "Section") .. "Section", BackgroundColor3 = Theme.Section,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parent,
    })
    corner(8, frame)
    stroke(Theme.SectionStroke, 0.5, frame)
    listLayout(frame, Enum.FillDirection.Vertical, 0)
    pad(frame, 0, 0, 0, 10)

    -- header
    local head = Create("Frame", {
        Name = "SectionNameHolderFrame", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 50), LayoutOrder = 0, Parent = frame,
    })
    Create("TextLabel", {
        Name = "SectionName", BackgroundTransparency = 1, Text = opts.Name or "Section",
        FontFace = Fonts.SerifBold, TextSize = 24, TextColor3 = Theme.SectionName,
        TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0.05, 0, 0.5, 0), Size = UDim2.new(0.85, 0, 0.9, 0), Parent = head,
    })
    local icon = Create("ImageLabel", {
        Name = "Icon", BackgroundTransparency = 1, Image = Icons.Chevron,
        ImageColor3 = Color3.fromRGB(120, 120, 120), Rotation = 180,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.92, 0, 0.5, 0),
        Size = UDim2.fromOffset(15, 15), Parent = head,
    })
    local sbtn = Create("ImageButton", {
        Name = "SectionButton", BackgroundTransparency = 1, ImageTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 5, Parent = head,
    })

    -- body
    local body = Create("Frame", {
        Name = "ButtonsHolderFrame", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true, LayoutOrder = 1, Parent = frame,
    })
    local bodyList = listLayout(body, Enum.FillDirection.Vertical, 4)
    pad(body, 14, 14, 0, 6)

    local section = setmetatable({}, Section)
    section.Window   = win
    section.Tab      = self
    section.Frame    = frame
    section.Body     = body
    section.Icon     = icon
    section.Name     = opts.Name or "Section"
    section.Open     = true
    section.Elements = {}
    table.insert(self.SectionList, section)

    local function setOpen(state)
        section.Open = state
        Anim.to(icon, { Rotation = state and 180 or 90 }, Anim.Spring)
        if state then
            body.Visible = true
            body.AutomaticSize = Enum.AutomaticSize.Y
            body.Size = UDim2.new(1, 0, 0, 0)
        else
            body.AutomaticSize = Enum.AutomaticSize.None
            local h = body.AbsoluteSize.Y
            body.Size = UDim2.new(1, 0, 0, h)
            local t = Anim.to(body, { Size = UDim2.new(1, 0, 0, 0) }, Anim.Spring)
            t.Completed:Connect(function() body.Visible = false end)
        end
    end
    sbtn.MouseButton1Click:Connect(function() setOpen(not section.Open) end)
    section.SetOpen = setOpen

    if opts.Open == false then task.defer(function() setOpen(false) end) end
    return section
end

--============================================================================--
--  COMPONENT HELPERS
--============================================================================--
function Section:_register(name, elementFrame, api)
    table.insert(self.Window.SearchIndex, {
        name = name, section = self.Name, tab = self.Tab.Name,
        frame = elementFrame, tabObj = self.Tab, sectionObj = self, api = api,
    })
end
function Section:_load(flag, default)
    if flag and self.Window.ConfigEnabled then
        return self.Window.Config:Get(flag, default)
    end
    return default
end
function Section:_store(flag, value)
    if flag and self.Window.ConfigEnabled then
        self.Window.Config:Set(flag, value)
    end
end

local function baseRow(section, name, height)
    local row = Create("Frame", {
        Name = (name or "Element"), BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or 50), Parent = section.Body,
    })
    local lbl = Create("TextLabel", {
        Name = "Name", BackgroundTransparency = 1, Text = name or "",
        FontFace = Fonts.Sans, TextSize = 16, TextColor3 = Theme.ElementName,
        TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0.02, 0, 0.5, 0), Size = UDim2.new(0.55, 0, 0, 27), Parent = row,
    })
    stroke(Theme.ElementName, 0.2, lbl)
    return row, lbl
end

-- format a number for display
local function fmtNumber(v, decimals, suffix)
    local s
    if decimals and decimals > 0 then
        s = string.format("%." .. decimals .. "f", v)
    else
        s = tostring(math.floor(v + 0.5))
    end
    return s .. (suffix or "")
end
local function round(v, decimals)
    local m = 10 ^ (decimals or 0)
    return math.floor(v * m + 0.5) / m
end

--============================================================================--
--  LABEL
--============================================================================--
function Section:CreateLabel(opts)
    opts = opts or {}
    local row, lbl = baseRow(self, opts.Name or opts.Text or "Label", opts.Height or 30)
    lbl.Size = UDim2.new(0.96, 0, 1, 0)
    lbl.TextColor3 = opts.Color or Theme.Muted
    lbl.FontFace = opts.Font or Fonts.Sans
    local api = { Instance = row }
    function api:Set(t) lbl.Text = t end
    self:_register(opts.Name or opts.Text or "Label", row, api)
    return api
end

--============================================================================--
--  BUTTON
--============================================================================--
function Section:CreateButton(opts)
    opts = opts or {}
    local row = Create("Frame", {
        Name = (opts.Name or "Button"), BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40), Parent = self.Body,
    })
    local btn = Create("ImageButton", {
        Name = "ButtonButton", BackgroundColor3 = Theme.Inset, ImageTransparency = 1,
        AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.97, 0, 0.72, 0), Parent = row,
    })
    corner(6, btn)
    local st = stroke(Color3.fromRGB(50, 50, 50), 1, btn)
    local lbl = Create("TextLabel", {
        Name = "Name", BackgroundTransparency = 1, Text = opts.Name or "Button",
        FontFace = Fonts.Sans, TextSize = 16, TextColor3 = Theme.ElementName,
        Size = UDim2.new(1, 0, 1, 0), Parent = btn,
    })
    stroke(Theme.ElementName, 0.2, lbl)

    btn.MouseEnter:Connect(function()
        Anim.to(btn, { BackgroundColor3 = Color3.fromRGB(22, 22, 24) }, Anim.Fast)
        Anim.to(st, { Color = Color3.fromRGB(80, 80, 80) }, Anim.Fast)
    end)
    btn.MouseLeave:Connect(function()
        Anim.to(btn, { BackgroundColor3 = Theme.Inset }, Anim.Fast)
        Anim.to(st, { Color = Color3.fromRGB(50, 50, 50) }, Anim.Fast)
    end)
    btn.MouseButton1Down:Connect(function() Anim.to(btn, { Size = UDim2.new(0.94, 0, 0.68, 0) }, Anim.Fast) end)
    btn.MouseButton1Up:Connect(function() Anim.to(btn, { Size = UDim2.new(0.97, 0, 0.72, 0) }, Anim.Snappy) end)
    btn.MouseButton1Click:Connect(function()
        if opts.Callback then task.spawn(opts.Callback) end
    end)

    local api = { Instance = row }
    function api:SetText(t) lbl.Text = t end
    self:_register(opts.Name or "Button", row, api)
    return api
end

--============================================================================--
--  TOGGLE
--============================================================================--
function Section:CreateToggle(opts)
    opts = opts or {}
    local state = self:_load(opts.Flag, opts.Default == true)
    local row, lbl = baseRow(self, opts.Name or "Toggle", 50)

    local tf = Create("Frame", {
        Name = "ToggleFrame", BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0.98, 0, 0.5, 0),
        Size = UDim2.fromOffset(45, 25), Parent = row,
    })
    corner(999, tf)
    local tfStroke = stroke(state and Theme.ToggleOnStroke or Theme.ToggleOffStroke, 0.5, tf)
    local dot = Create("Frame", {
        Name = "Dot", BackgroundColor3 = state and Color3.new(1, 1, 1) or Theme.ToggleOffDot,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(state and 0.7 or 0.3, 0, 0.5, 0), Size = UDim2.fromOffset(19, 19), Parent = tf,
    })
    corner(999, dot)
    local dotShadow = addShadow(dot, Color3.new(1, 1, 1), state and 0.17 or 1, 2)
    local valLbl = Create("TextLabel", {
        Name = "ToggleValue", BackgroundTransparency = 1, Text = state and "On" or "Off",
        FontFace = Fonts.SerifItalic, TextSize = 16, TextColor3 = Color3.fromRGB(102, 102, 102),
        TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(0.8, 0, 0.5, 0), Size = UDim2.new(0, 100, 1, 0), Parent = row,
    })
    local hit = Create("ImageButton", {
        BackgroundTransparency = 1, ImageTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = row,
    })

    local function apply(v, fire)
        state = v
        Anim.to(tf, { BackgroundColor3 = v and Theme.ToggleOn or Theme.ToggleOff }, Anim.Spring)
        Anim.to(tfStroke, { Color = v and Theme.ToggleOnStroke or Theme.ToggleOffStroke }, Anim.Spring)
        Anim.to(dot, {
            Position = UDim2.new(v and 0.7 or 0.3, 0, 0.5, 0),
            BackgroundColor3 = v and Color3.new(1, 1, 1) or Theme.ToggleOffDot,
        }, Anim.Snappy)
        Anim.to(dotShadow, { ImageTransparency = v and 0.17 or 1 }, Anim.Spring)
        valLbl.Text = v and "On" or "Off"
        self:_store(opts.Flag, v)
        if fire and opts.Callback then task.spawn(opts.Callback, v) end
    end
    hit.MouseButton1Click:Connect(function() apply(not state, true) end)
    if state and opts.Callback then task.spawn(opts.Callback, true) end

    local api = { Instance = row }
    function api:Set(v) apply(v == true, true) end
    function api:Get() return state end
    self:_register(opts.Name or "Toggle", row, api)
    return api
end

--============================================================================--
--  SLIDER
--============================================================================--
function Section:CreateSlider(opts)
    opts = opts or {}
    local min, max = opts.Min or 0, opts.Max or 100
    local decimals = opts.Decimals or 0
    local suffix   = opts.Suffix or ""
    local step     = opts.Step
    local value    = self:_load(opts.Flag, opts.Default or min)
    value = math.clamp(value, min, max)

    local row, lbl = baseRow(self, opts.Name or "Slider", 50)
    lbl.Position = UDim2.new(0.01, 0, 0.28, 0)
    lbl.Size = UDim2.new(0.6, 0, 0, 27)

    local track = Create("Frame", {
        Name = "SliderBg", BackgroundColor3 = Theme.SliderTrack,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.72, 0),
        Size = UDim2.new(0.95, 0, 0, 2), Parent = row,
    })
    corner(999, track)
    local fill = Create("Frame", {
        Name = "Fill", BackgroundColor3 = Theme.Accent, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 0, 1, 0), Parent = track,
    })
    corner(999, fill)
    addShadow(fill, Color3.new(1, 1, 1), 0.57, 1.4)
    local knob = Create("Frame", {
        Name = "Knob", BackgroundColor3 = Theme.Accent, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(15, 15), ZIndex = 3, Parent = track,
    })
    corner(999, knob)
    addShadow(knob, Color3.new(1, 1, 1), 0.27, 2)

    local valLbl = Create("TextLabel", {
        Name = "Value", BackgroundTransparency = 1, Text = fmtNumber(value, decimals, suffix),
        FontFace = Fonts.SerifBold, TextSize = 20, TextColor3 = Theme.Value,
        TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(0.99, 0, 0.28, 0), Size = UDim2.new(0, 104, 0, 27), Parent = row,
    })
    stroke(Theme.ElementName, 0.2, valLbl)
    local editBtn = Create("TextButton", {
        BackgroundTransparency = 1, Text = "", AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(0.99, 0, 0.28, 0), Size = UDim2.new(0, 104, 0, 27), ZIndex = 4, Parent = row,
    })

    local function frac() return (value - min) / (max - min) end
    local function refresh(fire)
        local f = frac()
        Anim.to(fill, { Size = UDim2.new(f, 0, 1, 0) }, Anim.Fast)
        Anim.to(knob, { Position = UDim2.new(f, 0, 0.5, 0) }, Anim.Fast)
        valLbl.Text = fmtNumber(value, decimals, suffix)
        self:_store(opts.Flag, value)
        if fire and opts.Callback then task.spawn(opts.Callback, value) end
    end
    local function setValue(v, fire)
        v = math.clamp(v, min, max)
        if step then v = min + math.floor((v - min) / step + 0.5) * step end
        v = round(v, decimals)
        value = v
        refresh(fire)
    end
    task.defer(function() refresh(false) end)

    -- dragging
    local dragging = false
    local function fromMouse(x)
        local rel = (x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X)
        setValue(min + math.clamp(rel, 0, 1) * (max - min), true)
    end
    local function begin(input)
        dragging = true
        Anim.to(knob, { Size = UDim2.fromOffset(18, 18) }, Anim.Snappy)
        fromMouse(input.Position.X)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then begin(i) end
    end)
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then begin(i) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            fromMouse(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            Anim.to(knob, { Size = UDim2.fromOffset(15, 15) }, Anim.Snappy)
        end
    end)

    -- click value to type it
    editBtn.MouseButton1Click:Connect(function()
        valLbl.TextTransparency = 1
        local editor = CustomInput.new(row, {
            Size = UDim2.new(0, 104, 0, 27), Position = UDim2.new(0.99, -104, 0.28, -13),
            Align = Enum.HorizontalAlignment.Right, Numeric = true,
            Font = Fonts.SerifBold, TextSize = 20, TextColor = Theme.Value,
            Default = fmtNumber(value, decimals, ""),
        })
        editor.Frame.ZIndex = 6
        editor:Focus()
        editor.Capture.FocusLost:Connect(function()
            local n = tonumber(editor:GetText())
            if n then setValue(n, true) end
            valLbl.TextTransparency = 0
            editor.Frame:Destroy()
        end)
    end)

    local api = { Instance = row }
    function api:Set(v) setValue(v, true) end
    function api:Get() return value end
    self:_register(opts.Name or "Slider", row, api)
    return api
end

--============================================================================--
--  NUMBER PICKER
--============================================================================--
function Section:CreateNumberPicker(opts)
    opts = opts or {}
    local min = opts.Min or 0
    local max = opts.Max or 100
    local step = opts.Step or 1
    local decimals = opts.Decimals or 0
    local value = self:_load(opts.Flag, opts.Default or min)
    value = math.clamp(value, min, max)

    local row, lbl = baseRow(self, opts.Name or "Number Picker", 50)

    local holder = Create("Frame", {
        Name = "NumberPickerHolder", BackgroundColor3 = Theme.Inset,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.83, 0, 0.5, 0),
        Size = UDim2.fromOffset(106, 32), Parent = row,
    })
    corner(8, holder)
    local minus = Create("ImageButton", {
        Name = "Minus", BackgroundTransparency = 1, Image = Icons.Minus,
        ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.4,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.14, 0, 0.5, 0),
        Size = UDim2.fromOffset(20, 20), Parent = holder,
    })
    local plus = Create("ImageButton", {
        Name = "Plus", BackgroundTransparency = 1, Image = Icons.Plus,
        ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.4,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.87, 0, 0.5, 0),
        Size = UDim2.fromOffset(20, 20), Parent = holder,
    })
    local valLbl = Create("TextLabel", {
        Name = "NumberValue", BackgroundTransparency = 1, Text = fmtNumber(value, decimals, ""),
        FontFace = Fonts.Serif, TextSize = 20, TextColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 50, 0.85, 0), Parent = holder,
    })
    local editBtn = Create("TextButton", {
        BackgroundTransparency = 1, Text = "", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 50, 1, 0), ZIndex = 4, Parent = holder,
    })

    local function setValue(v, fire)
        v = math.clamp(round(v, decimals), min, max)
        value = v
        valLbl.Text = fmtNumber(v, decimals, "")
        -- little bump animation
        valLbl.TextTransparency = 0.4
        Anim.to(valLbl, { TextTransparency = 0 }, Anim.Fast)
        self:_store(opts.Flag, v)
        if fire and opts.Callback then task.spawn(opts.Callback, v) end
    end
    local function bump(btn) Anim.to(btn, { ImageTransparency = 0 }, Anim.Fast); task.delay(0.12, function() Anim.to(btn, { ImageTransparency = 0.4 }, Anim.Fast) end) end
    minus.MouseButton1Click:Connect(function() bump(minus); setValue(value - step, true) end)
    plus.MouseButton1Click:Connect(function() bump(plus); setValue(value + step, true) end)

    editBtn.MouseButton1Click:Connect(function()
        valLbl.TextTransparency = 1
        local editor = CustomInput.new(holder, {
            Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(0.5, -25, 0, 0),
            Align = Enum.HorizontalAlignment.Center, Numeric = true,
            Font = Fonts.Serif, TextSize = 20, TextColor = Color3.new(1, 1, 1),
            Default = fmtNumber(value, decimals, ""),
        })
        editor.Frame.ZIndex = 6
        editor:Focus()
        editor.Capture.FocusLost:Connect(function()
            local n = tonumber(editor:GetText())
            if n then setValue(n, true) else valLbl.TextTransparency = 0 end
            valLbl.TextTransparency = 0
            editor.Frame:Destroy()
        end)
    end)

    task.defer(function() if opts.Callback then task.spawn(opts.Callback, value) end end)

    local api = { Instance = row }
    function api:Set(v) setValue(v, true) end
    function api:Get() return value end
    self:_register(opts.Name or "Number Picker", row, api)
    return api
end

--============================================================================--
--  COLOR PICKER WINDOW  (shared, draggable, outside-click close)
--============================================================================--
local function sliderFraction(frame, x)
    return math.clamp((x - frame.AbsolutePosition.X) / math.max(1, frame.AbsoluteSize.X), 0, 1)
end
local function toHex(c)
    return string.format("%02X%02X%02X",
        math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function fromHex(hex)
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end

function Window:_BuildColorPickerWindow()
    local w = Create("Frame", {
        Name = "ColorPicker", BackgroundColor3 = Theme.Popup, Visible = false,
        Position = UDim2.fromScale(0.78, 0.5), Size = UDim2.fromOffset(195, 349),
        ZIndex = 60, Parent = self.Gui,
    })
    corner(8, w)
    stroke(Theme.PopupStroke, 1, w)
    addShadow(w, Color3.new(0, 0, 0), 0.35, 1.5)

    -- title
    local title = Create("Frame", {
        Name = "Title", BackgroundColor3 = Color3.fromRGB(14, 14, 14),
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8),
        Size = UDim2.fromOffset(177, 34), ZIndex = 61, Parent = w,
    })
    corner(6, title)
    Create("TextLabel", {
        Name = "FromText", BackgroundTransparency = 1, Text = "Color Picker",
        FontFace = Fonts.Sans, TextSize = 16, TextColor3 = Theme.ElementName,
        TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0.05, 0, 0, 0),
        Size = UDim2.new(0.9, 0, 1, 0), ZIndex = 61, Parent = title,
    })
    local closeBtn = Create("ImageButton", {
        Name = "CloseButton", BackgroundTransparency = 1, Image = Icons.PopupClose,
        ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.5,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.88, 0, 0.5, 0),
        Size = UDim2.fromOffset(22, 22), ZIndex = 62, Parent = title,
    })
    makeDraggable(title, w)

    -- SV square
    local square = Create("Frame", {
        Name = "SV", BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 52),
        Size = UDim2.fromOffset(178, 150), ZIndex = 61, Parent = w,
    })
    corner(6, square)
    local whiteOv = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(1, 0, 1, 0), ZIndex = 61, Parent = square,
    })
    corner(6, whiteOv)
    Create("UIGradient", {
        Color = ColorSequence.new(Color3.new(1, 1, 1)),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
        Parent = whiteOv,
    })
    local blackOv = Create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.new(1, 0, 1, 0), ZIndex = 62, Parent = square,
    })
    corner(6, blackOv)
    Create("UIGradient", {
        Color = ColorSequence.new(Color3.new(0, 0, 0)),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
        Rotation = 90, Parent = blackOv,
    })
    local svKnob = Create("Frame", {
        Name = "Knob", BackgroundColor3 = Color3.fromRGB(255, 0, 0), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(14, 14), ZIndex = 63, Parent = square,
    })
    corner(999, svKnob)
    stroke(Color3.new(1, 1, 1), 1.5, svKnob)

    -- hue slider
    local hue = Create("Frame", {
        Name = "Hue", BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 210), Size = UDim2.fromOffset(178, 16), ZIndex = 61, Parent = w,
    })
    corner(999, hue)
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
        }), Parent = hue,
    })
    local hueKnob = Create("Frame", {
        Name = "Knob", BackgroundColor3 = Color3.new(0, 0, 0), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 15), ZIndex = 62, Parent = hue,
    })
    stroke(Color3.new(1, 1, 1), 1, hueKnob, 0.2)

    -- transparency slider
    local trans = Create("Frame", {
        Name = "Trans", BackgroundColor3 = Color3.fromRGB(255, 0, 0), AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 234), Size = UDim2.fromOffset(178, 16), ZIndex = 61, Parent = w,
    })
    corner(999, trans)
    Create("ImageLabel", {
        Name = "Chess", BackgroundTransparency = 1, Image = Icons.Chess,
        ImageColor3 = Color3.fromRGB(122, 122, 122), ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.fromOffset(12, 12), Size = UDim2.new(1, 0, 1, 0), ZIndex = 61, Parent = trans,
    })
    local transGrad = Create("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(255, 0, 0)),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
        Parent = trans,
    })
    local transKnob = Create("Frame", {
        Name = "Knob", BackgroundColor3 = Color3.new(0, 0, 0), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 15), ZIndex = 62, Parent = trans,
    })
    stroke(Color3.new(1, 1, 1), 1, transKnob, 0.2)

    -- hex holder
    local hexHolder = Create("Frame", {
        Name = "HexHolder", BackgroundColor3 = Color3.fromRGB(22, 22, 22),
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 260),
        Size = UDim2.fromOffset(177, 38), ZIndex = 61, Parent = w,
    })
    corner(8, hexHolder)
    local hexTag = Create("Frame", {
        BackgroundColor3 = Theme.Popup, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0.03, 0, 0.5, 0), Size = UDim2.fromOffset(41, 26), ZIndex = 62, Parent = hexHolder,
    })
    corner(6, hexTag)
    Create("TextLabel", {
        BackgroundTransparency = 1, Text = "HEX", FontFace = Fonts.Sans, TextSize = 15,
        TextColor3 = Color3.fromRGB(210, 210, 210), Size = UDim2.new(1, 0, 1, 0), ZIndex = 62, Parent = hexTag,
    })
    Create("TextLabel", {
        Name = "Prefix", BackgroundTransparency = 1, Text = "#", FontFace = Fonts.Sans, TextSize = 16,
        TextColor3 = Color3.fromRGB(190, 190, 190), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.4, 0, 0.5, 0), Size = UDim2.fromOffset(12, 20), ZIndex = 62, Parent = hexHolder,
    })
    local hexInputHolder = Create("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0.44, 0, 0.5, 0), Size = UDim2.fromOffset(56, 20), ZIndex = 62, Parent = hexHolder,
    })
    local transLbl = Create("TextLabel", {
        Name = "TransLbl", BackgroundTransparency = 1, Text = "0%", FontFace = Fonts.Sans, TextSize = 13,
        TextColor3 = Color3.fromRGB(190, 190, 190), TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0.97, 0, 0.5, 0),
        Size = UDim2.fromOffset(50, 20), ZIndex = 62, Parent = hexHolder,
    })

    -- state --------------------------------------------------------------
    local st = { h = 0, s = 1, v = 1, a = 0, onChange = nil }
    local hexInput
    local function apply(fireHex)
        local base = Color3.fromHSV(st.h, 1, 1)
        square.BackgroundColor3 = base
        svKnob.BackgroundColor3 = Color3.fromHSV(st.h, st.s, st.v)
        svKnob.Position = UDim2.fromScale(st.s, 1 - st.v)
        hueKnob.Position = UDim2.new(st.h, 0, 0.5, 0)
        transKnob.Position = UDim2.new(st.a, 0, 0.5, 0)
        transGrad.Color = ColorSequence.new(Color3.fromHSV(st.h, st.s, st.v))
        local col = Color3.fromHSV(st.h, st.s, st.v)
        transLbl.Text = math.floor(st.a * 100 + 0.5) .. "%"
        if fireHex and hexInput then hexInput:SetText(toHex(col), true) end
        if st.onChange then task.spawn(st.onChange, col, st.a) end
    end
    self._cpApply = apply

    hexInput = CustomInput.new(hexInputHolder, {
        Font = Fonts.Sans, TextSize = 14, TextColor = Color3.fromRGB(190, 190, 190),
        Default = "8FA8A0", MaxLen = 6, Align = Enum.HorizontalAlignment.Left,
    })
    hexInput.onEnter = function(t)
        local c = fromHex(t)
        if c then
            local h, s, v = Color3.toHSV(c)
            st.h, st.s, st.v = h, s, v
            apply(false)
        end
    end

    -- interactions
    local drag = nil
    local function sliderFraction2X(f, x) return math.clamp((x - f.AbsolutePosition.X) / math.max(1, f.AbsoluteSize.X), 0, 1) end
    local function sliderFraction2Y(f, y) return math.clamp((y - f.AbsolutePosition.Y) / math.max(1, f.AbsoluteSize.Y), 0, 1) end
    local function bindSlider(frame, kind)
        frame.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                drag = kind
                if kind == "sv" then
                    st.s = sliderFraction2X(square, i.Position.X); st.v = 1 - sliderFraction2Y(square, i.Position.Y)
                elseif kind == "hue" then st.h = sliderFraction(hue, i.Position.X)
                elseif kind == "trans" then st.a = sliderFraction(trans, i.Position.X) end
                apply(true)
            end
        end)
    end
    bindSlider(square, "sv"); bindSlider(hue, "hue"); bindSlider(trans, "trans")
    UserInputService.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
        if drag == "sv" then
            st.s = sliderFraction2X(square, i.Position.X); st.v = 1 - sliderFraction2Y(square, i.Position.Y)
        elseif drag == "hue" then st.h = sliderFraction(hue, i.Position.X)
        elseif drag == "trans" then st.a = sliderFraction(trans, i.Position.X) end
        apply(true)
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = nil end
    end)

    local function closeCP()
        Anim.to(w, { Size = UDim2.fromOffset(195, 0) }, Anim.Fast)
        task.delay(0.18, function() w.Visible = false; w.Size = UDim2.fromOffset(195, 349) end)
    end
    closeBtn.MouseButton1Click:Connect(closeCP)
    closeBtn.MouseEnter:Connect(function() Anim.to(closeBtn, { ImageTransparency = 0.15 }, Anim.Fast) end)
    closeBtn.MouseLeave:Connect(function() Anim.to(closeBtn, { ImageTransparency = 0.5 }, Anim.Fast) end)

    self._cp = { frame = w, state = st, apply = apply, close = closeCP }
end

-- open the shared color picker for a control
function Window:_openColorPicker(color, alpha, onChange, anchor)
    local cp = self._cp
    local h, s, v = Color3.toHSV(color)
    cp.state.h, cp.state.s, cp.state.v, cp.state.a = h, s, v, alpha or 0
    cp.state.onChange = onChange
    -- position near the control
    if anchor then
        local ap = anchor.AbsolutePosition
        cp.frame.Position = UDim2.fromOffset(ap.X - 205, ap.Y - 10)
    end
    cp.frame.Visible = true
    cp.frame.Size = UDim2.fromOffset(195, 0)
    Anim.to(cp.frame, { Size = UDim2.fromOffset(195, 349) }, Anim.Spring)
    cp.apply(true)
    self:CloseAllPopups()
    table.insert(self.OpenPopups, { frame = cp.frame, owner = anchor, close = cp.close })
end

--============================================================================--
--  COLOR PICKER (component)
--============================================================================--
function Section:CreateColorPicker(opts)
    opts = opts or {}
    local color = self:_load(opts.Flag, nil)
    if type(color) == "table" then color = Color3.new(color[1], color[2], color[3]) end
    color = color or opts.Default or Color3.fromRGB(143, 168, 160)
    local alpha = opts.Alpha or 0

    local row, lbl = baseRow(self, opts.Name or "Color Picker", 50)
    lbl.Size = UDim2.new(0.4, 0, 1, 0)

    local preview = Create("ImageButton", {
        Name = "Preview", BackgroundColor3 = color, ImageTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.93, 0, 0.5, 0),
        Size = UDim2.fromOffset(30, 30), Parent = row,
    })
    corner(6, preview)
    stroke(Color3.fromRGB(60, 60, 60), 0.5, preview)
    Create("TextLabel", {
        Name = "HexPrefix", BackgroundTransparency = 1, Text = "#", FontFace = Fonts.Serif,
        TextSize = 22, TextColor3 = Color3.fromRGB(222, 222, 222), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.63, 0, 0.5, 0), Size = UDim2.fromOffset(18, 40), Parent = row,
    })
    local hexHolder = Create("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0.68, 0, 0.5, 0), Size = UDim2.fromOffset(70, 24), Parent = row,
    })
    local hexInput = CustomInput.new(hexHolder, {
        Font = Fonts.SerifBold, TextSize = 20, TextColor = Color3.fromRGB(222, 222, 222),
        Default = toHex(color), MaxLen = 6, Align = Enum.HorizontalAlignment.Left,
    })

    local function set(c, a, fire, fromHexBox)
        color = c
        if a ~= nil then alpha = a end
        Anim.to(preview, { BackgroundColor3 = c }, Anim.Fast)
        if not fromHexBox then hexInput:SetText(toHex(c), true) end
        self:_store(opts.Flag, { c.R, c.G, c.B })
        if fire and opts.Callback then task.spawn(opts.Callback, c, alpha) end
    end
    hexInput.onEnter = function(t)
        local c = fromHex(t)
        if c then set(c, nil, true, true) end
    end
    preview.MouseButton1Click:Connect(function()
        self.Window:_openColorPicker(color, alpha, function(c, a) set(c, a, true) end, preview)
    end)
    task.defer(function() if opts.Callback then task.spawn(opts.Callback, color, alpha) end end)

    local api = { Instance = row }
    function api:Set(c) set(c, nil, true) end
    function api:Get() return color, alpha end
    self:_register(opts.Name or "Color Picker", row, api)
    return api
end

--============================================================================--
--  SELECTOR  (segmented single-select)
--============================================================================--
function Section:CreateSelector(opts)
    opts = opts or {}
    local options = opts.Options or {}
    local current = self:_load(opts.Flag, opts.Default or options[1])

    local row, lbl = baseRow(self, opts.Name or "Selector", 50)
    lbl.Size = UDim2.new(0.4, 0, 1, 0)

    local holder = Create("Frame", {
        Name = "SelectionsHolder", BackgroundColor3 = Theme.InsetDark,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0.97, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.X, Parent = row,
    })
    corner(6, holder)
    listLayout(holder, Enum.FillDirection.Horizontal, 0)
    pad(holder, 1, 1, 1, 1)

    local buttons = {}
    local function select(name, fire)
        current = name
        for n, b in pairs(buttons) do
            local active = (n == name)
            Anim.to(b.btn, { BackgroundColor3 = active and Theme.SelActive or Theme.InsetDark }, Anim.Fast)
            Anim.to(b.lbl, { TextColor3 = active and Theme.SelTextActive or Theme.SelTextIdle }, Anim.Fast)
            Anim.to(b.stroke, { Transparency = active and 0 or 1 }, Anim.Fast)
        end
        self:_store(opts.Flag, name)
        if fire and opts.Callback then task.spawn(opts.Callback, name) end
    end

    for i, opt in ipairs(options) do
        local b = Create("ImageButton", {
            Name = opt, BackgroundColor3 = Theme.InsetDark, ImageTransparency = 1, AutoButtonColor = false,
            Size = UDim2.new(0, 0, 1, -2), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = i, Parent = holder,
        })
        corner(5, b)
        local st = stroke(Theme.SelActiveStroke, 1, b, 1)
        local tl = Create("TextLabel", {
            Name = "Name", BackgroundTransparency = 1, Text = opt, FontFace = Fonts.Sans, TextSize = 14,
            TextColor3 = Theme.SelTextIdle, AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0), Parent = b,
        })
        pad(tl, 12, 12, 0, 0)
        buttons[opt] = { btn = b, lbl = tl, stroke = st }
        b.MouseButton1Click:Connect(function() select(opt, true) end)
    end
    if current then task.defer(function() select(current, false) end) end

    local api = { Instance = row }
    function api:Set(v) select(v, true) end
    function api:Get() return current end
    self:_register(opts.Name or "Selector", row, api)
    return api
end

--============================================================================--
--  DROPDOWN  (searchable, single or multi, outside-click close)
--============================================================================--
function Section:CreateDropdown(opts)
    opts = opts or {}
    local options = opts.Options or {}
    local multi   = opts.Multi == true
    local selected = {}     -- set of selected option -> true
    do
        local saved = self:_load(opts.Flag, opts.Default)
        if type(saved) == "table" then
            for _, v in ipairs(saved) do selected[v] = true end
        elseif saved ~= nil then selected[saved] = true end
    end

    local row, lbl = baseRow(self, opts.Name or "Dropdown", 50)
    lbl.Size = UDim2.new(0.35, 0, 1, 0)

    local box = Create("Frame", {
        Name = "DropdownSelectedFrame", BackgroundColor3 = Color3.fromRGB(13, 13, 13),
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0.975, 0, 0.5, 0),
        Size = UDim2.new(0, 150, 0, 26), Parent = row,
    })
    corner(6, box)
    stroke(Color3.fromRGB(40, 40, 40), 0.5, box)
    local picked = Create("TextLabel", {
        Name = "Picked", BackgroundTransparency = 1, Text = "...", FontFace = Fonts.Sans,
        TextSize = 15, TextColor3 = Color3.fromRGB(215, 215, 215), TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.new(1, -30, 1, 0), Parent = box,
    })
    local arrow = Create("ImageLabel", {
        Name = "Icon", BackgroundTransparency = 1, Image = Icons.DropArrow,
        ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0.6, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(15, 15), Parent = box,
    })
    local clickBtn = Create("TextButton", {
        BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 1, 0), ZIndex = 4, Parent = box,
    })

    local function pickedText()
        local list = {}
        for _, o in ipairs(options) do if selected[o] then table.insert(list, o) end end
        if #list == 0 then return "..." end
        return table.concat(list, ", ")
    end
    local function refresh(fire)
        picked.Text = pickedText()
        if opts.Flag then
            local list = {}
            for _, o in ipairs(options) do if selected[o] then table.insert(list, o) end end
            self:_store(opts.Flag, multi and list or list[1])
        end
        if fire and opts.Callback then
            local list = {}
            for _, o in ipairs(options) do if selected[o] then table.insert(list, o) end end
            task.spawn(opts.Callback, multi and list or list[1])
        end
    end

    -- panel (parented to gui so it floats above the window) -------------
    local panel = Create("Frame", {
        Name = "DropdownPanel", BackgroundColor3 = Theme.Popup, Visible = false,
        Size = UDim2.fromOffset(180, 0), ZIndex = 70, ClipsDescendants = true, Parent = self.Window.Gui,
    })
    corner(8, panel)
    stroke(Theme.PopupStroke, 1, panel)
    addShadow(panel, Color3.new(0, 0, 0), 0.4, 1.4)

    local searchHolder = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(24, 24, 24), Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 0, 26), ZIndex = 71, Parent = panel,
    })
    corner(6, searchHolder)
    pad(searchHolder, 8, 8, 0, 0)
    local searchInput = CustomInput.new(searchHolder, {
        Placeholder = "Search...", Font = Fonts.Sans, TextSize = 13,
        TextColor = Color3.fromRGB(200, 200, 200),
    })
    searchInput.Frame.ZIndex = 72

    local listFrame = Create("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 6, 0, 40),
        Size = UDim2.new(1, -12, 1, -46), ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60),
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 71, Parent = panel,
    })
    listLayout(listFrame, Enum.FillDirection.Vertical, 3)

    local optButtons = {}
    local closePanel   -- forward declaration
    local function repaint()
        for _, o in ipairs(options) do
            local b = optButtons[o]
            if b then
                local active = selected[o] == true
                Anim.to(b.btn, { BackgroundColor3 = active and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(20, 20, 20) }, Anim.Fast)
                Anim.to(b.lbl, { TextColor3 = active and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(140, 140, 140) }, Anim.Fast)
            end
        end
    end

    local function makeOptBtn(o)
        local b = Create("TextButton", {
            Name = o, BackgroundColor3 = Color3.fromRGB(20, 20, 20), AutoButtonColor = false,
            Text = "", Size = UDim2.new(1, 0, 0, 28), ZIndex = 71, Parent = listFrame,
        })
        corner(6, b)
        local tl = Create("TextLabel", {
            Name = "lbl", BackgroundTransparency = 1, Text = o, FontFace = Fonts.Sans, TextSize = 14,
            TextColor3 = Color3.fromRGB(140, 140, 140), TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -12, 1, 0), ZIndex = 72, Parent = b,
        })
        optButtons[o] = { btn = b, lbl = tl }
        b.MouseButton1Click:Connect(function()
            if multi then
                selected[o] = not selected[o] or nil
            else
                for k in pairs(selected) do selected[k] = nil end
                selected[o] = true
            end
            refresh(true); repaint()
            if not multi then closePanel() end
        end)
    end
    for _, o in ipairs(options) do makeOptBtn(o) end
    repaint()

    -- filter list on search
    searchInput.onChanged = function(q)
        q = string.lower(q or "")
        for _, o in ipairs(options) do
            local b = optButtons[o]
            if b then b.btn.Visible = (q == "" or string.find(string.lower(o), q, 1, true) ~= nil) end
        end
    end

    local isOpen = false
    function closePanel()
        if not isOpen then return end
        isOpen = false
        Anim.to(arrow, { Rotation = 0 }, Anim.Spring)
        Anim.to(panel, { Size = UDim2.new(0, panel.Size.X.Offset, 0, 0) }, Anim.Fast)
        task.delay(0.18, function() if not isOpen then panel.Visible = false end end)
    end
    local function openPanel()
        if isOpen then return end
        isOpen = true
        self.Window:CloseAllPopups()
        local ap, sz = box.AbsolutePosition, box.AbsoluteSize
        panel.Position = UDim2.fromOffset(ap.X + sz.X - 180, ap.Y + sz.Y + 6)
        panel.Visible = true
        panel.Size = UDim2.fromOffset(180, 0)
        Anim.to(panel, { Size = UDim2.fromOffset(180, math.min(220, 46 + #options * 31)) }, Anim.Spring)
        Anim.to(arrow, { Rotation = 180 }, Anim.Spring)
        table.insert(self.Window.OpenPopups, { frame = panel, owner = box, close = closePanel })
    end
    clickBtn.MouseButton1Click:Connect(function()
        if isOpen then closePanel() else openPanel() end
    end)

    refresh(false)
    task.defer(function() refresh(false) end)

    local api = { Instance = row }
    function api:Set(v)
        for k in pairs(selected) do selected[k] = nil end
        if type(v) == "table" then for _, x in ipairs(v) do selected[x] = true end
        elseif v ~= nil then selected[v] = true end
        refresh(true); repaint()
    end
    function api:Get()
        local list = {}
        for _, o in ipairs(options) do if selected[o] then table.insert(list, o) end end
        return multi and list or list[1]
    end
    self:_register(opts.Name or "Dropdown", row, api)
    return api
end

--============================================================================--
--  GLOBAL SEARCH  (expands under the search box)
--============================================================================--
function Window:_BuildSearch()
    local holder = Create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 34, 0, 0),
        Size = UDim2.new(1, -70, 1, 0), Parent = self.SearchBg,
    })
    local input = CustomInput.new(holder, {
        Placeholder = "search", Font = Fonts.Sans, TextSize = 14,
        TextColor = Color3.fromRGB(200, 200, 200), PlaceholderColor = Theme.Placeholder,
    })

    -- results panel under the search bar
    local panel = Create("Frame", {
        Name = "SearchResults", BackgroundColor3 = Theme.Popup, Visible = false,
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 8),
        Size = UDim2.new(1, 0, 0, 0), ZIndex = 80, ClipsDescendants = true, Parent = self.SearchBg,
    })
    corner(8, panel)
    stroke(Theme.PopupStroke, 1, panel)
    addShadow(panel, Color3.new(0, 0, 0), 0.4, 1.3)
    local list = Create("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 6, 0, 6),
        Size = UDim2.new(1, -12, 1, -12), ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60),
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 81, Parent = panel,
    })
    listLayout(list, Enum.FillDirection.Vertical, 4)

    local function clearList()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
    end
    local function jumpTo(entry)
        self:SelectTab(entry.tabObj)
        if entry.sectionObj and not entry.sectionObj.Open then entry.sectionObj.SetOpen(true) end
        task.wait(0.05)
        -- scroll & flash
        local page = entry.tabObj.Page
        if entry.frame and entry.frame.Parent then
            local hl = Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0), ZIndex = 20, Parent = entry.frame,
            })
            corner(6, hl)
            Anim.to(hl, { BackgroundTransparency = 0.9 }, Anim.Fast)
            task.delay(0.5, function()
                Anim.to(hl, { BackgroundTransparency = 1 }, Anim.Spring)
                task.delay(0.4, function() hl:Destroy() end)
            end)
        end
    end
    local function rebuild(q)
        clearList()
        q = string.lower(q or "")
        local shown = 0
        for _, entry in ipairs(self.SearchIndex) do
            if q ~= "" and (string.find(string.lower(entry.name), q, 1, true)
                or string.find(string.lower(entry.section), q, 1, true)) then
                shown = shown + 1
                local b = Create("TextButton", {
                    BackgroundColor3 = Color3.fromRGB(22, 22, 22), AutoButtonColor = false, Text = "",
                    Size = UDim2.new(1, 0, 0, 40), ZIndex = 81, Parent = list,
                })
                corner(6, b)
                Create("TextLabel", {
                    BackgroundTransparency = 1, Text = entry.name, FontFace = Fonts.Sans, TextSize = 15,
                    TextColor3 = Color3.fromRGB(215, 215, 215), TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -12, 0, 18), ZIndex = 82, Parent = b,
                })
                Create("TextLabel", {
                    BackgroundTransparency = 1, Text = entry.section .. "  \u{2022}  " .. entry.tab,
                    FontFace = Fonts.SerifItalic, TextSize = 12, TextColor3 = Color3.fromRGB(120, 120, 120),
                    TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 10, 0, 20),
                    Size = UDim2.new(1, -12, 0, 16), ZIndex = 82, Parent = b,
                })
                b.MouseButton1Click:Connect(function() jumpTo(entry) end)
            end
        end
        if q == "" or shown == 0 then
            panel.Visible = (q ~= "")
            Anim.to(panel, { Size = UDim2.new(1, 0, 0, q == "" and 0 or 44) }, Anim.Fast)
            if q ~= "" and shown == 0 then
                local b = Create("TextButton", {
                    BackgroundTransparency = 1, Text = "no results", FontFace = Fonts.SerifItalic,
                    TextSize = 14, TextColor3 = Color3.fromRGB(110, 110, 110),
                    Size = UDim2.new(1, 0, 0, 32), ZIndex = 81, Parent = list,
                })
            end
            if q == "" then task.delay(0.16, function() if input:GetText() == "" then panel.Visible = false end end) end
        else
            panel.Visible = true
            Anim.to(panel, { Size = UDim2.new(1, 0, 0, math.min(260, 12 + shown * 44)) }, Anim.Spring)
        end
    end
    input.onChanged = function(q) rebuild(q) end

    -- clicking a search result set is handled above; close on outside handled globally
    input.Capture.FocusLost:Connect(function()
        task.delay(0.15, function()
            if input:GetText() == "" then
                Anim.to(panel, { Size = UDim2.new(1, 0, 0, 0) }, Anim.Fast)
                task.delay(0.16, function() panel.Visible = false end)
            end
        end)
    end)
end

--============================================================================--
--  PUBLIC HELPERS + RETURN
--============================================================================--
function Window:Notify(opts)
    -- lightweight toast in the amphibia style
    opts = opts or {}
    local toast = Create("Frame", {
        BackgroundColor3 = Theme.Section, AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, 60), Size = UDim2.fromOffset(280, 64), ZIndex = 90, Parent = self.Gui,
    })
    corner(8, toast)
    stroke(Theme.SectionStroke, 0.5, toast)
    addShadow(toast, Color3.new(0, 0, 0), 0.4, 1.3)
    Create("TextLabel", {
        BackgroundTransparency = 1, Text = opts.Title or "Notification", FontFace = Fonts.SerifBold,
        TextSize = 17, TextColor3 = Theme.SectionName, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 14, 0, 10), Size = UDim2.new(1, -20, 0, 20), ZIndex = 91, Parent = toast,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1, Text = opts.Content or "", FontFace = Fonts.Sans, TextSize = 14,
        TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
        Position = UDim2.new(0, 14, 0, 32), Size = UDim2.new(1, -24, 0, 24), ZIndex = 91, Parent = toast,
    })
    Anim.to(toast, { Position = UDim2.new(1, -20, 1, -80) }, Anim.Spring)
    task.delay(opts.Duration or 3.5, function()
        Anim.to(toast, { Position = UDim2.new(1, -20, 1, 80) }, Anim.Spring)
        task.delay(0.4, function() toast:Destroy() end)
    end)
end

function Window:Destroy()
    if self.Gui then self.Gui:Destroy() end
end

Amphibia.Fonts  = Fonts
Amphibia.Theme  = Theme
Amphibia.Icons  = Icons

return Amphibia
