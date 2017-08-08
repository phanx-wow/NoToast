--[[----------------------------------------------------------------------------
	NoToast
	Replaces all the annoying "toast" pop-ups with nice simple chat messages.
	Copyright (c) 2016 Phanx <addons@phanx.net>. All rights reserved.
	https://github.com/Phanx/NoToast
------------------------------------------------------------------------------]]
-- see FrameXML/AlertFrameSystems.lua

local ADDON, ns = ...

local S_COMPLETE_REWARDS_S = ERR_QUEST_COMPLETE_S:gsub("%.$", "!") .. " " .. GARRISON_MISSION_REWARDS_TOOLTIP:gsub("|c.+|r", "%%s")
--[[
local OnEvent = AlertFrame:GetScript("OnEvent")
AlertFrame:SetScript("OnEvent", function(self, event, ...)
	print(strjoin(" \124 ", event, tostringall(...)))
	OnEvent(self, event, ...)
end)
]]
local function Print(channel, color, message, ...)
	if channel then
		for _, v in next, DEFAULT_CHAT_FRAME.messageTypeList do
			if v == channel then
				return
			end
		end
	end
	if type(color) ~= "table" then
		color = ChatTypeInfo[color or channel or "SYSTEM"]
	end
	if (...) then
		message = format(message, ...)
	end
	DEFAULT_CHAT_FRAME:AddMessage(message, color.r, color.g, color.b)
end

------------------------------------------------------------------------
-- LevelUpDisplay.lua
-- Remove middle of the screen "boss killed" and personal loot alerts

BossBanner:UnregisterAllEvents()

--------------------------------------------------------------------------------
-- ACHIEVEMENT_EARNED

function AchievementAlertSystem:AddAlert(achievementID, alreadyEarned)
	local id, name, points, completed, month, day, year, description, flags, icon, rewardText, 
		isGuildAchievement, wasEarnedByMe, earnedBy = GetAchievementInfo(achievementID)

	local link = GetAchievementLink(id):gsub("%-", "%%%-"):gsub("[%[%]]", "")
	if isGuildAchievement then
		Print(nil, "ACHIEVEMENT", "%s: %s", GUILD_ACHIEVEMENT_UNLOCKED, link)
	else
		Print(nil, "ACHIEVEMENT", ACHIEVEMENT_UNLOCKED_CHAT_MSG, link)
	end
	-- TODO: show if account-wide and already completed by another character
end

--------------------------------------------------------------------------------
-- CRITERIA_EARNED

local ACHIEVEMENT_PROGRESSED_S = ACHIEVEMENT_PROGRESSED .. ": %s"

function CriteriaAlertSystem:AddAlert(achievementID, criteriaString)
	-- local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuildAch = GetAchievementInfo(achievementID)
	local link = GetAchievementLink(achievementID)
	Print(nil, "ACHIEVEMENT", ACHIEVEMENT_PROGRESSED_S, link)
	-- TODO: show if achievement is account-wide and already completed by another character
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

	local name, typeID, subtypeID, textureFilename, moneyBase, moneyVar, 
		experienceBase, experienceVar, numStrangers, numRewards = GetLFGCompletionReward()
	local money = moneyBase + (moneyVar * numStrangers)
	local xp = experienceBase + (experienceVar * numStrangers)

	local rewardsList = {}
	for i = 1, numRewards do
		local itemLink = GetLFGCompletionRewardItemLink(i)
		local texturePath, quantity, isBonus, bonusQuantity = GetLFGCompletionRewardItem(i)
		print(i, itemLink, isBonus, bonusQuantity)
		tinsert(rewardsList, format("%sx%d", itemLink, quantity))
	end
	if money > 0 then
		tinsert(rewardsList, GetCoinTextureString(money))
	end
	if xp > 0 and UnitLevel("player") < MAX_PLAYER_LEVEL then
		tinsert(rewardsList, format("%d %s", xp, XP))
	end

	Print(nil, nil, S_COMPLETE_REWARDS_S,
		name,
		table.concat(rewardsList, PLAYER_LIST_DELIMITER))
end

ScenarioAlertSystem.AddAlert = DungeonCompletionAlertSystem.AddAlert

--------------------------------------------------------------------------------
-- GARRISON_BUILDING_ACTIVATABLE

