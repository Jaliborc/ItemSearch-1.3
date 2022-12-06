local Lib = LibStub:NewLibrary('ItemSearch-1.3', 1)
if not Lib then return end
local Unfit = LibStub('Unfit-1.0')

local MATCH_CLASS = ITEM_CLASSES_ALLOWED:format('(.*)')
local IN_SET = EQUIPMENT_SETS:format('(.*)')


function Lib:QuestInfo(item)
    local lines = self:GetTooltip(item).lines
    for i = 2, min(4, #lines) do
        if lines[i].arg[2]:find(QUEST_ITEM) then
            return true
        elseif lines[i].arg[2]:find(STARTS_QUEST) then
            return true, true
        end
    end
end

function Lib:EquipInfo(item)
    local lines = self:GetTooltip(item).lines
    if Unfit:IsItemUnusable(item:)

    local inSet = C_EquipmentSet and C_EquipmentSet.CanUseEquipmentSets() and lines[#lines-1].arg[2]:match(IN_SET)

    for i = #lines-1, 5, -1 do
        local class = lines[i].arg[2]:match(MATCH_CLASS)
        if class then
            return inSet, class
        end
    end

    return inSet
end

function Lib:GetTooltip(item)
    local loc = item.itemLocation
    return loc and (
        loc.bagID and C_TooltipInfo.GetBagItem(loc.bagID, loc.slotIndex) or
        loc.equipmentSlotIndex and C_TooltipInfo.GetInventoryItem(loc.unitID or 'player', loc.equipmentSlotIndex)) or
        item.itemLink and C_TooltipInfo.GetHyperlink(item.itemLink) or
        item.itemID and C_TooltipInfo.GetItemByID(item.itemID)
end