--[[


		 ▄▄▄          ███▄ ▄███▓    ██▓███      ██░ ██     ██▓    ▄▄▄▄       ██▓    ▄▄▄         
		▒████▄       ▓██▒▀█▀ ██▒   ▓██░  ██▒   ▓██░ ██▒   ▓██▒   ▓█████▄    ▓██▒   ▒████▄       
		▒██  ▀█▄     ▓██    ▓██░   ▓██░ ██▓▒   ▒██▀▀██░   ▒██▒   ▒██▒ ▄██   ▒██▒   ▒██  ▀█▄     
		░██▄▄▄▄██    ▒██    ▒██    ▒██▄█▓▒ ▒   ░▓█ ░██    ░██░   ▒██░█▀     ░██░   ░██▄▄▄▄██    
		 ▓█   ▓██▒   ▒██▒   ░██▒   ▒██▒ ░  ░   ░▓█▒░██▓   ░██░   ░▓█  ▀█▓   ░██░    ▓█   ▓██▒   
		 ▒▒   ▓▒█░   ░ ▒░   ░  ░   ▒▓▒░ ░  ░    ▒ ░░▒░▒   ░▓     ░▒▓███▀▒   ░▓      ▒▒   ▓▒█░   
		  ▒   ▒▒ ░   ░  ░      ░   ░▒ ░         ▒ ░▒░ ░    ▒ ░   ▒░▒   ░     ▒ ░     ▒   ▒▒ ░   
		  ░   ▒      ░      ░      ░░           ░  ░░ ░    ▒ ░    ░    ░     ▒ ░     ░   ▒      
		      ░  ░          ░                   ░  ░  ░    ░      ░          ░           ░  ░   
		                                                               ░                        

	Amphibia User Interface Library
	by Less

	Quick start:

		local Amphibia = loadstring(readfile("Amphibia.lua"))()

		local Window = Amphibia:CreateWindow({
			Name = "amphibia",
			Version = "v0.1337",
			ToggleUIKeybind = "K",

			KeySystem = true,
			KeySettings = {
				Title = "Welcome to amphibia.",
				Subtitle = "Enter your key to get started.",
				Key = {"devaccess1337"},
				SaveKey = true,
				Discord = "https://discord.gg/yourserver",
				Website = "https://your.site",
				Youtube = "https://youtube.com/@you",
			},

			ConfigurationSaving = {
				Enabled = true,
				FolderName = "Amphibia",
				FileName = "Default",
			},

			Theme = "Default", -- "Default" | "Midnight" | "Sakura" | "Emerald"
		})

		local Tab = Window:CreateTab({ Name = "Player", Category = "Main" })
		local Section = Tab:CreateSection({ Name = "Toggles", Side = "Left" })

		Section:CreateToggle({ Name = "Toggle", CurrentValue = true, Flag = "MyToggle", Callback = function(v) end })

		Window:CreateConfigTab({ Category = "Menu" })

]]

if debugX then
	warn("[ Amphibia DebugX ] Initialising Amphibia.")
end

local function getService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end

------------------------------------------------------------------------------------------------------------------------
--  Services
------------------------------------------------------------------------------------------------------------------------

local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local TextService = getService("TextService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")
local HttpService = getService("HttpService")
local RunService = getService("RunService")
local GuiService = getService("GuiService")
local ContextActionService = getService("ContextActionService")

local LocalPlayer = Players.LocalPlayer