function GarrisonBuildingAlertSystem:AddAlert(name)
	PlaySound("UI_Garrison_Toast_BuildingComplete")
	Print(nil, nil, "%s: %s", GARRISON_BUILDING_COMPLETE, name)
end

--------------------------------------------------------------------------------
-- GARRISON_FOLLOWER_ADDED

local GARRISON_FOLLOWER_ADDED_S = GARRISON_FOLLOWER_ADDED_TOAST .. ": %s"
local GARRISON_FOLLOWER_ADDED_UPGRADED_S = GARRISON_FOLLOWER_ADDED_TOAST .. ": %s. " .. LOOTUPGRADEFRAME_TITLE

function GarrisonFollowerAlertSystem:AddAlert(followerID, name, level, quality, isUpgraded)
	PlaySound("UI_Garrison_Toast_FollowerGained")

	local link = C_Garrison.GetFollowerLinkByID(followerID)
	if isUpgraded then
		Print(nil, nil, GARRISON_FOLLOWER_ADDED_UPGRADED_S, link or name, _G["ITEM_QUALITY" .. quality .."_DESC"])
	else
		Print(nil, nil, GARRISON_FOLLOWER_ADDED_S, link or name)
	end
end

local GARRISON_SHIP_ADDED_S = GARRISON_SHIPYARD_FOLLOWER_ADDED_TOAST .. ": %s"
local GARRISON_SHIP_ADDED_UPGRADED_S = GARRISON_SHIPYARD_FOLLOWER_ADDED_TOAST .. ": %s. " .. LOOTUPGRADEFRAME_TITLE

function GarrisonShipFollowerAlertSystem:AddAlert(followerID, name, class, texPrefix, level, quality, isUpgraded)
	PlaySound("UI_Garrison_Toast_FollowerGained")

	local link = C_Garrison.GetFollowerLinkByID(followerID)
	if isUpgraded then
		Print(nil, nil, GARRISON_SHIP_ADDED_UPGRADED_S, link or name, _G["ITEM_QUALITY" .. quality .."_DESC"])
	else
		Print(nil, nil, GARRISON_SHIP_ADDED_S, link or name)
	end
end
--------------------------------------------------------------------------------
-- GARRISON_MISSION_FINISHED

local GARRISON_MISSION_FINISHED = GARRISON_LOCATION_TOOLTIP .. " " .. GARRISON_MISSION_COMPLETE
local SHIPYARD_MISSION_FINISHED = GARRISON_SHIPYARD_FLEET_TITLE .. " " .. GARRISON_MISSION_COMPLETE

function GarrisonMissionAlertSystem:AddAlert(missionInfo)
	PlaySound("UI_Garrison_Toast_MissionComplete")
	
	local message = missionInfo.followerTypeID == LE_FOLLOWER_TYPE_SHIPYARD_6_2 and SHIPYARD_MISSION_FINISHED or GARRISON_MISSION_FINISHED
	local link = C_Garrison.GetMissionLink(missionInfo.missionID) or missionInfo.name

	Print(nil, nil, "%s: %s", message, link)
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
	if missionInfo.iLevel == 0 then
		Print(nil, nil, GARRISON_MISSION_ADDED_LEVEL,
			missionInfo.name,
			missionInfo.level,
			missionInfo.isRare and RARE or "")
	else
		Print(nil, nil, GARRISON_MISSION_ADDED_LEVEL_ITEMLEVEL,
			missionInfo.name,
			missionInfo.level,
			missionInfo.iLevel,
			missionInfo.isRare and RARE or "")
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

	Print(nil, nil, GARRISON_TALENT_RESEARCH_COMPLETE, talent.name)
end

--------------------------------------------------------------------------------

function GuildChallengeAlertSystem:AddAlert(challengeType, count, max)
	Print(nil, nil, "%s %s",
		_G["GUILD_CHALLENGE_TYPE" .. challengeType],
		format(GUILD_CHALLENGE_PROGRESS_FORMAT, count, max)
	)
end

--------------------------------------------------------------------------------
-- QUEST_LOOT_RECEIVED
-- SCENARIO_COMPLETED

function InvasionAlertSystem:AddAlert(rewardQuestID, rewardItemLink)
	if rewardItemLink then
		-- If we're seeing this with a reward the scenario hasn't been completed yet, no toast until scenario complete is triggered
		return false
	end

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

	Print(nil, nil, S_COMPLETE_REWARDS_S,
		zoneName or UNKNOWN,
		table.concat(rewardsList, PLAYER_LIST_DELIMITER))
