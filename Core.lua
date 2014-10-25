if select(2, UnitClass("player")) ~= "DRUID" then
    return
end

Addon = LibStub("AceAddon-3.0"):NewAddon("BalanceSpellSuggest", "AceTimer-3.0")

Addon.suggestFrame = nil
Addon.suggestTexture = nil
Addon.updateTimer = nil

local options = {
    name = "Balance Spell Suggest",
    handler = Addon,
    type = 'group',
    childGroups = "tab",
    args = {
        behavior = {
            name = "Behavior",
            type = "group",
            args = {
                dotRefreshPower = {
                    name = "DoT refresh power",
                    desc = "Check and remind me if a DoT needs to be refreshed if my eclipse power is below this value.",
                    type = "range",
                    min = 0,
                    max = 100,
                    softMin = 10,
                    softMax = 50,
                    step = 1,
                    set = function(info, val) Addon.db.profile.dotRefreshPower = val end,
                    get = function(info) return Addon.db.profile.dotRefreshPower end
                },
                starfireWrathTippingPoint = {
                    name = "Starfire -> Wrath tipping point",
                    desc = "When going from lunar to solar, at which power start to suggest Wrath instead of Starfire while still in lunar.",
                    type = "range",
                    min = 0,
                    max = 100,
                    softMin = 10,
                    softMax = 50,
                    step = 1,
                    set = function(info, val) Addon.db.profile.starfireWrathTippingPoint = val end,
                    get = function(info) return Addon.db.profile.starfireWrathTippingPoint end
                },
                wrathStarfireTippingPoint = {
                    name = "Wrath -> Starfire tipping point",
                    desc = "When going from solar to lunar, at which power start to suggest Starfire instead of Wrath while still in solar.",
                    type = "range",
                    min = 0,
                    max = 100,
                    softMin = 10,
                    softMax = 50,
                    step = 1,
                    set = function(info, val) Addon.db.profile.wrathStarfireTippingPoint = val end,
                    get = function(info) return Addon.db.profile.wrathStarfireTippingPoint end
                },
                euphoria = {
                    name = "Euphoria",
                    desc = "Is Euphoria skilled?",
                    type = "toggle",
                    set = function(info, val) Addon.db.profile.euphoria = val end,
                    get = function(info) return Addon.db.profile.euphoria end
                }
            }
        },
        display = {
            name = "Display",
            type = "group",
            args = {
                xPosition = {
                    name = "X position",
                    desc = "X position from the center.",
                    type = "range",
                    min = -2000.0,
                    max = 2000.0,
                    softMin = -2000.0,
                    softMax = 2000.0,
                    step = 0.1,
                    set = function(info, val)
                        Addon.db.profile.xPosition = val
                        Addon.suggestFrame:SetPoint("CENTER", Addon.db.profile.xPosition, Addon.db.profile.yPosition)
                    end,
                    get = function(info) return Addon.db.profile.xPosition end
                },
                yPosition = {
                    name = "Y position",
                    desc = "Y position from the center.",
                    type = "range",
                    min = -2000.0,
                    max = 2000.0,
                    softMin = -2000.0,
                    softMax = 2000.0,
                    step = 0.1,
                    set = function(info, val)
                        Addon.db.profile.yPosition = val
                        Addon.suggestFrame:SetPoint("CENTER", Addon.db.profile.xPosition, Addon.db.profile.yPosition)
                    end,
                    get = function(info) return Addon.db.profile.yPosition end
                }
            }
        }
    }
}

local defaults = {
    profile = {
        euphoria = false,
        dotRefreshPower = 40,
        starfireWrathTippingPoint = 45,
        wrathStarfireTippingPoint = 35,
        xPosition = 0,
        yPosition = 0
    }
}

function Addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BalanceSpellSuggestDB", defaults, true)
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BalanceSpellSuggest", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BalanceSpellSuggest", "Balance Spell Suggest")
end


function Addon:OnEnable()
    -- setup frame
    if self.updateTimer == nil then
        self.updateTimer = self:ScheduleRepeatingTimer("UpdateFrames", 0.1)
    end

    if self.suggestFrame == nil then
        self.suggestFrame = CreateFrame("Frame", "BSP_Suggest", UIParent)
        self.suggestFrame:SetFrameStrata("BACKGROUND")
        self.suggestFrame:SetWidth(64)
        self.suggestFrame:SetHeight(64)
        self.suggestFrame:SetPoint("CENTER", self.db.profile.xPosition, self.db.profile.yPosition)

        self.suggestTexture = self.suggestFrame:CreateTexture(nil, "BACKGROUND")
        self.suggestTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp")
        self.suggestTexture:SetAllPoints(self.suggestFrame)
        self.suggestFrame.texture = self.suggestTexture
    end

    print("BSP enabled")
end

function Addon:OnDisable()
    -- teardown frame
    if self.suggestFrame ~= nil then
        self.suggestFrame:Hide()
        self.suggestFrame = nil
    end

    if self.updateTimer ~= nil then
        self:CancelTimer(self.updateTimer)
    end

    print("BSP disabled")
end

function Addon:UpdateFrames()
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
    self.suggestFrame:Show()

    local newTexturePath = self:GetNextSpell()
    self.suggestTexture:SetTexture(newTexturePath)
    self.suggestTexture:SetAllPoints(self.suggestFrame)
end

-- return values
local moonfirename,_,moonfire = GetSpellInfo(164812)
local sunfirename,_,sunfire = GetSpellInfo(164815)
local starsurgename,_,starsurge = GetSpellInfo(78674)
local starfirename,_,starfire =  GetSpellInfo(2912)
local wrathname,_,wrath = GetSpellInfo(5176)
local celestialalignmentname,_,celestialalignment = GetSpellInfo(112071)
local moonkinformname,_,moonkinform = GetSpellInfo(24858)

local lunarempowermentname = GetSpellInfo(164547)
local solarempowermentname = GetSpellInfo(164545)


function Addon:GetNextSpell()
    local _,_,_,mfC = UnitBuff("player", moonkinformname)
    if mfC == nil then
        return moonkinform
    end

    local time = GetTime()
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

    local targetMoonfire = 0 -- duration, 0 if not applied
    local targetSunfire = 0  -- duration, 0 if not applied
    local dotDur = 20
    if self.db.profile.euphoria then
        dotDur = 10
    end
    local _,_,_,_,_,_,mET,mC = UnitAura("target", moonfirename, nil, "PLAYER|HARMFUL") -- Moonfire
    if mET and mC == "player" then
        targetMoonfire = mET - time
    end
    local _,_,_,_,_,_,sET,sC = UnitAura("target", sunfirename, nil, "PLAYER|HARMFUL") -- Sunfire
    if sET and sC == "player" then
        targetSunfire = sET - time
    end

    -- priority logic here

    if inLunar then
        if targetMoonfire < 7
        or (direction == "sun" and power <= self.db.profile.dotRefreshPower and targetMoonfire <= dotDur)
        or (inCelestialAlignment and targetSunfire < 7)
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
        if targetSunfire < 7
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