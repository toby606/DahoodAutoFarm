if (not game:IsLoaded()) then 
    game.Loaded:Wait()
    task.wait(1)
end

repeat task.wait(0.1) until (game:GetService("Players").LocalPlayer) and (game:GetService("Players").LocalPlayer.Character)

local Player = game:GetService("Players").LocalPlayer
local Cashiers = workspace.Cashiers 
local Drop = workspace.Ignored.Drop
local Dis = false
local Broken = 0 
local StartTick = os.time()
local LastCycleTime = os.time()
local StartCash = Player.DataFolder.Currency.Value

-- UI Setup
local SG = Instance.new("ScreenGui")
SG.Parent = game:GetService("CoreGui")
SG.Name = "AutofarmStats"
SG.IgnoreGuiInset = true

local Background = Instance.new("Frame")
Background.Parent = SG
Background.BackgroundColor3 = Color3.new(0, 0, 0)
Background.Size = UDim2.new(1, 0, 1, 0)
Background.ZIndex = 0

local MainFrame = Instance.new("Frame")
MainFrame.Parent = SG
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0.3, 0, 0.4, 0)
MainFrame.ZIndex = 1

local Corner = Instance.new("UICorner")
Corner.Parent = MainFrame
Corner.CornerRadius = UDim.new(0.05, 0)

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Text = "AUTOFARM STATS"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 28
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, 0, 0.15, 0)
Title.Position = UDim2.new(0, 0, 0.05, 0)

local Username = Instance.new("TextLabel")
Username.Parent = MainFrame
Username.Text = "@"..Player.Name
Username.Font = Enum.Font.GothamMedium
Username.TextSize = 18
Username.TextColor3 = Color3.fromRGB(200, 200, 200)
Username.BackgroundTransparency = 1
Username.Size = UDim2.new(1, 0, 0.1, 0)
Username.Position = UDim2.new(0, 0, 0.2, 0)

local StatsContainer = Instance.new("Frame")
StatsContainer.Parent = MainFrame
StatsContainer.BackgroundTransparency = 1
StatsContainer.Size = UDim2.new(0.9, 0, 0.6, 0)
StatsContainer.Position = UDim2.new(0.05, 0, 0.3, 0)

