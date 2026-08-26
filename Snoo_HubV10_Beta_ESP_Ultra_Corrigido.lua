--========================================================
-- SNOO HUB 
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
local UI_FONT = Enum.Font.Gotham

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
local FPSBoostEnabled = false
local UltraESPEnabled = false

local WalkValue = 110
local JumpValue = 100
local TravelValue = 110
local TPValue = 20

local OriginalWalkSpeed = nil
local OriginalJumpPower = nil

local SavedPosition = nil
local SpamTPInterval = 0.12

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
FPSBoostEnabled = LoadedConfig.FPSBoostEnabled == true
UltraESPEnabled = LoadedConfig.UltraESPEnabled == true

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

local Existing = PlayerGui:FindFirstChild("SnooHubV10_Beta")
if Existing then
	Existing:Destroy()
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "SnooHubV10_Beta"
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
Title.Text = "SnooHubV10 Beta"
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
	Button.Size = UDim2.fromOffset(100, 30)
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
CreateTab("Movement", "MOVEMENT")
CreateTab("Utility", "UTILITY")
CreateTab("Jump", "JUMP")
CreateTab("Credits", "CREDITS")
CreateTab("ESP", "ESP")

SelectPage("Movement")
for _, TabName in ipairs({"Movement", "Utility", "Jump", "Credits", "ESP"}) do
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

-- ==================== ULTRA ESP ====================
-- ESP visual: NÃO teleporta, NÃO puxa e NÃO altera o Player.
-- Procura os Brainrots somente dentro dos slots/modelos numerados 1..8
-- de cada Plot e escolhe APENAS o Brainrot disponível de maior prioridade.

local UltraESPGui = Instance.new("ScreenGui")
UltraESPGui.Name = "SnooUltraESP"
UltraESPGui.ResetOnSpawn = false
UltraESPGui.IgnoreGuiInset = true
UltraESPGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UltraESPGui.DisplayOrder = 999999
UltraESPGui.Enabled = false
UltraESPGui.Parent = PlayerGui

local ESPObjects = {}
local ESPConnections = {}

local ESPPriority = {
    ["strawberry elephant"] = 1,
    ["headless horseman"] = 2,
    ["meowl"] = 2,
    ["john pork"] = 3,
    ["skibid toilet"] = 4,
    ["dragon gingerine"] = 5,
    ["hydra dragon canneloni"] = 6,
    ["dragon aquanini"] = 7,
    ["arcadragon"] = 8,
    ["signore carapace"] = 9,
    ["antonio"] = 10,
    ["la supreme combinasion"] = 11,
    ["love love bear"] = 12,
    ["elefanto frigo"] = 13,
    ["dug dug dug"] = 14,
    ["griffin"] = 15,
    ["garama and madundung"] = 16,
}

local ESPAliases = {
    ["dragon cannelloni"] = "hydra dragon canneloni",
    ["dragon canneloni"] = "hydra dragon canneloni",
    ["hydra dragon cannelloni"] = "hydra dragon canneloni",
}

local function ESPNormalize(Text)
    Text = string.lower(tostring(Text or ""))
    Text = Text:gsub("[%c]", "")
    Text = Text:gsub("[%p]", "")
    Text = Text:gsub("%s+", " ")
    return Text:match("^%s*(.-)%s*$") or ""
end

local function ESPGetPriority(Name)
    local N = ESPNormalize(Name)
    N = ESPAliases[N] or N
    return ESPPriority[N]
end

local function ESPFindBrainrotName(Object)
    local Candidates = {Object.Name}

    for _, Key in ipairs({
        "BrainrotName",
        "DisplayName",
        "Name",
        "Brainrot",
        "PetName",
        "AnimalName",
        "ModelName"
    }) do
        local Attribute = Object:GetAttribute(Key)
        if typeof(Attribute) == "string" and Attribute ~= "" then
            table.insert(Candidates, Attribute)
        end

        local Child = Object:FindFirstChild(Key, true)
        if Child then
            if Child:IsA("StringValue") then
                table.insert(Candidates, Child.Value)
            elseif Child:IsA("TextLabel") or Child:IsA("TextButton") then
                table.insert(Candidates, Child.Text)
            end
        end
    end

    for _, Candidate in ipairs(Candidates) do
        local Priority = ESPGetPriority(Candidate)
        if Priority then
            return Candidate, Priority
        end
    end

    return nil, nil
end

local function ESPGetRoot()
    return Character and Character:FindFirstChild("HumanoidRootPart") or Root
end

