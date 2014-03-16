' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************

sub textrect(screenFull as object, msgport as object, topx, topy, w, h, par)

        print "Sprite Boing with positional text"
        drawing_regions = dfSetupDisplayRegions(screenFull, topx, topy, w, h)
        screen = drawing_regions.main    ' extra main drawing region 
        
        ' setup font stuff for drawing text
        fontreg = createobject("rofontregistry")
        font = fontreg.getdefaultfont()

        lineheight = font.getonelineheight()
        print "lineheight=";lineheight
        linewidth1 = font.getonelinewidth("abcdefghijklmnopqrstuvwxyz1234567890",99999)
        print "linewidth1=";linewidth1
        linewidth2 = font.getonelinewidth("AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz",99999)
        print "linewidth2=";linewidth2
        linewidth3 = font.getonelinewidth("`~!@#$%^&*()-_=+[{]}\|;:',<.>/?",99999)
        print "linewidth3=";linewidth3

        red=  &hFF0000FF    'RGBA
        green=&h00FF00FF	'RGBA
        blue= &h0000FFFF	'RGBA
        white=&hFFFFFFFF	'RGBA
        black=&hFF			'RGBA
        
        clr = int(255*.55)
        background = &h8c8c8c8cff
        sidebarcolor = green

        ' intialize sidebars if any
        regionsetupbackground(drawing_regions, background, sidebarcolor)
        regiondrawgrid(screen, background)
        screenFull.SwapBuffers()
        regionsetupbackground(drawing_regions, background, sidebarcolor)

        ' create a red block

        ballsize = h/4
        ballsizey = int(ballsize)
        ballsizex = int(ballsize*par)

        ballbitmap = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:false})
        ballbitmap.clear(red)

        ' create the blocks shadow
        ballshadow = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:true})
        ballshadow.clear(&h80)

        x = w/10
        y = h/10
        
        dim numbers[2,2]
        for i = 0 to 2
            for j = 0 to 2
                numbers[i,j] = 1.234
            next j
        next i

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
                regiondrawgrid(screen, background)

                drawline(screen,200,300,200+linewidth1,300,1,black)
                drawline(screen,10,300+lineheight,10+linewidth2,300+lineheight,1,black)
                drawline(screen,10,300+lineheight*2,10+linewidth2,300+lineheight*2,1,black)
                drawline(screen,200,300+lineheight*3,200+linewidth3,300+lineheight*3,1,black)

                ' draw numbers
                numbers[0,0] = x
                numbers[0,1] = y
                for i = 0 to 1
                    for j = 0 to 1
                        screen.drawtext(str(numbers[i,j]),200+j*200,100+100*i,white,font)
                    next j
                next i

                screen.drawtext("abcdefghijklmnopqrstuvwxyz1234567890",200,300,white,font)
                screen.drawtext("AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz",10,300+lineheight,white,font)
                screen.drawtext("`~!@#$%^&*()-_=+[{]}\|;:',<.>/?",200,300+lineheight*2,white,font)

                screen.SetAlphaEnable(true)
                screen.drawobject(x+ballsizex/3,y+ballsizey/4,ballshadow)
                screen.SetAlphaEnable(false)
                screen.drawobject(x,y,ballbitmap)
                screenFull.swapbuffers()

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
                if x<w/10
                        x = (w/10)+(w/10-x)
                        dx = -dx
                endif
                if y<0
                        y = -y
                        dy = -dy
                endif
                if x+ballsizex > (w*9)/10
                        x = 2*(w*9/10) - x - 2*ballsizex
                        dx = -dx
                endif
                if y+ballsizey > (h*9)/10
                        y = 2*y - y
                        dy = -dy + ay
                endif
        
                'msg=wait(15, msgport)   ' 15 ms or exit if button pressed
                if type(msg)="roUniversalControlEvent" then 
                    exit while
                end if
                framecount = framecount + 1
                if framecount >= 100
                      deltatime = timestamp.totalmilliseconds() - start
                      print "frames per second = "; (framecount*1000)/deltatime
                      framecount = 0
                      timestamp.mark()
                endif
        end while
End Sub
