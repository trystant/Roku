'***********************************************'
'*          SETTINGS ROUTINES                  *'
'* Settings is setup to use the same display   *'
'* utilities as the actual content routines    *'
'***********************************************'


Function findsettings()
' setup the filenames to use as targets for settings screen
    return [ "videos", "photos", "music" ]
end Function

Sub ShowSettings(item)
    print "Enter ShowSettings"

    container = item.container
    ' Use our own port so we don't get any messages not meant for us
    port =  CreateObject("romessageport")
    screen_aa = NewPosterScreen(port)
    screen = screen_aa.screen
    screen.SetBreadcrumbText(container.name, "")
    screen.Show()
    
    container.files = container.finder()

    posters = create_content_from_list(container, container.files)
    screen.setContentList(posters)

    while true
        print "wait for setting to be selected"
	    msg = pstr_process(screen, container.name)
	    print "got msg from pstr_process type=";type(msg)
	    if msg.isScreenClosed() return
	    if msg.isListItemSelected() and msg.GetIndex() < posters.Count()
	        selection = msg.GetIndex()
	        print "got selection:";selection
	        target_container = container.containers[selection]
	        target_container.settings({ container : target_container })
        endif
    end while

    print "Exit ShowSettings"
end Sub

Function create_setting(icon, desc1, f)
' Create a settings entry and display
    return {
            sdposterurl: m.imageDir + icon
            hdposterurl: m.imageDir + icon
            shortdescriptionline1: desc1
            shortdescriptionline2: "press select to change"
            callback: f
        }
end Function

Function rm_str(mode as integer)
' Convert mode number to corresponding descriptive string
    if (mode = 0) return "off"
    if (mode = 1) return "same file"
    if (mode = 2) return "sequential"
    if (mode = 3) return "random"
    ' much bigger than this and we should use an array
    return "Unknown repeat mode"
end Function

' common settings option
Sub doRepeatModeScreen(container, port)
    print "enter doRepeatScreen"
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.AddHeaderText("Repeat Mode options:")
    screen.AddParagraph("Set to 'off' to stop after current file is done.")
    screen.AddParagraph("Set to 'same file' to repeat the same file over and over.")
    screen.AddParagraph("Set to 'sequential to advance to the next file in the list.")
    screen.AddParagraph("Set to 'random' to advance to a random file in the list.")
    
    screen.AddButton(99, "exit - no change")
    screen.AddButton(0, rm_str(0))
    screen.AddButton(1, rm_str(1))
    screen.AddButton(2, rm_str(2))
    screen.AddButton(3, rm_str(3))
    screen.setdefaultmenuitem(1+container.repeatmode)

    ' want to set button to current state, but can't do that yet
    screen.Show()
'        screen.setdefaultmenuitem(1+container.repeatmode)       ' dammit
    while true
        print "waiting for setting selection"
        msg = WaitMessage(port)
        if msg.isScreenClosed() return
        if msg.isButtonPressed()
            i = msg.GetIndex()
            print "Button pressed:" i; " "; msg.GetData()
            if (i >= 0) and (i <= 3)
                if (container.repeatmode <> i)
                    reg_set_repeatmode(container.name, i)
                    container.repeatMode = i
                endif
            endif
            return
        endif
    end while
end Sub

Function doSetting(container, posters)
    print "Enter doSetting for "; container.name
    
    screen_aa = NewPosterScreen(container.port)
    screen = screen_aa.screen
    screen.SetBreadcrumbText(container.name, "settings")
    screen.Show()

    screen.setContentList(posters)
    
    ' use a separate port in subsettings screen to avoid usb interaction
    port = CreateObject("roMessagePort")

    while true
        print "wait for "; container.name; " setting to be selected"
	    msg = pstr_process(screen, container.name)
	    if msg.isScreenClosed() return -1
	    if msg.isListItemSelected() and msg.GetIndex() < posters.Count()
	        posters[msg.GetIndex()].callback(container, port)
	        return 0
        endif
    end while
end Function

' Dummy function
Sub SettingsSettings(item)
end Sub

Function newSettingsContainer()
    container = newContentContainer("settings", findsettings, "Provider_Settings_Center_HD.png", "Provider_Settings_Center_HD.png", ShowSettings, settingssettings, false)
    container.containers = [ m.videos, m.photos, m.music ]
    return container
end Function
