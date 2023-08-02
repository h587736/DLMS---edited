----------------------------------------------------------
-- Dynamic Loot Management System (DLMS)			--
--	A Loot AddOn for World of Warcraft					--
--														--			
-- 	Written by Auz @ Eitrigg        					--
-- 	Email: auz.addons@gmail.com							--
--     													--
-- WowInterface.com Portal:             				--
--   http://www.wowinterface.com/portal.php?&uid=315562 --
----------------------------------------------------------

DLMS_VERSION = GetAddOnMetadata("DLMS", "Version") --"v2.1.3"

----------------------
-- Saved Variables 	-- 
svdDB = {}				
svOptionsDB	= {}	
sv_white_list = {}	
sv_black_list = {}	
sv_safe_list = {}		
sv_ignore_list = {}	
----------------------
-- Working Tables --
loot_white_list = {}
loot_black_list = {}
autosell_safe_list = {}
autosell_ignore_list = {}

SLASH_DLMS1, SLASH_DLMS2 = "/dlms", "/DLMS"

local DLMS_OPTIONS_OPEN 	= 567422 --"Sound/Interface/uCharacterSheetTab.ogg"
local DLMS_OPTIONS_CLOSE 	= 567422 --"Sound/Interface/uCharacterSheetTab.ogg"
local DLMS_ICON_ALERT		= "Interface/DialogFrame/UI-Dialog-Icon-AlertNew"
local DLMS_IND_GREEN		= "Interface/COMMON/Indicator-Green" --
local DLMS_IND_RED			= "Interface/COMMON/Indicator-Red"
local DLMS_IND_YELLOW		= "Interface/COMMON/Help-i" --Indicator-Yellow
local DLMS_ANI_TEX			= "Interface/UNITPOWERBARALT/Atramedes_Circular_Flash"
local DLMS_BTN_TEX			= "Interface/UNITPOWERBARALT/Ice_Circular_Frame" --Atramedes_Circular_FrameFire_Circular_Frame
local DLMS_GOLD_TEX			= "\124TInterface/MoneyFrame/UI-GoldIcon:12:12:2:0\124t"
local DLMS_SILVER_TEX		= "\124TInterface/MoneyFrame/UI-SilverIcon:12:12:2:0\124t"
local DLMS_COPPER_TEX		= "\124TInterface/MoneyFrame/UI-CopperIcon:12:12:2:0\124t"
local DLMS_CACHE_DELAY 		= .5
local DLMS_PREFETCH 		= 25

DLMS_COLOR_1 				= "|cFFaa55cc"
DLMS_COLOR_2				= "|cFFffff00"
DLMS_COLOR_3				= "|cFFcc0000"
DLMS_COLOR_4				= "|cFF00cc00"
DLMS_COLOR_Junk				= "|cFF9d9d9d"
DLMS_COLOR_Common			= "|cFFffffff"
DLMS_COLOR_Uncommon			= "|cFF1eff00"
DLMS_COLOR_Rare				= "|cFF0070dd"
DLMS_COLOR_Epic				= "|cFFa335ee"
DLMS_COLOR_Lengendary		= "|cFFff8000"
DLMS_COLOR_Disable			= "|cFF555555"
DLMS_COLOR_Enable			= "|cFF00ff00"

local function DLMS_COLOR(s,c)
	s = s.."|r"
	if(_G["DLMS_COLOR_"..c]) then
		return _G["DLMS_COLOR_"..c]..s
	end
	return c..s
end

local function GetItemID(link)
   local linkType,itemID = string.match(link, ".*|H(%l+):(%d+):.*")   
   return linkType, itemID or false
end

local DLMS_HEADER 		= DLMS_COLOR("DLMS: ",1)
local DLMS_MONEY_MSG_1 	= DLMS_HEADER..DLMS_COLOR("Picked up: ",2)
local DLMS_MONEY_MSG_2 	= DLMS_HEADER..DLMS_COLOR("Received your share: ",2)
local DLMS_LOOT_MSG 	= DLMS_HEADER..DLMS_COLOR("Looted: ",2)

local DLMS_CreateFrame = CreateFrame
local CreateFontString = CreateFontString
local next,print,tinsert,tremove,gsub,strsub,strsplit = next,print,tinsert,tremove,gsub,strsub,strsplit

-- Create our static objects --
local DLMS_Loot_Options = {}
DLMS_Loot_Options.panel = DLMS_CreateFrame("Frame", "DLMS_Options_Panel", nil)
DLMS_Options = DLMS_Loot_Options.panel -- 568h x 623w
DLMS_Options.name = "DLMS"
DLMS_Options:SetSize(623,568)
DLMS_Options:SetMovable(true)
DLMS_Options:SetUserPlaced(true)
DLMS_Options:Hide()

-- de/select buttons --
local select_all_button = DLMS_CreateFrame("Button", "select_all", nil, "UIPanelButtonTemplate")
local deselect_all_button = DLMS_CreateFrame("Button", "deselect_all", nil, "UIPanelButtonTemplate")

local auto_sell_btn = DLMS_CreateFrame("Button", "auto_sell", nil, "UIPanelButtonTemplate")

-- Autosell, Value & Quality Sliders --
local lbvSlider = DLMS_CreateFrame("Slider", "LBV_Slider", nil, "OptionsSliderTemplate")
local lbqSlider = DLMS_CreateFrame("Slider", "LBQ_Slider", nil, "OptionsSliderTemplate")
local asrSlider = DLMS_CreateFrame("Slider", "ASR_Slider", nil, "OptionsSliderTemplate")

local cached = false

