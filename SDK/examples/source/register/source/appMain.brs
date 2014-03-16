' ********************************************************************
' **  Roku Registration Demonstration App 
' **  May 2009
' **  Copyright (c) 2009 Roku Inc. All Rights Reserved.
' ********************************************************************

Sub Main()

    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    'prepare the screen for display and get ready to begin
    screen=preShowHomeScreen("Register", "")
    if screen=invalid then
        print "unexpected error in preShowHomeScreen"
        return
    end if

    showHomeScreen(screen)

End Sub


'*************************************************************
'** Set the configurable theme attributes for the application
'** In this example app, we just use the SDK default artwork
'** 
'** Configure the custom overhang and Logo attributes
'*************************************************************

Sub initTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangOffsetSD_X = "72"
    theme.OverhangOffsetSD_Y = "25"
    theme.OverhangSliceSD = "pkg:/images/Overhang_BackgroundSlice_Blue_SD43.png"
    theme.OverhangLogoSD  = "pkg:/images/Logo_Overhang_Roku_SDK_SD43.png"

    theme.OverhangOffsetHD_X = "123"
    theme.OverhangOffsetHD_Y = "48"
    theme.OverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_Blue_HD.png"
    theme.OverhangLogoHD  = "pkg:/images/Logo_Overhang_Roku_SDK_HD.png"

    app.SetTheme(theme)

End Sub

