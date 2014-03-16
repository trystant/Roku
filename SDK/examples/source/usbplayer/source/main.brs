' ********************************************************************
' ********************************************************************
' **  Roku USB Player
' **
' **  February 2010
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' ********************************************************************
' ********************************************************************

'******************************************************
'Show a requires firmware update screen
'******************************************************
Sub showRequiresUpdateScreen()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)

    screen.AddHeaderText("Roku XR software update required")
    screen.AddParagraph("In order to use the USB Player, you must update the software on your Roku XR player to 2.6.  To update your software:")
    screen.AddParagraph("1.  Select " + chr(34) + "settings" + chr(34) + " from the Roku home screen.")
    screen.AddParagraph("2.  Select " + chr(34) + "player info." + chr(34))
    screen.AddParagraph("3.  Select " + chr(34) + "check for update." + chr(34))
    screen.AddParagraph("4.  Select " + chr(34) + "yes." + chr(34))
    screen.AddParagraph("5. Once your Roku XR player has finished updating to 2.8, you may use the USB channel.") 
    screen.AddButton(1, "back")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
            else if msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
            exit while                
        endif
    end while
End Sub

Sub Main()
    m.verbose = false
    if not goodFirmwareVersion(2,8,0)
        showRequiresUpdateScreen()
        return
    endif
    m.port = CreateObject("roMessagePort")
    m.filesystem = CreateObject("roFilesystem")

    m.filesystem.SetMessagePort(m.port)
    m.imagedir = imageLocation()
    app = CreateObject("roAppManager")
    app.SetTheme({
        OverhangOffsetSD_X: "64"
        OverhangOffsetSD_Y: "40"
        OverhangSliceSD: m.imageDir + "overhang-background-sd.png"
        OverhangLogoSD:  m.imageDir + "logo-sd.png"

        OverhangOffsetHD_X: "108"
        OverhangOffsetHD_Y: "60"
        OverhangSliceHD: m.imageDir + "overhang-background-hd.png"
        OverhangLogoHD:  m.imageDir + "logo-hd.png"

        BackgroundColor:       "#404040"
        PosterScreenLine1Text: "#18c314"
        BreadcrumbTextRight:   "#18c314"
    })

    ' create top level navigation
    TopLevel()
End Sub

sub prepare_toplevel()
	print "enter prepare_toplevel"
    m.topcontent = GetTopLevelPosters()
    SetContent(m.topscreen, m.topcontent)
    print "exit prepare_toplevel"
end sub

' ******************************************** content routines
function newContentContainer(name, finder, hdicon, sdicon, f_all, settings)
    repeatmode = reg_get_repeatmode(name, 0)  'supply default if nothing exists
    return {
            files : []                  ' hold the list of files for this content type
            finder : finder             ' updates the content file list
            posters : []
            hdicon: m.imageDir + hdicon
            sdicon: m.imageDir + sdicon
            port: m.port
            name : name
            f_all : f_all
            settings: settings
            repeatmode: repeatmode
            }
end function

' convert list of content files to list of poster
function create_content_from_list(container, filelist)
    posters = []
    ' create a regex to extract filename from fullpath
    filename_regex = CreateObject("roRegex","[^/]+$", "i")
    for each f in filelist
        resultarray = filename_regex.Match(f)
        fn = resultarray[0]
        ' if the lengths don't match then there is a directory prefix
        if (f.Len() <> fn.Len())
            dirname = f.Left(f.Len() - fn.Len() - 1)
            volname = f.Left(6) ' include the "/"
            labelname = lookupLabel(volname)
            if labelname <> invalid and labelname <> ""
                 folder = "in " + labelname + ":/" + dirname.Right(dirname.len() - 6)
            else
                folder = "in " + dirname
            endif
        else
            folder = ""
        endif
    'print "fn = "; fn; " folder=";folder
        posters.push({
		                    fullurl: f
		                    sdposterurl: container.sdicon
		                    hdposterurl: container.hdicon
		                    shortdescriptionline1: fn
   		                    shortdescriptionline2: folder
		              })
    end for
    return posters
end function

' ******************************************** end of content routines

