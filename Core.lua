if select(2, UnitClass("player")) ~= "DRUID" then
    -- no druid, no addon
    return
end

BalanceSpellSuggest = LibStub("AceAddon-3.0"):NewAddon("BalanceSpellSuggest", "AceTimer-3.0", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("BalanceSpellSuggest", true)
local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

BalanceSpellSuggest.suggestFrame = nil
BalanceSpellSuggest.curSpellFrame = nil
BalanceSpellSuggest.nextSpellFrame = nil
BalanceSpellSuggest.moonfireFrame = nil
BalanceSpellSuggest.sunfireFrame = nil
BalanceSpellSuggest.updateTimer = nil

BalanceSpellSuggest.predictor = {}

do
    -- Adapted from BlanacePowerTracker
    local a, ai, b, bi
    local euphoriaValues = {104.5, 1/3.2 }
    local normalValues = {104.5, math.pi/20 }

    local energyToTime = function(energy, direction)
        if direction == "sun" then
            return ((math.asin(energy * ai) + math.pi) * bi)
        else -- lunar and none
            return (math.asin(energy * ai) * bi * -1)
        end
    end

    BalanceSpellSuggest.predictor.updateValues = function(euphoria)
        a, b = unpack((euphoria and euphoriaValues) or normalValues)
        ai = 1/ a
        bi = 1/ b
    end

    BalanceSpellSuggest.predictor.getEnergy = function(casttime, player)
        local startEnergy
        if player.currentCast.startPower ~= nil then
            startEnergy = player.currentCast.startPower
        else
            startEnergy = player.rawPower
        end
        local timenow = energyToTime(startEnergy, player.direction)
        local temp = math.sin((timenow + casttime) * b) * a
        return math.min(math.max(math.floor(temp), -100), 100) * -1
    end
end

-- https://gist.github.com/MihailJP/3931841
local function clone (t) -- deep-copy a table
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            target[k] = clone(v)
        else
            target[k] = v
        end
    end
    setmetatable(target, meta)
    return target
end

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
                stellarFlarePowerWindow = {
                    name = L["Stellar Flare power window"],
                    desc = L["sfPowerWindowDesc"],
                    type = "range",
                    order = 1,
                    min = 1,
                    max = 90,
                    softMin = 5,
                    softMax = 30,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.stellarFlarePowerWindow = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.stellarFlarePowerWindow end
                },
                leaveOneSSCharge = {
                    name = L["Leave one SS charge"],
                    desc = L["leaveOneSSChargeDesc"],
                    type = "toggle",
                    order = 5,
                    set = function(_, val) BalanceSpellSuggest.db.profile.leaveOneSSCharge = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.leaveOneSSCharge end
                },
                caBehavior = {
                    name = L["CA behavior"],
                    desc = L["CABehaviorDesc"],
                    type = "select",
                    order = 6,
                    values = { always = L["CABehaviorAlways"], boss = L["CABehaviorBoss"], never = L["CABehaviorNever"] },
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.caBehavior = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.caBehavior end
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
                spacing = {
                    name = L["Spacing"],
                    desc = L["spacingDesc"],
                    type = "range",
                    order = 4,
                    min = 0,
                    max = 1000,
                    softMin = 0,
                    softMax = 100,
                    step = 1,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.display.spacing = val
                        BalanceSpellSuggest:UpdateFramePosition()
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.display.spacing end
                },
                misc = {
                    name = L["Misc"],
                    type = "header",
                    order = 100,
                },
                predictedEnergy = {
                    name = L["predictedEnergyShow"],
                    desc = L["predictedEnergyShowDesc"],
                    type = "toggle",
                    order = 101,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.display.predictedEnergy.show = val
                        BalanceSpellSuggest:UpdateFramePosition()
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.display.predictedEnergy.show end
                },
                predictedEnergyFontSize = {
                    name = L["predictedEnergyFontSize"],
                    type = "range",
                    order = 102,
                    min = 1,
                    max = 100,
                    softMin = 10,
                    softMax = 100,
                    step = 1,
                    set = function(_, val)
                        BalanceSpellSuggest.db.profile.display.predictedEnergy.fontSize = val
                        BalanceSpellSuggest:RecreateAllFonts()
                    end,
                    get = function(_) return BalanceSpellSuggest.db.profile.display.predictedEnergy.fontSize end
                },
                timers = {
                    name = L["DoT Timer"],
                    type = "header",
                    order = 200,
                },
                timersToggle = {
                    name = L["Enable timers"],
                    type = "toggle",
                    order = 201,
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
                    order = 202,
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
                    order = 203,
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
                    order = 204,
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
                    order = 205,
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
        dotRefreshTime = 7,
        leaveOneSSCharge = true,
        xPosition = 0,
        yPosition = 0,
        size = 64,
        locked = true,
        timers = true,
        normalfontsize = 15,
        highlightfontsize = 17,
        font = "Friz Quadrata TT",
        fontoptions = "OUTLINE",
        behavior = {
            stellarFlarePowerWindow = 20,
            peakBehavior = "time",
            caBehavior = "boss",
        },
        display = {
            peakGlow = "normal",
            spacing = 0,
            predictedEnergy = {
                show = true,
                fontSize = 15,
            }
        },
    }
}


-- spells and stuff
local moonfirename,_,moonfire = GetSpellInfo(164812)
local sunfirename,_,sunfire = GetSpellInfo(164815)
local starsurgename,_,starsurge = GetSpellInfo(78674)
local starfirename,_,starfire =  GetSpellInfo(2912)
local wrathname,_,wrath = GetSpellInfo(5176)
local stellarflarename,_,stellarflare = GetSpellInfo(152221)
local starfallname,_,starfall = GetSpellInfo(48505)
local celestialalignmentname,_,celestialalignment = GetSpellInfo(112071)
local incarnationname,_,incarnation = GetSpellInfo(102560)
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
    BalanceSpellSuggest:RegisterEvent("CHARACTER_POINTS_CHANGED")
    BalanceSpellSuggest:RegisterEvent("PLAYER_REGEN_DISABLED")
    BalanceSpellSuggest:RegisterEvent("PLAYER_REGEN_ENABLED")
    BalanceSpellSuggest:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    BalanceSpellSuggest:RegisterEvent("PLAYER_ENTERING_WORLD")

    self.curSpell = BalanceSpellSuggest.curSpell
    self.nextSpell = BalanceSpellSuggest.nextSpell

    self:SetUpFrames()

    self.db.RegisterCallback(self, "OnProfileChanged", "ProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "ProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "ProfileChanged")

    self.baseGCD = 1.5

    self.player = {
        moonkinForm = false,
        buffs = {
            lunarPeak = false,
            solarPeak = false,
            empoweredMoonkin = false,
            celestialAlignment = 0,
            starfall = 0,
            starsurgeLunarBonus = 0,
            starsurgeSolarBonus = 0,
        },
        talents = {
            euphoria = false,
            stellarflare = false,
            incarnation = false,
        },
        castTimes = {
            starfire = 0,
            wrath = 0,
            stellarflare = 0,
            gcd = 1.5,
            starsurge = 1.5, -- GCD
            starfall = 1.5, -- GCD
            moonfire = 1.5, -- GCD
            sunfire = 1.5, -- GCD
            moonkinform = 1.5, -- GCD
            celestialalignment = 0, -- no GCD
            solarbeam = 0, -- no GCD
            naturesvigil = 0, -- no GCD
        },
        inCombat = false,
        power = 0,
        rawPower = 0,
        direction = "none",
        inLunar = false,
        inSolar = false,
        currentCast = {
            spell = nil,
            icon = nil,
            startTime = nil,
            startPower = nil,
            endTime = nil,
            id = nil,
            interruptable = nil
        },
        target = {
            debuffs = {
                moonfire = 0,
                sunfire = 0,
                stellarflare = 0,
            }
        },
        celestialAlignmentReady = false,
        starsurgeCharges = 0,
    }

    self:UpdateFramePosition()

    if self.masque then
        self.masque:ReSkin()
    end
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


function BalanceSpellSuggest:CHARACTER_POINTS_CHANGED()
    self:UpdatePlayerState()
    self.predictor.updateValues(self.player.talents.euphoria)
end


function BalanceSpellSuggest:PLAYER_REGEN_DISABLED()
    self.player.inCombat = true
end


function BalanceSpellSuggest:PLAYER_REGEN_ENABLED()
    self.player.inCombat = false
end


function BalanceSpellSuggest:PLAYER_ENTERING_WORLD()
    if self.masque then
        self.masque:ReSkin()
    end
end


function BalanceSpellSuggest:UNIT_SPELLCAST_SUCCEEDED(_, unit, name, rank, counter, id)
    if unit ~= "player" then
        return
    end
    if self.player.castTimes[string.lower(name)] ~= nil then
        self.curSpellFrame.cooldown:SetCooldown(GetTime(), self.player.castTimes.gcd)
    end
end


-- Called on login
function BalanceSpellSuggest:OnEnable()
    -- enable or diable based on current spec
    self:ACTIVE_TALENT_GROUP_CHANGED()
    self:CHARACTER_POINTS_CHANGED()
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
    self:RecreateSpellFonts(self.curSpellFrame)
    self:RecreateSpellFonts(self.nextSpellFrame)
end


-- Updates the position and the size of the frames
function BalanceSpellSuggest:UpdateFramePosition()
    self.suggestFrame:SetPoint("CENTER", self.db.profile.xPosition, self.db.profile.yPosition)

    if self.db.profile.timers then
        self.suggestFrame:SetWidth(self.db.profile.size * 3 + self.db.profile.display.spacing)
        self.moonfireFrame:Show()
        self.sunfireFrame:Show()
    else
        self.suggestFrame:SetWidth(self.db.profile.size * 2 + self.db.profile.display.spacing)
        self.moonfireFrame:Hide()
        self.sunfireFrame:Hide()
    end

    self.moonfireFrame:SetHeight(self.db.profile.size/2)
    self.moonfireFrame:SetWidth(self.db.profile.size/2)
    self.moonfireFrame:SetPoint("CENTER", -self.db.profile.size*0.75, self.db.profile.size/4)

    self.sunfireFrame:SetHeight(self.db.profile.size/2)
    self.sunfireFrame:SetWidth(self.db.profile.size/2)
    self.sunfireFrame:SetPoint("CENTER", -self.db.profile.size*0.75, -self.db.profile.size/4)


    self.suggestFrame:SetHeight(self.db.profile.size)

    self.curSpellFrame:SetHeight(self.db.profile.size)
    self.curSpellFrame:SetWidth(self.db.profile.size)

    self.nextSpellFrame:SetHeight(self.db.profile.size)
    self.nextSpellFrame:SetWidth(self.db.profile.size)
    self.nextSpellFrame:SetPoint("CENTER", self.db.profile.size + self.db.profile.display.spacing, 0)

    if self.db.profile.display.predictedEnergy.show then
        self.curSpellFrame.text:Show()
        self.nextSpellFrame.text:Show()
    else
        self.curSpellFrame.text:Hide()
        self.nextSpellFrame.text:Hide()
    end

    if self.masque then
        self.masque:ReSkin()
    end
end


-- Toggles the frame lock of the suggestFrame
function BalanceSpellSuggest:ToggleFrameLock(_, val)
    self.db.profile.locked = val
    if self.db.profile.locked then
        self.suggestFrame:SetFrameStrata("BACKGROUND")
        self.suggestFrame:SetMovable(false)
        self.suggestFrame:EnableMouse(false)
        self.suggestFrame:SetScript("OnDragStart", function() end)
        self.suggestFrame:SetScript("OnDragStop", function() end)
        local frames = { self.suggestFrame:GetChildren() }
        for _, frame in ipairs(frames) do
            frame.bssTexture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
        end
    else
        self.suggestFrame:SetFrameStrata("MEDIUM")
        self.suggestFrame:SetMovable(true)
        self.suggestFrame:EnableMouse(true)
        self.suggestFrame:SetScript("OnDragStart", self.suggestFrame.StartMoving)
        self.suggestFrame:SetScript("OnDragStop", function(self, button) BalanceSpellSuggest:StopMoving(self, button) end)
        local frames = { self.suggestFrame:GetChildren() }
        for _, frame in ipairs(frames) do
            frame.bssTexture:SetVertexColor(1.0, 1.0, 1.0, 0.5)
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
        self.suggestFrame:SetWidth(self.db.profile.size * 2)
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

    self.curSpellFrame = CreateFrame("Button", "BSS_Cur", self.suggestFrame)
    self.curSpellFrame:SetFrameStrata("BACKGROUND")
    self.curSpellFrame:SetWidth(self.db.profile.size)
    self.curSpellFrame:SetHeight(self.db.profile.size)
    self.curSpellFrame:SetPoint("CENTER", 0, 0)
    self.curSpellFrame:EnableMouse(false)
    self.curSpellFrame.bssTexture = self.curSpellFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    self.curSpellFrame.bssTexture:SetTexture(starfire)
    self.curSpellFrame.bssTexture:SetAllPoints()
    self.curSpellFrame.cooldown = CreateFrame("Cooldown", "BSS_Cur_CD", self.curSpellFrame, "CooldownFrameTemplate")
    self.curSpellFrame.cooldown:SetAllPoints()
    self.curSpellFrame.cooldown:SetReverse(true)
    self.curSpellFrame.cooldown:SetDrawBling(false)
    self.curSpellFrame.cooldown:Show()
    self.curSpellFrame.glowTexture = self.curSpellFrame:CreateTexture(nil, "LOW", nil, 1)
    self.curSpellFrame.glowTexture:SetTexture(glowTexturePath)
    self.curSpellFrame.glowTexture:SetAllPoints()
    self.curSpellFrame.glowTexture:SetShown(false)
    self.curSpellFrame.text = self.curSpellFrame:CreateFontString(nil, "LOW")
    self.curSpellFrame.text:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.font), self.db.profile.display.predictedEnergy.fontSize, self.db.profile.fontoptions)
    self.curSpellFrame.text:SetTextColor(1, 1, 1, 1)
    self.curSpellFrame.text:SetAllPoints()
    self.curSpellFrame.text:SetShown(true)

    -- the frame for the next spell texture
    self.nextSpellFrame = CreateFrame("Button", "BSS_Next", self.suggestFrame)
    self.nextSpellFrame:SetFrameStrata("BACKGROUND")
    self.nextSpellFrame:SetWidth(self.db.profile.size)
    self.nextSpellFrame:SetHeight(self.db.profile.size)
    self.nextSpellFrame:SetPoint("CENTER", self.db.profile.size + self.db.profile.display.spacing, 0)
    self.nextSpellFrame:EnableMouse(false)
    self.nextSpellFrame.bssTexture = self.nextSpellFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    self.nextSpellFrame.bssTexture:SetTexture(starfire)
    self.nextSpellFrame.bssTexture:SetAllPoints()
    self.nextSpellFrame.glowTexture = self.nextSpellFrame:CreateTexture(nil, "LOW", nil, 1)
    self.nextSpellFrame.glowTexture:SetTexture(glowTexturePath)
    self.nextSpellFrame.glowTexture:SetAllPoints()
    self.nextSpellFrame.glowTexture:SetShown(false)
    self.nextSpellFrame.text = self.nextSpellFrame:CreateFontString(nil, "LOW")
    self.nextSpellFrame.text:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.font), self.db.profile.display.predictedEnergy.fontSize, self.db.profile.fontoptions)
    self.nextSpellFrame.text:SetTextColor(1, 1, 1, 1)
    self.nextSpellFrame.text:SetAllPoints()
    self.nextSpellFrame.text:SetShown(true)

    -- the frame for the moonfire timer
    self.moonfireFrame = self:CreateTimerFrame("BSS_Moonfire", moonfire, -self.db.profile.size*0.75, self.db.profile.size/4)

    -- the frame for the sunfire timer
    self.sunfireFrame = self:CreateTimerFrame("BSS_Sunfire", sunfire, -self.db.profile.size*0.75, -self.db.profile.size/4)

    -- Setup Masque
    local masque = LibStub("Masque", true)
    if not masque then
        return
    end
    self.masque = masque:Group("Balance Spell Suggest", "Suggestion Icons")
    self.masque:AddButton(self.curSpellFrame, {Icon = self.curSpellFrame.bssTexture, Cooldown = self.curSpellFrame.cooldown, })
    self.masque:AddButton(self.nextSpellFrame, {Icon = self.nextSpellFrame.bssTexture})
    self.masque:ReSkin()
