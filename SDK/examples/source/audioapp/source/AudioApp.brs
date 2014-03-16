'**********************************************************
'**  Audio Player Example Application - Audio Playback
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

REM ******************************************************
REM
REM AudioApp - shows use of audioplayer concurrently with
REM            basic Springboard. Using one shared msgport
REM            for multiple event types.
REM
REM ******************************************************


REM ******************************************************
REM
REM CreateCategories
REM
REM Create the categories for the PosterScreen
REM
REM ******************************************************
Function CreateCategories()
    aa = CreateObject("roAssociativeArray")
    aa.PosterItems = CreateObject("roArray", 5, true)

    Category = CreatePosterItem("npr","NPR","Radio Station")
    Category.Process = DoNpr
    aa.PosterItems.push(Category)

    Category = CreatePosterItem("mp3","MP3","Song List")
    Category.Process = DoMp3
    aa.PosterItems.push(Category)

    Category = CreatePosterItem("wma","WMA","Song List")
    Category.Process = DoWma
    aa.PosterItems.push(Category)

    return aa
End Function

REM ******************************************************
REM
REM Main - all Roku scripts startup here.
REM 
REM
REM ******************************************************
Sub Main()
    print "Entering Main"
    SetMainAppIsRunning()
    
    ' Set up the basic color scheme
    SetTheme()

    ' Create a list of audio programs to put in the selection screen
    Categories = CreateCategories()

    ' Display the selection screen
    Pscreen = StartPosterScreen(Categories,"","Categories")

    while true
        Category = Pscreen.GetSelection(0)    ' returns a selection
        if Category = -1 then
            return
        endif
        Categories.PosterItems[Category].Process("Categories")
    end while

    print "Exiting Main"
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

REM ******************************************************
REM
REM Show audio screen
REM
REM Upon entering screen, should start playing first audio stream
REM
REM ******************************************************
Sub Show_Audio_Screen(song as Object, prevLoc as string)
    Audio = AudioInit()
    picture = song.HDPosterUrl
    print "picture at:"; picture

    o = CreateObject("roAssociativeArray")
    o.HDPosterUrl = picture
    o.SDPosterUrl = picture
    o.Title = song.shortdescriptionline1
    o.Description = song.shortdescriptionline2
    o.contenttype = "episode"
	
    if (song.artist > "")
        o.Description = o.Description + chr(10) + "by: " + song.artist
    endif
	
    scr = create_springboard(Audio.port, prevLoc)
    scr.ReloadButtons(2) 'set buttons for state "playing"
    scr.screen.SetTitle("Screen Title")

    SaveCoverArtForScreenSaver(o.SDPosterUrl,o.HDPosterUrl)
    scr.screen.SetContent(o)

    scr.Show()

    ' start playing
    
    Audio.setupSong(song.feedurl, song.streamformat)
    Audio.audioplayer.setNext(0)
    Audio.setPlayState(2)		' start playing
	
    while true
        msg = Audio.getMsgEvents(20000, "roSpringboardScreenEvent")

        if type(msg) = "roAudioPlayerEvent"  then	' event from audio player
            if msg.isStatusMessage() then
                message = msg.getMessage()
                print "AudioPlayer Status Event - " message
                if message = "end of playlist"
                    print "end of playlist (obsolete status msg event)"
                        ' ignore
                else if message = "end of stream"
                    print "done playing this song (obsolete status msg event)"
                    'audio.setPlayState(0)	' stop the player, wait for user input
                    'scr.ReloadButtons(0)    ' set button to allow play start
                endif
            else if msg.isListItemSelected() then
                print "starting song:"; msg.GetIndex()
                else if msg.isRequestSucceeded()
                print "ending song:"; msg.GetIndex()
                audio.setPlayState(0)	' stop the player, wait for user input
                scr.ReloadButtons(0)    ' set button to allow play start
            else if msg.isRequestFailed()
                print "failed to play song:"; msg.GetData()
            else if msg.isFullResult()
                print "FullResult: End of Playlist"
            else if msg.isPaused()
                print "Paused"
            else if msg.isResumed()
                print "Resumed"
            else
                print "ignored event type:"; msg.getType()
            endif
        else if type(msg) = "roSpringboardScreenEvent" then	' event from user
            if msg.isScreenClosed()
                print "Show_Audio_Screen: screen close - return"
                Audio.setPlayState(0)
                return
            endif
            if msg.isRemoteKeyPressed() then
                button = msg.GetIndex()
                print "Remote Key button = "; button
            else if msg.isButtonPressed() then
                button = msg.GetIndex()
                print "button index="; button
                if button = 1 'pause or resume
                    if Audio.isPlayState < 2	' stopped or paused?
                        if (Audio.isPlayState = 0)
                              Audio.audioplayer.setNext(0)
                        endif
                        newstate = 2  ' now playing
		    else 'started
                         newstate = 1 ' now paused
                    endif
                else if button = 2 ' stop
                    newstate = 0 ' now stopped
                endif
                audio.setPlayState(newstate)
                scr.ReloadButtons(newstate)
                scr.Show()
            endif
        endif
    end while
End Sub
