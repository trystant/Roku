' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************

Library "v30/bslDefender.brs"

Function IsHD()
    di = CreateObject("roDeviceInfo")
    if di.GetDisplayType() = "HDTV" then return true
    return false
End Function

function GetSelection(selectionList, name1, name2) as integer
    port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText(name1, name2)
    screen.SetListStyle("arced-landscape")
    screen.setcontentlist(selectionList)
    screen.show()
    while true
        msg = wait(0, screen.getmessageport())
        if msg.isscreenclosed() then
            return -1
        endif
        if type(msg) = "roPosterScreenEvent" then
            if msg.islistitemselected() then
                return msg.GetIndex()
            endif
        endif
    end while
end function

function createScreenDescription(topx, topy, width ,height, screenwidth, screenheight, par)
    description1 = str(width)+"x"+str(height)
    description2 = "No Sidebars"
    if (topx)
        description2 = "sidebar=" + str(topx)
    endif
    if (topy)
        description2 = "letterbox=" + str(topy)
    endif
       
    return {    ShortDescriptionLine1: description1,
                ShortDescriptionLine2: description2,
                drawwidth: width,
                drawheight: height,
                screenwidth: screenwidth,
                screenheight: screenheight,
                par: par,
                drawtopx: topx,
                drawtopy: topy,
            }
end function

Sub Main()
    ' Show Poster screen of screen sizes for testing
  backstop = CreateObject("roParagraphScreen")
  backstop.show()
  while true

    screenlist = []
    if isHD() then
        screenList.push(createScreenDescription(0,0,1280,720,1280,720,1.0))
        screenList.push(createScreenDescription(0,0,854,480,854,480,1.0))
        screenList.push(createScreenDescription(107,0,640,480,854,480,1.0))
        screenList.push(createScreenDescription(110,0,720,480,940,480,1.1))
        screenList.push(createScreenDescription(320,120,640,480,1280,720,1.0))
    else
        screenList.push(createScreenDescription(0,0,720,480,720,480,1.1))
        screenList.push(createScreenDescription(0,0,640,480,640,480,1.0))
        screenList.push(createScreenDescription(0,73,854,480,854,626,1.0))
    endif

    selection =  GetSelection(screenList, "screensize", "select")
    if selection = -1
        print "got selection -1"
        return
    endif
    'print "got selection="; selection
    ShowDemo(screenList[selection])
    print "return from ShowDemo"
  end while
end Sub

Sub ShowDemo(screeninfo)

    topx = screeninfo.drawtopx
    topy = screeninfo.drawtopy
    screenwidth = screeninfo.screenwidth
    screenheight = screeninfo.screenheight
    width = screeninfo.drawwidth
    height = screeninfo.drawheight
    par = screeninfo.par

    screen=CreateObject("roScreen", true, screenwidth, screenheight)
    msgport=CreateObject("roMessagePort")

    if type(screen) <> "roScreen"
        print "Unable to open screen"
        return
    endif

    screen.SetPort(msgport)

    drawimage(screen, msgport, topx, topy, width, height, par)
    screenblit(screen, msgport, topx, topy, width, height, par)
    rectbounce(screen, msgport, topx, topy, width, height, par)
    rectboing(screen, msgport, topx, topy, width, height, par)
    textrect(screen, msgport, topx, topy, width, height, par)
    spritebouncedbl(screen, msgport, topx, topy, width, height, par)
    scaleblit(screen, msgport, topx, topy, width, height, par)
    rotateblit(screen, msgport, topx, topy, width, height, par)
    spritezbounce(screen, msgport, topx, topy, width, height, par)
    spritecollide(screen, msgport, topx, topy, width, height, par)
    spritecomplexcollide(screen, msgport, topx, topy, width, height, par)
    spriteanimcollide(screen, msgport, topx, topy, width, height, par)

end sub

Sub RunScreensaver()
    screeninfo = createScreenDescription(0,0,1280,720,1280,720,1.0)

    topx = screeninfo.drawtopx
    topy = screeninfo.drawtopy
    screenwidth = screeninfo.screenwidth
    screenheight = screeninfo.screenheight
    width = screeninfo.drawwidth
    height = screeninfo.drawheight
    par = screeninfo.par

    screen=CreateObject("roScreen", true, screenwidth, screenheight)
    msgport=CreateObject("roMessagePort")

    if type(screen) <> "roScreen"
        print "Unable to open screen"
        return
    endif

    screen.SetPort(msgport)

    'drawimage(screen, msgport, topx, topy, width, height, par)
    rectbounce(screen, msgport, topx, topy, width, height, par)
    'rectboing(screen, msgport, topx, topy, width, height, par)
    'textrect(screen, msgport, topx, topy, width, height, par)
    'spritebouncedbl(screen, msgport, topx, topy, width, height, par)
    'scaleblit(screen, msgport, topx, topy, width, height, par)
    'rotateblit(screen, msgport, topx, topy, width, height, par)
    'spritezbounce(screen, msgport, topx, topy, width, height, par)
    'spritecollide(screen, msgport, topx, topy, width, height, par)

    'screen = invalid
    'screenFacade = invalid


end sub
