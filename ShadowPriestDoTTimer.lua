-- Author      : Kressilac /Duskwood - Bathral@BlackhandEU
-- UI elements borrowed from Shadow Timer and extended for better use.
-- Create Date : 25/10/2014


local _; -- workaround to prevent leaking globals

--ShadowPriestDoTTimerFrame_Default_X = 0;
--ShadowPriestDoTTimerFrame_Default_Y = 0;
--ShadowPriestDoTTimerFrame_Default_Size = 100;
--ShadowPriestDoTTimerFrame_Default_Scale = 1;

local MyAddon_UpdateInterval = 0.05; -- How often the OnUpdate code will run (in seconds)
local TimeSinceLastUpdate = 0;

local WarningTime = 600; -- WarningTime (in milliseconds)
local buffscorecurrent = 0;
local savedbuffscorecurrent = 0;

--Used to proove that a Priest is being played
local Priest = false;
local ShadowSpecc = false;
local ActiveSpec = 1;

--Used to keep track of the DoTs on a Mob.
local moblist = {};
local isincombat = false;
local currentmob = nil;
local maxmoblist = 10;

--Save the previous ShadowOrbs number
local PrevShadowOrbsCount = "0 %";

--Buff modifier table for SaI with different Shadow orbs
local PrevShadowOrbs = {
	"33 %",
	"66 %",
	"100 %",
	"100 %",
	"100 %",
}

--MindFlay Insanity active indication
local MFI_Active = false;

--Used to prioritize DP texture over Shadoworbs
local Texture3used = false;

--Used to share Texture5 for Mindblast and SW:D
local Texture5used = false;

--Used to indivate UVLS is active
local UVLS_active = false;

--Used to determine if 2 piece T15 Set bonus is equipped
local set2t15 = false;

--Duration of DoTs for 2t15set bonus proc check
local VTduration = 0;
local SWPduration = 0;

--Shadowy Apparition array 
local ShadowyApp_GUID = {};
local MyID;
local extended = false;

----------------------------------------------
local WordPainID = 589;
local nameWordPain, rankWordPain, IconWordPain = GetSpellInfo(WordPainID);
--"Interface\\ICONS\\Spell_Shadow_ShadowWordPain.blp";
----------------------------------------------
local VTID = 34914
local nameVT, rankVT, IconVT, castTimeVT = GetSpellInfo(VTID)	
--"Interface\\ICONS\\Spell_Holy_Stoicism.blp";
----------------------------------------------
local PlagueID = 2944
local namePlague, rankPlague, IconPlague = GetSpellInfo(PlagueID);
--"Interface\\ICONS\\Spell_Shadow_DevouringPlague.blp";
----------------------------------------------
local WordDeathID = 32379;
local nameWordDeath, rankWordDeath, IconWordDeath = GetSpellInfo(WordDeathID);	--"Shadow Word: Death"
----------------------------------------------
local SPELL_POWER_SHADOW_ORBS  = SPELL_POWER_SHADOW_ORBS 
local IconShadowOrbs = "Interface\\ICONS\\spell_priest_shadoworbs.blp"
----------------------------------------------
local MindBlastID = 8092;
local nameMindBlast, rankMindBlast, IconMindBlast = GetSpellInfo(MindBlastID);
----------------------------------------------
local EmbraceID = 15286;
local nameEmbrace, rankEmbrace, IconEmbrace = GetSpellInfo(EmbraceID);	--"Vampiric Embrace"
--local IconEmbrace = "Interface\\ICONS\\spell_shadow_unsummonbuilding.blp"
----------------------------------------------
local PowerInfusionID = 10060;
local namePowerInfusion, rankPowerInfusion, IconPowerInfusion = GetSpellInfo(PowerInfusionID);
----------------------------------------------
local SurgeOfDarknessID = 87160;
local nameSurgeOfDarkness, rankSurgeOfDarkness, IconSurgeOfDarkness = GetSpellInfo(SurgeOfDarknessID);
----------------------------------------------
local SolaceInsanityID = 129197;
local nameSolaceInsanity, rankSolaceInsanity, IconSolaceInsanity = GetSpellInfo(SolaceInsanityID);
---------------------------------------------- 
local DivineInsightID = 124430;
local nameDivIn, rankDivIn, IconDivIn = GetSpellInfo(DivineInsightID);
----------------------------------------------
local MindbenderID = 123040;
local nameMindbender, rankMindbender, IconMindbender = GetSpellInfo(MindbenderID);
----------------------------------------------
local Shadowy_ApparitionsID = 148859;
----------------------------------------------
local UVLS_procID = 138963;
local _, _, IconUVLS = GetSpellInfo(UVLS_procID);
----------------------------------------------
local fluidity_ID = 138002;
local fluidity_name = GetSpellInfo(fluidity_ID);
------------------------------
local insanity_ID = 132573;
local insanity_name, _, IconInsanity = GetSpellInfo(insanity_ID);
------------------------------

local function PriestCheck()
	local _, englishClass = UnitClass("player");
	return englishClass;
end

--local function round(num) 
--    if num >= 0 then return math.floor(num+.5) 
--    else return math.ceil(num-.5) end
--end


local function Detect2T15()
    set2t15 = false;
    local t15items = 0;
    local t15set = {
        96674,96675,96676,96677,96678,
        95300,95301,95302,95303,95304,
        95930,95931,95932,95933,95934,
    };
    for i,v in ipairs(t15set) do
        if IsEquippedItem(v) then
            t15items = t15items + 1;
        end
    end
    if t15items >= 2 then 
    	set2t15 = true;
    end
--    if (set2t15 == true) then 
--    	DEFAULT_CHAT_FRAME:AddMessage("set2T15: true");
--    else
--      DEFAULT_CHAT_FRAME:AddMessage("set2T15: false");
--    end
end

local function HideAll()
	SPDT_Texture1:Hide();
	SPDT_Texture2:Hide();
	SPDT_Texture3:Hide();
	SPDT_Texture4:Hide();
	SPDT_Texture5:Hide();
	SPDT_Texture6:Hide();
	SPDT_Texture7:Hide();
	SPDT_Texture8:Hide();

	SPDT_TEXT1:Hide();
	SPDT_TEXT2:Hide();	
	SPDT_TEXT3:Hide();
	SPDT_TEXT4:Hide();
	SPDT_TEXT5:Hide();
	SPDT_TEXT6:Hide();
	SPDT_TEXT7:Hide();
	SPDT_TEXT8:Hide();
	
	SPDT_TEXT1Above:Hide();
	SPDT_TEXT2Above:Hide();
	SPDT_TEXT3Above:Hide();
	SPDT_TEXT3Above2:Hide();
	SPDT_TEXT4Above:Hide();
	SPDT_TEXT5Above:Hide();
	SPDT_TEXT6Above:Hide();
	SPDT_TEXT7Above:Hide();
	SPDT_TEXT8Above:Hide();
	
	buffscorecurrent = 0;
end

function SPDT_SetCooldownOffsets()
	local point, relativeTo, relativePoint, xOfs, yOfs;
	point, relativeTo, relativePoint, xOfs, yOfs = SPDT_TEXT1:GetPoint();
	SPDT_TEXT1:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
	point, relativeTo, relativePoint, xOfs, yOfs = SPDT_TEXT2:GetPoint();
	SPDT_TEXT2:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
	point, relativeTo, relativePoint, xOfs, yOfs = SPDT_TEXT3:GetPoint();
	SPDT_TEXT3:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
	--nothing for SPDT_TEXT4
	point, relativeTo, relativePoint, xOfs, yOfs = SPDT_TEXT5:GetPoint();
	SPDT_TEXT5:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
	point, relativeTo, relativePoint, xOfs, yOfs = SPDT_TEXT6:GetPoint();
	SPDT_TEXT6:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
	point, relativeTo, relativePoint, xOfs, yOfs = SPDT_TEXT7:GetPoint();
	SPDT_TEXT7:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
	point, relativeTo, relativePoint, xOfs, yOfs = SPDT_TEXT8:GetPoint();
	SPDT_TEXT8:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
