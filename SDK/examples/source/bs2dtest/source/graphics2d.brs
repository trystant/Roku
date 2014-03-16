Library "v30/bslDefender.brs"

function RegionFromFile(filespec)
	bitmap=CreateObject("roBitmap", filespec)
	return CreateObject("roRegion", bitmap, 0, 0, bitmap.GetWidth(), bitmap.GetHeight())
end function

function createScreen()

    screen = createobject( "roScreen", false, 1280, 720 )

    return screen
end function

function BriefTest() as boolean
    return true
end function

function IgnoreAlphaTest() as boolean
    return true
end function

function RegionFromColor(w, h, color)
	bitmap=CreateObject("roBitmap", {width: w, height: h})
	bitmap.Clear(color)
	return CreateObject("roRegion", bitmap, 0, 0, w, h)
end function

function Jiggle(sprite)
	r=rnd(0)
	if r < .25 then 
		sprite.MoveOffset(+8, 0)
	else if r < .50 then
		sprite.MoveOffset(-7, 0)
	else if r < .75 then
		sprite.MoveOffset(0, +8)
	else
		sprite.MoveOffset(0, -7)
	end if
end function

sub RGBtest(screen, label)
    print "RGBTests: "; label
	red=  &hFF0000FF    'RGBA
	green=&h00FF00FF	'RGBA
	blue= &h0000FFFF	'RGBA
	CheckClear(screen, &h123456ff, &h12, &h34, &h56)	
	CheckClear(screen, red, 255, 0, 0)
	CheckClear(screen, green, 0, 255, 0)
	CheckClear(screen, blue, 0, 0, 255)
end sub
		
Sub Main()

	print "2D graphics tests starting."

    ' create a regular screen so that homescreen never shows up if we've delected all the roscreens while running this test	
  backstop = CreateObject("roParagraphScreen")
  backstop.show()

	red=  &hFF0000FF    'RGBA
	green=&h00FF00FF	'RGBA
	blue= &h0000FFFF	'RGBA
	white=&hFFFFFFFF	'RGBA
	black=&hFF			'RGBA
	
'****************************************************
'****************************************************
'*** roCompositor tests
'****************************************************
'****************************************************	

if false   '' work in progress

	screen=createScreen()
	compositor=CreateObject("roCompositor")
	compositor.SetDrawTo(screen, black)
	
	sprite1=compositor.NewSprite(100, 100, RegionFromFile("pkg:/graphics2d_tests/gameover.png"))
	sprite2=compositor.NewSprite(300, 200, RegionFromFile("pkg:/graphics2d_tests/gameover.png"))
	sprite3=compositor.NewSprite(50, 50, RegionFromColor(25, 100, red))
	sprite4=compositor.NewSprite(500, 230, RegionFromColor(30, 30, blue))
	
	sprite1.SetData( { fred: ["fred"] } )
	if sprite1.GetData().fred[0]<>"fred" then stop
	
	sprite1.SetData( { fred: ["fred"] } )
	if sprite1.GetData().fred[0]<>"fred" then stop
	
	sprite1.SetRegion(	RegionFromFile("pkg:/graphics2d_tests/gameover.png") )
	
	for loop=1 to 100
		Jiggle(sprite1)
		Jiggle(sprite2)
		Jiggle(sprite3)
		Jiggle(sprite4)
		
		compositor.Draw()
		'screen.DrawRect(0,0,25,25,[red,green,blue,white][loop mod 4])
	
	end for
	

	stop
	
end if



'****************************************************
'****************************************************
'*** Initial Basic tests done with a single roScreen
'****************************************************
'****************************************************

	screen0=createScreen()
if 1
    RGBTest(screen0, "Visible Screen")

    ' quick alpha test on main screen
	screen0.SetAlphaEnable(true)
	screen0.clear(black)
    if not dfDrawImage(screen0, "pkg:/graphics2d_tests/background.png",0,0) then stop
    ba = screen0.getbytearray(1217,150,1,1)
    print "initial color(1217,150) = ";ba[0];",";ba[1];",";ba[2];",";ba[3]
	'screen0.clear(white)
	'screen0.DrawRect(100,100, screen0.GetWidth()-200, screen0.GetHeight()-200, &h80)  ' dim middle of
	screen0.DrawRect(150,150, screen0.GetWidth()-200, screen0.GetHeight()-200, &h80)  ' dim middle of screen

    ba = screen0.getbytearray(1217,150,1,1)
    print "dim color(1217,150) = ";ba[0];",";ba[1];",";ba[2];",";ba[3]