end


-- Creates a timer frame
function BalanceSpellSuggest:CreateTimerFrame(name, texturePath, xOfs, yOfs)
    local frame  = CreateFrame("Button", name, self.suggestFrame)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetWidth(self.db.profile.size/2)
    frame:SetHeight(self.db.profile.size/2)
    frame:SetPoint("CENTER", xOfs, yOfs)
    frame.bssTexture = frame:CreateTexture(nil, "ARTWORK", nil ,0)
    frame.bssTexture:SetTexture(texturePath)
    frame.bssTexture:SetAllPoints()
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


function BalanceSpellSuggest:RecreateSpellFonts(frame)
    local oldtext = frame.text
    frame.text = frame:CreateFontString(nil, "LOW")
    frame.text:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.font), self.db.profile.display.predictedEnergy.fontSize, self.db.profile.fontoptions)
    frame.text:SetTextColor(1, 1, 1, 1)
    frame.text:SetAllPoints()
    frame.text:SetShown(self.db.profile.display.predictedEnergy.show)
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
    self:UpdateTargetState()

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


    local curTexturePath, afterCurEnergy = self:curSpell()
    local nextTexturePath, afterNextEnergy = self:nextSpell(afterCurEnergy, curTexturePath)

    if curTexturePath then
        self.curSpellFrame.bssTexture:SetTexture(curTexturePath)
        self.curSpellFrame.bssTexture:SetAllPoints(self.curSpellFrame)
        self.curSpellFrame.text:SetText(string.format("%.0f", afterCurEnergy))
    end

    if nextTexturePath then
        self.nextSpellFrame.bssTexture:SetTexture(nextTexturePath)
        self.nextSpellFrame.bssTexture:SetAllPoints(self.nextSpellFrame)
        self.nextSpellFrame.text:SetText(string.format("%.0f", afterNextEnergy))
    end

    if self.db.profile.timers then
        self:TimerFrameUpdate(self.moonfireFrame, self.player.target.debuffs.moonfire)
        self:TimerFrameUpdate(self.sunfireFrame, self.player.target.debuffs.sunfire)
    end
