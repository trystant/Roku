'**********************************************************
'**  Audio Player Example Application - Audio Playback
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

' Wma support routines

Function CreateWmaSongList() as Object
    aa = CreateObject("roAssociativeArray")
    aa.PosterItems = CreateObject("roArray", 5, true)

    songhost = "http://download.lisztonian.com/music/download/"
    pichost = "http://www.8notes.com/"

    song = CreateSong("Minuet in G","Johann Sebastian Bach","Jeremiah Jones", "wma", songhost + "Minuet+in+G-85.wma", pichost + "wiki/images/250px-JSBach.jpg")
    aa.posteritems.push(song)

    song = CreateSong("Prelude in A Major Op. 28 No. 7","Frederic Chopin","Jeremiah Jones", "wma", songhost + "Prelude+in+A+Major+Op+28+No+7-46.wma", pichost + "wiki/images/180px-Frederic_Chopin_photo.jpg")
    aa.posteritems.push(song)

    song = CreateSong("Bagatelle in A Minor - WoO 59 (Fur Elise or For Elise)","Ludwig Van Beethoven","Jeremiah Jones","wma", songhost + "Bagatelle+in+A+Minor++WoO+59-81.wma", pichost + "images/artists/beethoven_large.jpg")
    aa.posteritems.push(song)

    return aa
End Function

Sub DoWma(from as string)
    'Put up poster screen to pick a song to play
    SongList = CreateWmaSongList()
    Pscreen = StartPosterScreen(SongList, from, "WMA Songs")
    while true
        song = Pscreen.GetSelection(0)
        if song = -1 exit while
        Show_Audio_Screen(songlist.posteritems[song],"WMA Songs")
    end while
End Sub
