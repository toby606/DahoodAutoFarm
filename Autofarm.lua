if (not game:IsLoaded()) then 
    game.Loaded:Wait()
    task.wait(1)
end

repeat task.wait(0.1) until (game:GetService("Players").LocalPlayer) and (game:GetService("Players").LocalPlayer.Character)

local SG = Instance.new("ScreenGui")
SG.Parent = game:GetService("CoreGui")
SG.Name = "abcdefg"
SG.IgnoreGuiInset = true 
local TL = Instance.new("TextLabel")
TL.Parent = SG 
TL.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
TL.Active = false
TL.Font = Enum.Font.MontserratMedium
TL.TextColor3 = Color3.fromRGB(200, 200, 200)
TL.TextSize = 24
TL.AnchorPoint = Vector2.new(0.5, 0.5)
TL.Position = UDim2.new(0.5, 0, 0.5, 0)
TL.Size = UDim2.new(1, 0, 1, 0)

local Player = game:GetService("Players").LocalPlayer
local Cashiers = workspace.Cashiers 
local Drop = workspace.Ignored.Drop
local Dis = false
local Broken = 0 
local StartTick = os.time()
local LastCycleTime = os.time()
local CycleCount = 0
local MaxTimePerCashier = 12 -- Maximum time to spend on one cashier (seconds)

_G.Disable = function()
    Dis = true
    game:GetService("RunService"):Set3dRenderingEnabled(true)
    setfpscap(60)
    game:GetService("CoreGui").abcdefg:Destroy()
end

Player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
Player.CameraMaxZoomDistance = 6
Player.CameraMinZoomDistance = 6

TL.Text = "\n@"..Player.Name.."\n$999,999,999"

-- Anti-cheat bypass
pcall(function()
    local a=game:GetService("ReplicatedStorage").MainEvent
    local b={"CHECKER_1","TeleportDetect","OneMoreTime"}
    local c
    c=hookmetamethod(game,"__namecall",function(...)
        local d={...}
        local self=d[1]
        local e=getnamecallmethod()
        if e=="FireServer" and self==a and table.find(b,d[2]) then 
            return 
        end 
        return c(...)
    end)
end)

local Click = function(Part)
    local Input = game:GetService("VirtualInputManager")
    local T = os.time()

    if (Part:GetAttribute("OriginalPos") == nil) then 
        Part:SetAttribute("OriginalPos", Part.Position)
    end

    repeat 
        Part.CFrame = (workspace.Camera.CFrame + workspace.Camera.CFrame.LookVector * 1) * CFrame.Angles(90, 0, 0)
        Input:SendMouseButtonEvent(workspace.Camera.ViewportSize.X/2, workspace.Camera.ViewportSize.Y/2, 0, true, game, 1)
        task.wait(0.1)
        Input:SendMouseButtonEvent(workspace.Camera.ViewportSize.X/2, workspace.Camera.ViewportSize.Y/2, 0, false, game, 1)
    until (Part == nil) or (Part:FindFirstChild("ClickDetector") == nil) or (os.time()-T >= 2)
end

local AntiSit = function(Char)
    task.wait(1)    
    local Hum = Char:WaitForChild("Humanoid")
    Hum.Seated:Connect(function()
        warn("SITTING")
        Hum.Sit = false
        Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        task.wait(0.3)
        Hum.Jump = true
    end)
end