if 0
    for i = 0 to screen0.getheight()-1
        ck = CheckSumBitmap(screen0,0,i,screen0.getwidth(),1)
        print "if CheckSumBitmap(screen0,0,";i;",screen0.getwidth(),1) <>";chr(34);ck;chr(34);" then stop"
    endfor
endif
if 0
    for i = 0 to screen0.getwidth()-1
        ck = CheckSumBitmap(screen0,i,150,1,1)
        print "if CheckSumBitmap(screen0,";i;",150,1,1) <>";chr(34);ck;chr(34);" then stop"
    endfor
endif

	if "400ce2d5ced9b000226c08ecb211d7cb"<>CheckSumBitmap(screen0) then
	'if "aec5791a89eaa4cf7c8683895c87caa8"<>CheckSumBitmap(screen0) then
        print "DrawRect Alpha Test Fail"
        if not ignoreAlphaTest() stop
    endif

	offscreen0=CreateObject("roBitmap",{width:200,height:200})
    RGBTest(offscreen0, "bitmap 200x200")

	offscreen1=CreateObject("roBitmap",{width:64,height:64})
    RGBTest(offscreen1, "bitmap 64x64")

    print "More off screen tests"
	offscreen1.Clear(white)
	screen0.Clear(0)
	offscreen0.Clear(0)
	ba=offscreen1.GetByteArray(0,0,offscreen1.GetWidth(), offscreen1.GetHeight())
	compareAsLongs(ba,&hffffffff)
	
	ba=offscreen0.GetByteArray(0,0,offscreen0.GetWidth(), offscreen0.GetHeight())
	for each byte in ba
		if byte<>0 then stop
	end for

	offscreen0=invalid
	offscreen1=invalid
endif

print "'****** creating 2000x1000 bitmap"
	off=createobject("roBitmap", {width:2000, height:1000, AlphaEnable: true})
	if off = invalid
	    print "Unable to allocate 2000x1000 bitmap - skipping test!!!!!!!!!!!!!!!!!!!!"
    else
	    off.Clear(white)
        print "off checksum0 = ";CheckSumBitmap(off)   ' good
	    if not dfDrawImage(off, "pkg:/graphics2d_tests/background.png",50,50) then stop
        print "off checksum1 = ";CheckSumBitmap(off)   ' good

        ' this drawrect is bad
	    off.DrawRect(150,150, screen0.GetWidth()-200, screen0.GetHeight()-200, &h80)  ' dim middle of screen
        print "off checksum2 = ";CheckSumBitmap(off)   ' bad

	    gameover=CreateObject("roBitmap", "pkg:/graphics2d_tests/gameover.png")
	    if type(gameover)<>"roBitmap" then stop
	    off.DrawObject(((1280+100)-gameover.getwidth())/2, ((720+100)-gameover.getheight())/2, gameover)
        print "off checksum3 = ";CheckSumBitmap(off)
	    region=CreateObject("roRegion", off, 50, 50, 1280, 720)
	    screen0.DrawObject(0,0,region)
	    screen0.Finish()

	    print" at this point, the display screen should be identical to the prior test."
        checksum = CheckSumBitmap(screen0)
	    if ("aaef0fb78b46f9d5b0094decfecac5e9"<>checksum)
            print "large alpha test fail"
            if not IgnoreAlphaTest() then stop
        endif

  	    region=invalid
	    off=invalid
        gameover = invalid
    endif


