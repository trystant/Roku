'**********************************************************
'**  Audio Player Example Application - Audio Playback
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

' NPR support routines

Function CreateNPRSongList() as Object
    aa = CreateObject("roAssociativeArray")
    aa.posteritems = CreateObject("roArray", 10, true)
    song = CreateSong("NPR","Live MP3 Internet Radio Stream","Many", "mp3", "http://npr.ic.llnwd.net/stream/npr_live24","http://media.npr.org/chrome/news/nprlogo_138x46.gif")
    aa.posteritems.push(song)
    return aa
End Function

Sub DoNPR(from as string)
    'Since there is only one item, go right into playing the NPR stream
    SongList = CreateNprSongList()
    Show_Audio_Screen(songlist.posteritems[0], from)
End Sub
