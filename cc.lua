-- ======================================
-- Grayx Hub Full Version (With Config + Info Tab)
-- ======================================

-- Load Libraries
local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

-- Create Window
local Window = Library:CreateWindow{
    Title = "Grayx Hub",
    SubTitle = "Plant Vs Brainrot",
    TabWidth = 160,
    Size = UDim2.fromOffset(650, 525),
    Resize = true,
    MinSize = Vector2.new(470, 380),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.G
}

-- ==========================
-- Services & Player
-- ==========================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- ==========================
-- Variables
-- ==========================
local selectedPlants = {}
local interval = 60
local speed = 16
local flySpeed = 50
local autoBuyItems = {
    ["Water Bucket"] = false,
    ["Frost Grenade"] = false,
    ["Banana Gun"] = false,
    ["Frost Blower"] = false,
    ["Carrot Launcher"] = false
}

-- ==========================
-- Tabs
-- ==========================
local Tabs = {
    Info = Window:CreateTab{ Title = "Info", Icon = "info" },
    Main = Window:CreateTab{ Title = "Main", Icon = "phosphor-users-bold" },
    Player = Window:CreateTab{ Title = "Player", Icon = "user" },
    ItemsTab = Window:CreateTab{ Title = "Items", Icon = "shopping-cart" },
    Extra = Window:CreateTab{ Title = "Extras", Icon = "crown" },
    Settings = Window:CreateTab{ Title = "Settings", Icon = "settings" }
}


-- trong phần Main (sau khi tạo MainSection)
local GraphicsSection = Tabs.Main:CreateSection("Graphics / FPS Boost")

local LowGraphicsToggle = GraphicsSection:CreateToggle("LowGraphics", {
    Title = "Low Graphics / Boost FPS",
    Description = "Giảm đồ họa để tăng FPS",
    Default = false
})
LowGraphicsToggle:OnChanged(function(state)
    if state then
        -- Tắt hiệu ứng nặng
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") 
               or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end

        -- Giảm chất lượng đồ họa
        pcall(function() settings().Rendering.QualityLevel = 0 end)

        -- Tắt ánh sáng / hiệu ứng hình ảnh trong Lighting
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e6
        Lighting.Brightness = 1

        pcall(function()
            for _, e in pairs(Lighting:GetChildren()) do
                if e:IsA("BloomEffect") or e:IsA("BlurEffect") or e:IsA("SunRaysEffect")
                   or e:IsA("ColorCorrectionEffect") then
                    e.Enabled = false
                end
            end
        end)

        print("[Graphics] Low Graphics ON")
    else
        -- Bật lại hiệu ứng
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") 
               or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = true
            end
        end

        pcall(function() settings().Rendering.QualityLevel = 10 end)

        Lighting.GlobalShadows = true
        Lighting.FogEnd = 1000
        Lighting.Brightness = 2

        pcall(function()
            for _, e in pairs(Lighting:GetChildren()) do
                if e:IsA("BloomEffect") or e:IsA("BlurEffect") or e:IsA("SunRaysEffect")
                   or e:IsA("ColorCorrectionEffect") then
                    e.Enabled = true
                end
            end
        end)

        print("[Graphics] Low Graphics OFF")
    end
end)

-- ==========================
local MainSection = Tabs.Main:CreateSection("Auto Buy Plants")
local ExtraSection = Tabs.Extra:CreateSection("Extras / Equip")

local Plants = {
    "Cactus Seed", "Strawberry Seed", "Pumpkin Seed", "Sunflower Seed",
    "Dragon Fruit Seed", "Eggplant Seed", "Watermelon Seed", "Grape Seed",
    "Cocotank Seed", "Carnivorous Plant Seed", "Mr Carrot Seed", "Tomatrio Seed",
    "Shroombino Seed", "Mango Seed"
}

