' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************


sub scaleblit(screenFull as object, msgport as object, topx, topy, w, h, par)

        print "Scale Boing"
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

        scaley = ballsizey/tmpballbitmap.getheight()
        scalex = scaley*par

        ballbitmap = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:false})
        ballbitmap.drawscaledobject(0,0,scalex,scaley,tmpballbitmap)

        ballregion = createobject("roregion",ballbitmap,0,0,ballsizex,ballsizey)
        ballcenterX = int(ballsizex/2)
        ballcenterY = int(ballsizey/2)
        ballregion.setpretranslation(-ballcenterX, -ballcenterY)
        ballregion.setscalemode(0)
        
        ' construct ball shadow
        tmpballbitmap = createobject("robitmap","pkg:/images/BallShadow.png")
        ballshadow = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:false})
        ballshadow.drawscaledobject(0,0,ballsizex/tmpballbitmap.getwidth(),ballsizey/tmpballbitmap.getheight(),tmpballbitmap)
        
        shadowregion = createobject("roregion",ballshadow,0,0,ballsizex,ballsizey)
        shadowregion.setpretranslation(-ballcenterX, -ballcenterY)
        shadowregion.setscalemode(0)

        ' calculate starting position and motion dynamics
        x = w/10 + ballcenterX
        y = h/10 + ballcenterY
        
        doboth = 0

        dx = 2
        dy = 1
        ay = 1
        framecount = 0
        timestamp = createobject("rotimespan")
        swapbuff_timestamp = createobject("rotimespan")
        start = timestamp.totalmilliseconds()
        swapbuff_time = 0
        shadow_dx = int(ballsizex/4)
        shadow_dy = int(ballsizey/10)
        w_over_10 = w/10
        rightedge = int(ballcenterx + (w*9)/10)
        bottomedge = int(ballcentery + (h*9)/10)
        if doboth
            rightedge = rightedge - 2*ballsizex
        endif
        running = true
        codes = bslUniversalControlEventCodes()
        while true
                regiondrawgrid(screen, background)
                screen.SetAlphaEnable(true)
                scalex = x/rightedge
                scaley = y/bottomedge
                screen.drawscaledobject(x+shadow_dx,y+shadow_dy,scalex,scaley,shadowregion)

                screen.drawscaledobject(x,y,scalex,scaley,ballregion)
                screen.SetAlphaEnable(false)
                screen.drawrect(x-2,y-2,5,5,green)        ' show where the (x,y) is
                
                if doboth
                    screen.SetAlphaEnable(true)
                    x2 = x + ballsizex
                    shadowregion.setscalemode(0)
                    screen.drawscaledobject(x2+shadow_dx,y+shadow_dy,scalex,scaley,shadowregion)
                    shadowregion.setscalemode(1)

                    ballregion.setscalemode(0)
                    screen.drawscaledobject(x2,y,scalex,scaley,ballregion)
                    ballregion.setscalemode(1)
                    screen.SetAlphaEnable(false)
                    screen.drawrect(x2-2,y-2,5,5,green)        ' show where the (x,y) is
                endif
                swapbuff_timestamp.mark()
                screenFull.SwapBuffers()
                swapbuff_time = swapbuff_time + swapbuff_timestamp.totalmilliseconds()
                
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
                            if button=codes.BUTTON_BACK_PRESSED   
                                return
                            endif
                            print "button getint="; msg.getint()
                            if button = codes.BUTTON_PLAY_PRESSED   ' play/pause
                                if running
                                    running = false
                                else
                                    running = true
                                endif
                            endif
                        endif
                    endif
                end while
    if running
                x = x + dx
                y = y + dy
                dy = dy + ay
                if x<w_over_10
                        x = w_over_10+(w_over_10-x)
                        dx = -dx
                endif
                if y<0
                        y = -y
                        dy = -dy
                endif
                if x+ballsizex > rightedge
                        x = 2*rightedge - x - 2*ballsizex
                        dx = -dx
                endif
                if y+ballsizey > bottomedge
                        y = 2*y - y
                        dy = -dy + ay
                endif
    endif
                framecount = framecount + 1
                if framecount >= 100
                      deltatime = timestamp.totalmilliseconds() - start
                      print "frames per second = "; (framecount*1000)/deltatime;
                      print " average swapbuff time = "; swapbuff_time/framecount; " milliseconds"
                      swapbuff_time = 0
                      framecount = 0
                      timestamp.mark()
                endif
        end while
        print "Exiting APP"
End Sub
