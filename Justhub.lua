--[[
    JUST HUB — Smooth Performance Edition (v18.5 PC+Mobile)
    ✦ Key system -> calls GameLoader -> GameLoader loads each game script
    ✦ Original UI / Layout / Effects preserved
]]

print(">>> START v18.5 PC+Mobile")

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local SS      = game:GetService("SoundService")
local HTTP    = game:GetService("HttpService")
local Debris  = game:GetService("Debris")

local LP  = Players.LocalPlayer
local PG  = LP:WaitForChild("PlayerGui")
local MOB = UIS.TouchEnabled and not UIS.KeyboardEnabled

local LS = loadstring or load
if not LS then
    warn(">>> [FATAL] No loadstring/load")
end

-- ═══════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════

local FRAME_IMG    = "rbxassetid://122792075573617"
local DISCORD_ICON = "rbxassetid://97396797065904"

local SERVICE_ID   = "justhubkey"
local DISCORD_URL  = "https://discord.gg/er5KkVYeS8"
local BUY_URL      = "https://ads.pandauth.com/getkey/justhubkey"
local SAVE_FILE    = "JustHub_SavedKey.json"

-- ★ Script 2: game loader (loads the right game script by GameId)
local LOADER_URL = "https://raw.githubusercontent.com/oveearn20/Game/main/GameLoader.lua"

_G.JustHubExpiry = 0

-- ═══════════════════════════════════════════════════════════
-- COLORS
-- ═══════════════════════════════════════════════════════════

local C = {
    white       = Color3.fromRGB(255,255,255),
    whiteSoft   = Color3.fromRGB(248,252,255),
    whiteDeep   = Color3.fromRGB(230,240,250),
    black       = Color3.fromRGB(0,0,0),
    bluePlace   = Color3.fromRGB(80,160,235),
    blueDeep    = Color3.fromRGB(20,70,150),
    blueMid     = Color3.fromRGB(40,110,200),
    blueLight   = Color3.fromRGB(80,160,235),
    iceBlue     = Color3.fromRGB(140,200,255),
    neonBlue    = Color3.fromRGB(0,180,255),
    purpleDeep  = Color3.fromRGB(70,40,130),
    purpleMid   = Color3.fromRGB(110,65,200),
    purpleLight = Color3.fromRGB(150,105,240),
    greenDeep   = Color3.fromRGB(15,90,50),
    greenMid    = Color3.fromRGB(35,165,90),
    greenLight  = Color3.fromRGB(90,230,150),
    dim         = Color3.fromRGB(160,195,235),
    muted       = Color3.fromRGB(120,145,180),
    good        = Color3.fromRGB(100,255,180),
    danger      = Color3.fromRGB(255,70,120),
    yellow      = Color3.fromRGB(255,200,65),
}

-- ═══════════════════════════════════════════════════════════
-- TWEEN MANAGER
-- ═══════════════════════════════════════════════════════════

local ActiveTweens = setmetatable({}, {__mode = "k"})

local function stopTween(obj)
    local old = ActiveTweens[obj]
    if old then
        pcall(function() old:Cancel() end)
        ActiveTweens[obj] = nil
    end
end

local function tw(obj, duration, props, style, direction)
    if not obj or not obj.Parent then return nil end
    stopTween(obj)
    local ok, tween = pcall(function()
        return TS:Create(
            obj,
            TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
            props
        )
    end)
    if not ok or not tween then return nil end
    ActiveTweens[obj] = tween
    tween.Completed:Connect(function()
        if ActiveTweens[obj] == tween then ActiveTweens[obj] = nil end
    end)
    pcall(function() tween:Play() end)
    return tween
end

local function cleanupTweens()
    for obj, tween in pairs(ActiveTweens) do
        pcall(function() tween:Cancel() end)
        ActiveTweens[obj] = nil
    end
end

-- ═══════════════════════════════════════════════════════════
-- UI HELPERS
-- ═══════════════════════════════════════════════════════════

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = o
    return c
end

