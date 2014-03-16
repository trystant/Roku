' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************

' Initialize drawing surface and any letterbox areas if they exist
sub regionsetupbackground(dRegions, backgroundcolor, sidebarcolor)
    dRegions.main.clear(backgroundcolor)
    if dRegions.left <> invalid
        dRegions.left.clear(sidebarcolor)
    endif
    if dRegions.right <> invalid
        dRegions.right.clear(sidebarcolor)
    endif
    if dRegions.upper <> invalid
        dRegions.upper.clear(sidebarcolor)
    endif    
    if dRegions.lower <> invalid
        dRegions.lower.clear(sidebarcolor)
    endif                                                         ' draw everything
end sub

sub rectbounce(screenFull as object, msgport as object, topx, topy, w, h, par)

    print "demonstrate moving ball using double buffering"
    
    drawing_regions = dfSetupDisplayRegions(screenFull, topx, topy, w, h)
    screen = drawing_regions.main    ' extract main drawing region 
        
        red=  &hFF0000FF    'RGBA
        green=&h00FF00FF	'RGBA
        blue= &h0000FFFF	'RGBA

        ballsize = h/5
        ' compute ball dimensions using pixel aspect ratio
        ballsizey = int(ballsize)
        ballsizex = int(ballsize*par)
        background=blue
        sidebarcolor=green
        
        ballcolor = red
        print "clear first screen to background"
        regionsetupbackground(drawing_regions, background, sidebarcolor)
        screenFull.SwapBuffers()
        regionsetupbackground(drawing_regions, background, sidebarcolor)

        ' starting position and motion dynamics
        x = 0
        dx = 4
        y = h/20
        ay = 1
        ax = 0
        dy = 1
        oldx = x
        oldy = y
        preoldx = oldx
        preoldy = oldy
        flipoldy = y
        framecount = 0
        codes = bslUniversalControlEventCodes()
        timestamp = createobject("rotimespan")
        start = timestamp.totalmilliseconds()
        while true
                screen.drawrect(oldx,oldy,ballsizex,ballsizey,background) ' erase original
                oldx = preoldx
                oldy = preoldy
                screen.drawrect(x,y,ballsizex,ballsizey,ballcolor)
                screenFull.SwapBuffers()
                
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
                
                preoldx = x
                preoldy = y
                x = x + dx
                y = y + dy
                dy = dy + ay
                dx = dx + ax
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
                        dx = -dx + ax
                endif
                if y+ballsizey > h
                        y = 2*y - y
                        dy = -dy + ay
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
