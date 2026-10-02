local VARIANT_SUFFIXES = {" Gold", " Rainbow", " Shiny", " Void"}

local function unitVariant(name)
    local s = tostring(name or "")
    for _, suf in ipairs(VARIANT_SUFFIXES) do
        if s:sub(-#suf) == suf then
            if suf == " Shiny" or suf == " Gold" then return "Shiny" end
            return "Void"
        end
    end
    return "Normal"
end

local function unitBase(name)
    local s = tostring(name or "")
    for _, suf in ipairs(VARIANT_SUFFIXES) do
        if s:sub(-#suf) == suf then
            local b = s:sub(1, #s - #suf)
            if b ~= "" then return b end
        end
    end
    return s
end
Stage("part1/4-config")
local SAVE_KEYS = {
    "am","sel","sk","sp","vm","vc","vmut",
    "mutPick","mutSel","mutPri","mutCat",
    "sum","sumCur","sumA","sumD",
    "buy","opn","crate","crateA","crateD",
    "lobby","jump","walk","fps","blk","hid",
    "endAct","mapV","compV","sv",
    "am1","am2","sellW","wh","url",
    "elevType","macroName","macroSpeed",
    "ab","abWave","abWaveOn","abBoss","abDelay"
}

local function loadUrl()
    local ok, c = pcall(function() return readfile("wl_webhook.txt") end)
    if ok and c and c ~= "" then return c:gsub("%s","") end
    return DEF_URL
end
local function saveCfg(S)
    local out = {}
    for _, k in ipairs(SAVE_KEYS) do out[k] = S[k] end
    pcall(function() writefile(SAVE_FILE, HS:JSONEncode(out)) end)
end
local function loadCfg(S)
    local ok, d = pcall(function() return HS:JSONDecode(readfile(SAVE_FILE)) end)
    if ok and type(d) == "table" then
        for _, k in ipairs(SAVE_KEYS) do
            if d[k] ~= nil then S[k] = d[k] end
        end
        return true
    end
    return false
end

Stage("part1/5-state")
local S = {
    Running=true,
    am=false, sel=false, sk=false, sp=false,
    vm=false, vc=false, vmut=false,
    mutPick="Priority", mutSel={}, mutPri={}, mutCat={},
    sum=false, sumCur="Cash", sumA=10, sumD=1.5,
    buy=false, opn=false, crate="Still Life Crate", crateA=1, crateD=2,
    lobby=false, jump=false, walk=false,
    fps=false, blk=false, hid=false,
    endAct="None", mapV="Base", compV="Normal",
    sv=5,
    am1=0.4, am2=1.0, sellW=100,
    wh=true, url=loadUrl(),
    tok=nil, tokT=0, busy=false,
    lp=0, lu=0, ls=0, lsp=0, lsel=0, lsum=0, lcr=0,
    fpsO=setmetatable({},{__mode="k"}), fpsC=nil, bsGui=nil, walkC=nil,
    abCd=setmetatable({},{__mode="k"}),
    elevType="Auto",
    macroName="", macroRec=false, macroPlay=false,
    macroActions={}, macroT0=0, macroSpeed=1, macroPlaceId=nil,
    ab=false, abWave=1, abWaveOn=false, abBoss=false, abDelay=5,
    tracker={start=os.time(), startCash=0, startGems=0, startMaterials={}, matches=0, lastMatchEnd=0, lastReport=os.time()}
}
loadCfg(S)
S.url = loadUrl()

Stage("part1/6-utils")
local function rnd(b, p)
    if p <= 0 then return b end
    local s = b * (p / 100)
    return b - s/2 + math.random() * s
end
local function wv()
    local i = WS:FindFirstChild("Info")
    local w = i and i:FindFirstChild("Wave")
    return w and tonumber(w.Value) or 0
end
local function rn()
    local i = WS:FindFirstChild("Info")
    local g = i and i:FindFirstChild("GameRunning")
    return g and g.Value
end
local function sd()
    local i = WS:FindFirstChild("Info")
    local s = i and i:FindFirstChild("SpeedGame")
    return s and tonumber(s.Value) or 1
end
local function ivm()
    local i = WS:FindFirstChild("Info")
    local v = i and i:FindFirstChild("Voting")
    return v and v.Value
end
local function ivc()
    local i = WS:FindFirstChild("Info")
    local v = i and i:FindFirstChild("ComplicationVoting")
    return v and v.Value
end

local VARIANT_SUFFIXES = {" Gold", " Rainbow", " Shiny", " Void"}

local function unitVariant(name)
    local s = tostring(name or "")
    for _, suf in ipairs(VARIANT_SUFFIXES) do
        if s:sub(-#suf) == suf then
            if suf == " Shiny" or suf == " Gold" then return "Shiny" end
            return "Void"
        end
    end
    return "Normal"
end

local function unitBase(name)
    local s = tostring(name or "")
    for _, suf in ipairs(VARIANT_SUFFIXES) do
        if s:sub(-#suf) == suf then
            local b = s:sub(1, #s - #suf)
            if b ~= "" then return b end
        end
    end
    return s
end

local mnCacheList, mnCacheAt = {}, 0
local function mn()
    local now = os.clock()
    if now - mnCacheAt < 0.5 then return mnCacheList end
    mnCacheAt = now
    local o = {}
    local t = WS:FindFirstChild("Towers")
    if not t then mnCacheList = o; return o end
    for _, v in ipairs(t:GetChildren()) do
        local c = v:FindFirstChild("Config")
        local ow = c and c:FindFirstChild("Owner")
        if ow and tostring(ow.Value) == LP.Name then table.insert(o, v) end
    end
    mnCacheList = o
    return o
end
local function lv(t)
    local c = t:FindFirstChild("Config")
    local l = c and c:FindFirstChild("LVL")
    return l and tonumber(l.Value) or 0
end
local function readVal(name)
    local v = LP:FindFirstChild(name)
    if v and v:IsA("ValueBase") then
        local n = tonumber(v.Value); if n then return n end
        local s = tostring(v.Value):gsub(",", "")
        n = tonumber(s) or tonumber(s:match("([%d%.]+)"))
        if n then return n end
    end
    local a = LP:GetAttribute(name)
    if type(a) == "number" then return a end
    if type(a) == "string" then
        local s = a:gsub(",", "")
        local n = tonumber(s) or tonumber(s:match("([%d%.]+)"))
        if n then return n end
    end
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        local x = ls:FindFirstChild(name)
        if x and x:IsA("ValueBase") then
            local s = tostring(x.Value):gsub(",", "")
            local n = tonumber(s) or tonumber(s:match("([%d%.]+)"))
            if n then return n end
        end
    end
    return 0
end
local function uu(v, d)
    d = (d or 0) + 1
    if d > 4 then return nil end
    if type(v) == "string" then
        if v:match("^[%x]+%-%x+%-%x+%-%x+%-%x+$") then return v end
        return nil
    end
    if type(v) == "table" then
        for _, c in pairs(v) do
            local r = uu(c, d)
            if r then return r end
        end
    end
end
local function getMaterials()
    local out = {}
    if not R.Data then return out end
    local ok, data = pcall(function() return R.Data:InvokeServer() end)
    if not ok or type(data) ~= "table" then return out end
    local items = data.Items
    if type(items) ~= "table" then return out end
    for name, info in pairs(items) do
        local count = 0
        if type(info) == "table" then
            count = tonumber(info.Count) or tonumber(info.Amount) or tonumber(info.Value) or 0
        elseif type(info) == "number" then count = info end
        out[tostring(name)] = count
    end
    return out
end

Stage("part1/7-tracker")
local function initTracker()
    S.tracker.startCash = readVal("Cash")
    S.tracker.startGems = readVal("Gems")
    S.tracker.startMaterials = getMaterials()
    S.tracker.start = os.time()
    S.tracker.lastReport = os.time()
    S.tracker.matches = 0
    S.tracker.lastMatchEnd = 0
end

task.spawn(function()
    pcall(function()
        local info = WS:WaitForChild("Info", 15)
        if not info then return end
        while S.Running do
            task.wait(1)
            local r = info:FindFirstChild("GameRunning")
            local w = info:FindFirstChild("Wave")
            r and r.Value; w and tonumber(w.Value)
        end
    end)
end)

task.spawn(function()
    pcall(initTracker)
end)

_G.__WL = {
    P=P, RS=RS, WS=WS, HS=HS, L=L, R2=R2, LP=LP,
    R=R, S=S, RF=RF, fn=fn, ev=ev, rm=rm, GetCD=GetCD,
    Log=Log, Stage=Stage, traceLog=traceLog, Confirm=Confirm,
    Watchdog=Watchdog,
    saveCfg=saveCfg, loadCfg=loadCfg, loadUrl=loadUrl,
    rnd=rnd, wv=wv, rn=rn, sd=sd, ivm=ivm, ivc=ivc, mn=mn, lv=lv,
    readVal=readVal, uu=uu, getMaterials=getMaterials, initTracker=initTracker,
    wrapRemote=wrapRemote, unitBase=unitBase, unitVariant=unitVariant,
    _R_orig=_R_orig, DEF_URL=DEF_URL, SAVE_FILE=SAVE_FILE, SAVE_KEYS=SAVE_KEYS,
    TRACE_DIR=TRACE_DIR, TRACE_FILE=TRACE_FILE,
}
local G = _G.__WL
if not G then error("part1 не запущена") end
local P, RS, WS, HS, L, R2, LP = G.P, G.RS, G.WS, G.HS, G.L, G.R2, G.LP
local R, S, RF, fn, ev, rm, GetCD = G.R, G.S, G.RF, G.fn, G.ev, G.rm, G.GetCD
local Log, Stage, traceLog, Confirm = G.Log, G.Stage, G.traceLog, G.Confirm
local Watchdog = G.Watchdog
local saveCfg, loadCfg, loadUrl = G.saveCfg, G.loadCfg, G.loadUrl
local rnd, wv, rn, sd, ivm, ivc = G.rnd, G.wv, G.rn, G.sd, G.ivm, G.ivc
local mn, lv, readVal, uu = G.mn, G.lv, G.readVal, G.uu
local getMaterials, initTracker = G.getMaterials, G.initTracker
local wrapRemote = G.wrapRemote
local unitBase = G.unitBase
local unitVariant = G.unitVariant
local _R_orig = G._R_orig
local DEF_URL, SAVE_FILE, SAVE_KEYS = G.DEF_URL, G.SAVE_FILE, G.SAVE_KEYS
local TRACE_DIR, TRACE_FILE = G.TRACE_DIR, G.TRACE_FILE

Stage("part2/8-antimacro")
local function findAntiBtn()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local root = pg and pg:FindFirstChild("AntiMacroCheck")
    if not root or not root.Enabled then return nil end
    local frame = root:FindFirstChild("Frame")
    local btn = frame and frame:FindFirstChild("TextButton")
    if btn and btn:IsA("GuiButton") then return btn end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("GuiButton") then
            local t = tostring(d.Text):lower():gsub("[^%a]", "")
            if t == "imhere" or t == "ihere" then return d end
        end
    end
    return nil
end

local function isVisible(obj)
    if not obj or not obj:IsDescendantOf(game) then return false end
    local cur = obj
    while cur and cur ~= game do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur:IsA("LayerCollector") and not cur.Enabled then return false end
        cur = cur.Parent
    end
    return true
end

local function clickButton(btn)
    if not btn then return false, "no_btn" end
    local mb = btn.MouseButton1Click
    local ac = btn.Activated
    if type(firesignal) == "function" then
        local sig = mb
        if type(getconnections) == "function" and #getconnections(mb) == 0 then sig = ac end
        if pcall(firesignal, sig) then return true, "firesignal" end
    end
    if type(getconnections) == "function" then
        local conns = getconnections(mb)
        if #conns == 0 then conns = getconnections(ac) end
        local fired = false
        for _, c in ipairs(conns) do
            if type(c.Fire) == "function" then fired = pcall(c.Fire, c) or fired
            elseif type(c.Function) == "function" then fired = pcall(c.Function) or fired end
        end
        if fired then return true, "getconnections" end
    end
    local ok, VIM = pcall(game.GetService, game, "VirtualInputManager")
    if ok and VIM then
        local pos = btn.AbsolutePosition + btn.AbsoluteSize * 0.5
        local ok2 = pcall(function()
            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
        end)
        if ok2 then return true, "VIM" end
    end
    return false, "all_failed"
end

local lastCheckRemote = nil
local lastCheckConnection = nil
local function bindCheck()
    local AM2 = ev and ev:FindFirstChild("AntiMacro")
    local newAC = AM2 and AM2:FindFirstChild("Check")
    if newAC == lastCheckRemote then return end
    if lastCheckConnection then
        pcall(function() lastCheckConnection:Disconnect() end)
        lastCheckConnection = nil
    end
    R.AC = (newAC and newAC:IsA("RemoteEvent")) and newAC or nil
    local newAR = AM2 and AM2:FindFirstChild("Respond")
    R.AR = (newAR and newAR:IsA("RemoteEvent")) and newAR or nil
    lastCheckRemote = newAC
    if R.AC then
        local ok, conn = pcall(function()
            return R.AC.OnClientEvent:Connect(function(...)
                local u = uu(table.pack(...))
                if u then S.tok = u; S.tokT = os.clock() end
            end)
        end)
        if ok then lastCheckConnection = conn end
    end
end

Watchdog.register("antimacro", function()
    while S.Running do
        task.wait(0.25)
        Watchdog.beat("antimacro")
        local ok = pcall(function()
            bindCheck()
            if not S.am or S.busy then return end
            local tok = S.tok
            local btn = findAntiBtn()
            local btnVis = btn and isVisible(btn)
            if tok and (os.clock() - S.tokT) > 35 then S.tok = nil; tok = nil end
            if tok and btnVis and R.AR then
                S.busy = true
                local dmin = math.min(tonumber(S.am1) or 0.4, tonumber(S.am2) or 1.0)
                local dmax = math.max(tonumber(S.am1) or 0.4, tonumber(S.am2) or 1.0)
                task.wait(dmin + math.random() * (dmax - dmin))
                if S.am and S.tok == tok then
                    pcall(function() R.AR:FireServer(tok) end)
                    S.tok = nil
                end
                S.busy = false
            elseif btnVis then
                local lastFallback = S.__lastFallback or 0
                if (os.clock() - lastFallback) >= 2 then
                    S.__lastFallback = os.clock()
                    clickButton(btn)
                end
            end
        end)
        if not ok then task.wait(2) end
    end
end)
Watchdog.spawn("antimacro")

Stage("part2/9-macros")
local MACRO_DIR = "wertlaider_macros"
if type(isfolder) == "function" and type(makefolder) == "function" then
    if not isfolder(MACRO_DIR) then pcall(makefolder, MACRO_DIR) end
end

local function mSan(n)
    n = tostring(n or ""):gsub("[^%w%-_]", "_"):gsub("_+", "_")
    return n:sub(1, 48)
end
local function mPath(n)
    local s = mSan(n); if s == "" then return nil end
    return MACRO_DIR .. "/" .. s .. ".json"
end
local function cfArr(cf) return {cf:GetComponents()} end
local function arrCf(a)
    if type(a) ~= "table" or #a < 12 then return nil end
    return CFrame.new(table.unpack(a, 1, 12))
end
local function tHandle(t)
    local id = t:GetAttribute("ID")
    if id and tostring(id) ~= "" then return tostring(id) end
    return tostring(t.Name)
end

local TowerMeta = setmetatable({}, {__mode="k"})
local RuntimeHandles = {}
local RecorderConns = {}
local NextHandle = 1

local function mPush(a)
    a.Wave = wv()
    a.Time = os.clock() - S.macroT0
    a.Cash = readVal("Cash")
    table.insert(S.macroActions, a)
end

local function mAttach(t, recordPlace)
    if not t or TowerMeta[t] then return end
    local deadline = os.clock() + 3
    while t.Parent and not t:FindFirstChild("Config") and os.clock() < deadline do
        task.wait(0.05)
    end
    if not t.Parent then return end
    local cfg = t:FindFirstChild("Config")
    if not cfg then return end
    local own = cfg:FindFirstChild("Owner")
    if not own or tostring(own.Value) ~= LP.Name then return end

    local handle = NextHandle; NextHandle = NextHandle + 1
    local meta = {Handle=handle, Level=lv(t), Target="", LastUpgradeAt=-math.huge, Removed=false}
    TowerMeta[t] = meta

    local tgtVal = cfg:FindFirstChild("TargetMode")
    if tgtVal and tgtVal:IsA("ValueBase") then meta.Target = tostring(tgtVal.Value) end

    if recordPlace and S.macroRec then
        local price = 0
        local pv = cfg:FindFirstChild("Price")
        if pv then price = tonumber(pv.Value) or 0 end
        local unitId = tHandle(t)
        mPush({
            Type="Place", Handle=handle, Unit=unitId,
            BaseUnit=unitBase(unitId), Variant=unitVariant(unitId),
            CFrame=cfArr(t:GetPivot()), Cost=price,
        })
    end

    local lvlVal = cfg:FindFirstChild("LVL")
    if lvlVal and lvlVal:IsA("ValueBase") then
        table.insert(RecorderConns, lvlVal.Changed:Connect(function()
            local newLvl = tonumber(lvlVal.Value) or meta.Level
            if S.macroRec and newLvl > meta.Level then
                for i = meta.Level + 1, newLvl do
                    local unitId = tHandle(t)
                    mPush({
                        Type="Upgrade", Handle=meta.Handle, Unit=unitId,
                        BaseUnit=unitBase(unitId), Variant=unitVariant(unitId),
                        PreviousLevel=i-1, Level=i,
                    })
                end
                meta.LastUpgradeAt = os.clock()
            end
            meta.Level = newLvl
        end))
    end

    if tgtVal and tgtVal:IsA("ValueBase") then
        table.insert(RecorderConns, tgtVal.Changed:Connect(function()
            local newT = tostring(tgtVal.Value)
            local isUp = (os.clock() - meta.LastUpgradeAt) < 0.8
            if S.macroRec and newT ~= meta.Target and not isUp and newT ~= "" and newT ~= "N/A" then
                mPush({Type="Target", Handle=meta.Handle, Unit=tHandle(t), PreviousMode=meta.Target, Mode=newT})
            end
            meta.Target = newT
        end))
    end

    table.insert(RecorderConns, t.AncestryChanged:Connect(function(_, parent)
        if parent == nil and not meta.Removed then
            meta.Removed = true
            if S.macroRec and rn() then
                mPush({Type="Sell", Handle=meta.Handle, Unit=tHandle(t)})
            end
        end
    end))
end

local function mBind()
    for _, c in ipairs(RecorderConns) do pcall(function() c:Disconnect() end) end
    RecorderConns = {}
    TowerMeta = setmetatable({}, {__mode="k"})
    NextHandle = 1
    local towers = WS:FindFirstChild("Towers")
    if not towers then return false, "Workspace.Towers не найден" end
    for _, t in ipairs(towers:GetChildren()) do mAttach(t, false) end
    table.insert(RecorderConns, towers.ChildAdded:Connect(function(t)
        task.defer(mAttach, t, true)
    end))
    return true
end

local function mStartRec(name)
    if S.macroPlay then return false, "плейбек идёт" end
    if S.macroRec then return false, "уже пишем" end
    name = mSan(name or S.macroName)
    if name == "" then return false, "имя не задано" end
    local towers = WS:FindFirstChild("Towers")
    if not towers then return false, "не в матче" end
    for _, t in ipairs(towers:GetChildren()) do
        local cfg = t:FindFirstChild("Config")
        local own = cfg and cfg:FindFirstChild("Owner")
        if own and tostring(own.Value) == LP.Name then
            return false, "уже есть твои башни — начни чистый матч"
        end
    end
    S.macroName = name
    S.macroActions = {}
    S.macroT0 = os.clock()
    S.macroRec = true
    local ok, err = mBind()
    if not ok then S.macroRec = false; return false, err end
    return true
end
local function mSave()
    local path = mPath(S.macroName)
    if not path then return false, "имя не задано" end
    local payload = {
        version = 1, game = "Slop TD", placeId = game.PlaceId,
        name = S.macroName, recordedAt = os.time(),
        actionCount = #S.macroActions, actions = S.macroActions,
    }
    local ok, encoded = pcall(function() return HS:JSONEncode(payload) end)
    if not ok then return false, "encode fail" end
    local pendingPath = path .. ".pending"
    local w1 = pcall(writefile, pendingPath, encoded)
    if not w1 then return false, "pending write fail" end
    local vok, vdata = pcall(function() return HS:JSONDecode(readfile(pendingPath)) end)
    if not vok or type(vdata) ~= "table" or tonumber(vdata.actionCount) ~= #S.macroActions then
        pcall(function() delfile(pendingPath) end)
        return false, "pending verify fail"
    end
    local bakPath = path .. ".bak"
    if isfile(path) then
        local oldOk, oldContent = pcall(function() return readfile(path) end)
        if oldOk and type(oldContent) == "string" then
            pcall(writefile, bakPath, oldContent)
        end
    end
    local w2 = pcall(writefile, path, encoded)
    if not w2 then return false, "final write fail (backup saved)" end
    local fok, fdata = pcall(function() return HS:JSONDecode(readfile(path)) end)
    if not fok or type(fdata) ~= "table" or tonumber(fdata.actionCount) ~= #S.macroActions then
        return false, "final verify fail (backup preserved)"
    end
    pcall(function() delfile(pendingPath) end)
    return true
end

local function mStopRec(save)
    if not S.macroRec then return false, "не пишем" end
    local count = #S.macroActions
    S.macroRec = false
    for _, c in ipairs(RecorderConns) do pcall(function() c:Disconnect() end) end
    RecorderConns = {}
    if save then
        local ok, err = mSave()
        return ok, ok and count or err
    end
    return true, count
end

local function mLoad(name)
    name = mSan(name or S.macroName)
    local path = mPath(name)
    if not path then return false, "имя не задано" end
    local candidates = { path, path .. ".bak", path .. ".pending" }
    local lastErr = "файл не найден"
    local found = false
    for _, p in ipairs(candidates) do
        if isfile(p) then
            found = true
            local ok, data = pcall(function() return HS:JSONDecode(readfile(p)) end)
            if ok and type(data) == "table" and type(data.actions) == "table" then
                S.macroName = name
                S.macroActions = data.actions
                S.macroPlaceId = tonumber(data.placeId)
                for _, act in ipairs(data.actions) do
                    if (act.Type == "Place" or act.Type == "Upgrade") and act.Unit then
                        if not act.BaseUnit or act.BaseUnit == "" then act.BaseUnit = unitBase(act.Unit) end
                        if not act.Variant  or act.Variant  == "" then act.Variant  = unitVariant(act.Unit) end
                    end
                end
                return true, #data.actions
            end
            lastErr = "битый: " .. tostring(p):sub(-30)
        end
    end
    if not found then return false, "файл не найден" end
    return false, lastErr
end

local function mList()
    if type(listfiles) ~= "function" then return {} end
    local seen, out = {}, {}
    for _, f in ipairs(listfiles(MACRO_DIR) or {}) do
        local base = tostring(f):match("([^/\\]+)%.json$")
        if base then
            base = base:gsub("%.bak$", ""):gsub("%.pending$", "")
            if base ~= "" and not seen[base] then
                seen[base] = true
                table.insert(out, base)
            end
        end
    end
    table.sort(out)
    return out
end

local function mDispatch(a)
    if not S.Running then return false, "stopped" end
    local kind = tostring(a.Type or "")
    if kind == "Place" then
        local cf = arrCf(a.CFrame)
        if not cf then return false, "bad CFrame" end
        local unit = tostring(a.Unit or "")
        local base = tostring(a.BaseUnit or "")
        if unit == "" then return false, "bad unit" end
        if base == "" then base = unitBase(unit) end

        local deadline = os.clock() + 300
        while S.macroPlay and os.clock() < deadline do
            if wv() >= (tonumber(a.Wave) or 0) and readVal("Cash") >= (tonumber(a.Cost) or 0) then break end
            task.wait(0.1)
        end
        if not S.macroPlay then return false, "stopped" end
        if wv() < (tonumber(a.Wave) or 0) or readVal("Cash") < (tonumber(a.Cost) or 0) then
            return false, "place prerequisites timeout"
        end

        local before = {}
        for _, v in ipairs(mn()) do before[v] = true end

        local reqA, reqB, reqC = R.Req:InvokeServer({unit, base}, false, true)
        if reqA == false then return false, "RequestTower rejected" end
        local reqData = (type(reqC) == "table" and reqC) or (type(reqB) == "table" and reqB) or {}
        task.wait(0.05)

        local jx = (math.random() - 0.5) * 0.4
        local jz = (math.random() - 0.5) * 0.4
        local pos = cf.Position + Vector3.new(jx, 0, jz)

        local ok, res = pcall(function()
            return R.Spawn:InvokeServer(base, pos, false, unit, reqData)
        end)
        if not ok then return false, "Spawn error: " .. tostring(res) end
        if res == false then return false, "SpawnTower rejected" end
        task.wait(0.3)

        local newT = (typeof(res) == "Instance") and res or nil
        if not newT or not newT.Parent then
            for _, t in ipairs(mn()) do if not before[t] then newT = t; break end end
        end
        if not newT then
            for _, t in ipairs(mn()) do if lv(t) == 0 then newT = t; break end end
        end
        if not newT then return false, "no new tower" end

        RuntimeHandles[a.Handle] = newT
        return true
    end

    local t = RuntimeHandles[a.Handle]
    if not t or not t.Parent then return false, "handle lost" end

    if kind == "Upgrade" then
        local cur = lv(t)
        local target = tonumber(a.Level) or cur + 1
        if cur >= target then return true end
        local deadline = os.clock() + 60
        while S.macroPlay and os.clock() < deadline do
            local price = tonumber(t:GetAttribute("NextUpgradePrice")) or 0
            if readVal("Cash") >= price then break end
            task.wait(0.5)
        end
        pcall(function() R.Upg:InvokeServer(t, tostring(t.Name)) end)
        task.wait(0.3)
        return true
    end

    if kind == "Sell" then
        pcall(function() R.Sell:InvokeServer(t) end)
        RuntimeHandles[a.Handle] = nil
        task.wait(0.3)
        return true
    end

    if kind == "Target" then return true end

    if kind == "Ability" then
        if R.AB then pcall(function() R.AB:FireServer(t) end) end
        return true
    end

    return true
end

local function mPlay()
    if S.macroRec then return false, "сначала STOP REC" end
    if S.macroPlay then return false, "уже играет" end

    if #S.macroActions == 0 and S.macroName ~= "" then
        local ok, err = mLoad(S.macroName)
        if not ok then
            return false, "в памяти пусто, на диске: " .. tostring(err)
        end
    end

    if #S.macroActions == 0 then return false, "пусто, ничего не записано" end

    if S.macroPlaceId and S.macroPlaceId ~= game.PlaceId then
        return false, "макрос из другого плейса"
    end

    local ok, snap = pcall(function() return HS:JSONDecode(HS:JSONEncode(S.macroActions)) end)
    if not ok or type(snap) ~= "table" or #snap == 0 then
        return false, "снапшот пуст"
    end

    S.macroPlay = true
    RuntimeHandles = {}
    local count = #snap

    task.spawn(function()
        local okRun, errRun = pcall(function()
            local t0 = os.clock()
            local speed = tonumber(S.macroSpeed) or 1
            if speed <= 0 then speed = 1 end
            for i, a in ipairs(snap) do
                if not S.macroPlay or not S.Running then break end
                if type(a) ~= "table" then
                    error("invalid action #" .. tostring(i))
                end
                local target = (tonumber(a.Time) or 0) / speed
                target = target * (0.85 + math.random() * 0.3)
                local waitT = target - (os.clock() - t0)
                if waitT > 0 then task.wait(waitT) end
                local okAction, errAction = mDispatch(a)
                if not okAction then
                    error("action #" .. tostring(i) .. ": " .. tostring(errAction))
                end
                if i % 10 == 0 then task.wait() end
            end
        end)
        S.macroPlay = false
        if not okRun and S.Running then
            S.__macroLastError = tostring(errRun)
        end
    end)

    return true, count
end

local function mStop()
    if S.macroRec then
        S.macroRec = false
        for _, c in ipairs(RecorderConns) do pcall(function() c:Disconnect() end) end
        RecorderConns = {}
    end
    if S.macroPlay then S.macroPlay = false end
end

_G.__WL_Macros = {
    StartRec = mStartRec,
    StopRec  = mStopRec,
    Save     = mSave,
    Load     = mLoad,
    List     = mList,
    Play     = mPlay,
    Stop     = mStop,
}
Stage("part2/10-autosell")
Watchdog.register("autosell", function()
    while S.Running do
        task.wait(.5)
        Watchdog.beat("autosell")
        local ok = pcall(function()
            if S.sel and rn() and wv() >= S.sellW and R.Sell and os.clock() - S.lsel > 3 then
                S.lsel = os.clock()
                for _, t in ipairs(mn()) do
                    if t and t.Parent then
                        pcall(function() R.Sell:InvokeServer(t) end)
                        task.wait(0.4 + math.random() * 0.3)
                    end
                end
            end
        end)
        if not ok then task.wait(2) end
    end
end)
Watchdog.spawn("autosell")

Stage("part2/11-autocontrol")
Watchdog.register("autocontrol", function()
    while S.Running do
        task.wait(1)
        Watchdog.beat("autocontrol")
        local ok = pcall(function()
            if S.__abCdMatch ~= S.tracker.matches then
                S.__abCdMatch = S.tracker.matches
                S.abCd = setmetatable({},{__mode="k"})
            end

            if S.sk and rn() and R.Skip and os.clock() - S.ls > 7 + math.random() * 3 then
                S.ls = os.clock()
                pcall(function() R.Skip:InvokeServer() end)
            end
            if S.sp and rn() and R.Spd and sd() ~= S.sv and os.clock() - S.lsp > 5 then
                S.lsp = os.clock()
                pcall(function() R.Spd:InvokeServer(S.sv) end)
            end

            if S.vm and R.VM and ivm() then
                if not S.__votedMap then
                    Confirm.mapVoteAt = os.clock()
                    Confirm.mapVoteOK = false
                    pcall(function() R.VM:FireServer(S.mapV) end)
                    S.__votedMap = true
                    S.__votedMapDeadline = os.clock() + 3
                elseif S.__votedMapDeadline and os.clock() > S.__votedMapDeadline then
                    if Confirm.mapVoteOK then
                        S.__votedMapDeadline = nil
                    else
                        Confirm.mapVoteAt = os.clock()
                        pcall(function() R.VM:FireServer(S.mapV) end)
                        S.__votedMapDeadline = os.clock() + 3
                    end
                end
            else
                S.__votedMap = false
                S.__votedMapDeadline = nil
            end

            if S.vc and R.VC and ivc() then
                if not S.__votedComp then
                    Confirm.compVoteAt = os.clock()
                    Confirm.compVoteOK = false
                    pcall(function() R.VC:FireServer(S.compV) end)
                    S.__votedComp = true
                    S.__votedCompDeadline = os.clock() + 3
                elseif S.__votedCompDeadline and os.clock() > S.__votedCompDeadline then
                    if Confirm.compVoteOK then
                        S.__votedCompDeadline = nil
                    else
                        Confirm.compVoteAt = os.clock()
                        pcall(function() R.VC:FireServer(S.compV) end)
                        S.__votedCompDeadline = os.clock() + 3
                    end
                end
            else
                S.__votedComp = false
                S.__votedCompDeadline = nil
            end

            if S.ab and rn() and R.AB and GetCD then
                if os.clock() - (S.__lastCD or 0) > 5 then
                    S.__lastCD = os.clock()
                    for _, t in ipairs(mn()) do
                        if t and t.Parent then
                            local cfg = t:FindFirstChild("Config")
                            local ab = cfg and cfg:FindFirstChild("Ability")
                            if ab and ab.Value and tostring(ab.Value) ~= "" then
                                local okr, ready = pcall(function() return GetCD:InvokeServer(t) end)
                                if okr and ready == true then
                                    local key = tostring(t)
                                    local last = S.abCd[key] or 0
                                    local delay = 2 + math.random() * 3
                                    if os.clock() - last >= delay then
                                        S.abCd[key] = os.clock()
                                        pcall(function() R.AB:FireServer(t) end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        if not ok then task.wait(2) end
    end
end)
Watchdog.spawn("autocontrol")

Stage("part2/11.5-mutators")
MUT_BASE = {
    TinySlop     = {Id="TinySlop",     Title="Tiny Slop",     Bad="Tiny enemies, +20% speed",      Good="+20% Rewards"},
    Gigantism    = {Id="Gigantism",    Title="Gigantism",     Bad="Enemies x1.5 size & HP",        Good="+30% Rewards"},
    ArmoredSlop  = {Id="ArmoredSlop",  Title="Armored Slop",  Bad="x2.5 enemy HP, -20% speed",     Good="+40% Rewards"},
    Regeneration = {Id="Regeneration", Title="Regeneration", Bad="Enemies heal 2% HP per second", Good="+30% Rewards"},
    BossRush     = {Id="BossRush",     Title="Boss Rush",     Bad="Bosses x2 HP, others +25% HP",  Good="+30% Rewards"},
    Speedrun     = {Id="Speedrun",     Title="Speedrun",      Bad="+40% enemy speed",              Good="x2 Cash"},
    Blackout     = {Id="Blackout",     Title="Blackout",      Bad="Lights out",                    Good="+25% Rewards"},
    Brainrot     = {Id="Brainrot",     Title="Brainrot",      Bad="Random enemy speed",            Good="+20% Rewards"},
    None         = {Id="None",         Title="No Mutator",    Bad="No bonus",                      Good="Normal game"},
}

local mut = {
    catalog={}, offer={}, offerAt=0, deadline=nil,
    voteSerial=0, lastVoteSerial=-1, lastVoteId=nil,
    voteConfirmed=false, lastAttemptAt=-math.huge,
    guiWasOpen=false, guiSignature=nil, active=nil,
    connection=nil, boundRemote=nil,
}

local function mutBuildCatalog()
    local c = {}
    for _,v in pairs(MUT_BASE) do c[v.Id] = {Id=v.Id,Title=v.Title,Bad=v.Bad,Good=v.Good} end
    if type(S.mutCat) == "table" then
        for _,v in pairs(S.mutCat) do
            if type(v) == "table" and v.Id then
                c[v.Id] = {Id=v.Id,Title=tostring(v.Title or v.Id),Bad=tostring(v.Bad or ""),Good=tostring(v.Good or "")}
            end
        end
    end
    mut.catalog = c
end
mutBuildCatalog()

local function mutRewardScore(good)
    local s = tostring(good or ""):lower()
    local x = s:match("x%s*(%d+%.?%d*)")
    if x then return math.max(0, (tonumber(x)-1)*100) end
    return tonumber(s:match("%+(%d+%.?%d*)%%")) or 0
end

local function mutPickChoice()
    local byId = {}
    for _,e in ipairs(mut.offer) do byId[e.Id] = e end
    local mode = S.mutPick or "Priority"
    if mode == "No Mutator" then return (byId.None and "None") or nil end
    local selected = {}
    for _,id in ipairs(S.mutSel or {}) do selected[id] = true end
    local best, bestScore
    for _,e in ipairs(mut.offer) do
        if e.Id ~= "None" then
            local eligible = (mode == "Highest Reward") or selected[e.Id]
            if eligible then
                local score = (mode == "Highest Reward") and -mutRewardScore(e.Good)
                              or tonumber((S.mutPri or {})[e.Id]) or 20
                if best == nil or score < bestScore then best, bestScore = e, score end
            end
        end
    end
    if best then return best.Id end
    return (byId.None and "None") or nil
end

local function mutTryVote(force)
    if not S.vmut or #mut.offer == 0 then return end
    if not force and (os.clock() - mut.offerAt) < 0.15 then return end
    local choice = mutPickChoice()
    if not choice then return end
    if not force and mut.voteConfirmed and mut.lastVoteSerial == mut.voteSerial and mut.lastVoteId == choice then return end
    if not force and mut.lastVoteSerial == mut.voteSerial and mut.lastVoteId == choice
       and (os.clock() - mut.lastAttemptAt) < 0.75 then return end
    if not R.SM or not R.SM.FireServer then return end
    mut.lastVoteSerial = mut.voteSerial
    mut.lastVoteId = choice
    mut.voteConfirmed = false
    mut.lastAttemptAt = os.clock()
    pcall(function() R.SM:FireServer("Vote", choice) end)
end

local function mutRegisterOffer(list, deadline, source)
    if type(list) ~= "table" then return end
    local clean = {}
    for _, item in ipairs(list) do
        if type(item) == "table" and item.Id then
            local id = tostring(item.Id)
            if id ~= "" then
                local prior = mut.catalog[id]
                table.insert(clean, {
                    Id=id,
                    Title=tostring(item.Title or (prior and prior.Title) or id),
                    Bad=tostring(item.Bad or (prior and prior.Bad) or ""),
                    Good=tostring(item.Good or (prior and prior.Good) or ""),
                })
            end
        end
    end
    if #clean == 0 then return end
    local ids = {}
    for _,e in ipairs(clean) do table.insert(ids, e.Id) end
    table.sort(ids)
    local sig = table.concat(ids, "|")
    if mut.guiSignature == sig and #mut.offer > 0 then
        mut.offer = clean
        if deadline then mut.deadline = tonumber(deadline) end
        return
    end
    mut.offer = clean
    mut.guiSignature = sig
    mut.offerAt = os.clock()
    mut.voteSerial = mut.voteSerial + 1
    mut.lastVoteSerial = -1
    mut.lastVoteId = nil
    mut.voteConfirmed = false
    mut.lastAttemptAt = -math.huge
    mut.deadline = tonumber(deadline)
    task.defer(mutTryVote, true)
end

local function mutRecoverFromGui()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local root = pg and pg:FindFirstChild("SlopMutatorGui")
    if root and not root.Enabled then root = nil end
    local voting = root and root:FindFirstChild("MutatorVoting", true)
    local function visible(o)
        if not o then return false end
        local cur = o
        while cur and cur ~= pg do
            if cur:IsA("GuiObject") and not cur.Visible then return false end
            if cur:IsA("LayerCollector") and not cur.Enabled then return false end
            cur = cur.Parent
        end
        return cur == pg
    end
    if not (voting and visible(voting)) then
        if mut.guiWasOpen then
            mut.offer = {}; mut.deadline = nil; mut.voteConfirmed = false; mut.guiSignature = nil
        end
        mut.guiWasOpen = false
        return false
    end
    local list, found = {}, false
    for _, child in ipairs(voting:GetChildren()) do
        local good = child:FindFirstChild("Good", true)
        local bad  = child:FindFirstChild("Bad", true)
        if visible(child) and (good or bad) then
            found = true
            local prev = mut.catalog[child.Name]
            table.insert(list, {
                Id=child.Name,
                Title=(prev and prev.Title) or child.Name,
                Bad=(bad and bad:IsA("TextLabel") and bad.Text) or (prev and prev.Bad) or "",
                Good=(good and good:IsA("TextLabel") and good.Text) or (prev and prev.Good) or "",
            })
        end
    end
    if not found then return false end
    mut.guiWasOpen = true
    mutRegisterOffer(list, mut.deadline, "GUI")
    return true
end

local function mutBindRemote()
    local remote = R.SM
    if remote == mut.boundRemote and mut.connection then
        local ok, conn = pcall(function() return mut.connection.Connected end)
        if ok and conn then return end
    end
    if mut.connection then pcall(function() mut.connection:Disconnect() end) end
    mut.connection = nil
    mut.boundRemote = remote
    if not remote or not remote.OnClientEvent then return end
    mut.connection = remote.OnClientEvent:Connect(function(action, payload, deadline)
        action = tostring(action or "")
        if action == "Vote" and type(payload) == "table" then
            mutRegisterOffer(payload, deadline, "Remote")
        elseif action == "Votes" and type(payload) == "table" then
            local mine = (mut.lastVoteId and tonumber(payload[mut.lastVoteId])) or 0
            if mut.lastVoteSerial == mut.voteSerial and mine > 0 then
                mut.voteConfirmed = true
            end
        elseif action == "Active" then
            local id = (type(payload) == "table" and tostring(payload.Id or "")) or "None"
            if id == "" then id = "None" end
            mut.active = id
            mut.offer = {}; mut.deadline = nil
            mut.voteConfirmed = true; mut.guiWasOpen = false; mut.guiSignature = nil
        end
    end)
end

Watchdog.register("mutators", function()
    while S.Running do
        task.wait(0.6)
        Watchdog.beat("mutators")
        local ok = pcall(function()
            mutBindRemote()
            mutRecoverFromGui()
            if S.vmut and #mut.offer > 0 and not mut.voteConfirmed then
                mutTryVote(false)
            end
        end)
        if not ok then task.wait(2) end
    end
end)
Watchdog.spawn("mutators")

_G.__WL_Mutators = {
    register=mutRegisterOffer, pick=mutPickChoice, vote=mutTryVote,
    catalog=function() return mut.catalog end,
    offer=function() return mut.offer end,
    active=function() return mut.active end,
    base=MUT_BASE,
}

Stage("part2/12-autosummon")
Watchdog.register("autosummon", function()
    while S.Running do
        task.wait(.5)
        Watchdog.beat("autosummon")
        local ok = pcall(function()
            if S.sum and os.clock() - S.lsum >= S.sumD then
                S.lsum = os.clock()
                local r = ((S.sumCur == "Gem") and R.SumP) or R.Sum
                if r then pcall(function() r:InvokeServer(S.sumA) end) end
            end
        end)
        if not ok then task.wait(2) end
    end
end)
Watchdog.spawn("autosummon")

Stage("part2/13-autocrates")
Watchdog.register("autocrates", function()
    while S.Running do
        task.wait(1)
        Watchdog.beat("autocrates")
        local ok = pcall(function()
            if (S.buy or S.opn) and os.clock() - S.lcr >= S.crateD then
                S.lcr = os.clock()
                if S.buy and R.Buy then pcall(function() R.Buy:FireServer(S.crate, S.crateA) end) end
                if S.opn and R.Open then pcall(function() R.Open:InvokeServer(S.crate, S.crateA) end) end
            end
        end)
        if not ok then task.wait(2) end
    end
end)
Watchdog.spawn("autocrates")
Stage("part2/14-autoelevator")
local function getPadPos(elev)
    if not elev then return nil end
    local best, bestScore = nil, 0
    for _, o in ipairs(elev:GetDescendants()) do
        if o:IsA("BasePart") then
            local score = o.Size.X * o.Size.Z
            local name = o.Name:lower()
            if name:find("pad") or name:find("circle") or name:find("floor") or name:find("teleport") then
                score = score * 5
            end
            if score > bestScore then bestScore = score; best = o end
        end
    end
    if best then return best.Position + Vector3.new(0, 3, 0) end
    local ok, bb = pcall(function() return elev:GetBoundingBox() end)
    if ok and bb then return bb.Position + Vector3.new(0, 3, 0) end
    return nil
end
local function isRaidElev(e)
    local v = e:GetAttribute("IsRaid")
    if v ~= nil then return tostring(v):lower() == "true" end
    return tostring(e.Name):lower():find("raid") ~= nil
end
local function isPlayerInElev(elev)
    if not elev then return false end
    local ids = elev:GetAttribute("PlayerUserIds")
    if type(ids) == "string" and ids ~= "" then
        if ids:find(tostring(LP.UserId), 1, true) then return true end
    end
    return false
end
local function pickElevator()
    local els = WS:FindFirstChild("Elevators")
    if not els then return nil end
    local best, bestCount = nil, 0
    for _, e in ipairs(els:GetChildren()) do
        if e:IsA("Model") then
            local mp = tonumber(e:GetAttribute("MaxPlayers")) or 4
            local raid = isRaidElev(e)
            local okType =
                S.elevType == "Raid"   and raid     or
                S.elevType == "Normal" and not raid or
                S.elevType == "Auto"
            if okType and mp > bestCount then bestCount = mp; best = e end
        end
    end
    return best
end
local lastElevName = ""
local retries = 0
Watchdog.register("autoelevator", function()
    while S.Running do
        task.wait(1)
        Watchdog.beat("autoelevator")
        local ok = pcall(function()
            if not (S.lobby and R.EE and R.SE) then lastElevName=""; retries=0; return end
            local best = pickElevator()
            if not best then return end
            if isPlayerInElev(best) then
                if lastElevName ~= best.Name then lastElevName = best.Name end
                return
            end
            if lastElevName ~= best.Name then
                lastElevName = best.Name; retries = 0
                local ch = LP.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                local padPos = getPadPos(best)
                if hrp and padPos then
                    pcall(function()
                        hrp.CFrame = CFrame.new(padPos) * hrp.CFrame.Rotation
                        hrp.AssemblyLinearVelocity = Vector3.zero
                    end)
                    task.wait(0.5)
                end
                Confirm.elevEnterAt = os.clock(); Confirm.elevEnterOK = false
                pcall(function() R.EE:FireServer(best.Name) end)
                local t0 = os.clock()
                while os.clock() - t0 < 6 do
                    if Confirm.elevEnterOK or isPlayerInElev(best) then break end
                    task.wait(0.2)
                end
                if not (Confirm.elevEnterOK or isPlayerInElev(best)) then
                    lastElevName = ""; return
                end
                Confirm.elevStartAt = os.clock(); Confirm.teleportedAt = 0
                pcall(function() R.SE:FireServer(best.Name) end)
                local t1 = os.clock(); local teleported = false
                while os.clock() - t1 < 20 do
                    if Confirm.teleportedAt > t1 then teleported = true; break end
                    task.wait(0.3)
                end
                if not teleported and isPlayerInElev(best) and retries < 3 then
                    retries = retries + 1
                    pcall(function() R.SE:FireServer(best.Name) end)
                end
            end
        end)
        if not ok then task.wait(2) end
    end
end)
Watchdog.spawn("autoelevator")

Stage("part2/15-matchend")
local function isEndScreen()
    local pg = LP:FindFirstChild("PlayerGui")
    local gg = pg and pg:FindFirstChild("GameGui")
    local es = gg and gg:FindFirstChild("EndScreen")
    if not es then return false end
    if es:IsA("LayerCollector") then return es.Enabled end
    if es:IsA("GuiObject") then return es.Visible end
    return false
end
local lastRun = false
local fired = false
Watchdog.register("matchend", function()
    while S.Running do
        task.wait(2)
        Watchdog.beat("matchend")
        local ok = pcall(function()
            local running = rn()
            local ended = isEndScreen()
            if running and not lastRun and S.tracker.lastMatchEnd == 0 then
                S.tracker.lastMatchEnd = os.time()
            elseif (not running) and S.tracker.lastMatchEnd > 0 and lastRun then
                S.tracker.matches = S.tracker.matches + 1
                S.tracker.lastMatchEnd = 0
            end
            lastRun = running
            if ended and not fired then
                fired = true
                if S.endAct == "Replay" and R.ED then pcall(function() R.ED:FireServer(true) end)
                elseif S.endAct == "New Map" and R.ED then pcall(function() R.ED:FireServer("new") end)
                elseif S.endAct == "Lobby" and R.EX then pcall(function() R.EX:FireServer() end) end
            elseif not ended then
                fired = false
            end
        end)
        if not ok then task.wait(2) end
    end
end)
Watchdog.spawn("matchend")

Stage("part2/16-antiafk")
Watchdog.register("autojump", function()
    while S.Running do
        task.wait(1)
        Watchdog.beat("autojump")
        local ok = pcall(function()
            if not S.jump then return end
            local ch = LP.Character
            local h = ch and ch:FindFirstChildOfClass("Humanoid")
            if not h or h.Sit then return end
            if h.FloorMaterial == Enum.Material.Air then return end
            pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end)
        if not ok then task.wait(2) end
    end
end)
Watchdog.spawn("autojump")

Watchdog.register("walkaround", function()
    while S.Running do
        task.wait(.5)
        Watchdog.beat("walkaround")
        local ok = pcall(function()
            if not S.walk then return end
            local ch = LP.Character
            local h  = ch and ch:FindFirstChildOfClass("Humanoid")
            local rp = ch and ch:FindFirstChild("HumanoidRootPart")
            if h and rp then
                S.walkC = S.walkC or rp.CFrame
                local a = math.random() * math.pi * 2
                local r = math.random(5, 15)
                pcall(function() h:MoveTo(S.walkC.Position + Vector3.new(math.cos(a)*r, 0, math.sin(a)*r)) end)
            end
        end)
        if not ok then task.wait(2) end
    end
end)
Watchdog.spawn("walkaround")

Stage("part3/17-performance")
local function fpsApply(on)
    if on then
        if S.__globalShadowsOriginal == nil then
            local ok, value = pcall(function() return L.GlobalShadows end)
            if ok then S.__globalShadowsOriginal = value end
        end
        for _, o in ipairs(WS:GetDescendants()) do
            if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam")
               or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") then
                pcall(function()
                    if S.fpsO[o] == nil then S.fpsO[o] = o.Enabled end
                    o.Enabled = false
                end)
            end
        end
        pcall(function() L.GlobalShadows = false end)
    else
        for o, v in pairs(S.fpsO) do pcall(function() if o.Parent then o.Enabled = v end end) end
        S.fpsO = setmetatable({},{__mode="k"})
        if S.__globalShadowsOriginal ~= nil then
            local original = S.__globalShadowsOriginal
            pcall(function() L.GlobalShadows = original end)
            S.__globalShadowsOriginal = nil
        end
    end
end

local function bsApply(on)
    if on then
        if not S.bsGui then
            local sg = Instance.new("ScreenGui")
            sg.Name = "ww_bs"; sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true; sg.DisplayOrder = 9998
            sg.Parent = (gethui and gethui()) or LP:WaitForChild("PlayerGui")
            local f = Instance.new("Frame", sg)
            f.Size = UDim2.new(1, 0, 1, 0)
            f.BackgroundColor3 = Color3.new(0, 0, 0)
            local b = Instance.new("TextButton", f)
            b.Size = UDim2.new(0, 200, 0, 40)
            b.Position = UDim2.new(.5, -100, .5, -20)
            b.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
            b.Text = "Disable"; b.TextColor3 = Color3.new(1, 1, 1)
            b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
            b.MouseButton1Click:Connect(function() bsApply(false); S.blk = false end)
            S.bsGui = sg
        end
        pcall(function() R2:Set3dRenderingEnabled(false) end)
    else
        if S.bsGui then pcall(function() S.bsGui:Destroy() end); S.bsGui = nil end
        pcall(function() R2:Set3dRenderingEnabled(true) end)
    end
end

local hidOriginal = setmetatable({}, {__mode="k"})
local function hidApply(on)
    local function applyHumanoid(o)
        if not o:IsA("Humanoid") then return end
        if on then
            if not hidOriginal[o] then
                local ok, snapshot = pcall(function()
                    return {
                        DisplayDistanceType = o.DisplayDistanceType,
                        NameDisplayDistance = o.NameDisplayDistance,
                        HealthDisplayDistance = o.HealthDisplayDistance,
                    }
                end)
                if ok then hidOriginal[o] = snapshot end
            end
            pcall(function()
                o.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                o.NameDisplayDistance = 0
                o.HealthDisplayDistance = 0
            end)
        else
            local snapshot = hidOriginal[o]
            if snapshot then
                pcall(function()
                    o.DisplayDistanceType = snapshot.DisplayDistanceType
                    o.NameDisplayDistance = snapshot.NameDisplayDistance
                    o.HealthDisplayDistance = snapshot.HealthDisplayDistance
                end)
                hidOriginal[o] = nil
            end
        end
    end
    for _, pl in ipairs(P:GetPlayers()) do
        if pl.Character then
            for _, o in ipairs(pl.Character:GetDescendants()) do applyHumanoid(o) end
        end
    end
end

Stage("part3/18-webhook")
local function send(full)
    if not S.wh or S.url == "" or type(request) ~= "function" then return false end
    local f = {}
    f[#f+1] = {name="Cash", value=tostring(readVal("Cash")), inline=true}
    f[#f+1] = {name="Gems", value=tostring(readVal("Gems")), inline=true}
    f[#f+1] = {name="Wave", value=tostring(wv()), inline=true}
    if full then
        f[#f+1] = {name="Towers", value=tostring(#mn()), inline=true}
        f[#f+1] = {name="PlaceId", value=tostring(game.PlaceId), inline=false}
    end
    return pcall(function()
        request({Url=S.url, Method="POST",
            Headers={["Content-Type"]="application/json"},
            Body=HS:JSONEncode({username="wertlaider", embeds={{title="wertlaider · "..LP.Name, color=3968255, fields=f, footer={text="wertlaider"}, timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}})
        })
    end)
end

local function progressReport()
    local curCash = readVal("Cash")
    local curGems = readVal("Gems")
    local curMats = getMaterials()
    local matDelta = {}
    local seen = {}
    for name, count in pairs(curMats) do
        local start = S.tracker.startMaterials[name] or 0
        matDelta[name] = count - start
        seen[name] = true
    end
    for name, start in pairs(S.tracker.startMaterials) do
        if not seen[name] then
            matDelta[name] = 0 - start
        end
    end
    return {
        elapsed = os.time() - S.tracker.start,
        cash = curCash, dCash = curCash - S.tracker.startCash,
        gems = curGems, dGems = curGems - S.tracker.startGems,
        matches = S.tracker.matches, materialDelta = matDelta
    }
end

local function sendTracker()
    if not S.wh or S.url == "" or type(request) ~= "function" then return false end
    local p = progressReport()
    local h = math.floor(p.elapsed / 3600)
    local m = math.floor((p.elapsed % 3600) / 60)
    local f = {}
    f[#f+1] = {name="Time", value=h.."h "..m.."m", inline=false}
    f[#f+1] = {name="Cash", value=tostring(p.cash), inline=true}
    f[#f+1] = {name="Gems", value=tostring(p.gems), inline=true}
    f[#f+1] = {name="Matches", value=tostring(p.matches), inline=true}
    return pcall(function()
        request({Url=S.url, Method="POST",
            Headers={["Content-Type"]="application/json"},
            Body=HS:JSONEncode({username="wertlaider", embeds={{title="Progress · "..LP.Name, color=3968255, fields=f, footer={text="wertlaider tracker"}, timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}})
        })
    end)
end

Stage("part3/19-autosave")
Watchdog.register("autosave", function()
    while S.Running do
        task.wait(30)
        Watchdog.beat("autosave")
        pcall(function()
            local snap = {}
            for _, k in ipairs(SAVE_KEYS) do
                snap[k] = S[k]
            end
            local cur = HS:JSONEncode(snap)
            if cur ~= S.__lastCfg then
                saveCfg(S)
                S.__lastCfg = cur
            end
        end)
    end
end)
Watchdog.spawn("autosave")

Stage("part3/20-tracker-report")
Watchdog.register("tracker-report", function()
    while S.Running do
        task.wait(60)
        Watchdog.beat("tracker-report")
        pcall(function()
            local elapsed = os.time() - S.tracker.lastReport
            if elapsed >= 1800 then
                S.tracker.lastReport = os.time()
                if S.wh and S.url ~= "" then sendTracker() end
            end
        end)
    end
end)
Watchdog.spawn("tracker-report")
Stage("part3/21-ui")
local W = RF:CreateWindow({
    Title="wertlaider", Author="wertlaider", Folder="Wertlaider2",
    Icon="swords", Theme="Sky", Size=UDim2.fromOffset(540, 440),
    Transparent=true, HideSearchBar=true, NewElements=true,
    ToggleKey=Enum.KeyCode.RightShift,
    OpenButton={Title="wertlaider", Enabled=true, Draggable=true, OnlyMobile=false}
})

local T1 = W:Tab({Title="Match", Icon="swords"})
T1:Section({Title="Vote"})
T1:Dropdown({Title="Map",
    Values={"BackroomsEndless","Base","Blood Moon","BrainrotEndless","Cooking Stove","Crossroads","Day","Desert","Doomspire","Dungeon","FairyEndless","GardenEndless","Gold Base","Happy Home","Kitchen Table","KitchenEndless","Level 1","Level 2","Level 3","Level0","Level94","Night","Night Base","NightPlot","Plot","Poolrooms","Raid","RetroEndless","RichPlot","Ruined City","Summer Raid","The Fridge","Toilet City","ToiletEndless"},
    Value=S.mapV, Multi=false, SearchBarEnabled=true,
    Callback=function(v) S.mapV = v end})
T1:Dropdown({Title="Complication", Values={"Normal","Hard","Nightmare","Chaos"}, Value=S.compV, Multi=false, Callback=function(v) S.compV = v end})
T1:Toggle({Title="Auto Vote Map", Value=S.vm, Callback=function(v) S.vm = v end})
T1:Toggle({Title="Auto Vote Complication", Value=S.vc, Callback=function(v) S.vc = v end})
T1:Toggle({Title="Auto Vote Mutator", Value=S.vmut, Callback=function(v)
    S.vmut = v
    if v and _G.__WL_Mutators then task.defer(_G.__WL_Mutators.vote, true) end
end})
T1:Dropdown({Title="Mutator Auto Pick", Desc="Priority / Highest Reward / No Mutator",
    Values={"Priority","Highest Reward","No Mutator"}, Value=S.mutPick, Multi=false,
    Callback=function(v) S.mutPick = v; if _G.__WL_Mutators then task.defer(_G.__WL_Mutators.vote, true) end end})
T1:Dropdown({Title="Preferred Mutators", Desc="Select several",
    Values=(function()
        local t = {}
        for id,_ in pairs(MUT_BASE) do if id ~= "None" then table.insert(t, id) end end
        table.sort(t); return t
    end)(),
    Value=S.mutSel, Multi=true, AllowNone=true, SearchBarEnabled=true,
    Callback=function(v)
        local out, seen = {}, {}
        for _, id in pairs(v or {}) do
            local s = tostring(id or "")
            if s ~= "" and not seen[s] and MUT_BASE[s] then seen[s] = true; table.insert(out, s) end
        end
        S.mutSel = out
        for i, id in ipairs(out) do
            if S.mutPri[id] == nil then S.mutPri[id] = i end
        end
        if _G.__WL_Mutators then task.defer(_G.__WL_Mutators.vote, true) end
    end})
for _, id in ipairs(S.mutSel or {}) do
    local base = MUT_BASE[id]
    if base then
        T1:Slider({Title=base.Title.." priority", Desc=base.Bad.." | "..base.Good,
            Step=1, Value={Min=1, Max=20, Default=S.mutPri[id] or 20},
            Callback=function(v)
                S.mutPri[id] = math.clamp(math.floor(tonumber(v) or 20), 1, 20)
                if _G.__WL_Mutators then task.defer(_G.__WL_Mutators.vote, true) end
            end})
    end
end

T1:Section({Title="Macros"})
T1:Input({Title="Macro Name", Placeholder="base1", Value=S.macroName,
    Callback=function(v) S.macroName = tostring(v):gsub("%s","") end})
T1:Slider({Title="Playback Speed", Step=0.25,
    Value={Min=0.25, Max=4, Default=S.macroSpeed},
    Callback=function(v) S.macroSpeed = tonumber(v) or 1 end})

local macroList = _G.__WL_Macros.List()
if #macroList == 0 then macroList = {"(none)"} end
T1:Dropdown({Title="Select Macro",
    Values=macroList,
    Value=(S.macroName ~= "" and S.macroName or "(none)"),
    Multi=false, SearchBarEnabled=true,
    Callback=function(v)
        if v == "(none)" then return end
        local ok, err = _G.__WL_Macros.Load(v)
        RF:Notify({Title="wertlaider",
            Content= ok and ("Загружен: "..v.." ("..tostring(#S.macroActions)..")")
                          or ("Ошибка: "..tostring(err)), Duration=3})
    end})

local uiSuppress = false
local recToggle, playToggle

recToggle = T1:Toggle({Title="Record",
    Desc="ВКЛ — писать, ВЫКЛ — сохранить и остановить",
    Value=false,
    Callback=function(v)
        if uiSuppress then return end
        if v then
            if S.macroPlay then
                uiSuppress = true; playToggle:Set(false); uiSuppress = false
            end
            local ok, err = _G.__WL_Macros.StartRec(S.macroName)
            if not ok then
                uiSuppress = true; recToggle:Set(false); uiSuppress = false
                RF:Notify({Title="wertlaider", Content="REC fail: "..tostring(err), Duration=3})
            else
                RF:Notify({Title="wertlaider", Content="REC: "..S.macroName, Duration=2})
            end
        else
            local ok, err = _G.__WL_Macros.StopRec(true)
            if ok then
                RF:Notify({Title="wertlaider",
                    Content="Сохранено: "..tostring(#S.macroActions).." действий", Duration=2})
            else
                RF:Notify({Title="wertlaider", Content="Save fail: "..tostring(err), Duration=3})
            end
        end
    end})

playToggle = T1:Toggle({Title="Play",
    Desc="ВКЛ — играть макрос, ВЫКЛ — стоп",
    Value=false,
    Callback=function(v)
        if uiSuppress then return end
        if v then
            if S.macroRec then
                uiSuppress = true; recToggle:Set(false); uiSuppress = false
                _G.__WL_Macros.StopRec(true)
            end
            local ok, err = _G.__WL_Macros.Play()
            if not ok then
                uiSuppress = true; playToggle:Set(false); uiSuppress = false
                RF:Notify({Title="wertlaider", Content="PLAY fail: "..tostring(err), Duration=3})
            else
                RF:Notify({Title="wertlaider", Content="Играем", Duration=2})
            end
        else
            _G.__WL_Macros.Stop()
            RF:Notify({Title="wertlaider", Content="Стоп", Duration=2})
        end
    end})

T1:Section({Title="Control"})
T1:Toggle({Title="Auto Skip", Value=S.sk, Callback=function(v) S.sk = v end})
T1:Toggle({Title="Auto Speed", Value=S.sp, Callback=function(v) S.sp = v end})
T1:Slider({Title="Speed", Step=1, Value={Min=1, Max=5, Default=S.sv}, Callback=function(v) S.sv = v end})
T1:Toggle({Title="Auto Ability", Value=S.ab, Callback=function(v) S.ab = v end})

T1:Section({Title="Endless"})
T1:Toggle({Title="Auto Sell All", Value=S.sel, Callback=function(v) S.sel = v end})
T1:Slider({Title="Sell At Wave", Step=10, Value={Min=10, Max=500, Default=S.sellW}, Callback=function(v) S.sellW = v end})

T1:Section({Title="Match End"})
T1:Dropdown({Title="After Match",
    Values={"Off","Replay","New Map","Return Lobby"},
    Value=(S.endAct=="None" and "Off" or (S.endAct=="Lobby" and "Return Lobby" or S.endAct)),
    Multi=false,
    Callback=function(v)
        if v=="Replay" then S.endAct = "Replay"
        elseif v=="New Map" then S.endAct = "New Map"
        elseif v=="Return Lobby" then S.endAct = "Lobby"
        else S.endAct = "None" end
    end})

local T2 = W:Tab({Title="Lobby", Icon="door-open"})
T2:Section({Title="Play"})
T2:Toggle({Title="Auto Elevator", Value=S.lobby, Callback=function(v) S.lobby = v end})
T2:Dropdown({Title="Elevator Type", Desc="Auto / Normal / Raid",
    Values={"Auto","Normal","Raid"}, Value=S.elevType, Multi=false,
    Callback=function(v) S.elevType = v end})
T2:Section({Title="Summon"})
T2:Toggle({Title="Enable", Value=S.sum, Callback=function(v) S.sum = v end})
T2:Dropdown({Title="Currency", Values={"Cash","Gem"}, Value=S.sumCur, Multi=false, Callback=function(v) S.sumCur = v end})
T2:Dropdown({Title="Amount", Values={"x1","x10","x50"}, Value="x"..tostring(S.sumA), Multi=false, Callback=function(v) S.sumA = tonumber(v:match("%d+")) or 10 end})
T2:Slider({Title="Delay", Step=0.5, Value={Min=0.5, Max=10, Default=S.sumD}, Callback=function(v) S.sumD = v end})
T2:Section({Title="Crates"})
T2:Dropdown({Title="Crate", Values={"Still Life Crate","Garden Crate","Alien Crate","Space Crate","Slopbux Crate 2"}, Value=S.crate, Multi=false, Callback=function(v) S.crate = v end})
T2:Dropdown({Title="Amount", Values={"x1","x3","x10","x25","x50"}, Value="x"..tostring(S.crateA), Multi=false, Callback=function(v) S.crateA = tonumber(v:match("%d+")) or 1 end})
T2:Toggle({Title="Auto Buy", Value=S.buy, Callback=function(v) S.buy = v end})
T2:Toggle({Title="Auto Open", Value=S.opn, Callback=function(v) S.opn = v end})
T2:Slider({Title="Delay", Step=0.5, Value={Min=0.5, Max=10, Default=S.crateD}, Callback=function(v) S.crateD = v end})
T2:Button({Title="Roll Now", Callback=function()
    if R.Buy then pcall(function() R.Buy:FireServer(S.crate, S.crateA) end) end
    task.wait(0.5)
    if R.Open then pcall(function() R.Open:InvokeServer(S.crate, S.crateA) end) end
end})

local T3 = W:Tab({Title="Misc", Icon="tool"})
T3:Section({Title="Anti-Macro"})
T3:Toggle({Title="Auto Anti-Macro", Value=S.am, Callback=function(v) S.am = v end})
T3:Slider({Title="Delay Min", Step=0.1, Value={Min=0.1, Max=3, Default=S.am1}, Callback=function(v) S.am1 = v end})
T3:Slider({Title="Delay Max", Step=0.1, Value={Min=0.2, Max=5, Default=S.am2}, Callback=function(v) S.am2 = v end})
T3:Section({Title="Anti-AFK"})
T3:Toggle({Title="Auto Jump", Value=S.jump, Callback=function(v) S.jump = v end})
T3:Toggle({Title="Walk Around", Value=S.walk, Callback=function(v) S.walk = v end})
T3:Section({Title="Performance"})
T3:Toggle({Title="FPS Boost", Value=S.fps, Callback=function(v) S.fps = v; fpsApply(v) end})
T3:Toggle({Title="Black Screen", Value=S.blk, Callback=function(v) S.blk = v; bsApply(v) end})
T3:Toggle({Title="Hide Name", Value=S.hid, Callback=function(v) S.hid = v; hidApply(v) end})

local T4 = W:Tab({Title="Webhook", Icon="radio"})
T4:Section({Title="Discord"})
T4:Input({Title="URL", Placeholder="https://...", Value=S.url, Callback=function(v) S.url = v end})
T4:Toggle({Title="Enable", Value=S.wh, Callback=function(v) S.wh = v end})
T4:Section({Title="Reports"})
T4:Button({Title="Send Cash/Gems", Callback=function()
    local ok = send(false)
    RF:Notify({Title="wertlaider", Content= ok and "Отправлено" or "Ошибка", Duration=2})
end})
T4:Button({Title="Send Full", Callback=function()
    local ok = send(true)
    RF:Notify({Title="wertlaider", Content= ok and "Full отправлен" or "Ошибка", Duration=2})
end})
T4:Button({Title="Send Progress Tracker", Callback=function()
    local ok = sendTracker()
    RF:Notify({Title="wertlaider", Content= ok and "Трекер отправлен" or "Ошибка", Duration=3})
end})
T4:Section({Title="Config"})
T4:Button({Title="Save Config Now", Callback=function()
    saveCfg(S)
    RF:Notify({Title="wertlaider", Content="Настройки сохранены", Duration=2})
end})
T4:Button({Title="Save URL to file", Callback=function()
    if S.url ~= "" then
        local ok = pcall(function() writefile("wl_webhook.txt", S.url) end)
        RF:Notify({Title="wertlaider", Content= ok and "URL сохранён" or "Ошибка", Duration=2})
    end
end})
T4:Button({Title="Reset Tracker", Callback=function()
    initTracker()
    RF:Notify({Title="wertlaider", Content="Трекер сброшен", Duration=2})
end})
T4:Button({Title="Reset Config", Callback=function()
    pcall(function() delfile(SAVE_FILE) end)
    RF:Notify({Title="wertlaider", Content="Конфиг удалён, перезапусти", Duration=3})
end})

RF:Notify({Title="wertlaider", Content="Загружен", Duration=3})

_G.__WL_Stop = function()
    local g = _G.__WL
    if not g or not g.S then return end
    g.S.Running = false
    g.S.macroRec = false
    g.S.macroPlay = false
    if g.S.__wlStop then return end
    g.S.__wlStop = true
end