local function loadWithTimeout(url: string, timeout: number?): ...any
	assert(type(url) == "string", "Expected string, got " .. type(url))
	timeout = timeout or 5
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url)

		if not fetchSuccess or type(fetchResult) ~= "string" or #fetchResult == 0 then
			if type(fetchResult) ~= "string" or #fetchResult == 0 then
				fetchResult = "Empty response"
			end
			success, result = false, fetchResult
			requestCompleted = true
			return
		end
		local content = fetchResult
		local execSuccess, execResult = pcall(function()
			return loadstring(content)()
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	local timeoutThread = task.delay(timeout, function()
		if not requestCompleted then
			warn("Request for " .. url .. " timed out after " .. tostring(timeout) .. " seconds")
			task.cancel(requestThread)
			result = "Request timed out"
			requestCompleted = true
		end
	end)

	while not requestCompleted do
		task.wait()
	end

	if coroutine.status(timeoutThread) ~= "dead" then
		task.cancel(timeoutThread)
	end

	if not success then
		warn("Failed to process " .. tostring(url) .. ": " .. tostring(result))
	end

	return if success then result else nil
end

local requestsDisabled = false
local customAssetId = nil
local secureMode = false

if getgenv then
	local ok, result = pcall(function() return getgenv().DISABLE_AMPHIBIA_REQUESTS end)
	if ok and result then requestsDisabled = true end

	local ok2, result2 = pcall(function() return getgenv().AMPHIBIA_ASSET_ID end)
	if ok2 and type(result2) == "number" then customAssetId = result2 end

	local ok3, result3 = pcall(function() return getgenv().AMPHIBIA_SECURE end)
	if ok3 and result3 then secureMode = true end
end

if secureMode then
	local _error = error
	local _assert = assert
	warn = function(...) end
	print = function(...) end
	error = function(_, level) _error("", level) end
	assert = function(v, ...) return _assert(v) end
end

local InterfaceBuild = "AA1AA"
local Release = "Build 0.91"
local AmphibiaFolder = "Amphibia"
local ConfigurationFolder = AmphibiaFolder .. "/Configs"
local ConfigurationExtension = ".amph"
local KeyFile = AmphibiaFolder .. "/key" .. ConfigurationExtension
local SettingsFile = AmphibiaFolder .. "/settings" .. ConfigurationExtension

local settingsTable = {
	General = {
		amphibiaOpen = { Type = "bind", Value = "K", Name = "Amphibia Keybind" },
		theme = { Type = "input", Value = "Default", Name = "Theme" },
		lastConfig = { Type = "input", Value = "", Name = "Last loaded config" },
	},
	System = {
		usageAnalytics = { Type = "toggle", Value = true, Name = "Anonymised Analytics" },
	},
}

local overriddenSettings: { [string]: any } = {}
local function overrideSetting(category: string, name: string, value: any)
	overriddenSettings[category .. "." .. name] = value
end

local function getSetting(category: string, name: string): any
	if overriddenSettings[category .. "." .. name] ~= nil then
		return overriddenSettings[category .. "." .. name]
	elseif settingsTable[category] and settingsTable[category][name] ~= nil then
		return settingsTable[category][name].Value
	end
end

if requestsDisabled then
	overrideSetting("System", "usageAnalytics", false)
end

local useStudio = RunService:IsStudio() or false

------------------------------------------------------------------------------------------------------------------------
--  Executor file API (with in-memory fallback so everything still works in Studio / limited executors)
------------------------------------------------------------------------------------------------------------------------

local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request

local function callSafely(func, ...)
	if func then
		local success, result = pcall(func, ...)
		if not success then
			warn("[ Amphibia Interface ] Function failed with error: ", result)
			return nil
		else
			return result
		end
	end
	return nil
end

local VirtualFS = { files = {}, folders = {} } -- fallback storage

local FS = {}

FS.available = (typeof(writefile) == "function" and typeof(readfile) == "function")

function FS.isfolder(path)
	if FS.available and typeof(isfolder) == "function" then
		local ok, res = pcall(isfolder, path)
		if ok then return res end
	end
	return VirtualFS.folders[path] == true
end

function FS.makefolder(path)
	if FS.available and typeof(makefolder) == "function" then
		local ok = pcall(makefolder, path)
		if ok then return end
	end
	VirtualFS.folders[path] = true
end

function FS.isfile(path)
	if FS.available and typeof(isfile) == "function" then
		local ok, res = pcall(isfile, path)
		if ok then return res end
	end
	return VirtualFS.files[path] ~= nil
end

function FS.read(path)
	if FS.available then
		local ok, res = pcall(readfile, path)
		if ok then return res end
	end
	return VirtualFS.files[path]
end

function FS.write(path, content)
	if FS.available then
		local ok = pcall(writefile, path, content)
		if ok then return true end
	end
	VirtualFS.files[path] = content
	return true
end

function FS.delete(path)
	if FS.available and typeof(delfile) == "function" then
		local ok = pcall(delfile, path)
		if ok then return true end
	end
	VirtualFS.files[path] = nil
	return true
end

function FS.list(folder)
	if FS.available and typeof(listfiles) == "function" then
		local ok, res = pcall(listfiles, folder)
		if ok and type(res) == "table" then return res end
	end
	local out = {}
	for path in pairs(VirtualFS.files) do
		if path:sub(1, #folder + 1) == folder .. "/" then
			table.insert(out, path)
		end
	end
	return out
end

local function ensureFolder(folderPath)
	if not FS.isfolder(folderPath) then
		FS.makefolder(folderPath)
	end
end

ensureFolder(AmphibiaFolder)
ensureFolder(ConfigurationFolder)

local function setClipboard(text)
	local fn = setclipboard or toclipboard or (syn and syn.write_clipboard)
	if fn then
		return pcall(fn, text) == true
	end
	return false
end

------------------------------------------------------------------------------------------------------------------------
--  Settings persistence
------------------------------------------------------------------------------------------------------------------------

local function saveSettings()
	local encoded = {}
	for categoryName, categoryTable in pairs(settingsTable) do
		encoded[categoryName] = {}
		for settingName, setting in pairs(categoryTable) do
			encoded[categoryName][settingName] = { Value = setting.Value }
		end
	end
	local ok, json = pcall(function() return HttpService:JSONEncode(encoded) end)
	if ok then
		FS.write(SettingsFile, json)
	end
end

local function loadSettings()
	local file = nil
	if FS.isfile(SettingsFile) then
		file = FS.read(SettingsFile)
	end
	if file then
		local decodeSuccess, decodedFile = pcall(function() return HttpService:JSONDecode(file) end)
		if decodeSuccess and type(decodedFile) == "table" then
			for categoryName, categoryTable in pairs(decodedFile) do
				if settingsTable[categoryName] then
					for settingName, setting in pairs(categoryTable) do
						local def = settingsTable[categoryName][settingName]
						if def and type(setting) == "table" and typeof(def.Value) == typeof(setting.Value) then
							def.Value = setting.Value
						end
					end
				end
			end
		end
	end
end

loadSettings()

if debugX then
	warn("[ Amphibia DebugX ] Settings loaded.")
end
------------------------------------------------------------------------------------------------------------------------
--  Library table
------------------------------------------------------------------------------------------------------------------------

local AmphibiaLibrary = {
	Flags = {},
	Elements = {}, -- Flag -> element object
	Version = Release,
	Build = InterfaceBuild,

	-- Reference palette (Default). Kept for direct access / backwards compatibility.
	Theme = {
		Default = {
			White = Color3.fromRGB(255, 255, 255),
			Black = Color3.fromRGB(0, 0, 0),
			Accent = Color3.fromRGB(143, 168, 160),

			MainBackground = Color3.fromRGB(13, 13, 14),
			MainBackgroundSplitter = Color3.fromRGB(34, 34, 34),

			SectionBackground = Color3.fromRGB(27, 27, 27),
			SectionBackgroundStroke = Color3.fromRGB(60, 60, 60),
			SectionName = Color3.fromRGB(216, 216, 216),

			EnabledToggleFrame = Color3.fromRGB(48, 48, 48),
			EnabledToggleFrameStroke = Color3.fromRGB(175, 175, 175),
			EnabledToggleFrameKnob = Color3.fromRGB(255, 255, 255),
			EnabledToggleValueText = Color3.fromRGB(150, 150, 150),
			DisabledToggleFrame = Color3.fromRGB(33, 33, 33),
			DisabledToggleFrameStroke = Color3.fromRGB(75, 75, 75),
			DisabledToggleFrameKnob = Color3.fromRGB(105, 105, 105),
			DisabledToggleValueText = Color3.fromRGB(102, 102, 102),

			NotificationDot_Red = Color3.fromRGB(224, 122, 114),
			NotificationDot_Green = Color3.fromRGB(143, 179, 139),
			NotificationDot_Yellow = Color3.fromRGB(179, 177, 105),
		},
	},
}

------------------------------------------------------------------------------------------------------------------------
--  Theme engine
--  The interface is authored in a neutral graphite palette; themes re-map every colour live through a palette
--  transform, so both static UI and animated targets always agree with the current theme.
------------------------------------------------------------------------------------------------------------------------

local Themes = {
	Default = {
		Hue = 0, GraySat = 0, ValueGain = 0,
		Accent = Color3.fromRGB(143, 168, 160),
	},
	Midnight = {
		Hue = 228 / 360, GraySat = 0.22, ValueGain = 0.015,
		Accent = Color3.fromRGB(126, 150, 210),
	},
	Sakura = {
		Hue = 341 / 360, GraySat = 0.15, ValueGain = 0.02,
		Accent = Color3.fromRGB(214, 143, 166),
	},
	Emerald = {
		Hue = 152 / 360, GraySat = 0.16, ValueGain = 0.01,
		Accent = Color3.fromRGB(126, 190, 160),
	},
	Ocean = {
		Hue = 197 / 360, GraySat = 0.20, ValueGain = 0.012,
		Accent = Color3.fromRGB(112, 178, 204),
	},
	Amethyst = {
		Hue = 268 / 360, GraySat = 0.17, ValueGain = 0.015,
		Accent = Color3.fromRGB(168, 140, 210),
	},
	Ember = {
		Hue = 18 / 360, GraySat = 0.15, ValueGain = 0.012,
		Accent = Color3.fromRGB(214, 150, 118),
	},
	Arctic = {
		Hue = 208 / 360, GraySat = 0.08, ValueGain = 0.035,
		Accent = Color3.fromRGB(150, 185, 214),
	},
	Mocha = {
		Hue = 32 / 360, GraySat = 0.13, ValueGain = 0.008,
		Accent = Color3.fromRGB(196, 168, 130),
	},
}

local CurrentThemeName = "Default"

local BASE_ACCENT = Color3.fromRGB(143, 168, 160)

local function colorsClose(a: Color3, b: Color3, tolerance: number?)
	tolerance = tolerance or 0.02
	return math.abs(a.R - b.R) < tolerance and math.abs(a.G - b.G) < tolerance and math.abs(a.B - b.B) < tolerance
end

-- Maps an authored (Default-palette) colour into the active theme.
local function TC(color: Color3): Color3
	local theme = Themes[CurrentThemeName]
	if not theme or CurrentThemeName == "Default" then
		return color
	end
	if colorsClose(color, BASE_ACCENT, 0.06) then
		return theme.Accent
	end
	local h, s, v = color:ToHSV()
	if s < 0.09 then -- graphite / white ramp -> tint it
		local sat = theme.GraySat * (1 - 0.72 * v)
		local val = math.clamp(v + theme.ValueGain * (1 - v), 0, 1)
		return Color3.fromHSV(theme.Hue, sat, val)
	end
	return color -- keep semantic colours (danger reds, hue slider, etc)
end

-- Snapshot of original (authored) colours, per instance. Weak keys so destroyed instances free themselves.
local ThemeRegistry = {}

local COLOR_PROPS = {
	Frame = { "BackgroundColor3" },
	ScrollingFrame = { "BackgroundColor3", "ScrollBarImageColor3" },
	TextLabel = { "BackgroundColor3", "TextColor3" },
	TextButton = { "BackgroundColor3", "TextColor3" },
	TextBox = { "BackgroundColor3", "TextColor3", "PlaceholderColor3" },
	ImageLabel = { "BackgroundColor3", "ImageColor3" },
	ImageButton = { "BackgroundColor3", "ImageColor3" },
	UIStroke = { "Color" },
	UIShadow = { "Color" },
}

local function themeRegister(inst: Instance)
	local props = COLOR_PROPS[inst.ClassName]
	if not props then
		return
	end
	local snapshot = ThemeRegistry[inst]
	if not snapshot then
		snapshot = {}
		ThemeRegistry[inst] = snapshot
	end
	for _, prop in ipairs(props) do
		if snapshot[prop] == nil then
			local ok, value = pcall(function() return inst[prop] end)
			if ok and typeof(value) == "Color3" then
				snapshot[prop] = value
			end
		end
	end
end

local function themeRegisterDeep(inst: Instance)
	themeRegister(inst)
	for _, descendant in ipairs(inst:GetDescendants()) do
		themeRegister(descendant)
	end
end

local function themeApply(inst: Instance)
	local snapshot = ThemeRegistry[inst]
	if not snapshot then
		return
	end
	for prop, original in pairs(snapshot) do
		pcall(function() inst[prop] = TC(original) end)
	end
end

local function themeApplyDeep(inst: Instance)
	themeApply(inst)
	for _, descendant in ipairs(inst:GetDescendants()) do
		themeApply(descendant)
	end
end

------------------------------------------------------------------------------------------------------------------------
--  Tween / misc helpers
------------------------------------------------------------------------------------------------------------------------

local EASE = {
	Out = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Slow = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Back = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Smooth = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
}

local function tween(object: Instance, info, goal)
	if typeof(info) == "number" then
		info = TweenInfo.new(info, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	elseif typeof(info) == "string" then
		info = EASE[info] or EASE.Out
	end
	local t = TweenService:Create(object, info, goal)
	t:Play()
	return t
end

local function round(value: number, factor: number?): number
	if not factor or factor == 0 then
		return math.floor(value + 0.5)
	end
	local rounded = math.floor(value / factor + 0.5) * factor
	-- clean float dust for readable labels
	local decimals = math.max(0, math.ceil(-math.log10(factor) - 1e-9))
	local mult = 10 ^ decimals
	return math.floor(rounded * mult + 0.5) / mult
end

local Connections = {}
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Connections, c)
	return c
end

local KEY_SHORT_NAMES = {
	LeftControl = "Ctrl", RightControl = "RCtrl", LeftShift = "Shift", RightShift = "RShift",
	LeftAlt = "Alt", RightAlt = "RAlt", CapsLock = "Caps", Backspace = "Bksp", Return = "Enter",
	Escape = "Esc", PageUp = "PgUp", PageDown = "PgDn", Insert = "Ins", Delete = "Del",
	MouseButton1 = "Lmb", MouseButton2 = "Rmb", MouseButton3 = "Mmb",
	KeypadZero = "Num0", KeypadOne = "Num1", KeypadTwo = "Num2", KeypadThree = "Num3", KeypadFour = "Num4",
	KeypadFive = "Num5", KeypadSix = "Num6", KeypadSeven = "Num7", KeypadEight = "Num8", KeypadNine = "Num9",
	Zero = "0", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
	Space = "Space", Tab = "Tab", Semicolon = ";", Quote = "'", Comma = ",", Period = ".", Slash = "/",
	Minus = "-", Equals = "=", LeftBracket = "[", RightBracket = "]", BackSlash = "\\",
}

local function keyDisplayName(keyName: string): string
	return KEY_SHORT_NAMES[keyName] or keyName
end

------------------------------------------------------------------------------------------------------------------------
--  GUI construction (design compiled from amphibia_design.rbxmx)
------------------------------------------------------------------------------------------------------------------------

local FONT_WEIGHTS = {
	[100] = Enum.FontWeight.Thin, [200] = Enum.FontWeight.ExtraLight, [300] = Enum.FontWeight.Light,
	[400] = Enum.FontWeight.Regular, [500] = Enum.FontWeight.Medium, [600] = Enum.FontWeight.SemiBold,
	[700] = Enum.FontWeight.Bold, [800] = Enum.FontWeight.ExtraBold, [900] = Enum.FontWeight.Heavy,
}

local FontCache = {}

local function c3(r, g, b) return Color3.fromRGB(r, g, b) end
local function u2(a, b, c, d) return UDim2.new(a, b, c, d) end
local function ud(s, o) return UDim.new(s, o) end
local function v2(x, y) return Vector2.new(x, y) end
local function ft(family, weight, style)
	local key = family .. weight .. style
	local cached = FontCache[key]
	if cached then
		return cached
	end
	local ok, font = pcall(function()
		return Font.new(family, FONT_WEIGHTS[weight] or Enum.FontWeight.Regular,
			style == "Italic" and Enum.FontStyle.Italic or Enum.FontStyle.Normal)
	end)
	if not ok then
		font = Font.fromEnum(Enum.Font.Gotham)
	end
	FontCache[key] = font
	return font
end

-- Serif family used across the design (headers / logo) and the body family — exposed for
-- programmatically-built pieces (keybind chips, smooth inputs, etc).
local FONT_SERIF = ft("rbxassetid://12187368093", 400, "Normal")
local FONT_SERIF_BOLD = ft("rbxassetid://12187368093", 700, "Normal")
local FONT_SERIF_ITALIC = ft("rbxassetid://12187368093", 400, "Italic")
local FONT_BODY = ft("rbxassetid://12187365364", 400, "Normal")
local FONT_MONO = ft("rbxasset://fonts/families/RobotoMono.json", 400, "Normal")

local UIShadowSupported = (function()
	local ok, inst = pcall(Instance.new, "UIShadow")
	if ok and inst then
		inst:Destroy()
		return true
	end
	return false
end)()

local function buildNode(node, parent: Instance?): Instance?
	local className, props, children = node[1], node[2], node[3]
	if className == "UIShadow" and not UIShadowSupported then
		return nil
	end
	local ok, inst = pcall(Instance.new, className)
	if not ok or not inst then
		return nil
	end
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
	end
	for prop, value in pairs(props) do
		pcall(function() inst[prop] = value end)
	end
	if children then
		for _, childNode in ipairs(children) do
			buildNode(childNode, inst)
		end
	end
	themeRegister(inst)
	inst.Parent = parent
	return inst
end
------------------------------------------------------------------------------------------------------------------------
--  SmoothInput — Amphibia's custom animated textbox
--
--  Every keystroke renders as its own label that fades and rises into place, the caret is a real element
--  that glides between characters, and pasted text diffs cleanly. A hidden TextBox does the actual text
--  editing (so IME / paste / arrows keep working), while we own the presentation completely.
------------------------------------------------------------------------------------------------------------------------

local ActiveInput = nil

local INPUT_SINK_ACTION = "AmphibiaInputSink"
local SINK_KEYS = {}
do
	for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
		local value = item.Value
		if (value >= 97 and value <= 122)        -- a-z
			or (value >= 48 and value <= 57)     -- 0-9
			or (value >= 256 and value <= 265)   -- numpad 0-9
		then
			table.insert(SINK_KEYS, item)
		end
	end
end

local function beginInputSink()
	pcall(function()
		ContextActionService:BindActionAtPriority(
			INPUT_SINK_ACTION,
			function() return Enum.ContextActionResult.Sink end,
			false,
			Enum.ContextActionPriority.High.Value + 100,
			table.unpack(SINK_KEYS)
		)
	end)
end

local function endInputSink()
	pcall(function() ContextActionService:UnbindAction(INPUT_SINK_ACTION) end)
end

local SmoothInput
;(function()
SmoothInput = {}
SmoothInput.__index = SmoothInput

local CHAR_IN = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CHAR_OUT = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CHAR_FLOW = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CARET_MOVE = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function toChars(text: string): { string }
	local chars = {}
	for _, code in utf8.codes(text) do
		table.insert(chars, utf8.char(code))
	end
	return chars
end

local WidthCache = {}

function SmoothInput:_charWidth(char: string): number
	local key = tostring(self.Font) .. "|" .. tostring(self.TextSize) .. "|" .. char
	local cached = WidthCache[key]
	if cached then
		return cached
	end
	local width
	local ok, bounds = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = char
		params.Font = self.Font
		params.Size = self.TextSize
		return TextService:GetTextBoundsAsync(params)
	end)
	if ok and bounds and bounds.X > 0 then
		width = bounds.X
	else
		self.Measure.Text = char          -- запасной путь
		width = self.Measure.TextBounds.X
	end
	WidthCache[key] = width
	return width
end

function SmoothInput:_updatePlaceholder(instant: boolean?)
	local visible = self.Text == ""
	self.Placeholder.Visible = visible
	local target = 1
	if visible then
		target = self.Focused and 0.62 or (self.Options.PlaceholderTransparency or 0.35)
	end
	if instant then
		self.Placeholder.TextTransparency = target
	else
		tween(self.Placeholder, CHAR_IN, { TextTransparency = target })
	end
end

function SmoothInput.new(options)
	local self = setmetatable({}, SmoothInput)

	self.Options = options
	self.Text = ""
	self.Chars = {} -- array of { Char = string, Label = TextLabel }
	self.Widths = {} -- cumulative pixel width up to index i
	self.Offset = 0
	self.Focused = false
	self.Suppressed = false
	self.InstantNext = false
	self.Destroyed = false
	self.BlinkClock = 0
	self.LastInsideClick = 0

	local parent = options.Parent
	local font = options.Font or FONT_BODY
	local textSize = options.TextSize or 14
	local textColor = options.TextColor or Color3.fromRGB(190, 190, 190)
	local caretColor = options.CaretColor or textColor
	local padL = options.PaddingLeft or 0
	local padR = options.PaddingRight or 0

	self.Font = font
	self.TextSize = textSize
	self.TextColor = textColor
	self.PadL = padL
	self.PadR = padR

	local root = Instance.new("Frame")
	root.Name = "SmoothInput"
	root.BackgroundTransparency = 1
	root.Size = UDim2.new(1, 0, 1, 0)
	root.ClipsDescendants = true
	root.ZIndex = (options.ZIndex or 5)
	root.Parent = parent
	self.Root = root

	local charsHolder = Instance.new("Frame")
	charsHolder.Name = "Chars"
	charsHolder.BackgroundTransparency = 1
	charsHolder.Size = UDim2.new(1, 0, 1, 0)
	charsHolder.Position = UDim2.new(0, padL, 0, 0)
	charsHolder.ZIndex = root.ZIndex
	charsHolder.Parent = root
	self.CharsHolder = charsHolder

	local placeholder = Instance.new("TextLabel")
	placeholder.Name = "Placeholder"
	placeholder.BackgroundTransparency = 1
	placeholder.Size = UDim2.new(1, -padL - padR, 1, 0)
	placeholder.Position = UDim2.new(0, padL, 0, 0)
	placeholder.FontFace = font
	placeholder.TextSize = textSize
	placeholder.TextColor3 = options.PlaceholderColor or textColor
	placeholder.TextTransparency = options.PlaceholderTransparency or 0.35
	placeholder.Text = options.PlaceholderText or ""
	placeholder.TextXAlignment = Enum.TextXAlignment.Left
	placeholder.TextYAlignment = Enum.TextYAlignment.Center
	placeholder.ZIndex = root.ZIndex
	placeholder.Parent = root
	themeRegister(placeholder)
	self.Placeholder = placeholder

	local caret = Instance.new("Frame")
	caret.Name = "Caret"
	caret.AnchorPoint = Vector2.new(0, 0.5)
	caret.BackgroundColor3 = caretColor
	caret.BackgroundTransparency = 1
	caret.Size = UDim2.new(0, 1, 0, textSize + 3)
	caret.Position = UDim2.new(0, padL, 0.5, 0)
	caret.ZIndex = root.ZIndex + 2
	caret.Parent = root
	themeRegister(caret)
	self.Caret = caret

	local selection = Instance.new("Frame")
	selection.Name = "Selection"
	selection.AnchorPoint = Vector2.new(0, 0.5)
	selection.BackgroundColor3 = caretColor
	selection.BackgroundTransparency = 0.84
	selection.Size = UDim2.new(0, 0, 0, textSize + 5)
	selection.Position = UDim2.new(0, padL, 0.5, 0)
	selection.Visible = false
	selection.ZIndex = root.ZIndex
	selection.Parent = root
	themeRegister(selection)
	self.SelectionFrame = selection

	local capture = Instance.new("TextBox")
	capture.Name = "Capture"
	capture.BackgroundTransparency = 1
	-- keep the invisible native text metrically identical to our rendered chars, so native
	-- click-to-place / drag-select / word-select map exactly onto the visual glyphs
	capture.Position = UDim2.new(0, padL, 0, 0)
	capture.Size = UDim2.new(1, -padL - padR, 1, 0)
	capture.Text = ""
	capture.TextTransparency = 1
	capture.FontFace = font
	capture.TextSize = math.max(1, textSize)
	capture.TextXAlignment = Enum.TextXAlignment.Left
	capture.TextYAlignment = Enum.TextYAlignment.Center
	capture.TextStrokeTransparency = 1
	capture.ClearTextOnFocus = false
	capture.MultiLine = false
	capture.ZIndex = root.ZIndex + 3
	capture.Parent = root
	self.Capture = capture

	local function markInside(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1
			or inputObject.UserInputType == Enum.UserInputType.MouseButton2
			or inputObject.UserInputType == Enum.UserInputType.Touch then
			self.LastInsideClick = os.clock()
		end
	end
	root.InputBegan:Connect(markInside)
	capture.InputBegan:Connect(markInside)

	local measure = Instance.new("TextLabel")
	measure.Name = "Measure"
	measure.BackgroundTransparency = 1
	measure.TextTransparency = 1
	measure.Size = UDim2.new(0, 4000, 0, textSize + 6)
	measure.Position = UDim2.new(0, 0, 0, -1000)
	measure.FontFace = font
	measure.TextSize = textSize
	measure.TextXAlignment = Enum.TextXAlignment.Left
	measure.Text = ""
	measure.Parent = root
	self.Measure = measure

	-- events ------------------------------------------------------------------------------------------------------

	capture:GetPropertyChangedSignal("Text"):Connect(function()
		if self.Suppressed or self.Destroyed then
			return
		end
		self:_onTextChanged(capture.Text)
	end)

	capture:GetPropertyChangedSignal("CursorPosition"):Connect(function()
		if self.Destroyed then return end
		self:_updateCaret(true)
	end)

	pcall(function()
		capture:GetPropertyChangedSignal("SelectionStart"):Connect(function()
			if self.Destroyed then return end
			self:_updateCaret(false)
		end)
	end)

	-- single click = native caret placement, double = select word, triple = select all
	local clickCount, lastClickAt = 0, 0
	capture.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local now = os.clock()
		clickCount = (now - lastClickAt < 0.34) and clickCount + 1 or 1
		lastClickAt = now
		if clickCount == 2 then
			task.defer(function()
				if not self.Destroyed then self:SelectWordAtCursor() end
			end)
		elseif clickCount >= 3 then
			clickCount = 0
			task.defer(function()
				if not self.Destroyed then self:SelectAll() end
			end)
		end
	end)

	capture.Focused:Connect(function()
		if self.Destroyed then return end
		ActiveInput = self
		-- capture.Focused
		ActiveInput = self
		beginInputSink()

		-- capture.FocusLost
		if ActiveInput == self then ActiveInput = nil end
		endInputSink()
		self.Focused = true
		self.BlinkClock = 0
		self:_updatePlaceholder()
		if options.OnFocus then
			task.spawn(options.OnFocus)
		end
		self:_updateCaret(false)
	end)

	capture.FocusLost:Connect(function(enterPressed)
		if self.Destroyed then return end
		if ActiveInput == self then ActiveInput = nil end
		self.Focused = false
		selection.Visible = false
		tween(caret, CHAR_OUT, { BackgroundTransparency = 1 })
		self:_updatePlaceholder()
		if enterPressed and options.OnSubmit then
			task.spawn(options.OnSubmit, self.Text)
		end
		if options.OnBlur then
			task.spawn(options.OnBlur, self.Text, enterPressed)
		end
	end)

	-- caret blink
	self._blinkConnection = RunService.RenderStepped:Connect(function(dt)
		if self.Destroyed then return end
		if not self.Focused then
			return
		end
		self.BlinkClock += dt
		local phase = self.BlinkClock % 1.1
		local target = phase < 0.62 and 0 or 0.85
		caret.BackgroundTransparency += (target - caret.BackgroundTransparency) * math.clamp(dt * 22, 0, 1)
	end)

	return self
end

function SmoothInput:_sanitize(text: string): string
	text = text:gsub("[\n\r\t]", "")
	local options = self.Options
	if options.AllowedPattern then
		text = text:gsub("[^" .. options.AllowedPattern .. "]", "")
	end
	if options.MaxLength then
		local chars = toChars(text)
		if #chars > options.MaxLength then
			text = table.concat(chars, "", 1, options.MaxLength)
		end
	end
	return text
end

function SmoothInput:_measureWidth(text: string): number
	if text == "" then
		return 0
	end
	self.Measure.Text = text
	return self.Measure.TextBounds.X
end

function SmoothInput:_recomputeWidths()
	local widths, total = {}, 0
	for index, entry in ipairs(self.Chars) do
		total += self:_charWidth(entry.Char)
		widths[index] = total
	end
	self.Widths = widths
end

function SmoothInput:_makeLabel(char: string): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = self.Font
	label.TextSize = self.TextSize
	label.TextColor3 = TC(self.TextColor)
	label.Text = char
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Size = UDim2.new(0, math.max(4, self:_charWidth(char)) + 3, 1, 0)
	label.ZIndex = self.Root.ZIndex + 1
	label.Parent = self.CharsHolder
	return label
end

function SmoothInput:_onTextChanged(rawText: string)
	local sanitized = self:_sanitize(rawText)
	if sanitized ~= rawText then
		self.Suppressed = true
		self.Capture.Text = sanitized
		self.Suppressed = false
	end

	local oldChars = self.Chars
	local newChars = toChars(sanitized)
	local oldText = self.Text
	self.Text = sanitized

	local instant = self.InstantNext
	self.InstantNext = false

	-- diff: common prefix / suffix ------------------------------------------------------------------------------
	local oldLen, newLen = #oldChars, #newChars
	local prefix = 0
	while prefix < oldLen and prefix < newLen and oldChars[prefix + 1].Char == newChars[prefix + 1] do
		prefix += 1
	end
	local suffix = 0
	while suffix < (oldLen - prefix) and suffix < (newLen - prefix)
		and oldChars[oldLen - suffix].Char == newChars[newLen - suffix] do
		suffix += 1
	end

	local result = table.create(newLen)
	for i = 1, prefix do
		result[i] = oldChars[i]
	end
	-- removed middle
	for i = prefix + 1, oldLen - suffix do
		local entry = oldChars[i]
		if entry.Label then
			local label = entry.Label
			if instant then
				label:Destroy()
			else
				tween(label, CHAR_OUT, { TextTransparency = 1, Position = label.Position - UDim2.new(0, 0, 0, 5) })
				task.delay(0.11, function() label:Destroy() end)
			end
		end
	end
	-- inserted middle
	for i = prefix + 1, newLen - suffix do
		result[i] = { Char = newChars[i], Label = self:_makeLabel(newChars[i]), New = true }
	end
	-- shared tail
	for i = 0, suffix - 1 do
		result[newLen - i] = oldChars[oldLen - i]
	end

	self.Chars = result
	self:_recomputeWidths()
	self:_reflow(instant)
	self:_updateCaret(not instant)

	self:_updatePlaceholder(instant)
	if sanitized ~= oldText and self.Options.OnChanged then
		task.spawn(self.Options.OnChanged, sanitized)
	end
end

function SmoothInput:_reflow(instant: boolean?)
	local widths = self.Widths
	for index, entry in ipairs(self.Chars) do
		local x = index == 1 and 0 or widths[index - 1]
		local label = entry.Label
		if not label then
			continue
		end
		local target = UDim2.new(0, x, 0, 0)
		if entry.New then
			entry.New = nil
			if instant then
				label.Position = target
			else
				label.Position = target + UDim2.new(0, 0, 0, 6)
				label.TextTransparency = 1
				label.TextSize = math.max(1, self.TextSize - 4)
				tween(label, CHAR_IN, { Position = target, TextTransparency = 0, TextSize = self.TextSize })
			end
		else
			if instant then
				label.Position = target
			elseif label.Position ~= target then
				tween(label, CHAR_FLOW, { Position = target })
			end
		end
	end
end

function SmoothInput:_caretX(): number
	local cursor = self.Capture.CursorPosition
	if cursor < 1 then
		cursor = #self.Chars + 1
	end
	local index = math.clamp(cursor - 1, 0, #self.Chars)
	if index == 0 then
		return 0
	end
	return self.Widths[index] or 0
end

function SmoothInput:_updateCaret(animate: boolean?)
	local caretX = self:_caretX()
	local totalWidth = self.Widths[#self.Widths] or 0
	local viewWidth = math.max(10, self.Root.AbsoluteSize.X - self.PadL - self.PadR)

	local offset = self.Offset
	if caretX + offset > viewWidth - 2 then
		offset = viewWidth - 2 - caretX
	elseif caretX + offset < 2 then
		offset = math.min(0, -caretX + 2)
	end
	offset = math.clamp(offset, math.min(0, viewWidth - totalWidth - 4), 0)
	self.Offset = offset

	local holderTarget = UDim2.new(0, self.PadL + offset, 0, 0)
	local caretTarget = UDim2.new(0, self.PadL + offset + caretX, 0.5, 0)
	self.BlinkClock = 0
	if self.Focused then
		self.Caret.BackgroundTransparency = 0
	end
	self.Capture.Position = UDim2.new(0, self.PadL + offset, 0, 0)
	if animate then
		tween(self.CharsHolder, CARET_MOVE, { Position = holderTarget })
		tween(self.Caret, CARET_MOVE, { Position = caretTarget })
	else
		self.CharsHolder.Position = holderTarget
		self.Caret.Position = caretTarget
	end

	-- selection highlight
	local selectionStart = -1
	pcall(function() selectionStart = self.Capture.SelectionStart end)
	local cursor = self.Capture.CursorPosition
	if selectionStart and selectionStart ~= -1 and cursor and cursor ~= -1 and selectionStart ~= cursor then
		local a = math.clamp(math.min(selectionStart, cursor) - 1, 0, #self.Chars)
		local b = math.clamp(math.max(selectionStart, cursor) - 1, 0, #self.Chars)
		local x1 = a == 0 and 0 or (self.Widths[a] or 0)
		local x2 = b == 0 and 0 or (self.Widths[b] or 0)
		self.SelectionFrame.Visible = true
		self.SelectionFrame.Position = UDim2.new(0, self.PadL + offset + x1, 0.5, 0)
		self.SelectionFrame.Size = UDim2.new(0, math.max(0, x2 - x1), 0, self.TextSize + 5)
	else
		self.SelectionFrame.Visible = false
	end
end

local function isWordChar(char: string): boolean
	return char:match("[%w_%-]") ~= nil
end

function SmoothInput:SelectWordAtCursor()
	local chars = self.Chars
	local total = #chars
	if total == 0 then return end
	local cursor = self.Capture.CursorPosition
	if not cursor or cursor < 1 then cursor = total + 1 end
	local index = math.clamp(cursor - 1, 1, total) -- char to the left of the caret (or first)
	if cursor <= 1 then index = 1 end
	local reference = chars[index]
	local a, b = index, index
	if reference and isWordChar(reference.Char) then
		while a > 1 and isWordChar(chars[a - 1].Char) do a -= 1 end
		while b < total and isWordChar(chars[b + 1].Char) do b += 1 end
	end
	pcall(function() self.Capture.SelectionStart = a end)
	self.Capture.CursorPosition = b + 1
	self:_updateCaret(false)
end

function SmoothInput:SelectAll()
	local total = #self.Chars
	if total == 0 then return end
	pcall(function() self.Capture.SelectionStart = 1 end)
	self.Capture.CursorPosition = total + 1
	self:_updateCaret(false)
end

function SmoothInput:SetText(text: string, instant: boolean?)
	self.InstantNext = instant and true or false
	self.Capture.Text = text
	self.Capture.CursorPosition = #text + 1
end

function SmoothInput:GetText(): string
	return self.Text
end

function SmoothInput:Focus()
	self.Capture:CaptureFocus()
end

function SmoothInput:Blur()
	self.Capture:ReleaseFocus()
end

-- Auto-typing animation (used for the remembered key). charDelay in seconds per character.
function SmoothInput:TypeText(text: string, charDelay: number?)
	charDelay = charDelay or 0.035
	self:SetText("", true)
	local chars = toChars(text)
	for index, char in ipairs(chars) do
		if self.Destroyed then
			return
		end
		self.Suppressed = false
		self.Capture.Text = self.Capture.Text .. char
		self.Capture.CursorPosition = index + 1
		task.wait(charDelay)
	end
end

function SmoothInput:SetTextColor(color: Color3, animate: boolean?)
	self.TextColor = color
	for _, entry in ipairs(self.Chars) do
		if entry.Label then
			if animate then
				tween(entry.Label, CHAR_IN, { TextColor3 = TC(color) })
			else
				entry.Label.TextColor3 = TC(color)
			end
		end
	end
end

function SmoothInput:Shake()
	local root = self.Root
	local original = root.Position
	task.spawn(function()
		for _, dx in ipairs({ 7, -6, 4, -3, 1, 0 }) do
			if self.Destroyed then return end
			tween(root, TweenInfo.new(0.045, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = original + UDim2.new(0, dx, 0, 0) })
			task.wait(0.045)
		end
		root.Position = original
	end)
end

function SmoothInput:Destroy()
	self.Destroyed = true
	if ActiveInput == self then ActiveInput = nil end
	if self._blinkConnection then
		self._blinkConnection:Disconnect()
	end
	if ActiveInput == self then
		ActiveInput = nil
		endInputSink()
	end
	self.Root:Destroy()
end
end)()

connect(UserInputService.InputBegan, function(inputObject)
	local active = ActiveInput
	if not active or active.Destroyed then
		return
	end

	if inputObject.UserInputType == Enum.UserInputType.Keyboard
		and inputObject.KeyCode == Enum.KeyCode.Escape then
		active:Blur()
		return
	end

	if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1
		and inputObject.UserInputType ~= Enum.UserInputType.MouseButton2
		and inputObject.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	task.defer(function()
		local current = ActiveInput
		if not current or current.Destroyed or not current.Focused then
			return
		end
		if os.clock() - (current.LastInsideClick or 0) < 0.1 then
			return          -- клик пришёлся по самому полю
		end
		current:Blur()
	end)
end)

------------------------------------------------------------------------------------------------------------------------
--  Dragging helper
------------------------------------------------------------------------------------------------------------------------

local function makeDraggable(dragZone: GuiObject, target: GuiObject)
	local dragging = false
	local dragStart, startPosition

	dragZone.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			tween(target, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(
					startPosition.X.Scale, startPosition.X.Offset + delta.X,
					startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
				),
			})
		end
	end)
end
local GuiData =
	{"ScreenGui",{DisplayOrder=1,Name="Amphibia",ResetOnSpawn=false,ZIndexBehavior=1},{
		{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(13,13,14),ClipsDescendants=true,Name="MainBackground",Position=u2(0.5,0,0.5,0),Size=u2(0,987,0,608)},{
			{"UICorner",{CornerRadius=ud(0,20)},{
			}},
			{"UIStroke",{ApplyStrokeMode=0,Color=c3(34,34,34),LineJoinMode=0,Thickness=1,Transparency=0},{
			}},
			{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="InfoFrame",Position=u2(0.4997,0,0.9655,0),Size=u2(1,0,0.0049,39),ZIndex=10},{
				{"UICorner",{CornerRadius=ud(0,20)},{
				}},
				{"Frame",{BackgroundColor3=c3(34,34,34),Name="Splitter",Position=u2(0,0,0,0),Size=u2(0,987,0,1)},{
				}},
				{"TextLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="ConnectStatusText",Position=u2(0.0436,0,0.0238,0),Size=u2(0,100,0.95,0),Text="Connected",TextColor3=c3(189,189,189),TextSize=16,TextXAlignment=0,TextYAlignment=1},{
				}},
				{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(170,170,170),Name="DotConnected",Position=u2(0.025,0,0.5,0),Size=u2(0,7,0,7),ZIndex=2},{
					{"UICorner",{CornerRadius=ud(1,0)},{
					}},
					{"UIShadow",{BlurRadius=ud(0,10),Color=c3(225,225,225),Offset=u2(0,0,0,0),Spread=u2(0,2,0,2),Transparency=0,ZIndex=-1},{
					}},
				}},
			}},
			{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="HeaderFrame",Position=u2(0,0,0,0),Size=u2(1,0,-0.0148,58),ZIndex=10},{
				{"TextLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",400,"Normal"),Name="Logo",Position=u2(0.0203,0,0,0),Size=u2(0,100,1,0),Text="amphibia",TextColor3=c3(255,255,255),TextSize=23,TextXAlignment=0,TextYAlignment=1},{
				}},
				{"TextLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Version",Position=u2(0.1064,0,0.1071,0),Size=u2(0,100,0.8929,0),Text="v0.1",TextColor3=c3(111,111,111),TextSize=13,TextXAlignment=0,TextYAlignment=1},{
				}},
				{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(30,30,30),Name="SearchBg",Position=u2(0.5,0,0.5,0),Size=u2(0,300,0.65,0)},{
					{"UICorner",{CornerRadius=ud(0,8)},{
					}},
					{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=0.5,Transparency=0},{
					}},
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://112312028684423",ImageColor3=c3(100,100,100),Name="SearchIcon",Position=u2(0.06,0,0.5,0),Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"TextBox",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="SearchTextbox",PlaceholderColor3=c3(65,65,65),PlaceholderText="search",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),Text="",TextColor3=c3(65,65,65),TextSize=14,TextXAlignment=2,TextYAlignment=1,ZIndex=3},{
						{"UICorner",{CornerRadius=ud(0,8)},{
						}},
					}},
				}},
				{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://90666376026129",ImageColor3=c3(55,55,55),Name="CloseMenuButton",Position=u2(0.969,0,0.5,0),Size=u2(0,35,0,35),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=999},{
				}},
				{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://130321961257203",ImageColor3=c3(255,255,255),ImageTransparency=0.93,Name="WhiteGlow",Position=u2(0.51,0,-0.757,0),Size=u2(0,1068,0,1068),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=-1},{
				}},
				{"Frame",{BackgroundColor3=c3(34,34,34),Name="Splitter",Position=u2(0,0,1.01,0),Size=u2(0,987,0,1)},{
				}},
			}},
			{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="TabsFrame",Position=u2(0.1094,0,0.507,0),Size=u2(0,218,0,515),ZIndex=10},{
				{"Frame",{BackgroundColor3=c3(34,34,34),Name="Splitter",Position=u2(1,0,0,0),Size=u2(0,1,1,0)},{
				}},
				{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="Holder",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0)},{
					{"UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}),Offset=v2(0,0),Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})},{
					}},
					{"UIListLayout",{FillDirection=1,HorizontalAlignment=1,Padding=ud(0,15),SortOrder=2,VerticalAlignment=1},{
					}},
					{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,25),PaddingRight=ud(0,0),PaddingTop=ud(0,25)},{
					}},
					{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,LayoutOrder=-1,Name="MainCategory",Position=u2(0,0,0.0573,0),Size=u2(0,100,0,0)},{
						{"TextLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",400,"Italic"),LayoutOrder=1,Name="CategoryText",Position=u2(0,0,0,0),Size=u2(0,84,0,10),Text="Main",TextColor3=c3(255,255,255),TextSize=17,TextTransparency=0.7,TextXAlignment=0,TextYAlignment=1},{
						}},
						{"UIListLayout",{FillDirection=1,HorizontalAlignment=1,Padding=ud(0,0),SortOrder=2,VerticalAlignment=1},{
						}},
						{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,LayoutOrder=2,Name="TabsHolder",Position=u2(0,0,0,0),Size=u2(1,0,0,0)},{
							{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,15),PaddingRight=ud(0,0),PaddingTop=ud(0,10)},{
							}},
							{"UIListLayout",{FillDirection=1,HorizontalAlignment=1,Padding=ud(0,2),SortOrder=2,VerticalAlignment=1},{
							}},
							{"TextButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="WorldTabButton",Position=u2(0.2875,0,0.6364,0),Size=u2(0,111,0,22),Text="",TextColor3=c3(188,188,188),TextSize=15,TextXAlignment=0,TextYAlignment=1,ZIndex=2},{
								{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0,0,0.5,0),Size=u2(0,10,1,0),Text="World",TextColor3=c3(188,188,188),TextSize=15,TextXAlignment=0,TextYAlignment=1},{
									{"UIShadow",{BlurRadius=ud(0,15),Color=c3(255,255,255),Enabled=false,Offset=u2(0,0,0,0),Spread=u2(0,10,0,-10),Transparency=0.8,ZIndex=-1},{
									}},
								}},
							}},
						}},
					}},
				}},
			}},
			{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,Name="Pages",Position=u2(0.6099,0,0.5074,0),Size=u2(0.7796,0,0.8503,0),ZIndex=10},{
				{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="TabPlayer",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0)},{
					{"ScrollingFrame",{Active=true,AnchorPoint=v2(0.5,0.5),AutomaticCanvasSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,CanvasSize=u2(0,0,0,0),ClipsDescendants=true,ElasticBehavior=1,Position=u2(0.5,0,0.5007,0),ScrollBarImageColor3=c3(0,0,0),ScrollBarImageTransparency=1,ScrollBarThickness=0,ScrollingDirection=2,Size=u2(1,0,1,0),VerticalScrollBarInset=0},{
						{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="RightColumn",Position=u2(0.5,0,0.1,0),Size=u2(0.5,0,0,0)},{
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=1,Padding=ud(0,20),SortOrder=2,VerticalAlignment=1},{
							}},
							{"UIPadding",{PaddingBottom=ud(0,10),PaddingLeft=ud(0,12),PaddingRight=ud(0,10),PaddingTop=ud(0,10)},{
							}},
							{"Frame",{AnchorPoint=v2(0.5,0.5),AutomaticSize=2,BackgroundColor3=c3(27,27,27),Name="SlidersSection",Position=u2(0.4742,0,0.1295,0),Size=u2(0,350,0,15)},{
								{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,1),SortOrder=2,VerticalAlignment=1},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
								}},
								{"UICorner",{CornerRadius=ud(0,12)},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=0.5,Transparency=0},{
								}},
								{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="SectionNameHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,50)},{
									{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="SectionButton",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=5},{
									}},
									{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://82022839420755",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0.91,0,0.5,0),Rotation=180,Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
									}},
									{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="SectionName",Position=u2(0.05,0,0.45,0),Size=u2(0,0,0.9,0),Text="Sliders",TextColor3=c3(216,216,216),TextSize=24,TextXAlignment=2,TextYAlignment=1},{
									}},
								}},
								{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ButtonsHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,10)},{
									{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,2),SortOrder=2,VerticalAlignment=1},{
									}},
									{"UIPadding",{PaddingBottom=ud(0,12),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
									}},
									{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="SliderPercent",Position=u2(0,0,0,0),Size=u2(0.92,0,0,50)},{
										{"TextLabel",{AnchorPoint=v2(0,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.01,0,0.2787,0),Size=u2(0,104,0,27),Text="Slider (percent)",TextColor3=c3(200,200,200),TextSize=16,TextXAlignment=0,TextYAlignment=1},{
											{"UIStroke",{ApplyStrokeMode=0,Color=c3(200,200,200),LineJoinMode=0,Thickness=0.2,Transparency=0},{
											}},
										}},
										{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(94,94,94),Name="SliderBg",Position=u2(0.5,0,0.679,0),Size=u2(0.95,0,0,2)},{
											{"UICorner",{CornerRadius=ud(1,0)},{
											}},
											{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),Name="Knob",Position=u2(0.5,0,0.5,0),Size=u2(0,15,0,15),ZIndex=3},{
												{"UICorner",{CornerRadius=ud(1,0)},{
												}},
												{"UIShadow",{BlurRadius=ud(0,10),Color=c3(255,255,255),Offset=u2(0,0,0,0),Spread=u2(0,0,0,0),Transparency=0.27,ZIndex=-1},{
												}},
											}},
											{"Frame",{AnchorPoint=v2(0,0.5),BackgroundColor3=c3(255,255,255),Name="Fill",Position=u2(0,0,0.5,0),Size=u2(0.5,0,1,0),ZIndex=2},{
												{"UICorner",{CornerRadius=ud(0,7)},{
												}},
												{"UIShadow",{BlurRadius=ud(0,10),Color=c3(255,255,255),Offset=u2(0,0,0,0),Spread=u2(0,15,0,5),Transparency=0.57,ZIndex=-1},{
												}},
											}},
										}},
										{"TextLabel",{AnchorPoint=v2(1,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="Value",Position=u2(0.99,0,0.279,0),Size=u2(0,104,0,27),Text="50%",TextColor3=c3(226,226,226),TextSize=20,TextXAlignment=1,TextYAlignment=1},{
											{"UIStroke",{ApplyStrokeMode=0,Color=c3(200,200,200),LineJoinMode=0,Thickness=0.2,Transparency=0},{
											}},
										}},
									}},
								}},
							}},
							{"Frame",{AnchorPoint=v2(0.5,0.5),AutomaticSize=2,BackgroundColor3=c3(27,27,27),Name="ColorPickersSection",Position=u2(0.6782,0,0.8104,0),Size=u2(0,350,0,15)},{
								{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,1),SortOrder=2,VerticalAlignment=1},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
								}},
								{"UICorner",{CornerRadius=ud(0,12)},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=0.5,Transparency=0},{
								}},
								{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="SectionNameHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,50)},{
									{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="SectionButton",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=5},{
									}},
									{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://82022839420755",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0.91,0,0.5,0),Rotation=180,Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
									}},
									{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="SectionName",Position=u2(0.05,0,0.45,0),Size=u2(0,0,0.9,0),Text="Color Pickers",TextColor3=c3(216,216,216),TextSize=24,TextXAlignment=2,TextYAlignment=1},{
									}},
								}},
								{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ButtonsHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,10)},{
									{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,2),SortOrder=2,VerticalAlignment=1},{
									}},
									{"UIPadding",{PaddingBottom=ud(0,12),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
									}},
									{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,LayoutOrder=2,Name="ColorPicker",Position=u2(0,0,0,0),Size=u2(0.92,0,0,50)},{
										{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.01,0,0.5,0),Size=u2(0,31,0,50),Text="Color Picker",TextColor3=c3(200,200,200),TextSize=16,TextXAlignment=0,TextYAlignment=1},{
											{"UIStroke",{ApplyStrokeMode=0,Color=c3(200,200,200),LineJoinMode=0,Thickness=0.2,Transparency=0},{
											}},
										}},
										{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),AutoButtonColor=false,BackgroundColor3=c3(143,168,160),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="ColorPickerPreview",Position=u2(0.932,0,0.5,0),Size=u2(0,30,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
											{"UICorner",{CornerRadius=ud(0,8)},{
											}},
										}},
										{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",400,"Normal"),Name="HexPrefix",Position=u2(0.628,0,0.5,0),Size=u2(0,23,0,50),Text="#",TextColor3=c3(222,222,222),TextSize=25,TextXAlignment=2,TextYAlignment=1},{
											{"UIPadding",{PaddingBottom=ud(0,2),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
											}},
										}},
										{"ImageButton",{Active=true,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="ValueButton",Position=u2(0.5822,0,0.32,0),Size=u2(0,97,0,24),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=3},{
										}},
										{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="HexValue",Position=u2(0.7593,0,0.5,0),Size=u2(0,68,0,50),Text="8FA8A0",TextColor3=c3(222,222,222),TextSize=20,TextWrapped=true,TextXAlignment=0,TextYAlignment=1},{
										}},
									}},
								}},
							}},
							{"Frame",{AnchorPoint=v2(0.5,0.5),AutomaticSize=2,BackgroundColor3=c3(27,27,27),Name="SelectorSection",Position=u2(0.6782,0,0.855,0),Size=u2(0,350,0,15)},{
								{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,1),SortOrder=2,VerticalAlignment=1},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
								}},
								{"UICorner",{CornerRadius=ud(0,12)},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=0.5,Transparency=0},{
								}},
								{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="SectionNameHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,50)},{
									{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="SectionButton",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=5},{
									}},
									{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://82022839420755",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0.91,0,0.5,0),Rotation=180,Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
									}},
									{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="SectionName",Position=u2(0.05,0,0.45,0),Size=u2(0,0,0.9,0),Text="Selectors",TextColor3=c3(216,216,216),TextSize=24,TextXAlignment=2,TextYAlignment=1},{
									}},
								}},
								{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ButtonsHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,10)},{
									{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,2),SortOrder=2,VerticalAlignment=1},{
									}},
									{"UIPadding",{PaddingBottom=ud(0,12),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
									}},
									{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,LayoutOrder=2,Name="Selector",Position=u2(0,0,0,0),Size=u2(0.92,0,0,50)},{
										{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.01,0,0.5,0),Size=u2(0,31,0,50),Text="Selector",TextColor3=c3(200,200,200),TextSize=16,TextXAlignment=0,TextYAlignment=1},{
											{"UIStroke",{ApplyStrokeMode=0,Color=c3(200,200,200),LineJoinMode=0,Thickness=0.2,Transparency=0},{
											}},
										}},
										{"Frame",{AnchorPoint=v2(1,0.5),AutomaticSize=1,BackgroundColor3=c3(16,16,16),Name="SelectionsHolder",Position=u2(0.97,0,0.5,0),Size=u2(0,15,0,30)},{
											{"UICorner",{CornerRadius=ud(0,8)},{
											}},
											{"ImageButton",{Active=true,AutoButtonColor=false,AutomaticSize=1,BackgroundColor3=c3(16,16,16),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="Selection1",Position=u2(0,0,0,0),Size=u2(0,13,0,28),SliceScale=1,TileSize=u2(1,0,1,0)},{
												{"UICorner",{CornerRadius=ud(0,8)},{
												}},
												{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0,0,0,0),Size=u2(1,0,1,0),Text="Selection1",TextColor3=c3(106,106,106),TextSize=14,TextXAlignment=2,TextYAlignment=1},{
												}},
												{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,4),PaddingRight=ud(0,4),PaddingTop=ud(0,0)},{
												}},
											}},
											{"UIListLayout",{FillDirection=0,HorizontalAlignment=2,Padding=ud(0,1),SortOrder=2,VerticalAlignment=0},{
											}},
											{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
											}},
										}},
									}},
								}},
							}},
							{"Frame",{AnchorPoint=v2(0.5,0.5),AutomaticSize=2,BackgroundColor3=c3(27,27,27),Name="DropdownSection",Position=u2(0.4824,0,0.8795,0),Size=u2(0,350,0,15)},{
								{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,1),SortOrder=2,VerticalAlignment=1},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
								}},
								{"UICorner",{CornerRadius=ud(0,12)},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=0.5,Transparency=0},{
								}},
								{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="SectionNameHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,50)},{
									{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="SectionButton",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=5},{
									}},
									{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://82022839420755",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0.91,0,0.5,0),Rotation=180,Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
									}},
									{"TextLabel",{AnchorPoint=v2(0,0),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="SectionName",Position=u2(0.05,0,0.12,0),Size=u2(0,0,0.9,0),Text="Dropdowns",TextColor3=c3(216,216,216),TextSize=24,TextXAlignment=2,TextYAlignment=1},{
									}},
								}},
								{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ButtonsHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,10)},{
									{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,2),SortOrder=2,VerticalAlignment=1},{
									}},
									{"UIPadding",{PaddingBottom=ud(0,12),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
									}},
									{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,LayoutOrder=2,Name="Dropdown",Position=u2(0,0,0,0),Size=u2(0.92,0,0,50)},{
										{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.01,0,0.5,0),Size=u2(0,31,0,50),Text="Dropdown",TextColor3=c3(200,200,200),TextSize=16,TextXAlignment=0,TextYAlignment=1},{
											{"UIStroke",{ApplyStrokeMode=0,Color=c3(200,200,200),LineJoinMode=0,Thickness=0.2,Transparency=0},{
											}},
										}},
										{"Frame",{AnchorPoint=v2(1,0.5),AutomaticSize=3,BackgroundColor3=c3(13,13,13),Name="DropdownSelectedFrame",Position=u2(0.975,0,0.5,0),Size=u2(0,15,0,23)},{
											{"UICorner",{CornerRadius=ud(0,8)},{
											}},
											{"TextLabel",{AnchorPoint=v2(1,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Picked",Position=u2(0.5,0,0.5,0),Size=u2(0,5,1,0),Text="Item 3",TextColor3=c3(215,215,215),TextSize=15,TextTruncate=1,TextXAlignment=1,TextYAlignment=1},{
											}},
											{"UIListLayout",{FillDirection=0,HorizontalAlignment=2,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
											}},
											{"UIPadding",{PaddingBottom=ud(0,6),PaddingLeft=ud(0,10),PaddingRight=ud(0,5),PaddingTop=ud(0,6)},{
											}},
											{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://71447831631799",ImageColor3=c3(115,115,115),Name="Icon",Position=u2(0,0,0,0),Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
											}},
										}},
									}},
								}},
							}},
						}},
						{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="LeftColumn",Position=u2(0,0,0.1,0),Size=u2(0.5,0,0,0)},{
							{"Frame",{AnchorPoint=v2(0.5,0.5),AutomaticSize=2,BackgroundColor3=c3(27,27,27),Name="TogglesSection",Position=u2(0.475,0,0.3574,0),Size=u2(0,350,0,15)},{
								{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="SectionNameHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,50)},{
									{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="SectionButton",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=5},{
									}},
									{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://82022839420755",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0.91,0,0.5,0),Rotation=180,Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
									}},
									{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="SectionName",Position=u2(0.05,0,0.45,0),Size=u2(0,0,0.9,0),Text="Toggles",TextColor3=c3(216,216,216),TextSize=24,TextXAlignment=2,TextYAlignment=1},{
									}},
								}},
								{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ButtonsHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,10)},{
									{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,2),SortOrder=2,VerticalAlignment=1},{
									}},
									{"ImageButton",{Active=true,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="ToggleEnabled",Position=u2(0,0,0,0),Size=u2(0.92,0,0,50),SliceScale=1,TileSize=u2(1,0,1,0)},{
										{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.01,0,0.5,0),Size=u2(0,31,0,50),Text="Toggle (enabled)",TextColor3=c3(200,200,200),TextSize=16,TextXAlignment=0,TextYAlignment=1},{
											{"UIStroke",{ApplyStrokeMode=0,Color=c3(200,200,200),LineJoinMode=0,Thickness=0.2,Transparency=0},{
											}},
										}},
										{"Frame",{AnchorPoint=v2(1,0.5),BackgroundColor3=c3(48,48,47),Name="ToggleFrame",Position=u2(0.98,0,0.5,0),Size=u2(0,45,0,25)},{
											{"UICorner",{CornerRadius=ud(1,0)},{
											}},
											{"UIStroke",{ApplyStrokeMode=0,Color=c3(175,175,175),LineJoinMode=0,Thickness=0.5,Transparency=0},{
											}},
											{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),Name="Dot",Position=u2(0.7,0,0.5,0),Size=u2(0,19,0,19)},{
												{"UICorner",{CornerRadius=ud(1,0)},{
												}},
												{"UIShadow",{BlurRadius=ud(0,15),Color=c3(225,225,225),Offset=u2(0,0,0,0),Spread=u2(0,0,0,0),Transparency=0,ZIndex=-1},{
												}},
											}},
										}},
										{"TextLabel",{AnchorPoint=v2(1,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",400,"Italic"),Name="ToggleValue",Position=u2(0.8019,0,0.5,0),Size=u2(0,102,0,50),Text="On",TextColor3=c3(150,150,150),TextSize=16,TextXAlignment=1,TextYAlignment=1},{
											{"UIPadding",{PaddingBottom=ud(0,4),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
											}},
										}},
									}},
									{"UIPadding",{PaddingBottom=ud(0,12),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
									}},
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=0.5,Transparency=0},{
								}},
								{"UICorner",{CornerRadius=ud(0,12)},{
								}},
								{"UIListLayout",{FillDirection=1,HorizontalAlignment=1,Padding=ud(0,1),SortOrder=2,VerticalAlignment=1},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
								}},
							}},
							{"Frame",{AnchorPoint=v2(0.5,0.5),AutomaticSize=2,BackgroundColor3=c3(27,27,27),Name="ButtonsSection",Position=u2(0.475,0,0.3574,0),Size=u2(0,350,0,15)},{
								{"UIListLayout",{FillDirection=1,HorizontalAlignment=1,Padding=ud(0,1),SortOrder=2,VerticalAlignment=1},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
								}},
								{"UICorner",{CornerRadius=ud(0,12)},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=0.5,Transparency=0},{
								}},
								{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="SectionNameHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,50)},{
									{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="SectionButton",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=5},{
									}},
									{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://82022839420755",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0.91,0,0.5,0),Rotation=180,Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
									}},
									{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="SectionName",Position=u2(0.05,0,0.45,0),Size=u2(0,0,0.9,0),Text="Buttons",TextColor3=c3(216,216,216),TextSize=24,TextXAlignment=2,TextYAlignment=1},{
									}},
								}},
								{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ButtonsHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,10)},{
									{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,2),SortOrder=2,VerticalAlignment=1},{
									}},
									{"UIPadding",{PaddingBottom=ud(0,12),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
									}},
									{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,LayoutOrder=2,Name="Button",Position=u2(0,0,0,0),Size=u2(0.92,0,0,40)},{
										{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),AutoButtonColor=false,BackgroundColor3=c3(13,13,14),Image="rbxasset://textures/ui/GuiImagePlaceholder.png",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="ButtonButton",Position=u2(0.5,0,0.5,0),Size=u2(0.95,0,0.7,0),SliceScale=1,TileSize=u2(1,0,1,0)},{
											{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.5,0,0.48,0),Size=u2(0,31,1,0),Text="Button",TextColor3=c3(200,200,200),TextSize=16,TextXAlignment=2,TextYAlignment=1},{
											}},
											{"UICorner",{CornerRadius=ud(0,8)},{
											}},
										}},
									}},
								}},
							}},
							{"Frame",{AnchorPoint=v2(0.5,0.5),AutomaticSize=2,BackgroundColor3=c3(27,27,27),Name="NumberPickerSection",Position=u2(0.6782,0,0.855,0),Size=u2(0,350,0,15)},{
								{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,1),SortOrder=2,VerticalAlignment=1},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
								}},
								{"UICorner",{CornerRadius=ud(0,12)},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=0.5,Transparency=0},{
								}},
								{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="SectionNameHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,50)},{
									{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="SectionButton",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=5},{
									}},
									{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://82022839420755",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0.91,0,0.5,0),Rotation=180,Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
									}},
									{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="SectionName",Position=u2(0.05,0,0.45,0),Size=u2(0,0,0.9,0),Text="Number Pickers",TextColor3=c3(216,216,216),TextSize=24,TextXAlignment=2,TextYAlignment=1},{
									}},
								}},
								{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ButtonsHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,10)},{
									{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,2),SortOrder=2,VerticalAlignment=1},{
									}},
									{"UIPadding",{PaddingBottom=ud(0,12),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
									}},
									{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,LayoutOrder=2,Name="NumberPicker",Position=u2(0,0,0,0),Size=u2(0.92,0,0,50)},{
										{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.01,0,0.5,0),Size=u2(0,31,0,50),Text="Number Picker",TextColor3=c3(200,200,200),TextSize=16,TextXAlignment=0,TextYAlignment=1},{
											{"UIStroke",{ApplyStrokeMode=0,Color=c3(200,200,200),LineJoinMode=0,Thickness=0.2,Transparency=0},{
											}},
										}},
										{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(13,13,14),Name="NumberPickerHolder",Position=u2(0.8137,0,0.5,0),Size=u2(0,106,0,32)},{
											{"UICorner",{CornerRadius=ud(0,12)},{
											}},
											{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="NumberValueHolder",Position=u2(0.5,0,0.5,0),Size=u2(0,50,1,0)},{
												{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",400,"Normal"),Name="NumberValue",Position=u2(0.5,0,0.4966,0),Size=u2(1,0,0.85,0),Text="20",TextColor3=c3(255,255,255),TextSize=20,TextXAlignment=2,TextYAlignment=1},{
												}},
											}},
											{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),AutoButtonColor=false,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="Minus",Position=u2(0.1347,0,0.4932,0),Size=u2(0,27,0,31),SliceScale=1,TileSize=u2(1,0,1,0)},{
												{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://128229913388215",ImageColor3=c3(175,175,175),Name="Icon",Position=u2(0.5,0,0.5,0),Size=u2(0,20,0,20),SliceScale=1,TileSize=u2(1,0,1,0)},{
												}},
											}},
											{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),AutoButtonColor=false,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="Plus",Position=u2(0.8706,0,0.4932,0),Size=u2(0,27,0,31),SliceScale=1,TileSize=u2(1,0,1,0)},{
												{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://96950735183906",ImageColor3=c3(175,175,175),Name="Icon",Position=u2(0.5,0,0.5,0),Size=u2(0,20,0,20),SliceScale=1,TileSize=u2(1,0,1,0)},{
												}},
											}},
										}},
									}},
								}},
							}},
							{"Frame",{AnchorPoint=v2(0.5,0.5),AutomaticSize=2,BackgroundColor3=c3(27,27,27),Name="TextboxSection",Position=u2(0.6782,0,0.855,0),Size=u2(0,350,0,15)},{
								{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,1),SortOrder=2,VerticalAlignment=1},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
								}},
								{"UICorner",{CornerRadius=ud(0,12)},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=0.5,Transparency=0},{
								}},
								{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="SectionNameHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,50)},{
									{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="SectionButton",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=5},{
									}},
									{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://82022839420755",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0.91,0,0.5,0),Rotation=180,Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
									}},
									{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="SectionName",Position=u2(0.05,0,0.45,0),Size=u2(0,0,0.9,0),Text="Textboxes",TextColor3=c3(216,216,216),TextSize=24,TextXAlignment=2,TextYAlignment=1},{
									}},
								}},
								{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ButtonsHolderFrame",Position=u2(0,0,0,0),Size=u2(1,0,0,10)},{
									{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,2),SortOrder=2,VerticalAlignment=1},{
									}},
									{"UIPadding",{PaddingBottom=ud(0,12),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
									}},
									{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,LayoutOrder=2,Name="Textbox",Position=u2(0,0,0,0),Size=u2(0.92,0,0,50)},{
										{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.01,0,0.5,0),Size=u2(0,31,0,50),Text="Textbox ",TextColor3=c3(200,200,200),TextSize=16,TextXAlignment=0,TextYAlignment=1},{
											{"UIStroke",{ApplyStrokeMode=0,Color=c3(200,200,200),LineJoinMode=0,Thickness=0.2,Transparency=0},{
											}},
										}},
										{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(20,20,20),Name="TextboxBg",Position=u2(0.6644,0,0.498,0),Size=u2(0,202,0,23),ZIndex=3},{
											{"UICorner",{CornerRadius=ud(0,9)},{
											}},
											{"UIStroke",{ApplyStrokeMode=0,Color=c3(45,45,45),LineJoinMode=0,Thickness=1,Transparency=0},{
											}},
											{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Text",Position=u2(0.4597,0,0.5,0),Size=u2(0.8706,0,1,0),Text="type here",TextColor3=c3(120,120,120),TextSize=14,TextXAlignment=0,TextYAlignment=1},{
												{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,3),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
												}},
											}},
											{"ImageButton",{Active=true,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="InputButton",Position=u2(0,0,0,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0)},{
											}},
										}},
									}},
								}},
							}},
							{"UIPadding",{PaddingBottom=ud(0,10),PaddingLeft=ud(0,20),PaddingRight=ud(0,10),PaddingTop=ud(0,10)},{
							}},
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=1,Padding=ud(0,20),SortOrder=2,VerticalAlignment=1},{
							}},
						}},
						{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="TabInfoFrameHolder",Position=u2(0,0,0,0),Size=u2(1,0,0.1,0)},{
							{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),LayoutOrder=1,Name="TabName",Position=u2(0.0213,0,0.5,0),Size=u2(0,0,1,0),Text="Player",TextColor3=c3(216,216,216),TextSize=25,TextXAlignment=0,TextYAlignment=1},{
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,2),PaddingTop=ud(0,0)},{
								}},
							}},
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=1,Padding=ud(0,10),SortOrder=2,VerticalAlignment=0},{
							}},
							{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,30),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
							}},
							{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://124160192323665",ImageColor3=c3(49,49,49),LayoutOrder=2,Name="Divider",Position=u2(0,0,0,0),Size=u2(0,9,0,9),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
							{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",400,"Italic"),LayoutOrder=3,Name="TabGroupName",Position=u2(0.0213,0,0.5,0),Size=u2(0,0,1,0),Text="Main",TextColor3=c3(100,100,100),TextSize=19,TextXAlignment=0,TextYAlignment=1},{
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,6)},{
								}},
							}},
						}},
						{"UIPadding",{PaddingBottom=ud(0,60),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
						}},
					}},
				}},
				{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="TabConfig",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),Visible=false},{
					{"Frame",{BackgroundColor3=c3(22,22,22),Name="ConfigsBg",Position=u2(0.03,0,0.04,0),Size=u2(0,531,0,475)},{
						{"UICorner",{CornerRadius=ud(0,12)},{
						}},
						{"UIStroke",{ApplyStrokeMode=0,Color=c3(50,50,50),LineJoinMode=0,Thickness=0.5,Transparency=0},{
						}},
						{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="Name",Position=u2(0,0,0.05,0),Size=u2(1,0,0,45),Text="Configs",TextColor3=c3(216,216,216),TextSize=24,TextXAlignment=0,TextYAlignment=1},{
							{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,17),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
							}},
							{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Info",Position=u2(0,0,0.4972,0),Size=u2(1,0,0,45),Text="7 configs in total",TextColor3=c3(70,70,70),TextSize=12,TextXAlignment=1,TextYAlignment=1},{
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,17),PaddingTop=ud(0,0)},{
								}},
							}},
						}},
						{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="NoConfigsFrameHolder",Position=u2(0.5,0,0.5,0),Size=u2(0,271,0,119),Visible=false},{
							{"TextLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Title",Position=u2(0,0,0.1681,0),Size=u2(1,0,0,30),Text="No configs yet.",TextColor3=c3(130,130,130),TextSize=18,TextXAlignment=2,TextYAlignment=1},{
							}},
							{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",400,"Normal"),Name="Description",Position=u2(0.5,0,0.6681,0),Size=u2(1.2804,0,0.2422,30),Text="Create one from scratch, or download a ready-made config\nfrom discord.",TextColor3=c3(80,80,80),TextSize=16,TextWrapped=true,TextXAlignment=2,TextYAlignment=0},{
							}},
						}},
						{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(20,20,20),Name="SearchFrame",Position=u2(0.5,0,0.135,0),Size=u2(0,495,0,25)},{
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(45,45,45),LineJoinMode=0,Thickness=1,Transparency=0},{
							}},
							{"UICorner",{CornerRadius=ud(0,9)},{
							}},
							{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Text",Position=u2(0.5248,0,0.5,0),Size=u2(0.9457,0,1,0),Text="Filter configs...",TextColor3=c3(120,120,120),TextSize=14,TextXAlignment=0,TextYAlignment=1},{
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,7),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
								}},
							}},
							{"ImageButton",{Active=true,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="InputButton",Position=u2(0,0,0,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0)},{
								{"UICorner",{CornerRadius=ud(0,9)},{
								}},
							}},
							{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://140365558570753",ImageColor3=c3(130,130,130),Name="Loupe",Position=u2(0.0358,0,0.52,0),Size=u2(0,16,0,16),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
						}},
						{"ScrollingFrame",{Active=true,AnchorPoint=v2(0.5,0.5),AutomaticCanvasSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,CanvasSize=u2(0,0,0,0),ClipsDescendants=true,ElasticBehavior=0,Position=u2(0.5002,0,0.5804,0),ScrollBarImageColor3=c3(0,0,0),ScrollBarImageTransparency=1,ScrollBarThickness=0,ScrollingDirection=4,Size=u2(0,530,0,398),VerticalScrollBarInset=0},{
							{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=1},{
							}},
							{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,25)},{
							}},
							{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(35,35,35),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="Config1",Position=u2(0,0,0,0),Size=u2(0,480,0,40),SliceScale=1,TileSize=u2(1,0,1,0)},{
								{"UICorner",{CornerRadius=ud(0,9)},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(70,70,70),LineJoinMode=0,Thickness=1,Transparency=1},{
								}},
								{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(143,168,160),Name="EnabledDot",Position=u2(0.04,0,0.5,0),Size=u2(0,7,0,7)},{
									{"UICorner",{CornerRadius=ud(1,0)},{
									}},
									{"UIShadow",{BlurRadius=ud(0,10),Color=c3(143,168,160),Offset=u2(0,0,0,0),Spread=u2(0,2,0,2),Transparency=0,ZIndex=-1},{
									}},
								}},
								{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.075,0,0.5,0),Size=u2(0,5,1,0),Text="config-one-enabled",TextColor3=c3(255,255,255),TextSize=16,TextXAlignment=2,TextYAlignment=1},{
									{"UIPadding",{PaddingBottom=ud(0,3),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
									}},
									{"UIStroke",{ApplyStrokeMode=0,Color=c3(255,255,255),LineJoinMode=0,Thickness=0.2,Transparency=0},{
									}},
								}},
								{"TextLabel",{AnchorPoint=v2(1,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Created",Position=u2(1,0,0.5,0),Size=u2(0.2703,5,1,0),Text="2d ago",TextColor3=c3(75,75,75),TextSize=14,TextWrapped=true,TextXAlignment=1,TextYAlignment=1},{
									{"UIPadding",{PaddingBottom=ud(0,1),PaddingLeft=ud(0,0),PaddingRight=ud(0,15),PaddingTop=ud(0,0)},{
									}},
								}},
							}},
						}},
					}},
					{"Frame",{BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,Name="ButtonsBg",Position=u2(0.7212,0,0.0387,0),Size=u2(0,214,0,477)},{
						{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,10),SortOrder=2,VerticalAlignment=1},{
						}},
						{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,10),PaddingRight=ud(0,10),PaddingTop=ud(0,0)},{
						}},
						{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(246,243,236),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=1,Name="LoadButton",Position=u2(0.0928,0,0,0),Size=u2(0,158,0,33),SliceScale=1,TileSize=u2(1,0,1,0)},{
							{"UICorner",{CornerRadius=ud(0,8)},{
							}},
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
							}},
							{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0,0,0,0),Size=u2(0,5,1,0),Text="Load",TextColor3=c3(20,19,15),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
							}},
							{"UIShadow",{BlurRadius=ud(0,20),Color=c3(246,243,236),Enabled=false,Offset=u2(0,0,0,0),Spread=u2(0,5,0,0),Transparency=0.4,ZIndex=-1},{
							}},
							{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://129861047513547",ImageColor3=c3(20,19,15),LayoutOrder=-1,Name="Icon",Position=u2(0,0,0,0),Size=u2(0,20,0,20),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
						}},
						{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(30,30,30),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=3,Name="OverwriteButton",Position=u2(0.0928,0,0,0),Size=u2(0,158,0,33),SliceScale=1,TileSize=u2(1,0,1,0)},{
							{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://121046347967510",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0,0,0,0),Size=u2(0,18,0,18),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
							{"UICorner",{CornerRadius=ud(0,8)},{
							}},
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
							}},
							{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0,0,0,0),Size=u2(0,5,1,0),Text="Overwrite",TextColor3=c3(120,120,120),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
							}},
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(65,65,65),LineJoinMode=0,Thickness=1.1,Transparency=0},{
							}},
						}},
						{"Frame",{BackgroundColor3=c3(45,45,45),LayoutOrder=4,Name="Separator",Position=u2(0,0,0,0),Size=u2(0,158,0,2)},{
						}},
						{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(45,45,45),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=2,Name="NewButton",Position=u2(0.0928,0,0,0),Size=u2(0,158,0,33),SliceScale=1,TileSize=u2(1,0,1,0)},{
							{"UICorner",{CornerRadius=ud(0,8)},{
							}},
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
							}},
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(85,85,85),LineJoinMode=0,Thickness=1.1,Transparency=0},{
							}},
							{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://112400023050433",ImageColor3=c3(225,225,225),Name="Icon",Position=u2(0,0,0,0),Size=u2(0,20,0,20),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
							{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0,0,0,0),Size=u2(0,5,1,0),Text="New",TextColor3=c3(225,225,225),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
							}},
						}},
						{"Frame",{BackgroundColor3=c3(45,45,45),LayoutOrder=7,Name="Separator2",Position=u2(0,0,0,0),Size=u2(0,158,0,2)},{
						}},
						{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(30,30,30),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=8,Name="ImportCodeButton",Position=u2(0.0928,0,0,0),Size=u2(0,158,0,33),SliceScale=1,TileSize=u2(1,0,1,0)},{
							{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://119378092905016",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0,0,0,0),Size=u2(0,18,0,18),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
							{"UICorner",{CornerRadius=ud(0,8)},{
							}},
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
							}},
							{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0,0,0,0),Size=u2(0,5,1,0),Text="Import code",TextColor3=c3(120,120,120),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
							}},
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(65,65,65),LineJoinMode=0,Thickness=1.1,Transparency=0},{
							}},
						}},
						{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(30,30,30),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=11,Name="ResetButton",Position=u2(0.0928,0,0,0),Size=u2(0,158,0,33),SliceScale=1,TileSize=u2(1,0,1,0)},{
							{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://99227055213666",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0,0,0,0),Size=u2(0,18,0,18),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
							{"UICorner",{CornerRadius=ud(0,8)},{
							}},
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
							}},
							{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0,0,0,0),Size=u2(0,5,1,0),Text="Reset config",TextColor3=c3(120,120,120),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
							}},
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(65,65,65),LineJoinMode=0,Thickness=1.1,Transparency=0},{
							}},
						}},
						{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(30,30,30),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=5,Name="RenameButton",Position=u2(0.0928,0,0,0),Size=u2(0,158,0,33),SliceScale=1,TileSize=u2(1,0,1,0)},{
							{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://129818828426508",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0,0,0,0),Size=u2(0,18,0,18),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
							{"UICorner",{CornerRadius=ud(0,8)},{
							}},
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
							}},
							{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0,0,0,0),Size=u2(0,5,1,0),Text="Rename",TextColor3=c3(120,120,120),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
							}},
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(65,65,65),LineJoinMode=0,Thickness=1.1,Transparency=0},{
							}},
						}},
						{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(30,30,30),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=6,Name="DuplicateButton",Position=u2(0.0928,0,0,0),Size=u2(0,158,0,33),SliceScale=1,TileSize=u2(1,0,1,0)},{
							{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://118944771595983",ImageColor3=c3(120,120,120),Name="Icon",Position=u2(0,0,0,0),Size=u2(0,18,0,18),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
							{"UICorner",{CornerRadius=ud(0,8)},{
							}},
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
							}},
							{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0,0,0,0),Size=u2(0,5,1,0),Text="Duplicate",TextColor3=c3(120,120,120),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
							}},
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(65,65,65),LineJoinMode=0,Thickness=1.1,Transparency=0},{
							}},
						}},
						{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(30,30,30),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=9,Name="ExportCodeButton",Position=u2(0.0928,0,0,0),Size=u2(0,158,0,33),SliceScale=1,TileSize=u2(1,0,1,0)},{
							{"UICorner",{CornerRadius=ud(0,8)},{
							}},
							{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0,0,0,0),Size=u2(0,5,1,0),Text="Export code",TextColor3=c3(120,120,120),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
							}},
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(65,65,65),LineJoinMode=0,Thickness=1.1,Transparency=0},{
							}},
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,7),SortOrder=2,VerticalAlignment=0},{
							}},
							{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://72127232048129",ImageColor3=c3(120,120,120),LayoutOrder=-1,Name="Icon",Position=u2(0,0,0,0),Rotation=180,Size=u2(0,16,0,16),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
						}},
						{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(35,30,30),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=12,Name="DeleteButton",Position=u2(0.0928,0,0,0),Size=u2(0,158,0,33),SliceScale=1,TileSize=u2(1,0,1,0)},{
							{"UICorner",{CornerRadius=ud(0,8)},{
							}},
							{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0,0,0,0),Size=u2(0,5,1,0),Text="Delete",TextColor3=c3(196,122,122),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
							}},
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(80,65,65),LineJoinMode=0,Thickness=1.1,Transparency=0},{
							}},
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
							}},
							{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://90320116313568",ImageColor3=c3(196,122,122),LayoutOrder=-1,Name="Icon",Position=u2(0,0,0,0),Rotation=180,Size=u2(0,16,0,16),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
						}},
						{"Frame",{BackgroundColor3=c3(45,45,45),LayoutOrder=10,Name="Separator3",Position=u2(0,0,0,0),Size=u2(0,158,0,2)},{
						}},
					}},
				}},
			}},
			{"Folder",{Name="Screens"},{
				{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(13,13,14),Name="LoadingScreen",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),Visible=false,ZIndex=11},{
					{"UICorner",{CornerRadius=ud(0,20)},{
					}},
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://130321961257203",ImageColor3=c3(255,255,255),ImageTransparency=0.93,Name="WhiteGlow",Position=u2(0.51,0,-0.045,0),Size=u2(0,1068,0,1068),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=-1},{
					}},
					{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",400,"Normal"),Name="LoadingTitle",Position=u2(0.5,0,0.4277,0),Size=u2(1,0,0,70),Text="Just a momentâ¦",TextColor3=c3(213,213,213),TextSize=35,TextXAlignment=2,TextYAlignment=1},{
					}},
					{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(25,25,25),Name="LoadingLine",Position=u2(0.5,0,0.54,0),Size=u2(0,224,0,9)},{
						{"UICorner",{CornerRadius=ud(1,0)},{
						}},
						{"Frame",{BackgroundColor3=c3(225,225,225),Name="Fill",Position=u2(0,0,0,0),Size=u2(0.5,0,1,0)},{
							{"UICorner",{CornerRadius=ud(1,0)},{
							}},
						}},
					}},
					{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",400,"Italic"),Name="LoadingDesc",Position=u2(0.5,0,0.5,0),Size=u2(1,0,-0.0375,70),Text="Setting things up â this won't take long.",TextColor3=c3(120,120,120),TextSize=17,TextXAlignment=2,TextYAlignment=0},{
					}},
					{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",400,"Italic"),Name="Timer",Position=u2(0.5,0,0.58,0),Size=u2(0.0344,0,-0.0762,70),Text="~6s",TextColor3=c3(50,50,50),TextSize=16,TextXAlignment=2,TextYAlignment=1},{
					}},
				}},
				{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(13,13,14),Name="EnterKeyScreen",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),Visible=false,ZIndex=12},{
					{"UICorner",{CornerRadius=ud(0,20)},{
					}},
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://130321961257203",ImageColor3=c3(255,255,255),ImageTransparency=0.93,Name="WhiteGlow",Position=u2(0.51,0,-0.045,0),Size=u2(0,1068,0,1068),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=-1},{
					}},
					{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",400,"Normal"),Name="WelcomeText",Position=u2(0.5,0,0.4014,0),Size=u2(1,0,0,70),Text="Welcome to amphibia.",TextColor3=c3(213,213,213),TextSize=35,TextXAlignment=2,TextYAlignment=1},{
					}},
					{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",400,"Italic"),Name="WelcomeDesc",Position=u2(0.5,0,0.48,0),Size=u2(1,0,-0.0382,70),Text="Enter your key to get started.",TextColor3=c3(120,120,120),TextSize=19,TextXAlignment=2,TextYAlignment=0},{
					}},
					{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(29,29,29),Name="KeyInputBG",Position=u2(0.5,0,0.558,0),Size=u2(0,319,0,23),ZIndex=3},{
						{"UICorner",{CornerRadius=ud(0,9)},{
						}},
						{"UIStroke",{ApplyStrokeMode=0,Color=c3(55,55,55),LineJoinMode=0,Thickness=1,Transparency=0},{
						}},
						{"ImageButton",{Active=true,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="InputButton",Position=u2(0,0,0,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0)},{
						}},
						{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxasset://fonts/families/RobotoMono.json",400,"Normal"),Name="Text",Position=u2(0.4624,0,0.5,0),Size=u2(0.8652,0,1,0),Text="Enter key here",TextColor3=c3(157,157,157),TextSize=14,TextXAlignment=0,TextYAlignment=1},{
						}},
						{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://94816744026537",ImageColor3=c3(80,80,80),Name="ActivateButton",Position=u2(0.9545,0,0.5,0),Rotation=90,Size=u2(0,20,0,18),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=0},{
						}},
					}},
					{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),AutoButtonColor=false,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://122829741481584",ImageColor3=c3(255,255,255),ImageTransparency=0.8,Name="CopyDiscrod",Position=u2(0.45,0,0.945,0),Size=u2(0,30,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),AutoButtonColor=false,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://109323416778766",ImageColor3=c3(255,255,255),ImageTransparency=0.8,Name="CopySite",Position=u2(0.5,0,0.945,0),Size=u2(0,30,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),AutoButtonColor=false,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://80810391923936",ImageColor3=c3(75,75,75),Name="CopyYoutube",Position=u2(0.55,0,0.945,0),Size=u2(0,30,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"TextButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxasset://fonts/families/SourceSansPro.json",400,"Normal"),Name="KeyInputStopButton",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),Text="Button",TextColor3=c3(0,0,0),TextSize=1,TextTransparency=1,TextXAlignment=2,TextYAlignment=1},{
						{"UICorner",{CornerRadius=ud(0,20)},{
						}},
					}},
					{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://134303082879830",ImageColor3=c3(200,200,200),Name="Icon",Position=u2(0.458,0,0.2204,0),Size=u2(0,82,0,82),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
				}},
				{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="DestructiveConfirmScreen",Position=u2(0,0,0,0),Size=u2(1,0,1,0),Visible=false,ZIndex=15},{
					{"UICorner",{CornerRadius=ud(0,20)},{
					}},
					{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(0,0,0),BackgroundTransparency=0.3,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="DimButton",Position=u2(0,0,0,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0)},{
						{"UICorner",{CornerRadius=ud(0,20)},{
						}},
					}},
					{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(20,20,20),Name="ConfirmWindow",Position=u2(0.5,0,0.5,0),Size=u2(0,389,0,181),ZIndex=5},{
						{"UICorner",{CornerRadius=ud(0,12)},{
						}},
						{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=1,Transparency=0},{
						}},
						{"TextLabel",{AnchorPoint=v2(0.5,0),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="Label",Position=u2(0.3075,0,0.0391,0),Size=u2(0,200,0,33),Text="Reset settings?",TextColor3=c3(200,200,200),TextSize=25,TextXAlignment=0,TextYAlignment=1},{
						}},
						{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ChoiseButtonsHolder",Position=u2(0.5051,0,0.8204,0),Size=u2(1,0,0,46)},{
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=2,Padding=ud(0,10),SortOrder=2,VerticalAlignment=0},{
							}},
							{"ImageButton",{Active=true,AnchorPoint=v2(1,0.5),AutoButtonColor=false,AutomaticSize=1,BackgroundColor3=c3(42,30,30),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=2,Name="YesButton",Position=u2(0.5397,0,0.8225,0),Size=u2(0,72,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
								{"UICorner",{CornerRadius=ud(0,6)},{
								}},
								{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
								}},
								{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.723,0,0.7,0),Size=u2(0,5,1,0),Text="Reset settings",TextColor3=c3(232,138,138),TextSize=16,TextXAlignment=2,TextYAlignment=1},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(75,54,54),LineJoinMode=0,Thickness=1,Transparency=0},{
								}},
								{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://88855827572519",ImageColor3=c3(232,138,138),LayoutOrder=-1,Position=u2(0,0,0,0),Size=u2(0,17,0,17),SliceScale=1,TileSize=u2(1,0,1,0)},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,10),PaddingRight=ud(0,10),PaddingTop=ud(0,0)},{
								}},
							}},
							{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,20),PaddingTop=ud(0,5)},{
							}},
							{"ImageButton",{Active=true,AnchorPoint=v2(1,0.5),AutoButtonColor=false,AutomaticSize=1,BackgroundColor3=c3(36,36,36),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=1,Name="NoButton",Position=u2(0.5397,0,0.8225,0),Size=u2(0,72,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
								{"UICorner",{CornerRadius=ud(0,6)},{
								}},
								{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
								}},
								{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.723,0,0.7,0),Size=u2(0,5,1,0),Text="Cancel",TextColor3=c3(201,201,201),TextSize=16,TextXAlignment=2,TextYAlignment=1},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=1,Transparency=0},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,10),PaddingRight=ud(0,10),PaddingTop=ud(0,0)},{
								}},
							}},
						}},
						{"TextLabel",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Desc",Position=u2(0.049,0,0.26,0),RichText=true,Size=u2(0,340,0,32),Text="Every setting goes back to defaults and this can't be undone. Your saved configs aren't affected.",TextColor3=c3(140,140,140),TextSize=16,TextWrapped=true,TextXAlignment=0,TextYAlignment=0},{
							{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
							}},
						}},
					}},
				}},
				{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="InputboxErrorScreen",Position=u2(0,0,0,0),Size=u2(1,0,1,0),Visible=false,ZIndex=15},{
					{"UICorner",{CornerRadius=ud(0,20)},{
					}},
					{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(0,0,0),BackgroundTransparency=0.3,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="DimButton",Position=u2(0,0,0,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0)},{
						{"UICorner",{CornerRadius=ud(0,20)},{
						}},
					}},
					{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(20,20,20),Name="InputboxWindow",Position=u2(0.5,0,0.5,0),Size=u2(0,389,0,181),ZIndex=5},{
						{"UICorner",{CornerRadius=ud(0,12)},{
						}},
						{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=1,Transparency=0},{
						}},
						{"TextLabel",{AnchorPoint=v2(0.5,0),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="Label",Position=u2(0.3075,0,0.0391,0),Size=u2(0,200,0,33),Text="Rename config.",TextColor3=c3(200,200,200),TextSize=25,TextXAlignment=0,TextYAlignment=1},{
						}},
						{"TextLabel",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Desc",Position=u2(0.049,0,0.2424,0),RichText=true,Size=u2(0,340,0,35),Text="Choose a new name for config-two.",TextColor3=c3(140,140,140),TextSize=16,TextWrapped=true,TextXAlignment=0,TextYAlignment=0},{
							{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
							}},
						}},
						{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ChoiseButtonsHolder",Position=u2(0.5051,0,0.8204,0),Size=u2(1,0,0,46)},{
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=2,Padding=ud(0,10),SortOrder=2,VerticalAlignment=0},{
							}},
							{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,20),PaddingTop=ud(0,5)},{
							}},
							{"ImageButton",{Active=true,AnchorPoint=v2(1,0.5),AutoButtonColor=false,AutomaticSize=1,BackgroundColor3=c3(36,36,36),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=1,Name="CancelButton",Position=u2(0.5397,0,0.8225,0),Size=u2(0,72,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
								{"UICorner",{CornerRadius=ud(0,6)},{
								}},
								{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
								}},
								{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.723,0,0.7,0),Size=u2(0,5,1,0),Text="Cancel",TextColor3=c3(201,201,201),TextSize=16,TextXAlignment=2,TextYAlignment=1},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=1,Transparency=0},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,10),PaddingRight=ud(0,10),PaddingTop=ud(0,0)},{
								}},
							}},
							{"ImageButton",{Active=true,AnchorPoint=v2(1,0.5),AutoButtonColor=false,AutomaticSize=1,BackgroundColor3=c3(20,20,20),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=2,Name="RenameButton",Position=u2(0.5397,0,0.8225,0),Size=u2(0,72,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
								{"UICorner",{CornerRadius=ud(0,6)},{
								}},
								{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
								}},
								{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.723,0,0.7,0),Size=u2(0,5,1,0),Text="Rename",TextColor3=c3(70,70,70),TextSize=16,TextXAlignment=2,TextYAlignment=1},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(40,40,40),LineJoinMode=0,Thickness=1,Transparency=0},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,10),PaddingRight=ud(0,10),PaddingTop=ud(0,0)},{
								}},
							}},
						}},
						{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(16,16,16),Name="InputBox",Position=u2(0.5,0,0.5045,0),Size=u2(0,355,0,26)},{
							{"UICorner",{CornerRadius=ud(0,4)},{
							}},
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(40,40,40),LineJoinMode=0,Thickness=1,Transparency=0},{
							}},
							{"TextLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="CharactersLimitText",Position=u2(0.6423,0,1.0769,0),Size=u2(0,126,0,19),Text="10/32",TextColor3=c3(60,60,60),TextSize=12,TextXAlignment=1,TextYAlignment=1},{
							}},
							{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Text",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),Text="config-two",TextColor3=c3(170,170,170),TextSize=14,TextXAlignment=0,TextYAlignment=1},{
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,10),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
								}},
							}},
						}},
						{"Frame",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ErrorHolder",Position=u2(0.0502,0,0.642,0),Size=u2(0,155,0,14)},{
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=1,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
							}},
							{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://93284547073641",ImageColor3=c3(194,127,127),Position=u2(0,0,0,0),Rotation=180,Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
							{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Position=u2(0.0919,0,0.6364,0),Size=u2(0,10,0,15),Text="That name already exists.",TextColor3=c3(194,127,127),TextSize=13,TextXAlignment=2,TextYAlignment=1},{
							}},
						}},
					}},
				}},
				{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ConfirmScreen",Position=u2(0,0,0,0),Size=u2(1,0,1,0),Visible=false,ZIndex=15},{
					{"UICorner",{CornerRadius=ud(0,20)},{
					}},
					{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(0,0,0),BackgroundTransparency=0.3,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="DimButton",Position=u2(0,0,0,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0)},{
						{"UICorner",{CornerRadius=ud(0,20)},{
						}},
					}},
					{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(20,20,20),Name="ConfirmWindow",Position=u2(0.5,0,0.5,0),Size=u2(0,389,0,181),ZIndex=5},{
						{"UICorner",{CornerRadius=ud(0,12)},{
						}},
						{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=1,Transparency=0},{
						}},
						{"TextLabel",{AnchorPoint=v2(0.5,0),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="Label",Position=u2(0.3075,0,0.0391,0),Size=u2(0,200,0,33),Text="Reset settings?",TextColor3=c3(200,200,200),TextSize=25,TextXAlignment=0,TextYAlignment=1},{
						}},
						{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ChoiseButtonsHolder",Position=u2(0.5051,0,0.8204,0),Size=u2(1,0,0,46)},{
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=2,Padding=ud(0,10),SortOrder=2,VerticalAlignment=0},{
							}},
							{"ImageButton",{Active=true,AnchorPoint=v2(1,0.5),AutoButtonColor=false,AutomaticSize=1,BackgroundColor3=c3(50,50,50),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=2,Name="YesButton",Position=u2(0.5397,0,0.8225,0),Size=u2(0,72,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
								{"UICorner",{CornerRadius=ud(0,6)},{
								}},
								{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
								}},
								{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.723,0,0.7,0),Size=u2(0,5,1,0),Text="Reset settings",TextColor3=c3(170,170,170),TextSize=16,TextXAlignment=2,TextYAlignment=1},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(90,90,90),LineJoinMode=0,Thickness=1,Transparency=0},{
								}},
								{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://88855827572519",ImageColor3=c3(170,170,170),LayoutOrder=-1,Position=u2(0,0,0,0),Size=u2(0,17,0,17),SliceScale=1,TileSize=u2(1,0,1,0)},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,10),PaddingRight=ud(0,10),PaddingTop=ud(0,0)},{
								}},
							}},
							{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,20),PaddingTop=ud(0,5)},{
							}},
							{"ImageButton",{Active=true,AnchorPoint=v2(1,0.5),AutoButtonColor=false,AutomaticSize=1,BackgroundColor3=c3(36,36,36),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=1,Name="NoButton",Position=u2(0.5397,0,0.8225,0),Size=u2(0,72,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
								{"UICorner",{CornerRadius=ud(0,6)},{
								}},
								{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
								}},
								{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.723,0,0.7,0),Size=u2(0,5,1,0),Text="Cancel",TextColor3=c3(201,201,201),TextSize=16,TextXAlignment=2,TextYAlignment=1},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=1,Transparency=0},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,10),PaddingRight=ud(0,10),PaddingTop=ud(0,0)},{
								}},
							}},
						}},
						{"TextLabel",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Desc",Position=u2(0.049,0,0.26,0),RichText=true,Size=u2(0,340,0,32),Text="Every setting goes back to defaults and this can't be undone. Your saved configs aren't affected.",TextColor3=c3(140,140,140),TextSize=16,TextWrapped=true,TextXAlignment=0,TextYAlignment=0},{
							{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
							}},
						}},
					}},
				}},
				{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="InputboxScreen",Position=u2(0,0,0,0),Size=u2(1,0,1,0),Visible=false,ZIndex=15},{
					{"UICorner",{CornerRadius=ud(0,20)},{
					}},
					{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(0,0,0),BackgroundTransparency=0.3,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="DimButton",Position=u2(0,0,0,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0)},{
						{"UICorner",{CornerRadius=ud(0,20)},{
						}},
					}},
					{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(20,20,20),Name="InputboxWindow",Position=u2(0.5,0,0.5,0),Size=u2(0,389,0,181),ZIndex=5},{
						{"UICorner",{CornerRadius=ud(0,12)},{
						}},
						{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=1,Transparency=0},{
						}},
						{"TextLabel",{AnchorPoint=v2(0.5,0),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187368093",700,"Normal"),Name="Label",Position=u2(0.3075,0,0.0391,0),Size=u2(0,200,0,33),Text="Rename config.",TextColor3=c3(200,200,200),TextSize=25,TextXAlignment=0,TextYAlignment=1},{
						}},
						{"TextLabel",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Desc",Position=u2(0.049,0,0.2424,0),RichText=true,Size=u2(0,340,0,35),Text="Choose a new name for config-two.",TextColor3=c3(140,140,140),TextSize=16,TextWrapped=true,TextXAlignment=0,TextYAlignment=0},{
							{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
							}},
						}},
						{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ChoiseButtonsHolder",Position=u2(0.5051,0,0.8204,0),Size=u2(1,0,0,46)},{
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=2,Padding=ud(0,10),SortOrder=2,VerticalAlignment=0},{
							}},
							{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,20),PaddingTop=ud(0,5)},{
							}},
							{"ImageButton",{Active=true,AnchorPoint=v2(1,0.5),AutoButtonColor=false,AutomaticSize=1,BackgroundColor3=c3(36,36,36),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=1,Name="CancelButton",Position=u2(0.5397,0,0.8225,0),Size=u2(0,72,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
								{"UICorner",{CornerRadius=ud(0,6)},{
								}},
								{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
								}},
								{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.723,0,0.7,0),Size=u2(0,5,1,0),Text="Cancel",TextColor3=c3(201,201,201),TextSize=16,TextXAlignment=2,TextYAlignment=1},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=1,Transparency=0},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,10),PaddingRight=ud(0,10),PaddingTop=ud(0,0)},{
								}},
							}},
							{"ImageButton",{Active=true,AnchorPoint=v2(1,0.5),AutoButtonColor=false,AutomaticSize=1,BackgroundColor3=c3(60,60,60),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=2,Name="RenameButton",Position=u2(0.5397,0,0.8225,0),Size=u2(0,72,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
								{"UICorner",{CornerRadius=ud(0,6)},{
								}},
								{"UIListLayout",{FillDirection=0,HorizontalAlignment=0,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
								}},
								{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.723,0,0.7,0),Size=u2(0,5,1,0),Text="Rename",TextColor3=c3(170,170,170),TextSize=16,TextXAlignment=2,TextYAlignment=1},{
								}},
								{"UIStroke",{ApplyStrokeMode=0,Color=c3(90,90,90),LineJoinMode=0,Thickness=1,Transparency=0},{
								}},
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,10),PaddingRight=ud(0,10),PaddingTop=ud(0,0)},{
								}},
							}},
						}},
						{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(16,16,16),Name="InputBox",Position=u2(0.5,0,0.5045,0),Size=u2(0,355,0,26)},{
							{"UICorner",{CornerRadius=ud(0,4)},{
							}},
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(40,40,40),LineJoinMode=0,Thickness=1,Transparency=0},{
							}},
							{"TextLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="CharactersLimitText",Position=u2(0.6423,0,1.0769,0),Size=u2(0,126,0,19),Text="10/32",TextColor3=c3(60,60,60),TextSize=12,TextXAlignment=1,TextYAlignment=1},{
							}},
							{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Text",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),Text="config-two",TextColor3=c3(170,170,170),TextSize=14,TextXAlignment=0,TextYAlignment=1},{
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,10),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
								}},
							}},
						}},
						{"Frame",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="ErrorHolder",Position=u2(0.0502,0,0.642,0),Size=u2(0,155,0,14),Visible=false},{
							{"UIListLayout",{FillDirection=0,HorizontalAlignment=1,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
							}},
							{"ImageLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://93284547073641",ImageColor3=c3(194,127,127),Position=u2(0,0,0,0),Rotation=180,Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
							}},
							{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Position=u2(0.0919,0,0.6364,0),Size=u2(0,10,0,15),Text="That name already exists.",TextColor3=c3(194,127,127),TextSize=13,TextXAlignment=2,TextYAlignment=1},{
							}},
						}},
					}},
				}},
			}},
			{"UIShadow",{BlurRadius=ud(0,100),Color=c3(0,0,0),Offset=u2(0,0,0,0),Spread=u2(0,50,0,50),Transparency=0.18,ZIndex=-1},{
			}},
		}},
		{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),AutoButtonColor=false,BackgroundColor3=c3(255,255,255),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="ShowUiButton",Position=u2(0.5,0,0.0177,0),Size=u2(0,236,0,8),SliceScale=1,TileSize=u2(1,0,1,0)},{
			{"UICorner",{CornerRadius=ud(1,0)},{
			}},
			{"UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0.8627,0.8627,0.8627)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}),Offset=v2(0,0),Rotation=-90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,0)})},{
			}},
			{"UIShadow",{BlurRadius=ud(0,15),Color=c3(255,255,255),Offset=u2(0,0,0,0),Spread=u2(0,15,0,0),Transparency=0,ZIndex=-1},{
			}},
		}},
		{"Folder",{Name="Other"},{
			{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(18,18,18),Name="ColorPicker",Position=u2(0.8421,0,0.5261,0),Size=u2(0,195,0,301),Visible=false,ZIndex=5},{
				{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(143,168,160),Name="ColorPicker",Position=u2(0.5,0,0.3222,0),Size=u2(0,178,0,178)},{
					{"UICorner",{CornerRadius=ud(0,5)},{
					}},
					{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(0,0,0),Name="Dark",Position=u2(0.3933,0,0.5,0),Size=u2(0.7865,0,1,0),ZIndex=2},{
						{"UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}),Offset=v2(0,0),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})},{
						}},
						{"UICorner",{CornerRadius=ud(0,4)},{
						}},
					}},
					{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),Name="White",Position=u2(0.5,0,0.6966,0),Size=u2(1,0,0.6067,0)},{
						{"UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}),Offset=v2(0,0),Rotation=-90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})},{
						}},
						{"UICorner",{CornerRadius=ud(0,5)},{
						}},
					}},
					{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(143,168,160),Name="Knob",Position=u2(0.8487,0,0.1578,0),Size=u2(0,14,0,14)},{
						{"UICorner",{CornerRadius=ud(1,0)},{
						}},
						{"UIStroke",{ApplyStrokeMode=0,Color=c3(255,255,255),LineJoinMode=0,Thickness=1.5,Transparency=0},{
						}},
					}},
				}},
				{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),Name="ColorSlider",Position=u2(0.5,0,0.68,0),Size=u2(0,178,0,20)},{
					{"UICorner",{CornerRadius=ud(0,5)},{
					}},
					{"UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0,0)),ColorSequenceKeypoint.new(0.1157,Color3.new(1,0.6157,0)),ColorSequenceKeypoint.new(0.2504,Color3.new(0.9843,1,0)),ColorSequenceKeypoint.new(0.3834,Color3.new(0.1804,0.9882,0)),ColorSequenceKeypoint.new(0.5665,Color3.new(0,1,0.9333)),ColorSequenceKeypoint.new(0.6995,Color3.new(0,0.0157,1)),ColorSequenceKeypoint.new(0.829,Color3.new(0.851,0,1)),ColorSequenceKeypoint.new(1,Color3.new(1,0,0))}),Offset=v2(0,0),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,0)})},{
					}},
					{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(0,0,0),Name="Knob",Position=u2(0.2,0,0.5,0),Size=u2(0,2,0,15)},{
						{"UIStroke",{ApplyStrokeMode=0,Color=c3(0,0,0),LineJoinMode=0,Thickness=1,Transparency=0.65},{
						}},
					}},
				}},
				{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(143,168,160),Name="TransparencySlider",Position=u2(0.5,0,0.78,0),Size=u2(0,178,0,20)},{
					{"UICorner",{CornerRadius=ud(0,5)},{
					}},
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://107060544057249",ImageColor3=c3(122,122,122),Name="ChessTexture",Position=u2(0.5,0,0.5,0),ScaleType=4,Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0)},{
						{"UICorner",{CornerRadius=ud(0,5)},{
						}},
						{"UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}),Offset=v2(0,0),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.8979,1),NumberSequenceKeypoint.new(1,1)})},{
						}},
					}},
					{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(0,0,0),Name="Knob",Position=u2(0.5,0,0.5,0),Size=u2(0,2,0,15)},{
						{"UIStroke",{ApplyStrokeMode=0,Color=c3(0,0,0),LineJoinMode=0,Thickness=1,Transparency=0.65},{
						}},
					}},
				}},
				{"Frame",{BackgroundColor3=c3(22,22,22),Name="HexUnputHolder",Position=u2(0.0436,0,0.8538,0),Size=u2(0,177,0,38)},{
					{"UICorner",{CornerRadius=ud(0,5)},{
					}},
					{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(18,18,18),Name="HexTextFrame",Position=u2(0.15,0,0.5,0),Size=u2(0,41,0,26)},{
						{"UICorner",{CornerRadius=ud(0,6)},{
						}},
						{"TextLabel",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Position=u2(0,0,0,0),Size=u2(1,0,1,0),Text="HEX",TextColor3=c3(210,210,210),TextSize=18,TextXAlignment=2,TextYAlignment=1},{
						}},
					}},
					{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="HexPrefix",Position=u2(0.3626,0,0.5,0),Size=u2(0,15,1,0),Text="#",TextColor3=c3(190,190,190),TextSize=18,TextXAlignment=2,TextYAlignment=1},{
					}},
					{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Hex",Position=u2(0.4626,0,0.51,0),Size=u2(0,15,1,0),Text="8FA8A0",TextColor3=c3(190,190,190),TextSize=14,TextXAlignment=0,TextYAlignment=1},{
					}},
					{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Transparency",Position=u2(0.673,0,0.5,0),Size=u2(0.4668,15,1,0),Text="40%",TextColor3=c3(190,190,190),TextSize=12,TextXAlignment=1,TextYAlignment=1},{
					}},
				}},
				{"UIStroke",{ApplyStrokeMode=0,Color=c3(40,40,40),LineJoinMode=0,Thickness=1,Transparency=0},{
				}},
				{"UICorner",{CornerRadius=ud(0,8)},{
				}},
			}},
			{"Frame",{AutomaticSize=2,BackgroundColor3=c3(13,13,14),BackgroundTransparency=0.8,Name="KeybindsListTransparentMode",Position=u2(0.562,0,0.4178,0),Size=u2(0,284,0,24),Visible=false,ZIndex=15},{
				{"UICorner",{CornerRadius=ud(0,8)},{
				}},
				{"UIShadow",{BlurRadius=ud(0,50),Color=c3(0,0,0),Offset=u2(0,0,0,0),Spread=u2(0,20,0,10),Transparency=0.7,ZIndex=-1},{
				}},
				{"UIListLayout",{FillDirection=1,HorizontalAlignment=1,Padding=ud(0,10),SortOrder=2,VerticalAlignment=1},{
				}},
				{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="Title",Position=u2(0,0,0,0),Size=u2(1,0,0,30)},{
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://77396420956914",ImageColor3=c3(255,255,255),ImageTransparency=0.2,Name="Icon",Position=u2(0.1,0,0.5,0),Size=u2(0,30,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"TextLabel",{AnchorPoint=v2(0,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Position=u2(0.2,0,0.5,0),Size=u2(0,139,0,50),Text="Keybinds",TextColor3=c3(220,220,220),TextSize=19,TextXAlignment=0,TextYAlignment=1},{
					}},
				}},
				{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="BindsListHolder",Position=u2(0,0,0,0),Size=u2(1,0,0,5)},{
					{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="Bind1",Position=u2(0,0,0,0),Size=u2(1,0,0,40)},{
						{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="BindName",Position=u2(0.3648,0,0.5,0),Size=u2(0,152,0,50),Text="Bind 1",TextColor3=c3(170,170,170),TextSize=18,TextXAlignment=0,TextYAlignment=1},{
						}},
						{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="ButtonBind",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0)},{
						}},
						{"Frame",{AnchorPoint=v2(1,0.5),AutomaticSize=1,BackgroundColor3=c3(27,27,27),Name="ButtonKey",Position=u2(0.9,0,0.5,0),Size=u2(0,30,0,30)},{
							{"UICorner",{CornerRadius=ud(0,8)},{
							}},
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(50,50,50),LineJoinMode=0,Thickness=1.5,Transparency=0},{
							}},
							{"TextLabel",{AnchorPoint=v2(1,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Bind",Position=u2(1,0,0.5,0),Size=u2(0,30,0,30),Text="Ctrl + A",TextColor3=c3(200,200,200),TextSize=18,TextXAlignment=2,TextYAlignment=1},{
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,5),PaddingRight=ud(0,5),PaddingTop=ud(0,0)},{
								}},
							}},
							{"UIListLayout",{FillDirection=1,HorizontalAlignment=1,Padding=ud(0,0),SortOrder=2,VerticalAlignment=1},{
							}},
						}},
					}},
					{"UIListLayout",{FillDirection=1,HorizontalAlignment=1,Padding=ud(0,3),SortOrder=2,VerticalAlignment=1},{
					}},
				}},
				{"UIPadding",{PaddingBottom=ud(0,10),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,10)},{
				}},
			}},
			{"Frame",{AutomaticSize=2,BackgroundColor3=c3(13,13,14),Name="KeybindsList",Position=u2(0.2635,0,0.4155,0),Size=u2(0,284,0,24),Visible=false,ZIndex=15},{
				{"UICorner",{CornerRadius=ud(0,8)},{
				}},
				{"UIShadow",{BlurRadius=ud(0,50),Color=c3(0,0,0),Offset=u2(0,0,0,0),Spread=u2(0,20,0,10),Transparency=0,ZIndex=-1},{
				}},
				{"UIListLayout",{FillDirection=1,HorizontalAlignment=1,Padding=ud(0,10),SortOrder=2,VerticalAlignment=1},{
				}},
				{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="Title",Position=u2(0,0,0,0),Size=u2(1,0,0,30)},{
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://77396420956914",ImageColor3=c3(205,205,205),Name="Icon",Position=u2(0.1,0,0.5,0),Size=u2(0,30,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"TextLabel",{AnchorPoint=v2(0,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Position=u2(0.2,0,0.5,0),Size=u2(0,139,0,50),Text="Keybinds",TextColor3=c3(220,220,220),TextSize=19,TextXAlignment=0,TextYAlignment=1},{
					}},
				}},
				{"UIPadding",{PaddingBottom=ud(0,10),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,10)},{
				}},
				{"Frame",{AutomaticSize=2,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="BindsListHolder",Position=u2(0,0,0,0),Size=u2(1,0,0,5)},{
					{"Frame",{BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Name="Bind1",Position=u2(0,0,0,0),Size=u2(1,0,0,40)},{
						{"TextLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="BindName",Position=u2(0.3648,0,0.5,0),Size=u2(0,152,0,50),Text="Bind 1",TextColor3=c3(170,170,170),TextSize=18,TextXAlignment=0,TextYAlignment=1},{
						}},
						{"ImageButton",{Active=true,AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,Name="ButtonBind",Position=u2(0.5,0,0.5,0),Size=u2(1,0,1,0),SliceScale=1,TileSize=u2(1,0,1,0)},{
						}},
						{"Frame",{AnchorPoint=v2(1,0.5),AutomaticSize=1,BackgroundColor3=c3(27,27,27),Name="ButtonKey",Position=u2(0.9,0,0.5,0),Size=u2(0,30,0,30)},{
							{"UICorner",{CornerRadius=ud(0,8)},{
							}},
							{"UIStroke",{ApplyStrokeMode=0,Color=c3(50,50,50),LineJoinMode=0,Thickness=1.5,Transparency=0},{
							}},
							{"TextLabel",{AnchorPoint=v2(1,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Bind",Position=u2(1,0,0.5,0),Size=u2(0,30,0,30),Text="Ctrl + A",TextColor3=c3(200,200,200),TextSize=18,TextXAlignment=2,TextYAlignment=1},{
								{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,5),PaddingRight=ud(0,5),PaddingTop=ud(0,0)},{
								}},
							}},
							{"UIListLayout",{FillDirection=1,HorizontalAlignment=1,Padding=ud(0,0),SortOrder=2,VerticalAlignment=1},{
							}},
						}},
					}},
					{"UIListLayout",{FillDirection=1,HorizontalAlignment=1,Padding=ud(0,3),SortOrder=2,VerticalAlignment=1},{
					}},
				}},
			}},
			{"Frame",{AutomaticSize=3,BackgroundColor3=c3(13,13,13),Name="Dropdown",Position=u2(0.695,0,0.582,0),Size=u2(0,20,0,32),Visible=false},{
				{"UICorner",{CornerRadius=ud(0,6)},{
				}},
				{"UIPadding",{PaddingBottom=ud(0,6),PaddingLeft=ud(0,5),PaddingRight=ud(0,5),PaddingTop=ud(0,6)},{
				}},
				{"UIShadow",{BlurRadius=ud(0,8),Color=c3(0,0,0),Offset=u2(0,0,0,0),Spread=u2(0,0,0,0),Transparency=0.2,ZIndex=-1},{
				}},
				{"UIListLayout",{FillDirection=1,HorizontalAlignment=2,Padding=ud(0,5),SortOrder=2,VerticalAlignment=0},{
				}},
				{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(20,20,20),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=-1,Name="Item1",Position=u2(0,0,0,0),Size=u2(1,0,0,25),SliceScale=1,TileSize=u2(1,0,1,0)},{
					{"ImageLabel",{AnchorPoint=v2(0,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://84358705612028",ImageColor3=c3(255,255,255),ImageTransparency=0.3,Name="Check",Position=u2(0,0,0.5,0),Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0),Visible=false},{
					}},
					{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,7),PaddingRight=ud(0,30),PaddingTop=ud(0,0)},{
					}},
					{"UICorner",{CornerRadius=ud(0,4)},{
					}},
					{"TextLabel",{AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0,0,0,0),Size=u2(0,5,0,25),Text="Item 1 (hovered)",TextColor3=c3(215,215,215),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
					}},
				}},
			}},
			{"Frame",{AutomaticSize=2,BackgroundColor3=c3(30,30,30),Name="ConfigDropdownMenu",Position=u2(0.5262,0,0.4167,0),Size=u2(0,153,0,10),Visible=false},{
				{"UIStroke",{ApplyStrokeMode=0,Color=c3(50,50,50),LineJoinMode=0,Thickness=1,Transparency=0},{
				}},
				{"UICorner",{CornerRadius=ud(0,12)},{
				}},
				{"UIShadow",{BlurRadius=ud(0,30),Color=c3(0,0,0),Offset=u2(0,0,0,0),Spread=u2(0,5,0,5),Transparency=0.53,ZIndex=-1},{
				}},
				{"ImageButton",{Active=true,AutoButtonColor=false,BackgroundColor3=c3(45,45,45),Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=1,Name="LoadButton",Position=u2(0,0,0.1,0),Size=u2(0,145,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
					{"UICorner",{CornerRadius=ud(0,8)},{
					}},
					{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.25,0,0.5,0),Size=u2(0,5,1,0),Text="Load",TextColor3=c3(180,180,180),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
					}},
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,Image="rbxassetid://129861047513547",ImageColor3=c3(200,200,200),LayoutOrder=-1,Name="Icon",Position=u2(0.125,0,0.5,0),Size=u2(0,20,0,20),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"UIPadding",{PaddingBottom=ud(0,2),PaddingLeft=ud(0,8),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
					}},
				}},
				{"UIListLayout",{FillDirection=1,HorizontalAlignment=0,Padding=ud(0,2),SortOrder=2,VerticalAlignment=1},{
				}},
				{"ImageButton",{Active=true,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=3,Name="RenameButton",Position=u2(0,0,0.1,0),Size=u2(0,153,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
					{"UICorner",{CornerRadius=ud(0,8)},{
					}},
					{"UIPadding",{PaddingBottom=ud(0,2),PaddingLeft=ud(0,8),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
					}},
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,Image="rbxassetid://129818828426508",ImageColor3=c3(140,140,140),LayoutOrder=-1,Name="Icon",Position=u2(0.1252,0,0.5,0),Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.2502,0,0.5,0),Size=u2(0,5,1,0),Text="Rename",TextColor3=c3(140,140,140),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
					}},
				}},
				{"ImageButton",{Active=true,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=4,Name="DuplicateButton",Position=u2(0,0,0.1,0),Size=u2(0,153,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
					{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.2502,0,0.5,0),Size=u2(0,5,1,0),Text="Duplicate",TextColor3=c3(140,140,140),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
					}},
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,Image="rbxassetid://118944771595983",ImageColor3=c3(140,140,140),LayoutOrder=-1,Name="Icon",Position=u2(0.1252,0,0.5,0),Size=u2(0,18,0,18),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"UIPadding",{PaddingBottom=ud(0,2),PaddingLeft=ud(0,8),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
					}},
					{"UICorner",{CornerRadius=ud(0,8)},{
					}},
				}},
				{"ImageButton",{Active=true,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=10,Name="DeleteButton",Position=u2(0,0,0.1,0),Size=u2(0,153,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
					{"UICorner",{CornerRadius=ud(0,8)},{
					}},
					{"UIPadding",{PaddingBottom=ud(0,2),PaddingLeft=ud(0,8),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
					}},
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,Image="rbxassetid://90320116313568",ImageColor3=c3(196,122,122),LayoutOrder=-1,Name="Icon",Position=u2(0.1252,0,0.5,0),Size=u2(0,16,0,16),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.2502,0,0.5,0),Size=u2(0,5,1,0),Text="Delete",TextColor3=c3(196,122,122),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
					}},
				}},
				{"Frame",{BackgroundColor3=c3(40,40,40),LayoutOrder=2,Name="Separator",Position=u2(0,0,0,0),Size=u2(1.02,0,0,2)},{
				}},
				{"UIPadding",{PaddingBottom=ud(0,5),PaddingLeft=ud(0,5),PaddingRight=ud(0,10),PaddingTop=ud(0,5)},{
				}},
				{"ImageButton",{Active=true,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=9,Name="ResetButton",Position=u2(0,0,0.1,0),Size=u2(0,153,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
					{"UICorner",{CornerRadius=ud(0,8)},{
					}},
					{"UIPadding",{PaddingBottom=ud(0,2),PaddingLeft=ud(0,8),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
					}},
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,Image="rbxassetid://99227055213666",ImageColor3=c3(140,140,140),LayoutOrder=-1,Name="Icon",Position=u2(0.1252,0,0.5,0),Size=u2(0,15,0,15),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.2502,0,0.5,0),Size=u2(0,5,1,0),Text="Reset config",TextColor3=c3(140,140,140),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
					}},
				}},
				{"ImageButton",{Active=true,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=7,Name="ExportCodeButton",Position=u2(0,0,0.1,0),Size=u2(0,153,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
					{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.2502,0,0.5,0),Size=u2(0,5,1,0),Text="Export code",TextColor3=c3(140,140,140),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
					}},
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,Image="rbxassetid://72127232048129",ImageColor3=c3(140,140,140),LayoutOrder=-1,Name="Icon",Position=u2(0.1252,0,0.5,0),Size=u2(0,16,0,16),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"UIPadding",{PaddingBottom=ud(0,2),PaddingLeft=ud(0,8),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
					}},
					{"UICorner",{CornerRadius=ud(0,8)},{
					}},
				}},
				{"ImageButton",{Active=true,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="",ImageColor3=c3(255,255,255),ImageTransparency=1,LayoutOrder=5,Name="OverwriteButton",Position=u2(0,0,0.1,0),Size=u2(0,153,0,30),SliceScale=1,TileSize=u2(1,0,1,0)},{
					{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Name="Name",Position=u2(0.2502,0,0.5,0),Size=u2(0,5,1,0),Text="Overwrite",TextColor3=c3(140,140,140),TextSize=15,TextXAlignment=2,TextYAlignment=1},{
					}},
					{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(0,0,0),BackgroundTransparency=1,Image="rbxassetid://121046347967510",ImageColor3=c3(140,140,140),LayoutOrder=-1,Name="Icon",Position=u2(0.1252,0,0.5,0),Size=u2(0,18,0,18),SliceScale=1,TileSize=u2(1,0,1,0)},{
					}},
					{"UIPadding",{PaddingBottom=ud(0,2),PaddingLeft=ud(0,8),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
					}},
					{"UICorner",{CornerRadius=ud(0,8)},{
					}},
				}},
				{"Frame",{BackgroundColor3=c3(40,40,40),LayoutOrder=6,Name="Separator2",Position=u2(0,0,0,0),Size=u2(1.02,0,0,2)},{
				}},
				{"Frame",{BackgroundColor3=c3(40,40,40),LayoutOrder=8,Name="Separator3",Position=u2(0,0,0,0),Size=u2(1.02,0,0,2)},{
				}},
			}},
		}},
		{"Frame",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(14,14,14),ClipsDescendants=true,Name="NotificationGreen",Position=u2(0.012,0,0.14,0),Size=u2(0,250,0,32)},{
			{"UICorner",{CornerRadius=ud(0,8)},{
			}},
			{"UIPadding",{PaddingBottom=ud(0,0),PaddingLeft=ud(0,0),PaddingRight=ud(0,0),PaddingTop=ud(0,0)},{
			}},
			{"Frame",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(143,179,139),Name="Dot",Position=u2(0,20,0.5,0),Size=u2(0,6,0,6)},{
				{"UICorner",{CornerRadius=ud(1,0)},{
				}},
			}},
			{"TextLabel",{AnchorPoint=v2(0,0.5),AutomaticSize=1,BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,FontFace=ft("rbxassetid://12187365364",400,"Normal"),Position=u2(0,35,0.5,0),Size=u2(-0.471,200,1,0),Text="All ok",TextColor3=c3(191,191,191),TextSize=16,TextXAlignment=0,TextYAlignment=1},{
				{"UIPadding",{PaddingBottom=ud(0,2),PaddingLeft=ud(0,0),PaddingRight=ud(0,17),PaddingTop=ud(0,0)},{
				}},
			}},
			{"UIStroke",{ApplyStrokeMode=0,Color=c3(60,60,60),LineJoinMode=0,Thickness=1,Transparency=0},{
			}},
			{"ImageLabel",{AnchorPoint=v2(0.5,0.5),BackgroundColor3=c3(255,255,255),BackgroundTransparency=1,Image="rbxassetid://130321961257203",ImageColor3=c3(255,255,255),ImageTransparency=0.85,Name="WhiteGlow",Position=u2(0.5,0,-1.5,0),Size=u2(0,364,0,364),SliceScale=1,TileSize=u2(1,0,1,0),ZIndex=-1},{
			}},
		}},
	}}------------------------------------------------------------------------------------------------------------------------
