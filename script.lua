getgenv().SecureMode = true
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local state = {
    flyEnabled = false,
    flySpeed = 75,
    godMode = false,
    teleportItems = false,
    teleportOffset = 5,
    freeCam = false,
    freeCamSpeed = 100,
    killAura = false,
    killAuraRange = 20,
    autoCollect = false,
    antiAfk = true,
    noClip = false,
    infJump = false,
    walkSpeed = 16,
    jumpPower = 50,
    speedHack = false,
    speedMultiplier = 2,
    esp = false,
    espObjects = {},
    reach = 5,
    spinbot = false,
    spinSpeed = 5,
    smoothFly = true
}

local camera = Workspace.CurrentCamera
local freeCamPos = camera and camera.CFrame.Position or Vector3.new(0,0,0)
local bv
local noclipConn
local humStateConn
local killAuraCache = {}
local espFolder = Instance.new("Folder")
espFolder.Name = "___ESP_FOLDER"
espFolder.Parent = game:GetService("CoreGui")

local function getCharacter(player)
    return player and player.Character
end

local function getHRP(char)
    if not char then return end
    return char:FindFirstChild("HumanoidRootPart")
end

local function safeFindHumanoid(model)
    if not model then return end
    return model:FindFirstChildOfClass("Humanoid")
end

local function enableBodyVelocity(part)
    if not part then return end
    if bv and bv.Parent == part then return bv end
    if bv and bv.Parent then pcall(function() bv:Destroy() end) end
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.P = 1250
    bv.Velocity = Vector3.new(0,0,0)
    bv.Parent = part
    return bv
end

local function disableBodyVelocity()
    if bv and bv.Parent then pcall(function() bv:Destroy() end) end
    bv = nil
end

local function applyGodToCharacter(char)
    local hum = safeFindHumanoid(char)
    if hum then
        pcall(function()
            hum.MaxHealth = math.huge
            hum.Health = hum.MaxHealth
        end)
    end
end

local function setupCharacterProtection(char)
    applyGodToCharacter(char)
    if not humStateConn and char then
        local hum = safeFindHumanoid(char)
        if hum then
            humStateConn = hum.StateChanged:Connect(function(_, state)
                if state == Enum.HumanoidStateType.Dead and state.godMode then
                    pcall(function() hum.Health = hum.MaxHealth end)
                end
            end)
        end
    end
end

local function teleportAllItemsToPlayer(offset)
    local char = getCharacter(LocalPlayer)
    local hrp = getHRP(char)
    if not hrp then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= hrp then
            pcall(function() obj.CFrame = hrp.CFrame + Vector3.new(0, offset, 0) end)
        end
    end
end

local function autoCollectLoop()
    local char = getCharacter(LocalPlayer)
    local hrp = getHRP(char)
    if not hrp then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = (obj.Name or ""):lower()
            if name:find("coin") or name:find("collect") or name:find("pickup") then
                pcall(function() obj.CFrame = hrp.CFrame end)
            end
        end
    end
end

local function setWalkSpeedJump(char)
    local hum = safeFindHumanoid(char)
    if hum then
        pcall(function()
            hum.WalkSpeed = state.walkSpeed
            hum.JumpPower = state.jumpPower
        end)
    end
end

