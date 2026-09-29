local P=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local WS=game:GetService("Workspace")
local HS=game:GetService("HttpService")
local L=game:GetService("Lighting")
local R2=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local LP=P.LocalPlayer

local fn=RS:FindFirstChild("Functions")
local ev=RS:FindFirstChild("Events")
local rm=RS:FindFirstChild("Remotes")

local R={}
R.Req=fn and fn:FindFirstChild("RequestTower")
R.Spawn=fn and fn:FindFirstChild("SpawnTower")
R.Upg=fn and fn:FindFirstChild("UpgradeTower")
R.Sell=fn and fn:FindFirstChild("SellTower")
R.Skip=fn and fn:FindFirstChild("VoteSkip")
R.Spd=fn and fn:FindFirstChild("ChangeSpeed")
R.Place=fn and fn:FindFirstChild("GetPlayerPlacement")
R.Data=rm and rm:FindFirstChild("PlayerData")and rm.PlayerData:FindFirstChild("GetData")
R.Sum=rm and rm:FindFirstChild("Summon")and rm.Summon:FindFirstChild("Summon")
R.Buy=rm and rm:FindFirstChild("Inventory")and rm.Inventory:FindFirstChild("BuyCrate")
R.Open=rm and rm:FindFirstChild("Inventory")and rm.Inventory:FindFirstChild("OpenCrate")
R.VMap=ev and ev:FindFirstChild("VoteForMap")
R.VComp=ev and ev:FindFirstChild("VoteForComplication")
R.Ability=ev and ev:FindFirstChild("ActivateAbility")
R.Exit=ev and ev:FindFirstChild("ExitGame")
R.EndDec=ev and ev:FindFirstChild("EndDecision")
R.EnterEl=ev and ev:FindFirstChild("EnterElevator")
R.StartEl=ev and ev:FindFirstChild("StartElevator")
local AM=ev and ev:FindFirstChild("AntiMacro")
R.ACheck=AM and AM:FindFirstChild("Check")
R.AResp=AM and AM:FindFirstChild("Respond")

local S={
am=false,ap=false,au=false,sel=false,sk=false,sp=false,ab=false,
vm=false,vc=false,sum=false,buy=false,opn=false,lobby=false,jump=false,
walk=false,fps=false,blk=false,hid=false,endAct="None",
wh=true,url="https://discord.com/api/webhooks/1540650813767032914/hUy6M_Ouz_6m2VR3a-N9C_gj-uD40tgRmMzzW2Z6vLD_mQW_uYFAkxXOLkap88eoh4Fd",
d_ap=4,r_ap=40,d_au=8,sv=5,am1=0.4,am2=1.0,sellW=100,sumA=10,sumD=1.5,
crateA=1,crateD=2,tok=nil,tokT=0,busy=false,
lp=0,lu=0,ls=0,lsp=0,lsel=0,lsum=0,lcr=0,
fpsO={},fpsC=nil,bsGui=nil,walkC=nil,
Mac={rec=false,play=false,acts={},t0=0,prof="default",meta=setmetatable({},{__mode="k"}),h=0}
}

local function rnd(b,p)if p<=0 then return b end local s=b*(p/100)return b-s/2+math.random()*s end
local function wv()local i=WS:FindFirstChild("Info")local w=i and i:FindFirstChild("Wave")return w and tonumber(w.Value)or 0 end
local function rn()local i=WS:FindFirstChild("Info")local g=i and i:FindFirstChild("GameRunning")return g and g.Value end
local function cs()local c=LP:FindFirstChild("Cash")return c and tonumber(c.Value)or 0 end
local function sd()local i=WS:FindFirstChild("Info")local s=i and i:FindFirstChild("SpeedGame")return s and tonumber(s.Value)or 1 end
local function ivm()local i=WS:FindFirstChild("Info")local v=i and i:FindFirstChild("Voting")return v and v.Value end
local function ivc()local i=WS:FindFirstChild("Info")local v=i and i:FindFirstChild("ComplicationVoting")return v and v.Value end
local function mn()
local o={}
local t=WS:FindFirstChild("Towers")
if not t then return o end
for _,v in ipairs(t:GetChildren())do
local c=v:FindFirstChild("Config")
local ow=c and c:FindFirstChild("Owner")
if ow and tostring(ow.Value)==LP.Name then table.insert(o,v)end
end
return o
end
local function lv(t)
local c=t:FindFirstChild("Config")
local l=c and c:FindFirstChild("LVL")
return l and tonumber(l.Value)or 0
end
local function eq()
local o={}
if not R.Data then return o end
local ok,d=pcall(function()return R.Data:InvokeServer()end)
if not ok or type(d)~="table"or type(d.Towers)~="table"then return o end
for n,i in pairs(d.Towers)do
if type(i)=="table"then
local s=tonumber(i.Equipped)
if s and s>=1 and s<=6 then o[s]={v=tostring(n),b=tostring(i.Name or n)}end
end
end
return o
end