local function stroke(o, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or C.blueMid
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.3
    s.Parent = o
    return s
end

-- ═══════════════════════════════════════════════════════════
-- SOUND CACHE
-- ═══════════════════════════════════════════════════════════

local SoundCache = {}

local function getSound(id)
    local sound = SoundCache[id]
    if sound and sound.Parent then return sound end
    sound = Instance.new("Sound")
    sound.Name = "JustHub_SFX"
    sound.SoundId = id
    sound.Volume = 0.4
    sound.Parent = SS
    SoundCache[id] = sound
    return sound
end

local function sfx(id, volume, pitch)
    pcall(function()
        local sound = getSound(id)
        sound.Volume = volume or 0.4
        sound.PlaybackSpeed = pitch or 1
        sound.TimePosition = 0
        sound:Play()
    end)
end

-- ═══════════════════════════════════════════════════════════
-- GENERAL HELPERS
-- ═══════════════════════════════════════════════════════════

local function fmtTime(s)
    if not s or s <= 0 then return "Expired" end
    s = math.floor(s)
    local d = math.floor(s / 86400)
    local h = math.floor((s % 86400) / 3600)
    local m = math.floor((s % 3600) / 60)
    local ss = s % 60
    if d > 0 then return d .. "d " .. h .. "h"
    elseif h > 0 then return h .. "h " .. m .. "m"
    elseif m > 0 then return m .. "m " .. ss .. "s"
    else return ss .. "s" end
end

local function copyLink(url)
    local ok = false
    pcall(function()
        if setclipboard then setclipboard(url); ok = true
        elseif toclipboard then toclipboard(url); ok = true end
    end)
    return ok
end

-- ═══════════════════════════════════════════════════════════
-- SAVE / LOAD
-- ═══════════════════════════════════════════════════════════

local function SaveKey(k, p, e)
    pcall(function()
        if writefile then
            writefile(SAVE_FILE, HTTP:JSONEncode({
                key = k, premium = p, expiry = e or 0, usedAt = os.time()
            }))
        end
    end)
end

local function LoadKey()
    local ok, data = pcall(function()
        if isfile and isfile(SAVE_FILE) then
            return HTTP:JSONDecode(readfile(SAVE_FILE))
        end
        return nil
    end)
    if ok then return data end
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- HTTP
-- ═══════════════════════════════════════════════════════════

local HTTP_METHODS = {
    function(url) return game:HttpGet(url, true) end,
    function(url) return game:HttpGet(url) end,
    function(url) return game:HttpGetAsync(url) end,
    function(url)
        if not request then error("no request") end
        local r = request({Url = url, Method = "GET"})
        if r and r.Body then return r.Body end
        error("empty body")
    end,
    function(url)
        if not syn or not syn.request then error("no syn") end
        local r = syn.request({Url = url, Method = "GET"})
        if r and r.Body then return r.Body end
        error("empty body")
    end,
    function(url)
        if not http_request then error("no http_request") end
        local r = http_request({Url = url, Method = "GET"})
        if r and r.Body then return r.Body end
        error("empty body")
    end,
}

local function httpGet(url)
    local lastErr = "unknown"
    for i = 1, #HTTP_METHODS do
        local fn = HTTP_METHODS[i]
        local ok, result = pcall(fn, url)
        if ok and type(result) == "string" and #result > 0 then
            print(">>> [HTTP] OK method #" .. i .. " | size:", #result)
            return result
        end
        lastErr = tostring(result)
    end
    warn(">>> [HTTP] FAILED:", lastErr)
    return nil, lastErr
end

-- ═══════════════════════════════════════════════════════════
-- LUA VALIDATION
-- ═══════════════════════════════════════════════════════════

local function isValidLua(src)
    if not src or #src < 30 then return false end
    local trimmed = src:gsub("^%s+", "")
    if trimmed:sub(1,1) == "<" then return false end
    if trimmed:find("<!DOCTYPE") or trimmed:find("<html") then return false end
    local lower = trimmed:lower()
    if lower:find("404") and lower:find("not found") then return false end
    if lower:find("couldn't find") or lower:find("could not find")
        or lower:find("repository not found") or lower:find("invalid response") then
        return false
    end
    if lower:find("not found") and #src < 200 then return false end
    return true
end

-- ═══════════════════════════════════════════════════════════
-- GAME LOADER CALL  (script 1 -> script 2)
-- ═══════════════════════════════════════════════════════════

local function LoadGame()
    _G.JustHubAuth = true  -- tell the loader the key was validated

    local src = httpGet(LOADER_URL)
    if not src or #src < 30 or src:sub(1, 1) == "<" then
        return false, "HTTP_FAIL"
    end

    local fn, syntaxErr = LS(src)
    if not fn then
        warn(">>> [LOAD] SYNTAX:", tostring(syntaxErr))
        return false, "SYNTAX"
    end

    local success, ok, reason = pcall(fn)
    if not success then
        warn(">>> [LOAD] RUNTIME:", tostring(ok))
        return false, "RUNTIME"
    end
    if ok == false then
        return false, reason or "RUNTIME"
    end
    return true
end

local LOAD_REASON = {
    UNSUPPORTED = "Game not supported",
    HTTP_FAIL   = "Download failed",
    SYNTAX      = "Script broken",
    RUNTIME     = "Script crashed",
}

-- ═══════════════════════════════════════════════════════════
-- PUSL
-- ═══════════════════════════════════════════════════════════

local PUSL
local PUSLReady = false
local PUSLState = "loading"

task.spawn(function()
    print(">>> [PUSL] Loading...")
    for attempt = 1, 3 do
        local ok, result = pcall(function()
            local src = httpGet("https://secure.pandauth.com/pv4/lib")
            if not src or src == "" then error("Empty") end
            return LS(src)()
        end)
        if ok and result and type(result.configure) == "function" then
            PUSL = result
            PUSLReady = true
            PUSLState = "ready"
            pcall(function() PUSL.configure({ serviceId = SERVICE_ID }) end)
            print(">>> [PUSL] READY")
            return
        end
        warn(">>> [PUSL] attempt " .. attempt .. " failed")
        task.wait(1)
    end
    PUSLState = "failed"
    warn(">>> [PUSL] FAILED")
end)

local function ValidateKey(key)
    if not key or key == "" then return false, "No key" end
    if not PUSLReady or not PUSL then return false, "Auth not ready" end
    local ok, result = pcall(function() return PUSL.validate(key) end)
    if not ok or not result then return false, "Network error" end
    if not result.success then return false, result.message or "Invalid key" end
    local expiry = 0
    for _, field in ipairs({
        "expiry","expires","expiresAt","expiresOn","expiration",
        "validUntil","timeRemaining","remaining","days"
    }) do
        local value = result[field]
        if value then
            if type(value) == "number" then
                if value > 1e12 then expiry = math.floor(value / 1000)
                elseif value > 1e9 then expiry = value
                elseif field == "days" then expiry = os.time() + value * 86400
                else expiry = os.time() + value end
            elseif type(value) == "string" then
                local y,mo,d,h,mi,s = value:match("(%d+)-(%d+)-(%d+)[ T](%d+):(%d+):(%d+)")
                if y then
                    expiry = os.time({
                        year=tonumber(y), month=tonumber(mo), day=tonumber(d),
                        hour=tonumber(h or 23), min=tonumber(mi or 59), sec=tonumber(s or 59)
                    })
                end
            end
            if expiry > 0 then break end
        end
    end
    return true, { isPremium = result.isPremium or false, expiry = expiry }
end

-- ═══════════════════════════════════════════════════════════
-- CLOCK
-- ═══════════════════════════════════════════════════════════

if PG:FindFirstChild("JustHubClock") then PG.JustHubClock:Destroy() end

local clockGui = Instance.new("ScreenGui")
clockGui.Name = "JustHubClock"
clockGui.ResetOnSpawn = false
clockGui.IgnoreGuiInset = true
clockGui.DisplayOrder = 999999
clockGui.Parent = PG

local CLOCK_W, CLOCK_H = 140, 48
local clockMoved = false

local function viewport()
    local s = clockGui.AbsoluteSize
    if s.X > 0 and s.Y > 0 then return s end
    local cam = workspace.CurrentCamera
    if cam and cam.ViewportSize.X > 0 then return cam.ViewportSize end
    return Vector2.new(800, 600)
end

local function clampClock(x, y)
    local vp = viewport()
    local pad = MOB and 20 or 8
    x = math.clamp(x, pad, math.max(pad, vp.X - CLOCK_W - pad))
    y = math.clamp(y, pad, math.max(pad, vp.Y - CLOCK_H - pad))
    return x, y
end

local function homeClock()
    local vp = viewport()
    local marginX = MOB and 70 or 30
    local marginY = MOB and 70 or 50
    return clampClock(vp.X - CLOCK_W - marginX, marginY)
end

local clock = Instance.new("Frame")
clock.AnchorPoint = Vector2.new(0,0)
do
    local hx, hy = homeClock()
    clock.Position = UDim2.fromOffset(hx, hy)
end
clock.Size = UDim2.fromOffset(CLOCK_W, CLOCK_H)
clock.ClipsDescendants = true
clock.Active = true
clock.BackgroundColor3 = Color3.fromRGB(4,11,27)
clock.BackgroundTransparency = 0.05
clock.BorderSizePixel = 0
clock.ZIndex = 5
clock.Visible = false
clock.Parent = clockGui
corner(clock,12)

local clockStroke = stroke(clock, C.blueLight, 1.4, 0.15)

local cdot = Instance.new("Frame")
cdot.AnchorPoint = Vector2.new(0,0.5)
cdot.Position = UDim2.new(0,10,0.5,0)
cdot.Size = UDim2.fromOffset(7,7)
cdot.BackgroundColor3 = C.good
cdot.BorderSizePixel = 0
cdot.ZIndex = 11
cdot.Parent = clock
corner(cdot,4)

local ctitle = Instance.new("TextLabel")
ctitle.Text = "JUST HUB"
ctitle.Font = Enum.Font.GothamBlack
ctitle.TextSize = 9
ctitle.TextColor3 = C.iceBlue
ctitle.BackgroundTransparency = 1
ctitle.Position = UDim2.fromOffset(24,5)
ctitle.Size = UDim2.new(1,-30,0,10)
ctitle.TextXAlignment = Enum.TextXAlignment.Left
ctitle.ZIndex = 12
ctitle.Parent = clock

local ctime = Instance.new("TextLabel")
ctime.Text = "--"
ctime.Font = Enum.Font.GothamBlack
ctime.TextSize = 15
ctime.TextColor3 = C.good
ctime.BackgroundTransparency = 1
ctime.Position = UDim2.fromOffset(24,17)
ctime.Size = UDim2.new(1,-32,0,18)
ctime.TextXAlignment = Enum.TextXAlignment.Left
ctime.TextScaled = true
ctime.ZIndex = 12
ctime.Parent = clock

local ctimeLimit = Instance.new("UITextSizeConstraint")
ctimeLimit.MaxTextSize = 15
ctimeLimit.MinTextSize = 8
ctimeLimit.Parent = ctime

local csub = Instance.new("TextLabel")
csub.Text = "REMAINING"
csub.Font = Enum.Font.GothamBold
csub.TextSize = 7
csub.TextColor3 = C.muted
csub.BackgroundTransparency = 1
csub.Position = UDim2.fromOffset(24,35)
csub.Size = UDim2.new(1,-32,0,10)
csub.TextXAlignment = Enum.TextXAlignment.Left
csub.TextTruncate = Enum.TextTruncate.AtEnd
csub.ZIndex = 12
csub.Parent = clock

task.spawn(function()
    local lastText, lastColor, lastSub, lastDot = nil, nil, nil, nil
    while clockGui.Parent do
        if clock.Visible then
            local expiry = _G.JustHubExpiry or 0
            local newText, newColor, newSub, newDot
            if expiry > 0 then
                local remain = expiry - os.time()
                if remain <= 0 then
                    newText = "EXPIRED"; newColor = C.danger
                    newSub = "PLEASE RENEW"; newDot = C.danger
                else
                    newText = fmtTime(remain)
                    if remain < 3600 then
                        newColor = C.danger; newDot = C.danger; newSub = "REMAINING"
                    elseif remain < 86400 then
                        newColor = C.yellow; newDot = C.yellow; newSub = "REMAINING"
                    else
                        newColor = C.good; newDot = C.good; newSub = "REMAINING"
                    end
                end
            else
                newText = "LIFETIME"; newColor = C.iceBlue
                newSub = "NO EXPIRY"; newDot = C.good
            end
            if lastText ~= newText then ctime.Text = newText; lastText = newText end
            if lastColor ~= newColor then
                ctime.TextColor3 = newColor; csub.TextColor3 = newColor; lastColor = newColor
            end
            if lastSub ~= newSub then csub.Text = newSub; lastSub = newSub end
            if lastDot ~= newDot then cdot.BackgroundColor3 = newDot; lastDot = newDot end
        end
        task.wait(1)
    end
end)

-- drag to move (mouse or touch)
do
    local dragging, dragStart, startPos = false, nil, nil

    clock.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = clock.AbsolutePosition
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            local x, y = clampClock(startPos.X + d.X, startPos.Y + d.Y)
            clock.Position = UDim2.fromOffset(x, y)
            clockMoved = true
        end
    end)

    local function onViewport()
        if not clock.Parent then return end
        if clockMoved then
            local x, y = clampClock(clock.AbsolutePosition.X, clock.AbsolutePosition.Y)
            clock.Position = UDim2.fromOffset(x, y)
        else
            local x, y = homeClock()
            clock.Position = UDim2.fromOffset(x, y)
        end
    end

    clockGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(onViewport)
    task.defer(onViewport)
end

local function ShowClock()
    if clock.Visible then return end
    if not clockMoved then
        local x, y = homeClock()
        clock.Position = UDim2.fromOffset(x, y)
    end
    clock.Visible = true
    clock.Size = UDim2.fromOffset(0,0)
    clock.BackgroundTransparency = 1
    clockStroke.Transparency = 1
    tw(clock, 0.5, {
        Size = UDim2.fromOffset(CLOCK_W, CLOCK_H),
        BackgroundTransparency = 0.05
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tw(clockStroke, 0.5, { Transparency = 0.15 })
end

-- ═══════════════════════════════════════════════════════════
-- KEY UI
-- ═══════════════════════════════════════════════════════════

if PG:FindFirstChild("JustHubKeyUI") then PG.JustHubKeyUI:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "JustHubKeyUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999998
gui.Parent = PG

local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1,1)
dim.BackgroundColor3 = Color3.new(0,0,0)
dim.BackgroundTransparency = 1
dim.BorderSizePixel = 0
dim.ZIndex = 1
dim.Parent = gui

local FW = 340
local FH = 300
local BASE_SCALE = MOB and 1 or 1.2

local win = Instance.new("Frame")
win.AnchorPoint = Vector2.new(0.5,0.5)
win.Position = UDim2.fromScale(0.5,0.5)
win.Size = UDim2.fromOffset(FW,FH)
win.BackgroundColor3 = Color3.fromRGB(4,11,27)
win.BackgroundTransparency = 1
win.BorderSizePixel = 0
win.ZIndex = 10
win.Active = false
win.Visible = false
win.Parent = gui

local winScale = Instance.new("UIScale")
winScale.Scale = BASE_SCALE
winScale.Parent = win

local frameImg = Instance.new("ImageLabel")
frameImg.Size = UDim2.fromScale(1,1)
frameImg.BackgroundTransparency = 1
frameImg.Image = FRAME_IMG
frameImg.ScaleType = Enum.ScaleType.Stretch
frameImg.ZIndex = 11
frameImg.Parent = win

local frameGlow = Instance.new("ImageLabel")
frameGlow.Size = UDim2.new(1,16,1,16)
frameGlow.Position = UDim2.fromOffset(-8,-8)
frameGlow.BackgroundTransparency = 1
frameGlow.Image = FRAME_IMG
frameGlow.ImageColor3 = C.blueLight
frameGlow.ImageTransparency = 1
frameGlow.ScaleType = Enum.ScaleType.Stretch
frameGlow.ZIndex = 9
frameGlow.Parent = win

local sweepLine = Instance.new("Frame")
sweepLine.Size = UDim2.new(0.35,0,0,2)
sweepLine.Position = UDim2.new(-0.4,0,0,0)
sweepLine.BackgroundColor3 = C.neonBlue
sweepLine.BackgroundTransparency = 1
sweepLine.BorderSizePixel = 0
sweepLine.ZIndex = 15
sweepLine.Parent = win

local sweepGrad = Instance.new("UIGradient")
sweepGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,1),
    NumberSequenceKeypoint.new(0.5,0),
    NumberSequenceKeypoint.new(1,1),
})
sweepGrad.Parent = sweepLine

