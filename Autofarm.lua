if (not game:IsLoaded()) then 
    game.Loaded:Wait()
    task.wait(1)
end
-- Default settings
local Settings = {
    Fps = 30,
    Saver = true,
    WebhookEnabled = false,
    WebhookInterval = 900, -- Default 15 minutes in seconds
    WebhookUrl = ""
}

-- Merge user settings with defaults
if _G.AutofarmSettings then
    for k,v in pairs(_G.AutofarmSettings) do
        if string.lower(k) == "webhooktime" then
            Settings.WebhookInterval = v * 60 -- Convert minutes to seconds
        elseif string.lower(k) == "webhookurl" then
            Settings.WebhookUrl = v
            Settings.WebhookEnabled = v ~= nil and v ~= ""
        else
            Settings[k] = v
        end
    end
end

_G.AutofarmSettings = Settings -- Make merged settings available globally

if not game:IsLoaded() then 
    game.Loaded:Wait()
    task.wait(1)
end

repeat task.wait(0.1) until (game:GetService("Players").LocalPlayer) and (game:GetService("Players").LocalPlayer.Character)

-- UI Setup
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

-- Variables
local Player = game:GetService("Players").LocalPlayer
local Cashiers = workspace.Cashiers 
local Drop = workspace.Ignored.Drop
local Dis = false
local Broken = 0 
local StartTick = os.time()
local LastCycleTime = os.time()
local CycleCount = 0
local LastWebhookTime = os.time()
local StartCash = Player.DataFolder.Currency.Value

-- Functions
_G.Disable = function()
    Dis = true
    game:GetService("RunService"):Set3dRenderingEnabled(true)
    setfpscap(60)
    game:GetService("CoreGui").abcdefg:Destroy()
end

local function SendWebhook()
    if not _G.AutofarmSettings.WebhookEnabled or _G.AutofarmSettings.WebhookUrl == "" then 
        warn("Webhook not enabled or URL not set")
        return 
    end
    
    local currentCash = Player.DataFolder.Currency.Value
    local profit = currentCash - StartCash
    local profitPercent = (profit / math.max(StartCash, 1)) * 100
    
    local embed = {
        {
            ["title"] = "💰 AutoFarm Update - " .. Player.Name,
            ["description"] = string.format("Current farming session statistics"),
            ["color"] = 65280, -- Green color
            ["fields"] = {
                {
                    ["name"] = "Current Cash",
                    ["value"] = "$"..tostring(currentCash):reverse():gsub("...","%0,",math.floor((#tostring(currentCash)-1)/3)):reverse(),
                    ["inline"] = true
                },
                {
                    ["name"] = "Profit",
                    ["value"] = "$"..tostring(profit):reverse():gsub("...","%0,",math.floor((#tostring(profit)-1)/3)):reverse()..string.format(" (%.2f%%)", profitPercent),
                    ["inline"] = true
                },
                {
                    ["name"] = "ATMs Broken",
                    ["value"] = Broken,
                    ["inline"] = true
                },
                {
                    ["name"] = "Cycles Completed",
                    ["value"] = CycleCount,
                    ["inline"] = true
                },
                {
                    ["name"] = "Session Duration",
                    ["value"] = string.format("%02i:%02i:%02i", (os.time()-StartTick)/60^2, (os.time()-StartTick)/60%60, (os.time()-StartTick)%60),
                    ["inline"] = true
                },
                {
                    ["name"] = "Time Since Last Cycle",
                    ["value"] = string.format("%02i:%02i", (os.time()-LastCycleTime)/60%60, (os.time()-LastCycleTime)%60),
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }
    
    local data = {
        ["embeds"] = embed,
        ["username"] = "AutoFarm Notifier",
        ["avatar_url"] = "https://cdn.discordapp.com/attachments/123456789012345678/123456789012345678/money_bag.png"
    }
    
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    local success, response = pcall(function()
        return game:HttpGet(_G.AutofarmSettings.WebhookUrl, true, {
            Method = "POST",
            Headers = headers,
            Body = game:GetService("HttpService"):JSONEncode(data)
        })
    end)
    
    if not success then
        warn("Failed to send webhook:", response)
    else
        print("Webhook sent successfully")
    end
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

local GetCashier = function()
    -- Check if 4 minutes have passed to reset cashiers
    if os.time() - LastCycleTime >= 240 then -- 240 seconds = 4 minutes
        LastCycleTime = os.time()
        CycleCount = CycleCount + 1
        
        -- Reset cashiers to their original positions
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
        
        -- Send webhook notification if enabled and interval has passed
        if _G.AutofarmSettings.WebhookEnabled and os.time() - LastWebhookTime >= _G.AutofarmSettings.WebhookInterval then
            print("Attempting to send webhook...")
            LastWebhookTime = os.time()
            SendWebhook()
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

-- Main farming loop
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
        
        repeat 
            To( (Cashier.Head.CFrame+Vector3.new(0, -2.5, 0)) * CFrame.Angles(math.rad(90), 0, 0) ) 
            task.wait()
            Player.Character.Combat:Activate()
        until (Cashier.Humanoid.Health <= 0)
        Broken += 1

        To(Cashier.Head.CFrame + Cashier.Head.CFrame.LookVector * Vector3.new(0, 2, 0))

        for i,v in pairs(Player.Character:GetChildren()) do 
            if (v:IsA("Tool")) then 
                v.Parent = Player.Backpack 
            end
        end
        
        local Cash = GetCash()
        
        for i,v in pairs(Cash) do 
            Click(v)
        end
    end
end)

-- UI Update loop
task.spawn(function()
    while true and task.wait(0.5) do 
        local currentCash = Player.DataFolder.Currency.Value
        local profit = currentCash - StartCash
        local profitPercent = (profit / math.max(StartCash, 1)) * 100
        
        TL.Text = string.format([[
@%s
$%s
ATMs: %d
Cycles: %d
Session: %02i:%02i:%02i
Cycle: %02i:%02i
Profit: $%s (%.2f%%)]],
            Player.Name,
            tostring(currentCash):reverse():gsub("...","%0,",math.floor((#tostring(currentCash)-1)/3)):reverse(),
            Broken,
            CycleCount,
            (os.time()-StartTick)/60^2, (os.time()-StartTick)/60%60, (os.time()-StartTick)%60,
            (os.time()-LastCycleTime)/60%60, (os.time()-LastCycleTime)%60,
            tostring(profit):reverse():gsub("...","%0,",math.floor((#tostring(profit)-1)/3)):reverse(),
            profitPercent
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

-- Performance optimizations
pcall(function() UserSettings().GameSettings.MasterVolume = 0 end)
pcall(function() settings().Rendering.QualityLevel = "Level01" end)

-- Anti-sit
Player.CharacterAdded:Connect(AntiSit)
task.spawn(function()
    task.wait(3)
    AntiSit(Player.Character)
end)

-- FPS settings
for i = 1, 10 do 
    setfpscap(_G.AutofarmSettings.Fps)
    task.wait(0.1)
end

-- Power saver mode
if (_G.AutofarmSettings.Saver == true) then 
    game:GetService("RunService"):Set3dRenderingEnabled(false) 
else 
    SG.Enabled = false
end

-- Initial webhook notification
if _G.AutofarmSettings.WebhookEnabled then
    task.spawn(function()
        task.wait(5)
        print("Sending initial webhook...")
        SendWebhook()
    end)
end
