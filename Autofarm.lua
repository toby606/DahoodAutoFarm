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
local MAX_TIME_PER_CASHIER = 12 -- Seconds per cashier attempt
local VAULT_POSITION = CFrame.new(-726.49, -22.47, -243.32) -- Default vault position
local cashierBlacklist = {}
local StartCash = Player.DataFolder.Currency.Value
local LastCashUpdate = os.time()
local LastProfit = 0

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
        task.wait()
        Input:SendMouseButtonEvent(workspace.Camera.ViewportSize.X/2, workspace.Camera.ViewportSize.Y/2, 0, false, game, 1)
    until (Part == nil) or (Part:FindFirstChild("ClickDetector") == nil) or (os.time()-T>=2)
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
    
    for i,v in pairs(Drop:GetChildren()) do 
        if (v.Name == "MoneyDrop") then 
            local Pos = nil 
            
            if (v:GetAttribute("OriginalPos") ~= nil) then 
                Pos = v:GetAttribute("OriginalPos")
            else 
                Pos = v.Position
            end
            if (Pos - Player.Character.HumanoidRootPart.Position).Magnitude <= 17 then 
                Found[#Found+1] = v 
            end
        end
    end
    return Found
end

local ResetCashiers = function()
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
    CycleCount = CycleCount + 1
    LastCycleTime = os.time()
    cashierBlacklist = {}
    print("Cashiers reset - Cycle:", CycleCount)
end

local GetCashier = function()
    if os.time() - LastCycleTime >= 240 then
        ResetCashiers()
    end
    
    for i,v in pairs(Cashiers:GetChildren()) do 
        if (v.Humanoid.Health > 0) and not cashierBlacklist[v] then 
            return v 
        end
    end
    return nil
end

local To = function(CF)
    Player.Character.HumanoidRootPart.CFrame = CF 
    Player.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
end

local GoToVault = function()
    print("Going to vault")
    To(VAULT_POSITION)
    task.wait(3)
    cashierBlacklist = {}
end

-- Main farming loop
task.spawn(function()
    while true and task.wait() do 
        if (Player.Character == nil) or (Player.Character:FindFirstChild("FULLY_LOADED_CHAR") == nil) or (Dis == true) then 
            return print("Stopped: Missing character or disabled")
        end
        
        -- Equip combat tool
        if (Player.Backpack:FindFirstChild("Combat") ~= nil) then 
            Player.Backpack.Combat.Parent = Player.Character 
            task.wait(0.5)
        end

        local cashier = GetCashier()
        
        if not cashier then
            print("No available cashiers - going to vault")
            GoToVault()
            ResetCashiers()
            task.wait(5)
            continue
        end

        -- Mark cashier as attempted
        cashierBlacklist[cashier] = true
        local startTime = os.time()
        local success = false
        
        -- Attempt to break cashier with timeout
        while os.time() - startTime < MAX_TIME_PER_CASHIER do
            if cashier.Humanoid.Health <= 0 then
                success = true
                break
            end
            
            To((cashier.Head.CFrame + Vector3.new(0, -2.5, 0)) * CFrame.Angles(math.rad(90), 0, 0))
            if Player.Character:FindFirstChild("Combat") then
                Player.Character.Combat:Activate()
            end
            task.wait(0.1)
        end

        if success then
            Broken = Broken + 1
            print("Cashier broken - collecting money")
            
            -- Collect money drops
            local cashDrops = GetCash()
            for _, drop in pairs(cashDrops) do
                Click(drop)
                task.wait(0.2)
            end
        else
            print("Timeout on cashier - moving on")
        end

        -- Check if all cashiers attempted
        local allAttempted = true
        for _, c in pairs(Cashiers:GetChildren()) do
            if c.Humanoid.Health > 0 and not cashierBlacklist[c] then
                allAttempted = false
                break
            end
        end

        if allAttempted then
            print("All cashiers attempted - going to vault")
            GoToVault()
            ResetCashiers()
            task.wait(5)
        end
    end
end)

-- UI Update loop
task.spawn(function()
    while true and task.wait(0.5) do 
        if Dis then break end
        
        -- Force update the cash value
        local currentCash
        pcall(function()
            currentCash = Player.DataFolder.Currency.Value
            -- Update start cash if it's higher than current (in case of death)
            if StartCash > currentCash then
                StartCash = currentCash
            end
        end)
        
        if not currentCash then
            TL.Text = "Error reading cash value"
            task.wait(2)
            continue
        end

        local profit = currentCash - StartCash
        local elapsedTime = os.time() - StartTick
        
        -- Format numbers properly
        local function formatCurrency(amount)
            return string.format("%d", amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        end

        -- Update display
        TL.Text = string.format([[
@%s
Cash: $%s
ATMs: %d
Time: %02d:%02d:%02d
Profit: $%s (+$%s/min)
Cycle: %02d:%02d (%d)
Status: %s]],
            Player.Name,
            formatCurrency(currentCash),
            Broken,
            math.floor(elapsedTime/3600), math.floor(elapsedTime/60%60), elapsedTime%60,
            formatCurrency(profit),
            formatCurrency(math.floor((profit-LastProfit)/((os.time()-LastCashUpdate)/60))),
            math.floor((os.time()-LastCycleTime)/60), (os.time()-LastCycleTime)%60, CycleCount,
            next(cashierBlacklist) and "Farming" or "Resetting"
        )
        
        LastProfit = profit
        LastCashUpdate = os.time()
    end
end)

-- Manual reset keybind
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.R then
        ResetCashiers()
        GoToVault()
    end
end)