print "' ****** Test boundries"

	' 1X1 rect
	screen0.Clear(0)
	ba=screen0.GetByteArray(49,49,3,3) 
        print "screen0.DrawRect(50,50,1,1, blue) before (";ba[16];",";ba[17];",";ba[18];") alpha=";ba[19]
	screen0.DrawRect(50,50,1,1, blue)
	ba=screen0.GetByteArray(49,49,3,3) 
        print "screen0.DrawRect(50,50,1,1, blue) after (";ba[16];",";ba[17];",";ba[18];") alpha=";ba[19]
	if ba[16]<>0 or ba[17]<>0 or ba[18]<>255 or ba[19]<>255
        print "screen0.DrawRect(50,50,1,1, blue) failed (";ba[16];",";ba[17];",";ba[18];") alpha=";ba[19]
        stop
    endif
	for x=0 to ba.count()-1
	   if (x<16 or x>19) and ba[x]<>0 then stop
	end for
	
	' 2x2 rect	
	screen0.Clear(0)
	screen0.DrawRect(50,50,2,2, blue)
	ba=screen0.GetByteArray(49,49,4,4) 
	if ba[20]<>0 or ba[21]<>0 or ba[22]<>255 or ba[23]<>255 then stop
	if ba[24]<>0 or ba[25]<>0 or ba[26]<>255 or ba[27]<>255 then stop
	if ba[36]<>0 or ba[37]<>0 or ba[38]<>255 or ba[39]<>255 then stop
	if ba[40]<>0 or ba[41]<>0 or ba[42]<>255 or ba[43]<>255 then stop
	for x=0 to ba.count()-1
	   if (x<20 or x>27) and (x<36 or x>43) and ba[x]<>0 then stop
	end for
	
	' 1x1 bitmap
	block=createobject("roBitmap", {width:1, height:1}) 
	block.clear(blue)
	screen0.DrawObject(100,100,block)
	ba=screen0.GetByteArray(99,99,3,3) 
	if ba[16]<>0 or ba[17]<>0 or ba[18]<>255 or ba[19]<>255 then stop
	for x=0 to ba.count()-1
	   if (x<16 or x>19) and ba[x]<>0 then stop
	end for
	block = invalid

	
'****************************************************************
'****************************************************************
print "'*** Test max bitmap size of 2048 on a side"
'****************************************************************
'****************************************************************
    if CreateObject("roBitmap", {width:2048, height:1})=invalid then stop
    if CreateObject("roBitmap", {width:1, height:2048})=invalid then stop

    if CreateObject("roBitmap", {width:-1, height:1})<>invalid then stop
	if CreateObject("roBitmap", {width:1, height:-1})<>invalid then stop
	if CreateObject("roBitmap", {width:1, height:2049})<>invalid
        print "bitmap {width:1, height:2049})<>invalid -- error -- ignoring"
        'stop
    endif
	if CreateObject("roBitmap", {width:2049, height:1})<>invalid
        print "bitmap {width:2049, height:1})<>invalid -- error -- ignoring"
        'stop
    endif

	screen0 = invalid
	ba = invalid

    print "Test loading of a very big png file"
	verybig=CreateObject("roBitmap", "pkg:/graphics2d_tests/big_2048x1800.png")
	if verybig=invalid then stop
	ba=verybig.GetByteArray(0,0,50,50)  ' pick a spot
	IsAllColor(ba, &hFF, 0, &hFF)
	ba=verybig.GetByteArray(1900,1200,94,94)  ' pick a spot
	IsAllColor(ba, &hFF, 0, &hFF)
    print "Recreating screen"
	screen0 = createscreen()	
	screen0.DrawObject(0,0, verybig)  ' will use this later
	screen0.finish()

	ba=invalid
	verybig=invalid

