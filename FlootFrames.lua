
local Floot = LibStub("AceAddon-3.0"):GetAddon("Floot")
FlootFrames = {}   -- DEBUG Should be local
FlootFrameObj = {}  -- DEBUG Should be local
local DropDownTable = {} 
local FlootFramesRuntime = {
	FlootTextBoxWidth = nil, -- Used to calculate offset for MainSpec Button
	FlootResultFrameBaseHeight = 160,
}


function FlootFrames:OnInitialize()
	FlootFrames:CreateBackgroundFrame("FlootFrame")
	FlootFrames:CreateBackgroundFrame("FlootResultFrame")
	FlootFrames:CreateBackgroundFrame("FlootUpdateWarning")
	FlootFrames:CreateBackgroundFrame("FlootChooseML")
	FlootFrames:CreateOwnTooltip()
	FlootFrames:CreateResultPlayerReasignDDFrame()
end

function FlootFrames:OnEnable()
	UIDropDownMenu_Initialize(FlootFrames:GetFrame("FlootResultPlayerDDFrame"), FlootInitPlayerDDFrame, "MENU")

end

----------------------------------------------------
----          Main background windows           ----
----------------------------------------------------
function FlootFrames:CreateBackgroundFrame(FrameName)
   if (not FrameName) then
	  Floot:Print("No Frame Name in CreateBackgroundFrame")
	  return 
   end
   
   local FlootBGMainFrame = { 
	  tile = true, 
	  tileSize = 32, 
	  edgeSize = 32, 
	  insets = {left = 11, right = 12, top = 12, bottom = 11}, 
	  bgFile = "Interface/DialogFrame/UI-DialogBox-Background", 
	  edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
   }

   local FlootBGTitleFrame = {
	   bgFile = "Interface/DialogFrame/UI-DialogBox-Header",
   }

   local Frame = CreateFrame("Frame", FrameName, UIParent) 
   	
   if (Floot_ConfigDb[FrameName] == nil) then
	  Floot_ConfigDb[FrameName] = {
		 Point = "CENTER",
		 X = 0,
		 Y = 0,
	  }
   end
   
   Frame:SetPoint(Floot_ConfigDb[FrameName]["Point"], UIParent, Floot_ConfigDb[FrameName]["Point"], Floot_ConfigDb[FrameName]["X"] , Floot_ConfigDb[FrameName]["Y"]) 
   Frame:SetHeight(250) 
   Frame:SetBackdrop(FlootBGMainFrame)
   Frame:SetFrameStrata("FULLSCREEN_DIALOG")
   Frame:SetBackdropColor(0,0,0,1)
   Frame:SetBackdropBorderColor(179,132,5,1)
   Frame:SetMovable(true)
   Frame:EnableMouse(true)
   Frame:RegisterForDrag("LeftButton")
   Frame:SetScript("OnDragStart", function(self) if self:IsMovable() then self:StartMoving() end end)
   Frame:SetScript("OnDragStop", function(...) FlootFrames:SetBGFramePoints(...) end)
 
   -- Create the Title Frame
   local Title = CreateFrame("Frame", FrameName .. "Title", Frame)
   Title:SetBackdrop(FlootBGTitleFrame)
   Title:SetPoint("TOP", Frame, "TOP", 0, 13.5)
   Title:SetHeight(64)
   Title:SetWidth(256)
   Title.Text = Title:CreateFontString(FrameName .. "TitleText", "ARTWORK", "GameFontNormal")
   Title.Text:SetPoint("CENTER", Title, "CENTER", 0, 11)
   Title.Text:SetText("Floot")
   Frame.Title = Title

   -- Create the Close button for LootFrame
   local CloseButton = CreateFrame("Button", FrameName .. "CloseButton", Frame, "UIPanelCloseButton")
   CloseButton:SetPoint("TOPRIGHT", FrameName, "TOPRIGHT", -6, -6)
   CloseButton:SetScript("OnMouseDown", function() end)

   -- Create the help button
   local HelpButton = CreateFrame("Button", FrameName .. "HelpButton", Frame, "UIPanelButtonTemplate")
   HelpButton:SetPoint("TOPRIGHT", CloseButton, "TOPLEFT", 0, -7)
   HelpButton:SetText("?")
   HelpButton:SetHeight(18)
   HelpButton:SetWidth(15)
   HelpButton:SetScript("OnEnter", function() FlootFrames:CreateHelpTooltip(HelpButton) end)
   HelpButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
   FlootFrameObj[FrameName .. "HelpButton"] = HelpButton

   FlootFrameObj[FrameName] = Frame

   if (FrameName == "FlootFrame") then  -- FlootFrame only stuff
	 CloseButton:SetScript("OnMouseUP", Floot.CloseLootFrame)
	 Frame:SetWidth(400)
	 Title.Text:SetText("Floot")
	 FlootFrames:CreateStatusFrame()
	 FlootFrames:UpdateStatusFrame()
	 FlootFrames:CreateAnnounceButton()
	 FlootFrames:CreateFlootWinnerListDateFrame()
  elseif (FrameName == "FlootResultFrame") then  -- ResultFrame only stuff
	 CloseButton:SetScript("OnMouseUP", Floot.CloseResultFrame)
	 Frame:SetWidth(560)  -- Set the initial width of the FlootResultFrame
	 Frame:SetHeight(FlootFramesRuntime["FlootResultFrameBaseHeight"])
	 Title.Text:SetText("Roll Window")	 FlootFrames:CreateResultWindowFrames() -- Create the Raider/member/unknown colum and Titles
	 FlootFrames:CreateNukeButton()
 elseif (FrameName == "FlootUpdateWarning") then
	 Frame:SetWidth(400)
	 Frame:SetHeight(160)
	 Title.Text:SetText("Floot")
	 FlootFrames:SetFlootUpdateWarning(Frame)
 elseif (FrameName == "FlootChooseML") then
	 Frame:SetWidth(160)
	 Frame:SetHeight(250)
	 Title.Text:SetText("Choose ML")
	 HelpButton:Hide()
	 CloseButton:Hide()
 end
 
	 Frame:Hide()

end

----------------------------------------------------
---- Save the relative X Y coordinates for      ----
---- SetPoint to the Floot_ConfigDb           ----
----------------------------------------------------
function FlootFrames:SetBGFramePoints(this)
   if this:IsMovable() then
	  this:StopMovingOrSizing()
   end

   local point, _, _, xOfs, yOfs = this:GetPoint()
   Floot_ConfigDb[this:GetName()] = {
	  Point = point,
	  X = xOfs,
	  Y = yOfs,
   }
end

