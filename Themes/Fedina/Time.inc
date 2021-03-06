[Variables]
Time_X=1920
;Left, Right or Center
Time_Anchor=right
Time_Width=(#Font_Size#*8)

[Metadata]
Name=Fedina\\Clock
Author=reddit.com/u/khanhas
Description=Clock with material icon. Click to activate Windows 10 Alarm & Clock app.

[TimeAnchor]
Measure=String
String = #Time_Anchor#
IfMatch = Center|center|Middle|middle
IfMatchAction = [!SetOption TimeShape X "(#Bar_OffsetX#+#*Time_X*#-#Time_Width#/2)"]
IfMatch2 = Right|right
IfMatchAction2 = [!SetOption TimeShape X "(#Bar_OffsetX#+#*Time_X*#-#Time_Width#)"]

[TimeShape]
Meter=Shape
X=(#Bar_OffsetX#+#Time_X#)
Y=#Bar_OffsetY#
Shape=Rectangle 0,0,#Time_Width#,#Bar_Height# | StrokeWidth 0 | Extend Color
Color = Fill Color [ColorMeasureScript:GetColor('#Color_Scheme3#', '#Color_Scheme4#', 'side to middle', 'Time_X')]
DynamicVariables=1

[MeasureTime]
Measure=Time
Format=%I:%M

[TimeIcon]
Meter=String
Text=
FontFace=FontAwesome
FontSize=(#Font_Size#*15/14)
FontColor=#Color_Scheme2#
AntiAlias=1
StringAlign=LeftCenter
X=([TimeShape:X] + [TimeShape:W]/2 - ([TimeIcon:W] + [Time:W] + 5)/2)
Y=(#Bar_OffsetY#+#Bar_Height#/2)
DynamicVariables=1

[Time]
Meter=String
MeasureName=MeasureTime
FontFace=#Font_Face#
FontSize=#Font_Size#
FontColor=#Color_Scheme2#
AntiAlias=1
StringAlign=LeftCenter
X=5R
Y=r
DynamicVariables=1
LeftMouseUpAction=[explorer.exe shell:appsFolder\Microsoft.WindowsAlarms_8wekyb3d8bbwe!App]
