' ********************************************************************
' ********************************************************************
' **  USB Support routines
' **
' **  February 2010
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' ********************************************************************
' ********************************************************************

' Simple search through the array of volumes for name and return the index
Function find_volume(volname)
    i = 0
    for each v in m.volumeList
        if v.fullpath = volname
            return i
        end if
        i = i + 1
    end for
    return -1
end Function

' Enter structure for a newly found volume on a usb device
Function NewVolume(c)
    label = c.left(c.len()-1)            ' chop ":" off to get default label
    c = c + "/"
    if c.left(3) = "ext" loc = "ext" else loc = "int"
    info = m.filesystem.GetVolumeInfo(c)
    desc = invalid
    if info.label <> invalid
        if info.label <> ""
            label = info.label
        endif
    endif

    if info.blocks > 0
        usage = int(100.0 * info.usedblocks / info.blocks + 0.5)
        desc = "usage: " + usage.tostr() + "%"
	    print "found volume:"; c; " label="; label; " "; desc
	else
	    print "found volume:"; c; " label="; label;  " 0 blocks"
    end if
    return ({
            FullPath: c
            loc: loc
            label: label
            totalblocks: info.blocks
            useblocks: info.usedblocks
            filelist: []
            photoslist: []
            musiclist: []
            videoslist: []
            })
end Function

Sub update_volume(screen, v)
    timer = CreateObject("roTimespan")
'   v is the volume datastructure
    volname = v.fullpath

    ' create a new entry if not found
    screen.SetBreadcrumbText(volname, "Scanning Media Files")

    print "Getting filelist:";volname
    waitobj = ShowPleaseWait("Scanning Media Files...","")
    cpath = CreateObject("roPath", volname)
    timer.Mark()
	v.filelist = FileIndex(cpath)        ' keep fileslists separate for each volume
	print "files found=";v.filelist.Count(); " time=";timer.TotalMilliseconds();" msecs"
	timer.Mark()
	v.photoslist = m.photos.finder(v.filelist)
    print "found "; v.photoslist.Count(); " photos in "; timer.TotalMilliseconds(); " msecs"
    timer.Mark()
    v.musiclist = m.music.finder(v.filelist)
    print "found "; v.musiclist.Count(); " songs in "; timer.TotalMilliseconds(); " msecs"
    timer.Mark()
	v.videoslist = m.videos.finder(v.filelist)
    print "found "; v.videoslist.Count(); " videos in "; timer.TotalMilliseconds(); " msecs"
end Sub

Sub delete_volume(volname)
    i = find_volume(volname)

    if (i >= 0)
        print "deleting volume ";volname; " at index ";i; "fullpath=";m.volumelist[i].fullpath
        m.volumelist[i] = {
                        fullpath: ""
                          }
    else
        print "could not fine volume ";volname; " to delete "
    end if
end Sub

Sub update_content(screen, name)
    print "update_content"
	 if NoUSBDevice(m.volumeList)
       	 print "No USB device detected"
       	 m.findcontent()     ' this will reset all the caches
         screen.SetBreadcrumbText("", "No USB device detected")
     else
         screen.SetBreadcrumbText(name, "Scanning Media Files")
         waitobj = ShowPleaseWait("Scanning Media Files...","")
         m.findcontent()
         screen.SetBreadcrumbText(name, "")
     endif
end Sub

' return true if there is a valid usb device connected
Function NoUSBDevice(volumelist)
    for each v in volumelist
    	if v.loc = "ext"
	        print "found external USB device:"; v.fullpath
            return false
        endif
    end for
    return true
end Function


Function get_filelist(filelist, match)
    files = []

    ' take the supplied regex and apply it case insensitively
    r = CreateObject("roRegex",match, "i")
    if (r = invalid)
        print "Error creating Regex with:"; match
        return []
    endif
    for each f in filelist
        if r.isMatch(f)
            files.Push(f)
        end if
    end for
    return files
end Function

Function AddToVolumeList(volname)
    i = 0
    searching = true
    while searching
        v = m.volumelist[i]
        if v = invalid
            searching = false
        else
            if v.fullpath = ""
                searching = false
            else
                if v.fullpath = volname+"/"
                    print "Warning, volume already in list, reusing slot"
                    searching = false
                else
                    i = i + 1
                endif
            endif
        end if
    end while
    print "after search i=";i; " volname=";volname
    v = Newvolume(volname)
    m.volumeList[i] = v
    m.volume2index.AddReplace(volname+"/", i)
    return v
end Function

Sub CreateVolumeList()
    m.volumeList = []
    m.volume2index = {}
    for each c in m.filesystem.GetVolumeList()
        print "Calling updatevolumelist c=";c
        AddToVolumeList(c)
    end for
end Sub

Function FileIndex(path)
' Extract all files and directory names from device
    print "Indexing(";path;")"

    files = m.filesystem.FindRecurse(path, ".+")
    print files.Count(); " files found on ";path
    return files
end Function
