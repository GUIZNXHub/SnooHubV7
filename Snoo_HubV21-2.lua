--========================================================
-- SNOO HUB V18
-- LocalScript - StarterPlayerScripts
--========================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Fonte desejada: Luckywestguy.
-- Se a fonte não estiver disponível no ambiente, Roblox usa Gotham como fallback.
local UI_FONT = Enum.Font.GothamBlack

local BACKGROUND_ID = "rbxassetid://92235193275042"
local LOGO_ID = "rbxassetid://109807470527334"

local Character
local Humanoid
local Root

local WalkEnabled = false
local JumpEnabled = false
local NoclipEnabled = false
local NoclipOriginals = {}
local CharacterParts = {}
local AntiRagdollEnabled = false
local InfiniteJumpEnabled = false
local InstantPromptEnabled = false
local FPSBoostEnabled = false
local UltraESPEnabled = false

local WalkValue = 110
local JumpValue = 100
local TravelValue = 110
local TPValue = 20

local OriginalWalkSpeed = nil
local OriginalJumpPower = nil

local SavedPosition = nil
local FloatingSavedPosition = nil
local SaveConfig = nil

-- Forward references shared by TP BEST / ESP. Declared once so TP BEST
-- never falls back to a global accidentally.
local ESPFindBestTargetReference = nil
local CurrentBestTarget = nil

-- Forward declarations: keep callbacks bound to locals even when their
-- definitions appear later in the file.
local SpamTPV1ButtonSmall = nil
local SpamTPV2ButtonSmall = nil
local ESPStartVisual = nil
local ESPStopVisual = nil
local ShowBestNotice = nil
local Texts = nil
local Languages = nil
local BestLineEnabled = false

local function IsValidCFrame(Value)
	if typeof(Value) ~= "CFrame" then return false end
	local P = Value.Position
	return P.X == P.X and P.Y == P.Y and P.Z == P.Z
		and math.abs(P.X) < 100000
		and math.abs(P.Y) < 100000
		and math.abs(P.Z) < 100000
end

local function GetSafeSavedCFrame()
	if IsValidCFrame(SavedPosition) then
		return SavedPosition
	end
	SavedPosition = nil
	return nil
end

local Traveling = false
local CancelTravel = false

local StepTeleporting = false
local CancelStepTeleport = false

local ConfigFileName = "SnooHub6_Config.json"
local SCRIPT_VERSION = "V18"
local LoadedConfig = {}
local Language = "pt-BR"

pcall(function()
	if type(isfile) == "function" and type(readfile) == "function" and isfile(ConfigFileName) then
		local Data = HttpService:JSONDecode(readfile(ConfigFileName))
		if type(Data) == "table" then LoadedConfig = Data end
	end
end)

local function ApplyLoadedNumber(Key, Default, Minimum, Maximum)
	local Value = tonumber(LoadedConfig[Key])
	if Value then return math.clamp(Value, Minimum, Maximum) end
	return Default
end

WalkValue = ApplyLoadedNumber("WalkValue", WalkValue, 1, 500)
JumpValue = ApplyLoadedNumber("JumpValue", JumpValue, 1, 500)
TravelValue = ApplyLoadedNumber("TravelValue", TravelValue, 1, 1000)
TPValue = ApplyLoadedNumber("TPValue", TPValue, 1, 200)
WalkEnabled = LoadedConfig.WalkEnabled == true
JumpEnabled = LoadedConfig.JumpEnabled == true
NoclipEnabled = LoadedConfig.NoclipEnabled == true
AntiRagdollEnabled = LoadedConfig.AntiRagdollEnabled == true
InfiniteJumpEnabled = LoadedConfig.InfiniteJumpEnabled == true
InstantPromptEnabled = LoadedConfig.InstantPromptEnabled == true
local LoadedFPSBoostEnabled = LoadedConfig.FPSBoostEnabled == true
FPSBoostEnabled = false

local function RebuildCharacterCache()
	table.clear(CharacterParts)
	if not Character or not Character.Parent then return end
	for _, Object in ipairs(Character:GetDescendants()) do
		if Object:IsA("BasePart") then
			table.insert(CharacterParts, Object)
		end
	end
end

local function SetupCharacter(CharacterObject)
	if not CharacterObject or not CharacterObject.Parent then return end
	Character = CharacterObject
	Humanoid = Character:FindFirstChildOfClass("Humanoid")
	Root = Character:FindFirstChild("HumanoidRootPart")
	RebuildCharacterCache()

	if not Humanoid or not Root then
		task.spawn(function()
			if not Character or Character ~= CharacterObject or not CharacterObject.Parent then return end
			Humanoid = CharacterObject:WaitForChild("Humanoid", 10)
			Root = CharacterObject:WaitForChild("HumanoidRootPart", 10)
			if not Humanoid or not Root then return end
			RebuildCharacterCache()
			if WalkEnabled then Humanoid.WalkSpeed = WalkValue end
			if JumpEnabled then
				Humanoid.UseJumpPower = true
				Humanoid.JumpPower = JumpValue
			end
		end)
		return
	end

	if WalkEnabled then Humanoid.WalkSpeed = WalkValue end
	if JumpEnabled then
		Humanoid.UseJumpPower = true
		Humanoid.JumpPower = JumpValue
	end
end

if Player.Character then
	SetupCharacter(Player.Character)
	Player.Character.DescendantAdded:Connect(function(Object)
		if Object:IsA("BasePart") then table.insert(CharacterParts, Object) end
	end)
	Player.Character.DescendantRemoving:Connect(function(Object)
		if Object:IsA("BasePart") then
			for Index = #CharacterParts, 1, -1 do
				if CharacterParts[Index] == Object then table.remove(CharacterParts, Index); break end
			end
		end
	end)
end

Player.CharacterAdded:Connect(SetupCharacter)

Player.CharacterRemoving:Connect(function(CharacterObject)
	if Character == CharacterObject then
		table.clear(CharacterParts)
		table.clear(NoclipOriginals)
		Humanoid = nil
		Root = nil
	end
end)

Player.CharacterAdded:Connect(function(CharacterObject)
	CharacterObject.DescendantAdded:Connect(function(Object)
		if Object:IsA("BasePart") then
			table.insert(CharacterParts, Object)
		end
	end)
	CharacterObject.DescendantRemoving:Connect(function(Object)
		if Object:IsA("BasePart") then
			for Index = #CharacterParts, 1, -1 do
				if CharacterParts[Index] == Object then
					table.remove(CharacterParts, Index)
					break
				end
			end
		end
	end)
end)

local Existing = PlayerGui:FindFirstChild("Snoo Hub")
if Existing then
	Existing:Destroy()
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "Snoo Hub"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(540, 420)
Main.Position = UDim2.new(0.5, -270, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Main.BackgroundTransparency = 0
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(155, 70, 255)
MainStroke.Transparency = 0.05
MainStroke.Thickness = 2
MainStroke.Parent = Main

local Background = Instance.new("ImageLabel")
Background.Name = "Background"
Background.Size = UDim2.fromScale(1, 1)
Background.BackgroundTransparency = 1
Background.Image = BACKGROUND_ID
Background.ImageTransparency = 0.95
Background.ScaleType = Enum.ScaleType.Crop
Background.ZIndex = 0
Background.Parent = Main

local BackgroundCorner = Instance.new("UICorner")
BackgroundCorner.CornerRadius = UDim.new(0, 12)
BackgroundCorner.Parent = Background

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 58)
Header.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Header.BackgroundTransparency = 0
Header.ClipsDescendants = true
Header.Active = true
Header.ZIndex = 5
Header.Parent = Main

local HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 20, 45)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 22))
})
HeaderGradient.Rotation = 15
HeaderGradient.Parent = Header

local Logo = Instance.new("ImageLabel")
Logo.Size = UDim2.fromOffset(28, 28)
Logo.Position = UDim2.fromOffset(8, 8)
Logo.BackgroundColor3 = Color3.fromRGB(20, 18, 25)
Logo.BackgroundTransparency = 0.1
Logo.BorderSizePixel = 0
Logo.Image = LOGO_ID
Logo.ScaleType = Enum.ScaleType.Fit
Logo.ZIndex = 6
Logo.Parent = Header

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 12)
LogoCorner.Parent = Logo

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 0, 30)
Title.Position = UDim2.fromOffset(43, 3)
Title.BackgroundTransparency = 1
Title.Text = "Snoo Hub"
Title.TextColor3 = Color3.fromRGB(245, 245, 250)
Title.TextSize = 17
Title.Font = UI_FONT
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 6
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -120, 0, 18)
Subtitle.Position = UDim2.fromOffset(44, 25)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "EPIC BRAINROT 2.0"
Subtitle.TextColor3 = Color3.fromRGB(190, 90, 255)
Subtitle.TextSize = 7
Subtitle.Font = UI_FONT
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 6
Subtitle.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(28, 24)
Minimize.Position = UDim2.new(1, -36, 0, 9)
Minimize.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Minimize.BorderSizePixel = 0
Minimize.Text = "—"
Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
Minimize.TextSize = 15
Minimize.Font = UI_FONT
Minimize.ZIndex = 7
Minimize.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 10)
MinCorner.Parent = Minimize

local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -20, 1, -112)
Content.Position = UDim2.fromOffset(10, 106)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(155, 70, 255)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.ZIndex = 3
Content.Parent = Main

local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -20, 0, 32)
TabBar.Position = UDim2.fromOffset(10, 68)
TabBar.BackgroundTransparency = 1
TabBar.ZIndex = 6
TabBar.Parent = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 8)
TabLayout.Parent = TabBar

local Pages = {}
local CurrentPage
local CurrentLayout

local function CreatePage(Name)
	local Page = Instance.new("ScrollingFrame")
	Page.Name = Name .. "Page"
	Page.Size = UDim2.fromScale(1, 1)
	Page.BackgroundTransparency = 1
	Page.BorderSizePixel = 0
	Page.ScrollBarThickness = 3
	Page.ScrollBarImageColor3 = Color3.fromRGB(155, 70, 255)
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
	Page.Visible = false
	Page.ZIndex = 4
	Page.Parent = Content

	local PageLayout = Instance.new("UIListLayout")
	PageLayout.Padding = UDim.new(0, 4)
	PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	PageLayout.Parent = Page

	Pages[Name] = {Frame = Page, Layout = PageLayout}
	return Page
end

local function SelectPage(Name)
	local Data = Pages[Name]
	if not Data then return end
	for _, PageData in pairs(Pages) do PageData.Frame.Visible = false end
	Data.Frame.Visible = true
	CurrentPage = Data.Frame
	CurrentLayout = Data.Layout
	Content.CanvasSize = UDim2.fromOffset(0, Data.Layout.AbsoluteContentSize.Y + 12)
end

