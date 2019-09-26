-- Item.lua
-- @Author : Dencer (tdItem@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 8/30/2019, 11:15:55 PM

local ns = select(2, ...)
local Addon = ns.Addon
local L = LibStub('AceLocale-3.0'):GetLocale('tdTip')

local Item = Addon:NewModule('Item', 'AceHook-3.0')

function Item:OnEnable()
    self:HookScript(GameTooltip, 'OnTooltipSetItem', 'OnTooltipSetItem')
    self:HookScript(ShoppingTooltip1, 'OnTooltipSetItem', 'OnTooltipSetItem')
    self:HookScript(ShoppingTooltip2, 'OnTooltipSetItem', 'OnTooltipSetItem')
end

function Item:OnTooltipSetItem(tip)
    local _, item = tip:GetItem()
    if not item then
        return
    end

    local lr, lg, lb = NORMAL_FONT_COLOR:GetRGB()
    local rr, rg, rb = YELLOW_FONT_COLOR:GetRGB()

    local function AddLineNotFirst(left, right)
        tip:AddDoubleLine(left, right, lr, lg, lb, rr, rg, rb)
    end

    local function AddLine(left, right)
        tip:AddLine(' ')
        AddLine = AddLineNotFirst
        AddLine(left, right)
    end

    local id = item:match('item:(%d+)')
    if id then
        AddLine(L['Item id'], id)
    end

    local _, _, itemQuality, itemLevel, _, itemType, itemSubType, _, _, itemTexture = GetItemInfo(item)
    if itemLevel then
        AddLine(L['Item level'], itemLevel)
    end
    if itemType and itemSubType then
        AddLine(L['Item class'], itemType .. '-' .. itemSubType)
    end
    if itemTexture then
        AddLine(L['Item icon'], itemTexture)
    end

    local spellName, spellId = GetItemSpell(item)
    if spellName then
        AddLine(L['Item spell'], spellName .. '-' .. spellId)
    end

    tip:Show()
end
