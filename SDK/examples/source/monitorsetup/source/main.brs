' ********************************************************************
' ********************************************************************
' **
' **  Roku TV Setup
' **  Display several types of monitor test patterns for position,
' **  size, aspect ratio, convergence, and color setup
' **  Example of app that uses slideshow object
' **
' **  August 2009
' **  Copyright (c) 2009 Roku Inc. All Rights Reserved.
' ********************************************************************
' ********************************************************************

'*************************************************************
'** Set the configurable theme attributes for the application
'** In this example app, we just use the SDK default artwork
'** 
'** Configure the custom overhang and Logo attributes
'*************************************************************
Sub SetTheme()
    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangOffsetSD_X = "72"
    theme.OverhangOffsetSD_Y = "25"
    theme.OverhangSliceSD = "pkg:/images/Overhang_BackgroundSlice_Blue_SD43.png"
    theme.OverhangLogoSD  = "pkg:/images/Logo_Overhang_Roku_SDK_SD43.png"

    theme.OverhangOffsetHD_X = "123"
    theme.OverhangOffsetHD_Y = "48"
    theme.OverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_Blue_HD.png"
    theme.OverhangLogoHD  = "pkg:/images/Logo_Overhang_Roku_SDK_HD.png"

    app.SetTheme(theme)
End Sub

'*************************************************************
'** Start slideshow with list of slides
'** 'glbls' is used to access the current underscan setting
'** 
'*************************************************************
Sub DoSlideShow(glbls as object, slides as object)
    slideshow = CreateObject("roSlideShow")
    port = CreateObject("roMessagePort")
    slideshow.SetMessagePort(port)

    slideshow.setcontentlist(slides)

    slideshow.setunderscan(glbls.underscan) ' shrink the display by x%
    slideshow.setPeriod(50000)             ' seconds, essentially forever
                                           ' allowing user to fwd and reverse at leisure

    slideshow.setTextOverlayHoldTime(3000) ' milliseconds

    slideshow.Show()

    while (true)
        msg = wait(0,port)
        if type(msg) = "roSlideShowEvent" then
            print "roSlideShowEvent:"; msg.getmessage()
            if msg.isScreenClosed() then
                return
            endif
        endif
   end while
End sub

'*************************************************************
'** Add a new picture url to the 'slides' array
'** 
'*************************************************************
sub addpicture(slides as object, filename as string)
    aa = CreateObject("roAssociativeArray")
    aa.url = filename
    aa.TextOverlayUL = "Upper Left Text"
    aa.TextOverlayUR = "Upper Right Text"
    aa.TextOverlayBody = "pic("+Stri(slides.count())+"):" + chr(10) + filename 
    slides.Push(aa)
end sub

'*************************************************************
'** Add a set of slides common to each resolution
'** 
'*************************************************************
Sub AddStandardImages(slides as object, host as string, res as string)
    addpicture(slides, host + res + "/overscan.gif")
    addpicture(slides, host + res + "/grid.gif")
    addpicture(slides, host + res + "/IndianHeadTestPattern.png")
    addpicture(slides, host + res + "/SMPTE_bars_setup_labels_lg.jpg")
End Sub

'*************************************************************
'** Setup slides for 1280x720 HD (16x9) resolution
'** 
'*************************************************************
sub Display1280x720(glbls, host as string)
    slides = CreateObject("roArray",10,true)
    AddStandardImages(slides, host, "1280x720")
    addpicture(slides, host + "1280x720/" + "testchart720.gif")
    addpicture(slides, host + "1280x720/" + "w.png")
    DoSlideShow(glbls, slides)
end sub

'*************************************************************
'** Setup misc slides for any resolution
'** 
'*************************************************************
Sub DisplayMisc(glbls, host as string)
    host = host + "misc/"
    slides = CreateObject("roArray",10,true)
    addpicture(slides, host + "Nokia-Monitor-Test_1.png")
    addpicture(slides, host + "Nokia-Monitor-Test_2.png")
    addpicture(slides, host + "Nokia-Monitor-Test_3.png")
    DoSlideShow(glbls, slides)
end sub

'*************************************************************
'** Setup slides for 720x480 SD (4x3) resolution
'** 
'*************************************************************
Sub Display1280x960(glbls, host as string)
    slides = CreateObject("roArray",10,true)
    AddStandardImages(slides, host, "1280x960")
    addpicture(slides, host + "1280x960/" + "star-chart-bars-full-600dpi.png")
    DoSlideShow(glbls, slides)
end sub

'*************************************************************
'** Create a category that can be picked on the poster screen
'** When picked the callback will be called
'*************************************************************
Sub AddCategory(posterlist as object, title as string, desc as string, desc2 as string, callback as object)
    Category = CreatePosterItem(title,desc,desc2)
    Category.Process = callback
    posterlist.push(Category)
End Sub

'*************************************************************
'** Create all the slideshow poster items,
'*************************************************************
Function CreateResolutionPickScreen() as object
    PosterItems = CreateObject("roArray", 10, true)
    AddCategory(PosterItems,"720p","16x9","1280x720 files",Display1280x720)
    AddCategory(PosterItems,"sd","4X3","1280x960 files",Display1280x960)
    AddCategory(PosterItems,"res","Misc","misc files",DisplayMisc)
    return PosterItems
End Function

Sub AdjustUnderscanUp(glbls as object, host as string)
    glbls.Underscan = glbls.Underscan + 1.0
end Sub

Sub AdjustUnderscanDown(glbls as object, host as string)
    glbls.Underscan = glbls.Underscan - 1.0
end sub

REM ************************************************************************
REM
REM Main - entry point for this application
REM 
REM ************************************************************************
Sub Main()
'
'   Initialization
'
    Underscan = 0.0
    FocusItem = 0
    host = "http://rokudev.roku.com/rokudev/testpatterns/"

    SetTheme()                  ' Default Roku SDK color scheme

'   create an associate array to hold our variables
    glbls = CreateObject("roAssociativeArray")
    
    glbls.PosterItems = CreateResolutionPickScreen()
    glbls.Underscan = Underscan    ' this will be used and modified

' Create Category to adjust underscan, these are interactive with the poster screen
    AddCategory(glbls.PosterItems,"shrink","Increase Underscan","Adjust Up",AdjustUnderscanUp)
    AddCategory(glbls.PosterItems,"blowup","Increase Overscan","Adjust Down",AdjustUnderscanDown)
    
    Underscantext = "Underscan:" + str(Underscan) + "%"
    ResText = "Resolutions"
    
    ' Create a poster screen with current values
    Pscreen = StartPosterScreen(glbls, FocusItem, UnderscanText, ResText)
    
    while true
        FocusItem = Pscreen.GetSelection(0)    ' returns a selection
        if FocusItem = -1 then
            return
        endif
        glbls.PosterItems[FocusItem].Process(glbls, host)
        if (Underscan <> glbls.Underscan) ' Did Underscan change?
            Underscan = glbls.Underscan
            Underscantext = "Underscan:" + str(Underscan) + "%"
            Pscreen.screen.SetBreadCrumbText(UnderscanText, ResText)
        endif
    end while
End Sub
