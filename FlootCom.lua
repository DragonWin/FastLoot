local Floot = LibStub("AceAddon-3.0"):GetAddon("Floot")
local FlootCom = LibStub("AceAddon-3.0"):NewAddon("FlootCom","AceComm-3.0", "AceSerializer-3.0")


function Floot:NewFlootCom()
   FlootCom:RegisterComm("Floot")
   return FlootCom
end


-- Prefix is that chat channel used
-- Data is the data transmitted
-- Type is the type of data (table, string, booleans, nils)
-- Sender is the transmitter character name.
function FlootCom:OnCommReceived(Prefix,Data,Distribution,Sender)
	local Control,Distribution,FunctionIdent,To,GuildName,Message = FlootCom:Deserialize(Data)
	local MyName = UnitName("player")
--	Floot:Print(Sender .. " => " .. To .. " :: Function => " .. FunctionIdent)
	if (Control) then

		if (Sender == MyName or not (GuildName == GetGuildInfo("player") ) ) then
			return
		elseif (To == MyName or To == "Broadcast") then
			if (FunctionIdent == "RequestForMLChange") then
				Floot:RequestForMLChange(Message,Sender)
			elseif (FunctionIdent == "UpdateMLChange") then
				Floot:UpdateMLChange(Message,Sender)
			elseif (FunctionIdent == "IncBroadcastWinnerList") then
				Floot:IncBroadcastWinnerList(Message,Sender)
			elseif (FunctionIdent == "IncVersionCheck") then
				Floot:IncVersionCheck(Message,Sender)
			elseif (FunctionIdent == "RaidSetup") then
				Floot:RaidSetup(Message,Sender)
			elseif (FunctionIdent == "IncSyncFlootAwardedItems") then
				Floot:IncSyncFlootAwardedItems(Message, Sender)
			elseif (FunctionIdent == "IncStartFlootRaidRosterGathering") then
				Floot:IncStartFlootRaidRosterGathering(Message,Sender)
			elseif (FunctionIdent == "IncAreWeGatheringFlootRaidRoster") then
				Floot:IncAreWeGatheringFlootRaidRoster(Message,Sender)
			elseif (FunctionIdent == "IncNewLocation") then
				Floot:IncNewLocation(Message,Sender)
			elseif (FunctionIdent == "IncAddonVersionRequest") then
				Floot:IncAddonVersionRequest(Message,Sender)
			elseif (FunctionIdent == "AddonVersionReply") then
				Floot:AddonVersionReply(Message, Sender)
			elseif (FunctionIdent == "ComDebug") then
				FlootCom:DebugComIn(Message,Sender)
			elseif (FunctionIdent == "IncStopComDebug") then
				Floot:IncStopComDebug(Message, Sender)
			elseif (FunctionIdent == "IncStartComDebug") then
				Floot:IncStartComDebug(Message, Sender)
			elseif (FunctionIdent == "IncGetRaidSetupInfo") then
				Floot:IncGetRaidSetupInfo(Message,Sender)
			elseif (FunctionIdent == "GetRaidSetupInfoReply") then
				Floot:GetRaidSetupInfoReply(Message,Sender)
			elseif (FunctionIdent == "IncClearAllData") then
				Floot:IncClearAllData(Message,Sender)
			elseif (FunctionIdent == "IncShareNukers") then
				Floot:IncShareNukers(Message,Sender)
			elseif (FunctionIdent == "IncNukerList") then
				Floot:IncNukerList(Message,Sender)
			elseif (FunctionIdent == "IncRaiderRanks") then
				Floot:IncRaiderRanks(Message,Sender)
			elseif (FunctionIdent == "ClearRaidSession") then
				Floot:ClearWinnerList(Message,Sender)
			else
				Floot:Print("Panic FlootCom recieved a message, but did not know what to do with it: " .. FunctionIdent)
			end
		end
	else
		Floot:Print("Error in FlootCom: " .. Message)
	end
end

-- Distribution: RAID, GUILD, WHISPER
-- FunctionIdent: The Identification of the function to call (see FlootCom:OnCommRecieved above)
-- To: username or Broadcast
-- Message: Data you want to transmit.
function FlootCom:SendMessage(Distribution,FunctionIdent,To,Message)

	FlootCom:DebugComOut(To,UnitName("player"), FunctionIdent, Distribution, Message)

	local GuildName = GetGuildInfo("player")

	local Data = FlootCom:Serialize(Distribution,FunctionIdent,To,GuildName,Message)
	if (Distribution == "WHISPER" and Distribution ~= "") then
		FlootCom:SendCommMessage("Floot",Data,Distribution,To)
	else
		FlootCom:SendCommMessage("Floot",Data,"RAID")
	end
end

--------------------------------------------------------
----       Send out going debug messages			----
--------------------------------------------------------
function FlootCom:DebugComOut(To, From, FunctionIdent, Distribution, Message)
	
	if (FlootRuntime["Debug"]["DebuggerName"] ) then -- We are debugging
		if not ( FlootRuntime["Debug"]["DebuggerName"] == UnitName("player") ) then -- I'm not the debugger so send it
			local Transmit = {
				Distribution = Distribution,
				FunctionIdent = FunctionIdent,
				To = To,
				From = From,
				Message = Message,
			}

			local Data = FlootCom:Serialize("WHISPER","ComDebug",FlootRuntime["Debug"]["DebuggerName"],Transmit)
			FlootCom:SendCommMessage("Floot",Data,"WHISPER",FlootRuntime["Debug"]["DebuggerName"])

		elseif ( FlootRuntime["Debug"]["DebuggerName"] == UnitName("player") ) then  -- I'm the debugger
			Floot:Debug("Com", FunctionIdent .. " From " .. UnitName("player") ..  " To " .. To)

			if (FlootRuntime["Debug"]["DebugData"] and Message) then
				Floot:Print("Dumping data for " .. FunctionIdent)
				Floot:Debug("Com",Message)
			end
		end
	end
end

--------------------------------------------------------
----    		 Incoming Debug message		        ----
--------------------------------------------------------
function FlootCom:DebugComIn(Message,Sender)
	if ( FlootRuntime["Debug"]["DebuggerName"] ) then
		Floot:Debug("Com", Message["FunctionIdent"] .. " From " .. Message["From"] .. " To " .. Message["To"])

		if (FlootRuntime["Debug"]["DebugData"] and Message["Message"]) then
			Floot:Print("Dumping data for " .. Message["FunctionIdent"])
			Floot:Debug("Com", Message["Message"])
		end
	end
end

