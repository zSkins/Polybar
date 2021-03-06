function GetEssentialVariables()
	
	IconGap = tonumber(SKIN:GetVariable('Icon_Gap',20))

	MaxProcess = tonumber(SKIN:GetVariable('Max_Tracking_Process',15))

	BarOffsetX = tonumber(SKIN:GetVariable('Bar_OffsetX',0))

	Anchor = SKIN:GetVariable('Taskbar_Anchor','left'):lower()

	showIcon = SKIN:GetVariable('Taskbar_Show_Icon','true'):lower() == 'true'

	iconSize = tonumber(SKIN:GetVariable('Icon_Size',26)) * (showIcon and 1 or 0)

	showTitle = SKIN:GetVariable('Taskbar_Show_Title','true'):lower() == 'true'

	titlePad = (showTitle and showIcon) and tonumber(SKIN:GetVariable('Title_Pad',5)) or 0

	SKIN:Bang('!SetOptionGroup', 'Title', 'X', titlePad..'R')
	
	widthMode = SKIN:GetVariable('Taskbar_Process_Width_Mode','fixed'):lower()
	processMaxWidth = tonumber(SKIN:GetVariable('Taskbar_Max_Process_Width',125))
	taskbarWidth = tonumber(SKIN:GetVariable('Taskbar_Width',1130))

	if not showIcon then
		titleAlign = SKIN:GetVariable('Taskbar_TitleAlign','left'):lower()
		SKIN:Bang('!SetOptionGroup', 'Title', 'StringAlign', titleAlign..'Center')
		SKIN:Bang('!UpdateMeterGroup', 'Title')
	else
		SKIN:Bang('!SetOptionGroup', 'Title', 'StringAlign', 'LeftCenter')
		SKIN:Bang('!UpdateMeterGroup', 'Title')
	end

	fileview = SKIN:GetMeasure('TaskbarIconThemeFolder_Child')
	filecount = SKIN:GetMeasure('TaskbarIconThemeFileCount')

	Dragging = false

	SKIN:Bang('[!CommandMeasure GetActiveProcess "Run"]')
	enableDiscord = SKIN:GetVariable('Taskbar_Enable_Discord','true'):lower() == 'true'
	if enableDiscord then 
		SKIN:Bang('!EnableMeasureGroup Taskbar_Discord') 
		discordNotice = SKIN:GetMeasure('Taskbar_DiscordNotice')
	end
end

q=2
iconFile ={}
function gatherIconFile()
	local curFile = fileview:GetStringValue()
	if curFile ~= '' and curFile ~= '..' then
		table.insert(iconFile,string.lower(curFile))
	end
	q = q+1
	if q <= filecount:GetValue() + 1 then
		SKIN:Bang('[!SetOption TaskbarIconThemeFolder_Child Index '..q..'][!CommandMeasure TaskbarIconThemeFolder "Update"]')
	end
end

BSChar = {['_'] = '',['%(.*%)']='',['^%s']='',['%s$']=''}
lessBSChar =function (s)
			for k,v in pairs(BSChar) do
				s = string.gsub(s,k,v)
			end return string.lower(s) end
init = true
processTable = {'empty'}
AnchorPoint = 0

