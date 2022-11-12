--[[

MIT License

Copyright (c) 2021 x3m4k

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]


local _D = {
	["Font"] = "DermaDefault",
	["FontSize"] = 14,
	["FontOutline"] = false,
	["Color"] = Color( 23, 13, 24, 200 ),
	["AnotherColor"] = Color( 240, 240, 240, 200 ),
	["TextColor"] = Color( 240, 240, 240, 200 ),
	["AnotherTextColor"] = Color( 23, 13, 24, 200 ),

	-- Preload
	["x"] = 0,
	["y"] = 0,
	["w"] = 0,
	["h"] = 0,
	["_RealFont"] = "DermaDefault",
	["MenuFont"] = "DermaDefault",
	["MaxFraction"] = 0.0039296,  -- about 128 units
	["Display_LocalTime"] = true
}

local LANG = {
	["title_config"] = {
		["ru"] = "Seetime - Конфиг",
		["en"] = "Seetime - Config",
	},
	["title_custom_font"] = {
		["ru"] = "Seetime - Свой шрифт",
		["en"] = "Seetime - Custom font",
	},
	["font"] = {
		["ru"] = "Шрифт",
		["en"] = "Font",
	},
	["specify_font"] = {
		["ru"] = "Укажите название шрифта",
		["en"] = "Specify the name of the font",
	},
	["apply"] = {
		["ru"] = "Применить",
		["en"] = "Apply",
	},
	["cancel"] = {
		["ru"] = "Отмена",
		["en"] = "Cancel",
	},
	["notify_config_saved"] = {
		["ru"] = "[Seetime] Конфиг сохранён!",
		["en"] = "[Seetime] Config saved!",
	},
	["custom"] = {
		["ru"] = "Свой",
		["en"] = "Custom",
	},
	["set_colors"] = {
		["ru"] = "Установить цвета",
		["en"] = "Set colors",
	},
	["reset"] = {
		["ru"] = "Сбросить",
		["en"] = "Reset",
	},
	["ok"] = {  -- wow such a big difference
		["ru"] = "Ок",
		["en"] = "Ok",
	},
	["distance_units"] = {
		["ru"] = "Макс. дистанция определения игроков",
		["en"] = "Max. player detection distance",
	},
	["display_localtime"] = {
		["ru"] = "Отображать локальное время?",
		["en"] = "Display local time?",
	},
	["outline"] = {
		["ru"] = "Выделение",
		["en"] = "Outline",
	},
	["title_colors"] = {
		["ru"] = "Установка цветов",
		["en"] = "Colors",
	},
	["title_colors_TextColor"] = {
		["ru"] = "Цвет текста вашей статистики",
		["en"] = "The text color of your stats",
	},
	["title_colors_Color"] = {
		["ru"] = "Основной цвет",
		["en"] = "Main color",
	},
	["title_colors_AnotherColor"] = {
		["ru"] = "Основной цвет для другого игрока",
		["en"] = "Main color for another player",
	},
	["title_colors_AnotherTextColor"] = {
		["ru"] = "Цвет текста чужой статистики",
		["en"] = "The color of the text of someone else's statistics",
	}
}

local function GetTranslation( phrase )
	if not phrase then return end

	local lang = GetConVar( "gmod_language" ):GetString() or "en"
	if LANG[phrase] == nil then return "##" .. phrase end

	return LANG[phrase][lang] or LANG[phrase]["en"]
end

local C = table.Copy( _D )

local totalTime, sessionTime = 0, 0
local anotherTotalTime, anotherSessionTime = 0, 0
local anotherPlayer = nil

Seetime_colorsDialogues = {}

-- true when just unfocused another player
local isCloseAnimationActive = false
-- true when configurator opened
-- local isEditingConfig = false

local _tempPlayers = {}

local DBUTTON = {}

function DBUTTON:SetTextAndSize( font, text, defaultY )

	surface.SetFont( font )
	local tw, th = surface.GetTextSize( text )
	self:SetText( tostring( text ) )
	self:SetSize( tw + 10, defaultY )

end

function DBUTTON:CenterAlignX()

	local parent = self:GetParent()
	if parent == nil then return end

	local sw, sh = self:GetSize()
	local sx, sy = self:GetPos()

	local pw, ph = parent:GetSize()

	self:SetPos( (pw-sw)/2, sy )

end

vgui.Register( "DButton1", DBUTTON, "DButton" )

local function DefaultPaintBuilder( title )

	local function FUNC( self, width, height )
		draw.RoundedBox( 5, 0, 0, width, 24, Color( 0,0,0,192 ) )
		draw.RoundedBox( 5, 0, 0, width, height, Color( 0,0,0,128 ) )

		draw.SimpleText( 
			title,
			"DermaDefault",
			width/2 - 50,
			12,
			Color( 220,220,220,255 ),
			1,
			1
		)
	end

	return FUNC

end

local function SetRow( parent, child, offsetX, offsetY )
	local parentX, parentY = parent:GetPos()
	local parentW, parentH = parent:GetSize()

	local childX, childY = child:GetPos()
	local childW, childH = child:GetSize()

	if offsetX == nil then offsetX = 0 end
	if offsetY == nil then offsetY = 0 end

	child:SetPos( 
		parentX + parentW + offsetX,
		parentY + offsetY
	)

end

local function SetActionFunc( target, func )

	function target:OnValueChanged( tableData )
		func( self, tableData )
	end

	function target:OnSelect( i, value, data )
		func( self, i, value, data )
	end

end

local function UpdateSize( newName )

	surface.SetFont( newName )
	local w, h = surface.GetTextSize( "00w 00d 00h 00m 00s" )

	-- Remember to use math.floor instead of //
	-- (overwritten with comment command for gmod)

	C.w = w + 5 * math.floor( w/50 )
	C.h = h * 4
	C._h_without_time = C.h
	if C.Display_LocalTime then
		local _, localTime_h = surface.GetTextSize( "23:59:59" )
		C.h = C.h + localTime_h + 5
	end

	if IsValid( Seetime_Panel ) then
		Seetime_Panel:SetSize( C.w, C.h )
	end

end

local function MakeCustomFont( fName, fSize, fOutline )

	C._RealFont = fName

	local newName = 'Seetime_' .. fName .. "@" ..
		fSize .. (fOutline and 1 or 0)

	surface.CreateFont( newName, {
		font = fName,
		size = fSize,
		outline = fOutline,
		extended = false,  -- No unicode (check gmod wiki for info)
		antialias = not (fOutline and 1 or 0)
	} )

	UpdateSize( newName )

	isCloseAnimationActive = false
	anotherPlayer = nil

	C.Font = newName

	return newName

end

local function LoadConfig()
	local dat = file.Read( "seetime.json" ) or "{}"
	dat = util.JSONToTable( dat )

	for k,v in pairs(dat) do
		if v == nil then goto exit end

		C[k] = v

		::exit::
	end

	C._RealFont = C.Font
	C.Font = MakeCustomFont( C.Font, C.FontSize, C.FontOutline )
	C.MaxFraction = GetGlobalInt( "seetime_maxdistance", 256 ) * 0.0000307

	surface.SetFont( C.Font )
	C.w, C.h = surface.GetTextSize( "00w 00d 00h 00m 00s" )
	C._h_without_time = C.h
end

local function SaveConfig()

	local fontName = C._RealFont
	local dataTable = {}

	local listOfVariables = {
		"Font", "FontSize", "FontOutline", "Color", "AnotherColor",
		"TextColor", "AnotherTextColor", "x", "y", "MaxFraction", "Display_LocalTime"
	}

	for i, v in ipairs( listOfVariables ) do
		if v == "Font" then
			dataTable[ v ] = C._RealFont
			goto exit
		end

		dataTable[ v ] = C[v]

		::exit::
	end

	file.Write( "seetime.json", util.TableToJSON( dataTable, true ) )

end

local function OpenCustomFontDialogue()

	if IsValid( Seetime_FontDialogue ) then
		Seetime_FontDialogue:Remove()
	end

	Seetime_FontDialogue = vgui.Create( "DFrame" )
	Seetime_FontDialogue:SetTitle( "" )
	Seetime_FontDialogue:SetSize( 300, 200 )
	Seetime_FontDialogue:MakePopup()
	Seetime_FontDialogue:Center()

	local paintFunc = DefaultPaintBuilder( GetTranslation( "title_custom_font" ) )
	Seetime_FontDialogue.Paint = paintFunc

	local text = vgui.Create( "DTextEntry", Seetime_FontDialogue )
	text:Dock( TOP )
	text:SetPlaceholderText( GetTranslation( "specify_font" ) )
	text:SetValue( C._RealFont )

	local buttonsSection = vgui.Create( "DPanel", Seetime_FontDialogue )
	function buttonsSection:Paint() end
	buttonsSection:Dock( BOTTOM )

	local cancelButton = vgui.Create( "DButton", buttonsSection )
	cancelButton:SetText( GetTranslation( "cancel" ) )
	cancelButton:Dock( LEFT )

	local applyButton = vgui.Create( "DButton", buttonsSection )
	applyButton:SetText( GetTranslation( "apply" ) )
	applyButton:Dock( RIGHT )

	cancelButton.DoClick = function() Seetime_FontDialogue:Remove() end
	applyButton.DoClick = function()
		if not text:GetValue() then return end

		Seetime_FontDialogue:Remove()
		MakeCustomFont( text:GetValue(), C.FontSize, C.FontOutline )
	end

end

local function OpenColorsDialogue()

	if IsValid( Seetime_ColorsDialogues ) then
		for k, v in pairs( Seetime_ColorsDialogues ) do
			Seetime_ColorsDialogues[ k ]:Remove()
		end
	end

	Seetime_ColorsDialogues = {}

	local function SelectColorDialogue( default, target )
		if IsValid( Seetime_colorsDialogues[target] ) then
			Seetime_colorsDialogues[target]:Remove()
		end

		Seetime_colorsDialogues[target] = vgui.Create( "DFrame" )
		local main = Seetime_colorsDialogues[target]
		main:SetSize( 300, 330 )
		main:Center()
		main:SetTitle( "" )
		main:MakePopup()

		local paintFunc = DefaultPaintBuilder( 
			GetTranslation( "title_colors_" .. target )
		)
		main.Paint = paintFunc

		local CMixer = vgui.Create( "DColorMixer", main )
		CMixer:SetSize( 266, 266 )
		CMixer:SetPos( 5, 29 )
		CMixer:SetColor( default )
		CMixer.ValueChanged = function( self, color )
			C[target] = color
		end

		local btn = vgui.Create( "DButton1", main )
		btn:SetText( GetTranslation( "ok" ) )
		btn:SetPos( 0, 300 )
		btn:SetSize( 150, 25 )
		btn:CenterAlignX()
		btn.DoClick = function() main:Remove() end
	end

	local pos = 0

	local function AddButton( title, func )
		local btn = vgui.Create( "DButton1", Seetime_colorsDialogue )
		btn:SetPos( 5, 5 + 24 + 25 * pos + 5 * pos )
		btn:SetTextAndSize( C.MenuFont, title, 25 )
		btn.DoClick = func

		pos = pos + 1
		return btn

	end

	if IsValid( Seetime_colorsDialogue ) then
		Seetime_colorsDialogue:Remove()
	end

	Seetime_colorsDialogue = vgui.Create( "DFrame" )
	Seetime_colorsDialogue:SetTitle( "" )
	Seetime_colorsDialogue:MakePopup()
	Seetime_colorsDialogue:Center()

	local paintFunc = DefaultPaintBuilder( GetTranslation( "title_colors" ) )
	Seetime_colorsDialogue.Paint = paintFunc

	local buttons = { "Color", "TextColor", "AnotherColor", "AnotherTextColor" }

	local maxW = 0

	for i, v in ipairs( buttons ) do
		local btn = AddButton( GetTranslation( "title_colors_" .. v ), function()
			SelectColorDialogue( C[v], v )
		end )

		local bw, bh = btn:GetSize()

		if bw > maxW then
			maxW = bw
		end
	end

	Seetime_colorsDialogue:SetSize( maxW + 10, 150 )

end

local function UnfocusPlayer()
	local w, h = Seetime_Panel:GetSize()

	if (w ~= C.w or h ~= C.h) and not isCloseAnimationActive then
		isCloseAnimationActive = true
		Seetime_Panel:SizeTo( C.w, C.h, .75, 1, -1, function()

			-- Called when animation is done
			anotherPlayer = nil
			anotherTotalTime = 0
			anotherSessionTime = 0
			isCloseAnimationActive = false
		end )
	end

end


local function OpenConfigEditor()

	local _Before = table.Copy( C )

	local function Reset()
		C = table.Copy( _Before )
		UpdateSize( C.Font )
	end

	if IsValid( Seetime_ColorsDialogues ) then
		for k, v in pairs( Seetime_ColorsDialogues ) do
			Seetime_ColorsDialogues[ k ]:Remove()
		end
	end

	Seetime_ColorsDialogues = {}

	-- isEditingConfig = true

	if IsValid( Seetime_ConfiguratorPanel ) then
		Seetime_ConfiguratorPanel:Remove()
	end

	local w, h = math.min( ScrW()/2, 400 ), math.min( ScrH()/2, 400 )

	Seetime_ConfiguratorPanel = vgui.Create( "DFrame" )
	Seetime_ConfiguratorPanel:SetTitle( "" )
	Seetime_ConfiguratorPanel:SetSize( w, h )
	Seetime_ConfiguratorPanel:Center()
	Seetime_ConfiguratorPanel:MakePopup()

	-- function Seetime_ConfiguratorPanel:OnClose()
	-- 	isEditingConfig = false
	-- end

	local paintFunc = DefaultPaintBuilder( GetTranslation( "title_config" ) )
	Seetime_ConfiguratorPanel.Paint = paintFunc

	local oFontLabel = vgui.Create( "DLabel", Seetime_ConfiguratorPanel )
	oFontLabel:SetText( GetTranslation( "font" ) )
	oFontLabel:SetColor( Color(235,235,235) )
	oFontLabel:SetPos( 5, 24 + 5 )

	local oFont = vgui.Create( "DComboBox", Seetime_ConfiguratorPanel )
	oFont:SetSize( math.max( w/2, 200 ), 25 )
	oFont:SetSortItems( false )
	oFont:AddChoice( "DermaDefault" )
	oFont:AddChoice( "Comic Sans MS" )
	oFont:AddChoice( "Roboto" )
	oFont:AddChoice( "Tahoma" )
	oFont:AddChoice( "Helvetica" )
	oFont:AddChoice( "Marlett" )
	oFont:AddChoice( GetTranslation( "custom" ), nil, false, "icon16/cog.png" )

	oFont:ChooseOption( C._RealFont, 1 )

	SetActionFunc( oFont, function( s, i, opt, _ )
		if opt == GetTranslation( "custom" ) then
			OpenCustomFontDialogue()
			return
		end
		
		MakeCustomFont( opt, C.FontSize, C.FontOutline )
	end )

	local oFontSize = vgui.Create( "DNumberWang", Seetime_ConfiguratorPanel )
	oFontSize:SetValue( C.FontSize )
	oFontSize:SetMin( 2 )
	oFontSize:SetMax( 200 )
	oFontSize:SetSize( 45, 25 )

	SetActionFunc( oFontSize, function( s, value )
		C.FontSize = tonumber(value)
		MakeCustomFont( C._RealFont, tonumber(value), C.FontOutline )
	end )

	SetRow( oFontLabel, oFont )
	SetRow( oFont, oFontSize )

	local oFontOutline = vgui.Create( "DLabel", Seetime_ConfiguratorPanel )
	oFontOutline:SetColor( Color(235,235,235) )
	oFontOutline:SetPos( 5, 24 + 5*2 + 25 )
	oFontOutline:SetText( GetTranslation( "outline" ) )

	local oFontOutlineCheckBox = vgui.Create( "DCheckBox", Seetime_ConfiguratorPanel )
	function oFontOutlineCheckBox:OnChange( state )

		C.FontOutline = state
		MakeCustomFont( C._RealFont, C.FontSize, C.FontOutline )

	end
	
	-- display local time
	
	local oLocalTime = vgui.Create( "DLabel", Seetime_ConfiguratorPanel )
	oLocalTime:SetColor( Color(235,235,235) )
	oLocalTime:SetPos( 5, 24 + 5*20 + 25 )
	oLocalTime:SetText( GetTranslation( "display_localtime" ) )
	oLocalTime:SizeToContents()

	local oLocalTimeCheckBox = vgui.Create( "DCheckBox", Seetime_ConfiguratorPanel )
	oLocalTimeCheckBox:SetChecked( C.Display_LocalTime )
	function oLocalTimeCheckBox:OnChange( state )
		C.Display_LocalTime = state
		UnfocusPlayer()
		UpdateSize( C.Font )
	end
	
	-- display local time
	
	SetRow( oLocalTime, oLocalTimeCheckBox, 5 )

	SetRow( oFontOutline, oFontOutlineCheckBox )

	local oChangeColors = vgui.Create( "DButton", Seetime_ConfiguratorPanel )
	oChangeColors:SetText( GetTranslation( "set_colors" ) )
	oChangeColors:SetSize( 125, 25 )
	oChangeColors:SetPos( 5, 4 + 30 + 25*3 + 5 )
	oChangeColors.DoClick = OpenColorsDialogue

	local oDistanceLabel = vgui.Create( "DLabel", Seetime_ConfiguratorPanel )
	oDistanceLabel:SetColor( Color(235,235,235) )

	surface.SetFont( C.MenuFont )
	local tw, th = surface.GetTextSize( GetTranslation( "distance_units" ) )

	oDistanceLabel:SetText( GetTranslation( "distance_units" ) )
	oDistanceLabel:SetSize( tw + 10, 25 )
	oDistanceLabel:SetPos( 5, 24 + 5*2 + 25*2 )

	local oDistance = vgui.Create( "DNumberWang", Seetime_ConfiguratorPanel )
	oDistance:SetMax( GetGlobalInt( "seetime_maxdistance", 256 ) )
	oDistance:SetValue( C.MaxFraction / 0.0000307 )
	oDistance:SetSize( 45, 25 )

	SetRow( oDistanceLabel, oDistance )
	
	SetActionFunc( oDistance, function( s, value )
		C.MaxFraction = tonumber(value) * 0.0000307
	end )

	local buttonsSection = vgui.Create( "DPanel", Seetime_ConfiguratorPanel )
	function buttonsSection:Paint() end
	buttonsSection:Dock( BOTTOM )
	local pw, ph = Seetime_ConfiguratorPanel:GetSize()
	buttonsSection:SetSize( pw, 25 )

	local cancelButton = vgui.Create( "DButton", buttonsSection )
	cancelButton:SetText( GetTranslation( "cancel" ) )
	cancelButton:Dock( LEFT )

	local resetButton = vgui.Create( "DButton1", buttonsSection )
	resetButton:SetTextAndSize( C.MenuFont, GetTranslation( "reset" ), 25 )
	resetButton:CenterAlignX()

	resetButton.DoClick = function()
		C = table.Copy( _D )
		UpdateSize( C.Font )
	end

	local applyButton = vgui.Create( "DButton", buttonsSection )
	applyButton:SetText( GetTranslation( "apply" ) )
	applyButton:Dock( RIGHT )

	local function Clear()
		if IsValid( Seetime_colorsDialogue ) then
			Seetime_colorsDialogue:Remove()
		end

		if IsValid( Seetime_FontDialogue ) then
			Seetime_FontDialogue:Remove()
		end

		Seetime_ConfiguratorPanel:Remove()
		-- isEditingConfig = false
	end

	cancelButton.DoClick = function()
		Reset()
		Clear()
	end

	applyButton.DoClick = function()
		SaveConfig()
		Clear()
		notification.AddLegacy( GetTranslation( "notify_config_saved" ), NOTIFY_GENERIC, 2)
		surface.PlaySound( "buttons/lightswitch2.wav" )
	end

end

local function TwoDigit( num )
	num = tostring( num )

	if #num == 1 then
		return "0" .. num
	end

	return num
end

local function GetTimeFormatted( seconds )
	local F = math.floor

	seconds = F(seconds)

	local w = F( seconds / 604800 )
	local d = F( seconds / 86400  % 28 )
	local h = F( seconds / 3600   % 24 )
	local m = F( seconds / 60     % 60 )
	local s = seconds % 60

	return string.format( "%sw %sd %sh %sm %ss",
		TwoDigit(w),
		TwoDigit(d),
		TwoDigit(h),
		TwoDigit(m),
		TwoDigit(s)
	)
end

local function GetSetPlayerTime( s64 )
	if not _tempPlayers[ s64 ] then

		net.Start( "Seetime_get" )
		net.WriteString( s64 )
		net.SendToServer()

	else
		local data = _tempPlayers[ s64 ]
		local now = UnPredictedCurTime()
		local lastCheck = data["lastCheckAt"]

		anotherTotalTime = math.floor( now - lastCheck + data["lastAmount"] )
		anotherSessionTime = math.floor( now - lastCheck + data["lastAmountSession"] )

		data["lastAmount"] = anotherTotalTime
		data["lastAmountSession"] = anotherSessionTime
		data["lastCheckAt"] = now

	end
end

local function Seetime_Initialize()

	LoadConfig()
	MakeCustomFont( C._RealFont, C.FontSize, C.FontOutline )

	local ply = LocalPlayer()
	net.Start( "Seetime_get_self" )
	net.SendToServer()

	timer.Create( "Seetime_timer", 1, 0, function()
		totalTime = totalTime + 1
		sessionTime = sessionTime + 1

		if anotherPlayer ~= nil then
			anotherTotalTime = anotherTotalTime + 1
			anotherSessionTime = anotherSessionTime + 1
		end
	end )

	net.Receive( "Seetime_recieve_self", function( len, ply )
		totalTime = net.ReadUInt( 32 )  -- up to 4,294,967,295
		sessionTime = net.ReadUInt( 32 )

		-- "Recreating" timer and start counting from THIS moment
		timer.Adjust( "Seetime_timer", 1, nil, nil )
	end )

	if IsValid( Seetime_Panel ) then
		Seetime_Panel:Remove()
	end

	Seetime_Panel = vgui.Create( "DFrame" )
	Seetime_Panel:SetPos( C.x, C.y )
	Seetime_Panel:SetSize( C.w, C.h )
	Seetime_Panel:ShowCloseButton( false )
	Seetime_Panel:SetDraggable( true )
	Seetime_Panel:SetTitle( "" )

	function Seetime_Panel:OnMouseReleased( kCode )
		-- Check gmod github for PANEL:OnMouseReleased
		self.Dragging = nil
		self.Sizing = nil
		self:MouseCapture( false )

		C.x, C.y = self:GetPos()

		if kCode == MOUSE_RIGHT then
			OpenConfigEditor()
			surface.PlaySound( "buttons/lightswitch2.wav" )
		end

		SaveConfig()  -- Save pos
	end

	local _prevTextHeight = 0

	Seetime_Panel.Paint = function( s, width, height )
		if height ~= C.h and anotherPlayer then
			draw.RoundedBox( 5, 0, C.h, C.w, C._h_without_time, C.AnotherColor )
			draw.SimpleText( 
				GetTimeFormatted( anotherTotalTime ),
				C.Font,
				C.w/2,
				C.h+_prevTextHeight,
				C.AnotherTextColor,
				1,
				1
			)
			
			local __calc_h = C.h*2-_prevTextHeight
			
			if C.Display_LocalTime then
				__calc_h = C._h_without_time*2
			end
			
			draw.SimpleText( 
				GetTimeFormatted( anotherSessionTime ),
				C.Font,
				C.w/2,
				__calc_h,
				C.AnotherTextColor,
				1,
				1
			)
		end

		draw.RoundedBox( 5, 0, 0, C.w, C.h, C.Color )
		local tw, th = draw.SimpleText( 
			GetTimeFormatted( totalTime ),
			C.Font,
			C.w/2,
			_prevTextHeight,
			C.TextColor,
			1,
			1
		)
		
		if C.Display_LocalTime then
			draw.SimpleText(
				os.date( "%H:%M:%S", os.time() ),
				C.Font,
				C.w/2,
				C.h/2,
				C.TextColor,
				1,
				1
			)
		end
		
		draw.SimpleText( 
			GetTimeFormatted( sessionTime ),
			C.Font,
			C.w/2,
			C.h-_prevTextHeight,
			C.TextColor,
			1,
			1
		)

		_prevTextHeight = th
	end

	net.Receive( "Seetime_recieve", function( len, ply )
		local anotherSteam64 = net.ReadString()
		local total = net.ReadUInt( 32 )
		local session = net.ReadUInt( 32 )

		anotherTotalTime = total
		anotherSessionTime = session

		_tempPlayers[ anotherSteam64 ] = {
			["lastAmount"] = total,
			["lastAmountSession"] = session,
			["lastCheckAt"] = UnPredictedCurTime(),
		}
	end )

	hook.Add( "Think", "Seetime_Think", function()
		if not IsValid( Seetime_Panel ) then return end
		-- if isEditingConfig then return end

		local eyetrace = ply:GetEyeTrace()
		if eyetrace.Fraction > C.MaxFraction then return UnfocusPlayer() end

		local ent = eyetrace.Entity
		if ent == nil then return end  -- Just in case

		if ent:IsPlayer() then
			if not anotherPlayer then
				anotherPlayer = ent:SteamID64() or "0"  -- Can be nil
				GetSetPlayerTime( anotherPlayer )
				Seetime_Panel:SizeTo( C.w, C.h*2, .75, 0 )
			end
		else
			if anotherPlayer then
				UnfocusPlayer()
			end
		end
	end )

end

concommand.Add( "seetime_resetpos", function()
	if IsValid( Seetime_Panel ) then
		Seetime_Panel:SetPos( 0, 0 )
	end
end, nil, "Resets pos to 0,0", 0)

hook.Add( "InitPostEntity", "Seetime_InitPostEntity",  Seetime_Initialize )
