--[[----------------------------------------------------------------------------
	NoToast
	Replaces all the annoying "toast" pop-ups with nice simple chat messages.
	Copyright (c) 2016 Phanx <addons@phanx.net>. All rights reserved.
	https://github.com/Phanx/NoToast
------------------------------------------------------------------------------]]
-- see FrameXML/AlertFrameSystems.lua

local ADDON, ns = ...

local S_COMPLETE_REWARDS_S = ERR_QUEST_COMPLETE_S:gsub("%.$", "!") .. " " .. GARRISON_MISSION_REWARDS_TOOLTIP:gsub("|c.+|r", "%%s")

AlertFrame:HookScript("OnEvent", function(self, event, ...)
	print(event)
end)

--------------------------------------------------------------------------------
-- ACHIEVEMENT_EARNED

function AchievementAlertSystem:AddAlert(achievementID, alreadyEarned)
	local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuildAch, wasEarnedByMe, earnedBy = GetAchievementInfo(achievementID)
	local link = GetAchievementLink(id)

	local color = ChatTypeInfo.SYSTEM
	if isGuildAch then
		DEFAULT_CHAT_FRAME:AddMessage(format(ACHIEVEMENT_BROADCAST, (GetGuildInfo("player")), link), color.r, color.g, color.b)
	else
		DEFAULT_CHAT_FRAME:AddMessage(format(ACHIEVEMENT_BROADCAST_SELF, link), color.r, color.g, color.b)
	end
	-- TODO: show if account-wide and already completed by another character
end

--------------------------------------------------------------------------------
-- CRITERIA_EARNED

local ACHIEVEMENT_PROGRESSED_S = ACHIEVEMENT_PROGRESSED .. ": "

function CriteriaAlertSystem:AddAlert(achievementID, criteriaString)
	local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuildAch = GetAchievementInfo(achievementID)
	local link = GetAchievementLink(id)

	local color = ChatTypeInfo.ACHIEVEMENT
	DEFAULT_CHAT_FRAME:AddMessage(format(ACHIEVEMENT_PROGRESSED_S, link), color.r, color.g, color.b)
	-- TODO: show if achievement is account-wide and already completed by another character
end

--------------------------------------------------------------------------------
-- GARRISON_BUILDING_ACTIVATABLE

function GarrisonBuildingAlertSystem:AddAlert(name)
	PlaySound("UI_Garrison_Toast_BuildingComplete")

	local color = ChatTypeInfo.SYSTEM
	DEFAULT_CHAT_FRAME:AddMessage(format("%s: %s", GARRISON_BUILDING_COMPLETE, name), color.r, color.g, color.b)
end

--------------------------------------------------------------------------------
-- GARRISON_FOLLOWER_ADDED

local GARRISON_FOLLOWER_ADDED_S = GARRISON_FOLLOWER_ADDED_TOAST .. ": %s"
local GARRISON_FOLLOWER_ADDED_UPGRADED_S = GARRISON_FOLLOWER_ADDED_TOAST .. ": %s (" .. LOOTUPGRADEFRAME_TITLE .. ")"

local GARRISON_SHIP_ADDED_S = GARRISON_SHIPYARD_FOLLOWER_ADDED_TOAST .. ": %s"
local GARRISON_SHIP_ADDED_UPGRADED_S = GARRISON_SHIPYARD_FOLLOWER_ADDED_TOAST .. ": %s (" .. LOOTUPGRADEFRAME_TITLE .. ")"

function GarrisonFollowerAlertSystem:AddAlert(followerID, name, class, level, quality, isUpgraded, texPrefix, followerType)
	PlaySound("UI_Garrison_Toast_FollowerGained")

	local link = C_Garrison.GetFollowerLinkByID(followerID)

	local template
	if (followerType == LE_FOLLOWER_TYPE_SHIPYARD_6_2) then
		template = isUpgraded and GARRISON_SHIP_ADDED_UPGRADED_S or GARRISON_SHIP_ADDED_S
	else
		template = isUpgraded and GARRISON_FOLLOWER_ADDED_UPGRADED_S or GARRISON_FOLLOWER_ADDED_S
	end

	local color = ChatTypeInfo.SYSTEM
	DEFAULT_CHAT_FRAME:AddMessage(format(template, link or name, _G["ITEM_QUALITY" .. quality .."_DESC"]), color.r, color.g, color.b)
