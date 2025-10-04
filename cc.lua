-- ======================================
-- Grayx Hub Full Version (Fluent-Renewed)
-- ======================================

-- Load Fluent-Renewed UI
local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

-- Create Window
local Window = Library:CreateWindow{
    Title = "Grayx Hub",
    SubTitle = "Plant Vs Brainrot",
    TabWidth = 160,
    Size = UDim2.fromOffset(650, 600),
    Resize = true,
    MinSize = Vector2.new(470, 420),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.G
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HttpService = game:GetService("HttpService")

-- ==========================
-- Variables
-- ==========================
local selectedPlants = {}
local interval = 60
local speed = 16
local flySpeed = 50

-- ==========================
-- Helper Functions
-- ==========================
local function buyPlant(plantName, quantity)
    local success, err = pcall(function()
        local remote = Remotes:WaitForChild("BuyItem")
        remote:FireServer(plantName, quantity)
    end)
    return success
end

-- ==========================
-- Tabs
-- ==========================
local Tabs = {
    Main = Window:CreateTab{ Title = "Main", Icon = "users-bold" },
    Player = Window:CreateTab{ Title = "Player", Icon = "user" },
    ItemsTab = Window:CreateTab{ Title = "Items", Icon = "shopping-cart" }
}
-- =====================================
-- Main Tab: Boots FPS (Tối ưu đồ họa)
-- =====================================
local BootsFPSToggle = Tabs.Main:CreateSection("Extras / FPS"):CreateToggle("Boots FPS", {
    Title = "Boots FPS",
    Description = "Giảm đồ họa game để tăng FPS",
    Default = false
})

-- Lưu trạng thái gốc
local _originalLighting = nil
local _originalParts = {}       -- [instance] = {Material, Reflectance, CastShadow, Transparency}
local _originalEffects = {}     -- [instance] = {Enabled/Transparency}
local _bootsActive = false

-- Lưu trạng thái Lighting
local function saveLightingState()
    local Lighting = game:GetService("Lighting")
    _originalLighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Technology = Lighting.Technology
    }
end

-- Áp dụng đồ họa thấp
local function applyLowGraphics()
    if _bootsActive then return end
    _bootsActive = true
    saveLightingState()

    local Lighting = game:GetService("Lighting")
    Lighting.GlobalShadows = false
    Lighting.FogStart = 0
    Lighting.FogEnd = 1000
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(200,200,200)
    Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not _originalParts[obj] then
                _originalParts[obj] = {
                    Material = obj.Material,
                    Reflectance = obj.Reflectance,
                    CastShadow = obj.CastShadow,
                    Transparency = obj.Transparency
                }
            end
            pcall(function()
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
                obj.CastShadow = false
            end)
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or
               obj:IsA("PointLight") or obj:IsA("SurfaceLight") or obj:IsA("SpotLight") then
            if not _originalEffects[obj] then
                _originalEffects[obj] = { Enabled = obj.Enabled ~= false }
            end
            pcall(function() obj.Enabled = false end)
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if not _originalEffects[obj] then
                _originalEffects[obj] = { Transparency = obj.Transparency }
            end
            pcall(function() obj.Transparency = 1 end)
        end
    end
end

-- Khôi phục đồ họa
local function restoreGraphics()
    if not _bootsActive then return end
    _bootsActive = false

    local Lighting = game:GetService("Lighting")
    if _originalLighting then
        for k,v in pairs(_originalLighting) do
            Lighting[k] = v
        end
    end

    for obj,props in pairs(_originalParts) do
        if obj and obj.Parent then
            pcall(function()
                obj.Material = props.Material
                obj.Reflectance = props.Reflectance
                obj.CastShadow = props.CastShadow
                obj.Transparency = props.Transparency
            end)
        end
    end

    for obj,props in pairs(_originalEffects) do
        if obj and obj.Parent then
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or
                   obj:IsA("PointLight") or obj:IsA("SurfaceLight") or obj:IsA("SpotLight") then
                    obj.Enabled = props.Enabled
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = props.Transparency
                end
            end)
        end
    end
end

BootsFPSToggle:OnChanged(function(state)
    if state then
        applyLowGraphics()
    else
        restoreGraphics()
    end
end)



local ItemsSection = Tabs.ItemsTab:CreateSection("Buy Gear / Items")

-- Danh sách item để auto mua
local autoBuyItems = {
    ["Water Bucket"] = false,
    ["Frost Grenade"] = false,
    ["Banana Gun"] = false,
    ["Frost Blower"] = false,
    ["Carrot Launcher"] = false
}

-- Thời gian giữa mỗi lần mua (giây)
local buyInterval = 1

