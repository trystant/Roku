Library "v30/bslDefender.brs"

'
' The game of Snake
' Demonstrates BrightScript programming concepts
' August 24, 2010


function Main()

    app=newSnakeApp()
    dfDrawMessage(app.screen, app.bitmapset.regions["title-screen"])
    app.screen.swapbuffers()
    while true
        msg=wait(0, app.msgport)
        if type(msg)="roUniversalControlEvent" then exit while
    end while
    
    while true
        app.GameReset()        
        app.EventLoop()
        app.GameOverSound.Trigger(100)
        if app.GameOver() then ExitWhile
    end while
    
end function


' *******************************************************
' *******************************************************
' ***************                   *********************
' ***************         APP       *********************
' ***************                   *********************
' *******************************************************
' *******************************************************


'
' newSnakeApp() is regular Function of module scope.
' The object container is a BrightScript Component of type roAssocitiveArray (AA).   
' The AA is used to hold member data and member functions.
'

Function newSnakeApp()
    app={ }       ' Create a BrightScript roAssociativeArray Component
    app.GameReset=appGameReset
    app.EventLoop=appEventLoop
    app.GameOver=appGameOver

    app.screen=CreateObject("roScreen", true)  ' true := use double buffer
    if type(app.screen)<>"roScreen" then
        print "Unable to create roscreen."
        stop   ' stop exits to the debugger
    endif
    
    app.screen.SetAlphaEnable(true) 

    app.bitmapset=dfNewBitmapSet(ReadAsciiFile("pkg:/snake_assets/sprite.small.map.xml"))
    if (app.bitmapset=invalid) then stop
    
    app.cellwidth=app.bitmapset.extrainfo.cellsize.toint()     ' each cell on game in pixels width
    app.cellheight = app.cellwidth
    app.msgport = CreateObject("roMessagePort")
    app.screen.SetPort(app.msgport)
    app.StartX=int(app.screen.GetWidth()/2)
    app.StartY=int(app.screen.GetHeight()/2)
    
    app.TurnSound=CreateObject("roAudioResource", "pkg:/snake_assets/cartoon002.wav")
    app.GameOverSound=CreateObject("roAudioResource", "pkg:/snake_assets/cartoon008.wav")
    
    return app

End Function

Function appEventLoop() As Void

    tick_count=0
    codes = bslUniversalControlEventCodes()
    
    clock = CreateObject("roTimespan")
    makelongertime = 0
    moveforwardtime = 0
    framecount = 0
    framecounttime = 0
    
    moveforward_every_n_msecs = 200
    grow_every_n_msecs = 1000
    
    while true
        msg = m.msgport.getmessage()   ' poll for a button press
        if msg <> invalid and type(msg)="roUniversalControlEvent" then
            ' remember that the part of an expression after "and" is only evaluated if the prior parts are true
            if msg.GetInt()=codes.BUTTON_UP_PRESSED    and m.snake.Turn(m,  0, -1) then return  ' North
            if msg.GetInt()=codes.BUTTON_DOWN_PRESSED  and m.snake.Turn(m,  0,  1) then return  ' South
            if msg.GetInt()=codes.BUTTON_RIGHT_PRESSED and m.snake.Turn(m,  1,  0) then return  ' East
            if msg.GetInt()=codes.BUTTON_LEFT_PRESSED  and m.snake.Turn(m, -1,  0) then return  ' West
        end if
        ' get elapsed time since last time here
        ticks = clock.totalmilliseconds()
        clock.mark()

        makelongertime = makelongertime + ticks
        moveforwardtime = moveforwardtime + ticks
        framecounttime = framecounttime + ticks
        ' make longer every 1 sec
        if makelongertime >= grow_every_n_msecs then
            if m.snake.MakeLonger(m) then return
            makelongertime = makelongertime - grow_every_n_msecs
            moveforwardtime = moveforwardtime - moveforward_every_n_msecs     ' we make longer by moving forward, so decrement this also
        endif
        ' move forward 10 times per second
        if moveforwardtime >= moveforward_every_n_msecs then
                if m.snake.MoveForward(m) then return
                moveforwardtime = moveforwardtime - moveforward_every_n_msecs
        end if

        m.compositor.AnimationTick(ticks)
        m.compositor.DrawAll()
        m.screen.SwapBuffers()
        framecount = framecount + 1
        ' every 3 seconds print out frame speed
        if framecounttime >= 3000
            ' in this calculation also include time to this point
            print "frames per second ="; 1000*framecount/(framecounttime+clock.totalmilliseconds())
            framecount = 0
            framecounttime = 0
        endif
    end while