local function CreateTab(Name, Text)
	local Button = Instance.new("TextButton")
	Button.Name = Name .. "Tab"
	Button.Size = UDim2.fromOffset(80, 30)
	Button.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	Button.BackgroundTransparency = 0.1
	Button.BorderSizePixel = 0
	Button.Text = Text
	Button.TextColor3 = Color3.fromRGB(130, 130, 140)
	Button.TextSize = 9
	Button.Font = Enum.Font.GothamBold
	Button.AutoButtonColor = false
	Button.ZIndex = 7
	Button.Parent = TabBar
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 9)
	Corner.Parent = Button
	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(40, 40, 48)
	Stroke.Parent = Button
	Button.MouseButton1Click:Connect(function()
		SelectPage(Name)
		for PageName, PageData in pairs(Pages) do
			local Tab = TabBar:FindFirstChild(PageName .. "Tab")
			if Tab then
				Tab.BackgroundColor3 = PageName == Name and Color3.fromRGB(85, 35, 135) or Color3.fromRGB(24, 24, 28)
				Tab.TextColor3 = PageName == Name and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
			end
		end
	end)
	return Button
end

local MovementPage = CreatePage("Movement")
local UtilityPage = CreatePage("Utility")
local JumpPage = CreatePage("Jump")
local CreditsPage = CreatePage("Credits")
local ESPPage = CreatePage("ESP")
local ConfigPage = CreatePage("Config")
CreateTab("Movement", "MOVEMENT")
CreateTab("Utility", "UTILITY")
CreateTab("Jump", "JUMP")
CreateTab("Credits", "CREDITS")
CreateTab("ESP", "ESP")
CreateTab("Config", "CONFIG")

SelectPage("Movement")
for _, TabName in ipairs({"Movement", "Utility", "Jump", "Credits", "ESP", "Config"}) do
	local Tab = TabBar:FindFirstChild(TabName .. "Tab")
	if Tab then
		Tab.BackgroundColor3 = TabName == "Movement" and Color3.fromRGB(85, 35, 135) or Color3.fromRGB(24, 24, 28)
		Tab.TextColor3 = TabName == "Movement" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
	end
end
local Layout = CurrentLayout

local function Section(Text)
	local Object = Instance.new("TextLabel")
	Object.Size = UDim2.new(1, -8, 0, 16)
	Object.BackgroundTransparency = 1
	Object.Text = Text
	Object.TextColor3 = Color3.fromRGB(190, 90, 255)
	Object.TextSize = 10
	Object.Font = UI_FONT
	Object.TextXAlignment = Enum.TextXAlignment.Left
	Object.ZIndex = 4
	Object.Parent = CurrentPage
	return Object
end

local function Label(Text)
	local Object = Instance.new("TextLabel")
	Object.Size = UDim2.new(1, -8, 0, 13)
	Object.BackgroundTransparency = 1
	Object.Text = Text
	Object.TextColor3 = Color3.fromRGB(154, 158, 177)
	Object.TextSize = 9
	Object.Font = UI_FONT
	Object.TextXAlignment = Enum.TextXAlignment.Left
	Object.ZIndex = 4
	Object.Parent = CurrentPage
	return Object
end

local function Description(Text)
	local Object = Instance.new("TextLabel")
	Object.Size = UDim2.new(1, -10, 0, 15)
	Object.BackgroundTransparency = 1
	Object.Text = Text
	Object.TextColor3 = Color3.fromRGB(115, 115, 125)
	Object.TextSize = 8
	Object.Font = Enum.Font.Gotham
	Object.TextXAlignment = Enum.TextXAlignment.Left
	Object.ZIndex = 4
	Object.Parent = CurrentPage
	return Object
end

local function TextBox(Default, Placeholder)
	local Object = Instance.new("TextBox")
	Object.Size = UDim2.new(1, -8, 0, 28)
	Object.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	Object.BorderSizePixel = 0
	Object.Text = Default
	Object.PlaceholderText = Placeholder
	Object.PlaceholderColor3 = Color3.fromRGB(90, 90, 100)
	Object.TextColor3 = Color3.fromRGB(245, 245, 250)
	Object.TextSize = 10
	Object.Font = UI_FONT
	Object.ClearTextOnFocus = false
	Object.ZIndex = 5
	Object.Parent = CurrentPage

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 10)
	Corner.Parent = Object

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(40, 40, 48)
	Stroke.Parent = Object

	return Object
end

local function Button(Text)
	local Object = Instance.new("TextButton")
	Object.Size = UDim2.new(1, -8, 0, 29)
	Object.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	Object.BorderSizePixel = 0
	Object.Text = Text
	Object.TextColor3 = Color3.fromRGB(225, 228, 240)
	Object.TextSize = 9
	Object.Font = UI_FONT
	Object.AutoButtonColor = false
	Object.TextXAlignment = Enum.TextXAlignment.Left
	Object.ZIndex = 5
	Object.Parent = CurrentPage

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 10)
	Corner.Parent = Object

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(40, 40, 48)
	Stroke.Transparency = 0.15
	Stroke.Parent = Object

	local DefaultColor = Object.BackgroundColor3
	Object.MouseEnter:Connect(function()
		Object.BackgroundColor3 = Color3.fromRGB(42, 25, 60)
		Stroke.Color = Color3.fromRGB(190, 90, 255)
	end)
	Object.MouseLeave:Connect(function()
		Object.BackgroundColor3 = DefaultColor
		Stroke.Color = Color3.fromRGB(40, 40, 48)
	end)

	return Object
end

-- ==================== CREDITS ====================
SelectPage("Credits")
Section("SNOO HUB")
Label("OWNER • CREATOR • SNOO")
Label("COLLABORATOR • GUIZNX")
Label("DISCORD • discord.gg/v2dwtQAqan")
local DiscordButton = Button("  DISCORD • COPIAR")
DiscordButton.MouseButton1Click:Connect(function()
	if type(setclipboard) == "function" then
		setclipboard("https://discord.gg/v2dwtQAqan")
		DiscordButton.Text = "  DISCORD COPIADO"
	else
		DiscordButton.Text = "  discord.gg/v2dwtQAqan"
	end
	task.delay(1.5, function()
		if DiscordButton.Parent then DiscordButton.Text = "  DISCORD • COPIAR" end
	end)
end)

SelectPage("Movement")


local AutoStealEnabled = LoadedConfig.AutoStealEnabled == true
local AutoStealConnection = nil
local StealBarGui = nil
local StealBarFill = nil
local StealPercentLabel = nil
local StealStateLabel = nil
local StealStartTime = nil
local StealDuration = ApplyLoadedNumber("StealDuration", 1.4, 0.1, 10)
local StealRadius = ApplyLoadedNumber("StealRadius", 60, 1, 500)
local IsStealing = false
local StealData = {}

local function CreateStealBar()
	if StealBarGui then return end
	StealBarGui = Instance.new("ScreenGui")
	StealBarGui.Name = "SnooStealBar"
	StealBarGui.ResetOnSpawn = false
	StealBarGui.IgnoreGuiInset = true
	StealBarGui.DisplayOrder = 20
	StealBarGui.Parent = PlayerGui

	local Frame = Instance.new("Frame")
	Frame.Name = "AutoSteal"
	Frame.Size = UDim2.fromOffset(240, 48)
	Frame.Position = UDim2.new(0.5, -120, 0.86, 0)
	Frame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
	Frame.BackgroundTransparency = 0.05
	Frame.BorderSizePixel = 0
	Frame.ClipsDescendants = true
	Frame.Parent = StealBarGui

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 10)
	Corner.Parent = Frame
	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(155, 70, 255)
	Stroke.Thickness = 1.5
	Stroke.Parent = Frame

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -24, 0, 18)
	Title.Position = UDim2.fromOffset(12, 5)
	Title.BackgroundTransparency = 1
	Title.Text = "AUTO STEAL"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 10
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Frame

	StealStateLabel = Instance.new("TextLabel")
	StealStateLabel.Size = UDim2.new(0.55, 0, 0, 14)
	StealStateLabel.Position = UDim2.fromOffset(12, 23)
	StealStateLabel.BackgroundTransparency = 1
	StealStateLabel.Text = "SEARCHING"
	StealStateLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
	StealStateLabel.TextSize = 8
	StealStateLabel.Font = Enum.Font.GothamBold
	StealStateLabel.TextXAlignment = Enum.TextXAlignment.Left
	StealStateLabel.Parent = Frame

	StealPercentLabel = Instance.new("TextLabel")
	StealPercentLabel.Size = UDim2.new(0, 45, 0, 14)
	StealPercentLabel.Position = UDim2.new(1, -57, 0, 23)
	StealPercentLabel.BackgroundTransparency = 1
	StealPercentLabel.Text = "0%"
	StealPercentLabel.TextColor3 = Color3.fromRGB(190, 90, 255)
	StealPercentLabel.TextSize = 9
	StealPercentLabel.Font = Enum.Font.GothamBlack
	StealPercentLabel.TextXAlignment = Enum.TextXAlignment.Right
	StealPercentLabel.Parent = Frame

	local Track = Instance.new("Frame")
	Track.Size = UDim2.new(1, -24, 0, 4)
	Track.Position = UDim2.fromOffset(12, 40)
	Track.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	Track.BorderSizePixel = 0
	Track.Parent = Frame
	Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

	StealBarFill = Instance.new("Frame")
	StealBarFill.Size = UDim2.new(0, 0, 1, 0)
	StealBarFill.BackgroundColor3 = Color3.fromRGB(155, 70, 255)
	StealBarFill.BorderSizePixel = 0
	StealBarFill.Parent = Track
	Instance.new("UICorner", StealBarFill).CornerRadius = UDim.new(1, 0)
end

local function RemoveStealBar()
	if StealBarGui then StealBarGui:Destroy() end
	StealBarGui = nil
	StealBarFill = nil
	StealPercentLabel = nil
	StealStateLabel = nil
end

local function FindNearestStealPrompt()
	local CharacterObject = Player.Character
	local RootObject = CharacterObject and CharacterObject:FindFirstChild("HumanoidRootPart")
	local Plots = workspace:FindFirstChild("Plots")
	if not RootObject or not Plots then return nil end
	local NearestPrompt, NearestDistance = nil, StealRadius
	for _, Plot in ipairs(Plots:GetChildren()) do
		local Podiums = Plot:FindFirstChild("AnimalPodiums")
		if Podiums then
			for _, Podium in ipairs(Podiums:GetChildren()) do
				local Base = Podium:FindFirstChild("Base")
				local Spawn = Base and Base:FindFirstChild("Spawn")
				local Attachment = Spawn and Spawn:FindFirstChild("PromptAttachment")
				if Attachment then
					local Distance = (Spawn.Position - RootObject.Position).Magnitude
					if Distance <= NearestDistance then
						for _, Prompt in ipairs(Attachment:GetChildren()) do
							if Prompt:IsA("ProximityPrompt") and Prompt.Enabled and (Prompt.ActionText == "Steal" or string.find(string.lower(Prompt.ActionText), "steal")) then
								NearestPrompt, NearestDistance = Prompt, Distance
							end
						end
					end
				end
			end
		end
	end
	return NearestPrompt
