'**********************************************************
'**  Audio Player Example Application - Audio Playback
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

REM ******************************************************
REM
REM PosterScreen object
REM
REM Upon return, there is a blank screen visible and you must call Show with a feed
REM then call GetSelection to wait for user selection
REM
REM ******************************************************
Function create_posterscreen(lastLocation As String, currentLocation As String) As Object
    o = CreateObject("roAssociativeArray")

    o.Feed           = []
    o.LastIASel      = 0

    'Methods
    o.LoadFeed                 = posterscreen_loadfeed
    o.GetSelection             = posterscreen_getsel
    o.Show                     = posterscreen_show
    o.CurrentList              = 0

    port = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetBreadcrumbText(lastLocation, currentLocation)
    screen.SetMessagePort(port)

    o.screen = screen 'keep alive as long as parent holds me
    return o
End Function

REM ******************************************************
REM
REM Display the screen
REM
REM ******************************************************
Sub posterscreen_show()
    m.screen.Show()
End Sub

REM ******************************************************
REM
REM Load a new feed into this screen
REM
REM Return true if the feed was successfully loaded,
REM false otherwise.
REM
REM ******************************************************
Function posterscreen_loadfeed(feed As Object) As Boolean
    if feed = invalid return false
    m.screen.SetListStyle("arced-portrait")
    m.screen.SetListDisplayMode("best-fit")

    m.screen.SetFocusedListItem(0)
    m.screen.SetContentList(feed)

    'm.Feed = feed
    return true
End Function

REM ******************************************************
REM
REM Wait for user to select something from the Poster Screen
REM
REM ******************************************************
Function posterscreen_getsel(timeout As Integer) As Integer
    print "Enter PosterScreen getsel"
    m.show()

    while true
        msg = wait(timeout, m.screen.GetMessagePort())
        print "posterscreen get selection typemsg = "; type(msg)

        if msg.isScreenClosed() then return -1

        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                print "list selected: " + Stri(msg.GetIndex())
                return msg.GetIndex()
            endif
        endif
    end while	        
End Function

Function StartPosterScreen(PosterList as object,a as string, b as string) as Object
    scr = create_posterscreen(a,b)
    scr.LoadFeed(PosterList.Posteritems)
    return scr
End function

Function CreatePosterItem(id as string, desc1 as string, desc2 as string) as Object
    item = CreateObject("roAssociativeArray")
    item.ShortDescriptionLine1 = desc1
    item.ShortDescriptionLine2 = desc2
    item.HDPosterUrl = "pkg:/images/" + id + "/Poster_Logo_HD.png"
    item.SDPosterUrl = item.HDPosterUrl
    return item
end Function
