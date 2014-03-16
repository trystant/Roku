' Main() is useful for testing. It should be commented
' out before this is checked in.
Sub Main()
    Init()
    facade = CreateObject("roParagraphScreen")
    facade.Show()
    RunScreenSaverSettings()
    RunScreenSaver()
End Sub

' The screensaver settings entry point.
Sub RunScreenSaverSettings()
    Init()
    m.settings.Show()
End Sub

' The screensaver entry point.
Sub RunScreenSaver()
    Init()
    canvas = CreateScreensaverCanvas("#000000")
    canvas.SetImageFunc(GetClockImage)
    canvas.SetLocFunc(screensaverLib_RandomLocation)
    canvas.SetLocUpdatePeriodInMS(6000)
    canvas.SetUpdatePeriodInMS(1000)
    canvas.SetUnderscan(.09)
    canvas.Go()
End Sub

' Return an AA for the appropriate clock image.
' This is an AA that is compatible with the screensaver
' canvas.
Function GetClockImage()
    if m.saved_image = invalid then
        m.saved_image = m.settings.GetClockImage()
    end if
    return m.saved_image
End Function

' Initialize all global objects.
Function Init()
    if (m.initialized = invalid) then
        m.settings = CreateSettings()
        m.initialized = true
    end if
End Function