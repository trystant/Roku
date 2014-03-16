'******************************************************
'Registry Helper Functions
'******************************************************
Function RegRead(key as String, section=invalid) as Dynamic
    if section = invalid then section = "Default"
    reg = CreateObject("roRegistry")
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then return sec.Read(key)
    return invalid
End Function

Function RegWrite(key as String, val as String, section=invalid) as Void
    if section = invalid then section = "Default"
    reg = CreateObject("roRegistry")
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val) 'commit it
End Function

Function RegDelete(key as String, section=invalid) as Void
    if section = invalid then section = "Default"
    reg = CreateObject("roRegistry")
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
End Function

' insert value into array
sub SortedInsert(A as object, value as string)
    count = a.count()
    a.push(value)       ' use push to make sure array size is correct now
    if count = 0
        return
    endif
    ' should do a binary search, but at least this is better than push and sort
    for i = count-1 to 0 step -1
        if value >= a[i]
            a[i+1] = value
            return
        endif
        a[i+1] = a[i]
    end for
    a[0] = value
end sub

'******************************************************
'Insertion Sort
'Will sort an array directly, or use a key function
'******************************************************
Sub Sort(A as Object, key=invalid as dynamic)
    
    't = CreateObject("roTimespan")
    if type(A)<>"roArray" then return

    if (key=invalid) then
        for i = 1 to A.Count()-1
            value = A[i]
            j = i-1
            while j>= 0 and A[j] > value
                A[j + 1] = A[j]
                j = j-1
            end while
            A[j+1] = value
        next

    else
        tk = type(key)
        if tk<>"Function" and tk<>"roFunction" then return
        for i = 1 to A.Count()-1
            valuekey = key(A[i])
            value = A[i]
            j = i-1
            while j>= 0 and key(A[j]) > valuekey
                A[j + 1] = A[j]
                j = j-1
            end while
            A[j+1] = value
        next

    end if
    'tot = A.count()
    'print "Sort on "; tot; " elements took"; t.totalMilliseconds(); "ms"

End Sub

sub internalQSort(A as Object, left as integer, right as integer)
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
end sub

sub internalKeyQSort(A as Object, key as dynamic, left as integer, right as integer)
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
end sub

'******************************************************
'Quick Sort
'Will sort an array directly, or use a key function
'******************************************************
Sub QuickSort(A as Object, key=invalid as dynamic)
    if type(A)<>"roArray" then return
    ' weed out trivial arrays
    if A.count() < 2 then return

    if (key=invalid) then
        internalQSort(A, 0, A.count() - 1)
    else
        if type(key)<>"Function" then return

        internalKeyQSort(A, key, 0, A.count() - 1)
    end if
End Sub



'***************************************************************************
' MakeLowestLast
' finds the lowest value item and exchanges it with the end of the array.
' If it is already at the end of the array don't do anything.
' This is designed to make it easy to use pop to extract the element
' Pop/Push is more efficient then shift/unshift when manipulating arrays
'***************************************************************************
Sub MakeLowestLast(A as Object, key=invalid as dynamic)
    if type(A)<>"roArray" then return
    array_end = A.count()-1
    if array_end <= 0 then return ' fewer than two things in the list
    lowest = array_end
    if (key=invalid) then
        lowestval = A[lowest]
        for i = 0 to A.Count()-2
            value = A[i]
            if lowestval > value
                lowestval = value
                lowest = i              ' remember new lowest
            endif
        next
        if lowest<array_end
            A[lowest] = A[array_end]
            A[array_end] = lowestval
        endif
    else
        tk = type(key)
        if tk<>"Function" and tk<>"roFunction" then return
        lowestval = key(A[lowest])
        for i = 0 to A.Count()-2
            value = key(A[i])
            if lowestval > value
                lowestval = value
                lowest = i
            endif
        next
        if lowest<array_end
            t = A[array_end]
            A[array_end] = A[lowest]
            A[lowest] = t
        endif
    end if
End Sub

Function SymDiff(A as Object, B As Object) As Object
    ' computes the set symmetric difference of two arrays
    ' of integers and it returns it in a AA.
    't = CreateObject("roTimespan")
    D = CreateObject("roAssociativeArray")
    if type(A)<>"roArray" or type(b)<>"roArray" then return D
    'tot = 0
    for each i in A
        D[itostr(i)] = false
        'tot = tot +1
    end for
    for each i in B
        bb = itostr(i)
        if D.DoesExist(bb)
            D.delete(bb)
        else
            D[bb] = true
        end if
        'tot = tot + 1
    end for
    'print "SymDiff on ";  tot; " elements took"; t.totalMilliseconds(); "ms"
    return D
