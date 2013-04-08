-- Initiate Ace3 with the modules we need.
Floot = LibStub("AceAddon-3.0"):NewAddon("Floot", "AceConsole-3.0", "AceTimer-3.0", "AceEvent-3.0", "AceHook-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local Floot_State = {}
local FlootFrames = {}
local FlootComs = {}
local ConfigOpts
FlootRuntime = {
	FoundItems = {
		[999] = "None",
	},								-- Stores the won items from the lookup on PlayerNameItemLookup = {}				
	FoundItemId = 999,				-- Used to store the items Id for the gui dropdown of who has also rolled on this item.
	ItemOwnerslist = {},			-- Holds those that has won one or more items for the gui move item function.
	PlayerNameItemLookup = "Fubar",	-- Used to store the players name who's won items is being looked up.
	FoundItemRollers = {
		[999] = "None",
	},								-- Store the rollers that was located from FoundItemId
	ChosenItemRoller = 999,			-- Used to store the player who should have the item moved to him or her.
	ShowNonRollers = false,			-- MoveItem .. If true will add all raid members to select player to transfer item to dropdown.
	MoveRollType = false,			-- If true will for a change of the item roll type (main/off spec) when moving it to another player.
	VersionMajor = "1",				-- Addon Major Version number. This is bumped when incompability with older versions are broken.
	VersionMinor = "06",			-- Addon Minor Version number. This is bumped for new versions that is still combatible with the previous version.
	VersionCheck = nil,				-- Keep track if user has been warned of an out of date addon.
	RollStatus = "Stopped", 		-- Used to keep track of running rolls
	RollType = nil, 				-- Keep track of current roll type
	RollLoot = {}, 					-- This is where the content of the current roll loot is stored
	SyncAwarded = false,			-- If an item has been handed out, sync FlootAwardedItems if this is true.
	InSync = false,					-- This will prevent people from resetting Winnerlist if they are in sync.
	Loot = {}, 						-- This is where the content of the loot from the blizz window is stored
	Nuker = nil,               		-- Name of the raid nuker.
	IsInRaid = nil,					-- Keep track to see if we are already in a raid group.
	AddonVersions = nil,			-- Holds the raids addon versions to be displayed in gui
	AddonVersionsArray = {},		-- Holds the raw addon version data from players.
	LocalSetupButtonPressed = nil,	-- This is true if this player pressed the setup button
	LastVersionCheck = 0,			-- This contains the last time addon requested a version.
	AutoLootTimer = nil,			-- This is used to store the autoloot timer.
	MLCandidates = {},				-- Stores those who runs the addon.
	DoaLootRunning = nil,			-- Make sure we don't spam constantly if DoaLoot is loaded. nil or 1
	Debug = {
		WinnerList = nil,			-- if true will print Winnerlist debug
		MasterLoot = nil,			-- If true enables MasterLoot candidate debug
		LootQuality = 3, 			-- What quality should an item have to be shown.
		MasterLootCandidates = {}, 	-- Used to store MasterLootCandidates in for debug purpose
		DebuggerName = nil,			-- Stores the name of the debugger to transmit data to
		DebugData = nil,			-- if set true, the com debug will dump the data part too
		BypassRaid = nil,			-- If true bypass raid restrictions.	
	},
}

-- This has to be after the initital creation of FlootRuntime, as I am using variables from itself.
FlootRuntime["DownloadURL"] = "http://floot.xpoints.dk/download/FastLoot_" .. FlootRuntime["VersionMajor"] .. "." .. FlootRuntime["VersionMinor"] .. ".zip"

FlootCurrentRolls = {}   	-- Used to store rolls for mainspec

if (not FlootAwardedItems) then
	FlootAwardedItems = {}	-- Used to store awarded items in case some one wants to pass later.
end

if (not FlootMainWinnerList) then
	FlootMainWinnerList = {}  -- Keep track of the winners
end

if (not FlootOffWinnerList) then
	FlootOffWinnerList = {}  -- Keep track of the winners
end

if (not FlootTier15MainSpec) then
	FlootTier15MainSpec = {}	-- Tier15 tokens mainspec
end

if (not FlootTier15OffSpec) then
	FlootTier15OffSpec = {}	-- Tier15 tokens offspec
end

if (not FlootTier15HeroicMainSpec) then
	FlootTier15HeroicMainSpec = {}	-- Tier15 Heroic tokens mainspec
end

if (not FlootTier15HeroicOffSpec) then
	FlootTier15HeroicOffSpec = {}	-- Tier15 Heroic tokens offspec
end

if (not FlootTier14MainSpec) then
	FlootTier14MainSpec = {} -- Tier14 Mainspec
end

if (not FlootTier14OffSpec) then
	FlootTier14OffSpec = {} -- Tier14 Mainspec
end

if (not FlootTier14HeroicMainSpec) then
	FlootTier14HeroicMainSpec = {} -- Tier14 Mainspec
end

if (not FlootTier14HeroicOffSpec) then
	FlootTier14HeroicOffSpec = {} -- Tier14 Mainspec
end

if (not FlootRaidRoster ) then	-- Stores raid session data for upload.
	FlootRaidRoster = {
		Raiders = {},
		Bosses = {},
	}
end

if (not FlootAccounts ) then
	FlootAccounts = {}			-- Hold mains and alts. 
end

if (not FlootGuildRoster ) then
	FlootGuildRoster = {}			-- Holds a total update of the guild roster name, rank
end


Floot_ConfigDb = {
	Enabled = true,   										-- Addon enabled or disabled can be true / false
	OfficialMode = true,  									-- can be Official / Unofficial
	WinnerListResetDate = date("%d/%m/%y %H:%M"),			-- Contains the date for the last lootlist reset
	Mode = nil,												-- No longer used
	MasterLooter = false,									-- Contains the default masterlooter
--	KnownNukers = {
--		PlaceHolder = ""
--	},										-- Place holder so the gui can work
--	BannedNukers = {
--		PlaceHolder = ""
--	},										-- Holds those that are banned as nukers.
	RaidLootQuality = 3,					-- Set the Raids loot quality to this.
	RaidDifficulty = 3,						-- 3 = 10 player, 4 = 25 player, 5 = 10 player heroic, 6 = 25 player heroic. 
	RaidDifficultyAI = true,				-- can be true or false, will try and determine if it's a 10 or 25 man raid.
	RaidDiffucltyHeroic = false,			-- AI force heroic false / true
	RaiderRanks = {							-- If true, that guild rank is considered a raider rank.
		[0] = true,
		[1] = true,
		[2] = true,
		[3] = true,
		[4] = true,
		[5] = true,
		[6] = true,
		[7] = false,
		[8] = false,
		[9] = false,
	},
	RankNames = {
		[0] = "Rank 0",
		[1] = "Rank 1",
		[2] = "Rank 2",
		[3] = "Rank 3",
		[4] = "Rank 4",
		[5] = "Rank 5",
		[6] = "Rank 6",
		[7] = "Rank 7",
		[8] = "Rank 8",
		[9] = "Rank 9",
	},
}


--------------------------------------------------------
----  Stuff that should be done before the addon    ----
----  is enabled                                    ----
--------------------------------------------------------
function Floot:OnInitialize()
	self:RegisterEvent("LOOT_OPENED","GatherLootData")
	self:RegisterEvent("LOOT_CLOSED","CloseLootFrame")
	self:RegisterEvent("CHAT_MSG_SYSTEM", "IncomingRolls")
	self:RegisterEvent("VARIABLES_LOADED", "CleanOldConfig")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "SetZoneName")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "RaidGroupChanged")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "EnterWorld")
	Floot:CleanOldConfig()
	FlootGui = Floot:NewFlootGui()
	ConfigOpts = FlootGui:CreateGui()
	AceConfig:RegisterOptionsTable("Floot", ConfigOpts, {"fastloot", "floot"})
	self.OptionsFrame = AceConfigDialog:AddToBlizOptions("Floot", "Floot")
	FlootCom = Floot:NewFlootCom()
	FlootFrames = Floot:NewFlootFrames()
	FlootFrames:OnInitialize()  -- Initialize the FlootFrames 

end


--------------------------------------------------------
----     Player entering world or changing zone		----
--------------------------------------------------------
function Floot:EnterWorld()
	GuildRoster()
end


--------------------------------------------------------
----     Change old saved lua, to new format		----
--------------------------------------------------------
function Floot:CleanOldConfig()
	Floot_ConfigDb["Mode"] = nil

--	if not (Floot_ConfigDb["KnownNukers"] ) then
--		Floot_ConfigDb["KnownNukers"] = {}
--		Floot_ConfigDb["KnownNukers"]["PlaceHolder"] = ""
--	end

	if not (Floot_ConfigDb["OfficialMode"] == true or Floot_ConfigDb["OfficialMode"] == false) then
		Floot_ConfigDb["OfficialMode"] = true
	end

	if not (Floot_ConfigDb["RaidLootQuality"] ) then
		Floot_ConfigDb["RaidLootQuality"] = 3
	end

	if not (Floot_ConfigDb["RaidDifficulty"] ) then
		Floot_ConfigDb["RaidDifficulty"] = 3
	end

	if not (Floot_ConfigDb["RaidDifficultyAI"] == true or Floot_ConfigDb["RaidDifficultyAI"] == false ) then
		Floot_ConfigDb["RaidDifficultyAI"] = true
	end

	if not (Floot_ConfigDb["RaidDiffucltyHeroic"] == true or Floot_ConfigDb["RaidDiffucltyHeroic"] == false  ) then
		Floot_ConfigDb["RaidDiffucltyHeroic"] = false
	end

	if not (Floot_ConfigDb["MasterLooter"] ) then
		Floot_ConfigDb["MasterLooter"] = ""
	end

	if (Floot_ConfigDb["StoreAttendence"] == false or Floot_ConfigDb["StoreAttendence"] == true ) then
		Floot_ConfigDb["StoreAttendence"] = nil
	end

	if not (FlootRuntime["InSync"] == true or FlootRuntime["InSync"] == false) then
		FlootRuntime["InSync"] = false
	end

--	if not (Floot_ConfigDb["BannedNukers"] ) then
--		Floot_ConfigDb["BannedNukers"] = {}
--		Floot_ConfigDb["BannedNukers"]["PlaceHolder"] = ""
--	end

	if not (Floot_ConfigDb["RaiderRanks"] ) then
		Floot_ConfigDb["RaiderRanks"] = {
			[0] = true,
			[1] = true,
			[2] = true,
			[3] = true,
			[4] = true,
			[5] = true,
			[6] = true,
			[7] = false,
			[8] = false,
			[9] = false,
		}
	end

	if not (Floot_ConfigDb["RankNames"]) then
		Floot_ConfigDb["RankNames"] = {
			[0] = "Rank 0",
			[1] = "Rank 1",
			[2] = "Rank 2",
			[3] = "Rank 3",
			[4] = "Rank 4",
			[5] = "Rank 5",
			[6] = "Rank 6",
			[7] = "Rank 7",
			[8] = "Rank 8",
			[9] = "Rank 9",
		}
	end

end

--------------------------------------------------------
----             Set Raider Ranks               ----
--------------------------------------------------------
function Floot:SetRaiderRank(RankIndex, Value)
	local ML = Floot:GetML()
        local RL = Floot:GetRL()
	-- Make sure only ML and RL can change raider ranks during a raid.
	if ( UnitInRaid("player") ) then
		if not ( UnitName("player") == ML or UnitName("player") == RL ) then
			Floot:Print("Only Raid leader or Master looter is allowed to change loot ranks during a raid")
			return
		end
	end

	Floot_ConfigDb["RaiderRanks"][RankIndex] = Value

	-- Make sure we only broadcast in a synced raid.
	if (FlootRuntime["InSync"] == true ) then
		Floot:BroadcastRaiderRanks()
	end

end

--------------------------------------------------------
----             Get Guild Rank Names               ----
--------------------------------------------------------
function Floot:GetGuildRanks()
	local RankNames = {}
	RankNames = {
		[0] = "Rank 0",
		[1] = "Rank 1",
		[2] = "Rank 2",
		[3] = "Rank 3",
		[4] = "Rank 4",
		[5] = "Rank 5",
		[6] = "Rank 6",
		[7] = "Rank 7",
		[8] = "Rank 8",
		[9] = "Rank 9",
		}

	for i=1, GuildControlGetNumRanks(), 1 do
		local Rank = GuildControlGetRankName(i)
                local Index = i - 1
		RankNames[Index] = Rank
	end

	local GuildName = GetGuildInfo("player")
	if (GuildName) then
		Floot_ConfigDb["RankNames"] = RankNames
	end

end

--------------------------------------------------------
----          Return the opposite rolltype          ----
--------------------------------------------------------
function Floot:GetMoveRollType()
	if (FlootRuntime.FoundItemId ~= 999) then
		if (FlootAwardedItems[FlootRuntime.FoundItemId]["RollType"] == "MainSpec" ) then
			return "Change to Off spec"
		elseif ( FlootAwardedItems[FlootRuntime.FoundItemId]["RollType"] == "OffSpec" ) then
			return "Change to Main spec"
		end
	end
	return "Unkown Roll type"
end

--------------------------------------------------------
----            Find the ML in the raid             ----
--------------------------------------------------------
function Floot:GetML()
	local ML
	for i=1, GetNumGroupMembers() do
		local RaidName, _, _, _, _, _, _, _, _, _, IsML = GetRaidRosterInfo(i)
		if (IsML) then
			ML = RaidName
		end
	end
	return ML
end


--------------------------------------------------------
----    Find the Raid leader in the raid            ----
--------------------------------------------------------
function Floot:GetRL()
	local RL
	for i=1, GetNumGroupMembers() do
		local RaidName, IsRL, _, _, _, _, _, _, _, _, IsML = GetRaidRosterInfo(i)
		if (IsRL == 2) then
			RL = RaidName
		end
	end
	return RL
end

--------------------------------------------------------
----     Set the Zone name in the raid session      ----
--------------------------------------------------------
function Floot:SetZoneName()
	if ( FlootRuntime["InSync"] == true and Floot:GetML() == UnitName("player") ) then
		local NewLocation = false
		local IsInstance, InstanceType = IsInInstance()
		local RaidInstance = ""
		if (IsInstance == 1 and InstanceType == "raid") then
			RaidInstance = GetZoneText()
		else
			RaidInstance = "none"
		end

		if not (RaidInstance == "none") then
			if (FlootRaidRoster["Location"] == "none" or FlootRaidRoster["Location"] == "" or FlootRaidRoster["Location"] == nil) then
				FlootRaidRoster["Location"] = RaidInstance
				NewLocation = true
			else
				if (string.match(FlootRaidRoster["Location"], RaidInstance) == nil) then
					FlootRaidRoster["Location"] = FlootRaidRoster["Location"] .. " and " .. RaidInstance
					NewLocation = true
				end
			end
		end

		if (NewLocation == true) then
			Floot:BroadcastNewLocation()
		end

	end

	-- Make sure RaidRoster["Raiders"] are updated if the raid is started and no group changes happens
	Floot:StoreFlootRaidRoster()
end


