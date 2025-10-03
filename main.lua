local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local bv

local state = {
    fly=false, flySpeed=75, god=false, tpItems=false, tpOffset=5, killAura=false, killRange=20,
    infJump=false, speedHack=false, speedMult=2, freeCam=false, freeCamSpeed=100,
    noClip=false, autoCollect=false, touchFlyVector=Vector3.new(0,0,0)
}

local freeCamPos = camera.CFrame.Position
local toggleIndex = 0

local function getChar()
    local c = LocalPlayer.Character
    if c then return c end
    LocalPlayer.CharacterAdded:Wait()
    return LocalPlayer.Character
end

local function getHRP()
    local c = getChar()
    return c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c:FindFirstChildOfClass("Humanoid")
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
    bv.Velocity = (dir.Magnitude > 0) and dir.Unit * state.flySpeed or Vector3.new()
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
    if hum then hum.WalkSpeed = state.speedHack and 16*state.speedMult or 16 end
end

local function freeCamUpdate()
    local move = state.touchFlyVector
    if move.Magnitude>0 then freeCamPos=freeCamPos+move.Unit*state.freeCamSpeed*0.03 end
    camera.CFrame=CFrame.new(freeCamPos,freeCamPos+camera.CFrame.LookVector)
end

local function noClipLoop()
    local c = getChar()
    for _,part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not state.noClip end
    end
end

local function killAura()
    local hrp = getHRP()
    for _,npc in ipairs(Workspace:GetDescendants()) do
        if npc:IsA("Model") and npc~=getChar() then
            local h = npc:FindFirstChildOfClass("Humanoid")
            local nHRP = npc:FindFirstChild("HumanoidRootPart")
            if h and nHRP and (nHRP.Position-hrp.Position).Magnitude<=state.killRange then
                pcall(function() h.Health=0 end)
            end
        end
    end
end

local function autoCollect()
    local hrp = getHRP()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name=(obj.Name or ""):lower()
            if name:find("coin") or name:find("collect") then
                pcall(function() obj.CFrame=hrp.CFrame end)
            end
        end
    end
end

local itemTypes = {
    "Old Sack","Good Sack","Infernal Sack","Giant Sack",
    "Old Axe","Good Axe","Ice Axe","Strong Axe","Chainsaw","Admin Axe",
    "Old Rod","Good Rod","Carrot","Corn","Pumpkin","Berry","Apple","Morsel","Steak"
}
local selectedItems = {}

local ScreenGui = Instance.new("ScreenGui", CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0,400,0,750)
MainFrame.Position = UDim2.new(0,10,0,50)
MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
MainFrame.BorderSizePixel = 0

local function createToggle(name,callback)
    toggleIndex=toggleIndex+1
    local frame=Instance.new("Frame",MainFrame)
    frame.Size=UDim2.new(1,0,0,40)
    frame.Position=UDim2.new(0,0,0,50*(toggleIndex-1))
    frame.BackgroundColor3=Color3.fromRGB(40,40,40)

    local label=Instance.new("TextLabel",frame)
    label.Text=name
    label.Size=UDim2.new(0.7,0,1,0)
    label.BackgroundTransparency=1
    label.TextColor3=Color3.new(1,1,1)
    label.TextScaled=true

    local button=Instance.new("TextButton",frame)
    button.Text="OFF"
    button.Size=UDim2.new(0.3,0,1,0)
    button.Position=UDim2.new(0.7,0,0,0)
    button.BackgroundColor3=Color3.fromRGB(80,80,80)
    button.TextColor3=Color3.new(1,1,1)

    local on=false
    button.MouseButton1Click:Connect(function()
        on=not on
        button.Text=on and "ON" or "OFF"
        callback(on)
    end)
end

