local ADDON, ns = ...

-- Rageborn: the settings window (docs/ui/ui-design.md). 860 x 560, drawn from plain frames,
-- solid textures and font strings; coordinates are x, y from the window's top left.
--   rail   General, the alerts the character knows by group, Gallery, Macros, Profiles
--   pages  one frame each over the whole window, built on first use
-- A page lists its controls; Refresh() makes every control re-read its setting, so a
-- control never has to know who else changed it.
local L, U, Data, Styles = ns.L, ns.U, ns.Data, ns.Styles

local Options = {}
ns.Options = Options

local W, H = 860, 560
local function hex(s)
    return { tonumber(s:sub(1, 2), 16) / 255, tonumber(s:sub(3, 4), 16) / 255, tonumber(s:sub(5, 6), 16) / 255 }
end
local C = {
    body = hex("161112"), well = hex("0C090A"), cap = hex("211A1B"), control = hex("2A2021"),
    hover = hex("3A2E30"), rule = hex("4A3536"), quiet = hex("8C7B78"), secondary = hex("C9B9AD"),
    ink = hex("EFE6D6"), ember = hex("D8372B"), emberGround = hex("3A1614"), bar = hex("5C1512"),
}
-- The game's own fonts; the player picks one for headings and one for text.
local FONTS = { { "friz", "Fonts\\FRIZQT__.TTF" }, { "morpheus", "Fonts\\MORPHEUS.TTF" },
                { "skurri", "Fonts\\SKURRI.TTF" }, { "arial", "Fonts\\ARIALN.TTF" } }
local WINDOW_SCALES = { 70, 80, 90, 100, 110, 120, 130 }
local GLOW_KINDS = { "procLoop", "ants", "pulse", "corners" }
local SIDES = { "both", "left", "right" }
local THRESHOLD = { battleShout = { 1, 15, "%d s" }, lowHealth = { 10, 60, "%d%%" }, demoPull = { 2, 6, "%d" },
                    sunder = { 1, 15, "%d s" }, rageDump = { 30, 100, "%d" } }

local win, pages, railRows = nil, {}, {}
local applyWindow

local FONT_FILE, lettered = {}, {}      -- lettered: everything with a font, { object, size, title }
for _, f in ipairs(FONTS) do FONT_FILE[f[1]] = f[2] end
local function fontFile(title)
    local w = ns.DB:Profile().window
    return FONT_FILE[title and w.headFont or w.textFont] or FONT_FILE[title and "friz" or "arial"]
end
local function SetFont(obj, size, title)
    lettered[#lettered + 1] = { obj, size, title }
    obj:SetFont(fontFile(title), size, "")
end
local selected = { page = "general" }

----------------------------------------------------------------------
-- Drawing
----------------------------------------------------------------------
local function At(f, parent, x, y, w, h)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    if w then f:SetSize(w, h) end
    return f
end

local function Fill(f, c, layer)
    local t = f:CreateTexture(nil, layer or "BACKGROUND")
    t:SetAllPoints(f)
    t:SetColorTexture(c[1], c[2], c[3], 1)
    return t
end

-- A 1 px outline inside the frame. Returns a function that recolours it.
local function Border(f, c)
    local sides = {}
    for i, a in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" },
                         { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
        local t = f:CreateTexture(nil, "BORDER")
        t:SetPoint(a[1], f, a[1]); t:SetPoint(a[2], f, a[2])
        if i <= 2 then t:SetHeight(1) else t:SetWidth(1) end
        sides[i] = t
    end
    local function colour(col) for _, t in ipairs(sides) do t:SetColorTexture(col[1], col[2], col[3], 1) end end
    colour(c)
    return colour
end

local function Text(parent, size, c, title)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    SetFont(fs, size, title)
    fs:SetTextColor(c[1], c[2], c[3])
    fs:SetJustifyH("LEFT")
    return fs
end

local function Label(parent, x, y, size, c, text, w, title)
    local fs = Text(parent, size, c, title)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    if w then fs:SetWidth(w); fs:SetWordWrap(true) end
    fs:SetText(text or "")
    return fs
end

local function Rule(parent, x, y, w)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetColorTexture(C.rule[1], C.rule[2], C.rule[3], 1)
    At(t, parent, x, y, w, 1)
    return t
end

-- "APPEARANCE ------------------"
local function Heading(parent, x, y, w, text)
    local f = CreateFrame("Frame", nil, parent)
    At(f, parent, x, y, w, 18)
    local fs = Label(f, 0, 2, 11, C.secondary, (text or ""):upper())
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(C.rule[1], C.rule[2], C.rule[3], 1)
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 12, 0)
    line:SetPoint("RIGHT", f, "RIGHT", 0, 0)
    return f
end

----------------------------------------------------------------------
-- Widgets. Each has Refresh() (re-read the setting) and Able(on).
----------------------------------------------------------------------
local function Button(parent, x, y, w, label, onClick)
    local b = CreateFrame("Button", nil, parent)
    At(b, parent, x, y, w, 26)
    local fill, edge = Fill(b, C.control), Border(b, C.rule)
    b.text = Text(b, 13, C.ink)
    b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.text:SetText(label)
    b.on = true
    local function paint(hot)
        local c = not b.on and C.cap or hot and C.hover or C.control
        fill:SetColorTexture(c[1], c[2], c[3], 1)
        if CreateColor then     -- lit from above, where the client can shade a texture
            pcall(fill.SetGradient, fill, "VERTICAL", CreateColor(c[1] * 0.82, c[2] * 0.82, c[3] * 0.82, 1),
                  CreateColor(c[1] * 1.25, c[2] * 1.25, c[3] * 1.25, 1))
        end
        local t = b.on and C.ink or C.quiet
        b.text:SetTextColor(t[1], t[2], t[3])
    end
    b:SetScript("OnEnter", function() paint(true) end)
    b:SetScript("OnLeave", function() paint(false) end)
    b:SetScript("OnClick", function() if b.on then onClick(b) end end)
    function b.Able(on) b.on = on and true or false; paint(false) end
    function b.Refresh() end
    paint(false)
    return b
end

local function Check(parent, x, y, w, label, get, set)
    local b = CreateFrame("Button", nil, parent)
    At(b, parent, x, y, w, 26)
    local box = CreateFrame("Frame", nil, b)
    At(box, b, 0, 6, 14, 14)
    Fill(box, C.well)
    local edge = Border(box, C.rule)
    local tick = box:CreateTexture(nil, "ARTWORK")
    tick:SetAllPoints(box)
    tick:SetColorTexture(C.ember[1], C.ember[2], C.ember[3], 1)
    local text = Label(b, 22, 6, 13, C.ink, label)
    b.on = true
    b:SetScript("OnEnter", function() edge(C.ink) end)
    b:SetScript("OnLeave", function() edge(C.rule) end)
    b:SetScript("OnClick", function() if b.on then set(not get()) end end)
    function b.Refresh() tick:SetShown(get() and true or false) end
    function b.Able(on)
        b.on = on and true or false
        local t = b.on and C.ink or C.quiet
        text:SetTextColor(t[1], t[2], t[3])
    end
    return b
end

-- get/set work in the units shown (per cent, seconds).
local function Slider(parent, x, y, w, caption, min, max, step, fmt, get, set)
    local f = CreateFrame("Frame", nil, parent)
    At(f, parent, x, y, w, 32)
    Label(f, 0, 0, 11, C.secondary, caption)
    local value = Text(f, 12, C.ink)
    value:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    local s = CreateFrame("Slider", nil, f)
    At(s, f, 0, 18, w, 13)
    s:SetOrientation("HORIZONTAL")
    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(C.control[1], C.control[2], C.control[3], 1)
    track:SetPoint("LEFT", s, "LEFT", 0, 0); track:SetPoint("RIGHT", s, "RIGHT", 0, 0); track:SetHeight(3)
    local thumb = s:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(C.ink[1], C.ink[2], C.ink[3], 1)
    thumb:SetSize(8, 13)
    s:SetThumbTexture(thumb)
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    local quiet, last = false, nil
    s:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v / step + 0.5) * step
        value:SetText(fmt:format(v))
        if quiet or v == last then return end
        last = v
        set(v)
    end)
    function f.Refresh()
        last = math.floor(get() / step + 0.5) * step
        quiet = true
        s:SetValue(last)
        quiet = false
        value:SetText(fmt:format(last))
    end
    function f.Able(on) s:SetEnabled(on and true or false) end
    f.slider = s
    return f