--------------------------------------------------------
----       Setup a raid based on stored data        ----
--------------------------------------------------------
function Floot:RaidSetup(Remote)
	local IsML
	local MLPresent
	local RL = Floot:GetRL()

	if ( UnitInRaid("player") or FlootRuntime["Debug"]["BypassRaid"] ) then	-- Am I in a raid?

		-- Find out if the set ML is in the raid.
		for i=1, GetNumGroupMembers() do
			local RaidName = GetRaidRosterInfo(i)
			if (RaidName == Floot_ConfigDb["MasterLooter"]) then
				MLPresent = RaidName
			end
		end


		if ( UnitName("player") == RL ) then	-- Am I raid leader?

			local LootMethod = GetLootMethod()
			if ( MLPresent ) then	-- Do I have a Master looter set.
				if (LootMethod == "master") then
					SetLootMethod("master", Floot_ConfigDb["MasterLooter"], 1)
					PromoteToAssistant(MLPresent)
				else
					SetLootMethod("master", Floot_ConfigDb["MasterLooter"])
					PromoteToAssistant(MLPresent)
				end

			else	-- We do not have a Master Looter set who is in the raid
				if (LootMethod == "master") then
					SetLootMethod("master", UnitName("player"), 1 )
				else
					SetLootMethod("master", UnitName("player") )
				end
				Floot:Print("WARNING: No MasterLooter found, You're it!")
			end
	
			FlootRuntime["LootThresholdTimer"] = Floot:ScheduleTimer("SetRestOfRaidUp", 1, "SetLootThreshold")
			FlootRuntime["RaidDifficultyTimer"] = Floot:ScheduleTimer("SetRestOfRaidUp", 3, "SetRaidDifficulty")
			FlootRuntime["MLCheckTimer"] = Floot:ScheduleTimer("SetRestOfRaidUp", 5, "IsML")

--		else
			-- FlootRuntime["MLCheckTimer"] = Floot:ScheduleTimer("SetRestOfRaidUp", 5, "IsML")
		end

		-- Notifiy others to setup Floot
		if (Remote ~= "Yes") then
			FlootCom:SendMessage("RAID", "RaidSetup","Broadcast", "Yes")
		end

		Floot:CreateGuildRoster() -- Take snapshot of guild, as no one seems to do it manually.
		Floot:CreateAllAccounts() -- Create the table with alt and mains
	
	else
		Floot:Print("You're not in a raid, can't do any setup for you")
	end
end


--------------------------------------------------------
----  Set LootMethod and treshold when timer hits   ----
----  Timer is set from Floot:Setup()             ----
--------------------------------------------------------
function Floot:SetRestOfRaidUp(Type)
	if (Type == "SetLootThreshold") then
		SetLootThreshold(Floot_ConfigDb["RaidLootQuality"])	-- 3 = 10 player, 4 = 25 player, 5 = 10 player heroic, 6 = 25 player heroic. 
		FlootRuntime["LootThresholdTimer"] = nil

	elseif (Type == "SetRaidDifficulty") then
		-- If AI is true try then figure out how many we are and set raid instance.
		if (Floot_ConfigDb["RaidDifficultyAI"] == true) then
			if ( GetNumGroupMembers() < 11 and not Floot_ConfigDb["RaidDiffucltyHeroic"] ) then
				SetRaidDifficultyID(3)	-- Normal 10 man
			elseif (GetNumGroupMembers() < 11 and Floot_ConfigDb["RaidDiffucltyHeroic"] ) then
				SetRaidDifficultyID(5)	-- Heroic 10 man
			elseif (GetNumGroupMembers() > 10 and not Floot_ConfigDb["RaidDiffucltyHeroic"] ) then
				SetRaidDifficultyID(4)	-- Normal 25 man
			elseif (GetNumGroupMembers() > 10 and Floot_ConfigDb["RaidDiffucltyHeroic"]) then
				SetRaidDifficultyID(6)	-- Heroic 25 man
			end
		else
			SetRaidDifficultyID(Floot_ConfigDb["RaidDifficulty"])
		end
		FlootRuntime["RaidDifficultyTimer"] = nil

	elseif (Type == "IsML") then
		-- Build our Raid session info if I pressed the setup button
		if ( not FlootRaidRoster["RaidsessionId"] and FlootRuntime["LocalSetupButtonPressed"] == true and FlootRuntime["InSync"] == false ) then
			local build, _, tocversion = select(2, GetBuildInfo())
			local Foo, GUID = strsplit("x", UnitGUID("player"))
			FlootRaidRoster["RaidsessionId"] = GUID .. tocversion .. build .. tostring((GetTime() * 1000))
			FlootRaidRoster["MasterLooter"] = UnitName("player")
			FlootRaidRoster["Date"] = date("%Y/%m/%d")
			FlootRaidRoster["Version"] = FlootRuntime["VersionMajor"] .. "." .. FlootRuntime["VersionMinor"]
			FlootRaidRoster["Raiders"] = {}
			FlootRaidRoster["RaidMode"] = Floot_ConfigDb["OfficialMode"]
			Floot:SetRaidNuker()

			-- Start storing attendance and broadcast to others they should do the same.
			FlootRuntime["InSync"] = true
			Floot:BroadcastStartFlootRaidRosterGathering()
			Floot:SetZoneName() -- Check if the player has already entered an instance, and get the name.
		end
		-- Always clear the button pressed mark
		FlootRuntime["LocalSetupButtonPressed"] = false
--		Floot:SetRaidNuker()
	end
end


--------------------------------------------------------
----           Set the raid Nuker                   ----
--------------------------------------------------------
function Floot:SetRaidNuker()
	local InEnchanting = false  -- keep track of profession group
	local SkillName = "Enchanting"  -- profession we are looking for
	local NukerName = UnitName("player")
	local NukerSkill = 1

	for index=1, GetNumGuildTradeSkill(), 1 do
		local skillID, isCollapsed, iconTexture, headerName, _, numOnline, numPlayers, playerName, class, online, zone, skill, classFileName, isMobile = GetGuildTradeSkillInfo(index)
	
		if (headerName == SkillName) then
			InEnchanting = true
		end
   
		if (headerName ~= nil and headerName ~= SkillName) then
			InEnchanting = false
		end
   
		if (InEnchanting == true and playerName ~= nil) then
			for i=1, GetNumGroupMembers() do
				local RaidName, _, _, _, _, _, _, _, _, _, _ = GetRaidRosterInfo(i)
				if (RaidName == playerName) then
					if (skill > NukerSkill) then
						NukerName = playerName
						NukerSkill = skill
					end
				end
			end
		end
	end

	Floot:SetNuker(Input, NukerName)
end

--------------------------------------------------------
----   Return the text version of the addon mode    ----
--------------------------------------------------------
function Floot:GetAddonModeText()
	if (Floot_ConfigDb["OfficialMode"]) then
		return "Official"
	else
		return "Unofficial"
	end
end

--------------------------------------------------------
----          Print the version number              ----
--------------------------------------------------------
function Floot:OpenConfig()
	Floot:GetGuildRanks()
	if ( InterfaceOptionsFrame_OpenToCategory ) then
		InterfaceOptionsFrame_OpenToCategory("Floot")
	else
		InterfaceOptionsFrame_OpenToFrame("Floot")
	end
end

--------------------------------------------------------
----          Print the version number              ----
--------------------------------------------------------
function Floot:GetVersion()
	local Version = FlootRuntime["VersionMajor"] .. "." .. FlootRuntime["VersionMinor"]
	Floot:Print("Version: " .. Version)
end

--------------------------------------------------------
----  Any thing we need to do when we login or rl   ----
--------------------------------------------------------
function Floot:OnEnable()
	FlootFrames:OnEnable()
end

--------------------------------------------------------
----         Enables or disables the addon          ----
--------------------------------------------------------
function Floot:EnableDisable()
	if (Floot_ConfigDb["Enabled"]) then
		Floot_ConfigDb["Enabled"] = false
		Floot:Print("Addon Disabled")
	else
		Floot_ConfigDb["Enabled"] = true
		Floot:Print("Addon Enabled")
		Floot:RaidGroupChanged()
	end
end

--------------------------------------------------------
----             Set the Loot Quality               ----
--------------------------------------------------------
function Floot:SetLootQuality(Input, Quality)
	-- Input is from commandline
	-- Quality is from the menu

	if (Input) then
		Quality = string.sub(Input, -1,-1)
	end

	Quality = tonumber(Quality)
	FlootRuntime["Debug"]["LootQuality"] = Quality
end

--------------------------------------------------------
----      Check to see if this is a new raid        ----
--------------------------------------------------------
function Floot:RaidGroupChanged(Event, ...)

	if ( (UnitInRaid("player") and Floot_ConfigDb["Enabled"]) or (FlootRuntime["Debug"]["BypassRaid"])  ) then

		-- Alert players if they are running both Floot and DoaLoot
		if (IsAddOnLoaded("DoaLoot") and FlootRuntime["DoaLootRunning"] == nil) then
			Floot:Print(RED_FONT_COLOR_CODE .. "Do not run DoaLoot and FastLoot at the same time, you will experience double popups etc" .. FONT_COLOR_CODE_CLOSE)
			Floot:Print(RED_FONT_COLOR_CODE .. "Please disable DoaLoot" .. FONT_COLOR_CODE_CLOSE)
			Floot:Print(RED_FONT_COLOR_CODE .. "Yes .. this is spam!" .. FONT_COLOR_CODE_CLOSE)
			FlootRuntime["DoaLootRunning"] = 1
		end


		-- Fix if only one is running the addon, so the list at least have the players name.
		FlootRuntime["MLCandidates"][UnitName("player")] = UnitName("player")

		
		if not ( FlootRuntime["IsInRaid"] ) then -- This is a new raid
			FlootRuntime["IsInRaid"] = 1
			Floot:ClearWinnerList()
			Floot:TriggerVersionCheck(true)
--			Floot:BroadcastShareNukers()

			-- Ask if we are Collecting FlootRaidRoster info
			Floot:ScheduleTimer("BroadcastAreWeGatheringFlootRaidRoster", 1)
		end

		-- Store the data
		Floot:StoreFlootRaidRoster()

	else -- Left raid group
		FlootRuntime["IsInRaid"] = nil
		-- Need to stop collecting FlootRaidRoster
		FlootRuntime["InSync"] = false

	end

end

--------------------------------------------------------
----      Check to see if this is a new raid        ----
--------------------------------------------------------
function Floot:StoreFlootRaidRoster()
-- TODO Add gathering of guild rank	
	for ri = 1, GetNumGroupMembers() do
		local rname = GetRaidRosterInfo(ri)
		Floot:CreateAccounts(rname)
		local newrname = Floot:GetMainName(rname)
		for gi = 1, GetNumGuildMembers(true) do
			local gname, _, Rank = GetGuildRosterInfo(gi)
			if (newrname == gname) then
				FlootRaidRoster["Raiders"][gname] = Rank
			end
		end
	end
end


--------------------------------------------------------
----    Store total guild roster for web update     ----
--------------------------------------------------------
function Floot:CreateGuildRoster()
	FlootGuildRoster = {}
	for ri = 1, GetNumGuildMembers(true) do
		local Name, _, RankIndex = GetGuildRosterInfo(ri)
		FlootGuildRoster[Name] = RankIndex
	end
end


--------------------------------------------------------
----  Trigger af version check on login or reload   ----
--------------------------------------------------------
function Floot:TriggerVersionCheck(Force)
	local Transmit = {
		VersionMajor = FlootRuntime["VersionMajor"],
		VersionMinor = FlootRuntime["VersionMinor"],
		DownloadURL = FlootRuntime["DownloadURL"],
		ForceReply = Force,
	}
	FlootCom:SendMessage("RAID", "IncVersionCheck", "Broadcast", Transmit)
end

--------------------------------------------------------
----            Incoming version check              ----
--------------------------------------------------------
function Floot:IncVersionCheck(Message,Sender)
	Message["VersionMajor"] = tostring(Message["VersionMajor"])
	Message["VersionMinor"] = tostring(Message["VersionMinor"])
	FlootRuntime["VersionMajor"] = tostring(FlootRuntime["VersionMajor"])
	FlootRuntime["VersionMinor"] = tostring(FlootRuntime["VersionMinor"])

	Floot:Debug("VersionCheck", "Recieved Major " .. Message["VersionMajor"] .. " Minor " .. Message["VersionMinor"] .. " from " .. Sender)
	Floot:Debug("VersionCheck", "My Version Major " .. FlootRuntime["VersionMajor"] .. " Minor " .. FlootRuntime["VersionMinor"])

	local Transmit = {
		VersionMajor = FlootRuntime["VersionMajor"],
		VersionMinor = FlootRuntime["VersionMinor"],
		DownloadURL = FlootRuntime["DownloadURL"],
	}


	-- Store a list of those who runs the addon, for use with Master looter choice
	FlootRuntime["MLCandidates"][UnitName("player")] = UnitName("player")
	FlootRuntime["MLCandidates"][Sender] = Sender

	-- Store data for the gui display of version numbers
	-- Insert the inc version number into the array
	FlootRuntime["AddonVersionsArray"][Sender] = Message["VersionMajor"] .. "." .. Message["VersionMinor"]

	-- Store own version first
	FlootRuntime["AddonVersions"] = Floot:GetTextColor("Name",UnitName("player")) .. UnitName("player") .. FONT_COLOR_CODE_CLOSE .. ":     " .. FlootRuntime["VersionMajor"] .. "." .. FlootRuntime["VersionMinor"]

	-- Create the string that is used in the gui to display versions
	for Name, Version in pairs(FlootRuntime["AddonVersionsArray"]) do
		FlootRuntime["AddonVersions"] = FlootRuntime["AddonVersions"] .. "\n" .. Floot:GetTextColor("Name",Name) .. Name .. FONT_COLOR_CODE_CLOSE .. ":     " .. Version
	end


	-- Lets check if one of us is out of date

	local OutOfDate = false
	local OtherOutOfDate = false
	local MajorEqual = false

	if ( Message["VersionMajor"] > FlootRuntime["VersionMajor"] ) then -- Major is out of date
		OutOfDate = true
	elseif ( Message["VersionMajor"] < FlootRuntime["VersionMajor"] ) then
		OtherOutOfDate = true
	else
		MajorEqual = true
	end

	if ( Message["VersionMinor"] > FlootRuntime["VersionMinor"] and MajorEqual == true ) then
		OutOfDate = true
	elseif ( Message["VersionMinor"] < FlootRuntime["VersionMinor"] and MajorEqual == true ) then
		OtherOutOfDate = true
	end

	if ( OutOfDate == true and not FlootRuntime["VersionCheck"] == true ) then
		FlootRuntime["VersionCheck"] = true
		PlaySoundFile("Interface\\AddOns\\Floot\\Sounds\\Pause.mp3")
		local WarningFrame = FlootFrames:GetFrame("FlootUpdateWarning")
		local FlootUpdateEditBox = FlootFrames:GetFrame("FlootUpdateEditBox")
		FlootUpdateEditBox:SetText(Message["DownloadURL"])
		WarningFrame:Show()
		Floot:Debug("VersionCheck", "This addon is out of date")
	elseif (OtherOutOfDate == true) then
		Floot:Debug("VersionCheck", Sender .. " is out of date, sending a warning")
		FlootCom:SendMessage("WHISPER", "IncVersionCheck", Sender, Transmit)
	end

	if (Message["ForceReply"] and OtherOutOfDate == false) then
		Floot:Debug("VersionCheck", Sender .. " requested all to reply with there versions")
		FlootCom:SendMessage("WHISPER", "IncVersionCheck", Sender, Transmit)
	end

end


