if select(2, UnitClass("player")) ~= "DRUID" then
    -- no druid, no addon
    return
end

BalanceSpellSuggest = LibStub("AceAddon-3.0"):NewAddon("BalanceSpellSuggest", "AceTimer-3.0", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("BalanceSpellSuggest", true)
local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

BalanceSpellSuggest.suggestFrame = nil
BalanceSpellSuggest.nextSpellFrame = nil
BalanceSpellSuggest.moonfireFrame = nil
BalanceSpellSuggest.sunfireFrame = nil
BalanceSpellSuggest.updateTimer = nil

local options = {
    name = "Balance Spell Suggest",
    handler = BalanceSpellSuggest,
    type = 'group',
    childGroups = "tab",
    args = {
        behavior = {
            name = L["Behavior"],
            type = "group",
            order = 0,
            args = {
                dotRefreshPower = {
                    name = L["DoT refresh power"],
                    desc = L["dotRefreshPowerDesc"],
                    type = "range",
                    order = 0,
                    min = 0,
                    max = 100,
                    softMin = 10,
                    softMax = 50,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.dotRefreshPower = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.dotRefreshPower end
                },
                dotRefreshTime = {
                    name = L["DoT refresh time"],
                    desc = L["dotRefreshTimeDesc"],
                    type = "range",
                    order = 1,
                    min = 0,
                    max = 40,
                    softMin = 1,
                    softMax = 20,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.dotRefreshTime = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.dotRefreshTime end
                },
                starfireWrathTippingPoint = {
                    name = L["Starfire -> Wrath tipping point"],
                    desc = L["starfireWrathTippingPointDesc"],
                    type = "range",
                    order = 2,
                    min = 0,
                    max = 100,
                    softMin = 10,
                    softMax = 50,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.starfireWrathTippingPoint = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.starfireWrathTippingPoint end
                },
                wrathStarfireTippingPoint = {
                    name = L["Wrath -> Starfire tipping point"],
                    desc = L["wrathStarfireTippingPointDesc"],
                    type = "range",
                    order = 3,
                    min = 0,
                    max = 100,
                    softMin = 10,
                    softMax = 50,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.wrathStarfireTippingPoint = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.wrathStarfireTippingPoint end
                },
                caOnBossOnly = {
                    name = L["CA on boss only"],
                    desc = L["CAOnlyOnBossDesc"],
                    type = "toggle",
                    order = 4,
                    set = function(_, val) BalanceSpellSuggest.db.profile.caOnBossOnly = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.caOnBossOnly end
                },
                leaveOneSSCharge = {
                    name = L["Leave one SS charge"],
                    desc = L["leaveOneSSChargeDesc"],
                    type = "toggle",
                    order = 5,
                    set = function(_, val) BalanceSpellSuggest.db.profile.leaveOneSSCharge = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.leaveOneSSCharge end
                },
                pBehavior = {
                    name = L["Peak behavior"],
                    desc = L["PeakBehaviorDesc"],
                    type = "select",
                    order = 6,
                    values = { always = L["PeakBehaviorAlways"], time = L["PeakBehaviorTime"], never = L["PeakBehaviorNever"] },
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.peakBehavior = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.peakBehavior end
                },
            }
        },
        display = {
            name = L["Display"],
            type = "group",
            order = 1,
            args = {
                locked = {
                    name = L["Locked"],
                    desc = L["Locks the suggestion frame in place."],
                    type = "toggle",
                    order = 0,
                    set = function(info, val) BalanceSpellSuggest:ToggleFrameLock(info, val) end,
                    get = function(_) return BalanceSpellSuggest.db.profile.locked end
                },
                xPosition = {
                    name = L["X position"],
                    desc = L["X position from the center."],
                    type = "range",
                    order = 1,
                    min = -2000.0,
                    max = 2000.0,
                    softMin = -2000.0,
                    softMax = 2000.0,
                    step = 0.1,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.xPosition = val
                        BalanceSpellSuggest:UpdateFramePosition()
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.xPosition end
                },
                yPosition = {
                    name = L["Y position"],
                    desc = L["Y position from the center."],
                    type = "range",
                    order = 2,
                    min = -2000.0,
                    max = 2000.0,
                    softMin = -2000.0,
                    softMax = 2000.0,
                    step = 0.1,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.yPosition = val
                        BalanceSpellSuggest:UpdateFramePosition()
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.yPosition end
                },
                size = {
                    name = L["Size"],
                    desc = L["sizeDesc"],
                    type = "range",
                    order = 3,
                    min = 10,
                    max = 256,
                    softMin = 10,
                    softMax = 128,
                    step = 1,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.size = val
                        BalanceSpellSuggest:UpdateFramePosition()
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.size end
                },
                timers = {
                    name = L["DoT Timer"],
                    type = "header",
                    order = 4,
                },
                timersToggle = {
                    name = L["Enable timers"],
                    type = "toggle",
                    order = 5,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.timers = val
                        BalanceSpellSuggest:UpdateFramePosition()
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.timers end
                },
                peakGlow = {
                    name = L["PeakGlow"],
                    desc = L["PeakGlowDesc"],
                    type = "select",
                    order = 6,
                    values = { none = L["PeakGlowNone"], normal = L["PeakGlowNormal"], spellalert = L["PeakGlowSpellAlert"] },
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.display.peakGlow = val
                        BalanceSpellSuggest:UpdateFramePosition()
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.display.peakGlow end
                },
                normalFontSize = {
                    name = L["Font size"],
                    type = "range",
                    order = 7,
                    min = 1,
                    max = 100,
                    softMin = 10,
                    softMax = 100,
                    step = 1,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.normalfontsize = val
                        BalanceSpellSuggest:RecreateAllFonts()
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.normalfontsize end
                },
                highlightFontSize = {
                    name = L["Highlight font size"],
                    type = "range",
                    order = 8,
                    min = 1,
                    max = 100,
                    softMin = 10,
                    softMax = 100,
                    step = 1,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.highlightfontsize = val
                        BalanceSpellSuggest:RecreateAllFonts()
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.highlightfontsize end
                },
                font = {
                    name = L["Font"],
                    type = "select",
                    order = 9,
                    dialogControl = "LSM30_Font",
                    values = AceGUIWidgetLSMlists.font,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.font = val
                        BalanceSpellSuggest:RecreateAllFonts()
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.font  end
                },
            }
        }
    }
}

local defaults = {
    profile = {
        dotRefreshPower = 40,
        starfireWrathTippingPoint = 45,
        wrathStarfireTippingPoint = 35,
        dotRefreshTime = 7,
        caOnBossOnly = true,
        leaveOneSSCharge = true,
        xPosition = 0,
        yPosition = 0,
        size = 64,
        locked = true,
        timers = true,
        normalfontsize = 25,
        highlightfontsize = 32,
        font = "Friz Quadrata TT",
        fontoptions = "OUTLINE",
        behavior = {
            peakBehavior = "always",
        },
        display = {
            peakGlow = "normal",
        },
    }
}


-- spells and stuff
local moonfirename,_,moonfire = GetSpellInfo(164812)
local sunfirename,_,sunfire = GetSpellInfo(164815)
local starsurgename,_,starsurge = GetSpellInfo(78674)
local starfirename,_,starfire =  GetSpellInfo(2912)
local wrathname,_,wrath = GetSpellInfo(5176)
local starfallname,_,starfall = GetSpellInfo(48505)
local celestialalignmentname,_,celestialalignment = GetSpellInfo(112071)
local moonkinformname,_,moonkinform = GetSpellInfo(24858)

local lunarempowermentname = GetSpellInfo(164547)
local solarempowermentname = GetSpellInfo(164545)
local lunarpeakname = GetSpellInfo(171743)
local solarpeakname = GetSpellInfo(171744)

local empoweredMoonkin = GetSpellInfo(157228)

local glowTexturePath = "Interface\\SpellActivationOverlay\\IconAlert"

-- Always called
function BalanceSpellSuggest:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BalanceSpellSuggestDB", defaults, true)
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BalanceSpellSuggest", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BalanceSpellSuggest", "Balance Spell Suggest")
    BalanceSpellSuggest:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

    self:SetUpFrames()

    self.db.RegisterCallback(self, "OnProfileChanged", "ProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "ProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "ProfileChanged")

    self.player = {
        moonkinForm = false,
        buffs = {
            lunarPeak = false,
            solarPeak = false,
            empoweredMoonkin = false,
            starfall = false,
        },
        power = 0,
        direction = "none",
        inLunar = false,
        inSolar = false,
        currentCast = {
            spell = nil,
            icon = nil,
            startTime = nil,
            endTime = nil,
            id = nil,
            interruptable = nil
        },
        celestialAlignmentReady = false,

    }

    self:UpdateFramePosition()