end

local function FindCurrentMob()
	local targetguid = UnitGUID("playertarget");
	currentmob = nil;
	if (targetguid) then
		local i = 1;
		while not currentmob and i <= #moblist do
			if (moblist[i][1] == targetguid) then
				currentmob = moblist[i];
			end
			i = i + 1;
		end
	end
end

local function FindOrCreateCurrentMob(targetguid_given)
	local targetguid;
	if (targetguid_given) then
		targetguid = targetguid_given;
	else
		targetguid = UnitGUID("playertarget");
	end
	currentmob = nil;

	if (targetguid) then
		--DEFAULT_CHAT_FRAME:AddMessage("SPDT Player Target: " .. targetguid);
		local i = 1;
		while not currentmob and i <= #moblist do
			if (moblist[i][1] == targetguid) then
				currentmob = moblist[i];
			end
			i = i + 1;
		end

		if (not currentmob) then
			-- GUID, buffscoreVT, buffscoreSWP, timewhenVTwascasted, bool_UVLSactiveonVT, bool_UVLSactiveonSWP, timeUVLScastedonVT, timeULVScastedonSWP, timewhenSWPwascasted, buffscoreofSA_hitsonVT, buffscoreofSA_hitsonSWP
			currentmob = {targetguid, 0, 0, GetTime(), 0, 0, 0, 0, GetTime(), 0, 0};
			table.insert(moblist, currentmob);
			--DEFAULT_CHAT_FRAME:AddMessage("SPDT New mob: " .. currentmob[1]);
		else
			--DEFAULT_CHAT_FRAME:AddMessage("SPDT Found mob: " .. currentmob[1]);
		end
	end
end

local function ClearMobList()
	for i = 1, #moblist do
		table.remove(moblist, i);
	end
	currentmob = nil;
end

-- check for talent Solace and Insanity is learned
local function SolaceInsanity_Check()
	-- SW:Insanity -- 
	local talentID, name, iconTexture, selected, available = GetTalentInfo(3,3,ActiveSpec);	
	if (selected == true) then
		return true
	else
		return false
	end
end

-- check for talent Mindbender is learned
local function Mindbender_Check()
	-- Mindbender -- 
	local talentID, name, iconTexture, selected, available = GetTalentInfo(3,2,ActiveSpec);
	if (selected == true) then
		return true;
	else
		return false;
	end
end

-- check for talent From Darkness Comes Light is learned
local function FDCL_Check()
	-- FDCL --
	local talentID, name, iconTexture, selected, available = GetTalentInfo(3,1,ActiveSpec);
	if (selected == true) then
		return true;
	else
		return false;
	end	
end

-- check for talent Power Infusion is learned
local function PowInf_Check()
	-- Power Infusion --
	local talentID, name, iconTexture, selected, available = GetTalentInfo(5,2,ActiveSpec);	
	if (selected == true) then
		return true;
	else
		return false;
	end	
end

-- check for talent Divine Insight is learned
local function DivIn_Check()
	-- Divine Insight --
	local talentID, name, iconTexture, selected, available = GetTalentInfo(5,3,ActiveSpec);
	if (selected == true) then
		return true;
	else
		return false;
	end	
end

