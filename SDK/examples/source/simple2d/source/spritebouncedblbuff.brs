' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************

sub spritebouncedbl(screenFull as object, msgport as object, topx, topy, w, h, par)

    print "Sprite Bounce Double Buffer"
        drawing_regions = dfSetupDisplayRegions(screenFull, topx, topy, w, h)
        screen = drawing_regions.main    ' extract main drawing region

        red = 255*256*256*256
        green = 255*256*256+255
        blue = 255*256

        background = blue+255
        sidebarcolor = green

        ' intialize sidebars if any
        regionsetupbackground(drawing_regions, background, sidebarcolor)
        screenFull.SwapBuffers()
        regionsetupbackground(drawing_regions, background, sidebarcolor)

        ' create bitmap for use with doublebuffering
        dblbuffer = createobject("robitmap",{width:w,height:h,alphaenable:false})
        dblbuffer.clear(background)

        ' create a red sprite

        ballsize = h/5
        ballsizey = int(ballsize)
        ballsizex = int(ballsize*par)

        ballbitmap = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:false})
        ballbitmap.clear(red+255)

        region = createobject("roregion", ballbitmap, 0,0,ballsizex,ballsizey)

        compositor = createobject("rocompositor")
        compositor.SetDrawTo(dblbuffer, background)

        x = 0
        y = h/20
        sprite = compositor.newsprite(x,y,region)

        dx = 2
        dy = 1
        ay = 1
        oldx = x
        oldy = y
        framecount = 0
        codes = bslUniversalControlEventCodes()
        timestamp = createobject("rotimespan")
        start = timestamp.totalmilliseconds()
        while true
                sprite.moveto(x,y)
                compositor.draw()
                screen.drawobject(0,0,dblbuffer)
                screenFull.swapbuffers()
                oldx = x
                oldy = y
                x = x + dx
                y = y + dy
                dy = dy + ay
                if x<0
                        x = -x
                        dx = -dx
                endif
                if y<0
                        y = -y
                        dy = -dy
                endif
                if x+ballsizex > w
                        x = 2*w - x - 2*ballsizex
                        dx = -dx
                endif
                if y+ballsizey > h
                        y = 2*y - y
                        dy = -dy + ay
                endif

                ' check for input
                pullingmsgs = true
                while pullingmsgs
                    msg = msgport.getmessage()
                    if msg = invalid
                        pullingmsgs = false
                    else
                        if type(msg) = "roUniversalControlEvent"
                            button = msg.getint()
                            print "button=";button
                            if button=codes.BUTTON_BACK_PRESSED   
                                return
                            endif
                        endif
                    endif
                end while
                
                framecount = framecount + 1
                if framecount >= 100
                      deltatime = timestamp.totalmilliseconds() - start
                      print "frames per second = "; (framecount*1000)/deltatime
                      framecount = 0
                      timestamp.mark()
                endif
        end while
End Sub
