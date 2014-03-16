' ******
' ****** Scroll a view around a large plane, double buffered
' ******

Library "v30/bslCore.brs"

Function IsHD()
    di = CreateObject("roDeviceInfo")
    if di.GetDisplayType() = "HDTV" then return true
    return false
End Function

function main()

    if IsHD()
        screen=CreateObject("roScreen", true, 854, 480)  'try this to see zoom
    else
        screen=CreateObject("roScreen", true)
    endif

    if true
        http = NewHttp2("http://rokudev.roku.com/rokudev/examples/scroll/VeryBigPng.png", "text/xml")
        http.GetToFileWithTimeout("tmp:/VeryBigPng.png", 120)
        bigbm=CreateObject("roBitmap", "tmp:/VeryBigPng.png")
    else   ' generic version
        bigbm=CreateObject("roBitmap", "pkg:/scroll_assets/VeryBigPng.png")
    end if
                
    if bigbm = invalid
        print "bigbm create failed"
        stop
    endif
    backgroundRegion=CreateObject("roRegion", bigbm, 0, 0, screen.getwidth(), screen.getheight())
    if backgroundRegion = invalid
        print "create region failed"
        stop
    endif
    backgroundRegion.SetWrap(true)

    screen.drawobject(0, 0, backgroundRegion)
    screen.SwapBuffers()
    
    msgport = CreateObject("roMessagePort")
    screen.SetPort(msgport)
    
    movedelta = 16
    if (screen.getwidth() <= 720)
        movedelta = 8
    endif

    codes = bslUniversalControlEventCodes()

    pressedState = -1 ' If > 0, is the button currently in pressed state
    while true
	if pressedState = -1 then
	    msg=wait(0, msgport)   ' wait for a button press
	else
	    msg=wait(1, msgport)   ' wait for a button release or move in current pressedState direction 
	endif
        if type(msg)="roUniversalControlEvent" then
                keypressed = msg.GetInt()
                print "keypressed=";keypressed
                if keypressed=codes.BUTTON_UP_PRESSED then 
                        Zip(screen, backgroundRegion, 0,-movedelta)  'up
			pressedState = codes.BUTTON_UP_PRESSED 
                else if keypressed=codes.BUTTON_DOWN_PRESSED then 
                        Zip(screen, backgroundRegion, 0,+movedelta)  ' down
			pressedState = codes.BUTTON_DOWN_PRESSED 
                else if keypressed=codes.BUTTON_RIGHT_PRESSED then 
                        Zip(screen, backgroundRegion, +movedelta,0)  ' right
			pressedState = codes.BUTTON_RIGHT_PRESSED 
                else if keypressed=codes.BUTTON_LEFT_PRESSED then 
                        Zip(screen, backgroundRegion, -movedelta, 0)  ' left
			pressedState = codes.BUTTON_LEFT_PRESSED 
                else if keypressed=codes.BUTTON_BACK_PRESSED then
		        pressedState = -1
		        exit while
                else if keypressed=codes.BUTTON_UP_RELEASED or keypressed=codes.BUTTON_DOWN_RELEASED or keypressed=codes.BUTTON_RIGHT_RELEASED or keypressed=codes.BUTTON_LEFT_RELEASED then 
		       pressedState = -1
                end if
	else if msg = invalid then
                print "eventLoop timeout pressedState = "; pressedState
                if pressedState=codes.BUTTON_UP_PRESSED then 
                        Zip(screen, backgroundRegion, 0,-movedelta)  'up
                else if pressedState=codes.BUTTON_DOWN_PRESSED then 
                        Zip(screen, backgroundRegion, 0,+movedelta)  ' down
                else if pressedState=codes.BUTTON_RIGHT_PRESSED then 
                        Zip(screen, backgroundRegion, +movedelta,0)  ' right
                else if pressedState=codes.BUTTON_LEFT_PRESSED then 
                        Zip(screen, backgroundRegion, -movedelta, 0)  ' left
		end if
        end if
    end while
        
end function

function Zip(screen, region, xd, yd)
    region.Offset(xd,yd,0,0)
    screen.drawobject(0, 0, region)
    screen.SwapBuffers()
end function

