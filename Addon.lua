
local Addon = LibStub('AceAddon-3.0'):NewAddon('tdTip', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0')
local L     = LibStub('AceLocale-3.0'):GetLocale('tdTip')

local tinsert, tconcat = table.insert, table.concat

---- WOW UI

local UIParent             = UIParent
local WorldFrame           = WorldFrame
local GameTooltip          = GameTooltip
local GameTooltipStatusBar = GameTooltipStatusBar

local ICON_LIST            = ICON_LIST
local PET_TYPE_SUFFIX      = PET_TYPE_SUFFIX
local RAID_CLASS_COLORS    = RAID_CLASS_COLORS
local FACTION_BAR_COLORS   = FACTION_BAR_COLORS
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR

---- WOW APIS

UnitFactionGroup

---- DEFINE

local PVP, LEVEL, TARGET = PVP, LEVEL, TARGET
local YOU                = format('|cffff0000>> %s <<|r', L.You)
local DEAD               = format('|cffee2222%s|r', DEAD)
local PLAYER_FACTION     = UnitFactionGroup('player')
local CLASSIFICATION     = {
    elite     = format('|cffffff33%s|r',   ELITE),
    worldboss = format('|cffff0000%s|r',   BOSS),
    rare      = format('|cffff66ff%s|r',   L.Rare),
    rareelite = format('|cffffaaff%s%s|r', L.Rare, ELITE),
}

local CLASS_ICONS = {} do
    for i = 1, GetNumClasses() do
        local _, classKey = GetClassInfo(i)
        local coords = CLASS_ICON_TCOORDS[classKey]
        CLASS_ICONS[classKey] = format([[|TInterface\WorldStateFrame\ICONS-CLASSES:%%d:%%d:0:0:256:256:%d:%d:%d:%d|t %%s]], coords[1] * 0xFF, coords[2] * 0xFF,coords[3] * 0xFF, coords[4] * 0xFF)
    end
end

local tipleft = setmetatable({}, {__index = function(o, k)
    local text = _G['GameTooltipTextLeft' .. k]
    o[k] = text
    return text
end})

---- Custom APIS

local function UnitColor(unit)
    if UnitIsPlayer(unit) then
        local _, classKey = UnitClass(unit)
        if classKey then
            return RAID_CLASS_COLORS[classKey]
        end
    else
        local reaction = UnitReaction(unit, 'player')
        if reaction then
            return FACTION_BAR_COLORS[reaction]
        end
    end
    return HIGHLIGHT_FONT_COLOR
end

local function strcolor(text, r, g, b)
    if type(r) == 'number' then
        r, g, b = r or 1, g or 1, b or 1
    elseif type(r) == 'table' then
        r, g, b = r.r, r.g, r.b
    elseif type(r) == 'string' and r:find('%x%x%x%x%x%x') then
        return format('|cff%s%s|r', r, text)
    else
        return text
    end
    return format('|cff%02x%02x%02x%s|r', r * 0xff, g * 0xff, b * 0xff, text)
end

---- Core

function Addon:ClearLine(i)
    tipleft[i]:SetText()
end

function Addon:SetLine(i, text, r, g, b, a)
    if tipleft[i] then
        tipleft[i]:SetText(text)
        if r then
            tipleft[i]:SetTextColor(r, g or 1, b or 1, a or 1)
        end
    end
end

function Addon:GetLine(i)
    if tipleft[i] then
        return tipleft[i]:GetText(), tipleft[i]:GetTextColor()
    end
end

function Addon:NumLines()
    return GameTooltip:NumLines()
end

function Addon:Refresh()
    GameTooltip:Show()
end

function Addon:GetEmptyLine()
    local line = self.lineFac or self.linePVP
    if line then
        if self.lineFac then
            self.lineFac = nil
        else
            self.linePVP = nil
        end
        return line
    else
        GameTooltip:AddLine('TempLine')
        self:ClearLine(GameTooltip:NumLines())
        return GameTooltip:NumLines()
    end
end

function Addon:SetIcon(texturePath)
    if texturePath then
        self.icon:SetTexture(texturePath)
        self.icon:Show()
    else
        self.icon:Hide()
    end
end

---- Unit

local function GameTooltip_UnitColor(unit)
    if not UnitIsPlayer(unit) and UnitIsTapDenied(unit) then
        return 0.55, 0.55, 0.55
    else
        local color = UnitColor(unit)
        return color.r, color.g, color.b
    end
end

function Addon:UpdateNameLine()
    self:SetLine(1, self.unitName)
end

function Addon:UpdateGuildLine()
    local realm = self.unitRealm
    if self.lineGuild then
        local tmp = self.unitGuild
        if realm then
            tmp = tmp .. ' @ ' .. realm
        end
        self:SetLine(self.lineGuild, tmp, 1, 1, 1)
    elseif realm then
        for i = self:GetEmptyLine(), 3, -1 do
            self:SetLine(i, self:GetLine(i-1))
        end
        self:SetLine(2, realm, 1, 1, 1)
        self.lineLevel = self.lineLevel + 1
    end
end

local levelCache = {}
function Addon:UpdateLevelLine()
    if not self.lineLevel then
        return
    end
    wipe(levelCache)
    if self.unitLevel then
        tinsert(levelCache, self.unitLevel)
    end
    if self.unitClass then
        tinsert(levelCache, self.unitClass)
    end
    if self.unitRace then
        tinsert(levelCache, self.unitRace)
    end
    if self.unitType then
        tinsert(levelCache, self.unitType)
    end
    if self.unitClassification then
        tinsert(levelCache, self.unitClassification)
    end
    if self.isDead then
        tinsert(levelCache, DEAD)
    end
    self:SetLine(self.lineLevel, tconcat(levelCache, ' '), 1, 1, 1)
end

function Addon:UpdateBar(bar)
    bar = bar or GameTooltipStatusBar
    if not bar:IsShown() then
        return
    end
    if self.isDead then
        bar:Hide()
    else
        self.lineBar = self.lineBar or self:GetEmptyLine()
        self:SetLine(self.lineBar, ' ')

        bar:ClearAllPoints()
        bar:SetPoint('TOPLEFT', tipleft[self.lineBar], 'TOPLEFT', 0, -3)
    end
end

function Addon:UpdateIcon()
    if not self.db.profile.showExtraIcon then
        return
    end

    local size = self.db.profile.extraIconSize
    self.icon:SetSize(size, size)

    local x, y = self.db.profile.extraIconOffsetX, self.db.profile.extraIconOffsetY
    self.icon:SetPoint('CENTER', GameTooltip, 'TOPRIGHT', x, y)

    if self.db.profile.showRaidIcon then
        local index = GetRaidTargetIndex(self.unit)
        if index then
            self:SetIcon(format([[Interface\TargetingFrame\UI-RaidTargetingIcon_%d]], index))
            return
        end
    end

    if self.isBattlePet then
        return
    end

    if not self.db.profile.showFacIcon or not self.unitFac or not (self.unitFac == 'Alliance' or self.unitFac == 'Horde') then
        return
    end
    if not self.isPlayer and not self.db.profile.showNpcFacIcon then
        return
    end
    self:SetIcon([[Interface\FriendsFrame\PlusManz-]] .. self.unitFac)
end

function Addon:UpdateTarget(force)
    if not self.db.profile.showTarget then
        return
    end
    if UnitExists('mouseover') or force then
        self.lineTarget = self.lineTarget or self:GetEmptyLine()
        self:SetLine(self.lineTarget, self:GetTargetText(), 0.67, 0.67, 1)
        self:Refresh()
    end
end

function Addon:OnTooltipSetUnit(tip)
    local unit = select(2, tip:GetUnit())
    if not unit or not UnitExists(unit) then
        return
    end

    self:SetUnit(unit)
    self:UpdateNameLine()
    self:UpdateGuildLine()
    self:UpdateLevelLine()
    self:UpdateBar()
    self:UpdateIcon()
    self:UpdateTarget(true)
    self:Refresh()

    if self.db.profile.showTarget then
        self:ScheduleRepeatingTimer('UpdateTarget', 0.5)
    end
end

---- statusbar

function Addon:Tooltip_OnSizeChanged(tip, w, h)
    GameTooltipStatusBar:SetWidth(w - 20)
end

function Addon:Tooltip_OnHide()
    GameTooltip:SetMinimumWidth(0, false)
    GameTooltip:SetSize(1, 1)
    self:SetIcon()
    self:CancelAllTimers()
end

function Addon:StatusBar_OnShow(bar)
    if UnitExists('mouseover') then
        return
    end
    self.isDead = nil
    self:UpdateBar(bar)
end

function Addon:StatusBar_OnValueChanged(bar, value)
    local min, max = bar:GetMinMaxValues()
    if value >= min and value <= max then
        self.bartext:Show()
        self.bartext:SetText(floor((value - min) / (max - min) * 100) .. ' %')
    else
        self.bartext:Hide()
    end
end

---- target

function Addon:GetTargetText()
    local unit = self.unit .. 'target'
    if not UnitExists(unit) then
        return
    end
    local unitName
    if UnitIsUnit(unit, 'player') then
        unitName = YOU
    else
        unitName = strcolor(UnitName(unit), UnitColor(unit))
    end
    return unitName and foramt('%s: [[ %s ]]', TARGET, unitName) or nil
end

function Addon:SetUnit(unit)
    self.linePVP,
    self.lineFac,
    self.lineBar,
    self.lineTarget,
    self.lineGuild,
    self.lineLevel,

    self.unit,
    self.isDead,
    self.isPlayer,
    self.isBattlePet,
    self.unitGuild,
    self.unitFac,
    self.unitLevel,
    self.unitClass,
    self.unitRace,
    self.unitType,
    self.unitName,
    self.unitRealm,
    self.unitClassification = nil

    local facLocale, classKey
    self.unit                          = unit
    self.isPlayer                      = UnitIsPlayer(unit)
    self.isDead                        = UnitIsDeadOrGhost(unit)
    self.isBattlePet                   = not self.isPlayer and (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit))
    self.unitGuild, self.unitGuildRank = GetGuildInfo(unit)
    self.unitFac, facLocale            = UnitFactionGroup(unit)
    self.unitName, self.unitRealm      = UnitName(unit)
    self.unitColor                     = UnitColor(unit)

    if self.unitRealm == '' or self.unitRealm == ' ' then
        self.unitRealm = nil
    end

    if self.isPlayer then
        self.unitLevel           = UnitLevel(unit)
        self.unitClass, classKey = UnitClass(unit)
        self.unitRace            = UnitRace(unit)
    elseif self.isBattlePet then
        self.unitLevel = UnitBattlePetLevel(unit)
        self.unitType  = _G['BATTLE_PET_DAMAGE_NAME_' .. UnitBattlePetType(unit)]
    else
        self.unitLevel          = UnitLevel(unit)
        self.unitType           = UnitPlayerControlled(unit) and UnitCreatureFamily(unit) or UnitCreatureType(unit)
        self.unitClassification = CLASSIFICATION[UnitClassification(unit)]
    end

    for i = self:NumLines(), 2, -1 do
        local text = self:GetLine(i)
        if text then
            if self.isPlayer and self.unitGuild and not self.lineGuild and text:find(self.unitGuild) then
                self.lineGuild = i
            elseif not self.lineLevel and text:find(LEVEL) then
                self.lineLevel = i
            elseif not self.linePVP and text:find(PVP) then
                self.linePVP = i
                self:ClearLine(i)
            elseif self.unitFac and not self.lineFac and text == facLocale then
                self.lineFac = i
                self:ClearLine(i)
            end
        end
    end

    if self.isBattlePet then
        self.unitLevel = strcolor(self.unitLevel, 1, 0.67, 1)

        local nameColor = tipleft[1]:GetText():match('^|c%x%x(%x%x%x%x%x%x)' .. self.unitName)
        if nameColor then
            self.unitType = strcolor(self.unitType, nameColor)
        end
    else
        if self.unitLevel <= 0 then
            self.unitLevel = '|cffff0000??|r'
        else
            self.unitLevel = strcolor(self.unitLevel, GetQuestDifficultyColor(self.unitLevel))
        end
    end

    if self.db.profile.showPVPName then
        self.unitName = UnitPVPName(unit) or self.unitName
    end
    if self.db.profile.showClassIcon and classKey then
        local iconSize = self.db.profile.classIconSize
        self.unitName = CLASS_ICONS[classKey]:format(iconSize, iconSize, self.unitName)
    end

    if self.isPlayer then
        self.unitClass = strcolor(self.unitClass, self.unitColor)
        if self.unitGuild then
            local unitGuild = self.unitGuild
            if self.db.profile.showGuildRank then
                unitGuild = foramt('<%s - %s>', self.unitGuild, self.unitGuildRank)
            else
                unitGuild = format('<%s>', self.unitGuild)
            end
            self.unitGuildRank = nil
            self.unitGuild = strcolor(unitGuild, self:GetGuildColor())
        end
        if self.unitRealm then
            self.unitRealm = strcolor(self.unitRealm, self:GetServerColor())
        end
        if self.unitRace then
            self.unitRace = strcolor(self.unitRace, self:GetRaceColor())
        end
    end
