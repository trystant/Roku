'**********************************************************
'**  twitter OAuth example
'**  May 2010
'**  Copyright (c) 2010 Roku Inc. All Rights Reserved.
'**********************************************************

' ********************************************************************
' **  Sample OAuth Application
' **  May 2010
' ********************************************************************

Sub Main()
    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    'display a fake screen while the real one initializes. this screen
    'has to live for the duration of the whole app to prevent flashing
    'back to the roku home screen.
    screenFacade = CreateObject("roImageCanvas")
    screenFacade.show()

    
    ' Initialize once: use global m scope as singleton pattern for oa and twitter
    ' Your credentials will look similar to the example (not valid) credentials in the comment below:
    ' m.oa = InitOauth("RokuOauthTestApp", "9gMsTs9ikcaiPW7NTH5aw", "2bzbzWGJIq82WOay8xvnT3R0aGwGx4a4YtgzREka4", "1.0")
    ' You can create a twitter developer account and register your app to get the consumerkey and consumersecret
    m.oa = InitOauth("YouTestAppName", "YourOAuthConsumerKey", "YouOAuthConsumerSecret", "1.0")
    m.twitter = InitTwitter()

    oa = Oauth()
    twitter = Twitter()
    
    if doRegistration() <> 0 then
        reason = "unknown"
        if not oa.linked() then reason = "unlinked"
        print "Main: exit due to error in registration, reason: "; reason
        'exit the app gently so that the screen doesn't flash to black
        sleep(25)
        return
    end if

    twitter.ShowTweetCanvas()
    
    screenFacade.show()
    sleep(25)
End Sub

'*************************************************************
'** Set the configurable theme attributes for the application
'** 
'** Configure the custom overhang and Logo attributes
'*************************************************************

Sub initTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangPrimaryLogoOffsetSD_X = "72"
    theme.OverhangPrimaryLogoOffsetSD_Y = "15"
    theme.OverhangSliceSD = "pkg:/images/Overhang_BackgroundSlice_SD43.png"
    theme.OverhangPrimaryLogoSD  = "pkg:/images/Logo_Overhang_SD43.png"

    theme.OverhangPrimaryLogoOffsetHD_X = "123"
    theme.OverhangPrimaryLogoOffsetHD_Y = "20"
    theme.OverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_HD.png"
    theme.OverhangPrimaryLogoHD  = "pkg:/images/Logo_Overhang_HD.png"

    theme.SpringboardSynopsisText = "#0000FF"

    app.SetTheme(theme)

End Sub


'*************************************************************
'** showImageCanvas()
'*************************************************************
Sub showImageCanvas(canvasItems As Object)

    print "showImageCanvas"
    
    canvas = CreateObject("roImageCanvas")
    port = CreateObject("roMessagePort")
    canvas.SetMessagePort(port)
    canvas.SetBackgroundColor("#FF000000")  'Set opaque background

    canvas.SetRequireAllImagesToDraw(true)
    canvas.SetContentList(canvasItems)
    canvas.Show()                               

    while(true)
        msg = wait(5000,port) 
        if type(msg) = "roImageCanvasEvent" then
            if (msg.isRemoteKeyPressed()) then
                i = msg.GetIndex()
                print "Key Pressed - " ; msg.GetIndex()
                if (i = 2) then
                    ' Up - Close the screen.
                    canvas.close()
                end if
            else if (msg.isScreenClosed()) then
                print "Closed"
                return
            end if
        end if
    end while

End Sub 

Function LoadingCanvasContentList()
    roku = CreateObject("roDeviceInfo")
    res = roku.GetDisplayType()
        
    textAttrs  = {Color:"#FFCCCCCC", Font:"Large"  , HAlign:"HCenter", VAlign:"VCenter",Direction:"LeftToRight"}

    if res = "HDTV" then
        loading        = {Text:"loading..."       , TextAttrs:textAttrs,   TargetRect:{x:0,y:0,w:1280,h:720}}
    else if res = "4:3 standard" OR res = "16:9 anamorphic"
        loading        = {Text:"loading..."       , TextAttrs:textAttrs,   TargetRect:{x:0,y:0,w:720,h:480}}
    end if  

    contentList =      [loading]
    return contentList
End Function