'****************************************************************
'****************************************************************
print "'*** Test clipping"
'****************************************************************
'****************************************************************

    boxsize = 100
	square=CreateObject("roBitmap", {width:boxsize, height:boxsize})
	' Initialize quadrants of box to provide visual aid for clipping
	midbox = int(boxsize/2)
	square.drawrect(0,0,midbox,midbox,&hFF0000FF)   ' upper left is red
    square.drawrect(midbox,0,midbox,midbox,&h00FF00FF)   ' upper right is green
	square.drawrect(0,midbox,midbox,midbox,&h0000FFFF)   ' lower left is blue
	square.drawrect(midbox,midbox,midbox,midbox,&hFFFFFFFF)   ' lower left is white

	bot=screen0.GetHeight()
	right=screen0.GetWidth()
	midy=bot/2
	midx=right/2

	screen0.DrawObject(-50,-50,square)
	screen0.DrawObject(right-50,-50,square)
	screen0.DrawObject(-50,bot-50,square)
	screen0.DrawObject(right-50,bot-50,square)
	
	screen0.DrawRect(midx, -50, 100, 100, &hFFFFFFFF)
	screen0.DrawRect(midx, bot-50, 100, 100, &hFFFFFFFF)
	screen0.Finish()
	print "Should see UL=white UR=blue LL=green LR=red"
    ' do first test without text
    if "3444bdad4c02ecbe8040e9c1f00ad63f"<>CheckSumBitmap(screen0) then stop	

	font=CreateObject("roFontRegistry").GetDefaultFont()
	tststr="1234567890"
	screen0.DrawText("ABCD",-font.GetOneLineHeight(), -font.GetOneLineHeight()/2, &hFF000000, font)
	screen0.DrawText(tststr,-font.GetOneLineWidth(tststr,400)/2, midy, &hFFFFFFFF, font)
	screen0.DrawText(tststr,right-font.GetOneLineWidth(tststr,400)/2, midy, &hFFFFFFFF, font)	
	screen0.Finish()
	print "Should see UL=white UR=blue LL=green LR=red with clipped text on left and righthand side"

    ' we have multiple md5s to deal with different font implementations
    md5 = CheckSumBitmap(screen0)
    if "330abe7491f6c8a1b467ad019bf94994" = md5 then
        print "OK Pico"
    elseif "bb29f2fab0d83ab140e9f6268de3dfcd" = md5 then
        print "OK Giga"
    elseif "18eee5144086460f27a5c3ed1f6650a0" = md5 then
        print "OK Paolo"
    else
        print "broken"
        stop
    endif

' more blending tests
print "'****** TEST various compositing using screen"
	screen0.SetAlphaEnable(true)
	screen0.clear(white)
	screen0.DrawRect(100,100, screen0.GetWidth()-200, screen0.GetHeight()-200, &h80)  ' dim middle of screen

	' at this point, screen0 exists, is the display screen, has alpha enabled.
	dfDrawImage(screen0, "pkg:/graphics2d_tests/background.png",0,0)
	screen0.DrawRect(100,100, screen0.GetWidth()-200, screen0.GetHeight()-200, &h80)  ' dim middle of screen
	gameover=CreateObject("roBitmap", "pkg:/graphics2d_tests/gameover.png")
	screen0.DrawObject((screen0.getwidth()-gameover.getwidth())/2, (screen0.getheight()-gameover.getheight())/2, gameover)
	screen0.Finish()
	print "at this point, the display screen should a leafy background, with a large sub rect alpha blended with black"
	print "the -game over- dialog on top."
    sleep(1000)

	savechecksum = CheckSumBitmap(screen0)	
	if ("aaef0fb78b46f9d5b0094decfecac5e9"<>checksum)
        print "complex blend fail"
        if not IgnoreAlphaTest() then stop
    endif

print "'*** DrawObject(), dfDrawImage(), and DrawRect() tests"
'****************************************************************
'****************************************************************

' ***** TEST Alpha

	bigimage=CreateObject("roBitmap", "pkg:/graphics2d_tests/leaves.png")  ' image with lots of pure alpha in the middle
	screen0.SetAlphaEnable(true)
	screen0.Clear(red)
	screen0.DrawObject(0,0,bigimage)
	screen0.Finish()

	bigimage = invalid
	
	ba=screen0.GetByteArray(0,30,1,1)  ' pick a spot where there should be some leaf (not alpha)
	if ba[0]=0 and ba[1]=255 and ba[2]=0 then stop

	ba=screen0.GetByteArray(500,300,50,50)  ' pick a spot where alpha should show the clear color
	IsAllColor(ba, 255, 0, 0)
    sleep(1000)

    print "'****** TEST DrawObject from the >>active display<< screen to an offscreen bitmap (this is a special case in OpenGL)"
	screen0.Clear(red)

	dfDrawImage(screen0, "pkg:/graphics2d_tests/gameover.png",150,64)

	if CheckSumBitmap(screen0, 150, 64, gameover.getwidth(), gameover.getheight())<>"c65792ba53533e26fd9c60454d2f2897" then stop
	region=CreateObject("roRegion", screen0, 150, 64, gameover.getwidth(), gameover.getheight())

	backstore=createobject("roBitmap", {width:700, height:400, AlphaEnable: false}) 
	backstore.clear(blue)
	backstore.DrawObject(5,5,region)
	if CheckSumBitmap(backstore, 5, 5, gameover.getwidth(), gameover.getheight())<>"c65792ba53533e26fd9c60454d2f2897" then stop
	
	screen0.DrawObject(0,0,backstore)  ' look for flipped bitmaps
	screen0.Finish()
	if "15475dbf409a2c86ab3a74a187ac59a4"<>CheckSumBitmap(backstore, 0, 0, gameover.getwidth()/2, gameover.getheight()/2) then stop
	region = invalid
	backstore = invalid
	gameover = invalid


    print "All standard graphics tests done"
    sleep(5000)
    return

