local Lib = LibStub:NewLibrary('ItemSearch-1.3', 1)
if Lib then
	Lib.Unusable, Lib.Bangs = {}, {}
	Lib.Filters = nil
else
	return
end

local C = LibStub('C_Everywhere')
local Unfit = LibStub('Unfit-1.0')
local Parser = LibStub('CustomSearch-1.0')
local L = {
    PLAYER_CLASS = LOCALIZED_CLASS_NAMES_MALE[UnitClassBase('player')],
    CLASS_REQUIREMENT = ITEM_CLASSES_ALLOWED:format('(.*)'),
    IN_SET = EQUIPMENT_SETS:format('(.*)'),
}


--[[ Main API ]]--

function Lib:Matches(item, search)
	if type(item) == 'table' then
    	return Parser({location = item, link = C_Item.GetItemLink(item)}, search, self.Filters)
	else
		return Parser({link = item}, search, self.Filters)
	end
end

function Lib:IsUnusable(id)
    if Unfit:IsItemUnusable(id) then
        return true
	elseif Lib.Unusable[id] == nil and IsEquippableItem(id) then
		Lib.Unusable[id] = (function()
			local lines = C.TooltipInfo.GetItemByID(id).lines
			for i = #lines-1, 5, -1 do
				local class = lines[i].args[2].stringVal:match(L.CLASS_REQUIREMENT)
				if class then
					return not class:find(L.PLAYER_CLASS)
				end
			end
		end)() or false
    end
	return Lib.Unusable[id]
end

function Lib:IsQuestItem(id)
	local _,_,_,_,_,_,_,_,_,_,_,class,_,bind = GetItemInfo(id)

	if (class == Enum.ItemClass.Questitem or bind == LE_ITEM_BIND_ON_ACQUIRE) and Lib.Bangs[id] == nil then
		Lib.Bangs[id] = (function()
			local lines = C.TooltipInfo.GetItemByID(id).lines
			for i = 2, min(4, #lines) do
				if lines[i].args[2].stringVal:find(ITEM_STARTS_QUEST) then
					return true
				end
			end
		end)() or false
	end

	if Lib.Bangs[id] then
		return true, true
	else
		return class == Enum.ItemClass.Questitem or bind == LE_ITEM_BIND_QUEST
	end
end


--[[ Equipment Sets ]]--

if IsAddOnLoaded('ItemRack') then
	function Lib:BelongsToSet(id, search)
		if IsEquippableItem(id) then
			for name, set in pairs(ItemRackUser.Sets) do
				if name:sub(1,1) ~= '' and (not search or Parser:Find(search, name)) then
					for _, item in pairs(set.equip) do
						if ItemRack.SameID(id, item) then
							return true
						end
					end
				end
			end
		end
	end

elseif IsAddOnLoaded('Wardrobe') then
	function Lib:BelongsToSet(id, search)
		if IsEquippableItem(id) then
			for _, outfit in ipairs(Wardrobe.CurrentConfig.Outfit) do
				local name = outfit.OutfitName
				if not search or Parser:Find(search, name) then
					for _, item in pairs(outfit.Item) do
						if item.IsSlotUsed == 1 and item.ItemID == id then
							return true
						end
					end
				end
			end
		end
	end

elseif C_EquipmentSet then
	function Lib:BelongsToSet(id, search)
		if IsEquippableItem(id) then
			for i, setID in pairs(C_EquipmentSet.GetEquipmentSetIDs()) do
				local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
				if not search or Parser:Find(search, name) then
					local items = C_EquipmentSet.GetItemIDs(setID)
					for _, item in pairs(items) do
						if id == item then
							return true
						end
					end
				end
			end
		end
	end

else
	function Lib:BelongsToSet() end
end
