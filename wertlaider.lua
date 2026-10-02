-- wertlaider lite · часть 1/3 · ядро + AntiMacro
-- грузи первой. экспортирует _G.__WL для частей 2 и 3.

local LOG = "wl_runtime.log"
pcall(writefile, LOG, "")
local function Log(...)
    local p = {}
    for _, v in ipairs({...}) do p[#p+1] = tostring(v) end
    local line = "[" .. os.date("%H:%M:%S") .. "] " .. table.concat(p, " ") .. "\n"
    pcall(function()
        if appendfile then appendfile(LOG, line) else writefile(LOG, (readfile(LOG) or "") .. line) end
    end)
end
Log("boot", "part1 start ·", identifyexecutor and identifyexecutor() or "?")

local P  = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local HS = game:GetService("HttpService")
local R2 = game:GetService("RunService")
local LP = P.LocalPlayer

local fn = RS:FindFirstChild("Functions")
local ev = RS:FindFirstChild("Events")
local rm = RS:FindFirstChild("Remotes")
local R = {}
R.Req   = fn and fn:FindFirstChild("RequestTower")
R.Spawn = fn and fn:FindFirstChild("SpawnTower")
R.Upg   = fn and fn:FindFirstChild("UpgradeTower")
R.Sell  = fn and fn:FindFirstChild("SellTower")
R.Skip  = fn and fn:FindFirstChild("VoteSkip")
R.Spd   = fn and fn:FindFirstChild("ChangeSpeed")
R.Sum   = rm and rm:FindFirstChild("Summon") and rm.Summon:FindFirstChild("Summon")
R.SumP  = rm and rm:FindFirstChild("Summon") and rm.Summon:FindFirstChild("SummonPremium")
R.Buy   = rm and rm:FindFirstChild("Inventory") and rm.Inventory:FindFirstChild("BuyCrate")
R.Open  = rm and rm:FindFirstChild("Inventory") and rm.Inventory:FindFirstChild("OpenCrate")
R.VM    = ev and ev:FindFirstChild("VoteForMap")
R.VC    = ev and ev:FindFirstChild("VoteForComplication")
R.SM    = ev and ev:FindFirstChild("SlopMutator")
R.EX    = ev and ev:FindFirstChild("ExitGame")
R.ED    = ev and ev:FindFirstChild("EndDecision")
R.EE    = ev and ev:FindFirstChild("EnterElevator")
R.SE    = ev and ev:FindFirstChild("StartElevator")
local AM = ev and ev:FindFirstChild("AntiMacro")
R.AC = AM and AM:FindFirstChild("Check")
R.AR = AM and AM:FindFirstChild("Respond")

local S = {
    run = true,
    am=false, am1=0.4, am2=1.0,
    sel=false, sellW=100,
    sk=false, sp=false, sv=5,
    vm=false, vc=false, vmut=false,
    mapV="Base", compV="Normal",
    sum=false, sumCur="Cash", sumA=10, sumD=1.5,
    buy=false, opn=false, crate="Still Life Crate", crateA=1, crateD=2,
    lobby=false, elevType="Auto",
    jump=false, walk=false,
    endAct="None",
    tok=nil, tokT=0, busy=false,
    lp=0, lu=0, ls=0, lsp=0, lsel=0, lsum=0, lcr=0,
    votedMap=false, votedComp=false, votedMut=false,
    votedMapDL=0, votedCompDL=0,
    lastCD=0, abCd={}, walkC=nil,
    lastFallback=0, lastElevName="", elevRetries=0,
}

local function wv()
    local i=WS:FindFirstChild("Info"); local w=i and i:FindFirstChild("Wave")
    return w and tonumber(w.Value) or 0
end
local function rn()
    local i=WS:FindFirstChild("Info"); local g=i and i:FindFirstChild("GameRunning")
    return g and g.Value
end
local function sd()
    local i=WS:FindFirstChild("Info"); local s=i and i:FindFirstChild("SpeedGame")
    return s and tonumber(s.Value) or 1
end
local function ivm()
    local i=WS:FindFirstChild("Info"); local v=i and i:FindFirstChild("Voting")
    return v and v.Value
end
local function ivc()
    local i=WS:FindFirstChild("Info"); local v=i and i:FindFirstChild("ComplicationVoting")
    return v and v.Value
end
local function mn()
    local o={}; local t=WS:FindFirstChild("Towers"); if not t then return o end
    for _,v in ipairs(t:GetChildren()) do
        local c=v:FindFirstChild("Config"); local ow=c and c:FindFirstChild("Owner")
        if ow and tostring(ow.Value)==LP.Name then table.insert(o,v) end
    end
    return o
end
local function readVal(name)
    local v=LP:FindFirstChild(name)
    if v and v:IsA("ValueBase") then
        local n=tonumber(v.Value); if n then return n end
        local s=tostring(v.Value):gsub(",","")
        n=tonumber(s) or tonumber(s:match("([%d%.]+)")); if n then return n end
    end
    local ls=LP:FindFirstChild("leaderstats")
    if ls then
        local x=ls:FindFirstChild(name)
        if x and x:IsA("ValueBase") then
            local s=tostring(x.Value):gsub(",","")
            local n=tonumber(s) or tonumber(s:match("([%d%.]+)")); if n then return n end
        end
    end
    return 0
end
local function uu(v, d)
    d=(d or 0)+1
    if d>4 then return nil end
    if type(v)=="string" then
        if v:match("^[%x]+%-%x+%-%x+%-%x+%-%x+$") then return v end
        return nil
    end
    if type(v)=="table" then
        for _,c in pairs(v) do
            local r=uu(c,d); if r then return r end
        end
    end
end

local function findAntiBtn()
    local pg=LP:FindFirstChildOfClass("PlayerGui")
    local root=pg and pg:FindFirstChild("AntiMacroCheck")
    if not root then return nil end
    local frame=root:FindFirstChild("Frame")
    local btn=frame and frame:FindFirstChild("TextButton")
    if btn and btn:IsA("GuiButton") then return btn end
    for _,d in ipairs(root:GetDescendants()) do
        if d:IsA("GuiButton") then
            local n=tostring(d.Name):lower()
            if n:find("button") or n:find("here") then return d end
        end
    end
    for _,d in ipairs(root:GetDescendants()) do
        if d:IsA("GuiButton") then
            local t=tostring(d.Text):lower():gsub("[^%a]","")
            if t=="imhere" or t=="ihere" then return d end
        end
    end
    return nil
end
local function isVis(obj)
    if not obj or not obj:IsDescendantOf(game) then return false end
    local cur=obj
    while cur and cur~=game do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur:IsA("LayerCollector") and not cur.Enabled then return false end
        cur=cur.Parent
    end
    return true
end
local function clickBtn(btn)
    if not btn then return false end
    local mb=btn.MouseButton1Click
    if type(firesignal)=="function" then
        if pcall(firesignal, mb) then return true end
    end
    if type(getconnections)=="function" then
        local conns=getconnections(mb)
        for _,c in ipairs(conns) do
            if type(c.Fire)=="function" then pcall(c.Fire, c) end
        end
        return true
    end
    local ok,VIM=pcall(game.GetService, game, "VirtualInputManager")
    if ok and VIM then
        local pos=btn.AbsolutePosition+btn.AbsoluteSize*0.5
        pcall(function()
            VIM:SendMouseButtonEvent(pos.X,pos.Y,0,true,game,0)
            VIM:SendMouseButtonEvent(pos.X,pos.Y,0,false,game,0)
        end)
        return true
    end
    return false
end
local lastAC=nil
local function bindAC()
    local AM2=ev and ev:FindFirstChild("AntiMacro")
    local newAC=AM2 and AM2:FindFirstChild("Check")
    if newAC==lastAC then return end
    R.AC=newAC
    R.AR=AM2 and AM2:FindFirstChild("Respond")
    lastAC=newAC
    if newAC then
        newAC.OnClientEvent:Connect(function(...)
            local u=uu(table.pack(...))
            if u then S.tok=u; S.tokT=os.clock() end
        end)
    end
end
task.spawn(function()
    while S.run do
        task.wait(0.2)
        pcall(function()
            bindAC()
            if not S.am or S.busy then return end
            local tok=S.tok
            local btn=findAntiBtn()
            local btnV=btn and isVis(btn)
            if tok and (os.clock()-S.tokT)>35 then S.tok=nil; tok=nil end
            if tok and btnV and R.AR then
                S.busy=true
                task.wait(S.am1+math.random()*(S.am2-S.am1))
                if S.am and S.tok==tok then
                    pcall(function() R.AR:FireServer(tok) end)
                    S.tok=nil
                    Log("AM", "remote respond")
                end
                S.busy=false
            elseif btnV then
                if (os.clock()-S.lastFallback)>=2 then
                    S.lastFallback=os.clock()
                    clickBtn(btn)
                end
            end
        end)
    end
end)

_G.__WL = {
    P=P, RS=RS, WS=WS, HS=HS, R2=R2, LP=LP,
    fn=fn, ev=ev, rm=rm, R=R, S=S,
    Log=Log, wv=wv, rn=rn, sd=sd, ivm=ivm, ivc=ivc,
    mn=mn, readVal=readVal, uu=uu,
}
Log("ready", "part1 done")
-- wertlaider lite · часть 2/3 · Sell · Control · Summon · Crates · Elevator · AFK
-- грузи после части 1.

local G = _G.__WL
if not G then error("part1 не загружена — сначала Execute p1.lua") end
local P, RS, WS, LP = G.P, G.RS, G.WS, G.LP
local R, S = G.R, G.S
local Log = G.Log
local wv, rn, sd, ivm, ivc = G.wv, G.rn, G.sd, G.ivm, G.ivc
local mn, readVal = G.mn, G.readVal

-- AUTO SELL
task.spawn(function()
    while S.run do
        task.wait(0.5)
        pcall(function()
            if S.sel and rn() and wv()>=S.sellW and R.Sell and os.clock()-S.lsel>3 then
                S.lsel=os.clock()
                for _,t in ipairs(mn()) do
                    if t and t.Parent then
                        pcall(function() R.Sell:InvokeServer(t) end)
                        task.wait(0.4+math.random()*0.3)
                    end
                end
            end
        end)
    end
end)

-- AUTO CONTROL
task.spawn(function()
    while S.run do
        task.wait(1)
        pcall(function()
            if S.sk and rn() and R.Skip and os.clock()-S.ls>7+math.random()*3 then
                S.ls=os.clock()
                pcall(function() R.Skip:InvokeServer() end)
            end
            if S.sp and rn() and R.Spd and sd()~=S.sv and os.clock()-S.lsp>5 then
                S.lsp=os.clock()
                pcall(function() R.Spd:InvokeServer(S.sv) end)
            end
            if S.vm and R.VM then
                if ivm() then
                    if not S.votedMap then
                        pcall(function() R.VM:FireServer(S.mapV) end)
                        S.votedMap=true
                        S.votedMapDL=os.clock()+3
                    elseif S.votedMapDL>0 and os.clock()>S.votedMapDL then
                        S.votedMapDL=0
                    end
                else
                    S.votedMap=false
                    S.votedMapDL=0
                end
            end
            if S.vc and R.VC then
                if ivc() then
                    if not S.votedComp then
                        pcall(function() R.VC:FireServer(S.compV) end)
                        S.votedComp=true
                        S.votedCompDL=os.clock()+3
                    elseif S.votedCompDL>0 and os.clock()>S.votedCompDL then
                        S.votedCompDL=0
                    end
                else
                    S.votedComp=false
                    S.votedCompDL=0
                end
            end
            if S.vmut and R.SM then
                local pg=LP:FindFirstChild("PlayerGui")
                local mg=pg and pg:FindFirstChild("SlopMutatorGui")
                local voting=mg and mg:FindFirstChild("MutatorVoting")
                if voting and voting.Visible and not S.votedMut then
                    S.votedMut=true
                    pcall(function() R.SM:FireServer("Vote","None") end)
                end
                if not (voting and voting.Visible) then S.votedMut=false end
            end
        end)
    end
end)

-- AUTO SUMMON
task.spawn(function()
    while S.run do
        task.wait(0.5)
        pcall(function()
            if S.sum and os.clock()-S.lsum>=S.sumD then
                S.lsum=os.clock()
                local r=((S.sumCur=="Gem") and R.SumP) or R.Sum
                if r then pcall(function() r:InvokeServer(S.sumA) end) end
            end
        end)
    end
end)

-- AUTO CRATES
task.spawn(function()
    while S.run do
        task.wait(1)
        pcall(function()
            if (S.buy or S.opn) and os.clock()-S.lcr>=S.crateD then
                S.lcr=os.clock()
                if S.buy and R.Buy then pcall(function() R.Buy:FireServer(S.crate, S.crateA) end) end
                if S.opn and R.Open then pcall(function() R.Open:InvokeServer(S.crate, S.crateA) end) end
            end
        end)
    end
end)

-- AUTO ELEVATOR — ходьба
local function getPadPos(elev)
    if not elev then return nil end
    local best,bestScore=nil,0
    for _,o in ipairs(elev:GetDescendants()) do
        if o:IsA("BasePart") then
            local score=o.Size.X*o.Size.Z
            local n=o.Name:lower()
            if n:find("pad") or n:find("circle") or n:find("floor") or n:find("teleport") then
                score=score*5
            end
            if score>bestScore then bestScore=score; best=o end
        end
    end
    if best then return best.Position end
    local ok,bb=pcall(function() return elev:GetBoundingBox() end)
    if ok and bb then return bb.Position end
    return nil
end
local function isRaidElev(e)
    local v=e:GetAttribute("IsRaid")
    if v~=nil then return tostring(v):lower()=="true" end
    return tostring(e.Name):lower():find("raid")~=nil
end
local function isPlayerInElev(elev)
    if not elev then return false end
    local ids=elev:GetAttribute("PlayerUserIds")
    if type(ids)=="string" and ids~="" then
        if ids:find(tostring(LP.UserId),1,true) then return true end
    end
    return false
end
local function pickElev()
    local els=WS:FindFirstChild("Elevators")
    if not els then return nil end
    local best,bestCount=nil,0
    for _,e in ipairs(els:GetChildren()) do
        if e:IsA("Model") then
            local mp=tonumber(e:GetAttribute("MaxPlayers")) or 4
            local raid=isRaidElev(e)
            local okType=
                S.elevType=="Raid" and raid or
                S.elevType=="Normal" and not raid or
                S.elevType=="Auto"
            if okType and mp>bestCount then bestCount=mp; best=e end
        end
    end
    return best
end
task.spawn(function()
    while S.run do
        task.wait(1)
        pcall(function()
            if not (S.lobby and R.EE and R.SE) then
                S.lastElevName=""
                S.elevRetries=0
                return
            end
            local best=pickElev()
            if not best then return end
            if isPlayerInElev(best) then
                S.lastElevName=best.Name
                return
            end
            if S.lastElevName~=best.Name then
                S.lastElevName=best.Name
                S.elevRetries=0
                local ch=LP.Character
                local h=ch and ch:FindFirstChildOfClass("Humanoid")
                local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
                local padPos=getPadPos(best)
                if h and hrp and padPos then
                    local t0=os.clock()
                    while S.run and os.clock()-t0<5 do
                        pcall(function() h:MoveTo(padPos) end)
                        local d=(hrp.Position-padPos).Magnitude
                        if d<4 then break end
                        task.wait(0.1)
                    end
                end
                pcall(function() R.EE:FireServer(best.Name) end)
                task.wait(0.5)
                pcall(function() R.SE:FireServer(best.Name) end)
            end
        end)
    end
end)

-- ANTI-AFK
task.spawn(function()
    while S.run do
        task.wait(1)
        pcall(function()
            if not S.jump then return end
            local ch=LP.Character
            local h=ch and ch:FindFirstChildOfClass("Humanoid")
            if not h or h.Sit then return end
            if h.FloorMaterial==Enum.Material.Air then return end
            pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end)
    end
end)
task.spawn(function()
    while S.run do
        task.wait(0.5)
        pcall(function()
            if not S.walk then return end
            local ch=LP.Character
            local h=ch and ch:FindFirstChildOfClass("Humanoid")
            local rp=ch and ch:FindFirstChild("HumanoidRootPart")
            if h and rp then
                S.walkC=S.walkC or rp.CFrame
                local a=math.random()*math.pi*2
                local r=math.random(5,15)
                pcall(function()
                    h:MoveTo(S.walkC.Position+Vector3.new(math.cos(a)*r,0,math.sin(a)*r))
                end)
            end
        end)
    end
end)

Log("ready", "part2 done")
-- wertlaider lite · часть 3/3 · встроенный UI
-- грузи после части 2.

local G = _G.__WL
if not G then error("part1 не загружена — сначала Execute p1.lua") end
local LP = G.LP
local R, S = G.R, G.S
local Log = G.Log

local THEME = {
    bg=Color3.fromRGB(18,20,28), panel=Color3.fromRGB(28,32,44),
    accent=Color3.fromRGB(90,160,255), text=Color3.fromRGB(232,236,245),
    dim=Color3.fromRGB(150,160,185), ok=Color3.fromRGB(80,220,130),
    bad=Color3.fromRGB(240,90,90),
}
local function inst(c,p,parent)
    local o=Instance.new(c)
    for k,v in pairs(p or {}) do o[k]=v end
    if parent then o.Parent=parent end
    return o
end
local function corner(o,r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=o
end
local function stroke(o,col,w)
    local s=Instance.new("UIStroke"); s.Color=col or THEME.dim; s.Thickness=w or 1; s.Parent=o
end

local gui = inst("ScreenGui", {
    Name="wertlaider", ResetOnSpawn=false, IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
})
gui.Parent = (gethui and gethui()) or LP:WaitForChild("PlayerGui")

local win = inst("Frame", {
    Size=UDim2.fromOffset(500,420),
    Position=UDim2.new(0,30,0,80),
    BackgroundColor3=THEME.bg, BorderSizePixel=0, Active=true,
}, gui)
corner(win,12); stroke(win,THEME.accent,1)

local tb = inst("Frame", {
    Size=UDim2.new(1,0,0,34), BackgroundColor3=THEME.panel, BorderSizePixel=0,
}, win)
corner(tb,12)
inst("TextLabel", {
    Size=UDim2.new(1,-80,1,0), Position=UDim2.new(0,14,0,0),
    BackgroundTransparency=1, Text="wertlaider",
    TextColor3=THEME.text, Font=Enum.Font.GothamBold, TextSize=15,
    TextXAlignment=Enum.TextXAlignment.Left,
}, tb)

local btnClose = inst("TextButton", {
    Size=UDim2.fromOffset(26,26), Position=UDim2.new(1,-32,0,4),
    BackgroundColor3=THEME.bad, Text="X", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0,
}, tb)
corner(btnClose,6)

local floating = inst("TextButton", {
    Size=UDim2.fromOffset(60,60), Position=UDim2.new(0,20,0,120),
    BackgroundColor3=THEME.accent, Text="W", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=20, BorderSizePixel=0,
    Visible=false, Active=true, Draggable=true,
}, gui)
corner(floating,30); stroke(floating,Color3.new(1,1,1),2)

btnClose.MouseButton1Click:Connect(function() win.Visible=false; floating.Visible=true end)
floating.MouseButton1Click:Connect(function() win.Visible=true; floating.Visible=false end)

local drag, dragS, dragP = false, nil, nil
tb.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true; dragS=i.Position; dragP=win.Position
    end
end)
tb.InputChanged:Connect(function(i)
    if drag and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
        local d=i.Position-dragS
        win.Position=UDim2.new(dragP.X.Scale,dragP.X.Offset+d.X,dragP.Y.Scale,dragP.Y.Offset+d.Y)
    end
end)
tb.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=false
    end
end)