local PlantDropdown = MainSection:CreateDropdown("Select Plants", {
    Title = "Plants",
    Description = "Chọn nhiều loại cây để mua",
    Values = Plants,
    Multi = true,
    Default = {}
})
PlantDropdown:OnChanged(function(Value)
    selectedPlants = {}
    for plant, state in pairs(Value) do
        if state then selectedPlants[plant] = true end
    end
end)

local PlantToggle = MainSection:CreateToggle("Auto Buy Plants", {
    Title = "Auto Buy Plants",
    Description = "Tự động mua tất cả cây đã chọn",
    Default = false
})
PlantToggle:OnChanged(function(state)
    if state then
        spawn(function()
            while PlantToggle.Value do
                local plantsList = {}
                for plant,_ in pairs(selectedPlants) do table.insert(plantsList, plant) end
                if #plantsList == 0 then task.wait(0.1) continue end

                local plant = plantsList[math.random(1,#plantsList)]
                local success = false
                for i=1,5 do
                    if pcall(function() Remotes:WaitForChild("BuyItem"):FireServer(plant,3) end) then success = true break end
                    task.wait(0.01)
                end
                if not success then warn("Không thể mua cây: "..plant) end
                task.wait(0.01)
            end
        end)
    end
end)

-- Equip Best Slider & Toggle
local EquipSlider = ExtraSection:CreateSlider("Interval", {
    Title = "Interval (s)",
    Description = "Khoảng thời gian giữa mỗi Equip Best",
    Min = 1,
    Max = 500,
    Default = interval,
    Rounding = 1
})
EquipSlider:OnChanged(function(val) interval = val end)

local EquipToggle = ExtraSection:CreateToggle("Equip Best Toggle", {
    Title = "Get Money & Equip Best",
    Description = "Mỗi interval, thực hiện EquipBestBrainrots",
    Default = false
})
EquipToggle:OnChanged(function(state)
    if state then
        spawn(function()
            while EquipToggle.Value do
                pcall(function() Remotes:WaitForChild("EquipBestBrainrots"):FireServer() end)
                task.wait(interval)
            end
        end)
    end
end)

-- ==========================
-- Items Tab: Auto Buy Gear
-- ==========================
local ItemsSection = Tabs.ItemsTab:CreateSection("Buy Gear / Items")
for itemName,_ in pairs(autoBuyItems) do
    local toggle = ItemsSection:CreateToggle(itemName, {
        Title = "Auto Buy "..itemName,
        Description = "Tự động mua "..itemName.." mỗi 1s",
        Default = false
    })
    toggle:OnChanged(function(state) autoBuyItems[itemName] = state end)
end
spawn(function()
    while true do
        for itemName, isEnabled in pairs(autoBuyItems) do
            if isEnabled then
                pcall(function() Remotes:WaitForChild("BuyGear"):FireServer(itemName) end)
                task.wait(0.01)
            end
        end
        task.wait(0.01)
    end
end)

-- ==========================
-- Player Tab
-- ==========================
local PlayerSection = Tabs.Player:CreateSection("Player Options")

local AntiAFKToggle = PlayerSection:CreateToggle("Anti AFK", {Title="Anti AFK", Description="Tự động tránh bị AFK", Default=true})
AntiAFKToggle:OnChanged(function(state)
    if state then
        LocalPlayer.Idled:Connect(function() 
            if AntiAFKToggle.Value then
                VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) 
            end
        end)
    end
end)

local SpeedSlider = PlayerSection:CreateSlider("WalkSpeed", {Title="Speed", Description="Điều chỉnh tốc độ người chơi", Min=16, Max=500, Default=speed, Rounding=1})
SpeedSlider:OnChanged(function(val)
    speed = val
    if Humanoid then Humanoid.WalkSpeed = speed end
end)

local JumpToggle = PlayerSection:CreateToggle("Infinite Jump", {Title="Jump Inf", Description="Nhảy vô hạn", Default=false})
JumpToggle:OnChanged(function(state)
    if state then
        game:GetService("UserInputService").JumpRequest:Connect(function()
            if JumpToggle.Value then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end)

local NoClipToggle = PlayerSection:CreateToggle("NoClip + Anti Void", {Title="NoClip & Anti Void", Description="Đi xuyên vật thể và tránh rơi", Default=false})
NoClipToggle:OnChanged(function(state)
    spawn(function()
        while NoClipToggle.Value do
            if Humanoid and RootPart then
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
                if RootPart.Position.Y < -50 then RootPart.CFrame = CFrame.new(0,50,0) end
            end
            RunService.Stepped:Wait()
        end
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end)
end)

-- Fly
local FlyToggle = PlayerSection:CreateToggle("Fly", {Title="Fly", Description="Bay lên/xuống", Default=false})
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
                if moveDir.Magnitude > 0 then flyBodyVelocity.Velocity = moveDir.Unit * flySpeed else flyBodyVelocity.Velocity = Vector3.new(0,0,0) end
            else
                if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity=nil end
            end
        end)
    else
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity=nil end
    end
end)