--------------------------------------------------------
----  Change the mode of the addon Official or      ----
----  Unofficial                                    ----
--------------------------------------------------------
function Floot:ChangeMode()
	local FlootResultFrame = FlootFrames:GetFrame("FlootResultFrame")
	if (FlootRuntime["RollStatus"] == "Running" or FlootResultFrame:IsVisible() ) then
		Floot:Print("It's not permitted to change mode in the middle of a roll or if the roll window is show")
		return
	end

	if (Floot_ConfigDb["OfficialMode"]) then
		Floot_ConfigDb["OfficialMode"] = false
		Floot:Print("Addon is now in Unofficial mode")
	else
		Floot_ConfigDb["OfficialMode"] = true
		Floot:Print("Addon is now in Official mode")
	end
	FlootFrames:UpdateStatusFrame()
end

-------------------------------------------------------
----        Start roll by linking in chat          ----
-------------------------------------------------------
function Floot:ManualLootStart(Input)
	if (not Input) then
		return
	end

	local Frame = FlootFrames:GetFrame("FlootFrame")
	if ( Frame:IsVisible() ) then
		Floot:Print("Can't start a roll when your already looting")
		return
	end

	local ItemLink = string.sub(Input, 7, -1)
	local TooltipInfo = Floot:CheckItem(ItemLink)
	local ItemName = string.match(ItemLink, ".+|h%[(.+)%]|h.+")
	local _, _, _, _, _, ItemType, ItemSubType, _, _, _ = GetItemInfo(ItemLink)

	local LootList = "Normal"
	if ( FlootListType[ItemName] ) then
		LootList = FlootListType[ItemName]
	end


	local LootInfo = {
		["ItemName"] = ItemName,
		["ItemLink"] = ItemLink,
		["ItemType"] = ItemType,
		["ItemSubType"] = ItemSubType,
		["BindType"] = TooltipInfo["BindType"],
		["ArmorType"] = TooltipInfo["ArmorType"],
		["EquipSlot"] = TooltipInfo["EquipSlot"],
		["ClassLimit"] = TooltipInfo["ClassLimit"],
		["LootList"] = LootList,
		["LootSlotId"] = 1,
		["ButtonId"] = 1,
	}
	table.insert(FlootRuntime["Loot"], LootInfo)
	FlootFrames:CreateLootRow(LootInfo)

end

-------------------------------------------------------
---- Loot window has been opened gather data       ----
-------------------------------------------------------
function Floot:GatherLootData()
	if ( (UnitInRaid("player") and Floot_ConfigDb["Enabled"] and FlootRuntime["InSync"]== true) or (FlootRuntime["Debug"]["BypassRaid"]) ) then
		-- Store what boss we killed
		local LootTarget = nil
		local LootTargetGuid = nil
		if (UnitName("target")) then -- Make sure the window did not close to fast to get the data.
			LootTarget = UnitName("target")
			LootTargetGuid = tonumber((UnitGUID("target")):sub(-12, -9), 16) -- npc id
			if (FlootRaidBosses[LootTarget] == true) then
				FlootRaidRoster["Bosses"][LootTarget] = LootTargetGuid
			end
		end
		-- Store the loot data
		local LootInfo = {}
		local FoundAutoLoot = {}
		ButtonId = 0
		for i=1, GetNumLootItems() do
			if (GetLootSlotType(i) == 1) then
				local Icon, ItemName, Quantity, Quality = GetLootSlotInfo(i)
				local ItemLink = GetLootSlotLink(i)
				local TooltipInfo = Floot:CheckItem(ItemLink)
				local _, _, _, _, _, ItemType, ItemSubType, _, _, _ = GetItemInfo(ItemLink)
				local SplitItemLink = {}
				SplitItemLink = Floot:Split(":",ItemLink)
				local Tooltip = SplitItemLink[2]

				local LootList = "Normal"

				if ( FlootListType[Tooltip] ) then
					LootList = FlootListType[Tooltip]
				elseif ( FlootListType[ItemName] ) then
					LootList = FlootListType[ItemName]
				end

				if (not FlootIgnoreItems[ItemName]) then
					if (Quality >= FlootRuntime["Debug"]["LootQuality"]) then
						ButtonId = ButtonId + 1
						LootInfo = {
							["ItemName"] = ItemName,
							["ItemLink"] = ItemLink,
							["Tooltip"] = Tooltip,
							["LootSlotId"] = i,
							["ButtonId"] = ButtonId,
							["ItemType"] = ItemType,
							["BindType"] = TooltipInfo["BindType"],
							["ArmorType"] = TooltipInfo["ArmorType"],
							["EquipSlot"] = TooltipInfo["EquipSlot"],
							["ClassLimit"] = TooltipInfo["ClassLimit"],
							["LootList"] = LootList,
							["ItemSubType"] = ItemSubType,
						}
						table.insert(FlootRuntime["Loot"], LootInfo)
						FlootFrames:CreateLootRow(LootInfo)
					end
				elseif (FlootAutoLootItems[ItemName]) then -- Autoloot items
					table.insert(FoundAutoLoot,
					{
					Name = ItemName,
					Slot = i,
				})
				elseif (FlootAutoBankItems[ItemName] and Floot_ConfigDb["OfficialMode"] and Quality >= FlootRuntime["Debug"]["LootQuality"] ) then -- Auto Bank the item
					FlootRuntime["RollLoot"]["LootSlotId"] = i
					FlootRuntime["RollLoot"]["ItemLink"] = ItemLink
					FlootRuntime["RollLoot"]["ButtonId"] = 200
					Floot:BankItem()
				end
			elseif (GetLootSlotType(i) == 2) then  -- Autoloot money
				LootSlot(i)
			end
		end
		FlootRuntime["AutoLootTimer"] = Floot:ScheduleTimer("AutoLoot", 4, FoundAutoLoot)
	end
end

-------------------------------------------------------
---- 	       	   Delayed Autoloot                ----
-------------------------------------------------------
function Floot:AutoLoot(FoundAutoLoot)
	FlootRuntime["AutoLootTimer"] = nil

	for Index = 1, #FoundAutoLoot, 1 do
		LootSlot(FoundAutoLoot[Index]["Slot"])
	end
end

-------------------------------------------------------
---- 			Read an items tooltip              ----
-------------------------------------------------------
function Floot:CheckItem(ItemLink,Pattern)
	FlootTooltip = FlootFrames:GetFrame("FlootTooltip")
	FlootTooltip:SetOwner( WorldFrame, "ANCHOR_NONE" );
	TooltipInfo = {}	-- DEBUG Should be local
	if (ItemLink) then
		FlootTooltip:SetHyperlink(ItemLink)

		local EquipSlotArray = { "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet", "Finger", "Trinket", "Main Hand", "Off Hand", "One-Hand", "Two-Hand", "Thrown", "Ranged", "Totem", "Relic", "Idol", "Sigil" }
		local ArmorTypeArray = { "Cloth", "Leather", "Mail", "Plate" }


		for i = 1, FlootTooltip:NumLines(), 1 do
			-- LEFT SIDE
			local Line = _G["FlootTooltipTextLeft" .. i]:GetText()
			if ( i == 1) then
				TooltipInfo["Name"] = Line
			elseif ( Line and string.match(Line, "Binds when picked up") ) then
				TooltipInfo["BindType"] = "BoP"
			elseif (Line and string.match(Line, "Binds when equipped") ) then
				TooltipInfo["BindType"] = "BoE"
			elseif (Line and string.match(Line, "^Classes:") ) then
				TooltipInfo["ClassLimit"] = string.match(Line, "^Classes: (.*)$")
			end

			for i = 1, #EquipSlotArray, 1 do	-- Find the equip slot
				if (Line and string.match(Line, "^" .. EquipSlotArray[i] .. "$") ) then
					TooltipInfo["EquipSlot"] = Line
				end
			end

			-- RIGHT SIDE
			local Line = _G["FlootTooltipTextRight" .. i]:GetText()
			for i = 1, #ArmorTypeArray, 1 do		-- Find the armor type
				if (Line and string.match(Line, "^" .. ArmorTypeArray[i] .. "$") ) then
					TooltipInfo["ArmorType"] = Line
				end
			end

		end
	end
	return TooltipInfo
end

--------------------------------------------------------
----   Called when the Blizz loot frame is closed    ---
--------------------------------------------------------
function Floot:CloseLootFrame()
	if (FlootRuntime["AutoLootTimer"] ) then
		Floot:CancelTimer(FlootRuntime["AutoLootTimer"])
		FlootRuntime["AutoLootTimer"] = nil
	end

	FlootRuntime["Loot"] = {}
	local LootFrame = FlootFrames:GetFrame("FlootFrame")
	local ResultFrame = FlootFrames:GetFrame("FlootResultFrame")
	FlootRuntime["RollStatus"] = "Stopped"
	FlootCurrentRolls = {}
	LootFrame:Hide()
	ResultFrame:Hide()
	FlootRuntime["RollLoot"] = {}
	FlootRuntime["RollType"] = nil
	FlootFrames:CleanupFlootFrame()
	FlootFrames:CleanupResultFrame()

	-- Insert Check if FlootAwardedItems should be synced
	if (FlootRuntime["SyncAwarded"] == true) then
		Floot:BroadcastSyncFlootAwardedItems()
	end
end

--------------------------------------------------------
----   Called when the Result window is closed      ----
--------------------------------------------------------
function Floot:CloseResultFrame()
	local ResultFrame = FlootFrames:GetFrame("FlootResultFrame")
	ResultFrame:Hide()
	FlootFrames:CleanupResultFrame()
end

--------------------------------------------------------
----          Return a players guild rank            ---
--------------------------------------------------------
function Floot:GetCharacterRank(Name)
	if (Floot_ConfigDb["OfficialMode"]) then
		for i=1, GetNumGuildMembers(true), 1 do 
			local RosterName, Rank, RankIndex = GetGuildRosterInfo(i)
			if (RosterName == Name and Floot_ConfigDb["RaiderRanks"][RankIndex] == true) then
				return 1
			elseif (RosterName == Name and Floot_ConfigDb["RaiderRanks"][RankIndex] == false ) then
				return 2
			end
		end
		return 3 -- This is not a guild member
	else
		return 1 -- Off-raid, so fake all to raiders
	end
end

--------------------------------------------------------
----   Announces roll start and sets state          ----
--------------------------------------------------------
function Floot:StartRolls(this)
--	if (FlootRuntime["RollStatus"] == "Running") then
--		Floot:Print("Can't start a new roll while a another is in progress")
--		return
--	end


	FlootFrames:CleanupResultFrame()
	FlootCurrentRolls = {}
	FlootRuntime["RollStatus"] = "Running"
	FlootRuntime["RollLoot"] = this["LootInfo"]
	
	Floot:SetNukeButton()

	-- Find out what type of roll it is.
	if (string.find(this:GetName(), "FlootMainSpec%d+")) then
		FlootRuntime["RollType"] = "MainSpec"
		SendChatMessage("Main Spec roll for " .. this["LootInfo"]["ItemLink"], "RAID_WARNING")
	elseif (string.find(this:GetName(), "FlootOffSpec%d+")) then
		FlootRuntime["RollType"] = "OffSpec"
		SendChatMessage("Off Spec roll for " .. this["LootInfo"]["ItemLink"], "RAID_WARNING")
	end

	-- update the Result frame's roll type frame
	local ResultFrameMode = FlootFrames:GetFrame("FlootResultFrameRollType")
	ResultFrameMode.Text:SetText(FlootRuntime["RollType"] .. "\n\n" .. this["LootInfo"]["ItemLink"])
	ResultFrameMode:SetWidth( FlootFrames:GetFrame("FlootResultFrame"):GetWidth() - 60)
	ResultFrameMode:SetHeight(ResultFrameMode.Text:GetHeight() + 12) 

	local ResultFrame = FlootFrames:GetFrame("FlootResultFrame")
	ResultFrame:Show()
end

---------------------------------------------------------
----   Register incoming rolls                        ---
---------------------------------------------------------
function Floot:IncomingRolls(Event, String)

	if (FlootRuntime["RollStatus"] == "Running") then  -- Do we have a roll going?
		local Name, Roll, Controll = string.match(String, "(.*) rolls (%d+) %((1%-100)%)")
		local RejectedRoller = nil

		if (Name) then
			for i=1, #FlootCurrentRolls do -- Is this a double roll if so complain and abort
				if (FlootCurrentRolls[i]["Name"] == Name) then
					RejectedRoller = Name
				end
			end

			if (RejectedRoller) then
				Floot:Print("Rejected double roll from " .. RejectedRoller)
				return
			end

			-- ArmorTypeMatch 
			-- 9 = No match
			-- 8 = Match
			local ArmorTypeMatch = "9" 
			for i = 1, GetNumGroupMembers() do
				local RosterName, _, _, _, Class, _, _, _, _, _, _ = GetRaidRosterInfo(i)
				if (RosterName == Name) then
					if ( FlootRuntime.RollLoot.ArmorType ) then
						if ( ( Class == "Mage" or Class == "Warlock" or Class == "Priest" ) and FlootRuntime.RollLoot.ArmorType == "Cloth" ) then
							ArmorTypeMatch = "8"
						elseif ( ( Class == "Druid" or Class == "Rogue" ) and FlootRuntime.RollLoot.ArmorType == "Leather" ) then
							ArmorTypeMatch = "8"
						elseif ( ( Class == "Shaman" or Class == "Hunter" ) and FlootRuntime.RollLoot.ArmorType == "Mail" ) then
							ArmorTypeMatch = "8"
						elseif ( ( Class == "Warrior" or Class == "Paladin" or Class == "Death Knight" ) and FlootRuntime.RollLoot.ArmorType == "Plate" ) then
							ArmorTypeMatch = "8"
						end
					end
				end
			end


			local InvertedRoll = tostring(string.format("%02d", 100 - Roll))
			local WinnerIndex = tostring( string.format("%03d", Floot:GetWinnerIndex(Name, FlootRuntime["RollLoot"]["LootList"]) ) )
			Index = tostring(Floot:GetCharacterRank(Name) .. ArmorTypeMatch .. WinnerIndex .. InvertedRoll)

			table.insert(FlootCurrentRolls,
			{
				Name = Name,
				Roll = Roll,
				Rank = Floot:GetCharacterRank(Name),
				Index = tostring(Index),
				ArmorTypeMatch = ArmorTypeMatch,
				WinnerListNumber = tostring(Floot:GetWinnerIndex(Name, FlootRuntime["RollLoot"]["LootList"])) -- Won Items
			})

			table.sort(FlootCurrentRolls, FlootRollSort)

			FlootFrames:PopulateResultWindow(FlootCurrentRolls)
		end
	end
end

---------------------------------------------------------
----            Roll Index sort function             ----
---------------------------------------------------------
function FlootRollSort(RollA,RollB)
	if(RollA.Index < RollB.Index) then
		return RollA.Index < RollB.Index
	end
end

---------------------------------------------------------
----   	        Announce all the loot                ----
---------------------------------------------------------
function Floot:AnnounceLoot()
	SendChatMessage("We have", "RAID_WARNING")

	local ItemLinks = ""
	local Loop = 1
	for Index = 1, #FlootRuntime["Loot"] do
		ItemLinks = ItemLinks .. " " .. FlootRuntime["Loot"][Index]["ItemLink"]
		if (Loop == 2) then
			SendChatMessage(ItemLinks, "RAID")
			Loop = 0
			ItemLinks = ""
		end
		Loop = Loop + 1
	end
	
	if (ItemLinks) then
		SendChatMessage(ItemLinks, "RAID")
	end
end