function UpdateNow()
	if Dragging then clearShape() return end
	Taskbar_X =tonumber(SKIN:GetVariable('Taskbar_X'))
	order = 0
	local discord = false
	processCount = tonumber(SKIN:GetVariable('processCount'))
	if not processCount then return end

	if showTitle then
		if widthMode == 'fixed' then
			titleWidth = processMaxWidth
		elseif widthMode == 'adapt' then
			titleWidth = processMaxWidth
			if ((IconGap*2 + iconSize + titlePad + titleWidth)*processCount) > taskbarWidth then
				titleWidth = taskbarWidth/processCount - IconGap*2 - iconSize - titlePad
			end
		elseif widthMode == 'hybrid' then
			titleWidth = taskbarWidth/processCount - IconGap*2 - iconSize - titlePad
		end
		SKIN:Bang('!SetOptionGroup', 'Title', 'ClipstringW', titleWidth)
	end
	processWidth = IconGap*2 + iconSize + (showTitle and titleWidth or 0) + titlePad

	SKIN:Bang('!SetVariable', 'Taskbar_Process_Width', processWidth)
	
	for i = 0,MaxProcess-1 do
		if SKIN:GetVariable('programscount'..i) ~='0' then 
			SKIN:Bang('!CommandMeasure', 'ProgramOptions', 'SetVariable|ProgramHandle'..i..'|ChildHandle|'..i..'|0')
		else
			SKIN:Bang('!SetVariable', 'ProgramHandle'..i, 'null')
		end
	end
	if init then 
		init = false
		--Create processTable{} table so we can remove, add, re-position icon.
		for i = 0, processCount-1 do
			processTable[i+1] = {
				['name'] = SKIN:GetVariable('programname'..i), 
				['handle'] = SKIN:GetVariable('programhandle'..i), 
				['index'] = i
			}
		end
	else 
		clearShape()

		--Tracking new process: If meet one, add it in processTable{}
		for i =  0, processCount-1 do
			local name = SKIN:GetVariable('programname'..i)
			local handle = SKIN:GetVariable('programhandle'..i)
			for j = 1,#processTable do
				if (
					name == processTable[j]['name'] and 
					handle == processTable[j]['handle']

				) then
					processTable[j]['index'] = i
					processTable[j]['handle'] = handle
					new = false
					break
				else
					new = true
				end
			end
			if new then processTable[#processTable+1] = {['name'] = name, ['handle'] = handle, ['index'] = i} end
		end

		--Tracking closed process: If isn't in program list anymore, remove it from our processTable{}
		for i = 1,#processTable do
			for j = 0, processCount-1 do
				local name = SKIN:GetVariable('programname'..j)
				local handle = SKIN:GetVariable('programhandle'..j)
				if name == processTable[i]['name'] and handle == processTable[i]['handle'] then
					nomore = false
					break
				else
					nomore = true
				end
			end
			if nomore then table.remove(processTable,i) 
			end
		end
	end

	shapeCount = 2
	if processCount == 0 then SKIN:Bang('!HideMeterGroup Taskbar_All') return end
	
	for i = 0,MaxProcess-1 do
		if processTable[i+1] then 
			local ProgramName = processTable[i+1]['name']

			SKIN:Bang('!ShowMeterGroup', i)

			local metaTable = {shape = {}, icon = {}, title = {}}

			--Calculate Icon position
			metaTable.shape['x'] = '(-#*AnchorPoint*#+'..(Taskbar_X + BarOffsetX + processWidth * i)..')'
			
			--Icon Theme Replace
			local tempName = lessBSChar(ProgramName)
			if showIcon then
				for k,v in pairs (iconFile) do
					if string.find(tempName,v) then
						metaTable.icon['ImageName'] = '#CURRENTPATH#Themes\\#Theme#\\Icons\\'..v..'.png'
						break
					else
						metaTable.icon['ImageName'] = '#@#Icons\\'..ProgramName..'.png'
					end
				end
			else
				metaTable.icon['Hidden'] = 1
			end

			if string.find(tempName,'discord') and enableDiscord then
				discord = true
				if showIcon then
					SKIN:Bang('!SetOption', 'Taskbar_Discord_UnreadCountBadge', 'X', '(['..i..'Icon:X]+#Icon_Size#)')
				else
					SKIN:Bang('!SetOption', 'Taskbar_Discord_UnreadCountBadge', 'X', '(['..i..'Title:X])')
				end
			end

			local tempIndex = processTable[i+1]['index']

			if showTitle then
				SKIN:Bang('!CommandMeasure', 'ProgramOptions', 'SetVariable|TitleName|ChildWindowName|'..tempIndex..'|0')
				metaTable.title['Text'] = SKIN:GetVariable('TitleName')
			else
				metaTable.title['Hidden'] = 1
			end

			if not showIcon then
				if titleAlign == 'center' then
					metaTable.icon['X'] = (processWidth/2) ..'r'
				elseif titleAlign == 'right' then
					metaTable.icon['X'] = (processWidth-IconGap) ..'r'
				elseif titleAlign == 'left' then
					metaTable.icon['X'] = IconGap ..'r'
				end
				metaTable.title['X'] = 'r'
			else
				metaTable.icon['X'] = IconGap ..'r'
				metaTable.title['X'] = titlePad ..'R'
			end
			
			local running = tonumber(SKIN:GetVariable('programscount'..tempIndex))
			metaTable.shape['MiddleMouseUpAction'] = concat {	
					'[!CommandMeasure ProgramOptions StartNew|', tempIndex, ']',
					'[!UpdateMeterGroup ', i, ']'
				}

			metaTable.shape['Shape'] = concat{'Rectangle 0,0,', processWidth, ',#Bar_Height# |Extend Trait'}
			if running == 0 then
				metaTable.shape['LeftMouseUpAction'] = concat {
					'[!DeactivateConfig "#ROOTCONFIG#\\Theme\\#Theme#\\Additional_Comps_And_Scripts"]',
					'[!CommandMeasure ProgramOptions StartNew|', tempIndex, ']',
					'[!UpdateMeterGroup ', i, ']'
				}

				metaTable.shape['MouseOverAction'] = ''
			else
				metaTable.shape['LeftMouseUpAction'] = concat {
					'[!DeactivateConfig "#ROOTCONFIG#\\Theme\\#Theme#\\Additional_Comps_And_Scripts"]',
					'[!CommandMeasure ProgramOptions ToFront|Main|', tempIndex, ']',
					'[!CommandMeasure TaskbarScript "DrawIconHighlight(', order, ')"]'
				}
				metaTable.shape['MouseOverAction'] = concat{
					'[!CommandMeasure AdditionalSkinActionTimer "Stop 1"]',
					'[!CommandMeasure TaskbarScript "ProcessMouseOver(', tempIndex, ',', i, ')"]'
				}

				local ActiveWindow = tonumber(SKIN:GetVariable('ActiveWindowProcess'))
				--Drawing subprocess tracking shape, depend on what theme, this function can be different and generate different style of shape.
				DrawSubProcessShape(running,i,ActiveWindow == tonumber(SKIN:GetVariable('programhandle'..tempIndex)))
			end
			SKIN:Bang('!CommandMeasure ProgramOptions "SetVariable|IsProcessPinned|IsPinned|'..tempIndex..'"')
			if SKIN:GetVariable('IsProcessPinned') == '0' then
				pinTitle = 'Pin to taskbar'
				pinCommand = 'PinItem|'..tempIndex
			else
				pinTitle = 'Unpin from taskbar'
				pinCommand = 'UnpinItem|'..tempIndex
			end
			metaTable.shape['RightMouseUpAction'] = concat {
				'[!DeactivateConfig "#ROOTCONFIG#\\Themes\\#Theme#\\Additional_Comps_And_Scripts"]',
				'[!WriteKeyValue Variables Title "', pinTitle, '" "#ROOTCONFIGPATH#Themes\\#Theme#\\Additional_Comps_And_Scripts\\taskbar_ContextMenu.ini"]',
				'[!WriteKeyValue Variables Action "', pinCommand, '" "#ROOTCONFIGPATH#Themes\\#Theme#\\Additional_Comps_And_Scripts\\taskbar_ContextMenu.ini"]',
				'[!WriteKeyValue Variables Title2 "', running == 0 and '' or running == 1 and 'Close window' or 'Close all windows', '" "#ROOTCONFIGPATH#Themes\\#Theme#\\Additional_Comps_And_Scripts\\taskbar_ContextMenu.ini"]',
				'[!WriteKeyValue Variables Action2 "Stop|All|', tempIndex, '" "#ROOTCONFIGPATH#Themes\\#Theme#\\Additional_Comps_And_Scripts\\taskbar_ContextMenu.ini"]',
				'[!ActivateConfig "#ROOTCONFIG#\\Themes\\#Theme#\\Additional_Comps_And_Scripts" "taskbar_ContextMenu.ini"]'
			}

			for mK,mV in pairs(metaTable) do
				for k,v in pairs(mV) do
					SKIN:Bang('!SetOption', i..mK, k, v)
				end
			end
			order = order + 1
		else
			SKIN:Bang('!HideMeterGroup', i)
		end
	end

	if discord and (discordNotice:GetValue() > 0) then 
		SKIN:Bang('!ShowMeterGroup', 'Taskbar_Discord')
	else
		SKIN:Bang('!HideMeterGroup', 'Taskbar_Discord')
	end

	DrawProcessBackground(order)
	
	if Anchor == 'left' then 
		AnchorPoint = 0
	elseif Anchor == 'right' then 
		AnchorPoint = processWidth*order
	else 
		AnchorPoint = processWidth*order / 2 
	end
	SKIN:Bang('!SetVariable', 'AnchorPoint', AnchorPoint)

	if SKIN:GetVariable('NeedsUpdate') == '1' then
		SKIN:Bang('["#@#getIcons.exe" "#AdditionalDependencies#"][!SetVariable NeedsUpdate 0]')
	end
end

function clearShape()
	--SKIN:Bang('!HideMeter', 'Taskbar_Discord_UnreadCountBadge')
	for i = 2,shapeCount do
		SKIN:Bang('!SetOption', 'SubprocessTrackingShape', 'Shape'..i, 'Ellipse 0,0,0 | StrokeWidth 0')
	end
end

taskbarIndex = -1 
function ProcessMouseOver(listIndex,index)
	taskbarIndex = index
	if Dragging then return end
	DrawIconHighlight(taskbarIndex)

	--Activate Media Control skin or Discord Status if meet one, else show subprocess list.
	local tempName = lessBSChar(processTable[index+1]['name'])
	local pathMusicControl = repVar('#ROOTCONFIGPATH#Themes\\#Theme#\\Additional_Comps_And_Scripts\\MusicControl.ini')
	local pathDiscord = repVar('#ROOTCONFIGPATH#\\Themes\\#Theme#\\Additional_Comps_And_Scripts\\DiscordStatus.ini')
	local playerMusicControl = '' 
	local discordStatus, musicControl, nowPlaying = false, false, false

	if string.find(tempName,'spotify') then
		musicControl = true
		playerMusicControl = 'Spotify'

	elseif string.find(tempName,'google play') then
		musicControl = true
		playerMusicControl = 'GPMDP'

	elseif string.find(tempName,'aimp') then
		musicControl = true
		nowPlaying = true
		playerMusicControl = 'AIMP'

	elseif (
		string.find(tempName,'foobar') or 
		string.find(tempName,'jukebox') or 
		string.find(tempName,'media center') or 
		string.find(tempName,'musicbee') 
	) then
		musicControl = true
		nowPlaying = true
		playerMusicControl = 'CAD'

	elseif string.find(tempName,'winamp') then
		musicControl = true
		nowPlaying = true
		playerMusicControl = 'winamp'

	elseif string.find(tempName,'mediamonkey') then
		musicControl = true
		nowPlaying = true
		playerMusicControl = 'MediaMonkey'

	elseif string.find(tempName,'wmplayer') then
		musicControl = true
		nowPlaying = true
		playerMusicControl = 'wmp'
	elseif string.find(tempName,'discord') and enableDiscord then
		discordStatus = true
	else
		ShowSubProcess(listIndex)
		return
	end

	local configPath, configFile = '', ''

--DISCORD STATUS SUB-SKIN
	if discordStatus then
		configPath = pathDiscord
		configFile = 'DiscordStatus.ini'

--MUSIC CONTROL SUB-SKIN
	elseif musicControl then
		configPath = pathMusicControl
		configFile = 'MusicControl.ini'
		if nowPlaying then
			SKIN:Bang('!WriteKeyValue', 'Variables', 'MusicControl_Current_Player', 'NowPlaying', pathMusicControl)
			SKIN:Bang('!WriteKeyValue', 'Variables', 'MusicControl_NowPlaying_Player', playerMusicControl, pathMusicControl)
		else	
			SKIN:Bang('!WriteKeyValue', 'Variables', 'MusicControl_Current_Player', playerMusicControl, pathMusicControl)
		end
	end

	--Set proper position for sub-skin
	SKIN:Bang('!WriteKeyValue', 'Variables', 'Curr_X', repVar('(['..taskbarIndex..'Shape:X]+['..taskbarIndex..'Shape:W]-'..processWidth..'/2+#CURRENTCONFIGX#)'), configPath)
	SKIN:Bang('!WriteKeyValue', 'Variables', 'Curr_Y', repVar('[SubSkinYPositionCalc]'), configPath)
	SKIN:Bang('!WriteKeyValue', 'Variables', 'Dir', repVar('[SubSkinDirectionCalc]'), configPath)

	SKIN:Bang('!DeactivateConfig', '#ROOTCONFIG#\\Themes\\#Theme#\\Additional_Comps_And_Scripts')
	SKIN:Bang('!ActivateConfig', '#ROOTCONFIG#\\Themes\\#Theme#\\Additional_Comps_And_Scripts', configFile)
end

function ShowSubProcess(index)
	local pathSubProcess = repVar('#ROOTCONFIGPATH#\\Themes\\#Theme#\\Additional_Comps_And_Scripts\\taskbar_Subprocess.ini')
	local configSubProcess = repVar('#ROOTCONFIG#\\Themes\\#Theme#\\Additional_Comps_And_Scripts')

	SKIN:Bang('!DeactivateConfig', configSubProcess)



--SUBPROCESS LIST SUBSKIN
	local running = tonumber(SKIN:GetVariable('programscount'..index))

	if running == 0 then return end
	SKIN:Bang('!WriteKeyValue', 'Variables', 'MaxSubprocessMeter', running-1, pathSubProcess)

	local listX = repVar(concat{'([', taskbarIndex, 'Shape:X]+[', taskbarIndex, 'Shape:W]-', processWidth, '/2+#CURRENTCONFIGX#)'})

	SKIN:Bang('!WriteKeyValue', 'Variables', 'Curr_X', listX, pathSubProcess)

	SKIN:Bang('!WriteKeyValue', 'Variables', 'Curr_Y', repVar('[SubSkinYPositionCalc]'), pathSubProcess)
	SKIN:Bang('!WriteKeyValue', 'Variables', 'Dir', repVar('[SubSkinDirectionCalc]'), pathSubProcess)

	for i = 0,running-1 do
		SKIN:Bang('!WriteKeyValue', 'SubShape'..i, 'Meter', 'Shape', pathSubProcess)
		SKIN:Bang('!WriteKeyValue', 'SubShape'..i, 'MeterStyle', 'SubShapeStyle', pathSubProcess)

		SKIN:Bang('!WriteKeyValue', 'Subprocess'..i, 'Meter', 'String', pathSubProcess)
		SKIN:Bang('!WriteKeyValue', 'Subprocess'..i, 'MeterStyle', 'SubProcessStyle', pathSubProcess)

		SKIN:Bang('!WriteKeyValue', 'SubDelete'..i, 'Meter', 'String', pathSubProcess)
		SKIN:Bang('!WriteKeyValue', 'SubDelete'..i, 'MeterStyle', 'SubDeleteStyle', pathSubProcess)
	end

	SKIN:Bang('!ActivateConfig', configSubProcess, 'taskbar_Subprocess.ini')

	--Get subprocess name from ProgramOptions plugin then set it to meters in Subprocess skin
	for i = 0, running-1 do
		SKIN:Bang('!CommandMeasure', 'ProgramOptions', concat{'SetVariable|WindowName|ChildWindowName|', index, '|', i})
		local p, s, d = 'Subprocess'..i, 'SubShape'..i, 'SubDelete'..i
		SKIN:Bang('!SetOption', p, 'Text', SKIN:GetVariable('WindowName'), configSubProcess)
		SKIN:Bang('!SetOption', s, 'LeftMouseUpAction', concat{'[!DeactivateConfig][!CommandMeasure ProgramOptions "ToFront|Child|', index, '|', i, '" "#ROOTCONFIG#"]'}, configSubProcess)
		SKIN:Bang('!ShowMeter', s, configSubProcess)
		SKIN:Bang('!ShowMeter', p, configSubProcess)
		SKIN:Bang('!ShowMeter', d, configSubProcess)
		--Set function for Close button: If this process has only one subprocess is itself, closing it will deactivate Subprocess skin. 
		--Else tell ProgramOptions to Update and re-run this function for new subprocess list.
		if running == 1 then
			closeAction = concat{
				'[!CommandMeasure ProgramOptions "Stop|Child|', index, '|0" "#ROOTCONFIG#"]',
				'[!DeactivateConfig]'
			}
		else	
			closeAction = concat{
				'[!CommandMeasure ProgramOptions "Stop|Child|', index, '|', i, '" "#ROOTCONFIG#"]',
				'[!UpdateMeasure ProgramOptions "#ROOTCONFIG#"][!CommandMeasure TaskbarScript "UpdateNow();ShowSubProcess(', index, ')" "#ROOTCONFIG#"]'
			}
		end
		SKIN:Bang('!SetOption', p, 'MiddleMouseUpAction', closeAction, configSubProcess)
		SKIN:Bang('!SetOption', d, 'LeftMouseUpAction', closeAction, configSubProcess)
	end
	SKIN:Bang('!UpdateMeter', 'SubprocessShape', configSubProcess)
	SKIN:Bang('!Update', configSubProcess)
end

copy = {}
animationTable= {}
draggingPos = -1
function MovingIcon(dragPos,curPos)
	draggingPos = getIndex(dragPos)

	SKIN:Bang('!SetOptionGroup', 'Action', 'MouseLeaveAction', ' ')

	DrawIconHighlight(draggingPos)
	--draggingPos is original index in taksbar of dragging Icon
	--curPos is index in taskbar of Icon currently on
	copy = {'empty'}
	copyOptionX = {}
	--Clone our program table
	for i = 1,#processTable do
		copy[i]=processTable[i]
		animationTable[i] = {}
		animationTable[i]['oldPos'] = SKIN:GetMeter((i-1)..'Shape'):GetX()
	end
	if #copy == 1 then return end

	--Switch position. Our taskbar index starts at 0 but table in Lua index starts at 1 so we need to +1 everything
	local temp = copy[draggingPos+1]
	table.remove(copy,draggingPos+1)
	table.insert(copy,curPos+1,temp)

	--Redraw every icons
	for i = 0,#copy-1 do
		for k,v in pairs(processTable) do
			if copy[i+1] == v then
				--Calculate index in taskbar
				order = k
				break
			end
		end
		animationTable[order]['newPos'] = -AnchorPoint + Taskbar_X + BarOffsetX + processWidth * i
	end
	timing = 1
	SKIN:Bang('!CommandMeasure', 'IconActionTimer', 'Execute 1')
	SKIN:Bang('!DeactivateConfig', '#ROOTCONFIG#\\Themes\\#Theme#\\Additional_Comps_And_Scripts')
end

--When user release the mouse, DoneMoving() will run. 
function DoneMoving()
	if (
		not #copy or 
		#copy == 1 or
		copy == processTable
	) then return end
	ProcessMouseLeave(draggingPos)
	--Apply new icon position to our program table
	for i = 1,#copy do
		processTable[i] = copy[i]
	end
	SKIN:Bang('!SetOptionGroup', 'Action', 'MouseLeaveAction', '!CommandMeasure TaskbarScript "ProcessMouseLeave(getIndex(\'#*CURRENTSECTION*#\'))"')
	SKIN:Bang('!UpdateMeterGroup','Action')
	SKIN:Bang('!Redraw')
end

function repVar(monstervar)
	return SKIN:ReplaceVariables(monstervar)
end

function getIndex(name)
	return name:match('%d+')
end

function runAnimation()
	if timing > 0 and timing < 10 then
		timing = timing + 1
		for i = 1,#copy do
			SKIN:GetMeter((i-1)..'Shape'):SetX(animationTable[i]['oldPos'] + (animationTable[i]['newPos'] - animationTable[i]['oldPos'])*math.sin(timing/10*math.pi/2))
		end
		if enableDiscord then 
			SKIN:Bang('!UpdateMeterGroup', 'Taskbar_Discord')
			
		end
	elseif timing == 10 then
		SKIN:Bang('!CommandMeasure', 'IconActionTimer', 'Stop 1')
	end
end

--Concatenate string by using table.concat instead of `..` to optimizing resource
function concat(t)
	return table.concat(t, "")
end