--  Assemble interface
------------------------------------------------------------------------------------------------------------------------

local function getGuiParent(): Instance
	if useStudio and LocalPlayer then
		return LocalPlayer:WaitForChild("PlayerGui")
	end
	local ok, hui = pcall(function()
		return gethui and gethui() or nil
	end)
	if ok and typeof(hui) == "Instance" then
		return hui
	end
	local okCore = pcall(function()
		local probe = Instance.new("Folder")
		probe.Parent = CoreGui
		probe:Destroy()
	end)
	if okCore then
		return CoreGui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local ScreenGui = buildNode(GuiData, nil) :: ScreenGui
ScreenGui.Name = "Amphibia_" .. HttpService:GenerateGUID(false):sub(1, 8)
pcall(function() ScreenGui.IgnoreGuiInset = true end)
if syn and syn.protect_gui then
	pcall(syn.protect_gui, ScreenGui)
end
ScreenGui.Parent = getGuiParent()

local Main = ScreenGui:WaitForChild("MainBackground")
local Header = Main:WaitForChild("HeaderFrame")
local Info = Main:WaitForChild("InfoFrame")
local TabsFrame = Main:WaitForChild("TabsFrame")
local TabsHolder = TabsFrame:WaitForChild("Holder")
local Pages = Main:WaitForChild("Pages")
local ScreensFolder = Main:WaitForChild("Screens")
local OtherFolder = ScreenGui:WaitForChild("Other")
local ShowUiButton = ScreenGui:WaitForChild("ShowUiButton")