End Function

Function HasOrderChanged(A as Object, B As Object) As Boolean
    if type(A)<>"roArray" or type(b)<>"roArray" then return true
    if A = invalid OR B = invalid then return true
    sizeA = A.count()
    sizeB = B.count()
    maxSize = 0
    if sizeA >= sizeB then 
        maxSize = sizeA
    else
        maxSize = sizeB
    end if
    
    for i=0 to maxSize-1
        if A[i] <> B[i] then return true
    end for
    return false
End Function


Function Deck(range as Integer)
    ' creates an array of integers of size range
    ' populated with the integers in order [0,range-1]
    A=CreateObject("roArray",range,true)
    for i=0 to range-1
        A[i]=i
    end for
    return A
End Function

Function RandSelect(count as Integer, range As Integer) As Object
    ' Selects count distinct integers in [0,range-1].
    ' Note that this creates an array with size range,
    ' so its interim size is not just limited
    ' by the final count of objects returned.
    A = Deck(range)
    for i=0 to count-1
        j = rnd(range-i) + i - 1
        tmp = A[j]
        A[j] = A[i]
        A[i] = tmp
    end for
    for i=count to range-1
        A.pop()
    end for
    return A
End Function

Function wrap(num As Integer, size As Dynamic) As Integer
    ' wraps via mod if size works
    ' else just clips negatives to zero
    ' (sort of an indefinite size wrap where we assume
    '  size is at least num and punt with negatives)
    remainder = num
    if isint(size) and size<>0
        base = int(num/size)*size
        remainder = num - base
    else if num<0
        remainder = 0
    end if
    return remainder
End Function

Function snap(num As Integer, window As Integer) As Integer
    ' snap to the start of a window when window is negative
    ' and to the end when it's positive
    ' snap(13,-5) = 10; snap(13,5) = 14
    if window=0 then return num
    div = abs(window)
    if window>0 then num = num + window
    base = int(num/div)*div
    if window>0 then base = base - 1
    return base
End Function

'******************************************************
'Convert anything to a string
'
'Always returns a string
'******************************************************
Function tostr(any)
    ret = AnyToString(any)
    if ret = invalid ret = type(any)
    if ret = invalid ret = "unknown" 'failsafe
    return ret
End Function


'******************************************************
'Get a " char as a string
'******************************************************
Function Quote()
    q$ = Chr(34)
    return q$
End Function


'******************************************************
'isxmlelement
'
'Determine if the given object supports the ifXMLElement interface
'******************************************************
Function isxmlelement(obj as dynamic) As Boolean
    return obj <> invalid and  GetInterface(obj, "ifXMLElement") <> invalid
End Function


'******************************************************
'islist
'
'Determine if the given object supports the ifList interface
'******************************************************
Function islist(obj as dynamic) As Boolean
    return obj <> invalid and GetInterface(obj, "ifArray") <> invalid
End Function

'******************************************************
'isint
'
'Determine if the given object supports the ifInt interface
'******************************************************
Function isint(obj as dynamic) As Boolean
    return obj <> invalid and GetInterface(obj, "ifInt") <> invalid
End Function

'******************************************************
'isfunc
'
'Determine if the given object supports the function interface
'******************************************************
Function isfunc(obj as dynamic) As Boolean
    tf = type(obj)
    return tf="Function" or tf="roFunction"
End Function

'******************************************************
' validint
'
' always return a valid int. if the argument is 
' invalid or not an int, return 0.
'******************************************************
Function validint(obj as dynamic) As Integer
    if obj <> invalid and GetInterface(obj, "ifInt") <> invalid
        return obj
    else
        return 0
    end if
End Function

'******************************************************
' validstr
'
' always return a valid string. if the argument is 
' invalid or not a string, return an empty string.
'******************************************************
Function validstr(obj As Object) As String
    if obj <> invalid and GetInterface(obj, "ifString") <> invalid
         return obj
    else
        return ""
    endif
End Function 


'******************************************************
'isstr
'
'Determine if the given object supports the ifString interface
'******************************************************
Function isstr(obj as dynamic) As Boolean
    return obj <> invalid and  GetInterface(obj, "ifString") <>invalid
End Function