local function ESPGetPosition(Object)
    if not Object or not Object.Parent then return nil end

    if Object:IsA("BasePart") then
        return Object.Position
    end

    if Object:IsA("Model") then
        local Part = Object.PrimaryPart
            or Object:FindFirstChild("HumanoidRootPart", true)
            or Object:FindFirstChildWhichIsA("BasePart", true)

        if Part then
            return Part.Position
        end

        return Object:GetPivot().Position
    end

    local Part = Object:FindFirstChildWhichIsA("BasePart", true)
    return Part and Part.Position or nil
end

local function ESPFindPlotsRoot()
    return workspace:FindFirstChild("Plots")
end

local function ESPIsNumberSlot(Object)
    if not Object then return nil end
    local Number = tonumber(tostring(Object.Name):match("^%s*(%d+)%s*$"))
    if Number and Number >= 1 and Number <= 8 then
        return Number
    end
    return nil
end

local function ESPFindSlots(PlotsRoot)
    local Slots = {}
    local Seen = {}

    -- Cada slot pode estar em qualquer nível dentro de Plots/plot.
    -- Só números 1..8 entram na busca.
    for _, Object in ipairs(PlotsRoot:GetDescendants()) do
        local SlotNumber = ESPIsNumberSlot(Object)

        if SlotNumber and not Seen[Object] then
            Seen[Object] = true
            table.insert(Slots, {
                Object = Object,
                Number = SlotNumber
            })
        end
    end

    table.sort(Slots, function(A, B)
        return A.Number < B.Number
    end)

    return Slots
end

local function ESPFindBestInSlot(Slot)
    local Best = nil

    local function Check(Object)
        if not Object then return end

        if Object:IsA("Model") or Object:IsA("BasePart") then
            local Name, Priority = ESPFindBrainrotName(Object)

            if Name and Priority then
                local Position = ESPGetPosition(Object)

                if Position then
                    if not Best or Priority < Best.Priority then
                        Best = {
                            Object = Object,
                            Name = Name,
                            Priority = Priority,
                            Position = Position,
                            Slot = Slot.Number
                        }
                    end
                end
            end
        end
    end

    Check(Slot.Object)

    for _, Object in ipairs(Slot.Object:GetDescendants()) do
        Check(Object)
    end

    return Best
end

local function ESPFindBestAvailable()
    local PlotsRoot = ESPFindPlotsRoot()
    if not PlotsRoot then return nil end

    local Slots = ESPFindSlots(PlotsRoot)
    local Best = nil

    -- IMPORTANTE:
    -- A posição do slot (1..8) NÃO interfere na preferência.
    -- Primeiro verifica quais Brainrots realmente existem;
    -- depois escolhe o menor número de prioridade.
    for _, Slot in ipairs(Slots) do
        local Target = ESPFindBestInSlot(Slot)

        if Target then
            if not Best or Target.Priority < Best.Priority then
                Best = Target
            end
        end
    end

    return Best
end

local function ESPMakeLine()
    local Line = Instance.new("Frame")
    Line.Name = "SnooESP_Line"
    Line.AnchorPoint = Vector2.new(0, 0.5)
    Line.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    Line.BorderSizePixel = 0
    Line.Visible = false
    Line.ZIndex = 1000
    Line.Parent = UltraESPGui
    return Line
end

local function ESPMakeText()
    local Text = Instance.new("TextLabel")
    Text.Name = "SnooESP_Name"
    Text.AnchorPoint = Vector2.new(0.5, 1)
    Text.BackgroundTransparency = 1
    Text.BorderSizePixel = 0
    Text.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text.TextStrokeTransparency = 0
    Text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Text.TextSize = 14
    Text.Font = Enum.Font.GothamBold
    Text.Size = UDim2.fromOffset(240, 28)
    Text.Visible = false
    Text.ZIndex = 1001
    Text.Parent = UltraESPGui
    return Text
end

local function ESPDestroyAll()
    for Object, Data in pairs(ESPObjects) do
        if Data.Line then
            Data.Line:Destroy()
        end

        if Data.Text then
            Data.Text:Destroy()
        end

        ESPObjects[Object] = nil
    end
end