---------------------------------------------------------
----   Get the Winner index Number by name           ----
---------------------------------------------------------
function Floot:GetWinnerIndex(Name, LootList)
	-- If it's an official raid and mainspec, or if it's off raid use winnerlist

	-- Make sure that any one that has rolled is in the lootlist with 000
	if (FlootRuntime["RollType"] == "MainSpec") then
		if ( not FlootMainWinnerList[Name] ) then
			FlootMainWinnerList[Name] = 000
		end

		if ( not FlootTier15MainSpec[Name] ) then
			FlootTier15MainSpec[Name] = 000
		end

		if ( not FlootTier15HeroicMainSpec[Name] ) then
			FlootTier15HeroicMainSpec[Name] = 000
		end

		if ( not FlootTier14MainSpec[Name] ) then
			FlootTier14MainSpec[Name] = 000
		end

		if ( not FlootTier14HeroicMainSpec[Name] ) then
			FlootTier14HeroicMainSpec[Name] = 000
		end

	elseif ( FlootRuntime["RollType"] == "OffSpec") then
		if ( not FlootOffWinnerList[Name] ) then
			FlootOffWinnerList[Name] = 000
		end

		if ( not FlootTier15OffSpec[Name] ) then
			FlootTier15OffSpec[Name] = 000
		end

		if ( not FlootTier15HeroicOffSpec[Name] ) then
			FlootTier15HeroicOffSpec[Name] = 000
		end

		if ( not FlootTier14OffSpec[Name] ) then
			FlootTier14OffSpec[Name] = 000
		end

		if ( not FlootTier14HeroicOffSpec[Name] ) then
			FlootTier14HeroicOffSpec[Name] = 000
		end
	end


	-- Find out what should be returned
	if (LootList == "Normal") then	-- This is normal loot
		if ( FlootRuntime["RollType"] == "MainSpec" ) then 
			return FlootMainWinnerList[Name]
		elseif ( FlootRuntime["RollType"] == "OffSpec" ) then
			return FlootOffWinnerList[Name]
		end

	elseif (LootList == "Tier15") then	-- This is Tier15 tokens
		if (FlootRuntime["RollType"] == "MainSpec" ) then
			return FlootTier15MainSpec[Name]
		elseif ( FlootRuntime["RollType"] == "OffSpec" ) then
			return FlootTier15OffSpec[Name]
		end

	elseif (LootList =="Tier15h") then -- This is Tier15 heroic tokens
		if (FlootRuntime["RollType"] == "MainSpec" ) then
			return FlootTier15HeroicMainSpec[Name]
		elseif ( FlootRuntime["RollType"] == "OffSpec" ) then
			return FlootTier15HeroicOffSpec[Name]
		end

	elseif (LootList == "Tier14") then	-- This is Tier14 tokens
		if (FlootRuntime["RollType"] == "MainSpec" ) then
			return FlootTier14MainSpec[Name]
		elseif ( FlootRuntime["RollType"] == "OffSpec" ) then
			return FlootTier14OffSpec[Name]
		end

	elseif (LootList =="Tier14h") then -- This is Tier14 heroic tokens
		if (FlootRuntime["RollType"] == "MainSpec" ) then
			return FlootTier14HeroicMainSpec[Name]
		elseif ( FlootRuntime["RollType"] == "OffSpec" ) then
			return FlootTier14HeroicOffSpec[Name]
		end


	end
end

---------------------------------------------------------
----  Award Item to a winner                         ----
---------------------------------------------------------
function Floot:AwardItem(Name)
	Floot:EndRolls()

	-- This is Normal Loot, Always deduct for a mainspec of offspec for that evening
	if ( FlootRuntime["RollType"] == "MainSpec" ) then
		FlootMainWinnerList[Name] = FlootMainWinnerList[Name] + 1
	elseif ( FlootRuntime["RollType"] == "OffSpec" ) then
		FlootOffWinnerList[Name] = FlootOffWinnerList[Name] + 1
	end

	-- This is Tier15 tokens
	if ( FlootRuntime["RollLoot"]["LootList"] == "Tier15" ) then
		if ( FlootRuntime["RollType"] == "MainSpec" ) then
			FlootTier15MainSpec[Name] = FlootTier15MainSpec[Name] + 1
		elseif ( FlootRuntime["RollType"] == "OffSpec" ) then
			FlootTier15OffSpec[Name] = FlootTier15OffSpec[Name] + 1
		end
	end

	-- This is Tier15 Heroic tokens
	if ( FlootRuntime["RollLoot"]["LootList"] == "Tier15h" ) then
		if ( FlootRuntime["RollType"] == "MainSpec" ) then
			FlootTier15HeroicMainSpec[Name] = FlootTier15HeroicMainSpec[Name] + 1
		elseif ( FlootRuntime["RollType"] == "OffSpec" ) then
			FlootTier15HeroicOffSpec[Name] = FlootTier15HeroicOffSpec[Name] + 1
		end
	end

	-- This is Tier14 tokens
	if ( FlootRuntime["RollLoot"]["LootList"] == "Tier14" ) then
		if ( FlootRuntime["RollType"] == "MainSpec" ) then
			FlootTier14MainSpec[Name] = FlootTier14MainSpec[Name] + 1
		elseif ( FlootRuntime["RollType"] == "OffSpec" ) then
			FlootTier14OffSpec[Name] = FlootTier14OffSpec[Name] + 1
		end
	end

	-- This is Tier14 Heroic tokens
	if ( FlootRuntime["RollLoot"]["LootList"] == "Tier14h" ) then
		if ( FlootRuntime["RollType"] == "MainSpec" ) then
			FlootTier14HeroicMainSpec[Name] = FlootTier14HeroicMainSpec[Name] + 1
		elseif ( FlootRuntime["RollType"] == "OffSpec" ) then
			FlootTier14HeroicOffSpec[Name] = FlootTier14HeroicOffSpec[Name] + 1
		end
	end

	Floot:GiveItem(Name)
end

--------------------------------------------------------
----              Nuke an item                      ----
--------------------------------------------------------
function Floot:NukeItem()

	table.insert(FlootCurrentRolls,
	{
		Name = "_nuked",
		Roll = 999,
		Rank = 1,
		Index = 3999999,
		ArmorTypeMatch = 9,
		WinnerListNumber = 99,
	})

	if not (FlootMainWinnerList["_nuked"]) then
		FlootMainWinnerList["_nuked"] = 0
	end

	if not (FlootOffWinnerList["_nuked"]) then
		FlootOffWinnerList["_nuked"] = 0
	end

	if not (FlootTier15MainSpec["_nuked"]) then
		FlootTier15MainSpec["_nuked"] = 0
	end

	if not (FlootTier15OffSpec["_nuked"]) then
		FlootTier15OffSpec["_nuked"] = 0
	end

	if not (FlootTier15HeroicMainSpec["_nuked"]) then
		FlootTier15HeroicMainSpec["_nuked"] = 0
	end

	if not (FlootTier15HeroicOffSpec["_nuked"]) then
		FlootTier15HeroicOffSpec["_nuked"] = 0
	end

	if not (FlootTier14MainSpec["_nuked"]) then
		FlootTier14MainSpec["_nuked"] = 0
	end

	if not (FlootTier14OffSpec["_nuked"]) then
		FlootTier14OffSpec["_nuked"] = 0
	end

	if not (FlootTier14HeroicMainSpec["_nuked"]) then
		FlootTier14HeroicMainSpec["_nuked"] = 0
	end

	if not (FlootTier14HeroicOffSpec["_nuked"]) then
		FlootTier14HeroicOffSpec["_nuked"] = 0
	end


	-- Normal items
	if ( FlootRuntime["RollLoot"]["LootInfo"] == "Normal" ) then
		if ( FlootRuntime["RollType"] == "MainSpec" ) then
			FlootMainWinnerList["_nuked"] = FlootMainWinnerList["_nuked"] + 1
		elseif ( FlootRuntime["RollType"] == "OffSpec" ) then
			FlootOffWinnerList["_nuked"] = FlootOffWinnerList["_nuked"] + 1
		end
		-- Tier15 items
	elseif (FlootRuntime["RollLoot"]["LootInfo"] == "Tier15" ) then
		if (FlootRuntime["RollType"] == "MainSpec" ) then
			FlootTier15MainSpec["_nuked"] = FlootTier15MainSpec["_nuked"] + 1
		elseif (FlootRuntime["RollType"] == "OffSpec" ) then
			FlootTier15OffSpec["_nuked"] = FlootTier15OffSpec["_nuked"] + 1
		end

		-- Tier15 Heroic items
	elseif (FlootRuntime["RollLoot"]["LootInfo"] == "Tier15h" ) then
		if (FlootRuntime["RollType"] == "MainSpec" ) then
			FlootTier15HeroicMainSpec["_nuked"] = FlootTier15HeroicMainSpec["_nuked"] + 1
		elseif (FlootRuntime["RollType"] == "OffSpec" ) then
			FlootTier15HeroicOffSpec["_nuked"] = FlootTier15HeroicOffSpec["_nuked"] + 1
		end

		-- Tier14 items
	elseif (FlootRuntime["RollLoot"]["LootInfo"] == "Tier14" ) then
		if (FlootRuntime["RollType"] == "MainSpec" ) then
			FlootTier14MainSpec["_nuked"] = FlootTier14MainSpec["_nuked"] + 1
		elseif (FlootRuntime["RollType"] == "OffSpec" ) then
			FlootTier14OffSpec["_nuked"] = FlootTier14OffSpec["_nuked"] + 1
		end

		-- Tier14 Heroic items
	elseif (FlootRuntime["RollLoot"]["LootInfo"] == "Tier14h" ) then
		if (FlootRuntime["RollType"] == "MainSpec" ) then
			FlootTier14HeroicMainSpec["_nuked"] = FlootTier14HeroicMainSpec["_nuked"] + 1
		elseif (FlootRuntime["RollType"] == "OffSpec" ) then
			FlootTier14HeroicOffSpec["_nuked"] = FlootTier14HeroicOffSpec["_nuked"] + 1
		end

	end

	Floot:StoreAwardedItem("_nuked")
	Floot:GiveItem(FlootRuntime["Nuker"], true)
	FlootRuntime["SyncAwarded"] = true
end

--------------------------------------------------------
----            Give Item to Bank                   ----
--------------------------------------------------------
function Floot:BankItem()
	if (Floot:GetML() ~= UnitName("player") ) then
		return
	end

	for i = 1, GetNumGuildMembers(), 1 do
		local RosterName, _, RankIndex = GetGuildRosterInfo(i)
		if (RankIndex == 0 or RankIndex == 1 or RankIndex == 2) then -- 0 = GM, 1 = Officers, 2 = Officers
--			for RaidIndex = 1, GetNumGroupMembers() do
			for RaidIndex = 1, 25 do
				local RaidName = GetRaidRosterInfo(RaidIndex)
				if (RaidName == RosterName) then
					Floot:GiveItem(RosterName, true)	-- True = this should not be registered as an item won
					SendChatMessage("Giving you the item for the guild bank", "WHISPER", "Common", RosterName);
					return true
				end
			end
		end
	end
	Floot:CleanUpAfterItem()
	Floot:Print("|cffc41f3b I did not find an Officer to hand the item to, you have to give it to some one yourself")
end

--------------------------------------------------------
----  Find the "Loot Candiate" and give out item    ----
--------------------------------------------------------
function Floot:GiveItem(Name, Nuking)

	for Loop = 1, 4 do
		FlootRuntime["Debug"]["MasterLootCandidates"] = {}
		Floot:Debug("MasterLoot", "Looking for " .. Name)
		for Candidate = 1, GetNumGroupMembers() do  -- Lets Hand out the item
			table.insert(FlootRuntime["Debug"]["MasterLootCandidates"], Candidate)
			if ( GetMasterLootCandidate(FlootRuntime["RollLoot"]["LootSlotId"], Candidate) == Name ) then
				Floot:Debug("MasterLoot", "Got a Match for handout " .. GetMasterLootCandidate(FlootRuntime["RollLoot"]["LootSlotId"], Candidate) )
				GiveMasterLoot(FlootRuntime["RollLoot"]["LootSlotId"], Candidate)
				if (Nuking) then
					SendChatMessage("Nuking " .. FlootRuntime["RollLoot"]["ItemLink"], "RAID")
				else
					SendChatMessage("Awarded ".. FlootRuntime["RollLoot"]["ItemLink"] .. " to " .. Name, "RAID")
					FlootRuntime["SyncAwarded"] = true
					Floot:StoreAwardedItem(Name)
					Floot:BroadcastWinnerList()
				end
				
				Floot:CleanUpAfterItem()
				Floot:Debug("MasterLoot","Use /dump FlootRuntime[\"Debug\"][\"MasterLootCandidates\"] to see the full list")
				return true
			end
		end
	end
	
	Floot:Debug("MasterLoot","Use /flootloot debug dumpwinnerlist to see the full list")
	if not (Nuking) then
		SendChatMessage("Tried to hand out ".. FlootRuntime["RollLoot"]["ItemLink"] .. " to " .. Name .. " but ML hand out failed", "RAID")
		FlootRuntime["SyncAwarded"] = true
		Floot:StoreAwardedItem(Name)
		Floot:BroadcastWinnerList()
	else
		Floot:Print(RED_FONT_COLOR_CODE .. "Tried to hand out ".. FlootRuntime["RollLoot"]["ItemLink"] .. RED_FONT_COLOR_CODE .. " to " .. Floot:GetTextColor("Name",Name) .. Name .. RED_FONT_COLOR_CODE .. " for nuking but ML hand out failed")
	end
	Floot:CleanUpAfterItem()
end

--------------------------------------------------------
----          Store and Awarded Item                ----
--------------------------------------------------------
function Floot:StoreAwardedItem(Name)
	-- Store info of who won.
		table.insert(FlootAwardedItems, {
			ItemName = FlootRuntime["RollLoot"]["ItemName"],
			ItemLink = FlootRuntime["RollLoot"]["ItemLink"],
			RollType = FlootRuntime["RollType"],
			LootList = FlootRuntime["RollLoot"]["LootList"],
			Winner = Name,
			Rollers = FlootCurrentRolls,
		})
end


--------------------------------------------------------
----           Find players won items,              ----
----           and who was next in line             ----
--------------------------------------------------------
function Floot:FindItemByPlayer(Input, Name)

	if (Input) then
		-- Do some thing
	end

	Name = Floot:FormatName(Name)
	local Found = false
	for IIndex, InfoArray in pairs(FlootAwardedItems) do	-- Grap the indidual item arrays
		if (InfoArray["Winner"] == Name) then	-- The person has won this item.
			Found = true
			FlootRuntime["PlayerNameItemLookup"] = Name
			for RIndex, Rollers in pairs(InfoArray["Rollers"]) do
				if (Rollers["Name"] == Name) then
					local NextInLineIndex = RIndex + 1
					if (InfoArray["Rollers"][NextInLineIndex]) then
					end
				end
			end
		end
	end

	if not (Found) then
		local NameColor = Floot:GetTextColor("Name",Name)
		Floot:Print(NameColor .. Name .. FONT_COLOR_CODE_CLOSE .." is not registered for any won items")
		-- Reset the Dropdowns?
	else
		Floot:CreateLookupItemsArray()
	end
end

--------------------------------------------------------
----   Create the Move Item from list for the gui   ----
--------------------------------------------------------
function Floot:CreateItemOwnersList()
	FlootRuntime["ItemOwnerslist"] = {}
	for Index, Array in pairs(FlootAwardedItems) do
		FlootRuntime["ItemOwnerslist"][FlootAwardedItems[Index]["Winner"]] = Floot:GetTextColor("Name",FlootAwardedItems[Index]["Winner"]) .. FlootAwardedItems[Index]["Winner"]
	end
	return FlootRuntime["ItemOwnerslist"]
end


