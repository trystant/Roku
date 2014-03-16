' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************

sub spriteanimcollide(screenFull as object, msgport as object, topx, topy, w, h, par)

    print "Sprite Ball Box Collide"
        drawing_regions = dfSetupDisplayRegions(screenFull, topx, topy, w, h)
        screen = drawing_regions.main    ' extra main drawing region 

        red = 255*256*256*256
        green = 255*256*256
        blue = 255*256
        yellow = red+green
        purple = blue+red
        bordercolor = purple+255

        background = blue+255
        sidebarcolor = green+255
        
        borderwidth = 50

        regionsetupbackground(drawing_regions, background, sidebarcolor)
        screenFull.swapbuffers()
        regionsetupbackground(drawing_regions, background, sidebarcolor)

        ' create a red animated sprite

        ballsize = h/10
        ballsizey = int(ballsize)
        ballsizex = int(ballsize*par)

        compositor = createobject("rocompositor")
        compositor.SetDrawTo(screen, 0)

        x = 0
        y = h/20
        
        ' create an array to hold all sprite info
        spritearray = []
        
        x = 1
        y = 2
        dx = 3
        dy = 4
        bs = 5
        
        spritecount = 6

        tmpballbitmap = createobject("robitmap","pkg:/images/AmigaBoingBall.png")
        ' first sprite is controllable, lets call it the cueball
        
        transitions = 10
        arraysize = transitions*2
        cueballregions = createobject("roarray",arraysize,false)
        for i = 0 to transitions
            sizex = int(ballsizex - i*(ballsizex/(arraysize)))
            sizey = int(ballsizey - i*(ballsizey/arraysize))
            xscale = sizex/tmpballbitmap.getwidth()
            yscale = sizey/tmpballbitmap.getwidth()
            bm = createobject("robitmap",{width:sizex,height:sizey,alphaenable:false})
            bm.drawscaledobject(0,0,xscale,yscale,tmpballbitmap)
            r = createobject("roregion", bm, 0,0,sizex,sizey)
            setcollisioncirculararea(r)
            r.setpretranslation(int(-sizex/2),int(-sizey/2))
            r.settime(1000)
            cueballregions[i] = r
            if (i>0 and i<transitions)    cueballregions[arraysize-i] = r
        end for

        z = 100

        cue = []

        cue[x] = borderwidth + ballsize
        cue[y] = borderwidth + ballsizey
        cue[dx] = 0          ' x velocity
        cue[dy] = 0          ' y velocity
        cue[bs] = ballsize
        
        spritearray[0] = cue
        sprite = compositor.newanimatedsprite(cue[x],cue[y],cueballregions, z)
        sprite.setdata(0)
        cue[0] = sprite

        ballbitmap = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:false})
        xscale = ballsizex/tmpballbitmap.getwidth()
        yscale = ballsizey/tmpballbitmap.getwidth()
        
        ballbitmap.drawscaledobject(0,0,xscale,yscale,tmpballbitmap)
        ballbitmap.drawline(0,0,0,ballsizey-1,yellow+255)
        ballbitmap.drawline(0,0,ballsizex-1,0,yellow+255)
        ballbitmap.drawline(ballsizex-1,0,ballsizex-1,ballsizey-1,yellow+255)
        ballbitmap.drawline(0,ballsizey-1,ballsizex-1,ballsizey-1,yellow+255)
        
        ballsPerRow = 4
        rowballcount = 0

        xpos = ballsize+borderwidth
        ypos = 2*ballsizey+20+borderwidth
        for i = 1 to spritecount-1
            'ballbitmap = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:false})
            'ballbitmap.clear((i*10*256*256)+255)
            region = createobject("roregion", ballbitmap, 0,0,ballsizex,ballsizey)
            sprite = compositor.newsprite(xpos, ypos, region, i*10)
            sprite.setdata(i)
            setcollisioncirculararea(region)
            ' stash the info away
            spriteinfo = []
            spriteinfo[0] = sprite
            spriteinfo[x] = xpos        ' x position
            spriteinfo[y] = ypos        ' y position
            spriteinfo[dx] = 0           ' x velocity
            spriteinfo[dy] = 0           ' y velocity
            spriteinfo[bs] = ballsize
            spritearray[i] = spriteinfo
            xpos = xpos + ballsizex + ballsizex/3
            rowballcount = rowballcount + 1
            if rowballcount = ballsperrow
                rowballcount = 0
                xpos = ballsize
                ypos = ypos + ballsizey + ballsizey/3
            endif
        next i

        framecount = 0
        timestamp = createobject("rotimespan")
        start = timestamp.totalmilliseconds()
        button = 0  ' no button pressed

        codes = bslUniversalControlEventCodes()
        
        absolute = 0    ' absolute positioning or velocity
        DetectCollisions = 1
        
        animtick_timestamp = createobject("rotimespan")
        

        
        ' create collision only sprites for bottom
        spriteinfo = []
        spriteinfo[x] = 0
        spriteinfo[y] = h - borderwidth
        spriteinfo[dx] = 0
        spriteinfo[dy] = 0
        spriteinfo[bs] = -1     ' special spritesize of -1 = bottom border
        spritearray[spritecount] = spriteinfo
        border_region = createobject("roRegion",screen,0,0,0,0)
        border_region.setcollisionrectangle(0,0,w,borderwidth)
        border_region.setcollisiontype(1)
        border = compositor.newsprite(spriteinfo[x], spriteinfo[y], border_region, 0)
        border.setdrawableflag(false)      ' collision detection only
        spriteinfo[0] = border
        border.setdata(spritecount)
        
        ' create collision only sprites for top
        spriteinfo = []
        spriteinfo[x] = 0
        spriteinfo[y] = 0
        spriteinfo[dx] = 0
        spriteinfo[dy] = 0
        spriteinfo[bs] = -2     ' special spritesize of -2 = top border
        spritearray[spritecount+1] = spriteinfo
        border_region = createobject("roRegion",screen,0,0,borderwidth,borderwidth)
        border_region.setcollisionrectangle(0,0,w,borderwidth)
        border_region.setcollisiontype(1)
        border = compositor.newsprite(spriteinfo[x], spriteinfo[y], border_region, 0)
        border.setdrawableflag(false)      ' collision detection only
        spriteinfo[0] = border
        border.setdata(spritecount+1)
        
        ' create collision only sprites for left border
        spriteinfo = []
        spriteinfo[x] = 0
        spriteinfo[y] = 0
        spriteinfo[dx] = 0
        spriteinfo[dy] = 0
        spriteinfo[bs] = -3     ' special spritesize of -3 = left border
        spritearray[spritecount+2] = spriteinfo
        border_region = createobject("roRegion",screen,0,0,borderwidth,0)
        border_region.setcollisionrectangle(0,0,borderwidth,h)
        border_region.setcollisiontype(1)
        border = compositor.newsprite(spriteinfo[x], spriteinfo[y], border_region, 0)
        border.setdrawableflag(false)      ' collision detection only
        spriteinfo[0] = border
        border.setdata(spritecount+2)
        
        ' create collision only sprites for right border
        spriteinfo = []
        spriteinfo[x] = w - borderwidth
        spriteinfo[y] = 0
        spriteinfo[dx] = 0
        spriteinfo[dy] = 0
        spriteinfo[bs] = -4     ' special spritesize of -4 = left border
        spritearray[spritecount+3] = spriteinfo
        border_region = createobject("roRegion",screen,0,0,0,0)
        border_region.setcollisionrectangle(0,0,borderwidth,h)
        border_region.setcollisiontype(1)
        border = compositor.newsprite(spriteinfo[x], spriteinfo[y], border_region, 0)
        border.setdrawableflag(false)      ' collision detection only
        spriteinfo[0] = border
        border.setdata(spritecount+3)

        while true
                ' redraw background
                screen.setalphaenable(false)
                screen.drawrect(borderwidth,borderwidth,w-2*borderwidth,h-2*borderwidth,background)  ' interior
                screen.drawrect(0,0,borderwidth,h,bordercolor) ' left
                screen.drawrect(w-borderwidth,0,borderwidth,h,bordercolor) ' right
                screen.drawrect(borderwidth,0,w-2*borderwidth,borderwidth,bordercolor)   ' top
                screen.drawrect(borderwidth,h-borderwidth,w-2*borderwidth,borderwidth,bordercolor) ' bottom
                screen.setalphaenable(true)
                compositor.drawall()
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
                ' handle user input
                if button=codes.BUTTON_UP_PRESSED
                    cue[dy+absolute] = cue[dy+absolute] - 1
                else if button = codes.BUTTON_DOWN_PRESSED
                    cue[dy+absolute] = cue[dy+absolute] + 1
                else if button = codes.BUTTON_RIGHT_PRESSED
                    cue[dx+absolute] = cue[dx+absolute] + 1
                else if button = codes.BUTTON_LEFT_PRESSED
                    cue[dx+absolute] = cue[dx+absolute] - 1
                else if button = codes.BUTTON_REWIND_PRESSED
                    z = z - 2
                    sprite.setz(z)
                    print "z=";z
                else if button = codes.BUTTON_FAST_FORWARD_PRESSED ' fwd
                    z = z + 2
                    sprite.setz(z)
                    print "z=";z
                else if button = codes.BUTTON_PLAY_RELEASED
                    if absolute = 0
                        absolute = -2   ' alter the absolute position
                        cue[dx] = 0     ' set velocity to 0
                        cue[dy] = 0
                    else
                        absolute = 0
                    endif
                    button = 0
                else if button = codes.BUTTON_INFO_RELEASED
                    print "info button"
                    if DetectCollisions
                        DetectCollisions = 0
                    else
                        DetectCollisions = 1
                    endif
                    button = 0
                endif
                
                ' should be a way to get the totalmilliseconds and at the same time reset the counter
                animtick = animtick_timestamp.totalmilliseconds()
                animtick_timestamp.mark()
                ' adjust animated sprite regions if needed
                compositor.animationtick(animtick)
                
                ' calculate new positions
                for each sprite in spritearray
                    if (sprite[bs] > 0) MoveAnimSprite(sprite,w,h)
                end for

                ' move the sprites
                for each sprite in spritearray
                    if (sprite[bs] > 0) sprite[0].moveto(sprite[x],sprite[y])
                end for
                
                cue[0].setmemberflags(1)
                for each sprite in spritearray
                       if (sprite[bs] > 0) sprite[0].setmemberflags(1)
                end for

                if DetectCollisions                
                    for each sprite in spritearray
                        if (sprite[bs] > 0) checkanimcollisions(sprite, spritearray)
                    end for
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