end


---- Anchor

local noparents = setmetatable({
    [UIParent] = false,
    [WorldFrame] = false,
}, {__index = function(_, k)
    return k
end})

local function GameTooltip_SetDefaultAnchor(self, parent)
    local frame = noparents[parent]-- or GetMouseFocus()]
    if not frame or frame == WorldFrame then
        self:SetOwner(UIParent, 'ANCHOR_CURSOR')
    else
        local halfWidth = GetScreenWidth() / 2
        local isTop = GetScreenHeight() - frame:GetTop() < 200
        if frame:GetWidth() > halfWidth then
            self:SetOwner(frame, 'ANCHOR_CURSOR')
        elseif frame:GetRight() >= halfWidth then
            self:SetOwner(frame, isTop and 'ANCHOR_BOTTOMLEFT' or 'ANCHOR_LEFT')
        else
            self:SetOwner(frame, isTop and 'ANCHOR_BOTTOMRIGHT' or 'ANCHOR_RIGHT')
        end
    end
end

local function GameTooltip_SetDefaultAnchor(self, parent)
    self:ClearAllPoints()
    self:SetPoint('BOTTOMRIGHT', MultiBarBottomRight, 'TOPRIGHT', 0, 160)
end

---- Event

function Addon:OnInitialize()
    local defaults = {
        profile = {
            showPVPName   = false,
            showGuildRank = false,

            showTarget    = true,
            showClassIcon = true,
            classIconSize = 22,

            showExtraIcon    = true,
            showRaidIcon     = true,
            showPetIcon      = false,
            showFacIcon      = true,
            showNpcFacIcon   = false,
            extraIconSize    = 48,
            extraIconOffsetX = 0,
            extraIconOffsetY = -5,

            colors = {
                guild      = { r = 1.00, g = 0.00, b = 1.00 },
                sameGuild  = { r = 1.00, g = 0.31, b = 0.38 },
                server     = { r = 0.67, g = 1.00, b = 1.00 },
                sameServer = { r = 0.34, g = 0.35, b = 1.00 },
                friend     = { r = 0.00, g = 1.00, b = 0.20 },
                enemy      = { r = 1.00, g = 0.20, b = 0.00 },
            },
        }
    }

    self.realms = {}

    self.db = LibStub('AceDB-3.0'):New('TDDB_TIP', defaults, true)

    self.icon = GameTooltip:CreateTexture(nil, 'OVERLAY')

    self.barbg = GameTooltipStatusBar:CreateTexture(nil, 'BACKGROUND')
    self.barbg:SetAllPoints(GameTooltipStatusBar)
    self.barbg:SetTexture([[Interface\AddOns\tdTip\Images\bar.tga]])
    self.barbg:SetVertexColor(0.5, 0.5, 0.5, 0.5)

    self.bartext = GameTooltipStatusBar:CreateFontString(nil, 'OVERLAY')
    self.bartext:SetPoint('CENTER')
    self.bartext:SetAlpha(0.8)
    self.bartext:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE')

    if self.LoadOptionFrame then
        self:LoadOptionFrame()
    end
