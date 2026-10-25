-- language: Lua, target: Roblox executor (Delta / dll) — MOBILE FRIENDLY
-- Valkrie v7. Tampilan emas gradasi ala MLBB, garis ornamen header, fitur v6 lengkap.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local parentGui = playerGui
pcall(function() parentGui = game:GetService("CoreGui") end)

local old = parentGui:FindFirstChild("ValkrieUI") or playerGui:FindFirstChild("ValkrieUI")
if old then old:Destroy() end

-- ===================== KONFIG =====================
local CROWN_IMAGE_ID = "rbxassetid://12221967"
local CONFIG_FOLDER = "Valkrie"
local CONFIG_FILE = CONFIG_FOLDER .. "/configs.json"
local AUTOLOAD_FILE = CONFIG_FOLDER .. "/autoload.txt"

local C = {
    bg        = Color3.fromRGB(12, 10, 8),
    sidebar   = Color3.fromRGB(18, 15, 11),
    panel     = Color3.fromRGB(24, 20, 15),
    panelHi   = Color3.fromRGB(40, 34, 24),
    gold      = Color3.fromRGB(212, 175, 55),
    goldSoft  = Color3.fromRGB(255, 235, 170),
    goldBright= Color3.fromRGB(255, 210, 80),
    goldDark  = Color3.fromRGB(140, 100, 30),
    text      = Color3.fromRGB(245, 238, 215),
    textDim   = Color3.fromRGB(160, 148, 120),
    danger    = Color3.fromRGB(180, 70, 60),
    green     = Color3.fromRGB(120, 200, 130),
}

local GRADIENT_GOLD = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, C.goldBright),
    ColorSequenceKeypoint.new(0.25, C.goldSoft),
    ColorSequenceKeypoint.new(0.50, C.gold),
    ColorSequenceKeypoint.new(0.75, C.goldSoft),
    ColorSequenceKeypoint.new(1.00, C.goldDark),
})

local GRADIENT_DARK = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, C.panelHi),
    ColorSequenceKeypoint.new(0.50, C.panel),
    ColorSequenceKeypoint.new(1.00, C.panelHi),
})

local function applyGoldGradient(inst)
    local g = Instance.new("UIGradient")
    g.Color = GRADIENT_GOLD
    g.Rotation = 90
    g.Parent = inst
    return g
end

local FONT_TITLE = Enum.Font.GothamBold
local FONT_BODY  = Enum.Font.Gotham
local FONT_MED   = Enum.Font.GothamMedium
local FONT_BOLD  = Enum.Font.GothamBold

-- ===================== SCREEN =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ValkrieUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = parentGui

-- ===================== TOAST =====================
local toastFrame = Instance.new("Frame")
toastFrame.Size = UDim2.fromOffset(300, 42)
toastFrame.Position = UDim2.new(0.5, 0, 1, -90)
toastFrame.AnchorPoint = Vector2.new(0.5, 1)
toastFrame.BackgroundColor3 = C.panel
toastFrame.BorderSizePixel = 0
toastFrame.BackgroundTransparency = 1
toastFrame.ZIndex = 200
toastFrame.Parent = screenGui
Instance.new("UICorner", toastFrame).CornerRadius = UDim.new(0, 8)
local toastStroke = Instance.new("UIStroke", toastFrame)
toastStroke.Color = C.gold
toastStroke.Thickness = 1
toastStroke.Transparency = 1
toastStroke.ZIndex = 200
applyGoldGradient(toastStroke)
local toastLabel = Instance.new("TextLabel")
toastLabel.Size = UDim2.new(1, -20, 1, 0)
toastLabel.Position = UDim2.new(0, 14, 0, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.Text = ""
toastLabel.TextColor3 = C.goldSoft
toastLabel.TextSize = 12
toastLabel.Font = FONT_MED
toastLabel.TextXAlignment = Enum.TextXAlignment.Left
toastLabel.TextTransparency = 1
toastLabel.ZIndex = 201
toastLabel.Parent = toastFrame

local toastToken = 0
local function toast(msg)
    toastToken += 1
    local my = toastToken
    toastLabel.Text = msg
    TweenService:Create(toastFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0.05}):Play()
    TweenService:Create(toastStroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
    TweenService:Create(toastLabel, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
    task.delay(1.8, function()
        if my ~= toastToken then return end
        TweenService:Create(toastFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(toastStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
        TweenService:Create(toastLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    end)
end

-- ===================== CONFIG MANAGER =====================
local function ensureFolder()
    pcall(function()
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    end)
end

local function getPlaceName()
    local ok, name = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId, Enum.InfoType.Asset).Name
    end)
    if ok and name and type(name) == "string" then return name end
    return "Place" .. tostring(game.PlaceId)
end

local currentGameKey = getPlaceName()

local function readConfigs()
    ensureFolder()
    if not isfile(CONFIG_FILE) then return {} end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if ok and type(data) == "table" then return data end
    return {}
end

local function writeConfigs(data)
    ensureFolder()
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(data)) end)
end

local function saveConfig(name, values, bl)
    local data = readConfigs()
    data[name] = { values = values, blacklist = bl or {} }
    writeConfigs(data)
end

local function loadConfig(name)
    local data = readConfigs()
    return data[name]
end

local function deleteConfig(name)
    local data = readConfigs()
    data[name] = nil
    writeConfigs(data)
end

local function listConfigs()
    local data = readConfigs()
    local out = {}
    for k in pairs(data) do table.insert(out, k) end
    table.sort(out)
    return out
end

local function getAutoloadName()
    ensureFolder()
    if isfile(AUTOLOAD_FILE) then
        local ok, txt = pcall(function() return readfile(AUTOLOAD_FILE) end)
        if ok and txt and txt ~= "" then return txt end
    end
    return nil
end

local function setAutoloadName(name)
    ensureFolder()
    pcall(function() writefile(AUTOLOAD_FILE, name or "") end)
end

-- ===================== MAIN =====================
local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(620, 480)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local border = Instance.new("UIStroke", main)
border.Color = C.gold
border.Thickness = 1.5
border.Transparency = 0.15
applyGoldGradient(border)

-- ===================== SIDEBAR =====================
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.fromOffset(160, 1)
sidebar.BackgroundColor3 = C.sidebar
sidebar.BorderSizePixel = 0
sidebar.Parent = main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)
local sidebarFix = Instance.new("Frame")
sidebarFix.Size = UDim2.new(0, 10, 1, 0)
sidebarFix.Position = UDim2.new(1, -10, 0, 0)
sidebarFix.BackgroundColor3 = C.sidebar
sidebarFix.BorderSizePixel = 0
sidebarFix.Parent = sidebar

local brandFrame = Instance.new("Frame")
brandFrame.Size = UDim2.new(1, -20, 0, 60)
brandFrame.Position = UDim2.new(0, 10, 0, 10)
brandFrame.BackgroundTransparency = 1
brandFrame.Parent = sidebar

local crownImg = Instance.new("ImageLabel")
crownImg.Size = UDim2.fromOffset(30, 30)
crownImg.Position = UDim2.new(0, 4, 0.5, -15)
crownImg.BackgroundTransparency = 1
crownImg.Image = CROWN_IMAGE_ID
crownImg.Parent = brandFrame

