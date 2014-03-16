' ********************************************************************
' ********************************************************************
' **
' **  Roku DeviantART Channel (BrightScript)
' **
' **  march 2009
' **  Copyright (c) 2009 Roku Inc. All Rights Reserved.
' ********************************************************************
' ********************************************************************

REM Demonstrate use of slideshow and audioplayer objects

Sub Main()

    SetTheme()

	' Pop up start of UI for some instant feedback while we load the icon data
	poster=uitkPreShowPosterMenu()
	if poster=invalid then
		print "unexpected error in uitkPreShowPosterMenu"
		return
	end if


	' Create a MediaRSS connection object.
	rss=CreateMediaRSSConnection()
	if rss=invalid then
		print "unexpected error in CreateMediaRSSConnection"
		return
	end if

	'Play some classical music while watching slideshow:
	audio = CreateObject("roAudioPlayer")
	item = CreateObject("roAssociativeArray")
	item.Url = "http://www.theflute.co.uk/media/BachCPE_SonataAmin_1.wma"
	item.StreamFormat = "wma"
	audio.AddContent(item)
	item.Url = "http://www.theflute.co.uk/media/Godard_SuitedeTroisMorceaux_3.wma"
      item.StreamFormat = "wma"
	audio.AddContent(item)
	item.Url = "http://www.theflute.co.uk/media/Bizet_Habanera.wma"
	item.StreamFormat = "wma"
	audio.AddContent(item)
	audio.SetLoop(true)
	audio.Play()

	' Create an Array of AAs.
	' Each AA contains the data needed to display a Main Menu icon
	hdposter = "pkg:/images/mm_icon_focus_hd.png"
	sdposter = "pkg:/images/mm_icon_focus_sd.png"
	mainmenudata = [
		{ShortDescriptionLine1:"User Favorites", ShortDescriptionLine2:"SlideShow User Favorites", HDPosterUrl:hdposter, SDPosterUrl:sdposter}
		{ShortDescriptionLine1:"Daily Deviations", ShortDescriptionLine2:"SlideShow Daily Deviation", HDPosterUrl:hdposter, SDPosterUrl:sdposter}
		]

	' create a map of functions to call when a Main Menu icon is selected.
	' Each is the text name of a member of an object.  In this case I am using functions built into the flickr connection object
	onselect = [0, rss, "DisplayUserFavorites", "DisplayDailyDeviations"]

	uitkDoPosterMenu(mainmenudata, poster, onselect)

End Sub

REM ******************************************************
REM
REM Setup theme for the application 
REM
REM ******************************************************

Sub SetTheme()
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