----------------------------------------------------
----      Create the hidden tooltips            ----
----------------------------------------------------
function FlootFrames:CreateOwnTooltip()
	local FlootTooltip = CreateFrame("GameTooltip", "FlootTooltip", UIParent, "GameTooltipTemplate")
	FlootTooltip:Hide()
	FlootFrameObj["FlootTooltip"] = FlootTooltip
end

----------------------------------------------------
----         Crete the Help tooltips            ----
----------------------------------------------------
function FlootFrames:CreateHelpTooltip(Frame)
	GameTooltip:SetOwner(Frame, "ANCHOR_LEFT")

	if (Frame:GetName() == "FlootFrameHelpButton") then
		GameTooltip:AddLine("Top Left date", 102/255, 255/255, 255/255)
		GameTooltip:AddLine("This is the date your last reset the winnerlist")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Offical / Unofficial Frame", 102/255, 255/255, 255/255)
		GameTooltip:AddLine("While running a raid you can at any time see what")
		GameTooltip:AddLine("mode the addon is in. To change mode simply click it")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Green background saying Official is offical raids")
		GameTooltip:AddLine("Official raids on mainspec rolls look at winnerlist,")
		GameTooltip:AddLine("rank and roll")
		GameTooltip:AddLine("Official raids on offspec rolls only look at rank")
		GameTooltip:AddLine("and roll")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Red background saying Unofficial is unofficial raids")
		GameTooltip:AddLine("Unofficial raids only look at the winnerlist for both")
		GameTooltip:AddLine("mainspec and offspec (shared winnerlist). All rollers")
		GameTooltip:AddLine("will be seen as raiders")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Item color codes", 102/255, 255/255, 255/255)
		GameTooltip:AddLine("The color codes is only a guide and can be wrong")
		GameTooltip:AddLine("use your own judgement too")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("The priority is Red, Blue, Green, rest")
		GameTooltip:AddLine("Red = Weapon")
		GameTooltip:AddLine("Blue = Tier item")
		GameTooltip:AddLine("Green = Trinket / rings / held in Off-Hand / Neck")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(" ")

	elseif (Frame:GetName() == "FlootResultFrameHelpButton") then
	-- Colors are r g b in 0 - 1 format so take RGB color and devide with 255
		GameTooltip:AddLine("The player lines consists of ", 102/255, 255/255, 255/255)
		GameTooltip:AddLine("Roll  |  PlayerName  |  Position in the winnerlist")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Roll", 102/255, 255/255, 255/255)
		GameTooltip:AddLine("This is the actual roll made by the player")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("PlayerName", 102/255, 255/255, 255/255)
		GameTooltip:AddLine("The name of the player color coded by class") 
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("WinnerList", 102/255, 255/255, 255/255)
		GameTooltip:AddLine("The number that player has in the winnerlist.") 
		GameTooltip:AddLine("When some one wins an item they go to the")
		GameTooltip:AddLine("end of the list (higest number)")
		GameTooltip:AddLine("The winnerlist should only be looked at")
		GameTooltip:AddLine("if you have a roller in the unknown section,")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("The person with the lowest winnerlist number,")
		GameTooltip:AddLine("should win if they have the same priority (rank).")
		GameTooltip:AddLine("This could be a raiders alt who is not in the guild.")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("If a person has not won an item, no number will be")
		GameTooltip:AddLine("displayed to the right of the name")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Who should have the item", 102/255, 255/255, 255/255)
		GameTooltip:AddLine("Start in the top left corner and move to")
		GameTooltip:AddLine("the bottom right corner. If there is any")
		GameTooltip:AddLine("one in the unknown section, you must go")
		GameTooltip:AddLine("by the rules agreed on")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Unknown colum", 102/255, 255/255, 255/255)
		GameTooltip:AddLine("The Unknown colum will only show if there is")
		GameTooltip:AddLine("any one to display in that colum.")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(" ")
	end
	GameTooltip:Show()
end

----------------------------------------------------
----  Crete the FlootFrameStatus frame        ----
----------------------------------------------------
function FlootFrames:CreateStatusFrame()

	local FlootFrameBG = {
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	}

	local Frame = CreateFrame("Frame", "FlootFrameStatus", FlootFrame)
	Frame:SetBackdrop(FlootFrameBG)
	Frame:SetBackdropColor(1,1,1,0.5) 
	Frame:SetPoint("TOPLEFT","FlootFrame","TOPLEFT", 30, -55)
	Frame:SetPoint("TOPRIGHT", "FlootFrame","TOPRIGHT", -30, -55)
	Frame:SetBackdropBorderColor(35,135,70,1)
	Frame.Text = Frame:CreateFontString("FlootFrameStatusText", "ARTWORK", "GameFontNormal") 
	Frame.Text:SetText( Floot:GetAddonModeText() )
	Frame.Text:SetPoint("CENTER", Frame, "CENTER", 0,0)
	Frame:SetHeight(25) 
	Frame:EnableMouse(true)
	Frame:SetScript("OnMouseDown", function()  end)
	Frame:SetScript("OnMouseUP", Floot.ChangeMode)
	FlootFrameObj["FlootFrameStatus"] = Frame
end

----------------------------------------------------
----          Update warning window             ----
----------------------------------------------------
function FlootFrames:SetFlootUpdateWarning(Frame)
	local FlootFrameBG = {
		tile = true,
		tileSize = 8,
		edgeSize = 12,
		insets = {left = 2, right = 2, top = 2, bottom = 2},
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	}

	local FlootUpdateInfo = CreateFrame("Frame", "FlootUpdateInfo", Frame)
	FlootUpdateInfo:SetBackdrop(FlootFrameBG)
	FlootUpdateInfo:SetBackdropColor(0/255,0/255,0/255,0.6)
	FlootUpdateInfo:SetBackdropBorderColor(255/255,153/255,0/255,1)
	FlootUpdateInfo:SetPoint("TOP","FlootUpdateWarning","TOP", 0, -40)
	FlootUpdateInfo.Text = FlootUpdateInfo:CreateFontString("FlootUpdateInfoText", "ARTWORK", "GameFontNormal")
	FlootUpdateInfo.Text:SetText("Floot is out of date, a new version is available, please update right away\n\n Click in the box below and press CRL + c to copy the download link")
	FlootUpdateInfo.Text:SetAllPoints(FlootUpdateInfo)
	FlootUpdateInfo:SetHeight(70)
	FlootUpdateInfo:SetWidth(350)

	local FlootUpdateEditBox = CreateFrame("EditBox", "FlootUpdateEditBox", Frame, "InputBoxTemplate")
	FlootUpdateEditBox:SetWidth(350)
	FlootUpdateEditBox:SetHeight(20)
	FlootUpdateEditBox:SetPoint("BOTTOM", Frame, "BOTTOM", 0, 20)
	FlootUpdateEditBox:SetAutoFocus(false)
	FlootUpdateEditBox:SetText(FlootRuntime["DownloadURL"])
	FlootFrameObj["FlootUpdateEditBox"] = FlootUpdateEditBox

