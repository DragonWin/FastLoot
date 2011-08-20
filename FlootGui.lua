local Floot = LibStub("AceAddon-3.0"):GetAddon("Floot")

local FlootGui = {}



function Floot:NewFlootGui()
	return FlootGui
end

function FlootGui:CreateGui()
	local ConfigOpts = {
		name = "Floot",
		childGroups = "tab",
		type = "group",
		args = {
			desc = {
				order = 1,
				type = "description",
				name = function() return FlootGui:GetDescription("Desc") end,
			},
			general = {
				order = 2,
				name = "General settings",
				desc = "Commenly used settings",
				type = "group",
				cmdHidden = true,
				args = {
					toggle = {
						order = 2,
						name = "Enable the addon",
						desc = "Toggles the addon on/off",
						type = "toggle",
						set = function() Floot:EnableDisable() end,
						get = function() return Floot_ConfigDb["Enabled"] end,
						cmdHidden = true,
					},
					mode = {
						order = 3,
						name = "Official Mode",
						desc = "Toggles between offical and non-official raids. In unofficial mode, all rollers are considered raiders, and raid data will be rejected by the website.",
						type = "toggle",
						set = function() Floot:ChangeMode() end,
						get = function() return Floot_ConfigDb["OfficialMode"] end,
					},
					nuker = {
						order = 4,
						name = "Nuker",
						desc = "Target the nuker and type /floot nuker, or use the GUI and just type the name",
						type = "input",
						set = function(self, Name) Floot:SetNuker(self.input, Name) end,
						get = function() return FlootRuntime["Nuker"] end,
						cmdHidden = true,
					},
					sync = {
						order = 6,
						name = "Sync",
						desc = "Request winner list, Nuker, and mode from another player",
						type = "input",
						set = function(self,Name) Floot:SendRequestForMLChange(self.input, Name) end,
						get = function() return "Player Name" end,
						guiHidden = true,
					},
					setup = {
						order = 7,
						name = "Setup the raid",
						desc = "Setup the raid based on the settings from \"Raid Settings\"",
						type = "execute",
						func = function()
							FlootRuntime["LocalSetupButtonPressed"] = true
							FlootFrames:PopulateMLChoiseFrame()
						end,
						confirm = true,
						confirmText = "Remember to check the raid mode (Official / Unofficial) before you press Accept\n\n Unofficial raids will not be accepted by the website",
						disabled = function() 
							if ( FlootRuntime["Debug"]["BypassRaid"] ) then
								return false
							elseif ( FlootRuntime["InSync"] == true or FlootRuntime["IsInRaid"] == nil ) then
								return true
							else 
								return false 
							end 
						end,
					},
					resetsession = {
						order = 8,
						name = "Reset Raid Session",
						desc = "This will clear awarded items, and other raid session related data. Only use this if you really want to lose the existing raid and start a new raid.",
						type = "execute",
						func = function() Floot:SendClearRaidSession() end,
						confirm = true,
						confirmText = "Are you really sure you want to lose your current raid?",
						disabled = function() if (FlootRuntime["InSync"] == true) then return false else return true end end,
					},
					versiongroup = {
						type = "group",
						name = "\n \n",
						guiInline = true,
						order = 9,
						args = {
							versionheader = {
								order = 1,
								name = "Version info",
								type = "header",
								width = "half",
								cmdHidden = true,
							},
							versiondescription = {
								order = 2,
								type = "description",
								name = function() return FlootRuntime["AddonVersions"] end,
								cmdHidden = true,
							},
						},
					},
				},
			},
			move = {
				name = "Manipulate an item",
				type = "group",
				desc = "Check what items a player has won, or Move an item from playerA to playerB",
				order = 5,
				cmdHidden = true,
				args = {
					LookupItem = {
						order = 1,
						name = "Lookup items a player has won",
						desc = "Select the player who is to have an item moved to another",
						type = "select",
						set = function(Input, PlayerName) FlootRuntime.FoundItemId = 999 Floot:FindItemByPlayer(Input.info, PlayerName)  end,
						get = function()  if (FlootRuntime.PlayerNameItemLookup) then return FlootRuntime.PlayerNameItemLookup else return "None" end end,
						values = function() return Floot:CreateItemOwnersList() end,
						cmdHidden = true,
					},
					selectItem = {
						order = 3,
						name = "Select Item",
						desc = "Select the item to transfer",
						type = "select",
						set = function(self, FoundItemId) FlootRuntime["MoveRollType"] = false Floot:CreateLookupRollersByItemID(FoundItemId) end,
						get = function() if (FlootRuntime["FoundItemId"] ~= 999 ) then return FlootRuntime.FoundItemId else return 999 end end,
						values = function() return FlootRuntime["FoundItems"] end,
						cmdHidden = true,
						width = "full",
					},
					movedescription4 = {
						order = 4,
						name = "\n ",
						type = "description",
					},
					movedescription2 = {
						order = 5,
						name = "Manipulate the selected item",
						type = "header",
					},
					enablenonrollers = {
						order = 6,
						name = "Show all in raid",
						desc = "Show all players in the raid. This includes those that did roll and those who did not roll",
						type = "toggle",
						get = function() return FlootRuntime.ShowNonRollers end,
						set = function(Input, Value) FlootRuntime.ShowNonRollers = Value end,
						cmdHidden = true,
						disabled = function() if (FlootRuntime.FoundItemId == 999) then return true else return false end end,
					},
					deleteitem = {
						order = 10,
						name = "Delete item",
						desc = "Delete the selected item",
						type = "execute",
						func = function() Floot:DeleteItem() end,
						confirm = true,
						confirmText = "Really delete item?",
						disabled = function() if (FlootRuntime.FoundItemId == 999) then return true else return false end end,
						guiHidden = true,
					},
					movedescription3 = {
						order = 8,
						name = " ",
						type = "description",
					},
					givetoplayer = {
						order = 9,
						name = "Select a player to transfer to",
							desc = "Transfer the choosen item to this player.\n\n" .. RED_FONT_COLOR_CODE .. "Red is the person whom have the item\n\n" .. GREEN_FONT_COLOR_CODE .. "Green are those who rolled and lost on that item, or passed on it after rolling\n\n" .. FONT_COLOR_CODE_CLOSE .. "White are those who did not roll, but are shown because \"Show all in raid\" is marked",
						type = "select",
						set = function(self, ChosenItemRoller) Floot:MoveItem(ChosenItemRoller) end,	
						get = function() if ( FlootRuntime["ChosenItemRoller"] ~= 999) then return FlootRuntime.ChosenItemRoller else return 999 end end,
						values = function() return Floot:CreateLookupRollersByItemID(FlootRuntime.FoundItemId) end,
						cmdHidden = true,
						disabled = function() if (FlootRuntime.FoundItemId == 999) then return true else return false end end,
						confirm = true,
						confirmText = "Really move the item ?",
					},
					changerolltype = {
						order = 7,
						name = function() return Floot:GetMoveRollType() end,
						desc = "Change the roll type from existing type to the displayed type when transfering the item. NOTE If you just want to change the roll type for the current winner, tick this and transfer it to the same player.",
						type = "toggle",
						get = function() return FlootRuntime.MoveRollType end,
						set = function(Input, Value) FlootRuntime.MoveRollType = Value end,
						cmdHidden = true,
						disabled = function() if (FlootRuntime.FoundItemId == 999) then return true else return false end end,
					},
				},
			},
			RaidSettings = {
				name = "Raid Settings",
				type = "group",
				desc = "Default Raid settings, used with /floot setup",
				order = 6,
				cmdHidden = true,
				args = {
					setupexplain = {
						order = 1,
						type = "description",
						name = "None of these settings will have any effect until you press the setup button under General settings. This is remembered from raid to raid, so if the master looter is not the same person as on the last raid you need to change the name here\n\n",
					},
					RaidLeaderGroup = {
						type = "group",
						name = "Raid Leader's Setup",
						guiInline = true,
						order = 2,
						args = {
							MasterLooter = {
								order = 1,
								name = "Designate a Master Looter",
								desc = "Auto set this player to ML if he or she is in the raid, by using the setup button, if the player is not found or this field is empty you will be set as ML",
								type = "input",
								get = function() return Floot_ConfigDb["MasterLooter"] end,
								set = function(info, Name) Floot_ConfigDb["MasterLooter"] = Floot:FormatName(Name) end,
							},
							RaidDifficultyAI = {
								order = 2,
								name = "Raid Type AI",
								desc = "Turns on or off the AI to auto select instance type, this will overwrite Raid Difficulty",
								type = "toggle",
								get = function() return Floot_ConfigDb["RaidDifficultyAI"] end,
								set = function() Floot:ToggleRaidDifficultyAI() end,
							},
							RaidDiffucltyHeroic = {
								order = 3,
								name = "AI Force Heroic",
								desc = "This will force the AI to choose heroic mode, it not checked it will choose normal",
								type = "toggle",
								disabled = function() return not Floot_ConfigDb["RaidDifficultyAI"] end,
								get = function() return Floot_ConfigDb["RaidDiffucltyHeroic"] end,
								set = function() 
									if (Floot_ConfigDb["RaidDiffucltyHeroic"]) then
										Floot_ConfigDb["RaidDiffucltyHeroic"] = false 
									else 
										Floot_ConfigDb["RaidDiffucltyHeroic"] = true 
									end 
								end,
							},
							RaidDifficulty = {
								order = 4,
								name = "Raid Difficulty",
								desc = "Sets the raid difficulty, can only be used when Raid Type AI is turned off",
								type = "select",
								disabled = function() return Floot_ConfigDb["RaidDifficultyAI"] end,
								get = function() return Floot_ConfigDb["RaidDifficulty"] end,
								set = function(info,value) Floot_ConfigDb["RaidDifficulty"] = value end,
								values = {
									[1] = "Normal 10",
									[3] = "Heroic 10",
									[2] = "Normal 25",
									[4] = "Heroic 25",
								},
							},
							RaidLootQuality = {
								order = 5,
								name = "Raid Loot Quality",
								desc = "Set the raid loot threshold",
								type = "select",
								get = function() return Floot_ConfigDb["RaidLootQuality"] end,
								set = function(info,value) Floot_ConfigDb["RaidLootQuality"] = value end,
								values = {
									[2] = GREEN_FONT_COLOR_CODE .. "Uncommon" .. FONT_COLOR_CODE_CLOSE,
									[3] = Floot:GetTextColor("Class", "SHAMAN") .. "Rare" .. FONT_COLOR_CODE_CLOSE,
									[4] = Floot:GetTextColor("Class", "WARLOCK") .. "Epic" .. FONT_COLOR_CODE_CLOSE,
									[5] = Floot:GetTextColor("Class", "DRUID") .. "Legendary" .. FONT_COLOR_CODE_CLOSE,
									[6] = "Artifact",
								},
							},
						},
					},
					MasterLooterGroup = {
						type = "group",
						name = "Master Looter's setup",
						guiInline = true,
						order = 3,
						args = {
							AddRaidNuker = {
								order = 1,
								name = "Add a raid nuker to the list",
								desc = "Auto set to one of the nukers from this list if your the ML, by using the setup command",
								type = "input",
								set = function(info, Name) Floot_ConfigDb["KnownNukers"][Floot:FormatName(Name)] = Floot:FormatName(Name)	end
							},
							DelRaidNuker = {
								order = 2,
								name = "Ban a raid Nuker",
								desc = "Ban a player so he or she will never be sync'd to you or be used as a nuker",
								type = "select",
								set = function(info, Name) 
									if not (Name == "PlaceHolder") then
										Floot_ConfigDb["KnownNukers"][Name] = nil
										Floot_ConfigDb["BannedNukers"][Name] = Name
									end
								end,
								values = Floot_ConfigDb["KnownNukers"],
								confirm = true,
								confirmText = "Really ban this raid nuker?",
							},
							UnbanNuker = {
								order = 3,
								name = "Unban a raid nuker",
								desc = "This will unban the player and allow him or her to be entered into the nuker list, or recived via sync",
								type = "select",
								set = function(info, Name)
									if not (Name == "PlaceHolder") then
										Floot_ConfigDb["BannedNukers"][Name] = nil end end,
								values = Floot_ConfigDb["BannedNukers"],
								confirm = true,
								confirmText = "Really unban this player?",
							},
						},
					},
				},
			},
			GuildSettingsGroup = {
				name = "Guild Settings",
				type = "group",
				desc = "Guild specific settings",
				order = 7,
				cmdHidden = true,
				args = {
					GuildRankGroup = {
						type = "group",
						name = "Set Raider ranks",
						desc = "Mark the ranks that are considered raiders",
						guiInline = true,
						order = 1,
						args = {
							ExplainRanks = {
								order = 1,
								type = "description",
								name= "Mark the ranks that are considered raiders for loot purposes",
							},
							Rank0 = {
								order = 2,
								name = function() return Floot_ConfigDb["RankNames"][0] end,
								desc = "This is always the GM",
								type = "toggle",
								get = function() return Floot_ConfigDb["RaiderRanks"][0] end,
								set = function(Input, Value) Floot:SetRaiderRank(0, Value) end,
								cmdHidden = true,
							},
							Rank1 = {
								order = 3,
								name = function() return Floot_ConfigDb["RankNames"][1] end,
								desc = "This is usually Officers as rank1",
								type = "toggle",
								get = function() return Floot_ConfigDb["RaiderRanks"][1] end,
								set = function(Input, Value) Floot:SetRaiderRank(1, Value) end,
								cmdHidden = true,
							},
							Rank2 = {
								order = 4,
								name = function() return Floot_ConfigDb["RankNames"][2] end,
								type = "toggle",
								get = function() return Floot_ConfigDb["RaiderRanks"][2] end,
								set = function(Input, Value) Floot:SetRaiderRank(2, Value) end,
								cmdHidden = true,
							},
							Rank3 = {
								order = 5,
								name = function() return Floot_ConfigDb["RankNames"][3] end,
								type = "toggle",
								get = function() return Floot_ConfigDb["RaiderRanks"][3] end,
								set = function(Input, Value) Floot:SetRaiderRank(3, Value) end,
								cmdHidden = true,
							},
							Rank4 = {
								order = 6,
								name = function() return Floot_ConfigDb["RankNames"][4] end,
								type = "toggle",
								get = function() return Floot_ConfigDb["RaiderRanks"][4] end,
								set = function(Input, Value) Floot:SetRaiderRank(4, Value) end,
								cmdHidden = true,
							},
							Rank5 = {
								order = 7,
								name = function() return Floot_ConfigDb["RankNames"][5] end,
								type = "toggle",
								get = function() return Floot_ConfigDb["RaiderRanks"][5] end,
								set = function(Input, Value) Floot:SetRaiderRank(5, Value) end,
								cmdHidden = true,
							},
							Rank6 = {
								order = 8,
								name = function() return Floot_ConfigDb["RankNames"][6] end,
								type = "toggle",
								get = function() return Floot_ConfigDb["RaiderRanks"][6] end,
								set = function(Input, Value) Floot:SetRaiderRank(6, Value) end,
								cmdHidden = true,
							},
							Rank7 = {
								order = 9,
								name = function() return Floot_ConfigDb["RankNames"][7] end,
								type = "toggle",
								get = function() return Floot_ConfigDb["RaiderRanks"][7] end,
								set = function(Input, Value) Floot:SetRaiderRank(7, Value) end,
								cmdHidden = true,
							},
							Rank8 = {
								order = 10,
								name = function() return Floot_ConfigDb["RankNames"][8] end,
								type = "toggle",
								get = function() return Floot_ConfigDb["RaiderRanks"][8] end,
								set = function(Input, Value) Floot:SetRaiderRank(8, Value) end,
								cmdHidden = true,
							},
							Rank9 = {
								order = 11,
								name = function() return Floot_ConfigDb["RankNames"][9] end,
								type = "toggle",
								get = function() return Floot_ConfigDb["RaiderRanks"][9] end,
								set = function(Input, Value) Floot:SetRaiderRank(9, Value) end,
								cmdHidden = true,
							},
						},
					},	
				},
			},
			debug = {
				name = "Debug options",
				type = "group",
				desc = "Any debug command set will be reset on ui reload or logout (development only)",
				order = 8,
				cmdHidden = true,
				args= {
					clearwinners = {
						order = 1,
						name = "Clear winnerlist",
						desc = "clear the winner list",
						type = "execute",
						func = function() Floot:ClearWinnerList("Force") end,
					},
					dumpwinnerlist = {
						order = 2,
						name = "Dump Winnerlist",
						desc = "Debug the winner list while rolling",
						type = "execute",
						func = function() Floot:DumpWinnerList() end,
					},
					dumpdoaawardeditems = {
						order = 3,
						name = "Dump FlootAwardedItems",
						desc = "Will dump the FlootAwardedItems array",
						type = "execute",
						func = function() Floot:DumpFlootAwardedItems() end,
					},
					dumpflootruntime = {
						order = 4,
						name = "Dump Runtime",
						desc = "Will dump the FlootRuntime array",
						type = "execute",
						func = function() Floot:DumpRuntime() end,
					},
					clearwinnerlist = {
						order = 5,
						name = "Clear all data",
						desc = "If you have done a raid, that should not be uploaded to the web site eg. unofficial then use this button to send a reset to all running the addon in the raid",
						type = "execute",
						func = function() Floot:SendClearAllData() end,
						cmdHidden = true,
						confirm = true,
						confirmText = "Really force all running the addon to reset raid data?",
					},
					winnerlist = {
						order = 6,
						name = "Winnerlist debug",
						desc = "Debug the winner list while rolling",
						type = "toggle",
						set = function() Floot:ToggleDebug("WinnerList") end,
						get = function() return FlootRuntime["Debug"]["WinnerList"] end,
					},
					masterloot = {
						order = 7,
						name = "MasterLoot debug",
						desc = "Debug MasterLoot stuff",
						type = "toggle",
						set = function() Floot:ToggleDebug("MasterLoot") end,
						get = function() return FlootRuntime["Debug"]["MasterLoot"] end,
					},
					versioncheck = {
						order = 8,
						name = "Version check debug",
						desc = "Dumps info about version check braodcasts and whispers",
						type = "toggle",
						set = function() Floot:ToggleDebug("VersionCheck") end,
						get = function() return FlootRuntime["Debug"]["VersionCheck"] end,
					},
					bypassraid = {
						order = 9,
						name = "Bypass Raid",
						desc = "Allows you to test looting without being in a raid",
						type = "toggle",
						set = function() Floot:ToggleDebug("BypassRaid") end,
						get = function() return FlootRuntime["Debug"]["BypassRaid"] end,
					},
					broadcastloot = {
						order = 10,
						name = "Broadcast loot",
						desc = "Dumps info about loot broadcasts when the FlootFrameWinnerlist widget closes",
						type = "toggle",
						set = function() Floot:ToggleDebug("BroadcastUpdate") end,
						get = function() return FlootRuntime["Debug"]["BroadcastUpdate"] end,
					},
					lootquality = {
						order = 11,
						name = "LootQuality",
						desc = "0 = poor, 1 = common, 2 = uncommon, 3 = rare, 4 = epic, 5 = legendary",
						type = "range",
						get = function() return FlootRuntime["Debug"]["LootQuality"] end,
						set = function(self, Quality) Floot:SetLootQuality(self.input, Quality) end,
						step = 1,
						min = 0,
						max = 5,
					},
					comgroup = {
						type = "group",
						name = "Communication debug",
						guiInline = true,
						order = 12,
						args = {
							communication = {
								order = 1,
								name = "Communication",
								desc = "Dumps the header of packets",
								type = "toggle",
								set = function() Floot:BroadcastStarStopComDebug() end,
								get = function() return FlootRuntime["Debug"]["DebuggerName"] end,
							},
							version = {
								order = 2,
								type = "description",
								name = function() return FlootRuntime["Debug"]["DebuggerName"] end,
							},
							dumpcomdata = {
								order = 3,
								name = "Dump packet data",
								desc = "Dummps the data of the packets",
								type = "toggle",
								set = function() Floot:ToggleDebug("DebugData") end,
								get = function() return FlootRuntime["Debug"]["DebugData"] end,
							},
						},
					},
					getraidsetup = {
						order = 11,
						name = "Get RaidSetupInfo",
						desc = "Will request the Raid Setup Info from the player name type in",
						type = "input",
						get = function() return "Player Name" end,
						set = function(info, Name) Floot:RequestRaidSetupInfo(Name) end,
						cmdHidden = true,
					},
				},
			},
			addoninfo = {
				order = 9,
				name = "Addon Info",
				type = "group",
				desc = "Info about the addon",
				cmdHidden = true,
				args = {
					versionheader = {
						order = 1,
						type = "header",
						name = "Version",
					},
					version = {
						order = 2,
						type = "description",
						name = function() return FlootGui:GetDescription("Version") end,
					},
					newfeatureheader = {
						order = 3,
						type = "header",
						name = "New features",
					},
					newfeature = {
						order = 4,
						type = "description",
						name = function() return FlootGui:GetDescription("NewFeatures") end,
					},
					changesheader = {
						order = 5,
						type = "header",
						name = "Changes",
					},
					changes = {
						order = 6,
						type = "description",
						name = function() return FlootGui:GetDescription("Changes") end,
					},
					bugfixheader = {
						order = 7,
						type = "header",
						name = "Bug fixes",
					},
					bugfix = {
						order = 8,
						type = "description",
						name = function() return FlootGui:GetDescription("Bugfix") end,
					},
					notesheader = {
						order = 9,
							type = "header",
						name = "Special notes",
					},
					notes = {
						order = 10,
						type = "description",
						name = function() return FlootGui:GetDescription("Notes") end,
					},
				},
			},
--[[			setup = {
				order = 997,
				name = "Setup the raid",
				desc = "This will do the raid setup depending on your status in the raid.\n RL Sets ML, and loot quality etc.\nML Set nuker from known nuker list",
				type = "execute",
				func = function() 
					FlootRuntime["LocalSetupButtonPressed"] = true
					FlootFrames:PopulateMLChoiseFrame()
				end,
				guiHidden = true,
				disabled = function() if (FlootRuntime["InSync"] == true or FlootRuntime["IsInRaid"] == nil  ) then return true else return false end end,
			}, --]]
			roll = {
				order = 998,
				name = "Roll",
				desc = "Start a roll by linking the item, there MUST be a space between roll and the item.",
				type = "input",
				set = function(self) Floot:ManualLootStart(self.input) end,
				get = function() return "Does not work in GUI" end,
				guiHidden = true,
			},
			gui = {
				name = "show UI",
				type = "execute",
				desc = "Shows the Graphical user interface",
				func = function() Floot:OpenConfig() end,
				guiHidden = true,
				order = 999,
			},
		},
	}

	return ConfigOpts
end


--------------------------------------------------------
----         Latest Changes description				----
--------------------------------------------------------
function FlootGui:GetDescription(Type)
	local Desc = "This addon is created for the guild Dead on Arrival (DoA) on Azjol-Nerub by Presco/Prescot, as the loot addon that Raid leader and master looter will run.\n\n"
	local Version = "Version " .. FlootRuntime["VersionMajor"] .. "." .. FlootRuntime["VersionMinor"] .. "\n"

	local NewFeatures = "\n"

	local Changes = "Guild snapshots now happen automatically when a raid is started, the button will be removed in version 7.20\n"

	local Bugfix = "Fixed a typo that prevented the Nuke button from being used.\n"

	local Notes = "None\n"

	if (Type == "Desc") then
		return Desc
	elseif (Type == "Version") then
		return Version
	elseif (Type == "NewFeatures") then
		return NewFeatures
	elseif (Type == "Changes") then
		return Changes
	elseif (Type == "Bugfix") then
		return Bugfix
	elseif (Type == "Notes") then
		return Notes
	end
end

