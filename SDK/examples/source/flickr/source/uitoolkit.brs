' *********************************************************
' *********************************************************
' **
' **  Roku DVP User Interface Helper Functions 
' **
' **  A. Wood, November 2009
' **
' **  Copyright (c) 2009 Anthony Wood. All Rights Reserved.
' **
' *********************************************************
' *********************************************************




'  uitkDoPosterMenu
'
'    Display "menu" items in a Poster Screen.   
'
'    if "onselect_callback" is valid, it is an Array.
'	 there are two options on the format of data in callback array
'	 entry 0 is an "array format type" integer
'    if type is 0
'		entry 1 is a this pointer.
'       entry 2...n are text names of functions to callback on the this pointer
'       like this: this[onselect_callback[msg.Index+2]]()
'    if type is 1
'		entry 1 & 2 are userdata
'       entry 3 is the callback function reference.  
'		like this: 	f(userdata1, userdata2, msg.Index)
'
'	 in each type:
'		returns when UP or HOME selected

'    else if onselect_callback is not valid
'		returns when UP or HOME or Menu Item selected
'		returns Integer of Menu Item index, or negative if home or up selected
'
' pass in "posterdata", an array of AAs with these entries:
'   HDPosterUrl As String - URI to HD Icon Image
'   SDPosterUrl As String - URI to SD Icon Image
'   ShortDescriptionLine1 As String - the text name of the menu item
'	ShortDescriptionLine1 As String - more text
'   
'  ******************************************************

function uitkPreShowPosterMenu(breadA=invalid, breadB=invalid) As Object
	port=CreateObject("roMessagePort")
	screen = CreateObject("roPosterScreen")
	screen.SetMessagePort(port)
	if breadA<>invalid and breadB<>invalid then
		screen.SetBreadcrumbText(breadA, breadB)
	end if
	screen.SetListStyle("flat-category")
	screen.SetListDisplayMode("best-fit")
	screen.Show()

	return screen
end function


function uitkDoPosterMenu(posterdata, screen, onselect_callback=invalid) As Integer

	if type(screen)<>"roPosterScreen" then
		print "illegal type/value for screen passed to uitkDoPosterMenu()" 
		return -1
	end if
	
	screen.SetContentList(posterdata)

    while true
        msg = wait(0, screen.GetMessagePort())
		
		'print "uitkDoPosterMenu | msg type = ";type(msg)
		
		if type(msg) = "roPosterScreenEvent" then
			' print "event.GetType()=";msg.GetType(); " Event.GetMessage()= "; msg.GetMessage()
			if msg.isListItemSelected() then
				if onselect_callback<>invalid then
					selecttype = onselect_callback[0]
					if selecttype=0 then
						this = onselect_callback[1]
						this[onselect_callback[msg.GetIndex()+2]]()
					else if selecttype=1 then
						userdata1=onselect_callback[1]
						userdata2=onselect_callback[2]
						f=onselect_callback[3]
						f(userdata1, userdata2, msg.GetIndex())
					end if
				else
					return msg.GetIndex()
				end if
			else if msg.isScreenClosed() then
				return -1
			end if
		end If
	end while
end function