end

----------------------------------------------------
----         Create the announce button         ----
----------------------------------------------------
function FlootFrames:CreateAnnounceButton()

   local AnnounceButton = CreateFrame("Button", "FlootAnnounceButton", FlootFrames:GetFrame("FlootFrame"), "UIPanelButtonTemplate")
   AnnounceButton:SetPoint("BOTTOMLEFT", "FlootFrameStatus", "TOPLEFT", 0, 5)
   AnnounceButton:SetText("Announce")
   AnnounceButton:SetWidth(100)
   AnnounceButton:SetHeight(25)
   AnnounceButton:SetScript("OnMouseUp", function() Floot:AnnounceLoot() end)
   AnnounceButton:SetScript("OnMouseDown", function()  end)
   FlootFrameObj["FlootAnnounceButton"] = AnnounceButton

end

----------------------------------------------------
----            Update Status frame             ----
----------------------------------------------------
function FlootFrames:UpdateStatusFrame()
	if (Floot_ConfigDb["OfficialMode"]) then
		FlootFrameObj["FlootFrameStatus"]:SetBackdropColor(0/255, 153/255, 0/255, 0.5);
	else
		FlootFrameObj["FlootFrameStatus"]:SetBackdropColor(153/255, 0/255, 0/255, 0.5);
	end
	FlootFrameObj["FlootFrameStatus"]["Text"]:SetText( Floot:GetAddonModeText() )
end

----------------------------------------------------
----      Create the winnerlist reset frame     ----
----------------------------------------------------
function FlootFrames:CreateFlootWinnerListDateFrame()
	local Frame = CreateFrame("Frame","FlootlootWinnerListDateFrame", FlootFrameObj["FlootFrame"])
	Frame:SetPoint("TOPLEFT", "FlootFrame", "TOPLEFT", 12, -12)
	Frame.Text = Frame:CreateFontString("LootListDateFrameText", "ARTWORK", "GameFontNormalSmall")
	Frame.Text:SetPoint("CENTER", Frame, "CENTER", 0,0)
	Frame.Text:SetText(date("%m/%d/%y %H:%M"))
	Frame:SetHeight(Frame.Text:GetHeight())
	Frame:SetWidth(Frame.Text:GetWidth())
	FlootFrameObj["FlootlootWinnerListDateFrame"] = Frame
end