-- Где на экране находится точка (0,0) нашего канваса. Работает независимо от IgnoreGuiInset.
local function canvasOrigin(): Vector2
	return ScreenGui.AbsolutePosition
end

-- AbsolutePosition любого элемента -> координаты внутри канваса
local function screenPointFor(absolutePosition: Vector2): Vector2
	return absolutePosition - canvasOrigin()
end

-- позиция мыши -> координаты внутри канваса
local function mousePoint(): Vector2
	local location = UserInputService:GetMouseLocation()
	local point = Vector2.new(location.X, location.Y)
	if ScreenGui.IgnoreGuiInset then
		point += GuiService:GetGuiInset()
	end
	return point
end

local LoadingScreen = ScreensFolder:WaitForChild("LoadingScreen")
local EnterKeyScreen = ScreensFolder:WaitForChild("EnterKeyScreen")
local ConfirmScreen = ScreensFolder:WaitForChild("ConfirmScreen")
local DestructiveConfirmScreen = ScreensFolder:WaitForChild("DestructiveConfirmScreen")
local InputboxScreen = ScreensFolder:WaitForChild("InputboxScreen")
local InputboxErrorScreen = ScreensFolder:WaitForChild("InputboxErrorScreen")

local ColorPickerWindow = OtherFolder:WaitForChild("ColorPicker")
local KeybindsListFrame = OtherFolder:WaitForChild("KeybindsList")
local KeybindsListTransparentFrame = OtherFolder:WaitForChild("KeybindsListTransparentMode")
local DropdownWindowTemplate = OtherFolder:WaitForChild("Dropdown")
local ConfigDropdownMenu = OtherFolder:WaitForChild("ConfigDropdownMenu")

local ConfigPage = Pages:WaitForChild("TabConfig")
local PageTemplateSource = Pages:WaitForChild("TabPlayer")

-- Adaptive scale + intro scale live on one UIScale.
local MainScale = Instance.new("UIScale")
MainScale.Parent = Main
local BaseScale = 1
do
	local camera = workspace.CurrentCamera
	local function updateScale()
		if not camera then return end
		local viewport = camera.ViewportSize
		BaseScale = math.clamp(math.min(viewport.X / 1060, viewport.Y / 690), 0.62, 1)
	end
	updateScale()
	if camera then
		connect(camera:GetPropertyChangedSignal("ViewportSize"), updateScale)
	end
end

------------------------------------------------------------------------------------------------------------------------
--  Template extraction — pull the showcase elements out as blueprints, then clear the example content.
------------------------------------------------------------------------------------------------------------------------

local DROPDOWN_GAP = 6      	  -- фиксированный отступ от нижней грани чипа
local DROPDOWN_FLIP = false 	  -- true — разворачивать вверх, если не влезает вниз
local DROPDOWN_MAX_HEIGHT = 220   -- полная высота окна, ≈ 7 пунктов
local DROPDOWN_ITEM_HEIGHT = 25
local DROPDOWN_ITEM_GAP = 5
local DROPDOWN_PADDING = 12       -- UIPadding окна: 6 сверху + 6 снизу

local CONFIG_MENU = {
	Width = 153,
	ItemHeight = 25,
	ItemGap = 2,
	PadX = 5,
	PadY = 4,             -- было 6
	SeparatorHeight = 1,
	SeparatorInset = 8,   -- на сколько линия короче меню с каждой стороны
	IconX = 14,           -- центр иконки от левого края кнопки
	TextX = 28,           -- левый край текста
}

local Templates = {}

;(function()
	local scroller = PageTemplateSource:WaitForChild("ScrollingFrame")
	local leftColumn = scroller:WaitForChild("LeftColumn")
	local rightColumn = scroller:WaitForChild("RightColumn")

	local togglesSection = leftColumn:WaitForChild("TogglesSection")
	Templates.Toggle = togglesSection.ButtonsHolderFrame.ToggleEnabled:Clone()
	Templates.Button = leftColumn.ButtonsSection.ButtonsHolderFrame.Button:Clone()
	Templates.NumberPicker = leftColumn.NumberPickerSection.ButtonsHolderFrame.NumberPicker:Clone()
	Templates.Textbox = leftColumn.TextboxSection.ButtonsHolderFrame.Textbox:Clone()
	Templates.Slider = rightColumn.SlidersSection.ButtonsHolderFrame.SliderPercent:Clone()
	Templates.ColorPicker = rightColumn.ColorPickersSection.ButtonsHolderFrame.ColorPicker:Clone()
	Templates.Selector = rightColumn.SelectorSection.ButtonsHolderFrame.Selector:Clone()
	Templates.SelectorOption = Templates.Selector.SelectionsHolder.Selection1:Clone()
	Templates.Selector.SelectionsHolder.Selection1:Destroy()
	Templates.Dropdown = rightColumn.DropdownSection.ButtonsHolderFrame.Dropdown:Clone()

	local sectionTemplate = togglesSection:Clone()
	for _, child in ipairs(sectionTemplate.ButtonsHolderFrame:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	Templates.Section = sectionTemplate

	-- category / tab buttons
	local categorySource = TabsHolder:WaitForChild("MainCategory")
	Templates.TabButton = categorySource.TabsHolder.WorldTabButton:Clone()
	Templates.TabButton.Name = "TabButton"
	local categoryTemplate = categorySource:Clone()
	for _, child in ipairs(categoryTemplate.TabsHolder:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	Templates.Category = categoryTemplate
	categorySource:Destroy()

	-- page template (empty columns). The design file left the column layouts in a horizontal
	-- dev-preview state, so rebuild them: sections must flow top-to-bottom.
	local pageTemplate = PageTemplateSource:Clone()
	local ptScroll = pageTemplate.ScrollingFrame
	pcall(function() ptScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
	pcall(function() ptScroll.CanvasSize = UDim2.new(0, 0, 0, 0) end)
	for _, column in ipairs({ ptScroll.LeftColumn, ptScroll.RightColumn }) do
		for _, child in ipairs(column:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local layout = column:FindFirstChildOfClass("UIListLayout")
		if not layout then
			layout = Instance.new("UIListLayout")
			layout.Parent = column
		end
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 20)
		local padding = column:FindFirstChildOfClass("UIPadding")
		if not padding then
			padding = Instance.new("UIPadding")
			padding.Parent = column
		end
		padding.PaddingTop = UDim.new(0, 4)
		padding.PaddingBottom = UDim.new(0, 30)
		pcall(function() column.AutomaticSize = Enum.AutomaticSize.Y end)
		column.Size = UDim2.new(0.5, 0, 0, 0)
	end
	pageTemplate.Visible = false
	Templates.Page = pageTemplate

	-- dropdown row: the authored chip auto-sized in every direction and inflated once overlay
	-- buttons were added — rebuild it deterministically (fixed height, measured width)
	do
		local selectedFrame = Templates.Dropdown.DropdownSelectedFrame
		pcall(function() selectedFrame.AutomaticSize = Enum.AutomaticSize.None end)
		local chipLayout = selectedFrame:FindFirstChildOfClass("UIListLayout")
		if chipLayout then chipLayout:Destroy() end
		local chipPadding = selectedFrame:FindFirstChildOfClass("UIPadding")
		if chipPadding then chipPadding:Destroy() end
		selectedFrame.Size = UDim2.new(0, 110, 0, 25)

		local icon = selectedFrame.Icon
		icon.AnchorPoint = Vector2.new(1, 0.5)
		icon.Position = UDim2.new(1, -7, 0.5, 0)
		icon.Size = UDim2.new(0, 15, 0, 15)

		local picked = selectedFrame.Picked
		pcall(function() picked.AutomaticSize = Enum.AutomaticSize.None end)
		picked.AnchorPoint = Vector2.new(0, 0.5)
		picked.Position = UDim2.new(0, 7, 0.5, 0)
		picked.Size = UDim2.new(1, -31, 1, 0)
		picked.TextXAlignment = Enum.TextXAlignment.Right
		pcall(function() picked.TextTruncate = Enum.TextTruncate.AtEnd end)

		local pickedMeasure = picked:Clone()
		pickedMeasure.Name = "PickedMeasure"
		pickedMeasure.TextTransparency = 1
		pickedMeasure.Position = UDim2.new(0, 0, 0, -200)
		pickedMeasure.Size = UDim2.new(0, 4, 0, 25)
		pcall(function() pickedMeasure.TextTruncate = Enum.TextTruncate.None end)
		pickedMeasure.Parent = selectedFrame
	end

	-- config context menu: the design left mismatched button sizes and a pre-hovered Load —
	-- normalize to the authored 153px width with identical entries
	do
		local menu = ConfigDropdownMenu
		pcall(function() menu.AutomaticSize = Enum.AutomaticSize.Y end)
		menu.Size = UDim2.new(0, CONFIG_MENU.Width, 0, 10)

		local menuLayout = menu:FindFirstChildOfClass("UIListLayout")
		if not menuLayout then
			menuLayout = Instance.new("UIListLayout")
			menuLayout.Parent = menu
		end
		menuLayout.FillDirection = Enum.FillDirection.Vertical
		menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
		menuLayout.Padding = UDim.new(0, CONFIG_MENU.ItemGap)

		local menuPadding = menu:FindFirstChildOfClass("UIPadding")
		if not menuPadding then
			menuPadding = Instance.new("UIPadding")
			menuPadding.Parent = menu
		end
		menuPadding.PaddingLeft = UDim.new(0, CONFIG_MENU.PadX)
		menuPadding.PaddingRight = UDim.new(0, CONFIG_MENU.PadX)
		menuPadding.PaddingTop = UDim.new(0, CONFIG_MENU.PadY)
		menuPadding.PaddingBottom = UDim.new(0, CONFIG_MENU.PadY)

		for _, child in ipairs(menu:GetChildren()) do
			if child:IsA("ImageButton") then
				child.Size = UDim2.new(1, 0, 0, CONFIG_MENU.ItemHeight)
				child.BackgroundTransparency = 1

				-- позиционируем иконку и текст в пикселях, а не в долях ширины
				local buttonPadding = child:FindFirstChildOfClass("UIPadding")
				if buttonPadding then
					buttonPadding:Destroy()
				end

				local icon = child:FindFirstChild("Icon")
				if icon then
					icon.AnchorPoint = Vector2.new(0.5, 0.5)
					icon.Position = UDim2.new(0, CONFIG_MENU.IconX, 0.5, 0)
				end

				local label = child:FindFirstChild("Name")
				if label then
					pcall(function() label.AutomaticSize = Enum.AutomaticSize.None end)
					label.AnchorPoint = Vector2.new(0, 0.5)
					label.Position = UDim2.new(0, CONFIG_MENU.TextX, 0.5, 0)
					label.Size = UDim2.new(1, -CONFIG_MENU.TextX - 6, 1, 0)
					label.TextXAlignment = Enum.TextXAlignment.Left
					pcall(function() label.TextTruncate = Enum.TextTruncate.AtEnd end)
				end
			elseif child:IsA("Frame") then
				child.Size = UDim2.new(1, -CONFIG_MENU.SeparatorInset * 2, 0, CONFIG_MENU.SeparatorHeight)
			end
		end

		local resetEntry = menu:FindFirstChild("ResetButton")
		local resetLabel = resetEntry and resetEntry:FindFirstChild("Name")
		if resetLabel then
			resetLabel.Text = "Reset settings"
		end
	end

	-- config entry
	local configScroller = ConfigPage.ConfigsBg.ScrollingFrame
	Templates.ConfigEntry = configScroller.Config1:Clone()
	configScroller.Config1:Destroy()

	-- keybind rows
	Templates.Bind = KeybindsListFrame.BindsListHolder.Bind1:Clone()
	for _, frame in ipairs({ KeybindsListFrame, KeybindsListTransparentFrame }) do
		for _, child in ipairs(frame.BindsListHolder:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end

	-- dropdown item
	Templates.DropdownItem = DropdownWindowTemplate.Item1:Clone()
	DropdownWindowTemplate.Item1:Destroy()
	DropdownWindowTemplate.Visible = false

	-- notification
	Templates.Notification = ScreenGui.NotificationGreen:Clone()
	Templates.Notification.Name = "Notification"
	ScreenGui.NotificationGreen:Destroy()

	-- the showcase page is now the live template; remove it from Pages
	PageTemplateSource:Destroy()
	ConfigPage.Visible = false
	ColorPickerWindow.Visible = false
	ConfigDropdownMenu.Visible = false
end)()

------------------------------------------------------------------------------------------------------------------------
--  Group fade helper (screens & sections)
------------------------------------------------------------------------------------------------------------------------

-- local FadeCache = setmetatable({}, { __mode = "k" })

local FADE_PROPS = {
	Frame = { "BackgroundTransparency" },
	ScrollingFrame = { "BackgroundTransparency" },
	TextLabel = { "BackgroundTransparency", "TextTransparency" },
	TextButton = { "BackgroundTransparency", "TextTransparency" },
	TextBox = { "BackgroundTransparency", "TextTransparency" },
	ImageLabel = { "BackgroundTransparency", "ImageTransparency" },
	ImageButton = { "BackgroundTransparency", "ImageTransparency" },
	UIStroke = { "Transparency" },
	UIShadow = { "Transparency" },
}

local FADE_ATTR = "_amphFade_"

local function fadeTargets(root: Instance)
	local targets = {}
	local function collect(inst)
		local props = FADE_PROPS[inst.ClassName]
		if props then
			local cache = {}
			for _, prop in ipairs(props) do
				local stored = inst:GetAttribute(FADE_ATTR .. prop)
				if stored == nil then
					local ok, value = pcall(function() return inst[prop] end)
					if ok then
						stored = value
						pcall(function() inst:SetAttribute(FADE_ATTR .. prop, value) end)
					end
				end
				if stored ~= nil then
					cache[prop] = stored
				end
			end
			targets[inst] = cache
		end
		for _, child in ipairs(inst:GetChildren()) do
			collect(child)
		end
	end
	collect(root)
	return targets
end
local function fadeOut(root: GuiObject, duration: number?, keepVisible: boolean?)
	duration = duration or 0.28
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for inst, cache in pairs(fadeTargets(root)) do
		local goal = {}
		for prop in pairs(cache) do
			goal[prop] = 1
		end
		tween(inst, info, goal)
	end
	task.delay(duration, function()
		if not keepVisible then
			root.Visible = false
		end
	end)
end

local function fadeIn(root: GuiObject, duration: number?)
	duration = duration or 0.3
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local targets = fadeTargets(root)
	for inst, cache in pairs(targets) do
		for prop in pairs(cache) do
			pcall(function() inst[prop] = 1 end)
		end
	end
	root.Visible = true
	for inst, cache in pairs(targets) do
		local goal = {}
		for prop in pairs(cache) do
			goal[prop] = cache[prop]
		end
		tween(inst, info, goal)
	end
end

local function primeFade(root: GuiObject)
	fadeTargets(root) -- capture originals while authored values are intact
end

for _, screen in ipairs({ LoadingScreen, EnterKeyScreen, ConfirmScreen, DestructiveConfirmScreen, InputboxScreen, InputboxErrorScreen }) do
	primeFade(screen)
end

------------------------------------------------------------------------------------------------------------------------
--  Notifications
------------------------------------------------------------------------------------------------------------------------

local NotifyHolder = Instance.new("Frame")
NotifyHolder.Name = "Notifications"
NotifyHolder.BackgroundTransparency = 1
NotifyHolder.Position = UDim2.new(0, 18, 0, 112)
NotifyHolder.Size = UDim2.new(0, 420, 1, -60)
NotifyHolder.ZIndex = 50
NotifyHolder.Parent = ScreenGui

local NotifyLayout = Instance.new("UIListLayout")
NotifyLayout.FillDirection = Enum.FillDirection.Vertical
NotifyLayout.Padding = UDim.new(0, 8)
NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifyLayout.Parent = NotifyHolder

local NOTIFY_COLORS = {
	Red = Color3.fromRGB(224, 122, 114),
	Green = Color3.fromRGB(143, 179, 139),
	Yellow = Color3.fromRGB(179, 177, 105),
}

local notifyOrder = 0

function AmphibiaLibrary:Notify(settings)
	settings = settings or {}
	local content = settings.Content or settings.Title or "Notification"
	local color = NOTIFY_COLORS[settings.Color or "Green"] or NOTIFY_COLORS.Green
	local duration = settings.Duration or 4

	notifyOrder += 1

	local wrapper = Instance.new("Frame")
	wrapper.Name = "Entry"
	wrapper.BackgroundTransparency = 1
	wrapper.ClipsDescendants = false
	wrapper.Size = UDim2.new(1, 0, 0, 0)
	wrapper.LayoutOrder = notifyOrder
	wrapper.ZIndex = 50
	wrapper.Parent = NotifyHolder

	local notification = Templates.Notification:Clone()
	notification.AnchorPoint = Vector2.new(0, 0.5)
	notification.Position = UDim2.new(0, -460, 0.5, 0)
	notification.Dot.BackgroundColor3 = TC(color)
	notification.TextLabel.Text = tostring(content)
	notification.ZIndex = 51
	notification.Visible = true
	themeRegisterDeep(notification)
	themeApplyDeep(notification)
	notification.Dot.BackgroundColor3 = TC(color)
	notification.Parent = wrapper

	tween(wrapper, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 32) })
	task.delay(0.05, function()
		tween(notification, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0.5, 0) })
	end)

	task.delay(duration, function()
		if not notification.Parent then return end
		tween(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = UDim2.new(0, -460, 0.5, 0) })
		task.wait(0.24)
		tween(wrapper, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 0) })
		task.wait(0.18)
		wrapper:Destroy()
	end)

	return notification
end

local secureWarnings = {}
local function secureNotify(wType, color, content)
	if secureWarnings[wType] then return end
	secureWarnings[wType] = true
	task.spawn(function()
		AmphibiaLibrary:Notify({ Color = color, Content = content, Duration = 8 })
	end)
end

------------------------------------------------------------------------------------------------------------------------
--  Status bar
------------------------------------------------------------------------------------------------------------------------

local StatusDot = Info:WaitForChild("DotConnected")
local StatusText = Info:WaitForChild("ConnectStatusText")

function AmphibiaLibrary:SetStatus(text: string?, connected: boolean?)
	if connected == nil then connected = true end
	StatusText.Text = text or (connected and "Connected" or "Disconnected")
	local dotColor = connected and Color3.fromRGB(170, 170, 170) or Color3.fromRGB(170, 90, 90)
	local textColor = connected and Color3.fromRGB(190, 190, 190) or Color3.fromRGB(170, 90, 90)
	tween(StatusDot, "Out", { BackgroundColor3 = TC(dotColor) })
	tween(StatusText, "Out", { TextColor3 = TC(textColor) })
	local shadow = StatusDot:FindFirstChildOfClass("UIShadow")
	if shadow then
		tween(shadow, "Out", {
			Color = connected and TC(Color3.fromRGB(200, 200, 200)) or Color3.fromRGB(190, 100, 100),
		})
	end
end

-- Small "pulse" used when configs are saved etc.
local function statusPulse(text: string)
	local previous = StatusText.Text
	AmphibiaLibrary:SetStatus(text, true)
	task.delay(1.6, function()
		if StatusText.Text == text then
			AmphibiaLibrary:SetStatus(previous, true)
		end
	end)
end

------------------------------------------------------------------------------------------------------------------------
--  Modal screens — confirm & input prompt
------------------------------------------------------------------------------------------------------------------------


-- Children literally named "Name" collide with the Instance.Name property, so fetch them explicitly.
local function nameLabel(inst: Instance): TextLabel
	return inst:FindFirstChild("Name") :: TextLabel
end