local function toggleNoClip(on)
    if on then
        noclipConn = Run.Stepped:Connect(function()
            local char = getCharacter(LocalPlayer)
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    end
end

local function performKillAura(range)
    local char = getCharacter(LocalPlayer)
    local hrp = getHRP(char)
    if not hrp then return end
    for _, npc in ipairs(Workspace:GetDescendants()) do
        if npc:IsA("Model") and npc ~= char then
            local npcHRP = npc:FindFirstChild("HumanoidRootPart")
            local hum = safeFindHumanoid(npc)
            if hum and npcHRP and (npcHRP.Position - hrp.Position).Magnitude <= range then
                pcall(function() hum.Health = 0 end)
            end
        end
    end
end

local function createESPForTarget(target)
    if not target or not target.Parent then return end
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if state.espObjects[target] and state.espObjects[target].box then return end
    local box = Drawing and Drawing.new and Drawing.new("Square") or nil
    local text = Drawing and Drawing.new and Drawing.new("Text") or nil
    if box then
        box.Size = Vector2.new(50, 50)
        box.Thickness = 2
        box.Transparency = 1
        box.Visible = true
    end
    if text then
        text.Size = 14
        text.Center = true
        text.Outline = true
        text.Visible = true
    end
    state.espObjects[target] = {box = box, text = text}
end

local function removeAllESP()
    for target, objs in pairs(state.espObjects) do
        if objs.box and objs.box.Remove then pcall(function() objs.box:Remove() end) end
        if objs.text and objs.text.Remove then pcall(function() objs.text:Remove() end) end
        state.espObjects[target] = nil
    end
end

local function updateESP()
    if not state.esp then return end
    for target, objs in pairs(state.espObjects) do
        if not target or not target.Parent then
            if objs.box and objs.box.Remove then pcall(function() objs.box:Remove() end) end
            if objs.text and objs.text.Remove then pcall(function() objs.text:Remove() end) end
            state.espObjects[target] = nil
        else
            local hrp = target:FindFirstChild("HumanoidRootPart")
            if hrp then
                local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local size = math.clamp(2000 / (screenPos.Z), 10, 300)
                    if objs.box then
                        objs.box.Position = Vector2.new(screenPos.X - size/2, screenPos.Y - size/2)
                        objs.box.Size = Vector2.new(size, size)
                        objs.box.Color = Color3.fromHSV((tick()%5)/5,1,1)
                        objs.box.Visible = true
                    end
                    if objs.text then
                        objs.text.Position = Vector2.new(screenPos.X, screenPos.Y - size/2 - 12)
                        objs.text.Text = target.Name
                        objs.text.Color = Color3.new(1,1,1)
                        objs.text.Visible = true
                    end
                else
                    if objs.box and objs.box.Visible then objs.box.Visible = false end
                    if objs.text and objs.text.Visible then objs.text.Visible = false end
                end
            end
        end
    end
end

local function infiniteJumpHandler(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
        if state.infJump then
            local char = getCharacter(LocalPlayer)
            local hum = safeFindHumanoid(char)
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end

local function spinbotLoop()
    if not state.spinbot then return end
    local char = getCharacter(LocalPlayer)
    if char then
        local hrp = getHRP(char)
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(state.spinSpeed), 0)
        end
    end
end

local function applySpeedHack(char)
    local hum = safeFindHumanoid(char)
    if hum then
        if state.speedHack then
            pcall(function() hum.WalkSpeed = (state.walkSpeed or 16) * (state.speedMultiplier or 2) end)
        else
            pcall(function() hum.WalkSpeed = state.walkSpeed or 16 end)
        end
    end
end

local function teleportToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local hrp = getHRP(LocalPlayer.Character)
    local targetHRP = getHRP(targetPlayer.Character)
    if hrp and targetHRP then
        pcall(function() hrp.CFrame = targetHRP.CFrame + Vector3.new(0,3,0) end)
    end
end

local function bringPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local hrp = getHRP(targetPlayer.Character)
    local myHRP = getHRP(LocalPlayer.Character)
    if hrp and myHRP then
        pcall(function() hrp.CFrame = myHRP.CFrame + Vector3.new(0,3,0) end)
    end
end

local function walkToPosition(pos)
    local char = getCharacter(LocalPlayer)
    local hum = safeFindHumanoid(char)
    if hum and char then
        hum:MoveTo(pos)
    end
end

local function safeDisconnect(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function() conn:Disconnect() end)
    end
end

local Window = Rayfield:CreateWindow({
    Name = "99 Nächte Executor - Full",
    LoadingTitle = "99 Nächte Executor",
    LoadingSubtitle = "Full Build",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "99NightsConfig",
        FileName = "config"
    },
    Discord = {Enabled = false},
    KeySystem = false
})

local MainTab = Window:CreateTab("Main")

MainTab:CreateToggle({Name="Fly", CurrentValue=false, Flag="fly", Callback=function(v) state.flyEnabled=v if not state.flyEnabled then disableBodyVelocity() end end})
MainTab:CreateSlider({Name="Fly Speed", Min=25, Max=300, Default=75, Increment=5, Suffix="Speed", CurrentValue=75, Flag="flyspeed", Callback=function(v) state.flySpeed=v end})

