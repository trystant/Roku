'**********************************************************
'**  Audio Player Example Application - Audio Playback
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

' playstate
' 0 = stopped
' 1 = paused
' 2 = playing

REM ******************************************************
REM
REM AudioPlayer object init
REM
REM ******************************************************
Function AudioInit() As Object
	o = CreateObject("roAssociativeArray")
	
	o.isPlayState			= 0   ' Stopped
	o.setPlayState			= audioPlayer_newstate
	o.setupSong			= audioPlayer_setup
	o.clearContent			= audioPlayer_clear_content
	o.setContentList		= audioPlayer_set_content_list
	o.getMsgEvents			= audioPlayer_getmsg
	
	audioPlayer			= CreateObject("roAudioPlayer")
	o.port 				= CreateObject("roMessagePort") 'Message will be coming out when a track is done
	audioPlayer.SetMessagePort(o.port)
	o.audioPlayer			= audioPlayer

	audioPlayer.SetLoop(0)
	
	return o
End Function

REM ******************************************************
REM
REM Setup song
REM
REM ******************************************************
Sub audioPlayer_setup(song As string, format as string)
	m.setPlayState(0)
	item = CreateObject("roAssociativeArray")
	item.Url = song
	item.StreamFormat = format
	m.audioPlayer.AddContent(item)
End Sub

REM ******************************************************
REM
REM Play audio
REM
REM ******************************************************
Sub audioPlayer_newstate(newstate as integer)
	if newstate = m.isplaystate return	' already there

	if newstate = 0 then			' STOPPED
		m.audioPlayer.Stop()
		m.isPlayState = 0
	else if newstate = 1 then		' PAUSED
		m.audioPlayer.Pause()
		m.isPlayState = 1
	else if newstate = 2 then		' PLAYING
		if m.isplaystate = 0
			m.audioPlayer.play()	' STOP->START
		else
			m.audioPlayer.Resume()	' PAUSE->START
		endif
		m.isPlayState = 2
	endif
End Sub

REM ******************************************************
REM
REM Clear content
REM
REM ******************************************************
Sub audioPlayer_clear_content()
	m.audioPlayer.ClearContent()
End Sub

REM ******************************************************
REM
REM Set content list
REM
REM ******************************************************
Sub audioPlayer_set_content_list(contentList As Object) 
	m.audioPlayer.SetContentList(contentList)
End Sub


REM ******************************************************
REM
REM Get Message events
REM Return with audioplayer events or events for the 'escape' active screen
REM
REM ******************************************************
Function audioPlayer_getmsg(timeout as Integer, escape as String) As Object
	'print "In audioPlayer get selection - Waiting for msg escape=" ; escape
	while true
	    msg = wait(timeout, m.port)
	    'print "Got msg = "; type(msg)
	    if type(msg) = "roAudioPlayerEvent" return msg
	    if type(msg) = escape return msg
	    if type(msg) = "Invalid" return msg
	    ' eat all other messages
	end while
End Function