local function popWindow(window: GuiObject)
	local scale = window:FindFirstChild("PopScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "PopScale"
		scale.Parent = window
	end
	scale.Scale = 0.9
	tween(scale, "Back", { Scale = 1 })
end

local DefaultConfirmIcons = {}

-- yields; returns true when confirmed
local function showConfirm(options)
	local screen = options.Destructive and DestructiveConfirmScreen or ConfirmScreen
	local window = screen:WaitForChild("ConfirmWindow")
	window.Label.Text = options.Title or "Are you sure?"
	pcall(function() window.Desc.RichText = true end)
	window.Desc.Text = options.Description or ""
	local yes = window.ChoiseButtonsHolder.YesButton
	local no = window.ChoiseButtonsHolder.NoButton
	nameLabel(yes).Text = options.ConfirmText or "Confirm"
	local yesIcon = yes:FindFirstChild("ImageLabel")
	if yesIcon then
		if DefaultConfirmIcons[yes] == nil then
			DefaultConfirmIcons[yes] = yesIcon.Image
		end
		yesIcon.Image = options.Icon or DefaultConfirmIcons[yes]
	end

	fadeIn(screen, 0.22)
	popWindow(window)

	local result = nil
	local connections = {}
	local function finish(value)
		if result ~= nil then return end
		result = value
		for _, c in ipairs(connections) do c:Disconnect() end
		fadeOut(screen, 0.2)
	end
	table.insert(connections, yes.MouseButton1Click:Connect(function() finish(true) end))
	table.insert(connections, no.MouseButton1Click:Connect(function() finish(false) end))
	table.insert(connections, screen.DimButton.MouseButton1Click:Connect(function() finish(false) end))

	while result == nil do
		task.wait()
	end
	return result
end

-- yields; returns entered text or nil when cancelled
local function showInputPrompt(options)
	local screen = InputboxScreen
	local window = screen:WaitForChild("InputboxWindow")
	window.Label.Text = options.Title or "Enter value"
	pcall(function() window.Desc.RichText = true end)
	window.Desc.Text = options.Description or ""

	local buttonsHolder = window.ChoiseButtonsHolder
	local continueButton = buttonsHolder:FindFirstChild("RenameButton") or buttonsHolder:FindFirstChild("ContinueButton")
	local cancelButton = buttonsHolder.CancelButton
	nameLabel(continueButton).Text = options.ConfirmText or "Continue"

	local inputBox = window.InputBox
	local limitText = inputBox.CharactersLimitText
	local errorHolder = window.ErrorHolder
	local errorLabel = errorHolder:FindFirstChildOfClass("TextLabel")
	errorHolder.Visible = false

	local maxLength = options.MaxLength or 32
	inputBox.Text.Visible = false

	local currentText = ""
	local currentError = nil

	local input = SmoothInput.new({
		Parent = inputBox,
		Font = FONT_BODY,
		TextSize = 14,
		TextColor = Color3.fromRGB(170, 170, 170),
		PlaceholderText = options.Placeholder or "",
		PlaceholderColor = Color3.fromRGB(110, 110, 110),
		MaxLength = maxLength,
		PaddingLeft = 10,
		PaddingRight = 10,
		ZIndex = 16,
	})

	local function setContinueEnabled(enabled: boolean)
		local stroke = continueButton:FindFirstChildOfClass("UIStroke")
		if enabled then
			tween(continueButton, "Fast", { BackgroundColor3 = TC(Color3.fromRGB(60, 60, 60)) })
			tween(nameLabel(continueButton), "Fast", { TextColor3 = TC(Color3.fromRGB(190, 190, 190)) })
			if stroke then tween(stroke, "Fast", { Color = TC(Color3.fromRGB(90, 90, 90)) }) end
		else
			tween(continueButton, "Fast", { BackgroundColor3 = TC(Color3.fromRGB(20, 20, 20)) })
			tween(nameLabel(continueButton), "Fast", { TextColor3 = TC(Color3.fromRGB(70, 70, 70)) })
			if stroke then tween(stroke, "Fast", { Color = TC(Color3.fromRGB(40, 40, 40)) }) end
		end
	end

	local function validate(text: string): boolean
		currentText = text
		limitText.Text = ("%d/%d"):format(utf8.len(text) or #text, maxLength)
		local errorMessage = nil
		if options.Validate then
			local ok, result = pcall(options.Validate, text)
			if ok and result ~= true and result ~= nil then
				errorMessage = tostring(result)
			elseif not ok then
				errorMessage = "Invalid value."
			end
		end
		if text == "" and not options.AllowEmpty then
			errorMessage = errorMessage or false -- disabled but no error banner for empty
		end
		currentError = errorMessage
		if errorMessage and errorMessage ~= false then
			errorHolder.Visible = true
			if errorLabel then errorLabel.Text = errorMessage end
			setContinueEnabled(false)
			return false
		end
		errorHolder.Visible = false
		local enabled = (text ~= "" or options.AllowEmpty) and errorMessage == nil
		setContinueEnabled(enabled)
		return enabled
	end

	input.Options.OnChanged = validate

	fadeIn(screen, 0.22)
	popWindow(window)
	input:SetText(options.Default or "", true)
	validate(options.Default or "")
	task.delay(0.15, function() input:Focus() end)

	local result, resolved = nil, false
	local connections = {}
	local function finish(value)
		if resolved then return end
		resolved = true
		result = value
		for _, c in ipairs(connections) do c:Disconnect() end
		input:Blur()
		fadeOut(screen, 0.2)
		task.delay(0.25, function() input:Destroy() end)
	end
	table.insert(connections, continueButton.MouseButton1Click:Connect(function()
		if validate(currentText) then
			finish(currentText)
		else
			input:Shake()
		end
	end))
	table.insert(connections, cancelButton.MouseButton1Click:Connect(function() finish(nil) end))
	table.insert(connections, screen.DimButton.MouseButton1Click:Connect(function() finish(nil) end))
	input.Options.OnSubmit = function(text)
		if validate(text) then
			finish(text)
		else
			input:Shake()
		end
	end

	while not resolved do
		task.wait()
	end
	return result
end
------------------------------------------------------------------------------------------------------------------------
--  Safe callback wrapper
------------------------------------------------------------------------------------------------------------------------

local statusIssueToken = 0

local function reportInterfaceIssue(text: string)
	statusIssueToken += 1
	local token = statusIssueToken
	AmphibiaLibrary:SetStatus(text, false)
	task.delay(5, function()
		if token == statusIssueToken then
			AmphibiaLibrary:SetStatus("Connected", true)
		end
	end)
end

local function safeCallback(fn, ...)
	if not fn then return end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(fn, table.unpack(args, 1, args.n))
		if not ok then
			warn("[ Amphibia Interface ] Callback error: " .. tostring(err))
			reportInterfaceIssue("Callback error")
			AmphibiaLibrary:Notify({ Color = "Red", Content = "A callback errored — check console.", Duration = 5 })
		end
	end)
end

local ThemeRefreshers = {}
local function onThemeRefresh(fn)
	table.insert(ThemeRefreshers, fn)
end

------------------------------------------------------------------------------------------------------------------------
--  Keybinds list overlay
------------------------------------------------------------------------------------------------------------------------

local KeybindsUI = {
	Mode = "Hidden", -- "Default" | "Transparent" | "Hidden"
	Entries = {},
}

-- one list only; the authored transparent variant stays retired
KeybindsListTransparentFrame.Visible = false

local KeybindsListStroke = KeybindsListFrame:FindFirstChildOfClass("UIStroke")
local KeybindsListShadow = KeybindsListFrame:FindFirstChildOfClass("UIShadow")
local KeybindsAuthored = {
	Bg = KeybindsListFrame.BackgroundTransparency,
	Stroke = KeybindsListStroke and KeybindsListStroke.Transparency or 0,
	Shadow = KeybindsListShadow and KeybindsListShadow.Transparency or 0,
}
do
	local templateChip = Templates.Bind:FindFirstChild("ButtonKey")
	KeybindsAuthored.ChipBg = templateChip and templateChip.BackgroundTransparency or 0
	local templateChipStroke = templateChip and templateChip:FindFirstChildOfClass("UIStroke")
	KeybindsAuthored.ChipStroke = templateChipStroke and templateChipStroke.Transparency or 0
end

local KEYBINDS_MODE_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- applies the current mode's transparency profile to the frame + every row
local function applyKeybindsModeStyle(instant: boolean?)
	local transparent = KeybindsUI.Mode == "Transparent"
	local info = instant and TweenInfo.new(0) or KEYBINDS_MODE_INFO
	tween(KeybindsListFrame, info, { BackgroundTransparency = transparent and 0.8 or KeybindsAuthored.Bg })
	if KeybindsListStroke then
		tween(KeybindsListStroke, info, { Transparency = transparent and 1 or KeybindsAuthored.Stroke })
	end
	if KeybindsListShadow then
		tween(KeybindsListShadow, info, { Transparency = transparent and 0.7 or KeybindsAuthored.Shadow })
	end
	for _, row in ipairs(KeybindsListFrame.BindsListHolder:GetChildren()) do
		if row:IsA("GuiObject") then
			local chip = row:FindFirstChild("ButtonKey")
			if chip then
				tween(chip, info, { BackgroundTransparency = transparent and 0.55 or KeybindsAuthored.ChipBg })
				local chipStroke = chip:FindFirstChildOfClass("UIStroke")
				if chipStroke then
					tween(chipStroke, info, { Transparency = transparent and 0.6 or KeybindsAuthored.ChipStroke })
				end
			end
		end
	end
end

-- fades the whole list (frame chrome + row text) in or out
local function setKeybindsListShown(shown: boolean, instant: boolean?)
	local info = instant and TweenInfo.new(0) or KEYBINDS_MODE_INFO
	if shown then
		KeybindsListFrame.Visible = true
		if not instant then
			KeybindsListFrame.BackgroundTransparency = 1
			if KeybindsListStroke then KeybindsListStroke.Transparency = 1 end
			if KeybindsListShadow then KeybindsListShadow.Transparency = 1 end
			popWindow(KeybindsListFrame)
		end
		applyKeybindsModeStyle(instant)
		for _, descendant in ipairs(KeybindsListFrame:GetDescendants()) do
			if descendant:IsA("TextLabel") then
				if not instant then descendant.TextTransparency = 1 end
				tween(descendant, info, { TextTransparency = 0 })
			end
		end
	else
		tween(KeybindsListFrame, info, { BackgroundTransparency = 1 })
		if KeybindsListStroke then tween(KeybindsListStroke, info, { Transparency = 1 }) end
		if KeybindsListShadow then tween(KeybindsListShadow, info, { Transparency = 1 }) end
		for _, descendant in ipairs(KeybindsListFrame:GetDescendants()) do
			if descendant:IsA("TextLabel") then
				tween(descendant, info, { TextTransparency = 1 })
			elseif descendant:IsA("UIStroke") then
				tween(descendant, info, { Transparency = 1 })
			elseif descendant:IsA("Frame") or descendant:IsA("ImageButton") then
				tween(descendant, info, { BackgroundTransparency = 1 })
			end
		end
		task.delay(instant and 0 or 0.32, function()
			if KeybindsUI.Mode == "Hidden" then
				KeybindsListFrame.Visible = false
			end
		end)
	end
end

function KeybindsUI.Refresh()
	for _, child in ipairs(KeybindsListFrame.BindsListHolder:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	if KeybindsUI.Mode == "Hidden" then
		return
	end
	for order, entry in ipairs(KeybindsUI.Entries) do
		local row = Templates.Bind:Clone()
		row.Name = "Bind_" .. order
		row.LayoutOrder = order
		row.BindName.Text = entry.Name
		row.ButtonKey.Bind.Text = keyDisplayName(entry.GetBind and entry.GetBind() or "None")
		-- the list is display-only: rebinding lives in the right-click menu
		local rebindButton = row:FindFirstChild("ButtonBind")
		if rebindButton then
			rebindButton.Visible = false
		end
		themeRegisterDeep(row)
		themeApplyDeep(row)
		row.Parent = KeybindsListFrame.BindsListHolder
	end
	applyKeybindsModeStyle(true)
end

function KeybindsUI.Register(entry)
	table.insert(KeybindsUI.Entries, entry)
	if KeybindsUI.Mode ~= "Hidden" then
		KeybindsUI.Refresh()
	end
	return entry
end

function KeybindsUI.Unregister(entry)
	for index, existing in ipairs(KeybindsUI.Entries) do
		if existing == entry then
			table.remove(KeybindsUI.Entries, index)
			break
		end
	end
	if KeybindsUI.Mode ~= "Hidden" then
		KeybindsUI.Refresh()
	end
end

function KeybindsUI.SetMode(mode: string)
	local previous = KeybindsUI.Mode
	if previous == mode then
		return
	end
	KeybindsUI.Mode = mode
	if mode == "Hidden" then
		setKeybindsListShown(false)
	elseif previous == "Hidden" then
		KeybindsUI.Refresh()
		setKeybindsListShown(true)
	else
		-- visible -> visible: just glide between transparency profiles
		applyKeybindsModeStyle(false)
	end
end

makeDraggable(KeybindsListFrame.Title, KeybindsListFrame)

------------------------------------------------------------------------------------------------------------------------
--  Window visibility (minimise / restore / keybind toggle)
------------------------------------------------------------------------------------------------------------------------

local WindowOpen = false
local InterfaceRevealed = false
local windowAnimating = false
local RememberedWindowPosition = UDim2.new(0.5, 0, 0.5, 0)

local function setWindowOpen(open: boolean, instant: boolean?)
	if open == WindowOpen or windowAnimating then
		return
	end
	WindowOpen = open
	if instant then
		Main.Visible = open
		MainScale.Scale = BaseScale
		return
	end
	windowAnimating = true
	if open then
		Main.Visible = true
		MainScale.Scale = BaseScale * 0.92
		local goalPos = RememberedWindowPosition
		Main.Position = goalPos + UDim2.new(0, 0, 0, 14)
		tween(MainScale, "Back", { Scale = BaseScale })
		tween(Main, "Back", { Position = goalPos })
		task.delay(0.36, function() windowAnimating = false end)
	else
		RememberedWindowPosition = Main.Position
		local restorePos = Main.Position
		tween(MainScale, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Scale = BaseScale * 0.92 })
		tween(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = restorePos + UDim2.new(0, 0, 0, 14) })
		task.delay(0.23, function()
			Main.Visible = false
			Main.Position = restorePos
			windowAnimating = false
		end)
	end
end

-- Show pill at the top of the screen
do
	local baseSize = ShowUiButton.Size
	ShowUiButton.MouseEnter:Connect(function()
		tween(ShowUiButton, "Fast", { Size = UDim2.new(0, baseSize.X.Offset + 14, 0, 12) })
	end)
	ShowUiButton.MouseLeave:Connect(function()
		tween(ShowUiButton, "Out", { Size = baseSize })
	end)
	ShowUiButton.MouseButton1Click:Connect(function()
		if InterfaceRevealed then
			setWindowOpen(not WindowOpen)
		end
	end)
end

Header.CloseMenuButton.MouseButton1Click:Connect(function()
	setWindowOpen(false)
end)
Header.CloseMenuButton.MouseEnter:Connect(function()
	tween(Header.CloseMenuButton, "Fast", { ImageColor3 = TC(Color3.fromRGB(120, 120, 120)), Rotation = 8 })
end)
Header.CloseMenuButton.MouseLeave:Connect(function()
	tween(Header.CloseMenuButton, "Out", { ImageColor3 = TC(Color3.fromRGB(55, 55, 55)), Rotation = 0 })
end)

makeDraggable(Header, Main)

connect(UserInputService.InputBegan, function(input, gameProcessed)
	if gameProcessed or ActiveInput then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local bindName = getSetting("General", "amphibiaOpen")
		if bindName and input.KeyCode.Name == bindName and InterfaceRevealed then
			setWindowOpen(not WindowOpen)
		end
	end
end)

------------------------------------------------------------------------------------------------------------------------
--  Key system
------------------------------------------------------------------------------------------------------------------------

local function readSavedKey(): string?
	if not FS.isfile(KeyFile) then
		return nil
	end
	local raw = FS.read(KeyFile)
	if not raw then return nil end
	local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok and type(decoded) == "table" and type(decoded.key) == "string" then
		return decoded.key
	end
	return nil
end

local function writeSavedKey(key: string)
	local ok, json = pcall(function()
		return HttpService:JSONEncode({ key = key, savedAt = os.time() })
	end)
	if ok then
		FS.write(KeyFile, json)
	end
end

-- Yields until a valid key has been entered. Assumes EnterKeyScreen is already visible.
local function runKeySystem(keySettings)
	local screen = EnterKeyScreen
	local welcomeText = screen.WelcomeText
	local welcomeDesc = screen.WelcomeDesc
	local inputBg = screen.KeyInputBG
	local inputStroke = inputBg:FindFirstChildOfClass("UIStroke")
	local activateButton = inputBg.ActivateButton
	local inputButton = inputBg.InputButton
	local stopButton = screen.KeyInputStopButton

	welcomeText.Text = keySettings.Title or "Welcome to amphibia."
	local subtitle = keySettings.Subtitle or "Enter your key to get started."
	welcomeDesc.Text = subtitle

	inputBg.Text.Visible = false

	local keyInput = SmoothInput.new({
		Parent = inputBg,
		Font = FONT_MONO,
		TextSize = 14,
		TextColor = Color3.fromRGB(157, 157, 157),
		CaretColor = Color3.fromRGB(200, 200, 200),
		PlaceholderText = "Enter key here",
		PlaceholderColor = Color3.fromRGB(157, 157, 157),
		PlaceholderTransparency = 0.45,
		MaxLength = 64,
		PaddingLeft = 12,
		PaddingRight = 34,
		ZIndex = 14,
	})

	local strokeIdle = Color3.fromRGB(55, 55, 55)
	local strokeHover = Color3.fromRGB(70, 70, 70)
	local strokeFocus = Color3.fromRGB(100, 100, 100)
	local strokeError = Color3.fromRGB(118, 78, 78)
	local strokeSuccess = Color3.fromRGB(104, 122, 114)

	keyInput.Options.OnFocus = function()
		if inputStroke then tween(inputStroke, "Fast", { Color = TC(strokeFocus) }) end
	end
	keyInput.Options.OnBlur = function()
		if inputStroke then tween(inputStroke, "Out", { Color = TC(strokeIdle) }) end
	end
	inputBg.MouseEnter:Connect(function()
		if not keyInput.Focused and inputStroke then
			tween(inputStroke, "Fast", { Color = TC(strokeHover) })
		end
	end)
	inputBg.MouseLeave:Connect(function()
		if not keyInput.Focused and inputStroke then
			tween(inputStroke, "Out", { Color = TC(strokeIdle) })
		end
	end)
	inputButton.MouseButton1Click:Connect(function()
		keyInput:Focus()
	end)
	stopButton.MouseButton1Click:Connect(function()
		keyInput:Blur()
	end)

	-- socials --------------------------------------------------------------------------------------------------
	local socials = {
		{ Button = screen:FindFirstChild("CopyDiscrod"), Link = keySettings.Discord },
		{ Button = screen:FindFirstChild("CopySite"), Link = keySettings.Website },
		{ Button = screen:FindFirstChild("CopyYoutube"), Link = keySettings.Youtube },
	}
	for _, social in ipairs(socials) do
		local button = social.Button
		if not button then continue end
		if not social.Link then
			button.Visible = false
			continue
		end
		button.ImageColor3 = Color3.fromRGB(255, 255, 255)
		button.ImageTransparency = 0.8
		button.MouseEnter:Connect(function()
			tween(button, "Fast", { ImageTransparency = 0.55 })
		end)
		button.MouseLeave:Connect(function()
			tween(button, "Out", { ImageTransparency = 0.8 })
		end)
		button.MouseButton1Click:Connect(function()
			if setClipboard(social.Link) then
				AmphibiaLibrary:Notify({ Color = "Green", Content = "Link copied to clipboard.", Duration = 3 })
			else
				AmphibiaLibrary:Notify({ Color = "Yellow", Content = social.Link, Duration = 6 })
			end
		end)
	end

	-- validation -----------------------------------------------------------------------------------------------
	local validKeys = keySettings.Key or {}
	if type(validKeys) == "string" then
		validKeys = { validKeys }
	end
	local function isValid(text: string): boolean
		text = text:gsub("^%s+", ""):gsub("%s+$", "")
		for _, key in ipairs(validKeys) do
			if text == key then
				return true
			end
		end
		return false
	end

	local resolved = false
	local errorRestore = nil

	local function showError()
		welcomeDesc.Text = "Invalid key — please try again."
		tween(welcomeDesc, "Fast", { TextColor3 = Color3.fromRGB(174, 118, 118) })
		if inputStroke then tween(inputStroke, "Fast", { Color = strokeError }) end
		keyInput:SetTextColor(Color3.fromRGB(172, 124, 124), true)
		keyInput:Shake()
		if errorRestore then task.cancel(errorRestore) end
		errorRestore = task.delay(1.6, function()
			if resolved then return end
			welcomeDesc.Text = subtitle
			tween(welcomeDesc, "Out", { TextColor3 = TC(Color3.fromRGB(120, 120, 120)) })
			if inputStroke then
				tween(inputStroke, "Out", { Color = TC(keyInput.Focused and strokeFocus or strokeIdle) })
			end
			keyInput:SetTextColor(Color3.fromRGB(157, 157, 157), true)
		end)
	end

	local function accept(fromSaved: boolean)
		if resolved then return end
		resolved = true
		keyInput:Blur()
		if inputStroke then tween(inputStroke, "Out", { Color = TC(strokeSuccess) }) end
		keyInput:SetTextColor(Color3.fromRGB(150, 162, 156), true)
		welcomeDesc.Text = fromSaved and "Welcome back." or "Key accepted."
		tween(welcomeDesc, "Fast", { TextColor3 = TC(Color3.fromRGB(142, 156, 148)) })
		tween(screen.Icon, "Back", { Rotation = 8 })
		if keySettings.SaveKey ~= false and not fromSaved then
			writeSavedKey(keyInput.Text:gsub("^%s+", ""):gsub("%s+$", ""))
		end
	end

	local function submit()
		if resolved then return end
		if isValid(keyInput.Text) then
			accept(false)
		else
			showError()
		end
	end

	keyInput.Options.OnSubmit = submit
	activateButton.MouseButton1Click:Connect(submit)
	activateButton.MouseEnter:Connect(function()
		tween(activateButton, "Fast", { ImageColor3 = TC(Color3.fromRGB(140, 140, 140)) })
	end)
	activateButton.MouseLeave:Connect(function()
		tween(activateButton, "Out", { ImageColor3 = TC(Color3.fromRGB(80, 80, 80)) })
	end)

	-- remembered key: auto-type it in and sign in ---------------------------------------------------------------
	task.delay(0.55, function()
		if resolved then return end
		local savedKey = readSavedKey()
		if savedKey and isValid(savedKey) then
			welcomeDesc.Text = "Welcome back — signing you in."
			keyInput:TypeText(savedKey, 0.024)
			task.wait(0.3)
			if not resolved and isValid(keyInput.Text) then
				accept(true)
			end
		elseif savedKey then
			FS.delete(KeyFile) -- key was rotated; fall back to manual input
		end
	end)

	while not resolved do
		task.wait()
	end
	task.wait(0.55)
	keyInput:Destroy()
	inputBg.Text.Visible = true
	return true
end

------------------------------------------------------------------------------------------------------------------------
--  Loading screen
------------------------------------------------------------------------------------------------------------------------

local function runLoading(title: string?, description: string?, minTime: number?)
	minTime = math.max(minTime or 2.4, 0.8)
	local screen = LoadingScreen
	screen.LoadingTitle.Text = title or "Just a moment…"
	screen.LoadingDesc.Text = description or "Setting things up — this won't take long."
	local fill = screen.LoadingLine.Fill
	local timer = screen.Timer

	fill.Size = UDim2.new(0, 0, 1, 0)
	timer.Text = ""

	tween(fill, TweenInfo.new(minTime * 0.92, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0.86, 0, 1, 0) })

	local start = os.clock()
	task.spawn(function()
		while os.clock() - start < minTime - 0.35 do
			local remaining = math.max(0, math.ceil(minTime - (os.clock() - start)))
			timer.Text = ("~%ds"):format(remaining)
			task.wait(0.5)
		end
	end)

	task.wait(minTime - 0.3)
	tween(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 1, 0) })
	task.wait(0.32)
	timer.Text = "Loaded!"
	task.wait(0.3)
end

------------------------------------------------------------------------------------------------------------------------
--  Tabs, sections & elements
------------------------------------------------------------------------------------------------------------------------

local ConfigHooks = {
	Autosave = function() end,       -- replaced by the configuration module
	OnElementRegistered = function(_) end,
}

------------------------------------------------------------------------------------------------------------------------
--  Key capture (shared by keybind elements and the right-click bind system)
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--  Bind system — right-click any element to attach custom keybinds to it
------------------------------------------------------------------------------------------------------------------------

local BindSystem = {
	Binds = {},
	NextId = 1,
	OpenMenu = nil, -- assigned by the UI module
	Changed = function() end,
	CaptureActive = false,
	ModesByType = {
		Toggle = { "Toggle", "Hold" },
		Button = { "Press" },
		Slider = { "Set value" },
		NumberPicker = { "Set value" },
		Input = { "Set value" },
		Selector = { "Set value" },
		Dropdown = { "Set value" },
	},
}

-- Calls back with the resolved bind name; "None" clears; nil = cancelled with Escape.
local function captureBindKey(onDone) -- BINDHELPER
	if BindSystem.CaptureActive then
		return false
	end
	BindSystem.CaptureActive = true
	local captureConnection
	captureConnection = UserInputService.InputBegan:Connect(function(input)
		local resolvedName, cancelled = nil, false
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				cancelled = true
			elseif input.KeyCode == Enum.KeyCode.Backspace then
				resolvedName = "None"
			else
				resolvedName = input.KeyCode.Name
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			resolvedName = "MouseButton2"
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			resolvedName = "MouseButton3"
		end
		if resolvedName or cancelled then
			captureConnection:Disconnect()
			task.delay(0.05, function()
				BindSystem.CaptureActive = false
			end)
			onDone(resolvedName)
		end
	end)
	return true
end

local function inputMatchesBind(input, bindName): boolean
	if not bindName or bindName == "None" then
		return false
	end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return input.KeyCode.Name == bindName
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		return bindName == "MouseButton2"
	elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
		return bindName == "MouseButton3"
	end
	return false
end

function BindSystem.IsBindable(element): boolean
	return BindSystem.ModesByType[element.Type] ~= nil
end

function BindSystem.ForElement(element)
	local out = {}
	for _, bind in ipairs(BindSystem.Binds) do
		if bind.Element == element then
			table.insert(out, bind)
		end
	end
	return out
end

function BindSystem.Execute(bind, pressed: boolean)
	local element = bind.Element
	if not element then return end
	local elementType = element.Type
	if elementType == "Toggle" then
		if bind.Mode == "Hold" then
			element:Set(pressed)
		elseif pressed then
			element:Set(not element.CurrentValue)
		end
		return
	end
	if not pressed then return end
	if elementType == "Button" then
		if element.Press then element.Press() end
	elseif elementType == "Slider" or elementType == "NumberPicker" then
		local numeric = tonumber(bind.Value)
		if numeric then element:Set(numeric) end
	elseif elementType == "Input" then
		element:Set(tostring(bind.Value or ""))
	elseif elementType == "Selector" or elementType == "Dropdown" then
		if bind.Value ~= nil and bind.Value ~= "" then
			element:Set(tostring(bind.Value))
		end
	end
end

function BindSystem.Add(bind)
	bind.Id = BindSystem.NextId
	BindSystem.NextId += 1
	table.insert(BindSystem.Binds, bind)
	bind.UIEntry = KeybindsUI.Register({
		Name = bind.Name,
		GetBind = function() return bind.Key end,
		StartRebind = function(refreshFn)
			captureBindKey(function(newKey)
				if newKey then
					bind.Key = newKey
					if refreshFn then refreshFn(newKey) end
					BindSystem.Changed()
					ConfigHooks.Autosave()
				end
			end)
		end,
	})
	BindSystem.Changed()
	ConfigHooks.Autosave()
	return bind
end

function BindSystem.Remove(bind)
	for index, existing in ipairs(BindSystem.Binds) do
		if existing == bind then
			table.remove(BindSystem.Binds, index)
			break
		end
	end
	if bind.UIEntry then
		KeybindsUI.Unregister(bind.UIEntry)
	end
	BindSystem.Changed()
	ConfigHooks.Autosave()
end

function BindSystem.Serialize()
	local out = {}
	for _, bind in ipairs(BindSystem.Binds) do
		local flag = bind.Element and bind.Element.Flag
		if flag then
			table.insert(out, { f = flag, n = bind.Name, k = bind.Key, m = bind.Mode, v = bind.Value })
		end
	end
	return out
end

function BindSystem.LoadSerialized(list)
	if type(list) ~= "table" then return end
	-- replace all flag-backed binds with the incoming set
	for index = #BindSystem.Binds, 1, -1 do
		local bind = BindSystem.Binds[index]
		if bind.Element and bind.Element.Flag then
			if bind.UIEntry then KeybindsUI.Unregister(bind.UIEntry) end
			table.remove(BindSystem.Binds, index)
		end
	end
	for _, saved in ipairs(list) do
		local element = saved.f and AmphibiaLibrary.Elements[saved.f]
		if element and BindSystem.IsBindable(element) then
			BindSystem.Add({
				Element = element,
				Name = tostring(saved.n or element.Name or "Bind"),
				Key = tostring(saved.k or "None"),
				Mode = tostring(saved.m or (BindSystem.ModesByType[element.Type] or {})[1] or "Press"),
				Value = saved.v,
			})
		end
	end
	BindSystem.Changed()
end

connect(UserInputService.InputBegan, function(input, gameProcessed)
	if gameProcessed or ActiveInput or BindSystem.CaptureActive then return end
	for _, bind in ipairs(BindSystem.Binds) do
		if inputMatchesBind(input, bind.Key) then
			task.spawn(BindSystem.Execute, bind, true)
		end
	end
end)

connect(UserInputService.InputEnded, function(input, gameProcessed)
	if gameProcessed or ActiveInput then return end
	for _, bind in ipairs(BindSystem.Binds) do
		if bind.Mode == "Hold" and inputMatchesBind(input, bind.Key) then
			task.spawn(BindSystem.Execute, bind, false)
		end
	end
end)

AmphibiaLibrary.BindSystem = BindSystem

local ActiveWindow = nil

local function registerFlag(element, value)
	if element.Flag then
		AmphibiaLibrary.Flags[element.Flag] = value
	end
	ConfigHooks.Autosave()
end

local function attachRowHover(row: GuiObject, label: TextLabel?)
	if not label then return end
	row.MouseEnter:Connect(function()
		tween(label, "Fast", { TextColor3 = TC(Color3.fromRGB(235, 235, 235)) })
	end)
	row.MouseLeave:Connect(function()
		tween(label, "Out", { TextColor3 = TC(Color3.fromRGB(200, 200, 200)) })
	end)
end

--========================================================== Section =================================================--

local SectionClass = {}
SectionClass.__index = SectionClass

local function createSection(tab, options)
	options = options or {}
	local self = setmetatable({}, SectionClass)
	self.Tab = tab
	self.Name = options.Name or "Section"
	self.Elements = {}
	self.Collapsed = false
	self.ElementOrder = 0

	local column = (options.Side == "Right") and tab.RightColumn or tab.LeftColumn
	local root = Templates.Section:Clone()
	root.Name = self.Name .. "Section"
	root.SectionNameHolderFrame.SectionName.Text = self.Name
	root.LayoutOrder = #column:GetChildren()
	themeRegisterDeep(root)
	themeApplyDeep(root)
	root.Parent = column

	self.Root = root
	self.Holder = root.ButtonsHolderFrame
	self.Icon = root.SectionNameHolderFrame.Icon

	root.SectionNameHolderFrame.SectionButton.MouseButton1Click:Connect(function()
		self:SetCollapsed(not self.Collapsed)
	end)

	if options.Collapsed then
		task.defer(function()
			self:SetCollapsed(true, true)
		end)
	end

	table.insert(tab.Sections, self)
	return self
end

function SectionClass:SetCollapsed(collapsed: boolean, instant: boolean?)
	if collapsed == self.Collapsed then return end
	self.Collapsed = collapsed
	local root, holder = self.Root, self.Holder
	local scale = math.max(MainScale.Scale, 0.01)

	if collapsed then
		local currentHeight = root.AbsoluteSize.Y / scale
		root.AutomaticSize = Enum.AutomaticSize.None
		root.Size = UDim2.new(0, 350, 0, currentHeight)
		root.ClipsDescendants = true
		tween(self.Icon, "Out", { Rotation = 90 })
		if instant then
			root.Size = UDim2.new(0, 350, 0, 50)
			holder.Visible = false
		else
			tween(root, "Out", { Size = UDim2.new(0, 350, 0, 50) })
			task.delay(0.25, function()
				if self.Collapsed then holder.Visible = false end
			end)
		end
	else
		holder.Visible = true
		tween(self.Icon, "Out", { Rotation = 180 })
		task.defer(function()
			local target = 50 + holder.AbsoluteSize.Y / scale
			if instant then
				root.Size = UDim2.new(0, 350, 0, target)
			else
				tween(root, "Out", { Size = UDim2.new(0, 350, 0, target) })
			end
			task.delay(instant and 0 or 0.26, function()
				if not self.Collapsed then
					root.AutomaticSize = Enum.AutomaticSize.Y
					root.Size = UDim2.new(0, 350, 0, 15)
					root.ClipsDescendants = false
				end
			end)
		end)
	end
end

function SectionClass:_mount(element, row, options)
	self.ElementOrder += 1
	row.LayoutOrder = self.ElementOrder
	element.Root = row
	element.Section = self
	element.Name = options.Name or element.Type
	element.Flag = options.Flag
	element.SearchText = string.lower(element.Name)
	table.insert(self.Elements, element)
	table.insert(self.Tab.Elements, element)
	if element.Flag then
		AmphibiaLibrary.Elements[element.Flag] = element
	end
	if element.GetSaveValue then
		local ok, defaultSave = pcall(element.GetSaveValue)
		if ok then
			element.DefaultSave = defaultSave
			if element.Flag then
				AmphibiaLibrary.Flags[element.Flag] = defaultSave
			end
		end
	end
	themeRegisterDeep(row)
	themeApplyDeep(row)
	if BindSystem.IsBindable(element) then
		local lastMenuOpen = 0
		local function tryOpenBindMenu(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
			if not BindSystem.OpenMenu or BindSystem.CaptureActive then return end
			local now = os.clock()
			if now - lastMenuOpen < 0.25 then return end
			lastMenuOpen = now
			BindSystem.OpenMenu(element, mousePoint())
		end
		-- InputBegan doesn't bubble, so hook the row AND everything inside it — right click must
		-- work over sliders, chips and inputs, not only over the name label
		row.InputBegan:Connect(tryOpenBindMenu)
		for _, descendant in ipairs(row:GetDescendants()) do
			if descendant:IsA("GuiObject") then
				descendant.InputBegan:Connect(tryOpenBindMenu)
			end
		end
		row.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("GuiObject") then
				descendant.InputBegan:Connect(tryOpenBindMenu)
			end
		end)
	end
	row.Parent = self.Holder
	ConfigHooks.OnElementRegistered(element)
	return element
end

--========================================================== Toggle ==================================================--

function SectionClass:CreateToggle(options)
	options = options or {}
	local element = { Type = "Toggle", CurrentValue = options.CurrentValue == true, DefaultValue = options.CurrentValue == true }
	local row = Templates.Toggle:Clone()
	row.Name = "Toggle"

	local label = nameLabel(row)
	label.Text = options.Name or "Toggle"
	local toggleFrame = row.ToggleFrame
	local stroke = toggleFrame:FindFirstChildOfClass("UIStroke")
	local dot = toggleFrame.Dot
	local dotShadow = dot:FindFirstChildOfClass("UIShadow")
	local valueLabel = row.ToggleValue

	local function render(instant: boolean?)
		local on = element.CurrentValue
		local info = instant and TweenInfo.new(0) or EASE.Back
		local colorInfo = instant and TweenInfo.new(0) or EASE.Out
		tween(dot, info, { Position = UDim2.new(on and 0.7 or 0.3, 0, 0.5, 0) })
		tween(dot, colorInfo, { BackgroundColor3 = TC(on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(105, 105, 105)) })
		tween(toggleFrame, colorInfo, { BackgroundColor3 = TC(on and Color3.fromRGB(48, 48, 48) or Color3.fromRGB(33, 33, 33)) })
		if stroke then
			tween(stroke, colorInfo, { Color = TC(on and Color3.fromRGB(175, 175, 175) or Color3.fromRGB(75, 75, 75)) })
		end
		if dotShadow then
			dotShadow.Enabled = on
			tween(dotShadow, colorInfo, { Transparency = on and 0 or 1 })
		end
		valueLabel.Text = on and "On" or "Off"
		tween(valueLabel, colorInfo, { TextColor3 = TC(on and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(102, 102, 102)) })
	end

	function element:Set(value: boolean, silent: boolean?)
		element.CurrentValue = value == true
		render(false)
		registerFlag(element, element.CurrentValue)
		if not silent then
			safeCallback(options.Callback, element.CurrentValue)
		end
	end
	element.GetSaveValue = function() return element.CurrentValue end
	element.LoadSaveValue = function(_, value) element:Set(value == true) end

	row.MouseButton1Click:Connect(function()
		element:Set(not element.CurrentValue)
	end)
	attachRowHover(row, label)

	render(true)
	registerFlag(element, element.CurrentValue)
	onThemeRefresh(function() render(true) end)
	element.Render = render
	return self:_mount(element, row, options)
end

--========================================================== Slider ==================================================--

function SectionClass:CreateSlider(options)
	options = options or {}
	local range = options.Range or { 0, 100 }
	local minValue, maxValue = range[1], range[2]
	local increment = options.Increment or 1
	local suffix = options.Suffix or ""
	local element = {
		Type = "Slider",
		CurrentValue = math.clamp(options.CurrentValue or minValue, minValue, maxValue),
	}
	element.DefaultValue = element.CurrentValue

	local row = Templates.Slider:Clone()
	row.Name = "Slider"
	local label = nameLabel(row)
	label.Text = options.Name or "Slider"
	local sliderBg = row.SliderBg
	local fill = sliderBg.Fill
	local knob = sliderBg.Knob
	local valueLabel = row.Value

	-- comfy hit-zone around the 2px track
	local hitZone = Instance.new("TextButton")
	hitZone.Name = "HitZone"
	hitZone.BackgroundTransparency = 1
	hitZone.Text = ""
	hitZone.AnchorPoint = Vector2.new(0.5, 0.5)
	hitZone.Position = UDim2.new(0.5, 0, 0.5, 0)
	hitZone.Size = UDim2.new(1, 14, 0, 26)
	hitZone.ZIndex = 6
	hitZone.Parent = sliderBg

	local function fraction(): number
		if maxValue == minValue then return 0 end
		return (element.CurrentValue - minValue) / (maxValue - minValue)
	end

	local function render(instant: boolean?)
		local info = instant and TweenInfo.new(0) or EASE.Fast
		local frac = fraction()
		tween(fill, info, { Size = UDim2.new(frac, 0, 1, 0) })
		tween(knob, info, { Position = UDim2.new(frac, 0, 0.5, 0) })
		valueLabel.Text = tostring(element.CurrentValue) .. suffix
	end

	function element:Set(value: number, silent: boolean?)
		value = math.clamp(round(value, increment), minValue, maxValue)
		element.CurrentValue = value
		render(false)
		registerFlag(element, value)
		if not silent then
			safeCallback(options.Callback, value)
		end
	end
	element.GetSaveValue = function() return element.CurrentValue end
	element.LoadSaveValue = function(_, value)
		if type(value) == "number" then element:Set(value) end
	end

	local dragging = false
	local function applyFromX(x: number)
		local frac = math.clamp((x - sliderBg.AbsolutePosition.X) / math.max(1, sliderBg.AbsoluteSize.X), 0, 1)
		element:Set(minValue + frac * (maxValue - minValue))
	end
	hitZone.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			tween(knob, "Fast", { Size = UDim2.new(0, 17, 0, 17) })
			applyFromX(input.Position.X)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			applyFromX(input.Position.X)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			tween(knob, "Back", { Size = UDim2.new(0, 15, 0, 15) })
		end
	end)

	render(true)
	registerFlag(element, element.CurrentValue)
	return self:_mount(element, row, options)
end

--========================================================== Button ==================================================--

function SectionClass:CreateButton(options)
	options = options or {}
	local element = { Type = "Button" }
	local row = Templates.Button:Clone()
	row.Name = "Button"
	local button = row.ButtonButton
	local label = nameLabel(button)
	label.Text = options.Name or "Button"

	local stroke = button:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Color = Color3.fromRGB(50, 50, 50)
		stroke.Transparency = 1
		stroke.Parent = button
	end
	themeRegister(stroke)

	local pressScale = Instance.new("UIScale")
	pressScale.Parent = button

	button.MouseEnter:Connect(function()
		tween(stroke, "Fast", { Transparency = 0 })
		tween(label, "Fast", { TextColor3 = TC(Color3.fromRGB(235, 235, 235)) })
	end)
	button.MouseLeave:Connect(function()
		tween(stroke, "Out", { Transparency = 1 })
		tween(label, "Out", { TextColor3 = TC(Color3.fromRGB(200, 200, 200)) })
	end)
	button.MouseButton1Click:Connect(function()
		pressScale.Scale = 0.965
		tween(pressScale, "Back", { Scale = 1 })
		tween(button, TweenInfo.new(0.08), { BackgroundColor3 = TC(Color3.fromRGB(26, 26, 27)) })
		task.delay(0.09, function()
			tween(button, "Out", { BackgroundColor3 = TC(Color3.fromRGB(13, 13, 14)) })
		end)
		safeCallback(options.Callback)
	end)

	function element:Set(newName: string)
		label.Text = newName
		element.Name = newName
		element.SearchText = string.lower(newName)
	end

	function element.Press()
		pressScale.Scale = 0.965
		tween(pressScale, "Back", { Scale = 1 })
		safeCallback(options.Callback)
	end

	return self:_mount(element, row, options)
end

--====================================================== Number picker ===============================================--

function SectionClass:CreateNumberPicker(options)
	options = options or {}
	local minValue = options.Min or 0
	local maxValue = options.Max or 100
	local increment = options.Increment or 1
	local element = {
		Type = "NumberPicker",
		CurrentValue = math.clamp(options.CurrentValue or minValue, minValue, maxValue),
	}
	element.DefaultValue = element.CurrentValue

	local row = Templates.NumberPicker:Clone()
	row.Name = "NumberPicker"
	local label = nameLabel(row)
	label.Text = options.Name or "Number Picker"
	local holder = row.NumberPickerHolder
	local valueLabel = holder.NumberValueHolder.NumberValue
	local minusButton, plusButton = holder.Minus, holder.Plus

	local function renderBounds()
		local atMin = element.CurrentValue <= minValue
		local atMax = element.CurrentValue >= maxValue
		tween(minusButton.Icon, "Fast", { ImageTransparency = atMin and 0.55 or 0 })
		tween(plusButton.Icon, "Fast", { ImageTransparency = atMax and 0.55 or 0 })
	end

	local function animateValue(direction: number)
		valueLabel.Text = tostring(element.CurrentValue)
		valueLabel.Position = UDim2.new(0.5, 0, 0.5, 6 * direction)
		valueLabel.TextTransparency = 0.6
		tween(valueLabel, "Out", { Position = UDim2.new(0.5, 0, 0.497, 0), TextTransparency = 0 })
	end

	function element:Set(value: number, silent: boolean?)
		local previous = element.CurrentValue
		value = math.clamp(round(value, increment), minValue, maxValue)
		if value == previous and not silent then
			return
		end
		element.CurrentValue = value
		animateValue(value >= previous and 1 or -1)
		renderBounds()
		registerFlag(element, value)
		if not silent then
			safeCallback(options.Callback, value)
		end
	end
	element.GetSaveValue = function() return element.CurrentValue end
	element.LoadSaveValue = function(_, value)
		if type(value) == "number" then element:Set(value) end
	end

	local function bindRepeat(button: GuiButton, direction: number)
		local holding = false
		local pressToken = 0
		button.MouseButton1Down:Connect(function()
			holding = true
			pressToken += 1
			local token = pressToken
			tween(button.Icon, "Fast", { Size = UDim2.new(0, 17, 0, 17) })
			element:Set(element.CurrentValue + increment * direction)
			task.delay(0.42, function()
				-- only this exact press may turn into a hold-repeat; quick re-clicks won't
				while holding and token == pressToken do
					element:Set(element.CurrentValue + increment * direction)
					task.wait(0.065)
				end
			end)
		end)
		local function release()
			holding = false
			pressToken += 1
			tween(button.Icon, "Back", { Size = UDim2.new(0, 20, 0, 20) })
		end
		button.MouseButton1Up:Connect(release)
		button.MouseLeave:Connect(release)
	end
	bindRepeat(minusButton, -1)
	bindRepeat(plusButton, 1)

	valueLabel.Text = tostring(element.CurrentValue)
	renderBounds()
	registerFlag(element, element.CurrentValue)
	element.Render = renderBounds
	return self:_mount(element, row, options)