local function ESPRefresh()
    if not UltraESPEnabled then
        ESPDestroyAll()
        return
    end

    local Target = ESPFindBestAvailable()

    -- Existe somente UMA linha e UM nome:
    -- o alvo de maior prioridade que realmente está nos slots 1..8.
    for Object, Data in pairs(ESPObjects) do
        if not Target or Object ~= Target.Object then
            if Data.Line then Data.Line:Destroy() end
            if Data.Text then Data.Text:Destroy() end
            ESPObjects[Object] = nil
        end
    end

    if not Target then
        return
    end

    if not ESPObjects[Target.Object] then
        ESPObjects[Target.Object] = {
            Line = ESPMakeLine(),
            Text = ESPMakeText()
        }
    end

    ESPObjects[Target.Object].Name = Target.Name
    ESPObjects[Target.Object].Priority = Target.Priority
end

local function ESPUpdateVisuals()
    if not UltraESPEnabled then return end

    local Camera = workspace.CurrentCamera
    local MyRoot = ESPGetRoot()

    if not Camera or not MyRoot then return end

    local TargetObject
    local TargetData

    for Object, Data in pairs(ESPObjects) do
        TargetObject = Object
        TargetData = Data
        break
    end

    if not TargetObject or not TargetData or not TargetObject.Parent then
        return
    end

    local TargetPosition = ESPGetPosition(TargetObject)
    if not TargetPosition then return end

    -- Apenas leitura da posição do player.
    -- NENHUM CFrame/Position do player é alterado.
    local Origin = Camera:WorldToViewportPoint(MyRoot.Position)
    local Point = Camera:WorldToViewportPoint(TargetPosition)

    local X1, Y1 = Origin.X, Origin.Y
    local X2, Y2 = Point.X, Point.Y

    local DX = X2 - X1
    local DY = Y2 - Y1
    local Length = math.sqrt(DX * DX + DY * DY)

    if Point.Z > 0 then
        TargetData.Line.Position = UDim2.fromOffset(X1, Y1)
        TargetData.Line.Size = UDim2.fromOffset(Length, 3)
        TargetData.Line.Rotation = math.deg(math.atan2(DY, DX))
        TargetData.Line.Visible = true

        TargetData.Text.Position = UDim2.fromOffset(X2, Y2 - 8)
        TargetData.Text.Text = TargetData.Name
        TargetData.Text.Visible = true
    else
        TargetData.Line.Visible = false
        TargetData.Text.Visible = false
    end
end

local function SetUltraESP(State)
    UltraESPEnabled = State == true
    UltraESPGui.Enabled = UltraESPEnabled

    if UltraESPEnabled then
        ESPRefresh()

        if not ESPConnections.Render then
            ESPConnections.Render = RunService.RenderStepped:Connect(ESPUpdateVisuals)
        end

        if not ESPConnections.Scan then
            ESPConnections.Scan = task.spawn(function()
                while UltraESPEnabled and Gui.Parent do
                    ESPRefresh()
                    task.wait(0.25)
                end
            end)
        end
    else
        ESPDestroyAll()

        if ESPConnections.Render then
            ESPConnections.Render:Disconnect()
            ESPConnections.Render = nil
        end

        ESPConnections.Scan = nil
    end
end

SelectPage("ESP")
Section("ULTRA ESP")
Description("Procura somente nos modelos/slots 1 a 8 dentro de Plots. A posição 1-8 não muda a preferência.")
local UltraESPButton = Button("  ESP ULTRA • OFF")

UltraESPButton.MouseButton1Click:Connect(function()
    SetUltraESP(not UltraESPEnabled)
    UltraESPButton.Text = "  ESP ULTRA • " .. (UltraESPEnabled and "ON" or "OFF")

    if SaveConfig then
        SaveConfig()
    end
end)

Description("Prioridade: Strawberry Elephant > Headless Horseman / Meowl > John Pork > Skibid Toilet > Dragon Gingerine > Hydra Dragon Canneloni > Dragon Aquanini > Arcadragon > Signore Carapace > Antonio > La Supreme Combinasion > Love Love Bear > Elefanto Frigo > Dug dug dug > Griffin > Garama and Madundung")

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
UltraESPButton.Text = "  ESP ULTRA • " .. (UltraESPEnabled and "ON" or "OFF")

if AutoStealEnabled then StartAutoSteal() end
if SpamTPV1Enabled then StartSpamTPV1() end
if SpamTPV2Enabled then StartSpamTPV2() end
if InfiniteJumpEnabled then StartInfiniteJump() end
if InstantPromptEnabled then UpdatePrompts() end
if UltraESPEnabled then SetUltraESP(true) end
if FPSBoostEnabled then
	FPSBoostEnabled = false
	ApplyFPSBoost()
end
SaveConfig()

task.spawn(function()
	while Gui.Parent do
		task.wait(2)
		SaveConfig()
	end
end)

print("SnooHubV10 Beta carregado corretamente.")
