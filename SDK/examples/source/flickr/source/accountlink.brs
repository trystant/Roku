' *********************************************************
' *********************************************************
' **
' **  Account Link/Auth Wizard for Flickr
' **
' **  A. Wood, November 2009
' **
' **  Copyright (c) 2009 Anthony Wood. All Rights Reserved.
' **
' *********************************************************
' *********************************************************


'  ::DoFlickrAccountLink
'
'  true on success or already linked
'  false if link didn't happen

Function DoFlickrAccountLink(flickr) As Boolean
print "in DoFlickrAccountLink"
    if flickr.IsLinked()				then print "IsLinked is true":return true
    if not ShowGetYourCode(flickr)		then print "ShowGetYourCode failed":return false
    if not ShowEnterCode(flickr)       then print "ShowEnterCode failed":return false
    if not ShowLinkResult(flickr)      then print "ShowLinkResult failed":return false
    
    return true
End Function

Function ShowGetYourCode(flickr) As Boolean
print "ENTER ShowGetYourCode"
    screen = CreateObject("roParagraphScreen")
    if screen=invalid then print "Unexpected failure in creating roParagraphScreen":stop
    mp = CreateObject("roMessagePort")
    if mp=invalid then print "roMessagePort Create Failed":stop
    screen.SetMessagePort(mp)
    screen.AddHeaderText("Flickr Account Link")
    screen.AddParagraph("To used this Flickr feature and view your photos, you need to link your Roku player to your Flickr account.")
    screen.AddParagraph("Go to www.flickr.com/auth-" + flickr.auth_num + " and retrieve the 9 digit code")
    screen.AddButton(0, "Next")
    screen.AddButton(1, "Cancel")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())
        
		print "ShowGetYourCode: type of msg: ";type(msg)

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                return false             
            else if msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                if msg.GetIndex() = 0 then return true    ' next
                if msg.GetIndex() = 1 then return false   ' cancel
            endif
        endif
    end while
End Function


Function ShowEnterCode(flickr) As Boolean
	print "ENTER ShowEnterCode"
    screen = CreateObject("roPinEntryDialog")
    if screen=invalid then print "Unexpected failure in creating roPinEntryDialog":stop
    mp = CreateObject("roMessagePort")
    if mp=invalid then print "roMessagePort Create Failed":stop
    screen.SetMessagePort(mp)
    screen.SetNumPinEntryFields(9)
    screen.SetTitle("Enter The Flickr Link Code")
    screen.AddButton(0, "Next")
    screen.AddButton(1, "Cancel")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

		print "ShowEnterCode: type of msg: ";type(msg)

        if type(msg) = "roPinEntryDialogEvent"
            print "ShowEnterCode: Index: ";msg.GetIndex();" Data: ";msg.GetData()
            if msg.isScreenClosed()
                return false              
            else if msg.isButtonPressed()
				flickr.minitoken=screen.Pin()
				print "mini_token: ";flickr.minitoken
                if msg.GetIndex() = 0 then return true   ' Okay
                if msg.GetIndex() = 1 then return false  ' Cancel
            endif
        endif
    end while
End Function


Function ShowLinkResult(flickr)
	print "ENTER ShowLinkResult"
    screen = CreateObject("roParagraphScreen")
    if screen=invalid then print "Unexpected failure in creating roParagraphScreen":stop
    mp = CreateObject("roMessagePort")
    if mp=invalid then print "roMessagePort Create Failed":stop
    screen.SetMessagePort(mp)
    
	if flickr.LinkAccount(flickr.minitoken) then
		suc=true
	    screen.AddHeaderText("Success!")
	    screen.AddParagraph("Your Flickr account has been sucessfuly linked with your Roku player.")
	else
		suc=false
	    screen.AddHeaderText("Error Linking Account")
	    screen.AddParagraph("Please try again.")
	end if
    screen.AddButton(0, "Done")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())
        
		print "ShowLinkResult: type of msg: ";type(msg)

        if type(msg) = "roParagraphScreenEvent"
            print "ShowLinkResult: Index: ";msg.GetIndex();" Data: ";msg.GetData()
            if msg.isScreenClosed()
                return false              
            else if msg.isButtonPressed()
				return suc
            endif
        endif
    end while
End Function