----------------------------------------------------
----  Crete the loot rows in the FlootFrame   ----
----------------------------------------------------
function FlootFrames:CreateLootRow(LootInfo)

	local Frame = FlootFrames:GetFrame("FlootTextBox" .. LootInfo["ButtonId"])
	if (not Frame) then

		-- Create Text frame for itemlink text
		local FlootFrameBG = {
			tile = true,
			tileSize = 8,
			edgeSize = 12,
			insets = {left = 2, right = 2, top = 2, bottom = 2},
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		}

		-- Create the Loot Text box
		local Frame = CreateFrame("Frame", "FlootTextBox" .. LootInfo["ButtonId"], FlootFrame)
		Frame:SetBackdrop(FlootFrameBG)
		Frame:SetBackdropColor(0,0,0,0.8) 
		if (LootInfo["ButtonId"] == 1) then
			Frame:SetPoint("TOPLEFT","FlootFrameStatus","BOTTOMLEFT", 0, -7)
		else
			local Anchor = LootInfo["ButtonId"] -1
			Frame:SetPoint("TOPLEFT","FlootTextBox" .. Anchor,"BOTTOMLEFT", 0, -7)
		end
		Frame:SetBackdropBorderColor(255/255,0,0,1)
		Frame.Text = Frame:CreateFontString("FlootTextBoxText".. LootInfo["ButtonId"], "ARTWORK", "GameFontNormal") 
		Frame.Text:SetText(LootInfo["ItemLink"])
		Frame.Text:SetPoint("CENTER", Frame, "CENTER", 0,0)
		Frame:SetHeight(Frame.Text:GetHeight() + 16) 
		Frame:SetWidth(Frame.Text:GetWidth() +17) 
		Frame:EnableMouse(true)
		Frame:SetScript("OnEnter", function() GameTooltip:SetOwner(Frame,"ANCHOR_CURSOR") GameTooltip:SetHyperlink(LootInfo["ItemLink"]) end)
		Frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
		Frame:SetID(LootInfo["LootSlotId"])
		FlootFrameObj["FlootTextBox" .. LootInfo["ButtonId"]] = Frame

		-- Create the MainSpec button
		local MainSpec = CreateFrame("Button","FlootMainSpec" .. LootInfo["ButtonId"], Frame, "UIPanelButtonTemplate")

		if (LootInfo["ButtonId"] == 1) then
			MainSpec:SetPoint("TOPLEFT", "FlootFrameStatus", "TOPLEFT", 12, -4)
		else
			local Anchor = LootInfo["ButtonId"] -1
			MainSpec:SetPoint("TOPLEFT", "FlootMainSpec" .. Anchor, "BOTTOMLEFT", 0, -15)
		end
		MainSpec:SetText("MainSpec")
		MainSpec:SetScript("OnMouseUP", function(...) Floot:StartRolls(...) end)
		MainSpec:SetScript("OnMouseDown", function() end)
		MainSpec:SetWidth(MainSpec:GetTextWidth() + 16)
		MainSpec:SetHeight(MainSpec:GetTextHeight() + 8)
		MainSpec:SetID(LootInfo["LootSlotId"])
		MainSpec["LootInfo"] = LootInfo
		FlootFrameObj["FlootMainSpec" .. LootInfo["ButtonId"]] = MainSpec

		-- Create the OffSpec button
		local OffSpec = CreateFrame("Button","FlootOffSpec" ..  LootInfo["ButtonId"], Frame, "UIPanelButtonTemplate")
		OffSpec:SetPoint("TOPLEFT", MainSpec, "TOPRIGHT", 5, 0)
		OffSpec:SetText("OffSpec")
		OffSpec:SetScript("OnMouseUP", function(...) Floot:StartRolls(...) end)
		OffSpec:SetScript("OnMouseDown", function() end)
		OffSpec:SetWidth(OffSpec:GetTextWidth() + 16)
		OffSpec:SetHeight(OffSpec:GetTextHeight() + 8)
		OffSpec:SetID(LootInfo["LootSlotId"])
		OffSpec["LootInfo"] = LootInfo

		if (LootInfo["BindType"] and LootInfo["BindType"] == "BoE" and Floot_ConfigDb["OfficialMode"]) then	-- Never do Offspec rolls on BoE items.
			OffSpec:Hide()
		else
			OffSpec:Show()
		end

		-- Overwrite BindType if it is a Recipe.
		if (LootInfo["ItemType"] and LootInfo["ItemType"] == "Recipe" and Floot_ConfigDb["OfficialMode"]) then -- Overwrite BindType if Recipe
			OffSpec:Show()
			MainSpec:Hide()
		end

		FlootFrameObj["FlootOffSpec" ..  LootInfo["ButtonId"]] = OffSpec

	else -- We have an existing frame
		local Frame = FlootFrames:GetFrame("FlootTextBox" ..  LootInfo["ButtonId"])
		Frame.Text:SetText(LootInfo["ItemLink"])
		Frame:SetHeight(Frame.Text:GetHeight() + 16)
		Frame:SetWidth(Frame.Text:GetWidth() +12)
		Frame:SetScript("OnEnter", function() GameTooltip:SetOwner(Frame,"ANCHOR_CURSOR") GameTooltip:SetHyperlink(LootInfo["ItemLink"]) end)
		Frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
		Frame:Show()

		-- Reuse the MainSpec button
		local MainSpec = FlootFrames:GetFrame("FlootMainSpec".. LootInfo["ButtonId"])
		MainSpec:SetText("MainSpec")
		MainSpec:SetScript("OnMouseUP", function(...) Floot:StartRolls(...) end)
		MainSpec:SetWidth(MainSpec:GetTextWidth() + 16)
		MainSpec:SetHeight(MainSpec:GetTextHeight() + 8)
		MainSpec["LootInfo"] = LootInfo
		MainSpec:Show()

		-- Reuse the OffSpec button
		local OffSpec = FlootFrames:GetFrame("FlootOffSpec" .. LootInfo["ButtonId"])
		OffSpec:SetText("OffSpec")
		OffSpec:SetScript("OnMouseUP", function(...) Floot:StartRolls(...) end)
		OffSpec:SetWidth(OffSpec:GetTextWidth() + 16)
		OffSpec:SetHeight(OffSpec:GetTextHeight() + 8)
		OffSpec["LootInfo"] = LootInfo
		if (LootInfo["BindType"] and LootInfo["BindType"] == "BoE" and Floot_ConfigDb["OfficialMode"]) then	-- Never do Offspec rolls on BoE items.
			OffSpec:Hide()
		else
			OffSpec:Show()
		end

		-- Overwrite BindType if it is a Recipe.
		if (LootInfo["ItemType"] and LootInfo["ItemType"] == "Recipe" and Floot_ConfigDb["OfficialMode"]) then -- Overwrite BindType if Recipe
			OffSpec:Show()
			MainSpec:Hide()
		end

	end

	-- Set FlootFrame height
	local LootFrameHeight = ((FlootFrameObj["FlootTextBox1"]:GetHeight() + 10) * LootInfo["ButtonId"]) + 90
	FlootFrameObj["FlootFrame"]:SetHeight(LootFrameHeight)

	-- Get the FlootTextBox
	for i=1, LootInfo["ButtonId"] do
		if (FlootFramesRuntime["FlootTextBoxWidth"]) then  -- Get the widest frames pixels
			if (FlootFrameObj["FlootTextBox" .. i]:GetWidth() > FlootFramesRuntime["FlootTextBoxWidth"]) then
				FlootFramesRuntime["FlootTextBoxWidth"] = FlootFrameObj["FlootTextBox" .. i]:GetWidth()
			end
		else
			FlootFramesRuntime["FlootTextBoxWidth"] = FlootFrameObj["FlootTextBox" .. i]:GetWidth()
		end
	end

	-- Set the last reset date of the Winnerlist
	FlootFrameObj["FlootlootWinnerListDateFrame"]["Text"]:SetText(Floot_ConfigDb["WinnerListResetDate"])

	-- Set the Border corlor of the item text frame
	-- Set default color white
	FlootFrameObj["FlootTextBox" .. LootInfo["ButtonId"]]:SetBackdropBorderColor(1,1,1,1)
	FlootFrameObj["FlootTextBox" .. LootInfo["ButtonId"]]:SetBackdropColor(0,0,0,0.8) 

	-- Weapons	Red
	if ( LootInfo["ItemType"] == "Weapon" ) then																	-- Weapons
		if not ( LootInfo["ItemSubType"] == "Wands") then
			FlootFrameObj["FlootTextBox" .. LootInfo["ButtonId"]]:SetBackdropColor(255/255,0,0,0.4)					
			FlootFrameObj["FlootTextBox" .. LootInfo["ButtonId"]]:SetBackdropBorderColor(255/255,0,0,1)
		end
		-- Armor Green
	elseif ( LootInfo["ItemType"] == "Armor") then																	-- Armor
		-- Miscellaneous = rings and trinkets
		if not ( LootInfo["ItemSubType"] == "Miscellaneous" or LootInfo["ItemSubType"] == "Librams" or LootInfo["ItemSubType"] == "Idols" or LootInfo["ItemSubType"] == " Totems") then
			FlootFrameObj["FlootTextBox" .. LootInfo["ButtonId"]]:SetBackdropColor(0,255/255,0,0.4)
			FlootFrameObj["FlootTextBox" .. LootInfo["ButtonId"]]:SetBackdropBorderColor(0,255/255,0,1)
		end
	end

	-- Tier items Blue
	if ( string.match(LootInfo["LootList"], "Tier.*") ) then
		FlootFrameObj["FlootTextBox" .. LootInfo["ButtonId"]]:SetBackdropColor(0,128/255,255/255,0.4)
		FlootFrameObj["FlootTextBox" .. LootInfo["ButtonId"]]:SetBackdropBorderColor(0,128/255,255/255,1)
	end


	FlootFrameObj["FlootMainSpec1"]:SetPoint("TOPLEFT", "FlootTextBox1", "TOPLEFT", FlootFramesRuntime["FlootTextBoxWidth"] + 10, -3)
	local LootFrameWidth = FlootFramesRuntime["FlootTextBoxWidth"] + FlootFrameObj["FlootMainSpec1"]:GetWidth() + FlootFrameObj["FlootOffSpec1"]:GetWidth()  
	FlootFrameObj["FlootFrame"]:SetWidth(LootFrameWidth + 80)
	FlootFrameObj["FlootFrame"]:Show()	