End Function

Sub appGameReset()

    m.compositor=CreateObject("roCompositor")
    m.compositor.SetDrawTo(m.screen, 0) ' 0 means "no background color".  Use &hFF for black. 

    width=int(m.screen.GetWidth()/m.cellwidth)
    height=int(m.screen.GetHeight()/m.cellheight)
    water=m.bitmapset.animations.water
    for x=0 to width-1
        m.compositor.NewAnimatedSprite(x*m.cellwidth, 0, water)
        m.compositor.NewAnimatedSprite(x*m.cellwidth, m.cellheight, water ) 
        m.compositor.NewAnimatedSprite(x*m.cellwidth,  (height-2)*m.cellheight, water )
        m.compositor.NewAnimatedSprite(x*m.cellwidth,  (height-1)*m.cellheight, water )
    end for

    for y=1 to height-2
        m.compositor.NewAnimatedSprite(0, y*m.cellheight, water )
        m.compositor.NewAnimatedSprite(m.cellwidth, y*m.cellheight, water ) 
        m.compositor.NewAnimatedSprite(m.cellwidth*2, y*m.cellheight, water )                   
        m.compositor.NewAnimatedSprite((width-3)*m.cellwidth,  y*m.cellheight, water )
        m.compositor.NewAnimatedSprite((width-2)*m.cellwidth,  y*m.cellheight, water )
        m.compositor.NewAnimatedSprite((width-1)*m.cellwidth,  y*m.cellheight, water )      
    end for

    m.compositor.NewSprite(0, 0, m.bitmapset.Regions.Background).SetMemberFlags(0)

    m.snake=newSnake(m, m.StartX, m.StartY)
    
    m.compositor.Draw()
    
End Sub

Function appGameOver()
    codes = bslUniversalControlEventCodes()

    m.compositor.DrawAll()
    dfDrawMessage(m.screen, m.bitmapset.regions["game-over"])
    m.screen.SwapBuffers()  

    while true
        msg=wait(0, m.msgport)
        if type(msg)="roUniversalControlEvent" 
            if msg.GetInt()=codes.BUTTON_SELECT_PRESSED return false else return true    
        end if
    end while

End Function


' *******************************************************
' *******************************************************
' ******************              ***********************
' ****************** SNAKE OBJECT ***********************
' ******************              ***********************
' *******************************************************
' *******************************************************

'
' construct a new snake BrightScript object
'
Function newSnake(app, x, y)

    snake = {   ' Use AA Operator { }

        Turn : snkTurn
        MoveForward : snkMoveForward
        MakeLonger : snkMakeLonger

        dx : 1      ' default snake direction
        dy : 0      ' default snake direction
        
        DirectionName : function(xdelta, ydelta, base)
            if xdelta = 1 then
               dir="East"
            else if xdelta = -1 then 
               dir="West"
            else if ydelta = 1 then 
               dir = "South"
            else 
               dir = "North"
            end if
            return base+dir
        end function    
        
        RegionName : function(xdelta, ydelta, base)
            if xdelta = 1 then
               dir="East"
            else if xdelta = -1 then 
               dir="West"
            else if ydelta = 1 then 
               dir = "South"
            else 
               dir = "North"
            end if
            return "snake."+base+dir
        end function
        
    

    }


    snake.tongue=app.compositor.NewAnimatedSprite(x,        y, app.bitmapset.animations[snake.DirectionName( 1, 0, "tongue-")] )
           head=app.compositor.NewSprite(x-app.cellwidth,   y, app.bitmapset.regions[snake.RegionName( 1, 0, "head-")] )
           body=app.compositor.NewSprite(x-2*app.cellwidth, y, app.bitmapset.regions[snake.RegionName( 1, 0, "body-")] )
    snake.tail= app.compositor.NewSprite(x-3*app.cellwidth, y, app.bitmapset.regions[snake.RegionName( 1, 0, "butt-")] )

    snake.tail.SetData( {dx: 1, dy: 0, next: body,         previous: invalid} )
           body.SetData( {dx: 1, dy: 0, next: head,         previous: snake.tail} )
           head.SetData( {dx: 1, dy: 0, next: snake.tongue,  previous: body} )
    snake.tongue.SetData( {dx: 1, dy: 0, next: invalid,      previous: head} )

    snake.tongue.SetmemberFlags(0)
    
    return snake

End Function