end

function Addon:OnEnable()
    wipe(self.realms)
    for _, realm in ipairs(GetAutoCompleteRealms() or {GetRealmName()}) do
        self.realms[realm] = true
    end

    self:HookScript(GameTooltip, 'OnTooltipSetUnit', 'OnTooltipSetUnit')
    self:HookScript(GameTooltip, 'OnSizeChanged', 'Tooltip_OnSizeChanged')
    self:HookScript(GameTooltip, 'OnTooltipCleared', 'Tooltip_OnHide')

    self:HookScript(GameTooltipStatusBar, 'OnShow', 'StatusBar_OnShow')
    self:HookScript(GameTooltipStatusBar, 'OnValueChanged', 'StatusBar_OnValueChanged')

    self:RawHook('GameTooltip_UnitColor', GameTooltip_UnitColor, true)
    self:SecureHook('GameTooltip_SetDefaultAnchor', GameTooltip_SetDefaultAnchor)

    GameTooltipStatusBar:SetStatusBarTexture([[Interface\AddOns\tdTip\Images\bar.tga]])
end

function Addon:OnDisable()
    GameTooltipStatusBar:ClearAllPoints()
    GameTooltipStatusBar:SetPoint('TOPLEFT', GameTooltip, 'BOTTOMLEFT', 2, -1)
    GameTooltipStatusBar:SetPoint('TOPRIGHT', GameTooltip, 'TOPRIGHT', -2, -1)
    GameTooltipStatusBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-TargetingFrame-BarFill]])

    self.icon:Hide()
    self.barbg:Hide()
    self.bartext:Hide()
end

---- Settings

function Addon:GetGuildColor()
    return UnitIsInMyGuild(self.unit) and self.db.profile.colors.sameGuild or self.db.profile.colors.guild
end

function Addon:GetRaceColor()
    return self.unitFac == PLAYER_FACTION and self.db.profile.colors.friend or self.db.profile.colors.enemy
end

function Addon:GetServerColor()
    return (not self.unitRealm or self.realms[self.unitRealm]) and self.db.profile.colors.sameServer or self.db.profile.colors.server
end