end


-- Enable or disable update timer based on current specialization
function BalanceSpellSuggest:ACTIVE_TALENT_GROUP_CHANGED()
    local currentSpec = GetSpecialization()
    if tonumber(currentSpec) == 1 then
        self:EnableTimer()
    else
        self:DisableTimer()
    end
end


-- Called on login
function BalanceSpellSuggest:OnEnable()
    -- enable or diable based on current spec
    self:ACTIVE_TALENT_GROUP_CHANGED()
end


-- Called after a spec change to non-balance
function BalanceSpellSuggest:OnDisable()
    self:DisableTimer()
end


-- Enables the update timer
function BalanceSpellSuggest:EnableTimer()
    if self.updateTimer == nil then
        self.updateTimer = self:ScheduleRepeatingTimer("UpdateFrames", 0.1)
    end
end


-- Disables the update timer
function BalanceSpellSuggest:DisableTimer()
    if self.updateTimer ~= nil then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end

    self.suggestFrame:Hide()
end


function BalanceSpellSuggest:ProfileChanged()
    self:UpdateFramePosition()
    self:RecreateAllFonts()
end


function BalanceSpellSuggest:RecreateAllFonts()
    BalanceSpellSuggest:RecreateFonts(BalanceSpellSuggest.moonfireFrame)
    BalanceSpellSuggest:RecreateFonts(BalanceSpellSuggest.sunfireFrame)