--------------------------------------------------------
----             Create the array for the           ----
----             itemlookup dropdown menu           ----
--------------------------------------------------------
function Floot:CreateLookupItemsArray()
	if (FlootRuntime["PlayerNameItemLookup"] ) then
		FlootRuntime["FoundItems"] = {}
		local Found = false
		for IIndex, InfoArray in pairs(FlootAwardedItems) do
			if (InfoArray["Winner"] == FlootRuntime["PlayerNameItemLookup"] ) then
				Found = true
				FlootRuntime["FoundItems"][IIndex] = InfoArray["ItemName"]
			end
		end
	end
		
	if (Found == false) then
		FlootRuntime["FoundItems"] = { 
			[999] = "None",
		}
		FlootRuntime["PlayerNameItemLookup"] = nil
	end

end

--------------------------------------------------------
----            Create the array for the            ----
----           Next in line dropdown menu           ----
--------------------------------------------------------
function Floot:CreateLookupRollersByItemID(FoundItemId)
	local Found = false
	local RealRollers = {}
	local LastIndex = 1
	FlootRuntime["FoundItemId"] = FoundItemId
	FlootRuntime["FoundItemRollers"] = {}

	-- Clean out the fake ones if an item has been moved
	for AIndex, AwardedArray in pairs(FlootAwardedItems) do
		local Winner = FlootAwardedItems[AIndex]["Winner"]

		for RIndex, RollerArray in pairs(FlootAwardedItems[AIndex]["Rollers"]) do
			if ( RollerArray["Roll"] == 999 and Winner ~= RollerArray["Name"] ) then
				FlootAwardedItems[AIndex]["Rollers"][RIndex] = nil
			end
		end
	end

	if (FlootRuntime["FoundItemId"] ~= 999 ) then
		for Index, Array in pairs(FlootAwardedItems[FlootRuntime.FoundItemId]["Rollers"]) do


			if (FlootRuntime["PlayerNameItemLookup"] == FlootAwardedItems[FlootRuntime.FoundItemId]["Rollers"][Index]["Name"] ) then -- Don't list the winner
				FlootRuntime["FoundItemRollers"][Index] = RED_FONT_COLOR_CODE .. FlootAwardedItems[FlootRuntime.FoundItemId]["Rollers"][Index]["Name"]
				RealRollers[FlootAwardedItems[FlootRuntime.FoundItemId]["Rollers"][Index]["Name"]] = true
			else
				FlootRuntime["FoundItemRollers"][Index] = GREEN_FONT_COLOR_CODE .. FlootAwardedItems[FlootRuntime.FoundItemId]["Rollers"][Index]["Name"]
				RealRollers[FlootAwardedItems[FlootRuntime.FoundItemId]["Rollers"][Index]["Name"]] = true
			end

			if (Found == false) then
				FlootRuntime["ChosenItemRoller"] = 999
			end
			Found = true
			LastIndex = Index
		end

		if (FlootRuntime.ShowNonRollers and FlootRuntime.FoundItemId) then
			for i=1, GetNumGroupMembers() do
				local Name = GetRaidRosterInfo(i)
				if not ( RealRollers[Name] ) then
					LastIndex = LastIndex + 1
					FlootRuntime["FoundItemRollers"][LastIndex] = Name
				end
			end
			LastIndex = LastIndex + 1
			FlootRuntime["FoundItemRollers"][LastIndex] = "_nuked"
		end
	
	else
		FlootRuntime["FoundItemRollers"] = {
			[999] = "None",
		}
	end

	FlootRuntime["FoundItemId"] = FoundItemId	-- Needs to be set last or it can bug the FoundItemRollers varaible.
	return FlootRuntime["FoundItemRollers"]
end


--------------------------------------------------------
----      Move item from PlayerA to PlayerB         ----
--------------------------------------------------------
function Floot:MoveItem(ChosenItemRoller)

	if (ChosenItemRoller == 999) then return end

	if (Floot:GetML() ~= UnitName("player") ) then
		Floot:Print("You're not ML, only the ML can reassign items")
		return
	end

	if not ( FlootAwardedItems[FlootRuntime.FoundItemId]["Rollers"][ChosenItemRoller] ) then -- Did not roll but should recieve item
		FlootAwardedItems[FlootRuntime.FoundItemId]["Rollers"][ChosenItemRoller] = {
			WinnerListNumber = 99,
			Name = FlootRuntime["FoundItemRollers"][ChosenItemRoller],
			ArmorTypeMatch = 9,
			Roll = 999,
			Index = 3999999,
			Rank = 1,
		}
	end


	FlootRuntime.ChosenItemRoller = ChosenItemRoller
	local RecievingPlayerName = FlootAwardedItems[FlootRuntime.FoundItemId]["Rollers"][ChosenItemRoller]["Name"]
	local Message = "Moved " .. FlootAwardedItems[FlootRuntime.FoundItemId]["ItemLink"] .. " from " .. FlootRuntime.PlayerNameItemLookup
	local LootList = FlootAwardedItems[FlootRuntime.FoundItemId]["LootList"] 

	-- Move won points from one player to another.
	-- Move Main Spec
	if ( FlootAwardedItems[FlootRuntime.FoundItemId]["RollType"] == "MainSpec" ) then
		Message = Message .. " as main spec to " .. RecievingPlayerName
		
		FlootMainWinnerList[FlootRuntime.PlayerNameItemLookup] = FlootMainWinnerList[FlootRuntime.PlayerNameItemLookup] -1
	
		-- Tier15
		if (LootList == "Tier15") then -- Need to decrement the Tier15 token list too if this is a tier10 item.
			FlootTier15MainSpec[FlootRuntime.PlayerNameItemLookup] = FlootTier15MainSpec[FlootRuntime.PlayerNameItemLookup] -1
		end

		-- Tier15 Heroic
		if (LootList == "Tier15h") then -- Need to decrement the Tier15 token list too if this is a tier10 heroic item.
			FlootTier15HeroicMainSpec[FlootRuntime.PlayerNameItemLookup] = FlootTier15HeroicMainSpec[FlootRuntime.PlayerNameItemLookup] -1
		end


		-- Tier 11
		if (LootList == "Tier14") then -- Need to decrement the tier10 token list too if this is a tier10 item.
			FlootTier14MainSpec[FlootRuntime.PlayerNameItemLookup] = FlootTier14MainSpec[FlootRuntime.PlayerNameItemLookup] -1
		end

		-- Tier 11 Heroic
		if (LootList == "Tier14h") then -- Need to decrement the tier10 token list too if this is a tier10 heroic item.
			FlootTier14HeroicMainSpec[FlootRuntime.PlayerNameItemLookup] = FlootTier14HeroicMainSpec[FlootRuntime.PlayerNameItemLookup] -1
		end


		if (FlootRuntime.MoveRollType == false) then	-- don't change roll type
			Message = Message .. " as main spec"
			if ( FlootMainWinnerList[RecievingPlayerName] ) then
				FlootMainWinnerList[RecievingPlayerName] = FlootMainWinnerList[RecievingPlayerName] +1
			else
				FlootMainWinnerList[RecievingPlayerName] = 1
			end
			Floot:Print("Moved Item to " .. FlootRuntime["FoundItemRollers"][ChosenItemRoller] .. FONT_COLOR_CODE_CLOSE .. " as MainSpec")

		else	-- Change roll type give new winner Offspec instead.
			Message = Message .. " as off spec"
			if ( FlootOffWinnerList[RecievingPlayerName] ) then
				FlootOffWinnerList[RecievingPlayerName] = FlootOffWinnerList[RecievingPlayerName] + 1
			else
				FlootOffWinnerList[RecievingPlayerName] = 1
			end
			FlootAwardedItems[FlootRuntime.FoundItemId]["RollType"] = "OffSpec"
			Floot:Print("Moved Item to " .. FlootRuntime["FoundItemRollers"][ChosenItemRoller] .. FONT_COLOR_CODE_CLOSE .. " as OffSpec")
		end

		-- Tier15 items needs to be moved by themself
		if (LootList == "Tier15") then

			if (FlootRuntime.MoveRollType == false) then	-- don't change roll type
				if ( FlootTier15MainSpec[RecievingPlayerName] ) then
					FlootTier15MainSpec[RecievingPlayerName] = FlootTier15MainSpec[RecievingPlayerName] +1
				else
					FlootTier15MainSpec[RecievingPlayerName] = 1
				end
				Floot:Print("Moved Item to " .. FlootRuntime["FoundItemRollers"][ChosenItemRoller] .. FONT_COLOR_CODE_CLOSE .. " as MainSpec")
	
			else	-- Change roll type give new winner Offspec instead.
				if ( FlootTier15OffSpec[RecievingPlayerName] ) then
					FlootTier15OffSpec[RecievingPlayerName] = FlootTier15OffSpec[RecievingPlayerName] + 1
				else
					FlootTier15OffSpec[RecievingPlayerName] = 1
				end
			end
		end

		-- Tier15 Heroic items needs to be moved by themself
		if (LootList == "Tier15h") then

			if (FlootRuntime.MoveRollType == false) then	-- don't change roll type
				if ( FlootTier15HeroicMainSpec[RecievingPlayerName] ) then
					FlootTier15HeroicMainSpec[RecievingPlayerName] = FlootTier15HeroicMainSpec[RecievingPlayerName] +1
				else
					FlootTier15HeroicMainSpec[RecievingPlayerName] = 1
				end
				Floot:Print("Moved Item to " .. FlootRuntime["FoundItemRollers"][ChosenItemRoller] .. FONT_COLOR_CODE_CLOSE .. " as MainSpec")
	
			else	-- Change roll type give new winner Offspec instead.
				if ( FlootTier15HeroicOffSpec[RecievingPlayerName] ) then
					FlootTier15HeroicOffSpec[RecievingPlayerName] = FlootTier15HeroicOffSpec[RecievingPlayerName] + 1
				else
					FlootTier15HeroicOffSpec[RecievingPlayerName] = 1
				end
			end
		end



		-- Tier14 items needs to be moved by themself
		if (LootList == "Tier14") then

			if (FlootRuntime.MoveRollType == false) then	-- don't change roll type
				if ( FlootTier14MainSpec[RecievingPlayerName] ) then
					FlootTier14MainSpec[RecievingPlayerName] = FlootTier14MainSpec[RecievingPlayerName] +1
				else
					FlootTier14MainSpec[RecievingPlayerName] = 1
				end
				Floot:Print("Moved Item to " .. FlootRuntime["FoundItemRollers"][ChosenItemRoller] .. FONT_COLOR_CODE_CLOSE .. " as MainSpec")
	
			else	-- Change roll type give new winner Offspec instead.
				if ( FlootTier14OffSpec[RecievingPlayerName] ) then
					FlootTier14OffSpec[RecievingPlayerName] = FlootTier14OffSpec[RecievingPlayerName] + 1
				else
					FlootTier14OffSpec[RecievingPlayerName] = 1
				end
			end
		end

		-- Tier14 Heroic items needs to be moved by themself
		if (LootList == "Tier14h") then

			if (FlootRuntime.MoveRollType == false) then	-- don't change roll type
				if ( FlootTier14HeroicMainSpec[RecievingPlayerName] ) then
					FlootTier14HeroicMainSpec[RecievingPlayerName] = FlootTier14HeroicMainSpec[RecievingPlayerName] +1
				else
					FlootTier14HeroicMainSpec[RecievingPlayerName] = 1
				end
				Floot:Print("Moved Item to " .. FlootRuntime["FoundItemRollers"][ChosenItemRoller] .. FONT_COLOR_CODE_CLOSE .. " as MainSpec")
	
			else	-- Change roll type give new winner Offspec instead.
				if ( FlootTier14HeroicOffSpec[RecievingPlayerName] ) then
					FlootTier14HeroicOffSpec[RecievingPlayerName] = FlootTier14HeroicOffSpec[RecievingPlayerName] + 1
				else
					FlootTier14HeroicOffSpec[RecievingPlayerName] = 1
				end
			end
		end



	-- Move Offspec
	elseif ( FlootAwardedItems[FlootRuntime.FoundItemId]["RollType"] == "OffSpec") then
		Message = Message .. " as off spec to " .. RecievingPlayerName

		FlootOffWinnerList[FlootRuntime.PlayerNameItemLookup] = FlootOffWinnerList[FlootRuntime.PlayerNameItemLookup] -1

		-- Tier15
		if (LootList == "Tier15") then
			FlootTier15OffSpec[FlootRuntime.PlayerNameItemLookup] = FlootTier15OffSpec[FlootRuntime.PlayerNameItemLookup] -1
		end

		-- Tier15 heroic
		if (LootList == "Tier15h") then
			FlootTier15HeroicOffSpec[FlootRuntime.PlayerNameItemLookup] = FlootTier15HeroicOffSpec[FlootRuntime.PlayerNameItemLookup] -1
		end

		-- Tier 11
		if (LootList == "Tier14") then
			FlootTier14OffSpec[FlootRuntime.PlayerNameItemLookup] = FlootTier15OffSpec[FlootRuntime.PlayerNameItemLookup] -1
		end

		-- Tier 11 heroic
		if (LootList == "Tier14h") then
			FlootTier14HeroicOffSpec[FlootRuntime.PlayerNameItemLookup] = FlootTier14HeroicOffSpec[FlootRuntime.PlayerNameItemLookup] -1
		end


		if (FlootRuntime.MoveRollType == false) then	-- don't change roll type
			Message = Message .. " as off spec"
			if ( FlootOffWinnerList[RecievingPlayerName] ) then
				FlootOffWinnerList[RecievingPlayerName] = FlootOffWinnerList[RecievingPlayerName] + 1
			else
				FlootOffWinnerList[RecievingPlayerName] = 1
			end
			Floot:Print("Moved Item to " .. FlootRuntime["FoundItemRollers"][ChosenItemRoller] .. FONT_COLOR_CODE_CLOSE .. " as Off Spec")

		else	-- Change roll type give new winner Main spec
			Message = Message .. " as main spec"
			if ( FlootMainWinnerList[RecievingPlayerName] ) then
				FlootMainWinnerList[RecievingPlayerName] = FlootMainWinnerList[RecievingPlayerName] +1
			else
				FlootMainWinnerList[RecievingPlayerName] = 1
			end
			FlootAwardedItems[FlootRuntime.FoundItemId]["RollType"] = "MainSpec"
			Floot:Print("Moved Item to " .. FlootRuntime["FoundItemRollers"][ChosenItemRoller] .. FONT_COLOR_CODE_CLOSE .. " as Main Spec")
		end


		-- Tier15 items needs to be moved by themself
		if (LootList == "Tier15") then

			if (FlootRuntime.MoveRollType == false) then	-- don't change roll type
				if ( FlootTier15OffSpec[RecievingPlayerName] ) then
					FlootTier15OffSpec[RecievingPlayerName] = FlootTier15OffSpec[RecievingPlayerName] + 1
				else
					FlootTier15OffSpec[RecievingPlayerName] = 1
				end
	
			else	-- Change roll type give new winner Main spec
				if ( FlootTier15MainSpec[RecievingPlayerName] ) then
					FlootTier15MainSpec[RecievingPlayerName] = FlootTier15MainSpec[RecievingPlayerName] +1
				else
					FlootTier15MainSpec[RecievingPlayerName] = 1
				end
			end
		end

		-- Tier15 heroic items needs to be moved by themself
		if (LootList == "Tier15h") then

			if (FlootRuntime.MoveRollType == false) then	-- don't change roll type
				if ( FlootTier15HeroicOffSpec[RecievingPlayerName] ) then
					FlootTier15HeroicOffSpec[RecievingPlayerName] = FlootTier15HeroicOffSpec[RecievingPlayerName] + 1
				else
					FlootTier15HeroicOffSpec[RecievingPlayerName] = 1
				end
	
			else	-- Change roll type give new winner Main spec
				if ( FlootTier15HeroicMainSpec[RecievingPlayerName] ) then
					FlootTier15HeroicMainSpec[RecievingPlayerName] = FlootTier15HeroicMainSpec[RecievingPlayerName] +1
				else
					FlootTier15HeroicMainSpec[RecievingPlayerName] = 1
				end
			end
		end



		-- Tier14 items needs to be moved by themself
		if (LootList == "Tier14") then

			if (FlootRuntime.MoveRollType == false) then	-- don't change roll type
				if ( FlootTier14OffSpec[RecievingPlayerName] ) then
					FlootTier14OffSpec[RecievingPlayerName] = FlootTier14OffSpec[RecievingPlayerName] + 1
				else
					FlootTier14OffSpec[RecievingPlayerName] = 1
				end
	
			else	-- Change roll type give new winner Main spec
				if ( FlootTier14MainSpec[RecievingPlayerName] ) then
					FlootTier14MainSpec[RecievingPlayerName] = FlootTier14MainSpec[RecievingPlayerName] +1
				else
					FlootTier14MainSpec[RecievingPlayerName] = 1
				end
			end
		end

		-- Tier14 heroic items needs to be moved by themself
		if (LootList == "Tier14h") then

			if (FlootRuntime.MoveRollType == false) then	-- don't change roll type
				if ( FlootTier14HeroicOffSpec[RecievingPlayerName] ) then
					FlootTier14HeroicOffSpec[RecievingPlayerName] = FlootTier14HeroicOffSpec[RecievingPlayerName] + 1
				else
					FlootTier14HeroicOffSpec[RecievingPlayerName] = 1
				end
	
			else	-- Change roll type give new winner Main spec
				if ( FlootTier14HeroicMainSpec[RecievingPlayerName] ) then
					FlootTier14HeroicMainSpec[RecievingPlayerName] = FlootTier14HeroicMainSpec[RecievingPlayerName] +1
				else
					FlootTier14HeroicMainSpec[RecievingPlayerName] = 1
				end
			end
		end

	end

	-- send message to raid that the item has been moved.
	SendChatMessage(Message,"RAID")

	-- Change the FlootAwardedItems array to match
	FlootAwardedItems[FlootRuntime.FoundItemId]["Winner"] = FlootAwardedItems[FlootRuntime.FoundItemId]["Rollers"][ChosenItemRoller]["Name"]

	-- Reset FlootRuntime Variables conserning the lookup
	FlootRuntime["FoundItems"] = {
		[999] = "None",
	}
	FlootRuntime["FoundItemId"] = 999
	FlootRuntime["PlayerNameITemLookup"] = nil
	FlootRuntime["FoundItemRollers"] = {
		[999] = "None",
	}
	FlootRuntime["ChosenItemRoller"] = "None"
	FlootRuntime["PlayerNameItemLookup"] = nil
	FlootRuntime["MoveRollType"] = false

	-- FlootAwardedItems changed so update all others
	Floot:BroadcastSyncFlootAwardedItems()