end


function BalanceSpellSuggest:UpdatePlayerState()
    local time = GetTime()

    local _,_,_,mfC = UnitBuff("player", moonkinformname)
    if mfC ~= nil then
        self.player.moonkinForm = true
    else
        self.player.moonkinForm = false
    end

    local _, _, _, t1, t2  = GetTalentInfo(7, 1, GetActiveSpecGroup())
    if t1 and t2 then
        self.player.talents.euphoria = true
    else
        self.player.talents.euphoria = false
    end

    local _, _, _, t1, t2  = GetTalentInfo(7, 2, GetActiveSpecGroup())
    if t1 and t2 then
        self.player.talents.stellarflare = true
    else
        self.player.talents.stellarflare = false
    end

    local _,_,_,_,_,_,emET = UnitBuff("player", empoweredMoonkin)
    if emET then
        self.player.buffs.empoweredMoonkin = true
    else
        self.player.buffs.empoweredMoonkin = false
    end

    local _,_,_,_,_,_,caET = UnitBuff("player", celestialalignmentname)
    if caET then
        self.player.buffs.celestialAlignment = caET - time
    else
        self.player.buffs.celestialAlignment = 0
    end

    local power = UnitPower("player", 8)
    self.player.rawPower = power
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

    self.player.starsurgeCharges = select(1, GetSpellCharges(78674))
    local _,_,_,leC,_,_,leET = UnitBuff("player", lunarempowermentname)
    local _,_,_,seC,_,_,seET = UnitBuff("player", solarempowermentname)
    if leET then
        self.player.buffs.starsurgeLunarBonus = tonumber(leC)
    else
        self.player.buffs.starsurgeLunarBonus = 0
    end
    if seET then
        self.player.buffs.starsurgeSolarBonus = tonumber(seC)
    else
        self.player.buffs.starsurgeSolarBonus = 0
    end

    local spell, _, _, icon, startTime, endTime, _, id, interrupt = UnitCastingInfo("player")
    if startTime ~= nil and self.player.currentCast.startTime ~= startTime then
        self.player.currentCast.startPower = self.player.rawPower
    elseif spell == nil then
        self.player.currentCast.startPower = nil
    end

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

    local _,_,_,_,_,_,lpET = UnitBuff("player", lunarpeakname)
    local _,_,_,_,_,_,spET = UnitBuff("player", solarpeakname)
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

    local _,_,_,_,_,_,sfET = UnitBuff("player", starfallname)
    if sfET then
        self.player.buffs.starfall = sfET - time
    else
        self.player.buffs.starfall = 0
    end

    self:UpdatePlayerCastTimes()