end


--------------------------------------------------------
----     Create the Nuke Button for ResultFrame     ----
--------------------------------------------------------
function FlootFrames:CreateNukeButton()

	local NukeButton = CreateFrame("Button","FlootNukeButton", FlootFrameObj["FlootResultFrame"], "UIPanelButtonTemplate")
	NukeButton:SetPoint("TOPRIGHT", FlootFrameObj["FlootResultFrameHelpButton"], "TOPLEFT", -7, 5)
	NukeButton:SetText("Nuke")
	NukeButton:SetScript("OnMouseUP", Floot.NukeItem)
	NukeButton:SetScript("OnMouseDown", function() end)
	NukeButton:SetWidth(60)
	NukeButton:SetHeight(30)
	FlootFrameObj["FlootNukeButton"] = NukeButton

end

--------------------------------------------------------
----  Create the rows for raider / member / unknown ----
--------------------------------------------------------
function FlootFrames:CreateResultWindowFrames()

	local FlootFrameBGWhite = {
		tile = true,
		tileSize = 8,
		edgeSize = 12,
		insets = {left = 2, right = 2, top = 2, bottom = 2},
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	}

   local FlootFrameTitle = { 
	  tile = true, 
	  tileSize = 32, 
	  edgeSize = 32, 
	  insets = {left = 11, right = 12, top = 12, bottom = 11}, 
	  bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
	  edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
   }

	-- Create Text frame for itemlink text
	local FlootFrameBG = {
		tile = true,
		tileSize = 8,
		edgeSize = 12,
		insets = {left = 2, right = 2, top = 2, bottom = 2},
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	}

	-- Create Info box
	local RollType = CreateFrame("Frame", "FlootResultFrameRollType", FlootResultFrame)
	RollType:SetBackdrop(FlootFrameBG)
	RollType:SetBackdropColor(0/255,0/255,0/255,0.6) 
	RollType:SetBackdropBorderColor(255/255,153/255,0/255,1)
	RollType:SetPoint("TOP","FlootResultFrame","TOP", 0, -33)
--	RollType:SetWidth(FlootFramesRuntime["FlootTextBoxWidth"] - 60)
	RollType.Text = RollType:CreateFontString("FlootResultFrameRollTypeText", "ARTWORK", "GameFontNormal") 
	RollType.Text:SetText("Test\nText")
	RollType.Text:SetPoint("CENTER", RollType, "CENTER", 0,0)
	RollType:EnableMouse(true)
	FlootFrameObj["FlootResultFrameRollType"] = RollType


	-- Raider colum
	local FlootResultBackgroundRaider = CreateFrame("Frame", "FlootResultBackgroundRaider", FlootFrames:GetFrame("FlootResultFrame"))
	FlootResultBackgroundRaider:SetBackdrop(FlootFrameBGWhite)
	FlootResultBackgroundRaider:SetBackdropBorderColor(255/255,153/255,0/255,1)
	FlootResultBackgroundRaider:SetBackdropColor(0/255,0/255,0/255,0.6) 
	FlootResultBackgroundRaider:SetPoint("TOPLEFT","FlootResultFrame","TOPLEFT", 32, -85)
	FlootResultBackgroundRaider:SetPoint("BOTTOMLEFT","FlootResultFrame","BOTTOMLEFT", -28, 20)
	local FlootResultBackgroundRaiderWidth = (FlootFrameObj["FlootResultFrame"]:GetWidth() -60) / 3
	FlootResultBackgroundRaider:SetWidth(167)
	FlootResultBackgroundRaider:EnableMouse(true)
	FlootFrameObj["FlootResultBackgroundRaider"] = FlootResultBackgroundRaider

	-- Raider Title
	local FlootResultRaiderTitle = CreateFrame("Frame", "FlootResultRaiderTitle", FlootResultBackgroundRaider)
	FlootResultRaiderTitle:SetBackdrop(FlootFrameTitle)
	FlootResultRaiderTitle:SetBackdropColor(1,1,1,0.2)
	FlootResultRaiderTitle:SetPoint("TOPLEFT", "FlootResultBackgroundRaider", "TOPLEFT", 5, -5)
	FlootResultRaiderTitle:SetPoint("TOPRIGHT", "FlootResultBackgroundRaider", "TOPRIGHT", -5, 5)
	FlootResultRaiderTitle.Text = FlootResultRaiderTitle:CreateFontString("FlootResultRaiderTitleText", "ARTWORK", "GameFontNormal")
	FlootResultRaiderTitle.Text:SetText("Raiders")
	FlootResultRaiderTitle.Text:SetPoint("CENTER", FlootResultRaiderTitle, "CENTER", 0,0)
	FlootResultRaiderTitle:SetHeight(FlootResultRaiderTitle.Text:GetHeight() + 31)
	FlootFrameObj["FlootResultRaiderTitle"] = FlootResultRaiderTitle

	-- Member colum
	local FlootResultBackgroundMember = CreateFrame("Frame", "FlootResultBackgroundMember", FlootFrames:GetFrame("FlootResultFrame"))
	FlootResultBackgroundMember:SetBackdrop(FlootFrameBGWhite)
	FlootResultBackgroundMember:SetBackdropBorderColor(255/255,153/255,0/255,1)
	FlootResultBackgroundMember:SetBackdropColor(0/255,0/255,0/255,0.6) 
	FlootResultBackgroundMember:SetPoint("TOPLEFT","FlootResultBackgroundRaider","TOPRIGHT", -3, 0)  -- Minus 2.5 pr windows
	FlootResultBackgroundMember:SetPoint("BOTTOMLEFT","FlootResultBackgroundRaider","BOTTOMRIGHT", -3, 0)  -- Minus 2.5 pr windows
	FlootResultBackgroundMember:SetWidth(FlootResultBackgroundRaider:GetWidth())
	FlootResultBackgroundMember:EnableMouse(true)
	FlootFrameObj["FlootResultBackgroundRaider"] = FlootResultBackgroundMember

	-- Member Title
	local FlootResultMemberTitle = CreateFrame("Frame", "FlootResultMemberTitle", FlootResultBackgroundMember)
	FlootResultMemberTitle:SetBackdrop(FlootFrameTitle)
	FlootResultMemberTitle:SetBackdropColor(1,1,1,0.2)
	FlootResultMemberTitle:SetPoint("TOPLEFT", "FlootResultBackgroundMember", "TOPLEFT", 5, -5)
	FlootResultMemberTitle:SetPoint("TOPRIGHT", "FlootResultBackgroundMember", "TOPRIGHT", -5, 5)
	FlootResultMemberTitle.Text = FlootResultMemberTitle:CreateFontString("FlootResultRaiderTitleText", "ARTWORK", "GameFontNormal")
	FlootResultMemberTitle.Text:SetText("Members")
	FlootResultMemberTitle.Text:SetPoint("CENTER", FlootResultMemberTitle, "CENTER", 0,0)
	FlootResultMemberTitle:SetHeight(FlootResultMemberTitle.Text:GetHeight() + 31)
	FlootFrameObj["FlootResultMemberTitle"] = FlootResultMemberTitle

	-- Unknown colum
	local FlootResultBackgroundUnknown = CreateFrame("Frame", "FlootResultBackgroundUnknown", FlootFrames:GetFrame("FlootResultFrame"))
	FlootResultBackgroundUnknown:SetBackdrop(FlootFrameBGWhite)
	FlootResultBackgroundUnknown:SetBackdropBorderColor(255/255,153/255,0/255,1)
	FlootResultBackgroundUnknown:SetBackdropColor(0/255,0/255,0/255,0.6) 
	FlootResultBackgroundUnknown:SetPoint("TOPLEFT","FlootResultBackgroundMember","TOPRIGHT", -3, 0)
	FlootResultBackgroundUnknown:SetPoint("BOTTOMLEFT","FlootResultBackgroundMember","BOTTOMLEFT", -3, 0)
	FlootResultBackgroundUnknown:SetWidth(FlootResultBackgroundRaider:GetWidth())
	FlootResultBackgroundUnknown:EnableMouse(true)
	FlootFrameObj["FlootResultBackgroundUnknown"] = FlootResultBackgroundUnknown

	-- Unknown Title
	local FlootResultUnknownTitle = CreateFrame("Frame", "FlootResultUnknownTitle", FlootResultBackgroundUnknown)
	FlootResultUnknownTitle:SetBackdrop(FlootFrameTitle)
	FlootResultUnknownTitle:SetBackdropColor(1,1,1,0.2)
	FlootResultUnknownTitle:SetPoint("TOPLEFT", "FlootResultBackgroundUnknown", "TOPLEFT", 5, -5)
	FlootResultUnknownTitle:SetPoint("TOPRIGHT", "FlootResultBackgroundUnknown", "TOPRIGHT", -5, 5)
	FlootResultUnknownTitle.Text = FlootResultUnknownTitle:CreateFontString("FlootResultUnknownTitleText", "ARTWORK", "GameFontNormal")
	FlootResultUnknownTitle.Text:SetText("Unknown")
	FlootResultUnknownTitle.Text:SetPoint("CENTER", FlootResultUnknownTitle, "CENTER", 0,0)
	FlootResultUnknownTitle:SetHeight(FlootResultUnknownTitle.Text:GetHeight() + 31)
	FlootFrameObj["FlootResultUnknownTitle"] = FlootResultUnknownTitle


