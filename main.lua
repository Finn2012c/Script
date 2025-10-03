local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local state = {
    fly = false,
    flySpeed = 75,
    god = false,
    tpItems = false,
    tpOffset = 5,
    killAura = false,
    killRange = 20,
    infJump = false,
    speedHack = false,
    speedMult = 2,
    freeCam = false,
    freeCamSpeed = 100,
    noClip = false,
    autoCollect = false,
    touchFlyVector = Vector3.new(0,0,0),
    selectedItems = {}
}

local freeCamPos = camera.CFrame.Position
local toggleIndex = 0
local bv = nil

local function getChar() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function getHRP()
    local c = getChar()
    if c then return c:FindFirstChild("HumanoidRootPart") end
end
local function getHum()
    local c = getChar()
    if c then return c:FindFirstChildOfClass("Humanoid") end
end

local function enableBV(part)
    if bv and bv.Parent then bv:Destroy() end
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.P = 1250
    bv.Velocity = Vector3.new(0,0,0)
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

local function godHover()
    local hum = getHum()
    local hrp = getHRP()
    if not hrp or not hum then return end
    pcall(function()
        hum.MaxHealth = math.huge
        hum.Health = hum.MaxHealth
    end)
    pcall(function()
        local upOrigin = hrp.Position + Vector3.new(0,100,0)
        local ray = workspace:Raycast(upOrigin, Vector3.new(0,-300,0), {getChar()})
        if ray and ray.Position then
            local targetY = ray.Position.Y + 50
            local targetPos = Vector3.new(hrp.Position.X, targetY, hrp.Position.Z)
            hrp.CFrame = CFrame.new(targetPos, targetPos + hrp.CFrame.LookVector)
        else
            local fallbackPos = hrp.Position + Vector3.new(0,50,0)
            hrp.CFrame = CFrame.new(fallbackPos, fallbackPos + hrp.CFrame.LookVector)
        end
    end)
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
    if hum then hum.WalkSpeed = state.speedHack and 16 * state.speedMult or 16 end
end

local function freeCamUpdate()
    local move = state.touchFlyVector
    if move.Magnitude > 0 then
        freeCamPos = freeCamPos + move.Unit * state.freeCamSpeed * 0.03
    end
    camera.CFrame = CFrame.new(freeCamPos, freeCamPos + camera.CFrame.LookVector)
end

local function noClipLoop()
    local char = getChar()
    for _,part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state.noClip
        end
    end
end

local function killAura()
    local hrp = getHRP()
    if not hrp then return end
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= getChar() then
            local h = obj:FindFirstChildOfClass("Humanoid")
            local nhrp = obj:FindFirstChild("HumanoidRootPart")
            if h and nhrp then
                local dist = (nhrp.Position - hrp.Position).Magnitude
                if dist <= state.killRange then
                    pcall(function() h.Health = 0 end)
                end
            end
        end
    end
end

local function autoCollect()
    local hrp = getHRP()
    if not hrp then return end
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = (obj.Name or ""):lower()
            if name:find("coin") or name:find("collect") then
                pcall(function() obj.CFrame = hrp.CFrame end)
            end
        end
    end
end

local itemTypes = {
    "Old Sack","Good Sack","Infernal Sack","Giant Sack",
    "Old Axe","Good Axe","Ice Axe","Strong Axe","Chainsaw","Admin Axe",
    "Old Rod","Good Rod","Carrot","Corn","Pumpkin","Berry","Apple","Morsel","Steak"
}

local function tpItemsFunc()
    local hrp = getHRP()
    if not hrp then return end
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= hrp then
            local name = (obj.Name or "")
            for k,v in pairs(state.selectedItems) do
                if v and name:lower():find(k:lower()) then
                    pcall(function() obj.CFrame = hrp.CFrame + Vector3.new(0, state.tpOffset, 0) end)
                end
            end
        end
    end
end

UIS.TouchMoved:Connect(function(_, delta)
    state.touchFlyVector = Vector3.new(delta.X/50, 0, delta.Y/50)
end)
UIS.TouchEnded:Connect(function() state.touchFlyVector = Vector3.new(0,0,0) end)
UIS.InputBegan:Connect(infJump)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NNExecutorGui"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0,520,0,920)
MainFrame.Position = UDim2.new(0,10,0,40)
MainFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
MainFrame.BorderSizePixel = 0

local Header = Instance.new("TextLabel", MainFrame)
Header.Size = UDim2.new(1,0,0,40)
Header.Position = UDim2.new(0,0,0,0)
Header.BackgroundTransparency = 1
Header.Text = "99 Nächte Executor"
Header.TextScaled = true
Header.TextColor3 = Color3.new(1,1,1)