end


function BalanceSpellSuggest:UpdatePlayerCastTimes()
    local _,_,_,starfirect =  GetSpellInfo(2912)
    local _,_,_,wrathct = GetSpellInfo(5176)
    local _,_,_,stellarflarect = GetSpellInfo(152221)
    local curHaste = UnitSpellHaste("player")
    self.player.castTimes.starfire = math.max(starfirect / 1000, 1)
    self.player.castTimes.wrath = math.max(wrathct / 1000, 1)
    self.player.castTimes.stellarflare = math.max(stellarflarect / 1000, 1)
    self.player.castTimes.moonfire = math.max(self.baseGCD * (1 - curHaste), 1)
    self.player.castTimes.sunfire = math.max(self.baseGCD * (1 - curHaste), 1)
    self.player.castTimes.starsurge = math.max(self.baseGCD * (1 - curHaste), 1)
    self.player.castTimes.starfall = math.max(self.baseGCD * (1 - curHaste), 1)
    self.player.castTimes.moonkinform = math.max(self.baseGCD * (1 - curHaste), 1)
    self.player.castTimes.gcd = math.max(self.baseGCD * (1 - curHaste), 1)
end


function BalanceSpellSuggest:UpdateTargetState()
    local time = GetTime()

    local _,_,_,_,_,_,mET,mC = UnitAura("target", moonfirename, nil, "PLAYER|HARMFUL") -- Moonfire
    if mET and mC == "player" then
        self.player.target.debuffs.moonfire = mET - time
    else
        self.player.target.debuffs.moonfire = 0
    end
    local _,_,_,_,_,_,sET,sC = UnitAura("target", sunfirename, nil, "PLAYER|HARMFUL") -- Sunfire
    if sET and sC == "player" then
        self.player.target.debuffs.sunfire = sET - time
    else
        self.player.target.debuffs.sunfire = 0
    end
    local _,_,_,_,_,_,sET,sC = UnitAura("target", stellarflarename, nil, "PLAYER|HARMFUL") -- Stellar Flare
    if sET and sC == "player" then
        self.player.target.debuffs.stellarflare = sET - time
    else
        self.player.target.debuffs.stellarflare = 0
    end

    local targetclassification = UnitClassification("target")
    local targetLevel = UnitLevel("target")
    if targetclassification == "worldboss" or ((targetLevel < 0 or targetLevel == UnitLevel("player") + 2) and targetclassification == "elite") then
        self.player.target.isBoss = true
    else
        self.player.target.isBoss = false
    end
