[Variables]
Battery_X =779
;Left, Right or Center
Battery_Anchor=Right
Battery_Width=(#Font_Size#*8)
;Self-generated
Battery_PowerPlan_Activate=

[Metadata]
Name=Fedina\\Battery
Author=reddit.com/u/khanhas
Description=Display battery level.

[BatteryAnchor]
Measure=String
String = #Battery_Anchor#
IfMatch = Center|center|Middle|middle
IfMatchAction = [!SetOption BatteryShape X "(#Bar_OffsetX#+#*Battery_X*#-#Battery_Width#/2)"]
IfMatch2 = Right|right
IfMatchAction2 = [!SetOption BatteryShape X "(#Bar_OffsetX#+#*Battery_X*#-#Battery_Width#)"]

[BatteryPowerPlanScript]
Measure=Script
ScriptFile=#@#Scripts\PowerPlan_Common_Script.lua
PlanList_FilePath = #ROOTCONFIGPATH#DownloadFile\PowerPlan.txt
BrightnessLevel_FilePath = #ROOTCONFIGPATH#DownloadFile\BrightnessLevel.txt
Meter_Name = Powerplan
Meter_Style = PlanStyle
Config = #ROOTCONFIG#\Themes\#Theme#\Additional_Comps_And_Scripts
Config_File = PowerPlanSwitcher.ini
Config_Path = #ROOTCONFIGPATH#\Themes\#Theme#\Additional_Comps_And_Scripts\PowerPlanSwitcher.ini

[BatteryFetchPowerPlanList]
Measure=Plugin
Plugin=RunCommand
Program="powercfg /L"
OutputFile=#ROOTCONFIGPATH#DownloadFile\PowerPlan.txt
OutputType=ANSI
FinishAction=!CommandMeasure BatteryPowerPlanScript "GetList()"

[BatteryFetchBrightnessLevel]
Measure=Plugin
Plugin=RunCommand
Parameter="powershell Get-Ciminstance -Namespace root/WMI -ClassName WmiMonitorBrightness"
OutputFile=#ROOTCONFIGPATH#DownloadFile\BrightnessLevel.txt
OutputType=ANSI
FinishAction=!CommandMeasure BatteryPowerPlanScript "GetBrightness()"

[BatteryShape]
Meter=Shape
X=(#Bar_OffsetX#+#Battery_X#)
Y=#Bar_OffsetY#
Shape=Rectangle 0,0,#Battery_Width#,#Bar_Height# | StrokeWidth 0 | Extend Color
Color = Fill Color [ColorMeasureScript:GetColor('#Color_Scheme3#', '#Color_Scheme4#', 'side to middle', #Battery_X#)] 
DynamicVariables=1

[BatteryLevel]
Measure=Plugin
Plugin=PowerPlugin
PowerState=Percent
IfCondition=(BatteryLevel <= 20)
IfTrueAction=[!SetOption BatteryIcon Text ""][!UpdateMeterGroup Battery][!Redraw]
IfCondition2=(BatteryLevel <= 40) && (BatteryLevel > 20)
IfTrueAction2=[!SetOption BatteryIcon Text ""][!UpdateMeterGroup Battery][!Redraw]
IfCondition3=(BatteryLevel <= 60) && (BatteryLevel > 40)
IfTrueAction3=[!SetOption BatteryIcon Text ""][!UpdateMeterGroup Battery][!Redraw]
IfCondition4=(BatteryLevel <= 80) && (BatteryLevel > 60)
IfTrueAction4=[!SetOption BatteryIcon Text ""][!UpdateMeterGroup Battery][!Redraw]
IfCondition5=(BatteryLevel <= 100) && (BatteryLevel > 80)
IfTrueAction5=[!SetOption BatteryIcon Text ""][!UpdateMeterGroup Battery][!Redraw]

[BatteryIcon]
Meter=String
FontFace=FontAwesome
FontSize=#Font_Size#
FontColor=#Color_Scheme2#
AntiAlias=1
StringAlign=LeftCenter
X=([BatteryShape:X] + [BatteryShape:W]/2 - ([BatteryIcon:W] + [Battery:W] + 5)/2)
Y=(#Bar_OffsetY#+#Bar_Height#/2)
Group=Battery
DynamicVariables=1

[Battery]
Meter=String
MeasureName=BatteryLevel
Postfix=%
FontFace=#Font_Face#
FontSize=#Font_Size#
FontColor=#Color_Scheme2#
AntiAlias=1
StringAlign=LeftCenter
X=5R
Y=r
Group=Battery
DynamicVariables=1
LeftMouseUpAction=[!WriteKeyValue Variables Curr_X "(#CURRENTCONFIGX# + [BatteryShape:X] + [BatteryShape:W]/2)" "#ROOTCONFIGPATH#\Themes\#Theme#\Additional_Comps_And_Scripts\PowerPlanSwitcher.ini"][!WriteKeyValue Variables Curr_Y "[SubSkinYPositionCalc]" "#ROOTCONFIGPATH#\Themes\#Theme#\Additional_Comps_And_Scripts\PowerPlanSwitcher.ini"][!WriteKeyValue Variables Dir "[SubSkinDirectionCalc]" "#ROOTCONFIGPATH#\Themes\#Theme#\Additional_Comps_And_Scripts\PowerPlanSwitcher.ini"]#Battery_PowerPlan_Activate#