end


-- Updates the position and the size of the frames
function BalanceSpellSuggest:UpdateFramePosition()
    self.suggestFrame:SetPoint("CENTER", self.db.profile.xPosition, self.db.profile.yPosition)

    if self.db.profile.timers then
        self.suggestFrame:SetWidth(self.db.profile.size * 3)
        self.moonfireFrame:Show()
        self.sunfireFrame:Show()
    else
        self.suggestFrame:SetWidth(self.db.profile.size)
        self.moonfireFrame:Hide()
        self.sunfireFrame:Hide()
    end

    self.suggestFrame:SetHeight(self.db.profile.size)

    self.nextSpellFrame:SetHeight(self.db.profile.size)
    self.nextSpellFrame:SetWidth(self.db.profile.size)

    self.moonfireFrame:SetHeight(self.db.profile.size)
    self.moonfireFrame:SetWidth(self.db.profile.size)
    self.moonfireFrame:SetPoint("CENTER", -self.db.profile.size, 0)

    self.sunfireFrame:SetHeight(self.db.profile.size)
    self.sunfireFrame:SetWidth(self.db.profile.size)
    self.sunfireFrame:SetPoint("CENTER", self.db.profile.size, 0)
end


-- Toggles the frame lock of the suggestFrame
function BalanceSpellSuggest:ToggleFrameLock(_, val)
    self.db.profile.locked = val
    if self.db.profile.locked then
        self.suggestFrame:SetMovable(false)
        self.suggestFrame:EnableMouse(false)
        self.suggestFrame:SetScript("OnDragStart", function() end)
        self.suggestFrame:SetScript("OnDragStop", function() end)
        local frames = { self.suggestFrame:GetChildren() }
        for _, frame in ipairs(frames) do
            frame.texture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
        end
    else
        self.suggestFrame:SetMovable(true)
        self.suggestFrame:EnableMouse(true)
        self.suggestFrame:SetScript("OnDragStart", self.suggestFrame.StartMoving)
        self.suggestFrame:SetScript("OnDragStop", function(self, button) BalanceSpellSuggest:StopMoving(self, button) end)
        local frames = { self.suggestFrame:GetChildren() }
        for _, frame in ipairs(frames) do
            frame.texture:SetVertexColor(1.0, 1.0, 1.0, 0.5)
        end
    end
