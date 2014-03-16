'******************************************************
'Registry Helper Functions
'******************************************************
Function RegRead(key, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then return sec.Read(key)
    return invalid
End Function

Function RegWrite(key, val, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    sec.Flush() 'commit it
End Function

Function RegDelete(key, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()
End Function


' registry tools
Function RegistryDump() as integer
    print "Dumping Registry"
    r = CreateObject("roRegistry")
    sections = r.GetSectionList()
    if (sections.Count() = 0)
        print "No sections in registry"
    endif
    for each section in sections
        print "section=";section
        s = CreateObject("roRegistrySection",section)
        keys = s.GetKeyList()
        for each key in keys
            val = s.Read(key)
            print "    ";key;" : "; val
        end for
    end for
    return sections.Count()
End Function

'*************************************************************'
'*                     SORT ROUTINES                         *'
'*************************************************************'

' simple quicksort of an array of values
Function internalQSort(A as Object, left as integer, right as integer) as void
    i = left
    j = right
    pivot = A[(left+right)/2]
    while i <= j
        while A[i] < pivot
            i = i + 1
        end while
        while A[j] > pivot
            j = j - 1
        end while
        if (i <= j)
            tmp = A[i]
            A[i] = A[j]
            A[j] = tmp
            i = i + 1
            j = j - 1
        end if
    end while
    if (left < j)
        internalQSort(A, left, j)
    endif
    if (i < right)
        internalQSort(A, i, right)
    end if        
End Function

' quicksort an array using a function to extract the compare value
Function internalKeyQSort(A as Object, key as object, left as integer, right as integer) as void
    i = left
    j = right
    pivot = key(A[(left+right)/2])
    while i <= j
        while key(A[i]) < pivot
            i = i + 1
        end while
        while key(A[j]) > pivot
            j = j - 1
        end while
        if (i <= j)
            tmp = A[i]
            A[i] = A[j]
            A[j] = tmp
            i = i + 1
            j = j - 1
        end if
    end while
    if (left < j)
        internalKeyQSort(A, key, left, j)
    endif
    if (i < right)
        internalKeyQSort(A, key, i, right)
    end if        
End Function

' quicksort an array using an indentically sized array that holds the comparison values
Function internalKeyArrayQSort(A as Object, keys as object, left as integer, right as integer) as void
    i = left
    j = right
    pivot = keys[A[(left+right)/2]]
    while i <= j
        while keys[A[i]] < pivot
            i = i + 1
        end while
        while keys[A[j]] > pivot
            j = j - 1
        end while
        if (i <= j)
            tmp = A[i]
            A[i] = A[j]
            A[j] = tmp
            i = i + 1
            j = j - 1
        end if
    end while
    if (left < j)
        internalKeyArrayQSort(A, keys, left, j)
    endif
    if (i < right)
        internalKeyArrayQSort(A, keys, i, right)
    end if        
End function

'******************************************************
' QuickSort(Array, optional keys function or array)
' Will sort an array directly
' If key is a function it is called to get the value for comparison
' If key is an identically sized array as the array to be sorted then
' the comparison values are pulled from there. In this case the Array
' to be sorted should be an array if integers 0 .. arraysize-1
'******************************************************
Function QuickSort(A as Object, key=invalid as dynamic) as void
    atype = type(A)
    if atype<>"roArray" then return
    ' weed out trivial arrays
    arraysize = A.Count()
    if arraysize < 2 then return
    if (key=invalid) then
        internalQSort(A, 0, arraysize - 1)
    else
        keytype = type(key)
        if keytype="Function" then
            internalKeyQSort(A, key, 0, arraysize - 1)
        else if (keytype="roArray" or keytype="Array") and key.count() = arraysize then
            internalKeyArrayQSort(A, key, 0, arraysize - 1)
        end if
    end if
End Function



'******************************************************'
'*         MISC UTILITIES                             *'
'******************************************************'

'******************************************************
'isstr
'
'Determine if the given object supports the ifString interface
'******************************************************
Function isstr(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifString") = invalid return false
    return true
End Function

'*********************************************************************'
'*  ShowPleaseWait - put up a please wait screen                     *'
'*********************************************************************'
Function ShowPleaseWait(title As dynamic, text As dynamic) As Object
    if not isstr(title) title = ""
    if not isstr(text) text = ""

    port = CreateObject("roMessagePort")
    dialog = invalid

    REM the OneLineDialog renders a single line of text better
    REM than the MessageDialog.
    if text = ""
        dialog = CreateObject("roOneLineDialog")
    else
        dialog = CreateObject("roMessageDialog")
        dialog.SetText(text)
    endif

    dialog.SetMessagePort(port)
    dialog.SetTitle(title)
    dialog.ShowBusyAnimation()
    dialog.Show()
    return dialog
End Function


'**************************************************************************************
'Perform Firmware version check
'Inputs: required major, minior, and build numbers
'
'Returns:
'    true - We have a good firmware version (equal to or greater then minimum required
'    false - We have a older firmware version - need to update
'**************************************************************************************
Function goodFirmwareVersion(minMajor=0, minMinor=0, minBuild=0) As boolean
    'get firmware version
    version = CreateObject("roDeviceInfo").GetVersion()

    print("Firmware Version Found: " + version)

    major = Val(Mid(version, 3, 1))
    minor = Val(Mid(version, 5, 2))
    build = Val(Mid(version, 8, 5))

    print "Major Version: ";major;" Minor Version: ";minor;" Build Number: ";build

    if minMajor > major then return false
    if minMajor < major then return true
    ' minMajor = major
    if minMinor > minor then return false
    if minMinor < minor then return true
    ' minMinor = minor
    if minBuild > build then return false    
    return true     
End Function



'*****************************************************************************************'
'*                     DEVELOPMENT UTILITIES                                             *'
'*****************************************************************************************'

'
' This is used to allow relocation of the image directory during development.
' New artwork can be put on an external usb drive in Roku/usbplayer/images and
' usbplayer will automatically start using the new images
' This way an artist will not need to get new artwork repackaged to see how it
' looks in the application. They can just put it on a usb drive and leave the
' programmer alone to program
Function imageLocation() as string
    ' setup default path
    path = "pkg:/images/"
    ' check for overrides
    fn = "ext1:/Roku/usbplayer/images/"
    if m.filesystem.Exists(fn)
        info = m.filesystem.Stat(fn)
        if info.type = "directory"
            path = fn
        else
            ' read the file and use the contents
            newpath = ReadAsciiFile(fn)
            if newpath.Left(4) = "http"
                path = newpath
            end if
        end if
        print "Found alternate images directory:"; path
    endif
    return path
end Function
