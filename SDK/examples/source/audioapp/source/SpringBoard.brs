'**********************************************************
'**  Audio Player Example Application - Audio Playback
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

REM ******************************************************
REM
REM SpringBoard object
REM
REM Upon return, there is a blank screen visible and you must
REM call Show with a feed item. Then call GetSelection to wait
REM for user selection
REM
REM ******************************************************
Function create_springboard(port as Object, prevLoc as string) As Object
    o = CreateObject("roAssociativeArray")
	
    'Methods
    o.Show               = springboard_show
    o.ReloadButtons      = springboard_reload_buttons

    screen = CreateObject("roSpringboardScreen")
    screen.SetBreadcrumbText(prevLoc,"Now Playing")
    screen.SetMessagePort(port)
    screen.SetStaticRatingEnabled(false)

    o.screen = screen 'keep alive as long as parent holds me
    return o
End Function

REM ******************************************************
REM
REM Set Buttons for the current Playstate
REM
REM ******************************************************
Sub springboard_reload_buttons(playstate as integer)
    m.screen.ClearButtons()
    if (playstate = 2)  then ' playing
        m.screen.AddButton(1, "pause playing")
       	m.screen.AddButton(2, "stop playing")
    else if (playstate = 1) then ' paused
      	m.screen.AddButton(1, "resume playing")
       	m.screen.AddButton(2, "stop playing")
    else ' stopped
       	m.screen.AddButton(1, "start playing")
    endif
End Sub

REM ******************************************************
REM
REM Show the springboard
REM
REM ******************************************************
Sub springboard_show()
    m.screen.Show()
End Sub
