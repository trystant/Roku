' *********************************************************
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' *********************************************************



sub drawimage(screenFull as object, msgport as object, topx, topy, w, h, par)

    print "demonstrate drawimage using double buffering"
        drawing_regions = dfSetupDisplayRegions(screenFull, topx, topy, w, h)
        screen = drawing_regions.main    ' extract main drawing region

        red = 255*256*256*256+255
        green = 255*256*256+255
        blue = 255*256+255

        background=blue
        sidebarcolor=green

        regionsetupbackground(drawing_regions, background, sidebarcolor)
        dfDrawImage(screen, "pkg:/images/bluebird.jpg", topx+100, topy+50)
        screenFull.SwapBuffers()
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