end

--========================================================= Textbox ==================================================--

function SectionClass:CreateInput(options)
	options = options or {}
	local element = { Type = "Input", CurrentValue = options.CurrentValue or "" }
	element.DefaultValue = element.CurrentValue

	local row = Templates.Textbox:Clone()
	row.Name = "Input"
	local label = nameLabel(row)
	label.Text = options.Name or "Textbox"
	local box = row.TextboxBg
	local boxWidth = options.BoxWidth or 150

	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(0.98, 0, 0.5, 0)
	box.Size = UDim2.new(0, boxWidth, 0, 23)

	pcall(function() label.AutomaticSize = Enum.AutomaticSize.None end)
	label.Size = UDim2.new(1, -(boxWidth + 26), 1, 0)
	pcall(function() label.TextTruncate = Enum.TextTruncate.AtEnd end)
	local stroke = box:FindFirstChildOfClass("UIStroke")
	box.Text.Visible = false

	local input = SmoothInput.new({
		Parent = box,
		Font = FONT_BODY,
		TextSize = 14,
		TextColor = Color3.fromRGB(185, 185, 185),
		PlaceholderText = options.PlaceholderText or "type here",
		PlaceholderColor = Color3.fromRGB(120, 120, 120),
		MaxLength = options.MaxLength or 48,
		AllowedPattern = options.Numeric and "%d%.%-" or nil,
		PaddingLeft = 8,
		PaddingRight = 8,
		ZIndex = 6,
	})
	element.Input = input

	input.Options.OnFocus = function()
		if stroke then tween(stroke, "Fast", { Color = TC(Color3.fromRGB(90, 90, 90)) }) end
	end
	input.Options.OnBlur = function(text)
		if stroke then tween(stroke, "Out", { Color = TC(Color3.fromRGB(45, 45, 45)) }) end
		element.CurrentValue = text
		registerFlag(element, text)
		safeCallback(options.Callback, text)
		if options.ClearOnSubmit then
			task.delay(0.05, function() input:SetText("", true) end)
		end
	end
	box.InputButton.MouseButton1Click:Connect(function()
		input:Focus()
	end)

	function element:Set(text: string, silent: boolean?)
		element.CurrentValue = text
		input:SetText(text, true)
		registerFlag(element, text)
		if not silent then
			safeCallback(options.Callback, text)
		end
	end
	element.GetSaveValue = function() return element.CurrentValue end
	element.LoadSaveValue = function(_, value)
		if type(value) == "string" then element:Set(value) end
	end

	input:SetText(element.CurrentValue, true)
	registerFlag(element, element.CurrentValue)
	return self:_mount(element, row, options)
end
SectionClass.CreateTextbox = SectionClass.CreateInput

--========================================================= Selector =================================================--

function SectionClass:CreateSelector(options)
	options = options or {}
	local optionList = options.Options or { "A", "B" }
	local element = {
		Type = "Selector",
		CurrentOption = options.CurrentOption or optionList[1],
	}
	element.DefaultValue = element.CurrentOption

	local row = Templates.Selector:Clone()
	row.Name = "Selector"
	local label = nameLabel(row)
	label.Text = options.Name or "Selector"
	local holder = row.SelectionsHolder

	local oldLayout = holder:FindFirstChildOfClass("UIListLayout")
	if oldLayout then oldLayout:Destroy() end
	local oldPadding = holder:FindFirstChildOfClass("UIPadding")
	if oldPadding then oldPadding:Destroy() end
	pcall(function() holder.AutomaticSize = Enum.AutomaticSize.None end)

	local templateLabel = nameLabel(Templates.SelectorOption)
	local optionTextSize = templateLabel.TextSize

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.AnchorPoint = Vector2.new(0, 0.5)
	indicator.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	indicator.Size = UDim2.new(0, 0, 0, 24)
	indicator.Position = UDim2.new(0, 4, 0.5, 0)
	indicator.Visible = false
	indicator.ZIndex = 2
	indicator.Parent = holder
	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0, 7)
	indicatorCorner.Parent = indicator
	local indicatorStroke = Instance.new("UIStroke")
	indicatorStroke.Thickness = 1
	indicatorStroke.Color = Color3.fromRGB(90, 90, 90)
	indicatorStroke.Transparency = 0.25
	indicatorStroke.Parent = indicator
	themeRegister(indicator)
	themeRegister(indicatorStroke)
	themeApply(indicator)
	themeApply(indicatorStroke)

	local COLOR_SELECTED = Color3.fromRGB(196, 196, 196)
	local COLOR_IDLE = Color3.fromRGB(106, 106, 106)
	local COLOR_HOVER = Color3.fromRGB(158, 158, 158)

	local PAD_X, GAP, EDGE = 9, 2, 4
	local entriesInOrder = {}
	local optionEntries = {}

	local function estimateWidth(text: string): number
		local length = utf8.len(text) or #text
		return math.max(26, math.ceil(length * optionTextSize * 0.56) + PAD_X * 2)
	end

	local MAX_OPTION_WIDTH = 118

	local function entryWidth(entry): number
		local ok, bounds = pcall(function() return entry.Label.TextBounds end)
		if ok and bounds and bounds.X and bounds.X > 1 then
			return math.clamp(math.ceil(bounds.X) + PAD_X * 2, 26, MAX_OPTION_WIDTH)
		end
		return math.min(entry.EstimatedWidth, MAX_OPTION_WIDTH)
	end

	-- lays everything out from current text bounds; safe to call repeatedly
	local function relayout()
		local x = EDGE
		for _, entry in ipairs(entriesInOrder) do
			entry.X = x
			entry.Width = entryWidth(entry)
			entry.Button.Position = UDim2.new(0, entry.X, 0.5, 0)
			entry.Button.Size = UDim2.new(0, entry.Width, 0, 24)
			x += entry.Width + GAP
		end
		holder.Size = UDim2.new(0, x - GAP + EDGE, 0, 30)
		local active = optionEntries[element.CurrentOption]
		if active then
			indicator.Visible = true
			indicator.Position = UDim2.new(0, active.X, 0.5, 0)
			indicator.Size = UDim2.new(0, active.Width, 0, 24)
		end
	end

	local relayoutScheduled = false
	local function scheduleRelayout()
		if relayoutScheduled then return end
		relayoutScheduled = true
		task.defer(function()
			relayoutScheduled = false
			relayout()
		end)
	end

	local function renderSelection(instant: boolean?)
		local info = instant and TweenInfo.new(0) or EASE.Out
		for optionName, entry in pairs(optionEntries) do
			local selected = optionName == element.CurrentOption
			tween(entry.Label, info, { TextColor3 = TC(selected and COLOR_SELECTED or COLOR_IDLE) })
		end
		local active = optionEntries[element.CurrentOption]
		if active then
			indicator.Visible = true
			local moveInfo = instant and TweenInfo.new(0) or TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			tween(indicator, moveInfo, {
				Position = UDim2.new(0, active.X, 0.5, 0),
				Size = UDim2.new(0, active.Width, 0, 24),
			})
		else
			indicator.Visible = false
		end
	end

	function element:Set(optionName: string, silent: boolean?)
		if not optionEntries[optionName] then return end
		element.CurrentOption = optionName
		renderSelection(false)
		registerFlag(element, optionName)
		if not silent then
			safeCallback(options.Callback, optionName)
		end
	end
	element.GetSaveValue = function() return element.CurrentOption end
	element.LoadSaveValue = function(_, value)
		if type(value) == "string" and optionEntries[value] then element:Set(value) end
	end

	for index, optionName in ipairs(optionList) do
		local button = Templates.SelectorOption:Clone()
		button.Name = "Option_" .. optionName
		button.LayoutOrder = index
		button.BackgroundTransparency = 1
		pcall(function() button.AutomaticSize = Enum.AutomaticSize.None end)
		button.AnchorPoint = Vector2.new(0, 0.5)
		button.ZIndex = 3
		local buttonPadding = button:FindFirstChildOfClass("UIPadding")
		if buttonPadding then buttonPadding:Destroy() end
		local buttonStroke = button:FindFirstChildOfClass("UIStroke")
		if buttonStroke then buttonStroke:Destroy() end
		local optionLabel = nameLabel(button)
		pcall(function() optionLabel.AutomaticSize = Enum.AutomaticSize.None end)
		optionLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		optionLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		optionLabel.Size = UDim2.new(1, 0, 1, 0)
		optionLabel.TextXAlignment = Enum.TextXAlignment.Center
		pcall(function() optionLabel.TextTruncate = Enum.TextTruncate.AtEnd end)
		optionLabel.ZIndex = 4
		optionLabel.Text = optionName

		button.MouseEnter:Connect(function()
			if element.CurrentOption ~= optionName then
				tween(optionLabel, "Fast", { TextColor3 = TC(COLOR_HOVER) })
			end
		end)
		button.MouseLeave:Connect(function()
			if element.CurrentOption ~= optionName then
				tween(optionLabel, "Out", { TextColor3 = TC(COLOR_IDLE) })
			end
		end)
		button.MouseButton1Click:Connect(function()
			element:Set(optionName)
		end)
		button.Parent = holder

		local entry = { Button = button, Label = optionLabel, X = 0, Width = 0, EstimatedWidth = estimateWidth(optionName) }
		table.insert(entriesInOrder, entry)
		optionEntries[optionName] = entry
		-- real glyph widths only exist once the engine measures the label — re-flow when they land
		pcall(function()
			optionLabel:GetPropertyChangedSignal("TextBounds"):Connect(scheduleRelayout)
		end)
	end

	relayout()
	task.delay(0.1, relayout)
	renderSelection(true)
	registerFlag(element, element.CurrentOption)
	onThemeRefresh(function() renderSelection(true) end)
	element.Render = renderSelection
	return self:_mount(element, row, options)
end

--========================================================= Label ====================================================--

function SectionClass:CreateLabel(options)
	options = options or {}
	local element = { Type = "Label" }
	local row = Instance.new("Frame")
	row.Name = "Label"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(0.92, 0, 0, 28)

	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(0.01, 0, 0.5, 0)
	label.Size = UDim2.new(0.98, 0, 1, 0)
	label.FontFace = FONT_BODY
	label.TextSize = 15
	label.TextColor3 = Color3.fromRGB(150, 150, 150)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Text = options.Name or "Label"
	label.Parent = row

	function element:Set(text: string)
		label.Text = text
		element.Name = text
		element.SearchText = string.lower(text)
	end

	return self:_mount(element, row, options)
end

--========================================================= Keybind (removed) ========================================--

-- The dedicated keybind row is gone: right-click any element to manage its binds instead.
-- Kept as a warning stub so older scripts don't hard-crash.
function SectionClass:CreateKeybind(options)
	warn("[ Amphibia Interface ] CreateKeybind was removed — right-click any element to add keybinds to it.")
	local element = { Type = "Label", CurrentKeybind = "None" }
	function element:Set() end
	return element
end
------------------------------------------------------------------------------------------------------------------------
--  Floating overlay windows (dropdown lists, colour picker)
------------------------------------------------------------------------------------------------------------------------

