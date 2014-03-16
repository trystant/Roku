' Creates an roAssociativeArray that is compatible with
' ScreensaverCanvas which represents an analog clock using images.
' A clock with a Roku branded face.
Function CreateRokuAnalogClock()
    this = {}
    
    this.Init = Function()
        m.clock_arm_slop = 4
     
        ' image "constants"
        if (IsHD()) then 
            m.clock  = {url:"pkg:/images/roku/clock_HD.png"  , SourceRect:{w:206,h:206} , Mode:"Source_Over"}
            m.hour   = {url:"pkg:/images/roku/hour_HD.png"   , SourceRect:{w:12,h:51}   , Mode:"Source_Over"}
            m.minute = {url:"pkg:/images/roku/minute_HD.png" , SourceRect:{w:16,h:77}   , Mode:"Source_Over"}
            m.second = {url:"pkg:/images/roku/second_HD.png" , SourceRect:{w:10,h:86}   , Mode:"Source_Over"}
            m.cap    = {url:"pkg:/images/roku/cap_HD.png"    , SourceRect:{w:16,h:16}   , Mode:"Source_Over"}
        else
            m.clock  = {url:"pkg:/images/roku/clock_SD.png"  , SourceRect:{w:152,h:136} , Mode:"Source_Over"}
            m.hour   = {url:"pkg:/images/roku/hour_SD.png"   , SourceRect:{w:9, h:34}   , Mode:"Source_Over"}
            m.minute = {url:"pkg:/images/roku/minute_SD.png" , SourceRect:{w:12,h:51}   , Mode:"Source_Over"}
            m.second = {url:"pkg:/images/roku/second_SD.png" , SourceRect:{w:7 ,h:57}   , Mode:"Source_Over"}
            m.cap    = {url:"pkg:/images/roku/cap_SD.png"    , SourceRect:{w:12,h:11}   , Mode:"Source_Over"}
        end if
    
        ' Setup the order of the images in the content list.
        m.content_list = [m.clock,m.cap,m.hour,m.minute, m.second]     
        ' Add a center value to all the "images" in the content_list
        CalcCenters(m.content_list)  
    End Function

    '''
    ''' Screensaver canvas required methods (GetHeight, GetWidth(), Update()
    '''
    this.GetHeight  = function() :return m.clock.SourceRect.h :end function
    this.GetWidth   = function() :return m.clock.SourceRect.w :end function

    this.Update = function(x,y)
        d = CreateObject("roDatetime")
        d.toLocalTime()
        m.hour.TargetRotation = GetHourRotation(d)
        m.hour.TargetTranslation = {x:(m.clock.center.x + x) , y:(m.clock.center.y + y)}
        m.hour.TargetRect = {x:-(m.hour.center.x) , y: -(m.hour.SourceRect.h) + m.clock_arm_slop}

        m.minute.TargetRotation = GetMinuteRotation(d)
        m.minute.TargetTranslation = {x:(m.clock.center.x + x) , y:(m.clock.center.y + y)}
        m.minute.TargetRect = {x:-(m.minute.center.x) , y: -(m.minute.SourceRect.h) + m.clock_arm_slop}
        
        m.second.TargetRotation = d.GetSeconds()*6
        m.second.TargetTranslation = {x:(m.clock.center.x + x) , y:(m.clock.center.y + y)}
        m.second.TargetRect = {x:-(m.second.center.x) , y: -(m.second.SourceRect.h) + m.clock_arm_slop}
        
        m.clock.TargetRect = {x:x, y:y}
        m.cap.TargetRect = {x:x + Int(m.clock.center.x - m.cap.SourceRect.w/2) ,y:y + Int(m.clock.center.y - m.cap.SourceRect.w/2)}
        
        return m.content_list
    end function
    
    this.Init()
    return this
End Function

' Creates an roAssociativeArray that is compatible with
' ScreensaverCanvas which represents an analog clock using images.
' A clock with a white face.
Function CreateWhiteAnalogClock()
    this = {}
    
    this.Init = Function()
        ' image "constants"
        if (IsHD()) then 
            m.clock  = {url:"pkg:/images/white/clock_HD.png"  , SourceRect:{w:356,h:356} , Mode:"Source_Over"}
            m.hour   = {url:"pkg:/images/white/hour_HD.png"   , SourceRect:{w:356,h:356} , Mode:"Source_Over"}
            m.minute = {url:"pkg:/images/white/minute_HD.png" , SourceRect:{w:356,h:356} , Mode:"Source_Over"}
            m.second = {url:"pkg:/images/white/second_HD.png" , SourceRect:{w:356,h:356} , Mode:"Source_Over"}
        else
            m.clock  = {url:"pkg:/images/white/clock_SD.png"  , SourceRect:{w:160,h:145} , Mode:"Source_Over"}
            m.hour   = {url:"pkg:/images/white/hour_SD.png"   , SourceRect:{w:160,h:145} , Mode:"Source_Over"}
            m.minute = {url:"pkg:/images/white/minute_SD.png" , SourceRect:{w:160,h:145} , Mode:"Source_Over"}
            m.second = {url:"pkg:/images/white/second_SD.png" , SourceRect:{w:160,h:145} , Mode:"Source_Over"}
        end if
    
        ' Setup the order of the images in the content list.
        m.content_list = [m.clock,m.hour,m.minute,m.second]     
        ' Add a center value to all the "images" in the content_list
        CalcCenters(m.content_list)  
    End Function

    '''
    ''' Screensaver canvas required methods (GetHeight, GetWidth(), Update()
    '''
    this.GetHeight  = function() :return m.clock.SourceRect.h :end function
    this.GetWidth   = function() :return m.clock.SourceRect.w :end function

    this.Update = function(x,y)
        d = CreateObject("roDatetime")
        d.toLocalTime()
        m.hour.TargetRotation = GetHourRotation(d)
        m.hour.TargetTranslation = {x:x+m.clock.center.x , y:y+m.clock.center.y}
        m.hour.TargetRect = {x:-(m.second.center.x) , y: -(m.second.center.y)}

        m.minute.TargetRotation = GetMinuteRotation(d)
        m.minute.TargetTranslation = {x:x+m.clock.center.x , y:y+m.clock.center.y}
        m.minute.TargetRect = {x:-(m.second.center.x) , y: -(m.second.center.y)}
        
        m.second.TargetRotation = d.GetSeconds()*6
        m.second.TargetTranslation = {x:x+m.clock.center.x , y:y+m.clock.center.y}
        m.second.TargetRect = {x:-(m.second.center.x) , y: -(m.second.center.y)}
        
        m.clock.TargetRect = {x:x, y:y}
        return m.content_list
    end function

    this.Init()
    return this
End Function