local brandTitle = Instance.new("TextLabel")
brandTitle.Size = UDim2.new(1, -44, 0, 20)
brandTitle.Position = UDim2.new(0, 40, 0, 4)
brandTitle.BackgroundTransparency = 1
brandTitle.Text = "VALKRIE"
brandTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
brandTitle.TextSize = 15
brandTitle.Font = FONT_TITLE
brandTitle.TextXAlignment = Enum.TextXAlignment.Left
brandTitle.Parent = brandFrame
local titleGrad = Instance.new("UIGradient")
titleGrad.Color = GRADIENT_GOLD
titleGrad.Parent = brandTitle

local brandSub = Instance.new("TextLabel")
brandSub.Size = UDim2.new(1, -44, 0, 14)
brandSub.Position = UDim2.new(0, 40, 0, 24)
brandSub.BackgroundTransparency = 1
brandSub.Text = "v7 · " .. string.sub(currentGameKey, 1, 18)
brandSub.TextColor3 = C.textDim
brandSub.TextSize = 9
brandSub.Font = FONT_BODY
brandSub.TextXAlignment = Enum.TextXAlignment.Left
brandSub.Parent = brandFrame

local div = Instance.new("Frame")
div.Size = UDim2.new(1, -24, 0, 1)
div.Position = UDim2.new(0, 12, 0, 72)
div.BackgroundColor3 = C.gold
div.BorderSizePixel = 0
div.Parent = sidebar
applyGoldGradient(div)

local tabList = Instance.new("Frame")
tabList.Size = UDim2.new(1, -16, 1, -160)
tabList.Position = UDim2.new(0, 8, 0, 80)
tabList.BackgroundTransparency = 1
tabList.Parent = sidebar
local tabLayout = Instance.new("UIListLayout", tabList)
tabLayout.Padding = UDim.new(0, 3)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

local bottomBar = Instance.new("Frame")
bottomBar.Size = UDim2.new(1, -16, 0, 32)
bottomBar.Position = UDim2.new(0, 8, 1, -42)
bottomBar.BackgroundTransparency = 1
bottomBar.Parent = sidebar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.fromOffset(66, 30)
minimizeBtn.BackgroundColor3 = C.panelHi
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = C.goldSoft
minimizeBtn.TextSize = 16
minimizeBtn.Font = FONT_MED
minimizeBtn.Parent = bottomBar
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(66, 30)
closeBtn.Position = UDim2.new(1, -66, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(45, 24, 20)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(240, 180, 170)
closeBtn.TextSize = 13
closeBtn.Font = FONT_MED
closeBtn.Parent = bottomBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- ===================== KONTEN =====================
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -160, 1, 0)
content.Position = UDim2.new(0, 160, 0, 0)
content.BackgroundTransparency = 1
content.Parent = main

-- ==== HEADER dengan ornamen garis ====
local contentHeader = Instance.new("Frame")
contentHeader.Size = UDim2.new(1, -24, 0, 52)
contentHeader.Position = UDim2.new(0, 12, 0, 10)
contentHeader.BackgroundColor3 = C.panel
contentHeader.BorderSizePixel = 0
contentHeader.Parent = content
Instance.new("UICorner", contentHeader).CornerRadius = UDim.new(0, 8)
local chStroke = Instance.new("UIStroke", contentHeader)
chStroke.Color = C.gold
chStroke.Thickness = 1
chStroke.Transparency = 0.3
applyGoldGradient(chStroke)

-- Ornamen garis kiri
local lineLeft = Instance.new("Frame")
lineLeft.Size = UDim2.new(0.25, 0, 0, 2)
lineLeft.Position = UDim2.new(0, 14, 0.5, -1)
lineLeft.BackgroundColor3 = C.gold
lineLeft.BorderSizePixel = 0
lineLeft.Parent = contentHeader
applyGoldGradient(lineLeft)

local dotLeft = Instance.new("Frame")
dotLeft.Size = UDim2.fromOffset(6, 6)
dotLeft.Position = UDim2.new(0, 10, 0.5, -3)
dotLeft.BackgroundColor3 = C.goldBright
dotLeft.BorderSizePixel = 0
dotLeft.Parent = contentHeader
Instance.new("UICorner", dotLeft).CornerRadius = UDim.new(1, 0)

-- Ornamen garis kanan
local lineRight = Instance.new("Frame")
lineRight.Size = UDim2.new(0.25, 0, 0, 2)
lineRight.Position = UDim2.new(1, -14, 0.5, -1)
lineRight.AnchorPoint = Vector2.new(1, 0)
lineRight.BackgroundColor3 = C.gold
lineRight.BorderSizePixel = 0
lineRight.Parent = contentHeader
applyGoldGradient(lineRight)

local dotRight = Instance.new("Frame")
dotRight.Size = UDim2.fromOffset(6, 6)
dotRight.Position = UDim2.new(1, -10, 0.5, -3)
dotRight.AnchorPoint = Vector2.new(1, 0)
dotRight.BackgroundColor3 = C.goldBright
dotRight.BorderSizePixel = 0
dotRight.Parent = contentHeader
Instance.new("UICorner", dotRight).CornerRadius = UDim.new(1, 0)

local contentTitle = Instance.new("TextLabel")
contentTitle.Size = UDim2.new(0.5, 0, 1, 0)
contentTitle.Position = UDim2.new(0.25, 0, 0, 0)
contentTitle.BackgroundTransparency = 1
contentTitle.Text = "Movement"
contentTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
contentTitle.TextSize = 15
contentTitle.Font = FONT_BOLD
contentTitle.TextXAlignment = Enum.TextXAlignment.Center
contentTitle.Parent = contentHeader
local ctGrad = Instance.new("UIGradient")
ctGrad.Color = GRADIENT_GOLD
ctGrad.Parent = contentTitle

-- ==== SCROLL ====
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 1, -86)
scroll.Position = UDim2.new(0, 12, 0, 70)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = C.goldDark
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = content
local contentLayout = Instance.new("UIListLayout", scroll)
contentLayout.Padding = UDim.new(0, 6)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
local contentPad = Instance.new("UIPadding", scroll)
contentPad.PaddingRight = UDim.new(0, 6)

-- ===================== PAGES =====================
local pages = {}
local pageOrder = {"Movement", "Visual", "Utility", "Misc", "Config"}
local currentTabName = nil
for _, n in ipairs(pageOrder) do
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = scroll
    page.AutomaticSize = Enum.AutomaticSize.Y
    local l = Instance.new("UIListLayout", page)
    l.Padding = UDim.new(0, 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    pages[n] = page
end

-- ===================== KOMPONEN =====================
local function makeToggle(parent, name, initial, onChanged)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = C.panel
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", row)
    s.Color = C.goldDark; s.Thickness = 1; s.Transparency = 0.5
    applyGoldGradient(s)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = C.text
    lbl.TextSize = 12
    lbl.Font = FONT_MED
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local state = initial and true or false
    local track = Instance.new("TextButton")
    track.Size = UDim2.fromOffset(38, 20)
    track.Position = UDim2.new(1, -52, 0.5, -10)
    track.BackgroundColor3 = state and C.gold or C.panelHi
    track.BorderSizePixel = 0
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local tStroke = Instance.new("UIStroke", track)
    tStroke.Color = state and C.goldSoft or C.goldDark
    tStroke.Thickness = 1
    tStroke.Transparency = 0.3

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, state and 22 or 3, 0.5, 0)
    knob.BackgroundColor3 = state and C.bg or C.goldSoft
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function refresh()
        track.BackgroundColor3 = state and C.gold or C.panelHi
        tStroke.Color = state and C.goldSoft or C.goldDark
        knob.BackgroundColor3 = state and C.bg or C.goldSoft
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = UDim2.new(0, state and 22 or 3, 0.5, 0)
        }):Play()
    end

    track.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        toast(name .. ": " .. (state and "ON" or "OFF"))
        if onChanged then onChanged(state) end
    end)

    return {
        set = function(v)
            state = v
            refresh()
            if onChanged then onChanged(state) end
        end,
        get = function() return state end,
    }