-- Creates a fullscreen catcher + positions `content` (scaled to match the window scale). Returns close().
local function openFloating(content: GuiObject, position: Vector2, onClose)
	local container = Instance.new("Frame")
	container.Name = "Floating"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 1, 0)
	container.ZIndex = 40
	container.Parent = ScreenGui

	local catcher = Instance.new("ImageButton")
	catcher.Name = "Catcher"
	catcher.BackgroundTransparency = 1
	catcher.ImageTransparency = 1
	catcher.Size = UDim2.new(1, 0, 1, 0)
	catcher.ZIndex = 40
	catcher.AutoButtonColor = false
	catcher.Parent = container

	local scale = content:FindFirstChild("FloatScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "FloatScale"
		scale.Parent = content
	end
	scale.Scale = MainScale.Scale

	pcall(function() content.Active = true end)
	content.Position = UDim2.new(0, position.X, 0, position.Y)
	content.Visible = true
	content.Parent = container

	local closed = false
	local function close()
		if closed then return end
		closed = true
		if onClose then onClose() end
		task.delay(0.18, function()
			container:Destroy()
		end)
	end
	catcher.MouseButton1Click:Connect(close)
	catcher.MouseButton2Click:Connect(close)
	return close, container
end

--========================================================= Dropdown =================================================--

function SectionClass:CreateDropdown(options)
	options = options or {}
	local optionList = table.clone(options.Options or {})
	local multiple = options.MultipleOptions == true

	local element = { Type = "Dropdown", Options = optionList }
	if multiple then
		local current = {}
		if type(options.CurrentOption) == "table" then
			for _, v in ipairs(options.CurrentOption) do current[v] = true end
		end
		element.Selected = current
	else
		element.CurrentOption = (type(options.CurrentOption) == "string" and options.CurrentOption)
			or (type(options.CurrentOption) == "table" and options.CurrentOption[1])
			or nil
	end
	element.DefaultValue = multiple and table.clone(options.CurrentOption or {}) or element.CurrentOption

	local row = Templates.Dropdown:Clone()
	row.Name = "Dropdown"
	local label = nameLabel(row)
	label.Text = options.Name or "Dropdown"
	local selectedFrame = row.DropdownSelectedFrame
	local pickedLabel = selectedFrame.Picked
	local arrowIcon = selectedFrame.Icon

	local openState = { close = nil }

	local function selectionText(): string
		if multiple then
			local picked = {}
			for _, optionName in ipairs(element.Options) do
				if element.Selected[optionName] then
					table.insert(picked, optionName)
				end
			end
			return #picked > 0 and table.concat(picked, ", ") or "None"
		end
		return element.CurrentOption or "None"
	end

	local pickedMeasure = selectedFrame:FindFirstChild("PickedMeasure")

	local function resizeChip()
		local textWidth = nil
		if pickedMeasure then
			local ok, bounds = pcall(function() return pickedMeasure.TextBounds end)
			if ok and bounds and bounds.X and bounds.X > 1 then
				textWidth = bounds.X
			end
		end
		if not textWidth then
			local text = pickedLabel.Text
			textWidth = (utf8.len(text) or #text) * pickedLabel.TextSize * 0.56
		end
		selectedFrame.Size = UDim2.new(0, math.clamp(math.ceil(textWidth) + 38, 70, 230), 0, 25)
	end

	if pickedMeasure then
		pcall(function()
			pickedMeasure:GetPropertyChangedSignal("TextBounds"):Connect(function()
				task.defer(resizeChip)
			end)
		end)
	end

	local function renderPicked()
		local text = selectionText()
		pickedLabel.Text = text
		if pickedMeasure then
			pickedMeasure.Text = text
		end
		resizeChip()
	end

	local function currentValue()
		if multiple then
			local picked = {}
			for _, optionName in ipairs(element.Options) do
				if element.Selected[optionName] then table.insert(picked, optionName) end
			end
			return picked
		end
		return element.CurrentOption
	end

	local function commit(silent: boolean?)
		renderPicked()
		registerFlag(element, currentValue())
		if not silent then
			safeCallback(options.Callback, currentValue())
		end
	end

	local hitButton = Instance.new("TextButton")
	hitButton.BackgroundTransparency = 1
	hitButton.Text = ""
	hitButton.Size = UDim2.new(1, 0, 1, 0)
	hitButton.ZIndex = 6
	hitButton.Parent = selectedFrame

	local function openDropdown()
		if openState.close then
			openState.close()
			return
		end
		local window = DropdownWindowTemplate:Clone()
		window.Name = "DropdownWindow"
		window.AutomaticSize = Enum.AutomaticSize.Y
		local width = math.clamp(selectedFrame.AbsoluteSize.X / math.max(MainScale.Scale, 0.01) + 24, 160, 230)
		window.Size = UDim2.new(0, width, 0, 0)
		window.ZIndex = 41

		-- шаблонную раскладку убираем: список строим сами, внутри скроллера
		local templateLayout = window:FindFirstChildOfClass("UIListLayout")
		if templateLayout then
			templateLayout:Destroy()
		end

		local count = math.max(#element.Options, 1)
		local contentHeight = count * DROPDOWN_ITEM_HEIGHT + (count - 1) * DROPDOWN_ITEM_GAP
		local viewHeight = math.min(contentHeight, DROPDOWN_MAX_HEIGHT - DROPDOWN_PADDING)
		local windowHeight = viewHeight + DROPDOWN_PADDING

		pcall(function() window.AutomaticSize = Enum.AutomaticSize.None end)
		window.Size = UDim2.new(0, width, 0, windowHeight)

		local list = Instance.new("ScrollingFrame")
		list.Name = "List"
		list.BackgroundTransparency = 1
		list.BorderSizePixel = 0
		list.Position = UDim2.new(0, 0, 0, 0)
		list.Size = UDim2.new(1, 0, 1, 0)
		list.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
		list.ScrollingDirection = Enum.ScrollingDirection.Y
		list.ScrollBarThickness = (contentHeight > viewHeight) and 2 or 0
		list.ScrollBarImageColor3 = Color3.fromRGB(88, 88, 88)
		list.ScrollBarImageTransparency = 0.35
		list.ClipsDescendants = true
		list.Active = true
		list.ZIndex = window.ZIndex
		pcall(function() list.VerticalScrollBarInset = Enum.ScrollBarInset.None end)
		list.Parent = window

		local listLayout = Instance.new("UIListLayout")
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, DROPDOWN_ITEM_GAP)
		listLayout.Parent = list

		local itemButtons = {}
		local function renderItems()
			for optionName, item in pairs(itemButtons) do
				local selected = multiple and element.Selected[optionName] or (element.CurrentOption == optionName)
				item.Check.Visible = selected
				tween(nameLabel(item), TweenInfo.new(0.12, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
					{ Position = UDim2.new(0, selected and 20 or 0, 0, 0) })
			end
		end

		for index, optionName in ipairs(element.Options) do
			local item = Templates.DropdownItem:Clone()
			item.Name = "Item_" .. index
			item.LayoutOrder = index
			item.ZIndex = 42
			pcall(function() item.AutomaticSize = Enum.AutomaticSize.None end)
			item.Size = UDim2.new(1, -4, 0, DROPDOWN_ITEM_HEIGHT)
			nameLabel(item).Text = optionName
			nameLabel(item).Position = UDim2.new(0, 0, 0, 0)
			pcall(function() nameLabel(item).TextTruncate = Enum.TextTruncate.AtEnd end)
			item.Check.Visible = false
			item.BackgroundTransparency = 1
			themeRegisterDeep(item)
			themeApplyDeep(item)
			item.MouseEnter:Connect(function()
				item.BackgroundTransparency = 0
			end)
			item.MouseLeave:Connect(function()
				item.BackgroundTransparency = 1
			end)
			item.MouseButton1Click:Connect(function()
				if multiple then
					element.Selected[optionName] = not element.Selected[optionName] or nil
					renderItems()
					commit()
				else
					element.CurrentOption = optionName
					renderItems()
					commit()
				end
			end)
			item.Parent = list
			itemButtons[optionName] = item
		end
		renderItems()
		themeRegisterDeep(window)
		themeApplyDeep(window)

		local scaleNow = math.max(MainScale.Scale, 0.01)
		local viewport = ScreenGui.AbsoluteSize
		local anchor = screenPointFor(selectedFrame.AbsolutePosition)

		-- точная высота: UIPadding 6+6, пункты по 25, шаг списка 5
		local exactHeight = windowHeight * scaleNow
		local windowWidth = width * scaleNow

		local chipHeight = selectedFrame.AbsoluteSize.Y
		if chipHeight < 5 then chipHeight = 25 * scaleNow end

		local x = math.clamp(
			anchor.X + selectedFrame.AbsoluteSize.X - windowWidth,
			8, math.max(8, viewport.X - windowWidth - 8))

		local y = anchor.Y + chipHeight + DROPDOWN_GAP * scaleNow
		local opensUpward = false
		if DROPDOWN_FLIP and y + exactHeight > viewport.Y - 8 then
			y = anchor.Y - exactHeight - DROPDOWN_GAP * scaleNow
			opensUpward = true
		end

		local target = Vector2.new(x, y)

		tween(arrowIcon, "Out", { Rotation = 180 })
		local close
		close = openFloating(window, target, function()
			openState.close = nil
			tween(arrowIcon, "Out", { Rotation = 0 })
			fadeOut(window, 0.14)
		end)
		openState.close = close

		window.Position = UDim2.new(0, target.X, 0, target.Y + (opensUpward and 4 or -4))
		fadeIn(window, 0.16)
		tween(window, "Out", { Position = UDim2.new(0, target.X, 0, target.Y) })
	end

	hitButton.MouseButton1Click:Connect(openDropdown)

	function element:Set(value, silent: boolean?)
		if multiple then
			element.Selected = {}
			if type(value) == "table" then
				for _, optionName in ipairs(value) do element.Selected[optionName] = true end
			end
		else
			element.CurrentOption = value
		end
		commit(silent)
	end

	function element:Refresh(newOptions, keepSelection: boolean?)
		element.Options = table.clone(newOptions or {})
		if multiple then
			if not keepSelection then element.Selected = {} end
		else
			if not keepSelection or not table.find(element.Options, element.CurrentOption) then
				element.CurrentOption = nil
			end
		end
		if openState.close then openState.close() end
		commit(true)
	end

	element.GetSaveValue = function() return currentValue() end
	element.LoadSaveValue = function(_, value) element:Set(value, false) end

	renderPicked()
	registerFlag(element, currentValue())
	return self:_mount(element, row, options)
end

--======================================================= Colour picker ==============================================--

-- Normalise the shared picker window's SV square so picking is mathematically correct.
do
	local square = ColorPickerWindow.ColorPicker
	local white = square.White
	local dark = square.Dark

	white.AnchorPoint = Vector2.new(0.5, 0.5)
	white.Position = UDim2.new(0.5, 0, 0.5, 0)
	white.Size = UDim2.new(1, 0, 1, 0)
	white.BackgroundColor3 = Color3.new(1, 1, 1)
	white.ZIndex = 2
	local whiteGradient = white:FindFirstChildOfClass("UIGradient")
	if whiteGradient then
		whiteGradient.Rotation = 0
		whiteGradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
		whiteGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
	end

	dark.AnchorPoint = Vector2.new(0.5, 0.5)
	dark.Position = UDim2.new(0.5, 0, 0.5, 0)
	dark.Size = UDim2.new(1, 0, 1, 0)
	dark.BackgroundColor3 = Color3.new(0, 0, 0)
	dark.ZIndex = 3
	local darkGradient = dark:FindFirstChildOfClass("UIGradient")
	if darkGradient then
		darkGradient.Rotation = 90
		darkGradient.Color = ColorSequence.new(Color3.new(0, 0, 0))
		darkGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
	end

	square.Knob.ZIndex = 5
	local knobStroke = square.Knob:FindFirstChildOfClass("UIStroke")
	if not knobStroke then
		knobStroke = Instance.new("UIStroke")
		knobStroke.Thickness = 1.6
		knobStroke.Color = Color3.new(1, 1, 1)
		knobStroke.Parent = square.Knob
	end

	ColorPickerWindow.ZIndex = 41

	for _, zone in ipairs({ square, ColorPickerWindow.ColorSlider, ColorPickerWindow.TransparencySlider }) do
		local hit = Instance.new("TextButton")
		hit.Name = "HitZone"
		hit.BackgroundTransparency = 1
		hit.AutoButtonColor = false
		hit.Text = ""
		hit.Size = UDim2.new(1, 0, 1, 0)
		hit.ZIndex = 8
		hit.Parent = zone
	end
end

local ColorPickerBusy = false

function SectionClass:CreateColorPicker(options)
	options = options or {}
	local element = {
		Type = "ColorPicker",
		Color = options.Color or Color3.fromRGB(143, 168, 160),
		Transparency = options.Transparency or 0,
	}
	element.DefaultValue = { Color = element.Color, Transparency = element.Transparency }

	local row = Templates.ColorPicker:Clone()
	row.Name = "ColorPicker"
	local label = nameLabel(row)
	label.Text = options.Name or "Color Picker"
	local preview = row.ColorPickerPreview
	local hexValueLabel = row.HexValue
	local valueButton = row.ValueButton

	local function toHex(color: Color3): string
		return ("%02X%02X%02X"):format(
			math.floor(color.R * 255 + 0.5),
			math.floor(color.G * 255 + 0.5),
			math.floor(color.B * 255 + 0.5))
	end

	local function renderRow()
		preview.BackgroundColor3 = element.Color
		hexValueLabel.Text = toHex(element.Color)
	end

	local function commit(silent: boolean?)
		renderRow()
		registerFlag(element, { __c = true,
			r = math.floor(element.Color.R * 255 + 0.5),
			g = math.floor(element.Color.G * 255 + 0.5),
			b = math.floor(element.Color.B * 255 + 0.5),
			t = element.Transparency })
		if not silent then
			safeCallback(options.Callback, element.Color, element.Transparency)
		end
	end

	function element:Set(color: Color3, transparency: number?, silent: boolean?)
		element.Color = color
		if transparency ~= nil then
			element.Transparency = math.clamp(transparency, 0, 1)
		end
		commit(silent)
	end
	element.GetSaveValue = function()
		return { __c = true,
			r = math.floor(element.Color.R * 255 + 0.5),
			g = math.floor(element.Color.G * 255 + 0.5),
			b = math.floor(element.Color.B * 255 + 0.5),
			t = element.Transparency }
	end
	element.LoadSaveValue = function(_, value)
		if type(value) == "table" and value.__c then
			element:Set(Color3.fromRGB(value.r or value[1] or 255, value.g or value[2] or 255, value.b or value[3] or 255), value.t or value[4] or 0)
		end
	end

	local function openPickerInner()
		local window = ColorPickerWindow
		local square = window.ColorPicker
		local squareKnob = square.Knob
		local hueSlider = window.ColorSlider
		local hueKnob = hueSlider.Knob
		local alphaSlider = window.TransparencySlider
		local alphaKnob = alphaSlider.Knob
		local hexHolder = window.HexUnputHolder
		local hexLabel = hexHolder:FindFirstChild("Hex")
		-- "Transparency" is a real GuiObject property, so dot-access would return the number,
		-- not the label — this exact collision froze the picker before
		local alphaLabel = hexHolder:FindFirstChild("Transparency")

		local h, s, v = element.Color:ToHSV()
		local alpha = element.Transparency

		local hexInput = nil
		local syncingHex = false

		local function renderWindow(skipHex: boolean?)
			local hueColor = Color3.fromHSV(h, 1, 1)
			local color = Color3.fromHSV(h, s, v)
			square.BackgroundColor3 = hueColor
			squareKnob.BackgroundColor3 = color
			squareKnob.Position = UDim2.new(math.clamp(s, 0.02, 0.98), 0, math.clamp(1 - v, 0.02, 0.98), 0)
			hueKnob.Position = UDim2.new(math.clamp(h, 0.01, 0.99), 0, 0.5, 0)
			alphaSlider.BackgroundColor3 = color
			alphaKnob.Position = UDim2.new(math.clamp(alpha, 0.01, 0.99), 0, 0.5, 0)
			if alphaLabel then
				alphaLabel.Text = ("%d%%"):format(math.floor(alpha * 100 + 0.5))
			end
			if hexInput and not skipHex then
				syncingHex = true
				hexInput:SetText(toHex(color), true)
				syncingHex = false
			end
			element.Color = color
			element.Transparency = alpha
			renderRow()
		end

		local function commitLive()
			commit(false)
		end

		-- hex input (SmoothInput over the label)
		if hexLabel then hexLabel.Visible = false end
		hexInput = SmoothInput.new({
			Parent = hexHolder,
			Font = FONT_BODY,
			TextSize = 14,
			TextColor = Color3.fromRGB(190, 190, 190),
			PlaceholderText = "",
			MaxLength = 6,
			AllowedPattern = "%x",
			PaddingLeft = 84,
			PaddingRight = 60,
			ZIndex = 44,
		})
		-- clicking anywhere in the hex box focuses the input
		local hexFocusButton = Instance.new("TextButton")
		hexFocusButton.Name = "HexFocus"
		hexFocusButton.BackgroundTransparency = 1
		hexFocusButton.Text = ""
		hexFocusButton.Position = UDim2.new(0, 58, 0, 0)
		hexFocusButton.Size = UDim2.new(1, -58, 1, 0)
		hexFocusButton.ZIndex = 46
		hexFocusButton.Parent = hexHolder
		hexFocusButton.MouseButton1Click:Connect(function()
			if hexInput then hexInput:Focus() end
		end)

		hexInput.Options.OnChanged = function(text)
			if syncingHex then return end
			if #text == 6 then
				local r = tonumber(text:sub(1, 2), 16)
				local g = tonumber(text:sub(3, 4), 16)
				local b = tonumber(text:sub(5, 6), 16)
				if r and g and b then
					h, s, v = Color3.fromRGB(r, g, b):ToHSV()
					renderWindow(true)
					commitLive()
				end
			end
		end

		local dragTarget = nil -- "sv" | "hue" | "alpha"
		local function applyDrag(position: Vector2)
			if dragTarget == "sv" then
				local relX = math.clamp((position.X - square.AbsolutePosition.X) / math.max(1, square.AbsoluteSize.X), 0, 1)
				local relY = math.clamp((position.Y - square.AbsolutePosition.Y) / math.max(1, square.AbsoluteSize.Y), 0, 1)
				s, v = relX, 1 - relY
			elseif dragTarget == "hue" then
				h = math.clamp((position.X - hueSlider.AbsolutePosition.X) / math.max(1, hueSlider.AbsoluteSize.X), 0, 1)
			elseif dragTarget == "alpha" then
				alpha = math.clamp((position.X - alphaSlider.AbsolutePosition.X) / math.max(1, alphaSlider.AbsoluteSize.X), 0, 1)
			end
			renderWindow()
			commitLive()
		end

		local zoneConnections = {}
		local function bindZone(zone: GuiObject, target: string)
			local hit = zone:FindFirstChild("HitZone") or zone
			table.insert(zoneConnections, hit.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragTarget = target
					applyDrag(Vector2.new(input.Position.X, input.Position.Y))
				end
			end))
		end
		bindZone(square, "sv")
		bindZone(hueSlider, "hue")
		bindZone(alphaSlider, "alpha")
		table.insert(zoneConnections, UserInputService.InputChanged:Connect(function(input)
			if dragTarget and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				applyDrag(Vector2.new(input.Position.X, input.Position.Y))
			end
		end))
		table.insert(zoneConnections, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragTarget = nil
			end
		end))

		-- positioning: prefer the right side of the row, clamp on-screen
		local anchor = screenPointFor(preview.AbsolutePosition)
		local scaleNow = MainScale.Scale
		local windowWidth, windowHeight = 195 * scaleNow, 301 * scaleNow
		local viewport = ScreenGui.AbsoluteSize
		local x = math.clamp(anchor.X + preview.AbsoluteSize.X + 12, 8, viewport.X - windowWidth - 8)
		local y = math.clamp(anchor.Y - windowHeight / 2, 8, viewport.Y - windowHeight - 8)

		window.AnchorPoint = Vector2.new(0, 0)
		renderWindow()

		local close
		close = openFloating(window, Vector2.new(x, y), function()
			ColorPickerBusy = false
			for _, connection in ipairs(zoneConnections) do connection:Disconnect() end
			if hexInput then hexInput:Destroy() end
			hexFocusButton:Destroy()
			if hexLabel then hexLabel.Visible = true end
			fadeOut(window, 0.15, true)
			task.delay(0.155, function()
				window.Visible = false
				window.Parent = OtherFolder
			end)
			commit(false)
		end)

		fadeIn(window, 0.18)
		local floatScale = window:FindFirstChild("FloatScale")
		if floatScale then
			floatScale.Scale = MainScale.Scale * 0.9
			tween(floatScale, "Back", { Scale = MainScale.Scale })
		end
	end

	local function openPicker()
		if ColorPickerBusy then return end
		ColorPickerBusy = true
		local ok, err = pcall(openPickerInner)
		if not ok then
			ColorPickerBusy = false
			warn("[ Amphibia Interface ] Color picker failed to open: " .. tostring(err))
			reportInterfaceIssue("Interface error")
		end
	end

	preview.MouseButton1Click:Connect(openPicker)
	valueButton.MouseButton1Click:Connect(openPicker)
	attachRowHover(row, label)

	renderRow()
	commit(true)
	return self:_mount(element, row, options)
end

------------------------------------------------------------------------------------------------------------------------
--  Tabs / categories / window
------------------------------------------------------------------------------------------------------------------------

local TabClass = {}
TabClass.__index = TabClass

local WindowClass = {}
WindowClass.__index = WindowClass

function WindowClass:_getCategory(categoryName: string)
	categoryName = categoryName or "Main"
	local existing = self.Categories[categoryName]
	if existing then
		return existing
	end
	local frame = Templates.Category:Clone()
	frame.Name = categoryName .. "Category"
	frame.CategoryText.Text = categoryName
	self.CategoryOrder += 1
	frame.LayoutOrder = self.CategoryOrder
	themeRegisterDeep(frame)
	themeApplyDeep(frame)
	frame.Parent = TabsHolder
	local category = { Name = categoryName, Frame = frame, TabsHolder = frame.TabsHolder, TabOrder = 0 }
	self.Categories[categoryName] = category
	return category
end

function WindowClass:CreateCategory(categoryName: string)
	return self:_getCategory(categoryName)
end

local function styleTabButton(button: TextButton, active: boolean, instant: boolean?)
	local buttonLabel = nameLabel(button)
	local shadow = buttonLabel and buttonLabel:FindFirstChildOfClass("UIShadow")
	local info = instant and TweenInfo.new(0) or EASE.Out
	if buttonLabel then
		tween(buttonLabel, info, {
			TextColor3 = TC(active and Color3.fromRGB(230, 230, 230) or Color3.fromRGB(188, 188, 188)),
			Position = UDim2.new(0, active and 4 or 0, 0.5, 0),
		})
	end
	if shadow then
		tween(shadow, info, { Transparency = active and 0.1 or 0.8 })
	end
end

function WindowClass:CreateTab(options)
	options = options or {}
	local tabName = options.Name or "Tab"
	local category = self:_getCategory(options.Category or "Main")

	local self2 = setmetatable({}, TabClass)
	self2.Window = self
	self2.Name = tabName
	self2.CategoryName = category.Name
	self2.Sections = {}
	self2.Elements = {}
	self2.IsConfig = false

	local page = Templates.Page:Clone()
	page.Name = "Tab_" .. tabName
	page.Visible = false
	local scroller = page.ScrollingFrame
	self2.Page = page
	self2.Scroller = scroller
	self2.LeftColumn = scroller.LeftColumn
	self2.RightColumn = scroller.RightColumn
	local tabInfo = scroller.TabInfoFrameHolder
	tabInfo.TabName.Text = tabName
	tabInfo.TabGroupName.Text = category.Name
	themeRegisterDeep(page)
	themeApplyDeep(page)
	page.Parent = Pages

	local button = Templates.TabButton:Clone()
	button.Name = tabName .. "TabButton"
	pcall(function() button.AutomaticSize = Enum.AutomaticSize.X end)
	nameLabel(button).Text = tabName
	category.TabOrder += 1
	button.LayoutOrder = category.TabOrder
	themeRegisterDeep(button)
	themeApplyDeep(button)
	styleTabButton(button, false, true)
	onThemeRefresh(function()
		styleTabButton(button, self.ActiveTab == self2, true)
	end)
	button.Parent = category.TabsHolder
	self2.Button = button

	button.MouseButton1Click:Connect(function()
		self:SelectTab(self2)
	end)
	button.MouseEnter:Connect(function()
		if self.ActiveTab ~= self2 then
			local buttonLabel = nameLabel(button)
			tween(buttonLabel, "Fast", { TextColor3 = TC(Color3.fromRGB(215, 215, 215)) })
		end
	end)
	button.MouseLeave:Connect(function()
		if self.ActiveTab ~= self2 then
			styleTabButton(button, false)
		end
	end)

	table.insert(self.Tabs, self2)
	if not self.ActiveTab then
		self:SelectTab(self2, true)
	end
	return self2
end

function TabClass:CreateSection(options)
	return createSection(self, options)
end

local function refreshTabVisuals(tab)
	if not tab or tab.IsConfig then return end
	for _, element in ipairs(tab.Elements) do
		if element.Render then
			pcall(element.Render, true)
		end
	end
end

function WindowClass:SelectTab(tab, instant: boolean?)
	if self.ActiveTab == tab then
		return
	end
	local previous = self.ActiveTab
	self.ActiveTab = tab

	if previous then
		styleTabButton(previous.Button, false, instant)
		local previousPage = previous.IsConfig and ConfigPage or previous.Page
		if instant then
			previousPage.Visible = false
		else
			fadeOut(previousPage, 0.15)
		end
	end
	styleTabButton(tab.Button, true, instant)

	local page = tab.IsConfig and ConfigPage or tab.Page
	if instant then
		primeFade(page)
		page.Visible = true
		refreshTabVisuals(tab)
	else
		task.delay(previous and 0.1 or 0, function()
			page.Position = UDim2.new(0.5, 0, 0.5, 10)
			fadeIn(page, 0.22)
			tween(page, "Out", { Position = UDim2.new(0.5, 0, 0.5, 0) })
			task.delay(0.24, function() refreshTabVisuals(tab) end)
		end)
	end
	if tab.IsConfig and self.OnConfigTabOpened then
		task.spawn(self.OnConfigTabOpened)
	end
end

-- Search is a palette: dim the content, list every match with its type, and jump to it on click.

local SearchInput -- assigned below, after the palette plumbing

local SearchUI = {}
SearchUI.Dim = Instance.new("TextButton")
SearchUI.Dim.Name = "SearchDim"
SearchUI.Dim.Text = ""
SearchUI.Dim.AutoButtonColor = false
SearchUI.Dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SearchUI.Dim.BackgroundTransparency = 1
SearchUI.Dim.Position = UDim2.new(0, 0, 0, 0)
SearchUI.Dim.Size = UDim2.new(1, 0, 1, 0)
SearchUI.Dim.Visible = false
SearchUI.Dim.ZIndex = 30
SearchUI.Dim.Parent = Main
do
	-- the dim is exactly the window: same footprint, same corner radius
	local mainCorner = Main:FindFirstChildOfClass("UICorner")
	local dimCorner = Instance.new("UICorner")
	dimCorner.CornerRadius = mainCorner and mainCorner.CornerRadius or UDim.new(0, 20)
	dimCorner.Parent = SearchUI.Dim
end

-- the header sits above the main dim while searching, so it gets its own dim layer;
-- only the search bar (raised above it) stays bright
SearchUI.HeaderDim = Instance.new("Frame")
SearchUI.HeaderDim.Name = "HeaderDim"
SearchUI.HeaderDim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SearchUI.HeaderDim.BackgroundTransparency = 1
SearchUI.HeaderDim.Size = UDim2.new(1, 0, 1, 0)
SearchUI.HeaderDim.Visible = false
SearchUI.HeaderDim.ZIndex = 5
SearchUI.HeaderDim.Parent = Header
do
	local mainCorner = Main:FindFirstChildOfClass("UICorner")
	local dimCorner = Instance.new("UICorner")
	dimCorner.CornerRadius = mainCorner and mainCorner.CornerRadius or UDim.new(0, 20)
	dimCorner.Parent = SearchUI.HeaderDim
end

SearchUI.HeaderZDefault = Header.ZIndex
SearchUI.SearchBgZDefault = Header.SearchBg.ZIndex

SearchUI.Panel = Instance.new("Frame")
SearchUI.Panel.Name = "SearchPanel"
SearchUI.Panel.AnchorPoint = Vector2.new(0.5, 0)
SearchUI.Panel.Position = UDim2.new(0.5, 0, 0, 66)
SearchUI.Panel.Size = UDim2.new(0, 460, 0, 120)
SearchUI.Panel.BackgroundColor3 = Color3.fromRGB(14, 14, 15)
SearchUI.Panel.Visible = false
SearchUI.Panel.ZIndex = 31
SearchUI.Panel.Parent = Main
do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = SearchUI.Panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(46, 46, 46)
	stroke.Thickness = 1
	stroke.Parent = SearchUI.Panel
	themeRegister(SearchUI.Panel)
	themeRegister(stroke)
	pcall(function()
		local shadow = Instance.new("UIShadow")
		shadow.Color = Color3.fromRGB(0, 0, 0)
		shadow.Transparency = 0.3
		shadow.BlurRadius = UDim.new(0, 18)
		shadow.Parent = SearchUI.Panel
	end)
end

SearchUI.Results = Instance.new("ScrollingFrame")
SearchUI.Results.Name = "Results"
SearchUI.Results.BackgroundTransparency = 1
SearchUI.Results.Position = UDim2.new(0, 8, 0, 8)
SearchUI.Results.Size = UDim2.new(1, -16, 1, -16)
SearchUI.Results.CanvasSize = UDim2.new(0, 0, 0, 0)
SearchUI.Results.ScrollBarThickness = 2
SearchUI.Results.ScrollBarImageColor3 = Color3.fromRGB(88, 88, 88)
SearchUI.Results.ScrollBarImageTransparency = 0.35
pcall(function() SearchUI.Results.VerticalScrollBarInset = Enum.ScrollBarInset.None end)
SearchUI.Results.ZIndex = 31
SearchUI.Results.Parent = SearchUI.Panel
pcall(function() SearchUI.Results.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
do
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = SearchUI.Results
end

SearchUI.Empty = Instance.new("TextLabel")
SearchUI.Empty.Name = "Empty"
SearchUI.Empty.BackgroundTransparency = 1
SearchUI.Empty.Size = UDim2.new(1, 0, 0, 46)
SearchUI.Empty.FontFace = FONT_BODY
SearchUI.Empty.TextSize = 14
SearchUI.Empty.TextColor3 = Color3.fromRGB(100, 100, 100)
SearchUI.Empty.Text = "No matches found."
SearchUI.Empty.Visible = false
SearchUI.Empty.ZIndex = 31
SearchUI.Empty.Parent = SearchUI.Panel
themeRegister(SearchUI.Empty)

SearchUI.Hide = function()
	if SearchUI.Panel.Visible then
		tween(SearchUI.Dim, "Fast", { BackgroundTransparency = 1 })
		tween(SearchUI.HeaderDim, "Fast", { BackgroundTransparency = 1 })
		task.delay(0.14, function()
			SearchUI.Dim.Visible = false
			SearchUI.HeaderDim.Visible = false
			Header.ZIndex = SearchUI.HeaderZDefault
			Header.SearchBg.ZIndex = SearchUI.SearchBgZDefault
		end)
		fadeOut(SearchUI.Panel, 0.13)
	end
end

function WindowClass:_collectSearchResults(query: string)
	query = string.lower(query)
	local results = {}
	local function push(result)
		if #results < 30 then
			table.insert(results, result)
		end
	end
	for _, tab in ipairs(self.Tabs) do
		if tab.IsConfig then
			if string.find(string.lower(tab.Name), query, 1, true) then
				push({ Type = "Tab", Name = tab.Name, Tab = tab, Path = tab.CategoryName })
			end
			continue
		end
		if string.find(string.lower(tab.Name), query, 1, true) then
			push({ Type = "Tab", Name = tab.Name, Tab = tab, Path = tab.CategoryName })
		end
		for _, section in ipairs(tab.Sections) do
			if string.find(string.lower(section.Name), query, 1, true) then
				push({ Type = "Section", Name = section.Name, Tab = tab, Section = section, Path = tab.Name })
			end
			for _, elementEntry in ipairs(section.Elements) do
				if string.find(elementEntry.SearchText or "", query, 1, true) then
					push({ Type = elementEntry.Type, Name = elementEntry.Name, Tab = tab,
						Section = section, Element = elementEntry, Path = tab.Name .. "  ·  " .. section.Name })
				end
			end
		end
	end
	return results
end

function WindowClass:_navigateToResult(result)
	SearchInput:SetText("", true)
	SearchInput:Blur()
	SearchUI.Hide()
	self:SelectTab(result.Tab)
	if result.Section and result.Section.Collapsed then
		result.Section:SetCollapsed(false)
	end
	if result.Tab.IsConfig then
		return
	end
	task.delay(0.3, function()
		local target = (result.Element and result.Element.Root) or (result.Section and result.Section.Root)
		if not target or not target.Parent then
			return
		end
		local scroller = result.Tab.Scroller
		local scale = math.max(MainScale.Scale, 0.01)
		local canvasY = (scroller.CanvasPosition and scroller.CanvasPosition.Y) or 0
		local offsetY = (target.AbsolutePosition.Y - scroller.AbsolutePosition.Y) / scale + canvasY - 90
		pcall(function()
			tween(scroller, "Slow", { CanvasPosition = Vector2.new(0, math.max(0, offsetY)) })
		end)
		-- highlight pulse so the eye lands on the right row
		local highlight = Instance.new("UIStroke")
		highlight.Thickness = 1.5
		highlight.Color = TC(BASE_ACCENT)
		highlight.Transparency = 0.25
		highlight.Parent = target
		task.delay(0.9, function()
			tween(highlight, "Slow", { Transparency = 1 })
			task.delay(0.5, function() highlight:Destroy() end)
		end)
	end)
end

SearchUI.TypeLabels = {
	Tab = "TAB", Section = "SECTION", Toggle = "TOGGLE", Slider = "SLIDER", Button = "BUTTON",
	NumberPicker = "NUMBER", Input = "INPUT", Selector = "SELECTOR", Dropdown = "DROPDOWN",
	ColorPicker = "COLOR", Keybind = "KEYBIND", Label = "LABEL",
}

function WindowClass:ApplySearch(query: string)
	self.SearchQuery = query
	if query == nil or query == "" then
		SearchUI.Hide()
		return
	end

	for _, child in ipairs(SearchUI.Results:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local results = self:_collectSearchResults(query)
	SearchUI.Empty.Visible = #results == 0

	for index, result in ipairs(results) do
		local rowButton = Instance.new("TextButton")
		rowButton.Name = "Result_" .. index
		rowButton.Text = ""
		rowButton.AutoButtonColor = false
		rowButton.BackgroundColor3 = Color3.fromRGB(27, 27, 28)
		rowButton.BackgroundTransparency = 1
		rowButton.Size = UDim2.new(1, 0, 0, 38)
		rowButton.LayoutOrder = index
		rowButton.ZIndex = 32
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 9)
		rowCorner.Parent = rowButton

		local chip = Instance.new("Frame")
		chip.Name = "TypeChip"
		chip.AnchorPoint = Vector2.new(0, 0.5)
		chip.Position = UDim2.new(0, 10, 0.5, 0)
		chip.Size = UDim2.new(0, 64, 0, 18)
		chip.BackgroundColor3 = Color3.fromRGB(24, 24, 25)
		chip.ZIndex = 33
		chip.Parent = rowButton
		local chipCorner = Instance.new("UICorner")
		chipCorner.CornerRadius = UDim.new(0, 5)
		chipCorner.Parent = chip
		local chipStroke = Instance.new("UIStroke")
		chipStroke.Color = Color3.fromRGB(52, 52, 52)
		chipStroke.Thickness = 1
		chipStroke.Parent = chip
		local chipLabel = Instance.new("TextLabel")
		chipLabel.BackgroundTransparency = 1
		chipLabel.Size = UDim2.new(1, 0, 1, 0)
		chipLabel.FontFace = FONT_BODY
		chipLabel.TextSize = 9
		chipLabel.TextColor3 = Color3.fromRGB(128, 128, 128)
		chipLabel.Text = SearchUI.TypeLabels[result.Type] or string.upper(result.Type)
		chipLabel.ZIndex = 33
		chipLabel.Parent = chip

		local nameText = Instance.new("TextLabel")
		nameText.Name = "ResultName"
		nameText.BackgroundTransparency = 1
		nameText.AnchorPoint = Vector2.new(0, 0.5)
		nameText.Position = UDim2.new(0, 88, 0.5, 0)
		nameText.Size = UDim2.new(1, -250, 1, 0)
		nameText.FontFace = FONT_BODY
		nameText.TextSize = 14
		nameText.TextColor3 = Color3.fromRGB(196, 196, 196)
		nameText.TextXAlignment = Enum.TextXAlignment.Left
		nameText.Text = result.Name
		pcall(function() nameText.TextTruncate = Enum.TextTruncate.AtEnd end)
		nameText.ZIndex = 33
		nameText.Parent = rowButton

		local pathText = Instance.new("TextLabel")
		pathText.BackgroundTransparency = 1
		pathText.AnchorPoint = Vector2.new(1, 0.5)
		pathText.Position = UDim2.new(1, -12, 0.5, 0)
		pathText.Size = UDim2.new(0, 150, 1, 0)
		pathText.FontFace = FONT_BODY
		pathText.TextSize = 12
		pathText.TextColor3 = Color3.fromRGB(88, 88, 88)
		pathText.TextXAlignment = Enum.TextXAlignment.Right
		pathText.Text = result.Path or ""
		pcall(function() pathText.TextTruncate = Enum.TextTruncate.AtEnd end)
		pathText.ZIndex = 33
		pathText.Parent = rowButton

		for _, guiObject in ipairs({ rowButton, chip, chipStroke, chipLabel, nameText, pathText }) do
			themeRegister(guiObject)
			themeApply(guiObject)
		end

		local hoverInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		rowButton.MouseEnter:Connect(function()
			tween(rowButton, hoverInfo, { BackgroundTransparency = 0 })
			tween(nameText, hoverInfo, { Position = UDim2.new(0, 94, 0.5, 0), TextColor3 = TC(Color3.fromRGB(228, 228, 228)) })
			tween(chipLabel, hoverInfo, { TextColor3 = TC(Color3.fromRGB(160, 160, 160)) })
		end)
		rowButton.MouseLeave:Connect(function()
			tween(rowButton, hoverInfo, { BackgroundTransparency = 1 })
			tween(nameText, hoverInfo, { Position = UDim2.new(0, 88, 0.5, 0), TextColor3 = TC(Color3.fromRGB(196, 196, 196)) })
			tween(chipLabel, hoverInfo, { TextColor3 = TC(Color3.fromRGB(128, 128, 128)) })
		end)
		rowButton.MouseButton1Click:Connect(function()
			self:_navigateToResult(result)
		end)
		rowButton.Parent = SearchUI.Results
	end

	local visibleRows = math.max(1, math.min(#results, 8))
	SearchUI.Panel.Size = UDim2.new(0, 460, 0, (#results == 0 and 58) or visibleRows * 40 + 14)

	if not SearchUI.Panel.Visible then
		SearchUI.Dim.Visible = true
		SearchUI.Dim.BackgroundTransparency = 1
		SearchUI.HeaderDim.Visible = true
		SearchUI.HeaderDim.BackgroundTransparency = 1
		Header.ZIndex = 31
		Header.SearchBg.ZIndex = 6
		tween(SearchUI.Dim, "Fast", { BackgroundTransparency = 0.42 })
		tween(SearchUI.HeaderDim, "Fast", { BackgroundTransparency = 0.42 })
		primeFade(SearchUI.Panel)
		fadeIn(SearchUI.Panel, 0.16)
	end
end

SearchUI.Dim.MouseButton1Click:Connect(function()
	SearchInput:SetText("", true)
	SearchInput:Blur()
	SearchUI.Hide()
end)

function WindowClass:SetKeybindsListMode(mode: string)
	KeybindsUI.SetMode(mode)
end

function WindowClass:SetToggleKey(keyName: string)
	settingsTable.General.amphibiaOpen.Value = keyName
	saveSettings()
end

function WindowClass:SetStatus(text, connected)
	AmphibiaLibrary:SetStatus(text, connected)
end

function WindowClass:Notify(settings)
	return AmphibiaLibrary:Notify(settings)
end

function WindowClass:SetTheme(themeName: string)
	AmphibiaLibrary:SetTheme(themeName)
end

function WindowClass:Toggle(open: boolean?)
	if open == nil then open = not WindowOpen end
	setWindowOpen(open)
end

function WindowClass:Destroy()
	for _, connection in ipairs(Connections) do
		pcall(function() connection:Disconnect() end)
	end
	ScreenGui:Destroy()
	ActiveWindow = nil
end

------------------------------------------------------------------------------------------------------------------------
--  Theme switching
------------------------------------------------------------------------------------------------------------------------

function AmphibiaLibrary:SetTheme(themeName: string)
	if not Themes[themeName] then
		warn("[ Amphibia Interface ] Unknown theme: " .. tostring(themeName))
		return
	end
	CurrentThemeName = themeName
	for instance in pairs(ThemeRegistry) do
		if instance.Parent ~= nil or instance == ScreenGui then
			themeApply(instance)
		end
	end
	for _, refresher in ipairs(ThemeRefreshers) do
		pcall(refresher)
	end
	settingsTable.General.theme = settingsTable.General.theme or { Type = "input", Value = "Default", Name = "Theme" }
	settingsTable.General.theme.Value = themeName
	saveSettings()
end

function AmphibiaLibrary:GetTheme(): string
	return CurrentThemeName
end

function AmphibiaLibrary:GetThemes()
	local list = {}
	for themeName in pairs(Themes) do
		table.insert(list, themeName)
	end
	table.sort(list)
	return list
end

------------------------------------------------------------------------------------------------------------------------
--  Header search
------------------------------------------------------------------------------------------------------------------------

do
	local searchBg = Header.SearchBg
	searchBg.SearchTextbox.Visible = false
	local searchStroke = searchBg:FindFirstChildOfClass("UIStroke")

	SearchInput = SmoothInput.new({
		Parent = searchBg,
		Font = FONT_BODY,
		TextSize = 14,
		TextColor = Color3.fromRGB(170, 170, 170),
		PlaceholderText = "search",
		PlaceholderColor = Color3.fromRGB(85, 85, 85),
		PlaceholderTransparency = 0.15,
		MaxLength = 40,
		PaddingLeft = 34,
		PaddingRight = 12,
		ZIndex = 12,
	})
	SearchInput.Options.OnFocus = function()
		if searchStroke then tween(searchStroke, "Fast", { Color = TC(Color3.fromRGB(95, 95, 95)) }) end
		tween(searchBg.SearchIcon, "Fast", { ImageColor3 = TC(Color3.fromRGB(160, 160, 160)) })
	end
	SearchInput.Options.OnBlur = function()
		if searchStroke then tween(searchStroke, "Out", { Color = TC(Color3.fromRGB(60, 60, 60)) }) end
		tween(searchBg.SearchIcon, "Out", { ImageColor3 = TC(Color3.fromRGB(100, 100, 100)) })
	end
	SearchInput.Options.OnChanged = function(text)
		if ActiveWindow then
			ActiveWindow:ApplySearch(text)
		end
	end

	connect(UserInputService.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if input.KeyCode ~= Enum.KeyCode.Escape then return end
		if not SearchUI.Panel.Visible then return end
		SearchInput:SetText("", true)
		SearchInput:Blur()
		SearchUI.Hide()
	end)

	local clickCatcher = Instance.new("TextButton")
	clickCatcher.BackgroundTransparency = 1
	clickCatcher.Text = ""
	clickCatcher.Size = UDim2.new(1, 0, 1, 0)
	clickCatcher.ZIndex = 11
	clickCatcher.Parent = searchBg
	clickCatcher.MouseButton1Click:Connect(function()
		SearchInput:Focus()
	end)
end

------------------------------------------------------------------------------------------------------------------------
--  Right-click bind menu — attach custom keybinds to any element
------------------------------------------------------------------------------------------------------------------------

BindSystem.MakeKeyChip = function(parent, initialText, zindex)
	local chip = Instance.new("TextButton")
	chip.Name = "KeyChip"
	chip.AutoButtonColor = false
	chip.Text = ""
	chip.AnchorPoint = Vector2.new(1, 0.5)
	chip.BackgroundColor3 = Color3.fromRGB(30, 30, 31)
	chip.Size = UDim2.new(0, 58, 0, 20)
	chip.ZIndex = zindex
	chip.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = chip
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(58, 58, 58)
	stroke.Thickness = 1
	stroke.Parent = chip
	local chipText = Instance.new("TextLabel")
	chipText.BackgroundTransparency = 1
	chipText.Size = UDim2.new(1, -6, 1, 0)
	chipText.Position = UDim2.new(0, 3, 0, 0)
	chipText.FontFace = FONT_MONO
	chipText.TextSize = 11
	chipText.TextColor3 = Color3.fromRGB(172, 172, 172)
	chipText.Text = initialText
	pcall(function() chipText.TextTruncate = Enum.TextTruncate.AtEnd end)
	chipText.ZIndex = zindex
	chipText.Parent = chip
	for _, guiObject in ipairs({ chip, stroke, chipText }) do
		themeRegister(guiObject)
		themeApply(guiObject)
	end
	chip.MouseEnter:Connect(function()
		tween(stroke, "Fast", { Color = TC(Color3.fromRGB(95, 95, 95)) })
	end)
	chip.MouseLeave:Connect(function()
		tween(stroke, "Out", { Color = TC(Color3.fromRGB(58, 58, 58)) })
	end)
	return chip, chipText, stroke
end

BindSystem.MenuOpen = false
local BIND_Z = 45

BindSystem.MakeLabel = function(parent, text, size, color)
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.FontFace = FONT_BODY
	textLabel.TextSize = size
	textLabel.TextColor3 = color
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Text = text
	textLabel.ZIndex = BIND_Z
	textLabel.Parent = parent
	themeRegister(textLabel)
	themeApply(textLabel)
	return textLabel
end

BindSystem.MakeInputBox = function(context, order, labelText, placeholder, numeric, defaultText)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 26)
	row.LayoutOrder = order
	row.ZIndex = BIND_Z
	row.Parent = context.editor
	local rowLabel = BindSystem.MakeLabel(row, labelText, 12, Color3.fromRGB(115, 115, 115))
	rowLabel.AnchorPoint = Vector2.new(0, 0.5)
	rowLabel.Position = UDim2.new(0, 0, 0.5, 0)
	rowLabel.Size = UDim2.new(0, 52, 1, 0)
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, 0, 0.5, 0)
	box.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
	box.Size = UDim2.new(1, -58, 1, 0)
	box.ZIndex = BIND_Z
	box.Parent = row
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = box
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(44, 44, 44)
	stroke.Thickness = 1
	stroke.Parent = box
	themeRegister(box)
	themeRegister(stroke)
	themeApply(box)
	themeApply(stroke)
	local input = SmoothInput.new({
		Parent = box,
		Font = FONT_BODY,
		TextSize = 13,
		TextColor = Color3.fromRGB(180, 180, 180),
		PlaceholderText = placeholder,
		PlaceholderColor = Color3.fromRGB(95, 95, 95),
		MaxLength = 40,
		AllowedPattern = numeric and "%d%.%-" or nil,
		PaddingLeft = 8,
		PaddingRight = 8,
		ZIndex = BIND_Z + 1,
	})
	input.Options.OnFocus = function()
		tween(stroke, "Fast", { Color = TC(Color3.fromRGB(85, 85, 85)) })
	end
	input.Options.OnBlur = function()
		tween(stroke, "Out", { Color = TC(Color3.fromRGB(44, 44, 44)) })
	end
	local focusCatcher = Instance.new("TextButton")
	focusCatcher.BackgroundTransparency = 1
	focusCatcher.Text = ""
	focusCatcher.Size = UDim2.new(1, 0, 1, 0)
	focusCatcher.ZIndex = BIND_Z
	focusCatcher.Parent = box
	focusCatcher.MouseButton1Click:Connect(function()
		input:Focus()
	end)
	if defaultText and defaultText ~= "" then
		input:SetText(defaultText, true)
	end
	table.insert(context.activeInputs, input)
	return input
end

BindSystem.OpenMenu = function(element, position)
	if BindSystem.MenuOpen then return end
	BindSystem.MenuOpen = true

	local activeInputs = {}
	local Z = BIND_Z

	local panel = Instance.new("Frame")
	panel.Name = "BindMenu"
	panel.BackgroundColor3 = Color3.fromRGB(16, 16, 17)
	panel.Size = UDim2.new(0, 264, 0, 10)
	pcall(function() panel.AutomaticSize = Enum.AutomaticSize.Y end)
	panel.ZIndex = Z
	do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = panel
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(52, 52, 52)
		stroke.Thickness = 1
		stroke.Parent = panel
		pcall(function()
			local shadow = Instance.new("UIShadow")
			shadow.Color = Color3.fromRGB(0, 0, 0)
			shadow.Transparency = 0.35
			shadow.BlurRadius = UDim.new(0, 16)
			shadow.Parent = panel
		end)
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 12)
		padding.PaddingRight = UDim.new(0, 12)
		padding.PaddingTop = UDim.new(0, 12)
		padding.PaddingBottom = UDim.new(0, 12)
		padding.Parent = panel
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 8)
		layout.Parent = panel
		themeRegister(panel)
		themeRegister(stroke)
	end

	local function makeSeparator(parent, order)
		local line = Instance.new("Frame")
		line.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
		line.BackgroundTransparency = 0.55
		line.BorderSizePixel = 0
		line.Size = UDim2.new(1, 0, 0, 1)
		line.LayoutOrder = order
		line.ZIndex = Z
		line.Parent = parent
		themeRegister(line)
		themeApply(line)
		return line
	end

	-- header ------------------------------------------------------------------------------------------------
	local headerRow = Instance.new("Frame")
	headerRow.BackgroundTransparency = 1
	headerRow.Size = UDim2.new(1, 0, 0, 38)
	headerRow.LayoutOrder = 1
	headerRow.ZIndex = Z
	headerRow.Parent = panel
	local title = BindSystem.MakeLabel(headerRow, "Keybinds", 16, Color3.fromRGB(212, 212, 212))
	title.FontFace = FONT_SERIF
	title.Size = UDim2.new(1, 0, 0, 19)
	local subtitle = BindSystem.MakeLabel(headerRow, element.Name or element.Type, 11, Color3.fromRGB(108, 108, 108))
	subtitle.Position = UDim2.new(0, 0, 0, 21)
	subtitle.Size = UDim2.new(1, 0, 0, 13)
	pcall(function() subtitle.TextTruncate = Enum.TextTruncate.AtEnd end)
	makeSeparator(panel, 2)

	-- existing binds ----------------------------------------------------------------------------------------
	local bindsHolder = Instance.new("Frame")
	bindsHolder.BackgroundTransparency = 1
	bindsHolder.Size = UDim2.new(1, 0, 0, 0)
	pcall(function() bindsHolder.AutomaticSize = Enum.AutomaticSize.Y end)
	bindsHolder.LayoutOrder = 3
	bindsHolder.ZIndex = Z
	bindsHolder.Parent = panel
	local bindsLayout = Instance.new("UIListLayout")
	bindsLayout.FillDirection = Enum.FillDirection.Vertical
	bindsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bindsLayout.Padding = UDim.new(0, 4)
	bindsLayout.Parent = bindsHolder

	local renderBinds -- forward
	renderBinds = function()
		for _, child in ipairs(bindsHolder:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local binds = BindSystem.ForElement(element)
		if #binds == 0 then
			local empty = BindSystem.MakeLabel(bindsHolder, "No keybinds yet — add one below.", 11, Color3.fromRGB(92, 92, 92))
			empty.Size = UDim2.new(1, 0, 0, 16)
			return
		end
		for index, bind in ipairs(binds) do
			local bindRow = Instance.new("Frame")
			bindRow.BackgroundTransparency = 1
			bindRow.Size = UDim2.new(1, 0, 0, 26)
			bindRow.LayoutOrder = index
			bindRow.ZIndex = Z
			bindRow.Parent = bindsHolder

			local bindName = BindSystem.MakeLabel(bindRow, bind.Name, 13, Color3.fromRGB(186, 186, 186))
			bindName.AnchorPoint = Vector2.new(0, 0.5)
			bindName.Position = UDim2.new(0, 0, 0.5, 0)
			bindName.Size = UDim2.new(1, -96, 1, 0)
			pcall(function() bindName.TextTruncate = Enum.TextTruncate.AtEnd end)

			local chip, chipText = BindSystem.MakeKeyChip(bindRow, keyDisplayName(bind.Key), Z)
			chip.Position = UDim2.new(1, -26, 0.5, 0)
			chip.MouseButton1Click:Connect(function()
				chipText.Text = "..."
				captureBindKey(function(newKey)
					if newKey then
						bind.Key = newKey
						BindSystem.Changed()
						ConfigHooks.Autosave()
					end
					if chipText.Parent then
						chipText.Text = keyDisplayName(bind.Key)
					end
					KeybindsUI.Refresh()
				end)
			end)

			local deleteButton = Instance.new("TextButton")
			deleteButton.AutoButtonColor = false
			deleteButton.BackgroundTransparency = 1
			deleteButton.AnchorPoint = Vector2.new(1, 0.5)
			deleteButton.Position = UDim2.new(1, 0, 0.5, 0)
			deleteButton.Size = UDim2.new(0, 20, 0, 20)
			deleteButton.FontFace = FONT_BODY
			deleteButton.TextSize = 15
			deleteButton.TextColor3 = Color3.fromRGB(110, 110, 110)
			deleteButton.Text = "×"
			deleteButton.ZIndex = Z
			deleteButton.Parent = bindRow
			deleteButton.MouseEnter:Connect(function()
				tween(deleteButton, "Fast", { TextColor3 = Color3.fromRGB(214, 118, 118) })
			end)
			deleteButton.MouseLeave:Connect(function()
				tween(deleteButton, "Out", { TextColor3 = TC(Color3.fromRGB(110, 110, 110)) })
			end)
			deleteButton.MouseButton1Click:Connect(function()
				BindSystem.Remove(bind)
				renderBinds()
			end)
		end
	end

	-- "+ new" toggle ----------------------------------------------------------------------------------------
	local addRow = Instance.new("TextButton")
	addRow.Name = "AddRow"
	addRow.AutoButtonColor = false
	addRow.BackgroundTransparency = 1
	addRow.Size = UDim2.new(1, 0, 0, 22)
	addRow.FontFace = FONT_BODY
	addRow.TextSize = 13
	addRow.TextXAlignment = Enum.TextXAlignment.Left
	addRow.TextColor3 = Color3.fromRGB(150, 150, 150)
	addRow.Text = "+  New keybind"
	addRow.LayoutOrder = 4
	addRow.ZIndex = Z
	addRow.Parent = panel
	themeRegister(addRow)
	themeApply(addRow)
	addRow.MouseEnter:Connect(function()
		tween(addRow, "Fast", { TextColor3 = TC(Color3.fromRGB(215, 215, 215)) })
	end)
	addRow.MouseLeave:Connect(function()
		tween(addRow, "Out", { TextColor3 = TC(Color3.fromRGB(150, 150, 150)) })
	end)

	-- editor ------------------------------------------------------------------------------------------------
	local modes = { "Press" }
	do
		local byType = {
			Toggle = { "Toggle", "Hold" }, Button = { "Press" },
			Slider = { "Set value" }, NumberPicker = { "Set value" }, Input = { "Set value" },
			Selector = { "Set value" }, Dropdown = { "Set value" },
		}
		modes = byType[element.Type] or { "Press" }
	end
	local hasValue = element.Type == "Slider" or element.Type == "NumberPicker" or element.Type == "Input"
		or element.Type == "Selector" or element.Type == "Dropdown"
	local pendingMode = modes[1]
	local pendingKey = "None"

	local editor = Instance.new("Frame")
	editor.Name = "Editor"
	editor.BackgroundTransparency = 1
	editor.Size = UDim2.new(1, 0, 0, 0)
	pcall(function() editor.AutomaticSize = Enum.AutomaticSize.Y end)
	editor.Visible = false
	editor.LayoutOrder = 5
	editor.ZIndex = Z
	editor.Parent = panel
	local editorLayout = Instance.new("UIListLayout")
	editorLayout.FillDirection = Enum.FillDirection.Vertical
	editorLayout.SortOrder = Enum.SortOrder.LayoutOrder
	editorLayout.Padding = UDim.new(0, 6)
	editorLayout.Parent = editor
	makeSeparator(editor, 0)

	local editorContext = { editor = editor, activeInputs = activeInputs }
	local nameInput = BindSystem.MakeInputBox(editorContext, 1, "Name", "bind name", false, nil)

	local keyRow = Instance.new("Frame")
	keyRow.Name = "KeyRow"
	keyRow.BackgroundTransparency = 1
	keyRow.Size = UDim2.new(1, 0, 0, 26)
	keyRow.LayoutOrder = 2
	keyRow.ZIndex = Z
	keyRow.Parent = editor
	local keyLabel = BindSystem.MakeLabel(keyRow, "Key", 12, Color3.fromRGB(115, 115, 115))
	keyLabel.AnchorPoint = Vector2.new(0, 0.5)
	keyLabel.Position = UDim2.new(0, 0, 0.5, 0)
	keyLabel.Size = UDim2.new(0, 52, 1, 0)
	local keyChip, keyChipText = BindSystem.MakeKeyChip(keyRow, "click to bind", Z)
	keyChip.Position = UDim2.new(1, 0, 0.5, 0)
	keyChip.Size = UDim2.new(0, 92, 0, 20)
	keyChip.MouseButton1Click:Connect(function()
		keyChipText.Text = "..."
		captureBindKey(function(newKey)
			if newKey then
				pendingKey = newKey
			end
			if keyChipText.Parent then
				keyChipText.Text = pendingKey == "None" and "click to bind" or keyDisplayName(pendingKey)
			end
		end)
	end)

	local modeButtons = {}
	if #modes > 1 then
		local modeRow = Instance.new("Frame")
		modeRow.BackgroundTransparency = 1
		modeRow.Size = UDim2.new(1, 0, 0, 26)
		modeRow.LayoutOrder = 3
		modeRow.ZIndex = Z
		modeRow.Parent = editor
		local modeLabel = BindSystem.MakeLabel(modeRow, "Mode", 12, Color3.fromRGB(115, 115, 115))
		modeLabel.AnchorPoint = Vector2.new(0, 0.5)
		modeLabel.Position = UDim2.new(0, 0, 0.5, 0)
		modeLabel.Size = UDim2.new(0, 52, 1, 0)
		local function renderModes()
			for modeName, modeButton in pairs(modeButtons) do
				local selected = modeName == pendingMode
				tween(modeButton, "Fast", { BackgroundTransparency = selected and 0 or 1 })
				tween(modeButton.ModeText, "Fast", { TextColor3 = TC(selected and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(105, 105, 105)) })
			end
		end
		local xOffset = 0
		for _, modeName in ipairs(modes) do
			local modeButton = Instance.new("TextButton")
			modeButton.AutoButtonColor = false
			modeButton.Text = ""
			modeButton.AnchorPoint = Vector2.new(1, 0.5)
			modeButton.Position = UDim2.new(1, -xOffset, 0.5, 0)
			modeButton.Size = UDim2.new(0, 52, 0, 20)
			modeButton.BackgroundColor3 = Color3.fromRGB(38, 38, 39)
			modeButton.BackgroundTransparency = 1
			modeButton.ZIndex = Z
			modeButton.Parent = modeRow
			local modeCorner = Instance.new("UICorner")
			modeCorner.CornerRadius = UDim.new(0, 6)
			modeCorner.Parent = modeButton
			local modeText = Instance.new("TextLabel")
			modeText.Name = "ModeText"
			modeText.BackgroundTransparency = 1
			modeText.Size = UDim2.new(1, 0, 1, 0)
			modeText.FontFace = FONT_BODY
			modeText.TextSize = 11
			modeText.TextColor3 = Color3.fromRGB(105, 105, 105)
			modeText.Text = modeName
			modeText.ZIndex = Z
			modeText.Parent = modeButton
			themeRegister(modeButton)
			themeRegister(modeText)
			modeButton.MouseButton1Click:Connect(function()
				pendingMode = modeName
				renderModes()
			end)
			modeButtons[modeName] = modeButton
			xOffset += 56
		end
		renderModes()
	end

	local valueInput = nil
	if hasValue then
		local defaultValue = ""
		if element.Type == "Slider" or element.Type == "NumberPicker" then
			defaultValue = tostring(element.CurrentValue or "")
		elseif element.Type == "Input" then
			defaultValue = tostring(element.CurrentValue or "")
		elseif element.Type == "Selector" then
			defaultValue = tostring(element.CurrentOption or "")
		elseif element.Type == "Dropdown" then
			defaultValue = type(element.CurrentOption) == "string" and element.CurrentOption or ""
		end
		local numeric = element.Type == "Slider" or element.Type == "NumberPicker"
		valueInput = BindSystem.MakeInputBox(editorContext, 4, "Value", numeric and "value to set" or "value / option to set", numeric, defaultValue)
	end

	local createButton = Instance.new("TextButton")
	createButton.Name = "CreateButton"
	createButton.AutoButtonColor = false
	createButton.Text = ""
	createButton.BackgroundColor3 = Color3.fromRGB(33, 33, 34)
	createButton.Size = UDim2.new(1, 0, 0, 28)
	createButton.LayoutOrder = 5
	createButton.ZIndex = Z
	createButton.Parent = editor
	do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 7)
		corner.Parent = createButton
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(64, 64, 64)
		stroke.Thickness = 1
		stroke.Parent = createButton
		themeRegister(createButton)
		themeRegister(stroke)
		themeApply(createButton)
		themeApply(stroke)
	end
	local createText = Instance.new("TextLabel")
	createText.BackgroundTransparency = 1
	createText.Size = UDim2.new(1, 0, 1, 0)
	createText.FontFace = FONT_BODY
	createText.TextSize = 13
	createText.TextColor3 = Color3.fromRGB(205, 205, 205)
	createText.Text = "Create bind"
	createText.ZIndex = Z
	createText.Parent = createButton
	themeRegister(createText)
	themeApply(createText)
	createButton.MouseEnter:Connect(function()
		tween(createButton, "Fast", { BackgroundColor3 = TC(Color3.fromRGB(46, 46, 47)) })
	end)
	createButton.MouseLeave:Connect(function()
		tween(createButton, "Out", { BackgroundColor3 = TC(Color3.fromRGB(36, 36, 37)) })
	end)

	local function setEditorOpen(open)
		editor.Visible = open
		addRow.Text = open and "−  Cancel" or "+  New keybind"
	end
	addRow.MouseButton1Click:Connect(function()
		setEditorOpen(not editor.Visible)
	end)

	createButton.MouseButton1Click:Connect(function()
		if pendingKey == "None" then
			keyChipText.Text = "set a key!"
			task.delay(1.1, function()
				if keyChipText.Parent and pendingKey == "None" then
					keyChipText.Text = "click to bind"
				end
			end)
			return
		end
		local bindName = nameInput.Text
		if bindName == "" then
			bindName = element.Name or element.Type
		end
		BindSystem.Add({
			Element = element,
			Name = bindName,
			Key = pendingKey,
			Mode = pendingMode,
			Value = valueInput and valueInput.Text or nil,
		})
		pendingKey = "None"
		keyChipText.Text = "click to bind"
		nameInput:SetText("", true)
		setEditorOpen(false)
		renderBinds()
	end)

	renderBinds()a

	-- position & open ---------------------------------------------------------------------------------------
	local viewport = ScreenGui.AbsoluteSize
	local scaleNow = math.max(MainScale.Scale, 0.01)
	local panelWidth = 264 * scaleNow
	local x = math.clamp(position.X, 8, math.max(8, viewport.X - menuWidth - 8))
	local y = math.clamp(position.Y, 8, math.max(8, viewport.Y - menuHeight - 8))

	openFloating(panel, Vector2.new(x, y), function()
		BindSystem.MenuOpen = false
		for _, input in ipairs(activeInputs) do
			pcall(function() input:Destroy() end)
		end
		fadeOut(panel, 0.12)
	end)
	popWindow(panel)
	fadeIn(panel, 0.14)
end

------------------------------------------------------------------------------------------------------------------------
--  Interface reveal (after loading)
------------------------------------------------------------------------------------------------------------------------

local function revealInterface(window)
	local tab = window.ActiveTab
	local sections = tab and not tab.IsConfig and tab.Sections or {}

	-- pre-hide sections so they can pop in
	local scales = {}
	for _, section in ipairs(sections) do
		local targets = fadeTargets(section.Root)
		for instance, cache in pairs(targets) do
			for prop in pairs(cache) do
				pcall(function() instance[prop] = 1 end)
			end
		end
		local sectionScale = Instance.new("UIScale")
		sectionScale.Scale = 0.94
		sectionScale.Parent = section.Root
		scales[section] = sectionScale
	end

	fadeOut(LoadingScreen, 0.35)
	task.wait(0.2)

	InterfaceRevealed = true
	WindowOpen = true

	for index, section in ipairs(sections) do
		task.delay((index - 1) * 0.07, function()
			fadeIn(section.Root, 0.3)
			local sectionScale = scales[section]
			if sectionScale then
				tween(sectionScale, "Back", { Scale = 1 })
				task.delay(0.4, function() sectionScale:Destroy() end)
			end
		end)
	end

	task.delay(#sections * 0.07 + 0.4, function()
		refreshTabVisuals(tab)
	end)
end
------------------------------------------------------------------------------------------------------------------------
--  Configuration system
-----------------------------------------------------------------------------------------------------------------------

local Base64 do
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	Base64 = {
		encode = function(data: string): string
			return ((data:gsub(".", function(char)
				local bits, byte = "", char:byte()
				for i = 8, 1, -1 do
					bits ..= (byte % 2 ^ i - byte % 2 ^ (i - 1) > 0) and "1" or "0"
				end
				return bits
			end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(bits)
				if #bits < 6 then return "" end
				local index = 0
				for i = 1, 6 do
					index += (bits:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
				end
				return alphabet:sub(index + 1, index + 1)
			end) .. ({ "", "==", "=" })[#data % 3 + 1])
		end,
		decode = function(data: string): string?
			data = data:gsub("[^" .. alphabet .. "=]", "")
			local decoded = (data:gsub("=", ""):gsub(".", function(char)
				local bits, index = "", (alphabet:find(char, 1, true) or 1) - 1
				for i = 6, 1, -1 do
					bits ..= (index % 2 ^ i - index % 2 ^ (i - 1) > 0) and "1" or "0"
				end
				return bits
			end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(bits)
				if #bits ~= 8 then return "" end
				local byte = 0
				for i = 1, 8 do
					byte += (bits:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
				end
				return string.char(byte)
			end))
			return decoded
		end,
	}
end

local function timeAgo(timestamp: number?): string
	if not timestamp then return "" end
	local delta = os.time() - timestamp
	if delta < 60 then return "<1m ago" end
	if delta < 3600 then return math.floor(delta / 60) .. "m ago" end
	if delta < 86400 then return math.floor(delta / 3600) .. "h ago" end
	if delta < 604800 then return math.floor(delta / 86400) .. "d ago" end
	if delta < 2629800 then return math.floor(delta / 604800) .. "w ago" end
	if delta < 31557600 then return math.floor(delta / 2629800) .. "mo ago" end
	return math.floor(delta / 31557600) .. "y ago"
end

local ConfigSystem = {
	Dir = ConfigurationFolder,
	AutosaveFile = nil,
	AutosaveEnabled = false,
	AutosavePending = false,
	PendingFlags = nil,
	SelectedConfig = nil,
	LoadedConfig = nil,
	SearchQuery = "",
	Rows = {},
}

;(function()

local function collectFlags(): { [string]: any }
	local flags = {}
	for flagName, element in pairs(AmphibiaLibrary.Elements) do
		if element.GetSaveValue then
			local ok, value = pcall(element.GetSaveValue)
			if ok then
				flags[flagName] = value
			end
		end
	end
	return flags
end

local function applyFlags(flags: { [string]: any })
	for flagName, value in pairs(flags) do
		local element = AmphibiaLibrary.Elements[flagName]
		if element and element.LoadSaveValue then
			pcall(element.LoadSaveValue, element, value)
		end
	end
end

local function configPath(name: string): string
	return ConfigSystem.Dir .. "/" .. name .. ConfigurationExtension
end

local function readConfig(name: string)
	if not FS.isfile(configPath(name)) then return nil end
	local raw = FS.read(configPath(name))
	if not raw then return nil end
	local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok and type(decoded) == "table" then
		decoded.meta = decoded.meta or {}
		decoded.flags = decoded.flags or {}
		return decoded
	end
	return nil
end

local function writeConfig(name: string, data)
	local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
	if ok then
		return FS.write(configPath(name), json)
	end
	return false
end

------------------------------------------------------------------------------------------------------------------------
--  In-memory config index. The UI renders from here — never straight from disk — so laggy or
--  asynchronous executor file APIs can't produce ghost rows, missing dates or lost selections.
--  A background reconcile merges disk state in, with a grace window around our own writes/deletes.
------------------------------------------------------------------------------------------------------------------------

ConfigSystem.Index = {}            -- name -> { Created = number, Modified = number? }
ConfigSystem.RecentlyWritten = {}  -- name -> os.clock() of our last write
ConfigSystem.RecentlyDeleted = {}  -- name -> os.clock() of our last delete
local FS_GRACE = 2.5

local function indexWrite(name: string, meta)
	ConfigSystem.Index[name] = {
		Created = (meta and meta.created) or (ConfigSystem.Index[name] and ConfigSystem.Index[name].Created) or os.time(),
		Modified = meta and meta.modified,
	}
	ConfigSystem.RecentlyWritten[name] = os.clock()
	ConfigSystem.RecentlyDeleted[name] = nil
end

local function indexDelete(name: string)
	ConfigSystem.Index[name] = nil
	ConfigSystem.RecentlyDeleted[name] = os.clock()
	ConfigSystem.RecentlyWritten[name] = nil
end

-- disk write + index update in one place
local writeConfigRaw = writeConfig
writeConfig = function(name, data)
	local ok = writeConfigRaw(name, data)
	indexWrite(name, data and data.meta)
	return ok
end

local function deleteConfigFile(name: string)
	FS.delete(configPath(name))
	indexDelete(name)
end

local function listConfigs(): { { Name: string, Created: number? } }
	local out = {}
	for name, meta in pairs(ConfigSystem.Index) do
		table.insert(out, { Name = name, Created = meta.Created })
	end
	table.sort(out, function(a, b)
		if (a.Created or 0) == (b.Created or 0) then
			return a.Name < b.Name
		end
		return (a.Created or 0) > (b.Created or 0)
	end)
	return out
end

local refreshConfigs -- forward

local function reconcileConfigsWithDisk()
	local ok, files = pcall(FS.list, ConfigSystem.Dir)
	if not ok or type(files) ~= "table" then
		return
	end
	local now = os.clock()
	local onDisk = {}
	for _, path in ipairs(files) do
		local fileName = path:match("([^/\\]+)" .. ConfigurationExtension:gsub("%.", "%%.") .. "$")
		if fileName then
			onDisk[fileName] = true
		end
	end
	local changed = false
	-- new files discovered on disk
	for name in pairs(onDisk) do
		local graceDeleted = ConfigSystem.RecentlyDeleted[name] and now - ConfigSystem.RecentlyDeleted[name] < FS_GRACE
		if not ConfigSystem.Index[name] and not graceDeleted then
			local data = readConfig(name)
			if data then
				local created = data.meta and data.meta.created
				if not created then
					created = os.time()
					data.meta = data.meta or {}
					data.meta.created = created
					pcall(writeConfigRaw, name, data) -- best-effort backfill; index keeps it either way
				end
				ConfigSystem.Index[name] = { Created = created, Modified = data.meta and data.meta.modified }
			else
				ConfigSystem.Index[name] = { Created = os.time() } -- unreadable right now; keep it listed anyway
			end
			changed = true
		end
	end
	-- index entries whose file is gone (outside our own write grace window)
	local knownNames = {}
	for name in pairs(ConfigSystem.Index) do
		table.insert(knownNames, name)
	end
	for _, name in ipairs(knownNames) do
		local graceWritten = ConfigSystem.RecentlyWritten[name] and now - ConfigSystem.RecentlyWritten[name] < FS_GRACE
		if not onDisk[name] and not graceWritten then
			ConfigSystem.Index[name] = nil
			changed = true
		end
	end
	-- prune stale grace stamps
	for name, stamp in pairs(ConfigSystem.RecentlyWritten) do
		if now - stamp > FS_GRACE * 2 then ConfigSystem.RecentlyWritten[name] = nil end
	end
	for name, stamp in pairs(ConfigSystem.RecentlyDeleted) do
		if now - stamp > FS_GRACE * 2 then ConfigSystem.RecentlyDeleted[name] = nil end
	end
	if changed and refreshConfigs then
		refreshConfigs()
	end
end

local function scheduleReconcile()
	task.delay(0.7, reconcileConfigsWithDisk)
end

local VALID_CONFIG_NAME = "^[%w%-%_ %.]+$"

local function validateConfigName(text: string, allowExisting: string?)
	if text == "" then return false end
	if not text:match(VALID_CONFIG_NAME) then
		return "Only letters, numbers, spaces, - _ . allowed."
	end
	if #text > 32 then
		return "Name is too long."
	end
	if text ~= allowExisting and FS.isfile(configPath(text)) then
		return "That name already exists."
	end
	return true
end

-- autosave -----------------------------------------------------------------------------------------------------------

local autosaveScheduled = false
ConfigHooks.Autosave = function()
	if not ConfigSystem.AutosaveEnabled or not ConfigSystem.AutosaveFile then
		return
	end
	if autosaveScheduled then
		ConfigSystem.AutosavePending = true
		return
	end
	autosaveScheduled = true
	task.delay(0.8, function()
		autosaveScheduled = false
		local payload = { meta = { autosave = true, modified = os.time() }, flags = collectFlags(), binds = BindSystem.Serialize() }
		local ok, json = pcall(function() return HttpService:JSONEncode(payload) end)
		if ok then
			FS.write(ConfigSystem.AutosaveFile, json)
		end
		if ConfigSystem.AutosavePending then
			ConfigSystem.AutosavePending = false
			ConfigHooks.Autosave()
		end
	end)
end

ConfigHooks.OnElementRegistered = function(element)
	local pending = ConfigSystem.PendingFlags
	if pending and element.Flag and pending[element.Flag] ~= nil and element.LoadSaveValue then
		local value = pending[element.Flag]
		pending[element.Flag] = nil
		pcall(element.LoadSaveValue, element, value)
	end
end

local function loadAutosave()
	if not ConfigSystem.AutosaveFile or not FS.isfile(ConfigSystem.AutosaveFile) then
		return
	end
	local raw = FS.read(ConfigSystem.AutosaveFile)
	if not raw then return end
	local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok and type(decoded) == "table" and type(decoded.flags) == "table" then
		ConfigSystem.PendingFlags = decoded.flags
		applyFlags(decoded.flags)
		BindSystem.LoadSerialized(decoded.binds)
	end
end

-- config page UI -----------------------------------------------------------------------------------------------------

local ConfigsBg = ConfigPage.ConfigsBg
local ButtonsBg = ConfigPage.ButtonsBg
local ConfigScroller = ConfigsBg.ScrollingFrame
local ConfigTitle = nameLabel(ConfigsBg)
local ConfigInfo = ConfigTitle and ConfigTitle:FindFirstChild("Info")
local NoConfigsHolder = ConfigsBg.NoConfigsFrameHolder
local ConfigSearchFrame = ConfigsBg.SearchFrame


local function setSelectedConfig(name: string?)
	ConfigSystem.SelectedConfig = name
	for rowName, row in pairs(ConfigSystem.Rows) do
		local selected = rowName == name
		local stroke = row:FindFirstChildOfClass("UIStroke")
		tween(row, "Fast", { BackgroundTransparency = selected and 0 or 1 })
		if stroke then
			tween(stroke, "Fast", { Transparency = selected and 0 or 1 })
		end
	end
end

local function markLoadedConfig(name: string?)
	ConfigSystem.LoadedConfig = name
	for rowName, row in pairs(ConfigSystem.Rows) do
		local dot = row:FindFirstChild("EnabledDot")
		if dot then
			local loaded = rowName == name
			tween(dot, "Out", { BackgroundColor3 = loaded and TC(BASE_ACCENT) or TC(Color3.fromRGB(65, 65, 65)) })
			local shadow = dot:FindFirstChildOfClass("UIShadow")
			if shadow then
				tween(shadow, "Out", { Transparency = loaded and 0 or 1 })
			end
		end
	end
end

-- actions ------------------------------------------------------------------------------------------------------------

local TrashIconImage do
	local deleteButton = ConfigDropdownMenu:FindFirstChild("DeleteButton")
	local icon = deleteButton and deleteButton:FindFirstChild("Icon")
	TrashIconImage = icon and icon.Image or nil
end

local ConfigActions = {}

function ConfigActions.saveNew()
	task.spawn(function()
		local name = showInputPrompt({
			Title = "New config.",
			Description = "Choose a name for your new configuration.",
			ConfirmText = "Create",
			Placeholder = "my-config",
			MaxLength = 32,
			Validate = function(text) return validateConfigName(text) end,
		})
		if not name then return end
		writeConfig(name, { meta = { created = os.time(), modified = os.time() }, flags = collectFlags(), binds = BindSystem.Serialize() })
		refreshConfigs()
		scheduleReconcile()
		setSelectedConfig(name)
		markLoadedConfig(name)
		AmphibiaLibrary:Notify({ Color = "Green", Content = ("Config '%s' created."):format(name), Duration = 3 })
	end)
end

function ConfigActions.load(name: string?)
	name = name or ConfigSystem.SelectedConfig
	if not name then
		AmphibiaLibrary:Notify({ Color = "Yellow", Content = "Select a config first.", Duration = 3 })
		return
	end
	local data = readConfig(name)
	if not data then
		AmphibiaLibrary:Notify({ Color = "Red", Content = "That config could not be read.", Duration = 4 })
		return
	end
	applyFlags(data.flags)
	BindSystem.LoadSerialized(data.binds)
	markLoadedConfig(name)
	settingsTable.General.lastConfig.Value = name
	saveSettings()
	AmphibiaLibrary:Notify({ Color = "Green", Content = ("Config '%s' loaded."):format(name), Duration = 3 })
end

function ConfigActions.overwrite(name: string?)
	name = name or ConfigSystem.SelectedConfig
	if not name then
		AmphibiaLibrary:Notify({ Color = "Yellow", Content = "Select a config first.", Duration = 3 })
		return
	end
	task.spawn(function()
		local confirmed = showConfirm({
			Title = "Overwrite config?",
			Description = ("Current settings will replace everything stored in <b>%s</b>."):format(name),
			ConfirmText = "Overwrite",
		})
		if not confirmed then return end
		local existing = readConfig(name) or { meta = { created = os.time() } }
		existing.flags = collectFlags()
		existing.binds = BindSystem.Serialize()
		existing.meta.modified = os.time()
		writeConfig(name, existing)
		refreshConfigs()
		scheduleReconcile()
		setSelectedConfig(name)
		AmphibiaLibrary:Notify({ Color = "Green", Content = ("Config '%s' overwritten."):format(name), Duration = 3 })
	end)
end

function ConfigActions.rename(name: string?)
	name = name or ConfigSystem.SelectedConfig
	if not name then
		AmphibiaLibrary:Notify({ Color = "Yellow", Content = "Select a config first.", Duration = 3 })
		return
	end
	task.spawn(function()
		local newName = showInputPrompt({
			Title = "Rename config.",
			Description = ("Choose a new name for %s."):format(name),
			ConfirmText = "Rename",
			Default = name,
			MaxLength = 32,
			Validate = function(text) return validateConfigName(text, name) end,
		})
		if not newName or newName == name then return end
		local data = readConfig(name)
		if data then
			writeConfig(newName, data)
			deleteConfigFile(name)
			if ConfigSystem.LoadedConfig == name then ConfigSystem.LoadedConfig = newName end
			refreshConfigs()
			scheduleReconcile()
			setSelectedConfig(newName)
			markLoadedConfig(ConfigSystem.LoadedConfig)
			AmphibiaLibrary:Notify({ Color = "Green", Content = "Config renamed.", Duration = 3 })
		else
			AmphibiaLibrary:Notify({ Color = "Red", Content = "That config could not be read — try again in a moment.", Duration = 4 })
		end
	end)
end

function ConfigActions.duplicate(name: string?)
	name = name or ConfigSystem.SelectedConfig
	if not name then
		AmphibiaLibrary:Notify({ Color = "Yellow", Content = "Select a config first.", Duration = 3 })
		return
	end
	local data = readConfig(name)
	if not data then
		AmphibiaLibrary:Notify({ Color = "Red", Content = "That config could not be read — try again in a moment.", Duration = 4 })
		return
	end
	local copyName = name .. " copy"
	local counter = 2
	while ConfigSystem.Index[copyName] or FS.isfile(configPath(copyName)) do
		copyName = ("%s copy %d"):format(name, counter)
		counter += 1
	end
	data.meta = { created = os.time(), modified = os.time() }
	writeConfig(copyName, data)
	refreshConfigs()
	scheduleReconcile()
	setSelectedConfig(copyName)
	markLoadedConfig(ConfigSystem.LoadedConfig)
	AmphibiaLibrary:Notify({ Color = "Green", Content = ("Duplicated as '%s'."):format(copyName), Duration = 3 })
end

function ConfigActions.exportCode(name: string?)
	name = name or ConfigSystem.SelectedConfig
	local flags, binds
	if name then
		local data = readConfig(name)
		flags = data and data.flags
		binds = data and data.binds
	end
	flags = flags or collectFlags()
	binds = binds or BindSystem.Serialize()
	local ok, json = pcall(function() return HttpService:JSONEncode({ flags = flags, binds = binds }) end)
	if not ok then return end
	local code = "AMPH1." .. Base64.encode(json)
	if setClipboard(code) then
		AmphibiaLibrary:Notify({ Color = "Green", Content = "Share code copied to clipboard.", Duration = 4 })
	else
		AmphibiaLibrary:Notify({ Color = "Yellow", Content = "Clipboard unavailable — check console.", Duration = 4 })
		print("[ Amphibia ] Config share code:\n" .. code)
	end
end

function ConfigActions.importCode()
	task.spawn(function()
		local code = showInputPrompt({
			Title = "Import config.",
			Description = "Paste a share code (AMPH1.…) below.",
			ConfirmText = "Import",
			Placeholder = "AMPH1.…",
			MaxLength = 8000,
			Validate = function(text)
				if not text:match("^AMPH1%.") then return "That doesn't look like a share code." end
				return true
			end,
		})
		if not code then return end
		local payload = Base64.decode(code:sub(7))
		local ok, decoded = pcall(function() return HttpService:JSONDecode(payload or "") end)
		if not ok or type(decoded) ~= "table" or type(decoded.flags) ~= "table" then
			AmphibiaLibrary:Notify({ Color = "Red", Content = "Share code is corrupted.", Duration = 4 })
			return
		end
		local name = showInputPrompt({
			Title = "Name imported config.",
			Description = "Choose a name to store this configuration under.",
			ConfirmText = "Save",
			Placeholder = "imported-config",
			MaxLength = 32,
			Validate = function(text) return validateConfigName(text) end,
		})
		if not name then return end
		writeConfig(name, { meta = { created = os.time(), modified = os.time(), imported = true }, flags = decoded.flags, binds = decoded.binds })
		refreshConfigs()
		scheduleReconcile()
		setSelectedConfig(name)
		AmphibiaLibrary:Notify({ Color = "Green", Content = ("Config '%s' imported."):format(name), Duration = 3 })
	end)
end

function ConfigActions.resetSettings()
	task.spawn(function()
		local confirmed = showConfirm({
			Title = "Reset settings?",
			Description = "Every setting goes back to defaults — <font color=\"#C97F7F\">this can't be undone</font>. Your saved configs aren't affected.",
			ConfirmText = "Reset settings",
			Destructive = true,
		})
		if not confirmed then return end
		for _, element in pairs(AmphibiaLibrary.Elements) do
			if element.DefaultSave ~= nil and element.LoadSaveValue then
				pcall(element.LoadSaveValue, element, element.DefaultSave)
			end
		end
		markLoadedConfig(nil)
		settingsTable.General.lastConfig.Value = ""
		saveSettings()
		AmphibiaLibrary:Notify({ Color = "Yellow", Content = "All settings reset to defaults.", Duration = 4 })
	end)
end

function ConfigActions.delete(name: string?)
	name = name or ConfigSystem.SelectedConfig
	if not name then
		AmphibiaLibrary:Notify({ Color = "Yellow", Content = "Select a config first.", Duration = 3 })
		return
	end
	task.spawn(function()
		local confirmed = showConfirm({
			Title = "Delete config?",
			Description = ("<b>%s</b> will be <font color=\"#C97F7F\">removed permanently</font>. This can't be undone."):format(name),
			ConfirmText = "Delete",
			Destructive = true,
			Icon = TrashIconImage,
		})
		if not confirmed then return end
		deleteConfigFile(name)
		if ConfigSystem.SelectedConfig == name then ConfigSystem.SelectedConfig = nil end
		if ConfigSystem.LoadedConfig == name then
			ConfigSystem.LoadedConfig = nil
			settingsTable.General.lastConfig.Value = ""
			saveSettings()
		end
		refreshConfigs()
		scheduleReconcile()
		AmphibiaLibrary:Notify({ Color = "Green", Content = ("Config '%s' deleted."):format(name), Duration = 3 })
	end)
end

-- context menu -------------------------------------------------------------------------------------------------------

local function openConfigContextMenu(configName: string, position: Vector2)
	local menu = ConfigDropdownMenu:Clone()
	menu.Name = "ConfigMenu"
	menu.ZIndex = 45
	menu.Visible = true

	local actionsByButton = {
		LoadButton = function() ConfigActions.load(configName) end,
		RenameButton = function() ConfigActions.rename(configName) end,
		DuplicateButton = function() ConfigActions.duplicate(configName) end,
		OverwriteButton = function() ConfigActions.overwrite(configName) end,
		ExportCodeButton = function() ConfigActions.exportCode(configName) end,
		ResetButton = function() ConfigActions.resetSettings() end,
		DeleteButton = function() ConfigActions.delete(configName) end,
	}

	local closeMenu
	local hoverInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, child in ipairs(menu:GetChildren()) do
		if child:IsA("ImageButton") then
			-- every entry identical: same size, and the hover highlight lives on a fresh child
			-- frame we fully control — authored per-button quirks can't leak through anymore
			child.BackgroundTransparency = 1
			child.ZIndex = 46
			pcall(function() child.AutoButtonColor = false end)
			local action = actionsByButton[child.Name]
			local buttonLabel = nameLabel(child)
			local icon = child:FindFirstChild("Icon")
			local danger = child.Name == "DeleteButton"

			for _, grandChild in ipairs(child:GetChildren()) do
				if grandChild:IsA("GuiObject") then
					grandChild.ZIndex = 48
				end
			end
			local hoverFrame = Instance.new("Frame")
			hoverFrame.Name = "HoverBg"
			hoverFrame.BackgroundColor3 = danger and Color3.fromRGB(58, 42, 42) or Color3.fromRGB(45, 45, 45)
			hoverFrame.BackgroundTransparency = 1
			hoverFrame.BorderSizePixel = 0
			hoverFrame.Size = UDim2.new(1, 0, 1, 0)
			hoverFrame.ZIndex = 47
			hoverFrame.Parent = child
			local hoverCorner = Instance.new("UICorner")
			hoverCorner.CornerRadius = UDim.new(0, 6)
			hoverCorner.Parent = hoverFrame
			themeRegister(hoverFrame)
			themeApply(hoverFrame)

			local idleContent = danger and Color3.fromRGB(196, 122, 122) or TC(Color3.fromRGB(140, 140, 140))
			local hoverContent = danger and Color3.fromRGB(231, 144, 144) or TC(Color3.fromRGB(198, 198, 198))
			if buttonLabel then buttonLabel.TextColor3 = idleContent end
			if icon then icon.ImageColor3 = idleContent end

			-- one identical smooth hover for every entry (delete just uses its red palette)
			child.MouseEnter:Connect(function()
				tween(hoverFrame, hoverInfo, { BackgroundTransparency = 0 })
				if buttonLabel then tween(buttonLabel, hoverInfo, { TextColor3 = hoverContent }) end
				if icon then tween(icon, hoverInfo, { ImageColor3 = hoverContent }) end
			end)
			child.MouseLeave:Connect(function()
				tween(hoverFrame, hoverInfo, { BackgroundTransparency = 1 })
				if buttonLabel then tween(buttonLabel, hoverInfo, { TextColor3 = idleContent }) end
				if icon then tween(icon, hoverInfo, { ImageColor3 = idleContent }) end
			end)
			if action then
				child.MouseButton1Click:Connect(function()
					if closeMenu then closeMenu() end
					action()
				end)
			end
		elseif child:IsA("Frame") then
			child.ZIndex = 46
		end
	end

	themeRegisterDeep(menu)
	themeApplyDeep(menu)

	-- open next to the cursor (offset so no entry starts underneath it), clamped on-screen
	local viewport = ScreenGui.AbsoluteSize
	local scaleNow = math.max(MainScale.Scale, 0.01)
	local menuWidth = 153 * scaleNow
	local menuHeight = (CONFIG_MENU.PadY * 2
	+ 7 * CONFIG_MENU.ItemHeight
	+ 3 * CONFIG_MENU.SeparatorHeight
	+ 9 * CONFIG_MENU.ItemGap) * scaleNow
	local x = math.clamp(position.X, 8, math.max(8, viewport.X - menuWidth - 8))
	local y = math.clamp(position.Y, 8, math.max(8, viewport.Y - menuHeight - 8))

	closeMenu = openFloating(menu, Vector2.new(x, y), function()
		fadeOut(menu, 0.12)
	end)
	popWindow(menu)
end

-- list rendering -----------------------------------------------------------------------------------------------------

refreshConfigs = function()
	for _, child in ipairs(ConfigScroller:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	ConfigSystem.Rows = {}

	local configs = listConfigs()
	local query = string.lower(ConfigSystem.SearchQuery or "")
	local shown = 0

	for index, config in ipairs(configs) do
		if query ~= "" and not string.find(string.lower(config.Name), query, 1, true) then
			continue
		end
		shown += 1
		local row = Templates.ConfigEntry:Clone()
		row.Name = "Config_" .. config.Name
		row.LayoutOrder = index
		row.BackgroundTransparency = 1
		local stroke = row:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Transparency = 1 end
		local rowName = nameLabel(row)
		rowName.Text = config.Name
		pcall(function()
			rowName.AutomaticSize = Enum.AutomaticSize.None
			rowName.Size = UDim2.new(1, -(rowName.Position.X.Offset + 96), 1, 0)
			rowName.TextTruncate = Enum.TextTruncate.AtEnd
			rowName.TextXAlignment = Enum.TextXAlignment.Left
		end)
		row.Created.Text = timeAgo(config.Created)
		themeRegisterDeep(row)
		themeApplyDeep(row)
		local stale = ConfigScroller:FindFirstChild("Config_" .. config.Name)
		if stale then
			stale:Destroy()
		end

		local lastClick = 0
		row.MouseButton1Click:Connect(function()
			local now = os.clock()
			if ConfigSystem.SelectedConfig == config.Name and now - lastClick < 0.4 then
				ConfigActions.load(config.Name)
			else
				setSelectedConfig(config.Name)
			end
			lastClick = now
		end)
		row.MouseButton2Click:Connect(function()
			setSelectedConfig(config.Name)
			openConfigContextMenu(config.Name, mousePoint())
		end)
		row.MouseEnter:Connect(function()
			if ConfigSystem.SelectedConfig ~= config.Name then
				tween(row, "Fast", { BackgroundTransparency = 0.65 })
			end
		end)
		row.MouseLeave:Connect(function()
			if ConfigSystem.SelectedConfig ~= config.Name then
				tween(row, "Out", { BackgroundTransparency = 1 })
			end
		end)

		row.Parent = ConfigScroller
		ConfigSystem.Rows[config.Name] = row
	end

	NoConfigsHolder.Visible = shown == 0
	if ConfigInfo then
		ConfigInfo.Text = #configs == 1 and "1 config" or (#configs .. " configs")
	end
	setSelectedConfig(ConfigSystem.SelectedConfig)
	markLoadedConfig(ConfigSystem.LoadedConfig)
end

-- panel buttons ------------------------------------------------------------------------------------------------------

do
	local PANEL_STYLE = {
		Default = {
			Idle = { Bg = Color3.fromRGB(30, 30, 30), Stroke = Color3.fromRGB(65, 65, 65), Content = Color3.fromRGB(120, 120, 120) },
			Hover = { Bg = Color3.fromRGB(45, 45, 45), Stroke = Color3.fromRGB(85, 85, 85), Content = Color3.fromRGB(225, 225, 225) },
		},
		Accent = {
			Idle = { Bg = Color3.fromRGB(246, 243, 236), Stroke = Color3.fromRGB(246, 243, 236), Content = Color3.fromRGB(20, 19, 15) },
			Hover = { Bg = Color3.fromRGB(255, 253, 248), Stroke = Color3.fromRGB(255, 253, 248), Content = Color3.fromRGB(20, 19, 15) },
		},
		Danger = {
			Idle = { Bg = Color3.fromRGB(35, 30, 30), Stroke = Color3.fromRGB(80, 65, 65), Content = Color3.fromRGB(196, 122, 122) },
			Hover = { Bg = Color3.fromRGB(48, 38, 38), Stroke = Color3.fromRGB(105, 80, 80), Content = Color3.fromRGB(231, 144, 144) },
		},
	}

	local buttonBindings = {
		{ Button = "LoadButton", Style = "Accent", Action = function() ConfigActions.load(nil) end },
		{ Button = "NewButton", Style = "Default", Action = ConfigActions.saveNew },
		{ Button = "OverwriteButton", Style = "Default", Action = function() ConfigActions.overwrite(nil) end },
		{ Button = "RenameButton", Style = "Default", Action = function() ConfigActions.rename(nil) end },
		{ Button = "DuplicateButton", Style = "Default", Action = function() ConfigActions.duplicate(nil) end },
		{ Button = "ImportCodeButton", Style = "Default", Action = ConfigActions.importCode },
		{ Button = "ExportCodeButton", Style = "Default", Action = function() ConfigActions.exportCode(nil) end },
		{ Button = "ResetButton", Style = "Default", Action = ConfigActions.resetSettings },
		{ Button = "DeleteButton", Style = "Danger", Action = function() ConfigActions.delete(nil) end },
	}

	local idleAppliers = {}

	for _, binding in ipairs(buttonBindings) do
		local button = ButtonsBg:FindFirstChild(binding.Button)
		if not button then continue end
		local style = PANEL_STYLE[binding.Style]
		local buttonLabel = nameLabel(button)
		local icon = button:FindFirstChild("Icon")
		local stroke = button:FindFirstChildOfClass("UIStroke")
		local isDanger = binding.Style == "Danger"

		local pressScale = Instance.new("UIScale")
		pressScale.Parent = button

		-- everything routes through TC, so accent/danger follow the active theme consistently
		local function applyStyle(state, instant)
			local info = instant and TweenInfo.new(0) or EASE.Fast
			local content = isDanger and state.Content or TC(state.Content)
			tween(button, info, { BackgroundColor3 = TC(state.Bg) })
			if stroke then tween(stroke, info, { Color = isDanger and state.Stroke or TC(state.Stroke) }) end
			if buttonLabel then tween(buttonLabel, info, { TextColor3 = content }) end
			if icon then tween(icon, info, { ImageColor3 = content }) end
		end

		local hovered = false
		button.MouseEnter:Connect(function()
			hovered = true
			applyStyle(style.Hover)
		end)
		button.MouseLeave:Connect(function()
			hovered = false
			applyStyle(style.Idle)
		end)
		button.MouseButton1Click:Connect(function()
			pressScale.Scale = 0.96
			tween(pressScale, "Back", { Scale = 1 })
			binding.Action()
		end)

		-- the design left some buttons in preview/hover states — normalise them all to idle
		applyStyle(style.Idle, true)
		table.insert(idleAppliers, function()
			applyStyle(hovered and style.Hover or style.Idle, true)
		end)
	end

	onThemeRefresh(function()
		for _, apply in ipairs(idleAppliers) do
			apply()
		end
	end)
end

-- config search ------------------------------------------------------------------------------------------------------

do
	ConfigSearchFrame.Text.Visible = false
	local stroke = ConfigSearchFrame:FindFirstChildOfClass("UIStroke")
	local configSearch = SmoothInput.new({
		Parent = ConfigSearchFrame,
		Font = FONT_BODY,
		TextSize = 14,
		TextColor = Color3.fromRGB(170, 170, 170),
		PlaceholderText = "search configs",
		PlaceholderColor = Color3.fromRGB(120, 120, 120),
		MaxLength = 32,
		PaddingLeft = 28,
		PaddingRight = 8,
		ZIndex = 6,
	})
	configSearch.Options.OnChanged = function(text)
		ConfigSystem.SearchQuery = text
		refreshConfigs()
	end
	configSearch.Options.OnFocus = function()
		if stroke then tween(stroke, "Fast", { Color = TC(Color3.fromRGB(80, 80, 80)) }) end
	end
	configSearch.Options.OnBlur = function()
		if stroke then tween(stroke, "Out", { Color = TC(Color3.fromRGB(45, 45, 45)) }) end
	end
	ConfigSearchFrame.InputButton.MouseButton1Click:Connect(function()
		configSearch:Focus()
	end)
end

function WindowClass:CreateConfigTab(options)
	options = options or {}
	local tabName = options.Name or "Configs"
	local category = self:_getCategory(options.Category or "Menu")

	local tab = setmetatable({}, TabClass)
	tab.Window = self
	tab.Name = tabName
	tab.CategoryName = category.Name
	tab.Sections = {}
	tab.Elements = {}
	tab.IsConfig = true
	tab.Page = ConfigPage

	local button = Templates.TabButton:Clone()
	button.Name = tabName .. "TabButton"
	pcall(function() button.AutomaticSize = Enum.AutomaticSize.X end)
	nameLabel(button).Text = tabName
	category.TabOrder += 1
	button.LayoutOrder = category.TabOrder
	themeRegisterDeep(button)
	themeApplyDeep(button)
	styleTabButton(button, false, true)
	onThemeRefresh(function()
		styleTabButton(button, self.ActiveTab == tab, true)
	end)
	button.Parent = category.TabsHolder
	tab.Button = button

	button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	self.OnConfigTabOpened = function()
		reconcileConfigsWithDisk()
		refreshConfigs()
	end
	table.insert(self.Tabs, tab)
	if not self.ActiveTab then
		self:SelectTab(tab, true)
	end
	return tab
end

function WindowClass:LoadConfiguration()
	loadAutosave()
end

function WindowClass:SaveConfiguration()
	ConfigHooks.Autosave()
end

ConfigSystem.LoadAutosave = loadAutosave
end)()

------------------------------------------------------------------------------------------------------------------------
--  CreateWindow — the front door
------------------------------------------------------------------------------------------------------------------------

function AmphibiaLibrary:CreateWindow(settings)
	settings = settings or {}

	if ActiveWindow then
		warn("[ Amphibia Interface ] A window already exists — returning the existing one.")
		return ActiveWindow
	end

	local window = setmetatable({}, WindowClass)
	window.Categories = {}
	window.CategoryOrder = 0
	window.Tabs = {}
	window.ActiveTab = nil
	window.SearchQuery = ""
	ActiveWindow = window

	-- branding
	Header.Logo.Text = settings.Name or "amphibia"
	Header.Version.Text = settings.Version or ("v" .. Release:match("[%d%.]+"))

	-- toggle key
	if settings.ToggleUIKeybind then
		settingsTable.General.amphibiaOpen.Value = tostring(settings.ToggleUIKeybind)
	end

	-- theme: saved preference wins, then the requested one
	local savedTheme = getSetting("General", "theme")
	local initialTheme = (savedTheme and Themes[savedTheme] and savedTheme) or settings.Theme or "Default"
	if initialTheme ~= "Default" then
		AmphibiaLibrary:SetTheme(initialTheme)
	end

	-- configuration saving
	local configurationSaving = settings.ConfigurationSaving
	if configurationSaving and configurationSaving.Enabled then
		local folderName = configurationSaving.FolderName or AmphibiaFolder
		ensureFolder(folderName)
		ConfigSystem.Dir = folderName .. "/Configs"
		ensureFolder(ConfigSystem.Dir)
		local fileName = configurationSaving.FileName or "Default"
		ConfigSystem.AutosaveFile = folderName .. "/autosave_" .. fileName .. ConfigurationExtension
		local lastLoaded = getSetting("General", "lastConfig")
		if type(lastLoaded) == "string" and lastLoaded ~= "" then
			ConfigSystem.LoadedConfig = lastLoaded
		end
	end

	-- startup flow --------------------------------------------------------------------------------------------------
	task.spawn(function()
		local keySystemEnabled = settings.KeySystem == true
		local keySettings = settings.KeySettings or {}

		LoadingScreen.Visible = not keySystemEnabled
		EnterKeyScreen.Visible = keySystemEnabled

		ScreenGui.Enabled = true
		Main.Visible = true
		WindowOpen = true
		MainScale.Scale = BaseScale * 0.9
		local restingPosition = UDim2.new(0.5, 0, 0.5, 0)
		Main.Position = restingPosition + UDim2.new(0, 0, 0, 18)
		tween(MainScale, EASE.Back, { Scale = BaseScale })
		tween(Main, EASE.Back, { Position = restingPosition })

		if keySystemEnabled then
			runKeySystem(keySettings)
			LoadingScreen.Visible = true
			fadeOut(EnterKeyScreen, 0.3)
		end

		task.spawn(function()
			runLoading(settings.LoadingTitle, settings.LoadingDescription, settings.LoadingTime or 2.6)

			-- apply persisted state right before the reveal so the interface wakes up configured
			ConfigSystem.LoadAutosave()
			ConfigSystem.AutosaveEnabled = true

			revealInterface(window)
		end)
	end)

	return window
end

AmphibiaLibrary.CreateNotification = AmphibiaLibrary.Notify

if debugX then
	warn("[ Amphibia DebugX ] Initialisation complete.")
end

return AmphibiaLibrary