Function snkMoveForward(app)
    sprite=m.tail
    m.tail=m.tail.GetData().next
    m.tail.GetData().previous=invalid
    sprite.Remove()
    m.tail.SetRegion(app.bitmapset.regions[m.RegionName(m.tail.GetData().dx, m.tail.GetData().dy, "butt-")])
    return m.MakeLonger(app) ' This isnt actually making the snake longer, its just the 2nd half of MoveForward()
End Function

Function snkMakeLonger(app)
    newbody_x=m.tongue.GetX()-m.dx*app.cellwidth
    newbody_y=m.tongue.GetY()-m.dy*app.cellheight
    newbody=app.compositor.NewSprite(newbody_x, newbody_y, app.bitmapset.regions[m.RegionName( m.dx, m.dy, "body-")] )

    m.tongue.MoveOffset(m.dx*app.cellwidth, m.dy*app.cellheight)
    head=m.tongue.GetData().previous
    head.MoveOffset(m.dx*app.cellwidth, m.dy*app.cellheight)
    
    body=head.GetData().previous
    head.GetData().previous=newbody
    body.GetData().next=newbody
    newbody.SetData( {dx: m.dx, dy: m.dy, next: head , previous: body} )
    collision = head.CheckCollision()
    return head.CheckCollision()<>invalid
    
End Function

Function snkTurn(app, newdx, newdy)

    if newdx=m.dx and newdy=m.dy then return false   ' already heading this way
    
    tongue_x=m.tongue.GetX()+newdx*app.cellwidth*2
    tongue_y=m.tongue.GetY()+newdy*app.cellheight*2
    
    head_x = tongue_x - newdx*app.cellwidth
    head_y = tongue_y - newdy*app.cellwidth
    
    corner_x = head_x - newdx*app.cellwidth
    corner_y = head_y - newdy*app.cellwidth
    
    prior_dx=m.dx
    prior_dy=m.dy
        
    m.dx=newdx
    m.dy=newdy
    
    newtongue=app.compositor.NewAnimatedSprite(tongue_x, tongue_y, app.bitmapset.animations[m.DirectionName( newdx, newdy, "tongue-")] )
    newhead=app.compositor.NewSprite(head_x, head_y, app.bitmapset.regions[m.RegionName( newdx, newdy, "head-")] )
    newcorner=m.tongue
    newbody=newcorner.GetData().previous
    
    newtongue.SetMemberFlags(0)
    
   
     newcorner.SetData( {dx: newdx, dy: newdy, next: newhead,  previous: newcorner.GetData().previous} )
       newhead.SetData( {dx: newdx, dy: newdy, next: newtongue,  previous: newcorner} )
     newtongue.SetData( {dx: newdx, dy: newdy, next: invalid,  previous: newhead} )

    m.tongue=newtongue
    
    if newhead.CheckCollision()<>invalid then return true
  
   ' fixup the last segment render 
   ' (there is a tongue which turns into a corner, and a head which turns into body)    

    newbody.SetRegion(app.bitmapset.regions[m.RegionName(newbody.GetData().dx, newbody.GetData().dy, "body-")])
    
    if m.dy=-1 then ' turned north
        if prior_dx=-1 then ' was west-bound
            newcorner.SetRegion(app.bitmapset.regions[m.RegionName(0, -1, "corner-")])
        else
            newcorner.SetRegion(app.bitmapset.regions[m.RegionName(-1, 0, "corner-")])
        end if
        
    else if m.dy=1  ' turned south
        if prior_dx=-1 then ' was west-bound
            newcorner.SetRegion(app.bitmapset.regions[m.RegionName(1, 0, "corner-")])
        else
            newcorner.SetRegion(app.bitmapset.regions[m.RegionName(0, 1, "corner-")])
        end if
        
    else if m.dx=-1 then ' turned west / left
        if prior_dy=-1 then ' was north-bound
            newcorner.SetRegion(app.bitmapset.regions[m.RegionName(0, 1, "corner-")])
        else
            newcorner.SetRegion(app.bitmapset.regions[m.RegionName(-1, 0, "corner-")])
        end if
    else if m.dx=1  ' turned east / right
        if prior_dy=-1 then   ' was north-bound
            newcorner.SetRegion(app.bitmapset.regions[m.RegionName(1, 0, "corner-")])
        else
            newcorner.SetRegion(app.bitmapset.regions[m.RegionName(0, -1, "corner-")])
        end if
    end if
    
    app.TurnSound.Trigger(100)
    
    return false

End Function






