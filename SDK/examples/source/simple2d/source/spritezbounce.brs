' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************

sub spritezbounce(screenFull as object, msgport as object, topx, topy, w, h, par)

    print "Sprite Z Bounce"
        drawing_regions = dfSetupDisplayRegions(screenFull, topx, topy, w, h)
        screen = drawing_regions.main    ' extra main drawing region 

        red = 255*256*256*256
        green = 255*256*256+255
        blue = 255*256

        background = blue+255
        sidebarcolor = green

        regionsetupbackground(drawing_regions, background, sidebarcolor)
        screenFull.swapbuffers()
        regionsetupbackground(drawing_regions, background, sidebarcolor)

        ' create bitmap for use with doublebuffering
        dblbuffer = createobject("robitmap",{width:w,height:h,alphaenable:false})
        dblbuffer.clear(background)

        ' create a red sprite

        ballsize = h/5
        ballsizey = int(ballsize)
        ballsizex = int(ballsize*par)

        compositor = createobject("rocompositor")
        compositor.SetDrawTo(dblbuffer, background)

        x = 0
        y = h/20

        for i = 0 to 15
            ballbitmap = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:false})
            ballbitmap.clear((i*10*256*256)+255)
            region = createobject("roregion", ballbitmap, 0,0,ballsizex,ballsizey)
            sprite = compositor.newsprite(i*20, i*10, region, i*10)
        next i
        
        ballbitmap = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:false})
        ballbitmap.clear(red+255)
        region = createobject("roregion", ballbitmap, 0,0,ballsizex,ballsizey)
        z = 100
        sprite = compositor.newsprite(x,y,region, z)


        framecount = 0
        timestamp = createobject("rotimespan")
        start = timestamp.totalmilliseconds()
        button = 0  ' no button pressed

        codes = bslUniversalControlEventCodes()

        while true
                sprite.moveto(x,y)
                compositor.draw()
                screen.drawobject(0,0,dblbuffer)
                screenFull.swapbuffers()

                ' check for input
                pullingmsgs = true
                while pullingmsgs
                    msg = msgport.getmessage()
                    if msg = invalid
                        pullingmsgs = false
                    else
                        'print "Got Msg "; type(msg)
                        if type(msg) = "roUniversalControlEvent"
                            button = msg.getint()
                            print "button=";button
                            if button=codes.BUTTON_BACK_PRESSED   
                                return
                            endif
                        endif
                    endif
                end while
                if button=codes.BUTTON_UP_PRESSED 
                    y = y - 2
                else if button = codes.BUTTON_DOWN_PRESSED
                    y = y + 2
                else if button = codes.BUTTON_RIGHT_PRESSED
                    x = x + 2
                else if button = codes.BUTTON_LEFT_PRESSED
                    x = x - 2
                else if button = codes.BUTTON_REWIND_PRESSED
                    z = z - 2
                    sprite.setz(z)
                    print "z=";z
                else if button = codes.BUTTON_FAST_FORWARD_PRESSED ' fwd
                    z = z + 2
                    sprite.setz(z)
                    print "z=";z
                endif
                
                framecount = framecount + 1
                if framecount >= 100
                      deltatime = timestamp.totalmilliseconds() - start
                      print "frames per second = "; (framecount*1000)/deltatime
                      framecount = 0
                      timestamp.mark()
                endif
        end while
End Sub