local function CheckCurrentTargetDeBuffs()
	local finished = false;
	local count = 0;
	local VTFound = 0;
	local VTLeft = 0;
	local VTlefttime = 0;
	local VTlasttickTime = 0;
	local VTlasttickcastTime = 0;
	local VTleftMS = 0;
	local PlagueFound = 0;
	local PlagueLeft = 0;
	local Plaguelefttime = 0;
	local WordPainFound = 0;
	local WordPainLeft = 0;
	local WordPainlefttime = 0;
	local WordPainleftMS = 0;
	local WordPainlasttickTime = 0;
	local WordPainlasttickCastTime = 0;
	local CastTime = 0;

	--PseudoGCD = castTimeVT;
	--PseudoGCD2 = castTimeVT*2;
	--PseudoGCDWarn = castTimeVT+WarningTime;
	VTlasttickTime = (castTimeVT*3)+WarningTime;
	VTlasttickcastTime = (castTimeVT*3);
	WordPainlasttickTime = (castTimeVT*2)+WarningTime;
	WordPainlasttickCastTime = (castTimeVT*2);

	while not finished do
		count = count+1;

		local bn,brank,bicon,bcount,bType,bduration,bexpirationTime,bisMine,bisStealable,bshouldConsolidate,bspellId =  UnitDebuff("target", count, 0);
		if not bn then
			finished = true;
		else
			--DEFAULT_CHAT_FRAME:AddMessage("testing debuff");
			if bisMine == "player" then
				--DEFAULT_CHAT_FRAME:AddMessage("ismine debuff");
				
				if bn == nameVT then 
					VTFound = 1;
					VTlefttime = floor((((bexpirationTime-GetTime())*10)+ 0.5))/10;
					if(VTlefttime <= 5.0) then				
						VTLeft = string.format("%1.1f",VTlefttime);
					else
						VTLeft = string.format("%d",VTlefttime);
					end
					VTleftMS = VTlefttime*1000;
					CastTime = castTimeVT;
					--VTleftMSSafe = VTleftMS-WarningTime;
					VTduration = bduration;
				end
				if bn == namePlague then 
					PlagueFound = 1;
					Plaguelefttime = floor((((bexpirationTime-GetTime())*10)+ 0.5))/10;		
					PlagueLeft = string.format("%1.1f",Plaguelefttime);

				end
				if bn == nameWordPain then 
					WordPainFound = 1;
					WordPainlefttime = floor((((bexpirationTime-GetTime())*10)+ 0.5))/10;
					if (WordPainlefttime <= 4.0) then
						WordPainLeft = string.format("%1.1f",WordPainlefttime);
					else
						WordPainLeft = string.format("%d",WordPainlefttime);
					end  
					WordPainleftMS = WordPainlefttime*1000;
					SWPduration = bduration;
				end
			end
		end
	end

	if (VTFound == 1) then
			
		--VT number above (re-)assignment
		FindCurrentMob();
		if (currentmob and (HideNumberAboveVT == 0)) then
			if (((GetTime() - currentmob[4]) > 15 ) and (Deactivate_2pT15display == 0) and ((currentmob[5] == true) or (currentmob[10] == 1))) then
			     currentmob[2] = currentmob[10];
			     --DEFAULT_CHAT_FRAME:AddMessage("extended VT buffscore: " .. currentmob[10]);
			end
			if ((currentmob[5] == true) or (currentmob[10] == 1)) then
				SPDT_TEXT1Above:SetText(string.format("%s", "UVLS"));
			else
				SPDT_TEXT1Above:SetText(string.format("%d", buffscorecurrent));
				--old one was: SPDT_TEXT1Above:SetText(string.format("%d", currentmob[2]));
			end
		end
	
		--VTIcon display, coloring and hide procedure
		if (HideIconVT == 0) then
			SPDT_Texture1:Show();
			if  VTleftMS < VTlasttickTime then
				if VTleftMS < VTlasttickcastTime then
					SPDT_Texture1:SetVertexColor(0.1, 0.6, 0.1);		--green
				else 
					SPDT_Texture1:SetVertexColor(0.9, 0.2, 0.2);		--red
				end
			else
				if (currentmob) then
					if (currentmob[5] == true) then
						if ((GetTime() - currentmob[7]) < 15) then
							--UVLS was active during DoT application and it is < 15s active
							SPDT_Texture1:SetVertexColor(0.9, 0.2, 0.2);		--red
						else
							SPDT_Texture1:SetVertexColor(1.0, 1.0, 1.0);		--nothing
							currentmob[5] = false;
						end
					elseif ((buffscorecurrent > (currentmob[2] + OffsetbuffscoreVT)) and (ColorBuffsWithBuffScore == 1)) then
						SPDT_Texture1:SetVertexColor(0.2, 0.2, 0.8);		--blue
					else
						SPDT_Texture1:SetVertexColor(1.0, 1.0, 1.0);		--no color				
					end
				else
					SPDT_Texture1:SetVertexColor(1.0, 1.0, 1.0);			--nothing
				end	
			end
		else 
			if (ShowDotsSoOutOffCombat == 0) then
				SPDT_Texture1:Hide();
			else
				SPDT_Texture1:SetVertexColor(1.0, 1.0, 1.0);		--no color
			end
		end

		--VT number above display and coloring
		if (HideNumberAboveVT == 0) then
			--set the color of the text above to green, when reapplication is usefull
			if (currentmob) then
				if (currentmob[5] == true) then
					if ((GetTime() - currentmob[7]) < 15) then
						--UVLS was active during DoT application and it is < 15s active
						SPDT_TEXT1Above:SetVertexColor(0.9, 0.2, 0.2);		--red
					else
						SPDT_TEXT1Above:SetVertexColor(1.0, 1.0, 1.0);		--nothing
						currentmob[5] = false;
					end
				elseif (buffscorecurrent > (currentmob[2] + OffsetbuffscoreVT)) then
					SPDT_TEXT1Above:SetVertexColor(0.1, 0.6, 0.1);	--green
				else
			   		SPDT_TEXT1Above:SetVertexColor(1.0, 0.9, 0.1);	--red
		   		end
			else
		   		SPDT_TEXT1Above:SetVertexColor(1.0, 0.9, 0.1);		--yellow
			end
			SPDT_TEXT1Above:Show();
		end
		
		if (HideTimerVT == 0) then
			SPDT_TEXT1:SetText(VTLeft);
			SPDT_TEXT1:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
			SPDT_TEXT1:Show();
		else
			SPDT_TEXT1:Hide();
		end
	else
		SPDT_TEXT1Above:Hide();
		SPDT_TEXT1:Hide();
		if (ShowDotsSoOutOffCombat == 0) then
			SPDT_Texture1:Hide();
		else 
			SPDT_Texture1:SetVertexColor(1.0, 1.0, 1.0);		--no color
			SPDT_Texture1:Show();
		end		
	end

	if (WordPainFound == 1) then
			
		--SWP number above assignment
		FindCurrentMob();
		if (currentmob and (HideNumberAboveSWP == 0)) then
			if (((GetTime() - currentmob[9]) > 18 ) and (Deactivate_2pT15display == 0) and ((currentmob[6] == true) or (currentmob[11] == 1))) then
				currentmob[3] = currentmob[11];
				--DEFAULT_CHAT_FRAME:AddMessage("extended SWP buffscore: " .. currentmob[11]);
			end
			if ((currentmob[6] == true) or (currentmob[11] == 1)) then
				SPDT_TEXT2Above:SetText(string.format("%s", "UVLS"));
			else
				SPDT_TEXT2Above:SetText(string.format("%d", buffscorecurrent));
				--old one was: SPDT_TEXT2Above:SetText(string.format("%d", currentmob[3]));
			end
		end
	
		--SWPIcon display, coloring and hide procedure
		if(HideIconSWP == 0) then
			SPDT_Texture2:Show();
			if  WordPainleftMS < WordPainlasttickTime then
				if (WordPainleftMS < WordPainlasttickCastTime)  then
					SPDT_Texture2:SetVertexColor(0.1, 0.6, 0.1);	--green
				else				
					SPDT_Texture2:SetVertexColor(0.9, 0.2, 0.2);	--red
				end
			else
				if (currentmob) then
					if (currentmob[6] == true) then
						if ((GetTime() - currentmob[8]) < 18) then
							--UVLS was active during DoT application and it is < 18s active
							SPDT_Texture2:SetVertexColor(0.9, 0.2, 0.2);		--red
						else
							SPDT_Texture2:SetVertexColor(1.0, 1.0, 1.0);		--nothing
							currentmob[6] = false;
						end
					elseif ((buffscorecurrent > (currentmob[3] + OffsetbuffscoreSWP)) and (ColorBuffsWithBuffScore == 1)) then
						SPDT_Texture2:SetVertexColor(0.2, 0.2, 0.9);		--blue
					else
						SPDT_Texture2:SetVertexColor(1.0, 1.0, 1.0);		--no color				
					end
				else
					SPDT_Texture2:SetVertexColor(1.0, 1.0, 1.0);		--no color
				end
			end
		else
			if (ShowDotsSoOutOffCombat == 0) then
				SPDT_Texture2:Hide();
			else 
				SPDT_Texture2:SetVertexColor(1.0, 1.0, 1.0);		--no color
				SPDT_TEXT2:Show();
			end	
		end

		--SWPnumber above display and coloring
		if (HideNumberAboveSWP == 0) then
			--set the color of the text above to green, when reapplication is usefull
			if (currentmob) then
				if (currentmob[6] == true) then
					if ((GetTime() - currentmob[8]) < 18) then
					--UVLS was active during DoT application and it is < 18s active
						SPDT_TEXT2Above:SetVertexColor(0.9, 0.2, 0.2);		--red
					else
						SPDT_TEXT2Above:SetVertexColor(1.0, 1.0, 1.0);		--nothing
						currentmob[6] = false;
					end
				elseif (buffscorecurrent > (currentmob[3] + OffsetbuffscoreSWP)) then
					SPDT_TEXT2Above:SetVertexColor(0.1, 0.6, 0.1);	--green
				else
			   		SPDT_TEXT2Above:SetVertexColor(1.0, 0.9, 0.1);	--red
		   		end
			else
		   		SPDT_TEXT2Above:SetVertexColor(1.0, 0.9, 0.1);		--yellow
			end
			SPDT_TEXT2Above:Show();
		end
		
		if (HideTimerSWP == 0) then 
			SPDT_TEXT2:SetText(WordPainLeft);
			SPDT_TEXT2:SetTextColor(1.0, 1.0, 1.0);
			SPDT_TEXT2:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
			SPDT_TEXT2:Show();
		else
			SPDT_TEXT2:Hide();
		end
	else

		SPDT_TEXT2Above:Hide();
		SPDT_TEXT2:Hide();
		if (ShowDotsSoOutOffCombat == 0) then
			SPDT_Texture2:Hide();
		else 
			SPDT_Texture2:SetVertexColor(1.0, 1.0, 1.0);		--no color
			SPDT_Texture2:Show();
		end	
	end
	
	if (PlagueFound == 1) then
		Texture3used = true;
		if(HideDP == 0) then
			MFI_Active = false;
			if (HideIconDP == 0) then
				SPDT_Texture3:SetTexture(IconPlague);
				SPDT_Texture3:SetVertexColor(1.0, 1.0, 1.0);		--no color
				SPDT_Texture3:Show();
			else
				SPDT_Texture3:Hide();
			end
			SPDT_TEXT3Above:Hide();
			SPDT_TEXT3Above2:Hide();
			if (HideTimerDP == 0) then
				SPDT_TEXT3:SetText(PlagueLeft);
				SPDT_TEXT3:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
				SPDT_TEXT3:Show();
			else
				SPDT_TEXT3:Hide();
			end
		else
			MFI_Active = false;
			SPDT_Texture3:Hide();
			SPDT_TEXT3:Hide();
			SPDT_TEXT3Above:Hide();
			SPDT_TEXT3Above2:Hide();
		end
	else
		MFI_Active = false;
		Texture3used = false;
		SPDT_Texture3:Hide();
		SPDT_TEXT3:Hide();
		SPDT_TEXT3Above:Hide();
		SPDT_TEXT3Above2:Hide();
	end

	
	return 