' Coallesc all volume media filelists into filelists for each media type
sub findcontent()
    timer = CreateObject("roTimespan")

    print "finding Photo Files"

    m.photos.files = []
    m.music.files = []
    m.videos.files = []

    timer.mark()    
    for each v in m.volumelist
        volname = v.fullpath
        if v.loc = "ext"
            for each f in v.musiclist
                m.music.files.push(volname+f)
            end for
            for each f in v.photoslist
                m.photos.files.push(volname+f)
            end for
            for each f in v.videoslist
                m.videos.files.push(volname+f)
            end for
        end if
    end for
            
    print "found "; m.photos.files.count(); " photos and "; m.music.files.count(); " tunes and "; m.videos.files.count(); " videos in "; timer.totalmilliseconds(); " msecs"
end sub

' Write the repeat mode setting to the registry for this media type
sub reg_set_repeatmode(name, value)
    keyname = name + ".repeatmode"
    print "Calling regwrite(";keyname;",";value;",Roku:usbplayer"
    regwrite(keyname, str(value), "Roku:usbplayer")
end sub

' Access the registry to get the repeat mode setting if there
' If not there then set the repeat mode to a default
' Finally return the repeat mode for this type of media
function reg_get_repeatmode(name, default)
    mode = default        ' default
    keyname = name + ".repeatmode"
    reg_repeatmode = RegRead(keyname, "Roku:usbplayer")
    print "reg_get_repeatmode keyname=";keyname, " default = ";default
    if reg_repeatmode = invalid
        print "write default repeat mode for "; name
        reg_set_repeatmode(name, mode)
    else
        print "Found value in registry :";reg_repeatmode
        mode = val(reg_repeatmode)
    endif
    return mode
end function

Sub TopLevel()
    print "Enter Top Level"
    m.findcontent = findcontent
    
    m.music = newMusicContainer()
    m.photos = newPhotosContainer()
    m.videos = newVideosContainer()
    m.settings = newSettingsContainer()
    
    m.get_filelist = get_filelist
    m.prepare_toplevel = prepare_toplevel

    m.topscreen_aa = NewPosterScreen(m.port)
    m.topscreen = m.topscreen_aa.screen
    
    m.topscreen.show()
    
    CreateVolumeList()

    timer = CreateObject("roTimespan")
    timer.mark()
    ' on startup look at all available external volumes
    for each v in m.volumelist
	    if v.loc = "ext"                                ' only search through external volumes
	        update_volume(m.topscreen, v)
	    end if
    end for
    print "find all files time = "; timer.totalmilliseconds(); " msecs"
    update_content(m.topscreen, "USB Player")
    m.prepare_toplevel()

    while true
	    print "TopLevel: waiting for message"
	    msg = pstr_process(m.topscreen, "USB Player")
'  	    msg = m.topscreen_aa.getmsg()
        if msg.isScreenClosed()
	        print "exit TopLevel"
	        return
        endif
        if msg.isStorageDeviceAdded() or msg.isStorageDeviceRemoved()
        	m.prepare_toplevel()
        endif
        if msg.isListItemSelected()
            item = m.topcontent[msg.GetIndex()]
            item.RenderFunction(item)
           	m.prepare_toplevel()
        end if
    end while
    print "Exit Top Level"
end sub

function gettoplevelposters()
    content = []

    musiccount = 0
    photocount = 0
    videocount = 0
    if (m.music <> invalid)
        musiccount = m.music.files.count()
    endif
    if (m.photos <> invalid)
	    photocount = m.photos.files.count()
    endif
    if (m.videos <> invalid)
	    videocount = m.videos.files.count()
    endif
    if videocount>0
        content.Push(create_poster("videos","videosfolder.jpg", stri(videocount) + " files", ShowVideosCategories, m.videos))
    endif
    if photocount>0
    	content.Push(create_poster("photos","photosfolder.jpg", stri(photocount) + " files", ShowPhotosCategories, m.photos))
    endif
    if musiccount>0
	content.Push(create_poster("music","musicfolder.jpg", stri(musiccount) + " files", ShowMusicCategories, m.music))
    endif

    ' We always have a settings folder at the top
    content.Push(create_poster("settings","Provider_Settings_Center_HD.png", "Change your Preferences", ShowSettings, m.settings))
    return content
end function

'This is a wait wrapper that ignores invalid message objects (from debugging)
Sub WaitMessage(port) As Object
    while true
        msg = wait(0, port)
        if msg <> invalid return msg
    end while
End Sub