end

--------------------------------------------------------
----   Clean up FlootFrame when it is closed      ----
--------------------------------------------------------
function FlootFrames:CleanupFlootFrame()
	for Name,_ in pairs(FlootFrameObj) do
		if (string.find(Name, "FlootTextBox%d+")) then
			local Frame = FlootFrames:GetFrame(Name)
			Frame.Text:SetText("You should never see this")
			Frame:SetScript("OnEnter", function()  end)
			Frame:SetScript("OnLeave", function()  end)
			Frame:Hide()
			FlootFrameObj[Name] = Frame
		elseif (string.find(Name, "FlootMainSpec%d+")) then
			local Button = FlootFrames:GetFrame(Name)
			Button:SetText("Unused")
			Button:SetScript("OnMouseUP", function() Floot:Print("This should never happen. Tell Presco he has an unused button in circulation") end)
			Button:Hide()
			Button["LootInfo"] = nil
			FlootFrameObj[Name] = Button
		elseif (string.find(Name, "FlootOffSpec%d+")) then
			local Button = FlootFrames:GetFrame(Name)
			Button:SetText("Unused")
			Button:SetScript("OnMouseUP", function() Floot:Print("This should never happen. Tell Presco he has an unused button in circulation") end)
			Button:Hide()
			Button["LootInfo"] = nil
			FlootFrameObj[Name] = Button
		end
	end
	FlootFramesRuntime["FlootTextBoxWidth"] = nil
end

--------------------------------------------------------
----   Reset the Result player frames pr player     ----
--------------------------------------------------------
function FlootFrames:CleanupResultFrame()
	for Name,_ in pairs(FlootFrameObj) do
		if (string.find(Name, "FlootResultPlayerFrame%d+")) then
			local Frame = FlootFrames:GetFrame(Name)
			Frame:Hide()
			Frame.Time.Text:SetText("")
			Frame.Roll.Text:SetText("")
			Frame.Name.Text:SetText("")
			Frame.Name["Player"] = nil
		end
	end
	FlootFrameObj["FlootResultFrame"]:SetHeight(FlootFramesRuntime["FlootResultFrameBaseHeight"])
	FlootFrameObj["FlootResultFrame"]:SetWidth(393)
	FlootFrameObj["FlootResultBackgroundUnknown"]:Hide()
	local FlootRuntime = Floot:GetRuntime()
	FlootRuntime["RollStatus"] = "Stopped"
end

