local P=game:GetService("Players")local T=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")local HS=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")local WS=game:GetService("Workspace")
local L=game:GetService("Lighting")
local LP=P.LocalPlayer local pg=LP:WaitForChild("PlayerGui")
local ID="rbxassetid://130176754065007"
local A=Color3.fromRGB(60,140,255)local B=Color3.fromRGB(28,32,42)
local BG=Color3.fromRGB(18,20,26)local SB=Color3.fromRGB(22,25,32)
local TX=Color3.fromRGB(235,238,245)local D=Color3.fromRGB(140,148,168)
local TR=Color3.fromRGB(45,50,62)

local R={}
local fn=RS:FindFirstChild("Functions")local ev=RS:FindFirstChild("Events")
local rm=RS:FindFirstChild("Remotes")
R.Req=fn and fn:FindFirstChild("RequestTower")
R.Spawn=fn and fn:FindFirstChild("SpawnTower")
R.Upg=fn and fn:FindFirstChild("UpgradeTower")
R.Sell=fn and fn:FindFirstChild("SellTower")
R.Skip=fn and fn:FindFirstChild("VoteSkip")
R.Spd=fn and fn:FindFirstChild("ChangeSpeed")
R.Place=fn and fn:FindFirstChild("GetPlayerPlacement")
R.Data=rm and rm:FindFirstChild("PlayerData")and rm.PlayerData:FindFirstChild("GetData")
R.Sum=rm and rm:FindFirstChild("Summon")and rm.Summon:FindFirstChild("Summon")
R.SumP=rm and rm:FindFirstChild("Summon")and rm.Summon:FindFirstChild("SummonPremium")
local am=ev and ev:FindFirstChild("AntiMacro")
R.ACheck=am and am:FindFirstChild("Check")
R.AResp=am and am:FindFirstChild("Respond")
R.VMap=ev and ev:FindFirstChild("VoteForMap")
R.VComp=ev and ev:FindFirstChild("VoteForComplication")
R.Ability=ev and ev:FindFirstChild("ActivateAbility")
R.Exit=ev and ev:FindFirstChild("ExitGame")
R.EndDec=ev and ev:FindFirstChild("EndDecision")
R.EnterEl=ev and ev:FindFirstChild("EnterElevator")
R.StartEl=ev and ev:FindFirstChild("StartElevator")

local W="https://discord.com/api/webhooks/1540650813767032914/hUy6M_Ouz_6m2VR3a-N9C_gj-uD40tgRmMzzW2Z6vLD_mQW_uYFAkxXOLkap88eoh4Fd"

local S={am=false,ap=false,au=false,sel=false,sk=false,sp=false,ab=false,
wh=true,url=W,vmap=false,vcomp=false,sum=false,lobby=false,endAct="None",
jump=false,walk=false,fps=false,black=false,hide=false,
d_ap=4,r_ap=40,d_au=8,sv=5,am_min=0.4,am_max=1.0,sellW=100,sumAmt=10,sumD=1.5,
tok=nil,tokT=0,busy=false,lp=0,lu=0,ls=0,lsp=0,lsel=0,lsum=0,ljump=0,
fpsOrig={},fpsConn=nil,blackGui=nil,walkCenter=nil,walkChar=nil,walkSerial=0}

local function rnd(b,p)if p<=0 then return b end local s=b*(p/100)return b-s/2+math.random()*s end
local function wv()local i=WS:FindFirstChild("Info")local w=i and i:FindFirstChild("Wave")return w and tonumber(w.Value)or 0 end
local function rn()local i=WS:FindFirstChild("Info")local g=i and i:FindFirstChild("GameRunning")return g and g.Value end
local function cs()local c=LP:FindFirstChild("Cash")return c and tonumber(c.Value)or 0 end
local function sd()local i=WS:FindFirstChild("Info")local s=i and i:FindFirstChild("SpeedGame")return s and tonumber(s.Value)or 1 end
local function vm()local i=WS:FindFirstChild("Info")local v=i and i:FindFirstChild("Voting")return v and v.Value end
local function vc()local i=WS:FindFirstChild("Info")local v=i and i:FindFirstChild("ComplicationVoting")return v and v.Value end
local function mn()local o={}local t=WS:FindFirstChild("Towers")if not t then return o end
for _,v in ipairs(t:GetChildren())do local c=v:FindFirstChild("Config")
local ow=c and c:FindFirstChild("Owner")
if ow and tostring(ow.Value)==LP.Name then table.insert(o,v)end end return o end
local function lv(t)local c=t:FindFirstChild("Config")local l=c and c:FindFirstChild("LVL")return l and tonumber(l.Value)or 0 end
local function eq()local o={}if not R.Data then return o end
local ok,d=pcall(function()return R.Data:InvokeServer()end)
if not ok or type(d)~="table"or type(d.Towers)~="table"then return o end
for n,i in pairs(d.Towers)do if type(i)=="table"then local s=tonumber(i.Equipped)
if s and s>=1 and s<=6 then o[s]={v=tostring(n),b=tostring(i.Name or n)}end end end return o end