local function createSlider(name,min,max,default,callback)
    toggleIndex=toggleIndex+1
    local frame=Instance.new("Frame",MainFrame)
    frame.Size=UDim2.new(1,0,0,50)
    frame.Position=UDim2.new(0,0,0,50*(toggleIndex-1))
    frame.BackgroundColor3=Color3.fromRGB(50,50,50)

    local label=Instance.new("TextLabel",frame)
    label.Text=name.." : "..default
    label.Size=UDim2.new(1,0,0.4,0)
    label.BackgroundTransparency=1
    label.TextColor3=Color3.new(1,1,1)
    label.TextScaled=true

    local slider=Instance.new("TextButton",frame)
    slider.Size=UDim2.new(1,0,0.6,0)
    slider.Position=UDim2.new(0,0,0.4,0)
    slider.Text=""
    slider.BackgroundColor3=Color3.fromRGB(100,100,100)

    local dragging=false
    slider.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
        end
    end)
    slider.InputEnded:Connect(function(input)
        dragging=false
    end)
    slider.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
            local sizeX=slider.AbsoluteSize.X
            local posX=math.clamp(input.Position.X-slider.AbsolutePosition.X,0,sizeX)
            local value=min+(posX/sizeX)*(max-min)
            label.Text=name.." : "..math.floor(value)
            callback(value)
        end
    end)
end

local function createItemCheckbox(name)
    toggleIndex=toggleIndex+1
    local frame=Instance.new("Frame",MainFrame)
    frame.Size=UDim2.new(1,0,0,40)
    frame.Position=UDim2.new(0,0,0,50*(toggleIndex-1))
    frame.BackgroundColor3=Color3.fromRGB(60,60,60)

    local label=Instance.new("TextLabel",frame)
    label.Text=name
    label.Size=UDim2.new(0.7,0,1,0)
    label.BackgroundTransparency=1
    label.TextColor3=Color3.new(1,1,1)
    label.TextScaled=true

    local button=Instance.new("TextButton",frame)
    button.Text="OFF"
    button.Size=UDim2.new(0.3,0,1,0)
    button.Position=UDim2.new(0.7,0,0,0)
    button.BackgroundColor3=Color3.fromRGB(100,100,100)
    button.TextColor3=Color3.new(1,1,1)

    local on=false
    button.MouseButton1Click:Connect(function()
        on=not on
        button.Text=on and "ON" or "OFF"
        selectedItems[name]=on
    end)
end

createToggle("Fly",function(v) state.fly=v if not v then disableBV() end end)
createSlider("Fly Speed",25,300,75,function(v) state.flySpeed=v end)
createToggle("God Mode",function(v) state.god=v end)
createToggle("Teleport Items Auto",function(v) state.tpItems=v end)
createSlider("TP Offset",1,20,5,function(v) state.tpOffset=v end)
createToggle("Kill Aura",function(v) state.killAura=v end)
createSlider("Kill Aura Range",5,100,20,function(v) state.killRange=v end)
createToggle("Infinite Jump",function(v) state.infJump=v end)
createToggle("Speed Hack",function(v) state.speedHack=v speedHack() end)
createSlider("Speed Multiplier",1,10,2,function(v) state.speedMult=v speedHack() end)
createToggle("Free Cam",function(v) state.freeCam=v if v then freeCamPos=camera.CFrame.Position end end)
createSlider("Free Cam Speed",10,500,100,function(v) state.freeCamSpeed=v end)
createToggle("NoClip",function(v) state.noClip=v end)
createToggle("Auto Collect",function(v) state.autoCollect=v end)

for _,item in ipairs(itemTypes) do
    createItemCheckbox(item)
end

local function tpItemsFunc()
    local hrp = getHRP()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj~=hrp then
            local name=(obj.Name or "")
            for k,v in pairs(selectedItems) do
                if v and name:lower():find(k:lower()) then
                    pcall(function() obj.CFrame=hrp.CFrame+Vector3.new(0,state.tpOffset,0) end)
                end
            end
        end
    end
end

Run.RenderStepped:Connect(function()
    if state.fly then fly() else disableBV() end
    if state.god then godMode() end
    if state.tpItems then tpItemsFunc() end
    if state.killAura then killAura() end
    if state.infJump then end
    if state.speedHack then speedHack() end
    if state.freeCam then freeCamUpdate() end
    if state.noClip then noClipLoop() end
    if state.autoCollect then autoCollect() end
end)

UIS.InputBegan:Connect(infJump)