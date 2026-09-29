-- wertlaider beta v0.3
-- Slop TD hub

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local HS = game:GetService("HttpService")
local VIM = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer
local pg = LP:WaitForChild("PlayerGui")

local ICON_ID = "rbxassetid://130176754065007"

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local W = {
    AntimacroOn = false, AntimacroMin = 0.4, AntimacroMax = 1.0,
    AutoPlaceOn = false, PlaceDelay = 4.0, PlaceRandom = 40,
    AutoUpgradeOn = false, UpgradeDelay = 8.0,
    AutoSkipOn = false, AutoSpeedOn = false, SpeedValue = 5,
    WebhookURL = "", WebhookOn = false,
    Running = true, PlaceAttempt = 0,
    LastPlace = 0, LastUpgrade = 0, LastSkip = 0, LastSpeed = 0,
    AntiBusy = false, AntiToken = nil, AntiTokenAt = 0,
}

local R = {}
local function refreshRemotes()
    local fn = RS:FindFirstChild("Functions")
    local ev = RS:FindFirstChild("Events")
    local rm = RS:FindFirstChild("Remotes")
    R.Request     = fn and fn:FindFirstChild("RequestTower")
    R.Spawn       = fn and fn:FindFirstChild("SpawnTower")
    R.Upgrade     = fn and fn:FindFirstChild("UpgradeTower")
    R.Sell        = fn and fn:FindFirstChild("SellTower")
    R.VoteSkip    = fn and fn:FindFirstChild("VoteSkip")
    R.ChangeSpeed = fn and fn:FindFirstChild("ChangeSpeed")
    R.GetPlace    = fn and fn:FindFirstChild("GetPlayerPlacement")
    R.GetData     = rm and rm:FindFirstChild("PlayerData") and rm.PlayerData:FindFirstChild("GetData")
    local am = ev and ev:FindFirstChild("AntiMacro")
    R.AMCheck   = am and am:FindFirstChild("Check")
    R.AMRespond = am and am:FindFirstChild("Respond")
end
refreshRemotes()

local function rand(base, pct)
    if pct <= 0 then return base end
    local spread = base * (pct / 100)
    return base - spread * 0.5 + math.random() * spread
end

local function log(s)
    pcall(function()
        appendfile("wertlaider_log.txt", "[" .. os.date("!%H:%M:%S") .. "] " .. tostring(s) .. "\n")
    end)
end

local function getWave()
    local info = WS:FindFirstChild("Info")
    local w = info and info:FindFirstChild("Wave")
    return w and tonumber(w.Value) or 0
end

local function getCash()
    local c = LP:FindFirstChild("Cash")
    return c and tonumber(c.Value) or 0
end

local function isRunning()
    local info = WS:FindFirstChild("Info")
    local g = info and info:FindFirstChild("GameRunning")
    return g and g.Value == true
end

local function getSpeed()
    local info = WS:FindFirstChild("Info")
    local s = info and info:FindFirstChild("SpeedGame")
    return s and tonumber(s.Value) or 1
end

local function getMyTowers()
    local out = {}
    local tws = WS:FindFirstChild("Towers")
    if not tws then return out end
    for _, t in ipairs(tws:GetChildren()) do
        local cfg = t:FindFirstChild("Config")
        local owner = cfg and cfg:FindFirstChild("Owner")
        if owner and tostring(owner.Value) == LP.Name then
            table.insert(out, t)
        end
    end
    return out
end

local function getEquipped()
    local out = {}
    if not R.GetData then return out end
    local ok, data = pcall(function() return R.GetData:InvokeServer() end)
    if not ok or type(data) ~= "table" or type(data.Towers) ~= "table" then return out end
    for name, info in pairs(data.Towers) do
        if type(info) == "table" then
            local slot = tonumber(info.Equipped)
            if slot and slot >= 1 and slot <= 6 then
                out[slot] = { variant = tostring(name), base = tostring(info.Name or name) }
            end
        end
    end
    return out
end

local function towerName(t) return tostring(t.Name) end
local function towerLevel(t)
    local cfg = t:FindFirstChild("Config")
    local lvl = cfg and cfg:FindFirstChild("LVL")
    return lvl and tonumber(lvl.Value) or 0
end

-- ANTIMACRO
local function extractUUID(v, depth)
    depth = (depth or 0) + 1
    if depth > 4 then return nil end
    if type(v) == "string" then
        if v:match("^[%x]+%-%x+%-%x+%-%x+%-%x+$") then return v end
        return nil
    end
    if type(v) == "table" then
        for _, c in pairs(v) do
            local r = extractUUID(c, depth)
            if r then return r end
        end
    end
    return nil