end

local function makeSlider(parent, name, min, max, default, onChanged)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 56)
    row.BackgroundColor3 = C.panel
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", row)
    s.Color = C.goldDark; s.Thickness = 1; s.Transparency = 0.5
    applyGoldGradient(s)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = C.text
    lbl.TextSize = 12
    lbl.Font = FONT_MED
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.fromOffset(50, 20)
    valLbl.Position = UDim2.new(1, -64, 0, 6)
    valLbl.BackgroundColor3 = C.panelHi
    valLbl.BorderSizePixel = 0
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = C.goldSoft
    valLbl.TextSize = 11
    valLbl.Font = FONT_BOLD
    valLbl.Parent = row
    Instance.new("UICorner", valLbl).CornerRadius = UDim.new(0, 4)

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 6)
    track.Position = UDim2.new(0, 14, 0, 36)
    track.BackgroundColor3 = C.panelHi
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = C.gold
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    applyGoldGradient(fill)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(12, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    knob.BackgroundColor3 = C.goldSoft
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        valLbl.Text = tostring(val)
        if onChanged then onChanged(val) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; updateFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {
        set = function(v)
            local rel = (v - min) / (max - min)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            valLbl.Text = tostring(v)
            if onChanged then onChanged(v) end
        end,
        get = function() return tonumber(valLbl.Text) or default end,
    }
end

local function makeButton(parent, text, onClick, danger)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 34)
    b.BackgroundColor3 = danger and Color3.fromRGB(45, 24, 20) or C.panel
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = danger and Color3.fromRGB(240, 180, 170) or C.text
    b.TextSize = 11
    b.Font = FONT_MED
    b.AutoButtonColor = true
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", b)
    s.Color = danger and C.danger or C.goldDark
    s.Thickness = 1
    s.Transparency = 0.4
    applyGoldGradient(s)
    b.MouseButton1Click:Connect(function() if onClick then onClick() end end)
    return b
end

local function makeSection(parent, text)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 30)
    wrap.BackgroundTransparency = 1
    wrap.Parent = parent
    wrap.AutomaticSize = Enum.AutomaticSize.Y
    local wl = Instance.new("UIListLayout", wrap)
    wl.Padding = UDim.new(0, 6)
    wl.SortOrder = Enum.SortOrder.LayoutOrder

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundTransparency = 1
    header.Text = "▾  " .. string.upper(text)
    header.TextColor3 = C.gold
    header.TextSize = 10
    header.Font = FONT_BOLD
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = wrap

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 0, 0)
    body.BackgroundTransparency = 1
    body.Parent = wrap
    body.AutomaticSize = Enum.AutomaticSize.Y
    local bl = Instance.new("UIListLayout", body)
    bl.Padding = UDim.new(0, 6)
    bl.SortOrder = Enum.SortOrder.LayoutOrder

    local open = true
    header.MouseButton1Click:Connect(function()
        open = not open
        body.Visible = open
        header.Text = (open and "▾  " or "▸  ") .. string.upper(text)
    end)
    return body
end

local function makeTextBox(parent, placeholder, default)
    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, 0, 0, 34)
    tb.BackgroundColor3 = C.panel
    tb.BorderSizePixel = 0
    tb.Text = default or ""
    tb.PlaceholderText = placeholder
    tb.PlaceholderColor3 = C.textDim
    tb.TextColor3 = C.text
    tb.TextSize = 12
    tb.Font = FONT_MED
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.ClearTextOnFocus = false
    tb.Parent = parent
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", tb)
    s.Color = C.goldDark; s.Thickness = 1; s.Transparency = 0.5
    local p = Instance.new("UIPadding", tb)
    p.PaddingLeft = UDim.new(0, 10)
    return tb
end

-- ===================== HELPER =====================
local function getChar()
    return player.Character or player.CharacterAdded:Wait()
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local store = {}
local function reg(id, obj, kind)
    store[id] = { obj = obj, kind = kind }
end

-- ===================== TAB BUTTONS =====================
local tabButtons = {}
local function switchTab(name)
    if currentTabName == name then return end
    currentTabName = name
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabButtons) do
        if n == name then
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.panelHi}):Play()
            b.TextColor3 = C.goldSoft
        else
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.sidebar}):Play()
            b.TextColor3 = C.textDim
        end
    end
    contentTitle.Text = name
    scroll.CanvasPosition = Vector2.new(0, 0)
end

local tabIcons = {
    Movement = "◈", Visual = "◉", Utility = "⚙", Misc = "✦", Config = "⚑",
}
for i, name in ipairs(pageOrder) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 32)
    b.BackgroundColor3 = C.sidebar
    b.BorderSizePixel = 0
    b.Text = "  " .. (tabIcons[name] or "•") .. "   " .. name
    b.TextColor3 = C.textDim
    b.TextSize = 12
    b.Font = FONT_MED
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.LayoutOrder = i
    b.Parent = tabList
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() switchTab(name) end)
    tabButtons[name] = b
end

-- ===================== MOVEMENT =====================
local pMov = pages["Movement"]

local secSpeed = makeSection(pMov, "Kecepatan")
local sprintActive = false
local speedSlider = makeSlider(secSpeed, "WalkSpeed", 16, 200, 16, function(v)
    local h = getHum(); if h and not sprintActive then h.WalkSpeed = v end
end)
reg("WalkSpeed", speedSlider, "slider")

local jumpSlider = makeSlider(secSpeed, "JumpPower", 50, 300, 50, function(v)
    local h = getHum()
    if h then h.UseJumpPower = true; h.JumpPower = v end
end)
reg("JumpPower", jumpSlider, "slider")

local sprintSpeed = 60
local sprintKey = Enum.KeyCode.LeftShift
local sprintConn, sprintEndConn
local sprintToggle = makeToggle(secSpeed, "Sprint Toggle (" .. sprintKey.Name .. ")", false, function(on)
    sprintActive = on
    if on then
        sprintConn = UserInputService.InputBegan:Connect(function(i, gp)
            if gp then return end
            if i.KeyCode == sprintKey then
                local h = getHum(); if h then h.WalkSpeed = sprintSpeed end
            end
        end)
        sprintEndConn = UserInputService.InputEnded:Connect(function(i)
            if i.KeyCode == sprintKey then
                local h = getHum(); if h then h.WalkSpeed = speedSlider.get() end
            end        end)
    else
        if sprintConn then sprintConn:Disconnect(); sprintConn = nil end
        if sprintEndConn then sprintEndConn:Disconnect(); sprintEndConn = nil end
        local h = getHum(); if h then h.WalkSpeed = speedSlider.get() end
    end
end)
reg("Sprint", sprintToggle, "toggle")

