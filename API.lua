--[[
Copyright 2013-2025 João Cardoso
ItemSearch is distributed under the terms of the GNU General Public License (Version 3).
As a special exception, the copyright holders of this library give you permission to embed it
with independent modules to produce an addon, regardless of the license terms of these
independent modules, and to copy and distribute the resulting software under terms of your
choice, provided that you also meet, for each embedded independent module, the terms and
conditions of the license of that module. Permission is not granted to modify this library.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

This file is part of ItemSearch.
--]]

local Lib = LibStub:NewLibrary('ItemSearch-1.3', 11)
if Lib then
	Lib.Unusable, Lib.Collected, Lib.Bangs = {}, {}, {}
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


--[[ General API ]]--

function Lib:Matches(item, search)
	if type(item) == 'table' then
    	return Parser({location = item, link = C.Item.DoesItemExist(item) and C.Item.GetItemLink(item)}, search, self.Filters)
	else
		return Parser({link = item}, search, self.Filters)
	end
end

function Lib:IsUnusable(id)
    if Unfit:IsItemUnusable(id) then
        return true
	elseif Lib.Unusable[id] == nil and C.Item.IsEquippableItem(id) then
		Lib.Unusable[id] = (function()
			local lines = C.TooltipInfo.GetItemByID(id).lines
			for i = #lines-1, 5, -1 do
				local class = lines[i].leftText:match(L.CLASS_REQUIREMENT)
				if class then
					return not class:find(L.PLAYER_CLASS)
				end
			end
		end)() or false
    end
	return Lib.Unusable[id]
end

function Lib:IsQuestItem(id)
	local _,_,_,_,_,_,_,_,_,_,_,class,_,bind = C.Item.GetItemInfo(id)

	if (class == Enum.ItemClass.Questitem or bind == LE_ITEM_BIND_ON_ACQUIRE) and Lib.Bangs[id] == nil then
		Lib.Bangs[id] = (function()
			local lines = C.TooltipInfo.GetItemByID(id).lines
			for i = 2, min(4, #lines) do
				if lines[i].leftText:find(ITEM_STARTS_QUEST) then
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


--[[ Sets and Collections ]]--

if LE_EXPANSION_LEVEL_CURRENT > 2 then
	function Lib:IsUncollected(id, link)
		if not Lib.Collected[id] and C.Item.IsDressableItemByID(id) and not C.TransmogCollection.PlayerHasTransmog(id) then
			local data = C.TooltipInfo.GetHyperlink(link)
			if data and #data.lines > 0 then
				local missing = data.lines[#data.lines].leftText == TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN
				Lib.Collected[id] = not missing
				return missing
			end
		end
	end
else
	Lib.IsUncollected = nop
end

if C.AddOns.IsAddOnLoaded('ItemRack') then
	function Lib:BelongsToSet(id, search)
		if C.Item.IsEquippableItem(id) then
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

elseif LE_EXPANSION_LEVEL_CURRENT > 2 then
	function Lib:BelongsToSet(id, search)
		if C.Item.IsEquippableItem(id) then
			for i, setID in pairs(C.EquipmentSet.GetEquipmentSetIDs()) do
				local name = C.EquipmentSet.GetEquipmentSetInfo(setID)
				if not search or Parser:Find(search, name) then
					local items = C.EquipmentSet.GetItemIDs(setID)
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
	Lib.BelongsToSet = nop
end
