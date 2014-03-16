'
' Set of routines to support creating lists of posters and present them for
' selection by the user
'

' Create alphabetical list of content and display it
Sub showAllalpha(item)
    print "Enter ShowAllAlpha"

    ' Create Regex to extract the filename from a string - everything after the last '/'
    ' the regex is decyphered as 'match everything starting from the end that isn't a backslash
    filename_regex = CreateObject("roRegex","[^\/]+$", "")
    
    timer = CreateObject("roTimespan")
    looping = true
    while looping
        timer.Mark()
        ' construct array of keys for sort comparison along with an array of indices to be sorted
        ' this is an array of filenames converted to lowercase so the sort is all done case insensitive
        
        ' get to the base variable to avoid unnecessary AA lookups
        ' this needs to be recomputed since the filelist may have changed
        files = item.container.files
        filecount = files.Count()

        if filecount = 0
            print "No files found - put up message"
            return
        endif
        filenames = CreateObject("roArray", filecount, false)
        indexes = CreateObject("roArray", filecount, false)
        index = 0
        for each f in files
            filenames[index] = lcase( filename_regex.Match(f)[0] )
            indexes[index] = index
            index = index + 1
        end for
        
        'use quicksort with an array of keys, not a function
        QuickSort(indexes, filenames)
        
        'construct a list of absolute filenames sorted by filename
        ' reuse the filenames array, it is already the right size
        k = 0
        for each i in indexes
            filenames[k] = files[i]
            k = k + 1
        end for
        print "construct list time=";timer.TotalMilliseconds()

        looping = ShowMediaDir(item, filenames, [], [], [], "")
        print "Categories: end of loop looping=";looping
  end while
end Sub

' return everything up to the first slash found after the i'th character
Function left_interesting_part(f,i)
    slash = instr(i+1, f, "/")
    if slash>0
        result = f.left(slash)
        return result
    endif
    return ""
end Function

Function find_unique_volumes(filelist, path)
' finds unique strings in filelist that end with slash, ignoring the path prefix
' this is used to find unique volume names as well as unique directory names
'ignore the initial "path part"
    pathlen = path.Len()
    volume_list = []
    istart = 0
    filelist_count = filelist.Count()
    if filelist_count = 0
        return []
    endif
    iend = filelist_Count - 1
    i = istart
    cvol = left_interesting_part(filelist[0], pathlen)
    volume_list.Push(cvol)
    i = i + 1
    ' dumb linear search for all unique volumes
    while i <= iend
        tname = left_interesting_part(filelist[i], pathlen)
        if tname <> ""
            if tname <> cvol
                cvol = tname
                volume_list.Push(cvol)
            endif
        endif
        i = i + 1
    end while
    if volume_list[0] = ""
        ' recover if the first entry was uninteresting
        print "removing null volume name count="; volume_list.count()
        if volume_list.Count() = 1
            return []
        else        ' return eveything except the first entry
            volume_list.Shift()
        endif
    endif
    return volume_list
end Function

Function find_local_files(infilelist,path)
' look for files in the current directory (skip directories)
    print "find_local_files path=";path
    outfilelist = []
    pathlen = path.Len()+1
    for each f in infilelist
        slash = instr(pathlen, f, "/")
        if slash < 1
            outfilelist.Push(f)
        endif
    end for
    return outfilelist
end Function

Function get_subdir_filelist(filelist, path)
' find all entries that have path as a prefix
    sublist = []
    len = path.len()
    for each f in filelist
        ' left side correct?
        if path = f.left(len)
            sublist.push(f)
        endif
    end for
    return sublist
end Function

' generate an array of indexes to use for accessing media in the order specified
' index is what we want the first one to be.
' israndom tells us to randomize the rest of the slots
Function GenerateMediaOrder(count, index, israndom)
    slideorder = [count]
    i = 0
    while i < count-index
        slideorder[i] = i+index
        i = i+1        
    end while
    while i < count
        slideorder[i] = i - (count-index)
        i = i+1
    end while

    if israndom
        ' now shuffle them up, except for the first one
        i = 1
        while i < count
            newpos = rnd(count-1)
            oldval = slideorder[newpos]
            slideorder[newpos] = slideorder[i]
            slideorder[i] = oldval
            i = i+1
        end while
    endif
    return slideorder
end Function

' Given internal volume name, eg 'ext1:/', lookup corresponding volume label
Function lookupLabel(v)
    label = ""
    index = m.volume2index.Lookup(v)
    label = m.volumeList[index].label
    return label
end Function

Function myimagedirlocation()
    ' used to retrieve the imageDir saved in the global 'm'
    return m.imageDir
end Function