MainTab:CreateToggle({Name="God Mode", CurrentValue=false, Flag="god", Callback=function(v) state.godMode=v if v and LocalPlayer.Character then applyGodToCharacter(LocalPlayer.Character) end end})

MainTab:CreateToggle({Name="Teleport Items Auto", CurrentValue=false, Flag="tpitems", Callback=function(v) state.teleportItems=v end})
MainTab:CreateSlider({Name="Teleport Offset", Min=0, Max=50, Default=5, Increment=1, Suffix="Studs", CurrentValue=5, Flag="tpoffset", Callback=function(v) state.teleportOffset=v end})
MainTab:CreateButton({Name="Teleport Items Now (P)", Callback=function() teleportAllItemsToPlayer(state.teleportOffset) end})

MainTab:CreateToggle({Name="Free Cam", CurrentValue=false, Flag="freecam", Callback=function(v) state.freeCam=v if v then freeCamPos = camera.CFrame.Position end end})
MainTab:CreateSlider({Name="Free Cam Speed", Min=10, Max=500, Default=100, Increment=5, Suffix="Speed", CurrentValue=100, Flag="freecamspeed", Callback=function(v) state.freeCamSpeed=v end})

MainTab:CreateToggle({Name="Kill Aura", CurrentValue=false, Flag="killaura", Callback=function(v) state.killAura=v end})
MainTab:CreateSlider({Name="Kill Aura Range", Min=5, Max=200, Default=20, Increment=1, Suffix="Studs", CurrentValue=20, Flag="killaurarange", Callback=function(v) state.killAuraRange=v end})

MainTab:CreateToggle({Name="Auto Collect", CurrentValue=false, Flag="autocollect", Callback=function(v) state.autoCollect=v end})
MainTab:CreateToggle({Name="Anti-AFK", CurrentValue=true, Flag="antiafk", Callback=function(v) state.antiAfk=v end})

MainTab:CreateToggle({Name="NoClip", CurrentValue=false, Flag="noclip", Callback=function(v) state.noClip=v toggleNoClip(v) end})
MainTab:CreateToggle({Name="Infinite Jump", CurrentValue=false, Flag="infjump", Callback=function(v) state.infJump=v end})

MainTab:CreateSlider({Name="Walk Speed", Min=8, Max=500, Default=16, Increment=1, Suffix="WS", CurrentValue=16, Flag="walkspeed", Callback=function(v) state.walkSpeed=v if LocalPlayer.Character then setWalkSpeedJump(LocalPlayer.Character) end end})
MainTab:CreateSlider({Name="Jump Power", Min=20, Max=200, Default=50, Increment=1, Suffix="JP", CurrentValue=50, Flag="jumppower", Callback=function(v) state.jumpPower=v if LocalPlayer.Character then setWalkSpeedJump(LocalPlayer.Character) end end})

MainTab:CreateToggle({Name="Speed Hack", CurrentValue=false, Flag="speedhack", Callback=function(v) state.speedHack=v if LocalPlayer.Character then applySpeedHack(LocalPlayer.Character) end end})
MainTab:CreateSlider({Name="Speed Multiplier", Min=1, Max=10, Default=2, Increment=0.1, Suffix="x", CurrentValue=2, Flag="speedmult", Callback=function(v) state.speedMultiplier=v if LocalPlayer.Character then applySpeedHack(LocalPlayer.Character) end end})

MainTab:CreateToggle({Name="ESP", CurrentValue=false, Flag="esp", Callback=function(v) state.esp=v if not v then removeAllESP() else for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then createESPForTarget(p.Character) end end end end})
MainTab:CreateSlider({Name="Reach", Min=1, Max=50, Default=5, Increment=0.5, Suffix="Studs", CurrentValue=5, Flag="reach", Callback=function(v) state.reach=v end})

MainTab:CreateToggle({Name="Spinbot", CurrentValue=false, Flag="spinbot", Callback=function(v) state.spinbot=v end})
MainTab:CreateSlider({Name="Spin Speed", Min=1, Max=30, Default=5, Increment=1, Suffix="deg", CurrentValue=5, Flag="spinspeed", Callback=function(v) state.spinSpeed=v end})