end

local function ExecuteAutoSteal(Prompt)
	if IsStealing or not Prompt or not Prompt.Parent then return end
	if not StealData[Prompt] then
		StealData[Prompt] = {Hold = {}, Trigger = {}, Ready = true}
		pcall(function()
			if getconnections then
				for _, Connection in ipairs(getconnections(Prompt.PromptButtonHoldBegan)) do
					if Connection.Function then table.insert(StealData[Prompt].Hold, Connection.Function) end
				end
				for _, Connection in ipairs(getconnections(Prompt.Triggered)) do
					if Connection.Function then table.insert(StealData[Prompt].Trigger, Connection.Function) end
				end
			end
		end)
	end
	local Data = StealData[Prompt]
	if not Data.Ready then return end
	Data.Ready = false
	IsStealing = true
	StealStartTime = tick()
	task.spawn(function()
		for _, Callback in ipairs(Data.Hold) do task.spawn(Callback) end
		while IsStealing and tick() - StealStartTime < StealDuration do
			local Progress = math.clamp((tick() - StealStartTime) / StealDuration, 0, 1)
			if StealBarFill then StealBarFill.Size = UDim2.new(Progress, 0, 1, 0) end
			if StealPercentLabel then StealPercentLabel.Text = math.floor(Progress * 100) .. "%" end
			if StealStateLabel then StealStateLabel.Text = "STEALING" end
			task.wait()
		end
		for _, Callback in ipairs(Data.Trigger) do task.spawn(Callback) end
		task.wait(0.1)
		Data.Ready = true
		IsStealing = false
		StealStartTime = nil
		if StealBarFill then StealBarFill.Size = UDim2.new(0, 0, 1, 0) end
		if StealPercentLabel then StealPercentLabel.Text = "0%" end
		if StealStateLabel then StealStateLabel.Text = "SEARCHING" end
	end)
end

local function StartAutoSteal()
	if AutoStealConnection then return end
	CreateStealBar()
	local LastAutoStealScan = 0
	AutoStealConnection = RunService.Heartbeat:Connect(function()
		if not AutoStealEnabled or IsStealing then return end
		local Now = os.clock()
		if Now - LastAutoStealScan < 0.15 then return end
		LastAutoStealScan = Now
		local Prompt = FindNearestStealPrompt()
		if Prompt then ExecuteAutoSteal(Prompt) end
	end)
end

local function StopAutoSteal()
	AutoStealEnabled = false
	IsStealing = false
	if AutoStealConnection then AutoStealConnection:Disconnect(); AutoStealConnection = nil end
	RemoveStealBar()
end

SelectPage("Movement")
Section("MOVEMENT")
Label("WALK SPEED")
local WalkBox = TextBox("110", "Digite a Walk Speed")
local SpeedButton = Button("  WALK SPEED • OFF")

Section("TRAJETO")
Label("TRAJETO SPEED")
local TravelBox = TextBox("110", "Digite a velocidade do trajeto")
local SaveButton = Button("  SALVAR LOCALIZAÇÃO")
local TravelButton = Button("  IR FLUTUANDO ATÉ LOCAL")

Label("TP SPEED • STUDS/SEGUNDO")
local TPBox = TextBox("20", "TP SPEED (studs/segundo)")
local TPButton = Button("  TP POR PASSOS • IR")
local SpamTPV1Button = Button("  SPAM TP V1 • OFF")
local SpamTPV2Button = Button("  SPAM TP V2 • OFF")

SelectPage("Utility")
Section("OUTROS")
local NoclipButton = Button("  NOCLIP • OFF")
local AntiRagdollButton = Button("  ANTI-RAGDOLL • OFF")
local FPSButton = Button("  FPS BOOST • OFF")

Section("PROXIMITY PROMPT")
local PromptButton = Button("  INSTANT PROMPT • OFF")
local AutoStealButton = Button("  AUTO STEAL • OFF")

SelectPage("Jump")
Section("JUMP")
Label("JUMP POWER")
local JumpBox = TextBox("100", "Digite o Jump Power")
local JumpButton = Button("  JUMP POWER • OFF")
local InfiniteButton = Button("  INFINITY JUMP • OFF")

SelectPage("Movement")
Layout = CurrentLayout

SpeedButton.MouseButton1Click:Connect(function()
	if not Humanoid then return end

	if not WalkEnabled then
		OriginalWalkSpeed = Humanoid.WalkSpeed

		local Number = tonumber(WalkBox.Text)
		if Number then
			WalkValue = math.clamp(Number, 1, 500)
		end

		Humanoid.WalkSpeed = WalkValue
		WalkEnabled = true
		SpeedButton.Text = "  WALK SPEED • ON"
	else
		if OriginalWalkSpeed ~= nil then
			Humanoid.WalkSpeed = OriginalWalkSpeed
		end

		WalkEnabled = false
		SpeedButton.Text = "  WALK SPEED • OFF"
	end
end)

SaveButton.MouseButton1Click:Connect(function()
	if not Root then return end

	SavedPosition = Root.CFrame
	SaveButton.Text = "  LOCALIZAÇÃO SALVA"

	task.delay(1.5, function()
		if SaveButton.Parent then
			SaveButton.Text = "  SALVAR LOCALIZAÇÃO"
		end
	end)
end)

local function MoveToPoint(Target)
	if not Root then return true end

	local Difference = Target - Root.Position
	local Distance = Difference.Magnitude

	if Distance <= 1 then
		return true
	end

	local DeltaTime = RunService.Heartbeat:Wait()
	local Speed = math.max(TravelValue, 1)
	local Amount = math.min(Distance, Speed * DeltaTime)

	Root.CFrame = CFrame.new(
		Root.Position + Difference.Unit * Amount
	)

	return false
end

local function StartTravel()
	if Traveling then return end

	local TargetCFrame = GetSafeSavedCFrame()
	if not TargetCFrame or not Root or not Humanoid then
		TravelButton.Text = "SALVE UMA LOCALIZAÇÃO"
		task.delay(1.5, function()
			if TravelButton.Parent then
				TravelButton.Text = "IR FLUTUANDO ATÉ LOCAL"
			end
		end)
		return
	end

	local Number = tonumber(TravelBox.Text)
	if Number then TravelValue = math.clamp(Number, 1, 1000) end

	Traveling = true
	CancelTravel = false
	TravelButton.Text = "CANCELAR TRAJETO"

	local Destination = TargetCFrame.Position
	local StartPosition = Root.Position
	local FlightHeight = math.clamp(
		math.max(StartPosition.Y + 25, Destination.Y + 25),
		-50000, 50000
	)

	local OldAutoRotate = Humanoid.AutoRotate
	local OldPlatformStand = Humanoid.PlatformStand
	Humanoid.AutoRotate = false
	Humanoid.PlatformStand = true

	local function MoveFloating(Target)
		if not Traveling or CancelTravel or not Root or not Root.Parent then
			return true
		end

		local Difference = Target - Root.Position
		local Distance = Difference.Magnitude

		if Distance <= 0.8 then
			Root.CFrame = CFrame.new(Target)
			Root.AssemblyLinearVelocity = Vector3.zero
			Root.AssemblyAngularVelocity = Vector3.zero
			return true
		end

		local dt = RunService.Heartbeat:Wait()
		local Step = math.min(Distance, math.max(TravelValue, 1) * dt)

		Root.CFrame = CFrame.new(Root.Position + Difference.Unit * Step)
		Root.AssemblyLinearVelocity = Vector3.zero
		Root.AssemblyAngularVelocity = Vector3.zero
		return false
	end

	while Traveling and not CancelTravel do
		if MoveFloating(Vector3.new(Root.Position.X, FlightHeight, Root.Position.Z)) then break end
	end

	while Traveling and not CancelTravel do
		if MoveFloating(Vector3.new(Destination.X, FlightHeight, Destination.Z)) then break end
	end

	while Traveling and not CancelTravel do
		if MoveFloating(Destination) then break end
	end

	if Traveling and not CancelTravel and Root and Root.Parent then
		Root.CFrame = TargetCFrame
		Root.AssemblyLinearVelocity = Vector3.zero
		Root.AssemblyAngularVelocity = Vector3.zero
		TravelButton.Text = "CHEGOU"
	else
		TravelButton.Text = "IR FLUTUANDO ATÉ LOCAL"
	end

	if Humanoid and Humanoid.Parent then
		Humanoid.PlatformStand = OldPlatformStand
		Humanoid.AutoRotate = OldAutoRotate
	end
	if Root and Root.Parent then
		Root.AssemblyLinearVelocity = Vector3.zero
		Root.AssemblyAngularVelocity = Vector3.zero
	end
	Traveling = false
	CancelTravel = false

	task.delay(1.5, function()
		if TravelButton.Parent then
			TravelButton.Text = "IR FLUTUANDO ATÉ LOCAL"
		end
	end)
end

TravelButton.MouseButton1Click:Connect(function()
	if Traveling then
		CancelTravel = true
	else
		task.spawn(StartTravel)
	end
end)

local function StartStepTeleport()
	if StepTeleporting then return end

	local TargetCFrame = GetSafeSavedCFrame()
	if not TargetCFrame or not Root then
		TPButton.Text = "SALVE UMA LOCALIZAÇÃO"
		task.delay(1.5, function()
			if TPButton.Parent then TPButton.Text = "TP POR VELOCIDADE • IR" end
		end)
		return
	end

	local Number = tonumber(TPBox.Text)
	if Number then TPValue = math.clamp(Number, 1, 1000) end

	StepTeleporting = true
	CancelStepTeleport = false
	TPButton.Text = "CANCELAR TP"

	local Destination = TargetCFrame.Position
	local StartTime = os.clock()
	local MaxDuration = math.clamp(
		(Destination - Root.Position).Magnitude / math.max(TPValue, 1) + 10,
		10, 180
	)

	while StepTeleporting and not CancelStepTeleport do
		if not Root or not Root.Parent then break end
		if os.clock() - StartTime > MaxDuration then break end

		local Difference = Destination - Root.Position
		local Distance = Difference.Magnitude
		if Distance <= 0.8 then break end

		local dt = RunService.Heartbeat:Wait()
		local Step = math.min(Distance, math.max(TPValue, 1) * dt)

		Root.CFrame = CFrame.new(Root.Position + Difference.Unit * Step)
		Root.AssemblyLinearVelocity = Vector3.zero
		Root.AssemblyAngularVelocity = Vector3.zero
	end

	if StepTeleporting and not CancelStepTeleport and Root and Root.Parent then
		Root.CFrame = TargetCFrame
		Root.AssemblyLinearVelocity = Vector3.zero
		Root.AssemblyAngularVelocity = Vector3.zero
		TPButton.Text = "CHEGOU"
	else
		TPButton.Text = "TP POR VELOCIDADE • IR"
	end

	StepTeleporting = false
	CancelStepTeleport = false

	task.delay(1.5, function()
		if TPButton.Parent then TPButton.Text = "TP POR VELOCIDADE • IR" end
	end)