end


function BalanceSpellSuggest:TimerFrameUpdate(frame, duration)
    if duration <= 0 then
        frame.bssTexture:SetVertexColor(1.0, 0, 0)
        frame.text:SetShown(false)
        frame.highlightText:SetShown(false)
    else
        frame.bssTexture:SetVertexColor(1.0, 1.0, 1.0)
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


function BalanceSpellSuggest:curSpell(player)
    local player = player or self.player

    if not player.moonkinForm then
        return moonkinform, 0
    end

    local minStarsurgeCharges = 0
    if self.db.profile.leaveOneSSCharge then
        minStarsurgeCharges = 1
    end

    local halfCycle = 20
    if player.talents.euphoria then
        halfCycle = 10
    end

    -- TODO opening rotation
    if not player.inCombat then
        return starfire, 0
    end

    if player.buffs.celestialAlignment > 0 then
        -- always do the lunar cycle
        if player.target.debuffs.sunfire < self.db.profile.dotRefreshTime
                or (player.buffs.celestialAlignment < 4 and player.target.debuffs.sunfire < halfCycle) then
            return moonfire, self.predictor.getEnergy(player.castTimes.moonfire, player)
        end

        local ss, sse = self:CalcStarsurgeRota(player, 0)
        if ss then
            return ss, sse
        end

        return starfire, self.predictor.getEnergy(player.castTimes.starfire, player)
    end

    if player.inSolar then
        if player.target.debuffs.sunfire < self.db.profile.dotRefreshTime
                or (player.direction == "sun" and player.power > 0 and player.target.debuffs.sunfire < 10)
                or (player.direction == "moon" and player.power <= self.db.profile.dotRefreshPower and player.target.debuffs.sunfire <= halfCycle)
                or (player.buffs.solarPeak and self.db.profile.behavior.peakBehavior == "always")
                or (player.buffs.solarPeak and self.db.profile.behavior.peakBehavior == "time" and player.target.debuffs.sunfire < (dotDur * 1.5)) then
            return sunfire, self.predictor.getEnergy(player.castTimes.sunfire, player)
        end

        local ss, sse = self:CalcStarsurgeRota(player, minStarsurgeCharges)
        if ss then
            return ss, sse
        end

        local sf, sfe = self:CalcStellarFlare(player)
        if sf then
            return sf, sfe
        end

        local afterWrath = self.predictor.getEnergy(player.castTimes.wrath, player)

        if player.direction == "sun" then
            return wrath, afterWrath
        end

        local afterStarfire = self.predictor.getEnergy(player.castTimes.starfire, player)

        if afterWrath <= 0 then
            return starfire, afterStarfire
        end
        return wrath, afterWrath
    else
        if player.celestialAlignmentReady
            and ((self.db.profile.behavior.caBehavior == "boss" and player.target.isBoss) or self.db.profile.behavior.caBehavior == "always") then
            return celestialalignment, self.predictor.getEnergy(player.castTimes.celestialalignment, player)
        end

        if player.target.debuffs.moonfire < self.db.profile.dotRefreshTime
                or (player.direction == "sun" and player.power <= self.db.profile.dotRefreshPower and player.target.debuffs.moonfire <= halfCycle)
                or (player.buffs.lunarPeak and self.db.profile.behavior.peakBehavior == "always")
                or (player.buffs.lunarPeak and self.db.profile.behavior.peakBehavior == "time" and player.target.debuffs.moonfire < (halfCycle * 1.5)) then
            return moonfire, self.predictor.getEnergy(player.castTimes.moonfire, player)
        end

        local ss, sse = self:CalcStarsurgeRota(player, minStarsurgeCharges)
        if ss then
            return ss, sse
        end

        local sf, sfe = self:CalcStellarFlare(player)
        if sf then
            return sf, sfe
        end

        local afterStarfire = self.predictor.getEnergy(player.castTimes.starfire, player)

        if player.direction == "moon" then
            return starfire, afterStarfire
        end

        local afterWrath = self.predictor.getEnergy(player.castTimes.wrath, player)

        if afterWrath <= 0 then
            return starfire, afterStarfire
        end

        return wrath, afterWrath
    end
    print("returned nil, should not happen!")
    return nil, 0