-- INPUT
local inputBox = Instance.new("TextBox")
inputBox.PlaceholderText = "Enter your key..."
inputBox.Text = ""
inputBox.Font = Enum.Font.GothamBold
inputBox.TextSize = 12
inputBox.TextColor3 = C.blueMid
inputBox.TextStrokeTransparency = 1
inputBox.PlaceholderColor3 = C.bluePlace
inputBox.BackgroundColor3 = C.white
inputBox.BorderSizePixel = 0
inputBox.Position = UDim2.fromOffset(72,134)
inputBox.Size = UDim2.fromOffset(140,28)
inputBox.ClearTextOnFocus = false
inputBox.TextXAlignment = Enum.TextXAlignment.Left
inputBox.TextYAlignment = Enum.TextYAlignment.Center
inputBox.ClipsDescendants = true
inputBox.TextTruncate = Enum.TextTruncate.AtEnd
inputBox.ZIndex = 20
inputBox.Active = true
inputBox.Selectable = true
inputBox.Parent = win
corner(inputBox,6)

local inGrad = Instance.new("UIGradient")
inGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,C.white),
    ColorSequenceKeypoint.new(0.5,C.whiteSoft),
    ColorSequenceKeypoint.new(1,C.whiteDeep),
})
inGrad.Parent = inputBox