end

--------------------------------------------------------
----          Clean up after award or nuke          ----
--------------------------------------------------------
function Floot:DeleteItem()

	if ( Floot:GetML() == UnitName("player") ) then

		if ( FlootRuntime.FoundItemId ~= 999 and FlootRuntime.FoundItemId ~= nil) then
			local OwnerName = FlootAwardedItems[FlootRuntime.FoundItemId]["Winner"]

			if ( FlootAwardedItems[FlootRuntime.FoundItemId]["RollType"] == "MainSpec" ) then
				Floot:DecrementMainSpecWonItem(nil, OwnerName)	-- Change the players won item so it's no longer registered as won
			else
				Floot:DecrementOffSpecWonItem(nil, OwnerName)		-- Change the players won item so it's no longer registered as won
			end
			FlootAwardedItems[FlootRuntime.FoundItemId] = nil
	
			FlootRuntime["FoundItems"] = {
				[999] = "None",
			}
			FlootRuntime["FoundItemId"] = 999
			FlootRuntime["PlayerNameITemLookup"] = nil
			FlootRuntime["FoundItemRollers"] = {
				[999] = "None",
			}
			FlootRuntime["ChosenItemRoller"] = "None"
			FlootRuntime["PlayerNameItemLookup"] = nil
			FlootRuntime["MoveRollType"] = false
			Floot:CreateItemOwnersList()

			-- Need to send the FlootAwardedItems as it has just been changed
			Floot:BroadcastSyncFlootAwardedItems()

		else	-- No item found
			Floot:Print("Can't delete an unknown item")
		end
	else
		Floot:Print("You're not the ML, so you can't delete items")
	end
end

--------------------------------------------------------
----          Clean up after award or nuke          ----
--------------------------------------------------------
function Floot:CleanUpAfterItem()

	FlootFrames:CleanupResultFrame() -- Clear the PlayerResultFrames
	FlootCurrentRolls = {} -- Don't want any old rolls to be hanging around
	local ResultFrame = FlootFrames:GetFrame("FlootResultFrame")
	ResultFrame:Hide()
	if not ( FlootRuntime["RollLoot"]["ButtonId"] == 200 ) then	-- 200 is magic number for autobank items.
		local MainSpecButton = FlootFrames:GetFrame("FlootMainSpec" .. FlootRuntime["RollLoot"]["ButtonId"])
		MainSpecButton:Hide()
		local OffSpecButton = FlootFrames:GetFrame("FlootOffSpec" .. FlootRuntime["RollLoot"]["ButtonId"])
		OffSpecButton:Hide()
	end
	FlootRuntime["RollStatus"] = "Stopped"
	FlootRuntime["RollType"] = nil
	FlootRuntime["RollLoot"] = {}

end

--------------------------------------------------------
----           Set the raid nuker                   ----
--------------------------------------------------------
function Floot:SetNuker(Input, Nuker)
	-- Input is from commandline, not used any more.
	-- Nuker is from menu.

	if (Nuker == "") then
		FlootRuntime["Nuker"] = nil
		Floot:Print("Nuker cleared, if this was not you're intent please type the name of a player in the raid.")
		return
	end

--	if (Floot_ConfigDb["BannedNukers"][Nuker]) then
--		Floot:Print(RED_FONT_COLOR_CODE .. "That nuker is in your ban list, no nuker set" .. FONT_COLOR_CODE_CLOSE)
--		return
--	end

	if (Nuker) then
		for i = 1, GetNumGroupMembers() do
			local Name = GetRaidRosterInfo(i)
			if (Name == Nuker) then
				FlootRuntime["Nuker"] = Nuker
				Floot:Print("Nuker set to " .. Floot:GetTextColor("Name",Nuker) .. Nuker)
				Found = true
			end
		end
	end

	if (not Found) then
		FlootRuntime["Nuker"] = nil
		Floot:Print("Nuker cleared, if this was not you're intent please type the name of a player in the raid.")
	end
end

--------------------------------------------------------
----     Check if the Nuke button should be shown   ----
--------------------------------------------------------
function Floot:SetNukeButton()
	local NukeButton = FlootFrames:GetFrame("FlootNukeButton")

	if ( ( (FlootRuntime["RollLoot"]["BindType"] and FlootRuntime["RollLoot"]["BindType"] == "BoE") or ( FlootRuntime["RollLoot"]["ItemType"] and FlootRuntime["RollLoot"]["ItemType"] == "Recipe") ) and Floot_ConfigDb["OfficialMode"]) then
		NukeButton:Show()
		NukeButton:SetText("Bank")
		NukeButton:SetScript("OnMouseUP", Floot.BankItem)
		return true
	end

	if (FlootRuntime["Nuker"]) then
		for i=1, GetNumGroupMembers() do
			local Name = GetRaidRosterInfo(i)
			if (Name == FlootRuntime["Nuker"]) then
				NukeButton:SetScript("OnMouseUP", Floot.NukeItem)
				NukeButton:SetText("Nuke")
				NukeButton:Show()
				return true
			end
		end
	end
	NukeButton:Hide()
end

--------------------------------------------------------
----             End the rolling                    ----
--------------------------------------------------------
function Floot:EndRolls()
	if (FlootRuntime["RollStatus"] == "Running") then
		-- Stop listening to rolls
		FlootRuntime["RollStatus"] = "Stopped"
		Floot:Print("No more rolls accepted")
	else
		Floot:Print("No Rolling in progress, need an ongoing roll to stop it")
	end
end

--------------------------------------------------------
----          Return FlootRuntime                 ----
--------------------------------------------------------
function Floot:GetRuntime()
	return FlootRuntime
end


--------------------------------------------------------
----         Reset the raid session                 ----
--------------------------------------------------------
function Floot:SendClearRaidSession()
	FlootCom:SendMessage("RAID", "ClearRaidSession", "Broadcast", "Force")
	Floot:ClearWinnerList("Force", "You")
end

--------------------------------------------------------
----   Ask to clear the winner list when entering   ----
----   an instance                                  ----
--------------------------------------------------------
function Floot:ClearWinnerList(Force, Sender)
	
	if (FlootRuntime["InSync"] == true and (not Force) ) then
		Floot:Print("You're in Sync with the Master looter, so you can't clear the data")
		return
	end

	FlootMainWinnerList = {}
	FlootOffWinnerList = {}
	FlootAwardedItems = {}
	FlootAccounts = {}
	FlootRaidRoster = {
		Raiders = {},
		Bosses = {},
	}
	FlootRuntime["InSync"] = false
	FlootRuntime["Nuker"] = nil
	Floot_ConfigDb["WinnerListResetDate"] = date("%d/%m/%y %H:%M")
	local Frame = FlootFrames:GetFrame("FlootlootWinnerListDateFrame")
	Frame.Text:SetText(Floot_ConfigDb["WinnerListResetDate"])
	if (Force and Sender) then -- We got a broadcast to clear session.
		Floot:Print(Sender .. " Cleared the raid session, data is no longer collected")
	elseif (Force) then
		Floot:Print("Winner list, nuker, attendance info, Raid session, and Awarded items has been cleared")
	end
end

--------------------------------------------------------
----     Decrement a players mainspec won items     ----
--------------------------------------------------------
function Floot:DecrementMainSpecWonItem(Input, TmpName)

	-- Input data is from command line
	-- TmpName is input from the menu
	
	if (Input) then
		TmpName = string.match(Input, "remove mainspec (.*)")
	end

	if (TmpName) then 
		local Name = Floot:FormatName(TmpName)	
		if (FlootMainWinnerList[Name]) then  -- We have some thing in the list
			if ( FlootMainWinnerList[Name] > 0) then
				FlootMainWinnerList[Name] = FlootMainWinnerList[Name] -1
				Floot:Print("I have removed one mainspec item from " .. Name)
				return true
			else
				Floot:Print("That player is not registered for any mainspec items")
			end
		else
			Floot:Print("I could not find " .. Name .. " in the mainspec loot list")
		end
	else 
		Floot:Print("Did you forget to give a name?")
	end
end

--------------------------------------------------------
----     Decrement a players offspec won items      ----
--------------------------------------------------------
function Floot:DecrementOffSpecWonItem(Input, TmpName)

	-- Input data is from command line
	-- TmpName is input from the menu
	
	if (Input) then
		TmpName = string.match(Input, "remove offspec (.*)")
	end


	if (TmpName) then 
		local Name = Floot:FormatName(TmpName)
		if (FlootOffWinnerList[Name]) then  -- We have some thing in the list
			if ( FlootOffWinnerList[Name] > 0) then
				FlootOffWinnerList[Name] = FlootOffWinnerList[Name] -1
				Floot:Print("I have removed one offspec item from " .. Name)
				return true
			else
				Floot:Print("That player is not registered for any offspec items")
			end
		else
			Floot:Print("I could not find " .. Name .. " in the offspec loot list")
		end
	else 
		Floot:Print("Did you forget to give a name?")
	end
end

--------------------------------------------------------
----     Increment a players mainspec won items     ----
--------------------------------------------------------
function Floot:IncrementMainSpecWonItem(Input,TmpName)

	-- Input data is from command line
	-- TmpName is input from the menu
	
	if (Input) then
		TmpName = string.match(Input, "add mainspec (.*)")
	end

	if (TmpName) then 
		local Name = Floot:FormatName(TmpName)
		if ( UnitInRaid(Name) ) then
			if (FlootMainWinnerList[Name]) then  -- Have this person rolled or won an item
				FlootMainWinnerList[Name] = FlootMainWinnerList[Name] + 1
				Floot:Print("I have added one mainspec item to " .. Name)
			else
				FlootMainWinnerList[Name] = 1
				Floot:Print("I have set " .. Name .. " to one item won")
			end
		else
			Floot:Print(Name .. " is not in the raid, so cant add an item")
		end
	else
		Floot:Print("Did you forget to give a name?")
	end
end

--------------------------------------------------------
----     Increment a players Offspec won items      ----
--------------------------------------------------------
function Floot:IncrementOffSpecWonItem(Input, TmpName)

	-- Input data is from command line
	-- TmpName is input from the menu

	if (Input) then
		TmpName = string.match(Input, "add offspec (.*)")
	end

	if (TmpName) then 
		local Name = Floot:FormatName(TmpName)
		if ( UnitInRaid(Name) ) then
			if ( FlootOffWinnerList[Name] ) then  -- Have this person rolled or won an item
				FlootOffWinnerList[Name] = FlootOffWinnerList[Name] + 1
				Floot:Print("I have added one offspec item to " .. Name)
			else
				FlootOffWinnerList[Name] = 1
				Floot:Print("I have set " .. Name .. " to one item won")
			end
		else
			Floot:Print(Name .. " is not in the raid, so cant add an item")
		end
	else
		Floot:Print("Did you forget to give a name?")
	end
end

--------------------------------------------------------
----   Uppercase the first letter, lower case rest  ----
--------------------------------------------------------
function Floot:FormatName(TmpName)
	if (TmpName) then
		TmpName = string.lower(TmpName)
		local Name = string.upper(string.sub(TmpName, 1, 1)) .. string.sub(TmpName,2) -- Format the name to capitalize first character, and lowercase rest
		return Name
	end
end


--------------------------------------------------------
----         Find the mains char name               ----
--------------------------------------------------------
function Floot:GetAccountName(Name)
	for i=1, GetNumGuildMembers(true), 1 do 
		local RosterName, _, _, _, _, _, Note = GetGuildRosterInfo(i)
		if (RosterName == Name) then -- We hold the requested character
			if ( string.upper(string.sub(Note, 1, 6)) == "ALT - " ) then
				-- This was an alt return the mains name
				return string.upper(string.sub(Note, 7, 7)) .. string.lower(string.sub(Note, 8))
			else
				-- This is a main return the original name
				return string.upper(string.sub(RosterName, 1, 1)) .. string.lower(string.sub(RosterName, 2))
			end
		end
	end
	return Name
end

--------------------------------------------------------
----           Create the main to alt link          ----
--------------------------------------------------------
-- This should be called when a new name is used eg. Incoming roll, or reasign, to make sure the main and alt is linked.
function Floot:CreateAccounts(Name)
	for gi=1, GetNumGuildMembers(true), 1 do 
		local RosterName, _, _, _, _, _, Note = GetGuildRosterInfo(gi)
		if (RosterName == Name) then -- We hold the requested character
			if ( string.upper(string.sub(Note, 1, 6)) == "ALT - " ) then
				-- This was an alt return the mains name
				FlootAccounts[Name] = string.upper(string.sub(Note, 7, 7)) .. string.lower(string.sub(Note, 8))
			end
		end
	end