end

local function findAmButton()
    local am = pg:FindFirstChild("AntiMacroCheck")
    if not am then return nil end
    local frame = am:FindFirstChild("Frame")
    local btn = frame and frame:FindFirstChild("TextButton")
    if btn and btn:IsA("GuiButton") then return btn end
    for _, v in ipairs(am:GetDescendants()) do
        if v:IsA("GuiButton") then
            local t = tostring(v.Text):lower():gsub("[^%a]", "")
            if t == "imhere" or t == "яздесь" then return v end
        end
    end
    return nil
end

local function pressButton(btn)
    if not btn then return false end
    if type(firesignal) == "function" then
        local ev = btn.MouseButton1Click
        if type(getconnections) == "function" then
            local conns = getconnections(ev)
            if #conns == 0 then ev = btn.Activated end
        end
        if pcall(firesignal, ev) then return true end
    end
    if type(getconnections) == "function" then
        local conns = getconnections(btn.MouseButton1Click)
        if #conns == 0 then conns = getconnections(btn.Activated) end
        local ok = false
        for _, c in ipairs(conns) do
            if type(c.Fire) == "function" then ok = pcall(c.Fire, c) or ok
            elseif type(c.Function) == "function" then ok = pcall(c.Function) or ok end
        end
        if ok then return true end
    end
    local x = btn.AbsolutePosition.X + btn.AbsoluteSize.X * 0.5
    local y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y * 0.5
    pcall(function()
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
    return true
end

if R.AMCheck then
    R.AMCheck.OnClientEvent:Connect(function(...)
        local uuid = extractUUID(table.pack(...))
        if uuid then
            W.AntiToken = uuid
            W.AntiTokenAt = os.clock()
        end
    end)
end

task.spawn(function()
    while W.Running do
        task.wait(0.2)
        if W.AntimacroOn and not W.AntiBusy then
            local t = W.AntiToken
            local btn = findAmButton()
            if t and (os.clock() - W.AntiTokenAt) > 35 then
                W.AntiToken = nil
                t = nil
            end
            if t and btn and R.AMRespond then
                W.AntiBusy = true
                local d = W.AntimacroMin + math.random() * (W.AntimacroMax - W.AntimacroMin)
                task.wait(d)
                if W.AntiToken == t then
                    pcall(function() R.AMRespond:FireServer(t) end)
                    W.AntiToken = nil
                    log("AntiMacro: Respond " .. t:sub(1,8))
                end
                W.AntiBusy = false
            elseif btn then
                pressButton(btn)
                log("AntiMacro: fallback tap")
                task.wait(1)
            end
        end
    end
end)

-- AUTOPLACE
local function placeOne()
    if not R.GetPlace or not R.Spawn then return false, "no remote" end
    local ok, points = pcall(function() return R.GetPlace:InvokeServer() end)
    if not ok or type(points) ~= "table" or #points == 0 then return false, "no points" end
    local equipped = getEquipped()
    local idx = 0
    for slot = 1, 6 do if equipped[slot] then idx = slot; break end end
    if idx == 0 then return false, "no equipped" end
    local eq = equipped[idx]
    local pt = points[math.random(1, #points)]
    local pos = pt.Position or pt
    pcall(function() R.Request:InvokeServer({eq.variant, eq.base}, false, true) end)
    task.wait(0.05)
    local cf = CFrame.new(pos + Vector3.new((math.random() - 0.5) * 0.6, 0, (math.random() - 0.5) * 0.6))
    local ok2 = pcall(function() return R.Spawn:InvokeServer(eq.base, cf, false, eq.variant, {}) end)
    if not ok2 then return false, "invoke fail" end
    W.PlaceAttempt = W.PlaceAttempt + 1
    return true
end

task.spawn(function()
    while W.Running do
        task.wait(0.3)
        if W.AutoPlaceOn and isRunning() and not W.AntiBusy then
            local now = os.clock()
            local wait = rand(W.PlaceDelay, W.PlaceRandom)
            if now - W.LastPlace >= wait then
                W.LastPlace = now
                local ok, err = placeOne()
                if ok then log("AutoPlace ok") else log("AutoPlace: " .. tostring(err)) end
            end
        end
    end
end)

task.spawn(function()
    while W.Running do
        task.wait(0.3)
        if W.AutoUpgradeOn and isRunning() then
            local now = os.clock()
            local wait = rand(W.UpgradeDelay, W.PlaceRandom)
            if now - W.LastUpgrade >= wait then
                W.LastUpgrade = now
                local towers = getMyTowers()
                if #towers > 0 then
                    table.sort(towers, function(a, b) return towerLevel(a) < towerLevel(b) end)
                    local t = towers[1]
                    if t and t.Parent and R.Upgrade then
                        pcall(function() R.Upgrade:InvokeServer(t, towerName(t)) end)
                        log("AutoUpgrade " .. towerName(t) .. " lvl=" .. towerLevel(t))
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while W.Running do
        task.wait(1)
        if W.AutoSkipOn and isRunning() and R.VoteSkip then
            if os.clock() - W.LastSkip > 3 then
                W.LastSkip = os.clock()
                pcall(function() R.VoteSkip:InvokeServer() end)
            end
        end
        if W.AutoSpeedOn and isRunning() and R.ChangeSpeed then
            if getSpeed() ~= W.SpeedValue and os.clock() - W.LastSpeed > 2 then
                W.LastSpeed = os.clock()
                pcall(function() R.ChangeSpeed:InvokeServer(W.SpeedValue) end)
            end
        end
    end
end)

local function sendDiscord(full)
    if not W.WebhookOn or W.WebhookURL == "" then return false, "off" end
    if not (type(request) == "function") then return false, "no request" end
    local cash, gems, stars = getCash(), 0, 0
    local leaderstats = LP:FindFirstChild("leaderstats")
    if leaderstats then
        local g = leaderstats:FindFirstChild("Gems")
        local s = leaderstats:FindFirstChild("Stars")
        if g then gems = tonumber(g.Value) or 0 end
        if s then stars = tonumber(s.Value) or 0 end
    end
    local towers = #getMyTowers()
    local fields = {
        { name = "Cash",  value = tostring(cash),  inline = true },
        { name = "Gems",  value = tostring(gems),  inline = true },
        { name = "Stars", value = tostring(stars), inline = true },
        { name = "Wave",  value = tostring(getWave()), inline = true },
    }
    if full then
        table.insert(fields, { name = "Towers", value = tostring(towers), inline = true })
        table.insert(fields, { name = "PlaceId", value = tostring(game.PlaceId), inline = false })
    end
    local payload = {
        username = "wertlaider",
        embeds = {{
            title = "wertlaider · " .. LP.Name,
            description = "`" .. LP.DisplayName .. "` · `" .. LP.UserId .. "`",
            color = 0x3C8CFF,
            fields = fields,
            footer = { text = "wertlaider beta" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }},
    }
    local ok = pcall(function()
        request({ Url = W.WebhookURL, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HS:JSONEncode(payload) })
    end)
    return ok
end

-- UI
local Window = Rayfield:CreateWindow({
    Name = "wertlaider",
    LoadingTitle = "wertlaider beta",
    LoadingSubtitle = "Slop TD · v0.3",
    ConfigurationSaving = { Enabled = true, FolderName = "wertlaider", FileName = "config" },
    KeySystem = false,
})

local T1 = Window:CreateTab("Anti-Macro", 4483362458)
T1:CreateToggle({Name = "Auto Anti-Macro", CurrentValue = false, Flag = "am_on", Callback = function(v) W.AntimacroOn = v end})
T1:CreateSlider({Name = "Задержка min (сек)", Range = {0.1, 5.0}, Increment = 0.1, Suffix = "s", CurrentValue = 0.4, Flag = "am_min", Callback = function(v) W.AntimacroMin = v end})
T1:CreateSlider({Name = "Задержка max (сек)", Range = {0.2, 8.0}, Increment = 0.1, Suffix = "s", CurrentValue = 1.0, Flag = "am_max", Callback = function(v) W.AntimacroMax = v end})
T1:CreateParagraph({Title = "Anti-Macro", Content = "Check → UUID → Respond 0.4-1.0с. Fallback: тап."})

local T2 = Window:CreateTab("Auto Place", 4483362458)
T2:CreateToggle({Name = "Auto Place", CurrentValue = false, Flag = "ap_on", Callback = function(v) W.AutoPlaceOn = v end})
T2:CreateSlider({Name = "Задержка между башнями", Range = {1.0, 20.0}, Increment = 0.5, Suffix = "s", CurrentValue = 4.0, Flag = "ap_delay", Callback = function(v) W.PlaceDelay = v end})
T2:CreateSlider({Name = "Рандомизация %", Range = {0, 100}, Increment = 5, Suffix = "%", CurrentValue = 40, Flag = "ap_rand", Callback = function(v) W.PlaceRandom = v end})
T2:CreateParagraph({Title = "Как работает", Content = "GetPlayerPlacement → точки. Спавн + рандом + сдвиг ±0.3 studs."})

local T3 = Window:CreateTab("Auto Upgrade", 4483362458)
T3:CreateToggle({Name = "Auto Upgrade", CurrentValue = false, Flag = "au_on", Callback = function(v) W.AutoUpgradeOn = v end})
T3:CreateSlider({Name = "Задержка", Range = {1.0, 30.0}, Increment = 0.5, Suffix = "s", CurrentValue = 8.0, Flag = "au_delay", Callback = function(v) W.UpgradeDelay = v end})
T3:CreateParagraph({Title = "Как работает", Content = "Скан своих башен → сортировка → апгрейд самой слабой."})

local T4 = Window:CreateTab("Skip / Speed", 4483362458)
T4:CreateToggle({Name = "Auto Skip Wave", CurrentValue = false, Flag = "as_on", Callback = function(v) W.AutoSkipOn = v end})
T4:CreateToggle({Name = "Auto Speed", CurrentValue = false, Flag = "asp_on", Callback = function(v) W.AutoSpeedOn = v end})
T4:CreateSlider({Name = "Speed Value", Range = {1, 5}, Increment = 1, Suffix = "x", CurrentValue = 5, Flag = "asp_val", Callback = function(v) W.SpeedValue = v end})

local T5 = Window:CreateTab("Discord", 4483362458)
T5:CreateInput({Name = "Webhook URL", PlaceholderText = "https://discord.com/api/webhooks/...", CurrentValue = "", Flag = "wh_url", Callback = function(v) W.WebhookURL = v end})
T5:CreateToggle({Name = "Enable Webhook", CurrentValue = false, Flag = "wh_on", Callback = function(v) W.WebhookOn = v end})
T5:CreateButton({Name = "SEND NOW (валюта)", Callback = function()
    local ok, err = sendDiscord(false)
    if ok then Rayfield:Notify({Title = "wertlaider", Content = "Отправлено", Duration = 2})
    else Rayfield:Notify({Title = "wertlaider", Content = "Ошибка: " .. tostring(err), Duration = 3}) end
end})
T5:CreateButton({Name = "SEND FULL (валюта + башни)", Callback = function()
    local ok, err = sendDiscord(true)
    if ok then Rayfield:Notify({Title = "wertlaider", Content = "Full отчёт", Duration = 2})
    else Rayfield:Notify({Title = "wertlaider", Content = "Ошибка: " .. tostring(err), Duration = 3}) end
end})

local T6 = Window:CreateTab("Info", 4483362458)
T6:CreateParagraph({Title = "wertlaider beta v0.3", Content = "Свой хаб для Slop TD.\nAntiMacro + AutoPlace + AutoUpgrade + Skip/Speed + Discord."})
T6:CreateParagraph({Title = "Скоро", Content = "AutoSell · AutoAbility · AutoVote · AutoLobby · AutoSummon · AutoCrate · FPS Boost · BlackScreen · HideName · WalkAround"})

-- FLOATING BUTTON (без контура)
local floatGui = Instance.new("ScreenGui")
floatGui.Name = "wertlaider_btn"
floatGui.ResetOnSpawn = false
floatGui.IgnoreGuiInset = true
floatGui.DisplayOrder = 9999
floatGui.Parent = (gethui and gethui()) or pg

local btn = Instance.new("ImageButton")
btn.Name = "ww"
btn.Size = UDim2.new(0, 58, 0, 58)
btn.Position = UDim2.new(0, 22, 0, 120)
btn.BackgroundTransparency = 1
btn.Image = ICON_ID
btn.ScaleType = Enum.ScaleType.Fit
btn.ZIndex = 9000
btn.Parent = floatGui
Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

local dragging, moved, d0, p0 = false, false, nil, nil
btn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        moved = false
        d0 = i.Position
        p0 = btn.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
btn.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - d0
        if d.Magnitude > 8 then
            moved = true
            btn.Position = UDim2.new(0, p0.X.Offset + d.X, 0, p0.Y.Offset + d.Y)
        end
    end
end)
btn.MouseButton1Click:Connect(function()
    if moved then return end
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game)
    end)
end)

log("wertlaider beta v0.3 loaded")
Rayfield:Notify({ Title = "wertlaider", Content = "v0.3 загружен", Duration = 3 })
