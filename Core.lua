if select(2, UnitClass("player")) ~= "DRUID" then
    -- no druid, no addon
    return
end

BalanceSpellSuggest = LibStub("AceAddon-3.0"):NewAddon("BalanceSpellSuggest", "AceTimer-3.0")

BalanceSpellSuggest.suggestFrame = nil
BalanceSpellSuggest.nextSpellFrame = nil
BalanceSpellSuggest.updateTimer = nil

local options = {
    name = "Balance Spell Suggest",
    handler = BalanceSpellSuggest,
    type = 'group',
    childGroups = "tab",
    args = {
        behavior = {
            name = "Behavior",
            type = "group",
            order = 0,
            args = {
                dotRefreshPower = {
                    name = "DoT refresh power",
                    desc = "Check and remind me if a DoT needs to be refreshed if my eclipse power is below this value when goind Lunar -> Solar or Solar -> Lunar.",
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
                starfireWrathTippingPoint = {
                    name = "Starfire -> Wrath tipping point",
                    desc = "When going from lunar to solar, at which power start to suggest Wrath instead of Starfire while still in lunar.",
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
                    name = "Wrath -> Starfire tipping point",
                    desc = "When going from solar to lunar, at which power start to suggest Starfire instead of Wrath while still in solar.",
                    type = "range",
                    order = 2,
                    min = 0,
                    max = 100,
                    softMin = 10,
                    softMax = 50,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.wrathStarfireTippingPoint = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.wrathStarfireTippingPoint end
                },
                talents = {
                    name = "Talents",
                    type = "header",
                    order = 3
                },
                euphoria = {
                    name = "Euphoria",
                    desc = "Is Euphoria skilled?",
                    type = "toggle",
                    order = 4,
                    set = function(_, val) BalanceSpellSuggest.db.profile.euphoria = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.euphoria end
                }
            }
        },
        display = {
            name = "Display",
            type = "group",
            order = 1,
            args = {
                locked = {
                    name = "Locked",
                    desc = "Locks the suggestion frame",
                    type = "toggle",
                    order = 0,
                    set = function(info, val) BalanceSpellSuggest:ToggleFrameLock(info, val) end,
                    get = function(_) return BalanceSpellSuggest.db.profile.locked end
                },
                xPosition = {
                    name = "X position",
                    desc = "X position from the center.",
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
                    name = "Y position",
                    desc = "Y position from the center.",
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
        yPosition = 0,
        locked = true
    }
}


-- Always called
function BalanceSpellSuggest:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BalanceSpellSuggestDB", defaults, true)
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BalanceSpellSuggest", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BalanceSpellSuggest", "Balance Spell Suggest")
end


-- Called on login ?
function BalanceSpellSuggest:OnEnable()
    -- setup frame
    if self.updateTimer == nil then
        self.updateTimer = self:ScheduleRepeatingTimer("UpdateFrames", 0.1)
    end

    if self.suggestFrame == nil then
        self.suggestFrame = CreateFrame("Frame", "BSP_Main", UIParent)
        self.suggestFrame:SetFrameStrata("BACKGROUND")
        -- TODO: calculate size based on inner frame sizes
        self.suggestFrame:SetWidth(64)
        self.suggestFrame:SetHeight(64)
        self.suggestFrame:SetPoint("CENTER", self.db.profile.xPosition, self.db.profile.yPosition)

        -- create the dragging texture
        local tex = self.suggestFrame:CreateTexture("ARTWORK")
        tex:SetTexture(1.0, 0.5, 0)
        tex:SetAlpha(0.5)
        self.suggestFrame.draggingTexture = tex
        if self.db.profile.locked then
            self.suggestFrame.draggingTexture:ClearAllPoints()
        else
            self.suggestFrame.draggingTexture:SetAllPoints()
            self.suggestFrame:Show()
        end

        self.nextSpellFrame = CreateFrame("Frame", "BSP_Next", self.suggestFrame)
        self.nextSpellFrame:SetFrameStrata("BACKGROUND")
        -- TODO: make size editable
        self.nextSpellFrame:SetWidth(64)
        self.nextSpellFrame:SetHeight(64)
        self.nextSpellFrame:SetPoint("CENTER", 0, 0)

        local suggestTexture = self.nextSpellFrame:CreateTexture(nil, "BACKGROUND")
        self.nextSpellFrame.texture = suggestTexture
    end
end


-- Called after a spec change to non-balance
function BalanceSpellSuggest:OnDisable()
    -- teardown frame
    if self.suggestFrame ~= nil then
        self.suggestFrame:Hide()
    end

    if self.updateTimer ~= nil then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end
end


-- Updates the position and the size of the frames
function BalanceSpellSuggest:UpdateFramePosition()
    self.suggestFrame:SetPoint("CENTER", self.db.profile.xPosition, self.db.profile.yPosition)
end


-- Toggles the frame lock of the suggestFrame
function BalanceSpellSuggest:ToggleFrameLock(_, val)
    self.db.profile.locked = val
    if val then
        self.suggestFrame:SetMovable(false)
        self.suggestFrame:EnableMouse(false)
        self.suggestFrame:SetScript("OnDragStart", function() end)
        self.suggestFrame:SetScript("OnDragStop", function() end)
        self.suggestFrame.draggingTexture:ClearAllPoints()
        self.suggestFrame.draggingTexture:SetAlpha(0)
        -- show the children
        local frames = { self.suggestFrame:GetChildren() }
        for _, frame in ipairs(frames) do
            frame:Show()
        end
    else
        self.suggestFrame:SetMovable(true)
        self.suggestFrame:EnableMouse(true)
        self.suggestFrame:RegisterForDrag("LeftButton")
        self.suggestFrame:SetScript("OnDragStart", self.suggestFrame.StartMoving)
        self.suggestFrame:SetScript("OnDragStop", function(self, button) BalanceSpellSuggest:StopMoving(self, button) end)
        self.suggestFrame.draggingTexture:SetAllPoints()
        self.suggestFrame.draggingTexture:SetAlpha(0.5)
        -- hide the children
        local frames = { self.suggestFrame:GetChildren() }
        for _, frame in ipairs(frames) do
            frame:Hide()
        end
    end
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

    local newTexturePath = self:GetNextSpell()
    self.nextSpellFrame.texture:SetTexture(newTexturePath)
    self.nextSpellFrame.texture:SetAllPoints(self.nextSpellFrame)
end

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

-- find out which spell should be cast next
function BalanceSpellSuggest:GetNextSpell()
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