end


function BalanceSpellSuggest:nextSpell(newEnergy, curCast)
    local player = clone(self.player)
    if newEnergy == nil then
        newEnergy = 0
        print("newEnergy was nil!")
    end

    if not player.inCombat then
        player.inCombat = true
    end

    if curCast == starsurge then
        player.starsurgeCharges = math.max(player.starsurgeCharges - 1, 0)
        if player.inSolar then
            player.buffs.starsurgeSolarBonus = 3
        else
            player.buffs.starsurgeLunarBouns = 2
        end
    elseif curCast == starfall then
        player.starsurgeCharges = math.max(player.starsurgeCharges - 1, 0)
        player.buffs.starfall = 10
    elseif curCast == moonfire then
        player.target.debuffs.moonfire = 40
        if player.buffs.celestialAlignment > 0 then
            player.target.debuffs.sunfire = 24
        end
    elseif curCast == sunfire then
        player.target.debuffs.sunfire = 24
        if player.buffs.celestialAlignment > 0 then
            player.target.debuffs.moonfire = 40
        end
    elseif curCast == stellarflare then
        player.target.debuffs.stellarflare = 20
    elseif curCast == starfire then
        if player.buffs.starsurgeLunarBonus > 0 then
            player.buffs.starsurgeLunarBonus = math.max(player.buffs.starsurgeLunarBonus - 1, 0)
        end
    elseif curCast == wrath then
        if player.buffs.starsurgeSolarBonus > 0 then
            player.buffs.starsurgeSolarBonus = math.max(player.buffs.starsurgeSolarBonus - 1, 0)
        end
    elseif curCast == celestialalignment then
        player.buffs.celestialAlignment = 15
        player.celestialAlignmentReady = false
    elseif curCast == moonkinform then
        player.moonkinForm = true
    end

    player.currentCast.startPower = nil
    player.currentCast.spell = nil
    player.currentCast.icon = nil
    player.currentCast.startTime = nil
    player.currentCast.endTime = nil
    player.currentCast.id = nil
    player.currentCast.interruptable = nil

    local oldEnergy = player.rawPower

    if player.direction == "moon" then
        if newEnergy >= oldEnergy then
            player.direction = "sun"
        end
    elseif player.direction == "sun" then
        if newEnergy <= oldEnergy then
            player.direction = "monn"
        end
    end

    player.power = newEnergy
    player.rawPower = newEnergy
    if player.power < 0 then
        player.power = player.power * -1
        player.inLunar = true
        player.inSolar = false
    elseif player.power > 0 then
        player.power = player.power
        player.inLunar = false
        player.inSolar = true
    else
        player.power = 0
        player.inLunar = false
        player.inSolar = false
    end

    return self:curSpell(player)