end

-- One popup shared by every dropdown.
local popup
local function OpenPopup(owner, items, current, onPick)
    if not popup then
        local catcher = CreateFrame("Button", nil, win)      -- a click anywhere else closes it
        catcher:SetAllPoints(UIParent)
        catcher:SetFrameStrata("DIALOG"); catcher:SetFrameLevel(100)
        popup = CreateFrame("Frame", nil, win)
        popup:SetFrameStrata("DIALOG"); popup:SetFrameLevel(110)
        Fill(popup, C.well); Border(popup, C.rule)
        popup.rows = {}
        for i = 1, 8 do
            local r = CreateFrame("Button", nil, popup)
            r:SetHeight(24)
            r:SetPoint("TOPLEFT", popup, "TOPLEFT", 4, -4 - (i - 1) * 24)
            r:SetPoint("RIGHT", popup, "RIGHT", -4, 0)
            r.fill = Fill(r, C.well)
            r.text = Text(r, 13, C.ink)
            r.text:SetPoint("LEFT", r, "LEFT", 8, 0)
            r:SetScript("OnEnter", function() r.fill:SetColorTexture(C.hover[1], C.hover[2], C.hover[3], 1) end)
            r:SetScript("OnLeave", function() popup.Draw() end)
            r:SetScript("OnClick", function()
                local pick, item = popup.onPick, r.item
                popup:Hide()
                pick(item.key)
            end)
            popup.rows[i] = r
        end
        function popup.Draw()
            for i, r in ipairs(popup.rows) do
                local item = popup.items[i + popup.offset]
                r:SetShown(item ~= nil)
                if item then
                    r.item = item
                    r.text:SetText(item.label)
                    local c = item.key == popup.current and C.emberGround or C.well
                    r.fill:SetColorTexture(c[1], c[2], c[3], 1)
                end
            end
        end
        popup:EnableMouseWheel(true)
        popup:SetScript("OnMouseWheel", function(_, d)
            popup.offset = math.max(0, math.min(#popup.items - 8, popup.offset - d * (#popup.items > 16 and 4 or 1)))   -- long lists move faster
            popup.Draw()
        end)
        popup:SetScript("OnShow", function() catcher:Show() end)
        popup:SetScript("OnHide", function() catcher:Hide() end)
        catcher:SetScript("OnClick", function() popup:Hide() end)
        popup:Hide(); catcher:Hide()
    end
    if popup:IsShown() and popup.owner == owner then popup:Hide() return end
    popup.owner, popup.items, popup.current, popup.onPick, popup.offset = owner, items, current, onPick, 0
    popup:ClearAllPoints()
    local height = math.min(#items, 8) * 24 + 8
    local bottom, floor = owner:GetBottom(), win:GetBottom()
    -- a dropdown at the foot of the window opens upwards
    if owner.up or (bottom and floor and bottom - floor < height) then
        popup:SetPoint("BOTTOMLEFT", owner, "TOPLEFT", 0, 2)
    else
        popup:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
    end
    popup:SetSize(owner.w, height)
    popup.Draw()
    popup:Show()
end

-- items() -> { { key, label } }
local function Dropdown(parent, x, y, w, items, get, set)
    local b = CreateFrame("Button", nil, parent)
    At(b, parent, x, y, w, 26)
    b.w = w
    local fill = Fill(b, C.control)
    Border(b, C.rule)
    local text = Text(b, 13, C.ink)
    text:SetPoint("LEFT", b, "LEFT", 10, 0); text:SetPoint("RIGHT", b, "RIGHT", -22, 0)
    text:SetWordWrap(false)
    local arrow = Text(b, 10, C.secondary)
    arrow:SetPoint("RIGHT", b, "RIGHT", -9, 0)
    arrow:SetText("v")
    b.on = true
    b:SetScript("OnEnter", function() if b.on then fill:SetColorTexture(C.hover[1], C.hover[2], C.hover[3], 1) end end)
    b:SetScript("OnLeave", function() b.Able(b.on) end)
    b:SetScript("OnClick", function() if b.on then OpenPopup(b, items(), get(), set) end end)
    function b.Refresh()
        local current, shown = get(), ""
        for _, item in ipairs(items()) do if item.key == current then shown = item.label end end
        text:SetText(shown)
    end
    function b.Able(on)
        b.on = on and true or false
        local c, t = b.on and C.control or C.cap, b.on and C.ink or C.quiet
        fill:SetColorTexture(c[1], c[2], c[3], 1)
        text:SetTextColor(t[1], t[2], t[3])
    end
    return b
end

-- get() -> {r, g, b}; set(r, g, b, cancelled). Opens the game's colour wheel; cancel restores.
-- b.onOpen, when set, runs as the wheel opens.
local function Swatch(parent, x, y, label, get, set)
    local b = CreateFrame("Button", nil, parent)
    At(b, parent, x, y, 80, 26)
    Label(b, 0, 6, 13, C.ink, label)
    local chip = CreateFrame("Frame", nil, b)
    At(chip, b, 52, 3, 28, 20)
    local colour = chip:CreateTexture(nil, "ARTWORK")
    colour:SetAllPoints(chip)
    local edge = Border(chip, C.quiet)
    b.on = true
    b:SetScript("OnEnter", function() edge(C.ink) end)
    b:SetScript("OnLeave", function() edge(C.quiet) end)
    b:SetScript("OnClick", function()
        if not (b.on and ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow) then return end
        if b.onOpen then b.onOpen() end
        local c = get()
        local r0, g0, b0 = c.r, c.g, c.b
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r0, g = g0, b = b0, hasOpacity = false,
            swatchFunc = function() set(ColorPickerFrame:GetColorRGB()) end,
            cancelFunc = function() set(r0, g0, b0, true) end,
        })
    end)
    function b.Refresh() local c = get(); colour:SetColorTexture(c.r, c.g, c.b, 1) end
    function b.Able(on) b.on = on and true or false end
    return b
end

local function Input(parent, x, y, w)
    local e = CreateFrame("EditBox", nil, parent)
    At(e, parent, x, y, w, 26)
    Fill(e, C.well)
    local edge = Border(e, C.rule)
    SetFont(e, 13)
    e:SetTextColor(C.ink[1], C.ink[2], C.ink[3])
    e:SetTextInsets(8, 8, 0, 0)
    e:SetAutoFocus(false)
    e:SetMaxLetters(40)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEditFocusGained", function() edge(C.ink) end)
    e:SetScript("OnEditFocusLost", function() edge(C.rule) end)
    return e
end

-- A clipped area scrolled with the mouse wheel, with a thin position mark at its right.
-- Set child.h to the height of what is inside, then call Sync().
local function Scroller(parent, x, y, w, h)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    At(sf, parent, x, y, w, h)
    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(w, h)
    sf:SetScrollChild(child)
    local mark = parent:CreateTexture(nil, "OVERLAY")
    mark:SetColorTexture(C.quiet[1], C.quiet[2], C.quiet[3], 1)
    sf.pos, child.h = 0, h
    function sf.Sync()
        local over = math.max(0, child.h - h)
        sf.pos = math.max(0, math.min(over, sf.pos))
        sf:SetVerticalScroll(sf.pos)
        child:SetHeight(math.max(h, child.h))
        mark:SetShown(over > 0)
        if over > 0 then
            local len = math.max(20, h * h / child.h)
            At(mark, parent, x + w + 4, y + (h - len) * sf.pos / over, 4, len)
        end
    end
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(_, d)
        if popup then popup:Hide() end      -- its dropdown is about to move away under it
        sf.pos = sf.pos - d * 48; sf.Sync()
    end)
    return sf, child