-- ANTI-MACRO
local function uu(v,d)d=(d or 0)+1 if d>4 then return nil end
if type(v)=="string"then if v:match("^[%x]+%-%x+%-%x+%-%x+%-%x+$")then return v end return nil end
if type(v)=="table"then for _,c in pairs(v)do local r=uu(c,d)if r then return r end end end end
if R.ACheck then R.ACheck.OnClientEvent:Connect(function(...)
local u=uu(table.pack(...))if u then S.tok=u S.tokT=os.clock()end end)end
task.spawn(function()while true do task.wait(0.2)
if S.am and not S.busy then local t=S.tok
if t and(os.clock()-S.tokT)>35 then S.tok=nil t=nil end
if t and R.AResp then S.busy=true
task.wait(S.am_min+math.random()*(S.am_max-S.am_min))
if S.tok==t then pcall(function()R.AResp:FireServer(t)end)S.tok=nil end
S.busy=false end end end end)

-- AUTOPLACE
task.spawn(function()while true do task.wait(0.3)
if S.ap and rn()and R.Place and R.Spawn then local n=os.clock()
if n-S.lp>=rnd(S.d_ap,S.r_ap)then S.lp=n
local ok,pts=pcall(function()return R.Place:InvokeServer()end)
if ok and type(pts)=="table"and#pts>0 then
local e=eq()local idx=0 for s=1,6 do if e[s]then idx=s break end end
if idx>0 then local x=e[idx]local pt=pts[math.random(1,#pts)]
local pos=pt.Position or pt
pcall(function()R.Req:InvokeServer({x.v,x.b},false,true)end)task.wait(0.05)
local cf=CFrame.new(pos+Vector3.new((math.random()-.5)*.6,0,(math.random()-.5)*.6))
pcall(function()R.Spawn:InvokeServer(x.b,cf,false,x.v,{})end)end end end end end end)

-- AUTOUPGRADE
task.spawn(function()while true do task.wait(0.3)
if S.au and rn()and R.Upg then local n=os.clock()
if n-S.lu>=rnd(S.d_au,S.r_ap)then S.lu=n
local t=mn()if#t>0 then table.sort(t,function(a,b)return lv(a)<lv(b)end)
local x=t[1]if x and x.Parent then pcall(function()R.Upg:InvokeServer(x,tostring(x.Name))end)end end end end end end)

-- AUTOSELL
task.spawn(function()while true do task.wait(0.5)
if S.sel and rn()and wv()>=S.sellW and R.Sell then
if os.clock()-S.lsel>3 then S.lsel=os.clock()
for _,t in ipairs(mn())do if t and t.Parent then pcall(function()R.Sell:InvokeServer(t)end)task.wait(0.1)end end end end end end)

-- SKIP/SPEED/VOTE/ABILITY
task.spawn(function()while true do task.wait(1)
if S.sk and rn()and R.Skip and os.clock()-S.ls>3 then S.ls=os.clock()pcall(function()R.Skip:InvokeServer()end)end
if S.sp and rn()and R.Spd and sd()~=S.sv and os.clock()-S.lsp>2 then S.lsp=os.clock()pcall(function()R.Spd:InvokeServer(S.sv)end)end
if S.vmap and vm()and R.VMap then pcall(function()R.VMap:FireServer("Base")end)end
if S.vcomp and vc()and R.VComp then pcall(function()R.VComp:FireServer("Normal")end)end
if S.ab and rn()and R.Ability then for _,t in ipairs(mn())do if t and t.Parent then pcall(function()R.Ability:FireServer(t)end)end end end
end end)

-- SUMMON
task.spawn(function()while true do task.wait(0.5)
if S.sum and rn()and R.Sum and os.clock()-S.lsum>=S.sumD then S.lsum=os.clock()
pcall(function()R.Sum:InvokeServer(S.sumAmt)end)end end end)

-- LOBBY (elevator)
task.spawn(function()while true do task.wait(1)
if S.lobby and R.EnterEl and R.StartEl then
local els=WS:FindFirstChild("Elevators")
if els then for _,e in ipairs(els:GetChildren())do
if e:IsA("Model")and not tostring(e:GetAttribute("IsRaid")):lower()=="true"then
pcall(function()R.EnterEl:FireServer(e.Name)end)task.wait(0.5)
pcall(function()R.StartEl:FireServer(e.Name)end)break end end end end end end)

-- END ACTION
task.spawn(function()while true do task.wait(3)
if S.endAct=="Replay"and R.EndDec then pcall(function()R.EndDec:FireServer(true)end)
elseif S.endAct=="New Map"and R.EndDec then pcall(function()R.EndDec:FireServer("new")end)
elseif S.endAct=="Lobby"and R.Exit then pcall(function()R.Exit:FireServer()end)end end end)

-- AUTO JUMP
task.spawn(function()while true do task.wait(1)
if S.jump then local ch=LP.Character local hum=ch and ch:FindFirstChildOfClass("Humanoid")
if hum and not hum.Sit and hum.FloorMaterial~=Enum.Material.Air then
pcall(function()hum.Jump=true end)end end end end)

-- WALK AROUND
task.spawn(function()while true do task.wait(0.5)
if S.walk then local ch=LP.Character local hum=ch and ch:FindFirstChildOfClass("Humanoid")
local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
if hum and hrp then
S.walkCenter=S.walkCenter or hrp.CFrame
local a=math.random()*math.pi*2 local r=math.random(5,15)
local target=S.walkCenter.Position+Vector3.new(math.cos(a)*r,0,math.sin(a)*r)
pcall(function()hum:MoveTo(target)end)end end end end)

-- FPS BOOST
local function fpsApply(on)
if on then if not S.fpsConn then S.fpsConn=WS.DescendantAdded:Connect(function(o)
if o:IsA("ParticleEmitter")or o:IsA("Trail")or o:IsA("Beam")or o:IsA("Smoke")
or o:IsA("Fire")or o:IsA("Sparkles")then pcall(function()
S.fpsOrig[o]=o.Enabled o.Enabled=false end)end end)end
for _,o in ipairs(WS:GetDescendants())do
if o:IsA("ParticleEmitter")or o:IsA("Trail")or o:IsA("Beam")or o:IsA("Smoke")
or o:IsA("Fire")or o:IsA("Sparkles")then pcall(function()
if S.fpsOrig[o]==nil then S.fpsOrig[o]=o.Enabled end o.Enabled=false end)end end
pcall(function()L.GlobalShadows=false end)
else if S.fpsConn then pcall(function()S.fpsConn:Disconnect()end)S.fpsConn=nil end
for o,v in pairs(S.fpsOrig)do pcall(function()if o.Parent then o.Enabled=v end end)end
S.fpsOrig={}pcall(function()L.GlobalShadows=true end)end end

-- BLACK SCREEN
local function blackApply(on)
if on then if not S.blackGui then
local sg=Instance.new("ScreenGui")sg.Name="wertlaider_bs"sg.ResetOnSpawn=false
sg.IgnoreGuiInset=true sg.DisplayOrder=9998
sg.Parent=(gethui and gethui())or pg
local f=Instance.new("Frame",sg)f.Size=UDim2.new(1,0,1,0)f.BackgroundColor3=Color3.new(0,0,0)
f.BorderSizePixel=0
local b=Instance.new("TextButton",f)b.Size=UDim2.new(0,200,0,40)
b.Position=UDim2.new(.5,-100,.5,-20)b.BackgroundColor3=Color3.fromRGB(40,44,56)
b.Text="Disable Black Screen"b.TextColor3=Color3.new(1,1,1)b.Font=Enum.Font.GothamBold
b.TextSize=13 b.BorderSizePixel=0
Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)
b.MouseButton1Click:Connect(function()blackApply(false)S.black=false end)
S.blackGui=sg end
pcall(function()game:GetService("RunService"):Set3dRenderingEnabled(false)end)
else if S.blackGui then pcall(function()S.blackGui:Destroy()end)S.blackGui=nil end
pcall(function()game:GetService("RunService"):Set3dRenderingEnabled(true)end)end end

-- HIDE NAME
local hideConns={}
local function hideApply(on)
if on then
local function hide(o)if o:IsA("Humanoid")then
pcall(function()o.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
o.NameDisplayDistance=0 o.HealthDisplayDistance=0 end)end end
for _,pl in ipairs(P:GetPlayers())do if pl.Character then
for _,o in ipairs(pl.Character:GetDescendants())do hide(o)end
table.insert(hideConns,pl.Character.DescendantAdded:Connect(hide))end end
table.insert(hideConns,P.PlayerAdded:Connect(function(pl)
pl.CharacterAdded:Connect(function(ch)
for _,o in ipairs(ch:GetDescendants())do hide(o)end
table.insert(hideConns,ch.DescendantAdded:Connect(hide))end)end))
else for _,c in ipairs(hideConns)do pcall(function()c:Disconnect()end)end
hideConns={}end end

-- WEBHOOK
local function send(full)
if not S.wh or S.url==""or type(request)~="function"then return false end
local gm,st=0,0 local ls=LP:FindFirstChild("leaderstats")
if ls then local x=ls:FindFirstChild("Gems")local y=ls:FindFirstChild("Stars")
if x then gm=tonumber(x.Value)or 0 end if y then st=tonumber(y.Value)or 0 end end
local f={{name="Cash",value=tostring(cs()),inline=true},
{name="Gems",value=tostring(gm),inline=true},
{name="Stars",value=tostring(st),inline=true},
{name="Wave",value=tostring(wv()),inline=true}}
if full then table.insert(f,{name="Towers",value=tostring(#mn()),inline=true})
table.insert(f,{name="PlaceId",value=tostring(game.PlaceId),inline=false})end
return pcall(function()request({Url=S.url,Method="POST",
Headers={["Content-Type"]="application/json"},
Body=HS:JSONEncode({username="wertlaider",
embeds={{title="wertlaider · "..LP.Name,
description="`"..LP.DisplayName.."` · `"..LP.UserId.."`",
color=0x3C8CFF,fields=f,footer={text="wertlaider"},
timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}})})end)end

-- UI
local g=Instance.new("ScreenGui",(gethui and gethui())or pg)
g.Name="wertlaider"g.IgnoreGuiInset=true g.ResetOnSpawn=false g.DisplayOrder=9999
local i=Instance.new("ImageButton",g)i.Size=UDim2.new(0,58,0,58)
i.Position=UDim2.new(0,22,0,120)i.BackgroundTransparency=1 i.Image=ID
i.ScaleType=Enum.ScaleType.Fit i.ZIndex=99
local WW,HH=370,320
local w=Instance.new("Frame",g)w.Size=UDim2.new(0,0,0,0)
w.Position=UDim2.new(0.5,-WW/2,0.5,-HH/2)w.BackgroundColor3=BG
w.BorderSizePixel=0 w.ClipsDescendants=true w.Visible=false w.Active=true w.ZIndex=10
Instance.new("UICorner",w).CornerRadius=UDim.new(0,12)
local sk2=Instance.new("UIStroke",w)sk2.Color=A sk2.Thickness=2
local hd=Instance.new("Frame",w)hd.Size=UDim2.new(1,0,0,34)
hd.BackgroundColor3=B hd.BorderSizePixel=0
Instance.new("UICorner",hd).CornerRadius=UDim.new(0,12)
local tt=Instance.new("TextLabel",hd)tt.Size=UDim2.new(1,-50,1,0)
tt.Position=UDim2.new(0,14,0,0)tt.BackgroundTransparency=1 tt.Text="wertlaider"
tt.TextColor3=TX tt.Font=Enum.Font.GothamBold tt.TextSize=13
tt.TextXAlignment=Enum.TextXAlignment.Left
local xb=Instance.new("TextButton",hd)xb.Size=UDim2.new(0,22,0,20)
xb.Position=UDim2.new(1,-28,0,7)xb.BackgroundColor3=B xb.Text="×"
xb.TextColor3=TX xb.Font=Enum.Font.GothamBold xb.TextSize=15 xb.BorderSizePixel=0
Instance.new("UICorner",xb).CornerRadius=UDim.new(0,6)
local sb=Instance.new("Frame",w)sb.Size=UDim2.new(0,100,1,-44)
sb.Position=UDim2.new(0,6,0,40)sb.BackgroundColor3=SB sb.BorderSizePixel=0
Instance.new("UICorner",sb).CornerRadius=UDim.new(0,9)
local ll=Instance.new("UIListLayout",sb)ll.Padding=UDim.new(0,2)ll.SortOrder=Enum.SortOrder.LayoutOrder
local cn=Instance.new("Frame",w)cn.Size=UDim2.new(1,-118,1,-44)
cn.Position=UDim2.new(0,114,0,40)cn.BackgroundTransparency=1

local tabs,pages={},{}
local function tab(n,label)
local p=Instance.new("ScrollingFrame",cn)p.Size=UDim2.new(1,0,1,0)
p.BackgroundTransparency=1 p.BorderSizePixel=0 p.ScrollBarThickness=3
p.ScrollBarImageColor3=A p.AutomaticCanvasSize=Enum.AutomaticSize.Y
p.CanvasSize=UDim2.new(0,0,0,0)p.Visible=false
local l=Instance.new("UIListLayout",p)l.Padding=UDim.new(0,5)l.SortOrder=Enum.SortOrder.LayoutOrder
local pd=Instance.new("UIPadding",p)pd.PaddingTop=UDim.new(0,4)pd.PaddingRight=UDim.new(0,4)
pages[n]=p
local b=Instance.new("TextButton",sb)b.Size=UDim2.new(1,0,0,26)
b.BackgroundColor3=SB b.Text="  "..label b.TextColor3=D b.Font=Enum.Font.GothamBold
b.TextSize=11 b.TextXAlignment=Enum.TextXAlignment.Left b.BorderSizePixel=0
Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
b.MouseButton1Click:Connect(function()
for k,v in pairs(pages)do v.Visible=(k==n)end
for k,v in pairs(tabs)do v.BackgroundColor3=(k==n)and A or SB
v.TextColor3=(k==n)and TX or D end end)
tabs[n]=b return p end

local function tg(p,label,init,cb)
local r=Instance.new("Frame",p)r.Size=UDim2.new(1,0,0,36)
r.BackgroundColor3=B r.BorderSizePixel=0
Instance.new("UICorner",r).CornerRadius=UDim.new(0,8)
local t=Instance.new("TextLabel",r)t.Size=UDim2.new(1,-70,1,0)
t.Position=UDim2.new(0,12,0,0)t.BackgroundTransparency=1 t.Text=label
t.TextColor3=TX t.Font=Enum.Font.Gotham t.TextSize=12
t.TextXAlignment=Enum.TextXAlignment.Left
local pl=Instance.new("Frame",r)pl.Size=UDim2.new(0,42,0,22)
pl.Position=UDim2.new(1,-52,0.5,-11)
pl.BackgroundColor3=init and A or TR pl.BorderSizePixel=0
Instance.new("UICorner",pl).CornerRadius=UDim.new(1,0)
local dt=Instance.new("Frame",pl)dt.Size=UDim2.new(0,16,0,16)
dt.Position=init and UDim2.new(1,-19,0,3)or UDim2.new(0,3,0,3)
dt.BackgroundColor3=Color3.new(1,1,1)dt.BorderSizePixel=0
Instance.new("UICorner",dt).CornerRadius=UDim.new(1,0)
local b=Instance.new("TextButton",r)b.Size=UDim2.new(1,0,1,0)
b.BackgroundTransparency=1 b.Text=""
local s=init b.MouseButton1Click:Connect(function()
s=not s pl.BackgroundColor3=s and A or TR
dt.Position=s and UDim2.new(1,-19,0,3)or UDim2.new(0,3,0,3)cb(s)end)end

local function sl(p,label,mn2,mx,stp,init,suf,cb)
local r=Instance.new("Frame",p)r.Size=UDim2.new(1,0,0,56)
r.BackgroundColor3=B r.BorderSizePixel=0
Instance.new("UICorner",r).CornerRadius=UDim.new(0,8)
local t=Instance.new("TextLabel",r)t.Size=UDim2.new(1,-80,0,16)
t.Position=UDim2.new(0,12,0,6)t.BackgroundTransparency=1 t.Text=label
t.TextColor3=TX t.Font=Enum.Font.Gotham t.TextSize=12
t.TextXAlignment=Enum.TextXAlignment.Left
local v=Instance.new("TextLabel",r)v.Size=UDim2.new(0,60,0,16)
v.Position=UDim2.new(1,-72,0,6)v.BackgroundTransparency=1
v.Text=tostring(init)..(suf or"")v.TextColor3=A v.Font=Enum.Font.GothamBold
v.TextSize=12 v.TextXAlignment=Enum.TextXAlignment.Right
local tr=Instance.new("Frame",r)tr.Size=UDim2.new(1,-24,0,4)
tr.Position=UDim2.new(0,12,0,40)tr.BackgroundColor3=TR tr.BorderSizePixel=0
Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0)
local fl=Instance.new("Frame",tr)fl.Size=UDim2.new((init-mn2)/(mx-mn2),0,1,0)
fl.BackgroundColor3=A fl.BorderSizePixel=0
Instance.new("UICorner",fl).CornerRadius=UDim.new(1,0)
local kn=Instance.new("Frame",tr)kn.Size=UDim2.new(0,14,0,14)
kn.Position=UDim2.new((init-mn2)/(mx-mn2),-7,0.5,-7)
kn.BackgroundColor3=TX kn.BorderSizePixel=0
Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
local hit=Instance.new("TextButton",r)hit.Size=UDim2.new(1,0,0,24)
hit.Position=UDim2.new(0,0,0,30)hit.BackgroundTransparency=1 hit.Text=""
local dr=false
local function set(x)
local rl=math.clamp((x-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
local val=math.floor((mn2+rl*(mx-mn2))/stp+0.5)*stp
val=math.clamp(val,mn2,mx)
fl.Size=UDim2.new((val-mn2)/(mx-mn2),0,1,0)
kn.Position=UDim2.new((val-mn2)/(mx-mn2),-7,0.5,-7)
v.Text=(stp<1 and string.format("%.2f",val)or tostring(val))..(suf or"")
cb(val)end
hit.InputBegan:Connect(function(inp)
if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then
dr=true set(inp.Position.X)end end)
hit.InputChanged:Connect(function(inp)
if dr and(inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseMovement)then
set(inp.Position.X)end end)
hit.InputEnded:Connect(function(inp)
if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then
dr=false end end)end

local function bt(p,label,cb,col)
local b=Instance.new("TextButton",p)b.Size=UDim2.new(1,0,0,36)
b.BackgroundColor3=col or B b.Text=label b.TextColor3=TX
b.Font=Enum.Font.GothamBold b.TextSize=12 b.BorderSizePixel=0
Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
b.MouseButton1Click:Connect(cb)end

local function inp(p,label,ph,cb,init)
local r=Instance.new("Frame",p)r.Size=UDim2.new(1,0,0,56)
r.BackgroundColor3=B r.BorderSizePixel=0
Instance.new("UICorner",r).CornerRadius=UDim.new(0,8)
local t=Instance.new("TextLabel",r)t.Size=UDim2.new(1,-24,0,14)
t.Position=UDim2.new(0,12,0,4)t.BackgroundTransparency=1 t.Text=label
t.TextColor3=D t.Font=Enum.Font.Gotham t.TextSize=10
t.TextXAlignment=Enum.TextXAlignment.Left
local b=Instance.new("TextBox",r)b.Size=UDim2.new(1,-24,0,26)
b.Position=UDim2.new(0,12,0,22)b.BackgroundColor3=Color3.fromRGB(38,44,56)
b.PlaceholderText=ph b.PlaceholderColor3=D b.Text=init or""
b.TextColor3=TX b.Font=Enum.Font.Code b.TextSize=11
b.TextXAlignment=Enum.TextXAlignment.Left b.ClearTextOnFocus=false b.BorderSizePixel=0
Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,8)
b.FocusLost:Connect(function()cb(b.Text)end)end

-- BUILD
local pAM=tab("Anti","Anti-Macro")
tg(pAM,"Auto Anti-Macro",false,function(v)S.am=v end)
sl(pAM,"Задержка min",0.1,3,0.1,0.4,"s",function(v)S.am_min=v end)
sl(pAM,"Задержка max",0.2,5,0.1,1.0,"s",function(v)S.am_max=v end)

local pM=tab("Match","Match")
tg(pM,"Auto Place",false,function(v)S.ap=v end)
sl(pM,"Задержка башня",1,20,0.5,4,"s",function(v)S.d_ap=v end)
sl(pM,"Рандомизация",0,100,5,40,"%",function(v)S.r_ap=v end)
tg(pM,"Auto Upgrade",false,function(v)S.au=v end)
sl(pM,"Задержка апгрейд",1,30,0.5,8,"s