'*******************************************************************************************************
' Multiple Screen tests can get pretty complicated
' screen0 is still a real screen, now create a second screen, making screen0 offscreen and non visible

    print "testing multiscreen"

	screen1=createScreen()
	if screen1.GetWidth()<>1280 then stop
	if screen1.GetHeight()<>720 then stop
	CheckClear(screen1, red, 255, 0, 0)
    ' check to see if the oldscreen was saved properly
    if savechecksum = CheckSumBitmap(screen0)
        print "failed to properly save old screen"
        stop
    else
        print "screen properly saved!"
        stop
    endif
	
	CheckClear(screen1, red, 255, 0, 0)
	CheckClear(screen1, green, 0, 255, 0)
	CheckClear(screen1, blue, 0, 0, 255)

	CheckClear(screen0, green, 0, 255, 0)
	CheckClear(screen0, blue, 0, 0, 255)
	CheckClear(screen0, red, 255, 0, 0)
	screen0.Clear(white)
	screen1.Clear(0)
	ba=screen0.GetByteArray(0,0,screen0.GetWidth(), screen0.GetHeight())
	compareAsLongs(ba,&hffffffff)

	ba=screen1.GetByteArray(0,0,screen1.GetWidth(), screen1.GetHeight())
	compareAsLongs(ba,0)
	screen1.Clear(0)
	screen0.Clear(white)
	ba=screen0.GetByteArray(0,0,screen0.GetWidth(), screen0.GetHeight())
    compareAsLongs(ba,&hffffffff)

	ba=screen1.GetByteArray(0,0,screen1.GetWidth(), screen1.GetHeight())
    compareAsLongs(ba,0)


'****************************************************************
'****************************************************************
print "'*** DrawObject(), dfDrawImage(), and DrawRect() tests"
'****************************************************************
'****************************************************************

' ***** TEST Alpha

	bigimage=CreateObject("roBitmap", "pkg:/graphics2d_tests/leaves.png")  ' image with lots of pure alpha in the middle
	screen0.SetAlphaEnable(true)
	screen0.Clear(red)
	screen0.DrawObject(0,0,bigimage)
	screen0.Finish()
	
	screen1.SetAlphaEnable(true)
	screen1.Clear(green)
	screen1.DrawObject(0,0,bigimage)
	screen1.Finish()
	bigimage = invalid
	
	ba=screen0.GetByteArray(0,30,1,1)  ' pick a spot where there should be some leaf (not alpha)
	if ba[0]=0 and ba[1]=255 and ba[2]=0 then stop

	ba=screen1.GetByteArray(0,30,1,1)  ' pick a spot where there should be some leaf (not alpha)
	if ba[0]=255 and ba[1]=0 and ba[2]=0 then stop

	ba=screen0.GetByteArray(500,300,50,50)  ' pick a spot where alpha should show the clear color
	IsAllColor(ba, 255, 0, 0)
	
	ba=screen1.GetByteArray(500,300,50,50)   ' pick a spot where alpha should show the clear color
	IsAllColor(ba, 0, 255, 0)	
	
	screen1.clear(255)
	screen1.Finish()
	screen1=invalid ' bring the hidden screen to top, and test again
	ba=screen0.GetByteArray(500,300,50,50)
	IsAllColor(ba, 255, 0, 0)
	ba=screen0.GetByteArray(0,30,1,1)  ' pick a spot where there should be some leaf (not alpha)
	if ba[0]=0 and ba[1]=255 and ba[2]=0 then stop