local function createToggle(name, callback)
    toggleIndex = toggleIndex + 1
    local frame = Instance.new("Frame", MainFrame)
    frame.Size = UDim2.new(1, -10, 0, 36)
    frame.Position = UDim2.new(0,5,0, 46 + 46 * (toggleIndex - 1))
    frame.BackgroundColor3 = Color3.fromRGB(32,32,32)
    frame.BorderSizePixel = 0

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.72, 0, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.28, -10, 0.9, 0)
    btn.Position = UDim2.new(0.72, 0, 0.05, 0)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(80,80,80)

    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        btn.Text = on and "ON" or "OFF"
        callback(on)
    end)
end

local function createSlider(name, min, max, default, callback)
    toggleIndex = toggleIndex + 1
    local frame = Instance.new("Frame", MainFrame)
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.Position = UDim2.new(0,5,0, 46 + 46 * (toggleIndex - 1))
    frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    frame.BorderSizePixel = 0

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,0,0.4,0)
    label.Position = UDim2.new(0,6,0,0)
    label.BackgroundTransparency = 1
    label.Text = name .. " : " .. tostring(math.floor(default))
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true

    local slider = Instance.new("Frame", frame)
    slider.Size = UDim2.new(1, -12, 0, 28)
    slider.Position = UDim2.new(0,6,0,18)
    slider.BackgroundColor3 = Color3.fromRGB(70,70,70)

    local knob = Instance.new("TextButton", slider)
    knob.Size = UDim2.new(0, 0, 1, 0)
    knob.Text = ""
    knob.AutoButtonColor = false
    knob.BackgroundColor3 = Color3.fromRGB(140,140,140)

    local function updateKnob(value)
        local pct = (value - min) / (max - min)
        pct = math.clamp(pct, 0, 1)
        knob.Size = UDim2.new(pct, 0, 1, 0)
    end

    updateKnob(default)
    callback(default)

    local dragging = false
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    knob.InputEnded:Connect(function(input) dragging = false end)
    slider.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local posX = math.clamp(input.Position.X - slider.AbsolutePosition.X, 0, slider.AbsoluteSize.X)
            local value = min + (posX / slider.AbsoluteSize.X) * (max - min)
            label.Text = name .. " : " .. tostring(math.floor(value))
            updateKnob(value)
            callback(value)
        end
    end)
end

local function createItemCheckbox(name)
    toggleIndex = toggleIndex + 1
    local frame = Instance.new("Frame", MainFrame)
    frame.Size = UDim2.new(1, -10, 0, 36)
    frame.Position = UDim2.new(0,5,0, 46 + 46 * (toggleIndex - 1))
    frame.BackgroundColor3 = Color3.fromRGB(36,36,36)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.72, 0, 1, 0)
    label.Position = UDim2.new(0,6,0,0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.28, -10, 0.9, 0)
    btn.Position = UDim2.new(0.72, 0, 0.05, 0)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(100,100,100)

    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        btn.Text = on and "ON" or "OFF"
        state.selectedItems[name] = on
    end)
end

createToggle("Fly", function(v) state.fly = v if not v then disableBV() end end)
createSlider("Fly Speed", 25, 300, 75, function(v) state.flySpeed = v end)
createToggle("God Mode (Hover 50)", function(v) state.god = v end)
createToggle("Teleport Items Auto", function(v) state.tpItems = v end)
createSlider("TP Offset", 1, 40, 5, function(v) state.tpOffset = math.floor(v) end)
createToggle("Kill Aura", function(v) state.killAura = v end)
createSlider("Kill Aura Range", 5, 200, 20, function(v) state.killRange = math.floor(v) end)
createToggle("Infinite Jump", function(v) state.infJump = v end)
createToggle("Speed Hack", function(v) state.speedHack = v speedHack() end)
createSlider("Speed Multiplier", 1, 10, 2, function(v) state.speedMult = v speedHack() end)
createToggle("Free Cam", function(v) state.freeCam = v if v then freeCamPos = camera.CFrame.Position end end)
createSlider("Free Cam Speed", 10, 800, 100, function(v) state.freeCamSpeed = v end)
createToggle("NoClip", function(v) state.noClip = v end)
createToggle("Auto Collect", function(v) state.autoCollect = v end)

for _,it in ipairs(itemTypes) do
    createItemCheckbox(it)
end

Run.RenderStepped:Connect(function(dt)
    if state.fly then fly() else disableBV() end
    if state.god then godHover() end
    if state.tpItems then tpItemsFunc() end
    if state.killAura then killAura() end
    if state.speedHack then speedHack() end
    if state.freeCam then freeCamUpdate() end
    if state.noClip then noClipLoop() end
    if state.autoCollect then autoCollect() end
end)