end

TPButton.MouseButton1Click:Connect(function()
	if StepTeleporting then
		CancelStepTeleport = true
	else
		task.spawn(StartStepTeleport)
	end
end)


-- ==================== SPAM TP V1 / V2 ====================
local SpamTPV1Enabled = false
local SpamTPV1Connection = nil
local SpamTPV2Enabled = false
local SpamTPV2Connection = nil
local SpamTPV2Busy = false

local function GetSpamTarget()
    return FloatingSavedPosition or GetSafeSavedCFrame()
end

local function StopSpamTPV1()
    SpamTPV1Enabled = false
    if SpamTPV1Connection then
        SpamTPV1Connection:Disconnect()
        SpamTPV1Connection = nil
    end
end

local function StartSpamTPV1()
    if SpamTPV1Connection then return end
    local LastSpamTPV1 = 0
    SpamTPV1Connection = RunService.Heartbeat:Connect(function()
        if not SpamTPV1Enabled or not Root or not Root.Parent then return end
        local Now = os.clock()
        if Now - LastSpamTPV1 < 0.08 then return end
        LastSpamTPV1 = Now
        local Target = GetSpamTarget()
        if not IsValidCFrame(Target) then return end

        Root.CFrame = Target
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function SetSpamTPV1(Value)
    SpamTPV1Enabled = Value == true
    if SpamTPV1Enabled then
        -- V1 and V2 are mutually exclusive.
        if SpamTPV2Enabled then
            SpamTPV2Enabled = false
            if SpamTPV2Connection then
                SpamTPV2Connection:Disconnect()
                SpamTPV2Connection = nil
            end
            SpamTPV2Busy = false
        end
        StartSpamTPV1()
    else
        StopSpamTPV1()
    end

    if SpamTPV1Button then
        SpamTPV1Button.Text = "  SPAM TP V1 • " .. (SpamTPV1Enabled and "ON" or "OFF")
    end
    if SpamTPV1ButtonSmall then
        SpamTPV1ButtonSmall.Text = "SPAM TP V1 • " .. (SpamTPV1Enabled and "ON" or "OFF")
    end
    if SpamTPV2Button then
        SpamTPV2Button.Text = "  SPAM TP V2 • " .. (SpamTPV2Enabled and "ON" or "OFF")
    end
    if SpamTPV2ButtonSmall then
        SpamTPV2ButtonSmall.Text = "SPAM TP V2 • " .. (SpamTPV2Enabled and "ON" or "OFF")
    end
    if SaveConfig then SaveConfig() end
end

local function StopSpamTPV2()
    SpamTPV2Enabled = false
    if SpamTPV2Connection then
        SpamTPV2Connection:Disconnect()
        SpamTPV2Connection = nil
    end
    SpamTPV2Busy = false
end

local function StartSpamTPV2()
    if SpamTPV2Connection then return end
    SpamTPV2Connection = RunService.Heartbeat:Connect(function()
        if not SpamTPV2Enabled or SpamTPV2Busy or not Root or not Root.Parent then return end
        local Target = GetSpamTarget()
        if not IsValidCFrame(Target) then return end

        SpamTPV2Busy = true
        task.spawn(function()
            pcall(function()
                local Behind = Target.Position - Target.LookVector * 5
                Root.AssemblyLinearVelocity = Vector3.zero
                Root.AssemblyAngularVelocity = Vector3.zero
                Root.CFrame = CFrame.lookAt(Behind, Target.Position)

                RunService.Heartbeat:Wait()

                if SpamTPV2Enabled and Root and Root.Parent then
                    local StartCF = Root.CFrame
                    local Duration = 0.08
                    local Started = os.clock()

                    while SpamTPV2Enabled and Root and Root.Parent do
                        local Alpha = math.clamp((os.clock() - Started) / Duration, 0, 1)
                        local Pos = StartCF.Position:Lerp(Target.Position, Alpha)
                        Root.CFrame = CFrame.lookAt(Pos, Target.Position)
                        Root.AssemblyLinearVelocity = Vector3.zero
                        Root.AssemblyAngularVelocity = Vector3.zero

                        if Alpha >= 1 then break end
                        RunService.Heartbeat:Wait()
                    end

                    if SpamTPV2Enabled and Root and Root.Parent then
                        Root.CFrame = Target
                        Root.AssemblyLinearVelocity = Vector3.zero
                        Root.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end)
            SpamTPV2Busy = false
        end)
    end)
end

local function SetSpamTPV2(Value)
    SpamTPV2Enabled = Value == true
    if SpamTPV2Enabled then
        -- V1 and V2 are mutually exclusive.
        if SpamTPV1Enabled then
            StopSpamTPV1()
        end
        StartSpamTPV2()
    else
        StopSpamTPV2()
    end

    if SpamTPV1Button then
        SpamTPV1Button.Text = "  SPAM TP V1 • " .. (SpamTPV1Enabled and "ON" or "OFF")
    end
    if SpamTPV1ButtonSmall then
        SpamTPV1ButtonSmall.Text = "SPAM TP V1 • " .. (SpamTPV1Enabled and "ON" or "OFF")
    end
    if SpamTPV2Button then
        SpamTPV2Button.Text = "  SPAM TP V2 • " .. (SpamTPV2Enabled and "ON" or "OFF")
    end
    if SpamTPV2ButtonSmall then
        SpamTPV2ButtonSmall.Text = "SPAM TP V2 • " .. (SpamTPV2Enabled and "ON" or "OFF")
    end
    if SaveConfig then SaveConfig() end
end

SpamTPV1Button.MouseButton1Click:Connect(function()
    local Target = GetSpamTarget()
    if not IsValidCFrame(Target) then
        SpamTPV1Button.Text = "  SPAM TP V1 • SEM LOCAL"
        task.delay(1.2, function()
            if SpamTPV1Button.Parent then
                SpamTPV1Button.Text = "  SPAM TP V1 • " .. (SpamTPV1Enabled and "ON" or "OFF")
            end
        end)
        return
    end
    SetSpamTPV1(not SpamTPV1Enabled)
end)

SpamTPV2Button.MouseButton1Click:Connect(function()
    local Target = GetSpamTarget()
    if not IsValidCFrame(Target) then
        SpamTPV2Button.Text = "  SPAM TP V2 • SEM LOCAL"
        task.delay(1.2, function()
            if SpamTPV2Button.Parent then
                SpamTPV2Button.Text = "  SPAM TP V2 • " .. (SpamTPV2Enabled and "ON" or "OFF")
            end
        end)
        return
    end
    SetSpamTPV2(not SpamTPV2Enabled)
end)

-- ==================== FPS BOOST ====================
local FPSOriginals = {}
local FPSOriginalLighting = nil
local FPSOriginalQuality = nil

local function ApplyFPSBoost()
	if FPSBoostEnabled then return end
	FPSBoostEnabled = true
	table.clear(FPSOriginals)

	pcall(function()
		local Lighting = game:GetService("Lighting")
		FPSOriginalLighting = {
			GlobalShadows = Lighting.GlobalShadows,
			EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
			EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
			FogEnd = Lighting.FogEnd,
		}

		Lighting.GlobalShadows = false
		Lighting.EnvironmentDiffuseScale = 0
		Lighting.EnvironmentSpecularScale = 0
		Lighting.FogEnd = math.min(Lighting.FogEnd, 100000)
	end)

	pcall(function()
		local GameSettings = UserSettings():GetService("UserGameSettings")
		FPSOriginalQuality = GameSettings.SavedQualityLevel
		GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
	end)

	for _, Object in ipairs(workspace:GetDescendants()) do
		if Object:IsA("BasePart") then
			FPSOriginals[Object] = FPSOriginals[Object] or {
				CastShadow = Object.CastShadow,
			}
			Object.CastShadow = false
		elseif Object:IsA("ParticleEmitter")
			or Object:IsA("Trail")
			or Object:IsA("Beam") then
			FPSOriginals[Object] = FPSOriginals[Object] or {
				Enabled = Object.Enabled,
			}
			Object.Enabled = false
		elseif Object:IsA("PostEffect") then
			FPSOriginals[Object] = FPSOriginals[Object] or {
				Enabled = Object.Enabled,
			}
			Object.Enabled = false
		end
	end

	FPSButton.Text = "  FPS BOOST • ON"
end

local function RemoveFPSBoost()
	if not FPSBoostEnabled then return end
	FPSBoostEnabled = false

	for Object, Original in pairs(FPSOriginals) do
		if Object and Object.Parent then
			pcall(function()
				if Original.CastShadow ~= nil then
					Object.CastShadow = Original.CastShadow
				end
				if Original.Enabled ~= nil then
					Object.Enabled = Original.Enabled
				end
			end)
		end
	end
	table.clear(FPSOriginals)

	pcall(function()
		local Lighting = game:GetService("Lighting")
		if FPSOriginalLighting then
			Lighting.GlobalShadows = FPSOriginalLighting.GlobalShadows
			Lighting.EnvironmentDiffuseScale = FPSOriginalLighting.EnvironmentDiffuseScale
			Lighting.EnvironmentSpecularScale = FPSOriginalLighting.EnvironmentSpecularScale
			Lighting.FogEnd = FPSOriginalLighting.FogEnd
		end
	end)

	pcall(function()
		local GameSettings = UserSettings():GetService("UserGameSettings")
		if FPSOriginalQuality then
			GameSettings.SavedQualityLevel = FPSOriginalQuality
		end
	end)

	FPSButton.Text = "  FPS BOOST • OFF"
end

FPSButton.MouseButton1Click:Connect(function()
	if FPSBoostEnabled then
		RemoveFPSBoost()
	else
		ApplyFPSBoost()
	end
	if SaveConfig then SaveConfig() end
end)

workspace.DescendantAdded:Connect(function(Object)
	if not FPSBoostEnabled then return end

	task.defer(function()
		if not Object.Parent then return end

		if Object:IsA("BasePart") then
			FPSOriginals[Object] = FPSOriginals[Object] or {
				CastShadow = Object.CastShadow,
			}
			Object.CastShadow = false
		elseif Object:IsA("ParticleEmitter")
			or Object:IsA("Trail")
			or Object:IsA("Beam")
			or Object:IsA("PostEffect") then
			FPSOriginals[Object] = FPSOriginals[Object] or {
				Enabled = Object.Enabled,
			}
			Object.Enabled = false
		end
	end)
end)

NoclipButton.MouseButton1Click:Connect(function()
	NoclipEnabled = not NoclipEnabled

	NoclipButton.Text =
		"  NOCLIP • " ..
		(NoclipEnabled and "ON" or "OFF")
end)

AntiRagdollButton.MouseButton1Click:Connect(function()
	AntiRagdollEnabled = not AntiRagdollEnabled

	AntiRagdollButton.Text =
		"  ANTI-RAGDOLL • " ..
		(AntiRagdollEnabled and "ON" or "OFF")
end)

local function ConfigurePrompt(Prompt)
	if not Prompt:IsA("ProximityPrompt") then return end

	if InstantPromptEnabled then
		if Prompt:GetAttribute("SnooOriginalHold") == nil then
			Prompt:SetAttribute(
				"SnooOriginalHold",
				Prompt.HoldDuration
			)
		end

		Prompt.HoldDuration = 0
		Prompt.RequiresLineOfSight = false
	else
		local Original =
			Prompt:GetAttribute("SnooOriginalHold")

		if typeof(Original) == "number" then
			Prompt.HoldDuration = Original
		end
	end
end

local PromptScanDirty = true
local function UpdatePrompts(Force)
	if not Force and not PromptScanDirty then return end
	PromptScanDirty = false
	for _, Object in ipairs(workspace:GetDescendants()) do
		if Object:IsA("ProximityPrompt") then
			ConfigurePrompt(Object)
		end
	end
end

AutoStealButton.MouseButton1Click:Connect(function()
	AutoStealEnabled = not AutoStealEnabled
	AutoStealButton.Text = "  AUTO STEAL • " .. (AutoStealEnabled and "ON" or "OFF")
	if AutoStealEnabled then StartAutoSteal() else StopAutoSteal() end
	if SaveConfig then SaveConfig() end
end)

PromptButton.MouseButton1Click:Connect(function()
	InstantPromptEnabled = not InstantPromptEnabled

	UpdatePrompts(true)

	PromptButton.Text =
		"  INSTANT PROMPT • " ..
		(InstantPromptEnabled and "ON" or "OFF")
end)

workspace.DescendantAdded:Connect(function(Object)
	if Object:IsA("ProximityPrompt") then
		task.defer(function()
			if Object:IsA("ProximityPrompt") then
			PromptScanDirty = true
			if InstantPromptEnabled then ConfigurePrompt(Object) end
		end
		end)
	end
end)

task.spawn(function()
	while Gui.Parent do
		task.wait(3)

		if InstantPromptEnabled then
			UpdatePrompts(false)
		end
	end
end)

JumpButton.MouseButton1Click:Connect(function()
	if not Humanoid then return end

	if not JumpEnabled then
		OriginalJumpPower = Humanoid.JumpPower

		local Number = tonumber(JumpBox.Text)
		if Number then
			JumpValue = math.clamp(Number, 1, 500)
		end

		Humanoid.UseJumpPower = true
		Humanoid.JumpPower = JumpValue

		JumpEnabled = true
		JumpButton.Text = "  JUMP POWER • ON"
	else
		if OriginalJumpPower ~= nil then
			Humanoid.UseJumpPower = true
			Humanoid.JumpPower = OriginalJumpPower
		end

		JumpEnabled = false
		JumpButton.Text = "  JUMP POWER • OFF"
	end
end)

local StartInfiniteJump
local StopInfiniteJump

InfiniteButton.MouseButton1Click:Connect(function()
	InfiniteJumpEnabled = not InfiniteJumpEnabled

	if InfiniteJumpEnabled then
		StartInfiniteJump()
	else
		StopInfiniteJump()
	end

	InfiniteButton.Text =
		"  INFINITY JUMP • " ..
		(InfiniteJumpEnabled and "ON" or "OFF")
end)

local InfiniteJumpRequestConnection

StartInfiniteJump = function()
	if InfiniteJumpRequestConnection then
		InfiniteJumpRequestConnection:Disconnect()
	end

	InfiniteJumpRequestConnection = UserInputService.JumpRequest:Connect(function()
		if not InfiniteJumpEnabled then return end
		local CharacterObject = Player.Character
		if not CharacterObject then return end
		local HumanoidObject = CharacterObject:FindFirstChildOfClass("Humanoid")
		if HumanoidObject and HumanoidObject.Health > 0 then
			HumanoidObject:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

StopInfiniteJump = function()
	if InfiniteJumpRequestConnection then
		InfiniteJumpRequestConnection:Disconnect()
		InfiniteJumpRequestConnection = nil
	end
end

local ResetCooldown = 0

local function ForceAntiRagdollReset()
	if not Character or not Humanoid or not Root or Humanoid.Health <= 0 then
		return
	end

	pcall(function()
		Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		Root.Velocity = Vector3.zero
		Root.RotVelocity = Vector3.zero
		Root.AssemblyLinearVelocity = Vector3.zero
		Root.AssemblyAngularVelocity = Vector3.zero

		for _, Object in ipairs(Character:GetDescendants()) do
			if Object:IsA("Motor6D") then Object.Enabled = true end
			if Object:IsA("Constraint") then Object.Enabled = true end
		end

		if workspace.CurrentCamera then
			workspace.CurrentCamera.CameraSubject = Humanoid
		end

		local PlayerModule = Player:FindFirstChild("PlayerScripts")
			and Player.PlayerScripts:FindFirstChild("PlayerModule")
		local ControlModule = PlayerModule and PlayerModule:FindFirstChild("ControlModule")
		if ControlModule then
			local Controls = require(ControlModule)
			if Controls then Controls:Enable() end
		end

		Humanoid.AutoRotate = true
		Humanoid.PlatformStand = false
		Humanoid.Sit = false
	end)
end

local LastMovementUpdate = 0
local function UpdateCharacterState()
	if not Character or not Humanoid or not Root or not Root.Parent then return end

	if WalkEnabled and not Traveling and not StepTeleporting and Humanoid.WalkSpeed ~= WalkValue then
		Humanoid.WalkSpeed = WalkValue
	end

	if JumpEnabled then
		Humanoid.UseJumpPower = true
		if Humanoid.JumpPower ~= JumpValue then Humanoid.JumpPower = JumpValue end
	end

	if NoclipEnabled then
		for _, Object in ipairs(CharacterParts) do
			if Object and Object.Parent then
				if NoclipOriginals[Object] == nil then NoclipOriginals[Object] = Object.CanCollide end
				if Object.CanCollide then Object.CanCollide = false end
			end
		end
	elseif next(NoclipOriginals) ~= nil then
		for Object, Original in pairs(NoclipOriginals) do
			if Object and Object.Parent then Object.CanCollide = Original end
		end
		table.clear(NoclipOriginals)
	end

	if AntiRagdollEnabled then
		local State = Humanoid:GetState()
		local Ragdolled = State == Enum.HumanoidStateType.Ragdoll
			or State == Enum.HumanoidStateType.FallingDown
			or State == Enum.HumanoidStateType.Physics
		if Ragdolled then
			local Now = os.clock()
			if Now - ResetCooldown > 0.20 then
				ResetCooldown = Now
				ForceAntiRagdollReset()
			end
		end
	end
end

-- Atualiza em intervalos curtos, evitando GetDescendants() a cada frame.
RunService.Heartbeat:Connect(function()
	local Now = os.clock()
	if Now - LastMovementUpdate >= 0.05 then
		LastMovementUpdate = Now
		UpdateCharacterState()
	end
end)

local Minimized = false

Minimize.MouseButton1Click:Connect(function()
	Minimized = not Minimized

	if Minimized then
		Content.Visible = false
		TabBar.Visible = false
		Minimize.Text = "+"

		Main:TweenSize(
			UDim2.fromOffset(200, 52),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.2,
			true
		)
	else
		Content.Visible = true
		TabBar.Visible = true
		Minimize.Text = "—"

		Main:TweenSize(
			UDim2.fromOffset(540, 420),
				Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.2,
			true
		)
	end
end)

local Dragging = false
local DragStart = nil
local StartPosition = nil

Header.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then

		Dragging = true
		DragStart = Input.Position
		StartPosition = Main.Position
	end
end)

UserInputService.InputChanged:Connect(function(Input)
	if not Dragging then return end

	if Input.UserInputType == Enum.UserInputType.MouseMovement
		or Input.UserInputType == Enum.UserInputType.Touch then

		local Delta = Input.Position - DragStart

		Main.Position = UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + Delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then

		Dragging = false
	end
end)

local function UpdateCanvas()
	Content.CanvasSize =
		UDim2.fromOffset(
			0,
			Layout.AbsoluteContentSize.Y + 12
		)
end

for _, PageData in pairs(Pages) do
	PageData.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if PageData.Frame.Visible then
			Content.CanvasSize = UDim2.fromOffset(0, PageData.Layout.AbsoluteContentSize.Y + 12)
		end
	end)