'******************************************************
'isnonemptystr
'
'Determine if the given object supports the ifString interface
'and returns a string of non zero length
'******************************************************
Function isnonemptystr(obj)
    if isnullorempty(obj) return false
    return true
End Function


'******************************************************
'isnullorempty
'
'Determine if the given object is invalid or supports
'the ifString interface and returns a string of non zero length
'******************************************************
Function isnullorempty(obj)
    if obj = invalid return true
    if not isstr(obj) return true
    if Len(obj) = 0 return true
    return false
End Function

Function validbool(obj) As Boolean
    return type(obj)="roBoolean" and obj=true
End Function

'******************************************************
'isbool
'
'Determine if the given object supports the ifBoolean interface
'******************************************************
Function isbool(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifBoolean") = invalid return false
    return true
End Function


'******************************************************
'isfloat
'
'Determine if the given object supports the ifFloat interface
'******************************************************
Function isfloat(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifFloat") = invalid return false
    return true
End Function


'******************************************************
'strtobool
'
'Convert string to boolean safely. Don't crash
'Looks for certain string values
'******************************************************
Function strtobool(obj As dynamic) As Boolean
    if obj = invalid return false
    if type(obj) <> "roString" and type(obj) <> "String" return false
    o = strTrim(obj)
    o = Lcase(o)
    if o = "true" return true
    if o = "t" return true
    if o = "y" return true
    if o = "1" return true
    return false
End Function

Function strtoprintable(obj as dynamic) As String
    r = ""
    if isnonemptystr(obj)
        l = len(obj)
        for i=1 to l
            c = mid(obj,i,1)
            a = asc(c)
            if a<0 then a = a + 256
            if a>=32 and a<127 then s = c else s = "&#" + itostr(a)
            r = r + s
        end for
    end if
    return r
End Function

Function str8859toutf8(obj as dynamic) As String
    r = ""
    if isnonemptystr(obj)
        l = len(obj)
        for i=1 to l
            c = mid(obj,i,1)
            a = asc(c)
            if a<0 then a = a + 256
            if a<160
                s = c
            else if a<192
                s = chr(194) + chr(a)
            else
                s = chr(195) + chr(a-64)
            end if
            r = r + s
        end for
    end if
    return r
End Function

'******************************************************
'itostr
'
'Convert int to string. This is necessary because
'the builtin Stri(x) prepends whitespace
'******************************************************
Function itostr(i As Integer) As String
    str = Stri(i)
    return strTrim(str)
End Function


'******************************************************
'Get remaining hours from a total seconds
'******************************************************
Function hoursLeft(seconds As Integer) As Integer
    hours% = seconds / 3600
    return hours%
End Function


'******************************************************
'Get remaining minutes from a total seconds
'******************************************************
Function minutesLeft(seconds As Integer) As Integer
    hours% = seconds / 3600
    mins% = seconds - (hours% * 3600)
    mins% = mins% / 60
    return mins%
End Function

'******************************************************
' Format seconds into duration like "1h 45m"
'******************************************************
Function FormatDuration(totalSeconds As Integer) As String
    hours = hoursLeft(totalSeconds)
    mins = minutesLeft(totalSeconds)
    timeStr = ""
    if hours>0 then timeStr = itostr(hours) + "h"
    if mins>0
        if hours>0 then timeStr = timeStr + " "
        if mins<10 then timeStr = timeStr + "0"
        timeStr = timeStr + itostr(mins) + "m"
    endif
    if hours=0 and mins=0 then timeStr = "0m" 
    return timeStr
End Function

'******************************************************
'Pluralize simple strings like "1 minute" or "2 minutes"
'******************************************************
Function Pluralize(val As Integer, str As String) As String
    ret = itostr(val) + " " + str
    if val <> 1 ret = ret + "s"
    return ret
End Function


'******************************************************
'Trim a string
'******************************************************
Function strTrim(str As String) As String
    st=CreateObject("roString")
    st.SetString(str)
    return st.Trim()
End Function


'******************************************************
'Tokenize a string. Return roList of strings
'******************************************************
Function strTokenize(str As String, delim As String) As Object
    st=CreateObject("roString")
    st.SetString(str)
    return st.Tokenize(delim)
End Function


'******************************************************
'Replace substrings in a string. Return new string
'******************************************************
Function strReplace(basestr As String, oldsub As String, newsub As String) As String
    newstr = ""

    i = 1
    while i <= Len(basestr)
        x = Instr(i, basestr, oldsub)
        if x = 0 then
            newstr = newstr + Mid(basestr, i)
            exit while
        endif

        if x > i then
            newstr = newstr + Mid(basestr, i, x-i)
            i = x
        endif

        newstr = newstr + newsub
        i = i + Len(oldsub)
    end while

    return newstr
End Function


'******************************************************
'Get all XML subelements by name
'
'return list of 0 or more elements
'******************************************************
Function GetXMLElementsByName(xml As Object, name As String) As Object
    list = CreateObject("roArray", 100, true)
    if islist(xml.GetBody()) = false return list

    for each e in xml.GetBody()
        if e.GetName() = name then
            list.Push(e)
        endif
    next

    return list
End Function


'******************************************************
'Get all XML subelement's string bodies by name
'
'return list of 0 or more strings
'******************************************************
Function GetXMLElementBodiesByName(xml As Object, name As String) As Object
    list = CreateObject("roArray", 100, true)
    if islist(xml.GetBody()) = false return list

    for each e in xml.GetBody()
        if e.GetName() = name then
            b = e.GetBody()
            if type(b) = "roString" or type(b) = "String" list.Push(b)
        endif
    next

    return list
End Function


'******************************************************
'Get first XML subelement by name
'
'return invalid if not found, else the element
'******************************************************
Function GetFirstXMLElementByName(xml As Object, name As String) As dynamic
    if islist(xml.GetBody()) = false return invalid

    for each e in xml.GetBody()
        if e.GetName() = name return e
    next

    return invalid
End Function


'******************************************************
'Get first XML subelement's string body by name
'
'return invalid if not found, else the subelement's body string
'******************************************************
Function GetFirstXMLElementBodyStringByName(xml As Object, name As String) As dynamic
    e = GetFirstXMLElementByName(xml, name)
    if e = invalid return invalid
    if type(e.GetBody()) <> "roString" and type(e.GetBody()) <> "String" return invalid
    return e.GetBody()
End Function


'******************************************************
'Get the xml element as an integer
'
'return invalid if body not a string, else the integer as converted by strtoi
'******************************************************
Function GetXMLBodyAsInteger(xml As Object) As dynamic
    if type(xml.GetBody()) <> "roString" and type(xml.GetBody()) <> "String" return invalid
    return strtoi(xml.GetBody())
End Function


'******************************************************
'Parse a string into a roXMLElement
'
'return invalid on error, else the xml object
'******************************************************
Function ParseXML(str As String) As dynamic
    if str = invalid return invalid
    xml=CreateObject("roXMLElement")
    if not xml.Parse(str) return invalid
    return xml
End Function


'******************************************************
'Get XML sub elements whose bodies are strings into an associative array.
'subelements that are themselves parents are skipped
'namespace :'s are replaced with _'s
'
'So an XML element like...
'
'<blah>
'    <This>abcdefg</This>
'    <Sucks>xyz</Sucks>
'    <sub>
'        <sub2>
'        ....
'        </sub2>
'    </sub>
'    <ns:doh>homer</ns:doh>
'</blah>
'
'returns an AA with:
'
'aa.This = "abcdefg"
'aa.Sucks = "xyz"
'aa.ns_doh = "homer"
'
'return an empty AA if nothing found
'******************************************************
Sub GetXMLintoAA(xml As Object, aa As Object)
    for each e in xml.GetBody()
        body = e.GetBody()
        if type(body) = "roString" or type(body) = "String" then
            name = e.GetName()
            name = strReplace(name, ":", "_")
            aa.AddReplace(name, body)
        endif
    next
End Sub


'******************************************************
'Walk an AA and print it
'******************************************************
Sub PrintAA(aa as Object)
    print "---- AA ----"
    if aa = invalid
        print "invalid"
        return
    else
        cnt = 0
        for each e in aa
            x = aa[e]
            PrintAny(0, e + ": ", aa[e])
            cnt = cnt + 1
        next
        if cnt = 0
            PrintAny(0, "Nothing from for each. Looks like :", aa)
        endif
    endif
    print "------------"
End Sub


'******************************************************
'Walk a list and print it
'******************************************************
Sub PrintList(list as Object)
    print "---- list ----"
    PrintAnyList(0, list)
    print "--------------"
End Sub

Sub tooDeep(depth As Integer) As Boolean
    hitLimit = (depth >= 10)
    if hitLimit then  print "**** TOO DEEP "; depth
    return hitLimit
End Sub

'******************************************************
'Print an associativearray
'******************************************************
Sub PrintAnyAA(depth As Integer, aa as Object)
    if tooDeep(depth) then return
    for each e in aa
        x = aa[e]
        PrintAny(depth, e + ": ", aa[e])
    next
End Sub


'******************************************************
'Print a list with indent depth
'******************************************************
Sub PrintAnyList(depth As Integer, list as Object)
    if tooDeep(depth) then return
    i = 0
    for each e in list
        PrintAny(depth, "List(" + itostr(i) + ")= ", e)
        i = i + 1
    next
End Sub


'******************************************************
'Print anything
'******************************************************
Sub PrintAny(depth As Integer, prefix As String, any As Dynamic)
    if tooDeep(depth) then return
    prefix = string(depth*2," ") + prefix
    depth = depth + 1
    str = AnyToString(any)
    if str <> invalid
        print prefix + str
        return
    endif
    if type(any) = "roAssociativeArray"
        print prefix + "(assocarr)..."
        PrintAnyAA(depth, any)
        return
    endif
    if (type(any) = "roByteArray")
        print prefix + "roByteArray: " ; any.Count() ; " bytes"
        return
    end if
    if islist(any) = true
        print prefix + "(list of " + itostr(any.Count()) + ")..."
        PrintAnyList(depth, any)
        return
    endif

    print prefix + "?" + type(any) + "?"
End Sub


'******************************************************
'Print an object as a string for debugging. If it is 
'very long print the first 500 chars.
'******************************************************
Sub Dbg(pre As Dynamic, o=invalid As Dynamic)
    p = AnyToString(pre)
    if p = invalid p = ""
    if o = invalid o = ""
    s = AnyToString(o)
    if s = invalid s = "???: " + type(o)
    if Len(s) > 4000
        s = Left(s, 4000)
    endif
    print p + s
End Sub


'******************************************************
'Try to convert anything to a string. Only works on simple items.
'
'Test with this script...
'
'    s$ = "yo1"
'    ss = "yo2"
'    i% = 111
'    ii = 222
'    f! = 333.333
'    ff = 444.444
'    d# = 555.555
'    dd = 555.555
'    bb = true
'
'    so = CreateObject("roString")
'    so.SetString("strobj")
'    io = CreateObject("roInt")
'    io.SetInt(666)
'    tm = CreateObject("roTimespan")
'
'    Dbg("", s$ ) 'call the Dbg() function which calls AnyToString()
'    Dbg("", ss )
'    Dbg("", "yo3")
'    Dbg("", i% )
'    Dbg("", ii )
'    Dbg("", 2222 )
'    Dbg("", f! )
'    Dbg("", ff )
'    Dbg("", 3333.3333 )
'    Dbg("", d# )
'    Dbg("", dd )
'    Dbg("", so )
'    Dbg("", io )
'    Dbg("", bb )
'    Dbg("", true )
'    Dbg("", tm )
'
'try to convert an object to a string. return invalid if can't
'******************************************************
Function AnyToString(any As Dynamic) As dynamic
    if any = invalid return "invalid"
    if isstr(any) return any
    if isint(any) return itostr(any)
    if isbool(any)
        if any = true return "true"
        return "false"
    endif
    if isfloat(any) then return Str(any)
    if type(any) = "roTimespan" then return itostr(any.TotalMilliseconds()) + "ms"
    if type(any) = "roDateTime" then return DateTimeToString(any)
    return invalid
End Function

Function DateTimeToString(o)
    s = ""
    s = s + ZeroPad(o.getMonth()        , 2) + "/"
    s = s + ZeroPad(o.getDayOfMonth()   , 2) + "/" 
    s = s + ZeroPad(o.getYear()         , 2) + " " 
    s = s + ZeroPad(o.getHours()        , 2) + ":" 
    s = s + ZeroPad(o.getMinutes()      , 2) + ":" 
    s = s + ZeroPad(o.getSeconds()      , 2) + "." 
    s = s + ZeroPad(o.getMilliseconds() , 3)
    return s
End Function

Function ZeroPad(i, width)
    ' This needs to be trimmed because str() on a number includes
    ' a leading space for a possible negative sign

    ' This little but may look a little strange. It's
    ' because  istr = str(i).Trim() leaks memory (or used to).
    s1 = CreateObject("roString")
    s1.SetString(str(i))
    istr = s1.Trim()
    
    istr_len = len(istr)
    if (istr_len >= width) then
        return istr
    end if

    return (string(width-istr_len,"0") + istr)
End Function

'******************************************************
'Walk an XML tree and print it
'******************************************************
Sub PrintXML(element As Object, depth=0 As Integer)
    print tab(depth*3);"Name: [" + element.GetName() + "]"
    if invalid <> element.GetAttributes() then
        print tab(depth*3);"Attributes: ";
        for each a in element.GetAttributes()
            print a;"=";left(element.GetAttributes()[a], 4000);
            if element.GetAttributes().IsNext() then print ", ";
        next
        print
    endif

    if element.GetBody()=invalid then
        ' print tab(depth*3);"No Body" 
    else if type(element.GetBody())="roString" or type(element.GetBody())="String" then
        print tab(depth*3);"Contains string: [" + left(element.GetBody(), 4000) + "]"
    else
        print tab(depth*3);"Contains list:"
        for each e in element.GetBody()
            PrintXML(e, depth+1)
        next
    endif
    print
end sub


'******************************************************
'Dump the bytes of a string
'******************************************************
Sub DumpString(str As String)
    print "DUMP STRING"
    print "---------------------------"
    print str
    print "---------------------------"
    l = Len(str)-1
    i = 0
    for i = 0 to l
        c = Mid(str, i)
        val = Asc(c)
        print itostr(val)
    next
    print "---------------------------"
End Sub


'******************************************************
'Validate parameter is the correct type
'******************************************************
Function validateParam(param As Object, paramType As String,functionName As String, allowInvalid = false) As Boolean
    if paramType = "roString" or paramType = "String" then
        if type(param) = "roString" or type(param) = "String" then
            return true
        end if
    else if type(param) = paramType then
        return true
    endif

    if allowInvalid = true then
        if type(param) = invalid then
            return true
        endif
    endif

    print "invalid parameter of type "; type(param); " for "; paramType; " in function "; functionName 
    return false
End Function

'******************************************************
'Aggressively strip out common HTML tags that Netflix embeds as text markup.
'
'Anything inside "<...>" is considered to be HTML markup.
'******************************************************
Function removeHTMLTags(input As String) As String
    newString = input

    while true
        startPos = Instr(1, newString, "<")
        if startPos = 0 exit while
        
        endPos = Instr(startPos, newString, ">")
        if endPos = 0 then    
            newString = Left(newString, startPos-1) 
        else
            newString = Left(newString, startPos-1) + Mid(newString, endPos+1)
        endif
    end while

    return newString
End Function

'******************************************************
'Extracts the contentID from a showID URL.
'
' For example,
'   http://api.netflix.com/catalog/titles/movies/1171468
' returns
'   1171468
'
' And 
'   http://api.netflix.com/catalog/titles/series/70057024/seasons/70120889
' returns
'   70120889
'******************************************************
Function contentIDFromShowID(showID as String) as Integer
    contentID = 0

    showIDTokens = strTokenize(showID, "/")
    numTokens    = showIDTokens.count()
    if (numTokens > 0)
         contentID = strtoi(showIDTokens[numTokens - 1])
    end if

    return contentID    
End Function

function verbose() as boolean
    return m.verbose
end function

sub setverbose(on as boolean)
    m.verbose = on
end sub

Function expBackoffWait() As Object
    msg = wait(m.interval*1000,m.port)
    nextInterval = (m.interval * 3 + 1) / 2
    if msg<>invalid then nextInterval = m.startInterval
    m.reset(nextInterval)
    return msg
End Function

Function expBackoffSet(startInterval=m.startInterval As Integer)
    m.interval = startInterval
    if m.interval>m.maxInterval then m.interval = m.maxInterval
End Function

Function expBackoffTimer(startInterval As Integer, maxInterval As Integer, port As Object) As Object
    ebt = CreateObject("roAssociativeArray")
    ebt.startInterval = startInterval
    ebt.maxInterval = maxInterval
    ebt.port = port
    ebt.wait = expBackoffWait
    ebt.reset = expBackoffSet
    ebt.reset()
    return ebt
End Function

'used to begin timestamp for selection event
sub markSelectedTime()
    if m.selecttimer = invalid
        m.selecttimer = createobject("rotimespan")
    endif
    m.selecttimer.mark()
end sub

function timeSinceSelected()
    return m.selecttimer.totalmilliseconds()
end function

Function nowSecs() As Integer
    now = m.globalClock
    if now=invalid
        now = CreateObject("roDateTime")
        m.globalClock = now
    end if
    now.mark()
    return now.asSeconds()
End Function

'***************************************************************
'@return A content ID that doesn't conflict with the *known* contentIDs.
'        This is unlikely to ever conflict with a real contentID since
'        the Netflix contentIDs are usually large positive numbers.
'***************************************************************
Function uniqueContentID() As Integer
    if not m.DoesExist("globalLastUniqueContentID")
        m.globalLastUniqueContentID = -100 'negative numbers are invalid NCCP contentIDs
    end if

    m.globalLastUniqueContentID  = m.globalLastUniqueContentID - 1

    nf = Netflix()
    while nf.getShow(m.globalLastUniqueContentID) <> invalid
        m.globalLastUniqueContentID  = m.globalLastUniqueContentID - 1
    end while

    return m.globalLastUniqueContentID
End Function

'***************************************************************
'@return True if the array contains the element.
'***************************************************************
Function containsElement(array as Object, element as Dynamic) as Boolean
    for i = 0 to array.count() - 1
        if array[i] = element then return true
    end for

    return false
End Function

'***************************************************************
' general integer parameter determination with default
'***************************************************************
Function getIntParam(name As String, defaultVal As Integer) As Integer
    if m[name] = invalid
        m[name] = defaultVal
    elseif not isint(m[name])
        m[name] = defaultVal
    elseif m[name] < 1
        m[name] = defaultVal
    endif
    return m[name]
End Function


'***************************************************************
' The refreshInterval is used to control how often we refresh
' potentially dynamic data
'***************************************************************
Function getRefreshInterval() As Integer
    return getIntParam("refreshInterval",300)
End Function


'***************************************************************
' The retryInterval is used to control how often we retry and
' check for registration success. its generally sent by the
' service and if this hasn't been done, we just return defaults 
'***************************************************************
Function getRetryInterval() As Integer
    return getIntParam("retryInterval",10)
End Function


'*********************************************************
' The retryTime is used to control how long we attempt to 
' retry. this value is generally obtained from the service
' if this hasn't yet been done, we just return the defaults 
'*********************************************************
Function getRetryTime() As Integer
    return getIntParam("retryTime",1800)
End Function

'
' log time since startup to brightscript console
'
Function timePrint(prefix As String, logOnceLabel=invalid As Dynamic)
    gt = m.globalTimer
    if gt=invalid
        gt = CreateObject("roTimespan")
        m.globalTimer = gt
        m.globalTimerBase = prefix
    end if
    tms = gt.totalMilliseconds()
    ts = int(tms/1000)
    rms = right("000"+itostr(tms - 1000 * ts),3)
    duration = itostr(ts) + "." + rms + "s"
    msg = prefix + " " + duration + " past " + m.globalTimerBase
    print msg
    if once(logOnceLabel) then appLog(logOnceLabel+","+duration)
End Function

Function appLog(msg as String)
    gp = m.globalPlugin
    if gp=invalid
        gp = CreateObject("roPlugin")
        m.globalPlugin = gp
    end if 
    gp.Log(msg)
    print msg
End Function

' returns true one time per script running per label
Function once(label As Dynamic) As Boolean
    if isnullorempty(label) then return false
    pre = m[label]
    doIt = pre <> true ' pre might be invalid
    if doIt then m[label] = true
    return doIt
End Function

'******************************************************
'Get our device version
'******************************************************
Function GetDeviceVersion()
    if m.softwareVersion = invalid OR m.softwareVersion = "" then
        m.softwareVersion = CreateObject("roDeviceInfo").GetVersion()
    end if
    return m.softwareVersion
End Function


'******************************************************
'Get device type (first 10 digits of serial number)
'******************************************************
Function GetDeviceType()
    if m.deviceType = invalid OR m.deviceType = "" then
        sn = GetDeviceESN()
        if sn <> invalid AND sn <> "" then
            m.deviceType = left(sn, 10)
        else
            m.deviceType = ""
        end if
    end if
    return m.deviceType
End Function


'******************************************************
'Get our serial number
'******************************************************
Function GetDeviceESN()
    if m.serialNumber = invalid OR m.serialNumber = "" then
        m.serialNumber = CreateObject("roDeviceInfo").GetDeviceUniqueId()
    end if
    return m.serialNumber
End Function