end

GarrisonShipFollowerAlertSystem.AddAlert = GarrisonFollowerAlertSystem.AddAlert

--------------------------------------------------------------------------------
-- GARRISON_MISSION_FINISHED

local GARRISON_MISSION_FINISHED = GARRISON_LOCATION_TOOLTIP .. " " .. GARRISON_MISSION_COMPLETE
local SHIPYARD_MISSION_FINISHED = GARRISON_SHIPYARD_FLEET_TITLE .. " " .. GARRISON_MISSION_COMPLETE

function GarrisonMissionAlertSystem:AddAlert(followerTypeID, missionID)
	GarrisonLandingPageMinimapButton.MinimapLoopPulseAnim:Play()
	PlaySound("UI_Garrison_Toast_MissionComplete")

	local link = C_Garrison.GetMissionLink(missionID)
	local missionInfo = C_Garrison.GetBasicMissionInfo(missionID)

	local color = ChatTypeInfo.SYSTEM
	local template = followerTypeID == LE_FOLLOWER_TYPE_SHIPYARD_6_2 and SHIPYARD_MISSION_FINISHED or GARRISON_MISSION_FINISHED
	DEFAULT_CHAT_FRAME:AddMessage(format("%s: %s", template, link or missionInfo.name), color.r, color.g, color.b)
end

GarrisonShipMissionAlertSystem.AddAlert = GarrisonMissionAlertSystem.AddAlert

--------------------------------------------------------------------------------
-- GARRISON_RANDOM_MISSION_ADDED

local GARRISON_MISSION_ADDED_LEVEL = GARRISON_MISSION_ADDED_TOAST1 .. ": %s - " .. GARRISON_MISSION_LEVEL_TOOLTIP .. "%s"
local GARRISON_MISSION_ADDED_LEVEL_ITEMLEVEL = GARRISON_MISSION_ADDED_TOAST1 .. ": %s - " .. GARRISON_MISSION_LEVEL_ITEMLEVEL_TOOLTIP .. "%s"
local RARE = " (" .. ITEM_QUALITY3_DESC .. ")"

function GarrisonRandomMissionAlertSystem:AddAlert(missionID)
	PlaySound("UI_Garrison_Toast_MissionComplete")

	local missionInfo = C_Garrison.GetBasicMissionInfo(missionID)

	local color = ChatTypeInfo.SYSTEM
	if missionInfo.iLevel == 0 then
		DEFAULT_CHAT_FRAME:AddMessage(format(GARRISON_MISSION_ADDED_LEVEL, missionInfo.name, missionInfo.level, missionInfo.isRare and RARE or ""), color.r, color.g, color.b)
	else
		DEFAULT_CHAT_FRAME:AddMessage(format(GARRISON_MISSION_ADDED_LEVEL_ITEMLEVEL, missionInfo.name, missionInfo.level, missionInfo.iLevel, missionInfo.isRare and RARE or ""), color.r, color.g, color.b)
	end
end

--------------------------------------------------------------------------------
-- GARRISON_TALENT_COMPLETE

local RESEARCH_COMPLETE_S = GARRISON_TALENT_RESEARCH_COMPLETE .. ": %s"

function GarrisonTalentAlertSystem:AddAlert(garrisonType)
	PlaySound("UI_OrderHall_Talent_Ready_Toast")
    local talentID = C_Garrison.GetCompleteTalent(garrisonType)
    local talent = C_Garrison.GetTalent(talentID)

	-- TODO: is there a link type for this?
	-- examples: http://www.wowhead.com/order-advancements/death-knight

    local color = ChatTypeInfo.SYSTEM
	DEFAULT_CHAT_FRAME:AddMessage(format(GARRISON_TALENT_RESEARCH_COMPLETE, talent.name), color.r, color.g, color.b)
