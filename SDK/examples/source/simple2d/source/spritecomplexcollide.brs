' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************

' set sprite collision areas as 80% of box size, centered
sub setcollisionrectarea(r as object)
    h = r.getheight()
    w = r.getwidth()
    dx = int(w/10)
    dy = int(h/10)
    print "Set collision area to (";dx;",";dy;") (";w-2*dx;",";h-2*dy;") sprsize=(";w;",";h;")"
    r.setcollisionrectangle(dx,dy,w-2*dx,h-2*dy)
    r.setcollisiontype(1)
end sub

sub setcollisioncirculararea(r as object)
    h = r.getheight()
    w = r.getwidth()
    dx = int(w/2)-1
    dy = int(h/2)-1
    radius = dx
    ' choose the smaller of the dimension for our radius
    if (radius > dy)
        radius = dy
    endif
    print "Set collision circle (";dx;",";dy;") radius=";radius;" sprsize=(";w;",";h;")"
    r.setcollisioncircle(dx,dy,radius)
    r.setcollisiontype(2)
end sub

sub spritecomplexcollide(screenFull as object, msgport as object, topx, topy, w, h, par)

    print "Sprite Ball Box Collide"
        drawing_regions = dfSetupDisplayRegions(screenFull, topx, topy, w, h)
        screen = drawing_regions.main    ' extra main drawing region 

        red = 255*256*256*256
        green = 255*256*256
        blue = 255*256
        yellow = red+green

        background = blue+255
        sidebarcolor = green+255

        regionsetupbackground(drawing_regions, background, sidebarcolor)
        screenFull.swapbuffers()
        regionsetupbackground(drawing_regions, background, sidebarcolor)

        ' create bitmap for use with doublebuffering
        dblbuffer = createobject("robitmap",{width:w,height:h,alphaenable:false})
        dblbuffer.clear(background)

        ' create a red sprite

        ballsize = h/10
        ballsizey = int(ballsize)
        ballsizex = int(ballsize*par)

        compositor = createobject("rocompositor")
        compositor.SetDrawTo(dblbuffer, background)

        x = 0
        y = h/20
        
        ' create an array to hold all sprite info
        spritearray = []
        
        x = 1
        y = 2
        dx = 3
        dy = 4
        bs = 5
        
        spritecount = 15

        ' first sprite is controllable, lets call it the cueball        
        ballbitmap = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:false})
        ballbitmap.clear(red+255)
        region = createobject("roregion", ballbitmap, 0,0,ballsizex,ballsizey)
        z = 100
        cuesprite = compositor.newsprite(x,y,region, z)
        cuesprite.setdata(0)
        ' leave collision area as default full size box

        cue = []
        cue[0] = cuesprite
        cue[x] = ballsize
        cue[y] = ballsizey
        cue[dx] = 0          ' x velocity
        cue[dy] = 0          ' y velocity
        cue[bs] = ballsize
        
        spritearray[0] = cue
        
        tmpballbitmap = createobject("robitmap","pkg:/images/AmigaBoingBall.png")
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

        xpos = ballsize
        ypos = 2*ballsizey+20
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

        while true

                compositor.draw()
                dblbuffer.setalphaenable(true)
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
                    cuesprite.setz(z)
                    print "z=";z
                else if button = codes.BUTTON_FAST_FORWARD_PRESSED ' fwd
                    z = z + 2
                    cuesprite.setz(z)
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

                ' calculate new positions
                for each sprite in spritearray
                    MoveSprite(sprite,w,h)
                end for

                ' move the sprites
                for each sprite in spritearray
                    sprite[0].moveto(sprite[x],sprite[y])
                end for
                
                cue[0].setmemberflags(1)
                for each sprite in spritearray
                       sprite[0].setmemberflags(1)
                end for

                if DetectCollisions                
                    for each sprite in spritearray
                        checkcollisions(sprite, spritearray)
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

sub checkcollisions(s, sa)
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
            print index; " x ";s[0].getdata()
            sprite = sa[index]
            tdx = sprite[dx]
            tdy = sprite[dy]
            sprite[dx] = s[dx]
            sprite[dy] = s[dy]
            s[dx] = tdx
            s[dy] = tdy
          next collideSprite
      endif
      s[0].setmemberflags(0)   ' one collision per frame
end sub