' start browsing the media in the filesystem.
' only show files that are playable in current media type
Sub browse(item)
    print "Enter Browse"
    'enumerate all volumes and create posters for each. If there is only one volume, just drop into it
    container = item.container
    ' we already have a list of all files of this type in container.files
    
    screen_aa = NewPosterScreen(container.port)
    screen = screen_aa.screen
    screen.SetBreadcrumbText(container.name, "By Folder")
    screen.Show()
    
    looping = true
    while looping
        print "browse: looping"
        content = []

        volumelist = find_unique_volumes(container.files, "")
        filelistlist = []       ' list of lists of files
    
        ' if only one volume - go immediately to it
        print "browse loop volume count=";volumelist.Count()
        if volumelist.Count() = 1
            print "browsing directly to "; volumelist[0]
            volpath = volumelist[0]
            looping = browsedir(item, volpath, get_subdir_filelist(container.files, volpath) )
        else
            i = 0
            imagedir = myimagedirlocation()
            for each v in volumelist
                label =  lookupLabel(v)
                filelistlist[i] = get_subdir_filelist(container.files, v)
                    content.Push({
                            sdposterurl: imagedir + "icon-phyext-sd.jpg"
                            hdposterurl: imagedir + "icon-phyext-hd.jpg"
                            shortdescriptionline1: label
                            shortdescriptionline2: str(filelistlist[i].Count()) + " media files"
                          })
                i = i+1
            end for
            setcontent(screen, content)
            volume_selection = -1
            looping2 = true
            while looping2
                print "wait for volume selection"
                msg = pstr_process(screen, container.name)
                if msg.isScreenClosed()
        	        print "exit volume selection"
        	        return
                endif
                if msg.isStorageDeviceAdded() or msg.isStorageDeviceRemoved()
                    if (item.container.files.count() = 0)
                        ' nothing to display, return to toplevel
                        return
                    endif
                    ' go back around and recompute volumelist
                    looping2 = false
                endif
                if msg.isListItemSelected() and msg.GetIndex() < content.Count()
                    volume_selection = msg.GetIndex()
                    looping = browsedir(item, volumelist[volume_selection], filelistlist[volume_selection])
                    if looping = true then looping2 = false
                end if
                if msg.isRemoteKeyPressed()
                    button = msg.GetIndex()
                    print "remote key button = ";button
                endif
            end while
        endif
    end while
end Sub

function makedirposter(icon as string, labeldir as string, desc2 as string)
    print "makedirposter(";icon;",";labeldir;",";desc2;")"
    return {
                sdposterurl: icon
                hdposterurl: icon
                shortdescriptionline1: labeldir
                title: labeldir
                shortdescriptionline2: desc2
                description: desc2
            }
end function

' Descend into a directory browsing the current media type
Function browsedir(item, path, filelist) as boolean
    print "enter browsedir path="; path
    container = item.container
    ' Get a list of directories in the current directory
    dirlist = find_unique_volumes(filelist, path)
    if (dirlist.Count() = 0)
        return ShowMediaDir(item, filelist, [], [], [], path)
    else   ' at least one directory in the list
        filelistlist = []
        content = []
        i = 0
        for each dir in dirlist
                filelistlist[i] = get_subdir_filelist(filelist, dir)
                icon = m.imageDir + container.name + "folder.jpg"
                labeldir = lookupLabel(dir.Left(6)) + ":/" + dir.Right(dir.Len() - 6)
                desc2 = str(filelistlist[i].Count()) + " media files"
                print "found dir:"; dir
                pstr = makedirposter(icon, labeldir, desc2)
                content.Push(pstr)
                i = i+1
        end for
        return ShowMediaDir(item, filelist, content, dirlist, filelistlist, path)
    endif
end Function