end

--------------------------------------------------------
----           Create the main to alt link          ----
----              Does the entire guild             ----
--------------------------------------------------------
function Floot:CreateAllAccounts()
	for GuildIndex=1, GetNumGuildMembers(true), 1 do
		local RosterName, _, _, _, _, _, Note = GetGuildRosterInfo(GuildIndex)
		if ( string.upper(string.sub(Note, 1, 6)) == "ALT - " ) then
			-- We have an alt find Main's name
			local SplitNote = {}
			for Peice in string.gmatch(Note, "[^ ]+") do
				table.insert(SplitNote, Peice)
			end
			local Mainname = SplitNote[3]
			for GuildCheck=1, GetNumGuildMembers(true), 1 do
				local CheckName, _, _, _, _, _, Note = GetGuildRosterInfo(GuildCheck)
				if (Mainname == CheckName) then -- Only insert if the main is in the guild
					FlootAccounts[RosterName] = Mainname
				end
			end
		end
	end
end	

--------------------------------------------------------
----        Get Main account from alt name          ----
--------------------------------------------------------
function Floot:GetMainName(Name)
	for Alt, Main in pairs(FlootAccounts) do
		if ( Alt == Name ) then
			-- Found the alt return the name
			return Main
		end
	end
	-- Did not find an alt, so this must be a main return the name.
	return Name
end


--------------------------------------------------------
----  Send a request for sync of winner list,       ----
----  Nuker and Mode                                ----
--------------------------------------------------------
function Floot:SendRequestForMLChange(Input, TmpName)
	FlootRuntime["InSync"] = false	-- If we manually ask for a full sync, we are not in sync.
	local Frame = FlootFrames:GetFrame("FlootFrame")
	if (Frame:IsVisible() ) then
		Floot:Print("Can't sync while looting")
	end

	if (Input) then
		local Word = Floot:Split(" ", Input)
		TmpName = Word[2]
	end

	if (TmpName) then
		local Name = Floot:FormatName(TmpName)

		for i=1, GetNumGroupMembers() do
			local RosterName = GetRaidRosterInfo(i)
			if (Name == RosterName) then
				FlootCom:SendMessage("WHISPER","RequestForMLChange",Name,"Transfer")
				Floot:Print("Requested sync from " .. Name)
				return
			end
		end
	else
		Floot:Print("Did you specify a name ? I did not find a name, so request denied!")
		return
	end

	Floot:Print("Are you and the one your trying to sync from in the same raid group? I could not find him")
end

-------------------------------------------------------
----     Pack full sync info to be transmitted     ----
-------------------------------------------------------
function Floot:PackFullSyncData()
	local Transmit = {}
	Transmit["MainWinnerList"] = FlootMainWinnerList
	Transmit["OffWinnerList"] = FlootOffWinnerList
	Transmit["FlootTier15MainSpec"] = FlootTier15MainSpec
	Transmit["FlootTier15OffSpec"] = FlootTier15OffSpec
	Transmit["FlootTier15HeroicMainSpec"] = FlootTier15HeroicMainSpec
	Transmit["FlootTier15HeroicOffSpec"] = FlootTier15HeroicOffSpec
	Transmit["FlootTier14MainSpec"] = FlootTier14MainSpec
	Transmit["FlootTier14OffSpec"] = FlootTier14OffSpec
	Transmit["FlootTier14HeroicMainSpec"] = FlootTier14HeroicMainSpec
	Transmit["FlootTier14HeroicOffSpec"] = FlootTier14HeroicOffSpec
	Transmit["WinnerListResetDate"] = Floot_ConfigDb["WinnerListResetDate"]
	Transmit["FlootAwardedItems"] = FlootAwardedItems
	Transmit["FlootRaidRoster"] = FlootRaidRoster
	Transmit["OfficialMode"] = Floot_ConfigDb["OfficialMode"]
	Transmit["RaiderRanks"] = Floot_ConfigDb["RaiderRanks"]
	Transmit["Nuker"] = FlootRuntime["Nuker"]
	return Transmit
end


-------------------------------------------------------
----   Unpack full sync info to be transmitted     ----
-------------------------------------------------------
function Floot:UnPackFullSyncData(Message)

	FlootMainWinnerList = Message["MainWinnerList"]
	FlootOffWinnerList = Message["OffWinnerList"]
	FlootTier15MainSpec = Message["FlootTier15MainSpec"]
	FlootTier15OffSpec = Message["FlootTier15OffSpec"]
	FlootTier15HeroicMainSpec = Message["FlootTier15HeroicMainSpec"]
	FlootTier15HeroicOffSpec = Message["FlootTier15HeroicOffSpec"]
	FlootTier14MainSpec = Message["FlootTier14MainSpec"]
	FlootTier14OffSpec = Message["FlootTier14OffSpec"]
	FlootTier14HeroicMainSpec = Message["FlootTier14HeroicMainSpec"]
	FlootTier14HeroicOffSpec = Message["FlootTier14HeroicOffSpec"]
	Floot_ConfigDb["WinnerListResetDate"] = Message["WinnerListResetDate"]
	FlootAwardedItems = Message["FlootAwardedItems"]
	FlootRaidRoster = Message["FlootRaidRoster"]
	Floot_ConfigDb["OfficialMode"] = Message["OfficialMode"]
	Floot_ConfigDb["Enabled"] = true
	Floot_ConfigDb["RaiderRanks"] = Message["RaiderRanks"]
	FlootRuntime["Nuker"] = Message["Nuker"]
	
	local Mode
	if (Floot_ConfigDb["OfficialMode"]) then
		Mode = "Official"
	else
		Mode = "Unofficial"
	end
	FlootFrames:UpdateStatusFrame()
	Floot:Print("Addon mode is now: " .. Mode)
end

--------------------------------------------------------
----  		Manual request for a full sync 		    ----
--------------------------------------------------------
function Floot:RequestForMLChange(Message,Sender)
	local Transmit = Floot:PackFullSyncData()
	Floot:Print("Responding to a sync request from " .. Sender)
	FlootCom:SendMessage("WHISPER","UpdateMLChange",Sender,Transmit)

end

--------------------------------------------------------
----         We recived a full sync reply           ----
--------------------------------------------------------
function Floot:UpdateMLChange(Message,Sender)

	if (FlootRuntime["InSync"] == false ) then
		FlootRuntime["InSync"] = true
		Floot:UnPackFullSyncData(Message)
		FlootFrames:UpdateStatusFrame()
		Floot:Debug("BroadcastUpdate", "Recieved full sync from " .. Sender)
		Floot:Print("Sync complete")
--		if (not FlootRuntime["Nuker"]) then
--			Floot:SetRaidNuker()
--		end
	end
end

--------------------------------------------------------
----        Broadcast a WinnerList update           ----
--------------------------------------------------------
function Floot:BroadcastWinnerList()
	local Transmit = {}
	Transmit["MainWinnerList"] = FlootMainWinnerList
	Transmit["OffWinnerList"] = FlootOffWinnerList
	Transmit["FlootTier15MainSpec"] = FlootTier15MainSpec
	Transmit["FlootTier15OffSpec"] = FlootTier15OffSpec
	Transmit["FlootTier15HeroicMainSpec"] = FlootTier15HeroicMainSpec
	Transmit["FlootTier15HeroicOffSpec"] = FlootTier15HeroicOffSpec
	Transmit["FlootTier14MainSpec"] = FlootTier14MainSpec
	Transmit["FlootTier14OffSpec"] = FlootTier14OffSpec
	Transmit["FlootTier14HeroicMainSpec"] = FlootTier14HeroicMainSpec
	Transmit["FlootTier14HeroicOffSpec"] = FlootTier14HeroicOffSpec

	FlootCom:SendMessage("RAID", "IncBroadcastWinnerList", "Broadcast", Transmit)
	Floot:Debug("BroadcastUpdate", "Sending Raid Broadcast with updated WinnerLists")
	
end

--------------------------------------------------------
----    Update Winnerlist with recieved broadcast   ----
--------------------------------------------------------
function Floot:IncBroadcastWinnerList(Message,Sender)

	FlootMainWinnerList = Message["MainWinnerList"]
	FlootOffWinnerList = Message["OffWinnerList"]
	FlootTier15MainSpec = Message["FlootTier15MainSpec"]
	FlootTier15OffSpec = Message["FlootTier15OffSpec"]
	FlootTier15HeroicMainSpec = Message["FlootTier15HeroicMainSpec"]
	FlootTier15HeroicOffSpec = Message["FlootTier15HeroicOffSpec"]
	FlootTier14MainSpec = Message["FlootTier14MainSpec"]
	FlootTier14OffSpec = Message["FlootTier14OffSpec"]
	FlootTier14HeroicMainSpec = Message["FlootTier14HeroicMainSpec"]
	FlootTier14HeroicOffSpec = Message["FlootTier14HeroicOffSpec"]
	Floot:Debug("BroadcastUpdate", "Recieved Raid Broadcast with updated WinnerList")
end

--------------------------------------------------------
----       Send FlootAwardedItems as broadcast      ----
--------------------------------------------------------
function Floot:BroadcastSyncFlootAwardedItems()
	local Transmit = {}
	Transmit["FlootAwardedItems"] = FlootAwardedItems
	Transmit["Bosses"] = FlootRaidRoster["Bosses"]
	FlootCom:SendMessage("RAID", "IncSyncFlootAwardedItems", "Broadcast", Transmit)
	FlootRuntime.SyncAwarded = false
	Floot:Debug("BroadcastUpdate", "Sending Raid Broadcast with FlootAwardedItems")
end

--------------------------------------------------------
----    Recieve FlootAwardedItems as broadcast        ----
--------------------------------------------------------
function Floot:IncSyncFlootAwardedItems(Message, Sender)

	FlootAwardedItems = Message["FlootAwardedItems"]
	FlootRaidRoster["Bosses"] = Message["Bosses"]

	FlootRuntime["FoundItems"] = {
		[999] = "None",
	}
	FlootRuntime["FoundItemId"] = 999
	FlootRuntime["PlayerNameITemLookup"] = nil
	FlootRuntime["FoundItemRollers"] = {
		[999] = "None",
	}
	FlootRuntime["ChosenItemRoller"] = "None"
	FlootRuntime["PlayerNameItemLookup"] = nil
	FlootRuntime["MoveRollType"] = false
	Floot:CreateItemOwnersList()
	Floot:Debug("BroadcastUpdate", "Recieved Raid Broadcast with FlootAwardedItems")
end

--------------------------------------------------------
----           Broadcast RaiderRanks                ----
--------------------------------------------------------
function Floot:BroadcastRaiderRanks()
	FlootCom:SendMessage("RAID", "IncRaiderRanks", "Broadcast", Floot_ConfigDb["RaiderRanks"])
	Floot:Debug("BroadcastUpdate", "Sending RaiderRanks")
end

--------------------------------------------------------
----           Recieving RaiderRanks                ----
--------------------------------------------------------
function Floot:IncRaiderRanks(Message,Sender)
	Floot_ConfigDb["RaiderRanks"] = Message
	Floot:Print("Raider Rank was updated by " .. Sender)
end

--------------------------------------------------------
----    Broadcast Start collecting FlootRosterInfo    ----
--------------------------------------------------------
function Floot:BroadcastStartFlootRaidRosterGathering()
	-- Setup has been triggered RL broadcast to inform addons to gather data
	local Transmit = Floot:PackFullSyncData()
	FlootCom:SendMessage("RAID", "IncStartFlootRaidRosterGathering", "Broadcast", Transmit)
	Floot:Debug("BroadcastUpdate", "Sending Start Gathering FlootRaidRoster data")
end

--------------------------------------------------------
----    Incoming start collecting FlootRosterInfo     ----
--------------------------------------------------------
function Floot:IncStartFlootRaidRosterGathering(Message, Sender)
	-- Recieved Data to start the raid Roster Data collection
	if ( FlootRuntime["InSync"] == false ) then
		FlootRuntime["InSync"] = true
		Floot:UnPackFullSyncData(Message)
		Floot:Print("This addons Data is now in sync")
		Floot:Debug("BroadcastUpdate", "Recieved Start Gathering FlootRaidRoster data")
	end
end


--------------------------------------------------------
----   Broadcast should I gather FlootRosterInfo     ----
--------------------------------------------------------
function Floot:BroadcastAreWeGatheringFlootRaidRoster()
	-- Just joined raid asking if I should gather data
	FlootCom:SendMessage("RAID", "IncAreWeGatheringFlootRaidRoster", "Broadcast", "NewInRaid")
	Floot:Debug("BroadcastUpdate", "Broadcasting Should I store FlootRaidRoster data")
end

---------------------------------------------------------
----  Recieved should I gather FlootRosterInfo request ----
---------------------------------------------------------
function Floot:IncAreWeGatheringFlootRaidRoster(Message, Sender)
	-- If Master Looter, then send data to the new player in the raid. 
	Floot:Debug("BroadcastUpdate", "Recieved Should I store FlootRaidRoster data question from" .. Sender)

	if ( FlootRuntime["InSync"] == true ) then
		Floot:Debug("BroadcastUpdate", "Sending responce to Broadcast Are We Gahtering FlootRaidRoster")
		Floot:RequestForMLChange(Message,Sender)  -- Make sure new players with addon gets a full update
	end
end


---------------------------------------------------------
----          Broadcast New raid location            ----
---------------------------------------------------------
function Floot:BroadcastNewLocation()
	FlootCom:SendMessage("RAID", "IncNewLocation", "Broadcast", FlootRaidRoster["Location"])
	Floot:Debug("BroadcastUpdate", "Broadcasting New FlootRaidRoster Location")
end

---------------------------------------------------------
----          Incoming New raid location            ----
---------------------------------------------------------
function Floot:IncNewLocation(Message, Sender)
	FlootRaidRoster["Location"] = Message
end

---------------------------------------------------------
----        Broadcast Start Com Debugging            ----
---------------------------------------------------------
function Floot:BroadcastStarStopComDebug()
	if (FlootRuntime["Debug"]["DebuggerName"]) then
		FlootCom:SendMessage("RAID", "IncStopComDebug", "Broadcast")
		FlootRuntime["Debug"]["DebuggerName"] = nil
		Floot:Print("Communication debug disabled")
	else
		FlootCom:SendMessage("RAID", "IncStartComDebug", "Broadcast")
		FlootRuntime["Debug"]["DebuggerName"] = UnitName("player")
		Floot:Print("Communication debug enabled")
		Floot:Print(RED_FONT_COLOR_CODE .. "WARNING: " .. FONT_COLOR_CODE_CLOSE .. "This doubles the amount of data transmitted")
	end
end


---------------------------------------------------------
----             Inc Start Com Debugging             ----
---------------------------------------------------------
function Floot:IncStartComDebug(Message, Sender)
	FlootRuntime["Debug"]["DebuggerName"] = Sender
	Floot:Print(Sender .. " enabled communication debugging")
end

---------------------------------------------------------
----          Incoming New raid location            ----
---------------------------------------------------------
function Floot:IncStopComDebug(Message, Sender)
	FlootRuntime["Debug"]["DebuggerName"] = nil
	Floot:Print(Sender .. " disabled communication debugging")
end