local tabBar = inst("Frame", {
    Size=UDim2.new(1,-16,0,32), Position=UDim2.new(0,8,0,40),
    BackgroundTransparency=1,
}, win)
inst("UIListLayout", {
    FillDirection=Enum.FillDirection.Horizontal,
    Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder,
}, tabBar)

local pages = inst("Frame", {
    Size=UDim2.new(1,-16,1,-82), Position=UDim2.new(0,8,0,74),
    BackgroundTransparency=1, ClipsDescendants=true,
}, win)

local tabs = {}
local function makeTab(name)
    local btn = inst("TextButton", {
        Size=UDim2.fromOffset(94,28),
        BackgroundColor3=THEME.panel, Text=name, TextColor3=THEME.text,
        Font=Enum.Font.Gotham, TextSize=12, BorderSizePixel=0,
    }, tabBar)
    corner(btn,7)
    local page = inst("ScrollingFrame", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=4,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false,
    }, pages)
    inst("UIListLayout", {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder}, page)
    local t = {btn=btn, page=page}
    table.insert(tabs, t)
    if #tabs==1 then
        page.Visible=true; btn.BackgroundColor3=THEME.accent
    end
    btn.MouseButton1Click:Connect(function()
        for _,x in ipairs(tabs) do
            x.page.Visible=(x==t)
            x.btn.BackgroundColor3=(x==t) and THEME.accent or THEME.panel
        end
    end)
    return t
