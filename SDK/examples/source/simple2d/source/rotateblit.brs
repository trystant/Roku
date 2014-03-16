' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************


sub rotateblit(screenFull as object, msgport as object, topx, topy, w, h, par)

        print "Rotate and Scale Test"
        drawing_regions = dfSetupDisplayRegions(screenFull, topx, topy, w, h)
        screen = drawing_regions.main    ' extract main drawing region 

        red = 255*256*256*256+255
        green = 255*256*256+255
        blue = 255*256+255
        
        clr = int(255*.55)
        background = &h8c8c8c8cff
        sidebarcolor = green

        ' intialize sidebars if any
        regionsetupbackground(drawing_regions, background, sidebarcolor)
        regiondrawgrid(screen, background)
        screenFull.SwapBuffers()
        regionsetupbackground(drawing_regions, background, sidebarcolor)      

        ' create a red sprite

        ballsize = h/4
        ballsizey = int(ballsize)
        ballsizex = int(ballsize*par)

        usebird = false
        if usebird
            tmpballbitmap = createobject("robitmap","pkg:/images/bluebird.jpg")
        else
            tmpballbitmap = createobject("robitmap","pkg:/images/AmigaBoingBall.png")
        endif

        ' draw a cross showing which way is up
        imgW = tmpballbitmap.getwidth()
        imgH = tmpballbitmap.getheight()
        tmpballbitmap.drawrect(int(imgW/2)-3,0,7,int(imgH*4/5),255)
        tmpballbitmap.drawrect(int(imgW/5),int(imgH/5)-3,int(imgW*3/5),7,255)
        xscale = ballsizey*par/imgH
        ballsizex = int(imgH*xscale)
        
        ballbitmap = createobject("robitmap",{width:ballsizex, height:ballsizey, alphaenable:true})

        ballbitmap.drawscaledobject(0,0,xscale,ballsizey/imgH, tmpballbitmap)
        
        ballregion = createobject("roregion", ballbitmap, 0,0,ballsizex,ballsizey)
        'ballregion = createobject("roregion", ballbitmap, ballsizex/2,ballsizey/2,ballsizex/2,ballsizey/2)
        ballregion.setpretranslation(int(-ballsizex/2),int(-ballsizey/2))
        ballregion.setscalemode(1)         ' smooth scale

        x = w/2
        y = h/2        
        theta = 0
        button = 0
        
        scalex = 1.0
        scaley = 1.0
        smoothscale = true
        codes = bslUniversalControlEventCodes()

        screen.SetAlphaEnable(false)
        regiondrawgrid(screen, background)
        screen.SetAlphaEnable(true)
        screen.drawobject(x,y,ballregion)
        screen.drawrect(x-2,y-2,5,5,green)        ' show where the (x,y) is
        screenFull.SwapBuffers()
        
        rotatecount = 1                             ' set rotatecount to 100 for benchmarking performance

        delta =  0
        rottime = createobject("rotimespan")
        while true
            if button>0 and button <= 99
                screen.SetAlphaEnable(false)
                regiondrawgrid(screen, background)
                screen.SetAlphaEnable(true)
                if button = codes.BUTTON_FAST_FORWARD_PRESSED or button = codes.BUTTON_REWIND_PRESSED
                    screen.finish()
                    rottime.mark()
                    for i = 0 to rotatecount
                        screen.drawrotatedobject(x,y,theta,ballregion)
                    next i
                    screen.finish()
                    delta = rottime.totalmilliseconds()
                    if rotatecount > 1
                        print "theta=";theta;" degrees"; " milliseconds=";delta
                    endif
                    scalex = 1.0
                    scaley = 1.0
                else if button = codes.BUTTON_UP_PRESSED
                        scaley = scaley + .1
                                            screen.drawscaledobject(x,y,scalex,scaley,ballregion)
                else if button = codes.BUTTON_DOWN_PRESSED
                        scaley = scaley - .1
                        if scaley < .1
                            scaley = .1
                        endif
                                            screen.drawscaledobject(x,y,scalex,scaley,ballregion)
                else if button = codes.BUTTON_RIGHT_PRESSED ' right
                        scalex = scalex + .1
                                            screen.drawscaledobject(x,y,scalex,scaley,ballregion)
                else if button = codes.BUTTON_LEFT_PRESSED
                        scalex = scalex - .1
                        if scalex < .1
                            scalex = .1
                        endif
                                            screen.drawscaledobject(x,y,scalex,scaley,ballregion)
                else if button = codes.BUTTON_PLAY_PRESSED ' play/pause
                    if smoothscale
                        smoothscale = false
                        scaledballwidth = int(ballsizex * scalex)
                        scaledballheight = int(ballsizey * scaley)
                        ballregion.setscalemode(0)
                    else
                        smoothscale = true
                        ballregion.setscalemode(1)
                    endif
                    print "scalemode=";smoothscale
                    screen.drawscaledobject(x,y,scalex,scaley,ballregion)
                    button = 0 ' debounce
                endif
                   
                screen.drawrect(x-2,y-2,5,5,green)        ' show where the (x,y) is

                screenFull.SwapBuffers()
            endif
                
                ' check for input
                pullingmsgs = true
                while pullingmsgs
                    msg = msgport.getmessage()
                    if msg = invalid
                        pullingmsgs = false
                    else
                        print "Got Msg "; type(msg)
                        if type(msg) = "roUniversalControlEvent"
                            button = msg.getint()
                            print "button=";button
                            if button = codes.BUTTON_BACK_PRESSED ' back
                                return
                            else if button = codes.BUTTON_REWIND_PRESSED ' rew
                                theta = theta - 90
                                if theta < 0
                                    theta = 360 + theta
                                endif
                            else if button = codes.BUTTON_FAST_FORWARD_PRESSED ' fwd
                                theta = theta + 90
                                if theta >= 360
                                    theta = theta - 360
                                endif
                            endif
                            pullingmsgs = false
                        endif
                    endif
                end while
        end while
        print "Exiting APP"
End Sub