local GetCash = function()
    local Found = {}
    local charPos = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.Position
    
    if not charPos then return Found end
    
    for i,v in pairs(Drop:GetChildren()) do 
        if v.Name == "MoneyDrop" then 
            local Pos = v:GetAttribute("OriginalPos") or v.Position
            if (Pos - charPos).Magnitude <= 17 then 
                Found[#Found+1] = v 
            end
        end
    end
    return Found
end

local ResetCashiers = function()
    for i,v in pairs(Cashiers:GetChildren()) do 
        if i == 15 then 
            v:MoveTo(Vector3.new(-622.948, 24, -286.52))
        elseif i == 16 then
            v:MoveTo(Vector3.new(-629.948, 24, -286.52))
        end
        
        for x,z in pairs(v:GetChildren()) do 
            if z:IsA("BasePart") then 
                z.CanCollide = false 
            end
        end
    end
    CycleCount = CycleCount + 1
    LastCycleTime = os.time()
end

local GetCashier = function()
    -- Reset cashiers every 4 minutes or if no cashiers are alive
    if os.time() - LastCycleTime >= 240 then
        ResetCashiers()
    end
    
    for i,v in pairs(Cashiers:GetChildren()) do 
        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then 
            return v 
        end
    end
    
    -- If no cashiers are alive, reset them immediately
    ResetCashiers()
    return nil
end

local To = function(CF)
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame = CF 
        Player.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    end
end

-- Main farming loop
task.spawn(function()
    while true and not Dis do
        task.wait()
        
        if not Player.Character or not Player.Character:FindFirstChild("FULLY_LOADED_CHAR") then
            repeat task.wait(1) until Player.Character and Player.Character:FindFirstChild("FULLY_LOADED_CHAR")
        end
        
        -- Equip combat tool
        local combat = Player.Backpack:FindFirstChild("Combat") or Player.Character:FindFirstChild("Combat")
        if not combat then continue end
        if combat.Parent ~= Player.Character then
            combat.Parent = Player.Character
            task.wait(0.5)
        end
        
        local Cashier = GetCashier()
        if not Cashier then continue end
        
        local startTime = os.time()
        local success = false
        
        -- Attempt to break cashier (max 12 seconds)
        while os.time() - startTime < MaxTimePerCashier and Cashier and Cashier:FindFirstChild("Humanoid") and Cashier.Humanoid.Health > 0 do
            To((Cashier.Head.CFrame + Vector3.new(0, -2.5, 0)) * CFrame.Angles(math.rad(90), 0, 0))
            Player.Character.Combat:Activate()
            task.wait(0.1)
        end
        
        -- If we successfully broke the cashier
        if Cashier and Cashier:FindFirstChild("Humanoid") and Cashier.Humanoid.Health <= 0 then
            Broken = Broken + 1
            To(Cashier.Head.CFrame + Cashier.Head.CFrame.LookVector * Vector3.new(0, 2, 0))
            
            -- Collect money
            local Cash = GetCash()
            for i,v in pairs(Cash) do 
                Click(v)
                task.wait(0.1)
            end
        end
        
        -- Unequip tool
        for i,v in pairs(Player.Character:GetChildren()) do 
            if v:IsA("Tool") then 
                v.Parent = Player.Backpack 
            end
        end
    end
end)

-- UI Update
local StartCash = Player.DataFolder.Currency.Value
task.spawn(function()
    while true and not Dis do
        task.wait(0.5)
        
        local currentCash = Player.DataFolder.Currency.Value
        local profit = currentCash - StartCash
        
        TL.Text = string.format([[
@%s
$%s
ATMS: %d
Time: %02d:%02d:%02d
Profit: $%s
Cycle: %02d:%02d (%d)
Current Target: %s
]],
            Player.Name,
            tostring(currentCash):reverse():gsub("...","%0,",math.floor((#tostring(currentCash)-1)/3)):reverse(),
            Broken,
            (os.time()-StartTick)/60^2, (os.time()-StartTick)/60%60, (os.time()-StartTick)%60,
            tostring(profit):reverse():gsub("...","%0,",math.floor((#tostring(profit)-1)/3)):reverse(),
            (os.time()-LastCycleTime)/60%60, (os.time()-LastCycleTime)%60, CycleCount,
            tostring(GetCashier()) or "None"
        )
    end
end)

-- Anti-afk
Player.Idled:Connect(function()
    for i = 1, 10 do 
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame) 
        task.wait(0.2) 
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.2)
    end
end)

-- Optimizations
pcall(function() UserSettings().GameSettings.MasterVolume = 0 end)
pcall(function() settings().Rendering.QualityLevel = "Level01" end)

-- Anti-sit
Player.CharacterAdded:Connect(AntiSit)
if Player.Character then
    task.spawn(function()
        task.wait(3)
        AntiSit(Player.Character)
    end)
end

-- FPS settings
for i = 1, 10 do 
    setfpscap(_G.AutofarmSettings and _G.AutofarmSettings.Fps or 60)
    task.wait(0.1)
end

-- Render settings
if _G.AutofarmSettings and _G.AutofarmSettings.Saver == true then 
    game:GetService("RunService"):Set3dRenderingEnabled(false) 
else 
    SG.Enabled = false
end