end


-- Set up all needed frames
function BalanceSpellSuggest:SetUpFrames()
    -- the main frame hosting all other frames
    self.suggestFrame = CreateFrame("Frame", "BSS_Main", UIParent)
    self.suggestFrame:SetFrameStrata("BACKGROUND")
    if self.db.profile.timers then
        self.suggestFrame:SetWidth(self.db.profile.size * 3)
    else
        self.suggestFrame:SetWidth(self.db.profile.size)
    end
    self.suggestFrame:SetHeight(self.db.profile.size)
    self.suggestFrame:SetPoint("CENTER", self.db.profile.xPosition, self.db.profile.yPosition)
    self.suggestFrame:RegisterForDrag("LeftButton")

    if self.db.profile.locked then
        self.suggestFrame:SetMovable(false)
        self.suggestFrame:EnableMouse(false)
    else
        self.suggestFrame:SetMovable(true)
        self.suggestFrame:EnableMouse(true)
        self.suggestFrame:Show()
    end

    -- the frame for the next spell texture
    self.nextSpellFrame = CreateFrame("Button", "BSS_Next", self.suggestFrame)
    self.nextSpellFrame:SetFrameStrata("BACKGROUND")
    self.nextSpellFrame:SetWidth(self.db.profile.size)
    self.nextSpellFrame:SetHeight(self.db.profile.size)
    self.nextSpellFrame:SetPoint("CENTER", 0, 0)
    self.nextSpellFrame.texture = self.nextSpellFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    self.nextSpellFrame.texture:SetTexture(starfire)
    self.nextSpellFrame.texture:SetAllPoints()
    self.nextSpellFrame.glowTexture = self.nextSpellFrame:CreateTexture(nil, "LOW", nil, 1)
    self.nextSpellFrame.glowTexture:SetTexture(glowTexturePath)
    self.nextSpellFrame.glowTexture:SetAllPoints()
    self.nextSpellFrame.glowTexture:SetShown(false)

    -- the frame for the moonfire timer
    self.moonfireFrame = self:CreateTimerFrame("BSS_Moonfire", moonfire, -self.db.profile.size, 0)

    -- the frame for the sunfire timer
    self.sunfireFrame = self:CreateTimerFrame("BSS_Sunfire", sunfire, self.db.profile.size, 0)
end


-- Creates a timer frame
function BalanceSpellSuggest:CreateTimerFrame(name, texturePath, xOfs, yOfs)
    local frame  = CreateFrame("Button", name, self.suggestFrame)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetWidth(self.db.profile.size)
    frame:SetHeight(self.db.profile.size)
    frame:SetPoint("CENTER", xOfs, yOfs)
    frame.texture = frame:CreateTexture(nil, "ARTWORK", nil ,0)
    frame.texture:SetTexture(texturePath)
    frame.texture:SetAllPoints()
    frame.glowTexture = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.glowTexture:SetTexture(glowTexturePath)
    frame.glowTexture:SetTexCoord(0.082, 0.44, 0.315, 0.49)
    frame.glowTexture:SetAllPoints()
    frame.glowTexture:SetShown(false)
    frame.text = frame:CreateFontString(nil, "LOW")
    frame.text:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.font), self.db.profile.normalfontsize, self.db.profile.fontoptions)
    frame.text:SetTextColor(1, 1, 1, 1)
    frame.text:SetAllPoints()
    frame.text:SetShown(false)
    frame.highlightText = frame:CreateFontString(nil, "LOW")
    frame.highlightText:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.font), self.db.profile.highlightfontsize, self.db.profile.fontoptions)
    frame.highlightText:SetTextColor(1, 0, 0, 1)
    frame.highlightText:SetAllPoints()
    frame.highlightText:SetShown(false)
    return frame