--------------------------------------------------------
----    Get the Result player frames pr player      ----
--------------------------------------------------------
function FlootFrames:GetResultPlayerFrame(Index)

	local Frame = FlootFrames:GetFrame("FlootResultPlayerFrame" .. Index)
	if (not Frame) then
		-- Create Text frame for itemlink text
		local FlootFrameBG = {
			tile = true,
			tileSize = 8,
			edgeSize = 12,
			insets = {left = 2, right = 2, top = 2, bottom = 2},
--			bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		}

		Frame = CreateFrame("Frame", "FlootResultPlayerFrame" .. Index, FlootFrames:GetFrame("FlootResultBackgroundRaider"))
		Frame:SetBackdrop(FlootFrameBG)
		Frame:SetBackdropColor(1,1,1,0.5) 
		Frame:SetBackdropBorderColor(35,135,70,1)
		Frame:EnableMouse(true)
		Frame:SetID(Index)
		Frame:SetScript("OnMouseDown", function(...) FlootFrames:FlootResultPlayerDDFrameClicked(...) end)
		Frame:SetScript("OnMouseUP", function()  end)

		-- Roll
		local Roll = CreateFrame("Frame", "FlootResultPlayerRoll" .. Index, Frame)
		Roll:SetPoint("LEFT", Frame, "LEFT", 0, 0)
		Roll.Text = Roll:CreateFontString("FlootResultPlayerRollText" .. Index, "ARTWORK", "GameFontNormalSmall")
		Roll.Text:SetPoint("Center", Roll, "Center", 0, 0)
		Roll.Text:SetJustifyH("LEFT")
		Roll:SetBackdrop(FlootFrameBG)
		Roll:SetBackdropColor(0,0,0,0)
		Roll:SetBackdropBorderColor(0,0,0,0)
		Frame.Roll = Roll

		-- Time Stamp Text Frame
		local Time = CreateFrame("Frame", "FlootResultPlayerTime" .. Index, Frame)
		Time:SetPoint("RIGHT", Frame, "RIGHT", 0, 0)
		Time.Text = Time:CreateFontString("FlootResultPlayerTimeText" .. Index, "ARTWORK", "GameFontNormalSmall")
		Time.Text:SetPoint("Center", Time, "Center", 0, 0)
		Time.Text:SetJustifyH("RIGHT")
		Time:SetBackdrop(FlootFrameBG)
		Time:SetBackdropColor(0,0,0,0)
		Time:SetBackdropBorderColor(0,0,0,0)
		Frame.Time = Time

		-- Name Text Frame
		local Name = CreateFrame("Frame", "FlootResultPlayerName" .. Index, Frame)
		Name:SetPoint("TOPLEFT", Roll, "TOPRIGHT", -3, 0)
		Name:SetPoint("TOPRIGHT", Time, "TOPLEFT", 3, 0)
		Name:SetPoint("BOTTOMLEFT", Roll, "BOTTOMRIGHT", -3, 0)
		Name:SetPoint("BOTTOMRIGHT", Time, "BOTTOMLEFT", 3, 0)
		Name.Text = Name:CreateFontString("FlootResultPlayerNameText" .. Index, "ARTWORK", "GameFontNormal")
		Name.Text:SetPoint("Center", Name, "Center", 0, 0)
		Name.Text:SetJustifyH("CENTER")
		Name:SetBackdrop(FlootFrameBG)
		Name:SetBackdropColor(0,0,0,0)
		Name:SetBackdropBorderColor(0,0,0,0)
		Frame.Name = Name

		FlootFrameObj["FlootResultPlayerFrame" .. Index] = Frame
	end
	return Frame
end

--------------------------------------------------------
----          Update Result window                   ---
--------------------------------------------------------
function FlootFrames:PopulateResultWindow(FlootCurrentRolls)

	local FlootRaiderFrameNumber = 0  -- used to check if it's the first frame, and decide the height of the FlootResult window
	local FlootMemberFrameNumber = 0  
	local FlootUnknownFrameNumber = 0 
	local LastRaiderFrame = "fubar"  -- Keep track of the last frame used, so I can attach it to the right place
	local LastMemberFrame = "fubar"
	local LastUnknownFrame = "fubar"

	for i=1, #FlootCurrentRolls do
		Frame = FlootFrames:GetResultPlayerFrame(i)   -- Get the Frame
		if (string.sub(FlootCurrentRolls[i]["Index"],1,1) == "1") then -- This is a raider
			FlootRaiderFrameNumber = FlootRaiderFrameNumber + 1  -- Increment Frame Number for calculating Height and SetPoint
			if (FlootRaiderFrameNumber == 1) then
				Frame:SetPoint("TOPLEFT", FlootFrames:GetFrame("FlootResultRaiderTitle"), "BOTTOMLEFT", 0, -5)
				Frame:SetPoint("TOPRIGHT", FlootFrames:GetFrame("FlootResultRaiderTitle"), "BOTTOMRIGHT", 0, -5)
				LastRaiderFrame = "FlootResultPlayerFrame" .. i
			else
				Frame:SetPoint("TOPLEFT", FlootFrames:GetFrame(LastRaiderFrame), "BOTTOMLEFT", 0, 2)
				Frame:SetPoint("TOPRIGHT", FlootFrames:GetFrame(LastRaiderFrame), "BOTTOMRIGHT", 0, 2)
				LastRaiderFrame = "FlootResultPlayerFrame" .. i
			end
		elseif (string.sub(FlootCurrentRolls[i]["Index"],1,1) == "2") then -- This is a member / Initiates
			FlootMemberFrameNumber = FlootMemberFrameNumber + 1
			if (FlootMemberFrameNumber == 1) then
				Frame:SetPoint("TOPLEFT", FlootFrames:GetFrame("FlootResultMemberTitle"), "BOTTOMLEFT", 0, -5)
				Frame:SetPoint("TOPRIGHT", FlootFrames:GetFrame("FlootResultMemberTitle"), "BOTTOMRIGHT", 0, -5)
				LastMemberFrame = "FlootResultPlayerFrame" .. i
			else
				Frame:SetPoint("TOPLEFT", FlootFrames:GetFrame(LastMemberFrame), "BOTTOMLEFT", 0, 2)
				Frame:SetPoint("TOPRIGHT", FlootFrames:GetFrame(LastMemberFrame), "BOTTOMRIGHT", 0, 2)
				LastMemberFrame = "FlootResultPlayerFrame" .. i
			end
		elseif (string.sub(FlootCurrentRolls[i]["Index"],1,1) == "3") then -- This is not a guild member
			FlootUnknownFrameNumber = FlootUnknownFrameNumber + 1
			if (FlootUnknownFrameNumber == 1) then
				Frame:SetPoint("TOPLEFT", FlootFrames:GetFrame("FlootResultUnknownTitle"), "BOTTOMLEFT", 0, -5)
				Frame:SetPoint("TOPRIGHT", FlootFrames:GetFrame("FlootResultUnknownTitle"), "BOTTOMRIGHT", 0, -5)
				LastUnknownFrame = "FlootResultPlayerFrame" .. i
			else
				Frame:SetPoint("TOPLEFT", FlootFrames:GetFrame(LastUnknownFrame), "BOTTOMLEFT", 0, 2)
				Frame:SetPoint("TOPRIGHT", FlootFrames:GetFrame(LastUnknownFrame), "BOTTOMRIGHT", 0, 2)
				LastUnknownFrame = "FlootResultPlayerFrame" .. i
			end

		end

		-- Set the background color according to if the armortype match or not.
		if (FlootCurrentRolls[i]["ArmorTypeMatch"] == "8") then
			Frame:SetBackdropColor(0,255/255,0,0.4)
		else
			Frame:SetBackdropColor(0,0,0,0.1)
		end
		Frame:SetBackdropBorderColor(1,1,1,0.4)

		-- Set the position and text of the 2 text frames
		Frame.Roll.Text:SetText(FlootCurrentRolls[i]["Roll"])
		local COLOR = Floot:GetTextColor("Name", FlootCurrentRolls[i]["Name"])
		Frame.Name.Text:SetText(COLOR .. FlootCurrentRolls[i]["Name"])
		Frame.Name["Player"] = FlootCurrentRolls[i]["Name"]

		if (FlootCurrentRolls[i]["WinnerListNumber"] == "000") then
			Frame.Time.Text:SetText("")
		else
			Frame.Time.Text:SetText(FlootCurrentRolls[i]["WinnerListNumber"])
		end
		
		Frame:SetHeight(Frame.Name.Text:GetHeight() +16)
		Frame.Roll:SetHeight(Frame:GetHeight())
		Frame.Roll:SetWidth(30)
		Frame.Name:SetHeight(Frame:GetHeight())
		Frame.Time:SetWidth(25)
		Frame.Time:SetHeight(Frame:GetHeight())

		-- Find the height of the FlootResultFrame
		local FlootResultHeightBase = FlootFramesRuntime["FlootResultFrameBaseHeight"]
		local DecidingFrame = 0
		if ( (FlootRaiderFrameNumber > FlootMemberFrameNumber) or (FlootRaiderFrameNumber > FlootUnknownFrameNumber) ) then
			DecidingFrame = FlootRaiderFrameNumber
		end

		if ( FlootMemberFrameNumber > DecidingFrame ) then
			DecidingFrame = FlootMemberFrameNumber
		end

		if ( FlootUnknownFrameNumber > DecidingFrame ) then
			DecidingFrame = FlootUnknownFrameNumber
		end

		FlootFrameObj["FlootResultFrame"]:SetHeight(FlootResultHeightBase + (DecidingFrame * (Frame:GetHeight() + 1) ) )

		-- Adjust the width to match if the unkown colum is shown or not.
		if (FlootUnknownFrameNumber > 0) then
			FlootFrameObj["FlootResultFrame"]:SetWidth(560)
			FlootFrameObj["FlootResultBackgroundUnknown"]:Show()
		else
			FlootFrameObj["FlootResultFrame"]:SetWidth(394)
			FlootFrameObj["FlootResultBackgroundUnknown"]:Hide()
		end

		Frame:Show()
	end

