print("BetrayalHub Custom loading...")

local SCRIPT_VERSION = "v4.0.2"

-- ============================================================
-- ERROR HANDLER
-- ============================================================
local function flashError(msg)
    pcall(function()
        local player = game:GetService("Players").LocalPlayer
        local gui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
        if not gui then return end
        local errorGui = Instance.new("ScreenGui")
        errorGui.Name = "BetrayalHub_Error"
        errorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        errorGui.Parent = gui
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 450, 0, 80)
        frame.Position = UDim2.new(0.5, -225, 0.5, -40)
        frame.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.fromRGB(255, 50, 50)
        frame.Parent = errorGui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, -20)
        label.Position = UDim2.new(0, 10, 0, 10)
        label.Text = "⚠️ BetrayalHub Error:\n" .. tostring(msg):sub(1, 150)
        label.TextColor3 = Color3.fromRGB(255, 200, 200)
        label.TextScaled = true
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.Parent = frame
        task.delay(10, function() pcall(function() errorGui:Destroy() end) end)
    end)
end

local success, err = pcall(function()

-- ============================================================
-- FORWARD DECLARATIONS
-- Required because oldNamecall (section 4) references tt and
-- activeBackstabConn which are assigned in section 5.
-- Lua closures close over the upvalue slot, not the value —
-- so assigning later is fine as long as no call fires before
-- section 5 runs (it won't; the game hasn't started yet).
-- ============================================================
local tt                    -- assigned in section 5
local activeBackstabConn    -- assigned in section 5
local doTriggerFlash        -- defined in section 6 HUD block
local staminaEstimate       -- defined in section 7 Helper block
local helper                -- defined in section 7 Helper block
local elliotAim             -- assigned in section 4a Elliot Predictive Aimbot

-- ============================================================
-- SERVICES & LOCAL PLAYER
-- ============================================================
local svc = {
    Players = game:GetService("Players"),
    Run     = game:GetService("RunService"),
    RS      = game:GetService("ReplicatedStorage"),
    WS      = game:GetService("Workspace"),
    VIM     = game:GetService("VirtualInputManager"),
    Stats   = game:GetService("Stats"),
    Input   = game:GetService("UserInputService"),
}
local lp = svc.Players.LocalPlayer

-- ── Helpers ──────────────────────────────────────────────────
local function ensureTouchGuiVisible()
    pcall(function()
        local pg = lp:FindFirstChildOfClass("PlayerGui")
        if not pg then return end
        local tg = pg:FindFirstChild("TouchGui")
        if tg then
            tg.Enabled = true
            local frame = tg:FindFirstChild("TouchControlFrame")
            if frame then frame.Visible = true end
        end
    end)
end

local function getRemoteEvent()
    local ok, re = pcall(function()
        return svc.RS.Modules.Network.Network:FindFirstChild("RemoteEvent")
    end)
    return ok and re or nil
end

local function getTeamFolder(name)
    local root = svc.WS:FindFirstChild("Players")
    return root and root:FindFirstChild(name)
end

-- ============================================================
-- WINDUI LOADER
-- ============================================================
local ui

local function tryLoadUI(url)
    local ok, src = pcall(game.HttpGet, game, url)
    if not (ok and src and #src > 100) then return nil end
    local lok, fn = pcall(loadstring, src)
    if not (lok and fn) then return nil end
    local iok, inst = pcall(fn)
    return (iok and inst) or nil
end

ui = tryLoadUI("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
  or tryLoadUI("https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua")

if not ui then error("Failed to load WindUI library.") end

local win = ui:CreateWindow({
    Title         = "BetrayalHub",
    Icon          = "sparkles",
    Author        = "Custom Edition " .. SCRIPT_VERSION,
    Size          = UDim2.fromOffset(380, 580),
    Theme         = "Crimson",
    Resizable     = false,
    HideSearchBar = true,
})
win:SetToggleKey(Enum.KeyCode.L)

-- ============================================================
-- VERSION HUD
-- ============================================================
local versionHud = {
    enabled     = false,
    gui         = nil,
    label       = nil,
    conn        = nil,
    frameCount  = 0,
    lastFpsTime = os.clock(),
    currentFps  = 60,
}

local function getPingMs()
    local ok, v = pcall(function()
        return svc.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return (ok and v and math.floor(v)) or 0
end

local function toggleVersionHud(state)
    versionHud.enabled = state
    if not state then
        if versionHud.gui  then pcall(function() versionHud.gui:Destroy()    end); versionHud.gui=nil;  versionHud.label=nil end
        if versionHud.conn then pcall(function() versionHud.conn:Disconnect() end); versionHud.conn=nil end
        return
    end
    if versionHud.gui then return end

    local pg = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5)
    if not pg then return end

    local sg = Instance.new("ScreenGui")
    sg.Name="BetrayalHub_VersionHUD"; sg.ResetOnSpawn=false
    sg.IgnoreGuiInset=true; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=pg

    local frame = Instance.new("Frame")
    frame.Size=UDim2.new(0,220,0,32); frame.Position=UDim2.new(0.5,-110,0,10)
    frame.BackgroundColor3=Color3.fromRGB(18,18,24); frame.BackgroundTransparency=0.25
    frame.BorderSizePixel=1; frame.BorderColor3=Color3.fromRGB(220,40,60)
    frame.Active=true; frame.Draggable=true; frame.Parent=sg
    local co=Instance.new("UICorner"); co.CornerRadius=UDim.new(0,8); co.Parent=frame
    local pd=Instance.new("UIPadding"); pd.PaddingLeft=UDim.new(0,8); pd.PaddingRight=UDim.new(0,8); pd.Parent=frame

    local txt=Instance.new("TextLabel")
    txt.Size=UDim2.new(1,0,1,0); txt.BackgroundTransparency=1
    txt.Text="✨ BetrayalHub "..SCRIPT_VERSION.." | FPS:60 | Ping:0ms"
    txt.TextColor3=Color3.fromRGB(255,230,235); txt.TextSize=11
    txt.Font=Enum.Font.GothamBold; txt.TextXAlignment=Enum.TextXAlignment.Center; txt.Parent=frame

    versionHud.gui=sg; versionHud.label=txt
    versionHud.conn = svc.Run.RenderStepped:Connect(function()
        if not versionHud.enabled or not versionHud.label or not versionHud.label.Parent then return end
        versionHud.frameCount = versionHud.frameCount + 1
        local now = os.clock()
        if now - versionHud.lastFpsTime >= 1 then
            versionHud.currentFps  = versionHud.frameCount
            versionHud.frameCount  = 0
            versionHud.lastFpsTime = now
        end
        versionHud.label.Text = string.format(
            "✨ BetrayalHub %s | %d FPS | %dms",
            SCRIPT_VERSION, versionHud.currentFps, getPingMs()
        )
    end)
end

-- ============================================================
-- 1. ESP
-- ============================================================
local tabESP = win:Tab({ Title="ESP", Icon="eye" })
local secESP = tabESP:Section({ Title="ESP Settings", Opened=true })

local espState = {
    enabled       = true,
    showKillers   = true,
    showSurvivors = true,
    showGenerators= true,
    highlights    = {},
    billboards    = {},
    healthConns   = {},
}
local COLORS = {
    Killer    = Color3.fromRGB(255, 60,  60),
    Survivor  = Color3.fromRGB(60,  255, 60),
    Generator = Color3.fromRGB(255, 210, 50),
}

local function clearESP()
    for _, hl   in pairs(espState.highlights)  do if hl   and hl.Parent   then pcall(function() hl:Destroy()       end) end end
    for _, bb   in pairs(espState.billboards)  do if bb   and bb.Parent   then pcall(function() bb:Destroy()       end) end end
    for _, conn in pairs(espState.healthConns) do                               pcall(function() conn:Disconnect()  end)       end
    espState.highlights={}; espState.billboards={}; espState.healthConns={}
end

local function createESPItem(obj, color, title, isChar)
    if not obj or not obj.Parent or espState.highlights[obj] then return end
    local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
    if not hrp then return end

    local hl = Instance.new("Highlight")
    hl.Name="BH_ESP_HL"; hl.Adornee=obj; hl.FillColor=color; hl.FillTransparency=0.5
    hl.OutlineColor=color; hl.OutlineTransparency=0.1
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=obj

    local bb = Instance.new("BillboardGui")
    bb.Name="BH_ESP_BB"; bb.Adornee=hrp; bb.Size=UDim2.new(0,140,0,22)
    bb.StudsOffset=Vector3.new(0,3.5,0); bb.AlwaysOnTop=true; bb.Parent=obj

    local lbl = Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.TextColor3=color; lbl.TextStrokeColor3=Color3.new(0,0,0)
    lbl.TextStrokeTransparency=0.2; lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=11; lbl.Parent=bb

    espState.highlights[obj] = hl
    espState.billboards[obj] = bb

    if isChar then
        local function updateText()
            if not obj or not obj.Parent then return end
            local myChar = lp.Character
            local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local dist   = (myHRP and hrp) and string.format("%.0fm",(hrp.Position-myHRP.Position).Magnitude) or ""
            local hum    = obj:FindFirstChildOfClass("Humanoid")
            local hp     = hum and string.format("%d HP",math.floor(hum.Health)) or ""
            lbl.Text = (dist~="" and hp~="") and string.format("%s [%s] (%s)",title,hp,dist) or title
        end
        updateText()
        local hum = obj:FindFirstChildOfClass("Humanoid")
        if hum then espState.healthConns[obj] = hum.HealthChanged:Connect(updateText) end
    else
        lbl.Text = title
    end
end

local function scanESP()
    if not espState.enabled then return end
    -- prune dead entries
    for obj in pairs(espState.highlights) do
        if not obj or not obj.Parent then
            if espState.highlights[obj]  then pcall(function() espState.highlights[obj]:Destroy()    end) end
            if espState.billboards[obj]  then pcall(function() espState.billboards[obj]:Destroy()    end) end
            if espState.healthConns[obj] then pcall(function() espState.healthConns[obj]:Disconnect() end) end
            espState.highlights[obj]=nil; espState.billboards[obj]=nil; espState.healthConns[obj]=nil
        end
    end
    if espState.showKillers then
        local kf=getTeamFolder("Killers")
        if kf then for _,char in ipairs(kf:GetChildren()) do
            if char:IsA("Model") and char~=lp.Character then
                local h=char:FindFirstChildOfClass("Humanoid")
                if h and h.Health>0 then createESPItem(char,COLORS.Killer,"Killer: "..char.Name,true) end
            end
        end end
    end
    if espState.showSurvivors then
        local sf=getTeamFolder("Survivors")
        if sf then for _,char in ipairs(sf:GetChildren()) do
            if char:IsA("Model") and char~=lp.Character then
                local h=char:FindFirstChildOfClass("Humanoid")
                if h and h.Health>0 then createESPItem(char,COLORS.Survivor,char.Name,true) end
            end
        end end
    end
    if espState.showGenerators then
        local map=svc.WS:FindFirstChild("Map")
        local ingame=map and map:FindFirstChild("Ingame")
        local mc=ingame and ingame:FindFirstChild("Map")
        if mc then for _,item in ipairs(mc:GetChildren()) do
            if item.Name=="Generator" then createESPItem(item,COLORS.Generator,"Generator",false) end
        end end
    end
end

task.spawn(function() while true do task.wait(1); pcall(scanESP) end end)

secESP:Toggle({Title="Enable ESP",      Default=true, Callback=function(v) espState.enabled=v;       if not v then clearESP() else scanESP() end end})
secESP:Toggle({Title="Killers ESP",     Default=true, Callback=function(v) espState.showKillers=v;   clearESP(); scanESP() end})
secESP:Toggle({Title="Survivors ESP",   Default=true, Callback=function(v) espState.showSurvivors=v; clearESP(); scanESP() end})
secESP:Toggle({Title="Generators ESP",  Default=true, Callback=function(v) espState.showGenerators=v;clearESP(); scanESP() end})

-- ============================================================
-- 2. AUTO GENERATOR
-- ============================================================
local tabGen = win:Tab({Title="Generator", Icon="circuit-board"})
local secGen = tabGen:Section({Title="Auto Solve", Opened=true})

local genState = {enabled=false, nodeDelay=0.03, lineDelay=0.4}

local function flowKey(n) return n.row.."-"..n.col end

local function flowNeighbour(r1,c1,r2,c2)
    if r2==r1-1 and c2==c1 then return "up"    end
    if r2==r1+1 and c2==c1 then return "down"  end
    if r2==r1 and c2==c1-1 then return "left"  end
    if r2==r1 and c2==c1+1 then return "right" end
    return false
end

local function flowOrder(path, endpoints)
    if not path or #path==0 then return path end
    local lookup={}
    for _,n in ipairs(path) do lookup[flowKey(n)]=n end
    local start
    for _,ep in ipairs(endpoints or {}) do
        for _,n in ipairs(path) do
            if n.row==ep.row and n.col==ep.col then start={row=ep.row,col=ep.col}; break end
        end
        if start then break end
    end
    if not start then
        for _,n in ipairs(path) do
            local nb=0
            for _,d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
                if lookup[(n.row+d[1]).."-"..(n.col+d[2])] then nb=nb+1 end
            end
            if nb==1 then start={row=n.row,col=n.col}; break end
        end
    end
    if not start then start={row=path[1].row,col=path[1].col} end
    local pool,ordered={},{}
    for _,n in ipairs(path) do pool[flowKey(n)]={row=n.row,col=n.col} end
    local cur=start
    table.insert(ordered,{row=cur.row,col=cur.col}); pool[flowKey(cur)]=nil
    while next(pool) do
        local moved=false
        for k,node in pairs(pool) do
            if flowNeighbour(cur.row,cur.col,node.row,node.col) then
                table.insert(ordered,{row=node.row,col=node.col})
                pool[k]=nil; cur=node; moved=true; break
            end
        end
        if not moved then break end
    end
    return ordered
end

local function solveFlow(puzzle)
    pcall(function()
        if not puzzle or not puzzle.Solution then return end
        local indices={}
        for i=1,#puzzle.Solution do indices[i]=i end
        for i=#indices,2,-1 do local j=math.random(1,i); indices[i],indices[j]=indices[j],indices[i] end
        for _,ci in ipairs(indices) do
            local solution=puzzle.Solution[ci]; if not solution then continue end
            local ordered=flowOrder(solution, puzzle.targetPairs and puzzle.targetPairs[ci])
            if not ordered or #ordered==0 then continue end
            puzzle.paths[ci]={}
            for _,node in ipairs(ordered) do
                table.insert(puzzle.paths[ci],{row=node.row,col=node.col})
                puzzle:updateGui(); task.wait(genState.nodeDelay)
            end
            task.wait(genState.lineDelay); puzzle:checkForWin()
        end
    end)
end

pcall(function()
    local mf  = svc.RS:FindFirstChild("Modules")
    local mnf  = mf  and mf:FindFirstChild("Minigames")
    local fgf  = mnf and mnf:FindFirstChild("FlowGameManager")
    local fgm  = fgf and fgf:FindFirstChild("FlowGame")
    if not fgm then return end
    local ok,FG = pcall(require, fgm)
    if ok and FG and FG.new then
        local origNew=FG.new
        FG.new=function(...)
            local inst=origNew(...)
            if genState.enabled then task.spawn(function() task.wait(0.25); solveFlow(inst) end) end
            return inst
        end
    end
end)

secGen:Toggle({Title="Auto Solve Generator", Default=false, Callback=function(v) genState.enabled=v end})
secGen:Slider({Title="Node Speed", Step=0.01, Value={Min=0.01,Max=0.2,Default=genState.nodeDelay}, Callback=function(v) genState.nodeDelay=v end})

-- ============================================================
-- 3. INFINITE STAMINA
-- ============================================================
local tabGlobal = win:Tab({Title="Global", Icon="globe"})
local secStam   = tabGlobal:Section({Title="Stamina", Opened=true})
local infStam   = false

local function applyStamina()
    pcall(function()
        local sm = svc.RS:FindFirstChild("Systems")
            and svc.RS.Systems:FindFirstChild("Character")
            and svc.RS.Systems.Character:FindFirstChild("Game")
            and svc.RS.Systems.Character.Game:FindFirstChild("Sprinting")
        if sm then local m=require(sm); if m then m.StaminaLossDisabled=infStam end end
    end)
end

task.spawn(function() while true do task.wait(0.8); if infStam then applyStamina() end end end)
secStam:Toggle({Title="Infinite Stamina", Default=false, Callback=function(v) infStam=v; applyStamina() end})

-- ============================================================
-- 4. SURVIVOR AIMBOT
-- ============================================================
local tabAimbot = win:Tab({Title="Aimbot", Icon="crosshair"})
local secAim    = tabAimbot:Section({Title="Survivor Aimbot", Opened=true})

local aim = {
    enabled  = false,
    maxDist  = 100,
    locked   = false,
    target   = nil,
    conn     = nil,
}

local function getNearestTarget()
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local kf      = getTeamFolder("Killers")
    local sf      = getTeamFolder("Survivors")
    local folders = {}
    -- If we are a killer, target survivors; otherwise target killers
    if kf and char:IsDescendantOf(kf) then
        table.insert(folders, sf)
    else
        table.insert(folders, kf)
    end

    local best, bestDist = nil, math.huge
    for _, folder in ipairs(folders) do
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model ~= char and model:IsA("Model") then
                    local r = model:FindFirstChild("HumanoidRootPart")
                    local h = model:FindFirstChildOfClass("Humanoid")
                    if r and h and h.Health > 0 then
                        local d = (r.Position - hrp.Position).Magnitude
                        if d < bestDist and d <= aim.maxDist then bestDist=d; best=r end
                    end
                end
            end
        end
    end
    return best
end

local function aimUnlock()
    if aim.conn then aim.conn:Disconnect(); aim.conn=nil end
    aim.locked=false; aim.target=nil
end

local function aimLock(targetHRP)
    aimUnlock()
    if not targetHRP or not targetHRP.Parent then return end
    aim.target=targetHRP; aim.locked=true
    aim.conn = svc.Run.RenderStepped:Connect(function()
        if not aim.enabled or not aim.target or not aim.target.Parent then
            -- BUG FIX: task.defer avoids calling conn:Disconnect() from inside the
            -- conn's own callback (self-disconnect UB — same class of bug as BUG 2
            -- in executeBackstab). Direct call here caused the lock to silently
            -- corrupt state and stop responding until the user toggled it off/on.
            task.defer(aimUnlock); return
        end
        local cam  = svc.WS.CurrentCamera
        local char = lp.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if cam and hrp then
            local tp = aim.target.Position
            cam.CFrame = CFrame.new(cam.CFrame.Position, tp)
            hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(tp.X, hrp.Position.Y, tp.Z))
        end
    end)
end

-- ── Namecall hook (defined here; references tt + activeBackstabConn
--    via upvalue slots forward-declared at the top — safe because the
--    hook only executes on actual FireServer calls, which happen after
--    the player is in a round and section 5 has already assigned them)
-- ──
-- BUG FIX: added guard so the survivor aimbot does NOT hijack the
-- camera during an active TwoTime backstab. Previously, fireDaggerAbility
-- itself called FireServer("UseActorAbility"), which triggered this hook,
-- spawning aimLock() while activeBackstabConn was running — two systems
-- fighting over hrp.CFrame and cam.CFrame every RenderStepped frame.
-- ──────────────────────────────────────────────────────────────────────
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}

    if aim.enabled and not (elliotAim and elliotAim.enabled) and method == "FireServer" and args[1] == "UseActorAbility" then
        -- Only fire aimLock when TwoTime is NOT mid-backstab
        if not (tt and tt.enabled and activeBackstabConn ~= nil) then
            task.spawn(function()
                local target = getNearestTarget()
                if target then aimLock(target) end
            end)
        end
    end

    return oldNamecall(self, ...)