makeSlider(secSpeed, "Sprint Speed", 30, 200, 60, function(v) sprintSpeed = v end)

local secFly = makeSection(pMov, "Terbang")
local flyActive = false
local flySpeed = 60
local flyBV, flyBG, flyConn
local flyDir = Vector3.zero

local function stopFly()
    flyActive = false
    flyDir = Vector3.zero
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local h = getHum(); if h then h.PlatformStand = false end
end

local flyToggle
local function startFly()
    local char = getChar()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local h = getHum()
    if not hrp or not h then toast("Fly gagal: karakter belum ada"); return end
    h.PlatformStand = true
    flyActive = true
    flyDir = Vector3.zero
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 1000; flyBG.D = 50
    flyBG.Parent = hrp
    flyConn = RunService.RenderStepped:Connect(function()
        if not flyActive then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        flyBG.CFrame = cam.CFrame
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
        move += flyDir
        if move.Magnitude > 0 then move = move.Unit end
        flyBV.Velocity = move * flySpeed
    end)
end

flyToggle = makeToggle(secFly, "Fly", false, function(on)
    if on then startFly() else stopFly() end
end)
reg("Fly", flyToggle, "toggle")

makeSlider(secFly, "Fly Speed", 20, 200, 60, function(v) flySpeed = v end)

local flyPad = Instance.new("Frame")
flyPad.Size = UDim2.new(1, 0, 0, 110)
flyPad.BackgroundColor3 = C.panel
flyPad.BorderSizePixel = 0
flyPad.Parent = secFly
Instance.new("UICorner", flyPad).CornerRadius = UDim.new(0, 6)
local fpStroke = Instance.new("UIStroke", flyPad)
fpStroke.Color = C.goldDark; fpStroke.Thickness = 1; fpStroke.Transparency = 0.5
applyGoldGradient(fpStroke)

local function flyBtn(text, pos, dirFn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(46, 46)
    b.Position = pos
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.BackgroundColor3 = C.panelHi
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = C.goldSoft
    b.TextSize = 18
    b.Font = FONT_MED
    b.AutoButtonColor = false
    b.Parent = flyPad
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    local s = Instance.new("UIStroke", b)
    s.Color = C.goldDark; s.Thickness = 1
    b.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            flyDir += dirFn()
            b.BackgroundColor3 = C.gold; b.TextColor3 = C.bg
        end
    end)
    b.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            flyDir -= dirFn()
            b.BackgroundColor3 = C.panelHi; b.TextColor3 = C.goldSoft
        end
    end)
end

local camFn = function() return workspace.CurrentCamera.CFrame end
flyBtn("↑", UDim2.new(0.5, 0, 0, 32), function() return camFn().LookVector end)
flyBtn("↓", UDim2.new(0.5, 0, 0, 82), function() return -camFn().LookVector end)
flyBtn("←", UDim2.new(0.5, -60, 0.5, 0), function() return -camFn().RightVector end)
flyBtn("→", UDim2.new(0.5, 60, 0.5, 0), function() return camFn().RightVector end)

local upBtn = Instance.new("TextButton")
upBtn.Size = UDim2.fromOffset(38, 26)
upBtn.Position = UDim2.new(1, -46, 0, 8)
upBtn.BackgroundColor3 = C.panelHi
upBtn.BorderSizePixel = 0
upBtn.Text = "Naik"
upBtn.TextColor3 = C.goldSoft
upBtn.TextSize = 10
upBtn.Font = FONT_MED
upBtn.Parent = flyPad
Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 5)

local downBtn = Instance.new("TextButton")
downBtn.Size = UDim2.fromOffset(38, 26)
downBtn.Position = UDim2.new(1, -46, 1, -34)
downBtn.BackgroundColor3 = C.panelHi
downBtn.BorderSizePixel = 0
downBtn.Text = "Turun"
downBtn.TextColor3 = C.goldSoft
downBtn.TextSize = 10
downBtn.Font = FONT_MED
downBtn.Parent = flyPad
Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 5)

upBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then flyDir += Vector3.new(0,1,0) end
end)
upBtn.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then flyDir -= Vector3.new(0,1,0) end
end)
downBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then flyDir -= Vector3.new(0,1,0) end
end)
downBtn.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then flyDir += Vector3.new(0,1,0) end
end)

local secNoclip = makeSection(pMov, "Noclip")
local noclipActive = false
local noclipConn
local function startNoclip()
    noclipActive = true
    noclipConn = RunService.Stepped:Connect(function()
        if not noclipActive then return end
        local char = player.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end)
end
local function stopNoclip()
    noclipActive = false
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
end
local noclipToggle = makeToggle(secNoclip, "Noclip", false, function(on)
    if on then startNoclip() else stopNoclip() end
end)
reg("Noclip", noclipToggle, "toggle")

-- ===================== VISUAL =====================
local pVis = pages["Visual"]

local secInfo = makeSection(pVis, "Info")
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(1, 0, 0, 24)
fpsLabel.BackgroundColor3 = C.panel
fpsLabel.BorderSizePixel = 0
fpsLabel.Text = "  FPS: —"
fpsLabel.TextColor3 = C.textDim
fpsLabel.TextSize = 11
fpsLabel.Font = FONT_MED
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.Parent = secInfo
Instance.new("UICorner", fpsLabel).CornerRadius = UDim.new(0, 6)

local fpsFrames = 0
local fpsTime = tick()
local fpsToggle = makeToggle(secInfo, "FPS Display", false, function(on)
    _G._VK_FPS_ON = on
    fpsLabel.Visible = on
end)
reg("FPSDisplay", fpsToggle, "toggle")

local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(1, 0, 0, 24)
pingLabel.BackgroundColor3 = C.panel
pingLabel.BorderSizePixel = 0
pingLabel.Text = "  Ping: —"
pingLabel.TextColor3 = C.textDim
pingLabel.TextSize = 11
pingLabel.Font = FONT_MED
pingLabel.TextXAlignment = Enum.TextXAlignment.Left
pingLabel.Parent = secInfo
Instance.new("UICorner", pingLabel).CornerRadius = UDim.new(0, 6)
local pingToggle = makeToggle(secInfo, "Ping Display", false, function(on)
    _G._VK_PING_ON = on
    pingLabel.Visible = on
end)
reg("PingDisplay", pingToggle, "toggle")

RunService.RenderStepped:Connect(function()
    if _G._VK_FPS_ON then
        fpsFrames += 1
        local now = tick()
        if now - fpsTime >= 1 then
            fpsLabel.Text = string.format("  FPS: %d", fpsFrames)
            fpsFrames = 0
            fpsTime = now
        end
    end
end)
RunService.Heartbeat:Connect(function()
    if not _G._VK_PING_ON then return end
    local ok, ping = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and ping then
        pingLabel.Text = string.format("  Ping: %d ms", math.floor(ping))
    end
end)

local secESP = makeSection(pVis, "ESP Player")
local espActive = false
local espFolder
local espConns = {}
local espNameActive = true
local espDistance = false
local espHealthActive = false
local espLabels = {}

