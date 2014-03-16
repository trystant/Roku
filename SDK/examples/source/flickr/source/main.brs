' *********************************************************
' *********************************************************
' **
' **  Roku DVP Yahoo Flickr Channel (BrightScript)
' **
' **  A. Wood, November 2009
' **
' **  Copyright (c) 2009 Anthony Wood. All Rights Reserved.
' **
' *********************************************************
' *********************************************************


' TO DO STILL
'
' Top Level
'  Browse HotTags (flickr.tags.getHotList) -> slideshow
'  Slideshow recent my changes ( flickr.photos.recentlyUpdated)
'  group search (icon)  -> enter keyword -> show results/select -> slideshow
'  tag search (icon) --> enter keyword -> show results/select -> slideshow
'
' slidshow
'  pause - show pause icon, pause.  pause or play to continue
'  ff or rw --> our trick mode screen? or grid of icons that you can scroll through.  Select picks up slide show at that point
'  info (title, photo #/total, etc) displayed in corder of photo
'

Sub Main()

    SetTheme()
'
' The following need to be setup for this application to work with flickr.
' You can get the information from this link:      http://www.flickr.com/services/api/auth.howto.web.html
'
    key = "00000000000000000000000000000000"
    secret = "0000000000000000"
    auth_num = "00000000000000000"

	' Pop up start of UI for some instant feedback while we load the icon data
	poster=uitkPreShowPosterMenu()
	if poster=invalid then
		print "unexpected error in uitkPreShowPosterMenu"
		return
	end if

	
	' Create a flickr connection object.  
	' Defined in the flickrtoolkit.brs.  
	' Pass in our API KEY and SECRET(get it from flickr.com)
	flickr=CreateFlickrConnection(key, secret)
	if flickr=invalid then
		print "unexpected error in CreateFlickrConnection"
		return
	end if

    flickr.auth_num = auth_num

	' get the URL of the first photo on the first page of the interesting photo list.  
	' This will be used as the Interestingness Main Menu Icon.
	five_photos = flickr.GetInterestingnessPhotoList(1, 5)
	if five_photos.Count()<>5 then
		print "unexpected error getting five_photos."
		return
	end if
	
	InterestingIcon = five_photos[0].GetURL()
	
	' use an actual picture if linked/auth'd, otherwise use a random interesting photo
	if flickr.auth_token=invalid then
		PhotoStreamIcon = five_photos[1].GetURL()
		SetsIcon		= five_photos[2].GetURL()
		GroupsIcon		= five_photos[3].GetURL()
		TagsIcon		= five_photos[4].GetURL()
	else
		PhotoStreamIcon = flickr.GetPhotoStreamPhotoList(1, 1)[0].GetURL()
		
		SetsIcon = flickr.GetPhotoSetList(flickr.nsid)
		if SetsIcon.IsEmpty() then
			SetsIcon = five_photos[2].GetURL()
		else
			SetsIcon		= SetsIcon[0].GetPrimaryURL()
		end if
		
		GroupsIcon = flickr.GetPublicGroupsList(flickr.nsid)
		if GroupsIcon.IsEmpty() then
			GroupsIcon = five_photos[3].GetURL()
		else
			GroupsIcon = GroupsIcon[0].GetPrimaryURL()
		end if
		
		TagsIcon=five_photos[4].GetURL()
		
	end if

	
	' Create an Array of AAs.  
	' Each AA contains the data needed to display a Main Menu icon
	mainmenudata = [ 
		{ShortDescriptionLine1:"Interestingness", ShortDescriptionLine2:"Show Random Interesting Photos", HDPosterUrl:InterestingIcon, SDPosterUrl:InterestingIcon}
		{ShortDescriptionLine1:"Hot Tags", ShortDescriptionLine2:"Browse Today's Top Tags",HDPosterUrl:TagsIcon, SDPosterUrl:TagsIcon}
		{ShortDescriptionLine1:"My PhotoStream", ShortDescriptionLine2:"Show My Photos",HDPosterUrl:PhotoStreamIcon, SDPosterUrl:PhotoStreamIcon}
		{ShortDescriptionLine1:"My Sets", ShortDescriptionLine2:"Browse My Sets", HDPosterUrl:SetsIcon, SDPosterUrl:SetsIcon}
		{ShortDescriptionLine1:"My Groups", ShortDescriptionLine2:"Browse My Groups", HDPosterUrl:GroupsIcon, SDPosterUrl:GroupsIcon}
		]
	
	' create a map of functions to call when a Main Menu icon is selected.
	' Each is the text name of a member of an object.  In this case I am using functions built into the flickr connection object
	onselect = [0, flickr, "DisplayInterestingPhotos", "BrowseHotTags", "DisplayMyPhotoStream", "BrowseMySets", "BrowseMyGroups"]
	
	uitkDoPosterMenu(mainmenudata, poster, onselect)

End Sub


' ******************************************************
' Setup theme for the application 
' ******************************************************
Sub SetTheme()
    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangOffsetSD_X = "72"
    theme.OverhangOffsetSD_Y = "25"
    theme.OverhangLogoSD  = "pkg:/images/Logo_Overhang_Flickr_HD.png"
    theme.OverhangSliceSD = "pkg:/images/Home_Overhang_BackgroundSlice_SD43.png"

    theme.OverhangOffsetHD_X = "123"
    theme.OverhangOffsetHD_Y = "48"
    theme.OverhangLogoHD  = "pkg:/images/Logo_Overhang_Flickr_HD.png"
    theme.OverhangSliceHD = "pkg:/images/Home_Overhang_BackgroundSlice_HD.png"

    app.SetTheme(theme)
End Sub


