function Main()
    m.title = "Upgrade Test B"
    m.port = CreateObject("roMessagePort")
    updateScreen()
    m.store = CreateObject("roChannelStore")
    m.store.SetMessagePort(m.port)
    m.store.GetUpgrade()
    m.state = "query"
    while true
        print "Main: looping in "; "'"; m.title; "'"; " in state "; m.state
        msg = wait(0,m.port)
        tm = type(msg)
        if tm="roParagraphScreenEvent"
            if msg.IsButtonPressed()
                btn = msg.GetIndex()
                if btn = m.exitBtn
                    transition("done")
                    exit while
                else if btn = m.upgradeBtn
                    if m.state="confirmUpgrade"
                        transition("upgrade")
                        print "Main: starting upgrade"
                        m.upgradeId = m.store.DoUpgrade()
                        transition("confirmGoto")
                        updateScreen()
                    else if m.state="confirmGoto"
                        transition("goto")
                        app = CreateObject("roAppManager")
                        app.LaunchApp(m.upgradeId,"",invalid)
                    end if
                end if
            end if
        else if tm="roChannelStoreEvent"
            if m.state="query"
                if msg.IsRequestSucceeded()
                    upgrades = msg.GetResponse()
                    if upgrades<>invalid and upgrades[0]<>invalid and upgrades[0].name<>invalid
                        m.upgradeName = upgrades[0].name
                        print "Main: "; "'"; m.title; "'"; " is upgradable to "; "'"; m.upgradeName; "'"
                        transition("confirmUpgrade")
                    else
                        print "Main: upgrades empty"
                        m.upgradeName = ""
                        transition("failure")
                    end if
                    updateScreen()
                else
                    print "Main: upgrade query failed or canceled: "; msg.GetStatusMessage()
                    m.upgradeName = ""
                    updateScreen()
                    transition("failure")
                end if
            else if m.state="upgrade" or m.state="confirmGoto"
                print "Main: upgrade completed: "; msg.GetStatusMessage()
            else
                print "Main: out of sequence message: "; msg.GetStatusMessage()
            end if
        end if
    end while
    print "Main: exiting on state "; m.state
end function

function transition(state as String)
    print "Main: transition from "; m.state; " to "; state
    m.state = state
end function

function updateScreen()
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(m.port)
    screen.SetTitle(m.title)
    m.exitBtn = 0
    m.upgradeBtn = 1
    if m.upgradeId<>invalid
        if m.upgradeId<>""
            screen.AddButton(m.exitBtn,"Exit")
            screen.AddButton(m.upgradeBtn,"Goto #"+m.upgradeId+" ("+m.upgradeName+")")
        else
            screen.AddButton(m.exitBtn,"Upgrade failed, exit")
        end if
    else if m.upgradeName<>invalid
        if m.upgradeName<>""
            screen.AddButton(m.exitBtn,"Exit")
            screen.AddButton(m.upgradeBtn,"Upgrade to "+m.upgradeName)
        else
            screen.AddButton(m.exitBtn,"No upgrade available, exit")
        end if
    else
        screen.AddButton(m.exitBtn,"Exit")
    end if
    screen.Show()
    m.screen = screen
end function

