local P = game:GetService("Players")
local T = game:GetService("TweenService")
local LP = P.LocalPlayer
local pg = LP:WaitForChild("PlayerGui")
local ICON = "rbxassetid://130176754065007"

local C = {
    bg = Color3.fromRGB(18,20,26), side = Color3.fromRGB(22,25,32),
    panel = Color3.fromRGB(28,32,42), ac = Color3.fromRGB(60,140,255),
    tx = Color3.fromRGB(235,238,245), dim = Color3.fromRGB(140,148,168),
    line = Color3.fromRGB(46,52,66),
}

local gui = Instance.new("ScreenGui")
gui.Name = "wertlaider"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.Parent = (gethui and gethui()) or pg

local icon = Instance.new("ImageButton")
icon.Size = UDim2.new(0,58,0,58)
icon.Position = UDim2.new(0,22,0,120)
icon.BackgroundTransparency = 1
icon.Image = ICON
icon.ScaleType = Enum.ScaleType.Fit
icon.ZIndex = 9000
icon.Parent = gui

local W, H = 380, 300

local win = Instance.new("Frame")
win.AnchorPoint = Vector2.new(0, 0)
win.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
win.Size = UDim2.new(0, 0, 0, 0)
win.BackgroundColor3 = C.bg
win.BorderSizePixel = 0
win.ClipsDescendants = true
win.Visible = false
win.ZIndex = 100
win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 12)
local st = Instance.new("UIStroke", win); st.Color = C.ac; st.Thickness = 2

local head = Instance.new("Frame")
head.Size = UDim2.new(1,0,0,36)
head.BackgroundColor3 = C.panel
head.BorderSizePixel = 0
head.ZIndex = 2
head.Parent = win
Instance.new("UICorner", head).CornerRadius = UDim.new(0, 12)
local hf = Instance.new("Frame")
hf.Size = UDim2.new(1,0,0,12); hf.Position = UDim2.new(0,0,1,-12)
hf.BackgroundColor3 = C.panel; hf.BorderSizePixel = 0; hf.ZIndex = 2; hf.Parent = head

local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(1,-50,1,0); ttl.Position = UDim2.new(0,14,0,0)
ttl.BackgroundTransparency = 1
ttl.Text = "wertlaider"
ttl.TextColor3 = C.tx
ttl.Font = Enum.Font.GothamBold
ttl.TextSize = 14
ttl.TextXAlignment = Enum.TextXAlignment.Left
ttl.ZIndex = 3
ttl.Parent = head

local close = Instance.new("TextButton")
close.Size = UDim2.new(0,24,0,22); close.Position = UDim2.new(1,-30,0,7)
close.BackgroundColor3 = C.panel; close.Text = "×"
close.TextColor3 = C.tx; close.Font = Enum.Font.GothamBold
close.TextSize = 16; close.BorderSizePixel = 0; close.ZIndex = 3; close.Parent = head
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

local side = Instance.new("Frame")
side.Size = UDim2.new(0,110,1,-48); side.Position = UDim2.new(0,8,0,42)
side.BackgroundColor3 = C.side; side.BorderSizePixel = 0; side.ZIndex = 2; side.Parent = win
Instance.new("UICorner", side).CornerRadius = UDim.new(0, 9)
local sl = Instance.new("UIListLayout", side); sl.Padding = UDim.new(0,2); sl.SortOrder = Enum.SortOrder.LayoutOrder
local sp = Instance.new("UIPadding", side)
sp.PaddingTop = UDim.new(0,6); sp.PaddingBottom = UDim.new(0,6)
sp.PaddingLeft = UDim.new(0,5); sp.PaddingRight = UDim.new(0,5)

local content = Instance.new("Frame")
content.Size = UDim2.new(1,-130,1,-48); content.Position = UDim2.new(0,126,0,42)
content.BackgroundTransparency = 1; content.ZIndex = 1; content.Parent = win

local pages, tabs = {}, {}
local function newPage(n)
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0
    p.ScrollBarThickness = 3; p.ScrollBarImageColor3 = C.ac
    p.CanvasSize = UDim2.new(0,0,0,0); p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Visible = false; p.Parent = content
    local l = Instance.new("UIListLayout", p)
    l.Padding = UDim.new(0,5); l.SortOrder = Enum.SortOrder.LayoutOrder
    local pd = Instance.new("UIPadding", p)
    pd.PaddingTop = UDim.new(0,4); pd.PaddingRight = UDim.new(0,4)
    pages[n] = p
    return p
end

local o = 0
local function ord() o = o + 1; return o end

local function sec(txt, p)
    local r = Instance.new("TextLabel")
    r.Size = UDim2.new(1,0,0,18); r.BackgroundTransparency = 1
    r.Text = txt; r.TextColor3 = C.ac; r.Font = Enum.Font.GothamBold
    r.TextSize = 10; r.TextXAlignment = Enum.TextXAlignment.Left
    r.LayoutOrder = ord(); r.Parent = p
end

local function div(p)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1,0,0,5); r.BackgroundTransparency = 1
    r.LayoutOrder = ord(); r.Parent = p
    local ln = Instance.new("Frame", r)
    ln.Size = UDim2.new(1,0,0,1); ln.Position = UDim2.new(0,0,0,2)
    ln.BackgroundColor3 = C.line; ln.BorderSizePixel = 0
end