end

local function section(tab, title)
    inst("TextLabel", {
        Size=UDim2.new(1,0,0,22), BackgroundTransparency=1,
        Text="— "..title, TextColor3=THEME.accent,
        Font=Enum.Font.GothamBold, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, tab.page)
end
local function toggle(tab, title, init, cb)
    local state = init and true or false
    local row = inst("Frame", {
        Size=UDim2.new(1,0,0,32), BackgroundColor3=THEME.panel, BorderSizePixel=0,
    }, tab.page)
    corner(row,6)
    inst("TextLabel", {
        Size=UDim2.new(0.75,-10,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, Text=title, TextColor3=THEME.text,
        Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, row)
    local b = inst("TextButton", {
        Size=UDim2.fromOffset(54,22), Position=UDim2.new(1,-62,0.5,-11),
        BackgroundColor3=state and THEME.ok or THEME.bg,
        Text=state and "ON" or "OFF", TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.GothamBold, TextSize=11, BorderSizePixel=0,
    }, row)
    corner(b,11); stroke(b,THEME.dim,1)
    b.MouseButton1Click:Connect(function()
        state=not state
        b.BackgroundColor3=state and THEME.ok or THEME.bg
        b.Text=state and "ON" or "OFF"
        if cb then cb(state) end
    end)
end
local function button(tab, title, cb)
    local b = inst("TextButton", {
        Size=UDim2.new(1,0,0,30), BackgroundColor3=THEME.panel,
        Text=title, TextColor3=THEME.text,
        Font=Enum.Font.Gotham, TextSize=12, BorderSizePixel=0,
    }, tab.page)
    corner(b,6)
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
end
local function stepper(tab, title, vmin, vmax, init, step, cb)
    local val = init
    local row = inst("Frame", {
        Size=UDim2.new(1,0,0,46), BackgroundColor3=THEME.panel, BorderSizePixel=0,
    }, tab.page)
    corner(row,6)
    local lbl = inst("TextLabel", {
        Size=UDim2.new(1,-20,0,18), Position=UDim2.new(0,10,0,4),
        BackgroundTransparency=1, Text=title..": "..tostring(val),
        TextColor3=THEME.text, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, row)
    local mn_ = inst("TextButton", {
        Size=UDim2.fromOffset(60,20), Position=UDim2.new(0,10,0,22),
        BackgroundColor3=THEME.bg, Text="− "..tostring(step),
        TextColor3=THEME.text, Font=Enum.Font.GothamBold, TextSize=11, BorderSizePixel=0,
    }, row)
    corner(mn_,5)
    local pl_ = inst("TextButton", {
        Size=UDim2.fromOffset(60,20), Position=UDim2.new(1,-70,0,22),
        BackgroundColor3=THEME.bg, Text="+ "..tostring(step),
        TextColor3=THEME.text, Font=Enum.Font.GothamBold, TextSize=11, BorderSizePixel=0,
    }, row)
    corner(pl_,5)
    local function upd(d)
        val=math.clamp(val+d,vmin,vmax)
        lbl.Text=title..": "..tostring(val)
        if cb then cb(val) end
    end
    mn_.MouseButton1Click:Connect(function() upd(-step) end)
    pl_.MouseButton1Click:Connect(function() upd(step) end)
end
local function dropdown(tab, title, values, init, cb)
    local idx=1
    for i,x in ipairs(values) do if x==init then idx=i break end end
    local cur=values[idx] or values[1]
    local row = inst("Frame", {
        Size=UDim2.new(1,0,0,32), BackgroundColor3=THEME.panel, BorderSizePixel=0,
    }, tab.page)
    corner(row,6)
    inst("TextLabel", {
        Size=UDim2.new(0.4,0,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, Text=title, TextColor3=THEME.text,
        Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, row)
    local b = inst("TextButton", {
        Size=UDim2.new(0.55,-10,0,24), Position=UDim2.new(0.45,0,0.5,-12),
        BackgroundColor3=THEME.bg, Text=tostring(cur),
        TextColor3=THEME.text, Font=Enum.Font.Gotham, TextSize=11, BorderSizePixel=0,
    }, row)
    corner(b,6); stroke(b,THEME.dim,1)
    b.MouseButton1Click:Connect(function()
        idx=idx+1
        if idx>#values then idx=1 end
        cur=values[idx]
        b.Text=tostring(cur)
        if cb then cb(cur) end
    end)
end

local T1 = makeTab("Match")
section(T1, "Vote")
dropdown(T1, "Map", {"BackroomsEndless","Base","Blood Moon","BrainrotEndless","Crossroads","Day","Desert","Doomspire","Dungeon","Gold Base","Kitchen Table","Level 1","Level 2","Level 3","Night","Night Base","Plot","Poolrooms","Raid","RetroEndless","RichPlot","Ruined City","Summer Raid","The Fridge","Toilet City"}, S.mapV, function(v) S.mapV=v end)
dropdown(T1, "Complication", {"Normal","Hard","Nightmare","Chaos"}, S.compV, function(v) S.compV=v end)
toggle(T1, "Auto Vote Map", S.vm, function(v) S.vm=v end)
toggle(T1, "Auto Vote Comp", S.vc, function(v) S.vc=v end)
toggle(T1, "Auto Vote Mutator (None)", S.vmut, function(v) S.vmut=v end)
section(T1, "Control")
toggle(T1, "Auto Skip", S.sk, function(v) S.sk=v end)
toggle(T1, "Auto Speed", S.sp, function(v) S.sp=v end)
stepper(T1, "Speed", 1, 5, S.sv, 1, function(v) S.sv=v end)
section(T1, "Sell")
toggle(T1, "Auto Sell All", S.sel, function(v) S.sel=v end)
stepper(T1, "Sell At Wave", 10, 500, S.sellW, 10, function(v) S.sellW=v end)

local T2 = makeTab("Lobby")
toggle(T2, "Auto Elevator", S.lobby, function(v) S.lobby=v end)
dropdown(T2, "Elevator Type", {"Auto","Normal","Raid"}, S.elevType, function(v) S.elevType=v end)
section(T2, "Summon")
toggle(T2, "Enable", S.sum, function(v) S.sum=v end)
dropdown(T2, "Currency", {"Cash","Gem"}, S.sumCur, function(v) S.sumCur=v end)
dropdown(T2, "Amount", {"x1","x10","x50"}, "x"..tostring(S.sumA), function(v) S.sumA=tonumber(v:match("%d+")) or 10 end)
stepper(T2, "Delay", 1, 10, math.floor(S.sumD*2), 1, function(v) S.sumD=v/2 end)
section(T2, "Crates")
dropdown(T2, "Crate", {"Still Life Crate","Garden Crate","Alien Crate","Space Crate"}, S.crate, function(v) S.crate=v end)
dropdown(T2, "Amount", {"x1","x3","x10","x25"}, "x"..tostring(S.crateA), function(v) S.crateA=tonumber(v:match("%d+")) or 1 end)
toggle(T2, "Auto Buy", S.buy, function(v) S.buy=v end)
toggle(T2, "Auto Open", S.opn, function(v) S.opn=v end)
button(T2, "Roll Now", function()
    if R.Buy then pcall(function() R.Buy:FireServer(S.crate, S.crateA) end) end
    task.wait(0.5)
    if R.Open then pcall(function() R.Open:InvokeServer(S.crate, S.crateA) end) end
end)

local T3 = makeTab("Misc")
section(T3, "Anti-Macro")
toggle(T3, "Auto Anti-Macro", S.am, function(v) S.am=v end)
stepper(T3, "Delay Min", 1, 30, math.floor(S.am1*10), 1, function(v) S.am1=v/10 end)
stepper(T3, "Delay Max", 2, 50, math.floor(S.am2*10), 1, function(v) S.am2=v/10 end)
section(T3, "Anti-AFK")
toggle(T3, "Auto Jump", S.jump, function(v) S.jump=v end)
toggle(T3, "Walk Around", S.walk, function(v) S.walk=v end)

Log("ready", "part3 done · UI shown")