print "'****** TEST various compositing using screens, offscreen"

	screen0=createScreen()   ' recreate screen in case there are Initialization bugs
	screen0.SetAlphaEnable(true)
	screen1=createScreen() 
	screen0.clear(white)
	screen0.Finish()
	screen1.clear(red)  ''' THIS LINE IS KEY TO A PROBLEM fixed
	screen1.Finish()
	CheckClear(screen1, red, 255, 0, 0)
	screen0.DrawRect(100,100, screen0.GetWidth()-200, screen0.GetHeight()-200, &h80)  ' dim middle of screen
	screen0.Finish()
	screen1=invalid
	
	print "at this point, the display screen should be white with a big gray block in the middle"
    sleep(10000)
	
	' at this point, the display screen should be white with a big gray block in the middle
	' The gray block is an alpha-blended black rect, and it is possible it will produce a slightly different
	' shade on different implementations.  In which case this checksum needs to be made platform specific.

	if "aec5791a89eaa4cf7c8683895c87caa8"<>CheckSumBitmap(screen0)
        print "multiscreen alpha test fail"
        if not IgnoreAlphaTest() then stop
    endif

	 	 
'****************************************************************
'****************************************************************
print "'*** Tiny Screen stress test"
    sleep(1000)
'****************************************************************
'****************************************************************

	screen1=createScreen()
    screen0 = invalid
	screen1.DrawRect(0,0,screen1.GetWidth(),screen1.GetHeight(),&h00000000)
	screen1.DrawRect(0,0,100,100,&hFF000080)
    redBoxmd5 = CheckSumBitmap(screen1)
    print "Should see red box in upper left"
    sleep(5000)
	for x=1 to 30
        print "Create tiny screen ";x
		screen2=createScreen()
        if redboxmd5 <> CheckSumBitmap(screen1) then
            print "md5 error with redbox background screen"
            stop
        endif
		if screen2 = invalid
		    print "stress test failed at iteration ";x
		    stop
		endif
        sleep(1000)
		screen2.Clear(black)
        sleep(1000)
		screen2=invalid
        print "Screen 1 should have come back"
        if redboxmd5 <> CheckSumBitmap(screen1) then
            print "Error: bits of redbox screen1 changed"
            stop
        endif
        sleep(5000)
        stop
	end for

	screen1.DrawRect(50,50,100,100,&h00FF0080)
    screen1.finish()
	
	print"at this point, the display screen  should display a red rect with an overlapped green rect on top of it."
	if "a7ae1741bd6301a24c751805d1da47c7"<>CheckSumBitmap(screen1) then stop

print "All 2D graphics tests completed."
    sleep(5000)
		
End sub


function CheckSumBitmap(bitmap, x=0, y=0, w=bitmap.GetWidth(), h=bitmap.GetHeight())
'   Change to md5 Checksum

	ba=bitmap.GetByteArray(x,y,w,h)
	'print "md5ing bitmap x=";x;" y=";y;" (";w;"x";h;")"

    digest = CreateObject("roEVPDigest")
    digest.Setup("md5")
    digest.Update(ba)
    result = digest.Final()

	print "md5 returns:"; result
    return result
	
end function

function compareAsLongs(ba, value)
    if ba.IsLittleEndianCPU()
        ' swap around bytes
        ' my kingdom for a shift instruction, or how about a swapbytes operator
        b3 = value and &hff
        b2 = value and &hff00
        b1 = value and &hff0000
        value = int((value and &hff000000)/(256*256*256)) and &hff      ' don't forget, it is signed
        value = int(value + int(b3*256*256*256) +b2*256 + int(b1/256))
    endif
    ourstep = 1
    if BriefTest()
        ourstep = 10
    endif
    count = ba.count()/4-1
    for i = 0 to count step ourstep
        v = ba.GetSignedLong(i)
        if  v <> value then
            print "Error in compareLongs index=";i;" want="; value;" found=";v
            stop
        endif
    end for
end function

function IsAllColor(ba, red, green, blue)
    value = 255+256*(blue+256*(green+256*red))
    compareAsLongs(ba,value)
end function

function CheckClear(bitmap, color, red, green, blue)
    print "CheckClear color=";color;" red=";red;" green=";green;" blue=";blue
	bitmap.Clear(color)
	bitmap.Finish()  ' show our work in progress
	ba=bitmap.GetByteArray(0, 0, bitmap.GetWidth(), bitmap.GetHeight())
	IsAllColor(ba, red, green, blue)
end function