-- The Dr. Suess of all functions! --
local function Update_List(sw, ilinks, this_list)

	local which_list = ""
	local that_list = ""
	local its_list = ""
	local itemIDs = {}
	local link_tbl = {}
	
	if(this_list == loot_black_list) then
		which_list = "Loot Black List"
		its_list = "Loot White List"
		that_list = loot_white_list
	elseif(this_list == loot_white_list) then
		which_list = "Loot White List"
		its_list = "Loot Black List"
		that_list = loot_black_list
	elseif(this_list == autosell_safe_list) then
		which_list = "Autosell Safe List"
		its_list = "Autosell Ignore List"
		that_list = autosell_ignore_list
	elseif(this_list == autosell_ignore_list) then
		which_list = "Autosell Ignore List"
		its_list = "Autosell Safe List"
		that_list = autosell_safe_list
	end
	
	local LIST_HEADER = DLMS_HEADER..DLMS_COLOR(which_list..": ",2)
	
	if(ilinks ~= nil) then
		for k,v in pairs(ilinks) do
			local l_type, i_id = GetItemID(ilinks[k])
			if(l_type == "item") then
				tinsert(itemIDs, 1, i_id)
			else
				print(LIST_HEADER..ilinks[k].." Not Added, \""..DLMS_COLOR("link type",2).."\" is a \""..DLMS_COLOR(l_type,2).."\"")
			end
		end
	end
	
	if(sw == "add") then
		if(itemIDs ~= nil) then
			for k,v in pairs(itemIDs) do
				if(tContains(this_list, v)) then
					print(LIST_HEADER..ilinks[k].." already exists.") 
				else
					if(tContains(that_list, v)) then
						link_tbl = { ilinks[k] }
						print(LIST_HEADER.."\"Add\": "..ilinks[k].." already exists in \""..
							DLMS_COLOR(strlower(its_list),2).."\". Removing item from that list before adding item to this list.")
						Update_List("remove", link_tbl, that_list)
					end
					print(LIST_HEADER..ilinks[k].." has been added.")
					tinsert(this_list, 1, v)
					link_tbl = nil
				end
			end
		else
			print(LIST_HEADER.." You need to specify at least one item to \""..DLMS_COLOR("add",2).."\"")
		end
	elseif(sw == "remove") then
		if(itemIDs ~= nil) then
			for k,v in pairs(itemIDs) do
				if(tContains(this_list, v)) then
					for k2,v2 in pairs(this_list) do
						if(v == v2) then
							print(LIST_HEADER..ilinks[k].." has been removed.")
							tremove(this_list, k2)
						end
					end
				else print(LIST_HEADER..ilinks[k].." does not exist.") end
			end
		else
			print(LIST_HEADER.."You need to specify at least one item to \""..DLMS_COLOR("remove",2)..".")
		end
	else
		if(next(this_list) ~= nil) then
			if(cached) then
				local tag = ""
				if(string.find(LIST_HEADER, "Safe")) then tag = "as_safe" end
				if(string.find(LIST_HEADER, "Ignore")) then tag = "as_ignore" end
				if(string.find(LIST_HEADER, "White")) then tag = "w_list" end
				if(string.find(LIST_HEADER, "Black")) then tag = "b_list" end
				print(LIST_HEADER.."Listing "..DLMS_COLOR(#this_list,2).." items...")
				print(" - To remove an item, use: "..DLMS_COLOR("/dlms "..tag.." remove",2).." and "..
					DLMS_COLOR("<shift+LClick>",2).." an "..DLMS_COLOR("item(s)",2).." in the list.")
				for k,v in pairs(this_list) do
					if(v == nil) then
						tremove(this_list, k)
					else
						--print(v.." before GetItemInfo(v)")
						v = select(2, GetItemInfo(v))
						--print(tostring(v).." after GetItemInfo(v)")
					end
					print(DLMS_COLOR(" - Item "..k..": ",2)..tostring(v))
				end
			else
				print(DLMS_HEADER.." Not finished caching this list...")
			end
		else print(LIST_HEADER.."is currently empty.") end
	end
	ilinks = nil
	inames = nil
end

-- Scrolling list setup --
local spacing = 1
local maxValue = 0
local step = 25
local header_txt = nil

local listframe = DLMS_CreateFrame("Frame", "Scroller", UIParent) 
local scrollframe = DLMS_CreateFrame("ScrollFrame", "scroll_frame", listframe)
local scrollbar = DLMS_CreateFrame("Slider", "scroll_bar", scrollframe, "UIPanelScrollBarTemplate")
local content = DLMS_CreateFrame("Frame", "content_container", scrollframe)

local header = listframe:CreateFontString()
header:SetFont("Fonts\\FRIZQT__.TTF", 16) -- Fonts\\ARIALN.TTF - Fonts\\SKURRI.TTF -  -
header:SetPoint("TOPLEFT", listframe, 10, -10)

local deleted_windows = {}
local function clear_content(self)
	for i=1, self:GetNumChildren() do
	
		local child = select(i, self:GetChildren())
		
		-- Saving a reference to our previous child frame so that we can reuse it later
		if(not tContains(deleted_windows, child)) then 
			tinsert(deleted_windows, child) 
		end
		
		child:Hide()
	end
end

local current_list = nil

local function update_content()
		
	clear_content(content)
	
	local items = 0
	local point = -2
	local alt_color = false
	maxValue = 0
	
	if(current_list == autosell_safe_list) then
		header_txt = "Autosell Safe List"
		current_list = autosell_safe_list
	elseif(current_list == autosell_ignore_list) then
		header_txt = "Autosell Ignore List"
		current_list = autosell_ignore_list
	elseif(current_list == loot_white_list) then
		header_txt = "Loot White List"
		current_list = loot_white_list
	elseif(current_list == loot_black_list) then
		header_txt = "Loot Black List"
		current_list = loot_black_list
	end
	
	header:SetText(DLMS_COLOR(header_txt.." ("..#current_list.." items)",2))
	
	scrollframe.content = nil
	if(next(current_list) ~= nil) then
		for _,itemID in pairs(current_list) do
			local link = select(2, GetItemInfo(itemID))
			if(link) then
				
				local name = "frame_"..itemID
				local f, tex = nil, nil
				local reusing = false
				
				-- attempting to reuse a previous child frame if it exists 
				-- (which should include the previously created fontstring and button)
				if(next(deleted_windows) ~= nil) then
					for i=1, #deleted_windows do
						if(name == deleted_windows[i]:GetName()) then
							f = deleted_windows[i]
							reusing = true
						end
					end
				end
				
				if(not resuing) then
					f = DLMS_CreateFrame("Frame", "frame_"..itemID, content)
					
					tex = f:CreateTexture(nil, "BACKGROUND")
					tex:SetAllPoints()
					
					local t = f:CreateFontString()
					t:SetFont("Fonts\\FRIZQT__.TTF", 14, "THIN")
					t:SetText(link.." (id: "..itemID..")")
					t:SetPoint("TOPLEFT", f, 2, -5)
					
					local b = DLMS_CreateFrame("Button", "btn_"..itemID, f)
					b:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
					b:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
					b:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
					b:SetDisabledTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled")
					b:SetSize(32,32)
					b:SetPoint("TOPRIGHT", 5,4)
					
					b:SetScript("OnClick",
						function(self)
							f:Hide()
							local tmp_tbl = {}
							tinsert(tmp_tbl, link)
							Update_List("remove", tmp_tbl, current_list)
							update_content()
							tmp_tbl = nil
						end
					)
					
					f:SetScript("OnEnter", 
						function(self)
							GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
							GameTooltip:SetItemByID(itemID)
							GameTooltip:Show()
						end
					)

					f:SetScript("OnLeave", 
						function(self)
							GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
							GameTooltip:Hide()
						end
					)
					
				end
				
				-- even if we are reusing, it may not be in the same order
				f:SetSize(scrollframe:GetWidth(), 24)
				f:ClearAllPoints()
				f:SetPoint("TOPLEFT", content, 0, point)
				
				-- also may not have the same colour
				if(alt_color) then
					tex:SetColorTexture(1, 1, 1, 0.0)
					alt_color = false
				else 
					tex:SetColorTexture(1, 1, 1, 0.05)
					alt_color = true
				end
												
				items = items+1
				point = point - (f:GetHeight()+spacing) 
				
				maxValue = maxValue + (f:GetHeight()+spacing)

				f:Show() -- forcing a show since if we are reusing, the old child was previously hidden
			end												
		end													
	end 
	
	if(items == 0) then listframe:Hide(); print(DLMS_HEADER.."List is now empty...") end
	
	if((maxValue-scrollframe:GetHeight()) < 0) then
		scrollbar:Disable()
		maxValue = 0
	else 
		scrollbar:Enable()
		maxValue = (maxValue-scrollframe:GetHeight())
	end
	
	content:SetSize(scrollframe:GetWidth(), scrollframe:GetHeight())
	scrollbar:SetMinMaxValues(0, maxValue)
	scrollframe.content = content
	scrollframe:SetScrollChild(content)

end

local function UpdateScrollValue(self, delta)
	if(delta == 1 and scrollbar:GetValue() >= 0) then
		if(scrollbar:GetValue()-step < 0) then
			scrollbar:SetValue(0)
		else scrollbar:SetValue(scrollbar:GetValue() - step) end
	elseif(delta == -1 and scrollbar:GetValue() < maxValue) then
		if(scrollbar:GetValue()+step > maxValue) then
			scrollbar:SetValue(maxValue)
		else scrollbar:SetValue(scrollbar:GetValue() + step) end
	end
end

-- Create the listframe frame
local listframe = DLMS_CreateFrame("Frame", "DIALOG", UIParent, "BackdropTemplate")
listframe:SetFrameStrata('DIALOG')
listframe:SetToplevel(true)
listframe:SetSize(400, 225)
listframe:SetPoint("TOPLEFT", 25, -25)
listframe:EnableMouse(true)
listframe:EnableMouseWheel(true)
listframe:SetMovable(true)

-- Define the backdrop table
local backdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 5, bottom = 3 }
}

-- Apply the backdrop to listframe
listframe:SetBackdrop(backdrop)

-- Register for drag functionality
listframe:RegisterForDrag("LeftButton")



local l = listframe:CreateLine()
l:SetColorTexture(1,1,1,0.5)
l:SetThickness(1)
l:SetStartPoint("TOPLEFT",10,-30)
l:SetEndPoint("TOPRIGHT",-10,-30)

local close_button = DLMS_CreateFrame("Button", nil, listframe, "UIPanelCloseButton")
close_button:ClearAllPoints()
close_button:SetPoint("TOPRIGHT", 0, -1)

scrollframe:SetPoint("TOPLEFT", 10, -35)
scrollframe:SetPoint("BOTTOMRIGHT", -25, 8) 

scrollbar:SetPoint("TOPLEFT", listframe, "TOPRIGHT", -22, -53) 
scrollbar:SetPoint("BOTTOMLEFT", listframe, "BOTTOMRIGHT", 22, 22) 
scrollbar:SetMinMaxValues(0,100)
scrollbar:SetWidth(16)
scrollbar:SetValue(0)
scrollbar:SetValueStep(step) 
scrollbar.scrollStep = step

scrollbar:SetScript("OnValueChanged", 
	function (self, value) 
		self:GetParent():SetVerticalScroll(value) 
	end
) 
	
listframe.scrollframe = scrollframe 
listframe.scrollbar = scrollbar

listframe:SetScript("OnMouseWheel", UpdateScrollValue)
listframe:SetScript("OnDragStart", function(self) self:StartMoving() end)
listframe:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
listframe:SetScript("OnShow", function(self) update_content() end)
listframe:Hide()

-- Backdrop table for Static Options Panels ----
local backdrop = {
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 16,
  insets = { left = 3, right = 3, top = 5, bottom = 3 }
}
------------------------------------------
-- divider backdrop for catagory panel dividers --
local divider = {
  bgFile = "Interface\\ChatFrame\\ChatFrameBackground",  
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 1,
  edgeSize = 2,
  insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

local QualityStrings = {
	[0] = "Junk",
	[1] = "Common",
	[2] = "Uncommon",
	[3] = "Rare",
	[4] = "Epic",
	[5] = "Legendary",
}
-- Close button --
local oClose = DLMS_CreateFrame("Button", "Close_Button", DLMS_Options) --, "UIPanelButtonTemplate"
oClose:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
oClose:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
oClose:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight") -- "BLEND"
oClose:SetDisabledTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled")
oClose.tooltip = "Close the options window."
oClose:SetPoint("TOPRIGHT", 0,0)
oClose:SetSize(32,32)
oClose:Show()

-- Float Options Button --
local oFloat = DLMS_CreateFrame("Button", "Float_Button", DLMS_Options) -- , "UIPanelButtonTemplate"
oFloat:SetNormalTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Up")
oFloat:SetPushedTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Down")
oFloat:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight") -- "BLEND"
oFloat:SetDisabledTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Disabled")
oFloat.tooltip = "Detach and float the options window."
oFloat:SetPoint("TOPRIGHT", -20,0)
oFloat:SetSize(32,32)
oFloat:Show()

-- The Animated DLMS Button... its for clicking on --
local DLMS_Button = DLMS_CreateFrame("Frame", "DLMS_Button_Frame", UIParent)

local DLMS_Btn_Tex2 = DLMS_Button:CreateTexture()

	DLMS_Btn_Tex2:SetAllPoints()
	DLMS_Btn_Tex2:SetDrawLayer("BACKGROUND", 2)
	DLMS_Btn_Tex2:SetBlendMode("ADD")
	DLMS_Btn_Tex2:SetTexture(DLMS_ANI_TEX) --Arcane_Circular_Flash

	local DLMS_Btn_Anim_AG1 = DLMS_Btn_Tex2:CreateAnimationGroup()
		DLMS_Btn_Anim_AG1:SetLooping("REPEAT")

	local DLMS_Btn_Anim_AG1_A1 = DLMS_Btn_Anim_AG1:CreateAnimation("Rotation")
		DLMS_Btn_Anim_AG1_A1:SetDegrees(360)
		DLMS_Btn_Anim_AG1_A1:SetDuration(4)
		DLMS_Btn_Anim_AG1_A1:SetSmoothing("NONE")

local DLMS_Btn_Tex3 = DLMS_Button:CreateTexture()
	DLMS_Btn_Tex3:SetAllPoints()
	DLMS_Btn_Tex3:SetDrawLayer("BACKGROUND", 3)
	DLMS_Btn_Tex3:SetBlendMode("ADD")
	DLMS_Btn_Tex3:SetTexture(DLMS_ANI_TEX) --Arcane_Circular_Flash

	local DLMS_Btn_Anim_AG2 = DLMS_Btn_Tex3:CreateAnimationGroup()
		DLMS_Btn_Anim_AG2:SetLooping("REPEAT")

	local DLMS_Btn_Anim_AG2_A1 = DLMS_Btn_Anim_AG2:CreateAnimation("Rotation")
		DLMS_Btn_Anim_AG2_A1:SetDegrees(-360)
		DLMS_Btn_Anim_AG2_A1:SetDuration(5)
		DLMS_Btn_Anim_AG2_A1:SetSmoothing("NONE")

local DLMS_Btn_Tex4 = DLMS_Button:CreateTexture()
	DLMS_Btn_Tex4:SetDrawLayer("BACKGROUND", 4)
	DLMS_Btn_Tex4:SetSize(60,60)
	DLMS_Btn_Tex4:SetPoint("CENTER", DLMS_Button,"CENTER", 0, -1)
	DLMS_Btn_Tex4:SetTexture(DLMS_IND_GREEN) --Interface\\RAIDFRAME\\ReadyCheck-ReadyInterface\\ICONS\\INV_Misc_Bag_EnchantedMageweave

local DLMS_Info_Tex = DLMS_Button:CreateTexture()
	DLMS_Info_Tex:SetDrawLayer("BACKGROUND", 5)
	DLMS_Info_Tex:SetSize(80,80)
	DLMS_Info_Tex:SetPoint("CENTER", DLMS_Button,"CENTER", .5, -0.5)
	DLMS_Info_Tex:SetTexture(DLMS_IND_YELLOW) --Interface\\RAIDFRAME\\ReadyCheck-ReadyInterface\\ICONS\\INV_Misc_Bag_EnchantedMageweave
	DLMS_Info_Tex:Hide()
	
local DLMS_Btn_Tex5 = DLMS_Button:CreateTexture()
	DLMS_Btn_Tex5:SetAllPoints()
	DLMS_Btn_Tex5:SetDrawLayer("ARTWORK", 5)
	DLMS_Btn_Tex5:SetTexture(DLMS_BTN_TEX) --MetalBronze_Circular_FrameHorde_Circular_FrameWowUI_Circular_Frame  


-- need to relocate and only 
-- play if the button is visible..
DLMS_Btn_Anim_AG1:Play()
DLMS_Btn_Anim_AG2:Play()

local asr = DLMS_Button:CreateTexture()
asr:SetDrawLayer("ARTWORK", 6)
asr:SetSize(20,20)
asr:SetPoint("CENTER", DLMS_Button, "CENTER" , 0, 2)
asr:SetTexture(DLMS_ICON_ALERT)
asr:Hide()

local lr = DLMS_Button:CreateTexture()
lr:SetDrawLayer("ARTWORK", 6)
--lr:SetVertexColor(1,.2,.2) -- AutoRoll Dice Vertex Colors U(.2,1,.2) R(.4,.4,1) P(1,.2,.2)
lr:SetSize(20,20)
lr:SetPoint("TOPLEFT", DLMS_Button , 12, -12)
lr:SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Dice-Up")
lr:Hide()

local fs_Slots = DLMS_Button:CreateFontString("bagFill_fs_Slots")
fs_Slots:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE") --Interface\\AddOns\\DLMS\\res\\fonts\\ariblk.ttfFonts\\MORPHEUS.TTFFonts\\ARIALN.TTFFonts\\SKURRI.TTF -  -
fs_Slots:SetPoint("TOPRIGHT", 0,-10)

DLMS_Button:SetSize(78,78)
DLMS_Button:SetScale(1.0)
DLMS_Button:SetPoint("CENTER",0,0)
DLMS_Button:SetClampedToScreen(true)
DLMS_Button:EnableMouse(true)
DLMS_Button:SetMovable(true)
DLMS_Button:SetUserPlaced(true)

local DLMS_Money_Frame = DLMS_CreateFrame("Frame", "DLMSMoney", DLMS_Button, nil)
DLMS_Money_Frame:SetPoint("BOTTOM", DLMS_Button, 20,-15)
DLMS_Money_Frame:SetFrameLevel(1)
DLMS_Money_Frame:SetSize(170, 25)
DLMS_Money_Frame:SetScale(.60)

local Money_Frame_FS = DLMS_Money_Frame:CreateFontString()
Money_Frame_FS:SetFont("Fonts\\ARIALN.TTF", 24, "OUTLINE") --Fonts\\FRIZQT__.TTFFonts\\SKURRI.TTF -  -
Money_Frame_FS:SetPoint("CENTER", DLMS_Money_Frame, -15,30)

local DLMS_Frame = DLMS_CreateFrame("Frame", nil, UIParent)

DLMS_Frame:RegisterEvent("VARIABLES_LOADED")
DLMS_Frame:RegisterEvent("ADDON_LOADED")
DLMS_Frame:RegisterEvent("PLAYER_LOGOUT")
DLMS_Frame:RegisterEvent("LOOT_OPENED")
DLMS_Frame:RegisterEvent("MERCHANT_SHOW")
DLMS_Frame:RegisterEvent("MERCHANT_CLOSED")
DLMS_Frame:RegisterEvent("START_LOOT_ROLL")
DLMS_Frame:RegisterEvent("CONFIRM_LOOT_ROLL")
DLMS_Frame:RegisterEvent("BAG_UPDATE")

local default = true
local isButtonOne = true
local IsEmpty = false
local newItem = false
local newLoot = false
local AutoRoll = true
local alreadyInRaid = false
local lowBagSpace = false
local Bags_Full = false
local options_loaded = false
local auto_delete_junk = false


local RollID = nil
local Roll   = 2
local notLootedCount = 1
local r = 0
local g = 1

-- locals --
local OptionsDB = {}
local DLMS = {}
local bNameTable = {}
local bpNameTable = {}
local bpcbNameTable = {}
local stcbNameTable = {}
local CatLinkTable = {}
local notLooted = {}
local ItemRollIDs = {}
local world = select(3,GetNetStats())

-- Sellable Items Related
local ikey = 0
local SellableItems = {}
-------------------------------------

-- Storage for option defaults --
local oDefaultsDB = {
	enabled = true,
	ASR = 1,
	LBC = false,
	LBV = false,
	LBQ = false,
	ASJ = true,
	ARG = true,
	LAG = true,
	ARL = false,
	ARB = false,
	UWM = false,
	KLO = false,
	ISQ = false,
	DIR = false,
	EDB = true,
	ELC = true,
	SNL = true,
	
	-- Button Options --
	SBB = true,
	SBS = true,
	SBV = false,
	FAD = false,
	TRN = 1.0,
	LOC = false,
	SCL = 1.0
}
---------------------------------
-- Static Labels --
local Static_Label_Table = {
	["DLMSPanel_Title_Label"] = {
		["Name"]					= "Title",
		["Text_Size"] 				= 24,
		["R"]						= 1.0,
		["G"]						= 1.0,
		["B"]						= 0.0,
		["A"]						= 0.8,
		["Point"]					= "TOPLEFT",
		["x"]						= 10,
		["y"]						= -10,
		["Text"]					= "Dynamic Loot Management System",
	},
	["DLMSPanel_Version_Label"] = {
		["Name"]					= "Version",
		["Text_Size"] 				= 13,
		["R"]						= 0.0,
		["G"]						= 0.6,
		["B"]						= 1.0,
		["A"]						= 0.8,
		["Point"]					= "TOPLEFT",
		["x"]						= 35,
		["y"]						= -33,
		["Text"]					= DLMS_VERSION.." by \124cFFFF7D0AAuz\124r (Eitrigg)",
	},
	["DLMSPanel_Options_Label"] = {
		["Name"]					= "Options",
		["Text_Size"] 				= 16,
		["R"]						= 1.0,
		["G"]						= 1.0,
		["B"]						= 0.0,
		["A"]						= 0.8,
		["Point"]					= "TOPLEFT",
		["x"]						= 16,
		["y"]						= -55,
		["Text"]					= "General Options",
	},	
	["DLMSPanel_Group_Label"] = {
		["Name"]					= "GRO",
		["Text_Size"] 				= 16,
		["R"]						= 1.0,
		["G"]						= 1.0,
		["B"]						= 0.0,
		["A"]						= 0.8,
		["Point"]					= "TOPLEFT",
		["x"]						= 16,
		["y"]						= -106,
		["Text"]					= "Group Options",
	},	
	["DLMSPanel_Vendor_Label"] = {
		["Name"]					= "VEN",
		["Text_Size"] 				= 16,
		["R"]						= 1.0,
		["G"]						= 1.0,
		["B"]						= 0.0,
		["A"]						= 0.8,
		["Point"]					= "TOPLEFT",
		["x"]						= 315,
		["y"]						= -106,
		["Text"]					= "Vendor Options",
	},	
	["DLMSPanel_Loot_Label"] = {
		["Name"]					= "Loot",
		["Text_Size"] 				= 20,
		["R"]						= 1.0,
		["G"]						= 1.0,
		["B"]						= 0.0,
		["A"]						= 0.8,
		["Point"]					= "TOPLEFT",
		["x"]						= 16,
		["y"]						= -196,
		["Text"]					= "What would you like to loot today?",
	},	
}

-- Static Layout Panels --
local Static_Panel_Table = {
	["GO_Panel"] = {
		["Name"]					= "gOptions",
		["Point"]					= "TOPLEFT",
		["x"]						= 10,
		["y"]						= -70,
		["w"]						= 602,
		["h"]						= 34,
	},
	["LBC_Panel"] = {
		["Name"]					= "LBC",
		["Point"]					= "BOTTOMLEFT",
		["x"]						= 10,
		["y"]						= 135,
		["w"]						= 602,
		["h"]						= 165, --290
	},	
	["EXT_Panel"] = {
		["Name"]					= "EXT",
		["Point"]					= "BOTTOMLEFT",
		["x"]						= 10,
		["y"]						= 94,
		["w"]						= 602,
		["h"]						= 42, --290
	},	
	["LVQ_Panel"] = {
		["Name"]					= "LVQ",
		["Point"]					= "BOTTOMLEFT",
		["x"]						= 10,
		["y"]						= 10,
		["w"]						= 302,
		["h"]						= 85, --290
	},	
	["LST_Panel"] = {
		["Name"]					= "LST",
		["Point"]					= "BOTTOMRIGHT",
		["x"]						= -12,
		["y"]						= 10,
		["w"]						= 300,
		["h"]						= 85, --290
	},	
	["GRO_Panel"] = {
		["Name"]					= "GRO",
		["Point"]					= "TOPLEFT",
		["x"]						= 10,
		["y"]						= -120,
		["w"]						= 301,
		["h"]						= 73, --290
	},	
	["VEN_Panel"] = {
		["Name"]					= "VEN",
		["Point"]					= "TOPLEFT",
		["x"]						= 309,
		["y"]						= -120,
		["w"]						= 302,
		["h"]						= 100, --290
	},	
}

-- Numbered to force pairsByKeys() to sort table topdown by check box --
local Static_Checkbox_Table = {
	["10_LAGCB"] = {
		["Name"]					= "LAG",
		["Parent"]					= "DLMS_Options",
		["Text"]					= "Loot All and GO!",
		["Point"]					= "TOPRIGHT",
		["x"]						= -170,
		["y"]						= -30,
		["Tooltip"]					= "Loot EVERYTHING and GO!",
	},	
	["11_DISCB"] = {
		["Name"]					= "DIS",
		["Parent"]					= "DLMS_Options", --gOptions_Panel
		["Text"]					= "Enable DLMS",
		["Point"]					= "TOPRIGHT",
		["x"]						= -255,
		["y"]						= -7,
		["Tooltip"]					= "Disables DLMS and all it's features.",
	},	
	["12_UWMCB"] = {
		["Name"]					= "UWM",
		["Parent"]					= "gOptions_Panel",
		["Text"]					= "Use WoW Messages",
		["Point"]					= "TOPLEFT",
		["x"]						= 10,
		["y"]						= -6,
		["Tooltip"]					= "Use standard WoW chat messages for looting and money.",
	},	
	["13_KLOCB"] = {
		["Name"]					= "KLO",
		["Parent"]					= "gOptions_Panel",
		["Text"]					= "Keep Loot Window Open",
		["Point"]					= "TOPRIGHT",
		["x"]						= -150,
		["y"]						= -6,
		["Tooltip"]					= "Keeps the Loot Window open after DLMS has finished looting (you can also use the Shift Key).",
	},	
	["14_EDBCB"] = {
		["Name"]					= "EDB",
		["Parent"]					= "DLMS_Options",
		["Text"]					= "Enable DLMS Button",
		["Point"]					= "TOPRIGHT",
		["x"]						= -160,
		["y"]						= -7,
		["Tooltip"]					= "Show the DLMS Button.",
	},	
	["15_ARLCB"] = {
		["Name"]					= "ARL",
		["Parent"]					= "GRO_Panel",
		["Text"]					= "Auto Roll Greed On \124cFF1eff00Uncommon\124r",
		["Point"]					= "TOPLEFT",
		["x"]						= 8,
		["y"]						= -6,
		["Tooltip"]					= "Will auto roll greed on all \124cFF1eff00Uncommon\124r items.",
	},	
	["16_ARBCB"] = {
		["Name"]					= "ARB",
		["Parent"]					= "ARL_checkbox",
		["Text"]					= "Roll Greed on \124cFF0070ddRare\124r",
		["Point"]					= "TOPLEFT",
		["x"]						= 10,
		["y"]						= -20,
		["Tooltip"]					= "Will auto roll greed on all \124cFF0070ddRare\124r items.",
	},	
	["17_ARPCB"] = {
		["Name"]					= "ARP",
		["Parent"]					= "ARL_checkbox",
		["Text"]					= "Auto Pass",
		["Point"]					= "TOPLEFT",
		["x"]						= 130,
		["y"]						= -20,
		["Tooltip"]					= "Will auto pass on all loot rolls.",
	},	
	["18_DIRCB"] = {
		["Name"]					= "DIR",
		["Parent"]					= "GRO_Panel",
		["Text"]					= "Use Standard Looting While in a Raid",
		["Point"]					= "BOTTOMLEFT",
		["x"]						= 8,
		["y"]						= 6,
		["Tooltip"]					= "Disables DLMS looting and auto-roll features while in a raid group.",
	},	
	["19_ASJCB"] = {
		["Name"]					= "ASJ",
		["Parent"]					= "VEN_Panel",
		["Text"]					= "Auto Sell Junk",
		["Point"]					= "TOPLEFT",
		["x"]						= 8,
		["y"]						= -6,
		["Tooltip"]					= "Will auto sell all sellable grey items.",
	},	
	["20_ISQCB"] = {
		["Name"]					= "ISQ",
		["Parent"]					= "ASJ_checkbox",
		["Text"]					= "Auto Sell Green Items\n(Weapons & Armor ONLY)",
		["Point"]					= "TOPLEFT",
		["x"]						= 10,
		["y"]						= -20,
		["Tooltip"]					= "Will also sell \124cFF1eff00Uncommon\124r Weapon or Armor items.",
	},	
	["21_ARGCB"] = {
		["Name"]					= "ARG",
		["Parent"]					= "VEN_Panel",
		["Text"]					= "Auto Repair Gear",
		["Point"]					= "TOPRIGHT",
		["x"]						= -110,
		["y"]						= -6,
		["Tooltip"]					= "Tells DLMS to auto repair all of your gear when at a vendor that can repair. If you are not in a guild, it will use your money. Otherwise, it will attempt to use the Guild Bank, if it can't, it will use your money.",
	},	
	["22_LBCCB"] = {
		["Name"]					= "LBC",
		["Parent"]					= "LBC_Panel",
		["Text"]					= "Loot by Category",
		["Point"]					= "TOPRIGHT",
		["x"]						= -295,
		["y"]						= -3,
		["Tooltip"]					= "Tells DLMS to loot items from the Categories below (will use Value and Quality".. 
										" sliders for Weapons and Armor). Items passed passed by category will"..
										" still be evaluated by quality and value (if enabled)",
	},	
	["23_ELCCB"] = {
		["Name"]					= "ELC",
		["Parent"]					= "LBC_Panel", --DLMS_Options
		["Text"]					= "Enforce Category Policy",
		["Point"]					= "TOPRIGHT",
		["x"]						= -145,
		["y"]						= -6,
		["Tooltip"]					= "Forces DLMS to loot ONLY items from the Categories below (will use Value and Quality"..
										" sliders for Weapons and Armor if enabled).",
	},	
	["24_SNLCB"] = {
		["Name"]					= "SNL",
		["Parent"]					= "gOptions_Panel", --DLMS_Options
		["Text"]					= "Show \"Not Looted\" Messages",
		["Point"]					= "CENTER",
		["x"]						= -90,
		["y"]						= -1,
		["Tooltip"]					= "Show messages for items that are not looted.",
	},	
	["25_ADJCB"] = {
		["Name"]					= "ADJ",
		["Parent"]					= "EXT_Panel", --DLMS_Options
		["Text"]					= "Auto Delete Junk (USE AT OWN RISK)(NOT SAVED BETWEEN SESSIONS)",
		["Point"]					= "LEFT",
		["x"]						= 5,
		["y"]						= 0,
		["Tooltip"]					= "Auto Auto deletes junk (grey) items.",
	},	
}

-- Giving credit to the Author of this function for alphabetically sorting non-numeric tables
-- not sure who the author is but, it's awesome!
-- Found here: http://www.wowwiki.com/API_sort : referencing http://lua-users.org/wiki/TableLibraryTutorial @ lua-users.org
function pairsByKeys (t, f)
	local a = {}
		for n in pairs(t) do table.insert(a, n) end
		table.sort(a, f)
		local i = 0      -- iterator variable
		local iter = function ()   -- iterator function
			i = i + 1
			if a[i] == nil then return nil
			else return a[i], t[a[i]]
			end
		end
	return iter
end

-- list our DB... for testing purposes --
local function ListDB(tbl)
	local i = 1
	for k,v in pairsByKeys(tbl) do
		if(type(tbl[k]) == "table") then
			print(i..") "..tostring(k))
			for k2,v2 in pairsByKeys(tbl[k]) do
				print(">>> "..k2.." = "..tostring(v2))
			end
		else 
			print(k.." = "..tostring(v))
		end
		i = i + 1
	end
end

-- General Label Creator --
local function CreateLabel(parent,name,tS,r,b,g,a,p,x,y,txt)
	
	local fs

	if(parent:GetObjectType() == "CheckButton") then 
		fs = _G[parent:GetName().."Text"]
	else
		fs = parent:CreateFontString(name.."_Label")
	end

	fs:SetFont("Fonts\\ARIALN.TTF", tS, nil)
	fs:SetTextColor(r,b,g,a)
	fs:SetPoint(p,x,y)
	fs:SetText(txt)
	fs:Show()
end

local function CreatePanelDivider(parent,name,p,x,y,w,h)
	local f = DLMS_CreateFrame("Frame", name, parent)
	f:SetPoint(p,x,y)
	f:SetSize(w,h)
	f:SetAlpha(0.3)
	f:SetBackdrop(divider)
	f:Show()
end

-- General Checkbox factory...
local function MakeCheckBox(name,parent,txt,p,x,y,tooltip)
	local cb = DLMS_CreateFrame("CheckButton", name, parent, "ChatConfigCheckButtonTemplate")
	CreateLabel(cb, name, 15, 1.0, 1.0, 0.0, 0.8, "TOPLEFT", 23, -5, txt)
	if(tooltip) then cb.tooltip = tooltip end
	cb:SetPoint(p,x,y)
	cb:SetHitRectInsets(0,0,0,0) 
end

-- Make our static labels... 
local function Generate_Static_Labels(parent)
    local tmp = Static_Panel_Table
    for k in pairs(tmp) do
        local f = CreateFrame("Frame", tmp[k].Name.."_Panel", parent, "BackdropTemplate")
        f:SetPoint(tmp[k].Point, tmp[k].x, tmp[k].y)
        f:SetWidth(tmp[k].w)
        f:SetHeight(tmp[k].h)

        -- Apply backdrop using the backdrop table
        f:SetBackdrop(tmp[k].Backdrop)

        f:Show()
    end
    tmp = nil
end

-- Make our static panels...
local function Generate_Static_Panels(parent)
	local tmp = Static_Panel_Table
	for k in pairs(tmp) do
		local f = CreateFrame("Frame", tmp[k].Name.."_Panel", parent)
		f:SetPoint(tmp[k].Point, tmp[k].x, tmp[k].y)
		f:SetWidth(tmp[k].w)
		f:SetHeight(tmp[k].h)
		f:SetBackdrop(backdrop)
		f:Show()
	end
	tmp = nil
end



-- Make our static checkboxes --
local function Generate_Static_Checkboxes(parent)
	local tmp = Static_Checkbox_Table
	for k in pairsByKeys(tmp) do
		local n,p,t = tmp[k].Name,tmp[k].Parent,tmp[k].Text
		local pn,x,y = tmp[k].Point,tmp[k].x,tmp[k].y
		local tt = tmp[k].Tooltip
				
		MakeCheckBox(n.."_checkbox",_G[p],t,pn,x,y,tt)
	
		if(n == "ISQ" or n == "ARB" or n == "ARP" or n == "DIS" or n == "EDB") then
			_G[n.."_checkbox"]:SetSize(16,16)
			_G[n.."_checkboxText"]:SetFont("Fonts\\ARIALN.TTF", 13, nil)
			_G[n.."_checkboxText"]:SetTextColor(1.0,1.0,0.0,0.8)
			_G[n.."_checkboxText"]:SetPoint("TOPLEFT", 17, -2)
		elseif(n == "LAG") then
			_G[n.."_checkbox"]:SetSize(44,44)
			_G[n.."_checkboxText"]:SetFont("Fonts\\ARIALN.TTF", 24, nil)
			_G[n.."_checkboxText"]:SetTextColor(1.0,1.0,0.0,0.8)
			_G[n.."_checkboxText"]:SetPoint("TOPLEFT", 40, -10)
		elseif(n == "LBC") then
			_G[n.."_checkbox"]:SetSize(32,32)
			_G[n.."_checkboxText"]:SetFont("Fonts\\ARIALN.TTF", 18, nil)
			_G[n.."_checkboxText"]:SetTextColor(1.0,1.0,0.0,0.8)
			_G[n.."_checkboxText"]:SetPoint("TOPLEFT", 30, -6)
		elseif(n == "ELC") then
			_G[n.."_checkbox"]:SetSize(24,24)
			_G[n.."_checkboxText"]:SetFont("Fonts\\ARIALN.TTF", 14, nil)
			_G[n.."_checkboxText"]:SetTextColor(1.0,1.0,0.0,0.8)
			--_G[n.."_checkboxText"]:SetPoint("TOPLEFT", 30, -6)
		end
		
		if(n == "DIS") then
			_G[n.."_checkbox"]:SetChecked(OptionsDB.enabled)
		else
			_G[n.."_checkbox"]:SetChecked(OptionsDB[n])
		end 
		
		if(not OptionsDB.enabled and n ~= "DIS" or (n == "LBC" and OptionsDB.LAG)) then
			--print(n.." is Disabled")
			_G[n.."_checkbox"]:Disable()
			_G[n.."_checkboxText"]:SetTextColor(0.5,0.5,0.5,0.8)
		else
			--print(n.." is Enabled")
			_G[n.."_checkbox"]:Enable()
			_G[n.."_checkboxText"]:SetTextColor(1.0,1.0,0.0,0.8)
		end
		
	end
	tmp = nil
end

-- Checkbox "OnClick" handler factory --
local function CreateCBHandlers(cb,cat,type)
	_G[cb]:SetScript("OnClick",
		function()
			DLMS[cat][type] = _G[cb]:GetChecked() and true or false
			print(DLMS[cat][type] and DLMS_HEADER.."\124cFF00cc00Looting:\124r "..cat.." - "..type or DLMS_HEADER.."\124cFFcc0000Not looting:\124r "..cat.." - "..type)
		end
	)
	
end

local cb_count = 1
local cb_pos_x = 8
local cb_pos_y = -45
local cb_x_inc = 148
local cb_y_inc = 30

local function CreateCatagoryCheckboxes(f,bname)
	for k,v in pairsByKeys(CatLinkTable) do
		if(k == bname) then
			for k2,v2 in pairsByKeys(DLMS[k]) do
				
				local bpcbName = f:GetName().."_"..k2.."_checkbox"
				
				if(not tContains(bpcbNameTable, bpcbName)) then
					tinsert(bpcbNameTable, bpcbName) -- saving a reference to my checkbox names incase I need them...
					
					MakeCheckBox(bpcbName, f, k2, "TOPLEFT", cb_pos_x, cb_pos_y, false)
					
					_G[bpcbName]:SetChecked(DLMS[bname][k2])
					
					if(OptionsDB.LBC and OptionsDB.enabled and not OptionsDB.LAG) then
						_G[bpcbName]:Enable()
						_G[bpcbName.."Text"]:SetTextColor(1.0,1.0,0.0,0.8)
					else 
						_G[bpcbName]:Disable()
						_G[bpcbName.."Text"]:SetTextColor(0.5,0.5,0.5,0.8)
					end
					
					CreateCBHandlers(bpcbName,bname,k2)
					
				else
					_G[bpcbName]:SetPoint("TOPLEFT", cb_pos_x, cb_pos_y)
				end

				-- making sure that our position gets updated even
				-- if we don't draw the checkbox so that we can update on the fly 
				cb_pos_x = cb_pos_x + cb_x_inc
				cb_count = cb_count + 1
					
				if(cb_count == 5) then
					cb_count = 1
					cb_pos_x = 8
					cb_pos_y = cb_pos_y - cb_y_inc
				end
			end
		end
	end
	
	cb_count = 1
	cb_pos_x = 8
	cb_pos_y = -45
	
end

-- Creating our "Button" tabbed panels
local function CreateHandlers(bpName,b,f)
	b:SetScript("OnClick",
		function()
			if(not f:IsVisible()) then f:Show() end
			for k,v in pairs(bpNameTable) do
				if(v ~= bpName) then
					_G[v]:Hide()
				end
			end
		end
	)
end

-- Make our catagory panels to go with our catagory buttons
local function MakeButtonPanels(b, bname)
	local bpName = b:GetName().."_panel"

	if(not tContains(bpNameTable, bpName)) then
		tinsert(bpNameTable, bpName) 
		CatLinkTable[bname] = bpName -- Saving a link between catagory button and its associated panel
		local f = DLMS_CreateFrame("Frame", bpName, LBC_Panel)
		f:SetAllPoints()
		
		local r,g,bl,a
		
		if(OptionsDB.enabled and not OptionsDB.LAG) then
			r = 1.0; g = 1.0; bl = 0.0; a = 0.8
		else
			r = 0.5; g = 0.5; bl = 0.5; a = 0.8
		end
		
		CreateLabel(f, bpName, 20, r, g, bl, a, "TOPLEFT", 10, -10, bname.." Item Types")
		
		if(isButtonOne) then
			f:Show()
			isButtonOne = false
		else
			f:Hide()
		end
		
		CreateHandlers(bpName,b,f) -- hmm.. I feel like Italian... where does this noodle go??... oh, wait.. I'm so confused...
		if(next(DLMS[bname]) == nil) then
			CreateLabel(f, bpName.."_Empty_Label", 24, 1.0, 1.0, 0.0, 0.8, "CENTER", 10, -10, "Nothing under "..bname.." yet, keep looting!")
		end
	end
	
	CreateCatagoryCheckboxes(_G[bpName],bname)
end

local b_count = 0
local b_pos_x = 11
local b_pos_y = 325
local b_x_inc = 100
local b_y_inc = 25

-- Generate our buttons -- 
local function MakeButtons()
	for k in pairsByKeys(DLMS) do
		local n = tostring(k)
		local button_name = n.."_button"
		
		if(not tContains(bNameTable, button_name)) then
			tinsert(bNameTable, button_name)
			local b = DLMS_CreateFrame("Button", button_name, DLMS_Options, "UIPanelButtonTemplate")
			b:SetWidth(100)
			b:SetHeight(25)
			local fs = _G[b:GetName().."Text"]
			fs:SetFont("Fonts\\ARIALN.TTF", 14, nil)
			fs:SetTextColor(1.0,1.0,0.0,0.8)
			
			b:SetPoint("BOTTOMLEFT", b_pos_x, b_pos_y)
			b:SetText(n)
			b:RegisterForClicks("AnyUp")
			
			if(OptionsDB.LBC and OptionsDB.enabled and not OptionsDB.LAG) then 
				_G[button_name]:Enable()
				_G[button_name.."Text"]:SetTextColor(1.0,1.0,0.0,0.8)
			else 
				_G[button_name]:Disable()
				_G[button_name.."Text"]:SetTextColor(0.5,0.5,0.5,0.8)
			end
		else
			_G[button_name]:SetPoint("BOTTOMLEFT", b_pos_x, b_pos_y)
		end
		
		-- making sure that our position gets updated even 
		-- if we don't draw the button so that we can update on the fly 
		b_pos_x = b_pos_x + b_x_inc
		b_count = b_count + 1

		if(b_count == 6) then
			b_count = 0
			b_pos_x = 11
			b_pos_y = b_pos_y - b_y_inc
		end
		MakeButtonPanels(_G[button_name], n)
	end
	b_count = 0
	b_pos_x = 11
	b_pos_y = 325
end

local function Update_Catagories()
	if(IsEmpty) then
		CreateLabel(LBC_Panel, "No_Category", 18, 1.0, 1.0, 0.0, 0.8, "CENTER", 0, 0, "Oops! No Catagories yet... Go loot something!")
	else
		if(_G["No_Category_Label"] ~= nil) then _G["No_Category_Label"]:Hide() end
		MakeButtons()
	end
end

local function de_select_all(switch)
		
	for k,v in pairs(bpNameTable) do
		if(_G[v]:IsVisible()) then
			for k2,v2 in pairs(bpcbNameTable) do
				if(strfind(v2,v) ~= nil) then
					local checkbox = _G[v2]
					local checked = checkbox:GetChecked()
					if(switch == "select" and not checked) then 
						checkbox:Click("LeftButton", false)
					else
						if(switch == "deselect" and checked) then
							checkbox:Click("LeftButton", false)
						end
					end
				end
			end
		end
	end

end

local function CatSwitchState()
	if(OptionsDB.LBC and OptionsDB.enabled and not OptionsDB.LAG) then 
		select_all_button:Enable(); 
		deselect_all_button:Enable();
		select_allText:SetTextColor(1.0,1.0,0.0,0.8);
		deselect_allText:SetTextColor(1.0,1.0,0.0,0.8); 		
		for k,v in pairs(bNameTable) do _G[v]:Enable(); _G[v.."Text"]:SetTextColor(1.0,1.0,0.0,0.8); end
		for k,v in pairs(bpNameTable) do _G[v.."_Label"]:SetTextColor(1.0,1.0,0.0,0.8); end
		for k,v in pairs(bpcbNameTable) do _G[v]:Enable(); _G[v.."Text"]:SetTextColor(1.0,1.0,0.0,0.8); end
	else
		select_all_button:Disable(); 
		deselect_all_button:Disable();
		select_allText:SetTextColor(0.5,0.5,0.5,0.8);  
		deselect_allText:SetTextColor(0.5,0.5,0.5,0.8);
		for k,v in pairs(bNameTable) do _G[v]:Disable(); _G[v.."Text"]:SetTextColor(0.5,0.5,0.5,0.8); end
		for k,v in pairs(bpNameTable) do _G[v.."_Label"]:SetTextColor(0.5,0.5,0.5,0.8); end
		for k,v in pairs(bpcbNameTable) do _G[v]:Disable(); _G[v.."Text"]:SetTextColor(0.5,0.5,0.5,0.8); end
	end
end

-- Build our options --
local function DLMSBuildOptions()
		
	Generate_Static_Labels(DLMS_Options)
	Generate_Static_Panels(DLMS_Options)
	Generate_Static_Checkboxes()
	
	CreatePanelDivider(LBC_Panel, "LBC_Divider1", "TOPLEFT", 10, -32, 582, 4)
	CreatePanelDivider(LBC_Panel, "LBC_Divider2", "BOTTOMLEFT", 10, 32, 582, 4)
			
-- Making our Select and Deselect All buttons do what we want --
	select_all_button:SetParent(LBC_Panel)
	select_all_button:SetWidth(100)
	select_all_button:SetHeight(25)
	select_all_button:SetPoint("BOTTOMLEFT", 8, 6)	
	select_allText:SetFont("Fonts\\ARIALN.TTF", 14, nil)
	select_allText:SetTextColor(1.0,1.0,0.0,0.8)
	select_allText:SetText("Select All")
	
	
	deselect_all_button:SetParent(LBC_Panel)
	deselect_all_button:SetWidth(100)
	deselect_all_button:SetHeight(25)
	deselect_all_button:SetPoint("BOTTOMLEFT", 108, 6)
	deselect_allText:SetFont("Fonts\\ARIALN.TTF", 14, nil)
	deselect_allText:SetTextColor(1.0,1.0,0.0,0.8)
	deselect_allText:SetText("Deselect All")
		
-- END ------------------------------------------------------------------------------

-- Sell Speed Slider --
		
	asrSlider:SetParent(VEN_Panel)
	asrSlider:SetWidth(280)
	asrSlider:SetMinMaxValues(.5, 10)
	asrSlider:SetValueStep(.1)
	asrSlider:SetObeyStepOnDrag(true)
	asrSlider:SetValue((OptionsDB.ASR ~= nil) and OptionsDB.ASR or 1)
	asrSlider:SetPoint("BOTTOMLEFT", 10, 14)
	
	 _G[asrSlider:GetName().."Low"]:SetText("   Fastest") 
	 _G[asrSlider:GetName().."High"]:SetText("Slowest   ")
	 _G[asrSlider:GetName().."Text"]:SetText("")
	
	local asr = (OptionsDB.ASR ~= nil) and OptionsDB.ASR or 1
	
	local rate = world * asr
	
	CreateLabel(VEN_Panel, "ASR_Header", 12, 1.0, 1.0, 0.0, 0.8, "BOTTOMLEFT", 15, 30, "Auto-sell Rate")		
	CreateLabel(VEN_Panel, "ASR_Value", 12, 1.0, 1.0, 0.0, 0.8, "BOTTOMRIGHT", -15, 30, string.format("(%.1fx)",asr)..string.format("(%.1fms)",rate))
	asrSlider:Show()
 -- END --

-- Value Slider --
		
	lbvSlider:SetParent(LVQ_Panel)
	lbvSlider:SetWidth(280) --582
	lbvSlider:SetMinMaxValues(0, 10000)
	lbvSlider:SetValue(OptionsDB.LBV and OptionsDB.LBV or 0)
	lbvSlider:SetPoint("TOPLEFT", 10, -22)
	
	 _G[lbvSlider:GetName().."Low"]:SetText("") 
	 _G[lbvSlider:GetName().."High"]:SetText("")
	 _G[lbvSlider:GetName().."Text"]:SetText("")
		
	CreateLabel(LVQ_Panel, "ValueHeader", 14, 1.0, 1.0, 0.0, 0.8, "TOPLEFT", 12, -8, "Loot by Value (0 disables)")		
	CreateLabel(LVQ_Panel, "Value", 14, 1.0, 1.0, 0.0, 0.8, "TOPRIGHT", -15, -10, OptionsDB.LBV and GetCoinTextureString(OptionsDB.LBV,10) 
																								or DLMS_COLOR("Disabled", "Disable"))
	lbvSlider:Show()
 -- END --

-- Quality Slider --
	
	lbqSlider:SetParent(LVQ_Panel)
	lbqSlider:SetWidth(280) --582
	lbqSlider:SetMinMaxValues(0, 3)
	lbqSlider:SetPoint("TOPLEFT", 10, -55)
	
	-- work around to fix glitch where label would not show without actually clicking the slider... 
	--------------------------------------------------------------
	--local lbQuality = OptionsDB.LBQ and OptionsDB.LBQ+1 or 0	
	lbqSlider:SetValue((OptionsDB.LBQ) and OptionsDB.LBQ or 0)
	local tmpstr = (OptionsDB.LBQ) and DLMS_COLOR(QualityStrings[OptionsDB.LBQ],QualityStrings[OptionsDB.LBQ])
									or DLMS_COLOR(QualityStrings[0],QualityStrings[0])
	--------------------------------------------------------------
	
	 _G[lbqSlider:GetName().."Low"]:SetText("   Disable") 
	 _G[lbqSlider:GetName().."High"]:SetText("")
	 _G[lbqSlider:GetName().."Text"]:SetText("")
		
		
	CreateLabel(LVQ_Panel, "QualityHeader", 14, 1.0, 1.0, 0.0, 0.8, "TOPLEFT", 13, -40, "Loot by Item Quality")		
	CreateLabel(LVQ_Panel, "Quality", 14, 1.0, 1.0, 0.0, 0.8, "TOPRIGHT", -15, -43, tmpstr)
		
	lbqSlider:Show()
-- END --
-- List Buttons --
	CreateLabel(LST_Panel, "autosell_header", 14, 1.0, 1.0, 0.0, 0.8, "TOPLEFT", 12, -8, "Manage Autosell Lists")		
	CreateLabel(LST_Panel, "autosell_header", 14, 1.0, 1.0, 0.0, 0.8, "TOPLEFT", 172, -8, "Manage Loot Lists")		

	local safe_btn = DLMS_CreateFrame ("Button", "as_safe_btn", LST_Panel, "UIPanelButtonTemplate")
	safe_btn:SetSize(125, 25)
	safe_btn:SetPoint("TOPLEFT", 13, -24)
	safe_btn.Text:SetFont("Fonts\\ARIALN.TTF", 12)
	safe_btn.Text:SetText("Autosell Safe List")
	safe_btn:Show()

	safe_btn:SetScript("OnClick", 
		function(self) 
			if(next(autosell_safe_list) ~= nil) then
				current_list = autosell_safe_list
				listframe:Show() 
			else print(DLMS_HEADER.."List is empty...") end
		end
	)

	local ignore_btn = DLMS_CreateFrame ("Button", "as_ignore_btn", LST_Panel, "UIPanelButtonTemplate")
	ignore_btn:SetSize(125, 25)
	ignore_btn:SetPoint("TOPLEFT", 13, -52)
	ignore_btn.Text:SetFont("Fonts\\ARIALN.TTF", 12)
	ignore_btn.Text:SetText("Autosell Ignore List")
	ignore_btn:Show()

	ignore_btn:SetScript("OnClick", 
		function(self) 
			if(next(autosell_ignore_list) ~= nil) then
				current_list = autosell_ignore_list
				listframe:Show() 
			else print(DLMS_HEADER.."List is empty...") end
		end
	)

	local lst_div = LST_Panel:CreateLine()
	lst_div:SetColorTexture(1,1,1,0.5)
	lst_div:SetThickness(1)
	lst_div:SetStartPoint("TOPLEFT",(LST_Panel:GetWidth()/2),-6)
	lst_div:SetEndPoint("BOTTOMLEFT",(LST_Panel:GetWidth()/2),6)

	local white_btn = DLMS_CreateFrame ("Button", "l_white_btn", LST_Panel, "UIPanelButtonTemplate")
	white_btn:SetSize(125, 25)
	white_btn:SetPoint("TOPLEFT", 162, -24)
	white_btn.Text:SetFont("Fonts\\ARIALN.TTF", 12)
	white_btn.Text:SetText("Loot White List")
	white_btn:Show()

	white_btn:SetScript("OnClick", 
		function(self) 
			if(next(loot_white_list) ~= nil) then
				current_list = loot_white_list
				listframe:Show() 
			else print(DLMS_HEADER.."List is empty...") end
		end
	)

	local black_btn = DLMS_CreateFrame ("Button", "l_black_btn", LST_Panel, "UIPanelButtonTemplate")
	black_btn:SetSize(125, 25)
	black_btn:SetPoint("TOPLEFT", 162, -52)
	black_btn.Text:SetFont("Fonts\\ARIALN.TTF", 12)
	black_btn.Text:SetText("Loot Black List")
	black_btn:Show()

	black_btn:SetScript("OnClick", 
		function(self) 
			if(next(loot_black_list) ~= nil) then
				current_list = loot_black_list
				listframe:Show() 
			else print(DLMS_HEADER.."List is empty...") end
		end
	)

-- Catagory Button "Tab" Panel ----------
	Update_Catagories()

-- Set Initial Addon load states for catagory elements, etc... --

	-- Init our ELC checkbox --
	if(OptionsDB.LBC) then
		ELC_checkbox:Enable()
		ELC_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
	else
		ELC_checkbox:Disable()
		ELC_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
	end
	
	-- Making sure ISQ and UPF get init correctly --
	if(not OptionsDB.ASJ) then
		ISQ_checkbox:SetChecked(false)
		ISQ_checkbox:Disable()
		ISQ_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
	else
		ISQ_checkbox:Enable()
		ISQ_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
	end
	
	------------------------------------------------
	
	local aRoll = OptionsDB.ARL
	ARB_checkbox:SetChecked(OptionsDB.ARB)
	


-- Work on this... ARB gets randomly checked when reloading or logging in and ARL is not checked...
	if(aRoll ~= false) then
		ARL_checkbox:SetChecked(true)
		if(aRoll == 0) then
			ARL_checkbox:Disable()
			ARB_checkbox:Disable()
			ARP_checkbox:SetChecked(true)
		elseif(aRoll == 3) then
			ARB_checkbox:SetChecked(true)
		end
	else
		ARB_checkbox:Disable()
		ARP_checkbox:Disable()
	end

	-- if our DB is empty, go ahead and setup to Loot All so we can build our catagory DB...
	if(IsEmpty) then
		OptionsDB.LAG = true
		LAG_checkbox:SetChecked(true)
	end
	-- end --
	if(OptionsDB.LAG or not OptionsDB.enabled) then
		lbvSlider:Disable()
		lbqSlider:Disable()
		ValueHeader_Label:SetTextColor(0.5,0.5,0.5,0.8)
		QualityHeader_Label:SetTextColor(0.5,0.5,0.5,0.8)
		Value_Label:Hide()
		Quality_Label:Hide()
	else
		ValueHeader_Label:SetTextColor(1.0,1.0,0.0,0.8)
		QualityHeader_Label:SetTextColor(1.0,1.0,0.0,0.8)
		lbvSlider:Enable()
		lbqSlider:Enable()
		Value_Label:Show()
		Quality_Label:Show()
	end
	
	if(OptionsDB.LBC and OptionsDB.enabled and not OptionsDB.LAG) then
		select_all_button:Enable()
		select_allText:SetTextColor(1.0,1.0,0.0,0.8)
		deselect_all_button:Enable()
		deselect_allText:SetTextColor(1.0,1.0,0.0,0.8)
	else 
		select_all_button:Disable()
		select_allText:SetTextColor(0.5,0.5,0.5,0.8)
		deselect_all_button:Disable()
		deselect_allText:SetTextColor(0.5,0.5,0.5,0.8)
	end
		
	CatSwitchState()
		
-- END --

-- Event Handlers --
	select_all_button:SetScript("OnClick",
		function()
			de_select_all("select")
		end
	)

	deselect_all_button:SetScript("OnClick",
		function()
			de_select_all("deselect")
		end
	)

	ADJ_checkbox:SetScript("OnClick",
		function()
			auto_delete_junk = (ADJ_checkbox:GetChecked()) and true or false
			print((ADJ_checkbox:GetChecked()) and (DLMS_HEADER.."Auto delete junk is "..DLMS_COLOR("ON",3)) 
												or (DLMS_HEADER.."Auto delete junk is "..DLMS_COLOR("OFF",4))) 
		end
	)
	
	UWM_checkbox:SetScript("OnClick",
		function()
			OptionsDB.UWM = UWM_checkbox:GetChecked() and true or false
			print(OptionsDB.UWM and DLMS_HEADER.."is using WoW messages.." 
									or DLMS_HEADER.."is using DLMS messages.")
		end
	)
	
	ELC_checkbox:SetScript("OnClick",
		function()
			OptionsDB.ELC = ELC_checkbox:GetChecked() and true or false
			print(OptionsDB.ELC and DLMS_HEADER.."Will strictly enforce Category policy. Looting Weapons or Armor will also be evaluated by Quality and Value (if enabled below)." 
									or DLMS_HEADER.."Looting by Category policy loosened. Items passed by category will also be evaluated by Quality and Value (if enabled below).")
		end
	)
	
	SNL_checkbox:SetScript("OnClick",
		function()
			OptionsDB.SNL = SNL_checkbox:GetChecked() and true or false
			print(OptionsDB.SNL and DLMS_HEADER.."Will now notify you if an item was not looted." or DLMS_HEADER.."Not Looted Messages are now Disabled.")
		end
	)

	EDB_checkbox:SetScript("OnClick",
		function()
			OptionsDB.EDB = EDB_checkbox:GetChecked() and true or false
			print(OptionsDB.EDB and DLMS_HEADER.."Button Enabled!" 
									or DLMS_HEADER.."Button Disabled! You can use /dlms button to show it again.")
			
			if(OptionsDB.EDB) then DLMS_Button:Show() else DLMS_Button:Hide() end
		end
	)
	
	DIS_checkbox:SetScript("OnClick",
		function()
			--print(DIS_checkbox:GetChecked())
			OptionsDB.enabled = (DIS_checkbox:GetChecked()) and true or false
			print(OptionsDB.enabled and DLMS_HEADER..DLMS_COLOR("enabled...",2) 
										or DLMS_HEADER..DLMS_COLOR("disabled...",2))
			
			if(OptionsDB.enabled) then
				if(not IsEmpty and not OptionsDB.LAG) then
					LBC_checkbox:Enable()				
					LBC_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
				end
				
				if(not OptionsDB.LAG) then
					ValueHeader_Label:SetTextColor(1.0,1.0,0.0,0.8)
					QualityHeader_Label:SetTextColor(1.0,1.0,0.0,0.8)
					lbvSlider:Enable()
					lbqSlider:Enable()
					Value_Label:Show()
					Quality_Label:Show()
				end
				
				asrSlider:Enable()
				ASR_Header_Label:SetTextColor(1.0,1.0,0.0,0.8)
				ASR_Value_Label:Show()

				LAG_checkbox:Enable()
				UWM_checkbox:Enable()
				KLO_checkbox:Enable()
				ARL_checkbox:Enable()
				ARP_checkbox:Enable()
				ARB_checkbox:Enable()
				DIR_checkbox:Enable()
				ASJ_checkbox:Enable()
				ISQ_checkbox:Enable()
				ARG_checkbox:Enable()
				SNL_checkbox:Enable()
				
				LAG_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
				UWM_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
				KLO_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
				ARL_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
				ARB_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
				ARP_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
				DIR_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
				ASJ_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
				ISQ_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
				ARG_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
				SNL_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)

				DLMS_Btn_Tex4:SetTexture(DLMS_IND_GREEN) --Interface\\RAIDFRAME\\ReadyCheck-ReadyInterface\\ICONS\\INV_Misc_Bag_EnchantedMageweave
				CatSwitchState()
				
			else
				LAG_checkbox:Disable()
				UWM_checkbox:Disable()
				KLO_checkbox:Disable()
				ARL_checkbox:Disable()
				ARP_checkbox:Disable()
				ARB_checkbox:Disable()
				DIR_checkbox:Disable()
				ASJ_checkbox:Disable()
				ISQ_checkbox:Disable()
				ARG_checkbox:Disable()
				LBC_checkbox:Disable()
				SNL_checkbox:Disable()
				
				lbvSlider:Disable()
				lbqSlider:Disable()
				asrSlider:Disable()
				
				ValueHeader_Label:SetTextColor(0.5,0.5,0.5,0.8)
				QualityHeader_Label:SetTextColor(0.5,0.5,0.5,0.8)
				
				ASR_Header_Label:SetTextColor(0.5,0.5,0.5,0.8)

				LBC_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
				LAG_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
				UWM_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
				KLO_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
				ARL_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
				ARB_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
				ARP_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
				DIR_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
				ASJ_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
				ISQ_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
				ARG_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
				SNL_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)

				Value_Label:Hide()
				Quality_Label:Hide()
				ASR_Value_Label:Hide()
				
				DLMS_Btn_Tex4:SetTexture(DLMS_IND_RED) --Interface\\RAIDFRAME\\ReadyCheck-ReadyInterface\\ICONS\\INV_Misc_Bag_EnchantedMageweave
				CatSwitchState()
			end
		end
	)
	
	LAG_checkbox:SetScript("OnClick", 
		function()
			
			OptionsDB.LAG = LAG_checkbox:GetChecked() and true or false
			print(OptionsDB.LAG and DLMS_HEADER.."LOOTING EVERYTHING!" 
									or DLMS_HEADER.."Looting based on options below.")

			if(OptionsDB.LAG) then
				--OptionsDB.LBC = false
				--LBC_checkbox:SetChecked(false)
				LBC_checkbox:Disable()
				lbvSlider:Disable()
				lbqSlider:Disable()
				
				LBC_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
				ValueHeader_Label:SetTextColor(0.5,0.5,0.5,0.8)
				QualityHeader_Label:SetTextColor(0.5,0.5,0.5,0.8)
				Value_Label:Hide()
				Quality_Label:Hide()
			else
				if(not IsEmpty) then
					LBC_checkbox:Enable()
					LBC_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
				end
				ValueHeader_Label:SetTextColor(1.0,1.0,0.0,0.8)
				QualityHeader_Label:SetTextColor(1.0,1.0,0.0,0.8)
				lbvSlider:Enable()
				lbqSlider:Enable()
				Value_Label:Show()
				Quality_Label:Show()
			end
			
			CatSwitchState()
		end
	)

	LBC_checkbox:SetScript("OnClick", 
		function()
			OptionsDB.LBC = LBC_checkbox:GetChecked() and true or false
			print(OptionsDB.LBC and DLMS_HEADER.."Looting by Category has been enabled." 
									or DLMS_HEADER.."Looting by Category has been disabled.")
			
			if(OptionsDB.LBC) then
				ELC_checkbox:Enable()
				ELC_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
			else
				ELC_checkbox:SetChecked(false)
				ELC_checkbox:Disable()
				ELC_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
			end
			
			CatSwitchState()
		end
	)

	ARL_checkbox:SetScript("OnClick", 
		function()
			OptionsDB.ARL = ARL_checkbox:GetChecked() and 2 or false
			
			if(ARL_checkbox:GetChecked()) then
				ARB_checkbox:Enable()
				ARP_checkbox:Enable()
				--lr:Show()
			else
				ARB_checkbox:SetChecked(false)
				ARB_checkbox:Disable()
				ARP_checkbox:SetChecked(false)
				ARP_checkbox:Disable()
				--lr:Hide()
			end
			
			print(OptionsDB.ARL and DLMS_HEADER.."Will roll greed on all "..DLMS_COLOR("Uncommon", DLMS_COLOR_Uncommon).." items." 
									or DLMS_HEADER.."Auto Loot Rolls Disabled")
		end
	)

	ARB_checkbox:SetScript("OnClick", 
		function()
		
			OptionsDB.ARL = ARB_checkbox:GetChecked() and 3 or 2
			OptionsDB.ARB = ARB_checkbox:GetChecked() and true or false
			print(OptionsDB.ARB and DLMS_HEADER.."Will roll greed on all "..DLMS_COLOR("Rare", DLMS_COLOR_Rare).." items." 
									or DLMS_HEADER.."Will roll greed on all "..DLMS_COLOR("Uncommon", DLMS_COLOR_Uncommon).." items.")
		end
	)

	ARP_checkbox:SetScript("OnClick", 
		function()
			if(ARP_checkbox:GetChecked()) then 
				OptionsDB.ARL = 0
				ARL_checkbox:Disable()
				ARB_checkbox:Disable()
				--lrp:Show()
				print(DLMS_HEADER.."Auto Passing on ALL Loot Rolls")
			else 
				ARL_checkbox:Enable()
				ARB_checkbox:Enable()
				--lrp:Hide()
				
				if(ARB_checkbox:GetChecked()) then 
					OptionsDB.ARL = 3
					print(DLMS_HEADER.."Will roll greed on all "..DLMS_COLOR("Rare", DLMS_COLOR_Rare).." items.")
				else 
					OptionsDB.ARL = 2 
					print(DLMS_HEADER.."Will roll greed on all "..DLMS_COLOR("Uncommon", DLMS_COLOR_Uncommon).." items.")
				end
			end
		end
	)

	ARG_checkbox:SetScript("OnClick", 
		function()
			OptionsDB.ARG = ARG_checkbox:GetChecked() and true or false
			print(OptionsDB.ARG and DLMS_HEADER.."Auto Repair Enabled" 
									or DLMS_HEADER.."Auto Repair Disabled")
		end
	)

	ASJ_checkbox:SetScript("OnClick", 
		function()
			OptionsDB.ASJ = ASJ_checkbox:GetChecked() and true or false
			if(not OptionsDB.ASJ) then
				ISQ_checkbox:SetChecked(false)
				ISQ_checkbox:Disable()
				ISQ_checkboxText:SetTextColor(0.5,0.5,0.5,0.8)
			else
				ISQ_checkbox:Enable()
				ISQ_checkboxText:SetTextColor(1.0,1.0,0.0,0.8)
			end
			print(OptionsDB.ASJ and DLMS_HEADER.."Auto Selling ALL sellable grey items." 
									or DLMS_HEADER.."Auto Sell Disabled")
		end
	)

	KLO_checkbox:SetScript("OnClick", 
		function()
			OptionsDB.KLO = KLO_checkbox:GetChecked() and true or false
			print(OptionsDB.KLO and DLMS_HEADER.."Will keep the loot window open." 
									or DLMS_HEADER.."Will auto close the loot window.")
		end
	)
		
	ISQ_checkbox:SetScript("OnClick", 
		function()
			OptionsDB.ISQ = ISQ_checkbox:GetChecked() and true or false
			print(OptionsDB.ISQ and DLMS_HEADER.."Adding Green quality Weapons & Armor to Auto Sell list." 
									or DLMS_HEADER.."Will only sell grey items.")
		end
	)
	
	DIR_checkbox:SetScript("OnClick", 
		function()
			OptionsDB.DIR = DIR_checkbox:GetChecked() and true or false
			print(OptionsDB.DIR and DLMS_HEADER.."Will now disable while in a raid group." 
									or DLMS_HEADER.."Will continue to loot while in a raid group.")
		end
	)
	
	lbvSlider:SetScript("OnValueChanged",
		function(self, value)
			value = floor(value)
			self:SetValue(value)
			if(value == 0) then 
				Value_Label:SetTextColor(0.5,0.5,0.5,0.8)
				Value_Label:SetText("Disabled")
			else
				Value_Label:SetTextColor(1.0,1.0,0.0,0.8)
				Value_Label:SetText(GetCoinTextureString(value,10))
			end
			OptionsDB.LBV = (value > 0) and (value) or false
		end
	)

	lbqSlider:SetScript("OnValueChanged",
			function(self, value)
				value = floor(value)
				self:SetValue(value)
				Quality_Label:SetText(DLMS_COLOR(QualityStrings[value],QualityStrings[value]))
				OptionsDB.LBQ = (value > 0) and (value) or false
			end
	)
	
	asrSlider:SetScript("OnValueChanged",
			function(self, value)
				local rate = world * value
				self:SetValue(value)
				ASR_Value_Label:SetText(string.format("(%.1fx)",value)..string.format("(%.1fms)",rate))
				OptionsDB.ASR = value
				--print(OptionsDB.ASR)
			end
	)

end

local fade = false

local DLMS_Menu

local function Update_DLMS_Menu()
	
	DLMS_Menu = nil -- Clearing it for a re-init.
	
	DLMS_Menu = {
		{ 
			text = "DLMS Button Options", 
			isTitle = true, 
			notCheckable = true,
		},
		{ 
			text = "Show Bag Free Space", 
			checked = fs_Slots:IsVisible(),
			func = function(self) 
						if(fs_Slots:IsVisible()) then
							fs_Slots:Hide()
							self.checked = false
							OptionsDB.SBS = false
						else
							fs_Slots:Show()
							self.checked = true
							OptionsDB.SBS = true
						end
					end,
			keepShownOnClick = true,
		},
{ 
			text = "Show Money", 
			--notCheckable = true,
			checked = DLMS_Money_Frame:IsVisible(),
			func = function(self) 
						if(DLMS_Money_Frame:IsVisible()) then
							DLMS_Money_Frame:Hide()
							self.checked = false
						else
							DLMS_Money_Frame:Show()
							self.checked = true
						end
					end,
			hasArrow = true,
			menuList = 
			{
				{ 
					text = "Player Money",
					checked = (OptionsDB.SBB and DLMS_Money_Frame:IsVisible()),
					func = function(self)
						print(UIDropDownMenu_GetSelectedID(self))
							if(DLMS_Money_Frame:IsVisible()) then
								if(OptionsDB.SBB) then
									OptionsDB.SBB = false
									self.checked = false
									OptionsDB.SBV = true
								else
									OptionsDB.SBB = true
									self.checked = true
									OptionsDB.SBV = false
								end
							end
					end, 
					keepShownOnClick = true,
				},
				{ 
					text = "Bag Value", 
					checked = (OptionsDB.SBV and DLMS_Money_Frame:IsVisible()),
					func = function(self) 
							if(DLMS_Money_Frame:IsVisible()) then
								if(OptionsDB.SBV) then
									OptionsDB.SBV = false
									self.checked = false
									OptionsDB.SBB = true
								else
									OptionsDB.SBV = true
									self.checked = true
									OptionsDB.SBB = false
								end
							end
					end, 
					keepShownOnClick = true,
				},
			},
			keepShownOnClick = true,
        }, 
		{
			text = "Fade Out",
			checked = fade,
			func = function(self)
				if(not fade) then
					self.checked = true
					OptionsDB.FAD = true
					fade = true
				else
					self.checked = false
					OptionsDB.FAD = false
					fade = false
				end
			end,
		},
		{
			text = "Lock Position",
			checked = OptionsDB.LOC,
			func = function(self)
				if(not OptionsDB.LOC) then
					self.checked = true
					OptionsDB.LOC = true
				else
					self.checked = false
					OptionsDB.LOC = false
				end
			end,
		},
	    { 
			text = "Scaling Options", 
			notCheckable = true,
			hasArrow = true,
			menuList = 
			{
				{ 
					text = "Scale 0.75",
					checked = (DLMS_Button:GetScale() == 0.75) and true or false,
					func = function(self) 
						OptionsDB.SCL = 0.75
						DLMS_Button:SetScale(0.75)
					end, 
				},
				{ 
					text = "Scale 1.0", 
					checked = (DLMS_Button:GetScale() == 1.0) and true or false,
					func = function(self) 
						OptionsDB.SCL = 1.0
						DLMS_Button:SetScale(1.0)
					end, 
				},
				{ 
					text = "Scale 1.25", 
					checked = (DLMS_Button:GetScale() == 1.25) and true or false,
					func = function(self) 
						OptionsDB.SCL = 1.25
						DLMS_Button:SetScale(1.25)
					end, 
				},
				{ 
					text = "Scale 1.5", 
					checked = (DLMS_Button:GetScale() == 1.5) and true or false,
					func = function(self) 
						OptionsDB.SCL = 1.5
						DLMS_Button:SetScale(1.5)
					end, 
				},
			},
        }, 
		{
			text = "Close Button",
			notCheckable = true,
			func = function(self)
				EDB_checkbox:Click("LeftButton", true)
			end,
		},
	}
end

local DLMS_Menu_Frame = DLMS_CreateFrame("Frame", "DLMSMenuFrame", DLMS_Button, "UIDropDownMenuTemplate")
DLMS_Menu_Frame:SetPoint("BOTTOMRIGHT")
DLMS_Menu_Frame:Hide()

-- Core Routines/Functions --

local seconds1 = 0

oFloat:SetScript("OnUpdate",
	function(self, time)
		seconds1 = seconds1 + time
		if(seconds1 >= 0.25) then
			if(InterfaceOptionsFrame:IsVisible() 
					and not self:IsEnabled()) then
				self:Enable()
			elseif(not InterfaceOptionsFrame:IsVisible() 
					and self:IsEnabled()) then
				self:Disable()
			end
			seconds1 = 0
		end
	end
)

local function floatDLMSOpt()
	-- Create DLMS_Options frame and mix in BackdropTemplateMixin
	local DLMS_Options = CreateFrame("Frame", "DLMS_Options", UIParent, "BackdropTemplate")
	
	-- Set the backdrop properties for DLMS_Options
	DLMS_Options:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	
	-- Set other properties for DLMS_Options
	DLMS_Options:SetWidth(623) 
	DLMS_Options:SetHeight(568)
	DLMS_Options:ClearAllPoints()
	DLMS_Options:SetPoint("CENTER", 0, 0)
	DLMS_Options:SetFrameStrata('DIALOG')
	DLMS_Options:SetToplevel(true)
	DLMS_Options:SetClampedToScreen(true)
	DLMS_Options:EnableMouse(true)
	DLMS_Options:SetMovable(true)
	DLMS_Options:RegisterForDrag("LeftButton")
	DLMS_Options:SetScript('OnDragStart', function() DLMS_Options:StartMoving() end)
	DLMS_Options:SetScript('OnDragStop', function() DLMS_Options:StopMovingOrSizing() end)
	
	-- Show the DLMS_Options frame
	DLMS_Options:Show()
end


oClose:SetScript("OnClick",
	function()
		DLMS_Options:Hide()
		InterfaceOptionsFrame:Hide()
		GameMenuFrame:Hide()
		DLMS_Options:SetParent(nil)
	end
)

oFloat:SetScript("OnClick",
	function()
		InterfaceOptionsFrame:Hide()
		GameMenuFrame:Hide()
		floatDLMSOpt()
	end
)

function comma_value(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

local tooltip
local function create()
	local tip, leftside = DLMS_CreateFrame("GameTooltip"), {}
	for i = 1, 5 do -- 4 to check for the extra line in Color Blind Mode AND the xmog tag which puts Soulbound on line 4
		local L,R = tip:CreateFontString(), tip:CreateFontString()
		L:SetFontObject(GameFontNormal)
		R:SetFontObject(GameFontNormal)
		tip:AddFontStrings(L,R)
		leftside[i] = L
	end
	tip.leftside = leftside
	return tip
end

local function IsSoulbound(bag, slot)   -- returns boolean
	tooltip = tooltip or create()
	tooltip:SetOwner(UIParent,"ANCHOR_NONE")
	tooltip:ClearLines()
	tooltip:SetBagItem(bag, slot)
	local t1 = tooltip.leftside[2]:GetText()
	local t2 = tooltip.leftside[3]:GetText()
	local t3 = tooltip.leftside[4]:GetText()
	local t4 = tooltip.leftside[5]:GetText()
	tooltip:Hide()
	return ((t1 == ITEM_SOULBOUND) or (t2 == ITEM_SOULBOUND) or (t3 == ITEM_SOULBOUND) or (t4 == ITEM_SOULBOUND))
end

local sellItems = false
local sellTime = 0
--local cbag = 0
--local cslot = 0
local print_sell_header = true
local tsVal = 0
local tItems = 0
									
local function Sell()

	tItems = tItems + SellableItems[ikey].sz
	tsVal = tsVal + SellableItems[ikey].sVal

	local stack = ""
						
	if(print_sell_header) then 
		print(DLMS_HEADER..DLMS_COLOR("Selling Item(s)...",2))
		print_sell_header = false
	end
																			
	UseContainerItem(SellableItems[ikey].bag, SellableItems[ikey].slot)

	if(SellableItems[ikey].sz > 1) then 
		stack = " x "..SellableItems[ikey].sz	
	end
	
	print(DLMS_COLOR("> Selling: ",2)..SellableItems[ikey].link..stack..SellableItems[ikey].tag)
	ikey = ikey + 1

	if(SellableItems[ikey] == nil or not sellItems) then

		print_sell_header = true
		sellItems = false
		
		if(tItems > 0) then
			local gAmount = GetCoinTextureString(tsVal,10)
			print(DLMS_HEADER.."Sold "..DLMS_COLOR(tItems,2).." item(s) totaling: "..gAmount)
		end
		
		tsVal = 0
		tItems = 0
		ikey = 0
	end
end

local function UpdateSellData()
		
	for bag = 0, NUM_BAG_SLOTS do
	
		for slot = 0, GetContainerNumSlots(bag) do
			
			local SellItem = false
			local tag = ""
			local link = GetContainerItemLink(bag, slot)
			
			if(link) then
				local i_id = select(2, GetItemID(link))
				local n = select(1, GetItemInfo(link))
				
				if(not tContains(autosell_ignore_list, i_id)) then
				
					local iQuality = select(3, GetItemInfo(link))
					local iValue = select(11, GetItemInfo(link))
					local iType = select(6, GetItemInfo(link))
					--local ilvl, l2, l3 = GetDetailedItemLevelInfo(link)					
					
					if(tContains(autosell_safe_list, i_id)) then
						SellItem = true
						tag = " \124cFF00bb00(autosell safe list)\124r"
					elseif((iValue > 0)) then

						if(iQuality == 0) then  --not IsSoulbound and 
							SellItem = true
						else
							if(OptionsDB.ISQ and not IsSoulbound(bag,slot)) then
							
								if((iQuality == 2)
									and ((iType == "Armor") 
									or  (iType == "Weapon"))) 
								then
										SellItem = true
								--elseif(iQuality == 3 
								--	and ((iType == "Armor") 
								--	or  (iType == "Weapon")) 
								--	and ilvl <= 40)
								--then
								--		--SellItem = true	
								end
							end
						end
					end
					
					if(SellItem) then
					
						local stackSize = select(2,GetContainerItemInfo(bag, slot))
						local sVal = iValue * stackSize						
						
						SellableItems[ikey] = {}
						SellableItems[ikey].link = link
						SellableItems[ikey].bag = bag
						SellableItems[ikey].slot = slot
						SellableItems[ikey].tag = tag
						SellableItems[ikey].sVal = sVal
						SellableItems[ikey].sz = stackSize
						ikey = ikey + 1
					end
				end
			end
		end
	end
	
	ikey = 0
	--print("DLMS: Update done...")
	--print(#SellableItems)
	--ListDB(SellableItems)
end

local function UpdateBagValue()
		
	local bag_value = 0

	for bag = 0, NUM_BAG_SLOTS do
	
		for slot = 0, GetContainerNumSlots(bag) do
			
			local AddItem = false
			local link = GetContainerItemLink(bag, slot)
			
			if(link) then
				local i_id = select(2, GetItemID(link))
				local n = select(1, GetItemInfo(link))
				
				if(not tContains(autosell_ignore_list, i_id)) then
				
					local iQuality = select(3, GetItemInfo(link))
					local iValue = select(11, GetItemInfo(link))
					local iType = select(6, GetItemInfo(link))
					
					if(tContains(autosell_safe_list, i_id)) then
						AddItem = true
					elseif((iValue > 0)) then

						if(iQuality == 0) then  --not IsSoulbound and 
							AddItem = true
						else
							if(OptionsDB.ISQ and not IsSoulbound(bag,slot)) then
							
								if((iQuality == 2)
									and ((iType == "Armor") 
									or  (iType == "Weapon"))) 
								then
										AddItem = true
								end
							end
						end
					end
					
					if(AddItem) then
					
						local stackSize = select(2,GetContainerItemInfo(bag, slot))
						local sVal = iValue * stackSize						
						
						bag_value = bag_value + sVal
					end
				end
			end
		end
	end
	
	return bag_value

end

local function Update_Bags()

	local tSlots = 0
	local freeSlots = 0
	local tItems = 0
	local bagType = 0
	
	for bag = 0, NUM_BAG_SLOTS do
		local numSlots = GetContainerNumSlots(bag)
		if(numSlots ~= 0) then
			tSlots = tSlots + numSlots
			bagType = select(2,GetContainerNumFreeSlots(bag))
			if(bagType == 0) then freeSlots = freeSlots + select(1,GetContainerNumFreeSlots(bag)) end
		end
	end
	
	if(freeSlots == 0) then Bags_Full = true else Bags_Full = false end
	
	tItems = (tSlots - freeSlots)

	--local Per_Free_Space  = ((freeSlots/tSlots)*100) -- percentage of free bag slots
	local Per_Space_Taken = ((tItems/tSlots)*100) -- percentage of bag space taken by items
	
	
	if(Per_Space_Taken >= 87.5) then lowBagSpace = true; asr:Show(); --[[DLMS_Info_Tex lbs:Show() ]] else lowBagSpace = false; asr:Hide(); --[[DLMS_Info_Tex lbs:Hide() ]] end
		
	r = 0
	g = 1

	if(Per_Space_Taken > 96) then r = 1; g = 0 
	elseif(Per_Space_Taken > 92) then r = 1; g = .25 
	elseif(Per_Space_Taken > 87.5) then  r = 1; g = .50 
	elseif(Per_Space_Taken > 75) then r = 1; g = .75 
	elseif(Per_Space_Taken > 60) then r = 1; g = 1 end
	
	fs_Slots:SetText(freeSlots)
	fs_Slots:SetTextColor(r,g,0,0.8)
	
	--bgf2:SetTexture(r,g,0,.8)
	--bgf2:SetHeight(bg2:GetHeight() * (tItems/tSlots))

	local money = 0
	
	if(OptionsDB.SBB) then 
		money = GetMoney()
	else
		money = UpdateBagValue()
	end
	
	local gold = floor(abs(money / 10000))
	
	if(gold < 1) then
		money = GetCoinTextureString(money, 10)
		Money_Frame_FS:SetText(money)
	else
		gold = GetCoinTextureString(gold.."0000",10)
		Money_Frame_FS:SetText(comma_value(gold))
	end
end

local isMoving = false
local isMouseOver = false
local bfadeTime = 0
local bagCheck = 0

DLMS_Button:SetScript("OnUpdate",
	function(self, tPassed)
		bagCheck = bagCheck + tPassed
			
		if(bagCheck >= 1) then
			Update_Bags()
			bagCheck = 0
		end

		if(bfadeTime < GetTime() - 3) then
			local a = self:GetAlpha()
			if(fade) then
				if(a >= 0.3 and not isMouseOver) then 
					self:SetAlpha(a - 0.025)
				end
			end
		end
				
		if(isMouseOver) then
			if(GameTooltip:GetOwner() ~= self) then

				local state = OptionsDB.enabled
				
				if(state) then state = DLMS_COLOR("Enabled","Enable") else state = DLMS_COLOR("Disabled","Disable") end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddDoubleLine(DLMS_HEADER..DLMS_VERSION, state)
				GameTooltip:AddDoubleLine("Inventory Value: ", GetCoinTextureString(UpdateBagValue(), 10))
				
				if(ADJ_checkbox:GetChecked()) then
					GameTooltip:AddDoubleLine("Auto Delete Junk: ", DLMS_COLOR("ON",3))
					GameTooltip:AddTexture(DLMS_ICON_ALERT)
				end
				
				if(IsInRaid() and OptionsDB.DIR) then
					GameTooltip:AddLine("You are in a Raid Group and have chosen to disable DLMS looting and automatic loot rolls.", 1,1,1, true)
					GameTooltip:AddTexture(DLMS_ICON_ALERT)
				end

				if(Bags_Full) then
					GameTooltip:AddLine("You're bags are full.", 1,1,1, true)
					GameTooltip:AddTexture(DLMS_ICON_ALERT)
					
				elseif(lowBagSpace) then
					GameTooltip:AddLine("You're almost out of bag space.", 1,1,1, true)
					GameTooltip:AddTexture(DLMS_ICON_ALERT)
				end
				
				GameTooltip:AddLine("------------------------------------------------")
				GameTooltip:AddDoubleLine("Left Click", "Drag Button")
				GameTooltip:AddDoubleLine("Right Click", "Enable/Disable DLMS")
				GameTooltip:AddDoubleLine("Shift+Left Click", "DLMS Options")
				GameTooltip:AddDoubleLine("Shift+Right Click", "Button Options")
				GameTooltip:AddDoubleLine("Shift+Ctrl L-Click", "Auto Delete Junk On/Off")
				GameTooltip:Show()
			end
		else
			if(GameTooltip:GetOwner() == self) then
				GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
				GameTooltip:Hide()
			end
		end
	end
)

DLMS_Button:SetScript("OnEnter",
	function(self, m)
		if(fade) then self:SetAlpha(1.0) end
		isMouseOver = true
	end
)

DLMS_Button:SetScript("OnLeave",
	function(self, m)
		bfadeTime = GetTime()
		GameTooltip:Hide()
		isMouseOver = false
	end
)

DLMS_Button:SetScript("OnMouseDown",
	function(self, button)
		if(not OptionsDB.LOC) then
			if(button == "LeftButton") then
				isMoving = true
				self:StartMoving()
			end
		end
	end
)

DLMS_Button:SetScript("OnMouseUp",
	function(self, button)
		if(isMoving) then
			isMoving = false
			self:StopMovingOrSizing()
		end

		--isMouseOver = DLMS_Button:IsMouseOver(2,-2,-2,2)
		if(IsShiftKeyDown() and IsControlKeyDown() and button == "LeftButton" and isMouseOver) then
			ADJ_checkbox:Click("LeftButton", true)
		elseif(IsShiftKeyDown() and IsControlKeyDown() and button == "RightButton" and isMouseOver) then
			print(DLMS_HEADER.."Deleting junk...")
			DELETE_JUNK()
		elseif(IsShiftKeyDown() and button == "LeftButton" and isMouseOver) then
			if(DLMS_Options:IsVisible()) then 
				DLMS_Options:Hide()
				DLMS_Options:SetParent(nil)
			else
				floatDLMSOpt()
			end
		elseif(IsShiftKeyDown() and button == "RightButton") then
			Update_DLMS_Menu()
			EasyMenu(DLMS_Menu, DLMS_Menu_Frame, DLMS_Menu_Frame, 0 , 0, "MENU")
		elseif(button == "RightButton" and isMouseOver) then
			DIS_checkbox:Click("LeftButton", true)
			if(OptionsDB.enabled) then 	
				DLMS_Btn_Tex4:SetTexture(DLMS_IND_GREEN) --Interface\\RAIDFRAME\\ReadyCheck-ReadyInterface\\ICONS\\INV_Misc_Bag_EnchantedMageweave
			else 	
				DLMS_Btn_Tex4:SetTexture(DLMS_IND_RED) --Interface\\RAIDFRAME\\ReadyCheck-ReadyInterface\\ICONS\\INV_Misc_Bag_EnchantedMageweave
			end
		end
	end
)	

DLMS_Options:SetScript("OnShow", 
	function(self)
		if(not tContains(UISpecialFrames, self:GetName())) then
			tinsert(UISpecialFrames, self:GetName())
		end
		PlaySoundFile(DLMS_OPTIONS_OPEN)
	end
)

DLMS_Options:SetScript("OnHide", 
	function(self)
		PlaySoundFile(DLMS_OPTIONS_CLOSE)
	end
)

local function PickItUp(slot)
	LootSlot(slot)
	ConfirmLootSlot(slot)
	return true
end

local function Update_DLMS(t,s)
	if(DLMS[t] == nil) then
		print(DLMS_HEADER.."Adding new Category: "..DLMS_COLOR(t,2))
		print(DLMS_HEADER.."Adding new "..DLMS_COLOR(t,2).." Type: "..DLMS_COLOR(s,2))
		print(DLMS_HEADER.."Setting "..DLMS_COLOR("default",2).." and looting item.")
		DLMS[t] = {}
		DLMS[t][s] = default
		newItem = true
		--newLoot = true
	elseif(DLMS[t][s] == nil) then
		print(DLMS_HEADER.."Adding new "..DLMS_COLOR(t,2).." Type: "..DLMS_COLOR(s,2))
		print(DLMS_HEADER.."Setting "..DLMS_COLOR("default",2).." and looting item.")
		DLMS[t][s] = default
		newItem = true
		--newLoot = true
	end
	if(IsEmpty) then IsEmpty = false end
	Update_Catagories()
end

local function IsWantedItem(t,s)
	return DLMS[t][s] or nil
end

local already_deleted = false

local function DELETE_JUNK()
	local link, q = nil, nil
	for b=0, NUM_BAG_SLOTS do
	   for s=1, GetContainerNumSlots(b) do
		  link = GetContainerItemLink(b,s)
		  if(link) then
			 q = select(4, GetContainerItemInfo(b,s))
			 if(q == 0) then
				PickupContainerItem(b,s)
				DeleteCursorItem()
				print(DLMS_HEADER..link.." has been deleted...")
			 end
		  end
		  link, q = nil, nil
	   end
	end
	already_deleted = true
end

-- EVENTS --

local function DLMS_OnEvent(self, event, ...)

	if(event == "VARIABLES_LOADED") then
		local autoLoot = GetCVar("autoLootDefault")
		if(autoLoot == "1") then
		   print(DLMS_HEADER.."WoW Auto Loot is on, turning it off...")
		   
		   local cvar_success = SetCVar("autoLootDefault", 0)
		   
		   if(cvar_success) then
			  print(DLMS_HEADER.."You can temporarily bypass DLMS by using your default Auto Loot key (e.g. SHIFT) while looting to loot all items.")
		   end
		end
	end
	
	if(event == "ADDON_LOADED") then
		for i=1,select("#", ...) do
			local AddOnName = select(i, ...)
			--print(AddOnName)
			if(AddOnName == "DLMS") then
				print(DLMS_HEADER..DLMS_VERSION.." loading...")
				
				
				if(next(svdDB) == nil) then
					IsEmpty = true 
				else
					DLMS = svdDB
				end
					
				if(next(svOptionsDB) == nil) then
					OptionsDB = oDefaultsDB
				else
					OptionsDB = svOptionsDB
				end

				if(sv_white_list 	~= nil) then loot_white_list 		= sv_white_list 	end
				if(sv_black_list 	~= nil) then loot_black_list 		= sv_black_list 	end
				if(sv_safe_list		~= nil) then autosell_safe_list 	= sv_safe_list		end
				if(sv_ignore_list 	~= nil) then autosell_ignore_list 	= sv_ignore_list	end

				if(IsEmpty) then
					print(DLMS_HEADER.."Empty Database. Categories Disabled.")
					print(DLMS_HEADER.."Setting "..DLMS_COLOR("\"Loot All and GO!\"",2).." as default.")
					print(DLMS_HEADER.."Needs to build Category Options... Go Loot!")
				else
					print(DLMS_HEADER.."Found existing database, building category options...")
				end
				
				DLMSBuildOptions()
				
				if(not OptionsDB.enabled) then 
					print(DLMS_HEADER.."Is currently \124cFFFF0000disabled.\124r")
					DLMS_Btn_Tex4:SetTexture(DLMS_IND_RED) --Interface\\RAIDFRAME\\ReadyCheck-ReadyInterface\\ICONS\\INV_Misc_Bag_EnchantedMageweave
				else
					DLMS_Btn_Tex4:SetTexture(DLMS_IND_GREEN) --Interface\\RAIDFRAME\\ReadyCheck-ReadyInterface\\ICONS\\INV_Misc_Bag_EnchantedMageweave
				end
				
				if(OptionsDB.SBS) then 
					fs_Slots:Show()
					DLMS_Money_Frame:Show()
				else 
					fs_Slots:Hide()
					DLMS_Money_Frame:Hide()
				end
				
				if(OptionsDB.SCL == nil) then DLMS_Button:SetScale(1.0) else DLMS_Button:SetScale(OptionsDB.SCL) end
				--if(OptionsDB.SBB) then bagFill2:Show() else bagFill2:Hide() end
				--if(OptionsDB.SDI) then lr:Show() else lr:Hide() end
				
				if(OptionsDB.FAD) then fade = OptionsDB.FAD else DLMS_Button:SetAlpha(OptionsDB.TRN) end
				
				if(OptionsDB.EDB) then DLMS_Button:Show() else DLMS_Button:Hide() end
				
				Update_Bags()
				options_loaded = true
				self:UnregisterEvent("ADDON_LOADED")
			end
		end
	end
	
	if(event == "BAG_UPDATE" and auto_delete_junk and not already_deleted) then
		DELETE_JUNK()
	end
	
	if(event == "PLAYER_LOGOUT") then
		svdDB = DLMS
		svOptionsDB = OptionsDB
		sv_white_list  = loot_white_list
		sv_black_list  = loot_black_list
		sv_safe_list   = autosell_safe_list
		sv_ignore_list = autosell_ignore_list
	end
		
	if(OptionsDB.enabled) then	

		-- Reset it all and shut it down --
		if(event == "MERCHANT_CLOSED") then 
			sellItems = false 
			--current_bag = 0
			--current_slot = 0
			tsVal = 0
			tItems = 0
			print_sell_header = true
			ikey = 0
		end
		
	-- Auto Sell/Repair Block --
		if(event == "MERCHANT_SHOW") then
				
			-- Auto Repair --
			if(OptionsDB.ARG) then
			
				local rCost, mCanRepair = GetRepairAllCost()
				
				if(mCanRepair) then 
					print(DLMS_HEADER..DLMS_COLOR("Repairing All Items: ",2)..GetCoinTextureString(rCost,10))
					RepairAllItems()
				end
			end
			-- END --
			
			-- Auto Sell Junk--
			if(OptionsDB.ASJ) then
				-- Clear/Reset Items table before update to account for changes in inventory.
				SellableItems = {}
				UpdateSellData()
				
				if(next(SellableItems) ~= nil) then
					sellItems = true
					sellTime = GetTime()
				end
			end
			-- END --
		end
-- END --

-- Checking for loot rolls.. --
		if(event == "START_LOOT_ROLL" and not alreadyInRaid) then
				-- and not OptionsDB.DIR) 
			--print("Loot roll fired...")
			RollID = select(1,...)
			ItemRollIDs = {}
			tinsert(ItemRollIDs, RollID)

			local _,N,_,Q,BoP = GetLootRollItemInfo(RollID)
			local lrILink = GetLootRollItemLink(RollID)
			if(OptionsDB.ARL ~= false) then
				if(OptionsDB.ARL > 0) then
					if((Q <= OptionsDB.ARL)) then
						print(DLMS_HEADER.."Auto Rolling \""..DLMS_COLOR("Greed" ,2).."\" on "..lrILink.."...")
						ConfirmLootRoll(RollID, 2)
					end
				else 
					print(DLMS_HEADER..DLMS_COLOR("Auto Passing",2).." on "..lrILink)
					ConfirmLootRoll(RollID, 0)
				end
			end
		end
		
		if(event == "CONFIRM_LOOT_ROLL") then
			print("Debug: Do we ever even get here??")
			if(OptionsDB.ARL) then ConfirmLootSlot(select(1,...)) end
		end


-- Loot Block --
		if(event == "LOOT_OPENED" and arg1 ~= 1 and not alreadyInRaid) then
						-- and not OptionsDB.DIR) 
			if((GetCVar("autoLootDefault") == "1") or IsModifierKeyDown()) then
				print(DLMS_HEADER.."Auto Loot enabled, bypassing DLMS and looting all items...")
			else
				local enforce_Loot_by_Category = OptionsDB.ELC
				--local we_got_nothing = true
				--local update = false
				--local track = 0			

				if(Bags_Full) then
					print(DLMS_HEADER.."Your bags are full. Will loot what we can...")
				end

				for i = 1, GetNumLootItems() do
					
					
					local loot_item = false
					local blacklisted = false
					local BeingRolledOn = false
					
					local LootIsCurrency = (GetLootSlotType(i) > 1) and true or false
						
					if(LootIsCurrency) then
						PickItUp(i)
					else
						local loot_link = GetLootSlotLink(i)
						
						if(loot_link) then
						
							local i_id = select(2, GetItemID(loot_link))
							
							local stackSize 		= select(3, GetLootSlotInfo(i))
							
							local itemName 			= select(1 ,GetItemInfo(loot_link))
							local itemLink 			= select(2 ,GetItemInfo(loot_link))
							local itemQuality		= select(3, GetItemInfo(loot_link))
							local itemType 			= select(6 ,GetItemInfo(loot_link))
							local itemSubType 		= select(7 ,GetItemInfo(loot_link))
							local itemStackCount 	= select(8 ,GetItemInfo(loot_link))
							local itemTexture 		= select(10,GetItemInfo(loot_link))
							local itemSellPrice 	= select(11,GetItemInfo(loot_link))

							Update_DLMS(itemType,itemSubType)
							
							if(next(loot_black_list) ~= nil) then
								if(tContains(loot_black_list, i_id)) then
									print(DLMS_HEADER..itemLink.." is "..DLMS_COLOR("Blacklisted",2)..".")
									blacklisted = true
								end
							end
							
							if(not blacklisted) then
							-- Checking for Loot Rolls if Grouped -- I'm not sure this even still applies or if the loot roll event even still fires
								if(IsInGroup() and next(ItemRollIDs) ~= nil) then
									for k,_ in pairs(ItemRollIDs) do
										local name = select(2, GetLootRollItemInfo(ItemRollIDs[k]))
										if(itemName == name) then
											print(DLMS_HEADER..itemLink.." is currently being rolled for...")
											BeingRolledOn = true
										end
									end
								end
								
								if(not BeingRolledOn) then
								
									if(next(loot_white_list) ~= nil) then
										if(tContains(loot_white_list, i_id)) then
											loot_item = true
										end
									end

										
									-- Just loot all --
									if(OptionsDB.LAG and not loot_item) then
										loot_item = true
									else
									
										local q = OptionsDB.LBQ
										local v = OptionsDB.LBV
										
									-- Loot by Category --
										if(OptionsDB.LBC) then
																	
											local iWantIt = IsWantedItem(itemType,itemSubType)
											
											if(iWantIt) then
												-- determine if quality or value sliders are enabled
												if(q or v) then  
													if(itemType == "Weapon" or itemType == "Armor") then
														if((q and v) and itemQuality >= q and itemSellPrice >= v) then
															loot_item = true
														else
															if(q and itemQuality >= q) then
																loot_item = true
															elseif(v and itemSellPrice >= v) then
																loot_item = true
															end
														end
													else
														loot_item = true
													end
												else
													loot_item = true
												end
											else
												if(not enforce_Loot_by_Category) then 
													if((q and v) and itemQuality >= q and itemSellPrice >= v) then
														loot_item = true
													else
														if(q and itemQuality >= q) then
															loot_item = true
														elseif(v and itemSellPrice >= v) then
															loot_item = true
														end
													end
												end
											end
										elseif(q or v) then
											if((q and v) and itemQuality >= q and itemSellPrice >= v) then
												loot_item = true
											else
												if(q and itemQuality >= q) then
													loot_item = true
												elseif(v and itemSellPrice >= v) then
													loot_item = true
												end
											end
										end
									end
									
									if(loot_item) then
										PickItUp(i)
										--we_got_nothing = false
									else
										if(OptionsDB.SNL) then
											print(DLMS_HEADER..itemLink..DLMS_COLOR(" was not looted.",2))
										end
									end
								end
							end
						end
					end
				end
				--print(#notLooted)
				--ListDB(notLooted)
				--if(we_got_nothing) then print(DLMS_HEADER.."Didn't loot anything, either theres nothing we want or all options are disabled?")
				if(newItem) then print(DLMS_HEADER.."Check Options:"..DLMS_COLOR(" New item(s) added.",2)); newItem = false end
				if(not OptionsDB.KLO and not IsShiftKeyDown()) then CloseLoot() end
				already_deleted = false
			end
		end	
	end
-- END --
end

local lists = {
	"loot_white_list",
	"loot_black_list",
	"autosell_safe_list",
	"autosell_ignore_list",
}

local process = GetTime()
local a_list_was_cached = false

local function prefetch()
	
	local tag = ""
	local count = 0
	
	for i = 1, 4 do	
		
		if(i == 1) then tag = "Loot White List:" end
		if(i == 2) then tag = "Loot Black List:" end
		if(i == 3) then tag = "Autosell Safe List:" end
		if(i == 4) then tag = "Autosell Ignore List:" end
		
		if(next(_G[lists[i]]) ~= nil) then
			print(DLMS_HEADER.."Caching: "..DLMS_COLOR(tag,2).." Processing: "..DLMS_COLOR(#_G[lists[i]],2).." items.")
			a_list_was_cached = true
			for k,v in pairs(_G[lists[i]]) do
				GetItemInfo(v) -- Just make it query the server...
				count = count + 1
				if(count % DLMS_PREFETCH == 0) then
					count = 0
					process = GetTime()
					coroutine.yield()
				end
			end
		end
	end
end

local cache = coroutine.create(prefetch)

local update,autoSort = 0,0
local load_done = false
local print_msg = true

local function DLMS_OnUpdate(self, t)

	--autoSort = autoSort + t
	--if(autoSort >= 5) then
	--	SortBags()
	--	autoSort = 0
	--end

	
	world = select(3,GetNetStats())
	local v = asrSlider:GetValue()
	local r = world*v
	ASR_Value_Label:SetText(string.format("(%.1fx)",v)..string.format("(%.1fms)",r))
	
	if(sellItems) then

		local rate = ((OptionsDB.ASR ~= nil) and OptionsDB.ASR or 1)
		local sellDelay = ((world * rate)/1000)
		

		if(GetTime() >= (sellTime+sellDelay)) then
			Sell()
			sellTime = GetTime()
		end
	end
		
	
	if(process < (GetTime() - DLMS_CACHE_DELAY) and not cached) then
		if(coroutine.status(cache) ~= "dead") then
			coroutine.resume(cache)
		else
			cached = true
			if(options_loaded) then load_done = true end
		end
	end
	
	if(load_done and print_msg) then
		print(DLMS_HEADER.."Load done... "..DLMS_COLOR("/dlms",2).." for options.")
		print_msg = false
	end
	
	update = update + t
	if(update >= 3) then
		if(IsInRaid() and OptionsDB.enabled and OptionsDB.DIR and not alreadyInRaid) then
			print(DLMS_HEADER.."You entered a raid group, DLMS looting features have been disabled!")
			DLMS_Info_Tex:Show() --Interface\\RAIDFRAME\\ReadyCheck-ReadyInterface\\ICONS\\INV_Misc_Bag_EnchantedMageweave
			alreadyInRaid = true
		elseif(not IsInRaid() and alreadyInRaid) then
			print(DLMS_HEADER.."You have left the raid group, DLMS looting features have regained control!")
			DLMS_Info_Tex:Hide() --Interface\\RAIDFRAME\\ReadyCheck-ReadyInterface\\ICONS\\INV_Misc_Bag_EnchantedMageweave
			alreadyInRaid = false
		elseif(OptionsDB.enabled and not OptionsDB.DIR and alreadyInRaid) then
			print(DLMS_HEADER.."DLMS looting features have been re-enabled.")
			DLMS_Info_Tex:Hide() --Interface\\RAIDFRAME\\ReadyCheck-ReadyInterface\\ICONS\\INV_Misc_Bag_EnchantedMageweave
			alreadyInRaid = false
		end
		update = 0
	end
end


-- DLMS style loot messages --
local function DLMS_Loot(self, event, arg1, ...)
	--print(event)
	if(OptionsDB.UWM or not OptionsDB.enabled) then
		return false, arg1, ...
	else
		if(string.find(arg1,"loot")) then
		--print("Found it")
			arg1 = gsub(arg1, "You receive loot:", DLMS_LOOT_MSG)
			arg1 = gsub(arg1, "(x)(%d+)"," \124cFFffffff %1 %2\124r") 
			arg1 = "\124cFF00aa00"..arg1.."\124r" --..--Loot_Tag
			--Loot_Tag = ""
		end
		return false, arg1, ...
	end
end

local function DLMS_Money(self, event, arg1, ...)
	if(OptionsDB.UWM or not OptionsDB.enabled) then
		return false, arg1, ...
	else
		local g,s,c = strsub(GOLD_AMOUNT,3), strsub(SILVER_AMOUNT,3), strsub(COPPER_AMOUNT,3)
		arg1 = gsub(arg1,"You loot", DLMS_MONEY_MSG_1 )
		arg1 = gsub(arg1,"Your share of the loot is", DLMS_MONEY_MSG_2)
		arg1 = gsub(arg1, "," ,"")
		arg1 = "\124cFFffffff"..arg1
		arg1 = gsub(arg1,c, DLMS_COPPER_TEX)
		arg1 = gsub(arg1,s, DLMS_SILVER_TEX)
		arg1 = gsub(arg1,g, DLMS_GOLD_TEX)
		arg1 = arg1.."\124r"
		return false, arg1, ...
	end
end

local function DLMS_Bag_Item_OnModifiedClick(self, button)

	local bag, slot  = GetMouseFocus():GetParent():GetID(), GetMouseFocus():GetID()
	local link = select(7, GetContainerItemInfo(bag, slot))
	local link_tbl = {}

	if(link) then
		tinsert(link_tbl, link)
		
		-- Need the item name and value.
		local id 	= select(2,GetItemID(link))
		local iv	= select(11,GetItemInfo(link))
		
		if(IsLeftAltKeyDown() and button == "RightButton") then
			if(tContains(loot_black_list, id)) then
				Update_List("remove", link_tbl, loot_black_list)
			else
				Update_List("add", link_tbl, loot_black_list)
			end
		elseif(IsLeftAltKeyDown() and button == "LeftButton") then
			if(tContains(loot_white_list, id)) then
				Update_List("remove", link_tbl, loot_white_list)
			else
				Update_List("add", link_tbl, loot_white_list)
			end
		elseif(IsRightAltKeyDown() and button == "RightButton") then
			if(tContains(autosell_ignore_list, id)) then
				Update_List("remove", link_tbl, autosell_ignore_list)
			else
				if(iv > 0) then
					Update_List("add", link_tbl, autosell_ignore_list)
				else
					print(DLMS_HEADER..DLMS_COLOR("Autosell Ignore List:",2)..
															link.." Not Added: Item has no value.")
				end
			end
		elseif(IsRightAltKeyDown() and button == "LeftButton") then
			if(tContains(autosell_safe_list, id)) then
				Update_List("remove", link_tbl, autosell_safe_list)
			else
				if(iv > 0) then
					Update_List("add", link_tbl, autosell_safe_list)
				else
					print(DLMS_HEADER..DLMS_COLOR("Autosell Safe List:",2)..
															link.." Not Added: Item has no value.")
				end
			end
		end
		link_tbl = nil
	end
end

--local curBag,curSlot
local cleared = true

--local function SetBagSlot(bag,slot)
--	curBag, curSlot = bag, slot
--end

--hooksecurefunc(GameTooltip,"SetBagItem", function(self,bag,slot) --[[SetBagSlot(bag,slot)]] print(bag,slot) end)

local function DLMS_OnTooltipSetItem(self)
	if(cleared) then
	
		local link = select(2,self:GetItem())
		
		if(link) then
		
			--local q 	= select(3, GetItemInfo(link))
			local cat   = select(6 ,GetItemInfo(link))
			local type  = select(7 ,GetItemInfo(link))
			
			if(cat ~= nil and type ~= nil) then
				self:AddLine(DLMS_HEADER..cat.." - "..type)
			end
			
			local i_id = select(2, GetItemID(link))
			if(tContains(autosell_safe_list, i_id)) then
				self:AddLine(DLMS_HEADER.."Will always sell this item.")
			end
			if(tContains(autosell_ignore_list, i_id)) then
				self:AddLine(DLMS_HEADER.."Will never sell this item.")
			end
			if(tContains(loot_white_list, i_id)) then
				self:AddLine(DLMS_HEADER.."Will always loot this item.")
			end
			if(tContains(loot_black_list, i_id)) then
				self:AddLine(DLMS_HEADER.."Will never loot this item.")
			end
		end
	end
		cleared = false
		--curBag, curSlot = nil, nil
end
 
local function DLMS_OnTooltipCleared(self)
	cleared = true
end

function SlashCmdList.DLMS(msg, editbox)
	
	local sw = ""
	local tmp = ""
	local ilinks = {}
	
	if(msg ~= "") then

		for v in string.gmatch(msg, "[^ ]+") do
			tmp = strjoin(" ", tmp, v) 
		end

		tmp = strtrim(tmp) 
		msg, sw, tmp = strsplit(" ", tmp, 3)

		--if(tmp ~= nil) then tmp = strtrim(tmp); links = { string.match(tmp, "(.+)\a(.+)\a(.+)") } end 
		if(tmp ~= nil) then
			tmp = gsub(tmp, "%]\124h\124r ", "%]\124h\124r\a") 	
			tmp = strtrim(tmp)
			ilinks = { strsplit("\a", tmp) }
		end
	end
	
	if(msg == "b_list") then
		Update_List(sw, ilinks, loot_black_list)
	elseif(msg == "w_list") then
		Update_List(sw, ilinks, loot_white_list)
	elseif(msg == "as_safe") then
		Update_List(sw, ilinks, autosell_safe_list)
	elseif(msg == "as_ignore") then
		Update_List(sw, ilinks, autosell_ignore_list)
	elseif(msg == "") then 
		print(DLMS_HEADER..DLMS_COLOR(DLMS_VERSION.." Usage: ",2).."/dlms [ "..DLMS_COLOR("options", 2).." | "..DLMS_COLOR("loot", 2).." | "
										..DLMS_COLOR("button", 2).." ("..DLMS_COLOR("reset", 2)..") | "..DLMS_COLOR("delete_junk", 2).." | "..DLMS_COLOR("auto_delete", 2).." ]")
		print(" - "..DLMS_COLOR("/dlms",1).." - "..DLMS_COLOR("Prints this help",1))
		print(" - "..DLMS_COLOR("/dlms",1)..DLMS_COLOR(" options",2).." - Opens \"Options\"")
		print(" - "..DLMS_COLOR("/dlms",1)..DLMS_COLOR(" loot",2).." - Enables/Disables DLMS")
		print(" - "..DLMS_COLOR("/dlms",1)..DLMS_COLOR(" button",2).." - Enables/Disables the DLMS Button")
		print(" - "..DLMS_COLOR("/dlms",1)..DLMS_COLOR(" button reset",2).." - Resets the button in case you lose it.")
		print(" - "..DLMS_COLOR("/dlms",1)..DLMS_COLOR(" delete_junk",2).." - Delete ALL junk from your bags now.")
		print(" - "..DLMS_COLOR("/dlms",1)..DLMS_COLOR(" auto_delete",2).." - Toggle auto deleting of junk on/off.")
		print(DLMS_COLOR("DLMS List Usage: ", 1).."/dlms [ "..DLMS_COLOR("w_list", 2).." | "..DLMS_COLOR("b_list", 2).." | "
												..DLMS_COLOR("as_safe", 2).." | "..DLMS_COLOR("as_ignore", 2).." ]".." [ "..DLMS_COLOR("add",2)
												.." | "..DLMS_COLOR("remove",2).." ] "..DLMS_COLOR("[link1] [link2] ... [linkN]",2))
	elseif(msg == "delete_junk") then
		print(DLMS_HEADER.."Deleting junk...")
		DELETE_JUNK()
	elseif(msg == "auto_delete") then
		ADJ_checkbox:Click("Leftbutton", true)
	elseif(msg == "options") then
		floatDLMSOpt()
	elseif(msg == "button") then
		if(sw == "reset") then
			DLMS_Button:ClearAllPoints()
			DLMS_Button:SetParent(UIParent)
			DLMS_Button:SetPoint("CENTER",UIParent,"CENTER",0,0)
			DLMS_Button:SetAlpha(1.0)
		else
			EDB_checkbox:Click("LeftButton", true)
		end
	elseif(msg == "loot") then
		DIS_checkbox:Click("LeftButton", true)
	end
	ilinks = nil
end

DLMS_Frame:SetScript("OnEvent", DLMS_OnEvent)
DLMS_Frame:SetScript("OnUpdate", DLMS_OnUpdate)
ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", DLMS_Loot)
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONEY", DLMS_Money)
InterfaceOptions_AddCategory(DLMS_Options)
hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", DLMS_Bag_Item_OnModifiedClick)
GameTooltip:HookScript("OnTooltipSetItem", DLMS_OnTooltipSetItem)
GameTooltip:HookScript("OnTooltipCleared", DLMS_OnTooltipCleared)