-- Tạo toggle cho từng item
for itemName, _ in pairs(autoBuyItems) do
    local toggle = ItemsSection:CreateToggle(itemName, {
        Title = "Auto Buy "..itemName,
        Description = "Tự động mua "..itemName.." mỗi "..buyInterval.."s",
        Default = false
    })

    toggle:OnChanged(function(state)
        autoBuyItems[itemName] = state
    end)
end

-- Vòng lặp chung để mua tất cả item được bật xen kẽ
spawn(function()
    while true do
        for itemName, isEnabled in pairs(autoBuyItems) do
            if isEnabled then
                local args = {itemName}
                local success, err = pcall(function()
                    Remotes:WaitForChild("BuyGear"):FireServer(unpack(args))
                end)
                if not success then
                    warn("Không thể mua "..itemName..":", err)
                end
                task.wait(buyInterval)
            end
        end
        task.wait(0.1) -- delay nhỏ giữa vòng lặp
    end
end)



local AntiAFKSection = Tabs.Player:CreateSection("Anti AFK")
local AntiAFKToggle = AntiAFKSection:CreateToggle("Anti AFK", {
    Title = "Anti AFK",
    Description = "Tự động tránh bị AFK",
    Default = true
})

local VirtualUser = game:GetService("VirtualUser")

AntiAFKToggle:OnChanged(function(state)
    if state then
        LocalPlayer.Idled:Connect(function()
            if AntiAFKToggle.Value then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end
        end)
    end
end)

-- =====================================
-- Main Tab: Auto Buy Plants + Equip Best
-- =====================================
local PlantSection = Tabs.Main:CreateSection("Auto Buy Plants")
local ExtraSection = Tabs.Main:CreateSection("Extras / Equip")

local Plants = {
    "Cactus Seed", "Strawberry Seed", "Pumpkin Seed", "Sunflower Seed",
    "Dragon Fruit Seed", "Eggplant Seed", "Watermelon Seed", "Grape Seed",
    "Cocotank Seed", "Carnivorous Plant Seed", "Mr Carrot Seed", "Tomatrio Seed",
    "Shroombino Seed", "Mango Seend"
}

local PlantDropdown = PlantSection:CreateDropdown("Select Plants", {
    Title = "Plants",
    Description = "Chọn nhiều loại cây để mua",
    Values = Plants,
    Multi = true,
    Default = {}
})

PlantDropdown:OnChanged(function(Value)
    selectedPlants = {}
    for plant, state in pairs(Value) do
        if state then
            selectedPlants[plant] = true
        end
    end
end)

local PlantToggle = PlantSection:CreateToggle("Auto Buy Plants", {
    Title = "Auto Buy Plants",
    Description = "Tự động mua tất cả cây đã chọn",
    Default = false
})

