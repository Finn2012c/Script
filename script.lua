getgenv().SecureMode = true
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

local flyEnabled = false
local flySpeed = 75
local godModeEnabled = false
local godModeConnection
local teleportItemsEnabled = false
local teleportHeightOffset = 5
local freeCamEnabled = false
local freeCamSpeed = 100
local killAuraEnabled = false
local killAuraRange = 20

local camera = Workspace.CurrentCamera
local freeCamPos = camera.CFrame.Position

local function applyGodMode(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        if not godModeConnection then
            godModeConnection = humanoid.StateChanged:Connect(function(_, state)
                if godModeEnabled and state == Enum.HumanoidStateType.Dead then
                    humanoid.Health = humanoid.MaxHealth
                end
            end)
        end
    end
end

Player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if godModeEnabled then
        applyGodMode(char)
    end
end)

local Window = Rayfield:CreateWindow({
    Name = "99 Nächte Executor",
    LoadingTitle = "99 Nächte Executor",
    LoadingSubtitle = "by DeinName",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "99NightsConfig",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "99 Nächte Executor",
        Subtitle = "Key System",
        Note = "Kein Key erforderlich",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"KeinKey"}
    }
})

local MainTab = Window:CreateTab("Main")
local FlySection = MainTab:CreateSection("Fly")
local GodSection = MainTab:CreateSection("God Mode")
local ItemsSection = MainTab:CreateSection("Item Bringer")
local FreeCamSection = MainTab:CreateSection("Free Cam")
local KillAuraSection = MainTab:CreateSection("Kill Aura")
local SettingsSection = MainTab:CreateSection("Settings")

FlySection:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(value)
        flyEnabled = value
        local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = flyEnabled
        end
    end
})

FlySection:CreateSlider({
    Name = "Fly Speed",
    Min = 25,
    Max = 200,
    Default = 75,
    Increment = 5,
    ValueName = "Speed",
    Flag = "FlySpeed",
    Callback = function(value)
        flySpeed = value
    end
})

GodSection:CreateToggle({
    Name = "Enable God Mode",
    CurrentValue = false,
    Flag = "GodToggle",
    Callback = function(value)
        godModeEnabled = value
        if Player.Character then
            applyGodMode(Player.Character)
        end
    end
})

ItemsSection:CreateToggle({
    Name = "Auto Teleport Items",
    CurrentValue = false,
    Flag = "TeleportToggle",
    Callback = function(value)
        teleportItemsEnabled = value
    end
})

ItemsSection:CreateSlider({
    Name = "Item Height Offset",
    Min = 1,
    Max = 20,
    Default = 5,
    Increment = 1,
    ValueName = "Offset",
    Flag = "ItemOffset",
    Callback = function(value)
        teleportHeightOffset = value
    end
})

ItemsSection:CreateButton({
    Name = "Teleport All Items Now (P)",
    Callback = function()
        if Player.Character then
            local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj ~= hrp then
                        obj.CFrame = hrp.CFrame + Vector3.new(0, teleportHeightOffset, 0)
                    end
                end
            end
        end
    end
})

FreeCamSection:CreateToggle({
    Name = "Enable Free Cam",
    CurrentValue = false,
    Flag = "FreeCamToggle",
    Callback = function(value)
        freeCamEnabled = value
        if freeCamEnabled then
            freeCamPos = camera.CFrame.Position
        else
            if Player.Character then
                local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    camera.CFrame = CFrame.new(hrp.Position + Vector3.new(0,5,0))
                end
            end
        end
    end
})

FreeCamSection:CreateSlider({
    Name = "Free Cam Speed",
    Min = 25,
    Max = 300,
    Default = 100,
    Increment = 5,
    ValueName = "Speed",
    Flag = "FreeCamSpeed",
    Callback = function(value)
        freeCamSpeed = value
    end
})

KillAuraSection:CreateToggle({
    Name = "Enable Kill Aura",
    CurrentValue = false,
    Flag = "KillAuraToggle",
    Callback = function(value)
        killAuraEnabled = value
    end
})

KillAuraSection:CreateSlider({
    Name = "Kill Aura Range",
    Min = 5,
    Max = 100,
    Default = 20,
    Increment = 1,
    ValueName = "Range",
    Flag = "KillRange",
    Callback = function(value)
        killAuraRange = value
    end
})

SettingsSection:CreateSlider({
    Name = "Update Rate",
    Min = 0.01,
    Max = 0.1,
    Default = 0.03,
    Increment = 0.01,
    ValueName = "Rate",
    Flag = "UpdateRate",
    Callback = function(value)
        _G.RenderStepDelta = value
    end
})

Run.RenderStepped:Connect(function()
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

    if flyEnabled and hrp then
        local cam = Workspace.CurrentCamera
        local dir = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
        hrp.Velocity = (dir.Magnitude > 0 and dir.Unit * flySpeed) or Vector3.new(0,0,0)
    end

    if teleportItemsEnabled and hrp then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj ~= hrp then
                obj.CFrame = hrp.CFrame + Vector3.new(0, teleportHeightOffset, 0)
            end
        end
    end

    if freeCamEnabled then
        local move = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0,0,-1) end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0,0,1) end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1,0,0) end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1,0,0) end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move + Vector3.new(0,-1,0) end
        if move.Magnitude > 0 then
            freeCamPos = freeCamPos + move.Unit * freeCamSpeed * (_G.RenderStepDelta or 0.03)
        end
        camera.CFrame = CFrame.new(freeCamPos, freeCamPos + camera.CFrame.LookVector)
    end

    if killAuraEnabled and hrp then
        for _, npc in ipairs(Workspace:GetDescendants()) do
            if npc:IsA("Model") and npc ~= Player.Character then
                local hum = npc:FindFirstChildOfClass("Humanoid")
                local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                if hum and npcHRP and (npcHRP.Position - hrp.Position).Magnitude <= killAuraRange then
                    hum.Health = 0
                end
            end
        end
    end
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj ~= hrp then
                    obj.CFrame = hrp.CFrame + Vector3.new(0, teleportHeightOffset, 0)
                end
            end
        end
    end
end)

Rayfield:Init()