end

--------------------------------------------------------------------------------
-- LFG_COMPLETION_REWARD

function DungeonCompletionAlertSystem:AddAlert()
	local scenarioBonusComplete
	if C_Scenario.IsInScenario() and not C_Scenario.TreatScenarioAsDungeon() then
		PlaySound("UI_Scenario_Ending")
		local _, _, _, _, hasBonusStep, isBonusStepComplete = C_Scenario.GetInfo()
		scenarioBonusComplete = hasBonusStep and isBonusStepComplete
		-- TODO: include this info in the printed message
	else
		PlaySound("LFG_Rewards")
	end

	local name, typeID, subtypeID, textureFilename, moneyBase, moneyVar, experienceBase, experienceVar, numStrangers, numRewards = GetLFGCompletionReward()
	local money = moneyBase + (moneyVar * numStrangers)
	local xp = experienceBase + (experienceVar * numStrangers)

	local rewardsList = {}
	for i = 1, numRewards do
		GameTooltip:SetLFGCompletionReward(i)
		local _, itemLink = GameTooltip:GetItem()
		local texturePath, quantity = GetLFGCompletionRewardItem(index)
		if itemLink then
			tinsert(rewardsList, format("%sx%d", itemLink, quantity))
		else
			-- Couldn't fetch item link, just show the icon
			tinsert(rewardsList, format("|T%s:0:0|tx%d", texturePath, quantity))
		end
	end
	if money > 0 then
		tinsert(rewardsList, GetCoinTextureString(money))
	end
	if xp > 0 and UnitLevel("player") < MAX_PLAYER_LEVEL then
		tinsert(rewardsList, format("%d %s", xp, XP))
	end

	local color = ChatTypeInfo.SYSTEM
	DEFAULT_CHAT_FRAME:AddMessage(format(S_COMPLETE_REWARDS_S, name, table.concat(rewardsList, PLAYER_LIST_DELIMITER)), color.r, color.g, color.b)
end

ScenarioAlertSystem.AddAlert = DungeonCompletionAlertSystem.AddAlert

--------------------------------------------------------------------------------
-- LOOT_ITEM_ROLL_WON
-- SHOW_LOOT_TOAST

local ROLL_WON_S = LOOT_ROLL_YOU_WON
local ROLL_WON_UPGRADED_S = LOOT_ROLL_YOU_WON .. " (" .. LOOTUPGRADEFRAME_TITLE .. ")"

function LootAlertSystem:AddAlert(itemLink, quantity, rollType, roll, specID, isCurrency, showFactionBG, lootSource, lessAwesome, isUpgraded, isPersonal)
	PlaySoundKitID(isUpgraded and 51561 or 31578) -- UI_Warforged_Item_Loot_Toast or UI_EpicLoot_Toast
	if isCurrency then
		for _, messageType in pairs(DEFAULT_CHAT_FRAME.messageTypeList) do
			if messageType == "CURRENCY" then return end
		end
		local color = ChatTypeInfo.CURRENCY
		if quantity > 1 then
			DEFAULT_CHAT_FRAME:AddMessage(format(CURRENCY_GAINED_MULTIPLE, itemLink, quantity), color.r, color.g, color.b)
		else
			DEFAULT_CHAT_FRAME:AddMessage(format(CURRENCY_GAINED, itemLink), color.r, color.g, color.b)
		end
	elseif rollType then
		local color = ChatTypeInfo.LOOT
		if isUpgraded then
			DEFAULT_CHAT_FRAME:AddMessage(format(ROLL_WON_UPGRADED_S, itemLink, _G["ITEM_QUALITY" .. rarity .. "_DESC"]), color.r, color.g, color.b)
		else
			DEFAULT_CHAT_FRAME:AddMessage(format(ROLL_WON_S, itemLink, _G["ITEM_QUALITY" .. rarity .. "_DESC"]), color.r, color.g, color.b)
		end
	else
		local color = ChatTypeInfo.LOOT
		if quantity > 1 then
			DEFAULT_CHAT_FRAME:AddMessage(format(LOOT_ITEM_SELF_MULTIPLE, itemLink, quantity), color.r, color.g, color.b)
		else
			DEFAULT_CHAT_FRAME:AddMessage(format(LOOT_ITEM_SELF, itemLink), color.r, color.g, color.b)
		end
	end
