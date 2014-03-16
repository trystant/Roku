' *********************************************************
' **  Roku Paragraph Demonstration App
' **  Support routines
' **  Feb 2010
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************

'***************************************************
'** Set up the screen in advance before its shown
'** Do any pre-display setup work here
'***************************************************
Function preShowHomeScreen(breadA=invalid, breadB=invalid) As Object
    port=CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    return screen
End Function

'********************************************************************
'** selecting close exits the application
'********************************************************************
Function showHomeScreen(screen) As Integer

	' borrow some pictures from the monitor setup program
    	host = "http://rokudev.roku.com/rokudev/testpatterns/"

	screen.SetTitle("Title Text")
    	screen.AddHeaderText("Header Text")
        screen.AddParagraph("Paragraph Text")

    	adUrl = host + "1280x720" + "/SMPTE_bars_setup_labels_lg.jpg"
	print "adUrl=" + adUrl
	screen.AddGraphic(adURL,"scale-to-fit")

	screen.AddButton(1,"Close")
	screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

	print "got message"

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while                
            else if msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            endif
        endif
    end while

End Function
