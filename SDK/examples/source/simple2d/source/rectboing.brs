' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************

sub drawline(screen, x0,y0,x1,y1,width,color)

    if (width = 1) and (y0 <> y1) and (x0 <> x1)
        screen.drawline(x0, y0, x1, y1, color)
        return
    endif

    if (x0=x1)
        ' vertical line
        h = y1-y0
        if h<0 ' upside down?
            y0=y1
            h = -h
        endif            
        screen.drawrect(x0,y0,width,h+1,color)
    elseif (y0=y1)
        w = x1-x0
        if w<0
            x0=x1
            w = -w
        endif
        screen.drawrect(x0,y0,w+1,width,color)
    endif
end sub

sub regiondrawgrid(screen, background)
    ' only draw into primary surface area now - do not touch sidebars
    screen.clear(background)
    w = screen.getWidth()
    h = screen.getHeight()
    left = int(w/10)
    right = w-left
    top= int(h/10)
    bottom = h-top

    color = &hff00ffff
    ' draw vertical lines
    i = 0
    x = left
    deltax = int(left/2)
    deltay = deltax
    lineheight = bottom - top
    bottom = top + deltay*int(lineheight/deltay)
    bottomXdelta = (deltax/3)
    bottomXdeltainit = bottomXdelta
    deltax_over_20 = int(deltax/20)
    deltay_over_2 = int(deltay/2)
    while x<=right
        drawline(screen,x,top,x,bottom,1,color)
        drawline(screen,x,bottom,x-bottomXdelta,bottom+deltay_over_2,1,color)
        x = x + deltax
        bottomXdelta =bottomXdelta - deltax_over_20
    end while
    ' correct for actual right edge
    right = x - deltax
    y = top
    'draw horizontal lines
    while y<=bottom
        drawline(screen,left,y,right,y,1,color)
        y = y + deltay
    end while
    ' draw floor
    drawline(screen, left-bottomXdeltainit, bottom+deltay_over_2,right-bottomXdelta-deltax_over_20 , bottom+deltay_over_2, 1, color)
    'qwe = -1
    'linewidth = 16
    ' draw a white box around everything
    'drawline(screen,0,topy,w-1,0,linewidth,qwe)
    'drawline(screen,0,topy,0,h-1,linewidth,qwe)
    'drawline(screen,0,h-1-linewidth,w-1,h-1-linewidth,linewidth,qwe)
    'drawline(screen,w-1-linewidth,0,w-1-linewidth,h-1,linewidth,qwe)
end sub

sub rectboing(screenFull as object, msgport as object, topx, topy, w, h, par)

        print "Rect Boing"
        drawing_regions = dfSetupDisplayRegions(screenFull, topx, topy, w, h)
        screen = drawing_regions.main    ' extract main drawing region

        red = 255*256*256*256+255
        green = 255*256*256+255
        blue = 255*256+255
        
        background = &h8C8C8CFF
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

        ballbitmap = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:false})
        ballbitmap.clear(red)
        
        ballshadow = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:true})
        ballshadow.clear(&h80)

        ' calculate starting position and motion dynamics
        x = w/10
        y = h/10

        dx = 2
        dy = 1
        ay = 1
        oldx = x
        oldy = y
        framecount = 0
        timestamp = createobject("rotimespan")
        swapbuff_timestamp = createobject("rotimespan")
        start = timestamp.totalmilliseconds()
        swapbuff_time = 0
        ballsizex_over_3 = ballsizex/3
        ballsizey_over_6 = ballsizey/6
        w_over_10 = w/10
        w_times9_over10 = (w*9)/10
        h_times9_over10 = (h*9)/10
        codes = bslUniversalControlEventCodes()
        while true
                regiondrawgrid(screen, background)
                screen.SetAlphaEnable(true)
                screen.drawobject(x+ballsizex_over_3,y+ballsizey_over_6,ballshadow)
                screen.SetAlphaEnable(false)
                screen.drawobject(x,y,ballbitmap)
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
                        if type(msg) = "roUniversalControlEvent"
                            button = msg.getint()
                            print "button=";button
                            if button=codes.BUTTON_BACK_PRESSED   
                                return
                            endif
                        endif
                    endif
                end while

                oldx = x
                oldy = y
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
                if x+ballsizex > w_times9_over10
                        x = 2*w_times9_over10 - x - 2*ballsizex
                        dx = -dx
                endif
                if y+ballsizey > h_times9_over10
                        y = 2*y - y
                        dy = -dy + ay
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