sub checkanimcollisions(s, sa)
        x = 1
        y = 2
        dx = 3
        dy = 4
        bs = 5
      collideswitharray = s[0].checkmultiplecollisions()
      if collideswitharray <> invalid
        ' exchange momentum, assume head on collision and equal mass
          for each collideSprite in collideswitharray
            index = collideSprite.getdata()
            'print index; " x ";s[0].getdata()
            sc = sa[index]
            spritewidth = sc[bs]
            if spritewidth > 0
                tdx = sc[dx]
                tdy = sc[dy]
                sc[dx] = s[dx]
                sc[dy] = s[dy]
                s[dx] = tdx
                s[dy] = tdy
            else if spritewidth = -1  ' bottom border collision
                r = s[0].getregion()   ' need to get current anim region
                ' calculate correct bounce position
                's[y] = s[y] - (s[y] + r.getheight() + r.getpretranslationy() - sc[y])
                oldy = s[y]
                h = sc[y]
                pretrany = r.getpretranslationy()
                sprheight= r.getheight()
                mydy = s[y]+sprheight+pretrany - h
                s[y] = h - sprheight - 2*mydy - pretrany
                'print "oldy="; oldy;" newy= ";s[y];" h=";h;" pretrany=";pretrany; " dy=";s[dy];" sprheight=";sprheight
                s[dy] = -s[dy]
                s[0].moveto(s[x],s[y])
            else if spritewidth = -2  ' top border collision
                r = s[0].getregion()   ' need to get current anim region
                ' calculate correct bounce position
                h = sc[0].getregion().getheight() ' height border
                pretrany = r.getpretranslationy()
                oldy = s[y]
                s[y] = h + (h - (s[y]+pretrany) ) - pretrany
                'print "oldy="; oldy;" newy= ";s[y];" h=";h;" pretrany=";pretrany; " dy=";s[dy]
                s[dy] = -s[dy]
                s[0].moveto(s[x],s[y])
            else if spritewidth = -3  ' left border collision
                r = s[0].getregion()   ' need to get current anim region
                ' calculate correct bounce position
                w = sc[0].getregion().getwidth() ' width border
                pretranx = r.getpretranslationx()
                oldx = s[x]
                s[x] = w + (w - (s[x]+pretranx) ) - pretranx
                'print "oldy="; oldy;" newy= ";s[y];" h=";h;" pretrany=";pretrany; " dy=";s[dy]
                s[dx] = -s[dx]
                s[0].moveto(s[x],s[y])
            else if spritewidth = -4  ' right border collision
                r = s[0].getregion()   ' need to get current anim region
                ' calculate correct bounce position
                's[y] = s[y] - (s[y] + r.getheight() + r.getpretranslationy() - sc[y])
                oldy = s[y]
                w = sc[x]
                pretranx = r.getpretranslationx()
                sprwidth= r.getwidth()
                mydx = s[x]+sprwidth+pretranx - w
                s[x] = w - sprwidth - 2*mydx - pretranx
                'print "oldy="; oldy;" newy= ";s[y];" h=";h;" pretrany=";pretrany; " dy=";s[dy];" sprheight=";sprheight
                s[dx] = -s[dx]
                s[0].moveto(s[x],s[y])
            endif
          next collideSprite
      endif
      s[0].setmemberflags(0)   ' one collision per frame
end sub

sub moveanimsprite(s as object,w,h)
        x = 1
        y = 2
        dx = 3
        dy = 4
        bs = 5
    s[x] = s[x] + s[dx]
    s[y] = s[y] + s[dy]
    ' all border collision detection done by sprite collision detection
end sub