end

local function CheckPlayerBuffs()
	local Texture6CD = 0;
	local Texture7CD = 0;
	local finished = false;
	local count = 0;
	local ShadowOrbsFound = 0;
	local ShadowOrbsStacks = 0;
	local ShadowOrbsLeft = 0;
	local EmbraceFound = 0;
	local EmbraceLeft = 0;
	local PowerInfusionFound = 0;
	local SurgeOfDarknessStacks = 0;
	local PowerInfusionLeft = 0;
	local SurgeOfDarknessFound = 0;
	local SurgeOfDarknessLeft = 0;
	local MindbenderLeft = 0;
	local DivInFound = 0;
	local DivInLeft = 0;
	local InsanityFound = 0;
	local InsanityLeft = 0;
	local MBLeft = 0;
	local PowerInfCD = 0;
	local EmbraceCD = 0;
	local SurgeOfDarknessCD = 0;
	local MindbenderCD = 0;
	UVLS_active = false;
	SPDT_Texture4:Hide();
	
	local found = false;
	local i = 0;
	local found1 = false;
	local j = 0;
	local k = 0;
	local l = 0;
	local m = 0;
	local n = 0;
	
	--local PseudoGCD = castTimeVT;
	
	local SPELL_POWER_SHADOW_ORBS  = SPELL_POWER_SHADOW_ORBS;
	local NumOfOrbs = UnitPower('player', SPELL_POWER_SHADOW_ORBS);

	buffscorecurrent = 0;
	local buffscorehaste = 1;
	local buffscorehastetemp = 0;
	local buffscorehastetemp2 = 0;
	local buffscoredamagetemp = 1;
	local modifiedint = 0;
	local fluidity_active 	= UnitAura("player", fluidity_name, nil, "HARMFUL");

	local base, stat, posBuff, negBuff = UnitStat("player",4);

	while not finished do
		count = count+1;
		local bn,brank,bicon,bcount,bType,bduration,bexpirationTime,bisMine,bisStealable,bshouldConsolidate,bspellId =  UnitBuff("player", count, 0);

		modifiedint = base + buffscorecurrent;
		
		if not bn then
			finished = true;
		else
			--UVLS check for indication of 100% CritBuff
			if (bspellId == UVLS_procID) then
				UVLS_active = true;
				if (Show_UVLSicon == 1) then
					SPDT_Texture4:SetTexture(IconUVLS);
					SPDT_Texture4:Show();
				end
			end
			if (NumOfOrbs > 0) then
				ShadowOrbsFound		= 1;
				ShadowOrbsStacks	= NumOfOrbs;
			end
			if (bn == nameEmbrace) then 
				EmbraceFound = 1;
				EmbraceLeft = string.format("%1.1f",floor((((bexpirationTime-GetTime())*10)+ 0.5))/10);		-- as formated string						
			end
			if (bn == namePowerInfusion) then
				PowerInfusionFound	= 1;
				PowerInfusionLeft = string.format("%1.1f",floor((((bexpirationTime-GetTime())*10)+ 0.5))/10); 
			end	
			if (bn == nameSurgeOfDarkness) then
				SurgeOfDarknessFound	= 1;
				SurgeOfDarknessStacks = bcount;
				SurgeOfDarknessLeft = string.format("%1.1f",floor((((bexpirationTime-GetTime())*10)+ 0.5))/10);
			end
			if (bn == nameDivIn) then
				DivInFound = 1;
				DivInLeft = string.format("%1.1f",floor((((bexpirationTime-GetTime())*10)+ 0.5))/10);
			end
			if (bn == insanity_name) then
				InsanityFound = 1;
				InsanityLeft = string.format("%1.1f",floor((((bexpirationTime-GetTime())*10)+ 0.5))/10);
			end 			
			
			
			-------------------------------------
			--loop the buffs in the list until we find a match.
			found = false;
			i = 1;
			while found == false and i <= #BuffList do
				local entry = BuffList[i];
				if (entry) then
					if (bn == entry[1]) then
						found = true;

						if (bcount <= 0) then
							bcount = entry[4];
						end

						if (string.lower(entry[2]) == "int") then
							buffscorecurrent = buffscorecurrent + (entry[3] * bcount);
						elseif (string.lower(entry[2]) == "mastery") then
							buffscorecurrent = buffscorecurrent + (entry[3] * bcount * MasteryWeight);
						elseif (string.lower(entry[2]) == "crit") then
							buffscorecurrent = buffscorecurrent + (entry[3] * bcount * CritWeight);
						elseif (string.lower(entry[2]) == "haste") then
							if (CalcHasteNew == 1) then
							--the more accurate haste calculation
								for k = bcount, 1, -1 do
									buffscorehastetemp = (entry[3] / 425.2); --TODO - Change to new value
									buffscorehastetemp = (buffscorehastetemp / 100);
									buffscorehastetemp = buffscorehastetemp + 1;
									buffscorehaste     = buffscorehaste * buffscorehastetemp;
								end
								--DEFAULT_CHAT_FRAME:AddMessage("Hastebuff: " .. buffscorehaste);
							else
							--the old standard calculation
								buffscorecurrent = buffscorecurrent + (entry[3] * bcount * HasteWeight);
							end	
						elseif (string.lower(entry[2]) == "damage") then
							for m = bcount, 1, -1 do
								buffscoredamagetemp = buffscoredamagetemp * ((entry[3] / 100) + 1);
							end
						elseif (string.lower(entry[2]) == "spellpower") then
							buffscorecurrent = buffscorecurrent + (entry[3] * bcount * SpellpowerWeight);
						end
					end
				end

				i = i + 1;
			end

			found1 = false;
			j = 1;
			while found1 == false and j <= #ClassBuffList do
				local entry1 = ClassBuffList[j];
				if (entry1) then
					if (bspellId == entry1[1]) then
						found1 = true;

						if (bcount <= 0) then
							bcount = entry1[4];
						end

						if (string.lower(entry1[2]) == "int") then
							buffscorecurrent = buffscorecurrent + (entry1[3] * bcount);
						elseif (string.lower(entry1[2]) == "mastery") then
							buffscorecurrent = buffscorecurrent + (entry1[3] * bcount * MasteryWeight);
						elseif (string.lower(entry1[2]) == "crit") then
							buffscorecurrent = buffscorecurrent + (entry1[3] * bcount * CritWeight);
						elseif (string.lower(entry1[2]) == "haste") then
							if (CalcHasteNew == 1) then
								for l = bcount, 1, -1 do
									if (entry1[3] > 100) then
										buffscorehastetemp = (entry1[3] / 425.2);--TODOChange to new value
									else
										buffscorehastetemp = entry1[3];
									end
									buffscorehastetemp = (buffscorehastetemp / 100);
									buffscorehastetemp = buffscorehastetemp + 1;
									buffscorehaste   = buffscorehaste   * buffscorehastetemp;
								end
								--DEFAULT_CHAT_FRAME:AddMessage("Hastebuff 2: " .. buffscorehaste);
							else
								if (entry1[3] > 100) then
									buffscorehastetemp2 = entry1[3];
								else
									buffscorehastetemp2 = (entry1[3] * 425.2); -- Todo change to new value
								end
								buffscorecurrent = buffscorecurrent + (buffscorehastetemp2 * bcount * HasteWeight);
							end
							--workaround to trigger the +dmg buff of PI
							if (bspellId == PowerInfusionID) then
								found1 = false;
							end
						elseif (string.lower(entry1[2]) == "damage") then
							for n = bcount, 1, -1 do
								buffscoredamagetemp = buffscoredamagetemp * ((entry1[3] / 100) + 1);
								--DEFAULT_CHAT_FRAME:AddMessage("Damage buff summed: " .. buffscoredamagetemp);
							end
						elseif (string.lower(entry1[2]) == "spellpower") then
							buffscorecurrent = buffscorecurrent + (entry1[3] * bcount * SpellpowerWeight);
						end
					end
				end

				j = j + 1;
			end		
				
		end --one buff check finished
	end --finished buff loop check of all buffs
	
	if (fluidity_active) then
		buffscoredamagetemp = buffscoredamagetemp * 1.4;
	end	

	--Has there been an active Haste buff?
	if (CalcHasteNew == 1 and buffscorehaste ~= 1) then
		--Add the HasteWeight to the haste score
		--DEFAULT_CHAT_FRAME:AddMessage("Haste Buff Score Sum: " .. buffscorehaste);
		buffscorehastetemp = (((buffscorehaste -1) *100 ) * 425.2);
		--DEFAULT_CHAT_FRAME:AddMessage("Haste Buff Score Sum after recalculation: " .. buffscorehastetemp);	
		buffscorehaste = buffscorehastetemp * HasteWeight;
		--DEFAULT_CHAT_FRAME:AddMessage("Haste Buff Score with Weight: " .. buffscorehaste);
		--Add the multiplied Hastebuffs to the buffscore
		buffscorecurrent = buffscorecurrent + buffscorehaste;
	else
		--If no Haste buff is active, don't calculate the 1 to the buffscore
	end
	
	--Has there been an active Damage buff?
	if (buffscoredamagetemp ~= 1) then
		--Add the DamageWeight to the Damage score
		--DEFAULT_CHAT_FRAME:AddMessage("Damage Buff Score Sum: " .. buffscoredamagetemp);
		buffscoredamagetemp = buffscoredamagetemp * modifiedint * DamageWeight;
		--DEFAULT_CHAT_FRAME:AddMessage("Damage Buff Score Sum with Weights: " .. buffscoredamagetemp);
		--add the multiplied Damagebuff to the buffscore
		buffscorecurrent = buffscorecurrent + buffscoredamagetemp;
	end

	--Set savedbuffscorecurrent to actual buffscorecurrent
	savedbuffscorecurrent = buffscorecurrent;

	--Insanity active procedure
	if (InsanityFound == 1 and SolaceInsanity_Check() == true and HideSoD == 0) then
	--Mindflay: Insanity Active Time Procedure
	--Cooldown -> No Color
		MFI_Active = true;
		SPDT_Texture4:SetVertexColor(1.0, 1.0, 1.0);		--green with the correct cooldown
		SPDT_Texture4:SetTexture(IconInsanity);
		SPDT_Texture4:Show();
		if (HideNumberAboveSaI == 0) then
			SPDT_TEXT4Above:SetText(InsanityLeft);
			SPDT_TEXT4Above:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
			SPDT_TEXT4Above:Show();
		else
			SPDT_TEXT4Above:Hide();
		end
	else
		SPDT_Texture4:Hide();
		SPDT_TEXT4Above:Hide();
	end
	
	-- ShadowWord:Death Icon and Display Procedure --
	if ((HideSWD == 0) and (UnitExists("target")) and (UnitCanAttack("player", "target"))) then
		local SWDstart, SWDduration, SWDenabled = GetSpellCooldown(WordDeathID);
		local UnitHP = ceil(((UnitHealth("target")) / (UnitHealthMax("target"))) * 100);
		if  ((UnitHP <= 20) and (UnitHP > 0)) then
			if (SWDstart == 0 and SWDenabled == 1 and ((isincombat == true) or (ShowEverythingOutOfCombat == 1))) then
				SPDT_Texture5:SetTexture(IconWordDeath);
				SPDT_Texture5:SetVertexColor(0.1, 0.6, 0.1);			--green
				SPDT_Texture5:Show();
				Texture5used = true;
				SPDT_TEXT5:Hide();
			else
				SPDT_TEXT5:Hide();
				SPDT_Texture5:Hide();		
				Texture5used = false;	
			end
		else				
			SPDT_TEXT5:Hide();
			SPDT_Texture5:Hide();
			Texture5used = false;
		end
	else
		SPDT_Texture5:Hide();
		SPDT_TEXT5:Hide();
		Texture5used = false;
	end	
	
	--Mindblast Icon and Cooldown Procedure
	if (Texture5used == false) then
		local MBstart, MBduration, MBenabled = GetSpellCooldown(MindBlastID);	--MB CD
		local MBLeft = MBduration - (floor((((GetTime()-MBstart)*10)+ 0.5))/10);
		if (HideMB == 0 and MBstart > 0 and MBduration > 1.5 and ((isincombat == true) or (ShowEverythingOutOfCombat == 1))) then
			SPDT_TEXT5:SetText(string.format("%1.1f", MBLeft));
			SPDT_TEXT5:Show();
			SPDT_TEXT5:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
			SPDT_Texture5:SetVertexColor(1.0, 1.0, 1.0);		--no colour
			SPDT_Texture5:SetTexture(IconMindBlast);		
			SPDT_Texture5:Show();
		elseif (ShowMBOffCD == 1 and HideMB == 0 and ((isincombat == true) or (ShowEverythingOutOfCombat == 1))) then
			SPDT_TEXT5:Hide();
			if (isincombat == true) then
				SPDT_Texture5:SetVertexColor(0.1, 0.6, 0.1);		--green
			else
				SPDT_Texture5:SetVertexColor(1.0, 1.0, 1.0);		--no colour
			end
			SPDT_Texture5:SetTexture(IconMindBlast);	
			SPDT_Texture5:Show();
		else
			SPDT_TEXT5:Hide();
			SPDT_Texture5:Hide();
		end
	end
		
	--Shadoworbs Icon and Count Procedure
	if (Texture3used == false) then 
		if (ShadowOrbsFound == 1 and HideOrbs == 0  and ((isincombat == true) or (ShowDotsSoOutOffCombat == 1) or (ShowEverythingOutOfCombat == 1)) ) then
			SPDT_Texture3:SetTexture(IconShadowOrbs);
			SPDT_Texture3:Show();
			SPDT_TEXT3Above:SetText(ShadowOrbsStacks);
			SPDT_TEXT3Above:Show();
			SPDT_TEXT3Above2:Hide();	
			
			if (ShadowOrbsStacks >= 3) then
				SPDT_Texture3:SetVertexColor(0.1, 0.6, 0.1);		--green
			else if (isincombat == false) then
					SPDT_Texture3:SetVertexColor(1.0, 1.0, 1.0);		--no colour
				else
					SPDT_Texture3:SetVertexColor(0.9, 0.2, 0.2);	--red
				end
			end
			
		else 
			SPDT_Texture3:Hide();
			SPDT_TEXT3:Hide();	
			SPDT_TEXT3Above:Hide();
			SPDT_TEXT3Above2:Hide();
		end	
	end

	if (PowInf_Check() == true) then
		--PowerInfusion Icon and Cooldown Procedure	
		local PowerInfStart, PowerInfDuration, PowerInfEnabled = GetSpellCooldown(PowerInfusionID);	--PowerInfusion CD
		PowerInfCD = PowerInfDuration - (floor((((GetTime()-PowerInfStart)*10)+ 0.5))/10);
		--Cooldown -> No Color
		if (HidePInf == 0 and PowerInfStart > 0 and PowerInfDuration > 0.5 and ((isincombat == true) or (ShowEverythingOutOfCombat == 1))) then
			if (PowerInfusionFound == 1) then
				SPDT_Texture6:SetVertexColor(0.1, 0.6, 0.1);		--green with PowerInfusion Icon
				SPDT_Texture6:SetTexture(IconPowerInfusion);
				SPDT_Texture6:Show();
				SPDT_TEXT6:SetText(PowerInfusionLeft);
				SPDT_TEXT6:Show();
				SPDT_TEXT6Above:Hide()
			else 
				SPDT_Texture6:SetVertexColor(0.9, 0.2, 0.2);		--red with the correct cooldown
				SPDT_Texture6:Show();
				Texture6CD = PowerInfCD;
				SPDT_Texture6:SetTexture(IconPowerInfusion);
				SPDT_TEXT6:SetText(string.format("%1.0f", Texture6CD));
				SPDT_TEXT6:Show();
				SPDT_TEXT6Above:Hide();
			end
		elseif (HidePInf == 0 and ShowPIOffCD == 1 and ((isincombat == true) or (ShowEverythingOutOfCombat == 1))) then
			SPDT_Texture6:SetVertexColor(1.0, 1.0, 1.0);		--no colour
			SPDT_Texture6:Show();
			SPDT_TEXT6Above:Hide();
			SPDT_TEXT6:Hide()
		else
			SPDT_Texture6:Hide();
			SPDT_TEXT6:Hide();
			SPDT_TEXT6Above:Hide();
		end
	end		
		
	if (DivIn_Check() == true) then
			--Cooldown -> No Color
		if (HidePInf == 0 and DivInFound == 1 and ((isincombat == true) or (ShowEverythingOutOfCombat == 1))) then
			SPDT_Texture6:SetVertexColor(0.1, 0.6, 0.1);		--green with Divine Insight Icon
			SPDT_Texture6:SetTexture(IconDivIn);
			SPDT_Texture6:Show();
			SPDT_TEXT6:SetText(DivInLeft);
			SPDT_TEXT6:Show();
			SPDT_TEXT6Above:Hide()	
		else
			SPDT_Texture6:Hide();
			SPDT_TEXT6:Hide();
			SPDT_TEXT6Above:Hide();
		end
	end
	
	
	if (FDCL_Check() == true) then
		--SurgeOfDarkness Icon Procedure
		--Cooldown -> No Color
		if (HideSoD == 0 and SurgeOfDarknessFound == 1 and ((isincombat == true) or (ShowEverythingOutOfCombat == 1))) then
			SPDT_Texture7:SetVertexColor(0.1, 0.6, 0.1);		--green with Surge of Darkness
			SPDT_Texture7:SetTexture(IconSurgeOfDarkness);
			SPDT_Texture7:Show();
			SPDT_TEXT7:SetText(SurgeOfDarknessLeft);
			SPDT_TEXT7:Show();
			SPDT_TEXT7Above:SetText(SurgeOfDarknessStacks);
			SPDT_TEXT7Above:Show()
		else
			SPDT_Texture7:Hide();
			SPDT_TEXT7:Hide();
			SPDT_TEXT7Above:Hide();
		end	
	end
	
	
	if (Mindbender_Check() == true) then
		--Mindbender Icon and CD Procedure
		local MindbenderStart, MindbenderDuration, MindbenderEnabled = GetSpellCooldown(MindbenderID);	--Mindbender CD
		MindbenderCD = MindbenderDuration - (floor((((GetTime()-MindbenderStart)*10)+ 0.5))/10);
		if (HideSoD == 0 and MindbenderStart > 0 and MindbenderDuration > 0.5 and ((isincombat == true) or (ShowEverythingOutOfCombat == 1))) then
			MindbenderLeft = string.format("%1.1f", 15.5 + (MindbenderStart - GetTime()));
			if (IsPetAttackActive() == true or MindbenderCD > 45) then
				SPDT_Texture7:SetVertexColor(1.0, 1.0, 1.0);		--no colour
				SPDT_Texture7:SetTexture(IconMindbender);
				SPDT_Texture7:Show();
				SPDT_TEXT7:SetText(MindbenderLeft);
				SPDT_TEXT7:Show();
				SPDT_TEXT7Above:Hide()
			elseif (MindbenderDuration >= 2) then
				SPDT_Texture7:SetVertexColor(0.9, 0.2, 0.2);		--red with the correct cooldown
				SPDT_Texture7:SetTexture(IconMindbender);
				SPDT_Texture7:Show();
				Texture7CD = MindbenderCD;
				SPDT_TEXT7:SetText(string.format("%1.0f", Texture7CD));
				SPDT_TEXT7:Show();
				SPDT_TEXT7Above:Hide();
			end
		else
			SPDT_Texture7:Hide();
			SPDT_TEXT7:Hide();
			SPDT_TEXT7Above:Hide();
		end
	end			


	--Vampiric Embrace Icon and Cooldown Procedure
	local EmbraceStart, EmbraceDuration, EmbraceEnabled = GetSpellCooldown(EmbraceID);  --VampiricEmbrace  CD
	EmbraceCD = EmbraceDuration - (floor((((GetTime()-EmbraceStart)*10)+ 0.5))/10); 
	if (HideVEmbrace == 0 and EmbraceStart > 0 and EmbraceDuration > 0.5 and ((isincombat == true) or (ShowEverythingOutOfCombat == 1))) then
		if (EmbraceFound == 1 ) then
			SPDT_Texture8:SetVertexColor(0.1, 0.6, 0.1);		--green
			SPDT_Texture8:Show();
			SPDT_TEXT8:SetText(EmbraceLeft);
			SPDT_TEXT8:Show();
			SPDT_TEXT8Above:Hide()
		else
			SPDT_Texture8:SetVertexColor(0.9, 0.2, 0.2);		--red
			SPDT_Texture8:Show();
			SPDT_TEXT8:SetText(string.format("%1.0f", EmbraceCD));
			SPDT_TEXT8:Show();
			SPDT_TEXT8Above:Hide();
		end
	elseif (ShowVEOffCD == 1 and HideVEmbrace == 0 and ((isincombat == true) or (ShowEverythingOutOfCombat == 1))) then
		SPDT_Texture8:SetVertexColor(1.0, 1.0, 1.0);		--no colour
		SPDT_Texture8:Show();
		SPDT_TEXT8Above:Hide();
		SPDT_TEXT8:Hide()
	else
		SPDT_Texture8:Hide();
		SPDT_TEXT8:Hide();
		SPDT_TEXT8Above:Hide();
	end	