local inStroke = stroke(inputBox, C.blueMid, 1.4, 0.2)

local inPad = Instance.new("UIPadding")
inPad.PaddingLeft = UDim.new(0,8)
inPad.PaddingRight = UDim.new(0,8)
inPad.Parent = inputBox

-- PASTE
local pasteBtn = Instance.new("TextButton")
pasteBtn.Text = ""
pasteBtn.AutoButtonColor = false
pasteBtn.BackgroundColor3 = C.blueMid
pasteBtn.BorderSizePixel = 0
pasteBtn.Position = UDim2.fromOffset(213,134)
pasteBtn.Size = UDim2.fromOffset(55,28)
pasteBtn.ZIndex = 25
pasteBtn.Active = true
pasteBtn.Parent = win
corner(pasteBtn,6)

local pGrad = Instance.new("UIGradient")
pGrad.Color = ColorSequence.new(C.blueDeep, C.iceBlue, C.blueDeep)
pGrad.Rotation = 90
pGrad.Parent = pasteBtn

local pStroke = stroke(pasteBtn, C.blueLight, 1.2, 0.15)

local pShine = Instance.new("Frame")
pShine.Size = UDim2.new(1,-8,0,1)
pShine.Position = UDim2.new(0,4,0,2)
pShine.BackgroundColor3 = C.white
pShine.BackgroundTransparency = 0.3
pShine.BorderSizePixel = 0
pShine.ZIndex = 26
pShine.Parent = pasteBtn
corner(pShine,1)