local function createStatLabel(name, yPosition)
    local frame = Instance.new("Frame")
    frame.Parent = StatsContainer
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0.15, 0)
    frame.Position = UDim2.new(0, 0, yPosition, 0)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = frame
    nameLabel.Text = name
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.Name = "Value"
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 16
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Size = UDim2.new(0.5, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    return valueLabel
end

-- Create all stat labels
local totalCashLabel = createStatLabel("TOTAL CASH", 0)
local profitLabel = createStatLabel("PROFIT", 0.15)
local atmsBrokenLabel = createStatLabel("ATMS BROKEN", 0.3)
local cycleLabel = createStatLabel("CURRENT CYCLE", 0.45)
local timeLabel = createStatLabel("TIME RUNNING", 0.6)
local cashiersLabel = createStatLabel("CASHIERS UP", 0.75)

local function countBrokenCashiers()
    local broken = 0
    for _,v in pairs(Cashiers:GetChildren()) do 
        if v.Humanoid.Health <= 0 then
            broken = broken + 1
        end
    end
    return broken
end

local function updateDisplay()
    local currentCash = Player.DataFolder.Currency.Value
    local profit = currentCash - StartCash
    
    totalCashLabel.Text = "$"..tostring(currentCash):reverse():gsub("...","%0,",math.floor((#tostring(currentCash)-1)/3)):reverse()
    profitLabel.Text = "$"..tostring(profit):reverse():gsub("...","%0,",math.floor((#tostring(profit)-1)/3)):reverse()
    atmsBrokenLabel.Text = Broken
    timeLabel.Text = string.format("%02i:%02i:%02i", (os.time()-StartTick)/60^2, (os.time()-StartTick)/60%60, (os.time()-StartTick)%60)
    cycleLabel.Text = string.format("%02i:%02i", (os.time()-LastCycleTime)/60%60, (os.time()-LastCycleTime)%60)
    cashiersLabel.Text = #Cashiers:GetChildren() - countBrokenCashiers()
end

_G.Disable = function()
    Dis = true
    game:GetService("RunService"):Set3dRenderingEnabled(true)
    setfpscap(60)
    game:GetService("CoreGui").AutofarmStats:Destroy()
end

Player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
Player.CameraMaxZoomDistance = 6
Player.CameraMinZoomDistance = 6

pcall(function()
    local a=game:GetService("ReplicatedStorage").MainEvent
    local b={"CHECKER_1","TeleportDetect","OneMoreTime"}
    local c
    c=hookmetamethod(game,"__namecall",function(...)
        local d={...}
        local self=d[1]
        local e=getnamecallmethod()
        if e=="FireServer"and self==a and table.find(b,d[2])then 
            return 
        end 
        return c(...)
    end)
end)

local function CollectCash()
    local cashPiles = {}
    for _,v in pairs(Drop:GetChildren()) do 
        if v.Name == "MoneyDrop" then 
            local pos = v:GetAttribute("OriginalPos") or v.Position
            if (pos - Player.Character.HumanoidRootPart.Position).Magnitude <= 17 then 
                table.insert(cashPiles, v)
            end
        end
    end
    
    local collectedAny = false
    local input = game:GetService("VirtualInputManager")
    
    for _, money in pairs(cashPiles) do
        if money and money:FindFirstChild("ClickDetector") then
            -- Position money in front of player
            money.CFrame = (workspace.Camera.CFrame + workspace.Camera.CFrame.LookVector * 1) * CFrame.Angles(90, 0, 0)
            
            -- Click multiple times to ensure collection
            for i = 1, 3 do
                input:SendMouseButtonEvent(workspace.Camera.ViewportSize.X/2, workspace.Camera.ViewportSize.Y/2, 0, true, game, 1)
                task.wait(0.05)
                input:SendMouseButtonEvent(workspace.Camera.ViewportSize.X/2, workspace.Camera.ViewportSize.Y/2, 0, false, game, 1)
                task.wait(0.05)
                
                if not money.Parent then
                    collectedAny = true
                    break
                end
            end
        end
    end
    
    if collectedAny then
        updateDisplay()
    end
    return collectedAny
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

local GetCashier = function()
    if os.time() - LastCycleTime >= 240 then
        LastCycleTime = os.time()
        for i,v in pairs(Cashiers:GetChildren()) do 
            if (i == 15) then 
                v:MoveTo(Vector3.new(-622.948, 24, -286.52))
                for x,z in pairs(v:GetChildren()) do 
                    if (z:IsA("Part")) or (z:IsA("BasePart")) then 
                        z.CanCollide = false 
                    end
                end
            elseif (i == 16) then
                v:MoveTo(Vector3.new(-629.948, 24, -286.52))
                for x,z in pairs(v:GetChildren()) do 
                    if (z:IsA("Part")) or (z:IsA("BasePart")) then 
                        z.CanCollide = false 
                    end
                end
            end
        end
    end
    
    for i,v in pairs(Cashiers:GetChildren()) do 
        if (v.Humanoid.Health > 0) then 
            return v 
        end
    end
    return nil
end

local To = function(CF)
    Player.Character.HumanoidRootPart.CFrame = CF 
    Player.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
end

task.spawn(function()
    while true and task.wait() do 
        if (Player.Character == nil) or (Player.Character:FindFirstChild("FULLY_LOADED_CHAR") == nil) or (Dis == true) then 
            return print("NO")
        end
        
        local Cashier = nil
        repeat 
            Cashier = GetCashier()

            if (Player.Backpack:FindFirstChild("Combat") ~= nil) then 
                Player.Backpack.Combat.Parent = Player.Character 
            end

            task.wait()
        until (Cashier ~= nil)
        
        local punchStart = os.time()
        local lastCashCheck = 0
        local actuallyBroken = false
        
        -- Phase 1: Break the ATM
        repeat 
            -- Position and punch
            To((Cashier.Head.CFrame + Vector3.new(0, -2.5, 0)) * CFrame.Angles(math.rad(90), 0, 0))
            Player.Character.Combat:Activate()
            
            -- Check for cash every 1 second
            if os.time() - lastCashCheck > 1 then
                CollectCash()
                lastCashCheck = os.time()
            end
            
            task.wait(0.1)
            
            -- Check if ATM is actually broken
            if Cashier.Humanoid.Health <= 0 then
                actuallyBroken = true
                Broken += 1
                atmsBrokenLabel.Text = Broken
                break
            end
            
            -- Move on if stuck for 5 seconds (regardless of whether it's "broken" in UI)
            if os.time() - punchStart > 5 then
                warn("Moving to next ATM - stuck for 5 seconds")
                break
            end
        until false
        
        -- Phase 2: Collect money if actually broken
        if actuallyBroken then
            To(Cashier.Head.CFrame + Cashier.Head.CFrame.LookVector * Vector3.new(0, 2, 0))
            
            -- Put away combat tool
            for _,v in pairs(Player.Character:GetChildren()) do 
                if v:IsA("Tool") then 
                    v.Parent = Player.Backpack 
                end
            end
            
            -- Dedicated collection with 3 attempts
            for i = 1, 3 do
                if CollectCash() then break end
                task.wait(0.5)
            end
        end
        
        updateDisplay()
    end
end)

-- Background updates
task.spawn(function()
    while true and task.wait(1) do
        updateDisplay()
    end
end)

Player.Idled:Connect(function()
    for i = 1, 10 do 
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame) 
        task.wait(0.2) 
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.2)
    end
end)

pcall(function() UserSettings().GameSettings.MasterVolume = 0 end)
pcall(function() settings().Rendering.QualityLevel = "Level01" end)

Player.CharacterAdded:Connect(AntiSit)
task.spawn(function()
    task.wait(3)
    AntiSit(Player.Character)
end)

for i = 1, 10 do 
    setfpscap(_G.AutofarmSettings.Fps)
    task.wait(0.1)
end

if (_G.AutofarmSettings.Saver == true) then 
    game:GetService("RunService"):Set3dRenderingEnabled(false) 
else 
    Background.Visible = false
end