end

-- The game's own yes/no box.
local function Confirm(text, accept, fn)
    StaticPopupDialogs.RAGEBORN_CONFIRM = StaticPopupDialogs.RAGEBORN_CONFIRM or {
        text = "%s", button1 = ACCEPT, button2 = CANCEL, timeout = 0, whileDead = true, hideOnEscape = true,
        OnAccept = function(_, data) data() end,
    }
    StaticPopupDialogs.RAGEBORN_CONFIRM.button1 = accept
    StaticPopup_Show("RAGEBORN_CONFIRM", text, nil, fn)
end

----------------------------------------------------------------------
-- Pages
----------------------------------------------------------------------
local function Page(kicker, title)
    local p = CreateFrame("Frame", nil, win)
    p:SetAllPoints(win)
    p:Hide()
    p.kicker = Label(p, 200, 53, 11, C.secondary, kicker)
    p.title = Label(p, 200, 69, 18, C.ink, title, nil, true)
    p.controls, p.statusY = {}, 461
    function p.Add(control) p.controls[#p.controls + 1] = control; return control end
    function p.Refresh() for _, c in ipairs(p.controls) do c.Refresh() end end
    -- "Info: ..." / "Error: ..." under the controls; nil clears
    local status
    function p.Say(text, isError)
        status = status or Label(p, 200, p.statusY, 13, C.ink, "", 640)
        status:SetText(text and ((isError and L.OPT_ERROR or L.OPT_INFO) .. " " .. text) or "")
    end
    return p
end

local function known(def)
    return def.kind == "lowHealth" or Data.Known(def, ns.Detect.IsKnown) ~= nil
end

-- The alerts this character has, as dropdown items.
local function alertItems()
    local items = {}
    for _, def in ipairs(Data.ALERTS) do
        if known(def) then items[#items + 1] = { key = def.key, label = ns.Alerts:Name(def.key) } end
    end
    return items
end

local function soundItems()
    local items = {}
    for _, s in ipairs(ns.Sounds.LIST) do items[#items + 1] = { key = s.key, label = s.label } end
    return items
end

local function inCombat() return ns.Detect.InCombat() == true end

local function toggleTest()
    ns.testing = not ns.testing
    ns.Engine:Test(ns.testing)
    ns.Engine:Refresh()
end

-- A setting that isn't one alert's changed: every alert on screen re-reads its settings.
local function applyAll()
    for _, def in ipairs(Data.ALERTS) do ns.Alerts:Apply(def.key) end
    ns.Engine:Refresh()
end

local function moveLabel() return ns.Mover:IsOn() and L.OPT_MOVE_DONE or L.OPT_MOVE end

---------------------------------------------------------------- General
local function BuildGeneral()
    local p = Page(L.OPT_SETTINGS, L.OPT_GENERAL)
    local function prof() return ns.DB:Profile() end
    local function flag(name, after)
        return function() return prof()[name] end,
               function(v) prof()[name] = v; if after then after() end; applyAll(); p.Refresh() end
    end

    if ns.BETA then Label(p, 200, 90, 12, C.ember, L.BETA_NOTE, 640):SetWordWrap(false) end
    Heading(p, 200, 106, 640, L.OPT_TRACKING)
    p.Add(Check(p, 200, 130, 300, L.OPT_ENABLE_ADDON, flag("enabled")))
    p.Add(Slider(p, 520, 127, 300, L.OPT_GLOBAL_SCALE, 50, 200, 5, "%d%%",
        function() return prof().scale * 100 end,
        function(v) prof().scale = v / 100; applyAll() end))

    Heading(p, 200, 176, 640, L.OPT_SOUNDS)
    p.Add(Check(p, 200, 200, 300, L.OPT_SOUNDS_ON, flag("sounds")))
    Label(p, 200, 238, 13, C.ink, L.OPT_CRIT_SOUND)
    p.Add(Dropdown(p, 344, 233, 200, soundItems, function() return prof().critSound end,
        function(v) prof().critSound = v; p.Refresh() end))
    local play = p.Add(Button(p, 552, 233, 54, L.OPT_PLAY, function() ns.Sounds.Play(prof().critSound, true) end))
    function play.Refresh() play.Able(prof().critSound ~= "none") end
    Label(p, 200, 266, 12, C.secondary, L.OPT_CRIT_HELP, 630)

    Heading(p, 200, 306, 640, L.OPT_MACRO_BUTTONS)
    p.Add(Check(p, 200, 330, 500, L.OPT_GLOW_MACRO,
        flag("glowEveryMacroSpell", function() if ns.Bars and ns.Bars.Rescan then ns.Bars:Rescan() end end)))
    Label(p, 200, 358, 12, C.secondary, L.OPT_GLOW_MACRO_HELP, 630)

    Heading(p, 200, 398, 640, L.OPT_PLACEMENT)
    local move = p.Add(Button(p, 200, 424, 128, moveLabel(), function()
        if inCombat() then p.Say(L.ERR_IN_COMBAT, true) return end
        ns.Mover:Toggle(not ns.Mover:IsOn()); p.Refresh()
    end))
    function move.Refresh() move.text:SetText(moveLabel()) end
    p.Add(Button(p, 336, 424, 84, L.OPT_TEST_ALL, toggleTest))
    Label(p, 430, 430, 12, C.secondary, L.OPT_MOVE_HELP, 260)
    p.Add(Check(p, 700, 424, 140, L.OPT_MINIMAP, function() return not prof().minimap.hide end,
        function(v) prof().minimap.hide = not v; if ns.Minimap then ns.Minimap:Apply() end; p.Refresh() end))

    p.statusY = 466
    Rule(p, 200, 499, 640)
    p.Add(Button(p, 200, 511, 140, L.OPT_RESET_ALL, function()
        Confirm(L.OPT_RESET_ASK:format(ns.DB:Current()), L.OPT_RESET, function() ns.DB:Reset() end)
    end))
    -- this window: its size and its two fonts
    local function windowSetting(x, w, labelX, label, name, items)
        Label(p, labelX, 517, 12, C.secondary, label)
        p.Add(Dropdown(p, x, 511, w, items, function() return prof().window[name] end,
            function(v) prof().window[name] = v; applyWindow(); p.Refresh() end)).up = true
    end
    local function fontItems()
        local items = {}
        for _, f in ipairs(FONTS) do items[#items + 1] = { key = f[1], label = L["FONT_" .. f[1]] } end
        return items
    end
    windowSetting(406, 66, 356, L.OPT_WIN_SCALE, "scale", function()
        local items = {}
        for _, v in ipairs(WINDOW_SCALES) do items[#items + 1] = { key = v / 100, label = v .. "%" } end
        return items
    end)
    windowSetting(544, 116, 486, L.OPT_FONT_HEAD, "headFont", fontItems)
    windowSetting(704, 136, 674, L.OPT_FONT_TEXT, "textFont", fontItems)
    return p
end

---------------------------------------------------------------- Alert
local PREVIEW_SCALE = 0.3

local function BuildAlert()
    local p = Page("", "")
    local previews = {}
    local function key() return selected.key end
    local function opt() return ns.DB:Alert(key()) end
    local function def() return Data.BY_KEY[key()] end
    local function style() return Styles.Get(Styles.Resolve(opt().style)) end
    local function changed() ns.Alerts:Apply(key()); ns.Engine:Refresh(); p.Refresh() end
    local function field(name)
        return function() return opt()[name] end, function(v) opt()[name] = v; changed() end
    end
    local function percent(name)
        return function() return (opt()[name] or 1) * 100 end, function(v) opt()[name] = v / 100; changed() end
    end
    local function colour(name)
        return function() return opt()[name] end,
               function(r, g, b) local c = opt()[name]; c.r, c.g, c.b = r, g, b; changed() end
    end
    -- controls shown only when they apply: name -> test
    local only = {}
    local function when(control, test) only[control] = test; return p.Add(control) end

    p.Add(Check(p, 200, 103, 100, L.OPT_ENABLED, field("enabled")))
    -- off: sound and button glow only. An opacity of 0 was the old way to say so.
    p.Add(Check(p, 310, 103, 160, L.OPT_ON_SCREEN, function() return opt().onScreen end, function(v)
        opt().onScreen = v
        if v and opt().opacity == 0 then opt().opacity = 1 end
        changed()
    end))
    Label(p, 200, 139, 11, C.secondary, L.OPT_DESIGN:upper())
    local about = Label(p, 200, 90, 12, C.secondary, "", 410)     -- what it is and when it shows
    about:SetWordWrap(false)        -- one line: a second would land on the tick boxes
    local styleName = Label(p, 200, 154, 13, C.ink, "")
    p.Add(Button(p, 200, 177, 124, L.OPT_BROWSE, function() Options:Select("gallery", key()) end))

    local well = CreateFrame("Frame", nil, p)
    At(well, p, 622, 54, 218, 142)
    Fill(well, C.well); Border(well, C.rule)
    Label(well, 10, 7, 11, C.secondary, L.OPT_PREVIEW:upper())
    local stage = CreateFrame("Frame", nil, well)
    At(stage, well, 10, 25, 198, 107)
    stage:SetClipsChildren(true)

    Heading(p, 200, 212, 640, L.OPT_APPEARANCE)
    local firstLook = #p.controls + 1       -- the appearance controls: greyed out when nothing is drawn
    -- Painted art keeps its own colours until one is picked on the wheel: picking turns Tint
    -- on, cancelling the wheel puts Tint back as it was.
    local getColour, setColour = colour("color")
    local tintBefore
    local swatch = p.Add(Swatch(p, 200, 239, L.OPT_COLOUR, getColour, function(r, g, b, cancelled)
        if cancelled then opt().recolor = tintBefore
        elseif style().family == "painted" then opt().recolor = true end
        setColour(r, g, b)
    end))
    function swatch.onOpen() tintBefore = opt().recolor end
    when(Check(p, 290, 239, 64, L.OPT_TINT, field("recolor")), function() return style().family == "painted" end)
    when(Slider(p, 360, 236, 200, L.OPT_SIZE, 50, 200, 5, "%d%%", percent("size")),
        function() return style().key ~= "vignette" end)
    p.Add(Slider(p, 590, 236, 250, L.OPT_OPACITY, 0, 100, 5, "%d%%", percent("opacity")))
    when(Slider(p, 200, 278, 150, L.OPT_SPREAD, 50, 200, 5, "%d%%", percent("spread")),
        function() return style().sides end)
    when(Dropdown(p, 360, 281, 96, function()
            local items = {}
            for _, s in ipairs(SIDES) do items[#items + 1] = { key = s, label = L["OPT_SIDE_" .. s] } end
            return items
        end, field("side")), function() return style().sides end)
    p.Add(Check(p, 476, 281, 90, L.OPT_ICON, field("showIcon")))
    p.Add(Check(p, 572, 281, 90, L.OPT_NAME, field("showName")))
    p.Add(Check(p, 668, 281, 100, L.OPT_TIMER, field("showTimer")))
    local lastLook = #p.controls

    Heading(p, 200, 322, 640, L.OPT_BEHAVIOUR)
    Label(p, 200, 347, 13, C.ink, L.OPT_SOUND)
    p.Add(Dropdown(p, 250, 342, 150, soundItems, field("sound")))
    local play = p.Add(Button(p, 408, 342, 54, L.OPT_PLAY, function() ns.Sounds.Play(opt().sound, true) end))
    function play.Refresh() play.Able(opt().sound ~= "none") end
    p.Add(Check(p, 483, 342, 145, L.OPT_COMBAT_ONLY, field("combatOnly")))
    when(Check(p, 686, 342, 150, L.OPT_STANCE_HINT, field("stanceHint")), function() return def().stances end)
    for alert, t in pairs(THRESHOLD) do
        when(Slider(p, 200, 370, 262, L["OPT_THRESHOLD_" .. alert], t[1], t[2], 1, t[3], field("threshold")),
            function() return key() == alert end)
    end

    local glowHead = Heading(p, 200, 406, 640, L.OPT_GLOW_HEAD)
    local hasButton = function() return def().spells ~= nil and def().kind ~= "buff" end
    only[glowHead] = hasButton
    when(Check(p, 200, 430, 150, L.OPT_GLOW, field("glow")), hasButton)
    local kind = when(Dropdown(p, 360, 430, 200, function()
            local items = {}
            for _, k in ipairs(ns.Glow and ns.Glow.STYLES or GLOW_KINDS) do
                items[#items + 1] = { key = k, label = L["GLOW_" .. k] }
            end
            return items
        end, field("glowStyle")), hasButton)
    local glowColour = when(Swatch(p, 590, 430, L.OPT_COLOUR, colour("glowColor")), hasButton)

    p.statusY = 468
    Rule(p, 200, 499, 640)
    local placeable = function() return style().key ~= "vignette" end
    local move = when(Button(p, 200, 511, 122, moveLabel(), function()
        if inCombat() then p.Say(L.ERR_IN_COMBAT, true) return end
        ns.Mover:Toggle(not ns.Mover:IsOn()); p.Refresh()
    end), placeable)
    function move.Refresh() move.text:SetText(moveLabel()) end
    when(Button(p, 330, 511, 120, L.OPT_RESET_POS, function() ns.Mover:ResetPosition(key()) end), placeable)
    p.Add(Button(p, 458, 511, 64, L.OPT_TEST, toggleTest))

    local refreshControls = p.Refresh
    function p.Refresh()
        local d, o = def(), opt()
        if not (d and o) then return end
        p.kicker:SetText((L["GROUP_" .. d.group] .. "  /  " .. L.OPT_ALERT):upper())
        p.title:SetText(ns.Alerts:Name(d.key))
        about:SetText(L["DESC_" .. d.key])
        for control, test in pairs(only) do control:SetShown(test() and true or false) end
        refreshControls()
        kind.Able(o.glow); glowColour.Able(o.glow)
        for i = firstLook, lastLook do p.controls[i].Able(o.onScreen) end

        local st = style()
        styleName:SetText((st.label or st.key) .. "  (" .. L["OPT_ERA_" .. st.era] .. ")")
        p.Say(st.key ~= o.style and L.OPT_DESIGN_GONE:format(st.label or st.key) or nil)
        if not previews[d.key] then
            previews[d.key] = ns.Alerts:Preview(d.key, stage)
            previews[d.key]:SetPoint("CENTER", stage, "CENTER", 0, 0)
        end
        for k, f in pairs(previews) do f:SetShown(k == d.key) end
        previews[d.key]:SetScale(PREVIEW_SCALE * math.max(0.5, o.size or 1))
    end
    return p
end

---------------------------------------------------------------- Gallery
local TILE_SCALE = 0.26
local FAMILIES = { "painted", "shape", "game" }
local ERAS = { "modern", "legacy" }

local function BuildGallery()
    local p = Page(L.OPT_LIBRARY, L.OPT_GALLERY)
    local tiles, heads = {}, {}
    local function key() return selected.key end

    Label(p, 200, 106, 13, C.ink, L.OPT_DESIGNS_FOR)
    p.Add(Dropdown(p, 290, 101, 222, alertItems, key, function(k) Options:Select("gallery", k) end))
    -- two menus: Modern and Legacy; the one in use is underlined
    local era, eraFor, tabs = "modern", nil, {}
    for i, e in ipairs(ERAS) do
        local tab = p.Add(Button(p, 532 + (i - 1) * 96, 101, 90, L["OPT_ERA_" .. e], function() era = e; p.Refresh() end))
        local line = tab:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(C.ember[1], C.ember[2], C.ember[3], 1)
        line:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0); line:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
        line:SetHeight(2)
        tabs[e] = line
    end
    local sf, child = Scroller(p, 200, 148, 626, 395)
    for _, family in ipairs(FAMILIES) do heads[family] = Heading(child, 0, 0, 626, L["OPT_FAMILY_" .. family]) end

    local function tile(style)
        local t = CreateFrame("Button", nil, child)
        t:SetSize(120, 144)
        local wellFrame = CreateFrame("Frame", nil, t)
        At(wellFrame, t, 0, 0, 120, 120)
        Fill(wellFrame, C.well)
        wellFrame:SetClipsChildren(true)
        t.edge = Border(wellFrame, C.rule)
        t.ground = t:CreateTexture(nil, "BACKGROUND")
        At(t.ground, t, 0, 120, 120, 24)
        local text = Text(t, 12, C.ink)
        text:SetPoint("TOPLEFT", t, "TOPLEFT", 5, -125); text:SetPoint("RIGHT", t, "RIGHT", -5, 0)
        text:SetWordWrap(false)
        text:SetText(style.label or style.key)
        t.preview = ns.Alerts:Preview(key(), wellFrame, style.key)
        t.preview:SetPoint("CENTER", wellFrame, "CENTER", 0, 0)
        t.preview:SetScale(TILE_SCALE)
        t:SetScript("OnEnter", function() if not t.current then t.edge(C.secondary) end end)
        t:SetScript("OnLeave", function() p.Mark() end)
        t:SetScript("OnClick", function()
            ns.DB:Alert(key()).style = style.key
            ns.Alerts:Apply(key()); ns.Engine:Refresh()
            p.Mark()
        end)
        return t
    end

    -- The border and label ground of the alert's current design.
    function p.Mark()
        local current = Styles.Resolve(ns.DB:Alert(key()).style)
        for styleKey, t in pairs(tiles) do
            t.current = styleKey == current
            t.edge(t.current and C.ember or C.rule)
            local c = t.current and C.emberGround or C.body
            t.ground:SetColorTexture(c[1], c[2], c[3], 1)
        end
    end

    local refreshControls, shownFor = p.Refresh, nil
    function p.Refresh()
        refreshControls()
        if not ns.DB:Alert(key()) then return end
        if eraFor ~= key() then              -- a newly chosen alert opens on the menu its design is in
            eraFor = key()
            era = Styles.Get(Styles.Resolve(ns.DB:Alert(key()).style)).era
        end
        for e, line in pairs(tabs) do line:SetShown(e == era) end
        if shownFor ~= key() .. era then     -- lay the tiles out for this alert and menu
            shownFor = key() .. era
            for _, t in pairs(tiles) do t:Hide() end
            for _, h in pairs(heads) do h:Hide() end
            local y, n, family = 0, 0, nil
            for _, style in ipairs(Styles.List(key(), era)) do
                if style.family ~= family then
                    if family then y = y + 24 + 156 * math.ceil(n / 4) end
                    family, n = style.family, 0
                    At(heads[family], child, 0, y, 626, 18):Show()
                end
                local t = tiles[style.key] or tile(style)
                tiles[style.key] = t
                ns.Alerts:Retarget(t.preview, key())
                At(t, child, 160 * (n % 4), y + 22 + 156 * math.floor(n / 4)):Show()
                n = n + 1
            end
            child.h = y + 24 + 156 * math.ceil(n / 4)
            sf.pos = 0
            sf.Sync()
        end
        p.Mark()
    end
    return p
end

---------------------------------------------------------------- Macros
-- Used only where the client can't measure the text: a guess at 80 characters a line.
local function visualLines(body)
    local n = 0
    for line in body:gmatch("[^\n]+") do n = n + math.ceil(#line / 80) end
    return n
end

local function BuildMacros()
    local p = Page(L.OPT_LIBRARY, L.OPT_MACROS)
    local M = ns.Macros
    Label(p, 200, 103, 13, C.ink, L.MACRO_SUBTITLE)
    -- tabs: every macro, or one spec's; opens on the spec the character has
    local spec, tabs = ns.Detect.Spec(), {}
    for i, key in ipairs({ "all", "arms", "fury", "prot" }) do
        local mine = key ~= "all" and key or nil
        local tab = p.Add(Button(p, 496 + (i - 1) * 86, 98, 80, key == "all" and L.MACRO_ALL or L["PRESET_" .. key],
            function() spec = mine; p.Refresh() end))
        local line = tab:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(C.ember[1], C.ember[2], C.ember[3], 1)
        line:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0); line:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
        line:SetHeight(2)
        tabs[key] = line
    end
    local none = Label(p, 200, 140, 13, C.secondary, L.MACRO_NONE, 624)
    local sf, child = Scroller(p, 200, 140, 624, 403)
    local rows = {}
    local measure = Text(p, 12, C.ink)              -- the macro text, wrapped as the box wraps it
    measure:SetWidth(588); measure:SetWordWrap(true); measure:Hide()
    -- the page follows the bags, the macro list and the end of a fight while it is open
    local watch = CreateFrame("Frame", nil, p)
    for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "UPDATE_MACROS", "PLAYER_REGEN_ENABLED" }) do
        pcall(watch.RegisterEvent, watch, event)
    end
    watch:SetScript("OnEvent", function() if p:IsVisible() then p.Refresh() end end)
    p:SetScript("OnHide", function() for _, r in pairs(rows) do r.said = nil end end)

    local function row(m)
        local r = CreateFrame("Frame", nil, child)
        Rule(r, 0, 0, 624)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(18, 18); r.icon:SetPoint("TOPLEFT", r, "TOPLEFT", 8, -10)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        Label(r, 32, 10, 15, C.ink, M.Name(m), nil, true)
        Label(r, 8, 34, 13, C.secondary, L["MACRO_" .. m.key], 608)
        local box = CreateFrame("EditBox", nil, r)
        Fill(box, C.well); Border(box, C.rule)
        box:SetMultiLine(true)
        box:SetAutoFocus(false)
        SetFont(box, 12)
        box:SetTextColor(C.ink[1], C.ink[2], C.ink[3])
        box:SetTextInsets(10, 10, 7, 7)
        -- read-only: typing puts the text back; it can still be selected and copied
        box:SetScript("OnTextChanged", function(self, user) if user then self:SetText(r.body) end end)
        box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        r.box = box
        r.note = Label(r, 8, 0, 13, C.ink, "", 608)
        r.create = Button(r, 540, 10, 76, L.MACRO_CREATE, function()
            local ok, err = M.Create(m.key)       -- eligibility is checked again here, at the click
            r.created = r.created or ok
            r.said = ok and L.OPT_INFO .. " " .. L.MACRO_ADDED:format(M.Name(m)) or L.OPT_ERROR .. " " .. L[err]
            p.Refresh()
        end)
        return r
    end

    local refreshControls = p.Refresh
    function p.Refresh()
        refreshControls()
        for _, r in pairs(rows) do r:Hide() end
        local y = 0
        for key, line in pairs(tabs) do line:SetShown(key == (spec or "all")) end
        for _, m in ipairs(M.Available(ns.Detect.IsKnown, spec)) do
            local r = rows[m.key] or row(m)
            rows[m.key] = r
            local body, why = M.Body(m)           -- the same text Create writes
            local exists = M.Exists(m)
            r.icon:SetTexture(U.SpellTexture(M.IconSpell(m, ns.Detect.IsKnown)))
            r.body = body
            if r.box:GetText() ~= body then r.box:SetText(body) end     -- keeps a selection being copied
            measure:SetText(body)
            local textH = measure:GetStringHeight()
            local boxH = type(textH) == "number" and textH > 0 and math.ceil(textH) + 16 or 17 + 15 * visualLines(body)
            At(r.box, r, 8, 58, 608, boxH)
            r.create.text:SetText(not exists and L.MACRO_CREATE or r.created and L.MACRO_CREATED or L.MACRO_EXISTS)
            r.create.Able(not exists and not why)
            -- one line under the text: what the last click did, else why Create is off
            local said = r.said or why and L[why] or exists and not r.created and L.ERR_MACRO_EXISTS or ""
            r.note:SetText(said)
            At(r.note, r, 8, 62 + boxH)
            local h = 79 + boxH + (said ~= "" and 21 or 0)
            At(r, child, 0, y, 624, h):Show()
            y = y + h
        end
        none:SetShown(y == 0)
        child.h = y
        sf.Sync()
    end
    return p
end

---------------------------------------------------------------- Consumables
-- Shift-click on an item's name: into the auction house search box when that is open,
-- otherwise as a link into the chat line, the way the game's own items do it.
local function linkItem(id)
    if not (IsShiftKeyDown and IsShiftKeyDown()) then return end
    local name, link = U.Call(GetItemInfo, id)
    if link and U.Call(ChatEdit_InsertLink, link) then return end
    if name and BrowseName and BrowseName:IsVisible() then BrowseName:SetText(name) end
end

local function itemTip(owner, id, spell)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if spell then pcall(GameTooltip.SetSpellByID, GameTooltip, spell) else pcall(GameTooltip.SetItemByID, GameTooltip, id) end
    GameTooltip:Show()
end

local function BuildConsumables()
    local p = Page(L.OPT_LIBRARY, L.OPT_CONSUMABLES)
    local D = ns.Detect
    Label(p, 200, 100, 12, C.ink, L.CONS_SUBTITLE, 450)
    Label(p, 200, 132, 12, C.secondary, L.CONS_DISCLAIMER, 636)
    Label(p, 200, 164, 12, C.secondary, L["CONS_STACK_" .. (ns.ERA and "era" or "forever")], 636)
    -- tabs: damage or tank; opens on tank for a Protection warrior
    local role, tabs = D.Spec() == "prot" and "tank" or "dps", {}
    for i, key in ipairs(ns.Consumables.ROLES) do
        local tab = p.Add(Button(p, 640 + (i - 1) * 102, 98, 98, L["CONS_ROLE_" .. key], function() role = key; p.Refresh() end))
        local stance = tab:CreateTexture(nil, "ARTWORK")       -- Berserker Stance for damage, Defensive for tank
        stance:SetSize(16, 16); stance:SetPoint("LEFT", tab, "LEFT", 8, 0)
        stance:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        stance:SetTexture(U.SpellTexture(key == "tank" and 71 or 2458))
        tab.text:ClearAllPoints(); tab.text:SetPoint("CENTER", tab, "CENTER", 10, 0)
        local line = tab:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(C.ember[1], C.ember[2], C.ember[3], 1)
        line:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0); line:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
        line:SetHeight(2)
        tabs[key] = line
    end
    local sf, child = Scroller(p, 200, 202, 624, 341)
    local heads, rows = {}, {}
    local flaskCost = Label(child, 0, 0, 12, C.ember, L.CONS_FLASK_COST, 620)
    -- names and icons arrive from the game a moment after they are first asked for
    local watch = CreateFrame("Frame", nil, p)
    for _, event in ipairs({ "GET_ITEM_INFO_RECEIVED", "BAG_UPDATE_DELAYED" }) do pcall(watch.RegisterEvent, watch, event) end
    watch:SetScript("OnEvent", function() if p:IsVisible() then p.Refresh() end end)

    -- one material of a recipe: "2x Gromsblood", with its own tooltip and shift-click
    local function mat(r, i)
        local m = CreateFrame("Button", nil, r)
        m.icon = m:CreateTexture(nil, "ARTWORK")
        m.icon:SetSize(14, 14); m.icon:SetPoint("LEFT", m, "LEFT", 0, 0)
        m.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        m.text = Text(m, 12, C.ink); m.text:SetPoint("LEFT", m, "LEFT", 17, 0)
        m:SetScript("OnEnter", function() m.text:SetTextColor(C.ember[1], C.ember[2], C.ember[3]); itemTip(m, m.itemID) end)
        m:SetScript("OnLeave", function()
            m.text:SetTextColor(C.ink[1], C.ink[2], C.ink[3])
            if GameTooltip then GameTooltip:Hide() end
        end)
        m:SetScript("OnClick", function() linkItem(m.itemID) end)
        r.mats[i] = m
        return m
    end

    local function row(i)
        local r = CreateFrame("Button", nil, child)
        r.mats = {}
        local top = CreateFrame("Frame", nil, r)        -- the first line; the lines under it belong to it
        top:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0); top:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0); top:SetHeight(22)
        r.rank = Text(top, 12, C.secondary); r.rank:SetPoint("LEFT", top, "LEFT", 2, 0)
        r.icon = top:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(18, 18); r.icon:SetPoint("LEFT", top, "LEFT", 24, 0)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        r.name = Text(top, 13, C.ink); r.name:SetPoint("LEFT", top, "LEFT", 50, 0)
        r.name:SetWidth(212); r.name:SetWordWrap(false)
        r.note = Text(top, 12, C.secondary); r.note:SetPoint("LEFT", top, "LEFT", 268, 0)
        r.note:SetWidth(232); r.note:SetWordWrap(false)
        r.have = Text(top, 12, C.ink); r.have:SetPoint("LEFT", top, "LEFT", 508, 0)
        r.source = Label(r, 50, 23, 11, C.quiet, "")                  -- "Alchemy (300)"
        r.needs = Label(r, 50, 40, 11, C.quiet, L.CONS_MATS)
        local fill = Fill(r, C.body)
        r:SetScript("OnEnter", function()
            fill:SetColorTexture(C.cap[1], C.cap[2], C.cap[3], 1)
            itemTip(r, r.itemID, r.spell)
        end)
        r:SetScript("OnLeave", function()
            fill:SetColorTexture(C.body[1], C.body[2], C.body[3], 1)
            if GameTooltip then GameTooltip:Hide() end
        end)
        r:SetScript("OnClick", function() if r.itemID then linkItem(r.itemID) end end)
        rows[i] = r
        return r
    end

    local function source(entry)
        local parts = {}
        if entry.prof then parts[1] = L["PROF_" .. entry.prof] .. (entry.skill and (" (" .. entry.skill .. ")") or "") end
        if entry.extra then parts[#parts + 1] = entry.extra end
        if entry.from then parts[#parts + 1] = entry.from end
        return table.concat(parts, ", ")
    end

    local refreshControls = p.Refresh
    function p.Refresh()
        refreshControls()
        for key, line in pairs(tabs) do line:SetShown(key == role) end
        for _, h in pairs(heads) do h:Hide() end
        for _, r in ipairs(rows) do r:Hide() end
        local y, n = 0, 0
        for _, section in ipairs(ns.Consumables.List(role)) do
            local key = role .. section[1]
            heads[key] = heads[key] or Heading(child, 0, 0, 624, L["CONS_SEC_" .. section[1]])
            At(heads[key], child, 0, y + 6, 624, 18):Show()
            y = y + 30
            if section[1] == "flask" then At(flaskCost, child, 0, y - 2); y = y + 20 end
            for rank, entry in ipairs(section[2]) do
                n = n + 1
                local r = rows[n] or row(n)
                r.itemID, r.spell = entry[1], entry.spell
                r.rank:SetText(rank .. ".")
                if entry.spell then
                    r.name:SetText(U.SpellName(entry.spell) or "")
                    r.icon:SetTexture(U.SpellTexture(entry.spell))
                    r.note:SetText(""); r.have:SetText("")
                else
                    local name, icon, count = D.Item(entry[1])
                    r.name:SetText(name or entry[2])
                    r.icon:SetTexture(icon)
                    r.note:SetText(entry[3])
                    r.have:SetText((count or 0) > 0 and ("x" .. count) or "")
                end
                local from = source(entry)
                r.source:SetText(from)
                local h = from ~= "" and 40 or 24
                -- the materials, in a line (two when it is long), with what they cost together
                local mats, x, line = entry.mats or {}, 86, 0
                for _, m in ipairs(r.mats) do m:Hide() end
                r.needs:SetShown(#mats > 0)
                for i, need in ipairs(mats) do
                    local m = r.mats[i] or mat(r, i)
                    m.itemID = need[1]
                    local name, icon = D.Item(need[1])
                    local label = need[2] .. "x " .. (name or need[3])
                    m.text:SetText(label)
                    m.icon:SetTexture(icon)
                    local w = #label * 6 + 30
                    if x + w > 600 then x, line = 86, line + 1 end
                    At(m, r, x, 39 + line * 16, w, 16):Show()
                    x = x + w
                end
                if #mats > 0 then h = 58 + line * 16 end
                At(r, child, 0, y, 624, h):Show()
                y = y + h + 2
            end
        end
        child.h = y + 8
        sf.Sync()
    end
    return p
end

---------------------------------------------------------------- Profiles
local function BuildProfiles()
    local p = Page(L.OPT_LIBRARY, L.OPT_PROFILES)
    local DB = ns.DB
    local target      -- the profile New/Copy/Rename/Delete/Export work on; never switched to by itself
    local preset = "standard"
    local function names()
        local items = {}
        for _, name in ipairs(DB:List()) do items[#items + 1] = { key = name, label = name } end
        return items
    end
    local function presets()
        local items = {}
        for _, key in ipairs(DB.PRESETS) do items[#items + 1] = { key = key, label = L["PRESET_" .. key] } end
        return items
    end
    local function orNone()
        local items = names()
        table.insert(items, 1, { key = "", label = L.OPT_PROFILE_NONE })
        return items
    end
    local function trimmed(name) return name:match("^%s*(.-)%s*$") end
    -- runs a profile change and reports it; nothing is changed in combat
    local function run(fn, ...)
        if inCombat() then p.Say(L.ERR_IN_COMBAT, true) return false end
        local ok, err = fn(DB, ...)
        if ok == false then p.Say(L[err], true) return false end
        p.Say(L.OPT_PROFILE_DONE)
        return true
    end

    -- the status line and Reset stay in place; everything else scrolls (y from the top of f)
    local sf, f = Scroller(p, 200, 106, 624, 330)
    Heading(f, 0, 0, 624, L.OPT_PROFILE_CURRENT)
    Label(f, 0, 31, 13, C.ink, L.OPT_PROFILE_USE)
    p.Add(Dropdown(f, 144, 26, 292, names, function() return DB:Current() end,
        function(name) run(DB.Use, name) end))
    Label(f, 0, 58, 12, C.secondary, L.OPT_PROFILE_USE_HELP, 624)

    Heading(f, 0, 88, 624, L.OPT_PROFILE_MANAGE)
    Label(f, 0, 119, 13, C.ink, L.OPT_PROFILE_TARGET)
    p.Add(Dropdown(f, 144, 114, 292, names, function() return target end,
        function(name) target = name; p.Refresh() end))
    Label(f, 0, 153, 13, C.ink, L.OPT_PROFILE_NAME)
    local input = Input(f, 144, 148, 292)
    local function typed() return input:GetText() or "" end
    Label(f, 0, 187, 13, C.ink, L.OPT_PROFILE_START)
    p.Add(Dropdown(f, 144, 182, 200, presets, function() return preset end,
        function(key) preset = key; p.Refresh() end))
    p.Add(Button(f, 352, 182, 190, L.OPT_PROFILE_APPLY, function()
        local key = preset
        Confirm(L.OPT_PROFILE_APPLY_ASK:format(DB:Current(), L["PRESET_" .. key]), L.OPT_PROFILE_APPLY,
            function() run(DB.ApplyPreset, key) end)
    end))

    p.Add(Button(f, 0, 220, 72, L.OPT_PROFILE_NEW, function()
        local name = typed()
        if run(DB.Create, name, nil, preset) then target = trimmed(name); p.Refresh() end
    end))
    p.Add(Button(f, 80, 220, 100, L.OPT_PROFILE_COPY, function()
        local name = typed()
        if run(DB.Create, name, target) then target = trimmed(name); p.Refresh() end
    end))
    p.Add(Button(f, 188, 220, 86, L.OPT_PROFILE_RENAME, function()
        local name = typed()
        if run(DB.Rename, target, name) then target = trimmed(name); p.Refresh() end
    end))
    p.Add(Button(f, 282, 220, 74, L.OPT_PROFILE_DELETE, function()
        if target == DB:Current() then p.Say(L.ERR_PROFILE_IN_USE, true) return end
        local name = target
        Confirm(L.OPT_PROFILE_DELETE_ASK:format(name), L.OPT_PROFILE_DELETE, function()
            if run(DB.Delete, name) then target = DB:Current(); p.Refresh() end
        end)
    end))
    Label(f, 0, 256, 12, C.secondary, L.OPT_PROFILE_MANAGE_HELP, 624)

    -- a profile for each talent tree, for this character
    Heading(f, 0, 302, 624, L.OPT_PROFILE_SPEC)
    for i, spec in ipairs({ "arms", "fury", "prot" }) do
        local y = 296 + i * 32
        Label(f, 0, y + 5, 13, C.ink, L["PRESET_" .. spec])
        p.Add(Dropdown(f, 144, y, 292, orNone, function() return DB:SpecProfile(spec) or "" end,
            function(name) DB:SetSpecProfile(spec, name ~= "" and name or nil); p.Refresh() end))
    end
    Label(f, 0, 426, 12, C.secondary, L.OPT_PROFILE_SPEC_HELP, 624)

    -- as text: the upper box is read-only (select and copy), the lower one takes a paste
    Heading(f, 0, 472, 624, L.OPT_PROFILE_SHARE)
    local out, paste, text = Input(f, 88, 498, 536), Input(f, 88, 530, 536), ""
    out:SetMaxLetters(0); paste:SetMaxLetters(0)
    out:SetScript("OnTextChanged", function(self, user) if user then self:SetText(text) end end)
    out:SetScript("OnMouseUp", function(self) self:HighlightText() end)
    p.Add(Button(f, 0, 498, 80, L.OPT_PROFILE_EXPORT, function()
        text = DB:Export(target) or ""
        out:SetText(text)
        out:SetCursorPosition(0)
        p.Say(L.OPT_PROFILE_EXPORTED)
    end))
    p.Add(Button(f, 0, 530, 80, L.OPT_PROFILE_IMPORT, function()
        local name = typed()
        if run(DB.Import, name, paste:GetText()) then target = trimmed(name); paste:SetText(""); p.Refresh() end
    end))
    Label(f, 0, 564, 12, C.secondary, L.OPT_PROFILE_SHARE_HELP, 624)
    f.h = 604
    sf.Sync()

    p.statusY = 445
    Rule(p, 200, 499, 640)
    p.Add(Button(p, 200, 511, 158, L.OPT_PROFILE_RESET, function()
        Confirm(L.OPT_RESET_ASK:format(DB:Current()), L.OPT_RESET, function() run(DB.Reset) end)
    end))

    local refreshControls = p.Refresh
    function p.Refresh()
        local exists = false
        for _, name in ipairs(DB:List()) do if name == target then exists = true end end
        if not exists then target = DB:Current() end
        refreshControls()
    end
    return p
end

local BUILD = { general = BuildGeneral, alert = BuildAlert, gallery = BuildGallery, macros = BuildMacros, consumables = BuildConsumables,
                profiles = BuildProfiles }

----------------------------------------------------------------------
-- The window and its rail
----------------------------------------------------------------------
local function RailRow(parent, x, y, w, label, inset, page, key)
    local b = CreateFrame("Button", nil, parent)
    At(b, parent, x, y, w, 24)
    b.fill = b:CreateTexture(nil, "BACKGROUND")
    b.fill:SetAllPoints(b)
    b.strip = b:CreateTexture(nil, "ARTWORK")
    b.strip:SetColorTexture(C.ink[1], C.ink[2], C.ink[3], 1)
    b.strip:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0); b.strip:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
    b.strip:SetWidth(3)
    if page == "alert" then     -- its spell or talent icon, set when the list is laid out
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetSize(16, 16)
        b.icon:SetPoint("LEFT", b, "LEFT", 9, 0)
        b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)      -- without the icon's own border
        inset = 31
    end
    local text = Text(b, 13, C.ink)
    text:SetPoint("LEFT", b, "LEFT", inset, 0)
    text:SetPoint("RIGHT", b, "RIGHT", -2, 0)
    text:SetWordWrap(false)
    text:SetText(label)
    b.page, b.key = page, key
    function b.Paint(hot)
        -- an alert row is lit on its own page only; Gallery keeps its own row lit
        local on = selected.page == page and (page ~= "alert" or selected.key == key)
        b.strip:SetShown(on)
        local c = on and C.ember or hot and C.hover or C.well
        b.fill:SetColorTexture(c[1], c[2], c[3], 1)
    end
    b:SetScript("OnEnter", function() b.Paint(true) end)
    b:SetScript("OnLeave", function() b.Paint(false) end)
    b:SetScript("OnClick", function() Options:Select(page, key or selected.key) end)
    railRows[#railRows + 1] = b
    return b
end

local railScroll, railChild, railItems = nil, nil, {}

-- Lists the alerts the character knows, group by group. Returns the first one.
local function layoutRail()
    local y, first = 0, nil
    for _, group in ipairs(Data.GROUPS) do
        local head = railItems[group]
        local any = false
        for _, def in ipairs(Data.ALERTS) do
            if def.group == group then
                local row = railItems[def.key]
                local show = known(def)
                row:SetShown(show)
                if show then
                    row.icon:SetTexture(ns.Alerts:Icon(def.key))
                    if not any then any = true; At(head, railChild, 8, y + 5); y = y + 22 end
                    At(row, railChild, 0, y, 159, 24)
                    y = y + 24
                    first = first or def.key
                end
            end
        end
        head:SetShown(any)
    end
    railChild.h = y
    railScroll.Sync()
    return first
end

local function savePosition()
    local x, y = win:GetCenter()
    local cx, cy = UIParent:GetCenter()
    if not (x and cx) then return end
    local w = ns.DB:Profile().window
    local s = w.scale or 1          -- stored in screen units, so it holds at any window size
    w.x, w.y = math.floor(x * s - cx + 0.5), math.floor(y * s - cy + 0.5)
end

local function restorePosition()
    local w = ns.DB:Profile().window
    local s = w.scale or 1
    win:ClearAllPoints()
    win:SetPoint("CENTER", UIParent, "CENTER", (w.x or 0) / s, (w.y or 0) / s)
end

-- The window's size, fonts and place, from the profile.
function applyWindow()
    win:SetScale(ns.DB:Profile().window.scale or 1)
    for _, f in ipairs(lettered) do f[1]:SetFont(fontFile(f[3]), f[2], "") end
    restorePosition()
end

local function BuildWindow()
    win = CreateFrame("Frame", "RagebornOptions", UIParent)
    win:SetSize(W, H)
    win:SetFrameStrata("HIGH")
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:Hide()
    Fill(win, C.body); Border(win, C.rule)
    if UISpecialFrames then UISpecialFrames[#UISpecialFrames + 1] = "RagebornOptions" end   -- Escape closes it
    win:SetScript("OnHide", function() if popup then popup:Hide() end end)

    local bar = CreateFrame("Frame", nil, win)
    At(bar, win, 1, 1, W - 2, 39)
    local red = Fill(bar, C.bar)
    if CreateColor then     -- darker at the foot, where the client can shade a texture
        pcall(red.SetGradient, red, "VERTICAL", CreateColor(0.29, 0.06, 0.055, 1), CreateColor(0.48, 0.11, 0.09, 1))
    end
    Rule(win, 1, 40, W - 2)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() win:StartMoving() end)
    bar:SetScript("OnDragStop", function() win:StopMovingOrSizing(); savePosition() end)
    local icon = bar:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\Rageborn\\Media\\icon")
    At(icon, win, 12, 8, 24, 24)
    local name = Label(win, 46, 10, 18, C.ink, L.ADDON_NAME, nil, true)
    if ns.BETA then         -- a test version says so beside its name
        local tag = Text(win, 11, C.ink)
        tag:SetPoint("LEFT", name, "RIGHT", 10, -1)
        tag:SetText(L.BETA_TAG .. "  " .. ns.VERSION)
    end
    local close = CreateFrame("Button", nil, win)
    At(close, win, 817, 4, 36, 32)
    local x = Text(close, 16, C.ink)
    x:SetPoint("CENTER", close, "CENTER", 0, 0)
    x:SetText("x")
    close:SetScript("OnClick", function() win:Hide() end)

    local rail = CreateFrame("Frame", nil, win)
    At(rail, win, 1, 41, 178, H - 42)
    Fill(rail, C.well)
    local divider = win:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(C.rule[1], C.rule[2], C.rule[3], 1)
    At(divider, win, 179, 41, 1, H - 42)

    RailRow(win, 8, 48, 159, L.OPT_GENERAL, 8, "general")
    Rule(win, 12, 79, 152)
    railScroll, railChild = Scroller(win, 8, 84, 159, 330)
    for _, group in ipairs(Data.GROUPS) do
        railItems[group] = Label(railChild, 8, 0, 11, C.secondary, L["GROUP_" .. group]:upper())
    end
    for _, def in ipairs(Data.ALERTS) do
        railItems[def.key] = RailRow(railChild, 0, 0, 159, ns.Alerts:Name(def.key), 17, "alert", def.key)
    end
    Rule(win, 12, 417, 152)
    Label(win, 16, 426, 11, C.secondary, L.OPT_LIBRARY:upper())
    RailRow(win, 8, 447, 159, L.OPT_GALLERY, 8, "gallery")
    RailRow(win, 8, 473, 159, L.OPT_MACROS, 8, "macros")
    RailRow(win, 8, 499, 159, L.OPT_CONSUMABLES, 8, "consumables")
    RailRow(win, 8, 525, 159, L.OPT_PROFILES, 8, "profiles")

    ns.DB:OnChange(function() if win:IsShown() then applyWindow(); Options:Refresh() end end)
end

-- Shows a page; key is the alert it is about (alert page and gallery).
function Options:Select(page, key)
    if not BUILD[page] then page = "general" end
    if page == "alert" or page == "gallery" then
        local def = Data.BY_KEY[key]
        if not (def and known(def)) then key = layoutRail() end
        if not key then page = "general" end
    end
    selected.page, selected.key = page, key or selected.key
    self:Refresh()
end

function Options:Refresh()
    if not win then return end
    layoutRail()
    local page = selected.page
    pages[page] = pages[page] or BUILD[page]()
    for name, p in pairs(pages) do p:SetShown(name == page) end
    for _, row in ipairs(railRows) do row.Paint(false) end
    pages[page].Refresh()
end

function Options:Open()
    if not win then BuildWindow() end
    applyWindow()
    win:Show()
    self:Select(selected.page, selected.key)
end

function Options:Toggle()
    if win and win:IsShown() then win:Hide() else self:Open() end
end

-- A page in the game's own AddOns settings with one button that opens the window.
function Options:Start()
    if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
    pcall(function()
        local panel = CreateFrame("Frame")
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        b:SetSize(180, 26)
        b:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
        b:SetText(L.OPT_OPEN)
        b:SetScript("OnClick", function() Options:Open() end)
        Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(panel, L.ADDON_NAME))
    end)
end