return 
end


function ShadowPriestDoTTimerFrame_OnLoad(self)
	ShadowPriestDoTTimerFrame:RegisterEvent("PLAYER_LOGOUT");
	ShadowPriestDoTTimerFrame:RegisterEvent("ADDON_LOADED");
	ShadowPriestDoTTimerFrame:RegisterEvent("SAVED_VARIABLES_TOO_LARGE");	
	ShadowPriestDoTTimerFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
	ShadowPriestDoTTimerFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
	ShadowPriestDoTTimerFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
	ShadowPriestDoTTimerFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
	ShadowPriestDoTTimerFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	ShadowPriestDoTTimerFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	
	local Class = PriestCheck();
	local currentSpec = GetSpecialization();
	if (Class ~= "PRIEST") then
		--not a Priest
		Priest = false;
		DEFAULT_CHAT_FRAME:AddMessage("---Shadow Priest DoT Timer Not Loaded---");
	else -- Is a Priest
		Priest = true;
		--with Shadow Spec
		if (currentSpec == 3) then
			ActiveSpec = GetActiveSpecGroup() or 1;
			ShadowSpecc = true;
			DEFAULT_CHAT_FRAME:AddMessage("---Shadow Priest DoT Timer Loaded---");
			Detect2T15();
		--with another specc
		else 
			local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None";
			ShadowSpecc = false;
			DEFAULT_CHAT_FRAME:AddMessage("You are now playing in " .. currentSpecName .. " Specc!");
			DEFAULT_CHAT_FRAME:AddMessage("---Shadow Priest DoT Timer turned off---");
		end
	end
	
	SPDT_Texture1:SetTexture(IconVT);
	SPDT_Texture2:SetTexture(IconWordPain);
	SPDT_Texture3:SetTexture(IconPlague);
	SPDT_Texture5:SetTexture(IconMindBlast);
	SPDT_Texture6:SetTexture(IconPowerInfusion);
	SPDT_Texture7:SetTexture(IconSurgeOfDarkness);
	SPDT_Texture8:SetTexture(IconEmbrace);
	
	SPDT_Texture1:Hide();
	SPDT_Texture2:Hide();
	SPDT_Texture3:Hide();
	SPDT_Texture4:Hide();
	SPDT_Texture5:Hide();
	SPDT_Texture6:Hide();
	SPDT_Texture7:Hide();
	SPDT_Texture8:Hide();

	SPDT_TEXT1:Hide();
	SPDT_TEXT2:Hide();	
	SPDT_TEXT3:Hide();
	SPDT_TEXT4:Hide();
	SPDT_TEXT5:Hide();
	SPDT_TEXT6:Hide();
	SPDT_TEXT7:Hide();
	SPDT_TEXT8:Hide();
	
	SPDT_TEXT1Above:Show();
	SPDT_TEXT2Above:Show();
	SPDT_TEXT3Above:Show();
	SPDT_TEXT3Above2:Hide();
	SPDT_TEXT4Above:Hide();
	SPDT_TEXT5Above:Hide();
	SPDT_TEXT6Above:Hide();
	SPDT_TEXT7Above:Hide();
	SPDT_TEXT8Above:Hide();
	
	TimeSinceLastUpdate = 0;

	ShadowPriestDoTTimerFrame:RegisterForDrag("LeftButton", "RightButton");
	ShadowPriestDoTTimerFrame:EnableMouse(false);
