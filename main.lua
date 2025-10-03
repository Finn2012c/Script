local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local bv

local state = {
    fly=false,
    flySpeed=75,
    god=false,
    tpItems=false,
    tpOffset=5,
    killAura=false,
    killRange=20,
    infJump=false,
    speedHack=false,
    speedMult=2,
    freeCam=false,
    freeCamSpeed=100,
    noClip=false,
    autoCollect=false,
    touchFlyVector=Vector3.new(0,0,0)
}

local freeCamPos = camera.CFrame.Position

local function getChar()
    local c = LocalPlayer.Character
    if c then return c end
    if not c then LocalPlayer.CharacterAdded:Wait() return LocalPlayer.Character end
end

local function getHRP()
    local c = getChar()
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp end
    end
end

local function getHum()
    local c = getChar()
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then return hum end
    end
end

local function enableBV(part)
    if bv and bv.Parent then bv:Destroy() end
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.P = 1250
    bv.Velocity = Vector3.new()
    bv.Parent = part
end

local function disableBV()
    if bv and bv.Parent then bv:Destroy() end
    bv = nil
end

local function fly()
    local hrp = getHRP()
    if not hrp then disableBV() return end
    enableBV(hrp)
    local dir = state.touchFlyVector
    if dir.Magnitude > 0 then
        bv.Velocity = dir.Unit * state.flySpeed
    else
        bv.Velocity = Vector3.new(0,0,0)
    end
end

local function godMode()
    local hum = getHum()
    if hum then
        hum.MaxHealth = math.huge
        hum.Health = hum.MaxHealth
    end
end

local function infJump(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
        local hum = getHum()
        if hum and state.infJump then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end

local function speedHack()
    local hum = getHum()
    if hum then
        hum.WalkSpeed = state.speedHack and 16 * state.speedMult or 16
    end
end

local function freeCamUpdate()
    local move = state.touchFlyVector
    if move.Magnitude > 0 then
        freeCamPos = freeCamPos + move.Unit * state.freeCamSpeed * 0.03
    end
    camera.CFrame = CFrame.new(freeCamPos, freeCamPos + camera.CFrame.LookVector)
end

local function noClipLoop()
    local c = getChar()
    if not c then return end
    for _, part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state.noClip
        end
    end
end

local function killAura()
    local hrp = getHRP()
    if not hrp then return end
    for _, npc in ipairs(Workspace:GetDescendants()) do
        if npc:IsA("Model") and npc ~= getChar() then
            local h = npc:FindFirstChildOfClass("Humanoid")
            local nHRP = npc:FindFirstChild("HumanoidRootPart")
            if h and nHRP and (nHRP.Position - hrp.Position).Magnitude <= state.killRange then
                pcall(function() h.Health = 0 end)
            end
        end
    end
end

local function autoCollect()
    local hrp = getHRP()
    if not hrp then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = (obj.Name or ""):lower()
            if name:find("coin") or name:find("collect") then
                pcall(function() obj.CFrame = hrp.CFrame end)
            end
        end
    end
end

local function tpItems()
    local hrp = getHRP()
    if not hrp then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= hrp then
            pcall(function() obj.CFrame = hrp.CFrame + Vector3.new(0, state.tpOffset, 0) end)
        end
    end
end

UIS.TouchMoved:Connect(function(_, delta)
    state.touchFlyVector = Vector3.new(delta.X/50, 0, delta.Y/50)
end)

UIS.TouchEnded:Connect(function()
    state.touchFlyVector = Vector3.new(0,0,0)
end)

local ScreenGui = Instance.new("ScreenGui", CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 600)
MainFrame.Position = UDim2.new(0, 10, 0, 50)
MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
MainFrame.BorderSizePixel = 0

local function createToggle(name, callback)
    local frame = Instance.new("Frame", MainFrame)
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    frame.BorderSizePixel = 0
    local label = Instance.new("TextLabel", frame)
    label.Text = name
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true
    local button = Instance.new("TextButton", frame)
    button.Text = "OFF"
    button.Size = UDim2.new(0.3, 0, 1, 0)
    button.Position = UDim2.new(0.7, 0, 0, 0)
    button.TextColor3 = Color3.new(1,1,1)
    button.BackgroundColor3 = Color3.fromRGB(80,80,80)
    local on = false
    button.MouseButton1Click:Connect(function()
        on = not on
        button.Text = on and "ON" or "OFF"
        callback(on)
    end)
end

createToggle("Fly", function(v) state.fly = v if not v then disableBV() end end)
createToggle("God Mode", function(v) state.god = v end)
createToggle("Teleport Items Auto", function(v) state.tpItems = v end)
createToggle("Kill Aura", function(v) state.killAura = v end)
createToggle("Infinite Jump", function(v) state.infJump = v end)
createToggle("Speed Hack", function(v) state.speedHack = v speedHack() end)
createToggle("Free Cam", function(v) state.freeCam = v if v then freeCamPos = camera.CFrame.Position end end)
createToggle("NoClip", function(v) state.noClip = v end)
createToggle("Auto Collect", function(v) state.autoCollect = v end)

Run.RenderStepped:Connect(function()
    if state.fly then fly() else disableBV() end
    if state.god then godMode() end
    if state.tpItems then tpItems() end
    if state.killAura then killAura() end
    if state.speedHack then speedHack() end
    if state.freeCam then freeCamUpdate() end
    if state.noClip then noClipLoop() end
    if state.autoCollect then autoCollect() end
end)

UIS.InputBegan:Connect(infJump)