local function sh(title, desc, p)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1,0,0,38); r.BackgroundColor3 = C.panel
    r.BorderSizePixel = 0; r.LayoutOrder = ord(); r.Parent = p
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 8)
    local b = Instance.new("Frame", r)
    b.Size = UDim2.new(0,3,1,-12); b.Position = UDim2.new(0,6,0,6)
    b.BackgroundColor3 = C.ac; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    local t = Instance.new("TextLabel", r)
    t.Size = UDim2.new(1,-24,0,14); t.Position = UDim2.new(0,16,0,4)
    t.BackgroundTransparency = 1; t.Text = title; t.TextColor3 = C.tx
    t.Font = Enum.Font.GothamBold; t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    local d = Instance.new("TextLabel", r)
    d.Size = UDim2.new(1,-24,0,14); d.Position = UDim2.new(0,16,0,20)
    d.BackgroundTransparency = 1; d.Text = desc or ""; d.TextColor3 = C.dim
    d.Font = Enum.Font.Gotham; d.TextSize = 10
    d.TextXAlignment = Enum.TextXAlignment.Left
end

local function addTab(name, label)
    local p = newPage(name)
    local b = Instance.new("TextButton", side)
    b.Size = UDim2.new(1,0,0,28); b.BackgroundColor3 = C.side
    b.Text = label; b.TextColor3 = C.dim; b.Font = Enum.Font.GothamBold
    b.TextSize = 11; b.TextXAlignment = Enum.TextXAlignment.Left
    b.BorderSizePixel = 0; b.LayoutOrder = #tabs + 1
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 8)
    b.MouseButton1Click:Connect(function()
        for n, p2 in pairs(pages) do p2.Visible = (n == name) end
        for n, b2 in pairs(tabs) do
            b2.BackgroundColor3 = (n == name) and C.ac or C.side
            b2.TextColor3 = (n == name) and C.tx or C.dim
        end
    end)
    tabs[name] = b
    return p
end

local pM = addTab("Macros", "Macros")
sec("MACRO", pM); sh("Record", "запись", pM); sh("Playback", "проигрывание", pM)
div(pM); sec("PROFILE", pM); sh("Load", "загрузить", pM); sh("Save", "сохранить", pM)

local pL = addTab("Lobby", "Lobby")
sec("LOBBY", pL); sh("Auto Lobby", "вход в лифт", pL); sh("Auto Summon", "призыв", pL)
div(pL); sec("CRATES", pL); sh("Buy Crate", "покупка", pL); sh("Open Crate", "открытие", pL)

local pMt = addTab("Match", "Match")
sec("TOWERS", pMt); sh("Auto Place", "постановка", pMt); sh("Auto Upgrade", "апгрейд", pMt); sh("Auto Sell", "продажа", pMt)
div(pMt); sec("ABILITY", pMt); sh("Auto Ability", "абилки", pMt)

local pC = addTab("Control", "Control")
sec("CONTROL", pC); sh("Auto Skip", "скип волн", pC); sh("Auto Speed", "x1 - x5", pC); sh("Auto Vote", "голос", pC)
div(pC); sec("SAFETY", pC); sh("Anti-Macro", "авто-ответ", pC)

local pV = addTab("Visual", "Visual")
sec("PERFORMANCE", pV); sh("FPS Boost", "эффекты off", pV); sh("Black Screen", "3D off", pV)
div(pV); sec("PRIVACY", pV); sh("Hide Name", "ники", pV); sh("Walk Around", "анти-АФК", pV)

local pD = addTab("Discord", "Discord")
sec("WEBHOOK", pD); sh("Webhook URL", "ввод", pD)
div(pD); sec("REPORTS", pD); sh("Send Now", "валюта", pD); sh("Send Full", "полный", pD)

for n, p in pairs(pages) do p.Visible = (n == "Macros") end
tabs["Macros"].BackgroundColor3 = C.ac
tabs["Macros"].TextColor3 = C.tx

local opened = false
local OP = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CL = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function open()
    if opened then return end
    opened = true
    icon.Visible = false
    win.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    win.Size = UDim2.new(0, 0, 0, 0)
    win.Visible = true
    T:Create(win, OP, {Size = UDim2.new(0, W, 0, H)}):Play()
end

local function closeWin()
    if not opened then return end
    opened = false
    T:Create(win, CL, {Size = UDim2.new(0, 0, 0, 0)}):Play()
    task.wait(0.2)
    win.Visible = false
    icon.Visible = true
end

close.MouseButton1Click:Connect(closeWin)

local iDrag, iMoved, iD0, iP0 = false, false, nil, nil
icon.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        iDrag = true; iMoved = false; iD0 = i.Position; iP0 = icon.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then iDrag = false end
        end)
    end
end)
icon.InputChanged:Connect(function(i)
    if iDrag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - iD0
        if d.Magnitude > 8 then
            iMoved = true
            icon.Position = UDim2.new(0, iP0.X.Offset + d.X, 0, iP0.Y.Offset + d.Y)
        end
    end
end)
icon.MouseButton1Click:Connect(function() if not iMoved then open() end end)

local wDrag, wD0, wP0 = false, nil, nil
head.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        wDrag = true; wD0 = i.Position; wP0 = win.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then wDrag = false end
        end)
    end
end)
head.InputChanged:Connect(function(i)
    if wDrag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - wD0
        win.Position = UDim2.new(0, wP0.X.Offset + d.X, 0, wP0.Y.Offset + d.Y)
    end
end)