end

--------------------------------------------------------
----      Create the player dropdown frame          ----
--------------------------------------------------------
function FlootFrames:CreateResultPlayerReasignDDFrame()
	local Frame = CreateFrame("Frame", "FlootResultPlayerDDFrame", UIParent, "UIDropDownMenuTemplate")
	Frame:SetFrameStrata("FULLSCREEN_DIALOG")
	FlootFrameObj["FlootResultPlayerDDFrame"] = Frame
end

--------------------------------------------------------
----      Generate Player Dropdown frame layout     ----
--------------------------------------------------------
function FlootInitPlayerDDFrame(Level, arg1, Name)

	if (UIDROPDOWNMENU_MENU_VALUE == nil) then
		-- Cleanup from previous dropdown display
		DropDownTable.func = nil
		DropDownTable.checked = nil
		DropDownTable.value = nil
		DropDownTable.hasArrow = nil

		if (Name) then -- Workaround as this is initialized at startup and I don't have a name.
			DropDownTable.text = "Award to " .. Floot:GetTextColor("Name",Name) .. Name
		else
			DropDownTable.text = "Award Item"
		end

		DropDownTable.isTitle = nil
		DropDownTable.hasArrow = nil
		DropDownTable.value = nil
		function DropDownTable.func()
			Floot:AwardItem(Name)
		end
		UIDropDownMenu_AddButton(DropDownTable)

	end

end

--------------------------------------------------------
----  Show the popup menu when a player is clicked  ----
----  on in FlootResultPlayerFrame                ----       
--------------------------------------------------------
function FlootFrames:FlootResultPlayerDDFrameClicked(this)
	local Frame = FlootFrames:GetFrame("FlootResultPlayerDDFrame")
	ToggleDropDownMenu(1, nil, Frame, this, this:GetWidth() , this:GetHeight(), this.Name["Player"])
end


--------------------------------------------------------
----   Populate the ML popup choices at raid setup  ----
--------------------------------------------------------
function FlootFrames:PopulateMLChoiseFrame()
	local FlootRuntime = Floot:GetRuntime()
	local MLCandidates = FlootRuntime["MLCandidates"]
	local Index = 1
	for Foo,Name in pairs(MLCandidates) do
		FlootFrames:CreateMLChoiseNameButton(Index,Name)
		Index = Index + 1
	end
--	_G["InterfaceOptionsFrame"]:Hide()
--	_G["GameMenuFrame"]:Hide()
	FlootFrameObj["FlootChooseML"]:Show()
end

--------------------------------------------------------
----     Create the buttons for choosing the ML     ----
--------------------------------------------------------
function FlootFrames:CreateMLChoiseNameButton(Index,Name)
	if (Index < 11) then
		
		local MLChoiseButton = CreateFrame("Button", "FlootMLChoiseButton" .. Index, FlootFrames:GetFrame("FlootChooseML"), "UIPanelButtonTemplate")
--		MLChoiseButton:SetPoint("TOPLEFT", "FlootChooseML", "TOPLEFT", 30, -25)
		MLChoiseButton:SetText(Name)
		MLChoiseButton:SetWidth(135)
		MLChoiseButton:SetHeight(25)
		MLChoiseButton:SetScript("OnMouseUp", function() Floot_ConfigDb["MasterLooter"] = Floot:FormatName(Name); Floot:RaidSetup(); FlootFrameObj["FlootChooseML"]:Hide() end)
		MLChoiseButton:SetScript("OnMouseDown", function()  end)
		FlootFrameObj["FlootMLChoiseButton" .. Index] = MLChoiseButton

		if (Index == 1) then
			MLChoiseButton:SetPoint("TOPLEFT", "FlootChooseML", "TOPLEFT", 13.5, -25)
		else
			local Offset = Index * 25
			MLChoiseButton:SetPoint("TOPLEFT", "FlootChooseML", "TOPLEFT", 13.5, -Offset)
		end
	end
	FlootChooseML = FlootFrames:GetFrame("FlootChooseML")
	local BaseHeight = 65
	local Multiplier = Index - 1
	local Height = BaseHeight + ( 25 * Multiplier)
	FlootChooseML:SetHeight(Height)

end

----------------------------------
-- Used to get the frame class ---
----------------------------------
function Floot:NewFlootFrames()
   return FlootFrames
end

----------------------------
--- Get the Frame object ---
----------------------------
function FlootFrames:GetFrame(name)
   return FlootFrameObj[name]
end