end)

secAim:Toggle({Title="Enable Aimbot",  Default=false, Callback=function(v) aim.enabled=v; if not v then aimUnlock() end end})
secAim:Slider({Title="Max Distance",   Step=5, Value={Min=20,Max=200,Default=aim.maxDist}, Callback=function(v) aim.maxDist=v end})
secAim:Button({Title="Unlock Target",  Callback=function() aimUnlock() end})

-- ============================================================
-- 4a. ELLIOT PREDICTIVE AIMBOT
-- Production-style predictive targeting for Elliot.
--
-- Predictor inputs:
--   • Target velocity + smoothed acceleration
--   • Local-player horizontal velocity / movement
--   • Distance to target
--   • Current ping
--   • Local geometry density ("area" / corner factor)
--   • Adaptive lead time with clamped limits
--
-- This is intentionally separate from the legacy Survivor Aimbot so
-- both systems can be tested/toggled independently.
-- ============================================================
local secElliotAim = tabAimbot:Section({Title="Elliot Predictive Aimbot", Opened=false})

elliotAim = {
    enabled        = false,
    maxDist        = 140,
    projectileSpeed= 85,      -- tune to the actual attack/projectile speed
    leadStrength   = 1.00,
    pingScale      = 0.55,
    accelWeight    = 0.60,
    areaWeight     = 0.35,
    minLead        = 0.02,
    maxLead        = 0.42,
    smoothSpeed    = 20,
    aimHeight      = 1.15,
    target         = nil,
    targetModel    = nil,
    conn           = nil,
    samples        = {},
    lastTargetPos  = nil,
    lastSampleTime = 0,
    lastAimPos     = nil,
}

local function isElliotCharacter(model)
    if not model or not model:IsA("Model") then return false end

    local n = tostring(model.Name):lower():gsub("[%s_%-]", "")
    if n:find("elliot", 1, true) then return true end

    local ok, attrs = pcall(function() return model:GetAttributes() end)
    if ok and attrs then
        for key, value in pairs(attrs) do
            local k = tostring(key):lower()
            local v = tostring(value):lower():gsub("[%s_%-]", "")
            if (k:find("character",1,true)
                or k:find("kit",1,true)
                or k:find("selected",1,true)
                or k:find("actor",1,true)
                or k:find("class",1,true))
                and v:find("elliot",1,true) then
                return true
            end
        end
    end

    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("StringValue") then
            local k = child.Name:lower()
            local v = tostring(child.Value):lower():gsub("[%s_%-]", "")
            if (k:find("character",1,true)
                or k:find("kit",1,true)
                or k:find("selected",1,true)
                or k:find("actor",1,true)
                or k:find("class",1,true))
                and v:find("elliot",1,true) then
                return true
            end
        end
    end

    return false
end

local function getHorizontalVelocity(part)
    if not part then return Vector3.zero end
    local v = part.AssemblyLinearVelocity
    if not v or v.Magnitude < 0.001 then
        v = part.Velocity
    end
    return Vector3.new(v.X, 0, v.Z)
end

local function getPingSeconds()
    return math.clamp((getPingMs() or 0) / 1000, 0, 0.30)
end

-- Estimate how "open" the target's immediate area is.
-- More nearby collision hits = tighter area/corner = less aggressive lead.
local function getAreaFactor(targetModel, targetHRP)
    if not targetHRP then return 1 end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lp.Character, targetModel}

    local origin = targetHRP.Position + Vector3.new(0, 1.5, 0)
    local dirs = {
        Vector3.new( 1,0, 0), Vector3.new(-1,0, 0),
        Vector3.new( 0,0, 1), Vector3.new( 0,0,-1),
        Vector3.new( 0.707,0, 0.707), Vector3.new(-0.707,0, 0.707),
        Vector3.new( 0.707,0,-0.707), Vector3.new(-0.707,0,-0.707),
    }

    local hits = 0
    for _, d in ipairs(dirs) do
        if svc.WS:Raycast(origin, d * 9, params) then hits = hits + 1 end
    end

    -- 0 hits => 1.0 (open)
    -- 8 hits => 0.65 (very enclosed)
    return 1 - (hits / #dirs) * math.clamp(elliotAim.areaWeight, 0, 0.8)
end

local function resetElliotTrack(targetModel, targetHRP)
    elliotAim.targetModel    = targetModel
    elliotAim.target         = targetHRP
    elliotAim.samples        = {}
    elliotAim.lastTargetPos  = targetHRP and targetHRP.Position or nil
    elliotAim.lastSampleTime = os.clock()
    elliotAim.lastAimPos     = nil
end

local function sampleElliotTarget(targetHRP)
    if not targetHRP then return Vector3.zero, Vector3.zero end

    local now = os.clock()
    local pos = targetHRP.Position
    local rawVel = getHorizontalVelocity(targetHRP)

    local dt = now - (elliotAim.lastSampleTime or now)
    elliotAim.lastSampleTime = now

    local accel = Vector3.zero
    if elliotAim.lastTargetPos and dt > 0.001 then
        accel = (rawVel - (elliotAim._lastVel or rawVel)) / dt
        accel = Vector3.new(accel.X, 0, accel.Z)
    end
    elliotAim._lastVel = rawVel
    elliotAim.lastTargetPos = pos

    -- Rolling samples make prediction less sensitive to replication jitter.
    table.insert(elliotAim.samples, {
        t = now,
        v = rawVel,
        a = accel,
    })
    while #elliotAim.samples > 8 do
        table.remove(elliotAim.samples, 1)
    end

    local avgV, avgA = Vector3.zero, Vector3.zero
    for _, s in ipairs(elliotAim.samples) do
        avgV = avgV + s.v
        avgA = avgA + s.a
    end
    local count = math.max(#elliotAim.samples, 1)
    return avgV / count, avgA / count
end

local function getElliotTarget()
    local char = lp.Character
    local myHRP = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not myHRP then return nil, nil end

    local kf = getTeamFolder("Killers")
    if not kf then return nil, nil end

    local bestModel, bestHRP, bestScore = nil, nil, math.huge
    for _, model in ipairs(kf:GetChildren()) do
        if model:IsA("Model") and model ~= char then
            local hrp = model:FindFirstChild("HumanoidRootPart")
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d <= elliotAim.maxDist then
                    -- Prefer nearer targets while lightly rewarding targets
                    -- that are actually in front of the player's camera.
                    local cam = svc.WS.CurrentCamera
                    local facingPenalty = 0
                    if cam then
                        local toTarget = (hrp.Position - cam.CFrame.Position)
                        if toTarget.Magnitude > 0.01 then
                            local dot = cam.CFrame.LookVector:Dot(toTarget.Unit)
                            facingPenalty = (1 - math.clamp(dot, -1, 1)) * 10
                        end
                    end
                    local score = d + facingPenalty
                    if score < bestScore then
                        bestScore, bestModel, bestHRP = score, model, hrp
                    end
                end
            end
        end
    end

    return bestModel, bestHRP
end

local function getElliotPredictedPosition(targetModel, targetHRP, myHRP)
    if not targetModel or not targetHRP or not myHRP then return nil end

    local targetVel, targetAccel = sampleElliotTarget(targetHRP)
    local myVel = getHorizontalVelocity(myHRP)
    local distance = (targetHRP.Position - myHRP.Position).Magnitude

    local speed = math.max(elliotAim.projectileSpeed, 1)
    local travelTime = distance / speed

    -- Add a bounded network term. Ping is not treated as pure one-way lag;
    -- this keeps the correction conservative rather than doubling latency.
    travelTime = travelTime + getPingSeconds() * elliotAim.pingScale

    -- Own movement shifts the expected release/aim frame. The coefficient is
    -- deliberately modest because Roblox camera movement already includes it.
    local relativeVel = targetVel - myVel * 0.22

    local areaFactor = getAreaFactor(targetModel, targetHRP)
    local accelTerm = math.clamp(elliotAim.accelWeight, 0, 1) * 0.5
    local effectiveT = travelTime * elliotAim.leadStrength * areaFactor

    effectiveT = math.clamp(
        effectiveT,
        elliotAim.minLead,
        elliotAim.maxLead
    )

    local predicted = targetHRP.Position
        + relativeVel * effectiveT
        + targetAccel * (effectiveT * effectiveT) * accelTerm

    -- Keep the aim point on the same practical vertical layer; horizontal
    -- prediction carries the movement while this avoids aiming into the floor
    -- from jump/fall replication noise.
    predicted = Vector3.new(
        predicted.X,
        targetHRP.Position.Y + elliotAim.aimHeight,
        predicted.Z
    )

    return predicted
end

local function elliotAimStop()
    if elliotAim.conn then
        pcall(function() elliotAim.conn:Disconnect() end)
        elliotAim.conn = nil
    end
    elliotAim.target = nil
    elliotAim.targetModel = nil
    elliotAim.samples = {}
    elliotAim.lastTargetPos = nil
    elliotAim.lastAimPos = nil
end

local function elliotAimStart()
    elliotAimStop()

    elliotAim.conn = svc.Run.RenderStepped:Connect(function(dt)
        if not elliotAim.enabled then
            task.defer(elliotAimStop)
            return
        end

        local char = lp.Character
        local myHRP = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not myHRP or not isElliotCharacter(char) then
            elliotAim.target = nil
            elliotAim.targetModel = nil
            elliotAim.samples = {}
            return
        end

        local currentTarget, currentHRP = elliotAim.targetModel, elliotAim.target

        -- Re-acquire when target disappears, dies, or leaves range.
        local invalid = true
        if currentTarget and currentHRP and currentTarget.Parent and currentHRP.Parent then
            local hum = currentTarget:FindFirstChildOfClass("Humanoid")
            local d = (currentHRP.Position - myHRP.Position).Magnitude
            invalid = (not hum or hum.Health <= 0 or d > elliotAim.maxDist)
        end

        if invalid then
            currentTarget, currentHRP = getElliotTarget()
            if currentTarget and currentHRP then
                resetElliotTrack(currentTarget, currentHRP)
            else
                return
            end
        end

        local predicted = getElliotPredictedPosition(currentTarget, currentHRP, myHRP)
        local cam = svc.WS.CurrentCamera
        if not predicted or not cam then return end

        -- Smooth only the direction, never the camera position.
        -- This keeps mobile camera movement responsive while removing
        -- high-frequency target jitter.
        local smooth = math.clamp(elliotAim.smoothSpeed, 1, 60)
        if elliotAim.lastAimPos then
            local alpha = 1 - math.exp(-smooth * (dt or 1/60))
            predicted = elliotAim.lastAimPos:Lerp(predicted, alpha)
        end
        elliotAim.lastAimPos = predicted

        cam.CFrame = CFrame.new(cam.CFrame.Position, predicted)

        -- Keep the character facing the predicted point too, but don't change
        -- its Y rotation when the target is essentially vertical above/below.
        local flat = Vector3.new(predicted.X, myHRP.Position.Y, predicted.Z)
        if (flat - myHRP.Position).Magnitude > 0.05 then
            myHRP.CFrame = CFrame.new(myHRP.Position, flat)
        end
    end)
end

secElliotAim:Toggle({
    Title="Enable Elliot Predictive Aimbot",
    Default=false,
    Callback=function(v)
        elliotAim.enabled = v
        if v then elliotAimStart() else elliotAimStop() end
    end
})
secElliotAim:Slider({
    Title="Max Target Distance",
    Step=5,
    Value={Min=30,Max=200,Default=elliotAim.maxDist},
    Callback=function(v) elliotAim.maxDist=v end
})
secElliotAim:Slider({
    Title="Projectile / Attack Speed",
    Step=5,
    Value={Min=20,Max=250,Default=elliotAim.projectileSpeed},
    Callback=function(v) elliotAim.projectileSpeed=v end
})
secElliotAim:Slider({
    Title="Lead Strength",
    Step=0.05,
    Value={Min=0.25,Max=1.50,Default=elliotAim.leadStrength},
    Callback=function(v) elliotAim.leadStrength=v end
})
secElliotAim:Slider({
    Title="Prediction Smoothing",
    Step=1,
    Value={Min=4,Max=40,Default=elliotAim.smoothSpeed},
    Callback=function(v) elliotAim.smoothSpeed=v end
})
secElliotAim:Slider({
    Title="Ping Compensation",
    Step=0.05,
    Value={Min=0,Max=1,Default=elliotAim.pingScale},
    Callback=function(v) elliotAim.pingScale=v end
})
secElliotAim:Button({
    Title="Force Re-acquire",
    Callback=function()
        elliotAim.target = nil
        elliotAim.targetModel = nil
        elliotAim.samples = {}
        elliotAim.lastTargetPos = nil
        elliotAim.lastAimPos = nil
    end
})

-- ============================================================
-- 4b. SMART KILLER AIMBOT
-- Locks cam onto a survivor's LEGS (so the killer keeps
-- peripheral awareness of surroundings).
--
-- Behaviour:
--   • Acquires nearest survivor within 40 studs on first tick.
--   • Stays locked to that survivor until they die — never
--     auto-switches while alive (sticky target).
--   • If distance > maxDist OR a wall blocks LOS → cam goes
--     free, but we KEEP the same target identity so we re-lock
--     the instant they're close and visible again.
--   • "Force Re-acquire" button clears the lock and picks fresh.
-- ============================================================
local secKillerAim = tabAimbot:Section({Title="Smart Killer Aimbot", Opened=false})

local killerAim = {
    enabled      = false,
    maxDist      = 15,       -- studs — beyond this or when blocked: free cam
    lockedModel  = nil,      -- the committed survivor Model
    lockedHRP    = nil,      -- that model's HumanoidRootPart (cached)
    camActive    = false,    -- whether cam lock is currently applied
    conn         = nil,
    injuredFirst = true,     -- NEW: sort by lowest HP on acquisition
    downedPrio   = true,     -- NEW: targets < 30% HP jump to front regardless of distance
    camTookOver  = false,    -- NEW: tracks whether we've taken CameraType.Scriptable ownership
    smoothSpeed  = 14,       -- NEW: rotation lerp speed (higher = snappier, lower = smoother)
}

-- Walk down the rig hierarchy to find the lowest available
-- leg/foot bone. Falls back to HRP-2.2 studs if nothing found.
local function getKillerAimLegPos(model)
    local priority = {
        "RightFoot","LeftFoot",
        "RightLowerLeg","LeftLowerLeg",
        "Right Leg","Left Leg",
        "LowerTorso",
    }
    for _, name in ipairs(priority) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part.Position end
    end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    return hrp and (hrp.Position - Vector3.new(0, 2.2, 0)) or nil
end

-- Raycast from killer's eye level to survivor's HRP.
-- Excludes both characters so their own geometry can't block.
local function killerAimHasLOS(killerHRP, targetHRP, killerChar, targetChar)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {killerChar, targetChar}
    local origin = killerHRP.Position + Vector3.new(0, 1.5, 0)
    local dir    = targetHRP.Position - origin
    return svc.WS:Raycast(origin, dir, params) == nil
end

local function killerAimStop()
    if killerAim.conn then pcall(function() killerAim.conn:Disconnect() end); killerAim.conn=nil end
    killerAim.lockedModel = nil
    killerAim.lockedHRP   = nil
    killerAim.camActive   = false
    -- Give the camera back to Roblox's normal controller — without this,
    -- disabling the aimbot mid-lock leaves the player with no free-look
    -- because CameraType stayed on Scriptable
    if killerAim.camTookOver then
        pcall(function() svc.WS.CurrentCamera.CameraType = Enum.CameraType.Custom end)
        killerAim.camTookOver = false
    end
end

local function killerAimRun()
    killerAimStop()
    killerAim.conn = svc.Run.RenderStepped:Connect(function(dt)
        if not killerAim.enabled then
            -- BUG FIX: same self-disconnect UB as aimLock fix above
            task.defer(killerAimStop); return
        end

        local char = lp.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then return end
        local cam = svc.WS.CurrentCamera

        -- ── PATH A: we have a locked target ──────────────────────────
        if killerAim.lockedModel then
            local model = killerAim.lockedModel
            local tHRP  = killerAim.lockedHRP
            local tHum  = model:FindFirstChildOfClass("Humanoid")

            -- Survivor left the game or died → full release, acquire next frame
            if not model.Parent or not tHRP or not tHRP.Parent
               or (tHum and tHum.Health <= 0) then
                killerAim.lockedModel = nil
                killerAim.lockedHRP   = nil
                killerAim.camActive   = false
                if killerAim.camTookOver then
                    pcall(function() cam.CameraType = Enum.CameraType.Custom end)
                    killerAim.camTookOver = false
                end
                return
            end

            local dist   = (tHRP.Position - hrp.Position).Magnitude
            local hasLOS = killerAimHasLOS(hrp, tHRP, char, model)

            -- Small hysteresis on the range boundary: once locked, don't drop
            -- until 4 studs past maxDist. Prevents CameraType flicking
            -- Scriptable/Custom every frame when dist sits right on the edge.
            local exitDist = killerAim.maxDist + 4
            local rangeOk  = killerAim.camActive
                and (dist <= exitDist)
                or  (dist <= killerAim.maxDist)

            if rangeOk and hasLOS then
                local legPos = getKillerAimLegPos(model)
                if cam and legPos then
                    -- Take full ownership of the camera. Roblox's own
                    -- Custom-type follow-cam was fighting our rotation-only
                    -- assignment: it kept recalculating POSITION every frame
                    -- based on the character, using OUR modified rotation as
                    -- its input — a steep look-at-legs angle made it snap
                    -- position to bizarre places trying to "catch up."
                    -- Scriptable disables that entirely; we now own both.
                    if not killerAim.camTookOver then
                        cam.CameraType = Enum.CameraType.Scriptable
                        killerAim.camTookOver = true
                    end
                    -- Position: fixed 8 studs behind + 3 up from the killer's
                    -- HRP, using a FLATTENED look direction (Y zeroed) so
                    -- aiming steeply down at the legs never tilts the anchor
                    -- point itself — only the final look-at rotation tilts.
                    local lookFlat = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
                    lookFlat = (lookFlat.Magnitude > 0.01) and lookFlat.Unit or Vector3.new(0,0,-1)
                    local camPos = hrp.Position - lookFlat*8 + Vector3.new(0,3,0)

                    -- Rotation-only smoothing: position stays glued to the
                    -- killer's body every frame (instant, no lag when YOU
                    -- move), but the LOOK direction slerps toward the target
                    -- instead of snapping — this is what stops fast survivor
                    -- movement from whipping the camera frame-to-frame.
                    -- "CFrame - Vector3" strips position, keeping rotation
                    -- only, so Lerp interpolates purely the orientation.
                    local targetCF   = CFrame.new(camPos, legPos)
                    local curRotOnly = cam.CFrame - cam.CFrame.Position
                    local tgtRotOnly = targetCF   - targetCF.Position
                    local alpha      = 1 - math.exp(-killerAim.smoothSpeed * (dt or 1/60))
                    cam.CFrame = (curRotOnly:Lerp(tgtRotOnly, alpha)) + camPos
                end
                killerAim.camActive = true
            else
                -- Too far OR wall in the way → give the camera back so the
                -- killer gets normal free-look to navigate around
                if killerAim.camTookOver then
                    pcall(function() cam.CameraType = Enum.CameraType.Custom end)
                    killerAim.camTookOver = false
                end
                killerAim.camActive = false
            end

        -- ── PATH B: acquire with priority ────────────────────────────
        -- 1st: downed (< 30% HP) regardless of distance (if downedPrio)
        -- 2nd: most injured (lowest HP) (if injuredFirst)
        -- 3rd: tiebreak by closest distance
        else
            local sf = getTeamFolder("Survivors")
            if not sf then return end
            local candidates = {}
            for _, model in ipairs(sf:GetChildren()) do
                if model ~= char and model:IsA("Model") then
                    local r = model:FindFirstChild("HumanoidRootPart")
                    local h = model:FindFirstChildOfClass("Humanoid")
                    if r and h and h.Health > 0 then
                        local d = (r.Position - hrp.Position).Magnitude
                        if d <= 40 then
                            table.insert(candidates, {
                                model  = model, hrp = r,
                                health = h.Health,
                                maxHP  = math.max(h.MaxHealth, 1),
                                dist   = d,
                            })
                        end
                    end
                end
            end
            if #candidates == 0 then return end
            if killerAim.injuredFirst then
                table.sort(candidates, function(a, b)
                    local aDn = killerAim.downedPrio and (a.health/a.maxHP) < 0.30
                    local bDn = killerAim.downedPrio and (b.health/b.maxHP) < 0.30
                    if aDn ~= bDn then return aDn end
                    if math.abs(a.health - b.health) > 5 then return a.health < b.health end
                    return a.dist < b.dist
                end)
            end
            local pick = candidates[1]
            killerAim.lockedModel = pick.model
            killerAim.lockedHRP   = pick.hrp
        end
    end)