local util={
rnd=rnd,wv=wv,rn=rn,cs=cs,sd=sd,ivm=ivm,ivc=ivc,
mn=mn,lv=lv,eq=eq
}

getgenv().WL={R=R,S=S,util=util,LP=LP,HS=HS,L=L,R2=R2,UIS=UIS}
print("[WL] core loaded")
local WL=getgenv().WL
if not WL then return end
local R=WL.R
local S=WL.S
local U=WL.util
local HS=WL.HS

local MF="Wertlaider_Macros"
pcall(function()if not isfolder(MF)then makefolder(MF)end end)

local Mac=S.Mac
local function path(n)return MF.."/"..n..".json"end

local function rec(a)
a.Wave=U.wv()
a.Time=os.clock()-Mac.t0
a.Cash=U.cs()
table.insert(Mac.acts,a)
end

local function track(t,asPlace)
if not t or Mac.meta[t]then return end
local cfg=t:FindFirstChild("Config")
local ow=cfg and cfg:FindFirstChild("Owner")
if not ow or tostring(ow.Value)~=WL.LP.Name then return end
Mac.h=Mac.h+1
local h=Mac.h
local m={h=h,lvl=0,tgt="",rem=false}
Mac.meta[t]=m
if asPlace and Mac.rec then
local ok,cf=pcall(function()
if t:IsA("Model")then return t:GetPivot()
elseif t:IsA("BasePart")then return t.CFrame end
end)
if ok and cf then
rec({Type="Place",Handle=h,Unit=tostring(t.Name),CFrame={cf:GetComponents()}})
end
end
local lvl=cfg and cfg:FindFirstChild("LVL")
if lvl then
m.lvl=tonumber(lvl.Value)or 0
lvl.Changed:Connect(function()
local n=tonumber(lvl.Value)or 0
if Mac.rec and n>m.lvl then
for i=m.lvl+1,n do
rec({Type="Upgrade",Handle=h,Unit=tostring(t.Name),Level=i})
end
end
m.lvl=n
end)
end
local tm=cfg and cfg:FindFirstChild("TargetMode")
if tm then
m.tgt=tostring(tm.Value)
tm.Changed:Connect(function()
local n=tostring(tm.Value)
if Mac.rec and n~=m.tgt and n~=""then
rec({Type="Target",Handle=h,Unit=tostring(t.Name),Mode=n})
end
m.tgt=n
end)
end
t.AncestryChanged:Connect(function(_,p)
if p==nil and Mac.rec and not m.rem then
m.rem=true
rec({Type="Sell",Handle=h,Unit=tostring(t.Name)})
end
end)
end

local function scanT(asPlace)
local tw=WL.R and nil
end

local function scanTowers(asPlace)
local WS=game:GetService("Workspace")
local tw=WS:FindFirstChild("Towers")
if not tw then return end
for _,t in ipairs(tw:GetChildren())do track(t,asPlace)end
if not Mac.conn then
Mac.conn=tw.ChildAdded:Connect(function(t)task.defer(track,t,true)end)
end
end

