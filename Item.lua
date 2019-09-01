-- Item.lua
-- @Author : Dencer (tdItem@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 8/30/2019, 11:15:55 PM

local ns = select(2, ...)
local Addon = ns.Addon

local Item = Addon:NewModule('Item', 'AceHook-3.0')

function Item:OnEnable()
    local function gen(link, count)
        return function(...)
            return link(...), count(...)
        end
    end

    local function gen2(link, count)
        return function(...)
            return link(...), select(2, count(...))
        end
    end

    local function gen3(link, count)
        return function(...)
            return link(...), select(3, count(...))
        end
    end

    self:RegisterItemPrice('SetInventoryItem', gen(GetInventoryItemLink, GetInventoryItemCount))
    self:RegisterItemPrice('SetBagItem', gen2(GetContainerItemLink, GetContainerItemInfo))
    self:RegisterItemPrice('SetAuctionItem', gen3(GetAuctionItemLink, GetAuctionItemInfo))
    self:RegisterItemPrice('SetLootRollItem', gen3(GetLootRollItemLink, GetLootRollItemInfo))
    self:RegisterItemPrice('SetTradePlayerItem', gen3(GetTradePlayerItemLink, GetTradePlayerItemInfo))
    self:RegisterItemPrice('SetTradeTargetItem', gen3(GetTradeTargetItemLink, GetTradeTargetItemInfo))
    self:RegisterItemPrice('SetQuestItem', gen3(GetQuestItemLink, GetQuestItemInfo))

    self:RegisterItemPrice('SetAuctionSellItem', function()
        local name, _, count = GetAuctionSellItemInfo()
        local _, link = GetItemInfo(name)
        return link, count
    end)

    self:RegisterItemPrice('SetLootItem', function(slot)
        if LootSlotHasItem(slot) then
            local link, _, num = GetLootSlotLink(slot)
            return link, num
        end
    end)

    self:RegisterItemPrice('SetQuestLogItem', function(type, index)
        local num, _
        if type == 'choice' then
            _, _, num = GetQuestLogChoiceInfo(index)
        else
            _, _, num = GetQuestLogRewardInfo(index)
        end

        return GetQuestLogItemLink(type, index), num
    end)

    self:RegisterItemPrice('SetInboxItem', function(index, attachIndex)
        if AUCTIONATOR_SHOW_MAILBOX_TIPS == 1 then
            local attachmentIndex = attachIndex or 1
            local _, _, _, num = GetInboxItem(index, attachmentIndex)

            return GetInboxItemLink(index, attachmentIndex), num
        end
    end)

    self:RegisterItemPrice('SetSendMailItem', function(id)
        local name, _, _, num = GetSendMailItem(id)
        local name, link = GetItemInfo(name)
        return link, num
    end)

    self:RegisterItemPrice('SetHyperlink', function(itemstring, num)
        local name, link = GetItemInfo(itemstring)
        return link, num
    end)

    self:HookScript(GameTooltip, 'OnTooltipSetItem', 'OnTooltipSetItem')
end

function Item:OnTooltipSetItem(tip)
    local _, item = tip:GetItem()
    if not item then
        return
    end

    local _, _, itemQuality, itemLevel, _, itemType, itemSubType, _, _, itemTexture =
        GetItemInfo(item)

    tip:AddLine('Item Level: ' .. itemLevel)
    tip:AddLine('Item Type: ' .. itemType .. '-' .. itemSubType)
    tip:Show()
end

function Item:RegisterItemPrice(method, func)
    if not GameTooltip[method] then
        print(method)
        return
    end

    self:SecureHook(GameTooltip, method, function(tip, ...)
        local item, count = func(...)
        if item then
            self:GameTooltipAddPrice(tip, item, count)
        end
    end)
end

function Item:GameTooltipAddPrice(tip, item, count)
    if MerchantFrame:IsVisible() then
        return
    end

    local price = select(11, GetItemInfo(item))
    if price and price > 0 then
        count = count or 1

        if count == 1 then
            SetTooltipMoney(tip, price * count, nil, string.format('%s:', SELL_PRICE))
        else
            SetTooltipMoney(tip, price * count, nil, string.format('%s|cff00ffffx%d|r:', SELL_PRICE, count))
        end
        tip:Show()
    end
end