local function clearESP()
    for _, c in ipairs(espConns) do c:Disconnect() end
    espConns = {}
    if espFolder then espFolder:Destroy() end
    espLabels = {}
end

local function addESP(plr)
    if not espFolder or not plr.Character then return end
    local head = plr.Character:FindFirstChild("Head")
        or plr.Character:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local hl = Instance.new("Highlight")
    hl.Name = "V_hl_" .. plr.Name
    hl.Adornee = plr.Character
    hl.FillColor = C.gold
    hl.OutlineColor = C.goldSoft
    hl.FillTransparency = 0.55
    hl.Parent = espFolder

    local bb = Instance.new("BillboardGui")
    bb.Name = "V_bb_" .. plr.Name
    bb.Adornee = head
    bb.Size = UDim2.fromOffset(200, 70)
    bb.StudsOffset = Vector3.new(0, 2.6, 0)
    bb.AlwaysOnTop = true
    bb.Parent = espFolder

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0, 20)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = C.goldSoft
    nameLbl.TextSize = 13
    nameLbl.Font = FONT_BOLD
    nameLbl.TextStrokeTransparency = 0.3
    nameLbl.Text = plr.Name
    nameLbl.Visible = espNameActive
    nameLbl.Parent = bb

    local distLbl = Instance.new("TextLabel")
    distLbl.Size = UDim2.new(1, 0, 0, 16)
    distLbl.Position = UDim2.new(0, 0, 0, 20)
    distLbl.BackgroundTransparency = 1
    distLbl.TextColor3 = C.textDim
    distLbl.TextSize = 10
    distLbl.Font = FONT_BODY
    distLbl.TextStrokeTransparency = 0.3
    distLbl.Text = ""
    distLbl.Visible = espDistance
    distLbl.Parent = bb

    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(1, -20, 0, 4)
    hpBg.Position = UDim2.new(0, 10, 0, 38)
    hpBg.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
    hpBg.BorderSizePixel = 0
    hpBg.Visible = espHealthActive
    hpBg.Parent = bb
    Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)

    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = C.green
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBg
    Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)

    espLabels[plr] = { name = nameLbl, dist = distLbl, hpBg = hpBg, hpFill = hpFill }
end

local function startESP()
    espActive = true
    espFolder = Instance.new("Folder", screenGui)
    espFolder.Name = "ValkrieESP"
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then addESP(plr) end
    end
    table.insert(espConns, Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(0.5)
            if espActive then addESP(plr) end
        end)
    end))
end

local espPlayerToggle = makeToggle(secESP, "ESP Player", false, function(on)
    if on then startESP() else espActive = false; clearESP() end
end)
reg("ESPPlayer", espPlayerToggle, "toggle")

makeToggle(secESP, "ESP Username", true, function(on)
    espNameActive = on
    for _, l in pairs(espLabels) do
        if l.name then l.name.Visible = on end
    end
end)

makeToggle(secESP, "ESP Distance", false, function(on)
    espDistance = on
    for _, l in pairs(espLabels) do
        if l.dist then l.dist.Visible = on end
    end
end)

makeToggle(secESP, "ESP Health Bar", false, function(on)
    espHealthActive = on
    for _, l in pairs(espLabels) do
        if l.hpBg then l.hpBg.Visible = on end
    end
end)

RunService.RenderStepped:Connect(function()
    if not espActive then return end
    local hrp = getHRP()
    if not hrp then return end
    for plr, lbls in pairs(espLabels) do
        if lbls.name and espNameActive and lbls.name.Text ~= plr.Name then
            lbls.name.Text = plr.Name
        end
        if lbls.dist and espDistance then
            local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if tHrp then
                lbls.dist.Text = string.format("%d stud",
                    math.floor((tHrp.Position - hrp.Position).Magnitude))
            else
                lbls.dist.Text = "?"
            end
        end
        if lbls.hpFill and espHealthActive then
            local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                lbls.hpFill.Size = UDim2.new(pct, 0, 1, 0)
                lbls.hpFill.BackgroundColor3 = Color3.fromRGB(
                    math.floor(200 * (1 - pct) + 60),
                    math.floor(60 + 140 * pct),
                    60)
            end
        end
    end
end)

local secItem = makeSection(pVis, "ESP Item")
local itemFolder
local itemConns = {}
local espItemActive = false
local espItemNameActive = false

local function clearItemESP()
    for _, c in ipairs(itemConns) do c:Disconnect() end
    itemConns = {}
    if itemFolder then itemFolder:Destroy() end
end

local function isItemLike(part)
    if not part:IsA("BasePart") then return false end
    local n = string.lower(part.Name)
    return (n:find("coin") or n:find("gem") or n:find("item") or n:find("egg")
         or n:find("collect") or n:find("pickup") or n:find("chest")) ~= nil
end

local function attachItemESP(part)
    if not itemFolder or not part:IsA("BasePart") then return end
    local key = part.Name .. "_" .. part:GetDebugId()
    if itemFolder:FindFirstChild(key) then return end
    local hl = Instance.new("Highlight")
    hl.Name = key
    hl.Adornee = part
    hl.FillColor = C.goldSoft
    hl.OutlineColor = C.gold
    hl.FillTransparency = 0.6
    hl.Parent = itemFolder
    if espItemNameActive then
        local bb = Instance.new("BillboardGui")
        bb.Name = "bb_" .. key
        bb.Adornee = part
        bb.Size = UDim2.fromOffset(120, 20)
        bb.StudsOffset = Vector3.new(0, 1, 0)
        bb.AlwaysOnTop = true
        bb.Parent = itemFolder
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.fromScale(1, 1)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = C.goldSoft
        lbl.TextSize = 11
        lbl.Font = FONT_BOLD
        lbl.TextStrokeTransparency = 0.4
        lbl.Text = part.Name
        lbl.Parent = bb
    end
end

local espItemToggle = makeToggle(secItem, "ESP Item", false, function(on)
    espItemActive = on
    if on then
        itemFolder = Instance.new("Folder", screenGui)
        itemFolder.Name = "ValkrieItems"
        for _, d in ipairs(workspace:GetDescendants()) do
            if isItemLike(d) then attachItemESP(d) end
        end
        table.insert(itemConns, workspace.DescendantAdded:Connect(function(d)
            if espItemActive and isItemLike(d) then
                task.wait(0.2)
                if espItemActive then attachItemESP(d) end
            end
        end))
    else
        clearItemESP()
    end
end)
reg("ESPItem", espItemToggle, "toggle")

makeToggle(secItem, "ESP Item Name", false, function(on)
    espItemNameActive = on
    if espItemActive then
        clearItemESP()
        espItemActive = false
        task.wait(0.05)
        espItemToggle.set(true)
    end
end)

local secLight = makeSection(pVis, "Lighting")
local oldB, oldOA, oldA, oldFE, oldFS
local fullbrightToggle = makeToggle(secLight, "Fullbright", false, function(on)
    if on then
        oldB = Lighting.Brightness; oldOA = Lighting.OutdoorAmbient; oldA = Lighting.Ambient
        Lighting.Brightness = 3
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
    else
        Lighting.Brightness = oldB or 2
        Lighting.OutdoorAmbient = oldOA or Color3.fromRGB(128, 128, 128)
        Lighting.Ambient = oldA or Color3.fromRGB(128, 128, 128)
    end
end)
reg("Fullbright", fullbrightToggle, "toggle")