local pLbl = Instance.new("TextLabel")
pLbl.Text = "PASTE"
pLbl.Font = Enum.Font.GothamBlack
pLbl.TextSize = 9
pLbl.TextColor3 = C.white
pLbl.BackgroundTransparency = 1
pLbl.Size = UDim2.fromScale(1,1)
pLbl.TextXAlignment = Enum.TextXAlignment.Center
pLbl.TextYAlignment = Enum.TextYAlignment.Center
pLbl.ZIndex = 28
pLbl.Parent = pasteBtn

pasteBtn.MouseButton1Click:Connect(function()
    sfx("rbxassetid://7058512845", 0.35)
    pcall(function()
        if getclipboard then
            local clip = getclipboard()
            if clip and clip ~= "" then inputBox.Text = clip end
        end
    end)
end)

pasteBtn.MouseEnter:Connect(function()
    tw(pStroke, 0.22, { Transparency = 0, Thickness = 1.6 })
end)

pasteBtn.MouseLeave:Connect(function()
    tw(pStroke, 0.22, { Transparency = 0.15, Thickness = 1.2 })
end)

-- STATUS
local status = Instance.new("TextLabel")
status.Text = "Ready"
status.Font = Enum.Font.GothamBlack
status.TextSize = 12
status.TextColor3 = C.good
status.TextStrokeTransparency = 1
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(72,162)
status.Size = UDim2.fromOffset(196,16)
status.TextXAlignment = Enum.TextXAlignment.Center
status.ZIndex = 20
status.Parent = win