PlantToggle:OnChanged(function(state)
    if state then
        spawn(function()
            while PlantToggle.Value do
                local plantsList = {}
                for plant,_ in pairs(selectedPlants) do
                    table.insert(plantsList, plant)
                end

                if #plantsList == 0 then
                    task.wait(0.1)
                    continue
                end

                local plant = plantsList[math.random(1, #plantsList)]

                local success = false
                for i = 1, 5 do
                    if buyPlant(plant, 3) then
                        success = true
                        break
                    end
                    task.wait(0.01)
                end

                if not success then
                    warn("Không thể mua cây: "..plant)
                end

                task.wait(0.01)
            end
        end)
    end
end)

-- Slider Interval Equip Best
local EquipSlider = ExtraSection:CreateSlider("Interval", {
    Title = "Interval (s)",
    Description = "Khoảng thời gian giữa mỗi Equip Best",
    Min = 1,
    Max = 500,
    Default = interval,
    Rounding = 1
})
EquipSlider:OnChanged(function(val)
    interval = val
end)

-- Toggle Equip Best
local EquipToggle = ExtraSection:CreateToggle("Equip Best Toggle", {
    Title = "Get Money & Equip Best",
    Description = "Mỗi interval, thực hiện EquipBestBrainrots",
    Default = false
})
EquipToggle:OnChanged(function(state)
    if state then
        spawn(function()
            while EquipToggle.Value do
                pcall(function()
                    Remotes:WaitForChild("EquipBestBrainrots"):FireServer()
                end)
                wait(interval)
            end
        end)
    end
end)

-- =====================================
-- Player Tab: ESP, Speed, Jump, NoClip, Fly
-- =====================================
local PlayerSection = Tabs.Player:CreateSection("Player Options")

-- ESP
local ESPToggle = PlayerSection:CreateToggle("ESP Players", {
    Title = "ESP Players",
    Description = "Hiển thị ESP cho tất cả người chơi",
    Default = false
})

local espObjects = {}

local function createESP(player)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart

        local box = Instance.new("BoxHandleAdornment")
        box.Adornee = root
        box.Size = Vector3.new(2,5,1)
        box.Color3 = Color3.fromRGB(255,0,0)
        box.Transparency = 0.5
        box.AlwaysOnTop = true
        box.Parent = workspace

        local bill = Instance.new("BillboardGui")
        bill.Adornee = root
        bill.Size = UDim2.new(0,100,0,50)
        bill.StudsOffset = Vector3.new(0,3,0)
        bill.AlwaysOnTop = true
        bill.Parent = root

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.Text = player.Name
        label.TextColor3 = Color3.fromRGB(255,255,255)
        label.TextStrokeTransparency = 0
        label.TextScaled = true
        label.Parent = bill

        espObjects[player] = {Box = box, NameTag = bill}
    end
end

local function removeESP(player)
    if espObjects[player] then
        if espObjects[player].Box then espObjects[player].Box:Destroy() end
        if espObjects[player].NameTag then espObjects[player].NameTag:Destroy() end
        espObjects[player] = nil
    end
end

ESPToggle:OnChanged(function(state)
    if state then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                createESP(player)
                player.CharacterAdded:Connect(function()
                    if ESPToggle.Value then
                        task.wait(0.1)
                        createESP(player)
                    end
                end)
            end
        end
    else
        for player,_ in pairs(espObjects) do
            removeESP(player)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- Speed Slider
local SpeedSlider = PlayerSection:CreateSlider("WalkSpeed", {
    Title = "Speed",
    Description = "Điều chỉnh tốc độ người chơi",
    Min = 16,
    Max = 500,
    Default = speed,
    Rounding = 1
})
SpeedSlider:OnChanged(function(val)
    speed = val
    if Humanoid then
        Humanoid.WalkSpeed = speed
    end
end)

-- Infinite Jump
local JumpToggle = PlayerSection:CreateToggle("Infinite Jump", {
    Title = "Jump Inf",
    Description = "Nhảy vô hạn",
    Default = false
})
JumpToggle:OnChanged(function(state)
    if state then
        game:GetService("UserInputService").JumpRequest:Connect(function()
            if JumpToggle.Value then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- NoClip + Anti Void
local NoClipToggle = PlayerSection:CreateToggle("NoClip + Anti Void", {
    Title = "NoClip & Anti Void",
    Description = "Đi xuyên vật thể và tránh rơi",
    Default = false
})
NoClipToggle:OnChanged(function(state)
    spawn(function()
        while NoClipToggle.Value do
            if Humanoid and RootPart then
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                if RootPart.Position.Y < -50 then
                    RootPart.CFrame = CFrame.new(0,50,0)
                end
            end
            RunService.Stepped:Wait()
        end
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end)
end)

-- Fly
local FlyToggle = PlayerSection:CreateToggle("Fly", {
    Title = "Fly",
    Description = "Bay lên/xuống",
    Default = false
})
local flyBodyVelocity
FlyToggle:OnChanged(function(state)
    if state then
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(400000,400000,400000)
        flyBodyVelocity.Velocity = Vector3.new(0,0,0)
        flyBodyVelocity.Parent = RootPart

        local UserInputService = game:GetService("UserInputService")
        RunService.RenderStepped:Connect(function()
            if FlyToggle.Value then
                local moveDir = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + workspace.CurrentCamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - workspace.CurrentCamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - workspace.CurrentCamera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + workspace.CurrentCamera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end
                if moveDir.Magnitude > 0 then
                    flyBodyVelocity.Velocity = moveDir.Unit * flySpeed
                else
                    flyBodyVelocity.Velocity = Vector3.new(0,0,0)
                end
            else
                if flyBodyVelocity then
                    flyBodyVelocity:Destroy()
                    flyBodyVelocity = nil
                end
            end
        end)
    else
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
    end
end)
-- Teleport Wander Prison
local WanderPrisonToggle = PlayerSection:CreateToggle("Teleport Wander Prison", {
    Title = "Teleport Wander Prison",
    Description = "Teleport đến Wander Prison",
    Default = false
})

local WanderPrisonPosition = Vector3.new(-173.44, 12.49, 999.06)

WanderPrisonToggle:OnChanged(function(state)
    if state then
        if RootPart then
            RootPart.CFrame = CFrame.new(WanderPrisonPosition)
            print("Đã teleport đến Wander Prison")
        end
        -- Tắt toggle ngay sau khi teleport nếu muốn chỉ teleport 1 lần
        task.wait(0.1)
        WanderPrisonToggle:Set(false)
    end
end)




Window:SelectTab(1)
Library:Notify{
    Title = "Auto Hub Loaded",
    Content = "Grayx Hub đã sẵn sàng!",
    Duration = 4
}