local noFogToggle = makeToggle(secLight, "No Fog", false, function(on)
    if on then
        oldFE = Lighting.FogEnd; oldFS = Lighting.FogStart
        Lighting.FogEnd = 1e6; Lighting.FogStart = 1e6
    else
        Lighting.FogEnd = oldFE or 100000
        Lighting.FogStart = oldFS or 0
    end
end)
reg("NoFog", noFogToggle, "toggle")

local camUnlockActive = false
local camUnlockConn
local camUnlockToggle = makeToggle(secLight, "Camera Unlock", false, function(on)
    camUnlockActive = on
    if on then
        local cam = workspace.CurrentCamera
        cam.CameraType = Enum.CameraType.Scriptable
        camUnlockConn = UserInputService.InputChanged:Connect(function(i)
            if not camUnlockActive then return end
            if i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch then
                local delta = i.Delta
                cam.CFrame = cam.CFrame
                    * CFrame.Angles(0, math.rad(-delta.X * 0.3), 0)
                    * CFrame.Angles(math.rad(-delta.Y * 0.3), 0, 0)
            end
        end)
    else
        if camUnlockConn then camUnlockConn:Disconnect(); camUnlockConn = nil end
        local cam = workspace.CurrentCamera
        cam.CameraType = Enum.CameraType.Custom
        local h = getHum()
        if h then cam.CameraSubject = h end
    end
end)
reg("CameraUnlock", camUnlockToggle, "toggle")

-- ===================== UTILITY =====================
local pUtil = pages["Utility"]

local secAFK = makeSection(pUtil, "Sesi")
local antiAfkActive = false
local antiAfkConn
local antiAfkToggle = makeToggle(secAFK, "Anti-AFK", false, function(on)
    antiAfkActive = on
    if on then
        antiAfkConn = player.Idled:Connect(function()
            if not antiAfkActive then return end
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    else
        if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
    end
end)
reg("AntiAFK", antiAfkToggle, "toggle")

local autoRejoinToggle = makeToggle(secAFK, "Auto-Rejoin", false, function(on)
    if on then
        _G._VK_REJOIN = game:GetService("Players").PlayerRemoving:Connect(function(plr)
            if plr == player then
                task.wait(1)
                pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
            end
        end)
    else
        if _G._VK_REJOIN then _G._VK_REJOIN:Disconnect(); _G._VK_REJOIN = nil end
    end
end)
reg("AutoRejoin", autoRejoinToggle, "toggle")

local secServer = makeSection(pUtil, "Server")
local serverInfoLabel = Instance.new("TextLabel")
serverInfoLabel.Size = UDim2.new(1, 0, 0, 40)
serverInfoLabel.BackgroundColor3 = C.panel
serverInfoLabel.BorderSizePixel = 0
serverInfoLabel.Text = string.format("  JobId: %s\n  PlaceId: %d",
    string.sub(game.JobId, 1, 20) .. "...", game.PlaceId)
serverInfoLabel.TextColor3 = C.textDim
serverInfoLabel.TextSize = 10
serverInfoLabel.Font = FONT_BODY
serverInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
serverInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
serverInfoLabel.Parent = secServer
Instance.new("UICorner", serverInfoLabel).CornerRadius = UDim.new(0, 6)
local sip = Instance.new("UIPadding", serverInfoLabel)
sip.PaddingTop = UDim.new(0, 6)
sip.PaddingLeft = UDim.new(0, 10)

makeButton(secServer, "Copy JobId", function()
    pcall(function() setclipboard(game.JobId) end)
    toast("JobId dicopy")
end)

makeButton(secServer, "Auto Find Server Sepi (min 1)", function()
    toast("Mencari server sepi...")
    local ok = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId
            .. "/servers/Public?sortOrder=Asc&limit=100"
        local data = HttpService:JSONDecode(game:HttpGet(url))
        local best, bestCount = nil, math.huge
        for _, s in ipairs(data.data or {}) do
            if s.playing >= 1 and s.playing < s.maxPlayers
                and s.id ~= game.JobId and s.playing < bestCount then
                best, bestCount = s.id, s.playing
            end
        end
        if best then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, best, player)
            toast(string.format("Hop ke server %d player", bestCount))
        else
            toast("Nggak ada server sepi")
        end
    end)
    if not ok then toast("Server hop gagal") end
end)

local hideUIToggle = makeToggle(secAFK, "Hide UI (Ctrl kanan balikin)", false, function(on)
    if on then
        main.Visible = false
        iconFrame.Visible = true
        toast("UI disembunyikan")
    else
        main.Visible = true
        iconFrame.Visible = false
    end
end)
reg("HideUI", hideUIToggle, "toggle")

-- Auto Collect
local secCollect = makeSection(pUtil, "Auto Collect")
local autoCollectActive = false
local autoCollectRadius = 50
local autoCollectSpeed = 80
local autoCollectConn
local autoCollectTarget = nil
local blacklist = {}

local function isBlacklisted(part)
    return blacklist[part.Name] == true
end

local function addBlacklist(name)
    if not name or name == "" then return end
    blacklist[name] = true
end

local function nearestItem()
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestDist = nil, autoCollectRadius
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") and isItemLike(d) and not isBlacklisted(d) then
            local dist = (d.Position - hrp.Position).Magnitude
            if dist < bestDist then best, bestDist = d, dist end
        end
    end
    return best, bestDist
end

local function startAutoCollect()
    autoCollectActive = true
    autoCollectConn = RunService.Heartbeat:Connect(function()
        if not autoCollectActive then return end
        local hrp = getHRP()
        if not hrp then return end
        if not autoCollectTarget or not autoCollectTarget.Parent then
            autoCollectTarget = nearestItem()
        end
        if autoCollectTarget then
            local dir = (autoCollectTarget.Position - hrp.Position)
            local dist = dir.Magnitude
            if dist < 4 then
                addBlacklist(autoCollectTarget.Name)
                autoCollectTarget = nil
            else
                local step = math.min(autoCollectSpeed * (1/60), dist)
                hrp.CFrame = hrp.CFrame + dir.Unit * step
            end
        end
    end)
end

local function stopAutoCollect()
    autoCollectActive = false
    if autoCollectConn then autoCollectConn:Disconnect(); autoCollectConn = nil end
    autoCollectTarget = nil
end

local autoCollectToggle = makeToggle(secCollect, "Auto Collect Item", false, function(on)
    if on then startAutoCollect() else stopAutoCollect() end
end)
reg("AutoCollect", autoCollectToggle, "toggle")

makeSlider(secCollect, "Radius", 10, 300, 50, function(v) autoCollectRadius = v end)
makeSlider(secCollect, "Kecepatan", 20, 300, 80, function(v) autoCollectSpeed = v end)

-- ===================== MISC =====================
local pMisc = pages["Misc"]
local secReset = makeSection(pMisc, "Reset")
makeButton(secReset, "Reset Karakter", function()
    local h = getHum(); if h then h.Health = 0 end
end, true)

