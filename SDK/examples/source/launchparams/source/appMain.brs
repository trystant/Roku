'********************************************************************
'**  Launch Params - Main
'**  March 2011
'**  Copyright (c) 2011 Roku Inc. All Rights Reserved.
'********************************************************************

'********************************************************************
'**  Example usage with External Control:
'**      echo -e 'POST /launch/dev?contentID=my_content_id&options=my_options HTTP/1.1\r\n' \
'**               | ncat <Roku DVP IP address> 8060
'**
'**  If your channel is launched via a clickable ad banner, the URL
'**  parameters will be passed to your app in the same way (through the
'**  params passed to RunUserInterface()).
'**
'**  The params.contentID parameter may be used in the future as a generic
'**  way of telling an app to show specific content.  The specification
'**  and handling of that parameter is completely up to the app. The
'**  only constant would be the name and the fact that it's a string.
'**
'**  If a user launches your app from the home screen directly, then
'**  params.contentID will be invalid.
'**
'********************************************************************

Sub RunUserInterface(params As Object)
    if params.contentID <> invalid
        contentID = params.contentID
    else
        contentID = ""
    end if

    if params.options <> invalid
        options = params.options
    else
        options = ""
    end if

    showScreen(contentID, options)
End Sub

Sub showScreen(contentID As String, options As String)
    screen = CreateObject("roParagraphScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    screen.addParagraph("contentID = " + contentID)
    screen.addParagraph("options = " + options)

    screen.Show()

    while true
        msg = wait(0, port)
        if msg <> invalid
            exit while
        end if
    end while
End Sub
