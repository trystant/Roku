' *********************************************************
' **  In-app purchase Demonstration App
' **  Nov 2011
' **  Copyright (c) 2011 Roku Inc. All Rights Reserved.
' *********************************************************

Sub Main()

    InitTheme()

    port = CreateObject("roMessagePort")
    store = InitStore(port)
    homeScreen = InitHome(store)
    detailScreen = InitDetail(homeScreen)
    dialog = invalid

    homeScreen.update()
    store.action()
    while true
        msg = wait(0, port)
        tm = type(msg)
        if tm = "roPosterScreenEvent"
            if homeScreen.handle(msg)
                if homeScreen.done then exit while
                product = store.GetProductByIndexes(homeScreen.listIndex,homeScreen.itemIndex)
                detailScreen.update(product)
            end if
        else if tm = "roChannelStoreEvent"
            error = store.handle(msg)
            if error=""
                homeScreen.update()
                store.action()
            else
                dialog = Alert(port, "Error", error)
            end if
        else if tm = "roMessageDialogEvent"
            dialog = invalid ' always close dialog
            store.action()
        else if tm = "roSpringboardScreenEvent"
            if detailScreen.handle(msg) then homeScreen.update()
        else
            print "Main: unexpected message type "; tm
        end if
    end while

    print "Main: exiting"

End Sub

Sub InitTheme()
    app = CreateObject("roAppManager")
    theme =  {
        OverhangOffsetSD_X : "72"
        OverhangOffsetSD_Y : "25"
        OverhangSliceSD    : "pkg:/images/Overhang_BackgroundSlice_Blue_SD43.png"
        OverhangLogoSD     : "pkg:/images/Logo_Overhang_Roku_SDK_SD43.png"

        OverhangOffsetHD_X : "123"
        OverhangOffsetHD_Y : "48"
        OverhangSliceHD    : "pkg:/images/Overhang_BackgroundSlice_Blue_HD.png"
        OverhangLogoHD     : "pkg:/images/Logo_Overhang_Roku_SDK_HD.png"
    }
    app.SetTheme(theme)
End Sub

' Put up a dialog with a message that the user must dismiss
Function Alert(port as Object, title As String, text As String) as Object
    dialog = CreateObject("roMessageDialog")
    dialog.setMessagePort(port)
    dialog.setTitle(title)
    dialog.setText(text)
    dialog.enableBackButton(true)
    dialog.addButton(0, "Continue")
    dialog.show()
    return dialog
End Function

function nonEmptyStr(str as Dynamic) as Boolean
    return type(str)="roString" and Len(str)>0 
end function