end


-- Recreates the normal and highlight fonts for a frame
function BalanceSpellSuggest:RecreateFonts(frame)
    local oldtext = frame.text
    frame.text = frame:CreateFontString(nil, "LOW")
    frame.text:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.font), self.db.profile.normalfontsize, self.db.profile.fontoptions)
    frame.text:SetTextColor(1, 1, 1, 1)
    frame.text:SetAllPoints()
    oldtext:SetShown(false)
    oldtext = frame.highlightText
    frame.highlightText = frame:CreateFontString(nil, "LOW")
    frame.highlightText:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.font), self.db.profile.highlightfontsize, self.db.profile.fontoptions)
    frame.highlightText:SetTextColor(1, 0, 0, 1)
    frame.highlightText:SetAllPoints()
    oldtext:SetShown(false)
end


-- Called on drag stop from the suggestFrame
function BalanceSpellSuggest:StopMoving(frame, _)
    frame:StopMovingOrSizing()

    -- get the coordinates for the offset from center
    for pointnum = 1, frame:GetNumPoints() do
        local point, _, _, x, y = frame:GetPoint(pointnum)
        if point == "CENTER" then
            self.db.profile.xPosition = x
            self.db.profile.yPosition = y
            break
        end
    end

end


-- Updates the suggestFrame visibility and the inner frames textures/strings
function BalanceSpellSuggest:UpdateFrames()
    -- drag/drop  mode
    if not self.db.profile.locked then
        self.suggestFrame:Show()
        return
    end

    -- we need a target
    if not UnitExists("target") then
        self.suggestFrame:Hide()
        return
    end

    -- which is attackable
    if not UnitCanAttack("player", "target") then
        self.suggestFrame:Hide()
        return
    end

    -- and alive
    if UnitIsDead("target") then
        self.suggestFrame:Hide()
        return
    end

    self.suggestFrame:Show()

    self:UpdatePlayerState()

--    if self.player.buffs.empoweredMoonkin then
--        self.nextSpellFrame.glowTexture:SetShown(true)
--    else
--        self.nextSpellFrame.glowTexture:SetShown(false)
--    end

    if self.player.buffs.lunarPeak then
        if self.db.profile.display.peakGlow == "normal" then
            self.moonfireFrame.glowTexture:SetShown(true)
        elseif self.db.profile.display.peakGlow == "spellalert" then
            ActionButton_ShowOverlayGlow(self.moonfireFrame)
        end
    else
        self.moonfireFrame.glowTexture:SetShown(false)
        ActionButton_HideOverlayGlow(self.moonfireFrame)
    end

    if self.player.buffs.solarPeak then
        if self.db.profile.display.peakGlow == "normal" then
            self.sunfireFrame.glowTexture:SetShown(true)
        elseif self.db.profile.display.peakGlow == "spellalert" then
            ActionButton_ShowOverlayGlow(self.sunfireFrame)
        end
    else
        self.sunfireFrame.glowTexture:SetShown(false)
        ActionButton_HideOverlayGlow(self.sunfireFrame)
    end

    -- some shared stuff
    local time = GetTime()
    local targetMoonfire = 0 -- duration, 0 if not applied
    local targetSunfire = 0  -- duration, 0 if not applied
    local _,_,_,_,_,_,mET,mC = UnitAura("target", moonfirename, nil, "PLAYER|HARMFUL") -- Moonfire
    if mET and mC == "player" then
        targetMoonfire = mET - time
    end
    local _,_,_,_,_,_,sET,sC = UnitAura("target", sunfirename, nil, "PLAYER|HARMFUL") -- Sunfire
    if sET and sC == "player" then
        targetSunfire = sET - time
    end

    local newTexturePath = self:GetNextSpell(time, targetMoonfire, targetSunfire)
    self.nextSpellFrame.texture:SetTexture(newTexturePath)
    self.nextSpellFrame.texture:SetAllPoints(self.nextSpellFrame)

    if self.db.profile.timers then
        self:TimerFrameUpdate(self.moonfireFrame, targetMoonfire)
        self:TimerFrameUpdate(self.sunfireFrame, targetSunfire)
    end