---------------------------------------------------------
----      Request Raid setup info from player        ----
---------------------------------------------------------
function Floot:RequestRaidSetupInfo(Name)
	if (Name) then
		FlootCom:SendMessage("WHISPER", "IncGetRaidSetupInfo", Floot:FormatName(Name), "GiveInfo")
	else
		Floot:Print("No name found")
	end
end


---------------------------------------------------------
----   Incoming Request Raid setup info from player  ----
---------------------------------------------------------
function Floot:IncGetRaidSetupInfo(Message,Sender)
	local Transmit = {}
	Transmit["InSync"] = FlootRuntime["InSync"]
	Transmit["MasterLooter"] = Floot_ConfigDb["MasterLooter"]
	Transmit["RaidLootQuality"] = Floot_ConfigDb["RaidLootQuality"]
	Transmit["RaidDifficulty"] = Floot_ConfigDb["RaidDifficulty"]
	Transmit["RaidDifficultyAI"] = Floot_ConfigDb["RaidDifficultyAI"]
	Transmit["RaidDiffucltyHeroic"] = Floot_ConfigDb["RaidDiffucltyHeroic"]
--	Transmit["KnownNukers"] = Floot_ConfigDb["KnownNukers"]
	if (FlootRuntime["Nuker"]) then
		Transmit["Nuker"] = FlootRuntime["Nuker"]
	end
	
	FlootCom:SendMessage("WHISPER", "GetRaidSetupInfoReply", Sender, Transmit)
end


---------------------------------------------------------
----   Incoming Reply Raid setup info from player    ----
---------------------------------------------------------
function Floot:GetRaidSetupInfoReply(Message,Sender)
	if (Message["InSync"] == true ) then
		Floot:Print("|cff2459ff" .. Sender .. FONT_COLOR_CODE_CLOSE .. " is in sync ")
	elseif (Message["InSync"] == false ) then
		Floot:Print("|cff2459ff" .. Sender .. FONT_COLOR_CODE_CLOSE .. " is out of sync")
	end

	if (Message["MasterLooter"]) then
		Floot:Print("|cff2459ffMasterLooter: " .. FONT_COLOR_CODE_CLOSE .. Message["MasterLooter"])
	end

	if (Message["RaidDifficultyAI"] and Message["RaidDifficultyAI"] == true) then
		Floot:Print("|cff2459ffRaid Difficulty AI is" .. FONT_COLOR_CODE_CLOSE .. " on")
	elseif (Message["RaidDifficultyAI"] and Message["RaidDifficultyAI"] == false) then
		Floot:Print("|cff2459ffRaid Difficulty AI is" .. FONT_COLOR_CODE_CLOSE .. " off")
	end

	if ( Message["RaidDiffucltyHeroic"] == true) then
		Floot:Print("|cff2459ffRaid is forced to" .. FONT_COLOR_CODE_CLOSE .. " heroic")
	else
		Floot:Print("|cff2459ffRaid is forced to" .. FONT_COLOR_CODE_CLOSE .. " normal")
	end

	if (Message["RaidDifficulty"]) then
		local Values = {
			[3] = "Normal 10",
			[5] = "Heroic 10",
			[4] = "Normal 25",
			[6] = "Heroic 25",
		}
		Floot:Print("|cff2459ffForced raid type set to: " .. FONT_COLOR_CODE_CLOSE .. Values[Message.RaidDifficulty])
	end

	if (Message["RaidLootQuality"]) then
		Floot:Print("|cff2459ffRaid Loot Quality is: " .. FONT_COLOR_CODE_CLOSE .. Message["RaidLootQuality"])
	end

	if (Message["Nuker"] ) then
		Floot:Print("|cff2459ffNuker set to: " .. FONT_COLOR_CODE_CLOSE .. Message["Nuker"])
	else
		Floot:Print("|cff2459ffNuker set to: " .. FONT_COLOR_CODE_CLOSE .. "None");
	end

--	Floot:Print("KnownNukers")
--	for Name, Value in pairs(Message["KnownNukers"]) do
--		Floot:Print(Name)
--	end

end

---------------------------------------------------------
----               Send ClearAllData                 ----
---------------------------------------------------------
function Floot:SendClearAllData()
	Floot:Debug("BroadcastUpdate", "Sending Clear All Data")
	FlootCom:SendMessage("RAID", "IncClearAllData", "Broadcast", "Force")
	-- Do it for this addon.
	Floot:IncClearAllData("Force", UnitName("player"))

end

---------------------------------------------------------
----            Recieve  ClearAllData                ----
---------------------------------------------------------
function Floot:IncClearAllData(Force, Sender)
	Floot:Debug("BroadcastUpdate", "Recieved Clear All Data")
	Floot:ClearWinnerList(Force)
	FlootTier15MainSpec = {}
	FlootTier15OffSpec = {}
	FlootTier15HeroicMainSpec = {}
	FlootTier15HeroicOffSpec = {}
	FlootTier14MainSpec = {}
	FlootTier14OffSpec = {}
	FlootTier14HeroicMainSpec = {}
	FlootTier14HeroicOffSpec = {}
	Floot:Print(Sender .. " forced the addon to clear all raid data")
end

---------------------------------------------------------
----        Broadcast start Sharing nukers           ----
---------------------------------------------------------
-- function Floot:BroadcastShareNukers()
--	Floot:Debug("BroadcastUpdate", "Sending StartShareNukers")
--	FlootCom:SendMessage("RAID", "IncShareNukers", "Broadcast", "update")
--	Floot:IncShareNukers("Fo", UnitName("player"))
--end

---------------------------------------------------------
----            Incoming Share Nukers                ----
---------------------------------------------------------
--function Floot:IncShareNukers(Message, Sender)
--	Transmit = {}
--	Transmit["RaidNukers"] = Floot_ConfigDb["KnownNukers"]
--	Floot:Debug("BroadcastUpdate", "Sending my nukers")
--	FlootCom:SendMessage("RAID", "IncNukerList", "Broadcast", Transmit)
--end

---------------------------------------------------------
----              Incoming Nuker list                ----
---------------------------------------------------------
--function Floot:IncNukerList(Message, Sender)
--	for Rkey, Rvalue in pairs(Message["RaidNukers"]) do
--		local Found = nil
--		for Lkey, Lvalue in pairs(Floot_ConfigDb["KnownNukers"]) do
--			if (Lkey == Rkey) then
--				Found = true
--			end
--		end
--		if (not Found) then
--			if (not Floot_ConfigDb["BannedNukers"][Rkey]) then
--				Floot_ConfigDb["KnownNukers"][Rkey] = Rkey
--			end
--		end
--	end
--end

--------------------------------------------------------
---- Requires LibRockConsole in order to work.      ----
---- Prints arrays / hashes / frames.               ----
--------------------------------------------------------
function Floot:DumpFrame(Array)
   Rock("LibRockConsole-1.0"):PrintLiteral(Array)
end

--------------------------------------------------------
--- Same as LibRockConsole, but sometimes LibRock    ---
--- can't print a frame or array, and sometimes      ---
--- this one can't. So both are needed               ---
--------------------------------------------------------
function Floot:DumpArray(Array,Ignore)
	
	local Printed = false
	if (not IsAddOnLoaded("Spew")) then
		Floot:Print("Warning: Spew is not loaded trying DevTools")
	elseif (IsAddOnLoaded("Spew") and not Ignore) then
		Spew("",Array)
		Printed = true
	end

	if (Printed == false) then
		if (not IsAddOnLoaded("DevTools")) then
	  		Floot:Print("Warning: DevTools is not installed, giving up")
		else
			DevTools_Dump(Array)
		end
   end
end

--------------------------------------------------------
----   Does the same as the perl Split function     ----
--------------------------------------------------------
function Floot:Split(Delimiter, Text)
     local list = {}
  local pos = 1
  if strfind("", Delimiter, 1) then -- this would result in endless loops
    error("delimiter matches empty string!")
  end
  while 1 do
    local first, last = strfind(Text, Delimiter, pos)
    if first then -- found?
      tinsert(list, strsub(Text, pos, first-1))
      pos = last+1
    else
      tinsert(list, strsub(Text, pos))
      break
    end
  end
  return list
end

--------------------------------------------------------
----           Color Text by using HEX              ----
----           Used inline in the text              ----
--------------------------------------------------------
function Floot:GetTextColor(Type,Data)
   local ClassColors = {
	  ["DEATH KNIGHT"] = "|cffc41f3b",
	  ["DRUID"] = "|cffff7d0a",
	  ["HUNTER"] = "|cffabd473",
	  ["MAGE"] = "|cff69ccf0",
	  ["PALADIN"] = "|cfff58cba",
	  ["PRIEST"] = "|cffffffff",
	  ["ROGUE"] = "|cfffff569",
	  ["SHAMAN"] = "|cff2459ff",
	  ["WARLOCK"] = "|cff9482c9",
	  ["WARRIOR"] = "|cffc79c6e",
	  ["MONK"] = "|cff66ffcc",
   }

   if (Type == "Name") then
	  for i=1,GetNumGroupMembers() do
		 local RosterName, _, _, _, Class, _, _, _, _, _, _ = GetRaidRosterInfo(i)
		 if (Data == RosterName) then
			local Class = string.upper(Class)
			return ClassColors[Class]
		 end
	  end
   elseif (Type == "Class") then
	  local Class = string.upper(Data)
	  return ClassColors[Class]
   end
   return RED_FONT_COLOR_CODE
end

--------------------------------------------------------
----       Toggle Raid Difficutlty AI on/off        ----
--------------------------------------------------------
function Floot:ToggleRaidDifficultyAI()
	if (Floot_ConfigDb["RaidDifficultyAI"]) then
		Floot_ConfigDb["RaidDifficultyAI"] = false
	else
		Floot_ConfigDb["RaidDifficultyAI"] = true
	end
end

--------------------------------------------------------
----  Toggle different types of debug on off        ----
--------------------------------------------------------
function Floot:ToggleDebug(Type)
	if (Type == "WinnerList") then
		if (FlootRuntime["Debug"]["WinnerList"]) then
			FlootRuntime["Debug"]["WinnerList"] = nil
			Floot:Print("Debug WinnerList disabled")
		else
			FlootRuntime["Debug"]["WinnerList"] = 1
			Floot:Print("Debug WinnerList enabled")
		end

	elseif (Type == "MasterLoot") then
		if (FlootRuntime["Debug"]["MasterLoot"]) then
			FlootRuntime["Debug"]["MasterLoot"] = nil
			Floot:Print("Debug MasterLoot disabled")
		else
			FlootRuntime["Debug"]["MasterLoot"] = 1
			Floot:Print("Debug MasterLoot enabled")
		end

	elseif (Type == "BroadcastUpdate" ) then
		if ( FlootRuntime["Debug"]["BroadcastUpdate"] ) then
			FlootRuntime["Debug"]["BroadcastUpdate"] = nil
			Floot:Print("Broadcast update debug disabled")
		else
			FlootRuntime["Debug"]["BroadcastUpdate"] = 1
			Floot:Print("Broadcast update debug enabled")
		end
		
	elseif (Type == "VersionCheck") then
		if ( FlootRuntime["Debug"]["VersionCheck"] ) then
			FlootRuntime["Debug"]["VersionCheck"] = nil
			Floot:Print("Version check is disabled")
		else
			FlootRuntime["Debug"]["VersionCheck"] = 1
			Floot:Print("Version check is enabled")
		end
	elseif (Type == "DebugData" ) then
		if ( FlootRuntime["Debug"]["DebugData"] ) then
			FlootRuntime["Debug"]["DebugData"] = nil
			Floot:Print("Com data debug disabled")
		else
			FlootRuntime["Debug"]["DebugData"] = 1
			Floot:Print("Com data debug enabled")
		end
	elseif (Type == "BypassRaid") then
		if (FlootRuntime["Debug"]["BypassRaid"] ) then
			FlootRuntime["Debug"]["BypassRaid"] = nil
			Floot:Print("BypassRaid Disabled")
		else 
			FlootRuntime["Debug"]["BypassRaid"] = 1
			Floot:Print("BypassRaid Enabled")
		end
	end
end

--------------------------------------------------------
----          Dump the WinnerList to chat           ----
--------------------------------------------------------
function Floot:DumpWinnerList()
	Floot:Print("MainSpec list")
	Floot:DumpArray(FlootMainWinnerList)
	Floot:Print("OffSpec list")
	Floot:DumpArray(FlootOffWinnerList)
	Floot:Print("FlootTier15MainSpec")
	Floot:DumpArray(FlootTier15MainSpec)
	Floot:Print("FlootTier15OffSpec")
	Floot:DumpArray(FlootTier15OffSpec)
	Floot:Print("FlootTier15HeroicMainSpec")
	Floot:DumpArray(FlootTier15HeroicMainSpec)
	Floot:Print("FlootTier15HeroicOffSpec")
	Floot:DumpArray(FlootTier15HeroicOffSpec)
	Floot:Print("FlootTier14MainSpec")
	Floot:DumpArray(FlootTier14MainSpec)
	Floot:Print("FlootTier14OffSpec")
	Floot:DumpArray(FlootTier14OffSpec)
	Floot:Print("FlootTier14HeroicMainSpec")
	Floot:DumpArray(FlootTier14HeroicMainSpec)
	Floot:Print("FlootTier14HeroicOffSpec")
	Floot:DumpArray(FlootTier14HeroicOffSpec)
end


--------------------------------------------------------
----     Dump the FlootAwardedItems to chat         ----
--------------------------------------------------------
function Floot:DumpFlootAwardedItems()
	Floot:Print("FlootAwardedItems")
	Floot:DumpArray(FlootAwardedItems)
end

--------------------------------------------------------
----     Dump the FlootAwardedItems to chat         ----
--------------------------------------------------------
function Floot:DumpRuntime()
	Floot:Print("FlootRuntime")
	Floot:DumpArray(FlootRuntime)
end

--------------------------------------------------------
----   Will print debug if that type is enabled     ----
--------------------------------------------------------
function Floot:Debug(MyType, Data)
	if ( MyType == "WinnerList" and FlootRuntime["Debug"]["WinnerList"] ) then
		if ( type(Data) == "table" ) then
			Floot:Print("|cfffff569" ..  "WL: table")
			Floot:DumpArray(Data)
		else
			Floot:Print("|cfffff569" ..  "WL: " .. Data)
		end

	elseif ( MyType == "MasterLoot" and FlootRuntime["Debug"]["MasterLoot"] ) then
		if ( type(Data) == "table" ) then
			Floot:Print("|cfffff569" ..  "ML: table")
			Floot:DumpArray(Data)
		else
			Floot:Print("|cfffff569" ..  "ML: " .. Data)
		end

	elseif ( MyType == "BroadcastUpdate" and FlootRuntime["Debug"]["BroadcastUpdate"] ) then
		if ( type(Data) == "table" ) then
			Floot:Print("|cfffff569" ..  "LBU: table")
			Floot:DumpArray(Data)
		else
			Floot:Print("|cfffff569" ..  "LBU: " .. Data)
		end

	elseif ( MyType == "VersionCheck" and FlootRuntime["Debug"]["VersionCheck"] ) then
		if ( type(Data) == "table" ) then
			Floot:Print("|cfffff569" ..  "VC: table")
			Floot:DumpArray(Data)
		else
			Floot:Print("|cfffff569" ..  "VC: " .. Data)
		end
	elseif ( MyType == "Com" and FlootRuntime["Debug"]["DebuggerName"] ) then
		if ( type(Data) == "table" ) then
			Floot:Print("|cfffff569" ..  "VC: table")
			Floot:DumpArray(Data, true)
		else
			Floot:Print("|cfffff569" ..  "VC: " .. Data)
		end

	end
end