end

UpdateCanvas()

-- ==================== TP BEST ====================
-- Seleciona o melhor jogador atualmente disponível.
-- Prioridade de estatística: Coins, Money, Cash, Value, Score; depois o primeiro valor numérico de leaderstats.
-- TP BEST usa a mesma lista real de Brainrots disponíveis no ESP.
-- A função é declarada aqui e resolvida no clique, depois que ESPFindBestTarget existir.
local function TPBest()
	if not Root or not Root.Parent then return nil end
	local Finder = ESPFindBestTargetReference
	if type(Finder) ~= "function" then return nil end
	local Target = Finder(true)
	if not Target or not Target.Part or not Target.Part.Parent then return nil end
	local TargetPart = Target.Part
	local TargetCFrame = CFrame.new(TargetPart.Position + Vector3.new(0, 4, 0))
	if not IsValidCFrame(TargetCFrame) then return nil end
	Root.CFrame = TargetCFrame
	Root.AssemblyLinearVelocity = Vector3.zero
	Root.AssemblyAngularVelocity = Vector3.zero
	CurrentBestTarget = Target
	return Target
end

-- ==================== FLOATING TP PANEL ====================
local FloatingTPGui = Instance.new("ScreenGui")
FloatingTPGui.Name = "SnooFloatingTP"
FloatingTPGui.ResetOnSpawn = false
FloatingTPGui.IgnoreGuiInset = true
FloatingTPGui.DisplayOrder = 30
FloatingTPGui.Parent = PlayerGui

local FloatingTP = Instance.new("Frame")
FloatingTP.Name = "FloatingTP"
FloatingTP.Size = UDim2.fromOffset(172, 214)
FloatingTP.Position = UDim2.fromOffset(
	type(LoadedConfig.FloatingXOffset) == "number" and LoadedConfig.FloatingXOffset or 20,
	type(LoadedConfig.FloatingYOffset) == "number" and LoadedConfig.FloatingYOffset or 300
)
FloatingTP.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
FloatingTP.BackgroundTransparency = 0.04
FloatingTP.BorderSizePixel = 0
FloatingTP.Active = true
FloatingTP.Parent = FloatingTPGui

