' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************

sub spritecollide(screenFull as object, msgport as object, topx, topy, w, h, par)

    print "Sprite Collide"
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

        ballsize = h/20
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
        
        spritecount = 10

        for i = 0 to spritecount
            ballbitmap = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:false})
            ballbitmap.clear((i*10*256*256)+255)
            region = createobject("roregion", ballbitmap, 0,0,ballsizex,ballsizey)
            sprite = compositor.newsprite(i*40, i*20, region, i*10)
            sprite.setdata(i)
            ' stash the info away
            spriteinfo = []
            spriteinfo[0] = sprite
            spriteinfo[x] = i*40        ' x position
            spriteinfo[y] = i*20        ' y position
            spriteinfo[dx] = 0           ' x velocity
            spriteinfo[dy] = 0           ' y velocity
            spriteinfo[bs] = ballsize
            spritearray[i] = spriteinfo
        next i
        
        ballbitmap = createobject("robitmap",{width:ballsizex,height:ballsizey,alphaenable:false})
        ballbitmap.clear(red+255)
        region = createobject("roregion", ballbitmap, 0,0,ballsizex,ballsizey)
        z = 100
        sprite = compositor.newsprite(x,y,region, z)
        sprite.setdata(-1)

        cue = []
        cue[0] = sprite
        cue[x] = 100
        cue[y] = 400
        cue[dx] = 0          ' x velocity
        cue[dy] = 0          ' y velocity
        cue[bs] = ballsize

        framecount = 0
        timestamp = createobject("rotimespan")
        start = timestamp.totalmilliseconds()
        button = 0  ' no button pressed

        codes = bslUniversalControlEventCodes()

        while true

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
                ' handle user input
                if button=codes.BUTTON_UP_PRESSED 
                    cue[dy] = cue[dy] - 1
                else if button = codes.BUTTON_DOWN_PRESSED
                    cue[dy] = cue[dy] + 1
                else if button = codes.BUTTON_RIGHT_PRESSED
                    cue[dx] = cue[dx] + 1
                else if button = codes.BUTTON_LEFT_PRESSED
                    cue[dx] = cue[dx] - 1
                else if button = codes.BUTTON_REWIND_PRESSED
                    z = z - 2
                    sprite.setz(z)
                    print "z=";z
                else if button = codes.BUTTON_FAST_FORWARD_PRESSED ' fwd
                    z = z + 2
                    sprite.setz(z)
                    print "z=";z
                else if button = codes.BUTTON_PLAY_RELEASED
                    cue[dx] = 0     ' set velocity to 0
                    cue[dy] = 0
                    button = 0
                endif
                
                MoveSprite(cue,w,h)
                for each sprite in spritearray
                    MoveSprite(sprite,w,h)
                end for

                cue[0].moveto(cue[x],cue[y])      ' move controllable ball
                for each sprite in spritearray
                    sprite[0].moveto(sprite[x],sprite[y])
                end for
                
                cue[0].setmemberflags(1)
                for each sprite in spritearray
                       sprite[0].setmemberflags(1)
                end for
                
                ' check for collisions with cue ball
                checkcollision(cue, spritearray)
                
                for each sprite in spritearray
                    checkcollision(sprite, spritearray)
                end for
                
                framecount = framecount + 1
                if framecount >= 100
                      deltatime = timestamp.totalmilliseconds() - start
                      print "frames per second = "; (framecount*1000)/deltatime
                      framecount = 0
                      timestamp.mark()
                endif
        end while
End Sub

sub checkcollision(s, sa)
        x = 1
        y = 2
        dx = 3
        dy = 4
        bs = 5
      collideswith = s[0].checkcollision()
      if collideswith <> invalid
        ' exchange momentum, assume head on collision and equal mass
            index = collideswith.getdata()
            print index; " x ";s[0].getdata()
            if (index = -1)
                return  ' ignore reverse collisions with cueball
            endif
            sprite = sa[index]
            tdx = sprite[dx]
            tdy = sprite[dy]
            sprite[dx] = s[dx]
            sprite[dy] = s[dy]
            s[dx] = tdx
            s[dy] = tdy
            s[0].setmemberflags(0)   ' one collision per frame
      endif
end sub

sub movesprite(s as object,w,h)
        x = 1
        y = 2
        dx = 3
        dy = 4
        bs = 5
    s[x] = s[x] + s[dx]
    if (s[x] < 0) ' left edge
        s[dx] = -s[dx]
        s[x] = -s[x]
    else if (s[x]+s[bs] > w)    ' check right edge
        s[x] = s[x] - (s[x] + s[bs] - w)
        s[dx] = -s[dx]
    endif
    s[y] = s[y] + s[dy]
    if (s[y] < 0) ' top edge
        s[dy] = -s[dy]
        s[y] = -s[y]
    else if (s[y]+s[bs] > h)    ' check bottom edge
        s[y] = s[y] - (s[y] + s[bs] - h)
        s[dy] = -s[dy]
    endif
end sub