makeButton(secReset, "Reset Semua Fitur", function()
    for _, s in pairs(store) do
        if s.kind == "toggle" and s.obj.get and s.obj.get() then
            s.obj.set(false)
        end
    end
    stopFly(); stopNoclip(); stopAutoCollect()
    toast("Semua fitur direset")
end)

local secAbout = makeSection(pMisc, "About")
local aboutLabel = Instance.new("TextLabel")
aboutLabel.Size = UDim2.new(1, 0, 0, 50)
aboutLabel.BackgroundColor3 = C.panel
aboutLabel.BorderSizePixel = 0
aboutLabel.Text = "  Valkrie v7\n  Layout: Redz · Tema: Emas Gradasi\n  Game: " .. currentGameKey
aboutLabel.TextColor3 = C.textDim
aboutLabel.TextSize = 10
aboutLabel.Font = FONT_BODY
aboutLabel.TextXAlignment = Enum.TextXAlignment.Left
aboutLabel.TextYAlignment = Enum.TextYAlignment.Top
aboutLabel.Parent = secAbout
Instance.new("UICorner", aboutLabel).CornerRadius = UDim.new(0, 6)
local apad = Instance.new("UIPadding", aboutLabel)
apad.PaddingTop = UDim.new(0, 6)
apad.PaddingLeft = UDim.new(0, 10)

-- ===================== CONFIG TAB =====================
local pCfg = pages["Config"]
local secSave = makeSection(pCfg, "Simpan Konfigurasi")

local cfgNameBox = makeTextBox(secSave, "Nama konfigurasi (misal: BloxFruits)", currentGameKey)

local function refreshConfigList() end
local function refreshBlacklist() end

makeButton(secSave, "Simpan Konfigurasi", function()
    local name = cfgNameBox.Text
    if name == "" then toast("Nama konfigurasi kosong"); return end
    local values = {}
    for id, s in pairs(store) do
        if (s.kind == "slider" or s.kind == "toggle") and s.obj.get then
            values[id] = s.obj.get()
        end
    end
    saveConfig(name, values, blacklist)
    setAutoloadName(name)
    toast("Konfigurasi disimpan: " .. name)
    refreshConfigList()
end)

local secLoad = makeSection(pCfg, "Muat Konfigurasi")
local configListFrame = Instance.new("Frame")
configListFrame.Size = UDim2.new(1, 0, 0, 0)
configListFrame.BackgroundTransparency = 1
configListFrame.AutomaticSize = Enum.AutomaticSize.Y
configListFrame.Parent = secLoad
local clLayout = Instance.new("UIListLayout", configListFrame)
clLayout.Padding = UDim.new(0, 4)
clLayout.SortOrder = Enum.SortOrder.LayoutOrder