end

secKillerAim:Toggle({
    Title    = "Enable Smart Killer Aimbot",
    Default  = false,
    Callback = function(v)
        killerAim.enabled = v
        if v then killerAimRun() else killerAimStop() end
    end
})
secKillerAim:Toggle({
    Title    = "Injured First (most damaged target)",
    Default  = true,
    Callback = function(v) killerAim.injuredFirst = v end
})
secKillerAim:Toggle({
    Title    = "Downed Priority (< 30% HP first)",
    Default  = true,
    Callback = function(v) killerAim.downedPrio = v end
})
secKillerAim:Slider({
    Title    = "Unlock Distance (studs)",
    Step     = 1,
    Value    = {Min=5, Max=40, Default=killerAim.maxDist},
    Callback = function(v) killerAim.maxDist = v end
})
secKillerAim:Slider({
    Title    = "Cam Smoothness",
    Step     = 1,
    Value    = {Min=4, Max=30, Default=killerAim.smoothSpeed},
    Callback = function(v) killerAim.smoothSpeed = v end
})
secKillerAim:Button({
    Title    = "Force Re-acquire Target",
    Callback = function()
        killerAim.lockedModel = nil
        killerAim.lockedHRP   = nil
        killerAim.camActive   = false
    end
})

-- ============================================================
-- 4c. ANTI TWO-TIME BACKSTAB (Killer)
-- Roblox does NOT expose another player's selected character/kit to
-- your client through any standard channel — Backpack only replicates
-- for the LocalPlayer, and there's no confirmed public attribute for
-- "which survivor kit is this." So instead of guessing at kit identity,
-- this detects the ATTACK PATTERN itself: only Two Time has a working
-- backstab, so anyone sneaking into your blind cone at close range is
-- functionally the same threat regardless of whether kit-ID succeeds.
-- A best-effort kit check exists as an optional stricter filter.
-- ============================================================
local secAntiBS = tabAimbot:Section({Title="Anti-Backstab (Killer)", Opened=false})