local FloatingCorner = Instance.new("UICorner")
FloatingCorner.CornerRadius = UDim.new(0, 10)
FloatingCorner.Parent = FloatingTP
local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Color = Color3.fromRGB(155, 70, 255)
FloatingStroke.Thickness = 1.5
FloatingStroke.Transparency = 0.12
FloatingStroke.Parent = FloatingTP

local FloatingTitle = Instance.new("TextLabel")
FloatingTitle.Size = UDim2.new(1, -12, 0, 16)
FloatingTitle.Position = UDim2.fromOffset(6, 4)
FloatingTitle.BackgroundTransparency = 1
FloatingTitle.Text = "TP CONTROL"
FloatingTitle.TextColor3 = Color3.fromRGB(190, 90, 255)
FloatingTitle.TextSize = 8
FloatingTitle.Font = Enum.Font.GothamBold
FloatingTitle.TextXAlignment = Enum.TextXAlignment.Center
FloatingTitle.Parent = FloatingTP

local SaveTPButton = Instance.new("TextButton")
SaveTPButton.Size = UDim2.new(0.5, -9, 0, 28)
SaveTPButton.Position = UDim2.fromOffset(6, 24)
SaveTPButton.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
SaveTPButton.BorderSizePixel = 0
SaveTPButton.Text = "SALVAR TP"
SaveTPButton.TextColor3 = Color3.fromRGB(245, 245, 245)
SaveTPButton.TextSize = 8
SaveTPButton.Font = Enum.Font.GothamBold
SaveTPButton.AutoButtonColor = false
SaveTPButton.Parent = FloatingTP

local TPButtonSmall = Instance.new("TextButton")
TPButtonSmall.Size = UDim2.new(0.5, -9, 0, 28)
TPButtonSmall.Position = UDim2.new(0.5, 3, 0, 24)
TPButtonSmall.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
TPButtonSmall.BorderSizePixel = 0
TPButtonSmall.Text = "TP"
TPButtonSmall.TextColor3 = Color3.fromRGB(245, 245, 245)
TPButtonSmall.TextSize = 9
TPButtonSmall.Font = Enum.Font.GothamBold
TPButtonSmall.AutoButtonColor = false
TPButtonSmall.Parent = FloatingTP

local TPBestButton = Instance.new("TextButton")
TPBestButton.Size = UDim2.new(1, -12, 0, 28)
TPBestButton.Position = UDim2.fromOffset(6, 58)
TPBestButton.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
TPBestButton.BorderSizePixel = 0
TPBestButton.Text = "TP BEST"
TPBestButton.TextColor3 = Color3.fromRGB(245, 245, 245)
TPBestButton.TextSize = 8
TPBestButton.Font = Enum.Font.GothamBold
TPBestButton.AutoButtonColor = false
TPBestButton.Parent = FloatingTP

local TravelButtonSmall = Instance.new("TextButton")
TravelButtonSmall.Size = UDim2.new(1, -12, 0, 28)
TravelButtonSmall.Position = UDim2.fromOffset(6, 92)
TravelButtonSmall.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
TravelButtonSmall.BorderSizePixel = 0
TravelButtonSmall.Text = "IR PELO TRAJETO"
TravelButtonSmall.TextColor3 = Color3.fromRGB(245, 245, 245)
TravelButtonSmall.TextSize = 8
TravelButtonSmall.Font = Enum.Font.GothamBold
TravelButtonSmall.AutoButtonColor = false
TravelButtonSmall.Parent = FloatingTP

SpamTPV1ButtonSmall = Instance.new("TextButton")
SpamTPV1ButtonSmall.Size = UDim2.new(1, -12, 0, 28)
SpamTPV1ButtonSmall.Position = UDim2.fromOffset(6, 126)
SpamTPV1ButtonSmall.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
SpamTPV1ButtonSmall.BorderSizePixel = 0
SpamTPV1ButtonSmall.Text = "SPAM TP V1 • OFF"
SpamTPV1ButtonSmall.TextColor3 = Color3.fromRGB(245, 245, 245)
SpamTPV1ButtonSmall.TextSize = 8
SpamTPV1ButtonSmall.Font = Enum.Font.GothamBold
SpamTPV1ButtonSmall.AutoButtonColor = false
SpamTPV1ButtonSmall.Parent = FloatingTP

SpamTPV2ButtonSmall = Instance.new("TextButton")
SpamTPV2ButtonSmall.Size = UDim2.new(1, -12, 0, 28)
SpamTPV2ButtonSmall.Position = UDim2.fromOffset(6, 160)
SpamTPV2ButtonSmall.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
SpamTPV2ButtonSmall.BorderSizePixel = 0
SpamTPV2ButtonSmall.Text = "SPAM TP V2 • OFF"
SpamTPV2ButtonSmall.TextColor3 = Color3.fromRGB(245, 245, 245)
SpamTPV2ButtonSmall.TextSize = 8
SpamTPV2ButtonSmall.Font = Enum.Font.GothamBold
SpamTPV2ButtonSmall.AutoButtonColor = false
SpamTPV2ButtonSmall.Parent = FloatingTP

for _, ButtonObject in ipairs({SaveTPButton, TPButtonSmall, TPBestButton, TravelButtonSmall, SpamTPV1ButtonSmall, SpamTPV2ButtonSmall}) do
	local ButtonCorner = Instance.new("UICorner")
	ButtonCorner.CornerRadius = UDim.new(0, 8)
	ButtonCorner.Parent = ButtonObject
	local ButtonStroke = Instance.new("UIStroke")
	ButtonStroke.Color = Color3.fromRGB(40, 40, 48)
	ButtonStroke.Transparency = 0.1
	ButtonStroke.Parent = ButtonObject
	ButtonObject.MouseEnter:Connect(function()
		ButtonObject.BackgroundColor3 = Color3.fromRGB(42, 25, 60)
		ButtonStroke.Color = Color3.fromRGB(190, 90, 255)
	end)
	ButtonObject.MouseLeave:Connect(function()
		ButtonObject.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
		ButtonStroke.Color = Color3.fromRGB(40, 40, 48)
	end)
end

if type(LoadedConfig.SavedTP) == "table" and #LoadedConfig.SavedTP == 12 then
	local ok, cf = pcall(function() return CFrame.new(table.unpack(LoadedConfig.SavedTP)) end)
	if ok and IsValidCFrame(cf) then
		FloatingSavedPosition = cf
		SavedPosition = cf
	end
end

SpamTPV1Enabled = LoadedConfig.SpamTPV1Enabled == true
SpamTPV2Enabled = LoadedConfig.SpamTPV2Enabled == true
UltraESPEnabled = LoadedConfig.UltraESPEnabled == true
if SpamTPV1Enabled and SpamTPV2Enabled then
    SpamTPV2Enabled = false
end

SaveConfig = function()
	if type(writefile) ~= "function" then return end
	local Data = {
		Version = SCRIPT_VERSION,
		WalkValue = WalkValue,
		JumpValue = JumpValue,
		TravelValue = TravelValue,
		TPValue = TPValue,
		StealDuration = StealDuration,
		StealRadius = StealRadius,
		WalkEnabled = WalkEnabled,
		JumpEnabled = JumpEnabled,
		NoclipEnabled = NoclipEnabled,
		AntiRagdollEnabled = AntiRagdollEnabled,
		InfiniteJumpEnabled = InfiniteJumpEnabled,
		InstantPromptEnabled = InstantPromptEnabled,
		FPSBoostEnabled = FPSBoostEnabled,
		AutoStealEnabled = AutoStealEnabled,
		SpamTPV1Enabled = SpamTPV1Enabled,
		SpamTPV2Enabled = SpamTPV2Enabled,
		UltraESPEnabled = UltraESPEnabled,
		BestLineEnabled = BestLineEnabled,
		Language = (Languages and Languages[Language]) and Language or "pt-BR",
		SavedTP = (function()
			if not FloatingSavedPosition then return nil end
			return {FloatingSavedPosition:GetComponents()}
		end)(),
		FloatingXScale = 0,
		FloatingXOffset = FloatingTP.Position.X.Offset,
		FloatingYScale = 0,
		FloatingYOffset = FloatingTP.Position.Y.Offset,
	}
	pcall(function() writefile(ConfigFileName, HttpService:JSONEncode(Data)) end)
end

SaveTPButton.MouseButton1Click:Connect(function()
	if not Root then
		SaveTPButton.Text = "SEM ROOT"
		task.delay(1.2, function()
			if SaveTPButton.Parent then SaveTPButton.Text = "SALVAR TP" end
		end)
		return
	end

	-- Salva o CFrame completo, incluindo posição e rotação exatas.
	if not IsValidCFrame(Root.CFrame) then
		SaveTPButton.Text = "LOCAL INVÁLIDO"
		return
	end
	FloatingSavedPosition = Root.CFrame
	SavedPosition = Root.CFrame
	SaveTPButton.Text = "SALVO!"
	if SaveConfig then SaveConfig() end
	task.delay(1.2, function()
		if SaveTPButton.Parent then SaveTPButton.Text = "SALVAR TP" end
	end)
end)

SpamTPV1ButtonSmall.MouseButton1Click:Connect(function()
    local Target = GetSpamTarget()
    if not IsValidCFrame(Target) then
        SpamTPV1ButtonSmall.Text = "SEM LOCAL"
        task.delay(1.2, function()
            if SpamTPV1ButtonSmall.Parent then
                SpamTPV1ButtonSmall.Text = "SPAM TP V1 • " .. (SpamTPV1Enabled and "ON" or "OFF")
            end
        end)
        return
    end
    SetSpamTPV1(not SpamTPV1Enabled)
end)

SpamTPV2ButtonSmall.MouseButton1Click:Connect(function()
    local Target = GetSpamTarget()
    if not IsValidCFrame(Target) then
        SpamTPV2ButtonSmall.Text = "SEM LOCAL"
        task.delay(1.2, function()
            if SpamTPV2ButtonSmall.Parent then
                SpamTPV2ButtonSmall.Text = "SPAM TP V2 • " .. (SpamTPV2Enabled and "ON" or "OFF")
            end
        end)
        return
    end
    SetSpamTPV2(not SpamTPV2Enabled)
end)

TPButtonSmall.MouseButton1Click:Connect(function()
	local Target = FloatingSavedPosition or GetSafeSavedCFrame()
	if not IsValidCFrame(Target) or not Root then
		TPButtonSmall.Text = "SEM TP"
		task.delay(1.2, function()
			if TPButtonSmall.Parent then TPButtonSmall.Text = "TP" end
		end)
		return
	end

	-- Teleporta para o CFrame salvo sem alterar a orientação registrada.
	Root.CFrame = Target
	Root.AssemblyLinearVelocity = Vector3.zero
	Root.AssemblyAngularVelocity = Vector3.zero
	if SaveConfig then SaveConfig() end
	TPButtonSmall.Text = "OK"
	task.delay(1.2, function()
		if TPButtonSmall.Parent then TPButtonSmall.Text = "TP" end
	end)
end)