end

function ShadowPriestDoTTimerFrame_OnUpdate(elapsed)
	-- check if Class is a Priest
	if (Priest == true) then
		--Specc is Shadow
		if (GetSpecialization() == 3) then
			ShadowSpecc = true;
			TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed; 	
			while (TimeSinceLastUpdate > MyAddon_UpdateInterval) do
				CheckCurrentTargetDeBuffs();
				CheckPlayerBuffs();
		
				if (((buffscorecurrent > 0) or (UVLS_active == true)) and (isincombat == true) and (HideBuffscore == 0)) then
					if (UVLS_active == true) then
						SPDT_TEXT4:SetText(string.format("%s", "UVLS"));
						SPDT_TEXT4:SetVertexColor(0.9, 0.2, 0.2);	--red
					else
						SPDT_TEXT4:SetText(string.format("%d", buffscorecurrent));
						SPDT_TEXT4:SetVertexColor(1.0, 0.9, 0.1);	--yellow
					end
					SPDT_TEXT4:Show();
				else
					SPDT_TEXT4:Hide();
				end
				TimeSinceLastUpdate = TimeSinceLastUpdate - MyAddon_UpdateInterval;
			end
		--Check if the specialization has changed to Holy or Disc
		else
			ShadowSpecc = false;
			Priest = false;
			HideAll();
		end
	else
		--Check if the specialization has changed to shadow and Class is Priest
		if (GetSpecialization() == 3 and PriestCheck() == "PRIEST") then
			ShadowSpecc = true;
			Priest = true;
			ActiveSpec = GetActiveSpecGroup() or 1;
		else
			HideAll();
			--do nothing;
		end
	end
