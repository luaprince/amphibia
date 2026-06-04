-- amphibia ui library
-- private use only

local Amphibia = {}
Amphibia.__index = Amphibia

-- ! Services
local Services = {
	Players = game:GetService("Players");
	UserInputService = game:GetService("UserInputService");
	TweenService = game:GetService("TweenService");
	RunService = game:GetService("RunService");
	TextService = game:GetService("TextService");
	HttpService = game:GetService("HttpService");
	CoreGui = game:GetService("CoreGui");
}

-- ! Config
local _config = {
	Title = "amphibia recode"
}

-- ! Theme
local Theme = {
	Font = {
		Inter = Font.fromName("Inter", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		RobotoMono = Font.fromEnum(Enum.Font.RobotoMono)
	},

	Image = {
		-- icon
		CloseIcon = "rbxassetid://130334254289066";
		SettingsIcon = "rbxassetid://9405931578";
		SearchIcon = "rbxassetid://131759514926900";
		ArrowIcon = "rbxassetid://123677364722832";
		ResetIcon = "rbxassetid://90159710556161";
		TrashIcon = "rbxassetid://100301615396153";
		UndoIcon = "rbxassetid://114916592621419";
		RedoIcon = "rbxassetid://94370733130097";
		RandomIcon = "rbxassetid://104525241277650";

		-- textures
		NoiseTexture = "rbxassetid://81574725932265";

		-- other
		ShadowImage = "rbxassetid://76575266047430";
	},
	
	Color = {
		White = Color3.fromRGB(255,255,255),
		Black = Color3.fromRGB(0,0,0),

		Text = {
			Watermark = Color3.fromRGB(198, 198, 198);
			Tab = Color3.fromRGB(188, 188, 188);
			TabActive = Color3.fromRGB(218, 218, 218);

			Section = Color3.fromRGB(163, 163, 164);

			Button = Color3.fromRGB(214, 214, 214);

			PickedOption = Color3.fromRGB(155, 155, 165);
			PickerOption = Color3.fromRGB(185, 185, 195);

			SliderValue = Color3.fromRGB(148, 148, 148);
			ToggleValue = Color3.fromRGB(120, 120, 120);

			ParagraphTitle = Color3.fromRGB(214, 214, 214);
			ParagraphDescription = Color3.fromRGB(165, 165, 165);

			Textbox = Color3.fromRGB(157, 157, 157);

			ColorPickerTextbox = Color3.fromRGB(162, 162, 162);
			ColorPickerHex = Color3.fromRGB(111, 111, 111);

			ColorPickerWindowTransparency = Color3.fromRGB(102, 99, 103);
			ColorPickerWindowTransparencyTextbox = Color3.fromRGB(148, 148, 148);
			ColorPickerWindowHex = Color3.fromRGB(126, 126, 126);
			ColorPickerWindowHexTextbox = Color3.fromRGB(186, 186, 186);
			ColorPickerWindowRGB = Color3.fromRGB(102, 102, 102);
			ColorPickerWindowRGBTextbox = Color3.fromRGB(145, 145, 145);
			ColorPickerWindowPresets = Color3.fromRGB(154, 154, 154);

			SearchPlaceholder = Color3.fromRGB(147,147,147);
			SearchText = Color3.fromRGB(216,216,216);
		},

		Background = {
			MainHeader = Color3.fromRGB(94, 92, 95);
			MainWindow = Color3.fromRGB(54, 51, 57);
			Search = Color3.fromRGB(95, 95, 95);
			Tabs = Color3.fromRGB(59, 59, 59);
			ColorPickerWindow = Color3.fromRGB(80, 80, 80);
		},

		Gradient = {
			MainBackground = Color3.fromRGB(118,118,118);

			MainHeaderMid = Color3.fromRGB(170,170,170);
			MainHeaderEnd = Color3.fromRGB(90,90,90);

			HeaderSearchFrameEnd = Color3.fromRGB(186,186,186);
		},

		Image = {
			SearchImage = Color3.fromRGB(207,207,207);
			CloseImage = Color3.fromRGB(198,198,198);
			SettingsImage = Color3.fromRGB(198,198,198);
		},

		Other = {
			TabSplitterLine = Color3.fromRGB(75, 72, 75);
		},
	},

	Animation = {
		Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		Normal = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		Slow = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

		Dropdown = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out);
		Window = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out);
	},

}