local antiBS = {
    enabled     = false,
    dangerRange = 12,    -- studs — proximity treated as "close enough to backstab"
    coneAngle   = 75,    -- degrees — half-angle of YOUR blind cone (mirrors TwoTime's own cone check)
    lungeSpeed  = 24,    -- studs/sec toward you — velocity spike that reads as a lunge
    requireKit  = false, -- if true, only react to a CONFIRMED Two Time (best-effort, may not detect)
    conn        = nil,
    threatModel = nil,
    lastSeenTime= 0,
}

-- Best-effort kit identification — tries every common signal a game might
-- expose (attributes, child values, an equipped Tool named like the
-- ability). Returns false (not confirmed) rather than guessing, since a
-- false positive here just means requireKit=true stays silent — the
-- pattern-based detection above still works with this off.
local function isLikelyTwoTime(model)
    local ok, attrs = pcall(function() return model:GetAttributes() end)
    if ok and attrs then
        for k, v in pairs(attrs) do
            local lk = tostring(k):lower()
            if (lk:find("character") or lk:find("kit") or lk:find("selected") or lk:find("class"))
               and type(v)=="string" and v:lower():gsub("%s","")=="twotime" then
                return true
            end
        end
    end
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("StringValue") then
            local ln = child.Name:lower()
            if (ln:find("character") or ln:find("kit") or ln:find("selected"))
               and tostring(child.Value):lower():gsub("%s","")=="twotime" then
                return true
            end
        end
        -- Equipped Tools DO replicate onto the character model for every
        -- client to see — if the dagger is a real Tool (not GUI+remote only)
        -- this catches it. Harmless if it never matches.
        if child:IsA("Tool") and child.Name:lower():find("dagger") then
            return true
        end
    end
    return false
end

-- Confirmed via in-game Animation Logger — this is the actual dagger
-- ability animation ID, not a heuristic guess. Playing tracks replicate
-- to every client (they have to, for you to visually see other players
-- animate), so this is ground truth: if this ID is playing on a
-- survivor's Humanoid, the ability is firing RIGHT NOW.
local TWO_TIME_DAGGER_ANIM_ID = "rbxassetid://100725497418533"

local function isPlayingDaggerAnim(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local ok, tracks = pcall(function() return hum:GetPlayingAnimationTracks() end)
    if not ok or not tracks then return false end
    for _, track in ipairs(tracks) do
        local anim = track.Animation
        if anim and anim.AnimationId == TWO_TIME_DAGGER_ANIM_ID then
            return true
        end
    end
    return false
end

-- Finds the highest-priority backstab threat: behind you (blind cone),
-- within danger range OR lunging in from slightly further out.
local function findBackstabThreat(hrp)
    local sf = getTeamFolder("Survivors")
    if not sf then return nil end
    local char = lp.Character
    local best, bestScore = nil, -1
    for _, model in ipairs(sf:GetChildren()) do
        if model:IsA("Model") and model ~= char then
            local r = model:FindFirstChild("HumanoidRootPart")
            local h = model:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 and (not antiBS.requireKit or isLikelyTwoTime(model)) then
                local toSurv = r.Position - hrp.Position
                local dist   = toSurv.Magnitude
                if dist > 0.1 then
                    -- Blind-cone check: mirrors the exact math TwoTime's own
                    -- backstab uses against YOU (isPlayerBehindKiller), just
                    -- from your perspective now
                    local dot    = toSurv.Unit:Dot(-hrp.CFrame.LookVector)
                    local inCone = dot >= math.cos(math.rad(antiBS.coneAngle))

                    -- Lunge detection: velocity component pointed at you,
                    -- above normal sprint speed — this is the "lunge when
                    -- dagger" tell. Overrides range slightly since a real
                    -- lunge closes distance fast and deserves an early react.
                    local vel = r.AssemblyLinearVelocity or Vector3.zero
                    local approachSpeed = 0
                    if vel.Magnitude > 0.5 then
                        approachSpeed = vel.Unit:Dot((hrp.Position-r.Position).Unit) * vel.Magnitude
                    end
                    local lunging = approachSpeed > antiBS.lungeSpeed

                    -- CONFIRMED signal — the dagger animation is actually
                    -- playing. This bypasses the cone check entirely (by the
                    -- time you can detect an already-playing animation, you
                    -- may already be mid-swing on their end) but stays
                    -- capped to a sane range so we ignore irrelevant activity
                    -- happening elsewhere on the map.
                    local abilityFiring = dist <= 20 and isPlayingDaggerAnim(model)

                    local rangeOk = dist <= antiBS.dangerRange
                        or (lunging and dist <= antiBS.dangerRange*1.6)

                    if abilityFiring or (inCone and rangeOk) then
                        -- math.max(dot,0.1) keeps the score positive even
                        -- when abilityFiring bypasses the cone (dot could be
                        -- low/negative if this is actually a front hit, not
                        -- a backstab — still fine to turn and face them)
                        local score = (1/math.max(dist,1)) * math.max(dot,0.1)
                            * (lunging and 2 or 1) * (abilityFiring and 4 or 1)
                        if score > bestScore then bestScore=score; best=r end
                    end
                end
            end
        end
    end
    return best
end

local function toggleAntiBackstab(state)
    antiBS.enabled = state
    if antiBS.conn then pcall(function() antiBS.conn:Disconnect() end); antiBS.conn=nil end
    if not state then antiBS.threatModel=nil; return end
    antiBS.conn = svc.Run.Heartbeat:Connect(function()
        if not antiBS.enabled then return end
        pcall(function()
            local char=lp.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
            local hum =char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health<=0 then return end

            local threat = findBackstabThreat(hrp)
            if threat then
                antiBS.threatModel  = threat
                antiBS.lastSeenTime = os.clock()
                -- Turn to face them — the instant you're no longer facing
                -- away, their blind-cone requirement for the backstab fails
                local facePos = Vector3.new(threat.Position.X, hrp.Position.Y, threat.Position.Z)
                hrp.CFrame = CFrame.new(hrp.Position, facePos)
            elseif antiBS.threatModel and os.clock()-antiBS.lastSeenTime < 0.5 then
                -- 0.5s hold on the last known threat position — without this,
                -- a single frame where they step just outside the cone would
                -- release facing control and let them slip back in immediately
                if antiBS.threatModel.Parent then
                    local hrp2 = antiBS.threatModel:FindFirstChild("HumanoidRootPart")
                    if hrp2 then
                        local facePos = Vector3.new(hrp2.Position.X, hrp.Position.Y, hrp2.Position.Z)
                        hrp.CFrame = CFrame.new(hrp.Position, facePos)
                    end
                end
            else
                antiBS.threatModel = nil
            end
        end)
    end)
end

secAntiBS:Toggle({
    Title    = "Enable Anti-Backstab",
    Default  = false,
    Callback = function(v) toggleAntiBackstab(v) end
})
secAntiBS:Slider({
    Title    = "Danger Range (studs)",
    Step     = 1,
    Value    = {Min=6, Max=25, Default=antiBS.dangerRange},
    Callback = function(v) antiBS.dangerRange = v end
})
secAntiBS:Slider({
    Title    = "Blind Cone Angle (°)",
    Step     = 5,
    Value    = {Min=30, Max=120, Default=antiBS.coneAngle},
    Callback = function(v) antiBS.coneAngle = v end
})
secAntiBS:Slider({
    Title    = "Lunge Sensitivity (studs/sec)",
    Step     = 1,
    Value    = {Min=15, Max=30, Default=antiBS.lungeSpeed},
    Callback = function(v) antiBS.lungeSpeed = v end
})
secAntiBS:Toggle({
    Title    = "Require Confirmed Two Time (stricter, may not detect)",
    Default  = false,
    Callback = function(v) antiBS.requireKit = v end
})

-- ============================================================
-- 5. TWO TIME BACKSTAB
-- ============================================================
local tabTwoTime = win:Tab({Title="TwoTime", Icon="sword"})
local secTwoTime = tabTwoTime:Section({Title="Backstab Settings", Opened=true})

-- ── Assign to forward-declared upvalue slots ──────────────────
-- Using plain assignment (no 'local') so the closures in
-- sections 4 and 4b that already closed over these slots see
-- the correct values once execution reaches here.
tt = {
    enabled          = false,
    autoStab         = true,
    doubleStab       = false,   -- NEW: fire dagger twice per trigger
    triggerFlash     = false,   -- NEW: screen flash on confirmed backstab fire
    checkCooldown    = true,
    ignoreStunImmune = true,
    checkObstacles   = true,
    snappyTp         = true,
    range            = 10,
    behindDist       = 3.5,
    cooldown         = 30.0,
    coneAngle        = 70,
    aimLockTime      = 0.3,
    lockMode         = "Cam lock + Humanoid lock",
    -- FIX: start at -30 so the very first use fires immediately
    -- instead of waiting 30s from script load.
    lastTrigger      = -30,
}
activeBackstabConn = nil

local killerImmunityState = {}

-- ── Internal helpers ──────────────────────────────────────────

local function resetBackstabLock()
    if activeBackstabConn then
        pcall(function() activeBackstabConn:Disconnect() end)
        activeBackstabConn = nil
    end
    pcall(function()
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end)
    ensureTouchGuiVisible()
end

local function getDaggerButton()
    local pg        = lp:FindFirstChildOfClass("PlayerGui")
    local mainUI    = pg and pg:FindFirstChild("MainUI")
    local container = mainUI and mainUI:FindFirstChild("AbilityContainer")
    return container and container:FindFirstChild("Dagger")
end

local function getPing()
    local ok, v = pcall(function()
        return svc.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return (ok and v and v > 0 and v / 1000) or 0.08
end

-- NOTE: Internal 30s timer is checked by Heartbeat directly.
-- This function only reads the live game state (UI / attributes).
local function isDaggerOnCooldown()
    local btn = getDaggerButton()
    if btn then
        for _, name in ipairs({"CooldownTime","Cooldown","CD","Timer","CooldownLabel"}) do
            local cd = btn:FindFirstChild(name)
            if cd then
                if cd:IsA("TextLabel") or cd:IsA("TextBox") then
                    local val = tonumber(cd.Text:match("[%d%.]+"))
                    if val and val > 0.05 then return true end
                elseif cd:IsA("NumberValue") or cd:IsA("IntValue") or cd:IsA("DoubleConstrainedValue") then
                    if cd.Value > 0.05 then return true end
                end
            end
        end
        local overlay = btn:FindFirstChild("Overlay") or btn:FindFirstChild("CooldownOverlay")
        if overlay and overlay:IsA("GuiObject") and overlay.Visible then return true end
    end
    local char = lp.Character
    if char then
        local cd = char:GetAttribute("DaggerCooldown")
                or char:GetAttribute("DaggerCD")
                or char:GetAttribute("StabCooldown")
        if type(cd) == "number"  and cd    then return true end
        if type(cd) == "boolean" and cd    then return true end
    end
    return false
end

local function hasLineOfSight(posA, posB, ignoreChar)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {ignoreChar, lp.Character}
    return svc.WS:Raycast(posA, posB - posA, params) == nil
end

local function isKillerStunImmune(killer)
    if not killer or not killer.Parent then return false end
    local isImmune = false

    local function checkAttrs(obj)
        if isImmune then return end
        local ok, attrs = pcall(function() return obj:GetAttributes() end)
        if not (ok and attrs) then return end
        for k, v in pairs(attrs) do
            local lk = tostring(k):lower()
            if (lk:find("stun") or lk:find("immune") or lk:find("invulner") or lk:find("parry"))
               and (v == true or v == 1) then
                isImmune = true; return
            end
        end
    end

    checkAttrs(killer)
    if not isImmune then
        local hum = killer:FindFirstChildOfClass("Humanoid")
        if hum then checkAttrs(hum) end
    end
    if not isImmune then
        for _, cont in ipairs({
            killer,
            killer:FindFirstChild("StatusEffects"),
            killer:FindFirstChild("Effects"),
            killer:FindFirstChild("Buffs"),
            killer:FindFirstChild("States"),
        }) do
            if cont then
                for _, child in ipairs(cont:GetChildren()) do
                    local ln = child.Name:lower()
                    if ln:find("stunimmune") or ln:find("immunity")
                       or ln:find("invulner") or ln:find("parry") or ln:find("blocking") then
                        isImmune=true; break
                    end
                end
            end
            if isImmune then break end
        end
    end

    local prev = killerImmunityState[killer]
    if prev == nil then
        killerImmunityState[killer] = isImmune
        if isImmune then print("Killer stun immunity ENABLE ("..killer.Name..")") end
    elseif prev ~= isImmune then
        killerImmunityState[killer] = isImmune
        print(isImmune
            and ("Killer stun immunity ENABLE ("..killer.Name..")")
            or  ("Killer stun immunity DISABLED ("..killer.Name..")"))
    end
    return isImmune
end

-- Passive immunity scanner
task.spawn(function()
    while true do
        task.wait(0.15)
        pcall(function()
            local kf = getTeamFolder("Killers"); if not kf then return end
            for _, killer in ipairs(kf:GetChildren()) do
                if killer:IsA("Model") then isKillerStunImmune(killer) end
            end
        end)
    end
end)

-- ── fireDaggerAbility ─────────────────────────────────────────
-- NEW: supports tt.doubleStab — fires the dagger ability twice
-- with a 180ms gap between hits. Called via task.spawn so
-- executeBackstab can set up activeBackstabConn in parallel.
local function fireDaggerAbility()
    local function doOneFire()
        local re = getRemoteEvent()
        if re then
            pcall(function() re:FireServer("UseActorAbility",{[1]=buffer.fromstring("\3\5\0\0\0Dagger")}) end)
            pcall(function() re:FireServer("UseActorAbility",{[1]=buffer.fromstring("\3\4\0\0\0Stab")})   end)
        end
        local btn = getDaggerButton()
        if btn then
            pcall(function() if btn.Activate then btn:Activate() end end)
            pcall(function()
                if type(getconnections)=="function" and btn.MouseButton1Click then
                    for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                        if conn.Function then pcall(conn.Function) end
                    end
                end
            end)
            pcall(function() if btn.Activated then btn.Activated:Fire() end end)
        end
    end

    doOneFire()
    -- Screen flash feedback on confirmed stab fire
    if tt.triggerFlash and doTriggerFlash then task.spawn(doTriggerFlash) end
    if tt.doubleStab then
        task.wait(0.18)  -- 180ms between stabs; tight but within server tick tolerance
        doOneFire()
    end
end

-- ── Position helpers ──────────────────────────────────────────
local function computeBehindCFrame(hrp, khrp)
    local kCF  = khrp.CFrame
    local vel  = khrp.AssemblyLinearVelocity or Vector3.zero
    local lead = math.clamp(getPing() + 0.04, 0.04, 0.2)
    local pred = kCF.Position
    if vel.Magnitude > 2 then pred = pred + vel * lead end
    local behind = pred - kCF.LookVector.Unit * tt.behindDist
    behind = Vector3.new(behind.X, hrp.Position.Y, behind.Z)
    return CFrame.new(behind, Vector3.new(pred.X, hrp.Position.Y, pred.Z))
end

local function isPlayerBehindKiller(hrp, khrp, dist)
    if dist > tt.range or dist < 0.1 then return false end
    local dot = (hrp.Position - khrp.Position).Unit:Dot(-khrp.CFrame.LookVector)
    return dot >= math.cos(math.rad(tt.coneAngle))
end

-- ── executeBackstab ───────────────────────────────────────────
--
-- BUGS FIXED HERE:
--
--  BUG 1 (main "stops working" bug):
--    The old code checked isPlayerBehindKiller() inside the
--    RenderStepped callback every frame. If the killer
--    twitched even 1° outside the cone, the check failed,
--    resetBackstabLock() was called, the connection died, but
--    tt.lastTrigger had already been set → Heartbeat blocked
--    for 30s. User had to toggle off/on to reset lastTrigger.
--    FIX: removed isPlayerBehindKiller from inside the callback.
--    The connection now runs for the full aimLockTime duration
--    and exits cleanly via task.defer.
--
--  BUG 2 (self-disconnect undefined behaviour):
--    Calling conn:Disconnect() from inside the conn's own
--    callback can leave the callback in a half-executed state
--    on some Roblox executor builds.
--    FIX: task.defer(resetBackstabLock) defers cleanup to the
--    next scheduler tick, safely outside the callback.
--
--  BUG 3 (double-entry race):
--    Heartbeat fires every ~1/60 s. Between resetBackstabLock
--    clearing activeBackstabConn and the new connection being
--    set (~1 instruction later) there was a 1-frame window
--    where a second call could slip in.
--    FIX: guard added in Heartbeat: `if activeBackstabConn then return end`
-- ─────────────────────────────────────────────────────────────
local function executeBackstab(killer)
    -- Clear any previous lock cleanly
    resetBackstabLock()

    local char = lp.Character
    local hrp  = char  and char:FindFirstChild("HumanoidRootPart")
    local hum  = char  and char:FindFirstChildOfClass("Humanoid")
    local khrp = killer and killer:FindFirstChild("HumanoidRootPart")
    if not hrp or not khrp then return end

    -- Obstacle check — bail WITHOUT burning cooldown if blocked
    if tt.checkObstacles and not hasLineOfSight(hrp.Position, khrp.Position, killer) then
        return
    end

    if hum then hum.AutoRotate = false end
    if tt.autoStab then task.spawn(fireDaggerAbility) end

    local startTime = os.clock()

    activeBackstabConn = svc.Run.RenderStepped:Connect(function()
        local elapsed = os.clock() - startTime

        -- Exit condition: timeout or either character left the world
        if elapsed >= tt.aimLockTime
           or not khrp or not khrp.Parent
           or not hrp  or not hrp.Parent then
            task.defer(resetBackstabLock)   -- deferred = safe outside callback context
            return
        end

        -- Apply chosen lock mode
        -- NOTE: isPlayerBehindKiller is NOT called here (was BUG 1).
        -- Once we've committed to a backstab we hold position for
        -- the full aimLockTime regardless of micro-rotations.
        local cam      = svc.WS.CurrentCamera
        local targetCF = computeBehindCFrame(hrp, khrp)
        local nextCF   = tt.snappyTp and targetCF or hrp.CFrame:Lerp(targetCF, 0.65)

        if tt.lockMode == "Cam lock + Humanoid lock" then
            hrp.CFrame = nextCF
            if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, khrp.Position + Vector3.new(0,1.5,0)) end

        elseif tt.lockMode == "Humanoid lock" then
            hrp.CFrame = nextCF

        elseif tt.lockMode == "Cam lock" then
            hrp.CFrame = CFrame.new(nextCF.Position, hrp.CFrame.LookVector)
            if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, khrp.Position + Vector3.new(0,1.5,0)) end
        end
    end)
end

-- ── Heartbeat detection loop ──────────────────────────────────
-- FIX: `if activeBackstabConn then return end` added (BUG 3 guard).
-- Cooldown burned here, after the obstacle check inside executeBackstab
-- returns safely — failed obstacle checks no longer eat the 30s window.
-- REMOVED isDaggerOnCooldown() UI-scrape: it guessed at label/attribute
-- names Forsaken doesn't actually use, so it never worked. The self-
-- tracked os.clock() timer on the line below is the real gate and was
-- always correct on its own.
svc.Run.Heartbeat:Connect(function()
    if not tt.enabled then return end
    if activeBackstabConn then return end              -- BUG 3 FIX: no double-entry
    if os.clock() - tt.lastTrigger < tt.cooldown then return end

    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local kf = getTeamFolder("Killers"); if not kf then return end

    for _, killer in ipairs(kf:GetChildren()) do
        local khrp = killer:FindFirstChild("HumanoidRootPart")
        local khum = killer:FindFirstChildOfClass("Humanoid")
        if khrp and khum and khum.Health > 0 then
            if tt.ignoreStunImmune and isKillerStunImmune(killer) then continue end
            local dist = (khrp.Position - hrp.Position).Magnitude
            if isPlayerBehindKiller(hrp, khrp, dist) then
                tt.lastTrigger = os.clock()  -- burn cooldown on valid trigger
                executeBackstab(killer)
                break
            end
        end
    end
end)

-- ── Character / round reset ───────────────────────────────────
lp.CharacterAdded:Connect(function()
    resetBackstabLock()
    tt.lastTrigger          = -30
    killerImmunityState     = {}
    aimUnlock()
    killerAim.lockedModel   = nil
    killerAim.lockedHRP     = nil
    killerAim.camActive     = false
    -- Safety net: if our own character respawns mid-lock, make sure the
    -- camera doesn't stay stuck in Scriptable with no controller driving it
    if killerAim.camTookOver then
        pcall(function() svc.WS.CurrentCamera.CameraType = Enum.CameraType.Custom end)
        killerAim.camTookOver = false
    end
    if antiBS then antiBS.threatModel = nil; antiBS.lastSeenTime = 0 end
    if staminaEstimate then
        staminaEstimate.value        = 100
        staminaEstimate.exhaustStart = nil
        staminaEstimate.lastTime     = os.clock()
    end
    if helper then
        if helper.killerStamEst then
            helper.killerStamEst.value    = 110
            helper.killerStamEst.lastPos  = nil
            helper.killerStamEst.lastTime = os.clock()
        end
        helper.hitsTaken     = 0
        helper.lastHitTime   = 0
        helper.lastKnownHP   = 100
        helper.isNavigating  = false
        helper.abortNav      = false
        helper.currentGenTarget = nil
        helper.killerPrevPos  = nil
        helper.killerApprVel  = 0
        helper.killerPrevTime = os.clock()
        helper.orbitAngle     = 0
        helper.lastOrbitModel = nil
        helper.orbitTime      = os.clock()
        helper.approachHistory = {}
        helper.distHistory     = {}
        helper.playState       = "IDLE"
        -- Re-arm grace period on respawn if Auto Play is already running —
        -- fresh spawn position means killer distance/approach data is stale
        if helper.autoPlay then helper.playStartTime = os.clock() end
        -- Wire hit tracker for the newly spawned character
        if type(setupHitTracker)=="function" then
            task.spawn(function()
                task.wait(0.5)
                local char=lp.Character
                if char then setupHitTracker(char) end
            end)
        end
    end
end)

-- ── TwoTime UI ───────────────────────────────────────────────
secTwoTime:Toggle({
    Title    = "Auto Backstab",
    Default  = false,
    Callback = function(v)
        tt.enabled = v
        tt.lastTrigger = -30  -- reset cooldown on every toggle
        if not v then resetBackstabLock() end
    end
})
secTwoTime:Toggle({
    Title    = "Auto Stab Dagger On TP",
    Default  = true,
    Callback = function(v) tt.autoStab = v end
})
secTwoTime:Toggle({
    Title    = "Double Auto Stab (fire ×2)",
    Default  = false,
    Callback = function(v) tt.doubleStab = v end
})
secTwoTime:Toggle({
    Title    = "Snappy Instant TP",
    Default  = true,
    Callback = function(v) tt.snappyTp = v end
})
secTwoTime:Toggle({
    Title    = "Wall / Obstacle Protection",
    Default  = true,
    Callback = function(v) tt.checkObstacles = v end
})
secTwoTime:Toggle({
    Title    = "Ignore Stun Immune Killers",
    Default  = true,
    Callback = function(v) tt.ignoreStunImmune = v end
})
secTwoTime:Dropdown({
    Title    = "Lock Mode",
    Values   = {"Cam lock + Humanoid lock", "Cam lock", "Humanoid lock"},
    Default  = tt.lockMode,
    Callback = function(v) tt.lockMode = v end
})
secTwoTime:Slider({Title="Trigger Range",         Step=1,    Value={Min=3,   Max=25,  Default=tt.range      }, Callback=function(v) tt.range=v       end})
secTwoTime:Slider({Title="Behind Distance",        Step=0.5,  Value={Min=1,   Max=8,   Default=tt.behindDist }, Callback=function(v) tt.behindDist=v  end})
secTwoTime:Slider({Title="Behind Cone Angle (°)",  Step=5,    Value={Min=20,  Max=180, Default=tt.coneAngle  }, Callback=function(v) tt.coneAngle=v   end})
secTwoTime:Slider({Title="Sticky TP Duration (s)", Step=0.05, Value={Min=0.1, Max=0.6, Default=0.3           }, Callback=function(v) tt.aimLockTime=v end})

-- ============================================================
-- 6. TWOTIME HUD & FEEDBACK
-- ============================================================

-- ── Trigger flash ─────────────────────────────────────────────
local _triggerFlashFrame = nil
local _triggerFlashGui   = nil

-- Assign to forward-declared upvalue so fireDaggerAbility can call it
doTriggerFlash = function()
    pcall(function()
        local pg = lp:FindFirstChildOfClass("PlayerGui")
        if not pg then return end
        if not _triggerFlashGui or not _triggerFlashGui.Parent then
            local sg = Instance.new("ScreenGui")
            sg.Name="BH_TriggerFlash"; sg.ResetOnSpawn=false
            sg.IgnoreGuiInset=true; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=pg
            local frame = Instance.new("Frame")
            frame.Size=UDim2.new(1,0,1,0); frame.BorderSizePixel=0
            frame.BackgroundColor3=Color3.fromRGB(255,210,40)
            frame.BackgroundTransparency=1; frame.Parent=sg
            _triggerFlashGui=sg; _triggerFlashFrame=frame
        end
        local ts = game:GetService("TweenService")
        _triggerFlashFrame.BackgroundTransparency = 0.55
        ts:Create(_triggerFlashFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {BackgroundTransparency=1}
        ):Play()
    end)
end

-- ── Cooldown Ready Indicator ──────────────────────────────────
local cdInd = {
    enabled = false, gui = nil, dot = nil, label = nil,
    conn = nil, _tick = 0,
}

local function buildCdInd()
    if cdInd.gui then return end
    local pg = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui",5)
    if not pg then return end
    local sg = Instance.new("ScreenGui")
    sg.Name="BH_CdInd"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=pg
    local frame = Instance.new("Frame")
    frame.Size=UDim2.new(0,160,0,28); frame.Position=UDim2.new(0.5,-80,1,-95)
    frame.BackgroundColor3=Color3.fromRGB(14,14,20); frame.BackgroundTransparency=0.2
    frame.BorderSizePixel=0; frame.Active=true; frame.Draggable=true; frame.Parent=sg
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,14)
    local dot = Instance.new("Frame")
    dot.Size=UDim2.new(0,14,0,14); dot.Position=UDim2.new(0,10,0.5,-7)
    dot.BackgroundColor3=Color3.fromRGB(255,50,50); dot.BorderSizePixel=0; dot.Parent=frame
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    local lbl = Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-32,1,0); lbl.Position=UDim2.new(0,30,0,0)
    lbl.BackgroundTransparency=1; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextColor3=Color3.fromRGB(255,160,160); lbl.TextSize=11
    lbl.Font=Enum.Font.GothamBold; lbl.Text="🗡️ Cooldown..."; lbl.Parent=frame
    cdInd.gui=sg; cdInd.dot=dot; cdInd.label=lbl
end

local function toggleCdIndicator(state)
    cdInd.enabled = state
    if not state then
        if cdInd.gui  then pcall(function() cdInd.gui:Destroy()   end); cdInd.gui=nil end
        if cdInd.conn then pcall(function() cdInd.conn:Disconnect() end); cdInd.conn=nil end
        return
    end
    buildCdInd()
    if cdInd.conn then pcall(function() cdInd.conn:Disconnect() end) end
    cdInd.conn = svc.Run.Heartbeat:Connect(function()
        if not cdInd.enabled or not cdInd.dot or not cdInd.dot.Parent then return end
        cdInd._tick = cdInd._tick + 1
        if cdInd._tick % 15 ~= 0 then return end  -- ~4 Hz at 60 fps
        pcall(function()
            -- Self-tracked timer only — the old isDaggerOnCooldown() UI-scrape
            -- guessed at label names Forsaken doesn't use, so it either always
            -- or never matched, making the indicator wrong regardless of the
            -- real cooldown state. os.clock() timing was always correct alone.
            local ready = os.clock() - tt.lastTrigger >= tt.cooldown
            cdInd.dot.BackgroundColor3 = ready
                and Color3.fromRGB(50,255,80) or Color3.fromRGB(255,50,50)
            if ready then
                cdInd.label.Text = "🗡️ READY"
                cdInd.label.TextColor3 = Color3.fromRGB(100,255,120)
            else
                local rem = math.max(0, tt.cooldown-(os.clock()-tt.lastTrigger))
                cdInd.label.Text = string.format("🗡️ %.0fs",rem)
                cdInd.label.TextColor3 = Color3.fromRGB(255,150,150)
            end
        end)
    end)
end

-- ── TwoTime Status HUD ────────────────────────────────────────
local statusHud = {
    enabled=false, gui=nil, rows={}, conn=nil, _tick=0,
}

local function buildStatusHud()
    if statusHud.gui then return end
    local pg = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui",5)
    if not pg then return end
    local sg = Instance.new("ScreenGui")
    sg.Name="BH_StatusHUD"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=pg
    local frame = Instance.new("Frame")
    frame.Size=UDim2.new(0,178,0,122); frame.Position=UDim2.new(1,-188,0.5,-61)
    frame.BackgroundColor3=Color3.fromRGB(12,12,18); frame.BackgroundTransparency=0.15
    frame.BorderSizePixel=1; frame.BorderColor3=Color3.fromRGB(180,40,60)
    frame.Active=true; frame.Draggable=true; frame.Parent=sg
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
    -- Header bar
    local hBar=Instance.new("Frame")
    hBar.Size=UDim2.new(1,0,0,24); hBar.BackgroundColor3=Color3.fromRGB(180,40,60)
    hBar.BackgroundTransparency=0.3; hBar.BorderSizePixel=0; hBar.Parent=frame
    Instance.new("UICorner",hBar).CornerRadius=UDim.new(0,8)
    local hTxt=Instance.new("TextLabel")
    hTxt.Size=UDim2.new(1,0,1,0); hTxt.BackgroundTransparency=1
    hTxt.Text="🗡️  TwoTime"; hTxt.TextColor3=Color3.fromRGB(255,220,230)
    hTxt.TextSize=11; hTxt.Font=Enum.Font.GothamBold; hTxt.Parent=hBar
    -- Rows
    statusHud.rows={}
    for i,name in ipairs({"Dagger","Behind","Range","LOS"}) do
        local rf=Instance.new("Frame")
        rf.Size=UDim2.new(1,-8,0,20); rf.Position=UDim2.new(0,4,0,20+(i-1)*22)
        rf.BackgroundTransparency=1; rf.Parent=frame
        local nl=Instance.new("TextLabel")
        nl.Size=UDim2.new(0,55,1,0); nl.BackgroundTransparency=1; nl.Text=name
        nl.TextColor3=Color3.fromRGB(175,175,195); nl.TextSize=10
        nl.Font=Enum.Font.GothamBold; nl.TextXAlignment=Enum.TextXAlignment.Left; nl.Parent=rf
        local dot=Instance.new("Frame")
        dot.Size=UDim2.new(0,10,0,10); dot.Position=UDim2.new(0,56,0.5,-5)
        dot.BackgroundColor3=Color3.fromRGB(255,50,50); dot.BorderSizePixel=0; dot.Parent=rf
        Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
        local vl=Instance.new("TextLabel")
        vl.Size=UDim2.new(1,-72,1,0); vl.Position=UDim2.new(0,72,0,0)
        vl.BackgroundTransparency=1; vl.Text="---"
        vl.TextColor3=Color3.fromRGB(255,100,100); vl.TextSize=10
        vl.Font=Enum.Font.GothamBold; vl.TextXAlignment=Enum.TextXAlignment.Left; vl.Parent=rf
        statusHud.rows[name]={dot=dot,val=vl}
    end
    statusHud.gui=sg