end

function MoneyWonAlertSystem:AddAlert(quantity)
	PlaySoundKitID(31578) -- UI_EpicLoot_Toast
	local color = ChatTypeInfo.MONEY
	DEFAULT_CHAT_FRAME:AddMessage(format(CURRENCY_GAINED, GetCoinTextureString(amount)), color.r, color.g, color.b)
end

--------------------------------------------------------------------------------
-- QUEST_LOOT_RECEIVED
-- SCENARIO_COMPLETED

function InvasionAlertSystem:AddAlert(rewardQuestID, rewardItemLink)
	PlaySound("UI_Scenario_Ending")
	local scenarioName, currentStage, numStages, flags, hasBonusStep, isBonusStepComplete, _, xp, money, scenarioType, areaName = C_Scenario.GetInfo()
	local zoneName = areaName or scenarioName
	local bonusComplete = hasBonusStep and isBonusStepComplete

	local rewardsList = {}
	if rewardItemLink then
		tinsert(rewardsList, rewardItemLink)
	end
	if money > 0 then
		tinsert(rewardsList, GetCoinTextureString(money))
	end
	if xp > 0 and UnitLevel("player") < MAX_PLAYER_LEVEL then
		tinsert(rewardsList, format("%d %s", xp, XP))
	end

	local color = ChatTypeInfo.SYSTEM
	DEFAULT_CHAT_FRAME:AddMessage(format(S_COMPLETE_REWARDS_S, scenarioName, table.concat(rewardsList, PLAYER_LIST_DELIMITER)), color.r, color.g, color.b)
end

--------------------------------------------------------------------------------
-- NEW_RECIPE_LEARNED

local RECIPE_LEARNED_S = NEW_RECIPE_LEARNED_TITLE:gsub("!$", "") .. ": %s%s"
local RECIPE_LEARNED_UPGRADED_S = UPGRADED_RECIPE_LEARNED_TITLE:gsub("!$", "") .. ": %s%s"

function NewRecipeLearnedAlertSystem:AddAlert(recipeID)
	local tradeSkillID, skillLineName = C_TradeSkillUI.GetTradeSkillLineForRecipe(recipeID)
	if not tradeSkillID then return end

	local name = GetSpellInfo(recipeID)
	if not name then return end

	PlaySound("UI_Professions_NewRecipeLearned_Toast")

	local rank = GetSpellRank(recipeID)
	local rankTexture = NewRecipeLearnedAlertFrame_GetStarTextureFromRank(rank)

	local color = ChatTypeInfo.SYSTEM
	local template = rank and rank > 1 and RECIPE_LEARNED_UPGRADED_S or RECIPE_LEARNED_S
	DEFAULT_CHAT_FRAME:AddMessage(format(template, C_TradeSkillUI.GetRecipeLink(recipeID) or name, rankTexture or ""), color.r, color.g, color.b)
end

--------------------------------------------------------------------------------
-- QUEST_LOOT_RECEIVED
-- QUEST_TURNED_IN

-- Fetched 2016/07/28 from http://www.wowhead.com/currencies
local currencyIDs = {61,81,241,361,384,385,391,393,394,397,398,399,400,401,402,416,515,614,615,676,677,697,738,752,754,776,777,789,821,823,824,828,829,910,944,980,994,999,1008,1017,1020,1101,1129,1149,1154,1155,1166,1171,1172,1173,1174,1191,1220,1226,1268,1273,1275}

