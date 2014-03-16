' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************

sub DumpFourPixels(screen, row)
        p = screen.getbytearray(0,row,4,1)

        print "4 pixels(";row;") ="
        for i = 0 to 3
            k = i*4
            print   " (";p[k];",";p[k+1];",";p[k+2];",";p[k+3];")";
        next i
        print
end sub

sub screenblit(screenFull as object, msgport as object, topx, topy, w, h, par)

    print "demonstrate drawimage using double buffering"
        drawing_regions = dfSetupDisplayRegions(screenFull, topx, topy, w, h)
        screen = drawing_regions.main    ' extract main drawing region

        red = 255*256*256*256+255
        green = 255*256*256+255
        blue = 255*256+255

        ballsize = h/5
        ' compute ball dimensions using pixel aspect ratio
        ballsizey = int(ballsize)
        ballsizex = int(ballsize*par)
        background=blue
        sidebarcolor=green

        regionsetupbackground(drawing_regions, background, sidebarcolor)

        screen.clear(blue)
        screen.drawrect(1,0,1,1,red)
        screen.drawrect(2,0,1,1,green)
        screen.Finish()

        print "SCREEN "
        DumpFourPixels(screen,0)
        DumpFourPixels(screen,1)


        'scrbitmap = CreateObject("roBitmap", {width:scr.GetWidth(), height:scr.GetHeight(), alphaenable:false})
        scrbitmap = CreateObject("roBitmap", {width:screen.getwidth(), height:screen.getheight(), alphaenable:false})
        scrbitmap.clear(red)
        scrbitmap.drawrect(1,0,1,1,green)
        scrbitmap.drawrect(2,0,1,1,blue)
        scrbitmap.Finish()
        print "bitmap "
        DumpFourPixels(scrbitmap,0)
        DumpFourPixels(scrbitmap,1)

        scrbitmap.DrawObject(0,0,screen)
        scrbitmap.Finish()

        print "bitmapFromScreen "
        DumpFourPixels(scrbitmap,0)
        DumpFourPixels(scrbitmap,1)
        
        screenFull.SwapBuffers()
        print "SCREEN after swapbuffers"
        DumpFourPixels(screen, 0)

        codes = bslUniversalControlEventCodes()
        while true
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
        end while
End Sub