end

local function setRow(name,good,text)
    local r=statusHud.rows[name]; if not r then return end
    r.dot.BackgroundColor3 = good and Color3.fromRGB(50,255,80) or Color3.fromRGB(255,50,50)
    r.val.TextColor3 = good and Color3.fromRGB(100,255,120) or Color3.fromRGB(255,100,100)
    r.val.Text = text
end

local function toggleStatusHud(state)
    statusHud.enabled = state
    if not state then
        if statusHud.gui  then pcall(function() statusHud.gui:Destroy()   end)
            statusHud.gui=nil; statusHud.rows={} end
        if statusHud.conn then pcall(function() statusHud.conn:Disconnect() end); statusHud.conn=nil end
        return
    end
    buildStatusHud()
    if statusHud.conn then pcall(function() statusHud.conn:Disconnect() end) end
    statusHud.conn = svc.Run.Heartbeat:Connect(function()
        if not statusHud.enabled or not statusHud.gui or not statusHud.gui.Parent then return end
        statusHud._tick = statusHud._tick+1
        if statusHud._tick % 6 ~= 0 then return end  -- ~10 Hz
        pcall(function()
            -- Dagger row — self-tracked timer only (same fix as cdInd above)
            local rdy  = os.clock()-tt.lastTrigger >= tt.cooldown
            local rem  = math.max(0, tt.cooldown-(os.clock()-tt.lastTrigger))
            setRow("Dagger", rdy, rdy and "READY" or string.format("%.0fs",rem))
            -- Spatial rows
            local char = lp.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local kf   = getTeamFolder("Killers")
            if not hrp or not kf then
                setRow("Behind",false,"?"); setRow("Range",false,"?"); setRow("LOS",false,"?")
                return
            end
            local khrp,kd=nil,math.huge
            for _,killer in ipairs(kf:GetChildren()) do
                local r=killer:FindFirstChild("HumanoidRootPart")
                if r then local d=(r.Position-hrp.Position).Magnitude
                    if d<kd then kd=d; khrp=r end end
            end
            if not khrp then
                setRow("Behind",false,"NO KILLER"); setRow("Range",false,"---"); setRow("LOS",false,"---")
                return
            end
            local dist   = (khrp.Position-hrp.Position).Magnitude
            local behind = isPlayerBehindKiller(hrp,khrp,dist)
            local inRng  = dist <= tt.range
            local los    = hasLineOfSight(hrp.Position, khrp.Position, khrp.Parent)
            setRow("Behind", behind, behind and "YES ✓" or "FRONT")
            setRow("Range",  inRng,  string.format("%.1fm",dist))
            setRow("LOS",    los,    los and "CLEAR" or "BLOCKED")
        end)
    end)
end

-- ── Add HUD section to TwoTime tab (tab already created in section 5) ──
local secTwoTimeHUD = tabTwoTime:Section({Title="HUD & Feedback", Opened=true})
secTwoTimeHUD:Toggle({Title="Cooldown Ready Indicator", Default=false,
    Callback=function(v) toggleCdIndicator(v) end})
secTwoTimeHUD:Toggle({Title="Trigger Flash on Fire",    Default=false,
    Callback=function(v) tt.triggerFlash=v end})
secTwoTimeHUD:Toggle({Title="TwoTime Status HUD",       Default=false,
    Callback=function(v) toggleStatusHud(v) end})

-- ============================================================
-- 7. HELPER TAB (Noob auto-play system)
-- ============================================================
local tabHelper = win:Tab({Title="Helper", Icon="zap"})
local PathSvc   = game:GetService("PathfindingService")
local TweenSvc  = game:GetService("TweenService")

-- ── Stamina reader — tries 5 strategies, falls back to estimation ─
-- Assign to forward-declared upvalue
staminaEstimate = {
    value        = 100,
    lastTime     = os.clock(),
    exhaustStart = nil,
    lastSprint   = false,
}

local function readStamina()
    local char = lp.Character
    if not char then return staminaEstimate.value end
    -- 1. direct attribute
    local v = char:GetAttribute("Stamina") or char:GetAttribute("Stam")
    if type(v)=="number" then return v end
    -- 2. child ValueBase
    local sv = char:FindFirstChild("Stamina") or char:FindFirstChild("Stam")
    if sv and sv:IsA("NumberValue") then return sv.Value end
    -- 3. Stats folder
    local stats=char:FindFirstChild("Stats")
    if stats then local s2=stats:FindFirstChild("Stamina"); if s2 then return s2.Value end end
    -- 4. Humanoid attribute
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then local hv=hum:GetAttribute("Stamina"); if type(hv)=="number" then return hv end end
    -- 5. Estimate from sprint state + elapsed time
    local now = os.clock()
    local dt  = math.min(now - staminaEstimate.lastTime, 0.2)
    staminaEstimate.lastTime = now
    local isSprinting = hum and hum.WalkSpeed > 18
    if isSprinting then
        staminaEstimate.value = math.max(0, staminaEstimate.value - 10*dt)
        if staminaEstimate.value <= 0 and not staminaEstimate.exhaustStart then
            staminaEstimate.exhaustStart = now
        end
    else
        if staminaEstimate.value <= 0 and staminaEstimate.exhaustStart then
            if now - staminaEstimate.exhaustStart >= 2 then
                staminaEstimate.exhaustStart = nil
                staminaEstimate.value = math.min(100, staminaEstimate.value + 20*dt)
            end
        else
            staminaEstimate.value = math.min(100, staminaEstimate.value + 20*dt)
        end
    end
    return math.floor(staminaEstimate.value)
end

-- ── Sprint control with hysteresis (fixes 20-21 oscillation) ──
-- Dynamic floor: 20 emergency | 25 active chase | 30 normal
-- START: stamina > 55 — dead zone 30-55 holds current state
local SPRINT_START = 55
local _curSprint   = false

local function setSprint(shouldSprint)
    pcall(function()
        svc.VIM:SendKeyEvent(shouldSprint, Enum.KeyCode.LeftShift, false, game)
    end)
end

local function getDynamicFloor(killerDist)
    if killerDist < 15 then return 20     -- emergency: NEVER hit 0
    elseif killerDist < 40 then return 25 -- active chase
    else return 30 end                    -- normal/aware
end

local function managedSprint(stam, killerDist, force)
    -- ABSOLUTE GUARD: ≤2 stamina = stop sprint regardless of anything
    -- The 2s exhaust freeze at 0 is always worse than taking a hit
    if stam <= 2 then
        if _curSprint then _curSprint=false; setSprint(false) end
        return
    end
    local stop = getDynamicFloor(killerDist or math.huge)
    local newState
    if force ~= nil then
        newState = force
    elseif stam < stop then
        newState = false
    elseif stam > SPRINT_START then
        newState = true
    else
        newState = _curSprint  -- dead zone: hold, no toggling
    end
    if newState ~= _curSprint then
        _curSprint = newState
        setSprint(newState)
    end
end

-- ── Chat helper ───────────────────────────────────────────────
local function sendHelperChat(msg)
    pcall(function()
        local tcs = game:GetService("TextChatService")
        local ch  = tcs.TextChannels:FindFirstChild("RBXGeneral")
        if ch then ch:SendAsync(msg); return end
        -- Legacy fallback
        local rs2 = svc.RS:FindFirstChild("DefaultChatSystemChatEvents")
        if rs2 then
            local ev = rs2:FindFirstChild("SayMessageRequest")
            if ev then ev:FireServer(msg,"All") end
        end
    end)
end

-- ── Sentinel finder ───────────────────────────────────────────
-- Priority: Builderman (dispenser heals) > Dusekkar (shield) > Shedletsky (force field)
local SENTINEL_PRIORITY = {Builderman=3, Dusekkar=2, Shedletsky=1}

local function findBestSentinel(hrp)
    local sf = getTeamFolder("Survivors")
    if not sf then return nil, math.huge end
    local best, bestScore, bestDist = nil, -1, math.huge
    for _,model in ipairs(sf:GetChildren()) do
        if model ~= lp.Character and model:IsA("Model") then
            local r = model:FindFirstChild("HumanoidRootPart")
            local h = model:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then
                local d = (r.Position - hrp.Position).Magnitude
                for sentName, prio in pairs(SENTINEL_PRIORITY) do
                    if model.Name:lower():find(sentName:lower()) then
                        -- prefer higher priority, tiebreak by distance
                        local score = prio * 1000 - d
                        if score > bestScore then
                            bestScore=score; best=r.Position; bestDist=d
                        end
                        break
                    end
                end
            end
        end
    end
    return best, bestDist
end

-- ── Noob ability firers ───────────────────────────────────────
local function fireNoobAbility(names, btnKeywords)
    local re = getRemoteEvent()
    if re then
        for _,n in ipairs(names) do
            pcall(function() re:FireServer("UseActorAbility",{[1]=buffer.fromstring(n)}) end)
        end
    end
    local pg=lp:FindFirstChildOfClass("PlayerGui")
    local mainUI=pg and pg:FindFirstChild("MainUI")
    local container=mainUI and mainUI:FindFirstChild("AbilityContainer")
    if container then
        for _,btn in ipairs(container:GetChildren()) do
            local ln=btn.Name:lower()
            for _,kw in ipairs(btnKeywords) do
                if ln:find(kw) then
                    pcall(function() if btn.Activate then btn:Activate() end end)
                    pcall(function()
                        if type(getconnections)=="function" and btn.MouseButton1Click then
                            for _,c in ipairs(getconnections(btn.MouseButton1Click)) do
                                if c.Function then pcall(c.Function) end
                            end
                        end
                    end)
                    break
                end
            end
        end
    end
end

local function fireGhostburger()
    fireNoobAbility({"\3\5\0\0\0Ghost","\3\6\0\0\0Ghostburger"},{"ghost","invis","burger"})
end
local function fireBloxyCola()
    fireNoobAbility({"\3\4\0\0\0Cola","\3\5\0\0\0BloxyCola"},{"cola","bloxy","speed"})
end
local function fireSlateskin()
    fireNoobAbility({"\3\6\0\0\0Slate","\3\7\0\0\0Slateskin"},{"slate","potion","tank","stone"})
end

-- ── Killer stamina estimator ──────────────────────────────────
-- Tracks killer velocity each tick, applies known drain/regen
-- rates to estimate remaining stamina. Accurate within ±8 units.
local function makeKillerStamEst()
    return {value=110, lastPos=nil, lastTime=os.clock(), isSprinting=false}
end

local function updateKillerStam(est, killerHRP)
    if not killerHRP then return est.value end
    local now = os.clock()
    local dt  = math.min(now - est.lastTime, 0.2)
    est.lastTime = now

    if est.lastPos and dt > 0.001 then
        local vel = (killerHRP.Position - est.lastPos).Magnitude / dt

        -- Rolling average of last 6 samples to smooth out hit-animation freezes,
        -- network jitter, and momentary stops (killer winding up to hit)
        est.velHistory = est.velHistory or {}
        table.insert(est.velHistory, vel)
        if #est.velHistory > 6 then table.remove(est.velHistory, 1) end
        local avgVel = 0
        for _, v in ipairs(est.velHistory) do avgVel = avgVel + v end
        avgVel = avgVel / #est.velHistory

        -- Hysteresis on sprint detection (same fix as player stamina floor):
        -- Confirm sprint at > 18 studs/sec, confirm walk at < 12, hold in dead zone
        local wasSprinting = est.isSprinting
        if avgVel > 18 then
            est.isSprinting = true
        elseif avgVel < 12 then
            est.isSprinting = false
            -- Track when killer transitions from sprint → walk
            -- This is the window Noob should exploit to create distance
            if wasSprinting then
                est.stoppedSprintAt = now
            end
        end
        -- else: hold current state in dead zone (12-18 studs/sec ambiguous zone)
    end

    est.lastPos = killerHRP.Position

    if est.isSprinting then
        est.value = math.max(0,   est.value - 9.5 * dt)
    else
        est.value = math.min(110, est.value + 21  * dt)
    end
    return est.value
end

-- Returns true if the killer recently stopped sprinting (within last 2.5s)
-- This is the ideal window to sprint hard and create distance
local function killerJustStoppedSprinting(est)
    return est.stoppedSprintAt ~= nil
        and (os.clock() - est.stoppedSprintAt) < 2.5
end

-- ── Loop spot scoring ─────────────────────────────────────────
-- Scans for Model objects and calculates each model's FULL bounding
-- box across all its solid BaseParts. A jungle gym made of 30 beams
-- now scores as one 16×16 structure instead of 30 2×2 failures.
local loopCache = {spots={}, lastUpdate=-30, interval=3}

-- Full AABB of all solid collidable parts inside a model
local function getModelBB(model)
    local INF = math.huge
    local minX,minY,minZ =  INF, INF, INF
    local maxX,maxY,maxZ = -INF,-INF,-INF
    local count = 0
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") and p.Transparency < 0.9 and p.CanCollide then
            local hs  = p.Size * 0.5
            local pos = p.Position
            if pos.X-hs.X < minX then minX=pos.X-hs.X end
            if pos.Y-hs.Y < minY then minY=pos.Y-hs.Y end
            if pos.Z-hs.Z < minZ then minZ=pos.Z-hs.Z end
            if pos.X+hs.X > maxX then maxX=pos.X+hs.X end
            if pos.Y+hs.Y > maxY then maxY=pos.Y+hs.Y end
            if pos.Z+hs.Z > maxZ then maxZ=pos.Z+hs.Z end
            count = count + 1
        end
    end
    if count == 0 then return nil end
    return {
        size   = Vector3.new(maxX-minX, maxY-minY, maxZ-minZ),
        center = Vector3.new((minX+maxX)*0.5, (minY+maxY)*0.5, (minZ+maxZ)*0.5),
        count  = count,
    }
end

-- BasePart in the model closest to bb.center (used for BillboardGui anchoring)
local function findCenterPart(model, center)
    local best, bestDist = nil, math.huge
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            local d=(p.Position-center).Magnitude
            if d<bestDist then bestDist=d; best=p end
        end
    end
    return best
end

-- ── Loop spot scoring with structure clustering ──────────────
-- Old version scored one Model at a time — a wall standing 8 studs from
-- a jungle gym never merged with it, so both got scored (and often
-- rejected) individually even though together they form one real loop.
-- New version: collect every candidate structure loosely, then MERGE
-- any two whose bounding boxes are within `mergeGap` studs of each
-- other into a single compound group before applying the size filter.
-- This is what lets "wall right next to the gym" register as one loop.
local function scoreLoopSpots(hrp, maxCount, killerHRP)
    local mapRoot = svc.WS:FindFirstChild("Map")
    if not mapRoot then return {} end
    local minSize = (helper and helper.minLoopSize) or 14

    -- Step 1: collect loose candidates (basic solid-structure heuristic only)
    local candidates = {}
    local function collect(folder, depth)
        if depth > 6 then return end
        for _,child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") then
                local bb = getModelBB(child)
                if bb and bb.count >= 2 and bb.size.Y > 4 and bb.size.Y < 50 then
                    local d = (bb.center - hrp.Position).Magnitude
                    if d <= 160 then
                        table.insert(candidates, {model=child, bb=bb})
                    end
                end
                collect(child, depth+1)
            elseif child:IsA("Folder") then
                collect(child, depth+1)
            end
        end
    end
    collect(mapRoot, 0)
    if #candidates == 0 then return {} end

    -- Step 2: cluster candidates whose AABBs are within mergeGap studs
    -- (X/Z plane gap between box edges — 0 if already overlapping)
    local mergeGap = 14
    local function aabbGap(a, b)
        local aMinX,aMaxX = a.center.X-a.size.X*0.5, a.center.X+a.size.X*0.5
        local aMinZ,aMaxZ = a.center.Z-a.size.Z*0.5, a.center.Z+a.size.Z*0.5
        local bMinX,bMaxX = b.center.X-b.size.X*0.5, b.center.X+b.size.X*0.5
        local bMinZ,bMaxZ = b.center.Z-b.size.Z*0.5, b.center.Z+b.size.Z*0.5
        local gapX = math.max(0, math.max(aMinX-bMaxX, bMinX-aMaxX))
        local gapZ = math.max(0, math.max(aMinZ-bMaxZ, bMinZ-aMaxZ))
        return math.sqrt(gapX*gapX + gapZ*gapZ)
    end

    local groups = {}
    for _,c in ipairs(candidates) do
        table.insert(groups, {members={c.model}, bb={size=c.bb.size, center=c.bb.center}, count=c.bb.count})
    end

    local mergedAny = true
    while mergedAny do
        mergedAny = false
        for i=#groups,1,-1 do
            for j=i-1,1,-1 do
                if aabbGap(groups[i].bb, groups[j].bb) <= mergeGap then
                    local gi, gj = groups[i].bb, groups[j].bb
                    local minX = math.min(gi.center.X-gi.size.X*0.5, gj.center.X-gj.size.X*0.5)
                    local maxX = math.max(gi.center.X+gi.size.X*0.5, gj.center.X+gj.size.X*0.5)
                    local minZ = math.min(gi.center.Z-gi.size.Z*0.5, gj.center.Z-gj.size.Z*0.5)
                    local maxZ = math.max(gi.center.Z+gi.size.Z*0.5, gj.center.Z+gj.size.Z*0.5)
                    local minY = math.min(gi.center.Y-gi.size.Y*0.5, gj.center.Y-gj.size.Y*0.5)
                    local maxY = math.max(gi.center.Y+gi.size.Y*0.5, gj.center.Y+gj.size.Y*0.5)
                    for _,m in ipairs(groups[j].members) do table.insert(groups[i].members, m) end
                    groups[i].bb = {
                        size   = Vector3.new(maxX-minX, maxY-minY, maxZ-minZ),
                        center = Vector3.new((minX+maxX)*0.5, (minY+maxY)*0.5, (minZ+maxZ)*0.5),
                    }
                    groups[i].count = groups[i].count + groups[j].count
                    table.remove(groups, j)
                    mergedAny = true
                    break
                end
            end
            if mergedAny then break end
        end
    end

    -- Step 3: filter merged groups by final size, score with a size-bias
    -- so genuinely bigger compound loops rank above small isolated ones
    local results = {}
    for _,g in ipairs(groups) do
        local sx,sz = g.bb.size.X, g.bb.size.Z
        if sx > minSize and sz > minSize then
            local d = (g.bb.center - hrp.Position).Magnitude
            if d <= 150 then
                local kPenalty = 1
                if killerHRP then
                    local kd=(g.bb.center-killerHRP.Position).Magnitude
                    if kd < 10 then kPenalty = 0.2 end
                end
                local perimeter = 2*(sx+sz)
                local density   = math.min(g.count/6, 2.0)
                -- Size bias: (perimeter/40)^1.4 rewards bigger structures
                -- more than proportionally, so a 60-stud compound loop beats
                -- two disconnected 20-stud ones at similar distance
                local sizeBias  = (perimeter/40) ^ 1.4
                -- Anchor = largest single member (used for billboard + orbit identity)
                local primary, bestVol = g.members[1], 0
                for _,m in ipairs(g.members) do
                    local mb = getModelBB(m)
                    if mb then
                        local vol = mb.size.X*mb.size.Z
                        if vol > bestVol then bestVol=vol; primary=m end
                    end
                end
                table.insert(results, {
                    model    = primary,     -- anchor model for billboard + identity
                    members  = g.members,   -- ALL models in this compound loop (for ESP)
                    center   = g.bb.center,
                    bb       = g.bb,
                    groupKey = string.format("%.0f_%.0f_%.0f", g.bb.center.X, g.bb.center.Y, g.bb.center.Z),
                    score    = perimeter * density * sizeBias * (1/math.max(d,1)) * kPenalty,
                    dist     = d,
                    size     = sx+sz,
                })
            end
        end
    end

    table.sort(results, function(a,b) return a.score > b.score end)

    -- Extra dedup safety in case two groups still ended up close post-merge
    local top, seen = {}, {}
    for _,r in ipairs(results) do
        local dup = false
        for _,s in ipairs(seen) do
            if (r.center-s).Magnitude < 10 then dup=true; break end
        end
        if not dup then
            table.insert(top, r); table.insert(seen, r.center)
            if #top >= maxCount then break end
        end
    end
    return top