local function mStart(name)
Mac.acts={}
Mac.t0=os.clock()
Mac.h=0
Mac.prof=name or Mac.prof
Mac.rec=true
scanTowers(false)
end

local function mStop()
Mac.rec=false
pcall(function()
writefile(path(Mac.prof),HS:JSONEncode({
Name=Mac.prof,PlaceId=game.PlaceId,Time=os.time(),
Count=#Mac.acts,Actions=Mac.acts
}))
end)
end

local function mLoad(name)
local ok,d=pcall(function()return HS:JSONDecode(readfile(path(name)))end)
if ok and type(d)=="table"and type(d.Actions)=="table"then
Mac.acts=d.Actions
Mac.prof=name
return true
end
return false
end

local function mPlay()
if Mac.play or #Mac.acts==0 then return end
Mac.play=true
local snap=HS:JSONDecode(HS:JSONEncode(Mac.acts))
task.spawn(function()
local map={}
for _,a in ipairs(snap)do
if not Mac.play then break end
if a.Type=="Place" and R.Spawn then
local cf=CFrame.new(table.unpack(a.CFrame))
pcall(function()R.Req:InvokeServer({a.Unit,a.Unit},false,true)end)
task.wait(0.05)
local ok,res=pcall(function()return R.Spawn:InvokeServer(a.Unit,cf,false,a.Unit,{})end)
if ok and typeof(res)=="Instance"then map[a.Handle]=res end
task.wait(0.5)
elseif a.Type=="Upgrade"then
local t=map[a.Handle]
if t and t.Parent and R.Upg then
pcall(function()R.Upg:InvokeServer(t,tostring(t.Name))end)
task.wait(0.3)
end
elseif a.Type=="Target"then
local t=map[a.Handle]
if t and t.Parent then
local cfg=t:FindFirstChild("Config")
local tm=cfg and cfg:FindFirstChild("TargetMode")
if tm then pcall(function()tm.Value=a.Mode end)end
task.wait(0.2)
end
elseif a.Type=="Sell"then
local t=map[a.Handle]
if t and t.Parent and R.Sell then
pcall(function()R.Sell:InvokeServer(t)end)
map[a.Handle]=nil
task.wait(0.3)
end
end
end
Mac.play=false
end)
end

getgenv().WL.MacroFns={
start=mStart,
stop=mStop,
load=mLoad,
play=mPlay,
stopPlay=function()Mac.play=false end
}

print("[WL] macros loaded")
local WL=getgenv().WL
if not WL then return end
local R=WL.R
local S=WL.S
local U=WL.util
local WS=game:GetService("Workspace")

