
Function CreateSettings()
    this = {}
    '' Initialize the object
    this.Init = Function()
        m.app = CreateObject("roAppManager")
        m.settings_section = "clock_screensaver"
        m.default_clock = "roku"

        m.clocks = []
        m.clocks.append([{name:"roku"  ,func:CreateRokuAnalogClock}])
        m.clocks.append([{name:"white" ,func:CreateWhiteAnalogClock}])
    End Function

    '''
    ''' Display the main settings screen
    '''
    this.Show = Function()
        m.SetupTheme()
        m.ShowDigitalClockSettings() 
    End Function

    '''
    ''' Display the digital clock settings page
    '''
    this.ShowDigitalClockSettings = Function()
        scr = CreateObject("roParagraphScreen")
        prt = CreateObject("roMessagePort")
        scr.SetMessagePort(prt)
        scr.SetTitle("Analog Clock Style")
        
        scr.AddParagraph("Select the style for the analog clock.")
        for i=0 to m.clocks.Count() - 1 step 1
            scr.AddButton(i,m.clocks[i].name)
        end for
        
        scr.Show()
        while(true)
            msg = wait(0,prt)
            if (msg.isButtonPressed())
                m.WriteClockType(m.clocks[msg.GetIndex()].name)
                scr=invalid
                exit while
            else if (msg.isScreenClosed())
                exit while
            end if
        end while
    End Function

    '''
    ''' Setup the theme for the settings screens
    '''
    this.SetupTheme = Function()
        theme = {}
        theme.OverhangOffsetSD_X = "88"
        theme.OverhangOffsetSD_Y = "30"
        theme.OverhangSliceSD = "pkg:/images/Home_Overhang_BackgroundSlice_SD43.png"
        theme.OverhangLogoSD  = "pkg:/images/Overhang_Logo_Roku_White_SD43.png"
        theme.OverhangOffsetHD_X = "136"
        theme.OverhangOffsetHD_Y = "45"
        theme.OverhangSliceHD = "pkg:/images/Home_Overhang_BackgroundSlice_HD.png"
        theme.OverhangLogoHD  = "pkg:/images/Overhang_Logo_Roku_White_HD.png"
        m.app.SetTheme(theme)
    End Function

    '''
    ''' Return an AA that represents the clock based on that current saved clock type.
    ''' 
    this.GetClockImage = Function()
        t = m.GetClockType()
        for i=0 to m.clocks.Count() - 1 step 1
            if m.clocks[i].name = t then return m.clocks[i].func()
        end for
    End Function

    '''
    ''' Settings Functions
    '''
    this.WriteClockType = Function(clock_type)
        print "Save clock type: " clock_type
        RegWrite("type",clock_type,m.reg_section)
    End Function

    this.GetClockType = Function()
        t = RegRead("type",m.reg_section)
        if (t = "" or t = invalid) then t = m.default_clock
        return t
    End Function
    
    this.Init()
    return this
End Function