end


function BalanceSpellSuggest:UpdatePlayerState()
    local _,_,_,mfC = UnitBuff("player", moonkinformname)
    if mfC ~= nil then
        self.player.moonkinForm = true
    else
        self.player.moonkinForm = false
    end

    local _,_,_,_,_,_,emET = UnitBuff("player", empoweredMoonkin)
    if emET then
        self.player.buffs.empoweredMoonkin = true
    else
        self.player.buffs.empoweredMoonkin = false
    end

    local power = UnitPower("player", 8)
    self.player.direction = GetEclipseDirection()
    if power < 0 then
        self.player.power = power * -1
        self.player.inLunar = true
        self.player.inSolar = false
    elseif power > 0 then
        self.player.power = power
        self.player.inLunar = false
        self.player.inSolar = true
    else
        self.player.power = 0
        self.player.inLunar = false
        self.player.inSolar = false
    end

    local spell, _, _, icon, startTime, endTime, _, id, interrupt = UnitCastingInfo("player")
    self.player.currentCast.spell = spell
    self.player.currentCast.icon = icon
    self.player.currentCast.startTime = startTime
    self.player.currentCast.endTime = endTime
    self.player.currentCast.id = id
    self.player.currentCast.interruptable = interrupt

    if select(2, GetSpellCooldown(112071)) == 0 then
        self.player.celestialAlignmentReady = true
    else
        self.player.celestialAlignmentReady = false
    end

    local _,_,_,lpC,_,_,lpET = UnitBuff("player", lunarpeakname)
    local _,_,_,spC,_,_,spET = UnitBuff("player", solarpeakname)
    if lpET then
        self.player.buffs.lunarPeak = true
    else
        self.player.buffs.lunarPeak = false
    end
    if spET then
        self.player.buffs.solarPeak = true
    else
        self.player.buffs.solarPeak = false
    end
end


function BalanceSpellSuggest:TimerFrameUpdate(frame, duration)
    if duration <= 0 then
        frame.texture:SetVertexColor(1.0, 0, 0)
        frame.text:SetShown(false)
        frame.highlightText:SetShown(false)
    else
        frame.texture:SetVertexColor(1.0, 1.0, 1.0)
        if duration <= self.db.profile.dotRefreshTime then
            frame.text:SetShown(false)
            frame.highlightText:SetShown(true)
            frame.highlightText:SetText(string.format("%.1f", duration))
        else
            frame.text:SetShown(true)
            frame.highlightText:SetShown(false)
            frame.text:SetText(string.format("%.0f", duration))
        end
    end
end