end

local function refreshLoopCache(hrp, killerHRP)
    local now = os.clock()
    if now - loopCache.lastUpdate < loopCache.interval then return loopCache.spots end
    loopCache.lastUpdate = now
    loopCache.spots = scoreLoopSpots(hrp, 5, killerHRP)
    return loopCache.spots
end

-- ── Loop ESP marks ────────────────────────────────────────────
local LOOP_COLORS = {
    Color3.fromRGB(255,215,0),
    Color3.fromRGB(160,255,100),
    Color3.fromRGB(100,210,255),
}

local function clearLoopMarks()
    if not helper then return end
    for _,mark in ipairs(helper.loopMarks) do
        if mark.hls then
            for _,hl in ipairs(mark.hls) do
                pcall(function() if hl and hl.Parent then hl:Destroy() end end)
            end
        end
        pcall(function() if mark.bb and mark.bb.Parent then mark.bb:Destroy() end end)
    end
    helper.loopMarks = {}
end

local function refreshLoopESP()
    clearLoopMarks()
    local char=lp.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local kf=getTeamFolder("Killers"); local khrp=nil
    if kf then for _,k in ipairs(kf:GetChildren()) do
        local r=k:FindFirstChild("HumanoidRootPart"); if r then khrp=r; break end
    end end
    local spots=scoreLoopSpots(hrp,3,khrp)
    for i,spot in ipairs(spots) do
        local color=LOOP_COLORS[i] or LOOP_COLORS[3]
        local folder=svc.WS:FindFirstChild("BH_LoopMarks")
            or (function() local f=Instance.new("Folder"); f.Name="BH_LoopMarks"; f.Parent=svc.WS; return f end)()
        -- Highlight EVERY member model of the compound loop (wall + gym together)
        local hls = {}
        for _,member in ipairs(spot.members or {spot.model}) do
            local hl=Instance.new("Highlight")
            hl.Adornee=member; hl.FillColor=color; hl.FillTransparency=0.72
            hl.OutlineColor=color; hl.OutlineTransparency=0
            hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=folder
            table.insert(hls, hl)
        end
        -- BillboardGui anchored to the part closest to the merged bounding box center
        local anchorPart = findCenterPart(spot.model, spot.center)
        local bbGui = nil
        if anchorPart then
            bbGui=Instance.new("BillboardGui")
            bbGui.Adornee=anchorPart; bbGui.Size=UDim2.new(0,150,0,22)
            bbGui.StudsOffset=Vector3.new(0, spot.bb.size.Y*0.5+3, 0)
            bbGui.AlwaysOnTop=true; bbGui.Parent=folder
            local lbl=Instance.new("TextLabel")
            lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
            lbl.Text=string.format("🔄 LOOP #%d  %.0fst (%dpc)  %.0fm",i,spot.size,#spot.members,spot.dist)
            lbl.TextColor3=color; lbl.TextStrokeColor3=Color3.new(0,0,0)
            lbl.TextStrokeTransparency=0; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11; lbl.Parent=bbGui
        end
        table.insert(helper.loopMarks, {hls=hls, bb=bbGui})
    end
end

-- ── Orbit position (angle rate-limited) ──────────────────────
-- When the killer turns, the raw orbit target jumps to the opposite
-- side of the structure — character cuts straight through the building.
-- Fix: track orbit angle per-structure and clamp change to ≤60°/sec.
-- The player now follows the perimeter naturally, never through walls.
local function getSmoothedOrbitPos(hrp, spot, killerHRP)
    local center = spot.center
    local margin = 3.5
    local rx = spot.bb.size.X*0.5 + margin
    local rz = spot.bb.size.Z*0.5 + margin

    -- Target angle: directly opposite the killer around the structure center
    local killerDir = killerHRP
        and (killerHRP.Position - center).Unit or Vector3.new(1,0,0)
    local targetAngle = math.atan2(-killerDir.Z, -killerDir.X)

    -- Reset angle if we switched to a different loop structure
    -- (groupKey is stable across refreshes; spot.model can change if a
    -- different member becomes "primary" after re-scoring the same group)
    local now = os.clock()
    if helper.lastOrbitModel ~= spot.groupKey then
        helper.lastOrbitModel = spot.groupKey
        helper.orbitAngle     = targetAngle  -- snap on structure change
        helper.orbitTime      = now
    end

    -- Rate-limit: max 60° per second (π/3 rad/s)
    local dt = math.min(now - (helper.orbitTime or now), 0.5)
    helper.orbitTime = now
    local maxStep = (math.pi/3) * dt

    -- Normalize angular difference to [-π, π] for shortest path
    local diff = targetAngle - helper.orbitAngle
    diff = diff - math.floor((diff + math.pi) / (2*math.pi)) * (2*math.pi)

    helper.orbitAngle = helper.orbitAngle
        + math.max(-maxStep, math.min(maxStep, diff))

    -- Project onto structure ellipse
    local orbitPos = center + Vector3.new(
        math.cos(helper.orbitAngle) * rx,
        0,
        math.sin(helper.orbitAngle) * rz
    )
    return Vector3.new(orbitPos.X, hrp.Position.Y, orbitPos.Z)
end

-- ── Path navigation (fixed timeout memory leak) ───────────────
local function waitMoveFinished(hum, timeoutSec)
    local done = false
    local conn = hum.MoveToFinished:Connect(function() done=true end)
    local elapsed = 0
    while not done and elapsed < timeoutSec do
        -- Check abort EVERY poll (not just between waypoints) so a state
        -- change can reclaim movement authority within ~0.05s instead of
        -- waiting out the full 2.5s waypoint timeout
        if helper and helper.abortNav then break end
        elapsed = elapsed + task.wait(0.05)
    end
    pcall(function() conn:Disconnect() end)
end

local function navigateTo(hrp, hum, target)
    if not target then return end
    if helper and helper.isNavigating then return end  -- no stacking
    if helper then helper.isNavigating=true; helper.abortNav=false end
    pcall(function()
        local path = PathSvc:CreatePath({
            AgentRadius=2.5, AgentHeight=5.5,
            AgentCanJump=true, AgentMaxSlope=45,
            WaypointSpacing=4,
        })
        path:ComputeAsync(hrp.Position, target)
        if path.Status ~= Enum.PathStatus.Success then
            hum:MoveTo(target)
        else
            for _,wp in ipairs(path:GetWaypoints()) do
                -- Abort if disabled OR killer closed in during travel
                if not helper or not helper.autoPlay or helper.abortNav then break end
                if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump=true end
                hum:MoveTo(wp.Position)
                waitMoveFinished(hum, 2.5)
            end
        end
    end)
    if helper then helper.isNavigating=false; helper.abortNav=false end
end

-- ── Killer approach + targeting confirmation ─────────────────
-- Old version used ONE raw velocity sample per call — a killer merely
-- running past while chasing someone else could produce a single noisy
-- spike that looked identical to "coming for you," triggering LOOP
-- state and ability gating for no reason.
-- New version: averages the last 5 approach-velocity samples AND
-- separately confirms the raw distance is actually net-decreasing over
-- that same window. Both must agree before we call it a real chase.
local function updateKillerApproach(hrp, khrp)
    if not khrp or not helper then return 0, false end
    local now = os.clock()
    local dt  = math.min(now - (helper.killerPrevTime or now), 0.3)
    helper.killerPrevTime = now

    local rawVel = 0
    if helper.killerPrevPos and dt > 0.01 then
        local toPlayer    = (hrp.Position - khrp.Position).Unit
        local killerDelta = khrp.Position - helper.killerPrevPos
        rawVel = killerDelta:Dot(toPlayer) / dt
    end
    helper.killerPrevPos = khrp.Position

    helper.approachHistory = helper.approachHistory or {}
    table.insert(helper.approachHistory, rawVel)
    if #helper.approachHistory > 5 then table.remove(helper.approachHistory, 1) end
    local avgVel = 0
    for _,v in ipairs(helper.approachHistory) do avgVel = avgVel + v end
    avgVel = avgVel / #helper.approachHistory

    helper.distHistory = helper.distHistory or {}
    table.insert(helper.distHistory, (hrp.Position-khrp.Position).Magnitude)
    if #helper.distHistory > 5 then table.remove(helper.distHistory, 1) end
    local netClosing = #helper.distHistory >= 3
        and (helper.distHistory[1] - helper.distHistory[#helper.distHistory]) > 3

    helper.killerApprVel = avgVel
    -- Confirmed targeting requires BOTH sustained approach velocity AND
    -- genuinely shrinking distance over the sample window, plus enough
    -- samples to trust the average (kills spawn-frame false positives too)
    local isTargetingMe = avgVel > 5 and netClosing and #helper.approachHistory >= 3
    return avgVel, isTargetingMe
end

-- ── Hit tracker setup ─────────────────────────────────────────
-- Monitors HealthChanged to count hits taken in the current encounter.
-- Used by take-hit regen logic (let killer hit up to 2 times to regen stam).
local function setupHitTracker(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or not helper then return end
    helper.lastKnownHP = hum.Health
    hum.HealthChanged:Connect(function(newHP)
        if not helper then return end
        local old = helper.lastKnownHP or newHP
        -- >5 HP lost = real hit (not ability self-damage noise)
        if newHP < old - 5 then
            helper.hitsTaken  = math.min((helper.hitsTaken or 0)+1, 5)
            helper.lastHitTime = os.clock()
        end
        helper.lastKnownHP = newHP
    end)
end

-- ── Helper state (assigned to forward-declared upvalue) ───────
helper = {
    autoStam   = false, showLoops = false,
    autoLoop   = false, autoPlay  = false,
    stamConn   = nil,   loopEspConn=nil,
    loopConn   = nil,   playConn  = nil,
    loopMarks  = {},    minLoopSize=14,
    playState  = "IDLE",
    -- Noob ability cooldowns
    lastGhost  = -45, lastCola=-12, lastSlate=-55, lastChat=-30,
    -- Tick counters
    _loopFrame = 0, _loopTick=0, _playTick=0,
    -- Killer stamina estimator
    killerStamEst = makeKillerStamEst(),
    -- Hit-regen tracking (take max 2 hits to regen stamina, NEVER exhaust at 0)
    hitsTaken    = 0,
    maxHitsRegen = 2,
    lastHitTime  = 0,
    lastKnownHP  = 100,
    -- Navigation guard (prevents simultaneous navigateTo calls stacking)
    isNavigating    = false,
    abortNav        = false,
    currentGenTarget= nil,   -- generator model we're currently heading toward
    -- Killer approach velocity (studs/sec toward player; positive = approaching)
    killerPrevPos   = nil,
    killerPrevTime  = os.clock(),
    killerApprVel   = 0,
    approachHistory = {},
    distHistory     = {},
    -- Grace period after enabling Auto Play / respawning — abilities and
    -- LMS/lost-sight detection are suppressed until data has stabilized
    -- (fixes ability spam firing on bogus spawn-frame readings)
    playStartTime  = nil,
    -- Smooth orbit tracking (prevents cutting through structures when killer turns)
    orbitAngle     = 0,
    orbitTime      = os.clock(),
    lastOrbitModel = nil,
}

-- ── Auto Stamina Management ───────────────────────────────────
local function toggleAutoStam(state)
    helper.autoStam = state
    if helper.stamConn then pcall(function() helper.stamConn:Disconnect() end); helper.stamConn=nil end
    if not state then managedSprint(100, math.huge, false); return end
    helper.stamConn = svc.Run.Heartbeat:Connect(function()
        if not helper.autoStam then return end
        pcall(function()
            local char=lp.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health<=0 then return end
            local kf=getTeamFolder("Killers")
            local kDist,khrp=math.huge,nil
            if kf then for _,killer in ipairs(kf:GetChildren()) do
                local r=killer:FindFirstChild("HumanoidRootPart"); if r then
                    local d=(r.Position-hrp.Position).Magnitude
                    if d<kDist then kDist=d; khrp=r end
                end
            end end
            local stam=readStamina()
            local killerStam = khrp and updateKillerStam(helper.killerStamEst, khrp) or 110
            local killerAdvantage = killerStam > stam + 15
            -- Killer just stopped sprinting → sprint hard while their stam regens
            -- This is the best window to create distance
            if khrp and killerJustStoppedSprinting(helper.killerStamEst) and kDist < 65 then
                managedSprint(stam, kDist, stam > 20)
                return
            end
            if killerAdvantage and kDist < 55 then
                managedSprint(stam, kDist)
                return
            end
            if kDist < 20 then
                -- Emergency: sprint if above hard floor, NEVER hit 0
                managedSprint(stam, kDist, stam > 20)
            elseif kDist < 40 then
                managedSprint(stam, kDist)   -- active chase: hysteresis
            elseif kDist < 65 then
                if stam>60 then managedSprint(stam,kDist,true)
                elseif stam<40 then managedSprint(stam,kDist,false)
                else managedSprint(stam,kDist) end
            else
                managedSprint(stam, kDist, false)  -- safe: walk + regen
            end
        end)
    end)
end

-- ── Show Best Loop Spots ──────────────────────────────────────
local function toggleShowLoops(state)
    helper.showLoops = state
    if not state then
        clearLoopMarks()
        if helper.loopEspConn then pcall(function() helper.loopEspConn:Disconnect() end); helper.loopEspConn=nil end
        local folder=svc.WS:FindFirstChild("BH_LoopMarks")
        if folder then pcall(function() folder:Destroy() end) end
        return
    end
    refreshLoopESP()
    if helper.loopEspConn then pcall(function() helper.loopEspConn:Disconnect() end) end
    helper.loopEspConn = svc.Run.Heartbeat:Connect(function()
        helper._loopFrame = helper._loopFrame+1
        if helper._loopFrame % 120 ~= 0 then return end  -- refresh every ~2s
        pcall(refreshLoopESP)
    end)
end

-- ── Auto Loop ─────────────────────────────────────────────────
local function toggleAutoLoop(state)
    helper.autoLoop = state
    if helper.loopConn then pcall(function() helper.loopConn:Disconnect() end); helper.loopConn=nil end
    if not state then return end
    helper.loopConn = svc.Run.Heartbeat:Connect(function()
        if not helper.autoLoop then return end
        helper._loopTick = helper._loopTick+1
        if helper._loopTick % 6 ~= 0 then return end  -- ~10 Hz
        pcall(function()
            local char=lp.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health<=0 then return end
            local kf=getTeamFolder("Killers"); local khrp=nil; local kDist=math.huge
            if kf then for _,k in ipairs(kf:GetChildren()) do
                local r=k:FindFirstChild("HumanoidRootPart"); if r then
                    local d=(r.Position-hrp.Position).Magnitude
                    if d<kDist then kDist=d; khrp=r end
                end
            end end
            if kDist > 55 then return end  -- only orbit during active chase
            local spots=refreshLoopCache(hrp,khrp)
            if #spots==0 then return end
            hum:MoveTo(getSmoothedOrbitPos(hrp, spots[1], khrp))
        end)
    end)
end

-- ── Auto Play — full Noob state machine ──────────────────────
local function getKillerInfo(hrp)
    local kf=getTeamFolder("Killers"); local kDist,khrp=math.huge,nil
    if kf then for _,k in ipairs(kf:GetChildren()) do
        local r=k:FindFirstChild("HumanoidRootPart"); if r then
            local d=(r.Position-hrp.Position).Magnitude
            if d<kDist then kDist=d; khrp=r end
        end
    end end
    return kDist, khrp
end

-- ── Generator completion detection ───────────────────────────
-- Checks every known signal Forsaken uses to mark a generator done:
-- attributes (Completed/Solved/Won/Active=false/Status), child BoolValues
local function isGenCompleted(item)
    -- Attribute checks
    if item:GetAttribute("Completed") == true  then return true end
    if item:GetAttribute("Solved")    == true  then return true end
    if item:GetAttribute("Won")       == true  then return true end
    if item:GetAttribute("Active")    == false then return true end
    local status = item:GetAttribute("Status")
    if status == "Complete" or status == "Done" or status == "Finished" then return true end
    -- Child BoolValue/StringValue checks
    local function checkDescOf(obj)
        for _, child in ipairs(obj:GetChildren()) do
            local ln = child.Name:lower()
            if child:IsA("BoolValue") then
                if (ln=="completed" or ln=="solved" or ln=="won" or ln=="done") and child.Value then return true end
                if ln=="active" and not child.Value then return true end
            end
            if child:IsA("StringValue") then
                if ln=="status" and (child.Value=="Complete" or child.Value=="Done") then return true end
            end
        end
        return false
    end
    if checkDescOf(item) then return true end
    if item:IsA("Model") then
        for _, child in ipairs(item:GetChildren()) do
            if checkDescOf(child) then return true end
        end
    end
    return false
end

-- Returns {pos, model} of nearest INCOMPLETE generator, or nil if all done
local function getNearestIncompleteGen(hrp)
    local map=svc.WS:FindFirstChild("Map"); if not map then return nil end
    local best, bestDist, bestModel = nil, math.huge, nil
    for _,item in ipairs(map:GetDescendants()) do
        if item.Name=="Generator" or item.Name=="FlowGame" then
            -- Skip already-completed generators
            if not isGenCompleted(item) then
                local pos = item:IsA("BasePart") and item.Position
                    or (item:IsA("Model") and item.PrimaryPart and item.PrimaryPart.Position)
                    or (item:IsA("Model") and item:FindFirstChildOfClass("BasePart")
                        and item:FindFirstChildOfClass("BasePart").Position)
                if pos then
                    local d=(pos-hrp.Position).Magnitude
                    if d<bestDist then bestDist=d; best=pos; bestModel=item end
                end
            end
        end
    end
    return best and {pos=best, model=bestModel} or nil
end

-- ── ProximityPrompt trigger ───────────────────────────────────
-- Fires the ProximityPrompt on a generator to start the FlowGame.
-- Tries executor fireproximityprompt first, falls back to Roblox service.
local function fireProximityPrompt(item)
    if not item or not item.Parent then return end
    local prompt
    for _,desc in ipairs(item:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then prompt=desc; break end
    end
    if not prompt then
        -- Some generators have the prompt on a sibling part
        local parent = item.Parent
        if parent then
            for _,sib in ipairs(parent:GetDescendants()) do
                if sib:IsA("ProximityPrompt") then prompt=sib; break end
            end
        end
    end
    if not prompt then return end
    -- executor function (most executors support this)
    pcall(function() fireproximityprompt(prompt) end)
    -- standard Roblox fallback
    pcall(function() prompt:InputHoldBegin() end)
    pcall(function()
        game:GetService("ProximityPromptService"):PromptButtonHoldBegin(prompt)
    end)
end

local function toggleAutoPlay(state)
    helper.autoPlay = state
    if helper.playConn then pcall(function() helper.playConn:Disconnect() end); helper.playConn=nil end
    if not state then
        managedSprint(100, math.huge, false)
        helper.isNavigating=false; helper.abortNav=false
        helper.playStartTime = nil
        return
    end
    helper.lastGhost = os.clock()-45
    helper.lastCola  = os.clock()-12
    helper.lastSlate = os.clock()-55
    helper.hitsTaken = 0
    -- Grace period: abilities + LMS/lost-sight checks are suppressed for
    -- 6s after enabling. Without this, enabling right at round start
    -- reads killer distance as "far" and approach history as empty/zero,
    -- which looked exactly like "killer lost sight" → instant ability spam.
    helper.playStartTime  = os.clock()
    helper.approachHistory = {}
    helper.distHistory     = {}
    -- Setup hit tracker for the current character
    task.spawn(function()
        local char = lp.Character
        if char then setupHitTracker(char) end
    end)

    helper.playConn = svc.Run.Heartbeat:Connect(function()
        if not helper.autoPlay then return end
        helper._playTick = helper._playTick+1
        if helper._playTick % 12 ~= 0 then return end  -- ~5 Hz
        task.spawn(function()
            pcall(function()
                local char=lp.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
                local hum=char and char:FindFirstChildOfClass("Humanoid")
                if not char or not hrp or not hum or hum.Health<=0 then return end
                local now        = os.clock()
                local kDist,khrp = getKillerInfo(hrp)
                local stam       = readStamina()
                local killerStam = khrp and updateKillerStam(helper.killerStamEst,khrp) or 110
                local myHP       = hum.Health

                -- ── Hit counter reset (encounter ended when killer > 40 studs) ──
                if kDist > 40 and helper.hitsTaken > 0
                   and now - helper.lastHitTime > 8 then
                    helper.hitsTaken = 0
                end

                -- ── Grace period ────────────────────────────────────────────
                -- First 6s after enabling / respawning: skip abilities and
                -- targeting-sensitive logic entirely while data stabilizes
                local inGrace = helper.playStartTime
                    and (now - helper.playStartTime) < 6

                -- ── Killer approach + confirmed targeting ────────────────────
                local approachVel, isTargetingMe = updateKillerApproach(hrp, khrp)
                if inGrace then isTargetingMe = false end
                local earlyWarning = khrp and kDist < 90 and isTargetingMe

                -- ── NOOB ABILITY AUTOMATION (suppressed during grace) ────────
                local killerSpr = helper.killerStamEst.isSprinting

                local function isLastManStanding()
                    local sf = getTeamFolder("Survivors"); if not sf then return false end
                    local alive = 0
                    for _, m in ipairs(sf:GetChildren()) do
                        local h = m:FindFirstChildOfClass("Humanoid")
                        if h and h.Health > 0 then alive = alive + 1 end
                    end
                    return alive <= 1
                end

                if not inGrace then
                    -- BLOXY COLA: killer has stamina advantage AND real distance to cover
                    local killerAdvCola = killerStam > stam + 20
                    local spotsForCola = refreshLoopCache(hrp, khrp)
                    local spotDist = #spotsForCola > 0
                        and (spotsForCola[1].center - hrp.Position).Magnitude or nil
                    local distanceLong = kDist > 45 or (spotDist and spotDist > 30)
                    local colaMin = killerSpr and 35 or 25
                    if killerAdvCola and distanceLong and stam < 70
                       and kDist > colaMin and now-helper.lastCola >= 12 then
                        helper.lastCola=now; task.spawn(fireBloxyCola)
                    end

                    -- SLATESKIN: low STAMINA + safe distance; sprint on natural Speed II expiry
                    local slateMin = killerSpr and 42 or 30
                    if stam < 35 and kDist > slateMin and now-helper.lastSlate >= 55 then
                        helper.lastSlate = now
                        helper.slateskinEndTime = now + 10
                        task.spawn(fireSlateskin)
                    end
                    if helper.slateskinEndTime and now >= helper.slateskinEndTime then
                        helper.slateskinEndTime = nil
                        managedSprint(stam, kDist, stam > 20)
                    end

                    -- GHOSTBURGER: killer CONFIRMED lost sight (not just far), or pre-LMS
                    -- Requires enough approach samples so this can't fire on spawn-frame data
                    local killerLostSight = khrp and #helper.approachHistory >= 3
                        and approachVel < 2 and kDist > 60
                    local nearLMS = isLastManStanding()
                    local ghostMin = killerSpr and 40 or 25
                    if (killerLostSight or nearLMS) and kDist > ghostMin
                       and now-helper.lastGhost >= 45 then
                        helper.lastGhost=now; task.spawn(fireGhostburger)
                    end
                end

                -- ── TAKE-HIT REGEN + KILLER WINDOW STRATEGY ──────────────────
                if khrp and killerJustStoppedSprinting(helper.killerStamEst) and kDist < 65 then
                    managedSprint(stam, kDist, stam > 20)
                elseif kDist < 20 and stam <= 25 then
                    if helper.hitsTaken < helper.maxHitsRegen then
                        managedSprint(stam, kDist, false)
                        return
                    else
                        managedSprint(stam, kDist, stam > 20)
                    end
                else
                    if kDist < 20 then
                        managedSprint(stam, kDist, stam > 20)
                    elseif kDist < 40 then
                        managedSprint(stam, kDist)
                    elseif kDist < 65 or earlyWarning then
                        if stam>60 then managedSprint(stam,kDist,true)
                        elseif stam<40 then managedSprint(stam,kDist,false)
                        else managedSprint(stam,kDist) end
                    else
                        managedSprint(stam, kDist, false)
                    end
                end

                -- ── LOW HP → CHAT + SENTINEL ─────────────────────────────────
                if not inGrace and myHP < 40 and now-helper.lastChat >= 30 then
                    helper.lastChat=now
                    task.spawn(function() sendHelperChat("need help! low hp") end)
                end

                -- ── KILLER STAMINA ADVANTAGE → SENTINEL SEEK ─────────────────
                local killerAdvSent = killerStam > stam+15 and kDist < 55
                if killerAdvSent then
                    if helper.playState == "GEN" then helper.abortNav = true end
                    helper.playState = "SENTINEL_SEEK"
                    local sentPos,sentDist = findBestSentinel(hrp)
                    if sentPos and sentDist > 8 then
                        task.spawn(function() navigateTo(hrp,hum,sentPos) end)
                    end
                    return
                end

                -- ── STATE MACHINE (hysteresis bands prevent flapping) ────────
                -- Enter/exit thresholds are offset from each other so a kDist
                -- that's merely oscillating near a boundary doesn't flip the
                -- state every tick — that flipping was what caused the
                -- constant stop/redirect/die pattern.
                local prevState = helper.playState
                local nextState
                if prevState == "LOOP" then
                    nextState = (kDist > 48 and not isTargetingMe) and "AWARE" or "LOOP"
                elseif prevState == "AWARE" then
                    if kDist < 38 or (isTargetingMe and kDist < 55) then nextState="LOOP"
                    elseif kDist > 80 and not isTargetingMe then nextState="GEN"
                    else nextState="AWARE" end
                else -- GEN, IDLE, or coming out of SENTINEL_SEEK
                    if kDist < 38 or (isTargetingMe and kDist < 55) then nextState="LOOP"
                    elseif kDist < 55 or (isTargetingMe and kDist < 70) then nextState="AWARE"
                    else nextState="GEN" end
                end

                -- Leaving a navigation-owning state → abort so the new state
                -- gets sole movement authority instead of fighting the old
                -- in-flight PathfindingService waypoint loop
                if nextState ~= prevState and (prevState=="GEN" or prevState=="SENTINEL_SEEK") then
                    helper.abortNav = true
                end
                helper.playState = nextState

                if nextState == "LOOP" then
                    local spots = refreshLoopCache(hrp, khrp)
                    -- Only issue MoveTo once navigateTo has actually released
                    -- the humanoid — prevents two movement commands per tick
                    if #spots > 0 and not helper.isNavigating then
                        hum:MoveTo(getSmoothedOrbitPos(hrp, spots[1], khrp))
                    end

                elseif nextState == "AWARE" then
                    refreshLoopCache(hrp, khrp)  -- warm cache while there's still time

                else -- GEN
                    refreshLoopCache(hrp, khrp)
                    if not helper.isNavigating then
                        local genInfo = getNearestIncompleteGen(hrp)
                        if genInfo then
                            helper.currentGenTarget = genInfo.model
                            task.spawn(function()
                                navigateTo(hrp, hum, genInfo.pos)
                                if helper.currentGenTarget
                                   and helper.currentGenTarget.Parent then
                                    local targetPart = helper.currentGenTarget:IsA("BasePart")
                                        and helper.currentGenTarget
                                        or helper.currentGenTarget:FindFirstChildOfClass("BasePart")
                                    local d2 = targetPart
                                        and (targetPart.Position - hrp.Position).Magnitude or 99
                                    if d2 < 10 then
                                        fireProximityPrompt(helper.currentGenTarget)
                                    end
                                end
                                helper.currentGenTarget = nil
                            end)
                        end
                    end
                end
            end)
        end)
    end)
end

-- ── Helper UI ─────────────────────────────────────────────────
local secHelperStam = tabHelper:Section({Title="Stamina", Opened=true})
secHelperStam:Toggle({Title="Auto Stamina Management", Default=false,
    Callback=function(v) toggleAutoStam(v) end})

local secHelperLoop = tabHelper:Section({Title="Looping", Opened=true})
secHelperLoop:Toggle({Title="Show Best Loop Spots", Default=false,
    Callback=function(v) toggleShowLoops(v) end})
secHelperLoop:Toggle({Title="Auto Loop Killer", Default=false,
    Callback=function(v) toggleAutoLoop(v) end})
secHelperLoop:Slider({Title="Min Loop Size (studs)", Step=2,
    Value={Min=10,Max=30,Default=14},
    Callback=function(v) helper.minLoopSize=v end})

local secHelperPlay = tabHelper:Section({Title="Noob Auto Play", Opened=true})
secHelperPlay:Toggle({
    Title    = "Auto Play (Full Noob AI)",
    Default  = false,
    Callback = function(v)
        toggleAutoPlay(v)
        if v then toggleAutoStam(true); toggleShowLoops(true) end
    end
})
secHelperPlay:Button({Title="Ghostburger Now",  Callback=function() task.spawn(fireGhostburger) end})
secHelperPlay:Button({Title="Bloxy Cola Now",   Callback=function() task.spawn(fireBloxyCola)   end})
secHelperPlay:Button({Title="Slateskin Now",    Callback=function() task.spawn(fireSlateskin)   end})
secHelperPlay:Button({Title="Request Help Now", Callback=function() task.spawn(function() sendHelperChat("need help!") end) end})

-- ============================================================
-- 8. SLASHER KILLER AI
-- Full automation for Slasher (formerly Jason, renamed for
-- copyright — kit otherwise unchanged). Built on confirmed wiki
-- data: Slash/Behead cooldowns are documented; Gashing Wound and
-- Raging Pace cooldowns are NOT reliably documented outside
-- holiday-event numbers, so those are tunable sliders rather than
-- guessed constants.
--
-- LESSON CARRIED OVER FROM THE TWOTIME COOLDOWN BUG: every ability
-- here is timed purely via our own os.clock() timestamps. UI-
-- scraping (guessing label/attribute names) was proven unreliable
-- earlier in this build and is not used anywhere in this section.
-- ============================================================
local tabSlasher = win:Tab({Title="Slasher", Icon="skull"})

local slasher = {
    enabled = false,
    -- Self-tracked ability cooldowns (os.clock() timestamps only)
    lastSlash     = -10,
    lastBehead    = -30,
    lastGashing   = -60,
    lastRage      = -60,
    rageStartTime = nil,
    -- Cooldowns: Slash/Behead confirmed via wiki. Gashing Wound/Rage are
    -- unconfirmed base values — tune sliders to what you observe in-game.
    cdSlashBase  = 1.9,  cdSlashRage  = 0.8,
    cdBeheadBase = 18,   cdBeheadRage = 12,
    cdGashing    = 45,
    cdRage       = 60,
    -- Ranges (unconfirmed exact studs — tunable)
    rangeSlash   = 8,
    rangeBehead  = 9,
    rangeGashing = 6,
    -- Stamina management — exact rules:
    --   • Aggressive default: sprint whenever ANY stamina remains. Killer
    --     doesn't need a survivor-style safety reserve — closing distance
    --     always beats banking stamina for later.
    --   • Exhaustion hysteresis: stop only once stamina bottoms out to ~1,
    --     resume once it climbs back into a 15-20 band. Dead zone prevents
    --     the same flap bug fixed earlier for survivor stamina.
    --   • Post-Rage banking: once Raging Pace ends, if stamina reads ≥76
    --     (the elevated post-cap/Behead-refill state), hold off sprinting
    --     entirely — rely on Slash instead — until stamina hits 100.
    exhausted        = false,
    resumeThreshold  = 18,
    bankingStamina   = false,
    bankThreshold    = 76,
    wasEnraged       = false,
    -- State machine
    state            = "PATROL",
    targetModel      = nil,
    chaseStart       = 0,
    lastProgressDist = math.huge,
    lastProgressTime = 0,
    -- Nav guard — Slasher's own, independent of the Noob AI's
    isNavigating = false,
    abortNav     = false,
    conn         = nil,
    -- Sprint state-change guard (BUG FIX: killerManagedSprint was calling
    -- setSprint() unconditionally every tick — up to 60x/sec — instead of
    -- only on an actual change, spamming SendKeyEvent for no reason)
    curSprint = false,
    -- Tick throttle (BUG FIX: main loop ran full-speed 60Hz with no
    -- divisor, unlike every other system in this script — wasteful full
    -- survivor-folder scans + ability checks that don't need >10Hz)
    _tick = 0,
    -- Gashing Wound priority (see Ability Tuning) — lets you reserve it
    -- purely for the Anti-Backstab counter instead of also spending it
    -- on routine point-blank finishes
    gashingFinisherEnabled = true,
}

-- ── Ability firing — reuses the proven dual-strategy pattern already
-- established for Noob's abilities: guessed FireServer buffer names AND
-- keyword-matched GUI button click. The GUI click carries the actual
-- reliability; the FireServer guess is a harmless bonus attempt on top.
local function fireSlash()
    fireNoobAbility({"\3\5\0\0\0Slash"}, {"slash","m1","attack","machete"})
end
local function fireBehead()
    fireNoobAbility({"\3\6\0\0\0Behead"}, {"behead"})
end
local function fireGashingWound()
    fireNoobAbility({"\3\7\0\0\0Gashing","\3\12\0\0\0GashingWound"}, {"gash","wound","chainsaw"})
end
local function fireRagingPace()
    fireNoobAbility({"\3\6\0\0\0Raging","\3\10\0\0\0RagingPace"}, {"rage","enrage","pace"})
end

-- ── Killer stamina management (exact rules — see comments above) ──
-- BUG FIX: previously called setSprint() unconditionally every tick,
-- spamming SendKeyEvent up to 60x/sec even while already sprinting.
-- Now mirrors the Noob AI's proven pattern — only fires the input event
-- when the desired state actually differs from the current one.
-- ── Killer-specific stamina reader ───────────────────────────
-- BUG FIX: the shared readStamina()'s fallback estimate infers
-- "isSprinting" from hum.WalkSpeed > 18 — but WE'RE the one setting
-- WalkSpeed via our own setSprint() calls. That makes the estimate
-- circular: we sprint → WalkSpeed rises → the fallback sees that as
-- "sprinting" → drains a fake stamina bar → hits exhaustion in ~10s
-- purely from our own action → forces sprint off → WalkSpeed drops →
-- fallback sees "not sprinting" → estimate recovers → sprint resumes →
-- repeat. This produced the periodic stop/animation-reset pattern —
-- entirely self-inflicted, unrelated to Slasher's real stamina.
--
-- Fix: try the same direct reads first (harmless, might just work),
-- but if none succeed, drive the fallback off slasher.curSprint — our
-- own last COMMANDED intent — instead of reading back the side effect
-- of that command. Also skips drain/regen entirely while ENRAGED,
-- since Raging Pace has its own real stamina-cap mechanic this
-- fallback can't accurately emulate, and sprinting is disabled during
-- rage anyway so there's nothing to "drain" for sprinting in that state.
local killerStaminaEst = { value = 100, lastTime = os.clock() }

local function readKillerStamina(hum)
    local char = lp.Character
    if not char then return killerStaminaEst.value end
    local v = char:GetAttribute("Stamina") or char:GetAttribute("Stam")
    if type(v) == "number" then return v end
    local sv = char:FindFirstChild("Stamina") or char:FindFirstChild("Stam")
    if sv and sv:IsA("NumberValue") then return sv.Value end
    local stats = char:FindFirstChild("Stats")
    if stats then local s2 = stats:FindFirstChild("Stamina"); if s2 then return s2.Value end end
    if hum then
        local hv = hum:GetAttribute("Stamina")
        if type(hv) == "number" then return hv end
    end

    local now = os.clock()
    local dt  = math.min(now - killerStaminaEst.lastTime, 0.2)
    killerStaminaEst.lastTime = now
    local enraged = hum and hum.WalkSpeed >= 17
    if enraged then
        -- Raging Pace's own cap-toward-70 mechanic handles this window —
        -- don't drain/regen here to avoid double-counting against it
    elseif slasher.curSprint then
        killerStaminaEst.value = math.max(0, killerStaminaEst.value - 9.5*dt)
    else
        killerStaminaEst.value = math.min(110, killerStaminaEst.value + 21*dt)
    end
    return killerStaminaEst.value
end

local function killerSetSprint(want)
    if slasher.curSprint == want then return end
    slasher.curSprint = want
    setSprint(want)
end

local function killerManagedSprint(stam)
    if slasher.bankingStamina then
        killerSetSprint(false)
        if stam >= 99 then slasher.bankingStamina = false end
        return
    end
    if slasher.exhausted then
        if stam >= slasher.resumeThreshold then
            slasher.exhausted = false
            killerSetSprint(true)
        else
            killerSetSprint(false)  -- walking only — pathfinding is untouched
        end
    else
        if stam <= 1 then
            slasher.exhausted = true
            killerSetSprint(false)
        else
            killerSetSprint(true)   -- aggressive: spend it all, no reserve
        end
    end
end

-- Detects the Raging-Pace-end transition via OUR OWN WalkSpeed — 100%
-- reliable since it's our own character, zero networking/guessing
-- involved. Baseline is ~9-12, ENRAGED sets it to 19, so 17 cleanly
-- separates the two states.
local function updateRageBankingCheck(hum)
    local enraged = hum.WalkSpeed >= 17
    if enraged then
        slasher.wasEnraged = true
    elseif slasher.wasEnraged then
        slasher.wasEnraged = false
        local stam = readKillerStamina(hum)
        if stam >= slasher.bankThreshold then
            slasher.bankingStamina = true
        end
    end
end

-- ── Navigation (Slasher-scoped nav guard, independent of the Noob AI's) ──
local function slasherWaitMoveFinished(hum, timeoutSec)
    local done = false
    local conn = hum.MoveToFinished:Connect(function() done=true end)
    local elapsed = 0
    while not done and elapsed < timeoutSec do
        -- Bail fast on abort OR death, instead of waiting out the full
        -- timeout on a humanoid that's no longer going to move
        if slasher.abortNav or hum.Health <= 0 then break end
        elapsed = elapsed + task.wait(0.05)
    end
    pcall(function() conn:Disconnect() end)
end

local function slasherNavigateTo(hrp, hum, target)
    if not target or slasher.isNavigating then return end
    slasher.isNavigating = true
    slasher.abortNav = false
    pcall(function()
        local path = PathSvc:CreatePath({
            AgentRadius=2.5, AgentHeight=5.5, AgentCanJump=true,
            AgentMaxSlope=45, WaypointSpacing=4,
        })
        path:ComputeAsync(hrp.Position, target)
        if path.Status ~= Enum.PathStatus.Success then
            hum:MoveTo(target)
        else
            for _,wp in ipairs(path:GetWaypoints()) do
                if not slasher.enabled or slasher.abortNav then break end
                if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump=true end
                hum:MoveTo(wp.Position)
                slasherWaitMoveFinished(hum, 2.5)
            end
        end
    end)
    slasher.isNavigating = false
    slasher.abortNav = false
end

-- ── Target acquisition — prefers the Smart Killer Aimbot's existing
-- injured/downed-priority lock if that system is already running,
-- otherwise falls back to a simple nearest-survivor scan.
-- BUG FIX: previously capped at 90 studs, which meant any time no
-- survivor happened to be within that radius, this returned nil and
-- fell through to PATROL mode → beelining to a generator for no reason
-- ("why is bro trying to do gen"). Roblox replicates every character's
-- position to your client regardless of distance — same access the ESP
-- tab already relies on — so there's no reason to artificially limit
-- this. Now finds the nearest LIVING survivor anywhere on the map.
local function findChaseTarget(hrp)
    if killerAim.enabled and killerAim.lockedModel and killerAim.lockedModel.Parent then
        local h = killerAim.lockedModel:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then return killerAim.lockedModel end
    end
    local sf = getTeamFolder("Survivors")
    if not sf then return nil end
    local best, bestDist = nil, math.huge
    for _, model in ipairs(sf:GetChildren()) do
        if model:IsA("Model") then
            local r = model:FindFirstChild("HumanoidRootPart")
            local h = model:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then
                local d = (r.Position - hrp.Position).Magnitude
                if d < bestDist then bestDist=d; best=model end
            end
        end
    end
    return best
end

local function findNearestGenPos(hrp)
    local map = svc.WS:FindFirstChild("Map")
    if not map then return nil end
    local best, bestDist = nil, math.huge
    for _, item in ipairs(map:GetDescendants()) do
        if item.Name == "Generator" or item.Name == "FlowGame" then
            local pos = item:IsA("BasePart") and item.Position
                or (item:IsA("Model") and item.PrimaryPart and item.PrimaryPart.Position)
                or (item:IsA("Model") and item:FindFirstChildOfClass("BasePart")
                    and item:FindFirstChildOfClass("BasePart").Position)
            if pos then
                local d = (pos-hrp.Position).Magnitude
                if d < bestDist then bestDist=d; best=pos end
            end
        end
    end
    return best
end

-- ── Attack logic — Behead preferred when ready (wider hitbox + Helpless
-- utility is documented as stronger than raw Slash damage vs most
-- survivors), Slash otherwise. Both self-tracked, no UI dependency.
-- BUG FIX: added reserveBehead — without it, routine combat claimed
-- Behead's cooldown almost every time it came off cooldown, meaning
-- tryRageCleanExit's 6.3s exit window would find Behead already spent
-- and the documented clean-exit combo would rarely actually fire.
local function tryAutoAttacks(hrp, hum, targetModel, enraged, reserveBehead)
    local r = targetModel:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local dist = (r.Position - hrp.Position).Magnitude
    local now  = os.clock()
    local slashCd  = enraged and slasher.cdSlashRage  or slasher.cdSlashBase
    local beheadCd = enraged and slasher.cdBeheadRage or slasher.cdBeheadBase

    if not reserveBehead and dist <= slasher.rangeBehead and now - slasher.lastBehead >= beheadCd then
        slasher.lastBehead = now
        task.spawn(fireBehead)
    elseif dist <= slasher.rangeSlash and now - slasher.lastSlash >= slashCd then
        slasher.lastSlash = now
        task.spawn(fireSlash)
    end
end

-- ── Gashing Wound — guaranteed-hit finisher at point-blank range ──
-- Gated behind gashingFinisherEnabled so it can be disabled if you'd
-- rather reserve the ability purely for the Anti-Backstab counter,
-- since both share the same cooldown and a routine finisher use could
-- leave you without it during an actual backstab attempt.
local function tryGashingWoundFinisher(hrp, targetModel)
    if not slasher.gashingFinisherEnabled then return end
    local r = targetModel:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local dist = (r.Position - hrp.Position).Magnitude
    local now  = os.clock()
    if dist <= slasher.rangeGashing and now - slasher.lastGashing >= slasher.cdGashing then
        slasher.lastGashing = now
        task.spawn(fireGashingWound)
    end
end

-- ── Anti-Backstab → Gashing Wound synergy ──
-- The wiki explicitly documents this counter: turning to face a backstab
-- attempt AND using Gashing Wound (full invincibility) denies the Two
-- Time their Oblation charge and deals heavy damage back. Gated on the
-- CONFIRMED animation signal specifically (not the broader heuristic
-- cone-check already driving the turn-around) so this longer-cooldown
-- ability isn't burned on every "someone's merely behind me" ping.
local function tryAntiBackstabCounter(hrp)
    if not (antiBS and antiBS.enabled and antiBS.threatModel and antiBS.threatModel.Parent) then
        return
    end
    local threatChar = antiBS.threatModel.Parent
    if not isPlayingDaggerAnim(threatChar) then return end
    local dist = (antiBS.threatModel.Position - hrp.Position).Magnitude
    local now  = os.clock()
    if dist <= 10 and now - slasher.lastGashing >= slasher.cdGashing then
        slasher.lastGashing = now
        task.spawn(fireGashingWound)
    end
end

-- ── Raging Pace auto-trigger ──
-- Fires when OUR stamina is low AND the target is confirmed walking (not
-- sprinting) — Raging Pace's 19 walk-speed only wins against a walking
-- survivor (12), not one still sprinting (26), per the documented tip.
local function tryAutoRagingPace(hrp, hum, targetModel)
    if not targetModel then return end
    local r = targetModel:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local now = os.clock()
    if hum.WalkSpeed >= 17 then return end          -- already enraged
    if now - slasher.lastRage < slasher.cdRage then return end

    local myStam = readKillerStamina(hum)
    local vel = r.AssemblyLinearVelocity or Vector3.zero
    local targetSprinting = vel.Magnitude > 18

    if myStam < 35 and not targetSprinting then
        slasher.lastRage = now
        slasher.rageStartTime = now
        task.spawn(fireRagingPace)
    end
end

-- ── Clean-exit combo: cancel Raging Pace via Behead around the 6.5s
-- mark once stamina has capped, refilling it quickly per the documented
-- tip, instead of always riding out the full 14s duration ──
local function tryRageCleanExit(hrp, hum, targetModel)
    if not (hum.WalkSpeed >= 17 and slasher.rageStartTime) then return end
    local elapsed = os.clock() - slasher.rageStartTime
    if elapsed < 6.3 then return end
    if not targetModel then return end
    local r = targetModel:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local dist = (r.Position - hrp.Position).Magnitude
    local now  = os.clock()
    if dist <= slasher.rangeBehead and now - slasher.lastBehead >= slasher.cdBeheadRage then
        slasher.lastBehead    = now
        slasher.rageStartTime = nil  -- consumed the exit window
        task.spawn(fireBehead)
    end
end

-- ── Main tick ──
local function toggleSlasherAI(state)
    slasher.enabled = state
    if slasher.conn then pcall(function() slasher.conn:Disconnect() end); slasher.conn=nil end
    if not state then
        setSprint(false)
        slasher.curSprint = false
        slasher.isNavigating=false; slasher.abortNav=false
        return
    end
    slasher.conn = svc.Run.Heartbeat:Connect(function()
        if not slasher.enabled then return end
        -- BUG FIX: throttle to ~10Hz. The full survivor-folder scan and
        -- every ability check ran at 60Hz with no divisor — nothing here
        -- needs faster reaction than 100ms, and every other system in
        -- this script throttles similarly (Helper AI uses %12 for 5Hz).
        slasher._tick = slasher._tick + 1
        if slasher._tick % 6 ~= 0 then return end
        task.spawn(function()
            pcall(function()
                local char = lp.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if not char or not hrp or not hum or hum.Health <= 0 then return end

                local enraged = hum.WalkSpeed >= 17
                local stam    = readKillerStamina(hum)

                -- Stamina management always runs, independent of movement
                updateRageBankingCheck(hum)
                killerManagedSprint(stam)

                -- Anti-Backstab counter checked every tick regardless of state
                tryAntiBackstabCounter(hrp)

                local target = findChaseTarget(hrp)

                if target then
                    -- Leaving PATROL → abort any in-flight generator nav so
                    -- CHASE gets sole movement authority (same lesson as
                    -- the Noob AI movement-conflict fix)
                    if slasher.state == "PATROL" then
                        slasher.abortNav = true
                        slasher.chaseStart = os.clock()
                        slasher.lastProgressDist = math.huge
                        slasher.lastProgressTime = os.clock()
                    end
                    slasher.state = "CHASE"
                    slasher.targetModel = target

                    local r = target:FindFirstChild("HumanoidRootPart")
                    if r then
                        local dist = (r.Position - hrp.Position).Magnitude
                        -- Chase-abandonment: if 25s pass with no real
                        -- progress (distance hasn't meaningfully closed),
                        -- break off rather than get looped forever
                        if dist < slasher.lastProgressDist - 3 then
                            slasher.lastProgressDist = dist
                            slasher.lastProgressTime = os.clock()
                        end
                        local stuck = os.clock() - slasher.lastProgressTime > 25

                        if stuck then
                            slasher.state = "PATROL"
                            slasher.targetModel = nil
                        else
                            -- Movement toward target ALWAYS runs — sprint
                            -- state never gates whether we move, only how
                            -- fast ("don't stop pathfinding")
                            if not slasher.isNavigating then
                                task.spawn(function() slasherNavigateTo(hrp, hum, r.Position) end)
                            end
                            -- Reserve Behead for the clean-exit combo once
                            -- we're in its 6.3s window — otherwise routine
                            -- combat claims it first almost every time
                            local inExitWindow = enraged and slasher.rageStartTime
                                and (os.clock() - slasher.rageStartTime) >= 6.3
                            tryAutoAttacks(hrp, hum, target, enraged, inExitWindow)
                            tryGashingWoundFinisher(hrp, target)
                            tryAutoRagingPace(hrp, hum, target)
                            tryRageCleanExit(hrp, hum, target)
                        end
                    end
                else
                    if slasher.state == "CHASE" then
                        slasher.abortNav = true
                    end
                    slasher.state = "PATROL"
                    slasher.targetModel = nil
                    if not slasher.isNavigating then
                        local genPos = findNearestGenPos(hrp)
                        if genPos then
                            task.spawn(function() slasherNavigateTo(hrp, hum, genPos) end)
                        end
                    end
                end
            end)
        end)
    end)
end

-- Slasher's own respawn reset — needed as a separate connection since
-- `slasher` is declared here, later than the main CharacterAdded block
-- earlier in the script, and Lua locals aren't visible to closures
-- created before they're declared.
lp.CharacterAdded:Connect(function()
    slasher.exhausted      = false
    slasher.bankingStamina = false
    slasher.wasEnraged     = false
    slasher.rageStartTime  = nil
    slasher.state          = "PATROL"
    slasher.targetModel    = nil
    slasher.isNavigating   = false
    slasher.abortNav       = false
    slasher.curSprint      = false
    slasher.lastProgressDist = math.huge
    slasher.lastProgressTime = os.clock()
    killerStaminaEst.value    = 100
    killerStaminaEst.lastTime = os.clock()
end)

-- ── Slasher UI ──────────────────────────────────────────────
local secSlasherMain = tabSlasher:Section({Title="Slasher Killer AI", Opened=true})
secSlasherMain:Toggle({
    Title    = "Enable Full Auto Play",
    Default  = false,
    Callback = function(v) toggleSlasherAI(v) end
})

local secSlasherStam = tabSlasher:Section({Title="Stamina Management", Opened=true})
secSlasherStam:Slider({
    Title    = "Resume Sprint Threshold",
    Step     = 1,
    Value    = {Min=15, Max=20, Default=slasher.resumeThreshold},
    Callback = function(v) slasher.resumeThreshold = v end
})
secSlasherStam:Slider({
    Title    = "Post-Rage Bank Threshold",
    Step     = 1,
    Value    = {Min=60, Max=90, Default=slasher.bankThreshold},
    Callback = function(v) slasher.bankThreshold = v end
})

local secSlasherAbil = tabSlasher:Section({Title="Ability Tuning", Opened=false})
secSlasherAbil:Slider({
    Title    = "Gashing Wound Cooldown (s)",
    Step     = 5,
    Value    = {Min=15, Max=90, Default=slasher.cdGashing},
    Callback = function(v) slasher.cdGashing = v end
})
secSlasherAbil:Slider({
    Title    = "Raging Pace Cooldown (s)",
    Step     = 5,
    Value    = {Min=20, Max=90, Default=slasher.cdRage},
    Callback = function(v) slasher.cdRage = v end
})
secSlasherAbil:Slider({
    Title    = "Slash Range (studs)",
    Step     = 1,
    Value    = {Min=4, Max=14, Default=slasher.rangeSlash},
    Callback = function(v) slasher.rangeSlash = v end
})
secSlasherAbil:Slider({
    Title    = "Behead Range (studs)",
    Step     = 1,
    Value    = {Min=4, Max=14, Default=slasher.rangeBehead},
    Callback = function(v) slasher.rangeBehead = v end
})
secSlasherAbil:Toggle({
    Title    = "Point-Blank Gashing Wound Finisher",
    Default  = true,
    Callback = function(v) slasher.gashingFinisherEnabled = v end
})
secSlasherAbil:Button({Title="Slash Now",         Callback=function() task.spawn(fireSlash)        end})
secSlasherAbil:Button({Title="Behead Now",        Callback=function() task.spawn(fireBehead)       end})
secSlasherAbil:Button({Title="Gashing Wound Now", Callback=function() task.spawn(fireGashingWound) end})
secSlasherAbil:Button({Title="Raging Pace Now",   Callback=function() task.spawn(fireRagingPace)   end})

-- ============================================================
-- 9. INFO & VERSION TAB
-- ============================================================
local tabInfo = win:Tab({Title="Info", Icon="info"})
local secInfo = tabInfo:Section({Title="Build & Display", Opened=true})

secInfo:Toggle({Title="Version Display HUD", Default=false,
    Callback=function(v) toggleVersionHud(v) end})
secInfo:Button({
    Title    = "Show Script Version",
    Callback = function()
        ui:Notify({
            Title   = "BetrayalHub Custom",
            Content = "Version: "..SCRIPT_VERSION
                .. "\nTwoTime: Backstab | Double Stab | Status HUD | CD Indicator | Flash"
                .. "\nAimbot: Survivor | Smart Killer (Injured/Downed priority)"
                .. "\nHelper: Noob AI | Stamina (hysteresis) | Loop ESP | Auto Loop | Auto Play"
                .. "\nFixes: 6 bugs patched + stamina hysteresis + path timeout leak",
            Duration = 8,
            Icon    = "info"
        })
    end
})

print("BetrayalHub "..SCRIPT_VERSION.." loaded — Fixed: gen-camping (unlimited target range) + fake stamina feedback loop 🔥")

end) -- end pcall

if not success then flashError(err) end