-- AUTO PLACE
task.spawn(function()
while true do
task.wait(0.3)
if S.ap and U.rn() and R.Place and R.Spawn and os.clock()-S.lp>=U.rnd(S.d_ap,S.r_ap)then
S.lp=os.clock()
local ok,pts=pcall(function()return R.Place:InvokeServer()end)
if ok and type(pts)=="table" and #pts>0 then
local e=U.eq()
local idx=0
for s=1,6 do
if e[s]then idx=s break end
end
if idx>0 then
local x=e[idx]
local pt=pts[math.random(1,#pts)]
local pos=pt.Position or pt
pcall(function()R.Req:InvokeServer({x.v,x.b},false,true)end)
task.wait(0.05)
local cf=CFrame.new(pos+Vector3.new((math.random()-0.5)*0.6,0,(math.random()-0.5)*0.6))
pcall(function()R.Spawn:InvokeServer(x.b,cf,false,x.v,{})end)
end
end
end
end
end)

-- AUTO UPGRADE
task.spawn(function()
while true do
task.wait(0.3)
if S.au and U.rn() and R.Upg and os.clock()-S.lu>=U.rnd(S.d_au,S.r_ap)then
S.lu=os.clock()
local t=U.mn()
if #t>0 then
table.sort(t,function(a,b)return U.lv(a)<U.lv(b)end)
local x=t[1]
if x and x.Parent then
pcall(function()R.Upg:InvokeServer(x,tostring(x.Name))end)
end
end
end
end
end)

-- AUTO SELL
task.spawn(function()
while true do
task.wait(0.5)
if S.sel and U.rn() and U.wv()>=S.sellW and R.Sell and os.clock()-S.lsel>3 then
S.lsel=os.clock()
for _,t in ipairs(U.mn())do
if t and t.Parent then
pcall(function()R.Sell:InvokeServer(t)end)
task.wait(0.1)
end
end
end
end
end)

print("[WL] autoplace loaded")
local WL=getgenv().WL
if not WL then return end
local R=WL.R
local S=WL.S
local U=WL.util
local WS=game:GetService("Workspace")

-- SKIP / SPEED / VOTE / ABILITY
task.spawn(function()
while true do
task.wait(1)
if S.sk and U.rn() and R.Skip and os.clock()-S.ls>3 then
S.ls=os.clock()
pcall(function()R.Skip:InvokeServer()end)
end
if S.sp and U.rn() and R.Spd and U.sd()~=S.sv and os.clock()-S.lsp>2 then
S.lsp=os.clock()
pcall(function()R.Spd:InvokeServer(S.sv)end)
end
if S.vm and U.ivm() and R.VMap then
pcall(function()R.VMap:FireServer("Base")end)
end
if S.vc and U.ivc() and R.VComp then
pcall(function()R.VComp:FireServer("Normal")end)
end
if S.ab and U.rn() and R.Ability then
for _,t in ipairs(U.mn())do
if t and t.Parent then
pcall(function()R.Ability:FireServer(t)end)
end
end
end
end
end)

-- SUMMON
task.spawn(function()
while true do
task.wait(0.5)
if S.sum and U.rn() and R.Sum and os.clock()-S.lsum>=S.sumD then
S.lsum=os.clock()
pcall(function()R.Sum:InvokeServer(S.sumA)end)
end
end
end)

-- CRATES
task.spawn(function()
while true do
task.wait(1)
if (S.buy or S.opn) and U.rn() and os.clock()-S.lcr>=S.crateD then
S.lcr=os.clock()
if S.buy and R.Buy then
pcall(function()R.Buy:FireServer("Basic",S.crateA)end)
end
if S.opn and R.Open then
pcall(function()R.Open:InvokeServer("Basic",S.crateA)end)
end
end
end
end)

-- END ACTION
task.spawn(function()
while true do
task.wait(3)
if S.endAct=="Replay" and R.EndDec then
pcall(function()R.EndDec:FireServer(true)end)
elseif S.endAct=="New Map" and R.EndDec then
pcall(function()R.EndDec:FireServer("new")end)
elseif S.endAct=="Lobby" and R.Exit then
pcall(function()R.Exit:FireServer()end)
end
end
end)

print("[WL] autoactions loaded")
local WL=getgenv().WL
if not WL then return end
local R=WL.R
local S=WL.S
local U=WL.util
local WS=game:GetService("Workspace")
local L=WL.L
local R2=WL.R2
local LP=WL.LP
local Players=game:GetService("Players")

-- LOBBY / ELEVATOR
task.spawn(function()
while true do
task.wait(1)
if S.lobby and R.EnterEl and R.StartEl then
local els=WS:FindFirstChild("Elevators")
if els then
for _,e in ipairs(els:GetChildren())do
if e:IsA("Model")then
pcall(function()R.EnterEl:FireServer(e.Name)end)
task.wait(0.5)
pcall(function()R.StartEl:FireServer(e.Name)end)
break
end
end
end
end
end
end)

-- AUTO JUMP
task.spawn(function()
while true do
task.wait(1)
if S.jump then
local ch=LP.Character
local h=ch and ch:FindFirstChildOfClass("Humanoid")
if h and not h.Sit and h.FloorMaterial~=Enum.Material.Air then
pcall(function()h.Jump=true end)
end
end
end
end)

-- WALK AROUND
task.spawn(function()
while true do
task.wait(0.5)
if S.walk then
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
end
end
end)

-- FPS BOOST
local function fpsApply(on)
if on then
if not S.fpsC then
S.fpsC=WS.DescendantAdded:Connect(function(o)
if o:IsA("ParticleEmitter")or o:IsA("Trail")or o:IsA("Beam")
or o:IsA("Smoke")or o:IsA("Fire")or o:IsA("Sparkles")then
pcall(function()S.fpsO[o]=o.Enabled o.Enabled=false end)
end
end)
end
for _,o in ipairs(WS:GetDescendants())do
if o:IsA("ParticleEmitter")or o:IsA("Trail")or o:IsA("Beam")
or o:IsA("Smoke")or o:IsA("Fire")or o:IsA("Sparkles")then
pcall(function()
if S.fpsO[o]==nil then S.fpsO[o]=o.Enabled end
o.Enabled=false
end)
end
end
pcall(function()L.GlobalShadows=false end)
else
if S.fpsC then pcall(function()S.fpsC:Disconnect()end)S.fpsC=nil end
for o,v in pairs(S.fpsO)do
pcall(function()if o.Parent then o.Enabled=v end end)
end
S.fpsO={}
pcall(function()L.GlobalShadows=true end)
end
end

-- BLACK SCREEN
local function bsApply(on)
if on then
if not S.bsGui then
local sg=Instance.new("ScreenGui")
sg.Name="ww_bs"
sg.ResetOnSpawn=false
sg.IgnoreGuiInset=true
sg.DisplayOrder=9998
sg.Parent=(gethui and gethui())or LP:WaitForChild("PlayerGui")
local f=Instance.new("Frame",sg)
f.Size=UDim2.new(1,0,1,0)
f.BackgroundColor3=Color3.new(0,0,0)
local b=Instance.new("TextButton",f)
b.Size=UDim2.new(0,200,0,40)
b.Position=UDim2.new(.5,-100,.5,-20)
b.BackgroundColor3=Color3.fromRGB(28,32,42)
b.Text="Disable"
b.TextColor3=Color3.new(1,1,1)
b.Font=Enum.Font.GothamBold
b.BorderSizePixel=0
Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)
b.MouseButton1Click:Connect(function()bsApply(false)S.blk=false end)
S.bsGui=sg
end
pcall(function()R2:Set3dRenderingEnabled(false)end)
else
if S.bsGui then pcall(function()S.bsGui:Destroy()end)S.bsGui=nil end
pcall(function()R2:Set3dRenderingEnabled(true)end)
end
end

-- HIDE NAME
local hideC={}
local function hideApply(on)
if on then
local function h(o)
if o:IsA("Humanoid")then
pcall(function()
o.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
o.NameDisplayDistance=0
o.HealthDisplayDistance=0
end)
end
end
for _,pl in ipairs(Players:GetPlayers())do
if pl.Character then
for _,o in ipairs(pl.Character:GetDescendants())do h(o)end
table.insert(hideC,pl.Character.DescendantAdded:Connect(h))
end
end
table.insert(hideC,Players.PlayerAdded:Connect(function(pl)
pl.CharacterAdded:Connect(function(ch)
for _,o in ipairs(ch:GetDescendants())do h(o)end
table.insert(hideC,ch.DescendantAdded:Connect(h))
end)
end))
else
for _,c in ipairs(hideC)do pcall(function()c:Disconnect()end)end
hideC={}
end
end

getgenv().WL.MiscFns={
fps=fpsApply,
blk=bsApply,
hide=hideApply
}

print("[WL] misc loaded")
local WL=getgenv().WL
if not WL then return end
local S=WL.S
local U=WL.util
local HS=WL.HS
local LP=WL.LP

local function send(full)
if not S.wh or S.url=="" or type(request)~="function" then return false,"off" end
local gm,st=0,0
local ls=LP:FindFirstChild("leaderstats")
if ls then
local x=ls:FindFirstChild("Gems")
local y=ls:FindFirstChild("Stars")
if x then gm=tonumber(x.Value)or 0 end
if y then st=tonumber(y.Value)or 0 end
end
local f={}
f[#f+1]={name="Cash",value=tostring(U.cs()),inline=true}
f[#f+1]={name="Gems",value=tostring(gm),inline=true}
f[#f+1]={name="Stars",value=tostring(st),inline=true}
f[#f+1]={name="Wave",value=tostring(U.wv()),inline=true}
if full then
f[#f+1]={name="Towers",value=tostring(#U.mn()),inline=true}
f[#f+1]={name="PlaceId",value=tostring(game.PlaceId),inline=false}
end
local em={
title="wertlaider · "..LP.Name,
description="`"..LP.DisplayName.."` · `"..LP.UserId.."`",
color=3968255,
fields=f,
footer={text="wertlaider"},
timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")
}
local pl={username="wertlaider",embeds={em}}
local ok,err=pcall(function()
request({
Url=S.url,
Method="POST",
Headers={["Content-Type"]="application/json"},
Body=HS:JSONEncode(pl)
})
end)
if ok then return true,"ok" end
return false,tostring(err)
end

local function test()
if S.url=="" or type(request)~="function" then return false end
return pcall(function()
request({
Url=S.url,
Method="POST",
Headers={["Content-Type"]="application/json"},
Body=HS:JSONEncode({content="wertlaider · test"})
})
end)
end

getgenv().WL.WebhookFns={
send=send,
test=test
}

print("[WL] webhook loaded")
local WL=getgenv().WL
if not WL then return end
local S=WL.S

local RF=loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window=RF:CreateWindow({
Title="wertlaider",
Author="wertlaider",
Folder="Wertlaider",
Icon="gamepad-2",
Theme="Dark",
Size=UDim2.fromOffset(420,340),
Transparent=true,
HideSearchBar=true,
NewElements=true,
ToggleKey=Enum.KeyCode.RightShift,
OpenButton={Title="wertlaider",Enabled=true,Draggable=true,OnlyMobile=false}
})

local function notify(t,c)
pcall(function()RF:Notify({Title=t,Content=c,Duration=3,Icon="bell"})end)
end

-- MACROS
local TM=Window:Tab({Title="Macros",Icon="clapperboard"})
TM:Input({Title="Profile",Placeholder="default",Value="default",Callback=function(v)S.Mac.prof=v end})
TM:Toggle({Title="REC",Value=false,Callback=function(v)
if v then WL.MacroFns.start(S.Mac.prof)else WL.MacroFns.stop()end
end})
TM:Button({Title="LOAD",Callback=function()
local ok=WL.MacroFns.load(S.Mac.prof)
notify("Macro",ok and "Загружено" or "Ошибка")
end})
TM:Button({Title="PLAY",Callback=function()WL.MacroFns.play()end})
TM:Button({Title="STOP",Callback=function()WL.MacroFns.stopPlay()end})

-- ANTI-MACRO
local TA=Window:Tab({Title="Anti-Macro",Icon="shield"})
TA:Toggle({Title="Auto Anti-Macro",Value=false,Callback=function(v)S.am=v end})
TA:Slider({Title="Мин задержка",Step=0.1,Value={Min=0.1,Max=3,Default=0.4},Callback=function(v)S.am1=v end})
TA:Slider({Title="Макс задержка",Step=0.1,Value={Min=0.2,Max=5,Default=1.0},Callback=function(v)S.am2=v end})

-- MATCH
local TMt=Window:Tab({Title="Match",Icon="crosshair"})
TMt:Toggle({Title="Auto Place",Value=false,Callback=function(v)S.ap=v end})
TMt:Slider({Title="Задержка башня",Step=0.5,Value={Min=1,Max=20,Default=4},Callback=function(v)S.d_ap=v end})
TMt:Slider({Title="Рандом %",Step=5,Value={Min=0,Max=100,Default=40},Callback=function(v)S.r_ap=v end})
TMt:Toggle({Title="Auto Upgrade",Value=false,Callback=function(v)S.au=v end})
TMt:Slider({Title="Задержка апгрейд",Step=0.5,Value={Min=1,Max=30,Default=8},Callback=function(v)S.d_au=v end})
TMt:Toggle({Title="Auto Sell All",Value=false,Callback=function(v)S.sel=v end})
TMt:Slider({Title="Продать на волне",Step=10,Value={Min=10,Max=500,Default=100},Callback=function(v)S.sellW=v end})

-- CONTROL
local TC=Window:Tab({Title="Control",Icon="settings-2"})
TC:Toggle({Title="Auto Skip",Value=false,Callback=function(v)S.sk=v end})
TC:Toggle({Title="Auto Speed",Value=false,Callback=function(v)S.sp=v end})
TC:Slider({Title="Speed",Step=1,Value={Min=1,Max=5,Default=5},Callback=function(v)S.sv=v end})
TC:Toggle({Title="Auto Vote Map",Value=false,Callback=function(v)S.vm=v end})
TC:Toggle({Title="Auto Vote Comp",Value=false,Callback=function(v)S.vc=v end})

-- ABILITY
local TAb=Window:Tab({Title="Ability",Icon="zap"})
TAb:Toggle({Title="Auto Ability",Value=false,Callback=function(v)S.ab=v end})

-- LOBBY
local TL=Window:Tab({Title="Lobby",Icon="door-open"})
TL:Toggle({Title="Auto Summon",Value=false,Callback=function(v)S.sum=v end})
TL:Slider({Title="Summon Amount",Step=1,Value={Min=1,Max=50,Default=10},Callback=function(v)S.sumA=v end})
TL:Slider({Title="Summon Delay",Step=0.5,Value={Min=0.5,Max=10,Default=1.5},Callback=function(v)S.sumD=v end})
TL:Toggle({Title="Auto Buy Crate",Value=false,Callback=function(v)S.buy=v end})
TL:Toggle({Title="Auto Open Crate",Value=false,Callback=function(v)S.opn=v end})
TL:Slider({Title="Crate Amount",Step=1,Value={Min=1,Max=10,Default=1},Callback=function(v)S.crateA=v end})
TL:Toggle({Title="Auto Elevator",Value=false,Callback=function(v)S.lobby=v end})

-- MISC
local TMs=Window:Tab({Title="Misc",Icon="sliders"})
TMs:Toggle({Title="Auto Jump",Value=false,Callback=function(v)S.jump=v end})
TMs:Toggle({Title="Walk Around",Value=false,Callback=function(v)S.walk=v end})
TMs:Toggle({Title="FPS Boost",Value=false,Callback=function(v)S.fps=v WL.MiscFns.fps(v)end})
TMs:Toggle({Title="Black Screen",Value=false,Callback=function(v)S.blk=v WL.MiscFns.blk(v)end})
TMs:Toggle({Title="Hide Name",Value=false,Callback=function(v)S.hid=v WL.MiscFns.hide(v)end})

-- END
local TE=Window:Tab({Title="End",Icon="log-out"})
TE:Button({Title="Replay",Callback=function()S.endAct="Replay"end})
TE:Button({Title="New Map",Callback=function()S.endAct="New Map"end})
TE:Button({Title="Return Lobby",Callback=function()S.endAct="Lobby"end})
TE:Button({Title="Off",Callback=function()S.endAct="None"end})

-- DISCORD
local TD=Window:Tab({Title="Discord",Icon="webhook"})
TD:Input({Title="Webhook URL",Placeholder="https://...",Value=S.url,Callback=function(v)S.url=v end})
TD:Toggle({Title="Enable Webhook",Value=true,Callback=function(v)S.wh=v end})
TD:Button({Title="SEND NOW",Callback=function()
local ok=WL.WebhookFns.send(false)
notify("Webhook",ok and "Отправлено" or "Ошибка")
end})
TD:Button({Title="SEND FULL",Callback=function()
local ok=WL.WebhookFns.send(true)
notify("Webhook",ok and "Full отправлен" or "Ошибка")
end})
TD:Button({Title="TEST",Callback=function()
local ok=WL.WebhookFns.test()
notify("Webhook",ok and "Тест ушёл" or "Провал")
end})

notify("wertlaider","Загружен")
print("[WL] ui loaded")