TPBestButton.MouseButton1Click:Connect(function()
	local Target = ESPFindBestTargetReference and ESPFindBestTargetReference(true)
	if Target then
		CurrentBestTarget = Target
		BestLineEnabled = true
		ESPStartVisual()
		local Result = TPBest()
		local Name = Target.Name or Target.Object.Name or "MELHOR"
		TPBestButton.Text = "BEST: " .. string.sub(Name, 1, 18)
		ShowBestNotice(Name)
	else
		TPBestButton.Text = "NÃO ENCONTRADO"
		ShowBestNotice((Texts and Texts[Language] and Texts[Language].noBest) or "NENHUM DISPONÍVEL")
	end
	task.delay(1.5, function()
		if TPBestButton.Parent then TPBestButton.Text = "TP BEST" end
	end)
end)

TravelButtonSmall.MouseButton1Click:Connect(function()
	if Traveling then
		CancelTravel = true
		TravelButtonSmall.Text = "CANCELANDO..."
		return
	end

	if not (FloatingSavedPosition or SavedPosition) then
		TravelButtonSmall.Text = "SEM LOCAL"
		task.delay(1.2, function()
			if TravelButtonSmall.Parent then
				TravelButtonSmall.Text = "IR PELO TRAJETO"
			end
		end)
		return
	end

	-- Keep the main travel system and the floating button synchronized.
	if FloatingSavedPosition then
		SavedPosition = FloatingSavedPosition
	end

	TravelButtonSmall.Text = "TRAJETO..."
	task.spawn(function()
		StartTravel()
		if TravelButtonSmall.Parent and not Traveling then
			TravelButtonSmall.Text = "IR PELO TRAJETO"
		end
	end)
end)


local FloatingDragging = false
local FloatingDragStart = nil
local FloatingStartPosition = nil
local FloatingDragMoved = false

local function IsInsideButton(InputPosition)
	for _, Object in ipairs(FloatingTP:GetDescendants()) do
		if Object:IsA("GuiButton") and Object.Visible then
			local P = Object.AbsolutePosition
			local S = Object.AbsoluteSize
			if InputPosition.X >= P.X and InputPosition.X <= P.X + S.X
				and InputPosition.Y >= P.Y and InputPosition.Y <= P.Y + S.Y then
				return true
			end
		end
	end
	return false
end

-- Drag only from empty/title space, so the TP/Salvar/Trajeto buttons remain clickable.
FloatingTP.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then

		if IsInsideButton(Input.Position) then
			return
		end

		FloatingDragging = true
		FloatingDragMoved = false
		FloatingDragStart = Input.Position
		FloatingStartPosition = FloatingTP.Position
	end
end)
UserInputService.InputChanged:Connect(function(Input)
	if not FloatingDragging then return end

	if Input.UserInputType == Enum.UserInputType.MouseMovement
		or Input.UserInputType == Enum.UserInputType.Touch then

		local Delta = Input.Position - FloatingDragStart
		if Delta.Magnitude > 3 then
			FloatingDragMoved = true
		end

		local Camera = workspace.CurrentCamera
		local Viewport = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)

		local NewX = FloatingStartPosition.X.Offset + Delta.X
		local NewY = FloatingStartPosition.Y.Offset + Delta.Y

		-- Keep the floating panel on-screen.
		local Width = FloatingTP.AbsoluteSize.X
		local Height = FloatingTP.AbsoluteSize.Y
		local Margin = 4

		NewX = math.clamp(NewX, Margin, math.max(Margin, Viewport.X - Width - Margin))
		NewY = math.clamp(NewY, Margin, math.max(Margin, Viewport.Y - Height - Margin))

		FloatingTP.Position = UDim2.fromOffset(NewX, NewY)
	end
end)
UserInputService.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
		FloatingDragging = false
		SaveConfig()
	end
end)

-- ==================== ESP ULTRA V10 BETA ====================
-- SOMENTE VISUAL.
-- Não altera CFrame, Position, HumanoidRootPart ou qualquer movimento do Player.
-- Procura nos modelos numerados 1..8 que estiverem dentro de workspace.Plots.
-- A preferência é global: entre os Brainrots que REALMENTE existem nos 1..8,
-- escolhe o de menor número de prioridade, independentemente do slot.

local ESPPriority = {
	["spyder elephant"] = 1,
	["strawberry elephant"] = 2,
	["headless horseman"] = 3,
	["meowl"] = 3,
	["john pork"] = 4,
	["skibid toilet"] = 5,
	["dragon gingerine"] = 6,
	["hydra dragon canneloni"] = 7,
	["dragon aquanini"] = 8,
	["arcadragon"] = 9,
	["signore carapace"] = 10,
	["antonio"] = 11,
	["la supreme combinasion"] = 12,
	["love love bear"] = 13,
	["elefanto frigo"] = 14,
	["dug dug dug"] = 15,
	["griffin"] = 16,
	["garama and madundung"] = 17,
}

local function ESPNormalize(Value)
	Value = string.lower(tostring(Value or ""))
	Value = Value:gsub("[%c]", "")
	Value = Value:gsub("[%p]", " ")
	Value = Value:gsub("%s+", " ")
	return Value:match("^%s*(.-)%s*$") or ""
end

local function ESPPriorityOf(Name)
	local Normalized = ESPNormalize(Name)
	return ESPPriority[Normalized]
end

local function ESPGetBrainrotName(Object)
	local Values = {Object.Name}

	for _, AttributeName in ipairs({
		"BrainrotName",
		"DisplayName",
		"AnimalName",
		"ModelName",
		"Brainrot",
	}) do
		local Value = Object:GetAttribute(AttributeName)
		if typeof(Value) == "string" and Value ~= "" then
			table.insert(Values, Value)
		end
	end

	for _, ChildName in ipairs({
		"BrainrotName",
		"DisplayName",
		"AnimalName",
		"ModelName",
		"Brainrot",
	}) do
		local Child = Object:FindFirstChild(ChildName, true)
		if Child then
			if Child:IsA("StringValue") and Child.Value ~= "" then
				table.insert(Values, Child.Value)
			elseif Child:IsA("TextLabel") and Child.Text ~= "" then
				table.insert(Values, Child.Text)
			end
		end
	end

	for _, Value in ipairs(Values) do
		local Priority = ESPPriorityOf(Value)
		if Priority then
			return Value, Priority
		end
	end

	return nil, nil
end

local function ESPGetPart(Object)
	if not Object then return nil end

	if Object:IsA("BasePart") then
		return Object
	end

	if Object:IsA("Model") then
		return Object.PrimaryPart
			or Object:FindFirstChild("HumanoidRootPart", true)
			or Object:FindFirstChildWhichIsA("BasePart", true)
	end

	return Object:FindFirstChildWhichIsA("BasePart", true)
end

local function ESPIsSlot(Object)
	local Number = tonumber(string.match(Object.Name, "^%s*(%d+)%s*$"))
	return Number and Number >= 1 and Number <= 8, Number
end

local ESPBestCache = nil
local ESPCacheDirty = true
local ESPPlots = nil
local ESPConnections = {}

local function ESPMarkDirty()
	ESPCacheDirty = true
end

local function ESPDisconnectWatchers()
	for _, Connection in ipairs(ESPConnections) do
		pcall(function() Connection:Disconnect() end)
	end
	table.clear(ESPConnections)
end

local function ESPWatchPlots()
	ESPDisconnectWatchers()
	ESPPlots = workspace:FindFirstChild("Plots")
	if not ESPPlots then return end
	table.insert(ESPConnections, ESPPlots.DescendantAdded:Connect(ESPMarkDirty))
	table.insert(ESPConnections, ESPPlots.DescendantRemoving:Connect(ESPMarkDirty))
end

local function ESPFindBestTarget(Force)
	if not Force and not ESPCacheDirty and ESPBestCache
		and ESPBestCache.Object and ESPBestCache.Object.Parent
		and ESPBestCache.Part and ESPBestCache.Part.Parent then
		return ESPBestCache
	end

	if not ESPPlots or not ESPPlots.Parent then ESPWatchPlots() end
	local Plots = ESPPlots
	if not Plots then ESPBestCache = nil; return nil end

	local Best = nil
	local BestPriority = math.huge

	-- IMPORTANTE: só varre quando o conteúdo dos Plots muda ou quando forçado.
	-- Não existe mais loop de scan periódico.
	for _, Slot in ipairs(Plots:GetChildren()) do
		local IsSlot, SlotNumber = ESPIsSlot(Slot)
		if IsSlot then
			local Candidates = {Slot}
			for _, Candidate in ipairs(Slot:GetDescendants()) do
				if Candidate:IsA("Model") or Candidate:IsA("BasePart") then
					table.insert(Candidates, Candidate)
				end
			end
			for _, Candidate in ipairs(Candidates) do
				local Name, Priority = ESPGetBrainrotName(Candidate)
				if Name and Priority and Priority < BestPriority then
					local Part = ESPGetPart(Candidate)
					if Part then
						BestPriority = Priority
						Best = {Name=Name, Priority=Priority, Part=Part, Slot=SlotNumber, Object=Candidate}
						if Priority == 1 then break end
					end
				end
			end
			if BestPriority == 1 then break end
		end
	end

	ESPCacheDirty = false
	ESPBestCache = Best
	return Best
end
ESPFindBestTargetReference = ESPFindBestTarget

-- GUI 2D: a linha é desenhada na tela entre o player e o Brainrot.
-- Ela não é um movimento/teleporte e não altera nenhuma propriedade do Player.
-- Aviso futurista no topo para o melhor encontrado.
local BestNoticeGui = Instance.new("ScreenGui")
BestNoticeGui.Name = "SnooBestNotice"
BestNoticeGui.ResetOnSpawn = false
BestNoticeGui.IgnoreGuiInset = true
BestNoticeGui.DisplayOrder = 1000000
BestNoticeGui.Parent = PlayerGui

