'**********************************************************
'**  Audio Player Example Application - Audio Playback
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

' Mp3 support routines

Function CreateMp3SongList() as Object
    aa = CreateObject("roAssociativeArray")
    aa.posteritems = CreateObject("roArray", 10, true)
    
    songhost = "http://download.lisztonian.com/music/download/"
    pichost = "http://www.8notes.com/"

    song = CreateSong("Tritsch-Tratsch Polka Op. 214 (Chit-Chat Polka)","Johann Strauss, Jr.","Jeremiah Jones","mp3", songhost + "TritschTratsch+Polka+Op+214-93.mp3", pichost + "images/artists/johann_strauss.jpg")
    aa.posteritems.push(song)

    song = CreateSong("Love Dreams - Nocturne in A flat Major No. 3 (Liebestraume)","Franz Liszt","Jeremiah Jones","mp3", songhost + "Nocturne+in+A+flat+Major+No+3-58.mp3", pichost + "images/artists/liszt.jpg")
    aa.posteritems.push(song)

    song = CreateSong("Sonata in F Major K. 300k (332) - III Allegro","Wolfgang Amadeus Mozart","Jeremiah Jones","mp3", songhost + "Sonata+in+F+Major+K+300k+332+III+Allegro-101.mp3", pichost + "wiki/images/W_a_mozart.jpg")
    aa.posteritems.push(song)

    return aa
End Function

Sub DoMp3(from as string)
    'Put up poster screen to pick a song to play
    SongList = CreateMp3SongList()
    Pscreen = StartPosterScreen(SongList, from, "MP3 Songs")

    while true
        song = Pscreen.GetSelection(0)
        if song = -1 exit while
        Show_Audio_Screen(songlist.posteritems[song],"MP3 Songs")
    end while
End Sub

