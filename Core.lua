if select(2, UnitClass("player")) ~= "DRUID" then
    -- no druid, no addon
    return
end

BalanceSpellSuggest = LibStub("AceAddon-3.0"):NewAddon("BalanceSpellSuggest", "AceTimer-3.0", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("BalanceSpellSuggest", true)

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
                    order = 0,
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
                    order = 1,
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
                    order = 2,
                    min = 0,
                    max = 100,
                    softMin = 10,
                    softMax = 50,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.wrathStarfireTippingPoint = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.wrathStarfireTippingPoint end
                }
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
                timers = {
                    name = L["DoT Timer"],
                    type = "header",
                    order = 3,
                },
                timersToggle = {
                    name = L["Enable timers"],
                    type = "toggle",
                    order = 4,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.timers = val
                        BalanceSpellSuggest:UpdateFramePosition()
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.timers end
                },
                normalFontSize = {
                    name = L["Font size"],
                    type = "range",
                    order = 5,
                    min = 1,
                    max = 100,
                    softMin = 10,
                    softMax = 100,
                    step = 1,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.normalfontsize = val
                        BalanceSpellSuggest:RecreateFonts(BalanceSpellSuggest.moonfireFrame)
                        BalanceSpellSuggest:RecreateFonts(BalanceSpellSuggest.sunfireFrame)
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.normalfontsize end
                },
                highlightFontSize = {
                    name = L["Highlight font size"],
                    type = "range",
                    order = 6,
                    min = 1,
                    max = 100,
                    softMin = 10,
                    softMax = 100,
                    step = 1,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.highlightfontsize = val
                        BalanceSpellSuggest:RecreateFonts(BalanceSpellSuggest.moonfireFrame)
                        BalanceSpellSuggest:RecreateFonts(BalanceSpellSuggest.sunfireFrame)
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.highlightfontsize end
                }
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
        xPosition = 0,
        yPosition = 0,
        locked = true,
        timers = true,
        normalfontsize = 25,
        highlightfontsize = 32,
        font = "Fonts\\FRIZQT__.TTF",
    }
}


-- spells and stuff
local moonfirename,_,moonfire = GetSpellInfo(164812)
local sunfirename,_,sunfire = GetSpellInfo(164815)
local starsurgename,_,starsurge = GetSpellInfo(78674)
local starfirename,_,starfire =  GetSpellInfo(2912)
local wrathname,_,wrath = GetSpellInfo(5176)
local celestialalignmentname,_,celestialalignment = GetSpellInfo(112071)
local moonkinformname,_,moonkinform = GetSpellInfo(24858)

local lunarempowermentname = GetSpellInfo(164547)
local solarempowermentname = GetSpellInfo(164545)


-- Always called
function BalanceSpellSuggest:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BalanceSpellSuggestDB", defaults, true)
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BalanceSpellSuggest", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BalanceSpellSuggest", "Balance Spell Suggest")
    BalanceSpellSuggest:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

    self:SetUpFrames()

    self.db.RegisterCallback(self, "OnProfileChanged", "UpdateFramePosition")
    self.db.RegisterCallback(self, "OnProfileCopied", "UpdateFramePosition")
    self.db.RegisterCallback(self, "OnProfileReset", "UpdateFramePosition")
end


-- Enable or disable update timer based on current specialization
function BalanceSpellSuggest:ACTIVE_TALENT_GROUP_CHANGED()
    local currentSpec = GetSpecialization()
    if tonumber(currentSpec) == 1 then
        BalanceSpellSuggest:EnableTimer()
    else
        BalanceSpellSuggest:DisableTimer()
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


-- Updates the position and the size of the frames
function BalanceSpellSuggest:UpdateFramePosition()
    self.suggestFrame:SetPoint("CENTER", self.db.profile.xPosition, self.db.profile.yPosition)

    if self.db.profile.timers then
        self.suggestFrame:SetWidth(64+64+64)
        self.moonfireFrame:Show()
        self.sunfireFrame:Show()
    else
        self.suggestFrame:SetWidth(64)
        self.moonfireFrame:Hide()
        self.sunfireFrame:Hide()
    end

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
    self.suggestFrame = CreateFrame("Frame", "BSP_Main", UIParent)
    self.suggestFrame:SetFrameStrata("BACKGROUND")
    -- TODO: calculate size based on inner frame sizes
    if self.db.profile.timers then
        self.suggestFrame:SetWidth(64+128)
    else
        self.suggestFrame:SetWidth(64)
    end
    self.suggestFrame:SetHeight(64)
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
    self.nextSpellFrame = CreateFrame("Frame", "BSP_Next", self.suggestFrame)
    self.nextSpellFrame:SetFrameStrata("BACKGROUND")
    -- TODO: make size adjustable
    self.nextSpellFrame:SetWidth(64)
    self.nextSpellFrame:SetHeight(64)
    self.nextSpellFrame:SetPoint("CENTER", 0, 0)
    local suggestTexture = self.nextSpellFrame:CreateTexture(nil, "ARTWORK")
    self.nextSpellFrame.texture = suggestTexture

    -- the frame for the moonfire timer
    self.moonfireFrame = self:CreateTimerFrame("BSP_Moonfire", moonfire, -64, 0)

    -- the frame for the sunfire timer
    self.sunfireFrame = self:CreateTimerFrame("BSP_Sunfire", sunfire, 64, 0)
end


