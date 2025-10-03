local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

local flyEnabled = false
local flySpeed = 75
local godModeEnabled = false
local teleportItemsEnabled = false
local teleportHeightOffset = 5
local freeCamEnabled = false
local freeCamSpeed = 100
local killAuraEnabled = false
local killAuraRange = 20

local camera = Workspace.CurrentCamera
local freeCamPos = camera.CFrame.Position
local freeCamCFrame = camera.CFrame
local lookVector = Vector3.new(0,0,-1)

local function applyGodMode(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        humanoid.StateChanged:Connect(function(_, state)
            if godModeEnabled and state == Enum.HumanoidStateType.Dead then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
    end
end

Player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if godModeEnabled then
        applyGodMode(char)
    end
end)

local Window = OrionLib:MakeWindow({Name = "99 Nächte Executor", HidePremium = true, SaveConfig = true, ConfigFolder = "99NightsConfig"})
local MainTab = Window:MakeTab({Name = "Main", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local FlySection = MainTab:AddSection({Name = "Fly"})
local GodSection = MainTab:AddSection({Name = "God Mode"})
local ItemsSection = MainTab:AddSection({Name = "Item Bringer"})
local FreeCamSection = MainTab:AddSection({Name = "Free Cam"})
local KillAuraSection = MainTab:AddSection({Name = "Kill Aura"})
local SettingsSection = MainTab:AddSection({Name = "Settings"})

FlySection:AddToggle({Name = "Enable Fly", Default = false, Callback = function(value)
    flyEnabled = value
    local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = flyEnabled
    end
end})

FlySection:AddSlider({Name = "Fly Speed", Min = 25, Max = 200, Default = 75, Increment = 5, ValueName = "Speed", Callback = function(value)
    flySpeed = value
end})

GodSection:AddToggle({Name = "Enable God Mode", Default = false, Callback = function(value)
    godModeEnabled = value
    if Player.Character then
        applyGodMode(Player.Character)
    end
end})

ItemsSection:AddToggle({Name = "Auto Teleport Items", Default = false, Callback = function(value)
    teleportItemsEnabled = value
end})

ItemsSection:AddSlider({Name = "Item Height Offset", Min = 1, Max = 20, Default = 5, Increment = 1, ValueName = "Offset", Callback = function(value)
    teleportHeightOffset = value
end})

ItemsSection:AddButton({Name = "Teleport All Items Now (P)", Callback = function()
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
end})

FreeCamSection:AddToggle({Name = "Enable Free Cam", Default = false, Callback = function(value)
    freeCamEnabled = value
    if freeCamEnabled then
        freeCamPos = camera.CFrame.Position
        freeCamCFrame = camera.CFrame
    else
        if Player.Character then
            local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                camera.CFrame = CFrame.new(hrp.Position + Vector3.new(0,5,0))
            end
        end
    end
end})

FreeCamSection:AddSlider({Name = "Free Cam Speed", Min = 25, Max = 300, Default = 100, Increment = 5, ValueName = "Speed", Callback = function(value)
    freeCamSpeed = value
end})

KillAuraSection:AddToggle({Name = "Enable Kill Aura", Default = false, Callback = function(value)
    killAuraEnabled = value
end})

KillAuraSection:AddSlider({Name = "Kill Aura Range", Min = 5, Max = 100, Default = 20, Increment = 1, ValueName = "Range", Callback = function(value)
    killAuraRange = value
end})

SettingsSection:AddSlider({Name = "Update Rate", Min = 0.01, Max = 0.1, Default = 0.03, Increment = 0.01, ValueName = "Rate", Callback = function(value)
    _G.RenderStepDelta = value
end})

Run.RenderStepped:Connect(function()
    if flyEnabled and Player.Character then
        local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
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
    end

    if teleportItemsEnabled and Player.Character then
        local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj ~= hrp then
                    obj.CFrame = hrp.CFrame + Vector3.new(0, teleportHeightOffset, 0)
                end
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
        camera.CFrame = CFrame.new(freeCamPos, freeCamPos + lookVector)
    end

    if killAuraEnabled and Player.Character then
        local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
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
    end
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
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
end)

OrionLib:Init()