-- ! Utilities
local Utility = {}

function Utility:Create(className, properties, children)
	local object = Instance.new(className)

	for property, value in pairs(properties or {}) do
		object[property] = value
	end

	for _, child in pairs(children or {}) do
		child.Parent = object
	end

	if object:IsA("GuiObject") then
		object.BorderSizePixel = 0
	end

	return object
end

function Utility:Tween(object, tweenInfo, properties)
	local tween = Services.TweenService:Create(object, tweenInfo, properties)
	tween:Play()
	return tween
end

function Utility:Corner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

function Utility:Stroke(parent, color, thickness, transparency, zindex)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	stroke.ZIndex = zindex or 1
	return stroke
end

-- ! Main Build -----------------------------------------------------------------------------------------------------------------------------------

function Amphibia:CreateWindow(config)
	config = config or {}

	local self = setmetatable({}, Amphibia)

	self.Title = config.Title or _config.Title or "[config title missed]"
	self.Theme = Theme
	self.Connections = {}
	self.Elements = {}


	-- main screen gui
	self.ScreenGui = Utility:Create("ScreenGui", {
		Name = "Amphibia",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Services.CoreGui
	})

	-- holder frame
	self.HolderFrame = Utility:Create("Frame", {
		Name = "Holder",
		AnchorPoint = Vector2.new(0.5,0.5),
		BackgroundTransparency = 1,
		Size = UDim2.new(0,900,0,600),
		Position = UDim2.new(0.5,0,0.5,0),
		Parent = self.ScreenGui
	})

	-- main background
	self.MainBackground = Utility:Create("Frame", {
		Name = "MainBackground",
		AnchorPoint = Vector2.new(0.5,0.5),
		BackgroundColor3 = self.Theme.Color.Background.MainWindow,
		BackgroundTransparency = 0,
		Position = UDim2.new(0.5,0,0.5,0),
		Size = UDim2.new(0,900,0,600),
		ZIndex = 2,
		Parent = self.HolderFrame
	})

	self.MainBackgroundNoise = Utility:Create("ImageLabel", {
		Name = "Noise",
		BackgroundColor3 = self.Theme.Color.White,
		BackgroundTransparency = 1,
		Position = UDim2.new(0,0,0,0),
		Size = UDim2.new(1,0,1,0),
		Image = self.Theme.Image.NoiseTexture,
		ImageColor3 = self.Theme.Color.White,
		ImageTransparency = 0.98,
		Parent = self.MainBackground
	})

	self.MainBackgroundGradient = Utility:Create("UIGradient", {
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, self.Theme.Color.White),
			ColorSequenceKeypoint.new(1, self.Theme.Color.Gradient.MainBackground)
		},
		Rotation = 90,
		Parent = self.MainBackground
	})

	self.HeaderShadow = Utility:Create("Frame", {
		Name = "HeaderShadow",
		BackgroundColor3 = self.Theme.Color.Black,
		BackgroundTransparency = 0.55,
		Position = UDim2.new(0,0,0,0),
		Size = UDim2.new(0,900,0,36),
		ZIndex = 999,
		Parent = self.MainBackground
	})

	self.HeaderShadowGradient = Utility:Create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.6, 0),
			NumberSequenceKeypoint.new(1, 1, 0),
		},
		Parent = self.HeaderShadow
	})

	self.TabsFolder = Utility:Create("Folder", {
		Name = "Tabs",
		Parent = self.MainBackground
	})

	self.TabsSplitterFrame = Utility:Create("Frame", {
		Name = "TabsSplitterFrame",
		BackgroundColor3 = self.Theme.Color.Other.TabSplitterLine,
		Position = UDim2.new(0.224,0,0,0),
		Size = UDim2.new(0,2,0,600),
		ZIndex = 2,
		Parent = self.TabsFolder
	})

	self.TabsSplitterFrameGradient = Utility:Create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0,0,0),
			NumberSequenceKeypoint.new(1,1,0)
		},
		Parent = self.TabsSplitterFrame
	})

	self.TabsFrame = Utility:Create("Frame", {
		Name = "TabsFrame", 
		BackgroundColor3 = self.Theme.Color.Background.Tabs,
		BackgroundTransparency = 0.6,
		Position = UDim2.new(0,0,0,0),
		Size = UDim2.new(0,204,0,600),
		ZIndex = 1,
		Parent = self.TabsFolder
	})

	self.TabsFrameGradient = Utility:Create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0,0,0),
			NumberSequenceKeypoint.new(1,1,0)
		},
		Parent = self.TabsFrame
	})

	self.TabsFrameList = Utility:Create("UIListLayout", {
		Padding = UDim.new(0,15),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.TabsFrame
	})

	self.TabsFramePadding = Utility:Create("UIPadding", {
		PaddingLeft = UDim.new(0,25),
		PaddingTop = UDim.new(0,25),
		Parent = self.TabsFrame
	})

	-- main header
	self.MainHeader = Utility:Create("Frame", {
		Name = "MainHeader",
		BackgroundColor3 = self.Theme.Color.Background.MainHeader,
		Position = UDim2.new(0,0,-0.063,0),
		Size = UDim2.new(0,900,0,56),
		ZIndex = 1,
		Parent = self.HolderFrame
	})

	self.MainHeaderCorner = Utility:Corner(self.MainHeader, 15)

	self.MainHeaderGradient = Utility:Create("UIGradient", {
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, self.Theme.Color.White),
			ColorSequenceKeypoint.new(0.515, self.Theme.Color.Gradient.MainHeaderMid),
			ColorSequenceKeypoint.new(1, self.Theme.Color.Gradient.MainHeaderEnd)
		},
		Rotation = 90,
		Parent = self.MainHeader
	})

	self.MainHeaderWatermark = Utility:Create("TextLabel", {
		Name = "Watermark",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.021,0,-0.018,0),
		Size = UDim2.new(0,121,0,39),
		ZIndex = 2,
		FontFace = self.Theme.Font.Inter,
		Text = self.Title,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = self.Theme.Color.Text.Watermark,
		Parent = self.MainHeader
	})

	self.MainHeaderNoise = Utility:Create("ImageLabel", {
		Name = "Noise",
		BackgroundColor3 = self.Theme.Color.White,
		BackgroundTransparency = 1,
		Position = UDim2.new(0,0,0,0),
		Size = UDim2.new(1,0,1,0),
		Image = self.Theme.Image.NoiseTexture,
		ImageColor3 = self.Theme.Color.White,
		ImageTransparency = 0.99,
		Parent = self.MainHeader
	})

	self.MainHeaderSearchFrame = Utility:Create("Frame", {
		Name = "SearchFrame",
		BackgroundColor3 = self.Theme.Color.Background.Search,
		Position = UDim2.new(0.327,0,0.107,0),
		Size = UDim2.new(0,312,0,25),
		ZIndex = 2,
		Parent = self.MainHeader
	})

	self.MainHeaderSearchFrameCorner = Utility:Corner(self.MainHeaderSearchFrame, 12)

	self.MainHeaderSearchFrameStroke1 = Utility:Stroke(self.MainHeaderSearchFrame, self.Theme.Color.Black, 0.5, 0.79, 3)

	self.MainHeaderSearchFrameStroke2 = Utility:Stroke(self.MainHeaderSearchFrame, self.Theme.Color.Black, 3, 0.98, 1)

	self.MainHeaderSearchFrameGradient = Utility:Create("UIGradient", {
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, self.Theme.Color.White),
			ColorSequenceKeypoint.new(1, self.Theme.Color.Gradient.HeaderSearchFrameEnd)
		},
		Rotation = 90,
		Parent = self.MainHeaderSearchFrame
	})

	self.MainHeaderSearchFrameNoise = Utility:Create("ImageLabel", {
		Name = "Noise",
		BackgroundColor3 = self.Theme.Color.White,
		BackgroundTransparency = 1,
		Position = UDim2.new(0,0,0,0),
		Size = UDim2.new(1,0,1,0),
		Image = self.Theme.Image.NoiseTexture,
		ImageColor3 = self.Theme.Color.White,
		ImageTransparency = 0.97,
		Parent = self.MainHeaderSearchFrame
	})

	self.MainHeaderSearchFrameSearchIcon = Utility:Create("ImageLabel", {
		Name = "SearchIcon",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.026,0,0.16,0),
		Size = UDim2.new(0,16,0,16),
		ZIndex = 1,
		Image = self.Theme.Image.SearchIcon,
		ImageColor3 = self.Theme.Color.Image.SearchImage,
		Parent = self.MainHeaderSearchFrame
	})

	self.MainHeaderSearchFrameTextbox = Utility:Create("TextBox", {
		Name = "SearchTextbox",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.096,0,0,0),
		Size = UDim2.new(0,276,0,25),
		ZIndex = 2,
		FontFace = self.Theme.Font.RobotoMono,
		PlaceholderColor3 = self.Theme.Color.Text.SearchPlaceholder,
		TextColor3 = self.Theme.Color.Text.SearchText,
		PlaceholderText = ". . .",
		Text = "",
		TextSize = 14,
		Parent = self.MainHeaderSearchFrame
	})

	self.MainHeaderClose = Utility:Create("ImageButton", {
		Name = "CloseButton",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.956,0,0.044,0),
		Size = UDim2.new(0,35,0,35),
		ZIndex = 2,
		Image = self.Theme.Image.CloseIcon,
		ImageTransparency = 0.54,
		ImageColor3 = self.Theme.Color.Image.CloseImage,
		Parent = self.MainHeader
	})

	self.MainHeaderSettings = Utility:Create("ImageButton", {
		Name = "SettingsButton",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.68,0,0.115,0),
		Size = UDim2.new(0,23,0,23),
		ZIndex = 2,
		Image = self.Theme.Image.SettingsIcon,
		ImageColor3 = self.Theme.Color.Image.SettingsImage,
		ImageTransparency = 0.56,
		Parent = self.MainHeader
	})

	self.MainHeaderSettingsShadow = Utility:Create("ImageLabel", {
		Name = "SettingsShadow",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.68,0,0.115,0),
		Size = UDim2.new(0,25,0,25),
		ZIndex = 1,
		Image = self.Theme.Image.SettingsIcon,
		ImageColor3 = self.Theme.Color.Black,
		ImageTransparency = 0.95,
		Parent = self.MainHeader
	})

	self.MainHeaderClose.MouseButton1Click:Connect(function()
		self:Destroy()
	end)

	-- shadow
	self.Shadow = Utility:Create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5,0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5,0,0.5,0),
		Size = UDim2.new(0,1907,0,1444),
		Image = self.Theme.Image.ShadowImage,
		ImageTransparency = 0.39,
		ImageColor3 = self.Theme.Color.White,
		ZIndex = 0,
		Parent = self.HolderFrame
	})
 
	return self
end

function Amphibia:Destroy()
	for _, connection in ipairs(self.Connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end

	table.clear(self.Connections)
	table.clear(self.Elements)

	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end
end

return Amphibia