end

function ShadowPriestDoTTimerFrame_OnEvent(self, event, ...)
	local arg1 = ...;

	if (event == "UNIT_SPELLCAST_SUCCEEDED") then
		local unit, _, _, _, spellid = ...;
		if (unit == "player") then
			if (spellid == VTID) then
				if (HideNumberAboveVT == 0) then
					if (UVLS_active == true) then
						SPDT_TEXT1Above:SetText(string.format("%s", "UVLS"));
					else
						SPDT_TEXT1Above:SetText(string.format("%d", buffscorecurrent));
					end
					SPDT_TEXT1Above:Show();
				end
				
				FindOrCreateCurrentMob();
				if (currentmob) then
					currentmob[2] = buffscorecurrent;
					currentmob[10] = 0;
					extended = false;
					currentmob[4] = GetTime();
					if (UVLS_active == true) then
						currentmob[5] = true;
						currentmob[7] = GetTime();
						--DEFAULT_CHAT_FRAME:AddMessage("SPDT UVLS on VT: " .. currentmob[7]);
					else
						currentmob[5] = false;
						currentmob[7] = 0;
					end					
				end
			elseif (spellid == WordPainID) then
				if (HideNumberAboveSWP == 0) then
					if (UVLS_active == true) then
						SPDT_TEXT2Above:SetText(string.format("%s", "UVLS"));
					else
						SPDT_TEXT2Above:SetText(string.format("%d", buffscorecurrent));
					end
					SPDT_TEXT2Above:Show();
				end
				
				FindOrCreateCurrentMob();
				if (currentmob) then
					currentmob[3] = buffscorecurrent;
					currentmob[11] = 0;
					extended = false;
					currentmob[9] = GetTime();
					if (UVLS_active == true) then
						currentmob[6] = true;
						currentmob[8] = GetTime();
						--DEFAULT_CHAT_FRAME:AddMessage("SPDT UVLS on: " .. currentmob[8]);
					else
						currentmob[6] = false;
						currentmob[8] = 0;
					end	
				end
			elseif (spellid == MindBlastID) then
				--DEFAULT_CHAT_FRAME:AddMessage("Mindblast event: ");	
				local SPELL_POWER_SHADOW_ORBS  = SPELL_POWER_SHADOW_ORBS;
				local NumOfOrbs = UnitPower('player', SPELL_POWER_SHADOW_ORBS);
				if ((NumOfOrbs >= 1) and (MFI_Active == false)) then
					PrevShadowOrbsCount = PrevShadowOrbs[NumOfOrbs];
					--DEFAULT_CHAT_FRAME:AddMessage("Prev Shadow Orbs: " .. PrevShadowOrbsCount);
				end
			elseif (spellid == WordDeathID) then
				--DEFAULT_CHAT_FRAME:AddMessage("SWD event: ");	
				local SPELL_POWER_SHADOW_ORBS  = SPELL_POWER_SHADOW_ORBS;
				local NumOfOrbs = UnitPower('player', SPELL_POWER_SHADOW_ORBS);
				if ((NumOfOrbs >= 1) and (MFI_Active == false)) then
					PrevShadowOrbsCount = PrevShadowOrbs[NumOfOrbs];
					--DEFAULT_CHAT_FRAME:AddMessage("Prev Shadow Orbs: " .. PrevShadowOrbsCount);
				end
			end
		end
	elseif (event == "COMBAT_LOG_EVENT_UNFILTERED" and (Deactivate_2pT15display == 0)) then
		local event_type, _, Source_GUID, _, SourceFlags, _, destination_GUID = select(2, ...);
		--DEFAULT_CHAT_FRAME:AddMessage("CombatLogEvent");
		if (event_type == "SPELL_DAMAGE") then
			local spellID = select(12,...);
			if ((spellID == Shadowy_ApparitionsID) and (Source_GUID == MyID) and (SourceFlags == 1297) and (set2t15 == true)) then
				--DEFAULT_CHAT_FRAME:AddMessage("Event: SpellDmg with my SA PTR");
				if (destination_GUID == UnitGUID("target") or 
					destination_GUID == UnitGUID("mouseover") or 
					destination_GUID == UnitGUID("focus") or 
					destination_GUID == UnitGUID("boss1") or 
					destination_GUID == UnitGUID("boss2") or 
					destination_GUID == UnitGUID("boss3") or 
					destination_GUID == UnitGUID("boss4") or 
					destination_GUID == UnitGUID("boss5"))    then
					--DEFAULT_CHAT_FRAME:AddMessage("My Shadowy app hits with 2pt15 @5.4");
					local target;
					if (destination_GUID == UnitGUID("target")) then target = "target"
					elseif (destination_GUID == UnitGUID("mouseover")) then target = "mouseover"
					elseif (destination_GUID == UnitGUID("focus")) then target = "focus"
					elseif (destination_GUID == UnitGUID("boss1")) then target = "boss1"
					elseif (destination_GUID == UnitGUID("boss2")) then target = "boss2"
					elseif (destination_GUID == UnitGUID("boss3")) then target = "boss3"
					elseif (destination_GUID == UnitGUID("boss4")) then target = "boss4"
					elseif (destination_GUID == UnitGUID("boss5")) then target = "boss5"
					end
					local finished = false;
					local count = 0;
					while not finished do
						count = count+1				
						local bn,_,_,_,_,bduration,_,bisMine,_,_,bspellId =  UnitDebuff(target, count, 0);
						if (not bn) then
							finished = true;
						else
							--DEFAULT_CHAT_FRAME:AddMessage("testing debuff");
							if bisMine == "player" then
							--DEFAULT_CHAT_FRAME:AddMessage("ismine debuff");
								if bn == nameVT then
									--check for 2pT15 proc
									--DEFAULT_CHAT_FRAME:AddMessage("Vt extended ");
									FindOrCreateCurrentMob(destination_GUID);
									if (currentmob) then
										if (UVLS_active == true) then
											currentmob[10] = 1;
										else
											currentmob[10] = savedbuffscorecurrent;
										end
									end
										
									if ((HideNumberAboveVT == 0) and (GetTime() - currentmob[4] > 15)) then
										if (UVLS_active == true) then
											SPDT_TEXT1Above:SetText(string.format("%s", "UVLS"));
										else
											SPDT_TEXT1Above:SetText(string.format("%d", savedbuffscorecurrent));
										end
										SPDT_TEXT1Above:Show();
									end
								end
								
								if bn == nameWordPain then 
									--DEFAULT_CHAT_FRAME:AddMessage("SWP extended ");
									FindOrCreateCurrentMob(destination_GUID);
									if (currentmob) then
										if (UVLS_active == true) then
											currentmob[11] = 1;
										else
											currentmob[11] = savedbuffscorecurrent;
											--DEFAULT_CHAT_FRAME:AddMessage("SWP extended with buffscore " .. currentmob[11]);
										end	
									end	
																			
									if (HideNumberAboveSWP == 0 and (GetTime() - currentmob[9] > 18)) then
										if (currentmob[11] == 1) then
											SPDT_TEXT2Above:SetText(string.format("%s", "UVLS"));
										else
											SPDT_TEXT2Above:SetText(string.format("%d", savedbuffscorecurrent));
										end
										SPDT_TEXT2Above:Show();
									end
								end
							end
						end
					end
				end
			end
		end	
	elseif (event == "PLAYER_EQUIPMENT_CHANGED") then
		Detect2T15();
	elseif (event == "PLAYER_ENTERING_WORLD") then
		Detect2T15();
		--DEFAULT_CHAT_FRAME:AddMessage("-->Player entering world!");
	elseif ((event == "ADDON_LOADED") and arg1 == ("ShadowPriestDoTTimer")) then
		if (not ShadowPriestDoTTimerFrameScaleFrame) then
			ShadowPriestDoTTimerFrameScaleFrame = 1.0;
		end
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerFrameScaleFrame);
		SPDT_SetCooldownOffsets();
		Detect2T15();
		MyID = UnitGUID("player");
	elseif ((event == "SAVED_VARIABLES_TOO_LARGE") and (arg1 == "ShadowPriestDoTTimer")) then
		ShadowPriestDoTTimerFrameScaleFrame = 1.0;
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerFrameScaleFrame);
		SPDT_SetCooldownOffsets();
		Detect2T15();
		MyID = UnitGUID("player");
	elseif (event == "PLAYER_LOGOUT") then
		ShadowPriestDoTTimerFrameScaleFrame = ShadowPriestDoTTimerFrame:GetScale();
		local point, relativeTo, relativePoint, xOffset, yOffset;
		point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint(1);
		ShadowPriestDoTTimerxPosiFrame = xOffset;
	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (maxmoblist < #moblist) then
			--SWP and VT don't last more than a minute so once we've been ooc for a minute, clear up the list.
			for i = 1, #moblist do
				if ((moblist[i][4]-GetTime() > 60000) and (moblist[i][9]-GetTime() > 60000) and (moblist[i][1] ~= currentmob[1])) then
					table.remove(moblist, i);
				end
			end
		end
		isincombat = false;
	elseif (event == "PLAYER_REGEN_DISABLED") then
		isincombat = true;
	end
end



SLASH_SHADOWPRIESTDOTTIMER1, SLASH_SHADOWPRIESTDOTTIMER2 = '/spdt', '/ShadowPriestDoTTimer';

local function SLASH_SHADOWPRIESTDOTTIMERhandler(msg, editbox)
	if msg == 'show' then
		ShadowPriestDoTTimerFrame:Show();
	elseif  msg == 'hide' then
		ShadowPriestDoTTimerFrame:Hide();
	elseif  msg == 'reset' then
		ShadowPriestDoTTimerFrame:Hide();
		ShadowPriestDoTTimerFrame:Show();
		ClearMobList();
	elseif  msg == 'clear' then
		ClearMobList();
	elseif  msg == 'noconfigmode' then
		if (isincombat == false) then	
			ShadowPriestDoTTimerFrame:EnableMouse(false);
			ShadowPriestDoTTimerFrame:SetBackdrop(nil);
			SPDT_SetCooldownOffsets();
		else
			print("Please wait for being Out of Combat, to stop moving SPDT")	
		end
	elseif  msg == 'configmode' then
		if(isincombat == false) then
			ShadowPriestDoTTimerFrame:EnableMouse(true);
			ShadowPriestDoTTimerFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile= "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 4, tile = false, tileSize =16, insets = { left = 0, right = 0, top = 0, bottom = 0 }});
		else
			print("Please wait for being Out of Combat, to move SPDT")
		end
	elseif  msg == 'options' then
		InterfaceOptionsFrame_OpenToCategory("Shadow Priest DoT Timer");
	elseif  msg == 'scale1' then
		ShadowPriestDoTTimerScaleFrame = 0.5
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerScaleFrame);
	elseif  msg == 'scale2' then
		ShadowPriestDoTTimerScaleFrame = 0.6
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerScaleFrame);
	elseif  msg == 'scale3' then
		ShadowPriestDoTTimerScaleFrame = 0.7
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerScaleFrame);
	elseif  msg == 'scale4' then
		ShadowPriestDoTTimerScaleFrame = 0.8
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerScaleFrame);
	elseif  msg == 'scale5' then
		ShadowPriestDoTTimerScaleFrame = 0.9
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerScaleFrame);
	elseif  msg == 'scale6' then
		ShadowPriestDoTTimerScaleFrame = 1.0
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerScaleFrame);
	else
		print("Syntax: /spdt (show | hide | reset | configmode | noconfigmode | options | clearmoblist )");
		print("Syntax: /spdt (scale1 | scale2 | scale3 | scale4 | scale5 | scale6)");
	end
end

SlashCmdList["SHADOWPRIESTDOTTIMER"] = SLASH_SHADOWPRIESTDOTTIMERhandler;







