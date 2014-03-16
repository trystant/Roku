Function findmusic(filelist)
' return a list of files with playable music extensions
	return get_filelist(filelist, "^.+\.(?:mp3|wma|m4a|mka)$")
end Function

Sub AudioPlayerInit(port) as Object
	o = CreateObject("roAssociativeArray")
	o.isPlayState = 0
	o.setPlayState = audio_newstate
	o.setbuttons = audio_setbuttons
	o.audio = CreateObject("roAudioPlayer")
	o.audio.setMessageport(port)
	o.audio.setLoop(0)
    s = CreateObject("roSpringboardScreen")
    s.SetBreadcrumbText("", "music player")
    s.SetDescriptionStyle("audio")
    s.SetMessagePort(port)
	o.screen = s
	return o
end Sub

Sub audio_setbuttons(newstate)
    m.screen.ClearButtons()
    if (newstate = 2)  then ' playing
        m.screen.AddButton(1, "pause")
       	m.screen.AddButton(2, "stop")
    else if (newstate = 1) then ' paused
      	m.screen.AddButton(1, "play")
       	m.screen.AddButton(2, "stop")
    else ' stopped
       	m.screen.AddButton(1, "start")
       	m.screen.AddButton(3, "next song")
    endif
end Sub

REM ******************************************************
REM
REM Set audio playing state to new state
REM    - update buttons
REM
REM ******************************************************
Sub audio_newstate(newstate as integer)
	if newstate = m.isplaystate return	' already there

	m.setbuttons(newstate)
	if newstate = 0 then			' STOPPED
		m.audio.Stop()
		m.isPlayState = 0
	else if newstate = 1 then		' PAUSED
		m.audio.Pause()
		m.isPlayState = 1
	else if newstate = 2 then		' PLAYING
		if m.isplaystate = 0
			m.audio.play()	' STOP->START
		else
			m.audio.Resume()	' PAUSE->START
		endif
		m.isPlayState = 2
	endif
End Sub

Function make_music_content(url)
    content = {}
    content.url = "file://" + url
    content.title = url
    content.description = url
    content.HDPosterURL = m.imageDir + "icon-music-hd.jpg"
    content.SDPosterURL = m.imageDir + "icon-music-sd.jpg"
    content.contenttype = "episode"
    if right(url,4) = ".m4a"
        content.StreamFormat = "mp4"
    endif
    return content
end Function    
        
Sub PlayMusic(container, content, selection, playbutton)
    port = CreateObject("roMessagePort")
    a = AudioPlayerInit(port)
    a.screen.Show()

    episode = make_music_content(content[selection].fullurl)

    mediacount = content.Count()    
    showOrder = GenerateMediaOrder(mediacount, selection, container.repeatmode = 3)
    
    localrepeatmode = container.repeatmode
'   Treat play button like the select button, do not make cause repeating, unless that was set in preferences
'    if (localrepeatmode = 0)
'        if (playbutton)
'            localrepeatmode = 2 ' sequential
'        endif
'    endif

    a.screen.setContent(episode)
    a.audio.setContentList([episode])

    a.setPlayState(2)		' playing
    index = 0
    do_next_song = false
    while true
	    msg = waitMessage(port)
        if type(msg) = "roAudioPlayerEvent"  then	' event from audio player
            if msg.isStatusMessage() then
                message = msg.getMessage()
                print "AudioPlayer Status Event - " message
            else if msg.isListItemSelected() then
                print "starting song:"; msg.GetIndex()
            else if msg.isRequestSucceeded()
                print "got request succeeded - ignore"
            else if msg.isFullResult() or msg.isRequestFailed()
                print "FullResult/isrequestfailed - playing finished type=";msg.getType();" data=";msg.GetData()
                a.setPlayState(0)
                if localrepeatmode = 0
                    print "no-repeat, returning now"
                    return
                endif
                print "setting do_next_song to true"
                do_next_song = true
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
                A.setPlayState(0)		' stop
                return
            endif
            if msg.isRemoteKeyPressed() then
                button = msg.GetIndex()
                print "Remote Key button = "; button
                if button = 5   ' right
                    do_next_song = true
                endif
            else if msg.isButtonPressed() then
                button = msg.GetIndex()
                print "button index="; button
                if button = 1 'pause or resume
                    if A.isPlayState < 2	' stopped or paused?
			            a.setPlayState(2)
		            else 'started
			            a.setPlayState(1)
                    endif
		        endif
                if button = 2 'stop
		            a.setplaystate(0) ' 	stop
		        endif
		        if button = 3 ' next song
		            print "Play next song"
		            do_next_song = true
		        endif
		    endif
	    endif
	    if do_next_song
	        print "Do Next Song"
            a.setPlayState(0)
            index = index + 1
            if index >= mediacount
                index = 0
            endif
            selection = showorder[index]
            print "index="; index; " selected next song=";selection
            episode = make_music_content(content[selection].fullurl)
            a.screen.setContent(episode)
            a.audio.setContentList([episode])
            a.setPlayState(2)		' playing
            do_next_song = false
	    endif
    end while
End Sub

Sub showMusicCategories(item)
    container = item.container
    looping = true
    while looping
        content = []
        content.Push(create_poster("all "+container.name, "icon-folder-hd.jpg", str(container.files.Count())+ " files", ShowAllAlpha, container))
        content.Push(create_poster("By Folder", "icon-folder-hd.jpg", "Navigate file structure", Browse, container))
        looping = DoCategories(item, content)
    end while
end Sub

sub MusicSettings(item)
    container = item.container
    while true
        posters = []
        desc1 = "Repeat set to "+rm_str(container.repeatmode)
        posters.Push(create_setting("Provider_Settings_Center_HD.png", desc1, doRepeatModeScreen) )
        result = dosetting(item.container, posters)
        if (result = -1) return
    end while
end sub

function newMusicContainer()
    container = newContentContainer("music", findmusic, "icon-music-hd.jpg", "icon-music-sd.jpg", PlayMusic, musicsettings )
    return container
end function