local statusToken = 0

local function setStatus(text, color)
    statusToken += 1
    status.Text = text
    status.TextColor3 = color or C.good
    status.TextSize = 9
    status.TextTransparency = 0.4
    tw(status, 0.25, { TextSize = 12 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tw(status, 0.3, { TextTransparency = 0 })
end

local function flashStatus(message, color)
    statusToken += 1
    local token = statusToken
    setStatus(message, color)
    task.delay(2.5, function()
        if token == statusToken and status and status.Parent and status.Text == message then
            setStatus("Ready", C.good)
        end
    end)
end

-- BUTTON MAKER
local function mkBtn(name, text, iconType, dark, mid, light, px, py, pw, ph)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.BackgroundColor3 = mid
    btn.BorderSizePixel = 0
    btn.Position = UDim2.fromOffset(px,py)
    btn.Size = UDim2.fromOffset(pw,ph)
    btn.ZIndex = 20
    btn.Active = true
    btn.Parent = win
    corner(btn,6)

    local bg = Instance.new("UIGradient")
    bg.Color = ColorSequence.new(dark, light, dark)
    bg.Rotation = 90
    bg.Parent = btn

    local s = stroke(btn, light, 1.1, 0.25)

    local topShine = Instance.new("Frame")
    topShine.Size = UDim2.new(1,-10,0,1)
    topShine.Position = UDim2.new(0,5,0,2)
    topShine.BackgroundColor3 = C.white
    topShine.BackgroundTransparency = 0.3
    topShine.BorderSizePixel = 0
    topShine.ZIndex = 26
    topShine.Parent = btn
    corner(topShine,1)

    local content = Instance.new("Frame")
    content.Size = UDim2.fromScale(1,1)
    content.BackgroundTransparency = 1
    content.ZIndex = 26
    content.Parent = btn

    if iconType == "discord" then
        local iconImg = Instance.new("ImageLabel")
        iconImg.Image = DISCORD_ICON
        iconImg.ImageColor3 = C.white
        iconImg.BackgroundTransparency = 1
        iconImg.Position = UDim2.new(0,4,0.5,-6)
        iconImg.Size = UDim2.fromOffset(12,12)
        iconImg.ScaleType = Enum.ScaleType.Fit
        iconImg.ZIndex = 27
        iconImg.Parent = content
    end

    local txtLbl = Instance.new("TextLabel")
    txtLbl.Text = text
    txtLbl.Font = Enum.Font.GothamBlack
    txtLbl.TextSize = 9
    txtLbl.TextColor3 = C.white
    txtLbl.BackgroundTransparency = 1

    if iconType == "discord" then
        txtLbl.Position = UDim2.new(0,18,0,0)
        txtLbl.Size = UDim2.new(1,-22,1,0)
    else
        txtLbl.Position = UDim2.new(0,4,0,0)
        txtLbl.Size = UDim2.new(1,-8,1,0)
    end
    txtLbl.TextXAlignment = Enum.TextXAlignment.Center
    txtLbl.TextYAlignment = Enum.TextYAlignment.Center
    txtLbl.ZIndex = 27
    txtLbl.Parent = content

    btn.MouseEnter:Connect(function()
        bg.Color = ColorSequence.new(mid, light:Lerp(C.white,0.3), mid)
        tw(s, 0.2, { Transparency = 0, Thickness = 1.5 })
        tw(topShine, 0.2, { BackgroundTransparency = 0.1 })
    end)

    btn.MouseLeave:Connect(function()
        bg.Color = ColorSequence.new(dark, light, dark)
        tw(s, 0.2, { Transparency = 0.25, Thickness = 1.1 })
        tw(topShine, 0.2, { BackgroundTransparency = 0.3 })
    end)

    btn.MouseButton1Click:Connect(function()
        local maxSize = math.max(pw,ph) * 3
        local ripple = Instance.new("Frame")
        ripple.Size = UDim2.fromOffset(0,0)
        ripple.AnchorPoint = Vector2.new(0.5,0.5)
        ripple.Position = UDim2.fromScale(0.5,0.5)
        ripple.BackgroundColor3 = C.white
        ripple.BackgroundTransparency = 0.55
        ripple.BorderSizePixel = 0
        ripple.ZIndex = 25
        ripple.Parent = btn
        corner(ripple, 9999)
        tw(ripple, 0.55, {
            Size = UDim2.fromOffset(maxSize, maxSize),
            BackgroundTransparency = 1
        }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        task.delay(0.6, function()
            if ripple and ripple.Parent then ripple:Destroy() end
        end)
    end)

    return btn
end

local b1 = mkBtn("BuyKey","Buy Key",nil,C.greenDeep,C.greenMid,C.greenLight,72,178,60,30)
local b2 = mkBtn("Activate","Activate",nil,C.blueDeep,C.blueMid,C.blueLight,136,178,60,30)
local b3 = mkBtn("Discord","Discord","discord",C.purpleDeep,C.purpleMid,C.purpleLight,200,178,60,30)

-- FOOTER
local version = Instance.new("TextLabel")
version.Text = "v18.5"
version.Font = Enum.Font.GothamBold
version.TextSize = 8
version.TextColor3 = C.blueLight
version.BackgroundTransparency = 1
version.AnchorPoint = Vector2.new(1,0)
version.Position = UDim2.new(1,-10,0,6)
version.Size = UDim2.fromOffset(50,12)
version.TextXAlignment = Enum.TextXAlignment.Right
version.ZIndex = 20
version.Parent = win

local credit = Instance.new("TextLabel")
credit.Text = "© JustHub"
credit.Font = Enum.Font.GothamBold
credit.TextSize = 8
credit.TextColor3 = C.muted
credit.BackgroundTransparency = 1
credit.AnchorPoint = Vector2.new(0.5,1)
credit.Position = UDim2.new(0.5,0,1,-10)
credit.Size = UDim2.new(1,0,0,12)
credit.TextXAlignment = Enum.TextXAlignment.Center
credit.ZIndex = 20
credit.Parent = win

inputBox.Focused:Connect(function()
    tw(inStroke, 0.2, { Color = C.blueMid, Transparency = 0, Thickness = 2 })
end)

inputBox.FocusLost:Connect(function()
    tw(inStroke, 0.2, { Color = C.blueMid, Transparency = 0.2, Thickness = 1.4 })
end)

-- ACTIVATION
local isActivating = false

local function doActivate(key)
    if isActivating then return end
    key = tostring(key or "")
    if key == "" then
        setStatus("Please enter a key", C.danger)
        sfx("rbxassetid://3744371091", 0.4)
        return
    end
    if not PUSLReady then
        if PUSLState == "failed" then
            setStatus("Auth offline — retry later", C.danger)
        else
            setStatus("Loading auth... please wait", C.blueLight)
        end
        return
    end

    isActivating = true
    local currentKey = key
    setStatus("Validating...", C.blueLight)

    task.spawn(function()
        local ok, result = ValidateKey(currentKey)

        if not ok or type(result) ~= "table" then
            if gui and gui.Parent then
                setStatus(tostring(result), C.danger)
                sfx("rbxassetid://3744371091", 0.4)
            end
            isActivating = false
            return
        end

        if not gui or not gui.Parent then
            isActivating = false
            return
        end

        setStatus("Activated! Loading script...", C.good)
        sfx("rbxassetid://4612375230", 0.5)
        _G.JustHubExpiry = result.expiry or 0

        task.spawn(function()
            pcall(function()
                SaveKey(currentKey, result.isPremium, result.expiry or 0)
            end)
        end)

        task.spawn(function()
            local loaded, reason = LoadGame()

            if loaded then
                task.defer(function()
                    if not gui or not gui.Parent then
                        isActivating = false
                        return
                    end

                    pcall(function() ShowClock() end)

                    task.defer(function()
                        if not gui or not gui.Parent then
                            isActivating = false
                            return
                        end

                        tw(dim, 0.4, { BackgroundTransparency = 1 })
                        tw(winScale, 0.5, { Scale = 0 },
                            Enum.EasingStyle.Back, Enum.EasingDirection.In)

                        task.delay(0.6, function()
                            if gui and gui.Parent then
                                cleanupTweens()
                                pcall(function() gui:Destroy() end)
                            end
                        end)

                        isActivating = false
                    end)
                end)
            else
                if gui and gui.Parent then
                    setStatus(LOAD_REASON[reason] or "Load failed", C.yellow)
                end
                isActivating = false
            end
        end)
    end)
end

b2.MouseButton1Click:Connect(function()
    doActivate(inputBox.Text)
end)

b1.MouseButton1Click:Connect(function()
    sfx("rbxassetid://7058512845", 0.4)
    local ok = copyLink(BUY_URL)
    if ok then
        flashStatus("📋 Buy link copied!", C.greenLight)
    else
        flashStatus("Copy: " .. BUY_URL, C.danger)
    end
end)

b3.MouseButton1Click:Connect(function()
    sfx("rbxassetid://4612375230", 0.4)
    local ok = copyLink(DISCORD_URL)
    if ok then
        flashStatus("📋 Discord copied!", C.purpleLight)
    else
        flashStatus("Copy: " .. DISCORD_URL, C.danger)
    end
end)

-- INTRO
task.spawn(function()
    task.wait(0.3)

    local saved = LoadKey()

    if saved and saved.key and saved.key ~= "" then
        local waited = 0
        while not PUSLReady and PUSLState ~= "failed" and waited < 6 do
            task.wait(0.2)
            waited += 0.2
        end

        if PUSLReady then
            local ok, result = ValidateKey(saved.key)
            if ok and type(result) == "table" then
                _G.JustHubExpiry = result.expiry or saved.expiry or 0

                task.spawn(function()
                    pcall(function()
                        SaveKey(saved.key, result.isPremium, _G.JustHubExpiry)
                    end)
                end)

                task.spawn(function()
                    local loaded = LoadGame()
                    if loaded then
                        task.defer(function()
                            if not gui or not gui.Parent then return end
                            ShowClock()
                            task.delay(0.7, function()
                                if gui and gui.Parent then
                                    cleanupTweens()
                                    gui:Destroy()
                                end
                            end)
                        end)
                    end
                end)
                return
            end
        end
    end

    sfx("rbxassetid://93949387354465", 0.4)

    win.Visible = true
    tw(dim, 0.6, { BackgroundTransparency = 0.55 })

    frameImg.ImageTransparency = 1
    frameGlow.ImageTransparency = 1
    winScale.Scale = BASE_SCALE * 2.5

    inputBox.Visible = false
    pasteBtn.Visible = false
    status.Visible = false
    b1.Visible = false
    b2.Visible = false
    b3.Visible = false
    version.Visible = false
    credit.Visible = false
    sweepLine.Visible = false

    task.wait(0.15)

    tw(winScale, 0.9, { Scale = BASE_SCALE },
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tw(frameImg, 0.5, { ImageTransparency = 0 })
    tw(frameGlow, 0.8, { ImageTransparency = 0.85 })

    task.wait(0.55)

    sfx("rbxassetid://4612375230", 0.3)

    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5,0.5)
    ring.Position = UDim2.fromScale(0.5,0.5)
    ring.Size = UDim2.fromOffset(FW * 0.5, FH * 0.5)
    ring.BackgroundTransparency = 1
    ring.ZIndex = 30
    ring.Parent = win
    corner(ring, 20)

    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = C.neonBlue
    ringStroke.Thickness = 3
    ringStroke.Transparency = 0.2
    ringStroke.Parent = ring

    tw(ring, 0.7, {
        Size = UDim2.fromOffset(FW + 100, FH + 100)
    }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    tw(ringStroke, 0.7, { Transparency = 1, Thickness = 0.5 })

    task.delay(0.8, function()
        if ring and ring.Parent then ring:Destroy() end
    end)

    task.wait(0.25)

    local function popIn(element, delayTime)
        task.delay(delayTime, function()
            if not element or not element.Parent then return end
            element.Visible = true
            local originalSize = element.Size
            element.Size = UDim2.fromOffset(0,0)
            tw(element, 0.5, { Size = originalSize },
                Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            sfx("rbxassetid://6895079853", 0.15, 1.5)
        end)
    end

    popIn(inputBox, 0)
    popIn(pasteBtn, 0.08)
    popIn(status, 0.16)
    popIn(b1, 0.24)
    popIn(b2, 0.32)
    popIn(b3, 0.40)
    popIn(version, 0.48)
    popIn(credit, 0.48)

    task.wait(0.6)

    sweepLine.Visible = true
    sweepLine.BackgroundTransparency = 0

    local PARTICLES = 20

    for i = 1, PARTICLES do
        local angle = (i / PARTICLES) * math.pi * 2
        local speed = math.random(70,130)
        local size = math.random(2,4)
        local particle = Instance.new("Frame")
        particle.Size = UDim2.fromOffset(size, size)
        particle.AnchorPoint = Vector2.new(0.5,0.5)
        particle.Position = UDim2.fromScale(0.5, 0.5)
        particle.BackgroundColor3 = (i % 2 == 0) and C.neonBlue or C.iceBlue
        particle.BorderSizePixel = 0
        particle.ZIndex = 220
        particle.Parent = gui
        corner(particle, size / 2)
        tw(particle, 1.2, {
            Position = UDim2.new(
                0.5, math.cos(angle) * speed,
                0.5, math.sin(angle) * speed
            ),
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(1, 1)
        }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        task.delay(1.35, function()
            if particle and particle.Parent then particle:Destroy() end
        end)
    end

    task.wait(1)

    task.spawn(function()
        while sweepLine and sweepLine.Parent do
            sweepLine.Position = UDim2.new(-0.4, 0, 0, 0)
            sweepLine.BackgroundTransparency = 0
            tw(sweepLine, 2.2, {
                Position = UDim2.new(1.1, 0, 0, 0)
            }, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            task.wait(3.5)
        end
    end)

    task.spawn(function()
        while frameGlow and frameGlow.Parent do
            tw(frameGlow, 2.5, { ImageTransparency = 0.65 },
                Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(2.5)
            if not frameGlow.Parent then break end
            tw(frameGlow, 2.5, { ImageTransparency = 0.9 },
                Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(2.5)
        end
    end)
end)

print(">>> [JUST HUB v18.5 PC+Mobile] READY - GameId:", tostring(game.GameId), "| PlaceId:", tostring(game.PlaceId))