local BestNotice = Instance.new("Frame")
BestNotice.Size = UDim2.fromOffset(300, 42)
BestNotice.Position = UDim2.new(0.5, -150, 0, 14)
BestNotice.BackgroundColor3 = Color3.fromRGB(8, 7, 12)
BestNotice.BackgroundTransparency = 0.08
BestNotice.BorderSizePixel = 0
BestNotice.Visible = false
BestNotice.Parent = BestNoticeGui
local BestCorner = Instance.new("UICorner")
BestCorner.CornerRadius = UDim.new(0, 10)
BestCorner.Parent = BestNotice
local BestStroke = Instance.new("UIStroke")
BestStroke.Color = Color3.fromRGB(155, 70, 255)
BestStroke.Thickness = 1.5
BestStroke.Parent = BestNotice
local BestGradient = Instance.new("UIGradient")
BestGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 8, 32)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 8, 12)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 8, 35))
})
BestGradient.Rotation = 15
BestGradient.Parent = BestNotice
local BestNoticeText = Instance.new("TextLabel")
BestNoticeText.Size = UDim2.fromScale(1, 1)
BestNoticeText.BackgroundTransparency = 1
BestNoticeText.Text = "MELHOR ENCONTRADO: -"
BestNoticeText.TextColor3 = Color3.fromRGB(255, 45, 65)
BestNoticeText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
BestNoticeText.TextStrokeTransparency = 0.25
BestNoticeText.TextSize = 13
BestNoticeText.Font = Enum.Font.GothamBlack
BestNoticeText.Parent = BestNotice

ShowBestNotice = function(Name)
	BestNoticeText.Text = (Texts and Texts[Language] and Texts[Language].best or "MELHOR ENCONTRADO: ") .. tostring(Name or "-")
	BestNotice.Visible = true
	BestNotice.BackgroundTransparency = 0.08
	task.delay(3, function()
		if BestNotice.Parent then BestNotice.Visible = false end
	end)
end

local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "SnooESPUltra"
ESPGui.ResetOnSpawn = false
ESPGui.IgnoreGuiInset = true
ESPGui.DisplayOrder = 999999
ESPGui.Enabled = false
ESPGui.Parent = PlayerGui

local ESPLine = Instance.new("Frame")
ESPLine.Name = "RedTrajectory"
ESPLine.AnchorPoint = Vector2.new(0, 0.5)
ESPLine.Size = UDim2.fromOffset(0, 3)
ESPLine.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ESPLine.BorderSizePixel = 0
ESPLine.Visible = false
ESPLine.ZIndex = 999999
ESPLine.Parent = ESPGui

local ESPName = Instance.new("TextLabel")
ESPName.Name = "BrainrotName"
ESPName.AnchorPoint = Vector2.new(0.5, 1)
ESPName.Size = UDim2.fromOffset(260, 28)
ESPName.BackgroundTransparency = 1
ESPName.TextColor3 = Color3.fromRGB(255, 35, 55)
ESPName.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
ESPName.TextStrokeTransparency = 0
ESPName.TextSize = 14
ESPName.Font = Enum.Font.GothamBlack
ESPName.Visible = false
ESPName.ZIndex = 1000000
ESPName.Parent = ESPGui

local ESPCurrentTarget = nil
BestLineEnabled = LoadedConfig.BestLineEnabled == true
local ESPVisualConnection = nil
local ESPVisualNext = 0

local function ESPUpdate()
	if not UltraESPEnabled and not BestLineEnabled then
		ESPLine.Visible = false
		ESPName.Visible = false
		return
	end

	local Camera = workspace.CurrentCamera
	local MyRoot = Root
	local Target = CurrentBestTarget or ESPCurrentTarget
	if not Camera or not MyRoot or not Target or not Target.Part or not Target.Part.Parent then
		ESPLine.Visible = false
		ESPName.Visible = false
		return
	end

	local PlayerPoint, PlayerVisible = Camera:WorldToViewportPoint(MyRoot.Position)
	local TargetPoint, TargetVisible = Camera:WorldToViewportPoint(Target.Part.Position)
	if not PlayerVisible or not TargetVisible or TargetPoint.Z <= 0 then
		ESPLine.Visible = false
		ESPName.Visible = false
		return
	end

	local DX = TargetPoint.X - PlayerPoint.X
	local DY = TargetPoint.Y - PlayerPoint.Y
	local Length = math.sqrt(DX * DX + DY * DY)
	ESPLine.Position = UDim2.fromOffset(PlayerPoint.X, PlayerPoint.Y)
	ESPLine.Size = UDim2.fromOffset(Length, 3)
	ESPLine.Rotation = math.deg(math.atan2(DY, DX))
	ESPLine.Visible = true
	ESPName.Position = UDim2.fromOffset(TargetPoint.X, TargetPoint.Y - 8)
	ESPName.Text = tostring(Target.Name or "MELHOR")
	ESPName.Visible = true
end

ESPStopVisual = function()
	if ESPVisualConnection then ESPVisualConnection:Disconnect(); ESPVisualConnection = nil end
	ESPLine.Visible = false
	ESPName.Visible = false
end

ESPStartVisual = function()
	if ESPVisualConnection then return end
	ESPVisualConnection = RunService.RenderStepped:Connect(function()
		local Now = os.clock()
		if Now < ESPVisualNext then return end
		ESPVisualNext = Now + (1/20)
		ESPUpdate()
	end)
end

local function ESPSetEnabled(State)
	UltraESPEnabled = State == true
	if UltraESPEnabled then
		local Target = ESPFindBestTarget(true)
		ESPCurrentTarget = Target
		CurrentBestTarget = Target
		ESPStartVisual()
	else
		ESPCurrentTarget = nil
		if not BestLineEnabled then ESPStopVisual() end
	end
	if SaveConfig then SaveConfig() end
end

-- O ESP não faz scans periódicos. Ele só cria/atualiza a linha e o nome do alvo já encontrado.
ESPWatchPlots()

SelectPage("ESP")
Section("ESP ULTRA")
Description("Procura a maior preferência DISPONÍVEL nos Plots 1-8.")
Description("O scan só acontece ao ativar/usar TP BEST ou quando o mapa muda.")
local ESPUltraButton = Button("  ESP ULTRA • " .. (UltraESPEnabled and "ON" or "OFF"))

ESPUltraButton.MouseButton1Click:Connect(function()
	ESPSetEnabled(not UltraESPEnabled)
	ESPUltraButton.Text = "  ESP ULTRA • " .. (UltraESPEnabled and "ON" or "OFF")
end)

-- ESPWatchPlots() already owns the Plot watchers; keep a single pair of
-- connections to avoid duplicate invalidations and repeated scans.

-- ==================== CONFIG / IDIOMA ====================
Language = LoadedConfig.Language or "pt-BR"
Languages = {
	["pt-BR"] = "Português (Brasil)",
	["pt-PT"] = "Português (Portugal)",
	["en-US"] = "English (USA)",
	["es-ES"] = "Español"
}
local LanguageOrder = {"pt-BR", "pt-PT", "en-US", "es-ES"}
if not table.find(LanguageOrder, Language) then Language = "pt-BR" end

Texts = {
	["pt-BR"] = {config="CONFIGURAÇÕES", language="IDIOMA", selected="IDIOMA ATUAL: ", best="MELHOR ENCONTRADO: ", noBest="NENHUM DISPONÍVEL"},
	["pt-PT"] = {config="CONFIGURAÇÕES", language="IDIOMA", selected="IDIOMA ATUAL: ", best="MELHOR ENCONTRADO: ", noBest="NENHUM DISPONÍVEL"},
	["en-US"] = {config="SETTINGS", language="LANGUAGE", selected="CURRENT LANGUAGE: ", best="BEST FOUND: ", noBest="NONE AVAILABLE"},
	["es-ES"] = {config="CONFIGURACIÓN", language="IDIOMA", selected="IDIOMA ACTUAL: ", best="MEJOR ENCONTRADO: ", noBest="NINGUNO DISPONIBLE"}
}

local function CurrentTexts() return Texts[Language] or Texts["pt-BR"] end

SelectPage("Config")
Section("CONFIG")
local LanguageLabel = Label("IDIOMA")
local LanguageButton = Button(Languages[Language] or Languages["pt-BR"])
local LanguageHint = Description("Português (Brasil) • Português (Portugal) • English (USA) • Español")

local function ApplyLanguage()
	LanguageLabel.Text = CurrentTexts().language
	LanguageButton.Text = Languages[Language] or Languages["pt-BR"]
	LanguageHint.Text = "pt-BR • pt-PT • en-US • es-ES"
	if TPBestButton and TPBestButton.Parent then TPBestButton.Text = "TP BEST" end
	SaveConfig()
end

LanguageButton.MouseButton1Click:Connect(function()
	local Index = table.find(LanguageOrder, Language) or 1
	Index = Index % #LanguageOrder + 1
	Language = LanguageOrder[Index]
	ApplyLanguage()
end)

ApplyLanguage()

-- Restaura os estados salvos depois que todos os controles já existem.
WalkBox.Text = tostring(WalkValue)
JumpBox.Text = tostring(JumpValue)
TravelBox.Text = tostring(TravelValue)
TPBox.Text = tostring(TPValue)
SpeedButton.Text = "  WALK SPEED • " .. (WalkEnabled and "ON" or "OFF")
JumpButton.Text = "  JUMP POWER • " .. (JumpEnabled and "ON" or "OFF")
NoclipButton.Text = "  NOCLIP • " .. (NoclipEnabled and "ON" or "OFF")
AntiRagdollButton.Text = "  ANTI-RAGDOLL • " .. (AntiRagdollEnabled and "ON" or "OFF")
PromptButton.Text = "  INSTANT PROMPT • " .. (InstantPromptEnabled and "ON" or "OFF")
FPSButton.Text = "  FPS BOOST • " .. (FPSBoostEnabled and "ON" or "OFF")
AutoStealButton.Text = "  AUTO STEAL • " .. (AutoStealEnabled and "ON" or "OFF")
InfiniteButton.Text = "  INFINITY JUMP • " .. (InfiniteJumpEnabled and "ON" or "OFF")
SpamTPV1Button.Text = "  SPAM TP V1 • " .. (SpamTPV1Enabled and "ON" or "OFF")
SpamTPV2Button.Text = "  SPAM TP V2 • " .. (SpamTPV2Enabled and "ON" or "OFF")
SpamTPV1ButtonSmall.Text = "SPAM TP V1 • " .. (SpamTPV1Enabled and "ON" or "OFF")
SpamTPV2ButtonSmall.Text = "SPAM TP V2 • " .. (SpamTPV2Enabled and "ON" or "OFF")

if AutoStealEnabled then StartAutoSteal() end
if SpamTPV1Enabled then StartSpamTPV1() end
if SpamTPV2Enabled then StartSpamTPV2() end
if UltraESPEnabled then ESPSetEnabled(true) end
if BestLineEnabled then CurrentBestTarget = ESPFindBestTarget() end
if InfiniteJumpEnabled then StartInfiniteJump() end
if InstantPromptEnabled then UpdatePrompts() end
if LoadedFPSBoostEnabled then
	ApplyFPSBoost()
end
SaveConfig()

task.spawn(function()
	while Gui and Gui.Parent do
		task.wait(5)
		pcall(SaveConfig)
	end
end)

print("SnooHubV18 carregado corretamente.")
