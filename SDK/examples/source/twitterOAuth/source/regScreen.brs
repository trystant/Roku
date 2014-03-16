'**********************************************************
'**  twitter OAuth example
'**  May 2010
'**  Copyright (c) 2010 Roku Inc. All Rights Reserved.
'**********************************************************


'******************************************************
'Perform the registration flow
'
'Steps:
'    1 - Get Twitter reg code
'    2 - Send user to Twitter web page to link Roku
'    3 - Retrieve Twitter temporary token and temporary secret
'    4 - Enroll user in oauth/LOLOMO using NCCP 2.4 Web API enroll
'    5 - Retrieve Twitter permanent token, user id and permanent secret
'Returns:
'    0 - We're registered. Proceed
'    1 - We're not registered. The user canceled the process.
'    2 - We're not registered. There was an error
'******************************************************
Function doRegistration() As Integer

    screenFacade = CreateObject("roParagraphScreen")
    screenFacade.show()

    oa = Oauth()

    if not oa.linked()
        status = doOauthLink()
        if status<>0 then return status
    end if

    return 0   

End Function

Function doOauthLink() As Integer
    status = doTempLink()
    if status=0
        ' busyDlg = ShowBusy("enrolling your Twitter account",Dispatcher().port) ' optional
        status = doTwitterEnroll()
        if status=0 then status = doLink()
    end if

    return status
End Function

Function doTempLink() As Integer
    print "RegScreen: doTempLink"
    status = 2

    twitter = Twitter()
    oa = Oauth()

    http = NewHttp(m.twitter.prefix+"oauth/request_token")
    oa.sign(http,false)
    rsp = http.getToStringWithTimeout(10)

    print "RegScreen: http failure = "; http.Http.GetFailureReason()
    print "RegScreen: temporary registration response = "; rsp

    'temporary token
    params = NewUrlParams(rsp)
    oa.authtoken = params.get("oauth_token")
    oa.authsecret = params.get("oauth_token_secret")

    if isnonemptystr(oa.authtoken) AND isnonemptystr(oa.authsecret) 
        print "temp oauth: "; oa.dump()
        status = 0
    else
        print "RegScreen: failed to retrieve temporary token"
        print "temp oauth: "; oa.dump()
        status = 2
    end if

    return status
End Function

Function doTwitterEnroll() As Integer
    print "RegScreen: doTwitterEnroll"
    status = 1 ' error

    twitter = Twitter()
    oa = Oauth()

    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)

    screen.AddHeaderText("Authorize Your Twitter Account")

    screen.AddParagraph("From your computer, go to")

    ' You probably want to setup a tinyurl service on your site to reduce the burden
    ' your users are carrying of typing a long urls...
    screen.AddParagraph("http://api.twitter.com/oauth/authorize?oauth_token=")
    screen.AddParagraph(oa.authtoken)
    screen.AddParagraph("and authorize this application.")

    screen.AddParagraph("Then come back to this screen and select the 'next' button below.")
    
    screen.AddButton(0, "next")
    screen.AddButton(1, "back")
    screen.Show()
    
    while true
        msg = wait(0, port)
        if type(msg) = "roParagraphScreenEvent" then
            if msg.isScreenClosed() then
                print "Screen closed"
                status = 2
                exit while                
            else if msg.isButtonPressed() then
                button = msg.GetIndex()
                if button = 0 then
                    status = 0
                    exit while
                else if button = 1 then
                    status = 2
                    exit while
                else 
                    print "Unknown button "; button
                    exit while                
                endif
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        endif
    end while

    print "RegScreen: enroll status: "; status
    return status
End Function

Function doLink() As Integer
    print "RegScreen: doLink"
    status = 2

    twitter = Twitter()
    oa = Oauth()


    port = CreateObject("roMessagePort")
    pin = CreateObject("roPinEntryDialog")
    pin.SetMessagePort(port)

    pin.SetTitle("Enter PIN received from Twitter on PC")
    pin.AddButton(0, "OK")
    pin.AddButton(1, "Cancel")
    pin.setNumPinEntryFields(7)
    pin.Show()

    buttonPressed = 5
    screenClosed  = 1
    pinCode = invalid
    complete = 0
    cancel = 1

    while true
        msg = wait(0, pin.GetMessagePort())
        print "I'm Waiting"

        if type(msg) = "roPinEntryDialogEvent" then
             if msg.isScreenClosed()
                 print "Screen closed"
                 return status
             else if msg.isButtonPressed()
                 buttonID = msg.GetIndex()
                 print "buttonID pressed: "; buttonID
                 if (buttonID = complete)
                     pinCode = pin.Pin()
                     print "Got pin: " + pinCode
                     exit while
                 else if (buttonID = cancel)
                     print "Cancel Pressed"
                     return status
                 endif
             else 
                 print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
             endif
        else
              print "Unexpected message class: "; type(msg)
        endIf   
    end while
    
    http = NewHttp(m.twitter.prefix+"oauth/access_token/")
    http.AddParam("application_name",oa.appname)
    oa.verifier = pinCode
    oa.sign(http,true,true)
    print "RegScreen: access_token URL: "; http.GetUrl()

    rsp = http.getToStringWithTimeout(10)
    print "RegScreen: final registration response = "; rsp

    params = NewUrlParams(rsp)
    oa.authtoken = params.get("oauth_token")
    oa.authsecret = params.get("oauth_token_secret")
    oa.userid = params.get("user_id")
    oa.resetHmac()

    if oa.linked() then
        oa.save()
        print "RegScreen: final oauth: "; oa.dump()
        status = 0
    else
        print "RegScreen: failed to retrieve final authorization token"
    end if

    return status

End Function


'******************************************************
'Load/Save a set of parameters to registry
'These functions must be called from an AA that has
'a "section" string and an "items" list of strings.
'******************************************************
Function loadReg() As Boolean
    for each item in m.items
        temp =  RegRead(item, m.section)
        if temp = invalid then temp = ""
        m[item] = temp
    end for
    return definedReg()
End Function

Function saveReg()
    for each item in m.items
        RegWrite(item, m[item], m.section)
    end for
End Function

Function eraseReg()
    for each item in m.items
        RegDelete(item, m.section)
        m[item] = ""
    end for
End Function

Function definedReg() As Boolean
    for each item in m.items
        if not m.DoesExist(item) then return false
        if Len(m[item])=0 then return false
    end for
    return true
End Function

Function dumpReg() As String
    result = ""
    for each item in m.items
        if m.DoesExist(item) then result = result + " " +item+"="+m[item]
    end for
    return result
End Function

