' *********************************************************
' **  Simple Grid Screen Demonstration App
' **  Jun 2010
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************

'************************************************************
'** Application startup
'************************************************************
Sub Main()

    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    m.verbose = false
    m.port = CreateObject("roMessagePort")
    m.filesystem = CreateObject("roFilesystem")
    m.filesystem.SetMessagePort(m.port)
    m.imageDir = imageLocation()
    
    m.ShowDescription = true

    TopLevel()
End Sub

Sub ToggleDescription(screen)
    if m.ShowDescription
        m.ShowDescription = false
    else
        m.ShowDescription = true
    endif
    screen.SetDescriptionVisible(m.ShowDescription)
end sub
    


'*************************************************************
'** Set the configurable theme attributes for the application
'** 
'** Configure the custom overhang and Logo attributes
'** These attributes affect the branding of the application
'** and are artwork, colors and offsets specific to the app
'*************************************************************

Sub initTheme()
    app = CreateObject("roAppManager")
    app.SetTheme(CreateDefaultTheme())
End Sub

'******************************************************
'** @return The default application theme.
'** Screens can make slight adjustments to the default
'** theme by getting it from here and then overriding
'** individual theme attributes.
'******************************************************
Function CreateDefaultTheme() as Object
    theme = CreateObject("roAssociativeArray")

    theme.ThemeType = "generic-dark"
    '
    '  SD values
    '
    theme.OverhangPrimaryLogoOffsetSD_X  = "324" 'centered horizontally in the overhang region
    theme.OverhangPrimaryLogoOffsetSD_Y  = "21"
    theme.OverhangSliceSD = "pkg:/images/Overhang_BackgroundSlice_Blue_SD.png"
    theme.OverhangPrimaryLogoSD          = "pkg:/images/Logo_SD.png"
    theme.GridScreenLogoOffsetSD_X  = "324" 'centered horizontally in the overhang region
    theme.GridScreenLogoOffsetSD_Y  = "21"
    theme.GridScreenLogoSD          = "pkg:/images/logo-sd.png"
    theme.GridScreenOverhangSliceSD = "pkg:/images/Overhang_BackgroundSlice_Blue_SD.png"

    ' 2.8 options =================================
    theme.GridImageSizeSD           = "(150x100)"

    ' channel store constants
    
    
    theme.GridScreenOverhangHeightSD = "66"
    theme.GridScreenOverhangHeightHD = "99"
    theme.GridImageSizeSD           = "(110x62)"

    theme.GridScreenVisibleRectOffsetSD = "(48,49)"
    theme.GridScreenVisibleRectSizeSD = "(630x431)"


    theme.GridScreenTextOffsetSD = "(64,168)" ' 64+62+42
    theme.GridScreenLogoSD          = "pkg:/images/Overhang_Test_SD43.png"
    theme.GridScreenLogoOffsetSD_X  = "0"
    theme.GridScreenLogoOffsetSD_Y  = "0"
    '
    '  HD values
    '
    theme.OverhangPrimaryLogoOffsetHD_X  = "592" 'centered horizontally in the overhang region
    theme.OverhangPrimaryLogoOffsetHD_Y  = "31"
    theme.OverhangSliceHD                = "pkg:/images/Overhang_BackgroundSlice_Blue_HD.png"
    theme.OverhangPrimaryLogoHD          = "pkg:/images/Logo_HD.png"

    theme.GridScreenLogoOffsetHD_X  = "592" 'centered horizontally in the overhang region
    theme.GridScreenLogoOffsetHD_Y  = "31"
    theme.GridScreenLogoHD          = "pkg:/images/logo-hd.png"
    theme.GridScreenOverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_Blue_HD.png"

'   ===================== new options for 2.8 ======== HD ===========================
    'theme.GridImageSizeHD           = "(270x180)"

    ' channel store constants
'    theme.GridImageSizeHD           = "(210x132)"
'     theme.GridScreenBorderOffsetHD  = "(-34,-34)"
'    theme.GridScreenDescriptionOffsetHD = "(180,100)"
'    theme.GridScreenDescriptionSizeHD = "(508,196)"
'    theme.GridDescriptionBackgroundHD  = "pkg:/images/channelstore/ChannelStore_BOB_HD.png"

'    theme.GridScreenDescriptionBackfillOffsetHD = ""
'    theme.GridScreenDescriptionBackfillSizeHD = ""

'    theme.GridScreenTextOffsetHD = "(74,292)" ' 92+132+68
    
    theme.GridScreenLogoHD          = "pkg:/images/Overhang_Test_HD.png"
    theme.GridScreenLogoOffsetHD_X  = "0"
    theme.GridScreenLogoOffsetHD_Y  = "0"

'    theme.GridScreenDescriptionBackFillSizeHD = "(0x0)" ' disable backfill
'   ===================== end new options for 2.8 ===============================

'    theme.GridScreenFocusBorderHD        = "pkg:/images/GridCenter_Border_Square_HD.png"
'    theme.GridScreenFocusBorderSD        = "pkg:/images/GridCenter_Border_Square_HD.png"

'    theme.GridScreenDescriptionImageHD  = "pkg:/images/GridDescription_HD.png"
'    theme.GridScreenDescriptionUpperLeftBorderHD = "(65,60)"
'    theme.GridScreenDescriptionLowerRightBorderHD = "(20,10)"
'    theme.GridScreenDescriptionBackFillSizeHD = "(0x0)" ' disable backfill

'    theme.GridScreenDescriptionOffsetSD = "(120,80)"   ' 146+62+42
'    theme.GridScreenDescriptionImageSD  = "pkg:/images/GridDescription_HD.png"
'    theme.GridScreenDescriptionUpperLeftBorderSD = "(65,60)"
'    theme.GridScreenDescriptionLowerRightBorderSD = "(20,10)"
'     theme.GridScreenDescriptionBackFillSizeSD = "(30x30)"
'     theme.GridScreenDescriptionBackFillOffsetSD = "(20x20)"

    ' All these are greyscales
'    theme.GridScreenBackgroundColor = "#000000" ' 363636
    theme.GridScreenMessageColor    = "#808080"
    theme.GridScreenRetrievingColor = "#CCCCCC"
    theme.GridScreenListNameColor   = "#FFFFFF"

    ' Color values work here
    theme.GridScreenDescriptionTitleColor    = "#00FFFF"
    theme.GridScreenDescriptionDateColor     = "#FF005B"
    theme.GridScreenDescriptionRuntimeColor  = "#5B005B"
    theme.GridScreenDescriptionSynopsisColor = "#606000"
    
    'used in the Grid Screen
    theme.CounterTextLeft           = "#FF0000"
    theme.CounterSeparator          = "#00FF00"
    theme.CounterTextRight          = "#0000FF"

    return theme
End Function