MainTab:CreateTextbox({Name="Teleport To Player (Name)", Placeholder="PlayerName", RemoveTextAfterFocusLost=true, Flag="tptoplayer", Callback=function(v) if v and v~="" then local target = Players:FindFirstChild(v) if target then teleportToPlayer(target) end end end})
MainTab:CreateTextbox({Name="Bring Player (Name)", Placeholder="PlayerName", RemoveTextAfterFocusLost=true, Flag="bringplayer", Callback=function(v) if v and v~="" then local target = Players:FindFirstChild(v) if target then bringPlayer(target) end end end})
MainTab:CreateButton({Name="Walk To Mouse", Callback=function() local mouse = LocalPlayer:GetMouse() walkToPosition(mouse.Hit.p) end})
MainTab:CreateButton({Name="Rejoin Server", Callback=function() pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end) end})

MainTab:CreateLabel({Name="Performance & Misc"})
MainTab:CreateToggle({Name="Disable Rendering (save FPS)", CurrentValue=false, Flag="disableRender", Callback=function(v) if v then Run.RenderStepped:Wait(); camera:Destroy() else workspace.CurrentCamera = Workspace.CurrentCamera end end})

MainTab:CreateButton({Name="Clear GUI ESP", Callback=function() removeAllESP() end})

Run.RenderStepped:Connect(function(dt)
    if state.flyEnabled then
        local char = getCharacter(LocalPlayer)
        local hrp = getHRP(char)
        if hrp then
            if state.smoothFly then
                enableBodyVelocity(hrp)
                local cam = Workspace.CurrentCamera
                local dir = Vector3.new()
                if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
                local vel = (dir.Magnitude > 0 and dir.Unit * state.flySpeed) or Vector3.new(0,0,0)
                if bv and bv.Parent then pcall(function() bv.Velocity = vel end) end
            else
                local char = getCharacter(LocalPlayer)
                local hrp = getHRP(char)
                if hrp then
                    local cam = Workspace.CurrentCamera
                    local dir = Vector3.new()
                    if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
                    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
                    pcall(function() hrp.Velocity = (dir.Magnitude > 0 and dir.Unit * state.flySpeed) or Vector3.new(0,0,0) end)
                end
            end
        end
    else
        disableBodyVelocity()
    end

    if state.teleportItems then
        pcall(function() teleportAllItemsToPlayer(state.teleportOffset) end)
    end

    if state.autoCollect then
        pcall(function() autoCollectLoop() end)
    end

    if state.killAura then
        pcall(function() performKillAura(state.killAuraRange) end)
    end

    if state.freeCam then
        local move = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0,0,-1) end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0,0,1) end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1,0,0) end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1,0,0) end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move + Vector3.new(0,-1,0) end
        if move.Magnitude > 0 then
            freeCamPos = freeCamPos + move.Unit * state.freeCamSpeed * (dt or 0.03)
        end
        camera.CFrame = CFrame.new(freeCamPos, freeCamPos + camera.CFrame.LookVector)
    end

    if state.noClip then
        toggleNoClip(true)
    end

    if state.spinbot then
        spinbotLoop()
    end

    if state.esp then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if not state.espObjects[p.Character] then createESPForTarget(p.Character) end
            end
        end
        updateESP()
    end

    local char = getCharacter(LocalPlayer)
    if char then
        setWalkSpeedJump(char)
        applySpeedHack(char)
        if state.godMode then applyGodToCharacter(char) end
    end
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        pcall(function() teleportAllItemsToPlayer(state.teleportOffset) end)
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if state.godMode then pcall(function() applyGodToCharacter(char) end) end
    end)
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    setWalkSpeedJump(char)
    if state.godMode then applyGodToCharacter(char) end
    if state.speedHack then applySpeedHack(char) end
end)

UIS.InputBegan:Connect(infiniteJumpHandler)

StarterGui:SetCore("SendNotification", {Title="99 Nächte Executor", Text="Loaded", Duration=3})

Rayfield:Init()