refreshConfigList = function()
    for _, c in ipairs(configListFrame:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    local list = listConfigs()
    if #list == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  (belum ada konfigurasi)"
        lbl.TextColor3 = C.textDim
        lbl.TextSize = 10
        lbl.Font = FONT_BODY
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = configListFrame
        return
    end
    for _, name in ipairs(list) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundColor3 = C.panel
        row.BorderSizePixel = 0
        row.Parent = configListFrame
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -140, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = C.text
        lbl.TextSize = 11
        lbl.Font = FONT_MED
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local lb = Instance.new("TextButton")
        lb.Size = UDim2.fromOffset(56, 24)
        lb.Position = UDim2.new(1, -124, 0.5, -12)
        lb.BackgroundColor3 = C.gold
        lb.BorderSizePixel = 0
        lb.Text = "Load"
        lb.TextColor3 = C.bg
        lb.TextSize = 10
        lb.Font = FONT_BOLD
        lb.Parent = row
        Instance.new("UICorner", lb).CornerRadius = UDim.new(0, 5)
        lb.MouseButton1Click:Connect(function()
            local cfg = loadConfig(name)
            if not cfg then toast("Konfigurasi gagal dimuat"); return end
            for id, val in pairs(cfg.values or {}) do
                if store[id] and store[id].obj.set then store[id].obj.set(val) end
            end
            blacklist = cfg.blacklist or {}
            setAutoloadName(name)
            toast("Dimuat: " .. name)
            refreshConfigList()
            refreshBlacklist()
        end)

        local db = Instance.new("TextButton")
        db.Size = UDim2.fromOffset(56, 24)
        db.Position = UDim2.new(1, -62, 0.5, -12)
        db.BackgroundColor3 = Color3.fromRGB(45, 24, 20)
        db.BorderSizePixel = 0
        db.Text = "Hapus"
        db.TextColor3 = Color3.fromRGB(240, 180, 170)
        db.TextSize = 10
        db.Font = FONT_BOLD
        db.Parent = row
        Instance.new("UICorner", db).CornerRadius = UDim.new(0, 5)
        db.MouseButton1Click:Connect(function()
            deleteConfig(name)
            toast("Dihapus: " .. name)
            refreshConfigList()
        end)
    end
end

makeToggle(secLoad, "Auto-Load Config saat execute", true, function(on)
    _G._VK_AUTOLOAD = on
end)

local secBL = makeSection(pCfg, "Blacklist Item (per konfigurasi)")
local blFrame = Instance.new("Frame")
blFrame.Size = UDim2.new(1, 0, 0, 0)
blFrame.BackgroundTransparency = 1
blFrame.AutomaticSize = Enum.AutomaticSize.Y
blFrame.Parent = secBL
local blLayout = Instance.new("UIListLayout", blFrame)
blLayout.Padding = UDim.new(0, 4)
blLayout.SortOrder = Enum.SortOrder.LayoutOrder

refreshBlacklist = function()
    for _, c in ipairs(blFrame:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    local count = 0
    for name, _ in pairs(blacklist) do
        count += 1
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = C.panel
        row.BorderSizePixel = 0
        row.Parent = blFrame
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = C.text
        lbl.TextSize = 11
        lbl.Font = FONT_BODY
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row
        local xb = Instance.new("TextButton")
        xb.Size = UDim2.fromOffset(48, 22)
        xb.Position = UDim2.new(1, -54, 0.5, -11)
        xb.BackgroundColor3 = Color3.fromRGB(45, 24, 20)
        xb.BorderSizePixel = 0
        xb.Text = "Hapus"
        xb.TextColor3 = Color3.fromRGB(240, 180, 170)
        xb.TextSize = 10
        xb.Font = FONT_BOLD
        xb.Parent = row
        Instance.new("UICorner", xb).CornerRadius = UDim.new(0, 5)
        xb.MouseButton1Click:Connect(function()
            blacklist[name] = nil
            toast("Hapus blacklist: " .. name)
            refreshBlacklist()
        end)
    end
    if count == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  (belum ada item di-blacklist)"
        lbl.TextColor3 = C.textDim
        lbl.TextSize = 10
        lbl.Font = FONT_BODY
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = blFrame
    end
end

makeButton(secBL, "Clear All Blacklist", function()
    blacklist = {}
    refreshBlacklist()
    toast("Blacklist dikosongkan")
end, true)

-- ===================== MINIMIZE / CLOSE =====================
local iconFrame = Instance.new("TextButton")
iconFrame.Size = UDim2.fromOffset(54, 54)
iconFrame.Position = UDim2.new(0, 16, 0, 16)
iconFrame.BackgroundColor3 = C.panel
iconFrame.BorderSizePixel = 0
iconFrame.Text = ""
iconFrame.Visible = false
iconFrame.ZIndex = 100
iconFrame.Parent = screenGui
Instance.new("UICorner", iconFrame).CornerRadius = UDim.new(1, 0)
local iconStroke = Instance.new("UIStroke", iconFrame)
iconStroke.Color = C.gold
iconStroke.Thickness = 2
iconStroke.ZIndex = 100
applyGoldGradient(iconStroke)
local iconImg = Instance.new("ImageLabel")
iconImg.Size = UDim2.fromScale(0.7, 0.7)
iconImg.Position = UDim2.fromScale(0.15, 0.15)
iconImg.BackgroundTransparency = 1
iconImg.Image = CROWN_IMAGE_ID
iconImg.ZIndex = 101
iconImg.Parent = iconFrame

local isMinimized = false
local function setMinimized(v)
    isMinimized = v
    main.Visible = not v
    iconFrame.Visible = v
end

minimizeBtn.MouseButton1Click:Connect(function()
    setMinimized(true)
    toast("Valkrie diminimize — klik mahkota")
end)
iconFrame.MouseButton1Click:Connect(function()
    setMinimized(false)
    toast("Valkrie dibuka")
end)

local iconDrag, iconStart, iconStartPos
iconFrame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
        iconDrag = true
        iconStart = i.Position
        iconStartPos = iconFrame.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then iconDrag = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not iconDrag then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - iconStart
        iconFrame.Position = UDim2.new(
            iconStartPos.X.Scale, iconStartPos.X.Offset + d.X,
            iconStartPos.Y.Scale, iconStartPos.Y.Offset + d.Y)
    end
end)

local confirmOverlay = Instance.new("Frame")
confirmOverlay.Size = UDim2.new(1, 0, 1, 0)
confirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
confirmOverlay.BackgroundTransparency = 0.45
confirmOverlay.BorderSizePixel = 0
confirmOverlay.Visible = false
confirmOverlay.ZIndex = 300
confirmOverlay.Parent = screenGui
local confirmBox = Instance.new("Frame")
confirmBox.Size = UDim2.fromOffset(300, 160)
confirmBox.Position = UDim2.new(0.5, 0, 0.5, 0)
confirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
confirmBox.BackgroundColor3 = C.panel
confirmBox.BorderSizePixel = 0
confirmBox.ZIndex = 301
confirmBox.Parent = confirmOverlay
Instance.new("UICorner", confirmBox).CornerRadius = UDim.new(0, 10)
local cbs = Instance.new("UIStroke", confirmBox)
cbs.Color = C.gold; cbs.Thickness = 1.5; cbs.ZIndex = 301
applyGoldGradient(cbs)

local ct = Instance.new("TextLabel")
ct.Size = UDim2.new(1, -20, 0, 30)
ct.Position = UDim2.new(0, 10, 0, 14)
ct.BackgroundTransparency = 1
ct.Text = "Tutup Valkrie?"
ct.TextColor3 = C.goldSoft
ct.TextSize = 16
ct.Font = FONT_BOLD
ct.ZIndex = 302
ct.Parent = confirmBox

local cd = Instance.new("TextLabel")
cd.Size = UDim2.new(1, -20, 0, 40)
cd.Position = UDim2.new(0, 10, 0, 48)
cd.BackgroundTransparency = 1
cd.Text = "UI disembunyikan. Ctrl kanan untuk buka."
cd.TextColor3 = C.textDim
cd.TextSize = 11
cd.Font = FONT_BODY
cd.TextWrapped = true
cd.ZIndex = 302
cd.Parent = confirmBox

local yesB = Instance.new("TextButton")
yesB.Size = UDim2.fromOffset(120, 34)
yesB.Position = UDim2.new(0, 16, 1, -50)
yesB.BackgroundColor3 = Color3.fromRGB(50, 26, 22)
yesB.BorderSizePixel = 0
yesB.Text = "Ya, tutup"
yesB.TextColor3 = Color3.fromRGB(240, 180, 170)
yesB.TextSize = 12
yesB.Font = FONT_MED
yesB.ZIndex = 302
yesB.Parent = confirmBox
Instance.new("UICorner", yesB).CornerRadius = UDim.new(0, 6)

local noB = Instance.new("TextButton")
noB.Size = UDim2.fromOffset(120, 34)
noB.Position = UDim2.new(1, -136, 1, -50)
noB.BackgroundColor3 = C.panelHi
noB.BorderSizePixel = 0
noB.Text = "Batal"
noB.TextColor3 = C.goldSoft
noB.TextSize = 12
noB.Font = FONT_MED
noB.ZIndex = 302
noB.Parent = confirmBox
Instance.new("UICorner", noB).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function() confirmOverlay.Visible = true end)
noB.MouseButton1Click:Connect(function() confirmOverlay.Visible = false end)
yesB.MouseButton1Click:Connect(function()
    confirmOverlay.Visible = false
    screenGui.Enabled = false
    toast("UI disembunyikan — Ctrl kanan untuk buka")
end)

-- ===================== RESIZE + DRAG =====================
local resizeHandle = Instance.new("TextButton")
resizeHandle.Size = UDim2.fromOffset(16, 16)
resizeHandle.Position = UDim2.new(1, -16, 1, -16)
resizeHandle.BackgroundColor3 = C.gold
resizeHandle.BorderSizePixel = 0
resizeHandle.Text = ""
resizeHandle.ZIndex = 5
resizeHandle.Parent = main
Instance.new("UICorner", resizeHandle).CornerRadius = UDim.new(0, 4)
applyGoldGradient(resizeHandle)

local hDrag, hStart, hStartSize
resizeHandle.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
        hDrag = true
        hStart = i.Position
        hStartSize = main.AbsoluteSize
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then hDrag = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not hDrag then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - hStart
        main.Size = UDim2.fromOffset(
            math.clamp(hStartSize.X + d.X, 480, 2000),
            math.clamp(hStartSize.Y + d.Y, 360, 2000))
    end
end)

local dragging, dragStart, startPos
contentHeader.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos = main.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                  startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ===================== RESPAWN =====================
player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if flyActive then stopFly(); if flyToggle then flyToggle.set(false) end end
    if noclipActive then task.wait(0.2); startNoclip() end
end)

-- ===================== TOGGLE UI =====================
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightControl then
        if isMinimized then setMinimized(false) end
        screenGui.Enabled = not screenGui.Enabled
    end
end)

-- ===================== AUTO-LOAD CONFIG =====================
_G._VK_AUTOLOAD = true
task.spawn(function()
    task.wait(0.5)
    local last = getAutoloadName()
    if last then
        local cfg = loadConfig(last)
        if cfg then
            for id, val in pairs(cfg.values or {}) do
                if store[id] and store[id].obj.set then store[id].obj.set(val) end
            end
            blacklist = cfg.blacklist or {}
            toast("Config auto-load: " .. last)
        end
    end
    refreshConfigList()
    refreshBlacklist()
end)

-- ===================== START =====================
switchTab("Movement")
toast("Valkrie v7 siap — Game: " .. string.sub(currentGameKey, 1, 20))