' Display directory and file posters for the current media type for this directory
Function ShowMediaDir(item, filelist, dirposters, volumelist, filelistlist, path) as boolean

    container = item.container

    print "Enter Show"; container.name

    newposters = []
    dircount = dirposters.Count()
    
    gridmode = container.useGrid

    if (gridmode = 0)
        ' posterscreen mode
        screen_aa = NewPosterScreen(container.port)
        screen = screen_aa.screen
        screen.setBreadcrumbText(container.name, path)
        screen.setDisplayMode("best-fit")
        screen.Show()

        newposters.Append(dirposters)

        if (dircount > 0)
            local_files = find_local_files(filelist, path)
            posters = create_content_from_list(container, local_files)
            newposters.Append(posters)
            filecount = local_files.Count()
        else
            posters = create_content_from_list(container, filelist)
            newposters.Append(posters)
            filecount = filelist.Count()
        endif
        screen.setContentList(newposters)

    else
        ' grid screen mode
        screen_aa = NewGridScreen(container.port)
        screen = screen_aa.screen
        screen.setBreadcrumbText(container.name, path)
        if (dircount > 0)
            local_files = find_local_files(filelist, path)
            posters = create_content_from_list(container, local_files)
            filecount = local_files.Count()
        else
            posters = create_content_from_list(container, filelist)
            filecount = filelist.Count()
        endif

        rowcount = 1
        dircount = dircount + 1     ' need to count the "ChangeDir" icon
        listnames = ["Change Directory"]

        icon = m.imageDir + "icon-folderback-hd.jpg"
        OurdirPosters = [makedirposter(icon, "..", "Previous directory")]
        OurdirPosters.append(dirposters)

        listOflists = []
        if filecount > 0
            ' break up posters into grid with 10 per row
            newlist = []
            for each poster in posters
                newList.push(poster)
                if (newList.count() = 10)
                    listOfLists.push(newList)
                    newList = []
                endif
            end for
            if newList.count() > 0
                listOfLists.push(newList)
            endif
        endif
        rowcount = 1 + listoflists.count()
        print "Setuplists rowcount = ";rowcount
        screen.setuplists(rowcount)
        
        for i = 1 to listoflists.count()
            listnames.push("123456789 Media files MMMyyWWjjggpp list # "+str(i))
        end for
      
        screen.SetListNames(listnames)
        index = 1
        for each posterlist in listoflists
            screen.SetContentlist(index, posterlist)
            index = index + 1
        end for

        screen.SetContentList(0,OurdirPosters)       
    endif

    LastFocusList = 0
    LastFocusItem = 0
    if (gridmode=0)
        screen.setFocusedListItem(LastFocusItem)
    else
        screen.show()
        screen.setListVisible(2,false)
        'if (listoflists.count()>3)   screen.setListVisible(listoflists.count(),false)
    endif
    while true
        print "wait for poster to be selected"
	    msg = pstr_process(screen, container.name)
	    if msg.isScreenClosed() return false ' stop looping
	    if msg.isStorageDeviceAdded() or msg.isStorageDeviceRemoved()
	        return true     ' go back and start up with new filelist
	    else if msg.isListFocused()
	        lastfocuslist = msg.GetIndex()
	        print "Change list to ";lastfocuslist
	    else if msg.isListItemSelected()
	                                        ' msg.GetIndex() < newposters.Count()
	        selection = msg.GetIndex()
	        print "isListItemSelected selection=";selection
	        if gridmode=0
    	        if selection < dircount       ' selected a directory
	                if browsedir(item, volumelist[selection], filelistlist[selection]) return true
	            else        
	                item.container.f_all(container, posters, selection-dircount, false)
	            endif
	        else
	            ' in grid mode is screwy, selection is the row number, getdata returns the selection from that row
	            lastfocuslist = selection
	            selection = msg.getData()
	            if lastfocuslist = 0            ' selection from directory row
	                if selection = 0
	                    print "selected .. - go up when level"
	                    return false        ' selected ".."
	                endif
	                print "Selected a directory browse into it"
	                if browsedir(item, volumelist[selection-1], filelistlist[selection-1]) return true
	            else                            ' selection from media file row
	                selection = selection + (lastfocuslist - 1)*10
	                item.container.f_all(container, posters, selection, false)
	            endif
	        endif
        else if msg.isListItemFocused()
            LastFocusItem = msg.GetIndex()
        else if msg.isRemoteKeyPressed()
            button = msg.GetIndex()
            print "remote key button = ";button
            if button = 13 ' play button
                if gridmode
                    lastfocusitem = msg.getData()
                    lastfocuslist = msg.GetIndex()
                endif
                selection = LastFocusitem
                if (lastfocuslist=0) and (selection < dircount)
                    print "attempt to play a dir not supported yet"
                else    ' select and immediately go into play mode
                    if gridmode = 0
                        selection = selection - dircount
                    else
                        selection = selection + (lastfocuslist - 1)*10
                    endif
                    item.container.f_all(container, posters, selection, true)
                endif
            else if button = 10 ' Info button
                ToggleDescription(screen)
            endif
        endif
    end while
end Function

Function DoCategories(item, content) as boolean
    print "Enter DoCategories"
    container = item.container
    screen_aa = NewPosterScreen(container.port)
    screen = screen_aa.screen
    screen.SetBreadcrumbText(container.name, "")
    screen.Show()

    setcontent(screen, content)
    
    while true
        print "wait for catagory selection"
        msg = pstr_process(screen, container.name)
        if msg.isScreenClosed()
	        print "exit category selection"
	        return false
        endif
        if msg.isStorageDeviceAdded() or msg.isStorageDeviceRemoved()
            return true
        endif
        if msg.isListItemSelected()
            item = content[msg.GetIndex()]
            item.RenderFunction(item)
            return true
        end if
        if msg.isRemoteKeyPressed()
            button = msg.GetIndex()
            print "remote key button = ";button
        endif
    end while 
end Function