function WorldQuestCompleteAlertSystem:AddAlert(questID, rewardItemLink)
	PlaySound("UI_WorldQuest_Complete")
	
	local isInArea, isOnMap, numObjectives, taskName, displayAsObjective = GetTaskInfo(questID)
	local money = GetQuestLogRewardMoney(questID)
	local xp = GetQuestLogRewardXP(questID)

	local rewardsList = {}
	if rewardItemLink then
		tinsert(rewardsList, rewardItemLink)
	end
	if money > 0 then
		tinsert(rewardsList, GetCoinTextureString(money))
	end
	for i = 1, GetNumQuestLogRewardCurrencies(questID) do
		local name, texture, count = GetQuestLogRewardCurrencyInfo(i, questID)
		local link -- TODO: is there a better way to get this? check quest log code?
		for _, currencyID in pairs(currencyIDs) do
			local currencyName, _, currencyTexture = GetCurrencyInfo(currencyID)
			if currencyName == name then
				link = GetCurrencyLink(currencyID)
				break
			end
		end
		tinsert(rewardsList, format("%s x%d", link or name, count))
	end
	if xp > 0 and UnitLevel("player") < MAX_PLAYER_LEVEL then
		tinsert(rewardsList, format("%d %s", xp, XP))
	end

	local color = ChatTypeInfo.SYSTEM
	DEFAULT_CHAT_FRAME:AddMessage(format(S_COMPLETE_REWARDS_S, name, table.concat(rewardsList, PLAYER_LIST_DELIMITER)), color.r, color.g, color.b)
end

--------------------------------------------------------------------------------
-- SHOW_LOOT_TOAST_LEGENDARY_LOOTED

local LEGENDARY_LOOT_S = LOOT_ITEM_SELF .. "(" .. LEGENDARY_ITEM_LOOT_LABEL .. ")"

function LegendaryItemAlertSystem:AddAlert(itemLink)
	PlaySound("UI_LegendaryLoot_Toast")
	local color = ChatTypeInfo.LOOT
	DEFAULT_CHAT_FRAME:AddMessage(format(LEGENDARY_LOOT_S, itemLink), color.r, color.g, color.b)
end

--------------------------------------------------------------------------------
-- SHOW_LOOT_TOAST_UPGRADE

local ITEM_LOOT_UPGRADE_S = LOOT_ITEM_SELF .. " (" .. LOOTUPGRADEFRAME_TITLE .. ")"

function LootUpgradeAlertSystem:AddAlert(itemLink, quantity, specID, sex, baseQuality, isPersonal, lessAwesome)
	PlaySoundKitID(31578) -- UI_EpicLoot_Toast
	local _, _, rarity = GetItemInfo(itemLink)
	local color = ChatTypeInfo.LOOT
	DEFAULT_CHAT_FRAME:AddMessage(format(ITEM_LOOT_UPGRADE_S, itemLink, _G["ITEM_QUALITY" .. rarity .. "_DESC"]), color.r, color.g, color.b)
end

--------------------------------------------------------------------------------
-- STORE_PRODUCT_DELIVERED

function StorePurchaseAlertSystem:AddAlert(productType, icon, name, payloadID)
	PlaySound("UI_igStore_PurchaseDelivered_Toast_01")

	local link
	if productType == LE_STORE_DELIVERY_TYPE_ITEM then
		link = GetItemLink(payloadID)

	elseif productType == LE_STORE_DELIVERY_TYPE_MOUNT then
		-- ¯\_(ツ)_/¯ but let's try this!
		for _, mountID in pairs(C_MountJournal.GetMountIDs()) do
			local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, hideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(mountID)
			if creatureName == name then
				link = GetSpellLink(spellID)
				break
			end
		end

	elseif productType == LE_STORE_DELIVERY_TYPE_BATTLEPET then
		-- ¯\_(ツ)_/¯ but let's try this!
		local speciesID, petID = C_PetJournal.FindPetIDByName(name)
		link = petID and C_PetJournal.GetBattlePetLink(petID)

	elseif productType == LE_STORE_DELIVERY_TYPE_COLLECTION then
		-- ¯\_(ツ)_/¯
	end

	local color = ChatTypeInfo.SYSTEM
	DEFAULT_CHAT_FRAME:AddMessage(format("%s %s", BLIZZARD_STORE_PURCHASE_COMPLETE:gsub("%.$", ":"), link or name))
end
