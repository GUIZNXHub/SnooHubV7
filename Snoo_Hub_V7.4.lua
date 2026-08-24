--========================================================
-- SNOO HUB 7.4
-- LocalScript - StarterPlayerScripts
--========================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--========================================================
-- DROP / NO-JUMP (integrado de 35_Drop_logic_no_jump)
--========================================================
local dropEnabled = false
local _dropConns = {}

local function ToggleSnooDrop(state)
    dropEnabled = state == true
    if dropEnabled then
        for _, c in ipairs(_dropConns) do
            if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
        end
        table.clear(_dropConns)

        local colConn = RunService.Stepped:Connect(function()
            if not dropEnabled then return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and p.Character then
                    for _, part in ipairs(p.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
        table.insert(_dropConns, colConn)

        task.spawn(function()
            while dropEnabled do
                RunService.Heartbeat:Wait()
                local c = Player.Character
                local root = c and c:FindFirstChild("HumanoidRootPart")
                if not root then continue end

                local vel = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)
                RunService.RenderStepped:Wait()
                if root and root.Parent then root.AssemblyLinearVelocity = vel end
                RunService.Stepped:Wait()
                if root and root.Parent then root.AssemblyLinearVelocity = vel + Vector3.new(0, 0.1, 0) end
            end
        end)
    else
        for _, c in ipairs(_dropConns) do
            if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
        end
        table.clear(_dropConns)
    end
end


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
local AntiRagdollEnabled = false
local InfiniteJumpEnabled = false
local InstantPromptEnabled = false
local PromptTeleportEnabled = false
local FPSBoostEnabled = false

local WalkValue = 110
local JumpValue = 100
local TravelValue = 110
local TPValue = 20

local OriginalWalkSpeed = nil
local OriginalJumpPower = nil

local SavedPosition = nil


local UndergroundTravelEnabled = true
local UndergroundDepth = 35

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

local ConfigFileName = "SnooHub_Config_V7.4.json"
local LoadedConfig = {}

pcall(function()
	if isfile and readfile and isfile(ConfigFileName) then
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
PromptTeleportEnabled = LoadedConfig.PromptTeleportEnabled == true
FPSBoostEnabled = LoadedConfig.FPSBoostEnabled == true
dropEnabled = LoadedConfig.SnooDropEnabled == true
local UndergroundEnabled = LoadedConfig.UndergroundEnabled ~= false

UndergroundDepth = 25

local function SetupCharacter(CharacterObject)
	Character = CharacterObject
	Humanoid = Character:WaitForChild("Humanoid")
	Root = Character:WaitForChild("HumanoidRootPart")

	if WalkEnabled then
		Humanoid.WalkSpeed = WalkValue
	end

	if JumpEnabled then
		Humanoid.UseJumpPower = true
		Humanoid.JumpPower = JumpValue
	end
end

if Player.Character then
	SetupCharacter(Player.Character)
end

Player.CharacterAdded:Connect(SetupCharacter)

local Existing = PlayerGui:FindFirstChild("SnooHub")
if Existing then
	Existing:Destroy()
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "SnooHub"
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
Subtitle.Text = "EPIC BRAINROT 2.0 • V7.3"
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
	Button.Size = UDim2.fromOffset(108, 30)
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
CreateTab("Movement", "MOVEMENT")
CreateTab("Utility", "UTILITY")
CreateTab("Jump", "JUMP")
SelectPage("Movement")
for _, TabName in ipairs({"Movement", "Utility", "Jump"}) do
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

local AutoStealEnabled = LoadedConfig.AutoStealEnabled == true
local AutoStealConnection = nil
local StealBarGui = nil
local StealBarFill = nil
local StealPercentLabel = nil
local StealStateLabel = nil
local StealStartTime = nil
local StealDuration = ApplyLoadedNumber("StealDuration", 0.01, 0.01, 10)
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
		-- Modo rápido: mantém o hold mínimo e dispara o Trigger assim que o
		-- intervalo configurado termina. Não há espera artificial de 0.1 s.
		while IsStealing and tick() - StealStartTime < StealDuration do
			local Progress = math.clamp((tick() - StealStartTime) / math.max(StealDuration, 0.001), 0, 1)
			if StealBarFill then StealBarFill.Size = UDim2.new(Progress, 0, 1, 0) end
			if StealPercentLabel then StealPercentLabel.Text = math.floor(Progress * 100) .. "%" end
			if StealStateLabel then StealStateLabel.Text = "STEALING" end
			RunService.Heartbeat:Wait()
		end
		for _, Callback in ipairs(Data.Trigger) do task.spawn(Callback) end
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
	AutoStealConnection = RunService.Heartbeat:Connect(function()
		if not AutoStealEnabled then return end
		if not IsStealing then
			local Prompt = FindNearestStealPrompt()
			if Prompt then ExecuteAutoSteal(Prompt) end
		end
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
local TravelButton = Button("  IR PELO TRAJETO")
local UndergroundButton = Button("  UNDERGROUND (UG) • OFF")
local UndergroundControlButton = UndergroundButton

Label("TP SPEED • STUDS/SEGUNDO")
local TPBox = TextBox("20", "TP SPEED (studs/segundo)")
local TPButton = Button("  TP POR PASSOS • IR")

SelectPage("Utility")
Section("OUTROS")
local NoclipButton = Button("  NOCLIP • OFF")
local AntiRagdollButton = Button("  ANTI-RAGDOLL • OFF")
local FPSButton = Button("  FPS BOOST • OFF")
local DropButton = Button("  DROP • OFF")

Section("PROXIMITY PROMPT")
local PromptButton = Button("  INSTANT PROMPT • OFF")
local PromptTeleportButton = Button("  PROMPT → LOCAL SALVO • OFF")
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

local function StabilizeAtTarget(TargetCFrame)
	if not Root or not Root.Parent or not IsValidCFrame(TargetCFrame) then return end
	-- Pequena janela ancorada evita que a física conserve a velocidade do trajeto
	-- e lance o personagem ao infinito ao chegar.
	local WasAnchored = Root.Anchored
	Root.Anchored = true
	Root.CFrame = TargetCFrame
	Root.AssemblyLinearVelocity = Vector3.zero
	Root.AssemblyAngularVelocity = Vector3.zero
	RunService.Heartbeat:Wait()
	if Root and Root.Parent then
		Root.CFrame = TargetCFrame
		Root.AssemblyLinearVelocity = Vector3.zero
		Root.AssemblyAngularVelocity = Vector3.zero
	end
	Root.Anchored = WasAnchored
	Root.AssemblyLinearVelocity = Vector3.zero
	Root.AssemblyAngularVelocity = Vector3.zero
end

local function StartTravel(ForceUnderground)
    if Traveling then
        CancelTravel = true
        TravelButton.Text = "IR PELO TRAJETO"
        return
    end

    local TargetCFrame = GetSafeSavedCFrame()
    if not TargetCFrame or not Root or not Humanoid then
        TravelButton.Text = "SALVE UMA LOCALIZAÇÃO"
        task.delay(1.5, function()
            if TravelButton.Parent then
                TravelButton.Text = "IR PELO TRAJETO"
            end
        end)
        return
    end

    local Speed = tonumber(TravelBox.Text) or TravelValue
    Speed = math.clamp(Speed, 1, 1000)
    TravelValue = Speed

    Traveling = true
    CancelTravel = false
    TravelButton.Text = "CANCELAR TRAJETO"

    local Destination = TargetCFrame.Position
    local StartPosition = Root.Position

    -- Underground: exatamente 25 studs abaixo do ponto de partida,
    -- depois cruza por baixo até o destino e sobe 10 studs acima.
    local UndergroundY = StartPosition.Y - 25

    local oldAutoRotate = Humanoid.AutoRotate
    local oldPlatformStand = Humanoid.PlatformStand
    Humanoid.AutoRotate = false
    Humanoid.PlatformStand = true

    local function MoveCFrame(TargetPosition)
        while Traveling and not CancelTravel and Root and Root.Parent do
            local Current = Root.Position
            local Offset = TargetPosition - Current
            local Distance = Offset.Magnitude

            if Distance <= 1 then
                Root.CFrame = CFrame.new(TargetPosition)
                Root.AssemblyLinearVelocity = Vector3.zero
                Root.AssemblyAngularVelocity = Vector3.zero
                return true
            end

            local dt = RunService.Heartbeat:Wait()
            local Step = math.min(Distance, Speed * dt)
            local Next = Current + Offset.Unit * Step

            Root.CFrame = CFrame.lookAt(Next, TargetPosition)
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
        end
        return false
    end

    local UseUnderground = (ForceUnderground == nil) and UndergroundEnabled or ForceUnderground

    if UseUnderground then
        -- 1. Desce 25 studs.
        local Down = Vector3.new(StartPosition.X, UndergroundY, StartPosition.Z)

        -- 2. Vai por baixo até ficar alinhado com o destino.
        local Across = Vector3.new(Destination.X, UndergroundY, Destination.Z)

        -- 3. Sobe exatamente até a altura salva (sem impulso no final).
        local Release = Vector3.new(Destination.X, Destination.Y, Destination.Z)

        if MoveCFrame(Down) and MoveCFrame(Across) then
            MoveCFrame(Release)
        end

        if Traveling and not CancelTravel and Root and Root.Parent then
            StabilizeAtTarget(TargetCFrame)
        end
    else
        if MoveCFrame(Destination) and Traveling and not CancelTravel then
            StabilizeAtTarget(TargetCFrame)
        end
    end

    -- Restaura o estado do Humanoid somente depois de a posição estar estável.
    if Root and Root.Parent then
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
    end
    Humanoid.PlatformStand = oldPlatformStand
    if Root and Root.Parent then
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
    end
    Humanoid.AutoRotate = oldAutoRotate
    Traveling = false
    CancelTravel = false
    TravelButton.Text = "IR PELO TRAJETO"
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


-- ==================== FPS BOOST ====================
local FPSOriginals = {}
local FPSOriginalLighting = nil
local FPSOriginalQuality = nil

local function ApplyFPSBoost()
	if FPSBoostEnabled then return end
	FPSBoostEnabled = true

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

DropButton.MouseButton1Click:Connect(function()
    ToggleSnooDrop(not dropEnabled)
    DropButton.Text = "  DROP • " .. (dropEnabled and "ON" or "OFF")
    if SaveConfig then SaveConfig() end
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

local function UpdatePrompts()
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


PromptTeleportButton.MouseButton1Click:Connect(function()
    PromptTeleportEnabled = not PromptTeleportEnabled
    PromptTeleportButton.Text = "  PROMPT → LOCAL SALVO • " .. (PromptTeleportEnabled and "ON" or "OFF")
    if SaveConfig then SaveConfig() end
end)

workspace.DescendantAdded:Connect(function(Object)
    if not Object:IsA("ProximityPrompt") then return end
    Object.Triggered:Connect(function()
        if not PromptTeleportEnabled then return end
        local Target = GetSafeSavedCFrame()
        if not Target or not Root then return end

        -- Teleporta para o local salvo da página principal.
        pcall(function()
            Root.CFrame = Target
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
        end)
    end)
end)

for _, Object in ipairs(workspace:GetDescendants()) do
    if Object:IsA("ProximityPrompt") then
        Object.Triggered:Connect(function()
            if not PromptTeleportEnabled then return end
            local Target = GetSafeSavedCFrame()
            if not Target or not Root then return end
            pcall(function()
                Root.CFrame = Target
                Root.AssemblyLinearVelocity = Vector3.zero
                Root.AssemblyAngularVelocity = Vector3.zero
            end)
        end)
    end
end

PromptButton.MouseButton1Click:Connect(function()
	InstantPromptEnabled = not InstantPromptEnabled

	UpdatePrompts()

	PromptButton.Text =
		"  INSTANT PROMPT • " ..
		(InstantPromptEnabled and "ON" or "OFF")
end)

workspace.DescendantAdded:Connect(function(Object)
	if Object:IsA("ProximityPrompt") then
		task.defer(function()
			if InstantPromptEnabled then
				ConfigurePrompt(Object)
			end
		end)
	end
end)

task.spawn(function()
	while Gui.Parent do
		task.wait(3)

		if InstantPromptEnabled then
			UpdatePrompts()
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

local InfiniteJumpConnection
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

RunService.Stepped:Connect(function()
	if not Character or not Humanoid or not Root then
		return
	end

	if WalkEnabled
		and not Traveling
		and not StepTeleporting then

		Humanoid.WalkSpeed = WalkValue
	end

	if JumpEnabled then
		Humanoid.UseJumpPower = true
		Humanoid.JumpPower = JumpValue
	end

	if NoclipEnabled then
		for _, Object in ipairs(Character:GetDescendants()) do
			if Object:IsA("BasePart") then
				Object.CanCollide = false
			end
		end
	end

	if AntiRagdollEnabled then
			local State = Humanoid:GetState()
			local Ragdolled = State == Enum.HumanoidStateType.Ragdoll
				or State == Enum.HumanoidStateType.FallingDown
				or State == Enum.HumanoidStateType.Physics

			if Ragdolled then
				local Now = tick()
				if Now - ResetCooldown > 0.15 then
					ResetCooldown = Now
					ForceAntiRagdollReset()
				end
			end
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

-- ==================== FLOATING TP PANEL ====================
local FloatingTPGui = Instance.new("ScreenGui")
FloatingTPGui.Name = "SnooFloatingTP"
FloatingTPGui.ResetOnSpawn = false
FloatingTPGui.IgnoreGuiInset = true
FloatingTPGui.DisplayOrder = 30
FloatingTPGui.Parent = PlayerGui

local FloatingTP = Instance.new("Frame")
FloatingTP.Name = "FloatingTP"
FloatingTP.Size = UDim2.fromOffset(190, 184)
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
SaveTPButton.Size = UDim2.fromOffset(84, 28)
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
TPButtonSmall.Size = UDim2.fromOffset(84, 28)
TPButtonSmall.Position = UDim2.fromOffset(100, 24)
TPButtonSmall.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
TPButtonSmall.BorderSizePixel = 0
TPButtonSmall.Text = "TP"
TPButtonSmall.TextColor3 = Color3.fromRGB(245, 245, 245)
TPButtonSmall.TextSize = 9
TPButtonSmall.Font = Enum.Font.GothamBold
TPButtonSmall.AutoButtonColor = false
TPButtonSmall.Parent = FloatingTP

local TravelButtonSmall = Instance.new("TextButton")
TravelButtonSmall.Size = UDim2.fromOffset(178, 28)
TravelButtonSmall.Position = UDim2.fromOffset(6, 58)
TravelButtonSmall.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
TravelButtonSmall.BorderSizePixel = 0
TravelButtonSmall.Text = "TRAJETO NORMAL"
TravelButtonSmall.TextColor3 = Color3.fromRGB(245, 245, 245)
TravelButtonSmall.TextSize = 8
TravelButtonSmall.Font = Enum.Font.GothamBold
TravelButtonSmall.AutoButtonColor = false
TravelButtonSmall.Parent = FloatingTP

local UndergroundSmallButton = Instance.new("TextButton")
UndergroundSmallButton.Size = UDim2.fromOffset(178, 28)
UndergroundSmallButton.Position = UDim2.fromOffset(6, 92)
UndergroundSmallButton.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
UndergroundSmallButton.BorderSizePixel = 0
UndergroundSmallButton.Text = "TRAJETO UNDERGROUND"
UndergroundSmallButton.TextColor3 = Color3.fromRGB(245, 245, 245)
UndergroundSmallButton.TextSize = 8
UndergroundSmallButton.Font = Enum.Font.GothamBold
UndergroundSmallButton.AutoButtonColor = false
UndergroundSmallButton.Parent = FloatingTP

local UndergroundModeButton = Instance.new("TextButton")
UndergroundModeButton.Size = UDim2.fromOffset(178, 28)
UndergroundModeButton.Position = UDim2.fromOffset(6, 126)
UndergroundModeButton.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
UndergroundModeButton.BorderSizePixel = 0
UndergroundModeButton.Text = "UG MODE: " .. (UndergroundEnabled and "ON" or "OFF")
UndergroundModeButton.TextColor3 = Color3.fromRGB(245, 245, 245)
UndergroundModeButton.TextSize = 8
UndergroundModeButton.Font = Enum.Font.GothamBold
UndergroundModeButton.AutoButtonColor = false
UndergroundModeButton.Parent = FloatingTP

for _, ButtonObject in ipairs({SaveTPButton, TPButtonSmall, TravelButtonSmall, UndergroundSmallButton, UndergroundModeButton}) do
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

-- Cada botão do TP CONTROL pode ser movido individualmente.
local function MakeFloatingButtonDraggable(ButtonObject, PositionKey)
    local dragging = false
    local moved = false
    local dragStart
    local startPos

    ButtonObject.Active = true
    ButtonObject.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = Input.Position
            startPos = ButtonObject.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(Input)
        if not dragging then return end
        if Input.UserInputType == Enum.UserInputType.MouseMovement
            or Input.UserInputType == Enum.UserInputType.Touch then
            local Delta = Input.Position - dragStart
            if Delta.Magnitude > 4 then moved = true end
            ButtonObject.Position = UDim2.fromOffset(
                startPos.X.Offset + Delta.X,
                startPos.Y.Offset + Delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                if moved then ButtonObject:SetAttribute("SnooDragged", true) end
                if PositionKey then
                    FloatingButtonPositions[PositionKey] = ButtonObject.Position
                end
                if SaveConfig then SaveConfig() end
            end
        end
    end)
end

for _, Item in ipairs({
    {SaveTPButton, "TP_Save"}, {TPButtonSmall, "TP_Teleport"},
    {TravelButtonSmall, "TP_Normal"}, {UndergroundSmallButton, "TP_Underground"},
    {UndergroundModeButton, "TP_UGMode"}
}) do
    MakeFloatingButtonDraggable(Item[1], Item[2])
end

local FloatingSavedPosition = nil
local SaveConfig

if type(LoadedConfig.SavedTP) == "table" and #LoadedConfig.SavedTP == 12 then
	FloatingSavedPosition = CFrame.new(table.unpack(LoadedConfig.SavedTP))
	SavedPosition = FloatingSavedPosition
end
local function RestoreFloatingPosition(ButtonObject, Key, Default)
    local P = LoadedConfig.FloatingButtonPositions and LoadedConfig.FloatingButtonPositions[Key]
    if type(P) == "table" and type(P.X) == "number" and type(P.Y) == "number" then
        ButtonObject.Position = UDim2.fromOffset(P.X, P.Y)
    elseif Default then
        ButtonObject.Position = Default
    end
end
RestoreFloatingPosition(SaveTPButton, "TP_Save", UDim2.fromOffset(6,24))
RestoreFloatingPosition(TPButtonSmall, "TP_Teleport", UDim2.fromOffset(100,24))
RestoreFloatingPosition(TravelButtonSmall, "TP_Normal", UDim2.fromOffset(6,58))
RestoreFloatingPosition(UndergroundSmallButton, "TP_Underground", UDim2.fromOffset(6,92))
RestoreFloatingPosition(UndergroundModeButton, "TP_UGMode", UDim2.fromOffset(6,126))


SaveConfig = function()
	if not writefile then return end
	local Data = {
        Version = "7.4",
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
PromptTeleportEnabled = PromptTeleportEnabled,
UndergroundEnabled = UndergroundEnabled,
SnooDropEnabled = dropEnabled,
FloatingButtonsEnabled = FloatingButtonsEnabled,
UndergroundTravelEnabled = UndergroundTravelEnabled,
UndergroundDepth = UndergroundDepth,
		FPSBoostEnabled = FPSBoostEnabled,
		AutoStealEnabled = AutoStealEnabled,
		SavedTP = (function()
			if not FloatingSavedPosition then return nil end
			return {FloatingSavedPosition:GetComponents()}
		end)(),
		FloatingXScale = 0,
		FloatingXOffset = FloatingTP.Position.X.Offset,
		FloatingYScale = 0,
		FloatingYOffset = FloatingTP.Position.Y.Offset,
        FloatingButtonPositions = (function()
            local Out = {}
            for Key, Pos in pairs(FloatingButtonPositions) do
                if typeof(Pos) == "UDim2" then
                    Out[Key] = {X = Pos.X.Offset, Y = Pos.Y.Offset}
                end
            end
            return Out
        end)(),
	}
	pcall(function() writefile(ConfigFileName, HttpService:JSONEncode(Data)) end)
end

SaveTPButton.MouseButton1Click:Connect(function()
	if SaveTPButton:GetAttribute("SnooDragged") then
		SaveTPButton:SetAttribute("SnooDragged", false)
		return
	end
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

TPButtonSmall.MouseButton1Click:Connect(function()
	if TPButtonSmall:GetAttribute("SnooDragged") then
		TPButtonSmall:SetAttribute("SnooDragged", false)
		return
	end
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

TravelButtonSmall.MouseButton1Click:Connect(function()
	if TravelButtonSmall:GetAttribute("SnooDragged") then
		TravelButtonSmall:SetAttribute("SnooDragged", false)
		return
	end
	if Traveling then
		CancelTravel = true
		TravelButtonSmall.Text = "CANCELANDO..."
		return
	end

	if not (FloatingSavedPosition or SavedPosition) then
		TravelButtonSmall.Text = "SEM LOCAL"
		task.delay(1.2, function()
			if TravelButtonSmall.Parent then
				TravelButtonSmall.Text = "TRAJETO NORMAL"
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


UndergroundSmallButton.MouseButton1Click:Connect(function()
	if UndergroundSmallButton:GetAttribute("SnooDragged") then
		UndergroundSmallButton:SetAttribute("SnooDragged", false)
		return
	end
    if Traveling then CancelTravel = true return end
    if not (FloatingSavedPosition or SavedPosition) then
        UndergroundSmallButton.Text = "SEM LOCAL"
        task.delay(1, function()
            if UndergroundSmallButton.Parent then UndergroundSmallButton.Text = "TRAJETO UNDERGROUND" end
        end)
        return
    end
    if FloatingSavedPosition then SavedPosition = FloatingSavedPosition end
    UndergroundSmallButton.Text = "UG TRAJETO..."
    task.spawn(function()
        StartTravel(true)
        if UndergroundSmallButton.Parent then UndergroundSmallButton.Text = "TRAJETO UNDERGROUND" end
    end)
end)

UndergroundModeButton.MouseButton1Click:Connect(function()
	if UndergroundModeButton:GetAttribute("SnooDragged") then
		UndergroundModeButton:SetAttribute("SnooDragged", false)
		return
	end
    UndergroundEnabled = not UndergroundEnabled
    UndergroundModeButton.Text = "UG MODE: " .. (UndergroundEnabled and "ON" or "OFF")
    if UndergroundButton then
        UndergroundButton.Text = "  UNDERGROUND (UG) • " .. (UndergroundEnabled and "ON" or "OFF")
    end
    if SaveConfig then SaveConfig() end
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

local function ApplyRoundedBorders(RootGui)
    local function Apply(Object)
        if Object:IsA("Frame") or Object:IsA("ScrollingFrame")
            or Object:IsA("TextButton") or Object:IsA("TextBox")
            or Object:IsA("ImageButton") then
            local Corner = Object:FindFirstChildOfClass("UICorner")
            if not Corner then
                Corner = Instance.new("UICorner")
                Corner.Parent = Object
            end
            Corner.CornerRadius = UDim.new(0, 9)

            if Object:IsA("Frame") or Object:IsA("ScrollingFrame") then
                local Stroke = Object:FindFirstChildOfClass("UIStroke")
                if not Stroke then
                    Stroke = Instance.new("UIStroke")
                    Stroke.Thickness = 1
                    Stroke.Transparency = 0.25
                    Stroke.Parent = Object
                end
            end
        end
    end

    for _, Object in ipairs(RootGui:GetDescendants()) do
        Apply(Object)
    end

    RootGui.DescendantAdded:Connect(function(Object)
        task.defer(function()
            if Object.Parent then Apply(Object) end
        end)
    end)
end

ApplyRoundedBorders(Gui)

-- ==================== JSON CONFIG • SNOO HUB V7.3 ====================
local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "Snoo_Hub_Config_V7.4.json"

local function CanUseFileAPI()
    return type(writefile) == "function" and type(isfile) == "function"
        and type(readfile) == "function"
end

local function BuildJSONConfig()
    return {
        Version = "7.4",
        WalkEnabled = WalkEnabled,
        WalkValue = WalkValue,
        JumpEnabled = JumpEnabled,
        JumpValue = JumpValue,
        NoclipEnabled = NoclipEnabled,
        AntiRagdollEnabled = AntiRagdollEnabled,
        InfiniteJumpEnabled = InfiniteJumpEnabled,
        PromptTeleportEnabled = PromptTeleportEnabled,
        InstantPromptEnabled = InstantPromptEnabled,
        UndergroundEnabled = UndergroundEnabled,
        SnooDropEnabled = dropEnabled,
        AutoStealEnabled = AutoStealEnabled,
        TravelValue = TravelValue,
        FloatingButtonsEnabled = FloatingButtonsEnabled,
        FloatingButtonPositions = (function()
            local Out = {}
            for Key, Pos in pairs(FloatingButtonPositions) do
                if typeof(Pos) == "UDim2" then
                    Out[Key] = {X = Pos.X.Offset, Y = Pos.Y.Offset}
                end
            end
            return Out
        end)()
    }
end

local function SaveJSONConfig()
    if not CanUseFileAPI() then return false end
    local ok, data = pcall(function()
        return HttpService:JSONEncode(BuildJSONConfig())
    end)
    if not ok then return false end
    return pcall(function() writefile(CONFIG_FILE, data) end)
end

local function LoadJSONConfig()
    if not CanUseFileAPI() or not isfile(CONFIG_FILE) then return false end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if not ok or type(data) ~= "table" then return false end
    LoadedConfig = data
    return true
end

pcall(LoadJSONConfig)

-- ==================== BUTTONS / BOTÕES NA TELA ====================
local FloatingButtons = {}
local FloatingButtonPositions = {}
local FloatingButtonsEnabled = {}
if type(LoadedConfig.FloatingButtonPositions) == "table" then
    for Key, Pos in pairs(LoadedConfig.FloatingButtonPositions) do
        if type(Pos) == "table" and type(Pos.X) == "number" and type(Pos.Y) == "number" then
            FloatingButtonPositions[Key] = UDim2.fromOffset(Pos.X, Pos.Y)
        end
    end
end

local ButtonsPage = CreatePage("Buttons")
CreateTab("Buttons", "BUTTONS")

local ButtonDefinitions = {
    {"InstantPrompt", "INSTANT PROMPT", function() return InstantPromptEnabled end,
        function(v) InstantPromptEnabled = v; PromptButton.Text = "  INSTANT PROMPT • " .. (v and "ON" or "OFF"); if v then UpdatePrompts() end end},
    {"PromptTP", "PROMPT → LOCAL", function() return PromptTeleportEnabled end,
        function(v) PromptTeleportEnabled = v; PromptTeleportButton.Text = "  PROMPT → LOCAL SALVO • " .. (v and "ON" or "OFF") end},
    {"Underground", "UNDERGROUND (UG)", function() return UndergroundEnabled end,
        function(v) UndergroundEnabled = v; UndergroundButton.Text = "  UNDERGROUND (UG) • " .. (v and "ON" or "OFF") end},
    {"Drop", "DROP", function() return dropEnabled end,
        function(v) dropEnabled = v; ToggleSnooDrop(v) end},
    {"Speed", "WALK SPEED", function() return WalkEnabled end,
        function(v)
            WalkEnabled = v
            if Humanoid then
                if v then
                    local n = tonumber(WalkBox.Text)
                    if n then WalkValue = math.clamp(n, 1, 500) end
                    OriginalWalkSpeed = OriginalWalkSpeed or Humanoid.WalkSpeed
                    Humanoid.WalkSpeed = WalkValue
                elseif OriginalWalkSpeed ~= nil then
                    Humanoid.WalkSpeed = OriginalWalkSpeed
                end
            end
            SpeedButton.Text = "  WALK SPEED • " .. (v and "ON" or "OFF")
        end},
    {"Jump", "JUMP POWER", function() return JumpEnabled end,
        function(v)
            JumpEnabled = v
            if Humanoid then
                if v then
                    local n = tonumber(JumpBox.Text)
                    if n then JumpValue = math.clamp(n, 1, 500) end
                    OriginalJumpPower = OriginalJumpPower or Humanoid.JumpPower
                    Humanoid.UseJumpPower = true
                    Humanoid.JumpPower = JumpValue
                elseif OriginalJumpPower ~= nil then
                    Humanoid.UseJumpPower = true
                    Humanoid.JumpPower = OriginalJumpPower
                end
            end
            JumpButton.Text = "  JUMP POWER • " .. (v and "ON" or "OFF")
        end},
    {"Noclip", "NOCLIP", function() return NoclipEnabled end,
        function(v) NoclipEnabled = v; NoclipButton.Text = "  NOCLIP • " .. (v and "ON" or "OFF") end},
    {"AntiRagdoll", "ANTI-RAGDOLL", function() return AntiRagdollEnabled end,
        function(v) AntiRagdollEnabled = v; AntiRagdollButton.Text = "  ANTI-RAGDOLL • " .. (v and "ON" or "OFF") end},
    {"InfinityJump", "INFINITY JUMP", function() return InfiniteJumpEnabled end,
        function(v)
            InfiniteJumpEnabled = v
            if v then StartInfiniteJump() else StopInfiniteJump() end
            InfiniteButton.Text = "  INFINITY JUMP • " .. (v and "ON" or "OFF")
        end},
    {"AutoSteal", "AUTO STEAL", function() return AutoStealEnabled end,
        function(v)
            AutoStealEnabled = v
            if v then StartAutoSteal() else StopAutoSteal() end
            AutoStealButton.Text = "  AUTO STEAL • " .. (v and "ON" or "OFF")
        end},
    {"TravelNormal", "TRAJETO NORMAL", function() return Traveling and not UndergroundEnabled end,
        function(v)
            if v then
                if FloatingSavedPosition then SavedPosition = FloatingSavedPosition end
                task.spawn(function() StartTravel(false) end)
            end
        end},
    {"TravelUnderground", "TRAJETO UNDERGROUND", function() return Traveling and UndergroundEnabled end,
        function(v)
            if v then
                if FloatingSavedPosition then SavedPosition = FloatingSavedPosition end
                task.spawn(function() StartTravel(true) end)
            end
        end},
}

local function CreateFloatingFeatureButton(Key, Name, GetState, SetState, DefaultY)
    if FloatingButtons[Key] then
        FloatingButtons[Key].Visible = true
        return FloatingButtons[Key]
    end

    local B = Instance.new("TextButton")
    B.Name = "Button_" .. Key
    B.Parent = Gui
    B.Size = UDim2.fromOffset(100, 30)
    B.Position = FloatingButtonPositions[Key] or UDim2.fromOffset(10, DefaultY)
    B.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    B.TextColor3 = Color3.fromRGB(255, 255, 255)
    B.Font = Enum.Font.GothamBold
    B.TextSize = 10
    B.Text = Name .. " • " .. (GetState() and "ON" or "OFF")
    B.AutoButtonColor = true
    B.ZIndex = 100

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 9)
    Corner.Parent = B

    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 1
    Stroke.Transparency = 0.15
    Stroke.Parent = B

    local dragging = false
    local dragStart
    local startPos

    B.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = Input.Position
            startPos = B.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(Input)
        if not dragging then return end
        if Input.UserInputType == Enum.UserInputType.MouseMovement
            or Input.UserInputType == Enum.UserInputType.Touch then
            local Delta = Input.Position - dragStart
            B.Position = UDim2.fromOffset(
                startPos.X.Offset + Delta.X,
                startPos.Y.Offset + Delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local Delta = Input.Position - dragStart
                if Delta.Magnitude > 4 then
                    B:SetAttribute("SnooDragged", true)
                end
            end
            dragging = false
            FloatingButtonPositions[Key] = B.Position
            if SaveConfig then SaveConfig() end
        end
    end)

    B.MouseButton1Click:Connect(function()
        if B:GetAttribute("SnooDragged") then
            B:SetAttribute("SnooDragged", false)
            return
        end
        SetState(not GetState())
        B.Text = Name .. " • " .. (GetState() and "ON" or "OFF")
        if SaveConfig then SaveConfig() end
    end)

    FloatingButtons[Key] = B
    return B
end

-- DROP dedicado: fica disponível na tela e também pode ser controlado pela aba BUTTONS.
local DropFloating = CreateFloatingFeatureButton("DropAlways", "DROP", function()
    return dropEnabled
end, function(v)
    ToggleSnooDrop(v)
    DropButton.Text = "  DROP • " .. (v and "ON" or "OFF")
end, 360)
DropFloating.Visible = true

local function RefreshFloatingButtons()
    for _, Def in ipairs(ButtonDefinitions) do
        local Key, Name, GetState, SetState = table.unpack(Def)
        if FloatingButtons[Key] then
            FloatingButtons[Key].Visible = FloatingButtonsEnabled[Key] == true
            FloatingButtons[Key].Text = Name .. " • " .. (GetState() and "ON" or "OFF")
        end
    end
end

SelectPage("Buttons")
Section("BOTÕES NA TELA")
Label("Todas as opções podem ter um botão pequeno e arrastável na tela.")
Description("Use ADICIONAR/REMOVER para escolher quais aparecem. O botão da tela liga/desliga a função.")

for Index, Def in ipairs(ButtonDefinitions) do
    local Key, Name, GetState, SetState = table.unpack(Def)
    if type(LoadedConfig.FloatingButtonsEnabled) == "table" and LoadedConfig.FloatingButtonsEnabled[Key] ~= nil then
        FloatingButtonsEnabled[Key] = LoadedConfig.FloatingButtonsEnabled[Key] == true
    else
        FloatingButtonsEnabled[Key] = false
    end

    local AddRemove = Button("  " .. Name .. " • ADICIONAR")
    AddRemove.MouseButton1Click:Connect(function()
        FloatingButtonsEnabled[Key] = not FloatingButtonsEnabled[Key]

        if FloatingButtonsEnabled[Key] then
            CreateFloatingFeatureButton(Key, Name, GetState, SetState, 160 + ((Index - 1) % 8) * 34)
            AddRemove.Text = "  " .. Name .. " • REMOVER"
        else
            if FloatingButtons[Key] then
                FloatingButtons[Key].Visible = false
            end
            AddRemove.Text = "  " .. Name .. " • ADICIONAR"
        end

        if SaveConfig then SaveConfig() end
    end)
    AddRemove.Text = "  " .. Name .. " • " .. (FloatingButtonsEnabled[Key] and "REMOVER" or "ADICIONAR")
end

SelectPage("Movement")

task.defer(function()
    if FloatingButtonsEnabled then
        for Index, Def in ipairs(ButtonDefinitions) do
            local Key, Name, GetState, SetState = table.unpack(Def)
            if FloatingButtonsEnabled[Key] then
                CreateFloatingFeatureButton(Key, Name, GetState, SetState, 160 + ((Index - 1) % 8) * 34)
            end
        end
        RefreshFloatingButtons()
        if UndergroundSmallButton and UndergroundSmallButton.Parent then
            UndergroundSmallButton.Text = "UNDERGROUND • " .. (UndergroundEnabled and "ON" or "OFF")
        end
    end
end)

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
PromptTeleportButton.Text = "  PROMPT → LOCAL SALVO • " .. (PromptTeleportEnabled and "ON" or "OFF")
FPSButton.Text = "  FPS BOOST • " .. (FPSBoostEnabled and "ON" or "OFF")
DropButton.Text = "  DROP • " .. (dropEnabled and "ON" or "OFF")
AutoStealButton.Text = "  AUTO STEAL • " .. (AutoStealEnabled and "ON" or "OFF")
InfiniteButton.Text = "  INFINITY JUMP • " .. (InfiniteJumpEnabled and "ON" or "OFF")


if dropEnabled then ToggleSnooDrop(true) end
if AutoStealEnabled then StartAutoSteal() end
if InfiniteJumpEnabled then StartInfiniteJump() end
if InstantPromptEnabled then UpdatePrompts() end
if FPSBoostEnabled then
	FPSBoostEnabled = false
	ApplyFPSBoost()
end
RefreshFloatingButtons()
SaveConfig()

task.spawn(function()
	while Gui.Parent do
		task.wait(2)
		SaveConfig()
	end
end)

print("Snoo Hub carregado corretamente.")

task.spawn(function()
    while Gui and Gui.Parent do
        task.wait(5)
        pcall(SaveJSONConfig)
    end
end)

pcall(SaveJSONConfig)
