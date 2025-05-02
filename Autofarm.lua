
-- Optimizations: FPS, rendering, volume, and quality
for i = 1, 10 do 
    setfpscap(tonumber(_G.AutofarmSettings.Fps))
    task.wait(0.1)
end

game:GetService("RunService"):Set3dRenderingEnabled(false)
pcall(function() UserSettings().GameSettings.MasterVolume = 0 end)
pcall(function() settings().Rendering.QualityLevel = "Level01" end)

-- Webhook logging
local SendLog = loadstring(game:HttpGet("https://github.com/applless/RandomScripts/raw/main/Webhookk"))()

task.spawn(function()
    while true and task.wait(_G.AutofarmSettings.Time * 60) do
        local s, e = pcall(function()
            SendLog(_G.AutofarmSettings.webhookUrl, {
                Player.Name, 
                Player.UserId, 
                WALLET.Text, 
                PROFIT.Text, 
                TIMER.Text, 
                BROKEN.Text, 
                "| iku autofarm by @trans"
            })
        end)
        if (e) then 
            Log("Error while sending log:\n"..tostring(e).."\n")
        end
    end
end)

-- Function to stop autofarming
_G.Disable = function()
    Dis = true
    game:GetService("RunService"):Set3dRenderingEnabled(true)
    setfpscap(60)
    game:GetService("CoreGui").abcdefg:Destroy()
end

-- Knife buying and usage (from previous code)
local Attack = function()
    local Mode = tonumber(_G.AutofarmSettings.AttackMode)
    if (Mode == nil) then
        return Log("INVALID ATTACK METHOD!!!")
    end
    
    -- Knife attack mode (Mode 3)
    if (Mode == 3) then
        if (Player.DataFolder.Currency.Value < 200) then 
            task.spawn(function()
                EMPTY.Text = "| Not enough dhc."
                task.wait(10)
                EMPTY.Text = "|"
            end)
            return Log("nigga how are you that broke that you cant afford to buy a knife lol.")
        end
        
        -- Buy knife if needed
        if (Player.Backpack:FindFirstChild("[Knife]") == nil) and (Player.Character:FindFirstChild("[Knife]") == nil) then 
            Log("buying knife.")
            EMPTY.Text = "| Buying knife."
            repeat 
                local KnifeBuy = workspace.Ignored.Shop["[Knife] - $159"]
                Player.Character.HumanoidRootPart.CFrame = KnifeBuy.Head.CFrame + Vector3.new(0, 3.2, 0)
                task.wait(0.2)
                fireclickdetector(KnifeBuy.ClickDetector)
            until (Player.Backpack:FindFirstChild("[Knife]")) or (Player.Character:FindFirstChild("[Knife]")) or (Shutdown == true)
            EMPTY.Text = "|"
        end
        
        -- Equip knife
        if (Player.Backpack:FindFirstChild("[Knife]")) then 
            task.wait(0.66)
            pcall(function()
                Player.Backpack["[Knife]"].Parent = Player.Character
            end)
        end
        
        -- Use knife
        local Knife = Player.Character:FindFirstChild("[Knife]")
        if (Knife == nil) then return Log("no knife tool found.") end
        Knife:Activate()
        task.wait(0.1)
    end
end

-- Main loop for attacking and collecting cash
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
        
        -- Perform knife attack on cashiers
        Attack()
        
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

-- Update UI with relevant stats
local StartCash = Player.DataFolder.Currency.Value
task.spawn(function()
    while true and task.wait(0.5) do 
        print(TL.Text)
        TL.Text = "\n@"..Player.Name.."\n$"..tostring(Player.DataFolder.Currency.Value):reverse():gsub("...","%0,",math.floor((#tostring(Player.DataFolder.Currency.Value)-1)/3)):reverse().."\nATMS: "..tostring(Broken).."\n"..string.format("%02i:%02i:%02i", (os.time()-StartTick)/60^2, (os.time()-StartTick)/60%60, (os.time()-StartTick)%60).."\nProfit: $"..tostring(Player.DataFolder.Currency.Value-StartCash):reverse():gsub("...","%0,",math.floor((#tostring(Player.DataFolder.Currency.Value-StartCash)-1)/3)):reverse().."\nCycle: "..string.format("%02i:%02i", (os.time()-LastCycleTime)/60%60, (os.time()-LastCycleTime)%60).."\n"..tostring(GetCashier()).."   "
    end
end)

-- Idle prevention
Player.Idled:Connect(function()
    for i = 1, 10 do 
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame) 
        task.wait(0.2) 
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.2)
    end
end)

-- Master volume and rendering settings
pcall(function() UserSettings().GameSettings.MasterVolume = 0 end)
pcall(function() settings().Rendering.QualityLevel = "Level01" end)

Player.CharacterAdded:Connect(AntiSit)
task.spawn(function()
    task.wait(3)
    AntiSit(Player.Character)
end)

if (_G.AutofarmSettings.Saver == true) then 
    game:GetService("RunService"):Set3dRenderingEnabled(false) 
else 
    SG.Enabled = false
end