end

-- handle starsurge
function BalanceSpellSuggest:CalcStarsurgeRota(player, minCharges)
    if player.inSolar then
        if player.starsurgeCharges > minCharges then
            if (player.starsurgeCharges == 3 and player.buffs.starsurgeSolarBonus > 0) then
                if player.buffs.starfall == 0 then
                    return starfall, self.predictor.getEnergy(player.castTimes.starfall, player)
                else
                    return starsurge, self.predictor.getEnergy(player.castTimes.starsurge, player)
                end
            end
            if (player.starsurgeCharges == 3 or player.buffs.starsurgeSolarBonus == 0) then
                return starsurge, self.predictor.getEnergy(player.castTimes.starsurge, player)
            end
        end
    else -- lunar and none
        if player.starsurgeCharges > minCharges then
            if (player.starsurgeCharges == 3 and player.buffs.starsurgeLunarBonus > 0) then
                if player.buffs.starfall == 0 then
                    return starfall, self.predictor.getEnergy(player.castTimes.starfall, player)
                else
                    return starsurge, self.predictor.getEnergy(player.castTimes.starsurge, player)
                end
            end
            if (player.starsurgeCharges == 3 or player.buffs.starsurgeLunarBonus == 0) then
                return starsurge, self.predictor.getEnergy(player.castTimes.starsurge, player)
            end
        end
    end
    return nil
end


function BalanceSpellSuggest:CalcStellarFlare(player)
    if player.talents.stellarflare then
        local afterStellarFlare = self.predictor.getEnergy(player.castTimes.stellarflare, player)
        if player.target.debuffs.stellarflare <= 5 and afterStellarFlare >= -self.db.profile.behavior.stellarFlarePowerWindow and afterStellarFlare <= self.db.profile.behavior.stellarFlarePowerWindow then
            return stellarflare, afterStellarFlare
        end
    end
    return nil
end