-- Teleport Wander Prison liên tục
local WanderPrisonToggle = PlayerSection:CreateToggle("Teleport Wander Prison", {Title="Teleport Wander Prison", Description="Teleport đến Wander Prison liên tục", Default=false})
local WanderPrisonPosition = Vector3.new(-173.44, 12.49, 999.06)
WanderPrisonToggle:OnChanged(function(state)
    if state then
        spawn(function()
            while WanderPrisonToggle.Value do
                if RootPart then RootPart.CFrame = CFrame.new(WanderPrisonPosition) end
                task.wait(0.5)
            end
        end)
    end
end)

-- ==========================
-- Info Tab
-- ==========================
local InfoSection = Tabs.Info:CreateSection("Update Info")

local InfoParagraph = InfoSection:CreateParagraph("Update Info", {
    Title = "Thông tin cập nhật",
    Content = [[
- Phiên bản mới nhất: Grayx Hub v1.2
- Thêm tính năng Teleport Wander Prison
- Thêm FPS Boost / Low Graphics
-  tính năng Auto Buy, Equip Best, Player Options
- Config và theme đổi màu
- Thêm FPS BOOST
- Thêm Graphics Quality
]]
})
-- ==========================
-- Graphics Quality Slider
-- ==========================
local QualitySlider = GraphicsSection:CreateSlider("GraphicsQuality", {
    Title = "Graphics Quality",
    Description = "Điều chỉnh chất lượng đồ họa (0 = thấp, 10 = cao)",
    Min = 1,
    Max = 20,
    Default = settings().Rendering.QualityLevel,
    Rounding = 1
})

QualitySlider:OnChanged(function(val)
    pcall(function()
        settings().Rendering.QualityLevel = val
        print("[Graphics] Quality Level set to", val)

        -- Tự động bật/tắt hiệu ứng lighting nếu kéo về 0 hoặc 10
        if val <= 1 then
            Lighting.GlobalShadows = false
            Lighting.Brightness = 1
            pcall(function()
                for _, e in pairs(Lighting:GetChildren()) do
                    if e:IsA("BloomEffect") or e:IsA("BlurEffect") or e:IsA("SunRaysEffect")
                       or e:IsA("ColorCorrectionEffect") then
                        e.Enabled = false
                    end
                end
            end)
        elseif val >= 10 then
            Lighting.GlobalShadows = true
            Lighting.Brightness = 2
            pcall(function()
                for _, e in pairs(Lighting:GetChildren()) do
                    if e:IsA("BloomEffect") or e:IsA("BlurEffect") or e:IsA("SunRaysEffect")
                       or e:IsA("ColorCorrectionEffect") then
                        e.Enabled = true
                    end
                end
            end)
        end
    end)
end)

-- ==========================
-- Settings Tab
-- ==========================
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes{}
InterfaceManager:SetFolder("GrayxHub")
SaveManager:SetFolder("GrayxHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- ==========================
-- Notification
-- ==========================
Library:Notify{Title="Grayx Hub", Content="Script đã được tải thành công!", Duration=8}
Window:SelectTab(1)





