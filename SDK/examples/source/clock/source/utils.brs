Function IsHD()
    di = CreateObject("roDeviceInfo")
    if di.GetDisplayType() = "HDTV" then return true
    return false
End Function

' Returns angle for the hour hand in degrees
Function GetHourRotation(d)
    rotation = 0.0
    hour = d.GetHours()
    if (hour > 12) then hour = hour - 12
    rotation = rotation + hour * 30.0
    rotation = rotation + (d.GetMinutes()/59.0) * 30.0
    return rotation
End Function

' Returns angle for the minute hand in degrees
Function GetMinuteRotation(d)
    rotation = 0.0
    rotation = rotation + d.GetMinutes() * 6
    rotation = rotation + (d.GetSeconds()/59.0) * 6
    return rotation
End Function

' Adds a center associative array to each associative array in
' the content_list. The center is the center of the image. Each
' aa must have a valid SourceRect aa with w and h.
Function CalcCenters(content_list)
        for each c in content_list
            c.center = {x:Int(c.SourceRect.w/2),y:Int(c.SourceRect.h/2)}
        end for
End Function

' Read a registry value
Function RegRead(key,section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then return sec.Read(key)
    return invalid
End Function

' Write a registry value
Function RegWrite(key, val, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
End Function