-- find out which spell should be cast next
function BalanceSpellSuggest:GetNextSpell(time, targetMoonfire, targetSunfire)
    local player = self.player

    if not player.moonkinForm then
        return moonkinform
    end

    local inCelestialAlignment = false
    local celestialalignmentDuration = 0
    local _,_,_,_,_,_,caET = UnitBuff("player", celestialalignmentname)
    if caET then
        celestialalignmentDuration = caET - time
        inCelestialAlignment = true
    end

    local minStarsurgeCharges = 0
    if self.db.profile.leaveOneSSCharge then
        minStarsurgeCharges = 1
    end
    local starsurgeCharges = select(1, GetSpellCharges(78674)) -- Starsurge
    local starsurgeLunarBonus = 0 -- charges, 0 if not applied
    local starsurgeSolarBonus = 0 -- charges, 0 if not applied
    local _,_,_,leC,_,_,leET = UnitBuff("player", lunarempowermentname)
    local _,_,_,seC,_,_,seET = UnitBuff("player", solarempowermentname)
    if leET then
        starsurgeLunarBonus = tonumber(leC)
    end
    if seET then
        starsurgeSolarBonus = tonumber(seC)
    end

    local dotDur = 20
    local _, _, _, t1, t2  = GetTalentInfo(7, 1, GetActiveSpecGroup())
    if t1 and t2 then
        dotDur = 10
    end

    local targetclassification = UnitClassification("target")
    local targetLevel = UnitLevel("target")
    local targetIsBoss = false
    if targetclassification == "worldboss" or ((targetLevel < 0 or targetLevel == UnitLevel("player") + 2) and targetclassification == "elite") then
        targetIsBoss = true
    end

    -- priority logic here

    if inCelestialAlignment then
        -- always do the lunar cycle
        if targetSunfire < self.db.profile.dotRefreshTime
        or (celestialalignmentDuration < 4 and targetSunfire < dotDur) then
            return moonfire
        end

        if starsurgeCharges > 0 then
            if ((starsurgeCharges == 3 or starsurgeLunarBonus == 0) and player.currentCast.spell ~= starfirename)
            or (starsurgeLunarBonus == 1 and player.currentCast.spell == starfirename) then
                return starsurge
            end
        end

        return starfire
    end

    if player.inLunar then
        if player.celestialAlignmentReady and not (self.db.profile.caOnBossOnly and not targetIsBoss) then
            return celestialalignment
        end

        if targetMoonfire < self.db.profile.dotRefreshTime
        or (player.direction == "sun" and player.power <= self.db.profile.dotRefreshPower and targetMoonfire <= dotDur)
        or (player.buffs.lunarPeak and self.db.profile.behavior.peakBehavior == "always")
        or (player.buffs.lunarPeak and self.db.profile.behavior.peakBehavior == "time" and targetMoonfire < (dotDur * 1.5)) then
            return moonfire
        end

        if inCelestialAlignment then
            minStarsurgeCharges = 0
        end

        if starsurgeCharges > minStarsurgeCharges then
            if (starsurgeCharges == 3 and starsurgeLunarBonus > 0) then
                return starfall
            end
            if ((starsurgeCharges == 3 or starsurgeLunarBonus == 0) and player.currentCast.spell ~= starsurgename)
            or (starsurgeLunarBonus == 1 and player.currentCast.spell == starfirename) then
                return starsurge
            end
        end

        if player.direction == "moon" then
            return starfire
        end

        if player.direction == "sun" then
            if player.power > self.db.profile.starfireWrathTippingPoint then
                return starfire
            else
                return wrath
            end
        end
    elseif player.inSolar then
        if targetSunfire < self.db.profile.dotRefreshTime
        or (player.direction == "sun" and player.power > 0 and targetSunfire < 10)
        or (player.direction == "moon" and player.power <= self.db.profile.dotRefreshPower and targetSunfire <= dotDur)
        or (player.buffs.solarPeak and self.db.profile.behavior.peakBehavior == "always")
        or (player.buffs.solarPeak and self.db.profile.behavior.peakBehavior == "time" and targetSunfire < (dotDur * 1.5)) then
            return sunfire
        end

        if starsurgeCharges > minStarsurgeCharges then
            if (starsurgeCharges == 3 and starsurgeSolarBonus > 0) then
                return starfall
            end
            if ((starsurgeCharges == 3 or starsurgeSolarBonus == 0) and player.currentCast.spell ~= starsurgename)
            or (starsurgeSolarBonus == 1 and player.currentCast.spell == wrathname) then
                return starsurge
            end
        end

        if player.direction == "sun" then
            return wrath
        end

        if player.direction == "moon" then
            if player.power > self.db.profile.wrathStarfireTippingPoint then
                return wrath
            else
                return starfire
            end
        end
    else
        -- opener
        if player.currentCast.spell == starfirename then
            return moonfire
        end
        return starfire
    end
end