-- Creates a timer frame
function BalanceSpellSuggest:CreateTimerFrame(name, texturePath, xOfs, yOfs)
    local frame  = CreateFrame("Frame", name, self.suggestFrame)
    frame:SetFrameStrata("BACKGROUND")
    -- TODO: make size adjustable
    frame:SetWidth(64)
    frame:SetHeight(64)
    frame:SetPoint("CENTER", xOfs, yOfs)
    frame.texture = frame:CreateTexture(nil, "ARTWORK")
    frame.texture:SetTexture(texturePath)
    frame.texture:SetAllPoints()
    frame.text = frame:CreateFontString(nil, "LOW")
    frame.text:SetFont(self.db.profile.font, self.db.profile.normalfontsize, "OUTLINE, MONOCHROME")
    frame.text:SetTextColor(1, 1, 1, 1)
    frame.text:SetAllPoints()
    frame.text:SetShown(false)
    frame.highlightText = frame:CreateFontString(nil, "LOW")
    frame.highlightText:SetFont(self.db.profile.font, self.db.profile.highlightfontsize, "OUTLINE, MONOCHROME")
    frame.highlightText:SetTextColor(1, 0, 0, 1)
    frame.highlightText:SetAllPoints()
    frame.highlightText:SetShown(false)
    return frame
end


-- Recreates the normal and highlight fonts for a frame
function BalanceSpellSuggest:RecreateFonts(frame)
    local oldtext = frame.text
    frame.text = frame:CreateFontString(nil, "LOW")
    frame.text:SetFont(self.db.profile.font, self.db.profile.normalfontsize, "OUTLINE, MONOCHROME")
    frame.text:SetTextColor(1, 1, 1, 1)
    frame.text:SetAllPoints()
    oldtext:SetShown(false)
    oldtext = frame.highlightText
    frame.highlightText = frame:CreateFontString(nil, "LOW")
    frame.highlightText:SetFont(self.db.profile.font, self.db.profile.highlightfontsize, "OUTLINE, MONOCHROME")
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

    self:TimerFrameUpdate(self.moonfireFrame, targetMoonfire)
    self:TimerFrameUpdate(self.sunfireFrame, targetSunfire)

end


function BalanceSpellSuggest:TimerFrameUpdate(frame, duration)
    if duration == 0 then
        frame.texture:SetVertexColor(1.0, 0, 0)
        frame.text:SetShown(false)
        frame.highlightText:SetShown(false)
    else
        frame.texture:SetVertexColor(1.0, 1.0, 1.0)
        if duration <= self.db.profile.dotRefreshTime then
            -- switch to highlight size
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
    local _,_,_,mfC = UnitBuff("player", moonkinformname)
    if mfC == nil then
        return moonkinform
    end

    local power = UnitPower("player", 8)
    local inLunar = false
    local inSolar = false
    local direction = GetEclipseDirection()
    if power < 0 then
        inLunar = true
        power = (power*-1)
    elseif power > 0 then
        inSolar = true
    else
        -- nothing, tipping point
    end

    local currentCast = UnitCastingInfo("player")

    local caReady = false
    local caCD = select(2, GetSpellCooldown(112071))
    if caCD == 0 then
        caReady = true
    end
    local inCelestialAlignment = false
    local celestialalignmentDuration = 0
    local _,_,_,_,_,_,caET = UnitBuff("player", celestialalignmentname)
    if caET then
        celestialalignmentDuration = caET - time
        inCelestialAlignment = true
    end

    local starsurgeCharges = select(1, GetSpellCharges(78674)) -- Starsurge

    local starsurgeLunarBonus = 0 -- charges, 0 if not applied
    local starsurgeSolarBonus = 0 -- charges, 0 if not applied
    local _,_,_,leC,_,_,leET = UnitBuff("player", lunarempowermentname) -- Lunar Empowerment
    local _,_,_,seC,_,_,seET = UnitBuff("player", solarempowermentname) -- Solar Empowerment
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

    -- priority logic here

    if inLunar then
        if targetMoonfire < self.db.profile.dotRefreshTime
        or (direction == "sun" and power <= self.db.profile.dotRefreshPower and targetMoonfire <= dotDur)
        or (inCelestialAlignment and targetSunfire < self.db.profile.dotRefreshTime)
        or (inCelestialAlignment and celestialalignmentDuration < 4 and targetSunfire < dotDur) then
            return moonfire
        end

        if power == 100 and caReady then
            return celestialalignment
        end

        local minStarsurgeCharges = 1
        if inCelestialAlignment then
            minStarsurgeCharges = 0
        end

        if starsurgeCharges > minStarsurgeCharges then
            if starsurgeCharges == 3
            or starsurgeLunarBonus == 0
            or (starsurgeLunarBonus == 1 and currentCast == starfirename) then
                if currentCast == starsurgename then
                    -- nothing
                else
                    return starsurge
                end
            end
        end

        if direction == "moon" then
            return starfire
        end

        if direction == "sun" then
            if power > self.db.profile.starfireWrathTippingPoint then
                return starfire
            else
                return wrath
            end
        end
    elseif inSolar then
        if targetSunfire < self.db.profile.dotRefreshTime
        or (direction == "sun" and power > 0 and targetSunfire < 10)
        or (direction == "moon" and power <= self.db.profile.dotRefreshPower and targetSunfire <= dotDur) then
            return sunfire
        end

        if starsurgeCharges > 1 then
            if starsurgeCharges == 3
            or starsurgeSolarBonus == 0
            or (starsurgeSolarBonus == 1 and currentCast == wrathname) then
                if currentCast == starsurgename then
                    -- nothing
                else
                    return starsurge
                end
            end
        end

        if direction == "sun" then
            return wrath
        end

        if direction == "moon" then
            if power > self.db.profile.wrathStarfireTippingPoint then
                return wrath
            else
                return starfire
            end
        end
    else
        -- opener
        if currentCast == starfirename then
            return moonfire
        end
        return starfire
    end
end