end

--------------------------------------------------------------------------------
-- LOOT_ITEM_ROLL_WON
-- SHOW_LOOT_TOAST

local ROLL_WON_S = LOOT_ROLL_YOU_WON
local ROLL_WON_UPGRADED_S = LOOT_ROLL_YOU_WON .. " " .. LOOTUPGRADEFRAME_TITLE

function LootAlertSystem:AddAlert(itemLink, quantity, rollType, roll, specID, isCurrency, showFactionBG, lootSource, lessAwesome, isUpgraded, isPersonal)
	PlaySoundKitID(isUpgraded and 51561 or 31578) -- UI_Warforged_Item_Loot_Toast or UI_EpicLoot_Toast
	if isCurrency then
		if quantity > 1 then
			Print("CURRENCY", "CURRENCY", CURRENCY_GAINED_MULTIPLE, itemLink, quantity)
		else
			Print("CURRENCY", "CURRENCY", CURRENCY_GAINED, itemLink)
		end
	elseif rollType then
		if isUpgraded then
			local _, _, rarity = GetItemInfo(itemLink)
			Print(nil, "LOOT", ROLL_WON_UPGRADED_S, itemLink, _G["ITEM_QUALITY" .. rarity .. "_DESC"])
		else
			Print(nil, "LOOT", ROLL_WON_S, itemLink)
		end
	else
		if quantity > 1 then
			Print(nil, "LOOT", LOOT_ITEM_SELF_MULTIPLE, itemLink, quantity)
		else
			Print(nil, "LOOT", LOOT_ITEM_SELF, itemLink)
		end
	end
end

-------------------------------------------------------------------------------
-- SHOW_LOOT_TOAST_LEGENDARY_LOOTED

local LEGENDARY_LOOT_S = LOOT_ITEM_SELF .. "(" .. LEGENDARY_ITEM_LOOT_LABEL .. ")"

function LegendaryItemAlertSystem:AddAlert(itemLink)
	PlaySound("UI_LegendaryLoot_Toast")
	Print(nil, "LOOT", LEGENDARY_LOOT_S, itemLink)
end

--------------------------------------------------------------------------------
-- SHOW_LOOT_TOAST_UPGRADE

local ITEM_LOOT_UPGRADE_S = LOOT_ITEM_SELF .. " " .. LOOTUPGRADEFRAME_TITLE

function LootUpgradeAlertSystem:AddAlert(itemLink, quantity, specID, sex, baseQuality, isPersonal, lessAwesome)
	PlaySoundKitID(31578) -- UI_EpicLoot_Toast
	local _, _, rarity = GetItemInfo(itemLink)
	Print(nil, "LOOT", ITEM_LOOT_UPGRADE_S,
		itemLink,
		_G["ITEM_QUALITY" .. rarity .. "_DESC"])
end

--------------------------------------------------------------------------------

function MoneyWonAlertSystem:AddAlert(quantity)
	PlaySoundKitID(31578) -- UI_EpicLoot_Toast
	Print("MONEY", "MONEY", CURRENCY_GAINED, GetCoinTextureString(amount))
end

function HonorAwardedAlertSystem:AddAlert(amount)
	PlaySoundKitID(31578) -- UI_EpicLoot_Toast
	Print("CURRENCY", "CURRENCY", MERCHANT_HONOR_POINTS, amount)
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

	Print(nil, nil, rank and rank > 1 and RECIPE_LEARNED_UPGRADED_S or RECIPE_LEARNED_S,
		C_TradeSkillUI.GetRecipeLink(recipeID) or name,
		rankTexture or "")
end

local ERR_RECIPE_LEARNED = gsub(ERR_LEARN_RECIPE_S, "%%s", ".+")

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(frame, event, message, ...)
	if strmatch(message, ERR_RECIPE_LEARNED) then
		return true
	end
end)

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

	Print(nil, "BN_ALERT", "%s %s", BLIZZARD_STORE_PURCHASE_COMPLETE:gsub("%.$", ":"), link or name)
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

	Print(nil, nil, S_COMPLETE_REWARDS_S, name, table.concat(rewardsList, PLAYER_LIST_DELIMITER))
end
